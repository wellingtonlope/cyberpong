class_name ScreenState
extends RefCounted

## Telas pelas quais a sessão passa. Substitui as flags paralelas de menu,
## pausa e fim de partida por um único estado.

enum State {
	CREDITS,
	MENU,
	PLAYING,
	PAUSED,
	GAME_OVER
}
