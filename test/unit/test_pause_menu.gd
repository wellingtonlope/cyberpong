extends GutTest

const PAUSE_SCENE := preload("res://scenes/pause_menu.tscn")
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
	menu = add_child_autofree(PAUSE_SCENE.instantiate())

func after_each() -> void:
	get_tree().paused = false
	get_viewport().size = DEFAULT_SIZE

func test_pause_menu_offers_resume_and_main_menu_actions() -> void:
	assert_eq(menu._cards.size(), 2)
	assert_eq(menu.PAUSE_CARDS[0]["action"], menu.Action.RESUME)
	assert_eq(menu.PAUSE_CARDS[1]["action"], menu.Action.MAIN_MENU)
	assert_eq(menu.PAUSE_CARDS[0]["title"], "CONTINUAR")
	assert_eq(menu.PAUSE_CARDS[1]["title"], "MENU PRINCIPAL")
	assert_true(get_tree().paused)

func test_layout_keeps_cards_and_footer_inside_window() -> void:
	for window_size in WINDOW_SIZES:
		var size: Vector2 = window_size
		var layout: Dictionary = menu._layout_for(size)
		var content: Rect2 = layout["content"]
		var cards: Array = layout["cards"]
		var footer: Rect2 = layout["footer"]

		assert_eq(cards.size(), 2, "Pause menu needs two cards at %s" % size)
		assert_gte(content.position.x, 0.0)
		assert_lte(content.end.x, size.x)
		assert_gte(cards[0].position.y, layout["strip"].end.y)
		assert_gt(footer.end.y, cards[1].end.y)
		assert_lte(footer.end.y, size.y, "Pause footer overflows at %s" % size)

func test_focus_cycles_between_both_cards() -> void:
	var resume: Button = menu.get_node("BtnResume")
	var main_menu: Button = menu.get_node("BtnMainMenu")

	assert_eq(resume.focus_neighbor_top, main_menu.get_path())
	assert_eq(resume.focus_neighbor_bottom, main_menu.get_path())
	assert_eq(main_menu.focus_neighbor_top, resume.get_path())
	assert_eq(main_menu.focus_neighbor_bottom, resume.get_path())

func test_resume_action_waits_for_transition_and_unpauses_the_tree() -> void:
	var emitted: Array = []
	menu.resume_requested.connect(func() -> void: emitted.append("resume"))

	menu._activate_card(0)
	assert_true(menu._closing)
	assert_false(menu._selected)

	menu._process(menu.CLOSE_DURATION * 0.5)
	assert_true(emitted.is_empty())

	menu._process(menu.CLOSE_DURATION)
	assert_true(menu._selected)
	assert_false(menu.visible)
	assert_false(get_tree().paused)
	assert_eq(emitted, ["resume"])

func test_main_menu_action_keeps_the_tree_paused_until_the_next_selection() -> void:
	var emitted: Array = []
	menu.main_menu_requested.connect(func() -> void: emitted.append("main_menu"))

	menu._activate_card(1)
	menu._process(menu.CLOSE_DURATION)

	assert_true(menu._selected)
	assert_false(menu.visible)
	assert_true(get_tree().paused)
	assert_eq(emitted, ["main_menu"])

func test_escape_requests_resume_without_changing_the_selection() -> void:
	var emitted: Array = []
	menu.resume_requested.connect(func() -> void: emitted.append("resume"))
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = KEY_ESCAPE

	menu._unhandled_key_input(event)
	menu._process(menu.CLOSE_DURATION)

	assert_eq(emitted, ["resume"])
	assert_false(get_tree().paused)

func test_second_action_is_ignored_while_the_menu_is_closing() -> void:
	var emitted: Array = []
	menu.resume_requested.connect(func() -> void: emitted.append("resume"))
	menu.main_menu_requested.connect(func() -> void: emitted.append("main_menu"))

	menu._activate_card(0)
	menu._activate_card(1)
	menu._process(menu.CLOSE_DURATION)

	assert_eq(emitted, ["resume"])
