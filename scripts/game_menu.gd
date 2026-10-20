extends "res://scripts/menu_screen.gd"

signal mode_selected(mode: int)
signal quit_requested

enum GameMode {
	PLAYER_VS_PLAYER,
	PLAYER_VS_AI,
	AI_VS_AI
}

const EXIT_CARD := {
	"title": "SAIR",
	"detail": "Fechar o jogo",
	"tag": "FECHAR"
}

const EXIT_CARD_INDEX := 3

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
@onready var btn_quit: Button = $BtnQuit

var _pending_mode := -1
var _pending_quit := false

func _ready() -> void:
	var buttons: Array[Button] = [btn_pvp, btn_pvai, btn_aivai, btn_quit]
	var cards := MODE_CARDS.duplicate()
	cards.append(EXIT_CARD)
	_setup_menu(buttons, cards)

func _activate_card(index: int) -> void:
	if index == EXIT_CARD_INDEX:
		_request_quit(index)
		return
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

func _request_quit(index: int) -> void:
	if _selected or _closing:
		return
	_closing = true
	_close_progress = 0.0
	_closing_index = index
	_pending_quit = true

func _finish_selection() -> void:
	if _pending_quit:
		_finish_quit()
		return
	var mode := _pending_mode
	_closing = false
	_closing_index = -1
	_pending_mode = -1
	_select(mode)

func _finish_quit() -> void:
	_closing = false
	_close_progress = 0.0
	_closing_index = -1
	_pending_quit = false
	if _selected:
		return
	_selected = true
	hide()
	set_process(false)
	get_tree().paused = false
	quit_requested.emit()

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
