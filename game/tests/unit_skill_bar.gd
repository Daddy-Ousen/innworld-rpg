extends GutTest
## M17.4 Skill bar (ADR 0027) on the main scene with the real data: one button
## per combat Skill (key, name, AP), keys 1-9, self Skills at once, a strike
## with one foe at once, a strike with more foes armed (gold frames), Esc and a
## click. A Rock Crab on the quiet ruins entrance map (see unit_combat_screen).

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


## The main scene, the player holding `skills`, a hostile Rock Crab at `off`.
func _main(skills: Array, off: Vector2i = Vector2i(0, 2)) -> Node:
	var db: DataDb = _session.db
	var gs := GameState.new_game(4, db)
	for id: String in skills:
		gs.progression.skills.append({"id": id, "class": "warrior", "level": 1, "day": 1})
	_session.set_state(gs)
	var m: Node = load("res://world/main.tscn").instantiate()
	m.switch_scene = false
	add_child_autofree(m)
	m.replay_turns = false
	var spot := _open_spot(gs, db)
	gs.player.place(AREA, spot)
	Combat.sync(gs, db)
	_crab = Combat.add_monster(gs, db, "rock_crab", spot + off, CombatState.HOSTILE)
	gs.combat.monsters[_crab]["hp"] = 500  # it neither falls nor runs
	Commands.wait(gs, db, 0)
	_session.changed()
	assert_true(Encounter.is_player_turn(gs))
	return m


func test_no_combat_skill_no_skill_row() -> void:
	var m := _main([])
	assert_false(m.bar.skills().visible)


func test_one_button_per_combat_skill() -> void:
	var m := _main(["lesser_strength", "power_strike", "fast_sprint"])
	var row: SkillBar = m.bar.skills()
	assert_true(row.visible)
	assert_eq(row.ids(), ["power_strike", "fast_sprint"] as Array[String], "passive Skills have no button")
	assert_eq(row.button_of("power_strike").text, "1 [Power Strike] 3 AP")
	assert_eq(row.button_of("fast_sprint").text, "2 [Fast Sprint] 0.5 AP")
	assert_false(row.button_of("fast_sprint").disabled)
	assert_ne(row.button_of("power_strike").tooltip_text, "")


func test_a_key_uses_a_self_skill_and_it_cools_down() -> void:
	var m := _main(["fast_sprint"])
	_press(m, KEY_1)
	assert_eq(m.bar.ap_text(), "AP 5.5")
	assert_eq(m.bar.move_text(), "Move 8", "one more AP of movement")
	var b: Button = m.bar.skills().button_of("fast_sprint")
	assert_eq(b.text, "1 [Fast Sprint] 0.5 AP (3)")
	assert_true(b.disabled)


func test_a_strike_with_one_foe_is_used_at_once() -> void:
	var m := _main(["power_strike"], Vector2i(0, 1))
	var gs: GameState = _session.gs
	_press(m, KEY_1)
	assert_eq(m.armed_skill(), "")
	assert_eq(CombatSkills.rounds_left(gs, Encounter.PLAYER, "power_strike"), 2)
	assert_eq(m.bar.ap_text(), "AP 3")


func test_a_strike_with_two_foes_is_armed_then_clicked() -> void:
	var m := _main(["power_strike"], Vector2i(0, 1))
	var gs: GameState = _session.gs
	var db: DataDb = _session.db
	var other := Combat.add_monster(gs, db, "rock_crab", gs.player.pos() + Vector2i(1, 0), CombatState.HOSTILE)
	gs.combat.monsters[other]["hp"] = 500
	_session.changed()
	_press(m, KEY_1)
	assert_eq(m.armed_skill(), "power_strike")
	assert_true(m.bar.skills().button_of("power_strike").button_pressed)
	assert_eq(m.view.overlay.marks.size(), 2, "both crabs framed")
	_press(m, KEY_ESCAPE)
	assert_eq(m.armed_skill(), "", "Esc lets it go")
	assert_false(m.pause.visible, "and does not open the pause menu")
	assert_eq(m.view.overlay.marks.size(), 0)
	_press(m, KEY_1)
	m.hover(CombatState.pos_of(gs.combat.monsters[other]))
	assert_string_ends_with(m.view.overlay.label_text(), "%")
	m.click(CombatState.pos_of(gs.combat.monsters[other]))
	assert_eq(m.armed_skill(), "")
	assert_eq(CombatSkills.rounds_left(gs, Encounter.PLAYER, "power_strike"), 2, "used on the clicked crab")
