extends GutTest
## M20.1 touch controls (ADR 0032): the setting (Auto / On / Off), the pad and
## buttons sending input actions, Back on panels, a tap that picks a list item,
## and a fight tap that shows the plan before it acts. Headless has no touch
## screen, so Auto hides the controls here.

const AREA := "ruins_entrance"
const TEST_FILE := "user://test_touch.cfg"

var _session: Node


func before_each() -> void:
	_session = get_node_or_null("/root/Session")
	_session.set_touch_mode(TouchSettings.ON)


func after_each() -> void:
	_session.set_touch_mode(TouchSettings.AUTO)
	_session.touch_seen = false
	_session.apply_ui_scale()  # M20.3: a faked touch makes Auto see a (tiny) phone
	for action: StringName in [&"move_e", &"wait", &"journal", &"back"]:
		Input.action_release(action)


func _main(gs: GameState = null) -> Node:
	_session.set_state(gs if gs != null else GameState.new_game(1, _session.db))
	var m: Node = load("res://world/main.tscn").instantiate()
	m.switch_scene = false
	add_child_autofree(m)
	m._process(0.0)
	return m


func _button(m: Node, action: StringName) -> Button:
	return m.touch.buttons[action]


## Presses (or lets go of) a touch button and delivers its action event.
func _hold(m: Node, action: StringName, down: bool) -> void:
	var b := _button(m, action)
	if down:
		b.button_down.emit()
	else:
		b.button_up.emit()
	Input.flush_buffered_events()


func test_settings_default_save_and_load() -> void:
	DirAccess.remove_absolute(TEST_FILE)
	var s := TouchSettings.load_file(TEST_FILE)
	assert_eq(s.mode, TouchSettings.AUTO, "Auto when there is no file")
	s.set_mode(TouchSettings.OFF)
	assert_eq(s.save(TEST_FILE), OK)
	assert_eq(TouchSettings.load_file(TEST_FILE).mode, TouchSettings.OFF)
	s.set_mode("sideways")
	assert_eq(s.mode, TouchSettings.AUTO, "an unknown mode reads as Auto")
	DirAccess.remove_absolute(TEST_FILE)


func test_shows_by_mode() -> void:
	var s := TouchSettings.new()
	assert_false(s.shows(false), "Auto, no touch screen")
	assert_true(s.shows(true), "Auto, touch screen")
	s.set_mode(TouchSettings.ON)
	assert_true(s.shows(false))
	s.set_mode(TouchSettings.OFF)
	assert_false(s.shows(true))


func test_auto_shows_after_the_first_touch() -> void:
	_session.set_touch_mode(TouchSettings.AUTO)
	var m := _main()
	assert_false(m.touch.visible, "headless: no touch screen")
	var ev := InputEventScreenTouch.new()
	ev.pressed = true
	_session._input(ev)
	m._process(0.0)
	assert_true(m.touch.visible, "a touch turns Auto on")


func test_on_shows_the_pad_and_makes_room_in_the_hud() -> void:
	var m := _main()
	assert_true(m.touch.visible)
	assert_true(m.touch.pad.visible)
	assert_false(m.touch.back.visible, "no panel open: no Back")
	assert_false(m.touch.cancel.visible, "nothing to cancel")
	assert_eq(m.hud.get_node("Bottom").offset_left, Hud.LOG_LEFT + TouchControls.PAD_WIDTH)
	_session.set_touch_mode(TouchSettings.OFF)
	m._process(0.0)
	assert_false(m.touch.visible)
	assert_eq(m.hud.get_node("Bottom").offset_left, Hud.LOG_LEFT, "the log goes back")


func test_a_held_pad_button_walks_and_stops() -> void:
	var m := _main()
	var gs: GameState = _session.gs
	var start: Vector2i = gs.player.pos()
	_hold(m, &"move_e", true)
	assert_true(Input.is_action_pressed(&"move_e"))
	m._process(1.0)
	assert_eq(gs.player.pos(), start + Vector2i(1, 0), "a step east")
	_hold(m, &"move_e", false)
	assert_false(Input.is_action_pressed(&"move_e"))
	m._process(1.0)
	assert_eq(gs.player.pos(), start + Vector2i(1, 0), "let go: no more steps")


func test_a_button_opens_a_panel_and_back_closes_it() -> void:
	var m := _main()
	m._unhandled_input(_action(&"journal"))  # what the More grid's Journal sends
	m._process(0.0)
	assert_true(m.journal.visible)
	assert_false(m.touch.pad.visible, "a panel hides the pad")
	assert_true(m.touch.back.visible, "and shows Back")
	m.journal._unhandled_input(_action(&"back"))  # what Back sends
	m._process(0.0)
	assert_false(m.journal.visible)
	assert_true(m.touch.pad.visible)


func test_a_panel_lets_go_of_a_held_pad_button() -> void:
	var m := _main()
	_hold(m, &"move_e", true)
	m.journal.open(_session.gs, _session.db)
	m._process(0.0)
	Input.flush_buffered_events()
	assert_false(m.touch.is_held(&"move_e"))
	assert_false(Input.is_action_pressed(&"move_e"), "no walking on after the panel closes")


func test_buttons_send_their_actions() -> void:
	var m := _main()
	for action: StringName in [&"use", &"bag", &"back", &"eat", &"sleep", &"sheet", &"journal", &"log",
			&"help", &"block", &"throw", &"drop", &"move_n", &"move_s", &"move_w", &"wait"]:
		assert_true(m.touch.buttons.has(action), "a button for %s" % action)
		assert_eq(_button(m, action).focus_mode, Control.FOCUS_NONE, "%s takes no key focus" % action)


func test_a_tap_picks_a_list_item() -> void:
	var m := _main()
	m.journal.open(_session.gs, _session.db)
	var list: ItemList = m.journal._focus
	assert_gt(list.item_count, 0, "focus choices")
	watch_signals(list)
	list.item_clicked.emit(0, Vector2.ZERO, MOUSE_BUTTON_LEFT)
	assert_signal_emitted(list, "item_activated", "one tap picks on touch")
	_session.set_touch_mode(TouchSettings.OFF)
	watch_signals(list)
	list.item_clicked.emit(0, Vector2.ZERO, MOUSE_BUTTON_LEFT)
	assert_signal_emit_count(list, "item_activated", 1, "with a mouse it needs a double click")


func test_a_fight_tap_shows_the_plan_then_acts() -> void:
	var db: DataDb = _session.db
	var gs := GameState.new_game(4, db)
	var m := _main(gs)
	var spot := _open_spot(gs, db)
	gs.player.place(AREA, spot)
	Combat.sync(gs, db)
	Combat.add_monster(gs, db, "rock_crab", spot + Vector2i(0, 2), CombatState.HOSTILE)
	Commands.wait(gs, db, 0)
	_session.changed()
	assert_true(Encounter.is_player_turn(gs))
	var to := spot + Vector2i(-2, 0)
	m.tap(to)
	assert_false(m._walking(), "the first tap only shows the plan")
	assert_eq(m.view.overlay.path.size(), 2, "the plan's path")
	m._process(0.0)
	assert_true(m.touch.cancel.visible == false, "nothing to cancel yet")
	m.tap(to)
	assert_true(m._walking(), "the second tap walks")
	m._process(0.0)
	assert_true(m.touch.cancel.visible, "Cancel while a walk runs")
	m.cancel()
	assert_false(m._walking(), "Cancel stops the walk")


func test_options_menu_sets_the_mode() -> void:
	var o: OptionsMenu = add_child_autofree(load("res://ui/options_menu.tscn").instantiate())
	o.open()
	var touch: OptionButton = o.get_node("%Touch")
	assert_eq(touch.get_item_text(touch.selected), "On")
	touch.item_selected.emit(2)
	assert_eq(_session.touch.mode, TouchSettings.OFF)


func test_cancel_sits_above_the_column() -> void:
	var m := _main()
	m.touch.cancel.visible = true
	await get_tree().process_frame
	var c: Rect2 = m.touch.cancel.get_global_rect()
	var col: Rect2 = m.touch.column.get_global_rect()
	assert_lt(c.end.y, col.position.y, "Cancel does not push the column")
	# The fit on a 1152x648 screen was checked on a render: headless windows are tiny.


func test_bag_buttons_do_what_x_and_p_do() -> void:
	var m := _main()
	m.bag.open(_session.gs, _session.db)
	watch_signals(m.bag)
	(m.bag.get_node("%Stow") as Button).pressed.emit()
	assert_signal_emitted_with_parameters(m.bag, "chosen", [Interact.STOW])
	assert_eq((m.bag.get_node("%LeaveOne") as Button).focus_mode, Control.FOCUS_NONE)


func test_the_load_list_has_a_back_button() -> void:
	var list: SlotList = add_child_autofree(load("res://ui/slot_list.tscn").instantiate())
	list.open(SlotList.LOAD, _session.save_dir, _session.db)
	watch_signals(list)
	(list.get_node("%Back") as Button).pressed.emit()
	assert_false(list.visible)
	assert_signal_emitted(list, "cancelled")


func test_help_names_the_touch_controls() -> void:
	assert_true(SystemMessages.KEYS.any(func(l: String) -> bool: return l.begins_with("Touch screen")))


func _action(action: StringName) -> InputEventAction:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	return ev


## A 7×7 block of free floor with no exit in it; its centre (as unit_combat_screen).
func _open_spot(gs: GameState, db: DataDb) -> Vector2i:
	var size := db.maps.size(AREA)
	for y in range(3, size.y - 3):
		for x in range(3, size.x - 3):
			var ok := true
			for dy in range(-3, 4):
				for dx in range(-3, 4):
					var c := Vector2i(x + dx, y + dy)
					if not Movement.can_enter(gs, db, AREA, c) or not db.maps.exit_at(AREA, c).is_empty():
						ok = false
			if ok:
				return Vector2i(x, y)
	return Vector2i(-1, -1)
