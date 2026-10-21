class_name PowerUpHudInfo
extends RefCounted

## Dados do painel de power-up exibido na barra superior. Substitui o dicionário
## de chaves soltas que era trocado entre o power-up e a arena.

var title := ""
var detail := ""
var progress := 0.0
var accent_color := Palette.MUTED_TEXT_COLOR
var show_progress := false

func _init(
	p_title: String = "",
	p_detail: String = "",
	p_progress: float = 0.0,
	p_accent_color: Color = Palette.MUTED_TEXT_COLOR,
	p_show_progress: bool = false
) -> void:
	title = p_title
	detail = p_detail
	progress = clampf(p_progress, 0.0, 1.0)
	accent_color = p_accent_color
	show_progress = p_show_progress
