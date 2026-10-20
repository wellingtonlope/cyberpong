extends GutTest

const DEBUG_HUD_SCRIPT := preload("res://scripts/debug_hud.gd")

var debug_hud

func before_each() -> void:
	debug_hud = add_child_autofree(DEBUG_HUD_SCRIPT.new())

func test_debug_hud_starts_hidden_and_toggle_changes_visibility() -> void:
	assert_false(debug_hud._panel.visible)
	debug_hud.toggle()
	assert_true(debug_hud._panel.visible)
	debug_hud.toggle()
	assert_false(debug_hud._panel.visible)

func test_debug_hud_displays_speed_and_per_ai_rebound_counts() -> void:
	debug_hud.set_ball_speed(1234.6)
	debug_hud.record_paddle_hit(true)
	debug_hud.record_paddle_hit(false)
	debug_hud.record_paddle_hit(true)

	assert_true(debug_hud._info_label.text.contains("Velocidade: 1235 px/s"))
	assert_true(debug_hud._info_label.text.contains("Rebatidas totais: 3"))
	assert_true(debug_hud._info_label.text.contains("Cyan Circuit: 2"))
	assert_true(debug_hud._info_label.text.contains("Magenta Volt: 1"))

func test_reset_clears_counts_but_preserves_current_speed() -> void:
	debug_hud.set_ball_speed(1400.0)
	debug_hud.record_paddle_hit(true)
	debug_hud.record_paddle_hit(false)
	debug_hud.reset_match_counts()

	assert_true(debug_hud._info_label.text.contains("Velocidade: 1400 px/s"))
	assert_true(debug_hud._info_label.text.contains("Rebatidas totais: 0"))
	assert_true(debug_hud._info_label.text.contains("Cyan Circuit: 0"))
	assert_true(debug_hud._info_label.text.contains("Magenta Volt: 0"))
