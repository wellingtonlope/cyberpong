extends GutTest

const MAIN_SCENE := preload("res://main.tscn")
const Effect = preload("res://scripts/power_up_effect.gd")
const FIELD_SIZE := Vector2(2880.0, 1620.0)

var game

func before_each() -> void:
	get_viewport().size = FIELD_SIZE
	SoundManager.play_count = 0
	SoundManager.last_played_sound = ""
	game = add_child_autofree(MAIN_SCENE.instantiate())
	var credits = game.get_node_or_null("CreditsScreen")
	if credits != null:
		credits.skip()
		credits._process(credits.SKIP_FADE_OUT_DURATION)
	var menu = game.get_node_or_null("GameMenu")
	if menu != null:
		menu.select_mode(GameMode.Mode.PLAYER_VS_AI)
	game.game_over = true
	SoundManager.play_count = 0
	SoundManager.last_played_sound = ""

func test_wall_bounce_plays_wall_bounce_sound() -> void:
	game.ball.position = Vector2(1000.0, game.ball.play_top + game.ball.radius + 1.0)
	game.ball.velocity = Vector2(0.0, -500.0)
	game.ball.advance(
		0.01,
		game.left_paddle.get_collision_rect(),
		game.right_paddle.get_collision_rect(),
		Vector2.ZERO,
		0.0
	)
	assert_eq(SoundManager.last_played_sound, "wall_bounce")

func test_paddle_hit_plays_paddle_sound_per_team() -> void:
	game._on_ball_paddle_hit(true, Vector2(100.0, 300.0), 1.0, 1.0, false)
	assert_eq(SoundManager.last_played_sound, "hit_cyan")

	game._on_ball_paddle_hit(false, Vector2(2000.0, 300.0), -1.0, 1.0, false)
	assert_eq(SoundManager.last_played_sound, "hit_magenta")

func test_paddle_hit_with_extra_defense_plays_defense_sound() -> void:
	game._on_ball_paddle_hit(true, Vector2(100.0, 300.0), 1.0, 1.0, true)
	assert_eq(SoundManager.last_played_sound, "pu_defense")

func test_paddle_hit_with_powerful_bounce_plays_bounce_sound() -> void:
	game.power_up.status = game.power_up.Status.HELD
	game.power_up.owner_is_left = true
	game.power_up.effect_id = Effect.Id.POWERFUL_BOUNCE
	game.power_up.hits_remaining = 8
	game.power_up.effect_uses_remaining = 4

	game._on_ball_paddle_hit(true, Vector2(100.0, 300.0), 1.0, 1.0, false)
	assert_eq(SoundManager.last_played_sound, "pu_bounce")

func test_paddle_hit_with_ball_brake_plays_brake_sound() -> void:
	game.power_up.status = game.power_up.Status.HELD
	game.power_up.owner_is_left = true
	game.power_up.effect_id = Effect.Id.BALL_BRAKE
	game.power_up.hits_remaining = 8
	game.power_up.effect_uses_remaining = 4

	# When opponent (right) hits the ball while left owns ball brake
	game._on_ball_paddle_hit(false, Vector2(2000.0, 300.0), -1.0, 1.0, false)
	assert_eq(SoundManager.last_played_sound, "pu_brake")

func test_score_and_win_trigger_respective_sounds() -> void:
	game.left_score = 0
	game.right_score = 0
	game._on_ball_missed(false) # left scores point 1
	assert_eq(SoundManager.last_played_sound, "serve") # after score, serves again

	# Now score winning point (3)
	game.left_score = 2
	game._on_ball_missed(false)
	assert_eq(SoundManager.last_played_sound, "win")

func test_pause_open_and_resume_trigger_pause_sounds() -> void:
	game.game_over = false
	game._menu_shown = false
	game._open_pause_menu()
	assert_eq(SoundManager.last_played_sound, "pause_open")

	game._on_pause_resume_requested()
	assert_eq(SoundManager.last_played_sound, "pause_close")
