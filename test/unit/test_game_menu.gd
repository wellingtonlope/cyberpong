extends GutTest

const MENU_SCENE := preload("res://scenes/game_menu.tscn")
const DEFAULT_SIZE := Vector2(2880.0, 1620.0)
const WINDOW_SIZES := [
	Vector2(2880.0, 1620.0),
	Vector2(1920.0, 1080.0),
	Vector2(1440.0, 810.0),
	Vector2(1280.0, 720.0),
	Vector2(1000.0, 600.0),
	Vector2(800.0, 600.0),
	Vector2(640.0, 480.0),
	Vector2(480.0, 320.0),
]

var menu

func before_each() -> void:
	get_viewport().size = DEFAULT_SIZE
	menu = add_child_autofree(MENU_SCENE.instantiate())

func after_each() -> void:
	get_tree().paused = false
	get_viewport().size = DEFAULT_SIZE

func test_layout_keeps_all_cards_and_footer_inside_window() -> void:
	for window_size in WINDOW_SIZES:
		var size: Vector2 = window_size
		var layout: Dictionary = menu._layout_for(size)
		var content: Rect2 = layout["content"]
		var header: Rect2 = layout["header"]
		var strip: Rect2 = layout["strip"]
		var cards: Array = layout["cards"]
		var selector_pills: Array = layout["selector_pills"]
		var footer: Rect2 = layout["footer"]

		assert_eq(cards.size(), 4, "Every game mode, settings and the exit action need a card at %s" % size)
		assert_eq(selector_pills.size(), 3, "Every difficulty needs a pill at %s" % size)
		assert_gt(content.size.x, 0.0)
		assert_gte(header.position.y, 0.0)
		assert_gte(header.end.y, header.position.y)
		assert_gt(strip.end.y, header.end.y)
		for pill in selector_pills:
			var pill_rect: Rect2 = pill
			assert_gt(pill_rect.size.x, 0.0)
			assert_gt(pill_rect.size.y, 0.0)
			assert_gte(pill_rect.position.y, strip.end.y)
			assert_lte(pill_rect.end.y, cards[0].position.y)
			assert_gte(pill_rect.position.x, content.position.x)
			assert_lte(pill_rect.end.x, content.end.x)
		assert_gte(cards[0].position.y, strip.end.y)
		assert_gt(footer.end.y, cards[3].end.y)
		assert_lte(footer.end.y, size.y, "Menu footer overflows at %s" % size)
		assert_gte(content.position.x, 0.0)
		assert_lte(content.end.x, size.x)

		var previous_bottom := -1.0
		for card in cards:
			var rect: Rect2 = card
			assert_gt(rect.size.x, 0.0)
			assert_gt(rect.size.y, 0.0)
			assert_gte(rect.position.x, 0.0)
			assert_lte(rect.end.x, size.x)
			assert_gte(rect.position.y, previous_bottom)
			assert_lte(rect.end.y, size.y)
			previous_bottom = rect.end.y

func test_layout_scale_is_clamped_for_huge_and_small_windows() -> void:
	var huge: Dictionary = menu._layout_for(Vector2(7680.0, 4320.0))
	var tiny: Dictionary = menu._layout_for(Vector2(320.0, 240.0))

	assert_eq(huge["scale"], menu.MAX_UI_SCALE)
	assert_eq(tiny["scale"], menu.MIN_UI_SCALE)

func test_mode_cards_map_to_expected_game_modes() -> void:
	var expected_modes := [
		GameMode.Mode.PLAYER_VS_PLAYER,
		GameMode.Mode.PLAYER_VS_AI,
	]
	assert_eq(menu.MODE_CARDS.size(), expected_modes.size())
	for index in range(menu.MODE_CARDS.size()):
		assert_eq(menu.MODE_CARDS[index]["mode"], expected_modes[index])

func test_difficulty_selector_starts_on_normal_and_hidden() -> void:
	assert_eq(menu.selected_difficulty, Difficulty.Level.NORMAL)
	assert_eq(
		menu._selector_selected_index,
		Difficulty.index_of(Difficulty.Level.NORMAL)
	)
	assert_eq(menu._selector_rects.size(), 3)
	assert_false(menu._selector_visible)

func test_difficulty_pills_map_to_the_expected_levels() -> void:
	menu._on_card_focused(1)
	var buttons := [menu.get_node("BtnEasy"), menu.get_node("BtnNormal"), menu.get_node("BtnHard")]
	for index in range(buttons.size()):
		buttons[index].pressed.emit()
		assert_eq(menu.selected_difficulty, Difficulty.level_at(index))
		assert_false(menu._closing)
		assert_false(menu._selected)

func test_choosing_a_difficulty_does_not_start_the_match() -> void:
	menu._on_card_focused(1)
	var emitted: Array = []
	menu.mode_selected.connect(
		func(mode: int, difficulty: int) -> void: emitted.append([mode, difficulty])
	)

	menu.get_node("BtnHard").pressed.emit()

	assert_eq(menu.selected_difficulty, Difficulty.Level.HARD)
	assert_true(emitted.is_empty())
	assert_true(menu.visible)

func test_mode_selection_emits_the_chosen_difficulty() -> void:
	menu._on_card_focused(1)
	menu.get_node("BtnEasy").pressed.emit()
	var emitted: Array = []
	menu.mode_selected.connect(
		func(mode: int, difficulty: int) -> void: emitted.append([mode, difficulty])
	)

	menu.select_mode(GameMode.Mode.PLAYER_VS_AI)

	assert_eq(emitted, [[GameMode.Mode.PLAYER_VS_AI, Difficulty.Level.EASY]])

func test_difficulty_selector_only_appears_for_player_vs_ai() -> void:
	var pvp: Button = menu.get_node("BtnPvP")
	var pvai: Button = menu.get_node("BtnPvAI")
	var settings: Button = menu.get_node("BtnSettings")
	var quit: Button = menu.get_node("BtnQuit")
	var pills := [menu.get_node("BtnEasy"), menu.get_node("BtnNormal"), menu.get_node("BtnHard")]

	pvp.grab_focus()
	assert_false(menu._selector_visible)
	for pill in pills:
		assert_false(pill.visible)

	pvai.grab_focus()
	assert_true(menu._selector_visible)
	for pill in pills:
		assert_true(pill.visible)

	settings.grab_focus()
	assert_false(menu._selector_visible)
	for pill in pills:
		assert_false(pill.visible)

	quit.grab_focus()
	assert_false(menu._selector_visible)
	for pill in pills:
		assert_false(pill.visible)

func test_arrow_keys_cycle_difficulty_only_when_player_vs_ai_is_focused() -> void:
	var pvp: Button = menu.get_node("BtnPvP")
	var pvai: Button = menu.get_node("BtnPvAI")

	pvp.grab_focus()
	menu._input(_arrow_event(KEY_RIGHT))
	assert_eq(menu.selected_difficulty, Difficulty.Level.NORMAL)

	pvai.grab_focus()
	menu._input(_arrow_event(KEY_RIGHT))
	assert_eq(menu.selected_difficulty, Difficulty.Level.HARD)
	menu._input(_arrow_event(KEY_RIGHT))
	assert_eq(menu.selected_difficulty, Difficulty.Level.EASY)
	menu._input(_arrow_event(KEY_LEFT))
	assert_eq(menu.selected_difficulty, Difficulty.Level.HARD)

func test_focus_neighbors_cycle_through_all_cards() -> void:
	var pvp: Button = menu.get_node("BtnPvP")
	var pvai: Button = menu.get_node("BtnPvAI")
	var settings: Button = menu.get_node("BtnSettings")
	var quit: Button = menu.get_node("BtnQuit")

	assert_eq(pvp.focus_neighbor_top, quit.get_path())
	assert_eq(pvp.focus_neighbor_bottom, pvai.get_path())
	assert_eq(pvai.focus_neighbor_top, pvp.get_path())
	assert_eq(pvai.focus_neighbor_bottom, settings.get_path())
	assert_eq(settings.focus_neighbor_top, pvai.get_path())
	assert_eq(settings.focus_neighbor_bottom, quit.get_path())
	assert_eq(quit.focus_neighbor_top, settings.get_path())
	assert_eq(quit.focus_neighbor_bottom, pvp.get_path())

func test_card_focus_moves_the_ball_cursor_target() -> void:
	menu._on_card_focused(2)

	assert_eq(menu._focused_index, 2)
	assert_eq(menu._cursor_target_y, menu._card_rects[2].get_center().y)

func test_first_card_can_receive_keyboard_focus() -> void:
	var pvp: Button = menu.get_node("BtnPvP")
	pvp.grab_focus()

	assert_true(pvp.has_focus())
	assert_eq(menu._focused_index, 0)

func test_select_emits_mode_and_resumes_the_paused_tree() -> void:
	assert_true(get_tree().paused)
	var emitted_modes: Array = []
	menu.mode_selected.connect(func(mode: int, _difficulty: int) -> void: emitted_modes.append(mode))

	menu.select_mode(GameMode.Mode.PLAYER_VS_AI)

	assert_eq(emitted_modes, [GameMode.Mode.PLAYER_VS_AI])
	assert_false(menu.visible)
	assert_false(menu.is_processing())
	assert_false(get_tree().paused)
	assert_true(menu._selected)

func test_select_ignores_a_second_choice() -> void:
	var emitted_modes: Array = []
	menu.mode_selected.connect(func(mode: int, _difficulty: int) -> void: emitted_modes.append(mode))

	menu.select_mode(GameMode.Mode.PLAYER_VS_PLAYER)
	menu.select_mode(GameMode.Mode.PLAYER_VS_AI)

	assert_eq(emitted_modes, [GameMode.Mode.PLAYER_VS_PLAYER])

func test_activate_waits_for_the_close_transition_before_selecting() -> void:
	var emitted_modes: Array = []
	menu.mode_selected.connect(func(mode: int, _difficulty: int) -> void: emitted_modes.append(mode))

	menu._activate(GameMode.Mode.PLAYER_VS_AI, 1)
	assert_true(menu._closing)
	assert_false(menu._selected)

	menu._process(menu.CLOSE_DURATION * 0.5)
	assert_false(menu._selected)
	assert_true(emitted_modes.is_empty())

	menu._process(menu.CLOSE_DURATION)
	assert_true(menu._selected)
	assert_eq(emitted_modes, [GameMode.Mode.PLAYER_VS_AI])

func test_focus_brackets_point_inward_at_every_corner() -> void:
	var rect := Rect2(100.0, 100.0, 200.0, 60.0)
	var segments: Array = menu._focus_bracket_segments(rect, 8.0, 2.0)

	assert_eq(segments.size(), 8)
	assert_eq(segments[1][0], Vector2(118.0, 110.0))
	assert_eq(segments[1][1], Vector2(118.0, 130.0))
	assert_eq(segments[3][0], Vector2(118.0, 150.0))
	assert_eq(segments[3][1], Vector2(118.0, 130.0))
	assert_eq(segments[5][0], Vector2(282.0, 110.0))
	assert_eq(segments[5][1], Vector2(282.0, 130.0))
	assert_eq(segments[7][0], Vector2(282.0, 150.0))
	assert_eq(segments[7][1], Vector2(282.0, 130.0))

func test_button_press_starts_the_same_selection_flow() -> void:
	var emitted_modes: Array = []
	menu.mode_selected.connect(func(mode: int, _difficulty: int) -> void: emitted_modes.append(mode))

	menu.get_node("BtnPvP").pressed.emit()
	assert_true(menu._closing)

	menu._process(menu.CLOSE_DURATION)
	assert_eq(emitted_modes, [GameMode.Mode.PLAYER_VS_PLAYER])

func test_exit_card_is_the_last_item_and_requests_to_quit() -> void:
	assert_eq(menu._cards.size(), 4)
	assert_eq(menu._cards[menu.EXIT_CARD_INDEX], menu.EXIT_CARD)
	assert_eq(menu.EXIT_CARD["title"], "SAIR")

func test_settings_card_opens_the_settings_menu_without_starting_the_match() -> void:
	var emitted: Array = []
	menu.mode_selected.connect(
		func(mode: int, difficulty: int) -> void: emitted.append([mode, difficulty])
	)

	menu._activate_card(menu.SETTINGS_CARD_INDEX)

	var settings = menu.get_node_or_null("SettingsMenu")
	assert_not_null(settings)
	assert_false(menu._closing)
	assert_false(menu._selected)
	assert_true(get_tree().paused)
	assert_true(emitted.is_empty())
	assert_true(menu.btn_pvp.disabled)
	assert_true(menu.btn_pvai.disabled)
	assert_true(menu.btn_settings.disabled)
	assert_true(menu.btn_quit.disabled)
	assert_false(menu._selector_visible)

func test_closing_the_settings_menu_restores_the_main_menu_cards() -> void:
	menu.get_node("BtnPvAI").grab_focus()
	menu._activate_card(menu.SETTINGS_CARD_INDEX)
	var settings = menu.get_node_or_null("SettingsMenu")
	assert_not_null(settings)

	settings.finish_close()

	assert_null(menu.get_node_or_null("SettingsMenu"))
	assert_false(menu.btn_pvp.disabled)
	assert_false(menu.btn_pvai.disabled)
	assert_false(menu.btn_settings.disabled)
	assert_false(menu.btn_quit.disabled)
	assert_true(get_tree().paused)
	assert_true(menu.btn_pvai.has_focus())
	assert_true(menu._selector_visible)

func test_exit_card_waits_for_the_close_transition_before_requesting_quit() -> void:
	var emitted: Array = []
	menu.quit_requested.connect(func() -> void: emitted.append("quit"))

	menu.get_node("BtnQuit").pressed.emit()
	assert_true(menu._closing)
	assert_false(menu._selected)

	menu._process(menu.CLOSE_DURATION * 0.5)
	assert_false(menu._selected)
	assert_true(emitted.is_empty())

	menu._process(menu.CLOSE_DURATION)
	assert_true(menu._selected)
	assert_false(menu.visible)
	assert_false(menu.is_processing())
	assert_false(get_tree().paused)
	assert_eq(emitted, ["quit"])

func test_exit_ignores_a_second_choice_while_closing() -> void:
	var emitted: Array = []
	menu.quit_requested.connect(func() -> void: emitted.append("quit"))
	menu.mode_selected.connect(func(_mode: int, _difficulty: int) -> void: emitted.append("mode"))

	menu._activate_card(menu.EXIT_CARD_INDEX)
	menu._activate_card(0)
	menu._process(menu.CLOSE_DURATION)

	assert_eq(emitted, ["quit"])

func _arrow_event(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = keycode
	return event
