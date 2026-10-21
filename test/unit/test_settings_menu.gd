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
var _original_volume_db := 0.0
var _original_sound_enabled := true

func before_each() -> void:
	get_viewport().size = DEFAULT_SIZE
	_original_volume_db = SoundManager.master_volume_db
	_original_sound_enabled = SoundManager.sound_enabled
	SoundManager.master_volume_db = 0.0
	SoundManager.sound_enabled = true
	menu = add_child_autofree(SETTINGS_SCENE.instantiate())

func after_each() -> void:
	SoundManager.master_volume_db = _original_volume_db
	SoundManager.sound_enabled = _original_sound_enabled
	get_tree().paused = false
	get_viewport().size = DEFAULT_SIZE

func test_settings_menu_lists_volume_sound_fullscreen_and_back_actions() -> void:
	assert_eq(menu._cards.size(), 5)
	assert_eq(menu.SETTINGS_CARDS[0]["action"], menu.Action.VOLUME_DOWN)
	assert_eq(menu.SETTINGS_CARDS[1]["action"], menu.Action.VOLUME_UP)
	assert_eq(menu.SETTINGS_CARDS[2]["action"], menu.Action.TOGGLE_SOUND)
	assert_eq(menu.SETTINGS_CARDS[3]["action"], menu.Action.TOGGLE_FULLSCREEN)
	assert_eq(menu.SETTINGS_CARDS[4]["action"], menu.Action.BACK)
	assert_eq(menu._cards[2]["tag"], "LIGADO")

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

func test_volume_controls_adjust_the_master_volume_in_steps() -> void:
	SoundManager.master_volume_db = -6.0
	var initial_percentage: int = menu.volume_percentage()

	menu._activate_card(1)
	assert_almost_eq(SoundManager.master_volume_db, -3.0, 0.001)
	assert_gt(menu.volume_percentage(), initial_percentage)

	menu._activate_card(0)
	assert_almost_eq(SoundManager.master_volume_db, -6.0, 0.001)
	assert_eq(menu.volume_percentage(), initial_percentage)

func test_volume_is_clamped_to_the_supported_range() -> void:
	for _index in range(20):
		menu._activate_card(0)
	assert_almost_eq(SoundManager.master_volume_db, menu.MIN_VOLUME_DB, 0.001)
	assert_eq(menu.volume_percentage(), 0)

	SoundManager.master_volume_db = menu.MAX_VOLUME_DB
	menu._activate_card(1)
	assert_almost_eq(SoundManager.master_volume_db, menu.MAX_VOLUME_DB, 0.001)

func test_sound_action_toggles_the_audio_and_updates_the_tag() -> void:
	menu._activate_card(2)
	assert_false(SoundManager.sound_enabled)
	assert_eq(menu._cards[2]["tag"], "DESLIGADO")

	menu._activate_card(2)
	assert_true(SoundManager.sound_enabled)
	assert_eq(menu._cards[2]["tag"], "LIGADO")

func test_fullscreen_action_toggles_the_window_mode_state() -> void:
	assert_false(menu.is_fullscreen())
	menu._activate_card(3)
	assert_true(menu.is_fullscreen())
	assert_eq(menu._cards[3]["tag"], "TELA CHEIA")

	menu._activate_card(3)
	assert_false(menu.is_fullscreen())
	assert_eq(menu._cards[3]["tag"], "JANELA")

func test_back_action_closes_the_menu_and_keeps_the_tree_paused() -> void:
	var emitted: Array = []
	menu.closed.connect(func() -> void: emitted.append("closed"))

	menu._activate_card(4)
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
