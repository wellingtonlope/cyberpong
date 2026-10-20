extends Node2D

const BACKGROUND_COLOR := Color(0.018, 0.03, 0.052)
const FIELD_COLOR := Color(0.035, 0.055, 0.09)
const DIVIDER_COLOR := Color(0.18, 0.24, 0.32)
const TEXT_COLOR := Color(0.9, 0.94, 1.0)
const MUTED_TEXT_COLOR := Color(0.58, 0.68, 0.8)
const LEFT_COLOR := Color(0.08, 0.98, 1.0)
const RIGHT_COLOR := Color(1.0, 0.12, 0.72)
const HUD_PANEL_COLOR := Color(0.012, 0.022, 0.04)
const FIELD_BORDER_COLOR := Color(0.08, 0.98, 1.0, 0.45)
const GOAL_LINE_COLOR := Color(1.0, 0.08, 0.12, 0.9)
const SCORE_LEFT_PANEL := Color(0.035, 0.22, 0.26, 0.72)
const SCORE_RIGHT_PANEL := Color(0.28, 0.035, 0.18, 0.72)
const COUNT_BADGE_COLOR := Color(0.08, 0.98, 1.0, 0.12)

var game_scale := 3.0
var hud_bar_height := 180.0
var paddle_margin := 120.0
var game_over := false
var left_score := 0
var right_score := 0
var winner_name := ""
var total_rebounds := 0
var power_up_hud_title := ""
var power_up_hud_detail := ""
var power_up_hud_progress := 0.0
var power_up_hud_accent := MUTED_TEXT_COLOR
var power_up_hud_show_progress := false

func configure(scale: float, bar_height: float = 0.0, margin: float = 120.0) -> void:
	game_scale = scale
	hud_bar_height = bar_height
	paddle_margin = margin
	queue_redraw()

func set_game_over(value: bool) -> void:
	game_over = value
	if not value:
		winner_name = ""
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
	game_over = true
	queue_redraw()

func _draw() -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND_COLOR)
	var field_margin := 12.0 * game_scale
	var field_rect := Rect2(
		Vector2(field_margin, hud_bar_height),
		Vector2(size.x - field_margin * 2.0, size.y - hud_bar_height)
	)
	draw_rect(field_rect, FIELD_COLOR)
	draw_rect(field_rect, FIELD_BORDER_COLOR, false, 2.0 * game_scale)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, hud_bar_height)), HUD_PANEL_COLOR)
	draw_rect(Rect2(0.0, hud_bar_height - 2.0 * game_scale, size.x, 2.0 * game_scale), FIELD_BORDER_COLOR)

	for y in range(int(hud_bar_height + 12.0 * game_scale), int(size.y - 12.0 * game_scale), 30 * int(game_scale)):
		draw_rect(Rect2(size.x * 0.5 - 2.0 * game_scale, float(y), 4.0 * game_scale, 14.0 * game_scale), DIVIDER_COLOR)
	_draw_goal_lines(size)

	var font := ThemeDB.fallback_font
	_draw_rebound_badge(font)
	_draw_score(font, size)
	_draw_power_up_status(font, size)

	if game_over:
		var message_width := 460.0 * game_scale
		var message_x := (size.x - message_width) * 0.5
		draw_rect(Rect2(message_x - 24.0 * game_scale, size.y * 0.5 - 80.0 * game_scale, message_width + 48.0 * game_scale, 160.0 * game_scale), Color(0.02, 0.035, 0.06, 0.94))
		draw_string(font, Vector2(message_x, size.y * 0.5 - 28.0 * game_scale), "%s VENCEU!" % winner_name, HORIZONTAL_ALIGNMENT_CENTER, message_width, 34 * int(game_scale), TEXT_COLOR)
		draw_string(font, Vector2(message_x, size.y * 0.5 + 5.0 * game_scale), "Fim de jogo: melhor de 5", HORIZONTAL_ALIGNMENT_CENTER, message_width, 18 * int(game_scale), MUTED_TEXT_COLOR)
		draw_string(font, Vector2(message_x, size.y * 0.5 + 40.0 * game_scale), "Pressione Enter para nova partida", HORIZONTAL_ALIGNMENT_CENTER, message_width, 16 * int(game_scale), TEXT_COLOR)

func _draw_goal_lines(size: Vector2) -> void:
	var field_margin := 12.0 * game_scale
	var left_line_x := field_margin
	var right_line_x := size.x - field_margin
	var line_width := 4.0 * game_scale
	draw_line(
		Vector2(left_line_x, hud_bar_height),
		Vector2(left_line_x, size.y),
		GOAL_LINE_COLOR,
		line_width
	)
	draw_line(
		Vector2(right_line_x, hud_bar_height),
		Vector2(right_line_x, size.y),
		GOAL_LINE_COLOR,
		line_width
	)

func _draw_rebound_badge(font: Font) -> void:
	var badge_center := Vector2(58.0 * game_scale, hud_bar_height * 0.5)
	var badge_radius := 23.0 * game_scale
	draw_circle(badge_center, badge_radius, COUNT_BADGE_COLOR)
	draw_arc(badge_center, badge_radius, 0.0, TAU, 64, LEFT_COLOR, 2.5 * game_scale, true)
	var count_text := str(total_rebounds)
	var count_font_size := 28 * int(game_scale)
	if count_text.length() >= 3:
		count_font_size = 20 * int(game_scale)
	draw_string(
		font,
		Vector2(badge_center.x - badge_radius, badge_center.y + 9.0 * game_scale),
		count_text,
		HORIZONTAL_ALIGNMENT_CENTER,
		badge_radius * 2.0,
		count_font_size,
		TEXT_COLOR
	)

func _draw_score(font: Font, size: Vector2) -> void:
	var card_size := Vector2(52.0 * game_scale, 50.0 * game_scale)
	var card_y := 5.0 * game_scale
	var center_x := size.x * 0.5
	var left_card := Rect2(Vector2(center_x - 58.0 * game_scale - card_size.x, card_y), card_size)
	var right_card := Rect2(Vector2(center_x + 58.0 * game_scale, card_y), card_size)
	draw_rect(left_card, SCORE_LEFT_PANEL)
	draw_rect(left_card, Color(LEFT_COLOR, 0.8), false, 2.0 * game_scale)
	draw_rect(right_card, SCORE_RIGHT_PANEL)
	draw_rect(right_card, Color(RIGHT_COLOR, 0.8), false, 2.0 * game_scale)
	draw_string(font, left_card.position + Vector2(0.0, 14.0 * game_scale), "CIANO", HORIZONTAL_ALIGNMENT_CENTER, card_size.x, 9 * int(game_scale), LEFT_COLOR)
	draw_string(font, right_card.position + Vector2(0.0, 14.0 * game_scale), "MAGENTA", HORIZONTAL_ALIGNMENT_CENTER, card_size.x, 9 * int(game_scale), RIGHT_COLOR)
	draw_string(font, left_card.position + Vector2(0.0, 44.0 * game_scale), str(left_score), HORIZONTAL_ALIGNMENT_CENTER, card_size.x, 24 * int(game_scale), TEXT_COLOR)
	draw_string(font, right_card.position + Vector2(0.0, 44.0 * game_scale), str(right_score), HORIZONTAL_ALIGNMENT_CENTER, card_size.x, 24 * int(game_scale), TEXT_COLOR)
	draw_string(font, Vector2(center_x - 20.0 * game_scale, 36.0 * game_scale), ":", HORIZONTAL_ALIGNMENT_CENTER, 40.0 * game_scale, 22 * int(game_scale), MUTED_TEXT_COLOR)

func _draw_power_up_status(font: Font, size: Vector2) -> void:
	if power_up_hud_title.is_empty():
		return
	var panel := Rect2(
		Vector2(size.x * 0.65, 8.0 * game_scale),
		Vector2(size.x * 0.33, hud_bar_height - 16.0 * game_scale)
	)
	draw_rect(panel, Color(0.035, 0.055, 0.09, 0.88))
	draw_rect(panel, Color(power_up_hud_accent, 0.48), false, 1.5 * game_scale)
	draw_rect(
		Rect2(panel.position, Vector2(4.0 * game_scale, panel.size.y)),
		power_up_hud_accent
	)
	var text_x := panel.position.x + 20.0 * game_scale
	var text_width := panel.size.x - 36.0 * game_scale
	draw_string(
		font,
		Vector2(text_x, panel.position.y + 18.0 * game_scale),
		power_up_hud_title.to_upper(),
		HORIZONTAL_ALIGNMENT_LEFT,
		text_width,
		13 * int(game_scale),
		TEXT_COLOR
	)
	draw_string(
		font,
		Vector2(text_x, panel.position.y + 32.0 * game_scale),
		power_up_hud_detail,
		HORIZONTAL_ALIGNMENT_LEFT,
		text_width,
		10 * int(game_scale),
		MUTED_TEXT_COLOR
	)
	if power_up_hud_show_progress:
		var track := Rect2(
			Vector2(text_x, panel.position.y + 39.0 * game_scale),
			Vector2(text_width, 4.0 * game_scale)
		)
		draw_rect(track, Color(0.4, 0.48, 0.58, 0.34))
		draw_rect(Rect2(track.position, Vector2(track.size.x * power_up_hud_progress, track.size.y)), power_up_hud_accent)
