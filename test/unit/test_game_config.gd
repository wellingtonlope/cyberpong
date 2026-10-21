extends GutTest

func test_scaled_values_follow_the_game_scale() -> void:
	assert_eq(GameConfig.PADDLE_WIDTH, GameConfig.PADDLE_WIDTH_UNITS * GameConfig.GAME_SCALE)
	assert_eq(GameConfig.PADDLE_HEIGHT, GameConfig.PADDLE_HEIGHT_UNITS * GameConfig.GAME_SCALE)
	assert_eq(GameConfig.PADDLE_MARGIN, GameConfig.PADDLE_MARGIN_UNITS * GameConfig.GAME_SCALE)
	assert_eq(GameConfig.PADDLE_SPEED, GameConfig.PADDLE_SPEED_UNITS * GameConfig.GAME_SCALE)
	assert_eq(GameConfig.BALL_RADIUS, GameConfig.BALL_RADIUS_UNITS * GameConfig.GAME_SCALE)
	assert_eq(GameConfig.HUD_BAR_HEIGHT, GameConfig.HUD_BAR_HEIGHT_UNITS * GameConfig.GAME_SCALE)
	assert_eq(GameConfig.FIRST_SERVE_SPEED, GameConfig.FIRST_SERVE_SPEED_UNITS * GameConfig.GAME_SCALE)
	assert_eq(GameConfig.NEXT_SERVE_SPEED, GameConfig.NEXT_SERVE_SPEED_UNITS * GameConfig.GAME_SCALE)
	assert_eq(GameConfig.MAX_BALL_SPEED, GameConfig.MAX_BALL_SPEED_UNITS * GameConfig.GAME_SCALE)

func test_documented_measures_are_preserved() -> void:
	assert_eq(GameConfig.GAME_SCALE, 3.0)
	assert_eq(GameConfig.FIRST_SERVE_SPEED, 1140.0)
	assert_eq(GameConfig.NEXT_SERVE_SPEED, 1500.0)
	assert_eq(GameConfig.MAX_BALL_SPEED, 3000.0)
	assert_eq(GameConfig.PADDLE_WIDTH, 48.0)
	assert_eq(GameConfig.PADDLE_HEIGHT, 288.0)
	assert_eq(GameConfig.PADDLE_MARGIN, 120.0)
	assert_eq(GameConfig.PADDLE_SPEED, 1320.0)
	assert_eq(GameConfig.BALL_RADIUS, 30.0)
	assert_eq(GameConfig.HUD_BAR_HEIGHT, 180.0)
	assert_eq(GameConfig.WINNING_SCORE, 3)
	assert_eq(GameConfig.POWER_UP_MIN_SPAWN_INTERVAL, 5)
	assert_eq(GameConfig.POWER_UP_MAX_SPAWN_INTERVAL, 15)

func test_serve_speeds_keep_the_documented_order() -> void:
	assert_lt(GameConfig.FIRST_SERVE_SPEED, GameConfig.NEXT_SERVE_SPEED)
	assert_lt(GameConfig.NEXT_SERVE_SPEED, GameConfig.MAX_BALL_SPEED)
