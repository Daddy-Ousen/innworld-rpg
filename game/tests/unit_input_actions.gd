extends GutTest
## M20.0 (ADR 0032): every command is an input action in project.godot, with
## today's keys. Touch buttons (M20.1) send the same actions.

## Action -> the physical keys it must keep.
const KEYS := {
	&"move_n": [KEY_W, KEY_UP], &"move_s": [KEY_S, KEY_DOWN], &"move_e": [KEY_D, KEY_RIGHT],
	&"move_w": [KEY_A, KEY_LEFT], &"wait": [KEY_SPACE], &"use": [KEY_E], &"eat": [KEY_F],
	&"bag": [KEY_I], &"sleep": [KEY_Z], &"sheet": [KEY_C], &"journal": [KEY_J], &"log": [KEY_L],
	&"help": [KEY_H], &"back": [KEY_ESCAPE], &"block": [KEY_B], &"throw": [KEY_T],
	&"drop": [KEY_X, KEY_DELETE], &"stow": [KEY_P], &"page_up": [KEY_PAGEUP],
	&"page_down": [KEY_PAGEDOWN], &"console": [KEY_QUOTELEFT], &"skill_1": [KEY_1],
	&"skill_9": [KEY_9],
}
## Scripts that must read actions, not raw keys.
const SCRIPTS: Array[String] = [
	"res://world/main.gd", "res://ui/bag.gd", "res://ui/journal.gd", "res://ui/text_page.gd",
	"res://ui/character_sheet.gd", "res://ui/slot_list.gd", "res://ui/options_menu.gd",
	"res://ui/pause_menu.gd", "res://ui/interact_menu.gd",
]


func _physical_keys(action: StringName) -> Array:
	var out := []
	for ev: InputEvent in InputMap.action_get_events(action):
		if ev is InputEventKey:
			out.append((ev as InputEventKey).physical_keycode)
	return out


func _action(action: StringName) -> InputEventAction:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	return ev


func _main() -> Node:
	var session := get_node_or_null("/root/Session")
	session.set_state(GameState.new_game(1, session.db))
	var m: Node = load("res://world/main.tscn").instantiate()
	m.switch_scene = false
	return add_child_autofree(m)


func test_every_action_keeps_its_keys() -> void:
	for action: StringName in KEYS:
		assert_true(InputMap.has_action(action), "action %s" % action)
		for key: Key in KEYS[action]:
			assert_has(_physical_keys(action), key, "%s has %s" % [action, OS.get_keycode_string(key)])


func test_actions_match_every_device() -> void:
	for action: StringName in KEYS:
		for ev: InputEvent in InputMap.action_get_events(action):
			assert_eq(ev.device, -1, "%s matches all devices" % action)


func test_scripts_read_actions_not_keys() -> void:
	for path in SCRIPTS:
		var text := FileAccess.get_file_as_string(path)
		assert_false(text.contains("KEY_"), "%s has no raw key codes" % path)
		assert_false(text.contains("physical_keycode"), "%s has no physical key checks" % path)


func test_key_names_for_ui_text() -> void:
	assert_eq(InputNames.key_of(&"log"), "L")
	assert_eq(InputNames.key_of(&"back"), "Escape")
	assert_eq(InputNames.key_of(&"no_such_action"), "")


func test_an_action_event_opens_and_closes_panels() -> void:
	var m := _main()
	m._unhandled_input(_action(&"journal"))
	assert_true(m.journal.visible, "journal action opens the journal")
	m.journal._unhandled_input(_action(&"back"))
	assert_false(m.journal.visible, "back closes it")
	m._unhandled_input(_action(&"bag"))
	assert_true(m.bag.visible, "bag action opens the bag")
	m.bag._unhandled_input(_action(&"bag"))
	assert_false(m.bag.visible, "bag again closes it")
	m._unhandled_input(_action(&"help"))
	assert_true(m.help.visible)
	assert_string_contains(m.help.get_node("%Title").text, "H or Esc")
	m.help._unhandled_input(_action(&"help"))
	assert_false(m.help.visible)


func test_a_held_move_action_walks() -> void:
	var m := _main()
	var gs: GameState = get_node("/root/Session").gs
	var start: Vector2i = gs.player.pos()
	Input.action_press(&"move_e")
	m._process(1.0)
	Input.action_release(&"move_e")
	assert_ne(gs.player.pos(), start, "a held move action steps like a held key")
