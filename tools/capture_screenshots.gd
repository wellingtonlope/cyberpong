extends Node

## Ferramenta temporaria que regera as capturas de tela do README.
## Executar com: godot --path . res://tools/capture_screenshots.tscn

const OUTPUT_DIR := "res://docs/screenshots"
const FRAMES_OUTPUT_DIR := "res://.godot/animation_frames"
const TARGET_SIZE := Vector2i(2880, 1620)
const WARM_UP_REBOUNDS := 32
const WARM_UP_MAX_FRAMES := 2700
const HIT_TIMEOUT_FRAMES := 900
const ANIMATION_FRAMES := 6
const ANIMATION_CROP := Vector2i(760, 760)
const ANIMATION_GIF_FRAMES := 20
const ANIMATION_GIF_CROP := Vector2i(640, 640)

var _main: CyberPong

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
	await _warm_up()
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
	await _capture_grow_animation()
	await _capture_shrink_animation()
	await _capture_animation_frames(
		PowerUpEffect.Id.DOUBLE_SIZE,
		true,
		GameConfig.PADDLE_GROW_ANIMATION_SECONDS,
		"aumento"
	)
	await _capture_animation_frames(
		PowerUpEffect.Id.HALF_SIZE,
		false,
		GameConfig.PADDLE_SHRINK_ANIMATION_SECONDS,
		"reducao"
	)

func _capture_grow_animation() -> void:
	await _capture_size_animation(
		PowerUpEffect.Id.DOUBLE_SIZE,
		true,
		GameConfig.PADDLE_GROW_ANIMATION_SECONDS,
		"power-up-animacao-aumento.png"
	)

func _capture_shrink_animation() -> void:
	await _capture_size_animation(
		PowerUpEffect.Id.HALF_SIZE,
		false,
		GameConfig.PADDLE_SHRINK_ANIMATION_SECONDS,
		"power-up-animacao-reducao.png"
	)

## Registra a animação de tamanho da raquete em quadros igualmente espaçados e
## salva as faixas lado a lado, para conferir o movimento do aumento e da
## redução.
func _capture_size_animation(
	effect_id: int,
	owner_is_left: bool,
	duration: float,
	file_name: String
) -> void:
	var paddle := _prepare_size_animation(effect_id, owner_is_left)
	paddle.set_process(false)
	var region := _crop_region(paddle, ANIMATION_CROP)
	var frames: Array[Image] = []
	for _index in range(ANIMATION_FRAMES):
		paddle.advance_size_animation(duration / float(ANIMATION_FRAMES))
		await RenderingServer.frame_post_draw
		frames.append(_crop_frame(_grab_frame(), region))
	paddle.advance_size_animation(duration)
	paddle.set_process(true)
	await _save_strip(frames, file_name)
	_clear_effect()

## Grava os quadros da animação em PNG, para a montagem do GIF.
func _capture_animation_frames(
	effect_id: int,
	owner_is_left: bool,
	duration: float,
	folder_name: String
) -> void:
	var paddle := _prepare_size_animation(effect_id, owner_is_left)
	paddle.set_process(false)
	var region := _crop_region(paddle, ANIMATION_GIF_CROP)
	var folder := FRAMES_OUTPUT_DIR.path_join(folder_name)
	DirAccess.make_dir_recursive_absolute(folder)
	for index in range(ANIMATION_GIF_FRAMES):
		paddle.advance_size_animation(duration / float(ANIMATION_GIF_FRAMES))
		await RenderingServer.frame_post_draw
		var frame := _crop_frame(_grab_frame(), region)
		frame.save_png(folder.path_join("frame_%02d.png" % index))
	paddle.advance_size_animation(duration)
	paddle.set_process(true)
	_clear_effect()
	print("quadros salvos em ", folder)

## Prepara a raquete que vai receber o efeito e aplica o power-up, deixando a
## animação de tamanho no início.
func _prepare_size_animation(effect_id: int, owner_is_left: bool) -> Paddle:
	_clear_effect()
	_main.left_paddle.advance_size_animation(1.0)
	_main.right_paddle.advance_size_animation(1.0)
	var paddle: Paddle = _main.left_paddle if owner_is_left else _main.right_paddle
	paddle.set_control_mode(Paddle.ControlMode.HUMAN)
	paddle.position.y = GameConfig.HUD_BAR_HEIGHT + (_main.field_size.y - GameConfig.HUD_BAR_HEIGHT) * 0.5
	_hold_effect(effect_id, owner_is_left, 20, 0)
	return paddle

func _crop_region(paddle: Paddle, size: Vector2i) -> Rect2i:
	var center := paddle.position
	return Rect2i(
		int(center.x - size.x * 0.5),
		int(center.y - size.y * 0.5),
		size.x,
		size.y
	)

## Recorta a área da raquete. A parte que fica fora da tela recebe o fundo
## escuro da arena, para as duas equipes ficarem centradas na faixa.
func _crop_frame(frame: Image, region: Rect2i) -> Image:
	var cropped := Image.create(region.size.x, region.size.y, false, Image.FORMAT_RGBA8)
	cropped.fill(Palette.PANEL_COLOR)
	var visible := region.intersection(Rect2i(Vector2i.ZERO, frame.get_size()))
	if visible.size.x > 0 and visible.size.y > 0:
		cropped.blit_rect(frame, visible, visible.position - region.position)
	return cropped

func _grab_frame() -> Image:
	return get_viewport().get_texture().get_image()

func _save_strip(frames: Array[Image], file_name: String) -> void:
	var frame_size := frames[0].get_size()
	var strip := Image.create(frame_size.x * frames.size(), frame_size.y, false, Image.FORMAT_RGBA8)
	for index in range(frames.size()):
		strip.blit_rect(
			frames[index],
			Rect2i(Vector2i.ZERO, frame_size),
			Vector2i(index * frame_size.x, 0)
		)
	var path := OUTPUT_DIR.path_join(file_name)
	var error := strip.save_png(path)
	print("salvo ", path, " erro=", error, " tamanho=", strip.get_size())

func _warm_up() -> void:
	Engine.time_scale = 2.0
	for _frame in range(WARM_UP_MAX_FRAMES):
		await get_tree().process_frame
		if _main.total_rebounds >= WARM_UP_REBOUNDS:
			break
		if _main.left_score >= 2 or _main.right_score >= 2:
			break
	Engine.time_scale = 1.0

func _capture_item_in_field() -> void:
	_clear_effect()
	var power_up: PowerUp = _main.power_up
	if not power_up.appear(_main.field_size):
		print("aviso: o item nao apareceu no campo")
	power_up.effect_id = PowerUpEffect.Id.DOUBLE_SIZE
	power_up._apply_effect_visuals()
	power_up.hits_remaining = 3
	power_up.position = _item_position()
	power_up._emit_status()
	await get_tree().process_frame
	await _save("partida.png")

func _capture_powerful_bounce() -> void:
	var power_up: PowerUp = _main.power_up
	power_up.clear_available_item()
	_hold_effect(PowerUpEffect.Id.POWERFUL_BOUNCE, true, 6, 3)
	await _wait_next_left_hit()
	await _wait(0.22, true)
	await _save("power-up-rebote-potente.png")

func _capture_reduced_paddle() -> void:
	_hold_effect(PowerUpEffect.Id.HALF_SIZE, false, 3, 0)
	await _wait(0.45, true)
	await _save("power-up-raquete-reduzida.png")

func _clear_effect() -> void:
	var power_up: PowerUp = _main.power_up
	if power_up.status == PowerUp.Status.HELD:
		power_up.effect_changed.emit(power_up.owner_is_left, false, 1.0, Color.TRANSPARENT)
	power_up.reset_for_match(_main.field_size)

func _item_position() -> Vector2:
	var field := _main.field_size
	var ball_position := _main.ball.position
	var candidates: Array[Vector2] = [
		Vector2(field.x * 0.32, field.y * 0.30),
		Vector2(field.x * 0.68, field.y * 0.30),
		Vector2(field.x * 0.32, field.y * 0.70),
		Vector2(field.x * 0.68, field.y * 0.70),
	]
	for candidate in candidates:
		if candidate.distance_to(ball_position) > 420.0:
			return candidate
	return candidates[0]

func _hold_effect(effect_id: int, owner_is_left: bool, hits_remaining: int, uses_remaining: int) -> void:
	var power_up: PowerUp = _main.power_up
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
	var before: int = _main.total_rebounds
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
