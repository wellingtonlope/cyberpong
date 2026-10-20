extends CanvasLayer

signal mode_selected(mode: int)

enum GameMode {
	PLAYER_VS_PLAYER,
	PLAYER_VS_AI,
	AI_VS_AI
}

@onready var panel: PanelContainer = $Panel
@onready var buttons: VBoxContainer = $Panel/MarginContainer/VBoxContainer
@onready var title: Label = $Panel/MarginContainer/VBoxContainer/Title
@onready var btn_pvp: Button = $Panel/MarginContainer/VBoxContainer/BtnPvP
@onready var btn_pvai: Button = $Panel/MarginContainer/VBoxContainer/BtnPvAI
@onready var btn_aivai: Button = $Panel/MarginContainer/VBoxContainer/BtnAIvAI

var _selected := false

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_ui()
	_show()
	
	# Conectar botões caso venham da cena
	if btn_pvp != null and not btn_pvp.pressed.is_connected(_on_pvp_pressed):
		btn_pvp.pressed.connect(_on_pvp_pressed)
	if btn_pvai != null and not btn_pvai.pressed.is_connected(_on_pvai_pressed):
		btn_pvai.pressed.connect(_on_pvai_pressed)
	if btn_aivai != null and not btn_aivai.pressed.is_connected(_on_aivai_pressed):
		btn_aivai.pressed.connect(_on_aivai_pressed)
	
	# Garantir navegação por teclado
	_configure_focus()
	call_deferred("grab_first_focus")

func _configure_focus() -> void:
	for btn in [btn_pvp, btn_pvai, btn_aivai]:
		if btn == null:
			continue
		btn.focus_mode = Control.FOCUS_ALL
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
	
	if btn_pvp != null and btn_pvai != null:
		btn_pvp.focus_neighbor_bottom = btn_pvai.get_path()
		btn_pvp.focus_next = btn_pvai.get_path()
		btn_pvai.focus_neighbor_top = btn_pvp.get_path()
		btn_pvai.focus_previous = btn_pvp.get_path()
	
	if btn_pvai != null and btn_aivai != null:
		btn_pvai.focus_neighbor_bottom = btn_aivai.get_path()
		btn_pvai.focus_next = btn_aivai.get_path()
		btn_aivai.focus_neighbor_top = btn_pvai.get_path()
		btn_aivai.focus_previous = btn_pvai.get_path()
	
	if btn_aivai != null and btn_pvp != null:
		btn_aivai.focus_neighbor_bottom = btn_pvp.get_path()
		btn_aivai.focus_next = btn_pvp.get_path()
		btn_pvp.focus_neighbor_top = btn_aivai.get_path()
		btn_pvp.focus_previous = btn_aivai.get_path()

func grab_first_focus() -> void:
	if _selected:
		return
	if btn_pvp != null and btn_pvp.is_inside_tree():
		btn_pvp.grab_focus()
		return
	if btn_pvai != null and btn_pvai.is_inside_tree():
		btn_pvai.grab_focus()
		return
	if btn_aivai != null and btn_aivai.is_inside_tree():
		btn_aivai.grab_focus()

func _on_pvp_pressed() -> void:
	_select(GameMode.PLAYER_VS_PLAYER)

func _on_pvai_pressed() -> void:
	_select(GameMode.PLAYER_VS_AI)

func _on_aivai_pressed() -> void:
	_select(GameMode.AI_VS_AI)

func _setup_ui() -> void:
	# Create UI if not present in scene
	if panel == null:
		panel = PanelContainer.new()
		add_child(panel)
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 40)
		margin.add_theme_constant_override("margin_right", 40)
		margin.add_theme_constant_override("margin_top", 30)
		margin.add_theme_constant_override("margin_bottom", 30)
		panel.add_child(margin)
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 16)
		margin.add_child(vbox)
		buttons = vbox
		
		title = Label.new()
		title.text = "CYBERPONG"
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 64)
		vbox.add_child(title)
		
		var subtitle = Label.new()
		subtitle.text = "Selecione o modo de jogo"
		subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		subtitle.add_theme_font_size_override("font_size", 28)
		vbox.add_child(subtitle)
		
		btn_pvp = Button.new()
		btn_pvp.text = "Jogador VS Jogador"
		btn_pvp.custom_minimum_size = Vector2(420, 60)
		btn_pvp.pressed.connect(_on_pvp_pressed)
		vbox.add_child(btn_pvp)
		
		btn_pvai = Button.new()
		btn_pvai.text = "Jogador VS AI"
		btn_pvai.custom_minimum_size = Vector2(420, 60)
		btn_pvai.pressed.connect(_on_pvai_pressed)
		vbox.add_child(btn_pvai)
		
		btn_aivai = Button.new()
		btn_aivai.text = "AI VS AI"
		btn_aivai.custom_minimum_size = Vector2(420, 60)
		btn_aivai.pressed.connect(_on_aivai_pressed)
		vbox.add_child(btn_aivai)
	
	# Center panel
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -250
	panel.offset_top = -200
	panel.offset_right = 250
	panel.offset_bottom = 200

func _show() -> void:
	show()
	get_tree().paused = true

func _select(mode: int) -> void:
	if _selected:
		return
	_selected = true
	hide()
	get_tree().paused = false
	mode_selected.emit(mode)
