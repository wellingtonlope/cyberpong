extends CanvasLayer

const PANEL_BACKGROUND := Color(0.015, 0.025, 0.045, 0.92)
const PANEL_BORDER := Color(0.08, 0.98, 1.0, 0.75)
const LABEL_COLOR := Color(0.9, 0.94, 1.0)

var _game_scale := 1.0
var _ball_speed := 0.0
var _left_rebounds := 0
var _right_rebounds := 0
var _panel: PanelContainer
var _info_label: Label

func _ready() -> void:
	layer = 10
	_panel = PanelContainer.new()
	add_child(_panel)
	_info_label = Label.new()
	_panel.add_child(_info_label)
	_panel.hide()
	_apply_style()
	_refresh_text()

func configure(scale: float) -> void:
	_game_scale = scale
	if is_instance_valid(_panel):
		_apply_style()

func toggle() -> void:
	_panel.visible = not _panel.visible

func set_ball_speed(value: float) -> void:
	_ball_speed = value
	_refresh_text()

func record_paddle_hit(is_left: bool) -> void:
	if is_left:
		_left_rebounds += 1
	else:
		_right_rebounds += 1
	_refresh_text()

func reset_match_counts() -> void:
	_left_rebounds = 0
	_right_rebounds = 0
	_refresh_text()

func _apply_style() -> void:
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = PANEL_BACKGROUND
	panel_style.border_color = PANEL_BORDER
	panel_style.set_border_width_all(maxi(roundi(_game_scale), 1))
	panel_style.set_content_margin_all(8.0 * _game_scale)
	_panel.add_theme_stylebox_override("panel", panel_style)
	_info_label.add_theme_color_override("font_color", LABEL_COLOR)
	_info_label.add_theme_font_size_override("font_size", 12 * int(_game_scale))
	_position_panel()

func _refresh_text() -> void:
	if not is_instance_valid(_info_label):
		return
	var total_rebounds := _left_rebounds + _right_rebounds
	_info_label.text = "DEBUG HUD\nVelocidade: %d px/s\nRebatidas totais: %d\nCyan Circuit: %d   Magenta Volt: %d" % [
		roundi(_ball_speed),
		total_rebounds,
		_left_rebounds,
		_right_rebounds,
	]
	_position_panel()

func _position_panel() -> void:
	if not is_instance_valid(_panel):
		return
	var margin := 16.0 * _game_scale
	_panel.size = _panel.get_combined_minimum_size()
	_panel.position = Vector2(margin, -_panel.size.y - margin)
