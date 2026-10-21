class_name SettingsMenu
extends MenuScreen

signal closed

enum Action {
	VOLUME_DOWN,
	VOLUME_UP,
	TOGGLE_SOUND,
	TOGGLE_FULLSCREEN,
	BACK
}

const VOLUME_STEP_DB := 3.0
const MIN_VOLUME_DB := -24.0
const MAX_VOLUME_DB := 0.0
const SETTINGS_MIN_UI_SCALE := 0.42
const LAYOUT_TOP_MARGIN_UNITS := 8.0

const SETTINGS_CARDS := [
	{
		"action": Action.VOLUME_DOWN,
		"title": "VOLUME -",
		"detail": "Diminui o volume geral em 3 dB",
		"tag": "-3 dB"
	},
	{
		"action": Action.VOLUME_UP,
		"title": "VOLUME +",
		"detail": "Aumenta o volume geral em 3 dB",
		"tag": "+3 dB"
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
		"action": Action.BACK,
		"title": "VOLTAR",
		"detail": "Retorna ao menu anterior",
		"tag": "ESC"
	}
]

const SOUND_CARD_INDEX := 2
const FULLSCREEN_CARD_INDEX := 3
const BACK_CARD_INDEX := 4

@onready var btn_volume_down: Button = $BtnVolumeDown
@onready var btn_volume_up: Button = $BtnVolumeUp
@onready var btn_sound: Button = $BtnSound
@onready var btn_fullscreen: Button = $BtnFullscreen
@onready var btn_back: Button = $BtnBack

var _fullscreen := false

func _ready() -> void:
	var buttons: Array[Button] = [
		btn_volume_down,
		btn_volume_up,
		btn_sound,
		btn_fullscreen,
		btn_back,
	]
	var cards: Array = []
	for card in SETTINGS_CARDS:
		cards.append(card.duplicate())
	_setup_menu(buttons, cards)
	_fullscreen = _is_fullscreen()
	_refresh_state()

func _activate_card(index: int) -> void:
	if _selected or _closing:
		return
	var action := int(_cards[index]["action"])
	if action == Action.BACK:
		begin_close(index)
		return
	_apply_action(action)
	SoundManager.play_ui_move()
	_refresh_state()

func _apply_action(action: int) -> void:
	match action:
		Action.VOLUME_DOWN:
			_set_volume(SoundManager.master_volume_db - VOLUME_STEP_DB)
		Action.VOLUME_UP:
			_set_volume(SoundManager.master_volume_db + VOLUME_STEP_DB)
		Action.TOGGLE_SOUND:
			SoundManager.sound_enabled = not SoundManager.sound_enabled
			if SoundManager.sound_enabled:
				SoundManager.play_ui_select()
		Action.TOGGLE_FULLSCREEN:
			_toggle_fullscreen()
		_:
			pass

func _set_volume(value: float) -> void:
	SoundManager.master_volume_db = clampf(value, MIN_VOLUME_DB, MAX_VOLUME_DB)

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
	_cards[SOUND_CARD_INDEX]["tag"] = "LIGADO" if SoundManager.sound_enabled else "DESLIGADO"
	_cards[FULLSCREEN_CARD_INDEX]["tag"] = "TELA CHEIA" if _fullscreen else "JANELA"
	queue_redraw()

func volume_percentage() -> int:
	var range_db := MAX_VOLUME_DB - MIN_VOLUME_DB
	var normalized := (SoundManager.master_volume_db - MIN_VOLUME_DB) / maxf(range_db, 0.001)
	return clampi(int(round(normalized * 100.0)), 0, 100)

func is_fullscreen() -> bool:
	return _fullscreen

func _on_close_finished(_index: int) -> void:
	closed.emit()

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
	return [["↑↓", "NAVEGAR"], ["ENTER", "AJUSTAR"], ["ESC", "VOLTAR"]]
