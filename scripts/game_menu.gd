extends "res://scripts/menu_screen.gd"

signal mode_selected(mode: int)

enum GameMode {
	PLAYER_VS_PLAYER,
	PLAYER_VS_AI,
	AI_VS_AI
}

const MODE_CARDS := [
	{
		"mode": GameMode.PLAYER_VS_PLAYER,
		"title": "JOGADOR VS JOGADOR",
		"detail": "W/S e setas · dois jogadores locais",
		"tag": "LOCAL"
	},
	{
		"mode": GameMode.PLAYER_VS_AI,
		"title": "JOGADOR VS AI",
		"detail": "W/S ou setas · você contra a IA",
		"tag": "SOLO"
	},
	{
		"mode": GameMode.AI_VS_AI,
		"title": "AI VS AI",
		"detail": "Duelo automático entre as IAs",
		"tag": "AUTO"
	}
]

@onready var btn_pvp: Button = $BtnPvP
@onready var btn_pvai: Button = $BtnPvAI
@onready var btn_aivai: Button = $BtnAIvAI

var _pending_mode := -1

func _ready() -> void:
	var buttons: Array[Button] = [btn_pvp, btn_pvai, btn_aivai]
	_setup_menu(buttons, MODE_CARDS)

func _activate_card(index: int) -> void:
	_activate(MODE_CARDS[index]["mode"], index)

func _on_mode_pressed(index: int) -> void:
	_activate_card(index)

func _activate(mode: int, index: int) -> void:
	if _selected or _closing:
		return
	_closing = true
	_close_progress = 0.0
	_closing_index = index
	_pending_mode = mode

func _finish_selection() -> void:
	var mode := _pending_mode
	_closing = false
	_closing_index = -1
	_pending_mode = -1
	_select(mode)

func _select(mode: int) -> void:
	if _selected:
		return
	_selected = true
	_closing = false
	_close_progress = 0.0
	_closing_index = -1
	_pending_mode = -1
	hide()
	set_process(false)
	get_tree().paused = false
	mode_selected.emit(mode)

func _footer_hints() -> Array:
	return [["↑↓", "NAVEGAR"], ["ENTER", "CONFIRMAR"], ["MOUSE", "SELECIONAR"]]
