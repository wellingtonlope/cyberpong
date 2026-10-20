extends "res://scripts/menu_screen.gd"

signal resume_requested
signal main_menu_requested

enum Action {
	RESUME,
	MAIN_MENU
}

const PAUSE_CARDS := [
	{
		"action": Action.RESUME,
		"title": "CONTINUAR",
		"detail": "Retomar o rally exatamente de onde parou",
		"tag": "ESC"
	},
	{
		"action": Action.MAIN_MENU,
		"title": "MENU PRINCIPAL",
		"detail": "Encerrar a partida e restaurar os valores padrão",
		"tag": "SAIR"
	}
]

@onready var btn_resume: Button = $BtnResume
@onready var btn_main_menu: Button = $BtnMainMenu

var _pending_action := -1

func _ready() -> void:
	var buttons: Array[Button] = [btn_resume, btn_main_menu]
	_setup_menu(buttons, PAUSE_CARDS)

func _activate_card(index: int) -> void:
	_activate_action(PAUSE_CARDS[index]["action"], index)

func _activate_action(action: int, index: int) -> void:
	if _selected or _closing:
		return
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
	if action == Action.MAIN_MENU:
		main_menu_requested.emit()
	else:
		get_tree().paused = false
		resume_requested.emit()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	if not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
		_activate_action(Action.RESUME, 0)
		get_viewport().set_input_as_handled()

func _header_subtitle() -> String:
	return "JOGO PAUSADO"

func _header_status() -> String:
	return "PAUSA"

func _header_live_label() -> String:
	return "EM ESPERA"

func _footer_hints() -> Array:
	return [["↑↓", "NAVEGAR"], ["ENTER", "CONFIRMAR"], ["ESC", "RETOMAR"]]
