class_name GameMenu
extends MenuScreen

signal mode_selected(mode: GameMode.Mode, difficulty: Difficulty.Level)
signal quit_requested


const EXIT_CARD := {
	"title": "SAIR",
	"detail": "Fechar o jogo",
	"tag": "FECHAR"
}

const SETTINGS_CARD := {
	"title": "CONFIGURAÇÕES",
	"detail": "Ajusta volume, som e tela cheia",
	"tag": "AJUSTE"
}

const SETTINGS_CARD_INDEX := 2
const EXIT_CARD_INDEX := 3

const SETTINGS_SCENE := preload("res://scenes/settings_menu.tscn")

const MODE_CARDS := [
	{
		"mode": GameMode.Mode.PLAYER_VS_PLAYER,
		"title": "JOGADOR VS JOGADOR",
		"detail": "W/S e setas · dois jogadores locais",
		"tag": "LOCAL"
	},
	{
		"mode": GameMode.Mode.PLAYER_VS_AI,
		"title": "JOGADOR VS AI",
		"detail": "W/S ou setas · você contra a IA",
		"tag": "SOLO"
	}
]

@onready var btn_pvp: Button = $BtnPvP
@onready var btn_pvai: Button = $BtnPvAI
@onready var btn_settings: Button = $BtnSettings
@onready var btn_quit: Button = $BtnQuit
@onready var btn_easy: Button = $BtnEasy
@onready var btn_normal: Button = $BtnNormal
@onready var btn_hard: Button = $BtnHard

var selected_difficulty: Difficulty.Level = Difficulty.DEFAULT_LEVEL
var _pending_mode: GameMode.Mode = GameMode.Mode.PLAYER_VS_AI
var _pending_quit := false

func _ready() -> void:
	var buttons: Array[Button] = [btn_pvp, btn_pvai, btn_settings, btn_quit]
	var cards := MODE_CARDS.duplicate()
	cards.append(SETTINGS_CARD)
	cards.append(EXIT_CARD)
	settings_scene = SETTINGS_SCENE
	_setup_menu(buttons, cards)
	var difficulty_titles := []
	for candidate in Difficulty.PRESETS:
		difficulty_titles.append(candidate.title)
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
	return int(MODE_CARDS[index]["mode"]) == GameMode.Mode.PLAYER_VS_AI

func _input(event: InputEvent) -> void:
	if _selected or _closing or _settings != null:
		return
	if not _selector_visible:
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
	if index == SETTINGS_CARD_INDEX:
		open_settings()
		return
	if index == EXIT_CARD_INDEX:
		_pending_quit = true
		begin_close(index)
		return
	_activate(int(MODE_CARDS[index]["mode"]), index)

func _menu_reference_height() -> float:
	return super._menu_reference_height() + (CARD_HEIGHT + CARD_GAP)

func _activate(mode: GameMode.Mode, index: int) -> void:
	if _selected or _closing:
		return
	_pending_mode = mode
	begin_close(index)

func _on_close_finished(_index: int) -> void:
	get_tree().paused = false
	if _pending_quit:
		_pending_quit = false
		quit_requested.emit()
		return
	mode_selected.emit(_pending_mode, selected_difficulty)

## Seleciona o modo imediatamente, sem a transição de fechamento.
func select_mode(mode: GameMode.Mode) -> void:
	if _selected:
		return
	_selected = true
	_closing = false
	_close_progress = 0.0
	_closing_index = -1
	hide()
	set_process(false)
	get_tree().paused = false
	mode_selected.emit(mode, selected_difficulty)

func _restore_focus_after_settings() -> void:
	var index := clampi(_settings_return_index, 0, _card_buttons.size() - 1)
	_focused_index = index
	_card_buttons[index].grab_focus()
	_set_selector_visible(_is_player_vs_ai_card(index))

func _footer_hints() -> Array:
	if _selector_visible:
		return [["↑↓", "NAVEGAR"], ["←→", "DIFICULDADE"], ["ENTER", "INICIAR"]]
	return [["↑↓", "NAVEGAR"], ["ENTER", "INICIAR"], ["MOUSE", "SELECIONAR"]]
