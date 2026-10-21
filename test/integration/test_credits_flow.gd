extends GutTest

const MAIN_SCENE := preload("res://main.tscn")
const FIELD_SIZE := Vector2(2880.0, 1620.0)

var game

func before_each() -> void:
	get_viewport().size = FIELD_SIZE
	game = add_child_autofree(MAIN_SCENE.instantiate())

func after_each() -> void:
	get_tree().paused = false
	get_viewport().size = FIELD_SIZE

func _finish_credits() -> void:
	var credits = game.get_node_or_null("CreditsScreen")
	assert_not_null(credits)
	credits.skip()
	credits._process(credits.SKIP_FADE_OUT_DURATION)

func test_game_starts_with_the_credits_screen_instead_of_the_menu() -> void:
	var credits = game.get_node_or_null("CreditsScreen")

	assert_not_null(credits, "A partida deve comecar pelos creditos")
	assert_null(game.get_node_or_null("GameMenu"))
	assert_true(credits.visible)
	assert_eq(credits.get_display_name(), "Moron Souls Productions")
	assert_eq(credits.background.color, Color.BLACK)
	assert_true(game._menu_shown)
	assert_true(get_tree().paused)

func test_credits_hand_off_to_the_menu_and_the_match_can_start() -> void:
	_finish_credits()

	assert_null(game.get_node_or_null("CreditsScreen"))
	var menu = game.get_node_or_null("GameMenu")
	assert_not_null(menu)
	assert_true(menu.visible)
	assert_true(get_tree().paused)

	menu.get_node("BtnPvAI").pressed.emit()
	menu._process(menu.CLOSE_DURATION)

	assert_false(get_tree().paused)
	assert_eq(game._game_mode, GameMode.Mode.PLAYER_VS_AI)
	assert_eq(game.left_paddle.control_mode, Paddle.ControlMode.HUMAN)
	assert_eq(game.right_paddle.control_mode, Paddle.ControlMode.AI)
	assert_eq(game.ball.current_speed, 1140.0)

func test_keys_during_the_credits_do_not_reach_the_match() -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = KEY_F3

	game._unhandled_key_input(event)

	assert_false(game.debug_hud._panel.visible)
	assert_not_null(game.get_node_or_null("CreditsScreen"))

func test_returning_to_the_menu_does_not_replay_the_credits() -> void:
	_finish_credits()
	var menu = game.get_node_or_null("GameMenu")
	menu.select_mode(GameMode.Mode.PLAYER_VS_AI)

	game._open_pause_menu()
	game._on_pause_main_menu_requested()

	assert_null(game.get_node_or_null("CreditsScreen"))
	assert_not_null(game.get_node_or_null("GameMenu"))
	assert_true(get_tree().paused)
	assert_eq(game.total_rebounds, 0)
	assert_false(game.game_over)
