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

func test_menu_opens_paused_and_starts_the_match_after_a_choice() -> void:
	var menu = game.get_node_or_null("GameMenu")
	assert_not_null(menu)
	assert_true(menu is Control)
	assert_true(menu.visible)
	assert_true(get_tree().paused)
	assert_eq(game._game_mode, game.GameMode.AI_VS_AI)

	menu.get_node("BtnPvP").pressed.emit()
	menu._process(menu.CLOSE_DURATION)

	assert_false(get_tree().paused)
	assert_false(menu.visible)
	assert_eq(game._game_mode, game.GameMode.PLAYER_VS_PLAYER)
	assert_eq(game.left_paddle.control_mode, 1)
	assert_eq(game.right_paddle.control_mode, 1)
	assert_eq(game.ball.current_speed, 1140.0)

func test_ai_mode_selection_keeps_both_paddles_automatic() -> void:
	var menu = game.get_node_or_null("GameMenu")
	assert_not_null(menu)

	menu.get_node("BtnAIvAI").pressed.emit()
	menu._process(menu.CLOSE_DURATION)

	assert_false(get_tree().paused)
	assert_eq(game._game_mode, game.GameMode.AI_VS_AI)
	assert_eq(game.left_paddle.control_mode, 0)
	assert_eq(game.right_paddle.control_mode, 0)
	assert_true(game.arena.rally_intro_remaining > 0.0)
