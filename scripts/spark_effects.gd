extends Node2D

const BOUNCE_RESTITUTION := 0.72
const TANGENTIAL_DAMPING := 0.9
const RING_LIFETIME := 0.3
const RING_START_RADIUS := 2.0
const RING_END_RADIUS := 22.0

var game_scale := 3.0
var top_boundary := 180.0
var side_boundary := 36.0
var _random := RandomNumberGenerator.new()
var _particles: Array[Dictionary] = []
var _rings: Array[Dictionary] = []

func _ready() -> void:
	_random.randomize()

func configure(scale: float, field_top: float, field_side: float) -> void:
	game_scale = scale
	top_boundary = field_top
	side_boundary = field_side

func play_paddle_hit(position: Vector2, tint: Color, horizontal_direction: float, speed_ratio: float) -> void:
	var size_factor := sqrt(speed_ratio)
	var amount := clampi(roundi(16.0 * size_factor), 10, 28)
	var base_direction := Vector2(horizontal_direction, -0.1).normalized()
	var lifetime := clampf(0.24 * size_factor, 0.2, 0.34)
	_rings.append({
		"position": position,
		"color": tint,
		"age": 0.0,
		"lifetime": RING_LIFETIME,
		"start_radius": RING_START_RADIUS * game_scale,
		"end_radius": RING_END_RADIUS * game_scale * size_factor,
	})

	for _index in range(amount):
		var direction := base_direction.rotated(_random.randf_range(-0.9, 0.9))
		var particle_speed := _random.randf_range(90.0, 190.0) * game_scale * size_factor
		var radius := _random.randf_range(0.45, 0.9) * game_scale
		_particles.append({
			"position": position,
			"previous_position": position,
			"velocity": direction * particle_speed,
			"color": tint,
			"radius": radius,
			"age": 0.0,
			"lifetime": lifetime * _random.randf_range(0.8, 1.0),
		})
	queue_redraw()

func _physics_process(delta: float) -> void:
	if _particles.is_empty() and _rings.is_empty():
		return

	for index in range(_rings.size() - 1, -1, -1):
		var ring: Dictionary = _rings[index]
		ring["age"] = float(ring["age"]) + delta
		if float(ring["age"]) >= float(ring["lifetime"]):
			_rings.remove_at(index)
		else:
			_rings[index] = ring

	var viewport_size := get_viewport_rect().size
	for index in range(_particles.size() - 1, -1, -1):
		var particle := _particles[index]
		particle["age"] += delta
		if particle["age"] >= particle["lifetime"]:
			_particles.remove_at(index)
			continue

		var particle_position: Vector2 = particle["position"]
		var velocity: Vector2 = particle["velocity"]
		var radius: float = particle["radius"]
		particle["previous_position"] = particle_position
		velocity.y += 520.0 * game_scale * delta
		particle_position += velocity * delta

		var left_edge := side_boundary + radius
		var right_edge := maxf(left_edge, viewport_size.x - side_boundary - radius)
		var top_edge := top_boundary + radius
		var bottom_edge := maxf(top_edge, viewport_size.y - radius)
		var bounced := false
		if particle_position.x < left_edge:
			particle_position.x = left_edge
			velocity.x = absf(velocity.x) * BOUNCE_RESTITUTION
			velocity.y *= TANGENTIAL_DAMPING
			bounced = true
		elif particle_position.x > right_edge:
			particle_position.x = right_edge
			velocity.x = -absf(velocity.x) * BOUNCE_RESTITUTION
			velocity.y *= TANGENTIAL_DAMPING
			bounced = true
		if particle_position.y < top_edge:
			particle_position.y = top_edge
			velocity.y = absf(velocity.y) * BOUNCE_RESTITUTION
			velocity.x *= TANGENTIAL_DAMPING
			bounced = true
		elif particle_position.y > bottom_edge:
			particle_position.y = bottom_edge
			velocity.y = -absf(velocity.y) * BOUNCE_RESTITUTION
			velocity.x *= TANGENTIAL_DAMPING
			bounced = true

		particle["position"] = particle_position
		particle["velocity"] = velocity
		if bounced:
			particle["previous_position"] = particle_position
		_particles[index] = particle

	queue_redraw()

func _draw() -> void:
	for ring in _rings:
		var ring_age: float = ring["age"]
		var ring_lifetime: float = ring["lifetime"]
		var progress := clampf(ring_age / ring_lifetime, 0.0, 1.0)
		var eased_progress := 1.0 - pow(1.0 - progress, 2.0)
		var ring_position: Vector2 = ring["position"]
		var ring_tint: Color = ring["color"]
		var ring_radius := lerpf(float(ring["start_radius"]), float(ring["end_radius"]), eased_progress)
		var ring_alpha := pow(1.0 - progress, 2.0)
		draw_arc(
			ring_position,
			ring_radius,
			0.0,
			TAU,
			48,
			Color(ring_tint, ring_alpha * 0.72),
			maxf(1.0, 2.0 * game_scale * (1.0 - progress * 0.5)),
			true
		)
		draw_circle(ring_position, ring_radius * 0.92, Color(ring_tint, ring_alpha * 0.05))

	for particle in _particles:
		var fade := 1.0 - float(particle["age"]) / float(particle["lifetime"])
		var alpha := fade * fade
		var tint: Color = particle["color"]
		var color := Color(tint.r, tint.g, tint.b, tint.a * alpha)
		var particle_position: Vector2 = particle["position"]
		var previous_position: Vector2 = particle["previous_position"]
		var radius: float = particle["radius"]
		draw_line(previous_position, particle_position, Color(tint.r, tint.g, tint.b, color.a * 0.78), maxf(1.0, radius), true)
		draw_circle(particle_position, radius * 1.6, Color(tint.r, tint.g, tint.b, color.a * 0.16))
		draw_circle(particle_position, radius * 0.55, color)
