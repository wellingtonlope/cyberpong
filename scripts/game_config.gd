class_name GameConfig
extends RefCounted

## Escala global e medidas do jogo. Todos os tamanhos e velocidades saem
## daqui, em unidades de projeto multiplicadas por GAME_SCALE, para que
## nenhuma constante absoluta fique espalhada pelos scripts e a proporção
## entre as medidas continue a mesma quando a escala muda.

## Escala aplicada às unidades de projeto.
const GAME_SCALE := 3.0

# --- unidades de projeto ---

const PADDLE_WIDTH_UNITS := 16.0
const PADDLE_HEIGHT_UNITS := 96.0
const PADDLE_MARGIN_UNITS := 40.0
const PADDLE_SPEED_UNITS := 440.0
const BALL_RADIUS_UNITS := 10.0
const HUD_BAR_HEIGHT_UNITS := 60.0
const FIRST_SERVE_SPEED_UNITS := 380.0
const NEXT_SERVE_SPEED_UNITS := 500.0
const MAX_BALL_SPEED_UNITS := 1000.0

# --- valores já escalados ---

const PADDLE_WIDTH := PADDLE_WIDTH_UNITS * GAME_SCALE
const PADDLE_HEIGHT := PADDLE_HEIGHT_UNITS * GAME_SCALE
const PADDLE_MARGIN := PADDLE_MARGIN_UNITS * GAME_SCALE
const PADDLE_SPEED := PADDLE_SPEED_UNITS * GAME_SCALE
const BALL_RADIUS := BALL_RADIUS_UNITS * GAME_SCALE
const HUD_BAR_HEIGHT := HUD_BAR_HEIGHT_UNITS * GAME_SCALE
const FIRST_SERVE_SPEED := FIRST_SERVE_SPEED_UNITS * GAME_SCALE
const NEXT_SERVE_SPEED := NEXT_SERVE_SPEED_UNITS * GAME_SCALE
const MAX_BALL_SPEED := MAX_BALL_SPEED_UNITS * GAME_SCALE

## Raio visual do power-up (moldura desenhada) e raio de coleta.
## A bola coleta o item quando chega a BALL_RADIUS + POWER_UP_PICKUP_RADIUS.
const POWER_UP_RADIUS_UNITS := 18.0
const POWER_UP_PICKUP_RADIUS_UNITS := 30.0
const POWER_UP_ICON_RATIO := 0.64
const POWER_UP_RADIUS := POWER_UP_RADIUS_UNITS * GAME_SCALE
const POWER_UP_PICKUP_RADIUS := POWER_UP_PICKUP_RADIUS_UNITS * GAME_SCALE

# --- regras da partida ---

## Pontos necessários para vencer a partida.
const WINNING_SCORE := 3

## Intervalo de rebatidas totais entre o nascimento de um power-up e o
## próximo.
const POWER_UP_MIN_SPAWN_INTERVAL := 5
const POWER_UP_MAX_SPAWN_INTERVAL := 15

## Aceleração normal da bola: 10% a cada dois rebatimentos.
const BALL_SPEED_ACCELERATION := 1.1
const BALL_SPEED_ACCELERATION_INTERVAL := 2

## Conversão do deslocamento vertical do rebote na raquete em ângulo de saída
## da bola. Compartilhado pela bola e pela IA para que o modelo de trajetória
## da IA e o da bola permaneçam alinhados.
const BOUNCE_VERTICAL_FACTOR := 0.85

## Duração das animações de tamanho da raquete quando um efeito de aumento
## ou de redução entra em vigor, e quando a raquete volta ao tamanho normal.
const PADDLE_GROW_ANIMATION_SECONDS := 0.36
const PADDLE_SHRINK_ANIMATION_SECONDS := 0.26
