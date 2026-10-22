extends GutTest

const PADDLE_SCENE := preload("res://scenes/paddle.tscn")
const FIELD_SIZE := Vector2(1000.0, 600.0)
const PLAY_TOP := 50.0

var paddle

func before_each() -> void:
	paddle = add_child_autofree(PADDLE_SCENE.instantiate())
	paddle.configure(FIELD_SIZE, 20.0, 100.0, 30.0, 200.0, 10.0, PLAY_TOP)

func after_each() -> void:
	for action in ["p1_up", "p1_down", "p2_up", "p2_down"]:
		if InputMap.has_action(action):
			Input.action_release(action)

func test_initial_position_and_collision_rect_match_configuration() -> void:
	assert_eq(paddle.position, Vector2(40.0, 325.0))
	assert_eq(paddle.get_collision_rect(), Rect2(Vector2(30.0, 275.0), Vector2(20.0, 100.0)))

func test_ai_predicts_intercept_after_reflecting_from_bottom_wall() -> void:
	var intercept_y: float = paddle._predict_intercept_y(
		Vector2(500.0, 200.0),
		Vector2(-100.0, 100.0)
	)

	# O atraso de reação da IA é sempre descontado da interceptação.
	assert_almost_eq(float(intercept_y), float(554.0), float(0.01))


func test_ai_keeps_the_same_prediction_precision_with_or_without_power_up() -> void:
	paddle.ai_reaction_delay = 0.4
	var ball_position := Vector2(500.0, 100.0)
	var ball_velocity := Vector2(-100.0, 50.0)
	var expected: float = paddle._predict_intercept_y(ball_position, ball_velocity)
	assert_almost_eq(float(expected), float(300.0), float(0.01))

	# O power-up fica sobre o próprio alvo, então a mira não muda o destino.
	paddle.update_ai(ball_position, ball_velocity, 0.2, true, Vector2(500.0, expected), true)

	assert_almost_eq(float(paddle.position.y), float(expected), float(0.01))

func test_ai_movement_obeys_speed_limit_and_field_bounds() -> void:
	paddle.update_ai(Vector2(50.0, 100.0), Vector2(-100.0, 0.0), 0.1)

	assert_almost_eq(float(paddle.position.y), float(308.6), float(0.01))
	assert_gte(float(paddle.position.y - paddle.paddle_height * 0.5), float(PLAY_TOP))
	assert_lte(float(paddle.position.y + paddle.paddle_height * 0.5), float(FIELD_SIZE.y))

func test_ai_stays_still_inside_dead_zone() -> void:
	var starting_y: float = paddle.position.y
	var dead_zone: float = paddle.ai_dead_zone
	assert_gt(dead_zone, 0.0)
	paddle.update_ai(Vector2(60.0, starting_y + dead_zone * 0.5), Vector2(-100.0, 0.0), 0.1)

	assert_eq(paddle.position.y, starting_y)

func test_power_up_updates_size_collision_and_visual_highlight() -> void:
	paddle.apply_power_up(2.0, Color(0.25, 1.0, 0.42))

	assert_true(paddle.power_up_highlight.visible)
	_finish_size_animation(paddle)

	assert_eq(paddle.paddle_height, 200.0)
	assert_eq(paddle.get_collision_rect().size.y, 200.0)

	paddle.clear_power_up()
	assert_false(paddle.power_up_highlight.visible)
	_finish_size_animation(paddle)
	assert_eq(paddle.paddle_height, 100.0)

func test_grow_animation_enlarges_the_paddle_until_the_target_is_reached() -> void:
	paddle.apply_power_up(2.0, Color(0.25, 1.0, 0.42))

	assert_eq(paddle.paddle_height, 100.0)
	assert_true(paddle.is_size_animating())
	assert_eq(paddle.get_size_animation_direction(), 1.0)

	var overshoot_height := 0.0
	var step := GameConfig.PADDLE_GROW_ANIMATION_SECONDS / 8.0
	for _index in range(8):
		paddle.advance_size_animation(step)
		overshoot_height = maxf(overshoot_height, paddle.paddle_height)

	assert_gt(float(overshoot_height), float(200.0))

	_finish_size_animation(paddle)
	assert_false(paddle.is_size_animating())
	assert_eq(paddle.paddle_height, 200.0)
	assert_eq(paddle.get_collision_rect().size.y, 200.0)
func test_shrink_animation_reduces_the_paddle_until_the_target_is_reached() -> void:
	paddle.apply_power_up(0.5, Color(1.0, 0.3, 0.2))

	assert_true(paddle.is_size_animating())
	assert_eq(paddle.get_size_animation_direction(), -1.0)

	paddle.advance_size_animation(GameConfig.PADDLE_SHRINK_ANIMATION_SECONDS)

	assert_false(paddle.is_size_animating())
	assert_eq(paddle.paddle_height, 50.0)
	assert_eq(paddle.get_collision_rect().size.y, 50.0)

func test_size_animation_never_goes_below_the_starting_height() -> void:
	paddle.apply_power_up(2.0, Color(0.25, 1.0, 0.42))
	var step := GameConfig.PADDLE_GROW_ANIMATION_SECONDS / 20.0
	for _index in range(20):
		paddle.advance_size_animation(step)
		assert_gte(float(paddle.paddle_height), float(paddle.base_paddle_height))

	paddle.apply_power_up(0.5, Color(1.0, 0.3, 0.2))
	_finish_size_animation(paddle)
	var shrink_step := GameConfig.PADDLE_SHRINK_ANIMATION_SECONDS / 20.0
	for _index in range(20):
		paddle.advance_size_animation(shrink_step)
		assert_gt(float(paddle.paddle_height), float(paddle.base_paddle_height * 0.08))

func test_clearing_the_power_up_animates_the_paddle_back_to_the_base_size() -> void:
	paddle.apply_power_up(2.0, Color(0.25, 1.0, 0.42))
	_finish_size_animation(paddle)
	assert_eq(paddle.paddle_height, 200.0)

	paddle.clear_power_up()

	assert_true(paddle.is_size_animating())
	assert_eq(paddle.get_size_animation_direction(), -1.0)

	_finish_size_animation(paddle)
	assert_eq(paddle.paddle_height, 100.0)
	assert_eq(paddle.get_collision_rect().size.y, 100.0)

func test_effects_without_size_change_do_not_start_an_animation() -> void:
	paddle.apply_power_up(1.0, Color(1.0, 0.56, 0.18))

	assert_false(paddle.is_size_animating())
	assert_eq(paddle.get_size_animation_direction(), 0.0)
	assert_eq(paddle.paddle_height, 100.0)

func test_size_animation_keeps_the_paddle_inside_the_play_area() -> void:
	paddle.apply_power_up(10.0, Color.WHITE)

	for _index in range(10):
		paddle.advance_size_animation(0.05)
		assert_gte(float(paddle.position.y - paddle.paddle_height * 0.5), float(PLAY_TOP) - 0.01)
		assert_lte(float(paddle.position.y + paddle.paddle_height * 0.5), float(FIELD_SIZE.y) + 0.01)

func _finish_size_animation(target) -> void:
	target.advance_size_animation(
		GameConfig.PADDLE_GROW_ANIMATION_SECONDS + GameConfig.PADDLE_SHRINK_ANIMATION_SECONDS
	)

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
	_finish_size_animation(paddle)

	assert_almost_eq(float(paddle.paddle_height), float(FIELD_SIZE.y - PLAY_TOP), float(0.01))
	assert_eq(paddle.position.y, (FIELD_SIZE.y + PLAY_TOP) * 0.5)

func test_apply_difficulty_updates_ai_parameters() -> void:
	paddle.apply_difficulty(Difficulty.preset(Difficulty.Level.EASY))

	assert_eq(paddle.ai_speed_factor, 0.64)
	assert_eq(paddle.ai_reaction_delay, 0.30)
	assert_eq(
		paddle.ai_dead_zone_ratio,
		Difficulty.preset(Difficulty.Level.EASY).ai_dead_zone_ratio
	)
	assert_almost_eq(
		float(paddle.ai_dead_zone),
		float(paddle.ai_dead_zone_ratio * paddle.base_paddle_height),
		float(0.01)
	)

	paddle.apply_difficulty(Difficulty.preset(Difficulty.Level.HARD))

	assert_eq(paddle.ai_speed_factor, 1.0)
	assert_eq(paddle.ai_reaction_delay, 0.04)
	assert_almost_eq(
		float(paddle.ai_dead_zone),
		float(Difficulty.preset(Difficulty.Level.HARD).ai_dead_zone_ratio * paddle.base_paddle_height),
		float(0.01)
	)


func test_dead_zone_follows_the_paddle_height_instead_of_a_fixed_pixel_value() -> void:
	var tall_paddle = add_child_autofree(PADDLE_SCENE.instantiate())
	tall_paddle.configure(FIELD_SIZE, 20.0, 200.0, 30.0, 200.0, 10.0, PLAY_TOP)
	tall_paddle.apply_difficulty(Difficulty.preset(Difficulty.Level.NORMAL))
	paddle.apply_difficulty(Difficulty.preset(Difficulty.Level.NORMAL))

	assert_almost_eq(
		float(tall_paddle.ai_dead_zone),
		float(paddle.ai_dead_zone_ratio * 200.0),
		float(0.01)
	)
	assert_gt(float(tall_paddle.ai_dead_zone), float(paddle.ai_dead_zone))


func test_default_paddle_dead_zone_matches_the_documented_pixels() -> void:
	var default_paddle = add_child_autofree(PADDLE_SCENE.instantiate())
	default_paddle.configure(
		FIELD_SIZE,
		GameConfig.PADDLE_WIDTH,
		GameConfig.PADDLE_HEIGHT,
		GameConfig.PADDLE_MARGIN,
		GameConfig.PADDLE_SPEED,
		GameConfig.BALL_RADIUS,
		GameConfig.HUD_BAR_HEIGHT
	)
	default_paddle.apply_difficulty(Difficulty.preset(Difficulty.Level.EASY))

	assert_almost_eq(float(default_paddle.ai_dead_zone), float(38.0), float(0.01))

func test_project_defines_separate_actions_for_both_players() -> void:
	for action in ["p1_up", "p1_down", "p2_up", "p2_down"]:
		assert_true(InputMap.has_action(action), "Missing input action: %s" % action)

func test_human_paddle_ignores_actions_not_assigned_to_it() -> void:
	paddle.set_control_mode(Paddle.ControlMode.HUMAN)
	paddle.set_control_actions(["p1_up"], ["p1_down"])
	var starting_y: float = paddle.position.y

	Input.action_press("p2_up")
	paddle.update_ai(Vector2.ZERO, Vector2.ZERO, 0.1)
	Input.action_release("p2_up")

	assert_eq(paddle.position.y, starting_y)

func test_human_paddle_moves_with_its_assigned_action() -> void:
	paddle.set_control_mode(Paddle.ControlMode.HUMAN)
	paddle.set_control_actions(["p1_up"], ["p1_down"])
	var starting_y: float = paddle.position.y

	Input.action_press("p1_up")
	paddle.update_ai(Vector2.ZERO, Vector2.ZERO, 0.1)
	Input.action_release("p1_up")

	assert_lt(float(paddle.position.y), float(starting_y))

func test_human_paddle_accepts_multiple_assigned_actions() -> void:
	paddle.set_control_mode(Paddle.ControlMode.HUMAN)
	paddle.set_control_actions(["p1_up", "p2_up"], ["p1_down", "p2_down"])
	var starting_y: float = paddle.position.y

	Input.action_press("p2_up")
	paddle.update_ai(Vector2.ZERO, Vector2.ZERO, 0.1)
	Input.action_release("p2_up")

	assert_lt(float(paddle.position.y), float(starting_y))

func test_hard_ai_covers_more_distance_than_easy_ai() -> void:
	var easy_paddle = add_child_autofree(PADDLE_SCENE.instantiate())
	easy_paddle.configure(FIELD_SIZE, 20.0, 100.0, 30.0, 200.0, 10.0, PLAY_TOP)
	easy_paddle.apply_difficulty(Difficulty.preset(Difficulty.Level.EASY))
	paddle.apply_difficulty(Difficulty.preset(Difficulty.Level.HARD))
	var ball_position := Vector2(50.0, 100.0)
	var ball_velocity := Vector2(-100.0, 0.0)

	easy_paddle.update_ai(ball_position, ball_velocity, 0.1)
	paddle.update_ai(ball_position, ball_velocity, 0.1)

	assert_gt(
		absf(paddle.position.y - 325.0),
		absf(easy_paddle.position.y - 325.0)
	)


func test_beneficial_aim_targets_power_up_with_reflected_path() -> void:
	var hit_offset: float = paddle._get_power_up_aim_hit_offset(200.0, Vector2(500.0, 300.0))

	assert_almost_eq(
		float(hit_offset),
		float(100.0 / (440.0 * GameConfig.BOUNCE_VERTICAL_FACTOR)),
		float(0.01)
	)
	assert_between(float(hit_offset), float(-0.72), float(0.72))

func test_negative_power_up_aim_chooses_clearer_path() -> void:
	var hit_offset: float = paddle._get_power_up_avoid_hit_offset(300.0, Vector2(500.0, 300.0))
	var crossing_y: float = paddle._reflect_ball_y(
		300.0 + hit_offset * GameConfig.BOUNCE_VERTICAL_FACTOR * 440.0
	)

	assert_gt(float(absf(crossing_y - 300.0)), float(150.0))
	assert_between(float(hit_offset), float(-0.72), float(0.72))

