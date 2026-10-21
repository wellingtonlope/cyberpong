class_name Palette
extends RefCounted

## Paleta e identidade das equipes compartilhadas pela arena, pelos menus e
## pelos HUDs. Alterar uma cor aqui reflete em todos os pontos que a usam.

const LEFT_COLOR := Color(0.08, 0.98, 1.0)
const RIGHT_COLOR := Color(1.0, 0.12, 0.72)
const BALL_COLOR := Color(1.0, 0.92, 0.12)
const TEXT_COLOR := Color(0.9, 0.94, 1.0)
const MUTED_TEXT_COLOR := Color(0.58, 0.68, 0.8)
const DIVIDER_COLOR := Color(0.18, 0.24, 0.32)

const PANEL_COLOR := Color(0.008, 0.016, 0.028, 0.94)
const PANEL_HOVER_COLOR := Color(0.018, 0.038, 0.062, 0.96)
const PANEL_FOCUS_COLOR := Color(0.028, 0.058, 0.092, 0.97)
const OVERLAY_COLOR := Color(0.003, 0.008, 0.016, 0.9)

const GAME_TITLE := "CYBERPONG"
const LEFT_TEAM_NAME := "Cyan Circuit"
const RIGHT_TEAM_NAME := "Magenta Volt"

## Cor da equipe. `is_left` indica Cyan Circuit; caso contrário, Magenta Volt.
static func team_color(is_left: bool) -> Color:
	return LEFT_COLOR if is_left else RIGHT_COLOR

## Nome da equipe. `is_left` indica Cyan Circuit; caso contrário, Magenta Volt.
static func team_name(is_left: bool) -> String:
	return LEFT_TEAM_NAME if is_left else RIGHT_TEAM_NAME
