extends GutTest

const POWER_UP_EFFECT := preload("res://scripts/power_up_effect.gd")

const MAIN_SCENE := preload("res://main.tscn")
const ARENA_SCRIPT := preload("res://scripts/arena.gd")
const BALL_SCRIPT := preload("res://scripts/ball.gd")
const POWER_UP_SCRIPT := preload("res://scripts/power_up.gd")
const FIELD_SIZE := Vector2(2880.0, 1620.0)
const WINDOW_SIZES := [
	Vector2(2880.0, 1620.0),
	Vector2(1920.0, 1080.0),
	Vector2(1440.0, 810.0),
	Vector2(1280.0, 720.0),
	Vector2(1000.0, 600.0),
	Vector2(800.0, 600.0),
	Vector2(640.0, 480.0),
]

var game


func before_each() -> void:
	get_viewport().size = FIELD_SIZE
	game = add_child_autofree(MAIN_SCENE.instantiate())
	var credits = game.get_node_or_null("CreditsScreen")
	assert_not_null(credits)
	credits.skip()
	credits._process(credits.SKIP_FADE_OUT_DURATION)
	var menu = game.get_node_or_null("GameMenu")
	assert_not_null(menu)
	menu._select(GameMode.Mode.PLAYER_VS_AI)


func after_each() -> void:
	get_tree().paused = false
	get_viewport().size = FIELD_SIZE


func test_gameplay_entities_fit_inside_hud_and_arena_across_window_sizes() -> void:
	for size in WINDOW_SIZES:
		var window_size: Vector2 = size
		get_viewport().size = window_size
		game._physics_process(0.016)
		assert_eq(game.field_size, window_size, "Field size did not follow %s" % window_size)

		var play_top: float = game.arena.hud_bar_height
		var play_height: float = window_size.y - play_top
		assert_gt(play_height, 0.0, "No playable area at %s" % window_size)

		game.ball.position = Vector2(window_size.x * 0.5, window_size.y)
		game.ball.update_field_size(window_size)
		assert_between(
			float(game.ball.position.y),
			play_top + game.ball.radius,
			window_size.y - game.ball.radius,
			"Ball is outside the play area at %s" % window_size
		)
		assert_lte(game.ball.radius * 2.0, play_height)

		for paddle in [game.left_paddle, game.right_paddle]:
			paddle.position.y = window_size.y
			paddle.update_field_size(window_size)
			assert_between(
				float(paddle.position.y - paddle.paddle_height * 0.5),
				play_top,
				window_size.y - paddle.paddle_height * 0.5,
				"Paddle is outside the play area at %s" % window_size
			)
			assert_lte(paddle.paddle_height, play_height)
			assert_gte(float(paddle.position.x - paddle.paddle_width * 0.5), 0.0)
			assert_lte(float(paddle.position.x + paddle.paddle_width * 0.5), window_size.x)

		game.power_up.reset_for_match(window_size)
		assert_true(game.power_up.appear(window_size))
		game.power_up.position = window_size
		game.power_up.update_field_size(window_size)
		var power_up_radius: float = game.power_up.get_collision_radius()
		assert_between(
			float(game.power_up.position.x),
			power_up_radius,
			window_size.x - power_up_radius,
			"Power-up is outside horizontally at %s" % window_size
		)
		assert_between(
			float(game.power_up.position.y),
			play_top + power_up_radius,
			window_size.y - power_up_radius,
			"Power-up is outside vertically at %s" % window_size
		)
		assert_lte(power_up_radius * 2.0, play_height)


func test_hud_panels_and_text_fit_without_overlap_across_window_sizes() -> void:
	for size in WINDOW_SIZES:
		var window_size: Vector2 = size
		var ui_scale: float = game.arena._hud_scale_for(window_size)
		var score_half_width: float = (120.0 + 56.0 * 0.5) * ui_scale
		var cards_left: float = window_size.x * 0.5 - score_half_width
		var cards_right: float = window_size.x * 0.5 + score_half_width
		var cards_bottom: float = (5.0 + 44.0) * ui_scale
		var power_panel_left: float = window_size.x * 0.68
		var logo_right: float = (125.0 + 150.0) * ui_scale

		assert_lt(logo_right, cards_left, "Logo overlaps scoreboard at %s" % window_size)
		assert_lt(cards_right, power_panel_left, "Scoreboard overlaps power-up panel at %s" % window_size)
		assert_lt(cards_bottom, game.arena.hud_bar_height, "Scoreboard exceeds HUD bar at %s" % window_size)
		assert_lt(power_panel_left + window_size.x * 0.3, window_size.x)
		assert_lt(game.arena.hud_bar_height, window_size.y)

		var font := ThemeDB.fallback_font
		var detail_width: float = window_size.x * 0.3 - 34.0 * ui_scale
		var title_font_size: int = UiDraw.fit_font_size(
			font,
			"RAQUETE REDUZIDA",
			maxi(int(12.0 * ui_scale), 10),
			8,
			detail_width
		)
		assert_gte(title_font_size, 8)
		assert_lte(
			font.get_string_size("RAQUETE REDUZIDA", HORIZONTAL_ALIGNMENT_LEFT, -1, title_font_size).x,
			detail_width,
			"Power-up title overflows at %s" % window_size
		)
		for detail in [
			"Raquete reduzida · 5 rebatidas para coletar",
			"Magenta Volt · 4 usos · 8 rebatidas restantes",
			"Magenta Volt · 1 defesa · 14 rebatidas restantes",
		]:
			var detail_font_size: int = UiDraw.fit_font_size(
				font,
				detail,
				maxi(int(9.0 * ui_scale), 8),
				7,
				detail_width
			)
			assert_gte(detail_font_size, 7)
			var detail_size: float = font.get_string_size(
				detail,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				detail_font_size
			).x
			assert_lte(detail_size, detail_width, "Power-up detail overflows at %s: %s" % [window_size, detail])

		var name_font_size := maxi(int(7.0 * ui_scale), 7)
		var name_width: float = 120.0 * ui_scale - 37.0 * ui_scale
		for team_name in [Palette.LEFT_TEAM_NAME, Palette.RIGHT_TEAM_NAME]:
			var name_size: float = font.get_string_size(
				team_name,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				name_font_size
			).x
			assert_lte(name_size, name_width, "Team name overflows at %s: %s" % [window_size, team_name])


func test_match_point_badge_fits_inside_the_hud_bar() -> void:
	var arena = add_child_autofree(ARENA_SCRIPT.new())
	for size in WINDOW_SIZES:
		var window_size: Vector2 = size
		var ui_scale: float = arena._hud_scale_for(window_size)
		var card_size := Vector2(120.0, 44.0) * ui_scale
		var card_gap := 56.0 * ui_scale
		var center_x: float = window_size.x * 0.5
		var left_card := Rect2(
			Vector2(center_x - card_size.x - card_gap * 0.5, 5.0 * ui_scale),
			card_size
		)
		var right_card := Rect2(
			Vector2(center_x + card_gap * 0.5, 5.0 * ui_scale),
			card_size
		)
		var left_badge: Rect2 = arena._match_point_badge_rect(left_card, ui_scale)
		var right_badge: Rect2 = arena._match_point_badge_rect(right_card, ui_scale)

		assert_lte(
			left_badge.end.y,
			game.arena.hud_bar_height,
			"Match point badge exceeds the HUD bar at %s" % window_size
		)
		assert_lte(
			right_badge.end.y,
			game.arena.hud_bar_height,
			"Match point badge exceeds the HUD bar at %s" % window_size
		)
		assert_lt(
			left_badge.end.x,
			right_badge.position.x,
			"Match point badges overlap at %s" % window_size
		)
		assert_gte(left_badge.position.x, 0.0)
		assert_lte(right_badge.end.x, window_size.x)


func test_score_pips_use_diamond_orientation() -> void:
	var arena = add_child_autofree(ARENA_SCRIPT.new())
	var center := Vector2(48.0, 36.0)
	var radius := 7.0
	var points: PackedVector2Array = UiDraw.diamond_points(center, radius)

	assert_eq(points.size(), 4)
	assert_eq(points[0], center + Vector2(0.0, -radius))
	assert_eq(points[1], center + Vector2(radius, 0.0))
	assert_eq(points[2], center + Vector2(0.0, radius))
	assert_eq(points[3], center + Vector2(-radius, 0.0))


func test_match_updates_collision_effects_and_power_up_highlight() -> void:
	game.ball.paddle_hit.emit(true, Vector2(200.0, 300.0), 1.0, 1.0, false)

	assert_gt(game.spark_effects._particles.size(), 0)
	assert_eq(game.spark_effects._rings.size(), 1)
	assert_eq(game.spark_effects._rings[0]["color"], game.left_paddle.tint)

	assert_true(game.power_up.appear(game.field_size))
	game.power_up.effect_id = POWER_UP_EFFECT.Id.DOUBLE_SIZE
	game.power_up.collect(true)
	assert_true(game.left_paddle.power_up_active)
	assert_eq(
		game.left_paddle.power_up_accent_color,
		POWER_UP_EFFECT.CATALOG[POWER_UP_EFFECT.Id.DOUBLE_SIZE]["color"]
	)


func test_key_colors_keep_readable_contrast() -> void:
	assert_gte(_contrast_ratio(Palette.TEXT_COLOR, ARENA_SCRIPT.HUD_PANEL_COLOR), 4.5)
	assert_gte(_contrast_ratio(Palette.MUTED_TEXT_COLOR, ARENA_SCRIPT.HUD_PANEL_COLOR), 4.5)
	assert_gte(_contrast_ratio(Palette.TEXT_COLOR, ARENA_SCRIPT.FIELD_COLOR), 4.5)
	assert_gte(_contrast_ratio(Palette.MUTED_TEXT_COLOR, ARENA_SCRIPT.FIELD_COLOR), 4.5)
	assert_gte(_contrast_ratio(Palette.LEFT_COLOR, ARENA_SCRIPT.SCORE_LEFT_PANEL), 4.5)
	assert_gte(_contrast_ratio(Palette.RIGHT_COLOR, ARENA_SCRIPT.SCORE_RIGHT_PANEL), 4.5)
	assert_gte(_contrast_ratio(Palette.BALL_COLOR, ARENA_SCRIPT.FIELD_CENTER_COLOR), 4.5)

	var item_body_color := Color(0.02, 0.035, 0.06)
	for effect_id in POWER_UP_EFFECT.ALL:
		var effect_color: Color = POWER_UP_EFFECT.CATALOG[effect_id]["color"]
		assert_gte(
			_contrast_ratio(effect_color, item_body_color),
			4.5,
			"Low contrast for power-up effect %s" % effect_id
		)


func test_winner_key_hints_are_aligned_and_evenly_spaced() -> void:
	var font := ThemeDB.fallback_font
	var arena = add_child_autofree(ARENA_SCRIPT.new())
	for size in WINDOW_SIZES:
		var window_size: Vector2 = size
		var ui_scale: float = arena._hud_scale_for(window_size)
		var panel_size := Vector2(560.0, 280.0) * ui_scale
		var panel_center := window_size * 0.5
		var panel := Rect2(panel_center - panel_size * 0.5, panel_size)

		var layout: Dictionary = arena._winner_key_hint_layout(font, panel, ui_scale)
		var items: Array = layout["items"]
		assert_eq(items.size(), 2, "Expected 2 winner key hints at %s" % window_size)

		var first: Dictionary = items[0]
		var second: Dictionary = items[1]

		# Verify horizontal alignment: keycaps share the same left and right X coordinates
		assert_almost_eq(
			float(first["key_rect"].position.x),
			float(second["key_rect"].position.x),
			0.001,
			"Keycap left X must match at %s" % window_size
		)
		assert_almost_eq(
			float(first["key_rect"].end.x),
			float(second["key_rect"].end.x),
			0.001,
			"Keycap right X must match at %s" % window_size
		)

		# Verify horizontal alignment: labels start at the exact same X coordinate
		assert_almost_eq(
			float(first["label_pos"].x),
			float(second["label_pos"].x),
			0.001,
			"Label start X must match at %s" % window_size
		)

		# Verify vertical spacing: uniform gaps of 10.0 * ui_scale
		var divider_y := panel.position.y + 194.0 * ui_scale
		var top_gap := float(first["key_rect"].position.y - divider_y)
		var row_gap := float(second["key_rect"].position.y - first["key_rect"].end.y)
		var bottom_gap := float((panel.position.y + panel.size.y) - second["key_rect"].end.y)

		assert_almost_eq(top_gap, 10.0 * ui_scale, 0.001, "Top gap must be 10 * ui_scale at %s" % window_size)
		assert_almost_eq(row_gap, 10.0 * ui_scale, 0.001, "Row gap must be 10 * ui_scale at %s" % window_size)
		assert_almost_eq(bottom_gap, 10.0 * ui_scale, 0.001, "Bottom gap must be 10 * ui_scale at %s" % window_size)

		# Verify hints stay inside the winner panel bounds
		assert_gte(float(first["key_rect"].position.x), float(panel.position.x))
		assert_lte(float(first["label_pos"].x + first["label_width"]), float(panel.end.x))
		assert_lte(float(second["label_pos"].x + second["label_width"]), float(panel.end.x))


func _contrast_ratio(first: Color, second: Color) -> float:
	var first_luminance := _relative_luminance(first)
	var second_luminance := _relative_luminance(second)
	return (maxf(first_luminance, second_luminance) + 0.05) / (minf(first_luminance, second_luminance) + 0.05)


func _relative_luminance(color: Color) -> float:
	return (
		0.2126 * _linear_channel(color.r)
		+ 0.7152 * _linear_channel(color.g)
		+ 0.0722 * _linear_channel(color.b)
	)


func _linear_channel(value: float) -> float:
	if value <= 0.03928:
		return value / 12.92
	return pow((value + 0.055) / 1.055, 2.4)
