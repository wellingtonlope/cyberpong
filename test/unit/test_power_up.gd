extends GutTest

const POWER_UP_SCRIPT := preload("res://scripts/power_up.gd")
const FIELD_SIZE := Vector2(1000.0, 600.0)
const PLAY_TOP := 60.0

var power_up

func before_each() -> void:
	power_up = POWER_UP_SCRIPT.new()
	power_up.add_child(Polygon2D.new(), true)
	power_up.get_child(0).name = "Body"
	power_up.add_child(Polygon2D.new(), true)
	power_up.get_child(1).name = "Core"
	power_up.add_child(Label.new(), true)
	power_up.get_child(2).name = "Symbol"
	add_child_autofree(power_up)
	power_up.configure(1.0, PLAY_TOP)
	power_up.reset_for_match(FIELD_SIZE)

func test_appearance_enters_available_state_inside_field() -> void:
	assert_true(power_up.appear(FIELD_SIZE))
	assert_true(power_up.is_available())
	assert_eq(power_up.hits_remaining, 5)
	assert_between(float(power_up.position.x), float(280.0), float(720.0))
	assert_between(float(power_up.position.y), float(168.0), float(492.0))
	assert_false(power_up.appear(FIELD_SIZE))

func test_available_item_expires_after_five_rebounds() -> void:
	power_up.appear(FIELD_SIZE)
	for _index in range(POWER_UP_SCRIPT.AVAILABLE_HITS):
		power_up.record_paddle_hit(true)

	assert_false(power_up.is_available())
	assert_eq(power_up.hits_remaining, 0)
	assert_false(power_up.visible)

func test_collect_assigns_owner_and_emits_effect_data() -> void:
	power_up.appear(FIELD_SIZE)
	power_up.effect_id = "double_size"
	watch_signals(power_up)
	power_up.collect(false)

	assert_false(power_up.owner_is_left)
	assert_eq(power_up.get_active_effect_id(), "double_size")
	assert_signal_emitted_with_parameters(power_up, "effect_changed", [false, true, 2.0, POWER_UP_SCRIPT.EFFECTS["double_size"]["color"]])

func test_collection_ignores_item_that_is_not_available() -> void:
	watch_signals(power_up)
	power_up.collect(true)

	assert_false(power_up.is_available())
	assert_eq(power_up.get_active_effect_id(), "")
	assert_signal_not_emitted(power_up, "effect_changed")

func test_default_effect_duration_is_ten_total_rebounds() -> void:
	power_up.appear(FIELD_SIZE)
	power_up.effect_id = "double_size"
	power_up.collect(true)

	assert_eq(power_up.effect_duration_hits, 10)
	assert_eq(power_up.hits_remaining, 10)

func test_active_duration_counts_rebounds_from_both_teams() -> void:
	power_up.active_duration_hits = 3
	power_up.appear(FIELD_SIZE)
	power_up.effect_id = "double_size"
	power_up.collect(true)

	power_up.record_paddle_hit(false)
	assert_eq(power_up.hits_remaining, 2)
	power_up.record_paddle_hit(true)
	assert_eq(power_up.hits_remaining, 1)
	power_up.record_paddle_hit(false)

	assert_eq(power_up.get_active_effect_id(), "")
	assert_eq(power_up.hits_remaining, 0)

func test_hit_limited_effect_counts_uses_only_for_owner() -> void:
	power_up.active_duration_hits = 10
	power_up.appear(FIELD_SIZE)
	power_up.effect_id = "ball_brake"
	power_up.collect(true)
	power_up.record_paddle_hit(false)

	assert_eq(power_up.effect_uses_remaining, 5)
	assert_eq(power_up.get_active_effect_id(), "ball_brake")
	for _index in range(4):
		power_up.record_paddle_hit(true)
	assert_eq(power_up.effect_uses_remaining, 1)
	assert_eq(power_up.get_active_effect_id(), "ball_brake")
	power_up.record_paddle_hit(true)

	assert_eq(power_up.get_active_effect_id(), "")
	assert_eq(power_up.effect_uses_remaining, 0)

func test_extra_defense_has_twenty_rebounds_and_consumes_on_save() -> void:
	power_up.active_duration_hits = 4
	power_up.appear(FIELD_SIZE)
	power_up.effect_id = "extra_defense"
	power_up.collect(true)

	assert_eq(power_up.effect_duration_hits, 20)
	assert_eq(power_up.hits_remaining, 20)
	power_up.record_paddle_hit(true, true)

	assert_eq(power_up.get_active_effect_id(), "")

func test_hud_information_tracks_available_and_held_states() -> void:
	var inactive_info: Dictionary = power_up.get_hud_info(7)
	assert_eq(inactive_info["title"], "Próximo power-up")
	assert_false(inactive_info["show_progress"])

	power_up.appear(FIELD_SIZE)
	power_up.effect_id = "half_size"
	var available_info: Dictionary = power_up.get_hud_info(7)
	assert_eq(available_info["title"], "Item no campo")
	assert_true(str(available_info["detail"]).contains("Raquete reduzida"))
	assert_true(available_info["show_progress"])

	power_up.collect(false)
	var held_info: Dictionary = power_up.get_hud_info(7)
	assert_eq(held_info["title"], "Raquete reduzida")
	assert_true(str(held_info["detail"]).contains("Magenta Volt"))
	assert_eq(held_info["progress"], 1.0)

	power_up.reset_for_match(FIELD_SIZE)
	power_up.appear(FIELD_SIZE)
	power_up.effect_id = "half_size"
	power_up.collect(true)
	var left_held_info: Dictionary = power_up.get_hud_info(7)
	assert_true(str(left_held_info["detail"]).contains("Cyan Circuit"))

func test_resizing_field_keeps_available_item_inside_play_area() -> void:
	power_up.appear(FIELD_SIZE)
	power_up.position = Vector2(900.0, 900.0)
	power_up.update_field_size(Vector2(200.0, 180.0))

	assert_eq(power_up.position, Vector2(188.0, 168.0))

