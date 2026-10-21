extends Control

const LEFT_COLOR := Color(0.08, 0.98, 1.0)
const RIGHT_COLOR := Color(1.0, 0.12, 0.72)
const TEXT_COLOR := Color(0.9, 0.94, 1.0)
const MUTED_TEXT_COLOR := Color(0.58, 0.68, 0.8)
const DIVIDER_COLOR := Color(0.18, 0.24, 0.32)
const BALL_COLOR := Color(1.0, 0.92, 0.12)
const PANEL_COLOR := Color(0.008, 0.016, 0.028, 0.94)
const PANEL_HOVER_COLOR := Color(0.018, 0.038, 0.062, 0.96)
const PANEL_FOCUS_COLOR := Color(0.028, 0.058, 0.092, 0.97)
const OVERLAY_COLOR := Color(0.003, 0.008, 0.016, 0.9)

const CARD_HEIGHT := 60.0
const CARD_GAP := 16.0
const HEADER_HEIGHT := 80.0
const STRIP_HEIGHT := 48.0
const FOOTER_HEIGHT := 34.0
const HEADER_GAP := 18.0
const BODY_GAP := 22.0
const CARD_GUTTER := 26.0
const CONTENT_WIDTH := 380.0
const SELECTOR_HEIGHT := 34.0
const SELECTOR_LABEL_WIDTH := 110.0
const SELECTOR_LABEL_GAP := 10.0
const SELECTOR_PILL_GAP := 8.0
const SELECTOR_REFERENCE_EXTRA := 36.0
const MENU_REFERENCE_HEIGHT := 540.0
const MIN_UI_SCALE := 0.55
const MAX_UI_SCALE := 3.0
const FADE_IN_DURATION := 0.35
const CLOSE_DURATION := 0.20

var _cards: Array = []
var _card_buttons: Array[Button] = []
var _card_rects: Array = []
var _layout: Dictionary = {}
var _font: Font
var _focused_index := 0
var _cursor_y := 0.0
var _cursor_target_y := 0.0
var _time := 0.0
var _fade_in := 0.0
var _closing := false
var _close_progress := 0.0
var _closing_index := -1
var _pending_index := -1
var _selected := false
var _selector_label := ""
var _selector_titles: Array = []
var _selector_buttons: Array[Button] = []
var _selector_rects: Array = []
var _selector_selected_index := 0
var _selector_visible := true

func _setup_menu(buttons: Array[Button], cards: Array) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_font = ThemeDB.fallback_font
	_cards = cards
	_card_buttons = buttons
	_configure_buttons()
	_update_layout()
	_show()
	call_deferred("grab_first_focus")

func _setup_selector(label: String, buttons: Array[Button], titles: Array) -> void:
	_selector_label = label
	_selector_buttons = buttons
	_selector_titles = titles
	_configure_selector_buttons()
	_set_selector_selection(0)
	_update_layout()

func _configure_selector_buttons() -> void:
	var empty_style := StyleBoxEmpty.new()
	for index in range(_selector_buttons.size()):
		var button := _selector_buttons[index]
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.flat = true
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			button.add_theme_stylebox_override(state, empty_style)
		button.pressed.connect(_on_selector_pressed.bind(index))

func _set_selector_selection(index: int) -> void:
	if _selector_buttons.is_empty():
		return
	var clamped := clampi(index, 0, _selector_buttons.size() - 1)
	if _selector_selected_index != clamped:
		SoundManager.play_ui_move()
	_selector_selected_index = clamped
	queue_redraw()

func _set_selector_visible(visible: bool) -> void:
	if _selector_buttons.is_empty():
		return
	_selector_visible = visible
	for button in _selector_buttons:
		button.visible = visible
		button.mouse_filter = (
			Control.MOUSE_FILTER_STOP if visible else Control.MOUSE_FILTER_IGNORE
		)
	queue_redraw()

func _on_selector_pressed(index: int) -> void:
	if _selected or _closing:
		return
	_selector_selected_index = clampi(index, 0, _selector_buttons.size() - 1)
	_selector_activated(index)
	queue_redraw()

func _selector_activated(_index: int) -> void:
	pass

func _process(delta: float) -> void:
	_time += delta
	if _fade_in < 1.0:
		_fade_in = minf(_fade_in + delta / FADE_IN_DURATION, 1.0)
	if _closing:
		_close_progress = minf(_close_progress + delta / CLOSE_DURATION, 1.0)
		if _close_progress >= 1.0:
			_finish_selection()
			return
	if not is_zero_approx(_cursor_target_y):
		_cursor_y = lerpf(_cursor_y, _cursor_target_y, minf(delta * 14.0, 1.0))
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_update_layout()

func _configure_buttons() -> void:
	var empty_style := StyleBoxEmpty.new()
	var count := _card_buttons.size()
	for index in range(count):
		var button := _card_buttons[index]
		var previous := _card_buttons[(index - 1 + count) % count]
		var next := _card_buttons[(index + 1) % count]
		button.focus_mode = Control.FOCUS_ALL
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.flat = true
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			button.add_theme_stylebox_override(state, empty_style)
		button.focus_neighbor_top = previous.get_path()
		button.focus_previous = previous.get_path()
		button.focus_neighbor_left = previous.get_path()
		button.focus_neighbor_bottom = next.get_path()
		button.focus_next = next.get_path()
		button.focus_neighbor_right = next.get_path()
		button.pressed.connect(_on_card_pressed.bind(index))
		button.focus_entered.connect(_on_card_focused.bind(index))
		button.mouse_entered.connect(_on_card_hovered.bind(index))

func _on_card_pressed(index: int) -> void:
	_activate_card(index)

func _activate_card(_index: int) -> void:
	pass

func _finish_selection() -> void:
	pass

func _on_card_focused(index: int) -> void:
	if _focused_index != index:
		SoundManager.play_ui_move()
	_focused_index = index
	if index < _card_rects.size():
		_cursor_target_y = _card_rects[index].get_center().y
	queue_redraw()

func _on_card_hovered(index: int) -> void:
	if _selected or _closing:
		return
	var button := _card_buttons[index]
	if not button.has_focus():
		button.grab_focus()

func grab_first_focus() -> void:
	if _selected:
		return
	for button in _card_buttons:
		if button != null and button.is_inside_tree():
			button.grab_focus()
			return

func set_cards_interactive(interactive: bool) -> void:
	for button in _card_buttons:
		if button == null:
			continue
		button.disabled = not interactive
		button.mouse_filter = (
			Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
		)

func _show() -> void:
	show()
	get_tree().paused = true

func _update_layout() -> void:
	_apply_layout(_current_surface_size())
	queue_redraw()

func _current_surface_size() -> Vector2:
	if size.x > 0.0 and size.y > 0.0:
		return size
	return get_viewport_rect().size

func _apply_layout(surface_size: Vector2) -> void:
	_layout = _layout_for(surface_size)
	_card_rects = _layout["cards"]
	_selector_rects = _layout["selector_pills"]
	for index in range(_card_buttons.size()):
		if index >= _card_rects.size():
			continue
		var rect: Rect2 = _card_rects[index]
		var button := _card_buttons[index]
		button.position = rect.position
		button.size = rect.size
	for index in range(_selector_buttons.size()):
		if index >= _selector_rects.size():
			continue
		var rect: Rect2 = _selector_rects[index]
		var button := _selector_buttons[index]
		button.position = rect.position
		button.size = rect.size
	if _card_rects.is_empty():
		return
	_focused_index = clampi(_focused_index, 0, _card_rects.size() - 1)
	_cursor_target_y = _card_rects[_focused_index].get_center().y
	_cursor_y = _cursor_target_y

func _layout_for(surface_size: Vector2) -> Dictionary:
	var scale_factor := _ui_scale_for(surface_size)
	var content_width := minf(
		surface_size.x - 48.0 * scale_factor,
		maxf(320.0, CONTENT_WIDTH * scale_factor)
	)
	var content_left := (surface_size.x - content_width) * 0.5
	var card_height := CARD_HEIGHT * scale_factor
	var card_gap := CARD_GAP * scale_factor
	var card_width := content_width - CARD_GUTTER * scale_factor
	var card_count := _cards.size()
	var cards_height := card_height * float(card_count)
	if card_count > 1:
		cards_height += card_gap * float(card_count - 1)
	var selector_height := 0.0
	if not _selector_buttons.is_empty():
		selector_height = SELECTOR_HEIGHT * scale_factor + BODY_GAP * scale_factor
	var total_height := (
		HEADER_HEIGHT * scale_factor
		+ HEADER_GAP * scale_factor
		+ STRIP_HEIGHT * scale_factor
		+ BODY_GAP * scale_factor
		+ selector_height
		+ cards_height
		+ BODY_GAP * scale_factor
		+ FOOTER_HEIGHT * scale_factor
	)
	var top := maxf((surface_size.y - total_height) * 0.5, 72.0 * scale_factor)
	if top + total_height > surface_size.y:
		top = maxf((surface_size.y - total_height) * 0.5, 8.0 * scale_factor)
	var header := Rect2(
		Vector2(content_left, top),
		Vector2(content_width, HEADER_HEIGHT * scale_factor)
	)
	var strip := Rect2(
		Vector2(content_left, header.end.y + HEADER_GAP * scale_factor),
		Vector2(content_width, STRIP_HEIGHT * scale_factor)
	)
	var selector_label := Rect2()
	var selector_pills: Array = []
	var selector_section_height := 0.0
	if not _selector_buttons.is_empty():
		selector_section_height = SELECTOR_HEIGHT * scale_factor
		var selector_top := strip.end.y + BODY_GAP * scale_factor
		selector_label = Rect2(
			Vector2(content_left, selector_top),
			Vector2(SELECTOR_LABEL_WIDTH * scale_factor, selector_section_height)
		)
		var pills_left := content_left + (SELECTOR_LABEL_WIDTH + SELECTOR_LABEL_GAP) * scale_factor
		var pills_width := content_width - (SELECTOR_LABEL_WIDTH + SELECTOR_LABEL_GAP) * scale_factor
		var pill_gap := SELECTOR_PILL_GAP * scale_factor
		var pill_count := _selector_buttons.size()
		var pill_width := maxf(
			(pills_width - pill_gap * float(pill_count - 1)) / float(pill_count),
			1.0
		)
		for index in range(pill_count):
			selector_pills.append(
				Rect2(
					Vector2(pills_left + float(index) * (pill_width + pill_gap), selector_top),
					Vector2(pill_width, selector_section_height)
				)
			)
	var cards: Array = []
	var cards_y := strip.end.y + BODY_GAP * scale_factor
	if selector_section_height > 0.0:
		cards_y += selector_section_height + BODY_GAP * scale_factor
	for index in range(card_count):
		cards.append(
			Rect2(
				Vector2(
					content_left + CARD_GUTTER * scale_factor,
					cards_y + float(index) * (card_height + card_gap)
				),
				Vector2(card_width, card_height)
			)
		)
	var footer := Rect2(
		Vector2(content_left, cards_y + cards_height + BODY_GAP * scale_factor),
		Vector2(content_width, FOOTER_HEIGHT * scale_factor)
	)
	return {
		"size": surface_size,
		"scale": scale_factor,
		"content": Rect2(Vector2(content_left, top), Vector2(content_width, footer.end.y - top)),
		"header": header,
		"strip": strip,
		"selector_label": selector_label,
		"selector_pills": selector_pills,
		"cards": cards,
		"footer": footer,
		"cursor_x": content_left + CARD_GUTTER * scale_factor * 0.5,
		"top": top,
		"bottom": footer.end.y
	}

func _ui_scale_for(surface_size: Vector2) -> float:
	var reference_height := MENU_REFERENCE_HEIGHT
	if not _selector_buttons.is_empty():
		reference_height += SELECTOR_REFERENCE_EXTRA
	return clampf(
		minf(surface_size.x / 960.0, surface_size.y / reference_height),
		MIN_UI_SCALE,
		MAX_UI_SCALE
	)

func _draw() -> void:
	var surface_size := _current_surface_size()
	if _layout.is_empty() or _layout.get("size") != surface_size:
		_apply_layout(surface_size)
	if _layout.is_empty():
		return
	var scale_factor: float = _layout["scale"]
	var alpha := _fade_in
	if _closing:
		alpha = minf(alpha, 1.0 - _close_progress)
	if alpha <= 0.001:
		return

	_draw_backdrop(surface_size, scale_factor, alpha)
	_draw_header(scale_factor, alpha)
	_draw_team_strip(scale_factor, alpha)
	if _selector_visible:
		_draw_selector(scale_factor, alpha)
	for index in range(_card_rects.size()):
		_draw_card(index, scale_factor, alpha)
	_draw_cursor(scale_factor, alpha)
	_draw_footer(scale_factor, alpha)
	if _closing:
		_draw_close_flash(surface_size, alpha)

func _draw_backdrop(surface_size: Vector2, scale_factor: float, alpha: float) -> void:
	draw_rect(Rect2(Vector2.ZERO, surface_size), _alpha(OVERLAY_COLOR, alpha))

	var strip_count := 18
	var strip_width := maxf(6.0 * scale_factor, 4.0)
	for index in range(strip_count):
		var strength := 1.0 - float(index) / float(strip_count)
		var glow_alpha := 0.04 * strength * alpha
		var x := float(index) * strip_width
		draw_rect(
			Rect2(x, 0.0, strip_width, surface_size.y),
			_alpha(LEFT_COLOR, glow_alpha)
		)
		draw_rect(
			Rect2(surface_size.x - x - strip_width, 0.0, strip_width, surface_size.y),
			_alpha(RIGHT_COLOR, glow_alpha)
		)

	var band_height := maxf(4.0 * scale_factor, 3.0)
	for index in range(6):
		var band_alpha := 0.055 * (1.0 - float(index) / 6.0) * alpha
		draw_rect(
			Rect2(0.0, float(index) * band_height, surface_size.x, band_height),
			Color(0.0, 0.0, 0.0, band_alpha)
		)
		draw_rect(
			Rect2(
				0.0,
				surface_size.y - float(index + 1) * band_height,
				surface_size.x,
				band_height
			),
			Color(0.0, 0.0, 0.0, band_alpha)
		)

	var scan_step := maxf(4.0 * scale_factor, 3.0)
	var scan_y := 0.0
	while scan_y < surface_size.y:
		draw_line(
			Vector2(0.0, scan_y),
			Vector2(surface_size.x, scan_y),
			Color(0.55, 0.8, 1.0, 0.016 * alpha),
			1.0
		)
		scan_y += scan_step

	var sweep_y := fmod(_time * 42.0 * scale_factor, surface_size.y + 180.0 * scale_factor)
	sweep_y -= 90.0 * scale_factor
	for index in range(4):
		var sweep_alpha := 0.035 * (1.0 - float(index) / 4.0) * alpha
		var line_y := sweep_y + float(index) * 2.0 * scale_factor
		draw_line(
			Vector2(0.0, line_y),
			Vector2(surface_size.x, line_y),
			Color(0.55, 0.85, 1.0, sweep_alpha),
			maxf(1.0, 1.5 * scale_factor)
		)

func _draw_header(scale_factor: float, alpha: float) -> void:
	var header: Rect2 = _layout["header"]
	var mark_center := Vector2(
		header.position.x + 18.0 * scale_factor,
		header.position.y + 26.0 * scale_factor
	)
	_draw_logo_mark(mark_center, scale_factor, alpha)

	var title_x := header.position.x + 44.0 * scale_factor
	var title_width := header.size.x - 44.0 * scale_factor
	var title_font_size := maxi(int(32.0 * scale_factor), 20)
	draw_string(
		_font,
		Vector2(title_x, header.position.y + 33.0 * scale_factor),
		_header_title(),
		HORIZONTAL_ALIGNMENT_LEFT,
		title_width,
		title_font_size,
		_alpha(TEXT_COLOR, alpha)
	)
	var subtitle_font_size := maxi(int(8.5 * scale_factor), 9)
	draw_string(
		_font,
		Vector2(title_x, header.position.y + 52.0 * scale_factor),
		_header_subtitle(),
		HORIZONTAL_ALIGNMENT_LEFT,
		title_width,
		subtitle_font_size,
		_alpha(MUTED_TEXT_COLOR, alpha)
	)

	var underline_y := header.position.y + 61.0 * scale_factor
	var line_width := maxf(1.0, 1.5 * scale_factor)
	draw_line(
		Vector2(title_x, underline_y),
		Vector2(title_x + 64.0 * scale_factor, underline_y),
		_alpha(LEFT_COLOR, alpha),
		line_width,
		true
	)
	draw_line(
		Vector2(title_x + 68.0 * scale_factor, underline_y),
		Vector2(title_x + 112.0 * scale_factor, underline_y),
		_alpha(RIGHT_COLOR, alpha),
		line_width,
		true
	)

	var status_width := 150.0 * scale_factor
	draw_string(
		_font,
		Vector2(header.end.x - status_width, header.position.y + 31.0 * scale_factor),
		_header_status(),
		HORIZONTAL_ALIGNMENT_RIGHT,
		status_width,
		maxi(int(9.0 * scale_factor), 8),
		_alpha(MUTED_TEXT_COLOR, alpha)
	)
	var live_text := _header_live_label()
	var live_font_size := maxi(int(8.0 * scale_factor), 8)
	var live_width := _font.get_string_size(
		live_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		live_font_size
	).x
	draw_string(
		_font,
		Vector2(header.end.x - live_width, header.position.y + 51.0 * scale_factor),
		live_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		live_width + 2.0,
		live_font_size,
		_alpha(TEXT_COLOR, alpha)
	)
	draw_circle(
		Vector2(
			header.end.x - live_width - 8.0 * scale_factor,
			header.position.y + 47.0 * scale_factor
		),
		maxf(2.4 * scale_factor, 2.0),
		_alpha(BALL_COLOR, alpha)
	)

func _header_title() -> String:
	return "CYBERPONG"

func _header_subtitle() -> String:
	return "SELECIONE O MODO DE JOGO"

func _header_status() -> String:
	return "MELHOR DE 5"

func _header_live_label() -> String:
	return "AO VIVO"

func _draw_logo_mark(center: Vector2, scale_factor: float, alpha: float) -> void:
	var frame_size := Vector2(30.0, 24.0) * scale_factor
	var frame := Rect2(center - frame_size * 0.5, frame_size)
	draw_rect(frame, _alpha(Color(0.035, 0.055, 0.09), 0.92 * alpha))
	draw_rect(
		frame,
		_alpha(DIVIDER_COLOR, alpha),
		false,
		maxf(1.0, 1.5 * scale_factor)
	)
	draw_rect(
		Rect2(center + Vector2(-8.0, -6.0) * scale_factor, Vector2(2.5, 12.0) * scale_factor),
		_alpha(LEFT_COLOR, alpha)
	)
	draw_rect(
		Rect2(center + Vector2(5.5, -6.0) * scale_factor, Vector2(2.5, 12.0) * scale_factor),
		_alpha(RIGHT_COLOR, alpha)
	)
	var radius := 4.5 * scale_factor
	var ball_mark := PackedVector2Array([
		center + Vector2(0.0, -radius),
		center + Vector2(radius, 0.0),
		center + Vector2(0.0, radius),
		center + Vector2(-radius, 0.0),
	])
	draw_colored_polygon(ball_mark, _alpha(BALL_COLOR, alpha))

func _draw_team_strip(scale_factor: float, alpha: float) -> void:
	var strip: Rect2 = _layout["strip"]
	var center := strip.get_center()
	var line_width := maxf(1.0, scale_factor)
	draw_line(
		Vector2(strip.position.x, center.y),
		Vector2(center.x - 36.0 * scale_factor, center.y),
		_alpha(Color(DIVIDER_COLOR, 0.55), alpha),
		line_width,
		true
	)
	draw_line(
		Vector2(center.x + 36.0 * scale_factor, center.y),
		Vector2(strip.end.x, center.y),
		_alpha(Color(DIVIDER_COLOR, 0.55), alpha),
		line_width,
		true
	)

	_draw_team_emblem(
		Vector2(strip.position.x + 14.0 * scale_factor, center.y),
		LEFT_COLOR,
		true,
		scale_factor,
		alpha
	)
	_draw_team_emblem(
		Vector2(strip.end.x - 14.0 * scale_factor, center.y),
		RIGHT_COLOR,
		false,
		scale_factor,
		alpha
	)

	var name_font_size := maxi(int(11.0 * scale_factor), 9)
	var name_width := strip.size.x * 0.5 - 60.0 * scale_factor
	draw_string(
		_font,
		Vector2(strip.position.x + 32.0 * scale_factor, center.y + 4.0 * scale_factor),
		"Cyan Circuit",
		HORIZONTAL_ALIGNMENT_LEFT,
		name_width,
		name_font_size,
		_alpha(LEFT_COLOR, alpha)
	)
	draw_string(
		_font,
		Vector2(
			strip.end.x - 32.0 * scale_factor - name_width,
			center.y + 4.0 * scale_factor
		),
		"Magenta Volt",
		HORIZONTAL_ALIGNMENT_RIGHT,
		name_width,
		name_font_size,
		_alpha(RIGHT_COLOR, alpha)
	)

	var bracket_size := 8.0 * scale_factor
	draw_polyline(
		PackedVector2Array([
			Vector2(center.x - 34.0 * scale_factor, center.y - bracket_size),
			Vector2(center.x - 42.0 * scale_factor, center.y),
			Vector2(center.x - 34.0 * scale_factor, center.y + bracket_size),
		]),
		_alpha(Color(LEFT_COLOR, 0.8), alpha),
		maxf(1.0, 1.5 * scale_factor),
		true
	)
	draw_polyline(
		PackedVector2Array([
			Vector2(center.x + 34.0 * scale_factor, center.y - bracket_size),
			Vector2(center.x + 42.0 * scale_factor, center.y),
			Vector2(center.x + 34.0 * scale_factor, center.y + bracket_size),
		]),
		_alpha(Color(RIGHT_COLOR, 0.8), alpha),
		maxf(1.0, 1.5 * scale_factor),
		true
	)
	draw_string(
		_font,
		Vector2(center.x - 30.0 * scale_factor, center.y + 5.0 * scale_factor),
		"VS",
		HORIZONTAL_ALIGNMENT_CENTER,
		60.0 * scale_factor,
		maxi(int(14.0 * scale_factor), 11),
		_alpha(TEXT_COLOR, alpha)
	)

func _draw_selector(scale_factor: float, alpha: float) -> void:
	if _selector_rects.is_empty() or not _selector_visible:
		return
	var label_rect: Rect2 = _layout["selector_label"]
	if not _selector_label.is_empty():
		var label_font_size := maxi(int(8.5 * scale_factor), 8)
		draw_string(
			_font,
			Vector2(
				label_rect.position.x,
				label_rect.get_center().y + label_font_size * 0.36
			),
			_selector_label,
			HORIZONTAL_ALIGNMENT_LEFT,
			label_rect.size.x,
			label_font_size,
			_alpha(MUTED_TEXT_COLOR, alpha)
		)

	for index in range(_selector_rects.size()):
		var rect: Rect2 = _selector_rects[index]
		var button := _selector_buttons[index]
		var selected := index == _selector_selected_index
		var hovered := button.is_hovered()
		var cut := maxf(6.0 * scale_factor, 4.0)
		var points := _angular_points(rect, cut)
		var fill := PANEL_COLOR
		if selected:
			fill = Color(0.035, 0.075, 0.115, 0.97)
		elif hovered:
			fill = PANEL_HOVER_COLOR
		draw_colored_polygon(points, _alpha(fill, alpha))

		var outline := points.duplicate()
		outline.append(points[0])
		var border_color := Color(DIVIDER_COLOR, 0.62 if hovered else 0.42)
		if selected:
			border_color = LEFT_COLOR.lerp(RIGHT_COLOR, float(index) / float(maxi(_selector_rects.size() - 1, 1)))
			border_color.a = 0.9
		elif hovered:
			border_color = Color(0.55, 0.75, 0.95, 0.55)
		draw_polyline(
			outline,
			_alpha(border_color, alpha),
			maxf(1.0, 1.5 * scale_factor),
			true
		)
		if selected:
			draw_line(
				Vector2(rect.position.x + cut, rect.end.y - maxf(1.0, 2.0 * scale_factor)),
				Vector2(rect.end.x - cut, rect.end.y - maxf(1.0, 2.0 * scale_factor)),
				_alpha(BALL_COLOR, 0.9 * alpha),
				maxf(1.0, 2.0 * scale_factor),
				true
			)

		var title := String(_selector_titles[index]) if index < _selector_titles.size() else ""
		var title_font_size := _fit_font_size(
			_font,
			title,
			maxi(int(11.0 * scale_factor), 10),
			maxi(int(8.0 * scale_factor), 8),
			rect.size.x - 16.0 * scale_factor
		)
		draw_string(
			_font,
			Vector2(
				rect.position.x,
				rect.get_center().y + title_font_size * 0.36
			),
			title,
			HORIZONTAL_ALIGNMENT_CENTER,
			rect.size.x,
			title_font_size,
			_alpha(TEXT_COLOR if selected or hovered else MUTED_TEXT_COLOR, alpha)
		)

func _draw_card(index: int, scale_factor: float, alpha: float) -> void:
	var rect: Rect2 = _card_rects[index]
	var card: Dictionary = _cards[index]
	var button := _card_buttons[index]
	var focused := (button.has_focus() or index == _focused_index) and not _selected
	var hovered := button.is_hovered()
	var cut := maxf(8.0 * scale_factor, 6.0)
	var points := _angular_points(rect, cut)
	var fill := PANEL_FOCUS_COLOR
	if not focused:
		fill = PANEL_HOVER_COLOR if hovered else PANEL_COLOR
	draw_colored_polygon(points, _alpha(fill, alpha))

	var outline := points.duplicate()
	outline.append(points[0])
	if focused:
		draw_polyline(
			outline,
			_alpha(Color(0.55, 0.8, 1.0, 0.12), alpha),
			maxf(6.0, 8.0 * scale_factor),
			true
		)
	var border_color := Color(0.55, 0.75, 0.95, 0.85)
	if not focused:
		border_color = Color(DIVIDER_COLOR, 0.62 if hovered else 0.42)
	draw_polyline(
		outline,
		_alpha(border_color, alpha),
		maxf(1.0, 1.5 * scale_factor),
		true
	)
	_draw_top_gradient(rect, cut, scale_factor, focused, alpha)
	draw_rect(
		Rect2(
			rect.position + Vector2(0.0, cut),
			Vector2(maxf(2.0, 3.0 * scale_factor), rect.size.y - cut * 2.0)
		),
		_alpha(BALL_COLOR if focused else DIVIDER_COLOR, (0.9 if focused else 0.45) * alpha)
	)

	var padding_left := 20.0 * scale_factor
	var tag: String = card["tag"]
	var tag_font_size := maxi(int(7.5 * scale_factor), 8)
	var tag_text_width := _font.get_string_size(
		tag,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		tag_font_size
	).x
	var tag_width := tag_text_width + 10.0 * scale_factor
	var tag_x := rect.end.x - 16.0 * scale_factor - tag_width
	draw_string(
		_font,
		Vector2(tag_x, rect.position.y + 20.0 * scale_factor),
		tag,
		HORIZONTAL_ALIGNMENT_LEFT,
		tag_width + 2.0,
		tag_font_size,
		_alpha(MUTED_TEXT_COLOR, 0.9 * alpha)
	)

	var title_max_width := tag_x - (rect.position.x + padding_left) - 10.0 * scale_factor
	var title: String = card["title"]
	var title_font_size := _fit_font_size(
		_font,
		title,
		maxi(int(15.0 * scale_factor), 12),
		maxi(int(10.0 * scale_factor), 10),
		title_max_width
	)
	draw_string(
		_font,
		Vector2(rect.position.x + padding_left, rect.position.y + 28.0 * scale_factor),
		title,
		HORIZONTAL_ALIGNMENT_LEFT,
		title_max_width,
		title_font_size,
		_alpha(TEXT_COLOR, alpha)
	)

	var detail_width := rect.size.x - padding_left - 16.0 * scale_factor
	var detail: String = card["detail"]
	var detail_font_size := _fit_font_size(
		_font,
		detail,
		maxi(int(8.5 * scale_factor), 9),
		maxi(int(8.0 * scale_factor), 8),
		detail_width
	)
	draw_string(
		_font,
		Vector2(rect.position.x + padding_left, rect.position.y + 46.0 * scale_factor),
		detail,
		HORIZONTAL_ALIGNMENT_LEFT,
		detail_width,
		detail_font_size,
		_alpha(MUTED_TEXT_COLOR, alpha)
	)

	if focused:
		_draw_focus_brackets(rect, cut, scale_factor, alpha)
	if _closing and index == _closing_index:
		draw_colored_polygon(points, _alpha(BALL_COLOR, 0.16 * (1.0 - _close_progress)))

func _draw_top_gradient(
	rect: Rect2,
	cut: float,
	scale_factor: float,
	focused: bool,
	alpha: float
) -> void:
	var start_x := rect.position.x + cut
	var end_x := rect.end.x - cut
	var segments := 16
	var line_alpha := (0.95 if focused else 0.32) * alpha
	for segment in range(segments):
		var start_ratio := float(segment) / float(segments)
		var end_ratio := float(segment + 1) / float(segments)
		var color := LEFT_COLOR.lerp(RIGHT_COLOR, (start_ratio + end_ratio) * 0.5)
		draw_line(
			Vector2(lerpf(start_x, end_x, start_ratio), rect.position.y),
			Vector2(lerpf(start_x, end_x, end_ratio), rect.position.y),
			_alpha(color, line_alpha),
			maxf(1.0, 2.0 * scale_factor),
			true
		)

func _draw_focus_brackets(
	rect: Rect2,
	cut: float,
	scale_factor: float,
	alpha: float
) -> void:
	var line_width := maxf(1.0, 2.0 * scale_factor)
	for segment in _focus_bracket_segments(rect, cut, scale_factor):
		draw_line(
			segment[0],
			segment[1],
			_alpha(segment[2], alpha),
			line_width,
			true
		)

func _focus_bracket_segments(rect: Rect2, cut: float, scale_factor: float) -> Array:
	var arm := 10.0 * scale_factor
	var inset := 5.0 * scale_factor
	var left_top := Vector2(rect.position.x + cut + inset, rect.position.y + inset)
	var left_bottom := Vector2(rect.position.x + cut + inset, rect.end.y - inset)
	var right_top := Vector2(rect.end.x - cut - inset, rect.position.y + inset)
	var right_bottom := Vector2(rect.end.x - cut - inset, rect.end.y - inset)
	return [
		[left_top, left_top + Vector2(arm, 0.0), LEFT_COLOR],
		[left_top, left_top + Vector2(0.0, arm), LEFT_COLOR],
		[left_bottom, left_bottom + Vector2(arm, 0.0), LEFT_COLOR],
		[left_bottom, left_bottom - Vector2(0.0, arm), LEFT_COLOR],
		[right_top, right_top - Vector2(arm, 0.0), RIGHT_COLOR],
		[right_top, right_top + Vector2(0.0, arm), RIGHT_COLOR],
		[right_bottom, right_bottom - Vector2(arm, 0.0), RIGHT_COLOR],
		[right_bottom, right_bottom - Vector2(0.0, arm), RIGHT_COLOR],
	]

func _draw_cursor(scale_factor: float, alpha: float) -> void:
	if _card_rects.is_empty():
		return
	var cursor_x: float = _layout["cursor_x"]
	var cursor_y := _cursor_y
	if is_zero_approx(cursor_y):
		cursor_y = _card_rects[_focused_index].get_center().y
	var pulse := 1.0 + 0.12 * sin(_time * 4.0)
	var radius := maxf(5.0 * scale_factor, 3.0) * pulse
	draw_circle(Vector2(cursor_x, cursor_y), radius * 2.6, _alpha(Color(BALL_COLOR, 0.07), alpha))
	for index in range(3):
		var offset := float(index + 1) * 7.0 * scale_factor
		draw_line(
			Vector2(cursor_x - offset - 8.0 * scale_factor, cursor_y),
			Vector2(cursor_x - offset, cursor_y),
			_alpha(Color(BALL_COLOR, 0.25 - float(index) * 0.06), alpha),
			maxf(1.0, 1.5 * scale_factor),
			true
		)
	var cursor_points := PackedVector2Array([
		Vector2(cursor_x, cursor_y - radius),
		Vector2(cursor_x + radius, cursor_y),
		Vector2(cursor_x, cursor_y + radius),
		Vector2(cursor_x - radius, cursor_y),
	])
	draw_colored_polygon(cursor_points, _alpha(BALL_COLOR, alpha))
	draw_circle(
		Vector2(cursor_x, cursor_y),
		maxf(1.2 * scale_factor, 1.0),
		_alpha(Color(0.02, 0.03, 0.05), alpha)
	)

func _draw_footer(scale_factor: float, alpha: float) -> void:
	var footer: Rect2 = _layout["footer"]
	var key_font_size := maxi(int(8.0 * scale_factor), 8)
	var label_font_size := maxi(int(8.0 * scale_factor), 8)
	var gap := 20.0 * scale_factor
	var hints := _footer_hints()
	var widths: Array = []
	var total_width := 0.0
	for hint in hints:
		var key_width := maxf(
			_font.get_string_size(hint[0], HORIZONTAL_ALIGNMENT_LEFT, -1, key_font_size).x
			+ 14.0 * scale_factor,
			30.0 * scale_factor
		)
		var label_width := _font.get_string_size(
			hint[1],
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			label_font_size
		).x
		widths.append([key_width, label_width])
		total_width += key_width + 6.0 * scale_factor + label_width
	total_width += gap * 2.0

	var x := footer.get_center().x - total_width * 0.5
	var key_height := maxf(14.0 * scale_factor, 12.0)
	var key_y := footer.get_center().y - key_height * 0.5
	for index in range(hints.size()):
		var hint: Array = hints[index]
		var sizes: Array = widths[index]
		var key_width: float = sizes[0]
		var label_width: float = sizes[1]
		var key_rect := Rect2(Vector2(x, key_y), Vector2(key_width, key_height))
		draw_rect(key_rect, _alpha(Color(0.04, 0.07, 0.11), 0.9 * alpha))
		draw_rect(
			key_rect,
			_alpha(Color(DIVIDER_COLOR, 0.8), alpha),
			false,
			maxf(1.0, 1.0 * scale_factor)
		)
		draw_string(
			_font,
			Vector2(key_rect.position.x, key_rect.position.y + key_height * 0.7),
			hint[0],
			HORIZONTAL_ALIGNMENT_CENTER,
			key_width,
			key_font_size,
			_alpha(TEXT_COLOR, alpha)
		)
		draw_string(
			_font,
			Vector2(key_rect.end.x + 6.0 * scale_factor, key_rect.position.y + key_height * 0.7),
			hint[1],
			HORIZONTAL_ALIGNMENT_LEFT,
			label_width + 2.0,
			label_font_size,
			_alpha(MUTED_TEXT_COLOR, alpha)
		)
		x += key_width + 6.0 * scale_factor + label_width
		if index < hints.size() - 1:
			x += gap

func _footer_hints() -> Array:
	return [["↑↓", "NAVEGAR"], ["ENTER", "CONFIRMAR"], ["MOUSE", "SELECIONAR"]]

func _draw_close_flash(surface_size: Vector2, alpha: float) -> void:
	var strength := 1.0 - _close_progress
	if strength <= 0.0:
		return
	if _closing_index >= 0 and _closing_index < _card_rects.size():
		var rect: Rect2 = _card_rects[_closing_index]
		draw_rect(rect, _alpha(BALL_COLOR, 0.08 * strength))
	draw_rect(
		Rect2(Vector2.ZERO, surface_size),
		Color(0.55, 0.85, 1.0, 0.035 * strength * alpha)
	)

func _draw_team_emblem(
	center: Vector2,
	team_color: Color,
	is_left: bool,
	emblem_scale: float,
	alpha: float
) -> void:
	var draw_color := _alpha(team_color, alpha)
	if is_left:
		var hexagon := PackedVector2Array()
		for point_index in range(7):
			var angle := -PI * 0.5 + TAU * float(point_index % 6) / 6.0
			hexagon.append(center + Vector2(cos(angle), sin(angle)) * 10.0 * emblem_scale)
		draw_polyline(hexagon, draw_color, maxf(1.0, 1.8 * emblem_scale), true)
		draw_line(
			center,
			center + Vector2(5.0, -5.0) * emblem_scale,
			draw_color,
			maxf(1.0, 1.4 * emblem_scale),
			true
		)
		draw_line(
			center,
			center + Vector2(-5.0, 5.0) * emblem_scale,
			draw_color,
			maxf(1.0, 1.4 * emblem_scale),
			true
		)
		draw_circle(center, 2.0 * emblem_scale, _alpha(TEXT_COLOR, alpha))
	else:
		var diamond := PackedVector2Array([
			center + Vector2(0.0, -11.0) * emblem_scale,
			center + Vector2(11.0, 0.0) * emblem_scale,
			center + Vector2(0.0, 11.0) * emblem_scale,
			center + Vector2(-11.0, 0.0) * emblem_scale,
			center + Vector2(0.0, -11.0) * emblem_scale,
		])
		draw_polyline(diamond, draw_color, maxf(1.0, 1.8 * emblem_scale), true)
		var bolt := PackedVector2Array([
			center + Vector2(1.0, -7.0) * emblem_scale,
			center + Vector2(-4.0, 1.0) * emblem_scale,
			center + Vector2(-1.0, 1.0) * emblem_scale,
			center + Vector2(-2.0, 7.0) * emblem_scale,
			center + Vector2(4.0, -1.0) * emblem_scale,
			center + Vector2(1.0, -1.0) * emblem_scale,
		])
		draw_colored_polygon(bolt, draw_color)

func _angular_points(rect: Rect2, cut: float) -> PackedVector2Array:
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

func _fit_font_size(
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

func _alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, color.a * alpha)
