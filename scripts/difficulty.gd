class_name Difficulty
extends RefCounted

## Presets de dificuldade aplicados às raquetes controladas pela IA.

enum Level {
	EASY,
	NORMAL,
	HARD
}

const DEFAULT_LEVEL := Level.NORMAL

## Um preset de dificuldade com os parâmetros usados pelo comportamento da IA.
class Preset extends RefCounted:
	var level: int = Level.NORMAL
	var title := ""
	var detail := ""
	var ai_speed_factor := 0.0
	var ai_reaction_delay := 0.0
	var ai_dead_zone := 0.0

	func _init(
		p_level: int,
		p_title: String,
		p_detail: String,
		p_speed_factor: float,
		p_reaction_delay: float,
		p_dead_zone: float
	) -> void:
		level = p_level
		title = p_title
		detail = p_detail
		ai_speed_factor = p_speed_factor
		ai_reaction_delay = p_reaction_delay
		ai_dead_zone = p_dead_zone

static var PRESETS: Array[Preset] = [
	Preset.new(Level.EASY, "FÁCIL", "IA mais lenta e tolerante", 0.64, 0.30, 38.0),
	Preset.new(Level.NORMAL, "MÉDIO", "Duelo equilibrado", 0.82, 0.14, 24.0),
	Preset.new(Level.HARD, "DIFÍCIL", "IA veloz e precisa", 1.0, 0.04, 12.0),
]

static func preset(level: int) -> Preset:
	for candidate in PRESETS:
		if candidate.level == level:
			return candidate
	return PRESETS[DEFAULT_LEVEL]

static func title(level: int) -> String:
	return preset(level).title

static func index_of(level: int) -> int:
	for index in range(PRESETS.size()):
		if PRESETS[index].level == level:
			return index
	return index_of(DEFAULT_LEVEL)

static func level_at(index: int) -> int:
	var clamped_index := clampi(index, 0, PRESETS.size() - 1)
	return PRESETS[clamped_index].level
