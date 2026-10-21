extends Node2D

const Effect = preload("res://scripts/power_up_effect.gd")

signal paddle_hit(
	is_left: bool,
	impact_position: Vector2,
	horizontal_direction: float,
	speed_ratio: float,
	used_extra_defense: bool
)
signal missed(left_side: bool)
signal speed_changed(current_speed: float)
signal power_up_collected(is_left: bool)
signal wall_hit(hit_position: Vector2)

const DEFAULT_RADIUS := 30.0
const DEFAULT_SPEED := 1140.0
const MAX_SPEED := 3000.0
const BALL_COLOR := Color(1.0, 0.92, 0.12)
const BRAKE_SPEED_MULTIPLIER := 0.92
const BRAKE_MINIMUM_SPEED_RATIO := 0.65
const POWERFUL_BOUNCE_SPEED_MULTIPLIER := 1.18
const POWERFUL_BOUNCE_VISUAL_SCALE := 1.2
const TRAIL_DURATION := 0.16
const TRAIL_MAX_SAMPLES := 12

@onready var body: Polygon2D = $Body

var field_size := Vector2.ZERO
var velocity := Vector2.ZERO
var current_speed := DEFAULT_SPEED
var radius := DEFAULT_RADIUS
var base_speed := DEFAULT_SPEED
var play_top := 0.0
var _paddle_hits := 0
var _last_hit_is_left := true
var _powerful_bounce_visual_scale := 1.0
var _ball_brake_reference_speed := DEFAULT_SPEED
var _ball_brake_active := false
var _stopped := false
var _deformation_tween: Tween
var _random := RandomNumberGenerator.new()
var _trail: Array[Dictionary] = []

func _ready() -> void:
	_random.randomize()
	body.color = BALL_COLOR
	body.z_index = 3

func _process(delta: float) -> void:
	if _trail.is_empty():
		return
	for index in range(_trail.size() - 1, -1, -1):
		var sample: Dictionary = _trail[index]
		sample["age"] = float(sample["age"]) + delta
		if float(sample["age"]) >= TRAIL_DURATION:
			_trail.remove_at(index)
		else:
			_trail[index] = sample
	queue_redraw()

func restart(
	size: Vector2,
	ball_radius: float,
	starting_speed: float,
	left_paddle: Rect2,
	right_paddle: Rect2,
	play_top_boundary: float = 0.0
) -> void:
	field_size = size
	radius = ball_radius
	play_top = play_top_boundary
	body.polygon = _make_circle_polygon(radius, 48)
	body.scale = Vector2.ONE
	_trail.clear()
	if _deformation_tween != null and _deformation_tween.is_running():
		_deformation_tween.kill()
	serve_from_paddle(left_paddle, right_paddle, true, starting_speed)

func serve_from_paddle(left_paddle: Rect2, right_paddle: Rect2, server_is_left: bool, starting_speed: float) -> void:
	if _deformation_tween != null and _deformation_tween.is_running():
		_deformation_tween.kill()
	_powerful_bounce_visual_scale = 1.0
	body.scale = Vector2.ONE
	_trail.clear()
	base_speed = starting_speed
	current_speed = base_speed
	_ball_brake_reference_speed = current_speed
	_ball_brake_active = false
	_paddle_hits = 0
	_last_hit_is_left = server_is_left
	var server_rect := left_paddle if server_is_left else right_paddle
	var horizontal_direction := 1.0 if server_is_left else -1.0
	var vertical_angle := _random.randf_range(-0.42, 0.42)
	var serve_x := server_rect.end.x + radius + 4.0
	if not server_is_left:
		serve_x = server_rect.position.x - radius - 4.0
	position = Vector2(serve_x, server_rect.get_center().y)
	velocity = Vector2(horizontal_direction, vertical_angle).normalized() * current_speed
	_stopped = false
	speed_changed.emit(current_speed)

func update_field_size(size: Vector2) -> void:
	field_size = size
	position.y = clampf(position.y, play_top + radius, field_size.y - radius)

func advance(
	delta: float,
	left_paddle: Rect2,
	right_paddle: Rect2,
	power_up_position: Vector2,
	power_up_radius: float,
	active_power_up_effect: int = Effect.Id.NONE,
	power_up_owner_is_left: bool = false
) -> void:
	if _stopped:
		return
	if active_power_up_effect == Effect.Id.BALL_BRAKE:
		if not _ball_brake_active:
			_ball_brake_reference_speed = minf(current_speed, MAX_SPEED)
			_ball_brake_active = true
	elif _ball_brake_active:
		_ball_brake_active = false

	var previous_position := position
	position += velocity * delta
	_record_trail(previous_position)

	if position.y - radius <= play_top:
		position.y = play_top + radius
		velocity.y = absf(velocity.y)
		wall_hit.emit(Vector2(position.x, play_top))
	elif position.y + radius >= field_size.y:
		position.y = field_size.y - radius
		velocity.y = -absf(velocity.y)
		wall_hit.emit(Vector2(position.x, field_size.y))

	if power_up_radius > 0.0 and _segment_intersects_power_up(
		previous_position,
		position,
		power_up_position,
		radius + power_up_radius
	):
		power_up_collected.emit(_last_hit_is_left)

	var ball_rect := Rect2(position - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)
	var left_effect: int = Effect.Id.NONE
	var right_effect: int = Effect.Id.NONE
	if active_power_up_effect == Effect.Id.BALL_BRAKE:
		left_effect = active_power_up_effect
		right_effect = active_power_up_effect
	elif power_up_owner_is_left:
		left_effect = active_power_up_effect
	else:
		right_effect = active_power_up_effect

	if velocity.x < 0.0 and ball_rect.intersects(left_paddle):
		position.x = left_paddle.end.x + radius
		_bounce_from_paddle(left_paddle, 1.0, true, left_effect, false, power_up_owner_is_left)
	elif velocity.x > 0.0 and ball_rect.intersects(right_paddle):
		position.x = right_paddle.position.x - radius
		_bounce_from_paddle(right_paddle, -1.0, false, right_effect, false, power_up_owner_is_left)

	if position.x + radius < left_paddle.position.x:
		if active_power_up_effect == Effect.Id.EXTRA_DEFENSE and power_up_owner_is_left:
			position.x = left_paddle.end.x + radius
			_bounce_from_paddle(left_paddle, 1.0, true, Effect.Id.NONE, true)
		else:
			_stop_after_miss(true)
	elif position.x - radius > right_paddle.end.x:
		if active_power_up_effect == Effect.Id.EXTRA_DEFENSE and not power_up_owner_is_left:
			position.x = right_paddle.position.x - radius
			_bounce_from_paddle(right_paddle, -1.0, false, Effect.Id.NONE, true)
		else:
			_stop_after_miss(false)

func _bounce_from_paddle(
	paddle: Rect2,
	horizontal_direction: float,
	is_left: bool,
	active_power_up_effect: int = Effect.Id.NONE,
	used_extra_defense: bool = false,
	power_up_owner_is_left: bool = false
) -> void:
	_last_hit_is_left = is_left
	var hit_position := (position.y - paddle.get_center().y) / (paddle.size.y * 0.5)
	hit_position = clampf(hit_position + _random.randf_range(-0.08, 0.08), -1.0, 1.0)
	_paddle_hits += 1
	var previous_speed := current_speed
	if active_power_up_effect == Effect.Id.BALL_BRAKE:
		if _paddle_hits % 2 == 0 and _ball_brake_reference_speed < MAX_SPEED:
			_ball_brake_reference_speed = minf(_ball_brake_reference_speed * 1.1, MAX_SPEED)
		current_speed = _ball_brake_reference_speed
		if is_left != power_up_owner_is_left:
			current_speed = maxf(
				_ball_brake_reference_speed * BRAKE_SPEED_MULTIPLIER,
				base_speed * BRAKE_MINIMUM_SPEED_RATIO
			)
		_powerful_bounce_visual_scale = 1.0
	elif active_power_up_effect == Effect.Id.POWERFUL_BOUNCE:
		if _paddle_hits % 2 == 0 and current_speed < MAX_SPEED:
			current_speed = minf(current_speed * 1.1, MAX_SPEED)
		current_speed = minf(
			current_speed * POWERFUL_BOUNCE_SPEED_MULTIPLIER,
			MAX_SPEED * POWERFUL_BOUNCE_SPEED_MULTIPLIER
		)
		_powerful_bounce_visual_scale = POWERFUL_BOUNCE_VISUAL_SCALE
	else:
		if _paddle_hits % 2 == 0 and current_speed < MAX_SPEED:
			current_speed = minf(current_speed * 1.1, MAX_SPEED)
		current_speed = minf(current_speed, MAX_SPEED)
		_powerful_bounce_visual_scale = 1.0
	if not is_equal_approx(current_speed, previous_speed):
		speed_changed.emit(current_speed)
	velocity = Vector2(horizontal_direction, hit_position * 0.85).normalized() * current_speed
	_animate_body(Vector2(0.72, 1.16))
	var impact_position := position - Vector2(horizontal_direction * radius, 0.0)
	paddle_hit.emit(is_left, impact_position, horizontal_direction, current_speed / base_speed, used_extra_defense)

func _stop_after_miss(left_side: bool) -> void:
	_stopped = true
	missed.emit(left_side)

func _segment_intersects_power_up(start: Vector2, end: Vector2, center: Vector2, combined_radius: float) -> bool:
	var segment := end - start
	var closest_point := start
	if segment.length_squared() > 0.0:
		var along_segment := clampf((center - start).dot(segment) / segment.length_squared(), 0.0, 1.0)
		closest_point = start + segment * along_segment
	return closest_point.distance_squared_to(center) <= combined_radius * combined_radius

func _animate_body(impact_scale: Vector2) -> void:
	if _deformation_tween != null and _deformation_tween.is_running():
		_deformation_tween.kill()
	body.scale = impact_scale * _powerful_bounce_visual_scale
	_deformation_tween = create_tween()
	_deformation_tween.tween_property(
		body,
		"scale",
		Vector2.ONE * _powerful_bounce_visual_scale,
		0.14
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _record_trail(point: Vector2) -> void:
	_trail.append({"position": point, "age": 0.0})
	while _trail.size() > TRAIL_MAX_SAMPLES:
		_trail.pop_front()
	queue_redraw()

func _draw() -> void:
	_draw_trail()
	_draw_glow()

func _draw_trail() -> void:
	if _trail.is_empty():
		return
	var first_sample: Dictionary = _trail[0]
	var previous_position: Vector2 = first_sample["position"]
	var previous_local := previous_position - position
	for index in range(1, _trail.size()):
		var sample: Dictionary = _trail[index]
		var sample_position: Vector2 = sample["position"]
		var sample_local := sample_position - position
		var age: float = sample["age"]
		var fade := clampf(1.0 - age / TRAIL_DURATION, 0.0, 1.0)
		var ratio := float(index) / float(maxi(_trail.size() - 1, 1))
		var width := radius * lerpf(0.35, 0.95, ratio)
		draw_line(previous_local, sample_local, Color(BALL_COLOR, fade * 0.16), width * 2.4, true)
		draw_line(previous_local, sample_local, Color(BALL_COLOR, fade * 0.58), width, true)
		previous_local = sample_local

	var newest: Dictionary = _trail[_trail.size() - 1]
	var newest_age: float = newest["age"]
	var newest_fade := clampf(1.0 - newest_age / TRAIL_DURATION, 0.0, 1.0)
	draw_line(previous_local, Vector2.ZERO, Color(BALL_COLOR, newest_fade * 0.16), radius * 2.4, true)
	draw_line(previous_local, Vector2.ZERO, Color(BALL_COLOR, newest_fade * 0.58), radius * 0.95, true)

func _draw_glow() -> void:
	var glow_radius := radius * _powerful_bounce_visual_scale
	draw_circle(Vector2.ZERO, glow_radius * 1.55, Color(BALL_COLOR, 0.055))
	draw_circle(Vector2.ZERO, glow_radius * 1.2, Color(BALL_COLOR, 0.11))

func _make_circle_polygon(circle_radius: float, point_count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(point_count):
		var angle := TAU * float(index) / float(point_count)
		points.append(Vector2(cos(angle), sin(angle)) * circle_radius)
	return points
