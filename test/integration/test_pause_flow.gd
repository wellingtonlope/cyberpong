extends GutTest

const POWER_UP_EFFECT := preload("res://scripts/power_up_effect.gd")

const MAIN_SCENE := preload("res://main.tscn")
const FIELD_SIZE := Vector2(2880.0, 1620.0)

var game

func before_each() -> void:
	get_viewport().size = FIELD_SIZE
	game = add_child_autofree(MAIN_SCENE.instantiate())
	var credits = game.get_node_or_null("CreditsScreen")
	assert_not_null(credits)
	credits.skip()
	credits._process(credits.SKIP_FADE_OUT_DURATION)
	var menu = game.get_node_or_null("GameMenu")
	assert_not_null(menu)
	menu.select_mode(GameMode.Mode.PLAYER_VS_AI)

func after_each() -> void:
	Input.action_release("ui_up")
	Input.action_release("ui_down")
	get_tree().paused = false
	get_viewport().size = FIELD_SIZE

func _press_key(keycode: Key) -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = keycode
	game._unhandled_key_input(event)

func test_pause_freezes_ball_and_paddles_and_resume_keeps_the_same_state() -> void:
	game.left_paddle.set_control_mode(Paddle.ControlMode.HUMAN)
	Input.action_press("ui_up")
	game.ball.position = Vector2(1200.0, 700.0)
	game.ball.velocity = Vector2(-2100.0, 480.0)
	game.ball.current_speed = 2100.0
	game.left_paddle.position.y = 620.0
	game.right_paddle.position.y = 880.0

	_press_key(KEY_ESCAPE)

	var pause_menu = game.get_node_or_null("PauseMenu")
	assert_not_null(pause_menu)
	assert_eq(game._pause_menu, pause_menu)
	assert_true(get_tree().paused)

	var ball_position: Vector2 = game.ball.position
	var ball_velocity: Vector2 = game.ball.velocity
	var ball_speed: float = game.ball.current_speed
	var left_position: Vector2 = game.left_paddle.position
	var right_position: Vector2 = game.right_paddle.position

	game._physics_process(0.5)

	assert_eq(game.ball.position, ball_position)
	assert_eq(game.ball.velocity, ball_velocity)
	assert_eq(game.ball.current_speed, ball_speed)
	assert_eq(game.left_paddle.position, left_position)
	assert_eq(game.right_paddle.position, right_position)

	pause_menu.select_action(pause_menu.Action.RESUME)

	assert_null(game._pause_menu)
	assert_null(game.get_node_or_null("PauseMenu"))
	assert_false(get_tree().paused)
	assert_eq(game.ball.position, ball_position)
	assert_eq(game.ball.velocity, ball_velocity)
	assert_eq(game.ball.current_speed, ball_speed)
	assert_eq(game.left_paddle.position, left_position)
	assert_eq(game.right_paddle.position, right_position)

	game._physics_process(0.1)
	assert_ne(game.ball.position, ball_position)
	assert_eq(game.ball.velocity, ball_velocity)
	await get_tree().process_frame

func test_p_key_also_opens_the_pause_menu() -> void:
	_press_key(KEY_P)

	assert_not_null(game.get_node_or_null("PauseMenu"))
	assert_true(get_tree().paused)

	game._on_pause_resume_requested()
	await get_tree().process_frame

func test_resume_button_unpauses_and_preserves_the_frozen_state() -> void:
	game.ball.position = Vector2(1400.0, 640.0)
	game.ball.velocity = Vector2(1800.0, -320.0)
	game.ball.current_speed = 1800.0
	game.left_paddle.position.y = 540.0
	game.right_paddle.position.y = 960.0
	_press_key(KEY_ESCAPE)

	var pause_menu = game.get_node_or_null("PauseMenu")
	assert_not_null(pause_menu)
	pause_menu.get_node("BtnResume").pressed.emit()
	pause_menu._process(pause_menu.CLOSE_DURATION)

	assert_false(get_tree().paused)
	assert_null(game._pause_menu)
	assert_eq(game.ball.position, Vector2(1400.0, 640.0))
	assert_eq(game.ball.velocity, Vector2(1800.0, -320.0))
	assert_eq(game.ball.current_speed, 1800.0)
	assert_eq(game.left_paddle.position.y, 540.0)
	assert_eq(game.right_paddle.position.y, 960.0)
	await get_tree().process_frame

func test_restart_action_resets_the_match_and_resumes_the_game() -> void:
	game.left_score = 2
	game.right_score = 1
	game.total_rebounds = 9
	game.debug_hud.record_paddle_hit(true)
	game.ball.current_speed = 3000.0
	game.ball.velocity = Vector2(-3000.0, 0.0)
	game.power_up.appear(game.field_size)
	game.power_up.effect_id = POWER_UP_EFFECT.Id.DOUBLE_SIZE
	game.power_up.collect(true)

	_press_key(KEY_ESCAPE)
	var pause_menu = game.get_node_or_null("PauseMenu")
	assert_not_null(pause_menu)
	pause_menu.select_action(pause_menu.Action.RESTART)

	assert_null(game._pause_menu)
	assert_null(game.get_node_or_null("PauseMenu"))
	assert_false(get_tree().paused)
	assert_false(game.game_over)
	assert_eq(game.left_score, 0)
	assert_eq(game.right_score, 0)
	assert_eq(game.total_rebounds, 0)
	assert_eq(game.ball.current_speed, 1140.0)
	assert_eq(game.ball._paddle_hits, 0)
	assert_eq(game.power_up.status, game.power_up.Status.INACTIVE)
	assert_false(game.left_paddle.power_up_active)
	assert_eq(game.left_paddle.paddle_height, game.left_paddle.base_paddle_height)
	await get_tree().process_frame

func test_settings_menu_opens_from_the_pause_menu_and_keeps_the_match_frozen() -> void:
	game.ball.position = Vector2(1200.0, 700.0)
	game.ball.velocity = Vector2(-2100.0, 480.0)

	_press_key(KEY_ESCAPE)
	var pause_menu = game.get_node_or_null("PauseMenu")
	assert_not_null(pause_menu)
	pause_menu._activate_action(pause_menu.Action.SETTINGS, 2)

	var settings = pause_menu.get_node_or_null("SettingsMenu")
	assert_not_null(settings)
	assert_true(get_tree().paused)

	var ball_position: Vector2 = game.ball.position
	game._physics_process(0.5)
	assert_eq(game.ball.position, ball_position)
	assert_eq(game.ball.velocity, Vector2(-2100.0, 480.0))

	settings.finish_close()
	await get_tree().process_frame

	assert_null(pause_menu.get_node_or_null("SettingsMenu"))
	assert_true(get_tree().paused)
	assert_not_null(game.get_node_or_null("PauseMenu"))

func test_returning_to_main_menu_restores_all_default_match_values() -> void:
	game.left_score = 2
	game.right_score = 1
	game.total_rebounds = 9
	game.debug_hud.record_paddle_hit(true)
	game.debug_hud.record_paddle_hit(false)
	game.ball.current_speed = 3000.0
	game.ball.velocity = Vector2(-3000.0, 0.0)
	game.power_up.appear(game.field_size)
	game.power_up.effect_id = POWER_UP_EFFECT.Id.DOUBLE_SIZE
	game.power_up.collect(true)
	assert_true(game.left_paddle.power_up_active)

	_press_key(KEY_ESCAPE)
	var pause_menu = game.get_node_or_null("PauseMenu")
	assert_not_null(pause_menu)
	pause_menu.select_action(pause_menu.Action.MAIN_MENU)

	assert_null(game._pause_menu)
	assert_null(game.get_node_or_null("PauseMenu"))
	assert_true(game._menu_shown)
	assert_true(get_tree().paused)
	var game_menu = game.get_node_or_null("GameMenu")
	assert_not_null(game_menu)
	assert_true(game_menu.visible)

	assert_eq(game.left_score, 0)
	assert_eq(game.right_score, 0)
	assert_eq(game.total_rebounds, 0)
	assert_eq(game.debug_hud._left_rebounds, 0)
	assert_eq(game.debug_hud._right_rebounds, 0)
	assert_eq(game.power_up.status, game.power_up.Status.INACTIVE)
	assert_eq(game.ball.current_speed, 1140.0)
	assert_eq(game.ball._paddle_hits, 0)
	assert_false(game.left_paddle.power_up_active)
	assert_false(game.right_paddle.power_up_active)
	assert_eq(game.left_paddle.paddle_height, game.left_paddle.base_paddle_height)
	assert_eq(game.right_paddle.paddle_height, game.right_paddle.base_paddle_height)
	assert_eq(game.arena.left_score, 0)
	assert_eq(game.arena.right_score, 0)
	assert_false(game.game_over)

	game_menu.select_mode(GameMode.Mode.PLAYER_VS_AI)

	assert_false(get_tree().paused)
	assert_eq(game._game_mode, GameMode.Mode.PLAYER_VS_AI)
	assert_eq(game.left_paddle.control_mode, Paddle.ControlMode.HUMAN)
	assert_eq(game.right_paddle.control_mode, Paddle.ControlMode.AI)
	assert_eq(game.ball.current_speed, 1140.0)
	assert_eq(game.total_rebounds, 0)
	assert_eq(game.power_up.status, game.power_up.Status.INACTIVE)
	await get_tree().process_frame
