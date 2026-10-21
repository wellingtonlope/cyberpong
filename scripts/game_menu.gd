extends "res://scripts/menu_screen.gd"

signal mode_selected(mode: int, difficulty: int)
signal quit_requested

const Difficulty = preload("res://scripts/difficulty.gd")

enum GameMode {
	PLAYER_VS_PLAYER,
	PLAYER_VS_AI
}

const EXIT_CARD := {
	"title": "SAIR",
	"detail": "Fechar o jogo",
	"tag": "FECHAR"
}

const EXIT_CARD_INDEX := 2

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
	}
]

@onready var btn_pvp: Button = $BtnPvP
@onready var btn_pvai: Button = $BtnPvAI
@onready var btn_quit: Button = $BtnQuit
@onready var btn_easy: Button = $BtnEasy
@onready var btn_normal: Button = $BtnNormal
@onready var btn_hard: Button = $BtnHard

var selected_difficulty: int = Difficulty.DEFAULT_LEVEL
var _pending_mode := -1
var _pending_quit := false

func _ready() -> void:
	var buttons: Array[Button] = [btn_pvp, btn_pvai, btn_quit]
	var cards := MODE_CARDS.duplicate()
	cards.append(EXIT_CARD)
	_setup_menu(buttons, cards)
	var difficulty_titles := []
	for candidate in Difficulty.PRESETS:
		difficulty_titles.append(candidate["title"])
	_setup_selector("DIFICULDADE", [btn_easy, btn_normal, btn_hard], difficulty_titles)
	_set_selector_selection(Difficulty.index_of(selected_difficulty))
	_set_selector_visible(false)

func _selector_activated(index: int) -> void:
	selected_difficulty = Difficulty.level_at(index)

func _on_card_focused(index: int) -> void:
	super._on_card_focused(index)
	_set_selector_visible(_is_player_vs_ai_card(index))

func _is_player_vs_ai_card(index: int) -> bool:
	if index < 0 or index >= MODE_CARDS.size():
		return false
	return int(MODE_CARDS[index]["mode"]) == GameMode.PLAYER_VS_AI

func _input(event: InputEvent) -> void:
	if _selected or _closing or not _selector_visible:
		return
	if not btn_pvai.has_focus():
		return
	if not event is InputEventKey:
		return
	if not event.pressed or event.echo:
		return
	if event.keycode == KEY_LEFT:
		_cycle_difficulty(-1)
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_RIGHT:
		_cycle_difficulty(1)
		get_viewport().set_input_as_handled()

func _cycle_difficulty(direction: int) -> void:
	var next_index := wrapi(
		_selector_selected_index + direction,
		0,
		Difficulty.PRESETS.size()
	)
	selected_difficulty = Difficulty.level_at(next_index)
	_set_selector_selection(next_index)

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
	SoundManager.play_ui_select()
	_closing = true
	_close_progress = 0.0
	_closing_index = index
	_pending_mode = mode

func _request_quit(index: int) -> void:
	if _selected or _closing:
		return
	SoundManager.play_ui_select()
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
	mode_selected.emit(mode, selected_difficulty)

func _footer_hints() -> Array:
	if _selector_visible:
		return [["↑↓", "NAVEGAR"], ["←→", "DIFICULDADE"], ["ENTER", "INICIAR"]]
	return [["↑↓", "NAVEGAR"], ["ENTER", "INICIAR"], ["MOUSE", "SELECIONAR"]]
