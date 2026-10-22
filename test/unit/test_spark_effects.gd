extends GutTest

const SPARK_EFFECTS_SCRIPT := preload("res://scripts/spark_effects.gd")

var spark_effects

func before_each() -> void:
	spark_effects = add_child_autofree(SPARK_EFFECTS_SCRIPT.new())
	spark_effects.configure(1.0, 60.0, 12.0)

func test_paddle_hit_creates_speed_scaled_particle_count() -> void:
	spark_effects.play_paddle_hit(Vector2(100.0, 100.0), Color.CYAN, 1.0, 1.0)
	assert_eq(spark_effects._particles.size(), 16)

	spark_effects._particles.clear()
	spark_effects.play_paddle_hit(Vector2(100.0, 100.0), Color.CYAN, 1.0, 4.0)
	assert_eq(spark_effects._particles.size(), 28)

func test_paddle_hit_creates_impact_ring_that_expires() -> void:
	spark_effects.play_paddle_hit(Vector2(100.0, 100.0), Color.CYAN, 1.0, 1.0)

	assert_eq(spark_effects._rings.size(), 1)
	var ring: Dictionary = spark_effects._rings[0]
	assert_eq(ring["position"], Vector2(100.0, 100.0))
	assert_eq(ring["color"], Color.CYAN)
	assert_gt(float(ring["end_radius"]), float(ring["start_radius"]))

	ring["age"] = ring["lifetime"] - 0.01
	spark_effects._rings[0] = ring
	spark_effects._physics_process(0.02)
	assert_eq(spark_effects._rings.size(), 0)

func test_particles_expire_after_their_lifetime() -> void:
	spark_effects.play_paddle_hit(Vector2(100.0, 100.0), Color.CYAN, 1.0, 1.0)
	for index in range(spark_effects._particles.size()):
		var particle: Dictionary = spark_effects._particles[index]
		particle["age"] = particle["lifetime"] - 0.01
		spark_effects._particles[index] = particle

	spark_effects._physics_process(0.02)
	assert_eq(spark_effects._particles.size(), 0)

func test_particle_bounces_inward_from_side_boundary() -> void:
	spark_effects._particles.clear()
	spark_effects._particles.append({
		"position": Vector2(30.0, 100.0),
		"previous_position": Vector2(30.0, 100.0),
		"velocity": Vector2(-100.0, 0.0),
		"color": Color.CYAN,
		"radius": 5.0,
		"age": 0.0,
		"lifetime": 10.0,
	})

	spark_effects._physics_process(0.2)
	var particle: Dictionary = spark_effects._particles[0]
	assert_eq(particle["position"].x, 17.0)
	assert_gt(float(particle["velocity"].x), float(0.0))

func test_power_up_grow_burst_sends_particles_outward() -> void:
	spark_effects.play_power_up_burst(Vector2(100.0, 100.0), Color.GREEN, 1.0)

	assert_eq(spark_effects._rings.size(), 1)
	assert_eq(spark_effects._particles.size(), 26)

	var ring: Dictionary = spark_effects._rings[0]
	assert_gt(float(ring["end_radius"]), float(ring["start_radius"]))

	for particle in spark_effects._particles:
		assert_false(bool(particle["attracts"]))
		assert_gt(float(particle["velocity"].length()), float(0.0))

func test_power_up_shrink_burst_pulls_particles_towards_the_paddle() -> void:
	spark_effects.play_power_up_burst(Vector2(100.0, 100.0), Color.RED, -1.0)

	assert_eq(spark_effects._rings.size(), 1)
	assert_eq(spark_effects._particles.size(), 26)

	var ring: Dictionary = spark_effects._rings[0]
	assert_lt(float(ring["end_radius"]), float(ring["start_radius"]))

	for particle in spark_effects._particles:
		assert_true(bool(particle["attracts"]))
		assert_eq(particle["attract_center"], Vector2(100.0, 100.0))
		assert_gt(float(particle["position"].distance_to(Vector2(100.0, 100.0))), float(0.0))

func test_power_up_burst_without_a_direction_does_not_create_effects() -> void:
	spark_effects.play_power_up_burst(Vector2(100.0, 100.0), Color.GREEN, 0.0)

	assert_eq(spark_effects._rings.size(), 0)
	assert_eq(spark_effects._particles.size(), 0)

func test_shrink_burst_particles_move_towards_the_paddle_center() -> void:
	spark_effects.play_power_up_burst(Vector2(100.0, 100.0), Color.RED, -1.0)
	var particle: Dictionary = spark_effects._particles[0]
	var starting_distance: float = particle["position"].distance_to(Vector2(100.0, 100.0))

	spark_effects._physics_process(0.1)
	var moved: Dictionary = spark_effects._particles[0]

	assert_lt(float(moved["position"].distance_to(Vector2(100.0, 100.0))), float(starting_distance))

