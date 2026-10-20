extends GutTest

const BALL_SCENE := preload("res://scenes/ball.tscn")
const FIELD_SIZE := Vector2(1000.0, 600.0)
const PLAY_TOP := 60.0
const LEFT_PADDLE := Rect2(Vector2(50.0, 220.0), Vector2(20.0, 120.0))
const RIGHT_PADDLE := Rect2(Vector2(930.0, 220.0), Vector2(20.0, 120.0))

var ball

func before_each() -> void:
	ball = add_child_autofree(BALL_SCENE.instantiate())
	ball.restart(FIELD_SIZE, 10.0, 1140.0, LEFT_PADDLE, RIGHT_PADDLE, PLAY_TOP)

func test_serve_uses_requested_speed_and_emits_speed_changed() -> void:
	watch_signals(ball)
	ball._paddle_hits = 3
	ball.serve_from_paddle(LEFT_PADDLE, RIGHT_PADDLE, false, 1500.0)

	assert_eq(ball.current_speed, 1500.0)
	assert_eq(ball._paddle_hits, 0)
	assert_lt(float(ball.velocity.x), float(0.0))
	assert_almost_eq(float(ball.velocity.length()), float(1500.0), float(0.01))
	assert_signal_emitted_with_parameters(ball, "speed_changed", [1500.0])

func test_normal_rebound_increases_speed_every_second_hit() -> void:
	ball.current_speed = 1000.0
	ball.base_speed = 1000.0
	watch_signals(ball)

	ball._bounce_from_paddle(LEFT_PADDLE, 1.0, true)
	assert_eq(ball.current_speed, 1000.0)
	ball._bounce_from_paddle(LEFT_PADDLE, 1.0, true)

	assert_almost_eq(float(ball.current_speed), float(1100.0), float(0.01))
	assert_signal_emitted_with_parameters(ball, "speed_changed", [1100.0])

func test_normal_rebounds_stop_at_speed_cap() -> void:
	ball.base_speed = 1000.0
	ball.current_speed = 1000.0
	for _index in range(120):
		ball._bounce_from_paddle(LEFT_PADDLE, 1.0, true)

	assert_eq(ball.current_speed, 3000.0)
	ball._bounce_from_paddle(LEFT_PADDLE, 1.0, true)
	ball._bounce_from_paddle(LEFT_PADDLE, 1.0, true)
	assert_eq(ball.current_speed, 3000.0)

func test_powerful_bounce_can_exceed_normal_speed_cap() -> void:
	ball.base_speed = 1140.0
	ball.current_speed = 3000.0
	ball._paddle_hits = 1
	ball._bounce_from_paddle(LEFT_PADDLE, 1.0, true, "powerful_bounce")

	assert_almost_eq(float(ball.current_speed), float(3540.0), float(0.01))
	assert_eq(ball._powerful_bounce_visual_scale, 1.2)

func test_opponent_rebound_resets_powerful_bounce_speed_and_visual_scale() -> void:
	ball.base_speed = 1140.0
	ball.current_speed = 3000.0
	ball._paddle_hits = 1
	ball.position = Vector2(81.0, 280.0)
	ball.velocity = Vector2(-100.0, 0.0)
	ball.advance(0.02, LEFT_PADDLE, RIGHT_PADDLE, Vector2.ZERO, 0.0, "powerful_bounce", true)
	assert_eq(ball.current_speed, 3540.0)
	assert_eq(ball._powerful_bounce_visual_scale, 1.2)

	ball.position = Vector2(919.0, 280.0)
	ball.velocity = Vector2(100.0, 0.0)
	watch_signals(ball)
	ball.advance(0.02, LEFT_PADDLE, RIGHT_PADDLE, Vector2.ZERO, 0.0, "powerful_bounce", true)

	assert_eq(ball.current_speed, 3000.0)
	assert_eq(ball._powerful_bounce_visual_scale, 1.0)
	assert_signal_emitted_with_parameters(ball, "speed_changed", [3000.0])

func test_brake_does_not_reduce_speed_below_rally_floor() -> void:
	ball.base_speed = 1000.0
	ball.current_speed = 660.0
	ball._ball_brake_reference_speed = 660.0
	ball._ball_brake_active = true
	watch_signals(ball)
	ball._bounce_from_paddle(LEFT_PADDLE, 1.0, true, "ball_brake")

	assert_eq(ball.current_speed, 650.0)
	assert_signal_emitted_with_parameters(ball, "speed_changed", [650.0])

func test_top_and_bottom_walls_reflect_ball_inside_play_area() -> void:
	ball.position = Vector2(500.0, 75.0)
	ball.velocity = Vector2(0.0, -1000.0)
	ball.advance(0.1, LEFT_PADDLE, RIGHT_PADDLE, Vector2.ZERO, 0.0)
	assert_eq(ball.position.y, PLAY_TOP + ball.radius)
	assert_gt(float(ball.velocity.y), float(0.0))

	ball.position = Vector2(500.0, FIELD_SIZE.y - 75.0)
	ball.velocity = Vector2(0.0, 1000.0)
	ball.advance(0.1, LEFT_PADDLE, RIGHT_PADDLE, Vector2.ZERO, 0.0)
	assert_eq(ball.position.y, FIELD_SIZE.y - ball.radius)
	assert_lt(float(ball.velocity.y), float(0.0))

func test_miss_emits_once_and_stops_the_ball() -> void:
	watch_signals(ball)
	ball.position = Vector2(0.0, 300.0)
	ball.velocity = Vector2(-100.0, 0.0)
	ball.advance(0.0, LEFT_PADDLE, RIGHT_PADDLE, Vector2.ZERO, 0.0)
	assert_signal_emitted_with_parameters(ball, "missed", [true])

	var stopped_position: Vector2 = ball.position
	ball.advance(1.0, LEFT_PADDLE, RIGHT_PADDLE, Vector2.ZERO, 0.0)
	assert_eq(ball.position, stopped_position)

func test_right_side_miss_reports_the_correct_side() -> void:
	watch_signals(ball)
	ball.position = Vector2(1000.0, 300.0)
	ball.velocity = Vector2(100.0, 0.0)
	ball.advance(0.0, LEFT_PADDLE, RIGHT_PADDLE, Vector2.ZERO, 0.0)

	assert_signal_emitted_with_parameters(ball, "missed", [false])

func test_extra_defense_returns_a_missed_ball_as_a_rebound() -> void:
	watch_signals(ball)
	ball.position = Vector2(0.0, 300.0)
	ball.velocity = Vector2(-100.0, 0.0)
	ball.advance(0.0, LEFT_PADDLE, RIGHT_PADDLE, Vector2.ZERO, 0.0, "extra_defense", true)

	assert_signal_emitted_with_parameters(ball, "paddle_hit", [true, Vector2(70.0, 300.0), 1.0, 1.0, true])
	assert_gt(float(ball.velocity.x), float(0.0))
	assert_false(ball._stopped)

func test_swept_collision_collects_power_up_between_frames() -> void:
	watch_signals(ball)
	ball.position = Vector2(100.0, 300.0)
	ball.velocity = Vector2(1000.0, 0.0)
	ball.advance(0.2, LEFT_PADDLE, RIGHT_PADDLE, Vector2(150.0, 300.0), 5.0)

	assert_signal_emitted_with_parameters(ball, "power_up_collected", [true])

func test_ball_trail_tracks_movement_and_fades_out() -> void:
	ball._trail.clear()
	ball.position = Vector2(500.0, 300.0)
	ball.velocity = Vector2(1000.0, 0.0)
	ball.advance(0.016, LEFT_PADDLE, RIGHT_PADDLE, Vector2.ZERO, 0.0)

	assert_eq(ball._trail.size(), 1)
	ball.serve_from_paddle(LEFT_PADDLE, RIGHT_PADDLE, true, 1140.0)
	assert_eq(ball._trail.size(), 0)

	ball.position = Vector2(500.0, 300.0)
	ball.velocity = Vector2(1000.0, 0.0)
	ball.advance(0.016, LEFT_PADDLE, RIGHT_PADDLE, Vector2.ZERO, 0.0)
	ball._process(ball.TRAIL_DURATION)
	assert_eq(ball._trail.size(), 0)

func test_power_up_collection_reports_last_paddle_that_hit_ball() -> void:
	ball._bounce_from_paddle(RIGHT_PADDLE, -1.0, false)
	ball.position = Vector2(100.0, 300.0)
	ball.velocity = Vector2(1000.0, 0.0)
	watch_signals(ball)
	ball.advance(0.2, LEFT_PADDLE, RIGHT_PADDLE, Vector2(150.0, 300.0), 5.0)

	assert_signal_emitted_with_parameters(ball, "power_up_collected", [false])
