class_name UiDraw
extends RefCounted

## Helpers de desenho compartilhados pela arena, pelos menus e pelos efeitos.
## Evitam que a mesma geometria ou o mesmo cálculo de fonte seja reimplementado
## em vários scripts.

## Reduz o tamanho da fonte até o texto caber em `max_width`, respeitando
## `minimum_size`.
static func fit_font_size(
	font: Font,
	text: String,
	preferred_size: int,
	minimum_size: int,
	max_width: float
) -> int:
	var font_size := maxi(preferred_size, minimum_size)
	while font_size > minimum_size:
		var measured_width := font.get_string_size(
			text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size
		).x
		if measured_width <= max_width:
			return font_size
		font_size -= 1
	return minimum_size

## Aplica um fator de transparência sobre a cor, preservando o alfa original.
static func with_alpha(color: Color, alpha_factor: float) -> Color:
	return Color(color.r, color.g, color.b, color.a * alpha_factor)

## Contorno com os quatro cantos cortados, no estilo dos cartões do menu.
static func angular_points(rect: Rect2, cut: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(rect.position.x + cut, rect.position.y),
		Vector2(rect.end.x - cut, rect.position.y),
		Vector2(rect.end.x, rect.position.y + cut),
		Vector2(rect.end.x, rect.end.y - cut),
		Vector2(rect.end.x - cut, rect.end.y),
		Vector2(rect.position.x + cut, rect.end.y),
		Vector2(rect.position.x, rect.end.y - cut),
		Vector2(rect.position.x, rect.position.y + cut),
	])

## Losango usado nos pips do placar, na bola e no símbolo do power-up.
static func diamond_points(center: Vector2, radius: float) -> PackedVector2Array:
	return PackedVector2Array([
		center + Vector2(0.0, -radius),
		center + Vector2(radius, 0.0),
		center + Vector2(0.0, radius),
		center + Vector2(-radius, 0.0),
	])

## Polígono que aproxima um círculo.
static func circle_points(
	center: Vector2,
	radius: float,
	segments: int
) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(segments):
		var angle := TAU * float(index) / float(segments)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points

## Emblema da equipe: hexágono com cruz para Cyan Circuit (esquerda) e losango
## com raio para Magenta Volt (direita).
static func draw_team_emblem(
	canvas: CanvasItem,
	center: Vector2,
	team_color: Color,
	is_left: bool,
	emblem_scale: float,
	alpha_factor: float = 1.0
) -> void:
	var draw_color := with_alpha(team_color, alpha_factor)
	if is_left:
		var hexagon := PackedVector2Array()
		for point_index in range(7):
			var angle := -PI * 0.5 + TAU * float(point_index % 6) / 6.0
			hexagon.append(center + Vector2(cos(angle), sin(angle)) * 10.0 * emblem_scale)
		canvas.draw_polyline(hexagon, draw_color, maxf(1.0, 1.8 * emblem_scale), true)
		canvas.draw_line(
			center,
			center + Vector2(5.0, -5.0) * emblem_scale,
			draw_color,
			maxf(1.0, 1.4 * emblem_scale),
			true
		)
		canvas.draw_line(
			center,
			center + Vector2(-5.0, 5.0) * emblem_scale,
			draw_color,
			maxf(1.0, 1.4 * emblem_scale),
			true
		)
		canvas.draw_circle(center, 2.0 * emblem_scale, with_alpha(Palette.TEXT_COLOR, alpha_factor))
		return
	var diamond := PackedVector2Array([
		center + Vector2(0.0, -11.0) * emblem_scale,
		center + Vector2(11.0, 0.0) * emblem_scale,
		center + Vector2(0.0, 11.0) * emblem_scale,
		center + Vector2(-11.0, 0.0) * emblem_scale,
		center + Vector2(0.0, -11.0) * emblem_scale,
	])
	canvas.draw_polyline(diamond, draw_color, maxf(1.0, 1.8 * emblem_scale), true)
	var bolt := PackedVector2Array([
		center + Vector2(1.0, -7.0) * emblem_scale,
		center + Vector2(-4.0, 1.0) * emblem_scale,
		center + Vector2(-1.0, 1.0) * emblem_scale,
		center + Vector2(-2.0, 7.0) * emblem_scale,
		center + Vector2(4.0, -1.0) * emblem_scale,
		center + Vector2(1.0, -1.0) * emblem_scale,
	])
	canvas.draw_colored_polygon(bolt, draw_color)
