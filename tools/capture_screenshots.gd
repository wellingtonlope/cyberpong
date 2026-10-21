extends Node

## Ferramenta temporaria que regera as capturas de tela do README.
## Executar com: godot --path . res://tools/capture_screenshots.tscn

const OUTPUT_DIR := "res://docs/screenshots"
const TARGET_SIZE := Vector2i(1920, 1080)
const WARM_UP_SECONDS := 16.0
const HIT_TIMEOUT_FRAMES := 900

var _main: Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(TARGET_SIZE)
	await get_tree().process_frame
	print("viewport: ", get_viewport().get_visible_rect().size)
	_main = (load("res://main.tscn") as PackedScene).instantiate()
	add_child(_main)
	await get_tree().process_frame
	SoundManager.sound_enabled = false
	await _capture_menu()
	await _capture_matches()
	get_tree().quit()

func _capture_menu() -> void:
	_main._on_credits_finished()
	await _wait(1.2, true)
	await _save("menu-inicial.png")

func _capture_matches() -> void:
	var menu := _main.get_node("GameMenu") as GameMenu
	menu.selected_difficulty = Difficulty.Level.HARD
	menu.select_mode(GameMode.Mode.PLAYER_VS_AI)
	await get_tree().process_frame
	_main.left_paddle.set_control_mode(Paddle.ControlMode.AI)
	_main.right_paddle.set_control_mode(Paddle.ControlMode.AI)
	Engine.time_scale = 2.0
	await _wait(WARM_UP_SECONDS, false)
	Engine.time_scale = 1.0
	await _wait(0.6, true)
	print(
		"estado: placar ",
		_main.left_score,
		" x ",
		_main.right_score,
		" rebatidas ",
		_main.total_rebounds
	)
	await _capture_item_in_field()
	await _capture_powerful_bounce()
	await _capture_reduced_paddle()

func _capture_item_in_field() -> void:
	var power_up := _main.power_up
	power_up.appear(_main.field_size)
	power_up.effect_id = PowerUpEffect.Id.DOUBLE_SIZE
	power_up._apply_effect_visuals()
	power_up.hits_remaining = 3
	power_up.position = Vector2(_main.field_size.x * 0.33, _main.field_size.y * 0.34)
	power_up._emit_status()
	await _wait(0.2, true)
	await _save("partida.png")

func _capture_powerful_bounce() -> void:
	var power_up := _main.power_up
	power_up.clear_available_item()
	_hold_effect(PowerUpEffect.Id.POWERFUL_BOUNCE, true, 6, 3)
	await _wait_next_left_hit()
	await _wait(0.22, true)
	await _save("power-up-rebote-potente.png")

func _capture_reduced_paddle() -> void:
	_hold_effect(PowerUpEffect.Id.HALF_SIZE, false, 3, 0)
	await _wait(0.45, true)
	await _save("power-up-raquete-reduzida.png")

func _hold_effect(effect_id: int, owner_is_left: bool, hits_remaining: int, uses_remaining: int) -> void:
	var power_up := _main.power_up
	if power_up.status == PowerUp.Status.HELD:
		power_up.effect_changed.emit(power_up.owner_is_left, false, 1.0, Color.TRANSPARENT)
	var data := PowerUpEffect.data(effect_id)
	power_up.status = PowerUp.Status.HELD
	power_up.owner_is_left = owner_is_left
	power_up.effect_id = effect_id
	power_up.effect_duration_hits = int(data["duration_hits"])
	power_up.hits_remaining = hits_remaining
	power_up.effect_uses_remaining = uses_remaining
	power_up.effect_changed.emit(
		owner_is_left,
		true,
		float(data["size_multiplier"]),
		data["color"]
	)
	power_up._emit_status()

func _wait_next_left_hit() -> void:
	var before := _main.total_rebounds
	for _frame in range(HIT_TIMEOUT_FRAMES):
		await get_tree().process_frame
		if _main.total_rebounds > before and _main.ball.velocity.x > 0.0:
			return
	print("aviso: nenhuma rebatida da esquerda a tempo")

func _wait(seconds: float, ignore_time_scale: bool) -> void:
	await get_tree().create_timer(seconds, true, false, ignore_time_scale).timeout

func _save(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := OUTPUT_DIR.path_join(file_name)
	var error := image.save_png(path)
	print("salvo ", path, " erro=", error, " tamanho=", image.get_size())
