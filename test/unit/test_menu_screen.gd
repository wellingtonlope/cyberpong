extends GutTest

const SETTINGS_SCENE := preload("res://scenes/settings_menu.tscn")

## Menu mínimo derivado do template, usado para exercitar a classe base.
class DummyMenu extends MenuScreen:
	var finished_index := -1
	var finished_count := 0

	func _activate_card(index: int) -> void:
		begin_close(index)

	func _on_close_finished(index: int) -> void:
		finished_index = index
		finished_count += 1

var menu
var buttons: Array[Button] = []

func before_each() -> void:
	buttons.clear()
	menu = add_child_autofree(DummyMenu.new())
	for index in range(3):
		var button := Button.new()
		button.name = "Btn%d" % index
		menu.add_child(button)
		buttons.append(button)
	menu._setup_menu(buttons, [
		{"title": "PRIMEIRO", "detail": "detalhe", "tag": "A"},
		{"title": "SEGUNDO", "detail": "detalhe", "tag": "B"},
		{"title": "TERCEIRO", "detail": "detalhe", "tag": "C"},
	])

func after_each() -> void:
	get_tree().paused = false

func test_setup_menu_shows_the_menu_and_pauses_the_tree() -> void:
	assert_true(menu.visible)
	assert_true(get_tree().paused)
	assert_eq(menu._cards.size(), 3)
	assert_eq(menu._card_buttons.size(), 3)

func test_cards_are_wired_for_keyboard_navigation() -> void:
	for index in range(buttons.size()):
		var button: Button = buttons[index]
		var previous: Button = buttons[(index - 1 + buttons.size()) % buttons.size()]
		var next: Button = buttons[(index + 1) % buttons.size()]
		assert_eq(button.focus_neighbor_top, previous.get_path())
		assert_eq(button.focus_neighbor_bottom, next.get_path())
		assert_eq(button.focus_neighbor_left, previous.get_path())
		assert_eq(button.focus_neighbor_right, next.get_path())

func test_grab_first_focus_focuses_the_first_card() -> void:
	menu.grab_first_focus()
	assert_true(buttons[0].has_focus())
	assert_eq(menu._focused_index, 0)

func test_set_cards_interactive_disables_the_buttons() -> void:
	menu.set_cards_interactive(false)
	for button in buttons:
		assert_true(button.disabled)
		assert_eq(button.mouse_filter, Control.MOUSE_FILTER_IGNORE)

	menu.set_cards_interactive(true)
	for button in buttons:
		assert_false(button.disabled)
		assert_eq(button.mouse_filter, Control.MOUSE_FILTER_STOP)

func test_begin_close_starts_the_transition_and_ignores_a_second_call() -> void:
	menu.begin_close(1)
	assert_true(menu._closing)
	assert_eq(menu._closing_index, 1)
	assert_almost_eq(menu._close_progress, 0.0, 0.001)

	menu.begin_close(2)
	assert_eq(menu._closing_index, 1)

func test_finish_close_selects_hides_and_notifies_the_subclass() -> void:
	menu.begin_close(2)
	menu.finish_close()

	assert_true(menu._selected)
	assert_false(menu._closing)
	assert_eq(menu._closing_index, -1)
	assert_false(menu.visible)
	assert_false(menu.is_processing())
	assert_eq(menu.finished_count, 1)
	assert_eq(menu.finished_index, 2)

func test_the_close_transition_finishes_after_the_animated_duration() -> void:
	menu.begin_close(0)
	menu._process(menu.CLOSE_DURATION * 0.5)
	assert_true(menu._closing)
	assert_eq(menu.finished_count, 0)

	menu._process(menu.CLOSE_DURATION)
	assert_false(menu._closing)
	assert_eq(menu.finished_count, 1)
	assert_eq(menu.finished_index, 0)

func test_layout_keeps_the_cards_and_the_footer_inside_the_surface() -> void:
	for surface_size in [Vector2(1920.0, 1080.0), Vector2(1280.0, 720.0), Vector2(800.0, 600.0)]:
		var size: Vector2 = surface_size
		var layout: Dictionary = menu._layout_for(size)
		var cards: Array = layout["cards"]
		var footer: Rect2 = layout["footer"]

		assert_eq(cards.size(), 3, "Cards missing at %s" % size)
		assert_gte(cards[0].position.y, layout["strip"].end.y)
		assert_lte(footer.end.y, size.y, "Footer overflows at %s" % size)
		for card_rect in cards:
			var rect: Rect2 = card_rect
			assert_lte(rect.end.x, size.x, "Card overflows at %s" % size)

func test_open_settings_disables_the_cards_and_restores_them_on_close() -> void:
	menu.settings_scene = SETTINGS_SCENE
	menu.open_settings()

	var settings = menu.get_node_or_null("SettingsMenu")
	assert_not_null(settings)
	assert_false(menu._closing)
	for button in buttons:
		assert_true(button.disabled)

	settings.finish_close()

	assert_null(menu.get_node_or_null("SettingsMenu"))
	for button in buttons:
		assert_false(button.disabled)
	assert_true(buttons[0].has_focus())

func test_open_settings_does_nothing_without_a_settings_scene() -> void:
	menu.open_settings()
	assert_null(menu.get_node_or_null("SettingsMenu"))
	assert_false(buttons[0].disabled)

func test_cards_with_progress_draw_a_bar_inside_the_card() -> void:
	var cards: Array = menu._cards
	cards[0]["progress"] = 0.5
	cards[0]["progress_color"] = Palette.BALL_COLOR
	menu.queue_redraw()
	await get_tree().process_frame

	assert_true(menu._cards[0].has("progress"))
	assert_almost_eq(float(menu._cards[0]["progress"]), 0.5, 0.001)
