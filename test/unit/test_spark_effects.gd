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

