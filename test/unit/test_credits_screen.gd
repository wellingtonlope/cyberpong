extends GutTest

const CREDITS_SCENE := preload("res://scenes/credits_screen.tscn")
const DEFAULT_SIZE := Vector2(2880.0, 1620.0)
const WINDOW_SIZES := [
	Vector2(2880.0, 1620.0),
	Vector2(1920.0, 1080.0),
	Vector2(1280.0, 720.0),
	Vector2(960.0, 540.0),
	Vector2(640.0, 480.0),
	Vector2(480.0, 320.0),
]

var credits

func before_each() -> void:
	get_viewport().size = DEFAULT_SIZE
	credits = add_child_autofree(CREDITS_SCENE.instantiate())

func after_each() -> void:
	get_tree().paused = false
	get_viewport().size = DEFAULT_SIZE

func test_credits_show_the_studio_name_over_black_with_the_avatar_icon() -> void:
	assert_eq(credits.get_display_name(), "Moron Souls Productions")
	assert_eq(credits.DISPLAY_NAME, "Moron Souls Productions")
	assert_eq(credits.background.color, Color.BLACK)
	assert_eq(credits.TEXT_COLOR, Color.WHITE)
	assert_not_null(credits.icon.texture, "O icone precisa estar atribuido na cena")
	assert_true(credits.icon.texture is Texture2D)
	assert_eq(credits.background.position, Vector2.ZERO)
	assert_eq(credits.background.size, DEFAULT_SIZE, "O fundo preto precisa cobrir a tela")
	assert_eq(credits.background.anchor_right, 1.0)
	assert_eq(credits.background.anchor_bottom, 1.0)

func test_icon_is_centered_above_the_name_at_every_window_size() -> void:
	for window_size in WINDOW_SIZES:
		var size: Vector2 = window_size
		var layout: Dictionary = credits._layout_for(size)
		var icon_rect: Rect2 = layout["icon"]
		var text_rect: Rect2 = layout["text"]

		assert_gt(icon_rect.size.x, 0.0, "Icon without size at %s" % size)
		assert_gt(text_rect.size.y, 0.0, "Name without size at %s" % size)
		assert_almost_eq(icon_rect.get_center().x, size.x * 0.5, 0.5, "Icon off center at %s" % size)
		assert_almost_eq(text_rect.get_center().x, size.x * 0.5, 0.5, "Name off center at %s" % size)
		assert_lte(icon_rect.end.y, text_rect.position.y, "Icon must sit above the name at %s" % size)
		assert_gte(icon_rect.position.y, 0.0, "Icon above the window at %s" % size)
		assert_lte(text_rect.end.y, size.y, "Credits overflow the window at %s" % size)

func test_name_stays_inside_the_window_width_at_every_size() -> void:
	var font := ThemeDB.fallback_font
	for window_size in WINDOW_SIZES:
		var size: Vector2 = window_size
		var layout: Dictionary = credits._layout_for(size)
		var text_rect: Rect2 = layout["text"]
		var font_size: int = layout["font_size"]
		var measured_width: float = font.get_string_size(
			credits.DISPLAY_NAME,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size
		).x

		assert_gte(font_size, 10)
		assert_lte(measured_width, text_rect.size.x + 0.01, "Name overflows at %s" % size)
		assert_lte(text_rect.size.x, size.x, "Name box exceeds the window at %s" % size)

func test_layout_scale_is_clamped_for_huge_and_small_windows() -> void:
	assert_eq(credits._layout_for(Vector2(7680.0, 4320.0))["scale"], credits.MAX_UI_SCALE)
	assert_eq(credits._layout_for(Vector2(320.0, 240.0))["scale"], credits.MIN_UI_SCALE)

func test_credits_fade_in_hold_and_finish_only_once() -> void:
	var emitted: Array = []
	credits.finished.connect(func() -> void: emitted.append("finished"))

	assert_almost_eq(credits.get_alpha(), 0.0, 0.001)

	credits._process(credits.FADE_IN_DURATION * 0.5)
	assert_gt(credits.get_alpha(), 0.0)
	assert_lt(credits.get_alpha(), 1.0)

	credits._process(credits.FADE_IN_DURATION)
	assert_almost_eq(credits.get_alpha(), 1.0, 0.001)
	assert_eq(credits._stage, credits.Stage.HOLD)
	assert_true(emitted.is_empty())

	credits._process(credits.HOLD_DURATION)
	assert_almost_eq(credits.get_alpha(), 1.0, 0.001)
	assert_eq(credits._stage, credits.Stage.FADE_OUT)
	assert_true(emitted.is_empty())

	credits._process(credits.FADE_OUT_DURATION * 0.5)
	assert_lt(credits.get_alpha(), 1.0)
	assert_gt(credits.get_alpha(), 0.0)

	credits._process(credits.FADE_OUT_DURATION)
	assert_true(credits.is_finished())
	assert_eq(emitted, ["finished"])
	assert_false(credits.visible)
	assert_false(credits.is_processing())

	credits._process(1.0)
	assert_eq(emitted, ["finished"], "O fim da tela nao pode ser emitido duas vezes")

func test_any_key_skips_the_hold_and_finishes_the_credits() -> void:
	var emitted: Array = []
	credits.finished.connect(func() -> void: emitted.append("finished"))
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = KEY_SPACE

	credits._unhandled_input(event)

	assert_eq(credits._stage, credits.Stage.FADE_OUT)
	credits._process(credits.SKIP_FADE_OUT_DURATION)
	assert_true(credits.is_finished())
	assert_eq(emitted, ["finished"])

func test_mouse_click_also_skips_the_credits() -> void:
	var event := InputEventMouseButton.new()
	event.pressed = true
	event.button_index = MOUSE_BUTTON_LEFT

	credits._unhandled_input(event)

	assert_eq(credits._stage, credits.Stage.FADE_OUT)
	credits._process(credits.SKIP_FADE_OUT_DURATION)
	assert_true(credits.is_finished())

func test_released_and_echo_keys_do_not_skip() -> void:
	credits._process(credits.FADE_IN_DURATION)

	var released := InputEventKey.new()
	released.pressed = false
	released.keycode = KEY_SPACE
	credits._unhandled_input(released)
	assert_eq(credits._stage, credits.Stage.HOLD)

	var echo := InputEventKey.new()
	echo.pressed = true
	echo.echo = true
	echo.keycode = KEY_SPACE
	credits._unhandled_input(echo)
	assert_eq(credits._stage, credits.Stage.HOLD)

func test_finished_credits_ignore_later_input() -> void:
	credits.skip()
	credits._process(credits.SKIP_FADE_OUT_DURATION)
	assert_true(credits.is_finished())

	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = KEY_ESCAPE
	credits._unhandled_input(event)

	assert_true(credits.is_finished())
	assert_almost_eq(credits.get_alpha(), 0.0, 0.001)
