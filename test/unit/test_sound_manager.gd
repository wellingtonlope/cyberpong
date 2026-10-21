extends GutTest

const SoundManagerScript = preload("res://scripts/sound_manager.gd")
const Effect = preload("res://scripts/power_up_effect.gd")

var sound_manager

func before_each() -> void:
	sound_manager = add_child_autofree(SoundManagerScript.new())
	sound_manager.sound_enabled = true
	sound_manager.play_count = 0
	sound_manager.last_played_sound = ""

func test_all_expected_audio_assets_are_loaded() -> void:
	var expected_keys := [
		"hit_cyan",
		"hit_magenta",
		"wall_bounce",
		"serve",
		"score",
		"power_up_spawn",
		"power_up_collect",
		"pu_double",
		"pu_half",
		"pu_brake",
		"pu_bounce",
		"pu_defense",
		"power_up_expire",
		"ui_move",
		"ui_select",
		"pause_open",
		"pause_close",
		"win",
		"credits_sting",
	]
	for key in expected_keys:
		assert_true(sound_manager.SOUNDS.has(key), "Missing key in SOUNDS dictionary: %s" % key)
		var stream: AudioStream = sound_manager.SOUNDS.get(key)
		assert_not_null(stream, "Sound stream for %s is null" % key)

func test_audio_pool_initializes_with_correct_size() -> void:
	assert_eq(sound_manager._players.size(), sound_manager.POOL_SIZE)
	for player in sound_manager._players:
		assert_eq(player.process_mode, Node.PROCESS_MODE_ALWAYS)

func test_play_plays_sound_and_tracks_state() -> void:
	var player = sound_manager.play("ui_select", 1.25)
	assert_not_null(player)
	assert_eq(sound_manager.last_played_sound, "ui_select")
	assert_almost_eq(sound_manager.last_pitch_scale, 1.25, 0.01)
	assert_eq(sound_manager.play_count, 1)

func test_play_returns_null_when_disabled() -> void:
	sound_manager.sound_enabled = false
	var player = sound_manager.play("ui_select")
	assert_null(player)
	assert_eq(sound_manager.play_count, 0)

func test_paddle_hit_selects_side_sound_and_scales_pitch() -> void:
	sound_manager.play_paddle_hit(true, 1.0)
	assert_eq(sound_manager.last_played_sound, "hit_cyan")
	var normal_pitch: float = float(sound_manager.last_pitch_scale)

	sound_manager.play_paddle_hit(false, 1.0)
	assert_eq(sound_manager.last_played_sound, "hit_magenta")

	sound_manager.play_paddle_hit(true, 1.5)
	assert_gt(sound_manager.last_pitch_scale, normal_pitch - 0.05)

func test_power_up_collection_plays_specific_effect_sounds() -> void:
	sound_manager.play_power_up_collect(Effect.Id.DOUBLE_SIZE)
	assert_eq(sound_manager.last_played_sound, "pu_double")

	sound_manager.play_power_up_collect(Effect.Id.HALF_SIZE)
	assert_eq(sound_manager.last_played_sound, "pu_half")

	sound_manager.play_power_up_collect(Effect.Id.BALL_BRAKE)
	assert_eq(sound_manager.last_played_sound, "pu_brake")

	sound_manager.play_power_up_collect(Effect.Id.POWERFUL_BOUNCE)
	assert_eq(sound_manager.last_played_sound, "pu_bounce")

	sound_manager.play_power_up_collect(Effect.Id.EXTRA_DEFENSE)
	assert_eq(sound_manager.last_played_sound, "pu_defense")

func test_gameplay_sound_helper_methods() -> void:
	sound_manager.play_wall_bounce()
	assert_eq(sound_manager.last_played_sound, "wall_bounce")

	sound_manager.play_serve()
	assert_eq(sound_manager.last_played_sound, "serve")

	sound_manager.play_score()
	assert_eq(sound_manager.last_played_sound, "score")

	sound_manager.play_win()
	assert_eq(sound_manager.last_played_sound, "win")

	sound_manager.play_power_up_spawn()
	assert_eq(sound_manager.last_played_sound, "power_up_spawn")

	sound_manager.play_power_up_expire()
	assert_eq(sound_manager.last_played_sound, "power_up_expire")

	sound_manager.play_pause_open()
	assert_eq(sound_manager.last_played_sound, "pause_open")

	sound_manager.play_pause_close()
	assert_eq(sound_manager.last_played_sound, "pause_close")

	sound_manager.play_credits_sting()
	assert_eq(sound_manager.last_played_sound, "credits_sting")
