extends Node2D

const BACKGROUND_COLOR := Color(0.018, 0.03, 0.052)
const FIELD_COLOR := Color(0.035, 0.055, 0.09)
const FIELD_CENTER_COLOR := Color(0.047, 0.069, 0.105)
const DIVIDER_COLOR := Color(0.18, 0.24, 0.32)
const TEXT_COLOR := Color(0.9, 0.94, 1.0)
const MUTED_TEXT_COLOR := Color(0.58, 0.68, 0.8)
const LEFT_COLOR := Color(0.08, 0.98, 1.0)
const RIGHT_COLOR := Color(1.0, 0.12, 0.72)
const HUD_PANEL_COLOR := Color(0.012, 0.022, 0.04)
const FIELD_BORDER_COLOR := Color(0.08, 0.98, 1.0, 0.45)
const SCORE_LEFT_PANEL := Color(0.035, 0.22, 0.26, 0.72)
const SCORE_RIGHT_PANEL := Color(0.28, 0.035, 0.18, 0.72)
const COUNT_BADGE_COLOR := Color(0.08, 0.98, 1.0, 0.12)
const GAME_TITLE := "CYBERPONG"
const LEFT_TEAM_NAME := "Cyan Circuit"
const RIGHT_TEAM_NAME := "Magenta Volt"
const POINT_FLASH_DURATION := 0.72
const RALLY_INTRO_DURATION := 1.0
const WINNER_REVEAL_DURATION := 0.55
const FIELD_GRADIENT_STRIPS := 48
const VIGNETTE_BANDS := 8

var game_scale := 3.0
var hud_bar_height := 180.0
var paddle_margin := 120.0
var game_over := false
var left_score := 0
var right_score := 0
var winner_name := ""
var winner_is_left := true
var total_rebounds := 0
var power_up_hud_title := ""
var power_up_hud_detail := ""
var power_up_hud_progress := 0.0
var power_up_hud_accent := MUTED_TEXT_COLOR
var power_up_hud_show_progress := false
var point_flash_remaining := 0.0
var point_flash_is_left := true
var rally_intro_remaining := 0.0
var rally_intro_is_left := true
var winner_reveal := 0.0

func _process(delta: float) -> void:
	var should_redraw := false
	if point_flash_remaining > 0.0:
		point_flash_remaining = maxf(point_flash_remaining - delta, 0.0)
		should_redraw = true
	if rally_intro_remaining > 0.0:
		rally_intro_remaining = maxf(rally_intro_remaining - delta, 0.0)
		should_redraw = true
	if game_over and winner_reveal < 1.0:
		winner_reveal = minf(winner_reveal + delta / WINNER_REVEAL_DURATION, 1.0)
		should_redraw = true
	if should_redraw:
		queue_redraw()

func configure(scale: float, bar_height: float = 0.0, margin: float = 120.0) -> void:
	game_scale = scale
	hud_bar_height = bar_height
	paddle_margin = margin
	queue_redraw()

func set_game_over(value: bool) -> void:
	game_over = value
	if not value:
		winner_name = ""
		point_flash_remaining = 0.0
		rally_intro_remaining = 0.0
		winner_reveal = 0.0
	queue_redraw()

func set_score(left_value: int, right_value: int) -> void:
	left_score = left_value
	right_score = right_value
	queue_redraw()

func set_match_hud(rebound_count: int, power_up_info: Dictionary) -> void:
	total_rebounds = rebound_count
	power_up_hud_title = str(power_up_info.get("title", ""))
	power_up_hud_detail = str(power_up_info.get("detail", ""))
	power_up_hud_progress = clampf(float(power_up_info.get("progress", 0.0)), 0.0, 1.0)
	power_up_hud_accent = power_up_info.get("accent_color", MUTED_TEXT_COLOR)
	power_up_hud_show_progress = bool(power_up_info.get("show_progress", false))
	queue_redraw()

func set_winner(name: String) -> void:
	winner_name = name
	winner_is_left = name.to_lower() == LEFT_TEAM_NAME.to_lower()
	game_over = true
	rally_intro_remaining = 0.0
	point_flash_remaining = 0.0
	winner_reveal = 0.0
	queue_redraw()

func show_point_awarded(is_left: bool) -> void:
	point_flash_is_left = is_left
	point_flash_remaining = POINT_FLASH_DURATION
	queue_redraw()

func show_rally_intro(server_is_left: bool) -> void:
	rally_intro_is_left = server_is_left
	rally_intro_remaining = RALLY_INTRO_DURATION
	queue_redraw()

func _draw() -> void:
	var size := get_viewport_rect().size
	var ui_scale := _hud_scale_for(size)
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND_COLOR)
	var field_margin := 12.0 * game_scale
	var field_rect := Rect2(
		Vector2(field_margin, hud_bar_height),
		Vector2(size.x - field_margin * 2.0, size.y - hud_bar_height)
	)
	draw_rect(field_rect, FIELD_COLOR)
	_draw_field_backdrop(field_rect)
	_draw_field_markings(field_rect)
	_draw_arena_frame(field_rect)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, hud_bar_height)), HUD_PANEL_COLOR)
	draw_rect(Rect2(0.0, hud_bar_height - 2.0 * game_scale, size.x, 2.0 * game_scale), FIELD_BORDER_COLOR)

	for y in range(int(hud_bar_height + 12.0 * game_scale), int(size.y - 12.0 * game_scale), 30 * int(game_scale)):
		draw_rect(Rect2(size.x * 0.5 - 2.0 * game_scale, float(y), 4.0 * game_scale, 14.0 * game_scale), DIVIDER_COLOR)
	_draw_goal_lines(size)
	_draw_point_flash(size)
	var font := ThemeDB.fallback_font
	_draw_rally_intro(font, size, ui_scale)

	_draw_game_logo(font, ui_scale)
	_draw_rebound_badge(font, ui_scale)
	_draw_score(font, size, ui_scale)
	_draw_power_up_status(font, size, ui_scale)

	if game_over:
		_draw_winner_panel(font, size, ui_scale)

func _hud_scale_for(size: Vector2) -> float:
	return minf(game_scale, maxf(size.x / 960.0, 0.55))

func _draw_field_backdrop(field_rect: Rect2) -> void:
	var strip_width := field_rect.size.x / float(FIELD_GRADIENT_STRIPS)
	for strip_index in range(FIELD_GRADIENT_STRIPS):
		var strip_x := field_rect.position.x + float(strip_index) * strip_width
		var strip_center := strip_x + strip_width * 0.5
		var center_distance := absf((strip_center - field_rect.get_center().x) / (field_rect.size.x * 0.5))
		var center_glow := pow(1.0 - center_distance, 1.4) * 0.7
		var strip_color := FIELD_COLOR.lerp(FIELD_CENTER_COLOR, center_glow)
		draw_rect(
			Rect2(Vector2(strip_x, field_rect.position.y), Vector2(strip_width + 1.0, field_rect.size.y)),
			strip_color
		)

	var band_size := 4.0 * game_scale
	for band_index in range(VIGNETTE_BANDS):
		var vignette_alpha := 0.075 * (1.0 - float(band_index) / float(VIGNETTE_BANDS))
		var offset := float(band_index) * band_size
		var vignette_color := Color(0.0, 0.0, 0.0, vignette_alpha)
		draw_rect(
			Rect2(field_rect.position + Vector2(0.0, offset), Vector2(field_rect.size.x, band_size)),
			vignette_color
		)
		draw_rect(
			Rect2(Vector2(field_rect.position.x, field_rect.end.y - offset - band_size), Vector2(field_rect.size.x, band_size)),
			vignette_color
		)
		draw_rect(
			Rect2(field_rect.position + Vector2(offset, 0.0), Vector2(band_size, field_rect.size.y)),
			vignette_color
		)
		draw_rect(
			Rect2(Vector2(field_rect.end.x - offset - band_size, field_rect.position.y), Vector2(band_size, field_rect.size.y)),
			vignette_color
		)

func _draw_field_markings(field_rect: Rect2) -> void:
	var center := field_rect.get_center()
	draw_arc(center, 56.0 * game_scale, 0.0, TAU, 64, Color(DIVIDER_COLOR, 0.34), 1.0 * game_scale, true)
	draw_circle(center, 2.0 * game_scale, Color(MUTED_TEXT_COLOR, 0.42))

	for height_fraction in [0.25, 0.75]:
		var marker_y: float = field_rect.position.y + field_rect.size.y * height_fraction
		draw_line(
			Vector2(field_rect.position.x + 10.0 * game_scale, marker_y),
			Vector2(field_rect.position.x + 22.0 * game_scale, marker_y),
			Color(LEFT_COLOR, 0.28),
			1.0 * game_scale,
			true
		)
		draw_line(
			Vector2(field_rect.end.x - 22.0 * game_scale, marker_y),
			Vector2(field_rect.end.x - 10.0 * game_scale, marker_y),
			Color(RIGHT_COLOR, 0.28),
			1.0 * game_scale,
			true
		)

func _draw_arena_frame(field_rect: Rect2) -> void:
	var left := field_rect.position.x
	var top := field_rect.position.y
	var right := field_rect.end.x
	var bottom := field_rect.end.y
	var corner_cut := 14.0 * game_scale
	var corner_span := 24.0 * game_scale
	var outline := PackedVector2Array([
		Vector2(left + corner_cut, top),
		Vector2(right - corner_cut, top),
		Vector2(right, top + corner_cut),
		Vector2(right, bottom - corner_cut),
		Vector2(right - corner_cut, bottom),
		Vector2(left + corner_cut, bottom),
		Vector2(left, bottom - corner_cut),
		Vector2(left, top + corner_cut),
		Vector2(left + corner_cut, top),
	])
	draw_polyline(outline, Color(DIVIDER_COLOR, 0.78), 1.5 * game_scale, true)
	draw_rect(field_rect.grow(-8.0 * game_scale), Color(DIVIDER_COLOR, 0.13), false, 1.0 * game_scale)
	draw_line(Vector2(left, top + corner_cut), Vector2(left, bottom - corner_cut), Color(LEFT_COLOR, 0.74), 2.0 * game_scale, true)
	draw_line(Vector2(right, top + corner_cut), Vector2(right, bottom - corner_cut), Color(RIGHT_COLOR, 0.74), 2.0 * game_scale, true)

	for is_left in [true, false]:
		var side_x := left if is_left else right
		var horizontal_direction := 1.0 if is_left else -1.0
		var team_color := LEFT_COLOR if is_left else RIGHT_COLOR
		for is_top in [true, false]:
			var corner_y := top if is_top else bottom
			var vertical_direction := 1.0 if is_top else -1.0
			draw_line(
				Vector2(side_x + horizontal_direction * corner_cut, corner_y),
				Vector2(side_x + horizontal_direction * (corner_cut + corner_span), corner_y),
				team_color,
				2.5 * game_scale,
				true
			)
			draw_line(
				Vector2(side_x, corner_y + vertical_direction * corner_cut),
				Vector2(side_x, corner_y + vertical_direction * (corner_cut + corner_span)),
				team_color,
				2.5 * game_scale,
				true
			)

func _draw_game_logo(font: Font, ui_scale: float) -> void:
	var center := Vector2(107.0 * ui_scale, hud_bar_height * 0.5)
	var frame_size := Vector2(26.0, 22.0) * ui_scale
	var frame := Rect2(center - frame_size * 0.5, frame_size)
	draw_rect(frame, Color(FIELD_COLOR, 0.9))
	draw_rect(frame, Color(DIVIDER_COLOR, 0.9), false, 1.5 * ui_scale)
	draw_rect(
		Rect2(center + Vector2(-8.0, -5.0) * ui_scale, Vector2(2.5, 10.0) * ui_scale),
		LEFT_COLOR
	)
	draw_rect(
		Rect2(center + Vector2(5.5, -5.0) * ui_scale, Vector2(2.5, 10.0) * ui_scale),
		RIGHT_COLOR
	)
	var ball_mark := PackedVector2Array([
		center + Vector2(0.0, -4.0) * ui_scale,
		center + Vector2(4.0, 0.0) * ui_scale,
		center + Vector2(0.0, 4.0) * ui_scale,
		center + Vector2(-4.0, 0.0) * ui_scale,
	])
	draw_colored_polygon(ball_mark, Color(1.0, 0.92, 0.12))

	var title_position := Vector2(125.0 * ui_scale, center.y + 6.0 * ui_scale)
	draw_string(font, title_position, GAME_TITLE, HORIZONTAL_ALIGNMENT_LEFT, 150.0 * ui_scale, maxi(int(13.0 * ui_scale), 10), TEXT_COLOR)
	draw_line(
		Vector2(title_position.x, center.y + 14.0 * ui_scale),
		Vector2(title_position.x + 45.0 * ui_scale, center.y + 14.0 * ui_scale),
		LEFT_COLOR,
		1.5 * ui_scale,
		true
	)
	draw_line(
		Vector2(title_position.x + 49.0 * ui_scale, center.y + 14.0 * ui_scale),
		Vector2(title_position.x + 72.0 * ui_scale, center.y + 14.0 * ui_scale),
		RIGHT_COLOR,
		1.5 * ui_scale,
		true
	)

func _draw_point_flash(size: Vector2) -> void:
	if point_flash_remaining <= 0.0:
		return
	var strength := point_flash_remaining / POINT_FLASH_DURATION
	var team_color := LEFT_COLOR if point_flash_is_left else RIGHT_COLOR
	var field_margin := 12.0 * game_scale
	var field_left := field_margin
	var field_right := size.x - field_margin
	var play_height := size.y - hud_bar_height
	var wash_width := minf(size.x * 0.16, 170.0 * game_scale)
	var strip_count := 12
	var strip_width := wash_width / float(strip_count)
	for strip_index in range(strip_count):
		var depth := float(strip_index) / float(strip_count)
		var strip_x := field_left + float(strip_index) * strip_width
		if not point_flash_is_left:
			strip_x = field_right - float(strip_index + 1) * strip_width
		draw_rect(
			Rect2(Vector2(strip_x, hud_bar_height), Vector2(strip_width + 1.0, play_height)),
			Color(team_color, 0.11 * strength * (1.0 - depth))
		)
	var goal_x := field_left if point_flash_is_left else field_right
	draw_line(
		Vector2(goal_x, hud_bar_height),
		Vector2(goal_x, size.y),
		Color(team_color, 0.32 + 0.5 * strength),
		7.0 * game_scale,
		true
	)

func _draw_rally_intro(font: Font, size: Vector2, ui_scale: float) -> void:
	if rally_intro_remaining <= 0.0:
		return
	var elapsed := RALLY_INTRO_DURATION - rally_intro_remaining
	var fade_in := clampf(elapsed / 0.12, 0.0, 1.0)
	var fade_out := clampf(rally_intro_remaining / 0.24, 0.0, 1.0)
	var alpha := minf(fade_in, fade_out)
	if alpha <= 0.0:
		return
	var team_color := LEFT_COLOR if rally_intro_is_left else RIGHT_COLOR
	var team_name := LEFT_TEAM_NAME if rally_intro_is_left else RIGHT_TEAM_NAME
	var banner_size := Vector2(minf(size.x * 0.34, 330.0 * ui_scale), maxf(44.0 * ui_scale, 26.0))
	var banner_position := Vector2(
		(size.x - banner_size.x) * 0.5,
		hud_bar_height + 18.0 * ui_scale + (1.0 - fade_in) * 8.0 * ui_scale
	)
	var banner := Rect2(banner_position, banner_size)
	draw_rect(banner, Color(0.01, 0.02, 0.035, 0.88 * alpha))
	draw_rect(banner, Color(team_color, 0.55 * alpha), false, 1.5 * ui_scale)
	draw_rect(
		Rect2(banner.position, Vector2(4.0 * ui_scale, banner.size.y)),
		Color(team_color, alpha)
	)
	var emblem_center := banner.position + Vector2(22.0 * ui_scale, banner.size.y * 0.5)
	_draw_team_emblem(emblem_center, team_color, rally_intro_is_left, ui_scale, alpha)
	var text_x := banner.position.x + 42.0 * ui_scale
	var text_width := banner.size.x - 54.0 * ui_scale
	draw_string(
		font,
		Vector2(text_x, banner.position.y + banner.size.y * 0.4),
		"SAQUE",
		HORIZONTAL_ALIGNMENT_LEFT,
		text_width,
		maxi(int(7.0 * ui_scale), 7),
		Color(MUTED_TEXT_COLOR, alpha)
	)
	draw_string(
		font,
		Vector2(text_x, banner.position.y + banner.size.y * 0.78),
		team_name.to_upper(),
		HORIZONTAL_ALIGNMENT_LEFT,
		text_width,
		maxi(int(13.0 * ui_scale), 9),
		Color(TEXT_COLOR, alpha)
	)

func _draw_winner_panel(font: Font, size: Vector2, ui_scale: float) -> void:
	var reveal := 1.0 - pow(1.0 - clampf(winner_reveal, 0.0, 1.0), 3.0)
	var team_color := LEFT_COLOR if winner_is_left else RIGHT_COLOR
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.003, 0.008, 0.016, 0.78 * reveal))
	var panel_size := Vector2(560.0, 260.0) * ui_scale * lerpf(0.94, 1.0, reveal)
	var panel_center := size * 0.5 + Vector2(0.0, (1.0 - reveal) * 16.0 * ui_scale)
	var panel := Rect2(panel_center - panel_size * 0.5, panel_size)
	draw_rect(panel.grow(18.0 * ui_scale), Color(team_color, 0.05 * reveal))
	draw_rect(panel, Color(0.02, 0.035, 0.06, 0.97 * reveal))
	draw_rect(panel, Color(team_color, 0.7 * reveal), false, 2.0 * ui_scale)
	draw_rect(
		Rect2(panel.position, Vector2(panel.size.x, 4.0 * ui_scale)),
		Color(team_color, reveal)
	)
	draw_string(
		font,
		Vector2(panel.position.x, panel.position.y + 28.0 * ui_scale),
		"PARTIDA ENCERRADA",
		HORIZONTAL_ALIGNMENT_CENTER,
		panel.size.x,
		maxi(int(8.0 * ui_scale), 8),
		Color(MUTED_TEXT_COLOR, reveal)
	)
	_draw_team_emblem(
		Vector2(panel.get_center().x, panel.position.y + 62.0 * ui_scale),
		team_color,
		winner_is_left,
		ui_scale,
		reveal
	)
	var title_text := "%s VENCEU!" % winner_name.to_upper()
	draw_string(
		font,
		Vector2(panel.position.x, panel.position.y + 108.0 * ui_scale),
		title_text,
		HORIZONTAL_ALIGNMENT_CENTER,
		panel.size.x,
		maxi(int(25.0 * ui_scale), 12),
		Color(team_color, reveal)
	)
	var score_y := panel.position.y + 148.0 * ui_scale
	var score_font_size := maxi(int(24.0 * ui_scale), 12)
	draw_string(
		font,
		Vector2(panel.position.x + 30.0 * ui_scale, score_y),
		str(left_score),
		HORIZONTAL_ALIGNMENT_RIGHT,
		panel.size.x * 0.5 - 48.0 * ui_scale,
		score_font_size,
		Color(LEFT_COLOR, reveal)
	)
	draw_string(
		font,
		Vector2(panel.get_center().x - 16.0 * ui_scale, score_y),
		"×",
		HORIZONTAL_ALIGNMENT_CENTER,
		32.0 * ui_scale,
		score_font_size,
		Color(MUTED_TEXT_COLOR, reveal)
	)
	draw_string(
		font,
		Vector2(panel.get_center().x + 18.0 * ui_scale, score_y),
		str(right_score),
		HORIZONTAL_ALIGNMENT_LEFT,
		panel.size.x * 0.5 - 48.0 * ui_scale,
		score_font_size,
		Color(RIGHT_COLOR, reveal)
	)
	draw_string(
		font,
		Vector2(panel.position.x, panel.position.y + 176.0 * ui_scale),
		"MELHOR DE 5",
		HORIZONTAL_ALIGNMENT_CENTER,
		panel.size.x,
		maxi(int(8.0 * ui_scale), 8),
		Color(MUTED_TEXT_COLOR, reveal)
	)
	draw_line(
		Vector2(panel.position.x + 40.0 * ui_scale, panel.position.y + 194.0 * ui_scale),
		Vector2(panel.end.x - 40.0 * ui_scale, panel.position.y + 194.0 * ui_scale),
		Color(team_color, 0.32 * reveal),
		ui_scale,
		true
	)
	var instruction_font_size := maxi(int(12.0 * ui_scale), 9)
	var instruction_text := "NOVA PARTIDA"
	var instruction_width := font.get_string_size(
		instruction_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		instruction_font_size
	).x
	var key_size := Vector2(62.0, 28.0) * ui_scale
	var group_width := key_size.x + 12.0 * ui_scale + instruction_width
	var group_left := panel.get_center().x - group_width * 0.5
	var instruction_y := panel.position.y + 215.0 * ui_scale
	var key_rect := Rect2(Vector2(group_left, instruction_y), key_size)
	draw_rect(key_rect, Color(0.04, 0.07, 0.11, reveal))
	draw_rect(key_rect, Color(team_color, 0.75 * reveal), false, 1.5 * ui_scale)
	draw_string(
		font,
		Vector2(key_rect.position.x, key_rect.position.y + key_size.y * 0.68),
		"ENTER",
		HORIZONTAL_ALIGNMENT_CENTER,
		key_size.x,
		maxi(int(9.0 * ui_scale), 8),
		Color(TEXT_COLOR, reveal)
	)
	draw_string(
		font,
		Vector2(key_rect.end.x + 12.0 * ui_scale, instruction_y + key_size.y * 0.68),
		instruction_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		instruction_width + 4.0,
		instruction_font_size,
		Color(TEXT_COLOR, reveal)
	)

func _draw_goal_lines(size: Vector2) -> void:
	var field_margin := 12.0 * game_scale
	var left_line_x := field_margin
	var right_line_x := size.x - field_margin
	var line_width := 4.0 * game_scale
	draw_line(
		Vector2(left_line_x, hud_bar_height),
		Vector2(left_line_x, size.y),
		LEFT_COLOR,
		line_width
	)
	draw_line(
		Vector2(right_line_x, hud_bar_height),
		Vector2(right_line_x, size.y),
		RIGHT_COLOR,
		line_width
	)

func _draw_rebound_badge(font: Font, ui_scale: float) -> void:
	var badge_center := Vector2(58.0 * ui_scale, hud_bar_height * 0.46)
	var badge_radius := 22.0 * ui_scale
	draw_circle(badge_center, badge_radius, Color(COUNT_BADGE_COLOR, 0.55))
	draw_arc(badge_center, badge_radius, 0.0, TAU, 64, Color(DIVIDER_COLOR, 0.92), 1.5 * ui_scale, true)
	draw_arc(
		badge_center,
		badge_radius,
		-PI * 0.5,
		PI * 0.5,
		32,
		Color(MUTED_TEXT_COLOR, 0.65),
		1.5 * ui_scale,
		true
	)
	var count_text := str(total_rebounds)
	var count_font_size := maxi(int(22.0 * ui_scale), 12)
	if count_text.length() >= 3:
		count_font_size = maxi(int(16.0 * ui_scale), 10)
	draw_string(
		font,
		Vector2(badge_center.x - badge_radius, badge_center.y + count_font_size * 0.34),
		count_text,
		HORIZONTAL_ALIGNMENT_CENTER,
		badge_radius * 2.0,
		count_font_size,
		TEXT_COLOR
	)
	draw_string(
		font,
		Vector2(badge_center.x - badge_radius * 1.4, badge_center.y + badge_radius + 5.0 * ui_scale),
		"REBATIDAS",
		HORIZONTAL_ALIGNMENT_CENTER,
		badge_radius * 2.8,
		maxi(int(5.0 * ui_scale), 7),
		MUTED_TEXT_COLOR
	)

func _draw_score(font: Font, size: Vector2, ui_scale: float) -> void:
	var card_size := Vector2(120.0, 54.0) * ui_scale
	var card_y := 3.0 * ui_scale
	var center_x := size.x * 0.5
	var card_gap := 56.0 * ui_scale
	var left_card := Rect2(Vector2(center_x - card_size.x - card_gap * 0.5, card_y), card_size)
	var right_card := Rect2(Vector2(center_x + card_gap * 0.5, card_y), card_size)
	draw_rect(left_card, SCORE_LEFT_PANEL)
	draw_rect(left_card, Color(LEFT_COLOR, 0.8), false, 2.0 * ui_scale)
	draw_rect(right_card, SCORE_RIGHT_PANEL)
	draw_rect(right_card, Color(RIGHT_COLOR, 0.8), false, 2.0 * ui_scale)
	draw_rect(Rect2(left_card.position, Vector2(3.0 * ui_scale, card_size.y)), LEFT_COLOR)
	draw_rect(Rect2(right_card.position, Vector2(3.0 * ui_scale, card_size.y)), RIGHT_COLOR)
	_draw_team_score(font, left_card, LEFT_TEAM_NAME, left_score, LEFT_COLOR, true, ui_scale)
	_draw_team_score(font, right_card, RIGHT_TEAM_NAME, right_score, RIGHT_COLOR, false, ui_scale)
	draw_string(
		font,
		Vector2(center_x - card_gap * 0.5, card_y + 36.0 * ui_scale),
		":",
		HORIZONTAL_ALIGNMENT_CENTER,
		card_gap,
		maxi(int(20.0 * ui_scale), 12),
		MUTED_TEXT_COLOR
	)

func _draw_team_score(
	font: Font,
	card: Rect2,
	team_name: String,
	score: int,
	team_color: Color,
	is_left: bool,
	ui_scale: float
) -> void:
	var emblem_center := card.position + Vector2(20.0, 24.0) * ui_scale
	_draw_team_emblem(emblem_center, team_color, is_left, ui_scale)
	draw_string(
		font,
		card.position + Vector2(34.0, 14.0) * ui_scale,
		team_name,
		HORIZONTAL_ALIGNMENT_LEFT,
		card.size.x - 37.0 * ui_scale,
		maxi(int(7.0 * ui_scale), 7),
		team_color
	)
	_draw_score_pips(card, score, team_color, ui_scale)
	draw_string(
		font,
		card.position + Vector2(30.0, 48.0) * ui_scale,
		str(score),
		HORIZONTAL_ALIGNMENT_RIGHT,
		card.size.x - 38.0 * ui_scale,
		maxi(int(26.0 * ui_scale), 14),
		TEXT_COLOR
	)
	if point_flash_remaining > 0.0 and point_flash_is_left == is_left:
		var flash_strength := point_flash_remaining / POINT_FLASH_DURATION
		draw_rect(
			card.grow(3.0 * ui_scale),
			Color(team_color, 0.9 * flash_strength),
			false,
			3.0 * ui_scale
		)

func _draw_score_pips(card: Rect2, score: int, team_color: Color, ui_scale: float) -> void:
	for pip_index in range(3):
		var pip_center := card.position + Vector2(36.0 + float(pip_index) * 8.0, 22.0) * ui_scale
		var pip_radius := 2.4 * ui_scale
		var pip := PackedVector2Array([
			pip_center + Vector2(0.0, -pip_radius),
			pip_center + Vector2(pip_radius, 0.0),
			pip_center + Vector2(0.0, pip_radius),
			pip_center + Vector2(-pip_radius, 0.0),
			pip_center + Vector2(0.0, -pip_radius),
		])
		if pip_index < score:
			draw_colored_polygon(pip, team_color)
		else:
			draw_polyline(pip, Color(team_color, 0.38), maxf(1.0, ui_scale * 0.8), true)

func _draw_team_emblem(
	center: Vector2,
	team_color: Color,
	is_left: bool,
	emblem_scale: float = -1.0,
	alpha: float = 1.0
) -> void:
	if emblem_scale < 0.0:
		emblem_scale = game_scale
	var draw_color := Color(team_color, alpha)
	if is_left:
		var hexagon := PackedVector2Array()
		for point_index in range(7):
			var angle := -PI * 0.5 + TAU * float(point_index % 6) / 6.0
			hexagon.append(center + Vector2(cos(angle), sin(angle)) * 10.0 * emblem_scale)
		draw_polyline(hexagon, draw_color, 1.8 * emblem_scale, true)
		draw_line(center, center + Vector2(5.0, -5.0) * emblem_scale, draw_color, 1.4 * emblem_scale, true)
		draw_line(center, center + Vector2(-5.0, 5.0) * emblem_scale, draw_color, 1.4 * emblem_scale, true)
		draw_circle(center, 2.0 * emblem_scale, Color(TEXT_COLOR, alpha))
	else:
		var diamond := PackedVector2Array([
			center + Vector2(0.0, -11.0) * emblem_scale,
			center + Vector2(11.0, 0.0) * emblem_scale,
			center + Vector2(0.0, 11.0) * emblem_scale,
			center + Vector2(-11.0, 0.0) * emblem_scale,
			center + Vector2(0.0, -11.0) * emblem_scale,
		])
		draw_polyline(diamond, draw_color, 1.8 * emblem_scale, true)
		var bolt := PackedVector2Array([
			center + Vector2(1.0, -7.0) * emblem_scale,
			center + Vector2(-4.0, 1.0) * emblem_scale,
			center + Vector2(-1.0, 1.0) * emblem_scale,
			center + Vector2(-2.0, 7.0) * emblem_scale,
			center + Vector2(4.0, -1.0) * emblem_scale,
			center + Vector2(1.0, -1.0) * emblem_scale,
		])
		draw_colored_polygon(bolt, draw_color)

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

func _draw_power_up_status(font: Font, size: Vector2, ui_scale: float) -> void:
	if power_up_hud_title.is_empty():
		return
	var panel_size := Vector2(size.x * 0.3, minf(hud_bar_height - 16.0 * ui_scale, 60.0 * ui_scale))
	var panel := Rect2(
		Vector2(size.x * 0.68, (hud_bar_height - panel_size.y) * 0.5),
		panel_size
	)
	draw_rect(panel, Color(0.035, 0.055, 0.09, 0.88))
	draw_rect(panel, Color(power_up_hud_accent, 0.48), false, 1.5 * ui_scale)
	draw_rect(
		Rect2(panel.position, Vector2(4.0 * ui_scale, panel.size.y)),
		power_up_hud_accent
	)
	var icon_center := panel.position + Vector2(14.0 * ui_scale, panel.size.y * 0.36)
	var icon_radius := 5.0 * ui_scale
	var accent_diamond := PackedVector2Array([
		icon_center + Vector2(0.0, -icon_radius),
		icon_center + Vector2(icon_radius, 0.0),
		icon_center + Vector2(0.0, icon_radius),
		icon_center + Vector2(-icon_radius, 0.0),
	])
	draw_colored_polygon(accent_diamond, power_up_hud_accent)
	var text_x := panel.position.x + 26.0 * ui_scale
	var text_width := panel.size.x - 34.0 * ui_scale
	var title_font_size := _fit_font_size(
		font,
		power_up_hud_title.to_upper(),
		maxi(int(12.0 * ui_scale), 10),
		8,
		text_width
	)
	var detail_font_size := _fit_font_size(
		font,
		power_up_hud_detail,
		maxi(int(9.0 * ui_scale), 8),
		7,
		text_width
	)
	draw_string(
		font,
		Vector2(text_x, panel.position.y + panel.size.y * 0.36),
		power_up_hud_title.to_upper(),
		HORIZONTAL_ALIGNMENT_LEFT,
		text_width,
		title_font_size,
		TEXT_COLOR
	)
	draw_string(
		font,
		Vector2(text_x, panel.position.y + panel.size.y * 0.64),
		power_up_hud_detail,
		HORIZONTAL_ALIGNMENT_LEFT,
		text_width,
		detail_font_size,
		MUTED_TEXT_COLOR
	)
	if power_up_hud_show_progress:
		var track := Rect2(
			Vector2(text_x, panel.position.y + panel.size.y * 0.8),
			Vector2(text_width, maxf(2.0, 3.0 * ui_scale))
		)
		draw_rect(track, Color(0.4, 0.48, 0.58, 0.34))
		draw_rect(Rect2(track.position, Vector2(track.size.x * power_up_hud_progress, track.size.y)), power_up_hud_accent)
