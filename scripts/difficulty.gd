extends RefCounted

enum Level {
	EASY,
	NORMAL,
	HARD
}

const DEFAULT_LEVEL := Level.NORMAL

const PRESETS := [
	{
		"level": Level.EASY,
		"title": "FÁCIL",
		"detail": "IA mais lenta e tolerante",
		"ai_speed_factor": 0.64,
		"ai_reaction_delay": 0.30,
		"ai_dead_zone": 38.0
	},
	{
		"level": Level.NORMAL,
		"title": "MÉDIO",
		"detail": "Duelo equilibrado",
		"ai_speed_factor": 0.82,
		"ai_reaction_delay": 0.14,
		"ai_dead_zone": 24.0
	},
	{
		"level": Level.HARD,
		"title": "DIFÍCIL",
		"detail": "IA veloz e precisa",
		"ai_speed_factor": 1.0,
		"ai_reaction_delay": 0.04,
		"ai_dead_zone": 12.0
	}
]

static func preset(level: int) -> Dictionary:
	for candidate in PRESETS:
		if int(candidate["level"]) == level:
			return candidate
	return PRESETS[DEFAULT_LEVEL]

static func title(level: int) -> String:
	return String(preset(level)["title"])

static func index_of(level: int) -> int:
	for index in range(PRESETS.size()):
		if int(PRESETS[index]["level"]) == level:
			return index
	return index_of(DEFAULT_LEVEL)

static func level_at(index: int) -> int:
	var clamped_index := clampi(index, 0, PRESETS.size() - 1)
	return int(PRESETS[clamped_index]["level"])
