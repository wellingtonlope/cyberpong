class_name PauseMenu
extends MenuScreen

signal resume_requested
signal restart_requested
signal main_menu_requested

enum Action {
	RESUME,
	RESTART,
	SETTINGS,
	MAIN_MENU
}

const SETTINGS_SCENE := preload("res://scenes/settings_menu.tscn")

const PAUSE_CARDS := [
	{
		"action": Action.RESUME,
		"title": "CONTINUAR",
		"detail": "Retomar o rally exatamente de onde parou",
		"tag": "ESC"
	},
	{
		"action": Action.RESTART,
		"title": "REINICIAR PARTIDA",
		"detail": "Zera o placar e começa um novo rally",
		"tag": "NOVO"
	},
	{
		"action": Action.SETTINGS,
		"title": "CONFIGURAÇÕES",
		"detail": "Ajusta volume, som e tela cheia",
		"tag": "AJUSTE"
	},
	{
		"action": Action.MAIN_MENU,
		"title": "MENU PRINCIPAL",
		"detail": "Encerra a partida e restaura os valores padrão",
		"tag": "SAIR"
	}
]

@onready var btn_resume: Button = $BtnResume
@onready var btn_restart: Button = $BtnRestart
@onready var btn_settings: Button = $BtnSettings
@onready var btn_main_menu: Button = $BtnMainMenu

var _pending_action := -1
var _settings: SettingsMenu = null

func _ready() -> void:
	var buttons: Array[Button] = [btn_resume, btn_restart, btn_settings, btn_main_menu]
	_setup_menu(buttons, PAUSE_CARDS)

func _activate_card(index: int) -> void:
	_activate_action(PAUSE_CARDS[index]["action"], index)

func _activate_action(action: int, index: int) -> void:
	if _selected or _closing:
		return
	if action == Action.SETTINGS:
		_open_settings()
		return
	SoundManager.play_ui_select()
	_closing = true
	_close_progress = 0.0
	_closing_index = index
	_pending_action = action

func _finish_selection() -> void:
	var action := _pending_action
	_closing = false
	_closing_index = -1
	_pending_action = -1
	_select_action(action)

func _select_action(action: int) -> void:
	if _selected:
		return
	_selected = true
	_closing = false
	_close_progress = 0.0
	_closing_index = -1
	_pending_action = -1
	hide()
	set_process(false)
	match action:
		Action.MAIN_MENU:
			main_menu_requested.emit()
		Action.RESTART:
			get_tree().paused = false
			restart_requested.emit()
		_:
			get_tree().paused = false
			resume_requested.emit()

func _open_settings() -> void:
	if _settings != null:
		return
	SoundManager.play_ui_select()
	var settings := SETTINGS_SCENE.instantiate() as SettingsMenu
	settings.name = "SettingsMenu"
	add_child(settings)
	settings.closed.connect(_on_settings_closed)
	_settings = settings
	set_cards_interactive(false)

func _on_settings_closed() -> void:
	if is_instance_valid(_settings):
		var settings := _settings
		_settings = null
		remove_child(settings)
		settings.queue_free()
	else:
		_settings = null
	set_cards_interactive(true)
	grab_first_focus()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	if not event.pressed or event.echo:
		return
	if _settings != null:
		return
	if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
		_activate_action(Action.RESUME, 0)
		get_viewport().set_input_as_handled()

func _header_subtitle() -> String:
	return "JOGO PAUSADO"

func _menu_reference_height() -> float:
	return super._menu_reference_height() + (CARD_HEIGHT + CARD_GAP)

func _header_status() -> String:
	return "PAUSA"

func _header_live_label() -> String:
	return "EM ESPERA"

func _footer_hints() -> Array:
	return [["↑↓", "NAVEGAR"], ["ENTER", "CONFIRMAR"], ["ESC", "RETOMAR"]]
