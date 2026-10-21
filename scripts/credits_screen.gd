class_name CreditsScreen
extends Control

signal finished

const DISPLAY_NAME := "Moron Souls Productions"
const BACKGROUND_COLOR := Color(0.0, 0.0, 0.0, 1.0)
const TEXT_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const MIN_UI_SCALE := 0.55
const MAX_UI_SCALE := 3.0
const ICON_BASE_SIZE := 180.0
const TEXT_BASE_SIZE := 30.0
const ICON_TEXT_GAP := 26.0
const SIDE_MARGIN := 60.0
const FADE_IN_DURATION := 0.5
const HOLD_DURATION := 1.6
const FADE_OUT_DURATION := 0.45
const SKIP_FADE_OUT_DURATION := 0.25

enum Stage {
	FADE_IN,
	HOLD,
	FADE_OUT
}

@onready var background: ColorRect = $Background
@onready var icon: TextureRect = $Icon

var _font: Font
var _layout: Dictionary = {}
var _stage: int = Stage.FADE_IN
var _stage_time := 0.0
var _alpha := 0.0
var _fade_out_from := 1.0
var _fade_out_duration := FADE_OUT_DURATION
var _finished := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	background.color = BACKGROUND_COLOR
	_update_layout()
	_apply_alpha()
	SoundManager.play_credits_sting()

func _process(delta: float) -> void:
	if _finished:
		return
	if _layout.get("size") != _current_surface_size():
		_update_layout()
	_stage_time += delta
	match _stage:
		Stage.FADE_IN:
			if _stage_time >= FADE_IN_DURATION:
				_alpha = 1.0
				_stage = Stage.HOLD
				_stage_time = 0.0
			else:
				_alpha = _stage_time / FADE_IN_DURATION
		Stage.HOLD:
			if _stage_time >= HOLD_DURATION:
				_begin_fade_out(FADE_OUT_DURATION)
		Stage.FADE_OUT:
			pass
	if _stage == Stage.FADE_OUT:
		_alpha = _fade_out_from * maxf(1.0 - _stage_time / _fade_out_duration, 0.0)
		if _stage_time >= _fade_out_duration:
			_finish()
	_apply_alpha()
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_update_layout()

func _unhandled_input(event: InputEvent) -> void:
	if _finished:
		return
	if event is InputEventKey:
		if not event.pressed or event.echo:
			return
	elif event is InputEventMouseButton:
		if not event.pressed:
			return
	else:
		return
	skip()
	get_viewport().set_input_as_handled()

func skip() -> void:
	if _finished:
		return
	_begin_fade_out(SKIP_FADE_OUT_DURATION)

func is_finished() -> bool:
	return _finished

func get_alpha() -> float:
	return _alpha

func get_display_name() -> String:
	return DISPLAY_NAME

func _begin_fade_out(duration: float) -> void:
	if _stage == Stage.FADE_OUT:
		return
	_stage = Stage.FADE_OUT
	_stage_time = 0.0
	_fade_out_from = _alpha
	_fade_out_duration = maxf(duration, 0.01)

func _finish() -> void:
	if _finished:
		return
	_finished = true
	_alpha = 0.0
	_apply_alpha()
	hide()
	set_process(false)
	finished.emit()

func _apply_alpha() -> void:
	if is_instance_valid(icon):
		icon.modulate = Color(1.0, 1.0, 1.0, _alpha)

func _update_layout() -> void:
	_layout = _layout_for(_current_surface_size())
	var surface_size: Vector2 = _layout["size"]
	if is_instance_valid(background):
		background.position = Vector2.ZERO
		background.size = surface_size
	if is_instance_valid(icon):
		var icon_rect: Rect2 = _layout["icon"]
		icon.position = icon_rect.position
		icon.size = icon_rect.size
	queue_redraw()

func _current_surface_size() -> Vector2:
	if size.x > 0.0 and size.y > 0.0:
		return size
	return get_viewport_rect().size

func _layout_for(surface_size: Vector2) -> Dictionary:
	var font := _current_font()
	var scale_factor := _ui_scale_for(surface_size)
	var icon_size := ICON_BASE_SIZE * scale_factor
	var gap := ICON_TEXT_GAP * scale_factor
	var available_width := maxf(surface_size.x - SIDE_MARGIN * 2.0 * scale_factor, 80.0)
	var font_size := UiDraw.fit_font_size(
		font,
		DISPLAY_NAME,
		maxi(int(TEXT_BASE_SIZE * scale_factor), 14),
		10,
		available_width
	)
	var measured_width := font.get_string_size(
		DISPLAY_NAME,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size
	).x
	var text_width := minf(measured_width + 4.0, available_width)
	var text_height := font.get_height(font_size)
	var total_height := icon_size + gap + text_height
	var top := maxf((surface_size.y - total_height) * 0.5, 0.0)
	var icon_rect := Rect2(
		Vector2((surface_size.x - icon_size) * 0.5, top),
		Vector2(icon_size, icon_size)
	)
	var text_rect := Rect2(
		Vector2((surface_size.x - text_width) * 0.5, icon_rect.end.y + gap),
		Vector2(text_width, text_height)
	)
	return {
		"size": surface_size,
		"scale": scale_factor,
		"icon": icon_rect,
		"text": text_rect,
		"font_size": font_size,
		"text_baseline": text_rect.position.y + font.get_ascent(font_size)
	}

func _ui_scale_for(surface_size: Vector2) -> float:
	return clampf(
		minf(surface_size.x / 960.0, surface_size.y / 540.0),
		MIN_UI_SCALE,
		MAX_UI_SCALE
	)

func _current_font() -> Font:
	if _font == null:
		_font = ThemeDB.fallback_font
	return _font

func _draw() -> void:
	var surface_size := _current_surface_size()
	if _layout.is_empty() or _layout.get("size") != surface_size:
		_update_layout()
	if _layout.is_empty() or _alpha <= 0.0:
		return
	var text_rect: Rect2 = _layout["text"]
	var font_size: int = _layout["font_size"]
	var baseline: float = _layout["text_baseline"]
	draw_string(
		_current_font(),
		Vector2(text_rect.position.x, baseline),
		DISPLAY_NAME,
		HORIZONTAL_ALIGNMENT_CENTER,
		text_rect.size.x,
		font_size,
		Color(TEXT_COLOR, _alpha)
	)
