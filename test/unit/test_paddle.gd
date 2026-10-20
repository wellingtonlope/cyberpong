extends GutTest

const PADDLE_SCENE := preload("res://scenes/paddle.tscn")
const FIELD_SIZE := Vector2(1000.0, 600.0)
const PLAY_TOP := 50.0

var paddle

func before_each() -> void:
	paddle = add_child_autofree(PADDLE_SCENE.instantiate())
	paddle.configure(FIELD_SIZE, 20.0, 100.0, 30.0, 200.0, 10.0, PLAY_TOP)

func test_initial_position_and_collision_rect_match_configuration() -> void:
	assert_eq(paddle.position, Vector2(40.0, 325.0))
	assert_eq(paddle.get_collision_rect(), Rect2(Vector2(30.0, 275.0), Vector2(20.0, 100.0)))

func test_ai_predicts_intercept_after_reflecting_from_bottom_wall() -> void:
	var intercept_y: float = paddle._predict_intercept_y(
		Vector2(500.0, 200.0),
		Vector2(-100.0, 100.0),
		false
	)

	assert_almost_eq(float(intercept_y), float(540.0), float(0.01))

func test_ai_movement_obeys_speed_limit_and_field_bounds() -> void:
	paddle.update_ai(Vector2(50.0, 100.0), Vector2(-100.0, 0.0), 0.1)

	assert_almost_eq(float(paddle.position.y), float(308.6), float(0.01))
	assert_gte(float(paddle.position.y - paddle.paddle_height * 0.5), float(PLAY_TOP))
	assert_lte(float(paddle.position.y + paddle.paddle_height * 0.5), float(FIELD_SIZE.y))

func test_ai_stays_still_inside_dead_zone() -> void:
	var starting_y: float = paddle.position.y
	paddle.update_ai(Vector2(60.0, starting_y + 10.0), Vector2(-100.0, 0.0), 0.1)

	assert_eq(paddle.position.y, starting_y)

func test_power_up_updates_size_collision_and_visual_highlight() -> void:
	paddle.apply_power_up(2.0, Color(0.25, 1.0, 0.42))

	assert_eq(paddle.paddle_height, 200.0)
	assert_eq(paddle.get_collision_rect().size.y, 200.0)
	assert_true(paddle.power_up_highlight.visible)

	paddle.clear_power_up()
	assert_eq(paddle.paddle_height, 100.0)
	assert_false(paddle.power_up_highlight.visible)

func test_paddle_visual_layers_follow_team_and_power_up_colors() -> void:
	assert_eq(paddle.body.color, paddle.tint)
	assert_eq(paddle.outline.default_color, Color(paddle.tint, 0.95))
	assert_gt(float(paddle.glow.color.a), float(0.0))
	assert_gt(float(paddle.core.color.a), float(0.0))
	assert_eq(paddle.outline.points.size(), 4)
	assert_true(paddle.outline.closed)

	var accent := Color(0.25, 1.0, 0.42)
	paddle.apply_power_up(2.0, accent)
	assert_eq(paddle.outline.default_color, Color(accent, 0.95))
	assert_true(paddle.power_up_highlight.visible)
	assert_eq(paddle.glow.color, Color(accent, 0.2))

func test_oversized_paddle_is_clamped_to_available_play_area() -> void:
	paddle.apply_power_up(10.0, Color.WHITE)

	assert_almost_eq(float(paddle.paddle_height), float(FIELD_SIZE.y - PLAY_TOP), float(0.01))
	assert_eq(paddle.position.y, (FIELD_SIZE.y + PLAY_TOP) * 0.5)

func test_beneficial_aim_targets_power_up_with_reflected_path() -> void:
	var hit_offset: float = paddle._get_power_up_aim_hit_offset(200.0, Vector2(500.0, 300.0))

	assert_almost_eq(float(hit_offset), float(100.0 / (440.0 * 0.85)), float(0.01))
	assert_between(float(hit_offset), float(-0.72), float(0.72))

func test_negative_power_up_aim_chooses_clearer_path() -> void:
	var hit_offset: float = paddle._get_power_up_avoid_hit_offset(300.0, Vector2(500.0, 300.0))
	var crossing_y: float = paddle._reflect_ball_y(300.0 + hit_offset * 0.85 * 440.0)

	assert_gt(float(absf(crossing_y - 300.0)), float(150.0))
	assert_between(float(hit_offset), float(-0.72), float(0.72))

