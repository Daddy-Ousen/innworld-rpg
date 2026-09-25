extends GutTest
## M8.1 canon fight on the real data, the afternoon of day 42 (2.04-2.05).
## Outside the Ruins Gazi of Reim stabs Zevara and fights the Watch; Relc,
## Klbkch, Ksmvr, Erin and guardsmen come at once, Krshia's Gnolls later.
## Gazi cannot die: hurt badly, she escapes through her portal (enemy
## "escape"). A player who fights her until she is gone changes the event;
## Erin still takes her eye. A knock-out keeps the canon.

const EVENT := "b2.gazi_attacks_outside_the_ruins"
const SPOT := Vector2i(12, 11)

var _db: DataDb


func before_each() -> void:
	_db = DataDb.load_dir()


## A new game (day 8) that has slept until the morning of `day`.
func _game_on_day(day: int, seed_value: int = 1) -> GameState:
	var gs := GameState.new_game(seed_value, _db)
	ToyCanon.sleep_through(gs, _db, day - 1)
	assert_eq(gs.clock.day(), day)
	return gs


## From `hour` on this day at the Ruins: waits until the event stages.
## Returns the combat lines seen.
func _stage_starts(gs: GameState, hour: int) -> Array[String]:
	gs.clock.advance((hour - 6) * 60)
	gs.player.place("ruins_entrance", SPOT)
	Commands.settle(gs, _db)
	var lines: Array[String] = gs.combat.lines.duplicate()
	for i in 20:
		if gs.world.staged.has(EVENT):
			break
		assert_true(Commands.wait(gs, _db, 6) >= 0, "wait")
		lines.append_array(gs.combat.lines)
	assert_true(gs.world.staged.has(EVENT), "Gazi comes")
	return lines


func _gazi(gs: GameState) -> String:
	for id in gs.combat.ids():
		if gs.combat.monsters[id]["type"] == "gazi_of_reim":
			return id
	return ""


## One turn: hit Gazi when she is next to the player, else step toward her.
func _step_toward_gazi(gs: GameState) -> void:
	var id := _gazi(gs)
	if id == "":
		Commands.wait(gs, _db, 6)
		return
	var at := CombatState.pos_of(gs.combat.monsters[id])
	var d := at - gs.player.pos()
	if absi(d.x) + absi(d.y) == 1:
		Commands.attack(gs, _db, "e" if d.x > 0 else "w" if d.x < 0 else "s" if d.y > 0 else "n")
		return
	var path := Pathfind.path(_db.maps, gs.player.area, gs.player.pos(), Pathfind.around(at), MonsterSim.taken(gs, ""))
	if path["found"] and not (path["steps"] as Array).is_empty():
		Commands.move(gs, _db, path["steps"][0])
	else:
		Commands.wait(gs, _db, 6)


## Puts the player on a free tile beside Gazi (the allies are quick).
func _next_to_gazi(gs: GameState) -> void:
	var at := CombatState.pos_of(gs.combat.monsters[_gazi(gs)])
	var taken := MonsterSim.taken(gs, "")
	for off: Vector2i in [Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1)]:
		if _db.maps.is_walkable("ruins_entrance", at + off) and not taken.has(at + off):
			gs.player.place("ruins_entrance", at + off)
			return
	fail_test("no free tile beside Gazi")


func _records(gs: GameState, action_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for r: Dictionary in gs.action_log.records:
		if r["action_id"] == action_id:
			out.append(r)
	return out


func _lines_of(gs: GameState, steps: int) -> Array[String]:
	var lines: Array[String] = []
	for i in steps:
		if not gs.combat.has_fight():
			break
		_step_toward_gazi(gs)
		lines.append_array(gs.combat.lines)
	return lines


func _hook_of(gs: GameState, id: String) -> String:
	var entry: Dictionary = gs.world.history.filter(func(h: Dictionary) -> bool: return h["event"] == id)[0]
	return str(entry.get("hook", ""))


func test_the_ruins_stage_data_is_sound() -> void:
	assert_eq(_db.errors, [] as Array[String])
	assert_has(_db.canon.stages, EVENT)
	var st: Dictionary = _db.canon.events[EVENT]["stage"]
	assert_eq(st["area"], "ruins_entrance")
	assert_eq(st["foes"].size(), 1)
	assert_eq(st["foes"][0]["enemy"], "gazi_of_reim")
	var gazi: Dictionary = _db.combat.enemies["gazi_of_reim"]
	assert_true(gazi.has("escape"), "she cannot die")
	assert_eq(float(gazi["danger"]), 1.0, "the fight's records name her")
	for npc: String in ["relc", "klbkch", "ksmvr", "erin_solstice", "krshia"]:
		assert_true(_db.behaviour.npcs.has(npc), npc + " can be a stage ally")
		assert_true(_db.behaviour.npcs[npc].has("combat"), npc + " has a combat block")
	for s: Dictionary in _db.combat.spawns:
		assert_false(["gazi_of_reim", "liscor_guardsman", "gnoll_hunter"].has(s["enemy"]),
				"only a stage brings " + str(s["enemy"]))
	var exits: Array = _db.maps.areas["floodplains_south"]["exits"]
	assert_true(exits.any(func(x: Dictionary) -> bool: return x["to"] == "ruins_entrance"), "the Floodplains lead there")
	assert_eq(_db.maps.areas["ruins_entrance"]["location"], "liscor_dungeon")


func test_an_escaping_foe_never_dies() -> void:
	var gs := GameState.new_game(1, _db)
	gs.player.place("ruins_entrance", SPOT)
	var id := Combat.add_monster(gs, _db, "gazi_of_reim", SPOT + Vector2i(1, 0))
	Combat.join(gs, id)
	assert_false(Combat.damage_monster(gs, _db, id, 10), "hurt, not gone")
	assert_true(gs.combat.monsters.has(id))
	assert_false(Combat.damage_monster(gs, _db, id, 999), "no kill")
	assert_false(gs.combat.monsters.has(id), "she stepped through her portal")
	assert_has(gs.combat.lines, _db.combat.enemies["gazi_of_reim"]["escape"]["line"])
	assert_eq(int(gs.combat.fight["routed"]), 1)
	assert_eq(int(gs.combat.fight["kills"]), 0)


func test_fighting_gazi_off_changes_the_event() -> void:
	ToyCombat.freeze(_db)
	ToyCombat.always_hit(_db)
	var gs := _game_on_day(42)
	var lines := _stage_starts(gs, 13)
	var st: Dictionary = _db.canon.events[EVENT]["stage"]
	assert_has(lines, st["line"])
	assert_has(lines, st["waves"][0]["line"], "the Watch comes at once")
	for npc: String in ["relc", "klbkch", "ksmvr", "erin_solstice"]:
		assert_eq(str(gs.npcs.npcs[npc]["area"]), "ruins_entrance", npc)
	_next_to_gazi(gs)
	lines = _lines_of(gs, 3000)
	assert_false(gs.combat.has_fight(), "the fight ends")
	assert_has(lines, _db.combat.enemies["gazi_of_reim"]["escape"]["line"])
	var melee := _records(gs, "attack_melee")
	assert_eq(melee.size(), 1)
	assert_eq(melee[0]["outcome"], "success")
	assert_eq(melee[0]["context"]["enemy"], "gazi_of_reim")
	assert_eq(melee[0]["context"]["location"], "liscor_dungeon")
	assert_false(melee[0]["context"]["killed"], "nobody killed her")

	ToyCanon.sleep_through(gs, _db, 42)
	assert_eq(gs.world.status(EVENT), Director.CHANGED)
	assert_eq(_hook_of(gs, EVENT), "player_fought_gazi")
	assert_true(gs.flags.has("liscor.earther_fought_gazi"))
	assert_true(gs.flags.has("gazi.lost_an_eye"), "Erin still takes her eye")
	assert_true(gs.world.is_alive(_db.canon, "gazi_pathseeker"))
	assert_eq(gs.world.relationship("erin_solstice", NpcSim.PLAYER), 3)
	assert_eq(gs.world.relationship("krshia", NpcSim.PLAYER), 2)
	var texts := gs.world.news.map(func(n: Dictionary) -> String: return n["text"])
	assert_true(texts.has(_db.canon.events[EVENT]["hooks"][0]["news"]))


func test_a_knock_out_keeps_the_canon() -> void:
	var gs := _game_on_day(42, 3)
	_stage_starts(gs, 13)
	var id := _gazi(gs)
	assert_ne(id, "")
	gs.player.place("ruins_entrance", CombatState.pos_of(gs.combat.monsters[id]) + Vector2i(0, 1))
	Combat.set_hp(gs, _db, 1)
	for i in 300:
		if Combat.is_down(gs) or not gs.combat.has_fight():
			break
		Commands.block(gs, _db)
	assert_true(Combat.is_down(gs), "knocked out")
	Commands.sleep(gs, _db, Rest.ANYWHERE)
	ToyCanon.sleep_through(gs, _db, 42)
	assert_eq(gs.world.status(EVENT), Director.DONE)
	assert_false(gs.flags.has("liscor.earther_fought_gazi"))
	assert_true(gs.flags.has("gazi.gone_to_reim"))


func test_no_gazi_the_day_before() -> void:
	var gs := _game_on_day(41)
	gs.clock.advance(8 * 60)  # 14:00 on day 41
	gs.player.place("ruins_entrance", SPOT)
	Commands.settle(gs, _db)
	Commands.wait(gs, _db, 60)
	assert_true(gs.world.staged.is_empty())
