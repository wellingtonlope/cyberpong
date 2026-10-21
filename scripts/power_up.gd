class_name PowerUp
extends Node2D

signal effect_changed(is_left: bool, is_active: bool, size_multiplier: float, accent_color: Color)
signal status_changed

const AVAILABLE_HITS := 5
const POWER_UP_COLOR := Color(1.0, 0.78, 0.16)

enum Status { INACTIVE, AVAILABLE, HELD }

@export_range(1, 100, 1) var active_duration_hits := 10

@onready var glow: Polygon2D = $Glow
@onready var body: Polygon2D = $Body
@onready var core: Polygon2D = $Core
@onready var frame: Line2D = $Frame
@onready var icon = $Icon

var status := Status.INACTIVE
var owner_is_left := false
var hits_remaining := 0
var effect_duration_hits := 0
var effect_uses_remaining := 0
var effect_id: int = PowerUpEffect.Id.NONE
var collision_radius := 36.0
var field_size := Vector2.ZERO
var play_top := 0.0
var _random := RandomNumberGenerator.new()
var _pulse_time := 0.0

func _ready() -> void:
	_random.randomize()
	glow.z_index = 0
	body.z_index = 1
	core.z_index = 2
	frame.z_index = 3
	icon.z_index = 4
	z_index = 1
	_apply_default_visuals()
	hide()

func configure(scale: float, play_top_boundary: float = 0.0) -> void:
	collision_radius = 12.0 * scale
	play_top = play_top_boundary
	glow.polygon = _make_diamond(collision_radius * 1.36)
	body.polygon = _make_diamond(collision_radius * 0.88)
	core.polygon = _make_diamond(collision_radius * 0.54)
	frame.points = _make_diamond(collision_radius)
	frame.width = maxf(1.5, collision_radius * 0.07)
	icon.configure(collision_radius * 0.54)
	_apply_default_visuals()

func reset_for_match(size: Vector2) -> void:
	field_size = size
	status = Status.INACTIVE
	owner_is_left = false
	hits_remaining = 0
	effect_duration_hits = 0
	effect_uses_remaining = 0
	effect_id = PowerUpEffect.Id.NONE
	rotation = 0.0
	scale = Vector2.ONE
	_pulse_time = 0.0
	_apply_default_visuals()
	hide()
	_emit_status()

func appear(size: Vector2) -> bool:
	field_size = size
	if status != Status.INACTIVE:
		return false
	_spawn()
	return true

func clear_available_item() -> void:
	if status != Status.AVAILABLE:
		return
	status = Status.INACTIVE
	owner_is_left = false
	hits_remaining = 0
	effect_id = PowerUpEffect.Id.NONE
	rotation = 0.0
	scale = Vector2.ONE
	_pulse_time = 0.0
	_apply_default_visuals()
	hide()
	_emit_status()

func update_field_size(size: Vector2) -> void:
	field_size = size
	if status == Status.AVAILABLE:
		_keep_inside_field()

func is_available() -> bool:
	return status == Status.AVAILABLE

func is_beneficial() -> bool:
	if not is_available():
		return false
	return PowerUpEffect.is_beneficial(effect_id)

func get_active_effect_id() -> int:
	if status != Status.HELD:
		return PowerUpEffect.Id.NONE
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
	var effect: Dictionary = PowerUpEffect.data(effect_id)
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
		if used_extra_defense and effect_id == PowerUpEffect.Id.EXTRA_DEFENSE:
			_deactivate_effect()
			return
		if is_left == owner_is_left and effect_uses_remaining > 0:
			effect_uses_remaining -= 1
		if hits_remaining <= 0 or effect_uses_remaining == 0 and int(PowerUpEffect.data(effect_id)["owner_hit_uses"]) > 0:
			_deactivate_effect()
			return
	elif hits_remaining <= 0:
		status = Status.INACTIVE
		owner_is_left = false
		hits_remaining = 0
		effect_id = PowerUpEffect.Id.NONE
		_apply_default_visuals()
		hide()
	_emit_status()

func get_hud_info(hits_until_next_appearance: int) -> Dictionary:
	match status:
		Status.AVAILABLE:
			var available_effect: Dictionary = PowerUpEffect.data(effect_id)
			return {
				"title": "Item no campo",
				"detail": "%s · %d rebatidas para coletar" % [available_effect["name"], hits_remaining],
				"progress": float(hits_remaining) / AVAILABLE_HITS,
				"accent_color": available_effect["color"],
				"show_progress": true,
			}
		Status.HELD:
			var effect: Dictionary = PowerUpEffect.data(effect_id)
			var owner_name := Palette.team_name(owner_is_left)
			var detail := "%s · %d rebatidas restantes" % [owner_name, hits_remaining]
			if effect_id == PowerUpEffect.Id.EXTRA_DEFENSE:
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
				"accent_color": Palette.MUTED_TEXT_COLOR,
				"show_progress": false,
			}

func _process(delta: float) -> void:
	if status != Status.AVAILABLE:
		return
	_pulse_time += delta
	rotation += delta * 0.8
	var pulse := 1.0 + sin(_pulse_time * 4.5) * 0.045
	scale = Vector2.ONE * pulse

func _spawn() -> void:
	status = Status.AVAILABLE
	owner_is_left = false
	hits_remaining = AVAILABLE_HITS
	effect_id = PowerUpEffect.ALL[_random.randi_range(0, PowerUpEffect.ALL.size() - 1)]
	_apply_effect_visuals()
	position = Vector2(
		_random.randf_range(field_size.x * 0.28, field_size.x * 0.72),
		play_top + _random.randf_range((field_size.y - play_top) * 0.2, (field_size.y - play_top) * 0.8)
	)
	rotation = 0.0
	scale = Vector2.ONE
	_pulse_time = 0.0
	show()
	_emit_status()

func _apply_default_visuals() -> void:
	body.color = Color(0.02, 0.035, 0.06, 0.94)
	core.color = Color(POWER_UP_COLOR, 0.18)
	glow.color = Color(POWER_UP_COLOR, 0.16)
	frame.default_color = POWER_UP_COLOR
	icon.set_effect(PowerUpEffect.Id.NONE, Color(1.0, 0.96, 0.72))

func _apply_effect_visuals() -> void:
	var effect: Dictionary = PowerUpEffect.data(effect_id)
	var accent_color: Color = effect["color"]
	body.color = Color(0.02, 0.035, 0.06, 0.94)
	core.color = Color(accent_color, 0.22)
	glow.color = Color(accent_color, 0.18)
	frame.default_color = Color(accent_color, 0.95)
	icon.set_effect(effect_id, accent_color.lightened(0.35))

func _deactivate_effect() -> void:
	var ended_owner_is_left := owner_is_left
	status = Status.INACTIVE
	hits_remaining = 0
	effect_duration_hits = 0
	effect_uses_remaining = 0
	effect_id = PowerUpEffect.Id.NONE
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
