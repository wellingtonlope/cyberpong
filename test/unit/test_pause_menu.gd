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

func test_pause_menu_offers_resume_restart_settings_and_main_menu_actions() -> void:
	assert_eq(menu._cards.size(), 4)
	assert_eq(menu.PAUSE_CARDS[0]["action"], menu.Action.RESUME)
	assert_eq(menu.PAUSE_CARDS[1]["action"], menu.Action.RESTART)
	assert_eq(menu.PAUSE_CARDS[2]["action"], menu.Action.SETTINGS)
	assert_eq(menu.PAUSE_CARDS[3]["action"], menu.Action.MAIN_MENU)
	assert_eq(menu.PAUSE_CARDS[0]["title"], "CONTINUAR")
	assert_eq(menu.PAUSE_CARDS[1]["title"], "REINICIAR PARTIDA")
	assert_eq(menu.PAUSE_CARDS[2]["title"], "CONFIGURAÇÕES")
	assert_eq(menu.PAUSE_CARDS[3]["title"], "MENU PRINCIPAL")
	assert_true(get_tree().paused)

func test_layout_keeps_cards_and_footer_inside_window() -> void:
	for window_size in WINDOW_SIZES:
		var size: Vector2 = window_size
		var layout: Dictionary = menu._layout_for(size)
		var content: Rect2 = layout["content"]
		var cards: Array = layout["cards"]
		var footer: Rect2 = layout["footer"]

		assert_eq(cards.size(), 4, "Pause menu needs four cards at %s" % size)
		assert_gte(content.position.x, 0.0)
		assert_lte(content.end.x, size.x)
		assert_gte(cards[0].position.y, layout["strip"].end.y)
		assert_gt(footer.end.y, cards[3].end.y)
		assert_lte(footer.end.y, size.y, "Pause footer overflows at %s" % size)

func test_focus_cycles_between_all_cards() -> void:
	var buttons: Array[Button] = [
		menu.get_node("BtnResume"),
		menu.get_node("BtnRestart"),
		menu.get_node("BtnSettings"),
		menu.get_node("BtnMainMenu"),
	]

	for index in range(buttons.size()):
		var button := buttons[index]
		var previous := buttons[(index - 1 + buttons.size()) % buttons.size()]
		var next := buttons[(index + 1) % buttons.size()]
		assert_eq(button.focus_neighbor_top, previous.get_path())
		assert_eq(button.focus_neighbor_bottom, next.get_path())

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

func test_restart_action_unpauses_and_requests_a_new_match() -> void:
	var emitted: Array = []
	menu.restart_requested.connect(func() -> void: emitted.append("restart"))

	menu._activate_card(1)
	menu._process(menu.CLOSE_DURATION)

	assert_true(menu._selected)
	assert_false(menu.visible)
	assert_false(get_tree().paused)
	assert_eq(emitted, ["restart"])

func test_main_menu_action_keeps_the_tree_paused_until_the_next_selection() -> void:
	var emitted: Array = []
	menu.main_menu_requested.connect(func() -> void: emitted.append("main_menu"))

	menu._activate_card(3)
	menu._process(menu.CLOSE_DURATION)

	assert_true(menu._selected)
	assert_false(menu.visible)
	assert_true(get_tree().paused)
	assert_eq(emitted, ["main_menu"])

func test_settings_action_opens_the_settings_menu_without_closing_the_pause() -> void:
	menu._activate_card(2)

	var settings = menu.get_node_or_null("SettingsMenu")
	assert_not_null(settings)
	assert_true(settings is Control)
	assert_false(menu._closing)
	assert_false(menu._selected)
	assert_true(get_tree().paused)
	assert_true(menu.btn_resume.disabled)
	assert_true(menu.btn_restart.disabled)
	assert_true(menu.btn_settings.disabled)
	assert_true(menu.btn_main_menu.disabled)

func test_closing_the_settings_menu_restores_the_pause_cards() -> void:
	menu._activate_card(2)
	var settings = menu.get_node_or_null("SettingsMenu")
	assert_not_null(settings)

	settings._finish_selection()

	assert_null(menu.get_node_or_null("SettingsMenu"))
	assert_false(menu.btn_resume.disabled)
	assert_false(menu.btn_restart.disabled)
	assert_false(menu.btn_settings.disabled)
	assert_false(menu.btn_main_menu.disabled)
	assert_true(get_tree().paused)

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

func test_escape_is_ignored_while_the_settings_menu_is_open() -> void:
	var emitted: Array = []
	menu.resume_requested.connect(func() -> void: emitted.append("resume"))
	menu._activate_card(2)
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = KEY_ESCAPE

	menu._unhandled_key_input(event)
	menu._process(menu.CLOSE_DURATION)

	assert_true(emitted.is_empty())
	assert_true(get_tree().paused)

func test_second_action_is_ignored_while_the_menu_is_closing() -> void:
	var emitted: Array = []
	menu.resume_requested.connect(func() -> void: emitted.append("resume"))
	menu.main_menu_requested.connect(func() -> void: emitted.append("main_menu"))

	menu._activate_card(0)
	menu._activate_card(3)
	menu._process(menu.CLOSE_DURATION)

	assert_eq(emitted, ["resume"])
