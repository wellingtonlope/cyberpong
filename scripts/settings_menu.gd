class_name SettingsMenu
extends MenuScreen

signal closed

enum Action {
	VOLUME,
	TOGGLE_SOUND,
	TOGGLE_FULLSCREEN,
	CYCLE_RESOLUTION,
	BACK
}

const VOLUME_STEP_PERCENT := 5
const SETTINGS_MIN_UI_SCALE := 0.42
const LAYOUT_TOP_MARGIN_UNITS := 8.0
const RESOLUTION_PRESETS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(2880, 1620),
]

const SETTINGS_CARDS := [
	{
		"action": Action.VOLUME,
		"title": "VOLUME",
		"detail": "← e → ajustam o volume geral",
		"tag": "100%",
		"progress": 1.0,
		"progress_color": Palette.BALL_COLOR,
	},
	{
		"action": Action.TOGGLE_SOUND,
		"title": "SOM",
		"detail": "Ativa ou desativa os efeitos sonoros",
		"tag": "LIGADO"
	},
	{
		"action": Action.TOGGLE_FULLSCREEN,
		"title": "TELA CHEIA",
		"detail": "Alterna entre janela e tela cheia",
		"tag": "TELA CHEIA"
	},
	{
		"action": Action.CYCLE_RESOLUTION,
		"title": "RESOLUÇÃO",
		"detail": "Muda a resolução da janela",
		"tag": "1920×1080"
	},
	{
		"action": Action.BACK,
		"title": "VOLTAR",
		"detail": "Retorna ao menu anterior",
		"tag": "ESC"
	}
]

const VOLUME_CARD_INDEX := 0
const SOUND_CARD_INDEX := 1
const FULLSCREEN_CARD_INDEX := 2
const RESOLUTION_CARD_INDEX := 3
const BACK_CARD_INDEX := 4

@onready var btn_volume: Button = $BtnVolume
@onready var btn_sound: Button = $BtnSound
@onready var btn_fullscreen: Button = $BtnFullscreen
@onready var btn_resolution: Button = $BtnResolution
@onready var btn_back: Button = $BtnBack

var _fullscreen := false
var _resolution_index := 0

func _ready() -> void:
	var buttons: Array[Button] = [
		btn_volume,
		btn_sound,
		btn_fullscreen,
		btn_resolution,
		btn_back,
	]
	var cards: Array = []
	for card in SETTINGS_CARDS:
		cards.append(card.duplicate())
	_setup_menu(buttons, cards)
	_fullscreen = _is_fullscreen()
	_resolution_index = _closest_resolution_index(_current_window_size())
	_refresh_state()

func _activate_card(index: int) -> void:
	if _selected or _closing:
		return
	var action := int(_cards[index]["action"])
	match action:
		Action.VOLUME:
			SoundManager.play_ui_move()
		Action.CYCLE_RESOLUTION:
			_cycle_resolution()
		Action.BACK:
			begin_close(index)
			return
		_:
			_apply_action(action)
			SoundManager.play_ui_move()
	_refresh_state()

func _apply_action(action: int) -> void:
	match action:
		Action.TOGGLE_SOUND:
			SoundManager.sound_enabled = not SoundManager.sound_enabled
			if SoundManager.sound_enabled:
				SoundManager.play_ui_select()
		Action.TOGGLE_FULLSCREEN:
			_toggle_fullscreen()
		_:
			pass

## Ajusta o volume geral em passos de porcentagem, de 0 a 100.
func adjust_volume(delta_percent: int) -> void:
	SoundManager.master_volume_percent = (
		SoundManager.master_volume_percent + delta_percent
	)
	SoundManager.play_ui_move()
	_refresh_state()

## Volume geral de 0 a 100.
func volume_percentage() -> int:
	return SoundManager.master_volume_percent

## Alterna para a próxima resolução disponível e a aplica na janela.
func _cycle_resolution() -> void:
	_resolution_index = (_resolution_index + 1) % RESOLUTION_PRESETS.size()
	_apply_resolution()
	SoundManager.play_ui_move()

## Resolução selecionada no momento.
func current_resolution() -> Vector2i:
	return RESOLUTION_PRESETS[_resolution_index]

func _apply_resolution() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MAXIMIZED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(current_resolution())

func _closest_resolution_index(size: Vector2i) -> int:
	var best_index := 0
	var best_distance := INF
	for index in range(RESOLUTION_PRESETS.size()):
		var candidate := RESOLUTION_PRESETS[index]
		var distance := absf(float(candidate.x - size.x)) + absf(float(candidate.y - size.y))
		if distance < best_distance:
			best_distance = distance
			best_index = index
	return best_index

func _current_window_size() -> Vector2i:
	if DisplayServer.get_name() == "headless":
		return Vector2i(RESOLUTION_PRESETS[0].x, RESOLUTION_PRESETS[0].y)
	return DisplayServer.window_get_size()

func _toggle_fullscreen() -> void:
	_fullscreen = not _fullscreen
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if _fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	)

func _is_fullscreen() -> bool:
	if DisplayServer.get_name() == "headless":
		return false
	return DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

func _refresh_state() -> void:
	if _cards.size() < SETTINGS_CARDS.size():
		return
	_cards[VOLUME_CARD_INDEX]["tag"] = "%d%%" % volume_percentage()
	_cards[VOLUME_CARD_INDEX]["progress"] = float(volume_percentage()) / 100.0
	_cards[SOUND_CARD_INDEX]["tag"] = "LIGADO" if SoundManager.sound_enabled else "DESLIGADO"
	_cards[FULLSCREEN_CARD_INDEX]["tag"] = "TELA CHEIA" if _fullscreen else "JANELA"
	_cards[RESOLUTION_CARD_INDEX]["tag"] = "%d×%d" % [
		current_resolution().x,
		current_resolution().y,
	]
	queue_redraw()

func is_fullscreen() -> bool:
	return _fullscreen

func _on_close_finished(_index: int) -> void:
	closed.emit()

func _input(event: InputEvent) -> void:
	if _selected or _closing:
		return
	if _focused_index != VOLUME_CARD_INDEX:
		return
	if not event is InputEventKey:
		return
	if not event.pressed or event.echo:
		return
	if event.keycode == KEY_LEFT:
		adjust_volume(-VOLUME_STEP_PERCENT)
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_RIGHT:
		adjust_volume(VOLUME_STEP_PERCENT)
		get_viewport().set_input_as_handled()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	if not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		begin_close(BACK_CARD_INDEX)
		get_viewport().set_input_as_handled()

func _ui_scale_for(surface_size: Vector2) -> float:
	var base_scale := super._ui_scale_for(surface_size)
	var card_count := float(_cards.size())
	var content_units := (
		HEADER_HEIGHT
		+ HEADER_GAP
		+ STRIP_HEIGHT
		+ BODY_GAP
		+ BODY_GAP
		+ FOOTER_HEIGHT
		+ CARD_HEIGHT * card_count
		+ CARD_GAP * maxf(card_count - 1.0, 0.0)
	)
	var height_scale := (
		surface_size.y * 0.99
	) / maxf(content_units + LAYOUT_TOP_MARGIN_UNITS, 1.0)
	return clampf(
		minf(base_scale, height_scale),
		SETTINGS_MIN_UI_SCALE,
		MAX_UI_SCALE
	)

func _header_subtitle() -> String:
	return "CONFIGURAÇÕES"

func _header_status() -> String:
	return "SOM LIGADO" if SoundManager.sound_enabled else "SOM DESLIGADO"

func _header_live_label() -> String:
	return "VOLUME %d%%" % volume_percentage()

func _footer_hints() -> Array:
	return [["↑↓", "NAVEGAR"], ["←→", "VOLUME"], ["ENTER", "AJUSTAR"]]
