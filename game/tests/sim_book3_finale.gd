extends GutTest
## M9.4 on the real Book 3 data (3.21L-3.25). Before dawn on day 82 (3.21L)
## Lyonette smokes the Ashfire Bee nest in its cave and the player can fight
## the bees that wake. Four scenes: the Soldiers paint themselves at the inn
## (day 82), Zel takes a room there (day 84), Erin stages Frozen at the
## Frenzied Hare (day 86) and leaves Celum on the wagon with the Horns (day
## 87). A player who takes part changes each event.
## The game is slept to day 80 once (before_all); each test starts from a
## copy of that save.

const SEED := 20260926
const BEES := "b3.lyonette_smokes_the_ashfire_bees"
const PAINT := "b3.the_soldiers_paint_themselves"
const ZEL := "b3.zel_takes_a_room_at_the_wandering_inn"
const FROZEN := "b3.erin_stages_frozen"
const LEAVE := "b3.erin_leaves_celum_on_the_wagon"
const CAVE_SPOT := Vector2i(4, 11)
const INN_SPOT := Vector2i(12, 12)
const HARE_SPOT := Vector2i(10, 10)
const GATE_SPOT := Vector2i(16, 6)
const HORNS := ["ceria_springwalker", "pisces", "ksmvr", "yvlon_byres"]

var _db: DataDb
var _day81 := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])
	var gs := GameState.new_game(SEED, _db)
	ToyCanon.sleep_through(gs, _db, 80)
	_day81 = gs.to_json()


func _copy(day: int, db: DataDb = null) -> GameState:
	var d := _db if db == null else db
	var gs := GameState.from_json(_day81)
	ToyCanon.sleep_through(gs, d, day - 1)
	assert_eq(gs.clock.day(), day)
	return gs


## Stands at `pos` in `area` and waits (10 minutes a step, up to 20 hours)
## until the event's stage starts. Returns the combat lines seen.
func _wait_for(gs: GameState, db: DataDb, event: String, area: String, pos: Vector2i) -> Array[String]:
	gs.player.place(area, pos)
	Commands.settle(gs, db)
	var lines: Array[String] = gs.combat.lines.duplicate()
	for i in 120:
		if gs.world.staged.has(event):
			break
		assert_true(Commands.wait(gs, db, 600) >= 0, "wait")
		lines.append_array(gs.combat.lines)
	assert_true(gs.world.staged.has(event), "%s is staged" % event)
	return lines


func _count(gs: GameState, types: Array, state: String) -> int:
	return gs.combat.ids().filter(func(id: String) -> bool:
		var m: Dictionary = gs.combat.monsters[id]
		return types.has(m["type"]) and m["state"] == state).size()


func _area_of(gs: GameState, id: String) -> String:
	var n: Dictionary = gs.npcs.npcs.get(id, {})
	return "" if n.is_empty() else String(n["area"])


func _hook_of(gs: GameState, id: String) -> String:
	var entry: Dictionary = gs.world.history.filter(func(h: Dictionary) -> bool: return h["event"] == id)[0]
	return str(entry.get("hook", ""))


func _texts(gs: GameState) -> Array:
	return gs.world.news.map(func(n: Dictionary) -> String: return n["text"])


func _hour(gs: GameState) -> int:
	@warning_ignore("integer_division")
	return gs.clock.minute() / 60


## One turn: hit a hostile monster next to the player, or step toward the
## closest one, or wait.
func _step_toward_a_foe(gs: GameState, db: DataDb) -> void:
	var area := gs.player.area
	var best: Array = []
	for id in gs.combat.ids():
		var m: Dictionary = gs.combat.monsters[id]
		if m["area"] != area or m["state"] != CombatState.HOSTILE:
			continue
		var at := CombatState.pos_of(m)
		var d := at - gs.player.pos()
		if absi(d.x) + absi(d.y) == 1:
			Commands.attack(gs, db, "e" if d.x > 0 else "w" if d.x < 0 else "s" if d.y > 0 else "n")
			return
		var path := Pathfind.path(db.maps, area, gs.player.pos(), Pathfind.around(at), MonsterSim.taken(gs, ""))
		if path["found"] and not (path["steps"] as Array).is_empty() \
				and (best.is_empty() or (path["steps"] as Array).size() < best.size()):
			best = path["steps"]
	if best.is_empty():
		Commands.wait(gs, db, 6)
	else:
		Commands.move(gs, db, best[0])


## Checks that a player hook changed event `id` and the canon still happened.
func _assert_changed(gs: GameState, id: String, hook: String, flag: String, canon_flag: String) -> void:
	assert_eq(gs.world.status(id), Director.CHANGED, id)
	assert_eq(_hook_of(gs, id), hook)
	assert_true(gs.flags.has(flag), flag)
	assert_true(gs.flags.has(canon_flag), "the canon still happens: " + canon_flag)
	assert_true(_texts(gs).has(_db.canon.events[id]["hooks"][0]["news"]), "the hook's news")


func test_the_cave_and_the_stages_are_loaded() -> void:
	assert_true(_db.maps.areas.has("bee_cave"), "the bee cave map")
	assert_true(_db.maps.is_indoor("bee_cave"), "out of the wind")
	var exits: Array = _db.maps.areas["inn_hill"]["exits"]
	assert_eq(exits.filter(func(e: Dictionary) -> bool: return e["to"] == "bee_cave").size(), 1, "a path from the inn hill")
	for id: String in [BEES, PAINT, ZEL, FROZEN, LEAVE]:
		assert_has(_db.canon.stages, id)
	assert_eq(_db.canon.events[BEES]["stage"]["area"], "bee_cave")
	assert_eq(_db.canon.events[BEES]["stage"].get("kind", "fight"), "fight")
	for id: String in [PAINT, ZEL, FROZEN, LEAVE]:
		assert_eq(_db.canon.events[id]["stage"]["kind"], "scene", id)
		for n: Dictionary in _db.canon.events[id]["stage"]["npcs"]:
			assert_true(_db.behaviour.npcs.has(n["npc"]), "%s can be placed by %s" % [n["npc"], id])
	assert_true(_db.behaviour.npcs["zel_shivertail"].has("combat"), "Zel fights")
	for s: Dictionary in _db.combat.spawns:
		assert_ne(s["enemy"], "ashfire_bee", "only a stage brings the bees")


func test_the_bees_wake_in_waves_with_lyonette() -> void:
	var db := DataDb.load_dir()
	ToyCombat.freeze(db)
	var gs := _copy(82, db)
	assert_true(gs.flags.has("lyonette.runs_the_inn"))
	var lines := _wait_for(gs, db, BEES, "bee_cave", CAVE_SPOT)
	var h := _hour(gs)
	assert_true(h >= 3 and h < 8, "before dawn")
	var st: Dictionary = db.canon.events[BEES]["stage"]
	assert_has(lines, st["line"])
	Commands.wait(gs, db, 6)
	assert_eq(_area_of(gs, "lyonette"), "bee_cave", "Lyonette comes in with the smoke")
	assert_true(_count(gs, ["ashfire_bee"], CombatState.HOSTILE) > 0, "bees on the comb")
	for i in 100:
		if not Stage.waves_left(gs, db):
			break
		for id in gs.combat.ids():
			if gs.combat.monsters.has(id) and gs.combat.monsters[id]["state"] == CombatState.HOSTILE:
				Combat.damage_monster(gs, db, id, 999)
		Commands.wait(gs, db, 30)
		lines.append_array(gs.combat.lines)
	assert_false(Stage.waves_left(gs, db), "every wave came")
	for w: Dictionary in st["waves"]:
		assert_has(lines, w["line"])


func test_fighting_the_bees_changes_the_raid() -> void:
	var db := DataDb.load_dir()
	ToyCombat.freeze(db)
	ToyCombat.always_hit(db)
	var gs := _copy(82, db)
	_wait_for(gs, db, BEES, "bee_cave", CAVE_SPOT)
	for i in 4000:
		if not gs.combat.has_fight():
			break
		_step_toward_a_foe(gs, db)
	assert_false(gs.combat.has_fight(), "the waking bees are beaten")
	var melee := gs.action_log.records.filter(func(r: Dictionary) -> bool: return r["action_id"] == "attack_melee")
	assert_true(melee.size() >= 1)
	assert_eq(melee[0]["context"]["enemy"], "ashfire_bee")
	assert_eq(melee[0]["context"]["location"], "giant_bee_cave")
	ToyCanon.sleep_through(gs, db, 82)
	_assert_changed(gs, BEES, "player_raided_the_bee_cave_with_lyonette",
			"bee_cave.earther_helped_lyonette", "lyonette.has_ashfire_honey")
	assert_eq(gs.world.relationship("lyonette", NpcSim.PLAYER), 3)


func test_no_raid_after_sunrise() -> void:
	var gs := _copy(82)
	gs.clock.advance(4 * 60)  # 10:00 on day 82
	gs.player.place("bee_cave", CAVE_SPOT)
	Commands.settle(gs, _db)
	Commands.wait(gs, _db, 60)
	assert_false(gs.world.staged.has(BEES))


func test_mrsha_is_back_at_the_inn() -> void:
	var gs := _copy(83)
	assert_false(gs.flags.has("mrsha.in_selys_care"), "she ran away from Selys")
	assert_true(gs.flags.has("mrsha.at_the_wandering_inn"))


func test_the_soldiers_paint_themselves_at_the_inn() -> void:
	var gs := _copy(82)
	_wait_for(gs, _db, PAINT, "inn_interior", INN_SPOT)
	var h := _hour(gs)
	assert_true(h >= 12 and h < 18, "in the afternoon")
	for npc: String in ["pawn", "lyonette", "mrsha"]:
		assert_eq(_area_of(gs, npc), "inn_interior", npc)
	Commands.wait(gs, _db, 1800)
	assert_eq(_area_of(gs, "pawn"), "inn_interior", "Pawn stays while the scene is live")


func test_painting_with_the_soldiers_changes_the_event() -> void:
	var gs := _copy(82)
	assert_eq(Commands.give(gs, _db, 200), "")
	gs.player.place("inn_interior", INN_SPOT)
	Commands.settle(gs, _db)
	assert_true(ToyMaps.walk_next_to(gs, _db, "inn_counter"), "walk to the counter")
	assert_eq(Commands.interact(gs, _db, "inn_counter", "buy_supplies")["error"], "")
	ToyCanon.sleep_through(gs, _db, 82)
	_assert_changed(gs, PAINT, "player_painted_with_the_soldiers",
			"wandering_inn.earther_saw_the_painted_soldiers", "mrsha.at_the_wandering_inn")
	assert_eq(gs.world.relationship("pawn", NpcSim.PLAYER), 2)


func test_zel_takes_a_room_and_stays() -> void:
	var gs := _copy(84)
	_wait_for(gs, _db, ZEL, "inn_interior", INN_SPOT)
	var h := _hour(gs)
	assert_true(h >= 18 and h < 23, "in the evening")
	for npc: String in ["zel_shivertail", "lyonette", "mrsha"]:
		assert_eq(_area_of(gs, npc), "inn_interior", npc)
	ToyCanon.sleep_through(gs, _db, 84)
	assert_true(gs.flags.has("zel.at_wandering_inn"))
	gs.player.place("inn_interior", INN_SPOT)
	Commands.settle(gs, _db)
	for i in 12:
		if _area_of(gs, "zel_shivertail") == "inn_interior":
			break
		Commands.wait(gs, _db, 600)
	assert_eq(_area_of(gs, "zel_shivertail"), "inn_interior", "Zel eats breakfast at the inn")


func test_meeting_zel_changes_the_event() -> void:
	var gs := _copy(84)
	gs.player.place("inn_interior", INN_SPOT)
	Commands.settle(gs, _db)
	assert_true(ToyMaps.walk_next_to(gs, _db, "chess_table"), "walk to the chessboard")
	assert_eq(Commands.interact(gs, _db, "chess_table", "play_chess")["error"], "")
	ToyCanon.sleep_through(gs, _db, 84)
	_assert_changed(gs, ZEL, "player_met_zel_at_the_inn", "wandering_inn.earther_met_zel", "zel.at_wandering_inn")
	assert_eq(gs.world.relationship("zel_shivertail", NpcSim.PLAYER), 2)


func test_the_horns_are_back_in_celum() -> void:
	var gs := _copy(86)
	assert_true(gs.flags.has("horns_of_hammerad.in_celum"))
	assert_false(gs.flags.has("horns_of_hammerad.gone_to_albez"), "back from Albez at last")
	assert_true(gs.flags.has("toren.link_severed"))


func test_erin_stages_frozen_with_jasi_and_ceria() -> void:
	var gs := _copy(86)
	_wait_for(gs, _db, FROZEN, "celum_frenzied_hare", HARE_SPOT)
	var h := _hour(gs)
	assert_true(h >= 19 and h < 23, "in the evening")
	for npc: String in ["erin_solstice", "jasi", "ceria_springwalker"]:
		assert_eq(_area_of(gs, npc), "celum_frenzied_hare", npc)


func test_watching_frozen_changes_the_event() -> void:
	var gs := _copy(86)
	gs.player.place("celum_frenzied_hare", HARE_SPOT)
	Commands.settle(gs, _db)
	assert_true(ToyMaps.walk_next_to(gs, _db, "hare_table_east"), "walk to a table")
	assert_eq(Commands.interact(gs, _db, "hare_table_east", "talk_with_guest")["error"], "")
	ToyCanon.sleep_through(gs, _db, 86)
	_assert_changed(gs, FROZEN, "player_watched_frozen", "frenzied_hare.earther_saw_frozen", "erin.in_celum")
	assert_eq(gs.world.relationship("ceria_springwalker", NpcSim.PLAYER), 2)


func test_erin_leaves_celum_with_the_horns() -> void:
	var gs := _copy(87)
	_wait_for(gs, _db, LEAVE, "celum_gate", GATE_SPOT)
	var h := _hour(gs)
	assert_true(h >= 17 and h < 20, "in the evening")
	assert_eq(_area_of(gs, "erin_solstice"), "celum_gate")
	for npc: String in HORNS:
		assert_eq(_area_of(gs, npc), "celum_gate", npc)
	ToyCanon.sleep_through(gs, _db, 87)
	assert_true(gs.flags.has("erin.left_celum"))
	assert_true(gs.flags.has("erin.has_albez_door"))
	assert_false(gs.flags.has("erin.in_celum"))
	assert_false(gs.flags.has("horns_of_hammerad.in_celum"))
	for i in 3:
		Commands.wait(gs, _db, 3600)
	assert_true(BehaviourDb.is_off_map(_area_of(gs, "erin_solstice")), "Erin is on the road, off the map")


func test_seeing_erin_off_changes_the_event() -> void:
	var gs := _copy(87)
	_wait_for(gs, _db, LEAVE, "celum_gate", GATE_SPOT)
	var r := Commands.interact(gs, _db, "erin_solstice", "talk_with_guest")
	assert_eq(r["error"], "")
	assert_eq(r["record"]["context"]["location"], "celum")
	ToyCanon.sleep_through(gs, _db, 87)
	_assert_changed(gs, LEAVE, "player_saw_erin_off", "celum.earther_saw_erin_off", "erin.left_celum")
	assert_true(gs.world.relationship("erin_solstice", NpcSim.PLAYER) >= 2)
