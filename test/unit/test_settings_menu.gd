extends GutTest

const SETTINGS_SCENE := preload("res://scenes/settings_menu.tscn")
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
var _original_volume_percent := 100
var _original_sound_enabled := true

func before_each() -> void:
	get_viewport().size = DEFAULT_SIZE
	_original_volume_percent = SoundManager.master_volume_percent
	_original_sound_enabled = SoundManager.sound_enabled
	SoundManager.master_volume_percent = 100
	SoundManager.sound_enabled = true
	menu = add_child_autofree(SETTINGS_SCENE.instantiate())

func after_each() -> void:
	SoundManager.master_volume_percent = _original_volume_percent
	SoundManager.sound_enabled = _original_sound_enabled
	get_tree().paused = false
	get_viewport().size = DEFAULT_SIZE

func test_settings_menu_lists_volume_sound_fullscreen_resolution_and_back_actions() -> void:
	assert_eq(menu._cards.size(), 5)
	assert_eq(menu.SETTINGS_CARDS[0]["action"], menu.Action.VOLUME)
	assert_eq(menu.SETTINGS_CARDS[1]["action"], menu.Action.TOGGLE_SOUND)
	assert_eq(menu.SETTINGS_CARDS[2]["action"], menu.Action.TOGGLE_FULLSCREEN)
	assert_eq(menu.SETTINGS_CARDS[3]["action"], menu.Action.CYCLE_RESOLUTION)
	assert_eq(menu.SETTINGS_CARDS[4]["action"], menu.Action.BACK)
	assert_eq(menu._cards[1]["tag"], "LIGADO")

func test_layout_keeps_cards_and_footer_inside_window() -> void:
	for window_size in WINDOW_SIZES:
		var size: Vector2 = window_size
		var layout: Dictionary = menu._layout_for(size)
		var cards: Array = layout["cards"]
		var footer: Rect2 = layout["footer"]

		assert_eq(cards.size(), 5, "Settings menu needs five cards at %s" % size)
		assert_gte(cards[0].position.y, layout["strip"].end.y)
		assert_gt(footer.end.y, cards[4].end.y)
		assert_lte(footer.end.y, size.y, "Settings footer overflows at %s" % size)

func test_volume_card_shows_a_bar_from_zero_to_one_hundred() -> void:
	SoundManager.master_volume_percent = 100
	menu._refresh_state()
	assert_eq(menu._cards[0]["progress"], 1.0)
	assert_eq(menu._cards[0]["tag"], "100%")

	SoundManager.master_volume_percent = 40
	menu._refresh_state()
	assert_almost_eq(float(menu._cards[0]["progress"]), 0.4, 0.001)
	assert_eq(menu._cards[0]["tag"], "40%")

	SoundManager.master_volume_percent = 0
	menu._refresh_state()
	assert_almost_eq(float(menu._cards[0]["progress"]), 0.0, 0.001)
	assert_eq(menu._cards[0]["tag"], "0%")

func test_volume_bar_is_drawn_without_errors() -> void:
	SoundManager.master_volume_percent = 35
	menu._refresh_state()
	menu.queue_redraw()
	await get_tree().process_frame
	await get_tree().process_frame

	assert_eq(menu._cards[menu.VOLUME_CARD_INDEX]["tag"], "35%")
	assert_almost_eq(float(menu._cards[menu.VOLUME_CARD_INDEX]["progress"]), 0.35, 0.001)

func test_arrow_keys_adjust_the_volume_in_steps_of_five_percent() -> void:
	SoundManager.master_volume_percent = 50
	menu._on_card_focused(menu.VOLUME_CARD_INDEX)

	var left := InputEventKey.new()
	left.pressed = true
	left.keycode = KEY_LEFT
	menu._input(left)

	assert_eq(menu.volume_percentage(), 45)
	assert_eq(SoundManager.master_volume_percent, 45)

	var right := InputEventKey.new()
	right.pressed = true
	right.keycode = KEY_RIGHT
	menu._input(right)

	assert_eq(menu.volume_percentage(), 50)
	assert_eq(SoundManager.master_volume_percent, 50)

func test_arrow_keys_do_not_change_the_volume_when_another_card_is_focused() -> void:
	SoundManager.master_volume_percent = 50
	menu._on_card_focused(menu.SOUND_CARD_INDEX)

	var right := InputEventKey.new()
	right.pressed = true
	right.keycode = KEY_RIGHT
	menu._input(right)

	assert_eq(menu.volume_percentage(), 50)

func test_volume_is_clamped_to_the_supported_range() -> void:
	SoundManager.master_volume_percent = 100
	menu._on_card_focused(menu.VOLUME_CARD_INDEX)
	for _index in range(30):
		menu.adjust_volume(-menu.VOLUME_STEP_PERCENT)
	assert_eq(menu.volume_percentage(), 0)
	assert_almost_eq(
		SoundManager.master_volume_db,
		SoundManager.MIN_VOLUME_DB,
		0.001
	)

	for _index in range(30):
		menu.adjust_volume(menu.VOLUME_STEP_PERCENT)
	assert_eq(menu.volume_percentage(), 100)
	assert_almost_eq(
		SoundManager.master_volume_db,
		SoundManager.MAX_VOLUME_DB,
		0.001
	)

func test_volume_percentage_and_decibels_stay_in_sync() -> void:
	SoundManager.master_volume_percent = 25
	assert_almost_eq(SoundManager.master_volume_db, -18.0, 0.001)

	SoundManager.master_volume_db = -12.0
	assert_eq(SoundManager.master_volume_percent, 50)

func test_sound_action_toggles_the_audio_and_updates_the_tag() -> void:
	menu._activate_card(menu.SOUND_CARD_INDEX)
	assert_false(SoundManager.sound_enabled)
	assert_eq(menu._cards[menu.SOUND_CARD_INDEX]["tag"], "DESLIGADO")

	menu._activate_card(menu.SOUND_CARD_INDEX)
	assert_true(SoundManager.sound_enabled)
	assert_eq(menu._cards[menu.SOUND_CARD_INDEX]["tag"], "LIGADO")

func test_fullscreen_action_toggles_the_window_mode_state() -> void:
	assert_false(menu.is_fullscreen())
	menu._activate_card(menu.FULLSCREEN_CARD_INDEX)
	assert_true(menu.is_fullscreen())
	assert_eq(menu._cards[menu.FULLSCREEN_CARD_INDEX]["tag"], "TELA CHEIA")

	menu._activate_card(menu.FULLSCREEN_CARD_INDEX)
	assert_false(menu.is_fullscreen())
	assert_eq(menu._cards[menu.FULLSCREEN_CARD_INDEX]["tag"], "JANELA")

func test_resolution_card_cycles_through_the_available_resolutions() -> void:
	var first: Vector2i = menu.current_resolution()
	menu._activate_card(menu.RESOLUTION_CARD_INDEX)

	var second: Vector2i = menu.current_resolution()
	assert_ne(second, first)
	assert_eq(menu._cards[menu.RESOLUTION_CARD_INDEX]["tag"], "%d×%d" % [second.x, second.y])

	for _index in range(menu.RESOLUTION_PRESETS.size()):
		menu._activate_card(menu.RESOLUTION_CARD_INDEX)
	assert_eq(menu.current_resolution(), second)

func test_resolution_presets_are_all_valid_window_sizes() -> void:
	assert_gt(menu.RESOLUTION_PRESETS.size(), 1)
	for resolution in menu.RESOLUTION_PRESETS:
		assert_gte(resolution.x, 640)
		assert_gte(resolution.y, 480)

func test_back_action_closes_the_menu_and_keeps_the_tree_paused() -> void:
	var emitted: Array = []
	menu.closed.connect(func() -> void: emitted.append("closed"))

	menu._activate_card(menu.BACK_CARD_INDEX)
	assert_true(menu._closing)
	menu._process(menu.CLOSE_DURATION)

	assert_eq(emitted, ["closed"])
	assert_false(menu.visible)
	assert_true(get_tree().paused)

func test_escape_closes_the_settings_menu() -> void:
	var emitted: Array = []
	menu.closed.connect(func() -> void: emitted.append("closed"))
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = KEY_ESCAPE

	menu._unhandled_key_input(event)
	menu._process(menu.CLOSE_DURATION)

	assert_eq(emitted, ["closed"])
	assert_false(menu.visible)
