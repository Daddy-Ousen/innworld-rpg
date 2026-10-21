extends GutTest
## M34.3 (ADR 0045): tap the world. Outside a fight a touch tap on a thing or a
## person walks next to it and opens its card; a tap on the floor walks there.
## Every step is a normal move, so the game is the same as with keys.

const SEED := 20260929
const AREA := "celum_square"

var _session: Node


func before_each() -> void:
	_session = get_node_or_null("/root/Session")
	_session.set_touch_mode(TouchSettings.ON)
	_session.touch.set_controls(TouchSettings.TAP)


func after_each() -> void:
	_session.set_touch_mode(TouchSettings.AUTO)
	_session.touch.set_controls(TouchSettings.TAP)
	_session.touch_seen = false
	_session.apply_ui_scale()


func _game() -> GameState:
	var gs := GameState.new_game(SEED, _session.db, "celum")
	gs.npcs.npcs.clear()
	return gs


func _main(gs: GameState) -> Node:
	_session.set_state(gs)
	var m: Node = load("res://world/main.tscn").instantiate()
	m.switch_scene = false
	add_child_autofree(m)
	m._process(0.0)
	return m


func _stall() -> Vector2i:
	var at := Interact.object_of(_session.db, AREA, "celum_stall")
	return Vector2i(int(at["at"][0]), int(at["at"][1]))


## A walkable square `far` steps (king distance) or more from the stall, with a path to it.
func _start_away(gs: GameState, far: int) -> Vector2i:
	var db: DataDb = _session.db
	var stall := _stall()
	for y in range(-8, 9):
		for x in range(-8, 9):
			var p := stall + Vector2i(x, y)
			if maxi(absi(x), absi(y)) >= far and db.maps.is_walkable(AREA, p) \
					and db.maps.exit_at(AREA, p).is_empty() and db.maps.objects_near(AREA, p).is_empty() \
					and Pathfind.path(db.maps, AREA, p, Pathfind.around(stall))["found"]:
				return p
	return MainAim.NO_CELL


## Runs the walk to its end (as MainScreen._process does each STEP_REPEAT).
func _finish(m: Node) -> int:
	var steps := 0
	while m.tapper.walking() and steps < MainTap.MAX_STEPS + 2:
		m.tapper.next()
		steps += 1
	return steps


func test_what_stands_on_a_cell() -> void:
	var gs := _game()
	gs.player.place(AREA, _start_away(gs, 4))
	assert_eq(MainTap.target_at(gs, _session.db, _stall()), "celum_stall")
	assert_eq(MainTap.target_at(gs, _session.db, gs.player.pos()), "", "the floor")


func test_a_tap_on_a_far_stall_walks_there_and_opens_its_card() -> void:
	var gs := _game()
	var start := _start_away(gs, 4)
	assert_ne(start, MainAim.NO_CELL, "a start spot")
	gs.player.place(AREA, start)
	var m := _main(gs)
	m.tap_world(_stall())
	assert_true(m.tapper.walking(), "the walk starts")
	assert_ne(gs.player.pos(), start, "the first step is made at once")
	_finish(m)
	assert_false(m.tapper.walking())
	var menu: InteractMenu = m.menu
	assert_true(menu.visible, "the card opens at the end")
	assert_eq(menu.page, InteractMenu.ACTIONS)
	assert_eq(menu.rows()[0]["action"], InteractMenu.SHOP)
	assert_lte(MapDb._dist(gs.player.pos(), _stall()), 1, "next to the stall")


func test_a_tap_next_to_it_opens_the_card_at_once() -> void:
	var gs := _game()
	var stall := _stall()
	for d: Vector2i in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
		if _session.db.maps.is_walkable(AREA, stall + d):
			gs.player.place(AREA, stall + d)
			break
	var m := _main(gs)
	var before: int = gs.clock.total_minutes
	m.tap_world(stall)
	assert_false(m.tapper.walking())
	assert_true(m.menu.visible)
	assert_eq(gs.clock.total_minutes, before, "no step, no time")


func test_a_tap_on_the_floor_walks_there() -> void:
	var gs := _game()
	var start := _start_away(gs, 4)
	gs.player.place(AREA, start)
	var m := _main(gs)
	var to := MainAim.NO_CELL
	for d: Vector2i in [Vector2i(3, 0), Vector2i(-3, 0), Vector2i(0, 3), Vector2i(0, -3)]:
		var p := start + d
		if MainTap.target_at(gs, _session.db, p) == "" and _session.db.maps.is_walkable(AREA, p) \
				and _session.db.maps.exit_at(AREA, p).is_empty() \
				and Pathfind.path(_session.db.maps, AREA, start, {p: true})["found"]:
			to = p
			break
	assert_ne(to, MainAim.NO_CELL, "a floor spot")
	m.tap_world(to)
	_finish(m)
	assert_eq(gs.player.pos(), to)
	assert_false(m.menu.visible, "the floor has no card")


func test_a_tap_walk_is_the_same_as_walking_with_keys() -> void:
	var a := _game()
	var start := _start_away(a, 4)
	a.player.place(AREA, start)
	var m := _main(a)
	var cells: Array[Vector2i] = []
	m.tap_world(_stall())
	cells.append(a.player.pos())
	while m.tapper.walking():
		m.tapper.next()
		cells.append(a.player.pos())
	var b := _game()
	b.player.place(AREA, start)
	var at := start
	for c: Vector2i in cells:
		if c == at:
			continue
		var dir := ""
		for k: String in PlayerState.DIRS:
			if at + (PlayerState.DIRS[k] as Vector2i) == c:
				dir = k
		assert_ne(dir, "", "one step at a time")
		Commands.move(b, _session.db, dir)
		at = c
	assert_eq(b.clock.total_minutes, a.clock.total_minutes, "the same time passed")
	assert_eq(b.rng.to_dict(), a.rng.to_dict(), "the same dice")
	assert_eq(b.player.pos(), a.player.pos())


func test_the_stick_a_key_or_cancel_stops_the_walk() -> void:
	var gs := _game()
	gs.player.place(AREA, _start_away(gs, 5))
	var m := _main(gs)
	m.tap_world(_stall())
	assert_true(m.tapper.walking())
	m._process(0.0)
	assert_true(m.touch.cancel.visible, "Cancel shows while a tap walk runs")
	m.cancel()
	assert_false(m.tapper.walking(), "Cancel stops it")
	m.tap_world(_stall())
	Input.action_press(&"move_n")
	m._process(1.0)
	Input.action_release(&"move_n")
	assert_false(m.tapper.walking(), "the stick or a key takes over")


func test_stick_only_and_a_fight_ignore_taps() -> void:
	var gs := _game()
	gs.player.place(AREA, _start_away(gs, 4))
	var m := _main(gs)
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.device = InputEvent.DEVICE_ID_EMULATION
	ev.position = Vector2(10, 10)
	_session.touch.set_controls(TouchSettings.STICK)
	ev.pressed = true
	m.controls.world_tap(ev)
	ev.pressed = false
	m.controls.world_tap(ev)
	assert_false(m.tapper.walking(), "Stick only: a tap does nothing")
	assert_false(m.menu.visible)


func test_a_slide_or_a_stick_walk_is_no_tap() -> void:
	var gs := _game()
	gs.player.place(AREA, _start_away(gs, 4))
	var m := _main(gs)
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.device = InputEvent.DEVICE_ID_EMULATION
	ev.pressed = true
	ev.position = Vector2(100, 100)
	m.controls.world_tap(ev)
	ev.pressed = false
	ev.position = Vector2(100 + MainTap.SLOP + 10, 100)
	m.controls.world_tap(ev)
	assert_false(m.tapper.walking(), "a slide is no tap")
	m.touch.stick_walked = true
	ev.pressed = true
	ev.position = Vector2(100, 100)
	m.controls.world_tap(ev)
	ev.pressed = false
	m.controls.world_tap(ev)
	assert_false(m.tapper.walking(), "a finger that walked with the stick is no tap")


func test_controls_setting_saves_and_loads() -> void:
	var path := "user://test_touch_controls.cfg"
	DirAccess.remove_absolute(path)
	var s := TouchSettings.load_file(path)
	assert_eq(s.controls, TouchSettings.TAP, "Tap + stick by default")
	s.set_controls(TouchSettings.STICK)
	assert_eq(s.save(path), OK)
	assert_eq(TouchSettings.load_file(path).controls, TouchSettings.STICK)
	s.set_controls("feet")
	assert_eq(s.controls, TouchSettings.TAP, "an unknown value reads as Tap + stick")
	DirAccess.remove_absolute(path)


func test_options_menu_sets_the_controls() -> void:
	var real_path: String = _session.touch_settings_path
	_session.touch_settings_path = "user://test_touch_controls2.cfg"
	var o: OptionsMenu = add_child_autofree(load("res://ui/options_menu.tscn").instantiate())
	o.open()
	var c: OptionButton = o.get_node("%Controls")
	assert_eq(c.get_item_text(c.selected), "Tap + stick")
	c.item_selected.emit(1)
	assert_eq(_session.touch.controls, TouchSettings.STICK)
	DirAccess.remove_absolute(_session.touch_settings_path)
	_session.touch_settings_path = real_path
