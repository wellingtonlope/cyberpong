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

func after_each() -> void:
	get_tree().paused = false
	get_viewport().size = FIELD_SIZE

func test_menu_opens_paused_and_starts_the_match_after_a_choice() -> void:
	var menu = game.get_node_or_null("GameMenu")
	assert_not_null(menu)
	assert_true(menu is Control)
	assert_true(menu.visible)
	assert_true(get_tree().paused)
	assert_eq(game._game_mode, game.GameMode.PLAYER_VS_AI)

	menu.get_node("BtnPvP").pressed.emit()
	menu._process(menu.CLOSE_DURATION)

	assert_false(get_tree().paused)
	assert_false(menu.visible)
	assert_eq(game._game_mode, game.GameMode.PLAYER_VS_PLAYER)
	assert_eq(game.left_paddle.control_mode, 1)
	assert_eq(game.right_paddle.control_mode, 1)
	assert_eq(game.ball.current_speed, 1140.0)

func test_player_vs_ai_selection_keeps_one_human_and_one_automatic_paddle() -> void:
	var menu = game.get_node_or_null("GameMenu")
	assert_not_null(menu)

	menu.get_node("BtnPvAI").pressed.emit()
	menu._process(menu.CLOSE_DURATION)

	assert_false(get_tree().paused)
	assert_eq(game._game_mode, game.GameMode.PLAYER_VS_AI)
	assert_eq(game.left_paddle.control_mode, 1)
	assert_eq(game.right_paddle.control_mode, 0)
	assert_true(game.arena.rally_intro_remaining > 0.0)

func test_player_vs_ai_uses_the_normal_difficulty_by_default() -> void:
	var menu = game.get_node_or_null("GameMenu")
	assert_not_null(menu)

	menu.get_node("BtnPvAI").grab_focus()
	menu.get_node("BtnPvAI").pressed.emit()
	menu._process(menu.CLOSE_DURATION)

	assert_eq(game._difficulty, game.Difficulty.Level.NORMAL)
	assert_eq(game.right_paddle.ai_speed_factor, 0.82)
	assert_eq(game.right_paddle.ai_reaction_delay, 0.14)
	assert_eq(game.right_paddle.ai_dead_zone, 24.0)

func test_selected_difficulty_is_applied_to_the_ai_paddle() -> void:
	var menu = game.get_node_or_null("GameMenu")
	assert_not_null(menu)

	menu.get_node("BtnPvAI").grab_focus()
	menu.get_node("BtnHard").pressed.emit()
	menu.get_node("BtnPvAI").pressed.emit()
	menu._process(menu.CLOSE_DURATION)

	assert_eq(game._difficulty, game.Difficulty.Level.HARD)
	assert_eq(game.right_paddle.ai_speed_factor, 1.0)
	assert_eq(game.right_paddle.ai_reaction_delay, 0.04)
	assert_eq(game.right_paddle.ai_dead_zone, 12.0)

func test_difficulty_persists_when_returning_to_the_main_menu() -> void:
	var menu = game.get_node_or_null("GameMenu")
	assert_not_null(menu)

	menu.get_node("BtnPvAI").grab_focus()
	menu.get_node("BtnHard").pressed.emit()
	menu.get_node("BtnPvAI").pressed.emit()
	menu._process(menu.CLOSE_DURATION)
	game._show_menu()

	var reopened_menu = game.get_node_or_null("GameMenu")
	assert_not_null(reopened_menu)
	assert_eq(reopened_menu.selected_difficulty, game.Difficulty.Level.HARD)
	assert_eq(
		reopened_menu._selector_selected_index,
		game.Difficulty.index_of(game.Difficulty.Level.HARD)
	)
	assert_false(reopened_menu._selector_visible)

func test_quit_card_signal_is_connected_to_the_game_shutdown() -> void:
	var menu = game.get_node_or_null("GameMenu")
	assert_not_null(menu)

	assert_true(menu.quit_requested.is_connected(game._on_quit_requested))
