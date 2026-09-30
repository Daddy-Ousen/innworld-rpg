extends GutTest
## M17.5 spell screen (ADR 0027) on the main scene with the real data: spells in the Skill
## bar (key, name, AP, MP), the MP labels, an "around" or one-foe spell cast at once, a
## line fired by a direction key, a blast previewed on hover and fired by a click, Esc,
## a refused click, the sheet, the console, the teacher's row and the spellbook row.
## A Rock Crab on the quiet ruins entrance map (see unit_skill_bar).

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


## The main scene, the player knowing `spells` and holding `skills`, a hostile Rock Crab at `off`.
func _main(spells: Array, off: Vector2i = Vector2i(0, 2), skills: Array = []) -> Node:
	var db: DataDb = _session.db
	var gs := GameState.new_game(4, db)
	for id: String in skills:
		gs.progression.skills.append({"id": id, "class": "warrior", "level": 1, "day": 1})
	for id: String in spells:
		gs.progression.spells.append(id)
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


func _crab_hp() -> int:
	return int(_session.gs.combat.monsters[_crab]["hp"])


func test_no_spell_no_mana_label() -> void:
	var m := _main([])
	assert_false(m.bar.skills().visible)
	assert_eq(m.bar.mp_text(), "")


func test_spells_are_buttons_after_the_skills() -> void:
	var m := _main(["ice_spike", "fireball"], Vector2i(0, 2), ["power_strike"])
	var row: SkillBar = m.bar.skills()
	assert_true(row.visible)
	assert_eq(row.ids(), ["power_strike", "spell:ice_spike", "spell:fireball"] as Array[String])
	assert_eq(row.button_of("spell:ice_spike").text, "2 [Ice Spike] 2 AP 2 MP")
	assert_eq(row.button_of("spell:fireball").text, "3 [Fireball] 4 AP 5 MP")
	assert_ne(row.button_of("spell:fireball").tooltip_text, "")
	assert_eq(m.bar.mp_text(), "MP 6/6")


func test_a_spell_button_is_off_without_the_mana() -> void:
	var m := _main(["ice_spike", "fireball"])
	Mana.set_mp(_session.gs, _session.db, 3)
	_session.changed()
	assert_false(m.bar.skills().button_of("spell:ice_spike").disabled)
	assert_true(m.bar.skills().button_of("spell:fireball").disabled, "5 MP, 3 left")
	assert_eq(m.bar.mp_text(), "MP 3/6")


func test_a_one_foe_spell_with_one_foe_is_cast_at_once() -> void:
	var m := _main(["ice_spike"], Vector2i(0, 3))
	_press(m, KEY_1)
	assert_eq(m.armed_skill(), "")
	assert_lt(_crab_hp(), 500, "the spike hit")
	assert_eq(m.bar.mp_text(), "MP 4/6")
	assert_eq(m.bar.ap_text(), "AP 4")


func test_a_line_spell_is_armed_and_fired_by_a_direction_key() -> void:
	var m := _main(["frozen_wind"], Vector2i(0, 2))
	_press(m, KEY_1)
	assert_eq(m.armed_skill(), "spell:frozen_wind")
	assert_true(m.bar.skills().button_of("spell:frozen_wind").button_pressed)
	m.step("s")
	assert_eq(m.armed_skill(), "")
	assert_lt(_crab_hp(), 500, "the wind hit the crab to the south")
	assert_eq(Mana.current(_session.gs, _session.db), 3)


func test_a_blast_previews_on_hover_and_fires_on_a_click() -> void:
	var m := _main(["fireball"], Vector2i(0, 3))
	var gs: GameState = _session.gs
	_press(m, KEY_1)
	assert_eq(m.armed_skill(), "spell:fireball")
	var at := CombatState.pos_of(gs.combat.monsters[_crab])
	m.hover(at)
	assert_eq(m.view.overlay.preview.size(), 9, "a 3 x 3 square round the tile")
	assert_eq(m.view.overlay.label_text(), "1 foe")
	m.click(at)
	assert_eq(m.armed_skill(), "")
	assert_lt(_crab_hp(), 500)
	assert_eq(m.view.overlay.preview.size(), 0, "the preview goes with the spell")


func test_a_one_foe_spell_with_two_foes_is_armed_with_gold_frames_and_shows_the_chance() -> void:
	var m := _main(["ice_spike"], Vector2i(0, 3))
	var gs: GameState = _session.gs
	var other := Combat.add_monster(gs, _session.db, "rock_crab", gs.player.pos() + Vector2i(2, 0), CombatState.HOSTILE)
	gs.combat.monsters[other]["hp"] = 500
	_session.changed()
	_press(m, KEY_1)
	assert_eq(m.armed_skill(), "spell:ice_spike")
	assert_eq(m.view.overlay.marks.size(), 2)
	m.hover(CombatState.pos_of(gs.combat.monsters[other]))
	assert_string_ends_with(m.view.overlay.label_text(), "%")
	m.click(CombatState.pos_of(gs.combat.monsters[other]))
	assert_lt(int(gs.combat.monsters[other]["hp"]), 500, "the clicked crab was hit")
	assert_eq(int(gs.combat.monsters[_crab]["hp"]), 500)


func test_esc_lets_a_spell_go() -> void:
	var m := _main(["fireball"], Vector2i(0, 3))
	_press(m, KEY_1)
	assert_eq(m.armed_skill(), "spell:fireball")
	_press(m, KEY_ESCAPE)
	assert_eq(m.armed_skill(), "")
	assert_false(m.pause.visible)
	_press(m, KEY_1)
	_press(m, KEY_1)
	assert_eq(m.armed_skill(), "", "picking it again lets it go")


func test_a_refused_click_keeps_the_spell_armed() -> void:
	var m := _main(["fireball"], Vector2i(0, 3))
	var gs: GameState = _session.gs
	_press(m, KEY_1)
	m.click(gs.player.pos() + Vector2i(3, 0))  # no foe there
	assert_eq(m.armed_skill(), "spell:fireball")
	assert_eq(Mana.current(gs, _session.db), 6, "nothing was paid")


func test_an_around_spell_is_cast_at_once_or_refused() -> void:
	var m := _main(["flashfire"], Vector2i(0, 2))
	_press(m, KEY_1)
	assert_eq(m.bar.mp_text(), "MP 6/6", "no foe next to you: nothing paid")
	assert_eq(_crab_hp(), 500)
	var m2 := _main(["flashfire"], Vector2i(0, 1))
	_press(m2, KEY_1)
	assert_lt(_crab_hp(), 500)
	assert_eq(m2.bar.mp_text(), "MP 3/6")


func test_hud_and_sheet_show_mana_and_spells() -> void:
	var db: DataDb = _session.db
	var gs := GameState.new_game(4, db)
	assert_false(Hud.health(gs, db).contains("MP"))
	assert_false("Spells:" in CharacterSheet.lines(gs, db))
	gs.progression.spells.append("ice_spike")
	assert_string_contains(Hud.health(gs, db), "MP 6/6")
	assert_true("Spells:" in CharacterSheet.lines(gs, db))
	assert_true(CharacterSheet.lines(gs, db).any(func(l: String) -> bool: return l.begins_with("  [Ice Spike]")))
	assert_true(CharacterSheet.lines(gs, db).any(func(l: String) -> bool: return l.contains("Intellect 3")))


func test_console_spell_and_cast() -> void:
	var db: DataDb = _session.db
	var c := ConsoleCommands.new(db)
	assert_eq(c.execute("spell ice_spike"), ["You know [Ice Spike]."] as Array[String])
	assert_string_contains("\n".join(c.execute("spell ice_spike")), "already know")
	assert_string_contains("\n".join(c.execute("spell nope")), "Unknown spell")
	assert_string_contains("\n".join(c.execute("status")), "Spells: [Ice Spike]")
	assert_string_contains("\n".join(c.execute("cast ice_spike")), Spells.NOT_IN_FIGHT)


func test_a_teacher_row_and_a_spellbook_row() -> void:
	var db: DataDb = _session.db
	var gs := GameState.new_game(4, db)
	gs.player.place("liscor_market", Vector2i(5, 5))
	gs.world.events["b1.ceria_teaches_ryoka_light"] = {"status": Spells.DONE}
	gs.npcs.npcs["ceria_springwalker"]["area"] = "liscor_market"
	gs.npcs.npcs["ceria_springwalker"]["x"] = 6
	gs.npcs.npcs["ceria_springwalker"]["y"] = 5
	_session.set_state(gs)
	var menu: InteractMenu = load("res://ui/interact_menu.tscn").instantiate()
	add_child_autofree(menu)
	assert_true(menu.open(Interact.options(gs, db), db))
	var items: ItemList = menu.get_node("%Items")
	var rows: Array[String] = []
	for i in items.item_count:
		rows.append(items.get_item_text(i))
	assert_true(rows.any(func(r: String) -> bool: return r.contains("Learn [Ice Spike] (2 h)")), str(rows))
	assert_true(rows.any(func(r: String) -> bool: return r.contains("Learn [Flashfire] (3 h)")))
	var picked: Array = []
	menu.chosen.connect(func(obj: String, act: String) -> void: picked.append([obj, act]))
	for i in items.item_count:
		if items.get_item_text(i).contains("Learn [Ice Spike]"):
			items.item_activated.emit(i)
	assert_eq(picked, [["ceria_springwalker", "learn:ice_spike"]])
	Commands.give(gs, db, 0, "spellbook_fireball", 1)
	var bag_rows := Bag.rows(gs, db)
	assert_eq(bag_rows.size(), 1)
	assert_eq(bag_rows[0]["use"], "use:spellbook_fireball")
	assert_string_contains(bag_rows[0]["text"], "Read")
	var menu2: InteractMenu = load("res://ui/interact_menu.tscn").instantiate()
	add_child_autofree(menu2)
	assert_true(menu2.open_bag(gs, db))
	assert_string_contains((menu2.get_node("%Items") as ItemList).get_item_text(0), "Read")
