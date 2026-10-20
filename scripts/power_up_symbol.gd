extends Node2D

const DEFAULT_ICON_COLOR := Color(1.0, 0.96, 0.72)

var effect_id := ""
var icon_color := DEFAULT_ICON_COLOR
var icon_radius := 16.0

func configure(radius: float) -> void:
	icon_radius = radius
	queue_redraw()

func set_effect(id: String, color: Color) -> void:
	effect_id = id
	icon_color = color
	queue_redraw()

func _draw() -> void:
	if effect_id.is_empty():
		return
	var stroke := maxf(2.0, icon_radius * 0.13)
	match effect_id:
		"double_size":
			_draw_size_arrows(true, stroke)
		"half_size":
			_draw_size_arrows(false, stroke)
		"ball_brake":
			_draw_ball_brake(stroke)
		"powerful_bounce":
			_draw_powerful_bounce()
		"extra_defense":
			_draw_extra_defense(stroke)

func _draw_size_arrows(outward: bool, stroke: float) -> void:
	var radius := icon_radius
	draw_line(Vector2(0.0, -radius * 0.58), Vector2(0.0, radius * 0.58), icon_color, stroke, true)
	var top_base := -radius * (0.22 if outward else 0.6)
	var top_tip := -radius * (0.6 if outward else 0.22)
	var bottom_base := radius * (0.22 if outward else 0.6)
	var bottom_tip := radius * (0.6 if outward else 0.22)
	draw_polyline(
		PackedVector2Array([
			Vector2(-radius * 0.34, top_base),
			Vector2(0.0, top_tip),
			Vector2(radius * 0.34, top_base),
		]),
		icon_color,
		stroke,
		true
	)
	draw_polyline(
		PackedVector2Array([
			Vector2(-radius * 0.34, bottom_base),
			Vector2(0.0, bottom_tip),
			Vector2(radius * 0.34, bottom_base),
		]),
		icon_color,
		stroke,
		true
	)

func _draw_ball_brake(stroke: float) -> void:
	var radius := icon_radius
	draw_arc(
		Vector2(radius * 0.36, 0.0),
		radius * 0.26,
		0.0,
		TAU,
		24,
		icon_color,
		stroke,
		true
	)
	for line_index in range(3):
		var line_y := float(line_index - 1) * radius * 0.36
		var line_length := radius * (0.58 - absf(float(line_index - 1)) * 0.14)
		draw_line(
			Vector2(-radius * 0.78, line_y),
			Vector2(-radius * 0.78 + line_length, line_y),
			icon_color,
			stroke,
			true
		)

func _draw_powerful_bounce() -> void:
	var radius := icon_radius
	var bolt := PackedVector2Array([
		Vector2(-radius * 0.18, -radius * 0.72),
		Vector2(radius * 0.46, -radius * 0.72),
		Vector2(radius * 0.06, -radius * 0.08),
		Vector2(radius * 0.44, -radius * 0.08),
		Vector2(-radius * 0.38, radius * 0.76),
		Vector2(-radius * 0.08, radius * 0.08),
		Vector2(-radius * 0.46, radius * 0.08),
	])
	draw_colored_polygon(bolt, icon_color)

func _draw_extra_defense(stroke: float) -> void:
	var radius := icon_radius
	var shield := PackedVector2Array([
		Vector2(-radius * 0.56, -radius * 0.6),
		Vector2(radius * 0.56, -radius * 0.6),
		Vector2(radius * 0.56, radius * 0.02),
		Vector2(0.0, radius * 0.72),
		Vector2(-radius * 0.56, radius * 0.02),
		Vector2(-radius * 0.56, -radius * 0.6),
	])
	draw_polyline(shield, icon_color, stroke, true)
	draw_polyline(
		PackedVector2Array([
			Vector2(-radius * 0.24, 0.0),
			Vector2(-radius * 0.04, radius * 0.22),
			Vector2(radius * 0.3, -radius * 0.22),
		]),
		icon_color,
		stroke,
		true
	)
