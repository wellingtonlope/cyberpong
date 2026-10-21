class_name PowerUpEffect
extends RefCounted

enum Id {
	NONE,
	DOUBLE_SIZE,
	HALF_SIZE,
	BALL_BRAKE,
	POWERFUL_BOUNCE,
	EXTRA_DEFENSE,
}

const ALL := [
	Id.DOUBLE_SIZE,
	Id.HALF_SIZE,
	Id.BALL_BRAKE,
	Id.POWERFUL_BOUNCE,
	Id.EXTRA_DEFENSE,
]

const CATALOG := {
	Id.DOUBLE_SIZE: {
		"name": "Raquete dobrada",
		"size_multiplier": 2.0,
		"color": Color(0.25, 1.0, 0.42),
		"beneficial_to_collector": true,
		"owner_hit_uses": 0,
		"duration_hits": 6,
	},
	Id.HALF_SIZE: {
		"name": "Raquete reduzida",
		"size_multiplier": 0.5,
		"color": Color(1.0, 0.3, 0.2),
		"beneficial_to_collector": false,
		"owner_hit_uses": 0,
		"duration_hits": 5,
	},
	Id.BALL_BRAKE: {
		"name": "Freio na bola",
		"size_multiplier": 1.0,
		"color": Color(0.24, 0.62, 1.0),
		"beneficial_to_collector": true,
		"owner_hit_uses": 4,
		"duration_hits": 8,
	},
	Id.POWERFUL_BOUNCE: {
		"name": "Rebote potente",
		"size_multiplier": 1.0,
		"color": Color(1.0, 0.56, 0.18),
		"beneficial_to_collector": true,
		"owner_hit_uses": 4,
		"duration_hits": 8,
	},
	Id.EXTRA_DEFENSE: {
		"name": "Defesa extra",
		"size_multiplier": 1.0,
		"color": Color(0.62, 0.42, 1.0),
		"beneficial_to_collector": true,
		"owner_hit_uses": 0,
		"duration_hits": 14,
	},
}

static func data(id: int) -> Dictionary:
	return CATALOG.get(id, {})

static func is_beneficial(id: int) -> bool:
	return bool(data(id).get("beneficial_to_collector", false))
