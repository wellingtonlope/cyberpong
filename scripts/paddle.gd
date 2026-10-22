class_name Paddle
extends Node2D

const POWER_UP_AIM_MAX_HIT_OFFSET := 0.72
const POWER_UP_AVOIDANCE_STEPS := 48
const BOUNCE_VERTICAL_FACTOR := GameConfig.BOUNCE_VERTICAL_FACTOR

## Altura mínima da raquete em relação à base, usada como piso das animações
## de tamanho.
const MIN_HEIGHT_MULTIPLIER := 0.08
## Excesso da curva de animação: a raquete passa um pouco do tamanho final e
## volta, o que dá o impulso visual do aumento e o impacto da redução.
const GROW_OVERSHOOT := 1.7
const SHRINK_OVERSHOOT := 2.6

enum ControlMode {
	AI,
	HUMAN
}

@export var is_left := true
@export var tint := Palette.LEFT_COLOR

@onready var visual_root: Node2D = $Visual
@onready var body: Polygon2D = $Visual/Body
@onready var power_up_highlight: Polygon2D = $Visual/PowerUpHighlight
@onready var glow: Polygon2D = $Visual/Glow
@onready var core: Polygon2D = $Visual/Core
@onready var outline: Line2D = $Visual/Outline

var field_size := Vector2.ZERO
var paddle_width := 0.0
var paddle_height := 0.0
var base_paddle_width := 0.0
var base_paddle_height := 0.0
var paddle_margin := 0.0
var paddle_speed := 0.0
var ball_radius := 0.0
var play_top := 0.0
var power_up_size_multiplier := 1.0
var effective_height_multiplier := 1.0
## Multiplicador de altura exibido no quadro atual. Segue o alvo durante a
## animação de tamanho e é igual a ele quando a animação termina.
var animated_height_multiplier := 1.0
var power_up_accent_color := Color.TRANSPARENT
var power_up_active := false
var ai_speed_factor := Difficulty.preset(Difficulty.DEFAULT_LEVEL).ai_speed_factor
var ai_reaction_delay := Difficulty.preset(Difficulty.DEFAULT_LEVEL).ai_reaction_delay
var ai_dead_zone_ratio := Difficulty.preset(Difficulty.DEFAULT_LEVEL).ai_dead_zone_ratio
var ai_dead_zone := 0.0
var control_up_actions: Array[String] = ["p1_up"]
var control_down_actions: Array[String] = ["p1_down"]
var _deformation_tween: Tween
var _size_animating := false
var _size_animation_elapsed := 0.0
var _size_animation_duration := 0.0
var _size_animation_from := 1.0
var _size_animation_to := 1.0
var _size_animation_direction := 1.0
var _transition_flash := 0.0

var control_mode: ControlMode = ControlMode.AI

func _ready() -> void:
	power_up_highlight.z_index = 0
	glow.z_index = 1
	body.z_index = 2
	core.z_index = 3
	outline.z_index = 4
	power_up_highlight.hide()
	_apply_visual_colors()

func configure(
	size: Vector2,
	width: float,
	height: float,
	margin: float,
	speed: float,
	radius: float,
	play_top_boundary: float = 0.0
) -> void:
	field_size = size
	base_paddle_width = width
	base_paddle_height = height
	paddle_margin = margin
	paddle_speed = speed
	ball_radius = radius
	play_top = play_top_boundary
	power_up_size_multiplier = 1.0
	power_up_active = false
	power_up_accent_color = Color.TRANSPARENT
	position = Vector2(_paddle_x(), play_top + (field_size.y - play_top) * 0.5)
	_refresh_ai_dead_zone()
	_reset_size_animation()
	_update_size_and_visuals()
	_reset_deformation()

func update_field_size(size: Vector2) -> void:
	field_size = size
	_update_size_and_visuals()
	_retarget_size_animation()
	position.y = clampf(position.y, play_top + paddle_height * 0.5, field_size.y - paddle_height * 0.5)

## Aplica um efeito à raquete. Quando o efeito muda a altura, a raquete
## cresce ou encolhe em animação até o novo tamanho, e a colisão acompanha o
## mesmo movimento.
func apply_power_up(size_multiplier: float, accent_color: Color) -> void:
	power_up_size_multiplier = size_multiplier
	power_up_accent_color = accent_color
	power_up_active = true
	_apply_visual_colors()
	_start_size_animation(_clamped_height_multiplier(size_multiplier))

## Remove o efeito da raquete. A volta ao tamanho normal também é animada.
func clear_power_up() -> void:
	power_up_size_multiplier = 1.0
	power_up_accent_color = Color.TRANSPARENT
	power_up_active = false
	_apply_visual_colors()
	_start_size_animation(_clamped_height_multiplier(1.0))

## Verdadeiro enquanto a raquete cresce ou encolhe.
func is_size_animating() -> bool:
	return _size_animating

## Direção da animação de tamanho em curso: 1.0 para crescimento, -1.0 para
## redução e 0.0 quando não há animação.
func get_size_animation_direction() -> float:
	if not _size_animating:
		return 0.0
	return _size_animation_direction

func set_control_mode(mode: ControlMode) -> void:
	control_mode = mode

func set_control_actions(up_actions: Array, down_actions: Array) -> void:
	control_up_actions.assign(up_actions)
	control_down_actions.assign(down_actions)

func apply_difficulty(preset: Difficulty.Preset) -> void:
	ai_speed_factor = maxf(preset.ai_speed_factor, 0.0)
	ai_reaction_delay = maxf(preset.ai_reaction_delay, 0.0)
	ai_dead_zone_ratio = maxf(preset.ai_dead_zone_ratio, 0.0)
	_refresh_ai_dead_zone()

## Converte a zona morta em fração da altura da raquete para uma distância
## absoluta. A fração acompanha a escala do jogo, então a precisão da IA não
## depende de `GAME_SCALE`.
func _refresh_ai_dead_zone() -> void:
	ai_dead_zone = ai_dead_zone_ratio * base_paddle_height

func update_ai(
	ball_position: Vector2,
	ball_velocity: Vector2,
	delta: float,
	power_up_available: bool = false,
	power_up_position: Vector2 = Vector2.ZERO,
	power_up_is_beneficial: bool = false
) -> void:
	if control_mode == ControlMode.HUMAN:
		var direction := _read_human_direction()
		if absf(direction) > 0.0:
			position.y += direction * paddle_speed * delta
		position.y = clampf(
			position.y,
			play_top + paddle_height * 0.5,
			field_size.y - paddle_height * 0.5
		)
		return

	var target_y := play_top + (field_size.y - play_top) * 0.5
	var ball_is_approaching := (is_left and ball_velocity.x < 0.0) or (not is_left and ball_velocity.x > 0.0)
	if ball_is_approaching:
		var intercept_y := _predict_intercept_y(ball_position, ball_velocity)
		target_y = intercept_y
		if power_up_available:
			var steering_hit_offset := 0.0
			if power_up_is_beneficial:
				steering_hit_offset = _get_power_up_aim_hit_offset(intercept_y, power_up_position)
			else:
				steering_hit_offset = _get_power_up_avoid_hit_offset(intercept_y, power_up_position)
			target_y -= steering_hit_offset * paddle_height * 0.5

	var difference := target_y - position.y
	if absf(difference) <= ai_dead_zone:
		return
	var max_step := paddle_speed * ai_speed_factor * delta
	position.y = clampf(
		position.y + clampf(difference, -max_step, max_step),
		play_top + paddle_height * 0.5,
		field_size.y - paddle_height * 0.5
	)

func _read_human_direction() -> float:
	var direction := 0.0
	for action in control_up_actions:
		if Input.is_action_pressed(action):
			direction -= 1.0
			break
	for action in control_down_actions:
		if Input.is_action_pressed(action):
			direction += 1.0
			break
	return direction

func get_collision_rect() -> Rect2:
	return Rect2(
		Vector2(position.x - paddle_width * 0.5, position.y - paddle_height * 0.5),
		Vector2(paddle_width, paddle_height)
	)

func play_impact_deformation() -> void:
	_animate_body(Vector2(0.82, 1.04))

## Previsão da altura em que a bola alcança a raquete. O atraso de reação da
## IA é sempre descontado do tempo de interceptação, de modo que a previsão
## não fica mais precisa por causa de power-ups disponíveis no campo.
func _predict_intercept_y(
	ball_position: Vector2,
	ball_velocity: Vector2
) -> float:
	var intercept_x := paddle_margin + paddle_width + ball_radius
	if not is_left:
		intercept_x = field_size.x - intercept_x
	var time_to_intercept := absf(intercept_x - ball_position.x) / maxf(absf(ball_velocity.x), 1.0)
	var prediction_time := maxf(time_to_intercept - ai_reaction_delay, 0.0)
	var predicted_y := ball_position.y + ball_velocity.y * prediction_time
	return _reflect_ball_y(predicted_y)

func _get_power_up_aim_hit_offset(intercept_y: float, power_up_position: Vector2) -> float:
	var horizontal_distance := _get_horizontal_distance_to_power_up(power_up_position)
	if horizontal_distance <= 0.0:
		return 0.0

	var min_y := play_top + ball_radius
	var vertical_range := maxf(field_size.y - ball_radius - min_y, 1.0)
	var reflection_period := vertical_range * 2.0
	var max_vertical_distance := horizontal_distance * BOUNCE_VERTICAL_FACTOR
	var image_count := int(ceil(max_vertical_distance / reflection_period)) + 2
	var best_hit_offset := 0.0
	var best_distance := INF
	for image_index in range(-image_count, image_count + 1):
		var vertical_shift := reflection_period * image_index
		var direct_image_y := power_up_position.y + vertical_shift
		var reflected_image_y := min_y * 2.0 - power_up_position.y + vertical_shift
		for image_y in [direct_image_y, reflected_image_y]:
			var hit_offset: float = (float(image_y) - intercept_y) / (horizontal_distance * BOUNCE_VERTICAL_FACTOR)
			var aim_distance := absf(hit_offset)
			if aim_distance < best_distance:
				best_distance = aim_distance
				best_hit_offset = hit_offset
	return clampf(best_hit_offset, -POWER_UP_AIM_MAX_HIT_OFFSET, POWER_UP_AIM_MAX_HIT_OFFSET)

func _get_power_up_avoid_hit_offset(intercept_y: float, power_up_position: Vector2) -> float:
	var horizontal_distance := _get_horizontal_distance_to_power_up(power_up_position)
	if horizontal_distance <= 0.0:
		return 0.0

	var best_hit_offset := 0.0
	var best_clearance := -1.0
	var sample_count := POWER_UP_AVOIDANCE_STEPS * 2
	for sample_index in range(sample_count + 1):
		var sample_ratio := float(sample_index) / float(sample_count) * 2.0 - 1.0
		var hit_offset := sample_ratio * POWER_UP_AIM_MAX_HIT_OFFSET
		var crossing_y := _reflect_ball_y(
			intercept_y + hit_offset * BOUNCE_VERTICAL_FACTOR * horizontal_distance
		)
		var clearance := absf(crossing_y - power_up_position.y)
		if clearance > best_clearance or (
			is_equal_approx(clearance, best_clearance)
			and absf(hit_offset) < absf(best_hit_offset)
		):
			best_clearance = clearance
			best_hit_offset = hit_offset
	return best_hit_offset

func _get_horizontal_distance_to_power_up(power_up_position: Vector2) -> float:
	var bounce_x := position.x
	if is_left:
		bounce_x += paddle_width * 0.5 + ball_radius
	else:
		bounce_x -= paddle_width * 0.5 + ball_radius
	return absf(power_up_position.x - bounce_x)

func _reflect_ball_y(y: float) -> float:
	var min_y := play_top + ball_radius
	var travel_range := field_size.y - play_top - ball_radius * 2.0
	var reflected_y := fposmod(y - min_y, travel_range * 2.0)
	if reflected_y > travel_range:
		reflected_y = travel_range * 2.0 - reflected_y
	return min_y + reflected_y

func _paddle_x() -> float:
	if is_left:
		return paddle_margin + base_paddle_width * 0.5
	return field_size.x - paddle_margin - base_paddle_width * 0.5

func _update_size_and_visuals() -> void:
	effective_height_multiplier = _clamped_height_multiplier(power_up_size_multiplier)
	if not _size_animating:
		animated_height_multiplier = effective_height_multiplier
	_apply_geometry()

## Desenha a raquete com a altura do quadro atual. A colisão usa a mesma
## altura, então a bola encontra a raquete exatamente onde ela está desenhada.
func _apply_geometry() -> void:
	paddle_width = base_paddle_width
	paddle_height = base_paddle_height * animated_height_multiplier
	body.polygon = _make_rectangle_polygon(paddle_width, paddle_height)
	core.polygon = _make_rectangle_polygon(
		maxf(paddle_width * 0.32, 2.0),
		paddle_height * 0.84
	)
	outline.points = _make_rectangle_polygon(paddle_width, paddle_height)
	outline.width = maxf(2.0, paddle_width * 0.055)
	var glow_padding := 5.0 * maxf(animated_height_multiplier, 1.0)
	var highlight_padding := glow_padding * 0.55
	glow.polygon = _make_rectangle_polygon(
		paddle_width + glow_padding * 2.0,
		paddle_height + glow_padding * 2.0
	)
	power_up_highlight.polygon = _make_rectangle_polygon(
		paddle_width + highlight_padding * 2.0,
		paddle_height + highlight_padding * 2.0
	)
	_apply_visual_colors()
	position.x = _paddle_x()
	position.y = clampf(
		position.y,
		play_top + paddle_height * 0.5,
		field_size.y - paddle_height * 0.5
	)

## Avança a animação de tamanho da raquete. O `_process` chama este método a
## cada quadro e os testes o chamam com um delta fixo, para não depender da
## taxa de quadros.
func advance_size_animation(delta: float) -> void:
	if not _size_animating:
		return
	_size_animation_elapsed += delta
	var duration := maxf(_size_animation_duration, 0.001)
	var progress := clampf(_size_animation_elapsed / duration, 0.0, 1.0)
	var overshoot := GROW_OVERSHOOT if _size_animation_direction > 0.0 else SHRINK_OVERSHOOT
	var eased := maxf(_ease_out_back(progress, overshoot), 0.0)
	animated_height_multiplier = clampf(
		lerpf(_size_animation_from, _size_animation_to, eased),
		MIN_HEIGHT_MULTIPLIER,
		_max_height_multiplier()
	)
	_transition_flash = sin(progress * PI)
	_apply_geometry()
	if progress >= 1.0:
		_size_animating = false
		animated_height_multiplier = _size_animation_to
		_transition_flash = 0.0
		_apply_geometry()

## Começa a animação até o tamanho alvo. Efeitos que não mudam a altura não
## iniciam animação.
func _start_size_animation(target: float) -> void:
	effective_height_multiplier = target
	if is_equal_approx(animated_height_multiplier, target):
		_size_animating = false
		_transition_flash = 0.0
		_apply_geometry()
		return
	_size_animation_from = animated_height_multiplier
	_size_animation_to = target
	_size_animation_elapsed = 0.0
	_size_animation_direction = 1.0 if target > animated_height_multiplier else -1.0
	_size_animation_duration = (
		GameConfig.PADDLE_GROW_ANIMATION_SECONDS
		if _size_animation_direction > 0.0
		else GameConfig.PADDLE_SHRINK_ANIMATION_SECONDS
	)
	_size_animating = true

## Ajusta o alvo da animação em curso quando o campo muda de tamanho.
func _retarget_size_animation() -> void:
	if not _size_animating:
		return
	_size_animation_to = effective_height_multiplier

## Volta a raquete ao tamanho base, sem animação.
func _reset_size_animation() -> void:
	_size_animating = false
	_size_animation_elapsed = 0.0
	_size_animation_duration = 0.0
	_size_animation_from = 1.0
	_size_animation_to = 1.0
	_size_animation_direction = 1.0
	animated_height_multiplier = 1.0
	_transition_flash = 0.0

## Multiplicador de altura limitado pela área de jogo, para que a raquete
## nunca ultrapasse o topo nem a base da área de jogo.
func _clamped_height_multiplier(multiplier: float) -> float:
	return clampf(multiplier, MIN_HEIGHT_MULTIPLIER, _max_height_multiplier())

func _max_height_multiplier() -> float:
	var available_height := maxf(field_size.y - play_top, 1.0)
	return maxf(available_height / maxf(base_paddle_height, 1.0), MIN_HEIGHT_MULTIPLIER)

## Curva que passa do alvo e volta, dando o impulso do aumento e o impacto
## da redução. O começo pode ficar abaixo de zero em curvas muito fortes; o
## `maxf` no avanço da animação evita que a raquete encolha antes de crescer.
static func _ease_out_back(progress: float, overshoot: float) -> float:
	var shifted := progress - 1.0
	return 1.0 + (overshoot + 1.0) * shifted * shifted * shifted + overshoot * shifted * shifted

func _process(delta: float) -> void:
	advance_size_animation(delta)

func _apply_visual_colors() -> void:
	var accent_color := power_up_accent_color if power_up_active else tint
	if power_up_active:
		body.color = tint.lerp(power_up_accent_color, 0.72)
		power_up_highlight.color = Color(power_up_accent_color, 0.42 + 0.3 * _transition_flash)
		power_up_highlight.show()
		glow.color = Color(power_up_accent_color, 0.2 + 0.25 * _transition_flash)
	else:
		body.color = tint
		power_up_highlight.hide()
		glow.color = Color(tint, 0.11)
	core.color = Color(accent_color.lightened(0.35), 0.58)
	outline.default_color = Color(accent_color, 0.95)

func _make_rectangle_polygon(width: float, height: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-width * 0.5, -height * 0.5),
		Vector2(width * 0.5, -height * 0.5),
		Vector2(width * 0.5, height * 0.5),
		Vector2(-width * 0.5, height * 0.5),
	])

func _animate_body(impact_scale: Vector2) -> void:
	if _deformation_tween != null and _deformation_tween.is_running():
		_deformation_tween.kill()
	visual_root.scale = impact_scale
	_deformation_tween = create_tween()
	_deformation_tween.tween_property(visual_root, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _reset_deformation() -> void:
	if _deformation_tween != null and _deformation_tween.is_running():
		_deformation_tween.kill()
	visual_root.scale = Vector2.ONE
