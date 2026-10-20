extends Node2D

signal effect_changed(is_left: bool, is_active: bool, size_multiplier: float, accent_color: Color)
signal status_changed

const AVAILABLE_HITS := 5
const POWER_UP_COLOR := Color(1.0, 0.78, 0.16)

const EFFECTS := {
	"double_size": {
		"name": "Raquete dobrada",
		"symbol": "+",
		"size_multiplier": 2.0,
		"color": Color(0.25, 1.0, 0.42),
		"beneficial_to_collector": true,
		"owner_hit_uses": 0,
	},
	"half_size": {
		"name": "Raquete reduzida",
		"symbol": "−",
		"size_multiplier": 0.5,
		"color": Color(1.0, 0.3, 0.2),
		"beneficial_to_collector": false,
		"owner_hit_uses": 0,
	},
	"ball_brake": {
		"name": "Freio na bola",
		"symbol": "↓",
		"size_multiplier": 1.0,
		"color": Color(0.24, 0.62, 1.0),
		"beneficial_to_collector": true,
		"owner_hit_uses": 5,
	},
	"powerful_bounce": {
		"name": "Rebote potente",
		"symbol": "↑",
		"size_multiplier": 1.0,
		"color": Color(1.0, 0.56, 0.18),
		"beneficial_to_collector": true,
		"owner_hit_uses": 5,
	},
	"extra_defense": {
		"name": "Defesa extra",
		"symbol": "1",
		"size_multiplier": 1.0,
		"color": Color(0.62, 0.42, 1.0),
		"beneficial_to_collector": true,
		"owner_hit_uses": 0,
		"duration_hits": 20,
	},
}
const EFFECT_IDS := ["double_size", "half_size", "ball_brake", "powerful_bounce", "extra_defense"]

enum Status { INACTIVE, AVAILABLE, HELD }

@export_range(1, 100, 1) var active_duration_hits := 10

@onready var body: Polygon2D = $Body
@onready var core: Polygon2D = $Core
@onready var symbol: Label = $Symbol

var status := Status.INACTIVE
var owner_is_left := false
var hits_remaining := 0
var effect_duration_hits := 0
var effect_uses_remaining := 0
var effect_id := ""
var collision_radius := 36.0
var field_size := Vector2.ZERO
var play_top := 0.0
var _random := RandomNumberGenerator.new()

func _ready() -> void:
	_random.randomize()
	body.color = POWER_UP_COLOR
	core.color = Color(1.0, 0.96, 0.72)
	symbol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	symbol.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	symbol.add_theme_color_override("font_color", Color(0.035, 0.055, 0.09))
	z_index = 1
	hide()

func configure(scale: float, play_top_boundary: float = 0.0) -> void:
	collision_radius = 12.0 * scale
	play_top = play_top_boundary
	body.polygon = _make_diamond(collision_radius)
	core.polygon = _make_diamond(collision_radius * 0.42)
	symbol.position = Vector2(-collision_radius, -collision_radius)
	symbol.size = Vector2.ONE * collision_radius * 2.0
	symbol.add_theme_font_size_override("font_size", int(collision_radius * 0.9))

func reset_for_match(size: Vector2) -> void:
	field_size = size
	status = Status.INACTIVE
	owner_is_left = false
	hits_remaining = 0
	effect_duration_hits = 0
	effect_uses_remaining = 0
	effect_id = ""
	hide()
	_emit_status()

func appear(size: Vector2) -> bool:
	field_size = size
	if status != Status.INACTIVE:
		return false
	_spawn()
	return true

func update_field_size(size: Vector2) -> void:
	field_size = size
	if status == Status.AVAILABLE:
		_keep_inside_field()

func is_available() -> bool:
	return status == Status.AVAILABLE

func is_beneficial() -> bool:
	if not is_available():
		return false
	var effect: Dictionary = EFFECTS[effect_id]
	return bool(effect["beneficial_to_collector"])

func get_active_effect_id() -> String:
	if status != Status.HELD:
		return ""
	return effect_id

func get_active_owner_is_left() -> bool:
	return status == Status.HELD and owner_is_left

func get_collision_radius() -> float:
	return collision_radius

func collect(is_left: bool) -> void:
	if status != Status.AVAILABLE:
		return
	status = Status.HELD
	owner_is_left = is_left
	hide()
	var effect: Dictionary = EFFECTS[effect_id]
	effect_duration_hits = int(effect.get("duration_hits", active_duration_hits))
	hits_remaining = effect_duration_hits
	effect_uses_remaining = int(effect["owner_hit_uses"])
	effect_changed.emit(owner_is_left, true, effect["size_multiplier"], effect["color"])
	_emit_status()

func record_paddle_hit(is_left: bool, used_extra_defense: bool = false) -> void:
	if status == Status.INACTIVE:
		return

	var previous_status := status
	hits_remaining -= 1
	if previous_status == Status.HELD:
		if used_extra_defense and effect_id == "extra_defense":
			_deactivate_effect()
			return
		if is_left == owner_is_left and effect_uses_remaining > 0:
			effect_uses_remaining -= 1
		if hits_remaining <= 0 or effect_uses_remaining == 0 and int(EFFECTS[effect_id]["owner_hit_uses"]) > 0:
			_deactivate_effect()
			return
	elif hits_remaining <= 0:
		status = Status.INACTIVE
		hits_remaining = 0
		hide()
	_emit_status()

func get_hud_info(hits_until_next_appearance: int) -> Dictionary:
	match status:
		Status.AVAILABLE:
			var available_effect: Dictionary = EFFECTS[effect_id]
			return {
				"title": "Item no campo",
				"detail": "%s · %d rebatidas para coletar" % [available_effect["name"], hits_remaining],
				"progress": float(hits_remaining) / AVAILABLE_HITS,
				"accent_color": available_effect["color"],
				"show_progress": true,
			}
		Status.HELD:
			var effect: Dictionary = EFFECTS[effect_id]
			var owner_name := "IA ciano" if owner_is_left else "IA magenta"
			var detail := "%s · %d rebatidas restantes" % [owner_name, hits_remaining]
			if effect_id == "extra_defense":
				detail = "%s · 1 defesa · %d rebatidas restantes" % [owner_name, hits_remaining]
			elif effect_uses_remaining > 0:
				detail = "%s · %d usos · %d rebatidas restantes" % [owner_name, effect_uses_remaining, hits_remaining]
			return {
				"title": effect["name"],
				"detail": detail,
				"progress": float(hits_remaining) / maxf(effect_duration_hits, 1),
				"accent_color": effect["color"],
				"show_progress": true,
			}
		_:
			return {
				"title": "Próximo power-up",
				"detail": "em %d rebatidas" % hits_until_next_appearance,
				"progress": 0.0,
				"accent_color": Color(0.58, 0.68, 0.8),
				"show_progress": false,
			}

func _process(delta: float) -> void:
	if status == Status.AVAILABLE:
		rotation += delta * 0.8

func _spawn() -> void:
	status = Status.AVAILABLE
	owner_is_left = false
	hits_remaining = AVAILABLE_HITS
	effect_id = EFFECT_IDS[_random.randi_range(0, EFFECT_IDS.size() - 1)]
	var effect: Dictionary = EFFECTS[effect_id]
	body.color = effect["color"]
	core.color = Color(1.0, 0.96, 0.72)
	symbol.text = effect["symbol"]
	position = Vector2(
		_random.randf_range(field_size.x * 0.28, field_size.x * 0.72),
		play_top + _random.randf_range((field_size.y - play_top) * 0.2, (field_size.y - play_top) * 0.8)
	)
	rotation = 0.0
	show()
	_emit_status()

func _deactivate_effect() -> void:
	var ended_owner_is_left := owner_is_left
	status = Status.INACTIVE
	hits_remaining = 0
	effect_duration_hits = 0
	effect_uses_remaining = 0
	effect_id = ""
	hide()
	effect_changed.emit(ended_owner_is_left, false, 1.0, Color.TRANSPARENT)
	_emit_status()

func _keep_inside_field() -> void:
	position.x = clampf(position.x, collision_radius, field_size.x - collision_radius)
	position.y = clampf(position.y, play_top + collision_radius, field_size.y - collision_radius)

func _make_diamond(radius: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0.0, -radius),
		Vector2(radius, 0.0),
		Vector2(0.0, radius),
		Vector2(-radius, 0.0),
	])

func _emit_status() -> void:
	status_changed.emit()
