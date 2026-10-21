extends Node

const Effect = preload("res://scripts/power_up_effect.gd")

const SOUNDS := {
	"hit_cyan": preload("res://assets/audio/hit_cyan.wav"),
	"hit_magenta": preload("res://assets/audio/hit_magenta.wav"),
	"wall_bounce": preload("res://assets/audio/wall_bounce.wav"),
	"serve": preload("res://assets/audio/serve.wav"),
	"score": preload("res://assets/audio/score.wav"),
	"power_up_spawn": preload("res://assets/audio/power_up_spawn.wav"),
	"power_up_collect": preload("res://assets/audio/power_up_collect.wav"),
	"pu_double": preload("res://assets/audio/pu_double.wav"),
	"pu_half": preload("res://assets/audio/pu_half.wav"),
	"pu_brake": preload("res://assets/audio/pu_brake.wav"),
	"pu_bounce": preload("res://assets/audio/pu_bounce.wav"),
	"pu_defense": preload("res://assets/audio/pu_defense.wav"),
	"power_up_expire": preload("res://assets/audio/power_up_expire.wav"),
	"ui_move": preload("res://assets/audio/ui_move.wav"),
	"ui_select": preload("res://assets/audio/ui_select.wav"),
	"pause_open": preload("res://assets/audio/pause_open.wav"),
	"pause_close": preload("res://assets/audio/pause_close.wav"),
	"win": preload("res://assets/audio/win.wav"),
	"credits_sting": preload("res://assets/audio/credits_sting.wav"),
}

const POOL_SIZE := 12

var sound_enabled := true
var master_volume_db := 0.0
var last_played_sound := ""
var last_pitch_scale := 1.0
var play_count := 0

var _players: Array[AudioStreamPlayer] = []
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	for i in range(POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.name = "AudioPlayer_%d" % i
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		_players.append(player)

func play(sound_name: String, pitch_scale: float = 1.0, volume_db: float = 0.0) -> AudioStreamPlayer:
	if not sound_enabled:
		return null
	var stream: AudioStream = SOUNDS.get(sound_name)
	if stream == null:
		return null

	last_played_sound = sound_name
	last_pitch_scale = pitch_scale
	play_count += 1

	var player := _get_available_player()
	if player == null:
		return null

	player.stream = stream
	player.pitch_scale = pitch_scale
	player.volume_db = master_volume_db + volume_db
	player.play()
	return player

func play_paddle_hit(is_left: bool, speed_ratio: float = 1.0) -> AudioStreamPlayer:
	var sound_name := "hit_cyan" if is_left else "hit_magenta"
	var pitch := clampf(0.92 + (speed_ratio - 1.0) * 0.22, 0.85, 1.45)
	pitch += _rng.randf_range(-0.02, 0.02)
	return play(sound_name, pitch)

func play_wall_bounce() -> AudioStreamPlayer:
	var pitch := _rng.randf_range(0.96, 1.04)
	return play("wall_bounce", pitch, -2.0)

func play_serve(_server_is_left: bool = true) -> AudioStreamPlayer:
	return play("serve", 1.0, -1.0)

func play_score(_scorer_is_left: bool = true) -> AudioStreamPlayer:
	return play("score", 1.0, 1.0)

func play_win(_winner_is_left: bool = true) -> AudioStreamPlayer:
	return play("win", 1.0, 2.0)

func play_power_up_spawn() -> AudioStreamPlayer:
	return play("power_up_spawn", 1.0, 0.0)

func play_power_up_collect(effect_id: int = Effect.Id.NONE) -> AudioStreamPlayer:
	play("power_up_collect", 1.0, 1.0)
	match effect_id:
		Effect.Id.DOUBLE_SIZE:
			return play("pu_double", 1.0, 0.5)
		Effect.Id.HALF_SIZE:
			return play("pu_half", 1.0, 0.5)
		Effect.Id.BALL_BRAKE:
			return play("pu_brake", 1.0, 0.5)
		Effect.Id.POWERFUL_BOUNCE:
			return play("pu_bounce", 1.0, 0.5)
		Effect.Id.EXTRA_DEFENSE:
			return play("pu_defense", 1.0, 0.5)
		_:
			return null

func play_power_up_expire() -> AudioStreamPlayer:
	return play("power_up_expire", 1.0, -1.0)

func play_powerful_bounce() -> AudioStreamPlayer:
	return play("pu_bounce", 1.0, 1.5)

func play_ball_brake() -> AudioStreamPlayer:
	return play("pu_brake", 1.0, 0.5)

func play_extra_defense() -> AudioStreamPlayer:
	return play("pu_defense", 1.0, 2.0)

func play_ui_move() -> AudioStreamPlayer:
	var pitch := _rng.randf_range(0.97, 1.03)
	return play("ui_move", pitch, -4.0)

func play_ui_select() -> AudioStreamPlayer:
	return play("ui_select", 1.0, -1.0)

func play_pause_open() -> AudioStreamPlayer:
	return play("pause_open", 1.0, -1.0)

func play_pause_close() -> AudioStreamPlayer:
	return play("pause_close", 1.0, -1.0)

func play_credits_sting() -> AudioStreamPlayer:
	return play("credits_sting", 1.0, 1.0)

func _get_available_player() -> AudioStreamPlayer:
	for player in _players:
		if not player.playing:
			return player
	# If all players are busy, steal the oldest one
	if not _players.is_empty():
		return _players[0]
	return null
