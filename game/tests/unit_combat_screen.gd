extends GutTest
## M17.3 combat screen (ADR 0027) on the main scene with the real data: the
## combat bar (turn order faces, AP pips, End turn), the move range and the
## click preview on the map, mouse walks and blows, and the replay of the
## others' turns (skipped by a key). A Rock Crab (Agility 2) on the quiet
## ruins entrance map; the player (Agility 3) goes first.

const AREA := "ruins_entrance"

var _session: Node
var _crab := ""


func before_each() -> void:
	_session = get_node_or_null("/root/Session")


func _press(node: Node, code: Key) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	ev.keycode = code
	ev.pressed = true
	node._unhandled_input(ev)


## A 7×7 block of free floor with no exit in it; its centre.
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


## The main scene with the player at an open spot and a hostile Rock Crab at
## `off` from them; the encounter has started.
func _main(off: Vector2i = Vector2i(0, 2), replay := false) -> Node:
	var db: DataDb = _session.db
	var gs := GameState.new_game(4, db)
	_session.set_state(gs)
	var m: Node = load("res://world/main.tscn").instantiate()
	m.switch_scene = false
	add_child_autofree(m)
	m.replay_turns = replay
	var spot := _open_spot(gs, db)
	assert_ne(spot, Vector2i(-1, -1), "an open spot on %s" % AREA)
	gs.player.place(AREA, spot)
	Combat.sync(gs, db)
	_crab = Combat.add_monster(gs, db, "rock_crab", spot + off, CombatState.HOSTILE)
	Commands.wait(gs, db, 0)
	_session.changed()
	assert_true(Encounter.is_player_turn(gs))
	return m


func test_the_bar_is_hidden_with_no_fight() -> void:
	_session.set_state(GameState.new_game(4, _session.db))
	var m: Node = load("res://world/main.tscn").instantiate()
	m.switch_scene = false
	add_child_autofree(m)
	assert_false(m.bar.visible)


func test_the_bar_shows_the_order_and_the_ap() -> void:
	var m := _main()
	var gs: GameState = _session.gs
	assert_true(m.bar.visible)
	var order: Array[String] = []
	order.assign(gs.combat.encounter["order"])
	assert_eq(m.bar.face_ids(), order)
	assert_eq(m.bar.active_id(), "player")
	assert_eq(m.bar.ap_text(), "AP 6")
	assert_eq(m.bar.move_text(), "Move 4")
	assert_false(m.bar.button().disabled)
	Commands.move(gs, _session.db, "n")
	_session.changed()
	assert_eq(m.bar.ap_text(), "AP 5.75")
	assert_eq(m.bar.move_text(), "Move 3")


func test_the_ap_text_counts_quarters() -> void:
	assert_eq(CombatBar._ap_string(24), "6")
	assert_eq(CombatBar._ap_string(18), "4.5")
	assert_eq(CombatBar._ap_string(13), "3.25")


func test_the_map_shows_the_move_range() -> void:
	var m := _main()
	var reach := Encounter.reach(_session.gs, _session.db)
	assert_gt(reach.size(), 0)
	assert_eq(m.view.overlay.reach, reach)


func test_hover_shows_the_path_and_the_hit_chance() -> void:
	var m := _main()
	var gs: GameState = _session.gs
	m.hover(gs.player.pos() + Vector2i(2, 0))
	assert_eq(m.view.overlay.path.size(), 2)
	assert_false(m.view.overlay.has_target)
	m.hover(CombatState.pos_of(gs.combat.monsters[_crab]))
	assert_true(m.view.overlay.has_target)
	var chance := roundi(Combat.player_hit_chance(gs, _session.db, _crab) * 100.0)
	assert_eq(m.view.overlay.label_text(), "%d%%" % chance)
	assert_eq(m.view.overlay.path.size(), 1, "one step to its side")


func test_a_click_walks_to_the_tile() -> void:
	var m := _main()
	var gs: GameState = _session.gs
	var to := gs.player.pos() + Vector2i(-2, 0)
	m.click(to)
	for i in 6:
		m._process(1.0)
	assert_eq(gs.player.pos(), to)
	assert_eq(int(gs.combat.encounter["moved_q"]), 2)


func test_a_click_on_a_foe_walks_up_and_hits_it() -> void:
	var m := _main()
	var gs: GameState = _session.gs
	m.click(CombatState.pos_of(gs.combat.monsters[_crab]))
	for i in 6:
		m._process(1.0)
	assert_eq(int(gs.combat.encounter["moved_q"]), 1)
	assert_eq(int(gs.combat.encounter["ap_q"]), 24 - 1 - 8, "a step and a blow")
	assert_eq(int(gs.combat.fight["attacks"]), 1)


func test_the_end_turn_button_runs_the_others() -> void:
	var m := _main()
	var gs: GameState = _session.gs
	m.bar.button().pressed.emit()
	assert_eq(int(gs.combat.encounter["round"]), 2)
	assert_true(Encounter.is_player_turn(gs))
	assert_eq(m.bar.ap_text(), "AP 6")


func test_a_key_skips_the_replay() -> void:
	var m := _main(Vector2i(0, 2), true)
	var gs: GameState = _session.gs
	m.end_turn()
	assert_true(m.view.is_replaying(), "the crab's turn plays")
	assert_true(m.is_busy())
	assert_eq(m.bar.active_id(), _crab, "the bar shows who acts")
	assert_true(m.bar.button().disabled)
	_press(m, KEY_B)
	assert_false(m.view.is_replaying())
	assert_false(gs.combat.blocking, "the key only skipped the replay")
	var crab_turn: Dictionary = gs.combat.turns[0]
	var history: Array = m.hud.history()
	for line: String in crab_turn["lines"]:
		assert_has(history, line)
	assert_eq(m.view.monsters.get_node(NodePath(_crab)).position,
			WorldView.cell_center(CombatState.pos_of(gs.combat.monsters[_crab])), "the end state is drawn")


func test_a_replay_ends_by_itself() -> void:
	var m := _main(Vector2i(0, 2), true)
	m.end_turn()
	assert_true(m.view.is_replaying())
	await wait_for_signal(m.view.replay_done, 10)
	assert_false(m.view.is_replaying())
	assert_true(m.bar.visible)
	assert_eq(m.view.camera.position, Vector2.ZERO, "the camera is back on the player")


func test_cell_at_finds_the_cell() -> void:
	var m := _main()
	var c := Vector2i(5, 3)
	assert_eq(m.view.cell_at(m.view.to_global(WorldView.cell_center(c))), c)
