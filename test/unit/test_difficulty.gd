extends GutTest



func test_presets_are_ordered_from_easiest_to_hardest() -> void:
	assert_eq(Difficulty.PRESETS.size(), 3)
	assert_eq(Difficulty.level_at(0), Difficulty.Level.EASY)
	assert_eq(Difficulty.level_at(1), Difficulty.Level.NORMAL)
	assert_eq(Difficulty.level_at(2), Difficulty.Level.HARD)
	for index in range(1, Difficulty.PRESETS.size()):
		var previous: Difficulty.Preset = Difficulty.PRESETS[index - 1]
		var current: Difficulty.Preset = Difficulty.PRESETS[index]
		assert_gt(current.ai_speed_factor, previous.ai_speed_factor)
		assert_lt(current.ai_reaction_delay, previous.ai_reaction_delay)
		assert_lt(current.ai_dead_zone_ratio, previous.ai_dead_zone_ratio)


func test_dead_zone_ratio_reproduces_the_documented_pixels_with_default_paddle() -> void:
	assert_almost_eq(
		float(Difficulty.preset(Difficulty.Level.EASY).ai_dead_zone_ratio * GameConfig.PADDLE_HEIGHT),
		float(38.0),
		float(0.01)
	)
	assert_almost_eq(
		float(Difficulty.preset(Difficulty.Level.NORMAL).ai_dead_zone_ratio * GameConfig.PADDLE_HEIGHT),
		float(24.0),
		float(0.01)
	)
	assert_almost_eq(
		float(Difficulty.preset(Difficulty.Level.HARD).ai_dead_zone_ratio * GameConfig.PADDLE_HEIGHT),
		float(12.0),
		float(0.01)
	)


func test_default_level_is_normal_and_titles_are_defined() -> void:
	assert_eq(Difficulty.DEFAULT_LEVEL, Difficulty.Level.NORMAL)
	assert_eq(Difficulty.title(Difficulty.Level.EASY), "FÁCIL")
	assert_eq(Difficulty.title(Difficulty.Level.NORMAL), "MÉDIO")
	assert_eq(Difficulty.title(Difficulty.Level.HARD), "DIFÍCIL")


func test_level_and_index_helpers_round_trip_and_clamp() -> void:
	for index in range(Difficulty.PRESETS.size()):
		var level := Difficulty.level_at(index)
		assert_eq(Difficulty.index_of(level), index)
	assert_eq(Difficulty.level_at(-5), Difficulty.Level.EASY)
	assert_eq(Difficulty.level_at(99), Difficulty.Level.HARD)
	assert_eq(Difficulty.index_of(999), Difficulty.index_of(Difficulty.DEFAULT_LEVEL))


func test_unknown_level_falls_back_to_normal() -> void:
	assert_eq(Difficulty.preset(999), Difficulty.preset(Difficulty.Level.NORMAL))
	assert_eq(Difficulty.title(999), "MÉDIO")
