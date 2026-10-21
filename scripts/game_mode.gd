class_name GameMode
extends RefCounted

## Modos de jogo disponíveis. A enumeração é única para que o menu inicial e
## a coordenação da partida nunca fiquem com definições divergentes.

enum Mode {
	PLAYER_VS_PLAYER,
	PLAYER_VS_AI
}
