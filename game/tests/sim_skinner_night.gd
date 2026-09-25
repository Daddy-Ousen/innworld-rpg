extends GutTest
## M7.4 canon fights on the real Book 1 data, the night of day 39 (1.60-1.62).
## The dead reach Liscor's gate at dusk: Relc and Zevara hold the road, Pisces
## and a few Soldiers come later. Then they climb the inn's hill: Erin, Toren,
## Bird and Workers fight, and Soldiers and Rags's Goblins come last. A win
## against the gate's Crypt Lord or against Skinner changes that event; a
## knock-out keeps the canon. Also the day-39 schedules: the Horns miss
## dinner, and Klbkch walks his rounds again once he is reborn.

const GATE_EVENT := "b1.skinner_leads_the_dead_into_liscor"
const INN_EVENT := "b1.rags_kills_skinner"
const GATE_SPOT := Vector2i(10, 11)
const HILL_SPOT := Vector2i(16, 14)

var _db: DataDb


func before_each() -> void:
	_db = DataDb.load_dir()


## A new game (day 8) that has slept until the morning of `day`.
func _game_on_day(day: int, seed_value: int = 1) -> GameState:
	var gs := GameState.new_game(seed_value, _db)
	ToyCanon.sleep_through(gs, _db, day - 1)
	assert_eq(gs.clock.day(), day)
	return gs


## From `hour` on this day at `spot` in `area`: waits until event `id`
## stages. Returns the combat lines seen.
func _stage_starts(gs: GameState, area: String, spot: Vector2i, hour: int, id: String) -> Array[String]:
	gs.clock.advance((hour - 6) * 60)
	gs.player.place(area, spot)
	Commands.settle(gs, _db)
	var lines: Array[String] = gs.combat.lines.duplicate()
	for i in 20:
		if gs.world.staged.has(id):
			break
		assert_true(Commands.wait(gs, _db, 6) >= 0, "wait")
		lines.append_array(gs.combat.lines)
	assert_true(gs.world.staged.has(id), id + " stages")
	return lines


## One turn: hit a hostile monster next to the player, or step toward the
## closest one, or wait.
func _step_toward_a_foe(gs: GameState) -> void:
	var area := gs.player.area
	var best: Array = []
	for id in gs.combat.ids():
		var m: Dictionary = gs.combat.monsters[id]
		if m["area"] != area or m["state"] != CombatState.HOSTILE:
			continue
		var at := CombatState.pos_of(m)
		var d := at - gs.player.pos()
		if absi(d.x) + absi(d.y) == 1:
			Commands.attack(gs, _db, "e" if d.x > 0 else "w" if d.x < 0 else "s" if d.y > 0 else "n")
			return
		var path := Pathfind.path(_db.maps, area, gs.player.pos(), Pathfind.around(at), MonsterSim.taken(gs, ""))
		if path["found"] and not (path["steps"] as Array).is_empty() \
				and (best.is_empty() or (path["steps"] as Array).size() < best.size()):
			best = path["steps"]
	if best.is_empty():
		Commands.wait(gs, _db, 6)
	else:
		Commands.move(gs, _db, best[0])


func _fight_to_the_end(gs: GameState) -> void:
	for i in 4000:
		if not gs.combat.has_fight():
			break
		_step_toward_a_foe(gs)
	assert_false(gs.combat.has_fight(), "the dead are beaten")


func _records(gs: GameState, action_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for r: Dictionary in gs.action_log.records:
		if r["action_id"] == action_id:
			out.append(r)
	return out


func _npc_area(gs: GameState, npc: String) -> String:
	return str(gs.npcs.npcs[npc]["area"])


## Every foe type in event `id`'s stage (first foes and all waves).
func _foe_types(id: String) -> Array:
	var st: Dictionary = _db.canon.events[id]["stage"]
	var out := []
	for f: Dictionary in st["foes"]:
		out.append(f["enemy"])
	for w: Dictionary in st["waves"]:
		out.append_array(w.get("foes", []))
	return out


## The foe type that names the fight's records: the most dangerous one.
func _top_foe(id: String) -> String:
	var top := ""
	for type: String in _foe_types(id):
		if top == "" or float(_db.combat.enemies[type]["danger"]) > float(_db.combat.enemies[top]["danger"]):
			top = type
	return top


func _hook_of(gs: GameState, id: String) -> String:
	var entry: Dictionary = gs.world.history.filter(func(h: Dictionary) -> bool: return h["event"] == id)[0]
	return str(entry.get("hook", ""))


func test_the_night_stage_data_is_sound() -> void:
	assert_eq(_db.errors, [] as Array[String])
	for id: String in [GATE_EVENT, INN_EVENT]:
		assert_has(_db.canon.stages, id)
	assert_eq(_db.canon.events[GATE_EVENT]["stage"]["area"], "liscor_gate")
	assert_eq(_db.canon.events[INN_EVENT]["stage"]["area"], "inn_hill")
	assert_eq(_top_foe(GATE_EVENT), "crypt_lord", "the gate's records name the Crypt Lord")
	assert_eq(_top_foe(INN_EVENT), "skinner", "the hill's records name Skinner")
	assert_false(_foe_types(GATE_EVENT).has("skinner"), "Skinner stays out of reach at the gate")
	for npc: String in ["erin_solstice", "toren", "bird", "rags", "relc", "zevara", "pisces"]:
		assert_true(_db.behaviour.npcs.has(npc), npc + " can be a stage ally")
		assert_true(_db.behaviour.npcs[npc].has("combat"), npc + " has a combat block")
	var stage_only := ["zombie", "skeleton", "ghoul", "crypt_lord", "skinner", "antinium_worker", "antinium_soldier"]
	for s: Dictionary in _db.combat.spawns:
		assert_false(stage_only.has(s["enemy"]), "only a stage brings " + str(s["enemy"]))
	for id: String in [GATE_EVENT, INN_EVENT]:
		for type: String in _foe_types(id):
			assert_false(str(type).begins_with("antinium_"), "Antinium only fight on the player's side")


func test_holding_the_gate_wins_the_watchs_thanks() -> void:
	ToyCombat.freeze(_db)
	ToyCombat.always_hit(_db)
	var gs := _game_on_day(39)
	var lines := _stage_starts(gs, "liscor_gate", GATE_SPOT, 18, GATE_EVENT)
	var st: Dictionary = _db.canon.events[GATE_EVENT]["stage"]
	assert_has(lines, st["line"])
	assert_has(lines, st["waves"][0]["line"], "Relc and Zevara come at once")
	assert_eq(_npc_area(gs, "relc"), "liscor_gate")
	assert_eq(_npc_area(gs, "zevara"), "liscor_gate")
	_fight_to_the_end(gs)
	var melee := _records(gs, "attack_melee")
	assert_eq(melee.size(), 1)
	assert_eq(melee[0]["outcome"], "success")
	assert_eq(melee[0]["context"]["enemy"], "crypt_lord")
	assert_eq(melee[0]["context"]["location"], "liscor_east_gate")

	ToyCanon.sleep_through(gs, _db, 39)
	assert_eq(gs.world.status(GATE_EVENT), Director.CHANGED)
	assert_eq(_hook_of(gs, GATE_EVENT), "player_held_the_gate")
	assert_true(gs.flags.has("liscor.earther_held_the_gate"))
	assert_true(gs.flags.has("skinner.hunts_the_inn"), "canon effects still apply")
	assert_eq(gs.world.relationship("zevara", NpcSim.PLAYER), 2)
	assert_eq(gs.world.relationship("relc", NpcSim.PLAYER), 1)
	assert_eq(gs.world.status(INN_EVENT), Director.DONE, "the inn's night goes on without the player")


func test_standing_against_skinner_changes_the_night_at_the_inn() -> void:
	ToyCombat.freeze(_db)
	ToyCombat.always_hit(_db)
	var gs := _game_on_day(39)
	var lines := _stage_starts(gs, "inn_hill", HILL_SPOT, 20, INN_EVENT)
	var st: Dictionary = _db.canon.events[INN_EVENT]["stage"]
	assert_has(lines, st["line"])
	assert_has(lines, st["waves"][0]["line"], "Erin and the Workers come out at once")
	for npc: String in ["erin_solstice", "toren", "bird"]:
		assert_eq(_npc_area(gs, npc), "inn_hill", npc)
	assert_eq(gs.combat.in_state(CombatState.ALLY).size(), 5, "five Workers")
	_fight_to_the_end(gs)
	var melee := _records(gs, "attack_melee")
	assert_eq(melee.size(), 1)
	assert_eq(melee[0]["outcome"], "success")
	assert_eq(melee[0]["context"]["enemy"], "skinner")

	ToyCanon.sleep_through(gs, _db, 39)
	assert_eq(gs.world.status(INN_EVENT), Director.CHANGED)
	assert_eq(_hook_of(gs, INN_EVENT), "player_fought_skinner")
	assert_true(gs.flags.has("wandering_inn.earther_fought_skinner"))
	assert_true(gs.flags.has("skinner.dead"), "Rags still kills it")
	assert_eq(gs.world.relationship("erin_solstice", NpcSim.PLAYER), 3)
	assert_eq(gs.world.relationship("bird", NpcSim.PLAYER), 2)
	var texts := gs.world.news.map(func(n: Dictionary) -> String: return n["text"])
	assert_true(texts.has(_db.canon.events[INN_EVENT]["hooks"][0]["news"]))
	assert_false(texts.has(_db.canon.events[INN_EVENT]["news"]))
	assert_eq(gs.world.status("b1.klbkch_is_reborn"), Director.DONE)
	assert_true(gs.world.is_alive(_db.canon, "klbkch"))


func test_a_knock_out_on_the_hill_keeps_the_canon() -> void:
	var gs := _game_on_day(39, 3)
	_stage_starts(gs, "inn_hill", HILL_SPOT, 20, INN_EVENT)
	var foe := ""
	for id in gs.combat.ids():
		var m: Dictionary = gs.combat.monsters[id]
		if m["stage"] == INN_EVENT and m["state"] == CombatState.HOSTILE:
			foe = id
			break
	assert_ne(foe, "")
	gs.player.place("inn_hill", CombatState.pos_of(gs.combat.monsters[foe]) + Vector2i(0, -1))
	Combat.set_hp(gs, _db, 1)
	for i in 200:
		if Combat.is_down(gs) or not gs.combat.has_fight():
			break
		Commands.block(gs, _db)
	assert_true(Combat.is_down(gs), "knocked out")
	Commands.sleep(gs, _db, Rest.ANYWHERE)
	ToyCanon.sleep_through(gs, _db, 39)
	assert_eq(gs.world.status(INN_EVENT), Director.DONE)
	assert_false(gs.flags.has("wandering_inn.earther_fought_skinner"))
	assert_eq(gs.world.relationship("erin_solstice", NpcSim.PLAYER), 0)


func test_no_dead_on_the_hill_the_night_before() -> void:
	var gs := _game_on_day(38)
	gs.clock.advance(15 * 60)  # 21:00 on day 38
	gs.player.place("inn_hill", HILL_SPOT)
	Commands.settle(gs, _db)
	Commands.wait(gs, _db, 60)
	assert_true(gs.world.staged.is_empty())


func test_the_horns_miss_dinner_on_day_39_and_do_not_come_back() -> void:
	var gs := _game_on_day(38)
	gs.player.place("inn_interior", Vector2i(6, 8))  # not at the gate: its fight would start on day 39
	gs.clock.advance(13 * 60)  # 19:00 on day 38: the last dinner
	Commands.wait(gs, _db, 60)
	assert_eq(_npc_area(gs, "calruz"), "inn_interior")
	ToyCanon.sleep_through(gs, _db, 38)
	gs.clock.advance(60)  # 07:00 on day 39: breakfast before the ruins
	Commands.wait(gs, _db, 60)
	assert_eq(_npc_area(gs, "calruz"), "inn_interior")
	gs.clock.advance(12 * 60)  # 19:00: in the ruins
	Commands.wait(gs, _db, 60)
	assert_ne(_npc_area(gs, "calruz"), "inn_interior")
	ToyCanon.sleep_through(gs, _db, 39)
	gs.clock.advance(60)  # 07:00 on day 40
	Commands.wait(gs, _db, 60)
	for npc: String in ["calruz", "ceria_springwalker"]:
		assert_ne(_npc_area(gs, npc), "inn_interior", npc + " is missing")
	assert_false(gs.world.is_alive(_db.canon, "gerial"))


func test_klbkch_walks_his_rounds_again_after_the_rite() -> void:
	var gs := _game_on_day(39)
	assert_false(gs.world.is_alive(_db.canon, "klbkch"))
	ToyCanon.sleep_through(gs, _db, 39)
	gs.clock.advance(3 * 60)  # 09:00 on day 40
	gs.player.place("liscor_gate", GATE_SPOT)
	Commands.settle(gs, _db)
	Commands.wait(gs, _db, 60)
	assert_true(gs.world.is_alive(_db.canon, "klbkch"))
	assert_eq(_npc_area(gs, "klbkch"), "liscor_gate", "on patrol at the east gate")
