extends Node2D

const GAME_SCALE := 3.0
const PADDLE_WIDTH := 16.0 * GAME_SCALE
const PADDLE_HEIGHT := 96.0 * GAME_SCALE
const PADDLE_MARGIN := 40.0 * GAME_SCALE
const PADDLE_SPEED := 440.0 * GAME_SCALE
const BALL_RADIUS := 10.0 * GAME_SCALE
const BALL_SPEED := 380.0 * GAME_SCALE
const NEXT_RALLY_BALL_SPEED := 1500.0
const WINNING_SCORE := 3
const POWER_UP_MIN_SPAWN_INTERVAL := 5
const POWER_UP_MAX_SPAWN_INTERVAL := 15
const HUD_BAR_HEIGHT := 60.0 * GAME_SCALE
const CREDITS_SCENE := preload("res://scenes/credits_screen.tscn")
const GAME_MENU_SCENE := preload("res://scenes/game_menu.tscn")
const PAUSE_MENU_SCENE := preload("res://scenes/pause_menu.tscn")
const Difficulty = preload("res://scripts/difficulty.gd")

enum GameMode {
	PLAYER_VS_PLAYER,
	PLAYER_VS_AI
}

@onready var arena = $Arena
@onready var left_paddle = $Paddles/Left
@onready var right_paddle = $Paddles/Right
@onready var ball = $Ball
@onready var spark_effects = $SparkEffects
@onready var debug_hud = $DebugHud
@onready var power_up = $PowerUp

var field_size := Vector2.ZERO
var game_over := false
var left_score := 0
var right_score := 0
var total_rebounds := 0
var _next_power_up_rebound := 0
var _random := RandomNumberGenerator.new()
var _game_mode: int = GameMode.PLAYER_VS_AI
var _difficulty: int = Difficulty.DEFAULT_LEVEL
var _menu_shown := false
var _pause_menu: Control = null
var _credits: Control = null

func _ready() -> void:
	_random.randomize()
	field_size = get_viewport_rect().size
	arena.configure(GAME_SCALE, HUD_BAR_HEIGHT, PADDLE_MARGIN)
	spark_effects.configure(GAME_SCALE, HUD_BAR_HEIGHT, 12.0 * GAME_SCALE)
	debug_hud.configure(GAME_SCALE)
	power_up.configure(GAME_SCALE, HUD_BAR_HEIGHT)
	ball.paddle_hit.connect(_on_ball_paddle_hit)
	ball.missed.connect(_on_ball_missed)
	ball.speed_changed.connect(debug_hud.set_ball_speed)
	ball.power_up_collected.connect(power_up.collect)
	power_up.effect_changed.connect(_on_power_up_effect_changed)
	power_up.status_changed.connect(_refresh_match_hud)
	_show_credits()

func _show_credits() -> void:
	_menu_shown = true
	var credits = CREDITS_SCENE.instantiate()
	credits.name = "CreditsScreen"
	add_child(credits)
	credits.connect("finished", _on_credits_finished)
	_credits = credits
	get_tree().paused = true

func _on_credits_finished() -> void:
	_dismiss_credits()
	_show_menu()

func _dismiss_credits() -> void:
	if not is_instance_valid(_credits):
		_credits = null
		return
	var credits := _credits
	_credits = null
	remove_child(credits)
	credits.queue_free()

func _show_menu() -> void:
	var previous_menu := get_node_or_null("GameMenu")
	if previous_menu != null:
		remove_child(previous_menu)
		previous_menu.queue_free()
	var menu = GAME_MENU_SCENE.instantiate()
	menu.name = "GameMenu"
	menu.selected_difficulty = _difficulty
	add_child(menu)
	menu.connect("mode_selected", _on_mode_selected)
	menu.connect("quit_requested", _on_quit_requested)
	_menu_shown = true

func _on_quit_requested() -> void:
	get_tree().quit()

func _on_mode_selected(mode: int, difficulty: int) -> void:
	_game_mode = mode
	_difficulty = difficulty
	_menu_shown = false
	_apply_game_mode()
	_restart_match()

func _apply_game_mode() -> void:
	match _game_mode:
		GameMode.PLAYER_VS_PLAYER:
			left_paddle.set_control_mode(1)
			right_paddle.set_control_mode(1)
		GameMode.PLAYER_VS_AI:
			left_paddle.set_control_mode(1)
			right_paddle.set_control_mode(0)

func _physics_process(delta: float) -> void:
	if game_over or _menu_shown or _pause_menu != null:
		return

	var viewport_size := get_viewport_rect().size
	if viewport_size != field_size:
		field_size = viewport_size
		left_paddle.update_field_size(field_size)
		right_paddle.update_field_size(field_size)
		ball.update_field_size(field_size)
		power_up.update_field_size(field_size)
		arena.queue_redraw()

	var power_up_available: bool = power_up.is_available()
	var power_up_position: Vector2 = power_up.position if power_up_available else Vector2.ZERO
	var power_up_radius: float = power_up.get_collision_radius() if power_up_available else 0.0
	var power_up_is_beneficial: bool = power_up.is_beneficial() if power_up_available else false
	var active_effect_id: String = power_up.get_active_effect_id()
	var active_effect_owner_is_left: bool = power_up.get_active_owner_is_left()
	left_paddle.update_ai(ball.position, ball.velocity, delta, power_up_available, power_up_position, power_up_is_beneficial)
	right_paddle.update_ai(ball.position, ball.velocity, delta, power_up_available, power_up_position, power_up_is_beneficial)
	ball.advance(
		delta,
		left_paddle.get_collision_rect(),
		right_paddle.get_collision_rect(),
		power_up_position,
		power_up_radius,
		active_effect_id,
		active_effect_owner_is_left
	)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	if not event.pressed or event.echo:
		return
	if _credits != null:
		return
	if event.keycode == KEY_F3:
		debug_hud.toggle()
		get_viewport().set_input_as_handled()
		return
	if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
		if not game_over and not _menu_shown and _pause_menu == null:
			_open_pause_menu()
			get_viewport().set_input_as_handled()
		return
	if not game_over:
		return
	if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
		_restart_match()

func _open_pause_menu() -> void:
	if _pause_menu != null or _menu_shown or game_over:
		return
	var menu = PAUSE_MENU_SCENE.instantiate()
	add_child(menu)
	menu.connect("resume_requested", _on_pause_resume_requested)
	menu.connect("main_menu_requested", _on_pause_main_menu_requested)
	_pause_menu = menu
	get_tree().paused = true

func _on_pause_resume_requested() -> void:
	_dismiss_pause_menu()
	get_tree().paused = false

func _on_pause_main_menu_requested() -> void:
	_dismiss_pause_menu()
	_restart_match()
	_show_menu()

func _dismiss_pause_menu() -> void:
	if not is_instance_valid(_pause_menu):
		_pause_menu = null
		return
	var menu := _pause_menu
	_pause_menu = null
	remove_child(menu)
	menu.queue_free()

func _restart_match() -> void:
	field_size = get_viewport_rect().size
	left_paddle.configure(field_size, PADDLE_WIDTH, PADDLE_HEIGHT, PADDLE_MARGIN, PADDLE_SPEED, BALL_RADIUS, HUD_BAR_HEIGHT)
	right_paddle.configure(field_size, PADDLE_WIDTH, PADDLE_HEIGHT, PADDLE_MARGIN, PADDLE_SPEED, BALL_RADIUS, HUD_BAR_HEIGHT)
	var difficulty_config := Difficulty.preset(_difficulty)
	left_paddle.apply_difficulty(difficulty_config)
	right_paddle.apply_difficulty(difficulty_config)
	left_score = 0
	right_score = 0
	total_rebounds = 0
	_schedule_next_power_up_spawn()
	game_over = false
	power_up.reset_for_match(field_size)
	debug_hud.reset_match_counts()
	arena.set_score(left_score, right_score)
	_refresh_match_hud()
	arena.set_game_over(false)
	arena.show_rally_intro(true)
	ball.restart(
		field_size,
		BALL_RADIUS,
		BALL_SPEED,
		left_paddle.get_collision_rect(),
		right_paddle.get_collision_rect(),
		HUD_BAR_HEIGHT
	)

func _on_ball_paddle_hit(
	is_left: bool,
	impact_position: Vector2,
	horizontal_direction: float,
	speed_ratio: float,
	used_extra_defense: bool
) -> void:
	var paddle = left_paddle if is_left else right_paddle
	total_rebounds += 1
	debug_hud.record_paddle_hit(is_left)
	power_up.record_paddle_hit(is_left, used_extra_defense)
	if total_rebounds >= _next_power_up_rebound and power_up.appear(field_size):
		_schedule_next_power_up_spawn()
	_refresh_match_hud()
	paddle.play_impact_deformation()
	spark_effects.play_paddle_hit(impact_position, paddle.tint, horizontal_direction, speed_ratio)

func _refresh_match_hud() -> void:
	var hits_until_next_power_up := maxi(_next_power_up_rebound - total_rebounds, 0)
	arena.set_match_hud(total_rebounds, power_up.get_hud_info(hits_until_next_power_up))

func _schedule_next_power_up_spawn() -> void:
	var interval := _random.randi_range(POWER_UP_MIN_SPAWN_INTERVAL, POWER_UP_MAX_SPAWN_INTERVAL)
	_next_power_up_rebound = total_rebounds + interval

func _on_power_up_effect_changed(is_left: bool, is_active: bool, size_multiplier: float, accent_color: Color) -> void:
	var paddle = left_paddle if is_left else right_paddle
	if is_active:
		paddle.apply_power_up(size_multiplier, accent_color)
	else:
		paddle.clear_power_up()

func _on_ball_missed(left_side: bool) -> void:
	power_up.clear_available_item()
	var scorer_is_left := not left_side
	if scorer_is_left:
		left_score += 1
	else:
		right_score += 1
	arena.set_score(left_score, right_score)
	arena.show_point_awarded(scorer_is_left)

	var winning_score := left_score if scorer_is_left else right_score
	if winning_score >= WINNING_SCORE:
		game_over = true
		var winner_name := "Cyan Circuit" if scorer_is_left else "Magenta Volt"
		arena.set_winner(winner_name)
		return

	ball.serve_from_paddle(
		left_paddle.get_collision_rect(),
		right_paddle.get_collision_rect(),
		scorer_is_left,
		NEXT_RALLY_BALL_SPEED
	)
	arena.show_rally_intro(scorer_is_left)
