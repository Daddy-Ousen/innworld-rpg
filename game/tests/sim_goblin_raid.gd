extends GutTest
## M7.1 canon fight on the real Book 1 data: the Goblin raid on the inn at
## midday on day 21 (1.29). A win next to Erin changes the event (Klbkch
## still dies, user choice 2026-09-24); a knock-out leaves the canon.
## M7.B: 40 Goblins in 4 waves; Klbkch and the Designated Worker come with
## wave 2, Rags and three helpers with wave 3.

const RAID_EVENT := "b1.klbkch_dies_defending_erin"
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


## Day 21 in the inn: waits until the raiders come in. Returns their ids.
func _raid_arrives(gs: GameState) -> Array[String]:
	gs.player.place("inn_interior", INN_SPOT)
	Commands.settle(gs, _db)
	var lines: Array[String] = []
	for i in 480:
		if not gs.world.staged.is_empty():
			break
		assert_true(Commands.wait(gs, _db, 60) >= 0, "wait")
		lines.append_array(gs.combat.lines)
	assert_eq(gs.world.staged, {RAID_EVENT: 21})
	assert_eq(gs.clock.minute(), 12 * 60, "they come at 12:00")
	assert_has(lines, _db.canon.events[RAID_EVENT]["stage"]["line"])
	var out: Array[String] = []
	for id in gs.combat.ids():
		if gs.combat.monsters[id]["stage"] == RAID_EVENT:
			out.append(id)
	return out


## One turn: hit a raider next to the player, or step toward the raider
## with the shortest free path (they stand close together), or wait.
func _step_toward_a_raider(gs: GameState) -> void:
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


func test_the_raid_stage_data_is_sound() -> void:
	assert_eq(_db.errors, [] as Array[String])
	assert_has(_db.canon.stages, RAID_EVENT)
	var st: Dictionary = _db.canon.events[RAID_EVENT]["stage"]
	var foes: Array = st["foes"]
	assert_eq(foes.size(), 8)
	assert_eq(foes.filter(func(f: Dictionary) -> bool: return f["enemy"] == "goblin_raid_leader").size(), 1)
	var total := foes.size()
	for w: Dictionary in st["waves"]:
		total += (w["foes"] as Array).size()
	assert_eq(st["waves"].size(), 3)
	assert_eq(total, 40, "canon: about forty Goblins")
	assert_eq(st["waves"][1]["allies"], ["klbkch", "designated_worker"])
	assert_has(st["waves"][2]["allies"], "rags")
	assert_eq((st["waves"][2]["helpers"] as Array).size(), 3, "Rags's band")
	var e: Dictionary = _db.combat.enemies["goblin_raid_leader"]
	assert_has(e["tags"], "goblin")
	assert_gt(float(e["danger"]), float(_db.combat.enemies["goblin_grunt"]["danger"]),
			"the leader names the fight's records")
	for s: Dictionary in _db.combat.spawns:
		assert_ne(s["enemy"], "goblin_raid_leader", "only a stage brings him")


func test_winning_the_raid_with_erin_changes_it_but_klbkch_still_dies() -> void:
	ToyCombat.freeze(_db)
	ToyCombat.always_hit(_db)
	var gs := _game_on_day(21)
	var raiders := _raid_arrives(gs)
	assert_eq(raiders.size(), 8)
	assert_eq(Stage.foes_left(gs, _db), 40)
	assert_eq(gs.npcs.npcs["erin_solstice"]["area"], "inn_interior", "Erin is home")
	var lines: Array[String] = []
	var klbkch_came := false
	var most_foes := 0
	for i in 3000:
		if not gs.combat.has_fight():
			break
		_step_toward_a_raider(gs)
		lines.append_array(gs.combat.lines)
		most_foes = maxi(most_foes, gs.combat.in_state(CombatState.HOSTILE).size())
		if gs.npcs.npcs.has("klbkch") and gs.npcs.npcs["klbkch"]["area"] == "inn_interior":
			klbkch_came = true
	assert_false(gs.combat.has_fight(), "all 40 beaten")
	assert_true(gs.combat.stage_run.is_empty())
	assert_true(klbkch_came, "Klbkch came with wave 2")
	assert_has(lines, _db.canon.events[RAID_EVENT]["stage"]["waves"][2]["line"])
	assert_lte(most_foes, 23, "never all forty at once: a wave waits while 12 are on the map")
	assert_true(lines.any(func(l: String) -> bool: return l.begins_with("Erin Solstice hits")),
			"Erin fights next to the player")
	assert_true(lines.any(func(l: String) -> bool: return l.begins_with("Klbkch hits")), "Klbkch fights")
	assert_true(gs.combat.in_state(CombatState.ALLY).is_empty(), "the helpers left")
	var melee := _records(gs, "attack_melee")
	assert_eq(melee.size(), 1)
	assert_eq(melee[0]["outcome"], "success")
	assert_eq(melee[0]["context"]["enemy"], "goblin_raid_leader")

	ToyCanon.sleep_through(gs, _db, 21)
	assert_eq(gs.world.status(RAID_EVENT), Director.CHANGED)
	var entry: Dictionary = gs.world.history.filter(func(h: Dictionary) -> bool:
		return h["event"] == RAID_EVENT)[0]
	assert_eq(entry["by"], Director.BY_PLAYER)
	assert_eq(entry["hook"], "player_fought_raid")
	assert_false(gs.world.is_alive(_db.canon, "klbkch"), "Klbkch still dies (user choice)")
	assert_true(gs.flags.has("klbkch.died_saving_erin"))
	assert_true(gs.flags.has("wandering_inn.earther_fought_raid"))
	assert_false(gs.flags.has("erin.stabbed_by_goblins"), "Erin was not stabbed")
	assert_eq(gs.world.relationship("erin_solstice", NpcSim.PLAYER), 3)
	var texts := gs.world.news.map(func(n: Dictionary) -> String: return n["text"])
	assert_true(texts.has(_db.canon.events[RAID_EVENT]["hooks"][0]["news"]))
	assert_false(texts.has(_db.canon.events[RAID_EVENT]["news"]))
	# The rest of day 21 runs as canon: the Queen, the Watch, Pawn.
	for id: String in ["b1.free_queen_blames_erin", "b1.watch_abandons_the_inn", "b1.pawn_becomes_himself",
			"b1.erin_beats_the_hive_mind"]:
		assert_eq(gs.world.status(id), Director.DONE, id)


func test_losing_the_raid_leaves_the_canon() -> void:
	var gs := _game_on_day(21, 3)
	_raid_arrives(gs)
	Combat.set_hp(gs, _db, 1)
	for i in 200:
		if Combat.is_down(gs):
			break
		Commands.block(gs, _db)
	assert_true(Combat.is_down(gs), "knocked out")
	Commands.sleep(gs, _db, Rest.ANYWHERE)
	ToyCanon.sleep_through(gs, _db, 21)
	assert_eq(gs.world.status(RAID_EVENT), Director.DONE)
	assert_false(gs.flags.has("wandering_inn.earther_fought_raid"), "canon: Erin fought alone")
	assert_true(gs.flags.has("erin.stabbed_by_goblins"))
	assert_eq(gs.world.relationship("erin_solstice", NpcSim.PLAYER), 0)


func test_no_raid_after_the_hours() -> void:
	var gs := _game_on_day(21)
	gs.player.place("inn_interior", INN_SPOT)
	Commands.settle(gs, _db)
	gs.clock.advance(8 * 60)  # 14:00: past the stage hours
	Commands.wait(gs, _db, 60)
	assert_true(gs.world.staged.is_empty())
	ToyCanon.sleep_through(gs, _db, 21)
	assert_eq(gs.world.status(RAID_EVENT), Director.DONE)


func test_no_patrols_bring_monsters_near_the_inn() -> void:
	var gs := _game_on_day(21)
	var spawn: Dictionary = _db.combat.spawns.filter(func(s: Dictionary) -> bool:
		return s["id"] == "crab_hill_unpatrolled")[0]
	assert_false(MonsterSim.spawn_open(gs, spawn), "the Watch still patrols on day 21")
	ToyCanon.sleep_through(gs, _db, 21)
	gs.clock.advance(6 * 60)  # 12:00 on day 22
	assert_true(gs.flags.has("liscor_watch.no_inn_patrols"))
	assert_true(MonsterSim.spawn_open(gs, spawn), "from day 22 the spawn may roll")
