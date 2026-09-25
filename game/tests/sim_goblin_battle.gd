extends GutTest
## M7.3 canon fight on the real Book 1 data: on the morning of day 35 a
## feathered Goblin tribe attacks Rags's band in a Floodplains valley (1.52R).
## Rags and her line come at once, her flankers a minute later. A win next to
## Rags changes the event (she trusts the player); a knock-out leaves the
## canon. Also the M7.3 schedules: the Horns lodge at the inn, and Pawn stays
## away while Ksmvr holds him.

const BATTLE_EVENT := "b1.rags_kills_the_feathered_chieftain"
const VALLEY_SPOT := Vector2i(16, 11)

var _db: DataDb


func before_each() -> void:
	_db = DataDb.load_dir()


## A new game (day 8) that has slept until the morning of `day`.
func _game_on_day(day: int, seed_value: int = 1) -> GameState:
	var gs := GameState.new_game(seed_value, _db)
	ToyCanon.sleep_through(gs, _db, day - 1)
	assert_eq(gs.clock.day(), day)
	return gs


## Day 35 at 08:00 in the valley: the battle starts. Returns the foes' ids.
func _battle_starts(gs: GameState) -> Array[String]:
	gs.clock.advance(2 * 60)  # 08:00
	gs.player.place("floodplains_south", VALLEY_SPOT)
	Commands.settle(gs, _db)
	var lines: Array[String] = gs.combat.lines.duplicate()
	for i in 20:
		if not gs.world.staged.is_empty():
			break
		assert_true(Commands.wait(gs, _db, 6) >= 0, "wait")
		lines.append_array(gs.combat.lines)
	assert_eq(gs.world.staged, {BATTLE_EVENT: 35})
	var st: Dictionary = _db.canon.events[BATTLE_EVENT]["stage"]
	assert_has(lines, st["line"])
	assert_has(lines, st["waves"][0]["line"], "Rags's line comes at once")
	var out: Array[String] = []
	for id in gs.combat.ids():
		var m: Dictionary = gs.combat.monsters[id]
		if m["stage"] == BATTLE_EVENT and m["state"] != CombatState.ALLY:
			out.append(id)
	return out


## One turn: hit a stage foe next to the player, or step toward the closest
## one, or wait.
func _step_toward_a_foe(gs: GameState) -> void:
	var best: Array = []
	for id in gs.combat.ids():
		var m: Dictionary = gs.combat.monsters[id]
		if m["area"] != "floodplains_south" or m["state"] != CombatState.HOSTILE:
			continue
		var at := CombatState.pos_of(m)
		var d := at - gs.player.pos()
		if absi(d.x) + absi(d.y) == 1:
			Commands.attack(gs, _db, "e" if d.x > 0 else "w" if d.x < 0 else "s" if d.y > 0 else "n")
			return
		var path := Pathfind.path(_db.maps, "floodplains_south", gs.player.pos(), Pathfind.around(at),
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


func _npc_area(gs: GameState, npc: String) -> String:
	return str(gs.npcs.npcs[npc]["area"])


func test_the_battle_stage_data_is_sound() -> void:
	assert_eq(_db.errors, [] as Array[String])
	assert_has(_db.canon.stages, BATTLE_EVENT)
	var st: Dictionary = _db.canon.events[BATTLE_EVENT]["stage"]
	assert_eq(st["area"], "floodplains_south")
	assert_eq(st["foes"][0]["enemy"], "goblin_feathered_chieftain")
	assert_eq(st["waves"][0]["allies"], ["rags"])
	assert_true(_db.behaviour.npcs["rags"].has("combat"), "Rags can fight")
	var chief: Dictionary = _db.combat.enemies["goblin_feathered_chieftain"]
	var grunt: Dictionary = _db.combat.enemies["goblin_grunt"]
	var crab: Dictionary = _db.combat.enemies["rock_crab"]
	assert_gt(float(chief["danger"]), float(grunt["danger"]), "the chieftain names the fight's records")
	assert_gt(float(chief["danger"]), float(crab["danger"]), "even if a Rock Crab joins in")
	assert_eq(float(chief["flee_below"]), 0.0, "canon: he dies in the fight")
	for s: Dictionary in _db.combat.spawns:
		assert_ne(s["enemy"], "goblin_feathered_chieftain", "only the stage brings him")


func test_winning_beside_rags_wins_her_trust() -> void:
	ToyCombat.freeze(_db)
	ToyCombat.always_hit(_db)
	var gs := _game_on_day(35)
	var foes := _battle_starts(gs)
	assert_eq(foes.size(), 5)
	assert_eq(_npc_area(gs, "rags"), "floodplains_south", "Rags leads her line")
	assert_eq(gs.combat.in_state(CombatState.ALLY).size(), 3, "her line")
	for i in 900:
		if not gs.combat.has_fight():
			break
		_step_toward_a_foe(gs)
	assert_false(gs.combat.has_fight(), "the feathered tribe is beaten")
	var melee := _records(gs, "attack_melee")
	assert_eq(melee.size(), 1)
	assert_eq(melee[0]["outcome"], "success")
	assert_eq(melee[0]["context"]["enemy"], "goblin_feathered_chieftain")

	ToyCanon.sleep_through(gs, _db, 35)
	assert_eq(gs.world.status(BATTLE_EVENT), Director.CHANGED)
	var entry: Dictionary = gs.world.history.filter(func(h: Dictionary) -> bool:
		return h["event"] == BATTLE_EVENT)[0]
	assert_eq(entry["hook"], "player_fought_beside_rags")
	assert_true(gs.flags.has("rags.earther_fought_beside_her"))
	assert_true(gs.flags.has("rags.killed_rival_chieftain"), "canon effects still apply")
	assert_eq(gs.world.relationship("rags", NpcSim.PLAYER), 2)
	var texts := gs.world.news.map(func(n: Dictionary) -> String: return n["text"])
	assert_true(texts.has(_db.canon.events[BATTLE_EVENT]["hooks"][0]["news"]))
	assert_false(texts.has(_db.canon.events[BATTLE_EVENT]["news"]))
	assert_eq(gs.world.status("b1.rags_band_chases_ryoka"), Director.DONE, "then her band still chases Ryoka")


func test_losing_the_battle_leaves_the_canon() -> void:
	var gs := _game_on_day(35, 3)
	var foes := _battle_starts(gs)
	var chief := ""
	for id in foes:
		if gs.combat.monsters[id]["type"] == "goblin_feathered_chieftain":
			chief = id
	assert_ne(chief, "")
	gs.player.place("floodplains_south", CombatState.pos_of(gs.combat.monsters[chief]) + Vector2i(0, -1))
	Combat.set_hp(gs, _db, 1)
	for i in 200:
		if Combat.is_down(gs) or not gs.combat.has_fight():
			break
		Commands.block(gs, _db)
	assert_true(Combat.is_down(gs), "knocked out")
	Commands.sleep(gs, _db, Rest.ANYWHERE)
	ToyCanon.sleep_through(gs, _db, 35)
	assert_eq(gs.world.status(BATTLE_EVENT), Director.DONE)
	assert_false(gs.flags.has("rags.earther_fought_beside_her"))
	assert_eq(gs.world.relationship("rags", NpcSim.PLAYER), 0)


func test_no_battle_the_day_before() -> void:
	var gs := _game_on_day(34)
	gs.clock.advance(3 * 60)  # 09:00 on day 34
	gs.player.place("floodplains_south", VALLEY_SPOT)
	Commands.settle(gs, _db)
	Commands.wait(gs, _db, 60)
	assert_true(gs.world.staged.is_empty())


func test_the_horns_lodge_at_the_inn_from_night_35() -> void:
	var gs := _game_on_day(35)
	gs.clock.advance(13 * 60)  # 19:00 on day 35: not here yet
	Commands.wait(gs, _db, 60)
	assert_ne(_npc_area(gs, "calruz"), "inn_interior")
	ToyCanon.sleep_through(gs, _db, 35)
	gs.clock.advance(60)  # 07:00 on day 36: breakfast
	Commands.wait(gs, _db, 60)
	for npc: String in ["calruz", "ceria_springwalker", "gerial", "sostrom"]:
		assert_eq(_npc_area(gs, npc), "inn_interior", npc)
	gs.clock.advance(4 * 60)  # 11:00: out in the city
	Commands.wait(gs, _db, 60)
	assert_ne(_npc_area(gs, "calruz"), "inn_interior")


func test_pawn_stays_away_while_ksmvr_holds_him() -> void:
	var gs := _game_on_day(34)
	gs.clock.advance(13 * 60)  # 19:00 on day 34
	Commands.wait(gs, _db, 60)
	assert_eq(_npc_area(gs, "pawn"), "inn_interior", "chess night as usual")
	ToyCanon.sleep_through(gs, _db, 35)
	assert_true(gs.flags.has("pawn.taken_for_judgment"))
	gs.clock.advance(13 * 60)  # 19:00 on day 36
	Commands.wait(gs, _db, 60)
	assert_ne(_npc_area(gs, "pawn"), "inn_interior")
