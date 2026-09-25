extends GutTest
## M6.5 canon fights on the real Book 1 data (ADR 0011): the Chieftain's
## stage in the inn on day 9 (win → the event changes; lose → canon), a
## Liscor guard fights a Goblin at the gate, and Goblins the player lets go
## still come to eat on day 19.

const CHIEFTAIN_EVENT := "b1.erin_kills_chieftain"
const INN_SPOT := Vector2i(12, 11)

var _db: DataDb


func before_each() -> void:
	_db = DataDb.load_dir()


## A new game (day 8) that has slept until the morning of `day`.
func _game_on_day(day: int, seed_value: int = 1) -> GameState:
	var gs := GameState.new_game(seed_value, _db)
	ToyCanon.sleep_through(gs, _db, day - 1)
	assert_eq(gs.clock.day(), day)
	return gs


## Day 9 in the inn: waits until the Chieftain comes in. Returns his id.
func _chieftain_arrives(gs: GameState) -> String:
	gs.player.place("inn_interior", INN_SPOT)
	Commands.settle(gs, _db)
	var lines: Array[String] = []
	for i in 240:
		if not gs.world.staged.is_empty():
			break
		assert_true(Commands.wait(gs, _db, 60) >= 0, "wait")
		lines.append_array(gs.combat.lines)
	assert_eq(gs.world.staged, {CHIEFTAIN_EVENT: 9})
	assert_eq(gs.clock.minute(), 9 * 60, "he comes at 09:00")
	assert_has(lines, _db.canon.events[CHIEFTAIN_EVENT]["stage"]["line"])
	for id in gs.combat.ids():
		if gs.combat.monsters[id]["type"] == "goblin_chieftain":
			assert_eq(gs.combat.monsters[id]["stage"], CHIEFTAIN_EVENT)
			return id
	fail_test("no Chieftain on the map")
	return ""


func _records(gs: GameState, action_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for r: Dictionary in gs.action_log.records:
		if r["action_id"] == action_id:
			out.append(r)
	return out


func test_the_chieftain_stage_data_is_sound() -> void:
	assert_eq(_db.errors, [] as Array[String])
	assert_has(_db.canon.stages, CHIEFTAIN_EVENT)
	var e: Dictionary = _db.combat.enemies["goblin_chieftain"]
	assert_eq(float(e["flee_below"]), 0.0, "he fights to the death")
	for s: Dictionary in _db.combat.spawns:
		assert_ne(s["enemy"], "goblin_chieftain", "only a stage brings him")


func test_beating_the_chieftain_with_erin_changes_the_story() -> void:
	ToyCombat.freeze(_db)
	ToyCombat.always_hit(_db)
	var gs := _game_on_day(9)
	var boss := _chieftain_arrives(gs)
	assert_eq(gs.npcs.npcs["erin_solstice"]["area"], "inn_interior", "Erin is home")
	var lines: Array[String] = []
	for i in 60:
		if not gs.combat.monsters.has(boss):
			break
		var at := CombatState.pos_of(gs.combat.monsters[boss])
		var path := Pathfind.path(_db.maps, "inn_interior", gs.player.pos(), Pathfind.around(at),
				MonsterSim.taken(gs, ""))
		if path["found"] and (path["steps"] as Array).is_empty():
			var d := at - gs.player.pos()
			var dir := "e" if d.x > 0 else "w" if d.x < 0 else "s" if d.y > 0 else "n"
			Commands.attack(gs, _db, dir)
		elif path["found"]:
			Commands.move(gs, _db, path["steps"][0])
		else:
			Commands.wait(gs, _db, 6)
		lines.append_array(gs.combat.lines)
	assert_false(gs.combat.monsters.has(boss), "the Chieftain is dead")
	assert_false(gs.combat.has_fight())
	assert_true(lines.any(func(l: String) -> bool: return l.begins_with("Erin Solstice hits the Goblin Chieftain")),
			"Erin fights next to the player")
	var melee := _records(gs, "attack_melee")
	assert_eq(melee.size(), 1)
	assert_eq(melee[0]["outcome"], "success")
	assert_eq(melee[0]["context"]["enemy"], "goblin_chieftain")
	assert_eq(melee[0]["context"]["killed"], true)

	ToyCanon.sleep_through(gs, _db, 9)
	assert_eq(gs.world.status(CHIEFTAIN_EVENT), Director.CHANGED)
	var entry: Dictionary = gs.world.history.filter(func(h: Dictionary) -> bool:
		return h["event"] == CHIEFTAIN_EVENT)[0]
	assert_eq(entry["by"], Director.BY_PLAYER)
	assert_eq(entry["hook"], "player_fought_chieftain")
	assert_false(gs.world.is_alive(_db.canon, "goblin_chieftain"), "the event still kills him")
	assert_true(gs.flags.has("erin.killed_chieftain"))
	assert_true(gs.flags.has("wandering_inn.earther_fought_chieftain"))
	assert_false(gs.flags.has("erin.stab_wound"), "Erin was not stabbed")
	assert_false(gs.flags.has("erin.hands_burned"))
	assert_eq(gs.world.relationship("erin_solstice", NpcSim.PLAYER), 3)
	var texts := gs.world.news.map(func(n: Dictionary) -> String: return n["text"])
	assert_true(texts.has(_db.canon.events[CHIEFTAIN_EVENT]["hooks"][0]["news"]))
	assert_false(texts.has(_db.canon.events[CHIEFTAIN_EVENT]["news"]))

	# The rest of the canon runs on: only this event changed.
	ToyCanon.sleep_through(gs, _db, 19)
	for h: Dictionary in gs.world.history:
		if int(h["day"]) >= 8 and h["event"] != CHIEFTAIN_EVENT:
			assert_true(Director.happened(h["outcome"]), "%s: %s" % [h["event"], h["outcome"]])
	var rules: Dictionary = _db.rules["director"]
	assert_almost_eq(gs.world.drift, float(rules["drift"]["changed"]) * float(rules["tier_weight"]["2"]),
			0.000001)


func test_losing_to_the_chieftain_leaves_the_canon() -> void:
	var gs := _game_on_day(9, 3)
	_chieftain_arrives(gs)
	Combat.set_hp(gs, _db, 1)
	for i in 200:
		if Combat.is_down(gs):
			break
		Commands.block(gs, _db)
	assert_true(Combat.is_down(gs), "knocked out")
	Commands.sleep(gs, _db, Rest.ANYWHERE)
	ToyCanon.sleep_through(gs, _db, 9)
	assert_eq(gs.world.status(CHIEFTAIN_EVENT), Director.DONE)
	assert_false(gs.flags.has("wandering_inn.earther_fought_chieftain"), "canon: Erin fought alone")
	assert_eq(gs.world.relationship("erin_solstice", NpcSim.PLAYER), 0)


func test_the_chieftain_does_not_come_to_an_empty_inn() -> void:
	var gs := _game_on_day(9)
	gs.player.place("inn_interior", INN_SPOT)
	Commands.settle(gs, _db)
	gs.clock.advance(7 * 60)  # 13:00: past the stage hours
	Commands.wait(gs, _db, 60)
	assert_true(gs.world.staged.is_empty())
	ToyCanon.sleep_through(gs, _db, 9)
	assert_eq(gs.world.status(CHIEFTAIN_EVENT), Director.DONE)


func test_a_liscor_guard_fights_a_goblin_at_the_gate() -> void:
	ToyCombat.freeze(_db)
	ToyCombat.always_hit(_db)
	var gs := GameState.new_game(1, _db)
	assert_eq(gs.player.area, "liscor_gate")
	var guards := gs.npcs.in_area("liscor_gate").filter(func(id: String) -> bool:
		return (_db.canon.npcs[id]["tags"] as Array).has("guard"))
	assert_false(guards.is_empty(), "guards at the gate")
	var gob: String = Commands.spawn_monster(gs, _db, "goblin_grunt", Vector2i(6, 14))["id"]
	assert_ne(gob, "")
	var lines: Array[String] = []
	for i in 40:
		if not gs.combat.monsters.has(gob):
			break
		Commands.wait(gs, _db, 6)
		lines.append_array(gs.combat.lines)
	assert_false(gs.combat.monsters.has(gob), "a guard killed the Goblin")
	assert_true(lines.any(func(l: String) -> bool: return l.contains(" hits the Goblin for ")), str(lines))
	assert_false(gs.combat.has_fight())


func test_goblins_you_let_go_still_come_to_eat() -> void:
	ToyCombat.always_hit(_db)
	var gs := _game_on_day(14)
	gs.player.place("floodplains_south", Vector2i(5, 2))
	Commands.settle(gs, _db)
	var gob := Combat.add_monster(gs, _db, "goblin_grunt", Vector2i(5, 1))
	gs.combat.monsters[gob]["hp"] = 5
	Commands.attack(gs, _db, "n")
	for i in 20:
		if not gs.combat.has_fight():
			break
		Commands.wait(gs, _db, 6)
	assert_false(gs.combat.monsters.has(gob), "the Goblin ran off")
	assert_eq(_records(gs, "spare_foe").size(), 1, "the player let it go")
	assert_eq(_records(gs, "attack_melee")[0]["context"]["killed"], false)
	ToyCanon.sleep_through(gs, _db, 19)
	assert_eq(gs.world.status("b1.rags_brings_goblins_to_eat"), Director.DONE,
			"no Goblin died: the tribe still comes")
