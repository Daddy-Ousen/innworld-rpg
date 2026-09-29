extends GutTest
## M15.2 HUD log: a short see-through strip at the bottom left that fades, a message history (L)
## and a help page (H).

var _session: Node


func before_each() -> void:
	_session = get_node_or_null("/root/Session")


func _press(node: Node, code: Key) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	ev.keycode = code
	ev.pressed = true
	node._unhandled_input(ev)


func _hud() -> Hud:
	return add_child_autofree(load("res://ui/hud.tscn").instantiate())


func _main() -> Node:
	_session.set_state(GameState.new_game(4, _session.db))
	var m: Node = load("res://world/main.tscn").instantiate()
	m.switch_scene = false
	return add_child_autofree(m)


func test_the_strip_shows_three_lines_and_the_history_keeps_all() -> void:
	var hud := _hud()
	for i in 8:
		hud.add_lines(["line %d" % i])
	assert_eq(Hud.LOG_LINES, 3)
	assert_eq((hud.get_node("%Log").text as String).split("\n"), PackedStringArray(["line 5", "line 6", "line 7"]))
	assert_eq(hud.history().size(), 8)
	assert_eq(hud.history()[0], "line 0", "oldest first")


func test_history_is_capped() -> void:
	var hud := _hud()
	for i in Hud.HISTORY_MAX + 20:
		hud.add_lines(["line %d" % i])
	assert_eq(hud.history().size(), Hud.HISTORY_MAX)
	assert_eq(hud.history()[-1], "line %d" % (Hud.HISTORY_MAX + 19))


func test_the_strip_fades_after_a_few_seconds_and_a_new_line_brings_it_back() -> void:
	var hud := _hud()
	hud.add_lines(["hello"])
	hud.tick(Hud.FADE_AFTER - 0.5)
	assert_eq(hud.log_alpha(), 1.0, "still fully shown")
	hud.tick(Hud.FADE_TIME / 2.0 + 0.5)
	assert_between(hud.log_alpha(), 0.01, 0.99, "fading")
	hud.tick(Hud.FADE_TIME)
	assert_eq(hud.log_alpha(), 0.0, "gone")
	hud.add_lines(["again"])
	assert_eq(hud.log_alpha(), 1.0)


func test_no_new_line_leaves_the_fade_alone() -> void:
	var hud := _hud()
	hud.add_lines(["hello"])
	hud.tick(Hud.FADE_AFTER + Hud.FADE_TIME)
	hud.add_lines([])
	assert_eq(hud.log_alpha(), 0.0)


func test_the_strip_sits_bottom_left_under_half_the_width_and_is_see_through() -> void:
	var bottom: Control = _hud().get_node("Bottom")
	assert_eq(bottom.anchor_left, 0.0)
	assert_eq(bottom.anchor_top, 1.0)
	assert_eq(bottom.anchor_right, 0.5)
	assert_lt(bottom.offset_right, 0.0, "a gap keeps it under half the width")
	assert_lt(bottom.self_modulate.a, 1.0, "see-through")


func test_the_hint_is_one_short_line() -> void:
	var hint: Label = _hud().get_node("Hint")
	assert_eq(hint.text, "H: help")


func test_l_opens_the_history_newest_first_and_esc_closes_it() -> void:
	if _session == null:
		return
	var main := _main()
	main.hud.add_lines(["first thing", "second thing"])
	_press(main, KEY_L)
	assert_true(main.message_log.visible)
	assert_true(main.is_busy())
	var text: String = main.message_log.get_node("%Text").text
	assert_lt(text.find("second thing"), text.find("first thing"), "newest first")
	_press(main.message_log, KEY_ESCAPE)
	assert_false(main.message_log.visible)
	_press(main, KEY_L)
	_press(main.message_log, KEY_L)
	assert_false(main.message_log.visible, "L closes it too")


func test_h_opens_the_key_list() -> void:
	if _session == null:
		return
	var main := _main()
	_press(main, KEY_H)
	assert_true(main.help.visible)
	assert_true(main.is_busy())
	var text: String = main.help.get_node("%Text").text
	for line: String in SystemMessages.KEYS:
		assert_string_contains(text, line)
	_press(main.help, KEY_H)
	assert_false(main.help.visible)


func test_every_key_the_game_uses_is_on_the_help_page() -> void:
	var keys := "\n".join(SystemMessages.KEYS)
	for k: String in ["WASD", "Space", "B:", "T:", "X:", "E:", "F:", "I:", "Z:", "C:", "J:", "L:", "H:", "Esc"]:
		assert_string_contains(keys, k)
