extends GutTest

const ARENA_SCRIPT := preload("res://scripts/arena.gd")

var arena

func before_each() -> void:
	arena = add_child_autofree(ARENA_SCRIPT.new())
	arena.configure(3.0, 180.0, 120.0)

func test_configure_stores_the_scale_and_the_field_limits() -> void:
	assert_eq(arena.game_scale, 3.0)
	assert_eq(arena.hud_bar_height, 180.0)
	assert_eq(arena.paddle_margin, 120.0)

func test_set_score_updates_the_placar_and_the_match_point() -> void:
	arena.set_score(2, 1, 3)
	assert_eq(arena.left_score, 2)
	assert_eq(arena.right_score, 1)
	assert_true(arena.left_match_point)
	assert_false(arena.right_match_point)

func test_match_point_tracks_every_team_at_the_winning_threshold() -> void:
	arena.set_score(2, 1, 3)
	assert_true(arena.left_match_point)
	assert_false(arena.right_match_point)

	arena.set_score(2, 2, 3)
	assert_true(arena.left_match_point)
	assert_true(arena.right_match_point)

	arena.set_score(3, 2, 3)
	assert_false(arena.left_match_point)
	assert_false(arena.right_match_point)

func test_set_game_over_clears_the_winner_and_the_match_point() -> void:
	arena.set_score(2, 1, 3)
	arena.set_winner(true)
	arena.set_game_over(false)

	assert_eq(arena.winner_name, "")
	assert_false(arena.game_over)
	assert_true(arena.left_match_point)

func test_set_winner_uses_the_palette_for_the_name_and_the_side() -> void:
	arena.set_winner(true)
	assert_eq(arena.winner_name, Palette.LEFT_TEAM_NAME)
	assert_true(arena.winner_is_left)

	arena.set_winner(false)
	assert_eq(arena.winner_name, Palette.RIGHT_TEAM_NAME)
	assert_false(arena.winner_is_left)

func test_set_match_hud_copies_the_power_up_information() -> void:
	var info := PowerUpHudInfo.new("Raquete dobrada", "detalhe", 0.5, Color.RED, true)
	arena.set_match_hud(12, info)

	assert_eq(arena.total_rebounds, 12)
	assert_eq(arena.power_up_hud_title, "Raquete dobrada")
	assert_eq(arena.power_up_hud_detail, "detalhe")
	assert_almost_eq(arena.power_up_hud_progress, 0.5, 0.001)
	assert_eq(arena.power_up_hud_accent, Color.RED)
	assert_true(arena.power_up_hud_show_progress)

func test_point_flash_and_rally_intro_expire() -> void:
	arena.show_point_awarded(false)
	assert_true(arena.point_flash_is_left == false)
	assert_gt(arena.point_flash_remaining, 0.0)

	arena.show_rally_intro(false)
	assert_true(arena.rally_intro_is_left == false)
	assert_gt(arena.rally_intro_remaining, 0.0)

	arena._process(2.0)
	assert_eq(arena.point_flash_remaining, 0.0)
	assert_eq(arena.rally_intro_remaining, 0.0)

func test_winner_panel_emits_the_new_match_request() -> void:
	var emitted: Array = []
	arena.new_match_requested.connect(func() -> void: emitted.append("new_match"))
	arena.set_winner(true)
	arena.winner_reveal = 1.0

	var position: Vector2 = arena._winner_action_position(arena.WINNER_ACTION_NEW_MATCH)
	_click_at(position)

	assert_eq(emitted, ["new_match"])

func test_winner_panel_emits_the_main_menu_request() -> void:
	var emitted: Array = []
	arena.main_menu_requested.connect(func() -> void: emitted.append("main_menu"))
	arena.set_winner(true)
	arena.winner_reveal = 1.0

	var position: Vector2 = arena._winner_action_position(arena.WINNER_ACTION_MAIN_MENU)
	_click_at(position)

	assert_eq(emitted, ["main_menu"])

func test_winner_panel_ignores_clicks_outside_the_actions() -> void:
	var emitted: Array = []
	arena.new_match_requested.connect(func() -> void: emitted.append("new_match"))
	arena.main_menu_requested.connect(func() -> void: emitted.append("main_menu"))
	arena.set_winner(true)
	arena.winner_reveal = 1.0

	_click_at(Vector2(5.0, 5.0))

	assert_eq(emitted, [])

func test_winner_actions_are_ignored_before_the_match_ends() -> void:
	var emitted: Array = []
	arena.new_match_requested.connect(func() -> void: emitted.append("new_match"))
	arena.set_score(1, 0, 3)

	_click_at(Vector2(5.0, 5.0))

	assert_eq(emitted, [])

func _click_at(local_position: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.pressed = true
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = local_position
	arena._unhandled_input(event)
