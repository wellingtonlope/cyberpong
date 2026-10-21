extends GutTest

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
	menu._select(game.GameMode.PLAYER_VS_AI)
	game.game_over = true

func test_main_scene_initializes_expected_nodes_and_first_serve() -> void:
	for node_path in ["Arena", "Paddles/Left", "Paddles/Right", "Ball", "PowerUp", "SparkEffects", "DebugHud"]:
		assert_true(is_instance_valid(game.get_node_or_null(node_path)), "Missing scene node: %s" % node_path)

	assert_true(game.ball.paddle_hit.is_connected(Callable(game, "_on_ball_paddle_hit")))
	assert_true(game.ball.missed.is_connected(Callable(game, "_on_ball_missed")))
	assert_eq(game.ball.current_speed, 1140.0)
	assert_eq(game.total_rebounds, 0)
	assert_false(game.debug_hud._panel.visible)
	assert_eq(game.arena.rally_intro_remaining, game.arena.RALLY_INTRO_DURATION)
	assert_true(game.arena.rally_intro_is_left)

func test_rebounds_persist_between_points_and_later_rally_uses_second_speed() -> void:
	game.ball.paddle_hit.emit(true, Vector2(100.0, 300.0), 1.0, 1.0, false)
	game._on_ball_missed(false)

	assert_eq(game.left_score, 1)
	assert_eq(game.total_rebounds, 1)
	assert_eq(game.debug_hud._left_rebounds, 1)
	assert_eq(game.ball.current_speed, 1500.0)
	assert_eq(game.ball._paddle_hits, 0)

func test_three_points_end_match_and_enter_starts_new_match() -> void:
	for _index in range(3):
		game._on_ball_missed(true)

	assert_true(game.game_over)
	assert_eq(game.right_score, 3)
	assert_eq(game.arena.winner_name, "Magenta Volt")

	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = KEY_ENTER
	game._unhandled_key_input(event)

	assert_false(game.game_over)
	assert_eq(game.left_score, 0)
	assert_eq(game.right_score, 0)
	assert_eq(game.ball.current_speed, 1140.0)

func test_left_side_can_also_win_at_three_points() -> void:
	for _index in range(3):
		game._on_ball_missed(false)

	assert_true(game.game_over)
	assert_eq(game.left_score, 3)
	assert_eq(game.arena.winner_name, "Cyan Circuit")

func test_m_returns_to_main_menu_after_victory() -> void:
	game._restart_match()
	for _index in range(3):
		game._on_ball_missed(true)
	assert_true(game.game_over)

	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = KEY_M
	game._unhandled_key_input(event)

	assert_false(game.game_over)
	assert_true(game._menu_shown)
	assert_true(get_tree().paused)
	assert_eq(game.left_score, 0)
	assert_eq(game.right_score, 0)
	var menu = game.get_node_or_null("GameMenu")
	assert_not_null(menu)
	assert_true(menu.visible)

func test_m_does_not_open_menu_during_an_active_match() -> void:
	game._restart_match()
	assert_false(game.game_over)

	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = KEY_M
	game._unhandled_key_input(event)

	assert_false(game._menu_shown)
	var menu = game.get_node_or_null("GameMenu")
	assert_not_null(menu)
	assert_false(menu.visible)

func test_scoring_point_briefly_highlights_scoring_team() -> void:
	game._on_ball_missed(true)

	assert_false(game.arena.point_flash_is_left)
	assert_eq(game.arena.point_flash_remaining, game.arena.POINT_FLASH_DURATION)
	assert_false(game.arena.rally_intro_is_left)
	assert_eq(game.arena.rally_intro_remaining, game.arena.RALLY_INTRO_DURATION)
	game.arena._process(0.2)
	assert_gt(game.arena.point_flash_remaining, 0.0)
	assert_lt(game.arena.point_flash_remaining, game.arena.POINT_FLASH_DURATION)
	assert_lt(game.arena.rally_intro_remaining, game.arena.RALLY_INTRO_DURATION)

	game._on_ball_missed(false)
	assert_true(game.arena.point_flash_is_left)
	assert_eq(game.arena.point_flash_remaining, game.arena.POINT_FLASH_DURATION)
	assert_true(game.arena.rally_intro_is_left)

	game.arena._process(game.arena.POINT_FLASH_DURATION)
	assert_eq(game.arena.point_flash_remaining, 0.0)

	game._on_ball_missed(false)
	game._restart_match()
	assert_eq(game.arena.point_flash_remaining, 0.0)
	assert_eq(game.arena.rally_intro_remaining, game.arena.RALLY_INTRO_DURATION)

func test_winning_point_clears_serve_intro_and_reveals_victory_panel() -> void:
	game.arena.show_rally_intro(true)
	game.arena._process(0.4)
	assert_gt(game.arena.rally_intro_remaining, 0.0)

	for _index in range(3):
		game._on_ball_missed(true)

	assert_true(game.game_over)
	assert_eq(game.arena.rally_intro_remaining, 0.0)
	assert_eq(game.arena.point_flash_remaining, 0.0)
	assert_eq(game.arena.winner_reveal, 0.0)

	game.arena._process(game.arena.WINNER_REVEAL_DURATION * 0.5)
	assert_gt(game.arena.winner_reveal, 0.0)
	assert_lt(game.arena.winner_reveal, 1.0)

	game.arena._process(game.arena.WINNER_REVEAL_DURATION)
	assert_eq(game.arena.winner_reveal, 1.0)

	game._restart_match()
	assert_eq(game.arena.winner_reveal, 0.0)
	assert_eq(game.arena.rally_intro_remaining, game.arena.RALLY_INTRO_DURATION)

func test_new_match_resets_rebound_counts_and_debug_hud() -> void:
	game.ball.paddle_hit.emit(true, Vector2(100.0, 300.0), 1.0, 1.0, false)
	game.ball.paddle_hit.emit(false, Vector2(900.0, 300.0), -1.0, 1.0, false)
	game._restart_match()

	assert_eq(game.total_rebounds, 0)
	assert_eq(game.debug_hud._left_rebounds, 0)
	assert_eq(game.debug_hud._right_rebounds, 0)
	assert_eq(game.arena.total_rebounds, 0)

func test_power_up_signal_updates_owner_paddle_and_match_hud() -> void:
	game.power_up.appear(game.field_size)
	game.power_up.effect_id = "double_size"
	game.power_up.collect(true)

	assert_eq(game.left_paddle.paddle_height, game.left_paddle.base_paddle_height * 2.0)
	assert_eq(game.right_paddle.paddle_height, game.right_paddle.base_paddle_height)
	assert_eq(game.arena.power_up_hud_title, "Raquete dobrada")
	assert_true(game.arena.power_up_hud_show_progress)

func test_ball_collection_signal_assigns_power_up_to_last_hitter() -> void:
	game.power_up.appear(game.field_size)
	game.power_up.effect_id = "double_size"
	game.ball.power_up_collected.emit(false)

	assert_false(game.power_up.owner_is_left)
	assert_true(game.right_paddle.power_up_active)
	assert_false(game.left_paddle.power_up_active)

func test_extra_defense_save_counts_as_a_rebound_and_consumes_effect() -> void:
	game.power_up.appear(game.field_size)
	game.power_up.effect_id = "extra_defense"
	game.power_up.collect(true)
	game.ball.position = Vector2(0.0, game.left_paddle.position.y)
	game.ball.velocity = Vector2(-100.0, 0.0)

	game.ball.advance(
		0.0,
		game.left_paddle.get_collision_rect(),
		game.right_paddle.get_collision_rect(),
		Vector2.ZERO,
		0.0,
		game.power_up.get_active_effect_id(),
		game.power_up.get_active_owner_is_left()
	)

	assert_eq(game.total_rebounds, 1)
	assert_eq(game.power_up.get_active_effect_id(), "")
	assert_false(game.left_paddle.power_up_active)
	assert_gt(float(game.ball.velocity.x), float(0.0))

func test_scoring_point_clears_available_power_up_from_field() -> void:
	game.power_up.appear(game.field_size)
	assert_true(game.power_up.is_available())

	game._on_ball_missed(true)

	assert_false(game.power_up.is_available())
	assert_false(game.power_up.visible)
	assert_eq(game.power_up.hits_remaining, 0)
	assert_eq(game.arena.power_up_hud_title, "Próximo power-up")

func test_due_power_up_appears_when_previous_effect_expires() -> void:
	game._next_power_up_rebound = 0
	game.power_up.appear(game.field_size)
	game.power_up.effect_id = "double_size"
	game.power_up.collect(true)
	game.power_up.hits_remaining = 1

	game._on_ball_paddle_hit(false, Vector2(100.0, 300.0), 1.0, 1.0, false)

	assert_eq(game.power_up.status, 1)
	assert_eq(game.power_up.hits_remaining, 5)
	assert_eq(game.total_rebounds, 1)

func test_power_up_spawn_interval_is_between_five_and_fifteen_rebounds() -> void:
	game.total_rebounds = 100
	game._schedule_next_power_up_spawn()

	assert_between(float(game._next_power_up_rebound - game.total_rebounds), float(5), float(15))

func test_f3_toggles_debug_hud_through_main_input_handler() -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = KEY_F3
	game._unhandled_key_input(event)
	assert_true(game.debug_hud._panel.visible)
	game._unhandled_key_input(event)
	assert_false(game.debug_hud._panel.visible)

func test_hud_scale_keeps_interface_compact_on_narrow_windows() -> void:
	assert_almost_eq(float(game.arena._hud_scale_for(FIELD_SIZE)), float(3.0), float(0.01))
	assert_almost_eq(float(game.arena._hud_scale_for(Vector2(1440.0, 810.0))), float(1.5), float(0.01))
	assert_almost_eq(float(game.arena._hud_scale_for(Vector2(960.0, 540.0))), float(1.0), float(0.01))
	assert_gte(float(game.arena._hud_scale_for(Vector2(480.0, 270.0))), float(0.55))
	assert_lte(float(game.arena._hud_scale_for(FIELD_SIZE)), float(3.0))

func test_viewport_resize_keeps_entities_inside_play_area() -> void:
	game.game_over = false
	game.power_up.appear(game.field_size)
	game.power_up.position = FIELD_SIZE - Vector2.ONE * 2.0
	get_viewport().size = Vector2(1000.0, 600.0)
	game._physics_process(0.016)

	assert_eq(game.field_size, Vector2(1000.0, 600.0))
	assert_gte(float(game.ball.position.y - game.ball.radius), float(180.0))
	assert_lte(float(game.ball.position.y + game.ball.radius), float(600.0))
	for paddle in [game.left_paddle, game.right_paddle]:
		assert_gte(float(paddle.position.y - paddle.paddle_height * 0.5), float(180.0))
		assert_lte(float(paddle.position.y + paddle.paddle_height * 0.5), float(600.0))
	assert_between(float(game.power_up.position.x), float(game.power_up.collision_radius), float(1000.0 - game.power_up.collision_radius))
	assert_between(float(game.power_up.position.y), float(180.0 + game.power_up.collision_radius), float(600.0 - game.power_up.collision_radius))
