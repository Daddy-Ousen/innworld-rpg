extends GutTest
## M7.2 canon fight on the real Book 1 data: three Human adventurers attack
## Rags's Goblins in the inn on the evening of day 28 (1.42). Erin, Pawn and
## the skeleton fight; Rags and two of her band join at once. A win changes
## the event (the Goblins trust the player); a knock-out leaves the canon.

const BRAWL_EVENT := "b1.adventurers_attack_goblins_at_inn"
const INN_SPOT := Vector2i(6, 8)

var _db: DataDb


func before_each() -> void:
	_db = DataDb.load_dir()


## A new game (day 8) that has slept until the morning of `day`.
func _game_on_day(day: int, seed_value: int = 1) -> GameState:
	var gs := GameState.new_game(seed_value, _db)
	ToyCanon.sleep_through(gs, _db, day - 1)
	assert_eq(gs.clock.day(), day)
	return gs


## Day 28 in the inn: waits until the adventurers come in. Returns their ids.
func _brawl_starts(gs: GameState) -> Array[String]:
	gs.player.place("inn_interior", INN_SPOT)
	Commands.settle(gs, _db)
	var lines: Array[String] = []
	for i in 900:
		if not gs.world.staged.is_empty():
			break
		assert_true(Commands.wait(gs, _db, 60) >= 0, "wait")
		lines.append_array(gs.combat.lines)
	lines.append_array(gs.combat.lines)
	assert_eq(gs.world.staged, {BRAWL_EVENT: 28})
	assert_eq(gs.clock.minute(), 19 * 60, "they come at 19:00")
	var st: Dictionary = _db.canon.events[BRAWL_EVENT]["stage"]
	assert_has(lines, st["line"])
	assert_has(lines, st["waves"][0]["line"], "Rags's band joins at once")
	var out: Array[String] = []
	for id in gs.combat.ids():
		var m: Dictionary = gs.combat.monsters[id]
		if m["stage"] == BRAWL_EVENT and m["state"] != CombatState.ALLY:
			out.append(id)
	return out


## One turn: hit an adventurer next to the player, or step toward the
## closest one, or wait.
func _step_toward_a_foe(gs: GameState) -> void:
	var best: Array = []
	for id in gs.combat.ids():
		var m: Dictionary = gs.combat.monsters[id]
		if m["area"] != "inn_interior" or m["state"] != CombatState.HOSTILE:
			continue
		var at := CombatState.pos_of(m)
		var d := at - gs.player.pos()
		if absi(d.x) + absi(d.y) == 1:
			Commands.attack(gs, _db, "e" if d.x > 0 else "w" if d.x < 0 else "s" if d.y > 0 else "n")
			return
		var path := Pathfind.path(_db.maps, "inn_interior", gs.player.pos(), Pathfind.around(at),
				MonsterSim.taken(gs, ""))
		if path["found"] and not (path["steps"] as Array).is_empty() \
				and (best.is_empty() or (path["steps"] as Array).size() < best.size()):
			best = path["steps"]
	if best.is_empty():
		Commands.wait(gs, _db, 6)
	else:
		Commands.move(gs, _db, best[0])


func _records(gs: GameState, action_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for r: Dictionary in gs.action_log.records:
		if r["action_id"] == action_id:
			out.append(r)
	return out


func test_the_brawl_stage_data_is_sound() -> void:
	assert_eq(_db.errors, [] as Array[String])
	assert_has(_db.canon.stages, BRAWL_EVENT)
	var st: Dictionary = _db.canon.events[BRAWL_EVENT]["stage"]
	assert_eq((st["foes"] as Array).size(), 3, "canon: three adventurers")
	for a: String in ["erin_solstice", "pawn", "toren"]:
		assert_has(st["allies"], a)
	assert_true(_db.behaviour.npcs.has("toren"), "the skeleton has a behaviour entry")
	assert_true(_db.behaviour.npcs["toren"].has("combat"))
	assert_eq(st["waves"][0]["allies"], ["rags"])
	assert_eq((st["waves"][0]["helpers"] as Array).size(), 2)
	var axe: Dictionary = _db.combat.enemies["adventurer_axeman"]
	var sword: Dictionary = _db.combat.enemies["adventurer_brawler"]
	assert_gt(float(axe["danger"]), float(sword["danger"]), "the big one names the fight's records")
	for e: Dictionary in [axe, sword]:
		assert_has(e["tags"], "human")
		assert_gte(float(e["flee_below"]), 0.4, "they run rather than die")
	for s: Dictionary in _db.combat.spawns:
		assert_false(str(s["enemy"]).begins_with("adventurer_"), "only a stage brings them")


func test_the_skeleton_keeps_to_the_inn_once_it_exists() -> void:
	var gs := _game_on_day(27)
	gs.clock.advance(4 * 60)
	Commands.wait(gs, _db, 60)
	assert_ne(gs.npcs.npcs["toren"]["area"], "inn_interior", "not made yet on day 27")
	ToyCanon.sleep_through(gs, _db, 27)
	gs.clock.advance(4 * 60)  # 10:00 on day 28
	Commands.wait(gs, _db, 60)
	assert_eq(gs.npcs.npcs["toren"]["area"], "inn_interior")


func test_winning_the_brawl_wins_the_goblins_trust() -> void:
	ToyCombat.freeze(_db)
	ToyCombat.always_hit(_db)
	var gs := _game_on_day(28)
	var foes := _brawl_starts(gs)
	assert_eq(foes.size(), 3)
	assert_eq(gs.npcs.npcs["rags"]["area"], "inn_interior", "Rags joins the fight")
	assert_eq(gs.npcs.npcs["toren"]["area"], "inn_interior", "the skeleton is home")
	assert_eq(gs.combat.in_state(CombatState.ALLY).size(), 2, "two of Rags's band")
	for i in 600:
		if not gs.combat.has_fight():
			break
		_step_toward_a_foe(gs)
	assert_false(gs.combat.has_fight(), "all three beaten")
	assert_true(gs.combat.in_state(CombatState.ALLY).is_empty(), "the helpers left")
	var melee := _records(gs, "attack_melee")
	assert_eq(melee.size(), 1)
	assert_eq(melee[0]["outcome"], "success")
	assert_eq(melee[0]["context"]["enemy"], "adventurer_axeman")

	ToyCanon.sleep_through(gs, _db, 28)
	assert_eq(gs.world.status(BRAWL_EVENT), Director.CHANGED)
	var entry: Dictionary = gs.world.history.filter(func(h: Dictionary) -> bool:
		return h["event"] == BRAWL_EVENT)[0]
	assert_eq(entry["hook"], "player_fought_adventurers")
	assert_true(gs.flags.has("wandering_inn.earther_defended_goblins"))
	assert_true(gs.flags.has("wandering_inn.furniture_broken"), "canon effects still apply")
	assert_eq(gs.world.relationship("rags", NpcSim.PLAYER), 2)
	assert_eq(gs.world.relationship("erin_solstice", NpcSim.PLAYER), 1)
	var texts := gs.world.news.map(func(n: Dictionary) -> String: return n["text"])
	assert_true(texts.has(_db.canon.events[BRAWL_EVENT]["hooks"][0]["news"]))
	assert_false(texts.has(_db.canon.events[BRAWL_EVENT]["news"]))
	assert_eq(gs.world.status("b1.gazi_marks_erin_and_pisces"), Director.DONE, "Gazi still chooses them")


func test_losing_the_brawl_leaves_the_canon() -> void:
	var gs := _game_on_day(28, 3)
	_brawl_starts(gs)
	gs.player.place("inn_interior", Vector2i(12, 13))  # face to face with the big one
	Combat.set_hp(gs, _db, 1)
	for i in 200:
		if Combat.is_down(gs) or not gs.combat.has_fight():
			break
		Commands.block(gs, _db)
	assert_true(Combat.is_down(gs), "knocked out")
	Commands.sleep(gs, _db, Rest.ANYWHERE)
	ToyCanon.sleep_through(gs, _db, 28)
	assert_eq(gs.world.status(BRAWL_EVENT), Director.DONE)
	assert_false(gs.flags.has("wandering_inn.earther_defended_goblins"))
	assert_eq(gs.world.relationship("rags", NpcSim.PLAYER), 0)


func test_no_brawl_the_evening_before() -> void:
	var gs := _game_on_day(27)
	gs.player.place("inn_interior", INN_SPOT)
	Commands.settle(gs, _db)
	gs.clock.advance(13 * 60)  # 19:00 on day 27
	Commands.wait(gs, _db, 60)
	assert_true(gs.world.staged.is_empty())


func test_the_adventurers_run_out_of_the_door() -> void:
	var gs := _game_on_day(28, 3)
	_brawl_starts(gs)
	for i in 400:
		if not gs.combat.has_fight():
			break
		Commands.wait(gs, _db, 6)
	assert_false(gs.combat.has_fight(), "the fight ends: nobody is stuck in a corner")
	assert_false(Combat.is_down(gs), "the allies held; the player stood back")
	var left := gs.combat.ids().filter(func(id: String) -> bool:
		return gs.combat.monsters[id]["stage"] == BRAWL_EVENT)
	assert_eq(left, [], "no adventurer is left on the map")

