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
		var footer: Rect2 = layout["footer"]

		assert_eq(cards.size(), 3, "Every game mode needs a card at %s" % size)
		assert_gt(content.size.x, 0.0)
		assert_gte(header.position.y, 0.0)
		assert_gte(header.end.y, header.position.y)
		assert_gt(strip.end.y, header.end.y)
		assert_gte(cards[0].position.y, strip.end.y)
		assert_gt(footer.end.y, cards[2].end.y)
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
		menu.GameMode.PLAYER_VS_PLAYER,
		menu.GameMode.PLAYER_VS_AI,
		menu.GameMode.AI_VS_AI,
	]
	for index in range(menu.MODE_CARDS.size()):
		assert_eq(menu.MODE_CARDS[index]["mode"], expected_modes[index])

func test_focus_neighbors_cycle_through_the_three_cards() -> void:
	var pvp: Button = menu.get_node("BtnPvP")
	var pvai: Button = menu.get_node("BtnPvAI")
	var aivai: Button = menu.get_node("BtnAIvAI")

	assert_eq(pvp.focus_neighbor_top, aivai.get_path())
	assert_eq(pvp.focus_neighbor_bottom, pvai.get_path())
	assert_eq(pvai.focus_neighbor_top, pvp.get_path())
	assert_eq(pvai.focus_neighbor_bottom, aivai.get_path())
	assert_eq(aivai.focus_neighbor_top, pvai.get_path())
	assert_eq(aivai.focus_neighbor_bottom, pvp.get_path())

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
	menu.mode_selected.connect(func(mode: int) -> void: emitted_modes.append(mode))

	menu._select(menu.GameMode.PLAYER_VS_AI)

	assert_eq(emitted_modes, [menu.GameMode.PLAYER_VS_AI])
	assert_false(menu.visible)
	assert_false(menu.is_processing())
	assert_false(get_tree().paused)
	assert_true(menu._selected)

func test_select_ignores_a_second_choice() -> void:
	var emitted_modes: Array = []
	menu.mode_selected.connect(func(mode: int) -> void: emitted_modes.append(mode))

	menu._select(menu.GameMode.PLAYER_VS_PLAYER)
	menu._select(menu.GameMode.AI_VS_AI)

	assert_eq(emitted_modes, [menu.GameMode.PLAYER_VS_PLAYER])

func test_activate_waits_for_the_close_transition_before_selecting() -> void:
	var emitted_modes: Array = []
	menu.mode_selected.connect(func(mode: int) -> void: emitted_modes.append(mode))

	menu._activate(menu.GameMode.AI_VS_AI, 2)
	assert_true(menu._closing)
	assert_false(menu._selected)

	menu._process(menu.CLOSE_DURATION * 0.5)
	assert_false(menu._selected)
	assert_true(emitted_modes.is_empty())

	menu._process(menu.CLOSE_DURATION)
	assert_true(menu._selected)
	assert_eq(emitted_modes, [menu.GameMode.AI_VS_AI])

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
	menu.mode_selected.connect(func(mode: int) -> void: emitted_modes.append(mode))

	menu.get_node("BtnPvP").pressed.emit()
	assert_true(menu._closing)

	menu._process(menu.CLOSE_DURATION)
	assert_eq(emitted_modes, [menu.GameMode.PLAYER_VS_PLAYER])
