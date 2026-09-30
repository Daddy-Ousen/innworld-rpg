extends GutTest
## M13.7 on the real Book 5 data (4.28 – 4.31, days 111–114). Two scenes and
## a fight: Brunkr's feast at the inn (day 111 evening), 'Regrika Blackpaw'
## turns on Griffon Hunt in the common room and escapes to Celum (day 112
## night), and the pyres for Brunkr and Ulrien below the inn (day 113 night).
## A player who joins in changes each event. After day 114 Ryoka, Lyonette and
## Mrsha are gone from the inn.
## The game is slept to the morning of day 111 once (before_all); each test
## starts from a copy of that save.

const SEED := 20260928
const DAY := 111
const FEAST := "b5.zzzzf_brunkrs_feast_at_the_inn"
const FIGHT := "b5.zzzzq_regrika_kills_ulrien_in_the_inn"
const PYRES := "b5.zzzzz_liscor_burns_brunkr_and_ulrien"
const INN_SPOT := Vector2i(10, 10)
const HILL_SPOT := Vector2i(15, 13)

var _db: DataDb
var _day111 := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])
	var gs := GameState.new_game(SEED, _db)
	ToyCanon.sleep_through(gs, _db, DAY - 1)
	_day111 = gs.to_json()


func _copy(day: int, db: DataDb = null) -> GameState:
	var d := _db if db == null else db
	var gs := GameState.from_json(_day111)
	ToyCanon.sleep_through(gs, d, day - 1)
	assert_eq(gs.clock.day(), day)
	return gs


## Stands at `pos` in `area` and waits (10 minutes a step, up to 20 hours)
## until the event's stage starts.
func _wait_for(gs: GameState, db: DataDb, event: String, area: String, pos: Vector2i) -> void:
	gs.player.place(area, pos)
	Commands.settle(gs, db)
	for i in 120:
		if gs.world.staged.has(event):
			break
		assert_true(Commands.wait(gs, db, 600) >= 0, "wait")
	assert_true(gs.world.staged.has(event), "%s is staged" % event)


## Waits in the inn until `hour` (bounded: M13.6 trap).
func _wait_indoors_until(gs: GameState, db: DataDb, hour: int) -> void:
	gs.player.place("inn_interior", INN_SPOT)
	Commands.settle(gs, db)
	for i in 48:
		if _hour(gs) >= hour:
			break
		assert_true(Commands.wait(gs, db, 1800) >= 0, "wait")
	assert_true(_hour(gs) >= hour, "it is %d:00" % hour)


func _area_of(gs: GameState, id: String) -> String:
	var n: Dictionary = gs.npcs.npcs.get(id, {})
	return "" if n.is_empty() else String(n["area"])


func _hour(gs: GameState) -> int:
	@warning_ignore("integer_division")
	return gs.clock.minute() / 60


func _hook_of(gs: GameState, id: String) -> String:
	var entry: Dictionary = gs.world.history.filter(func(h: Dictionary) -> bool: return h["event"] == id)[0]
	return str(entry.get("hook", ""))


func _assert_changed(gs: GameState, id: String, hook: String, flag: String, canon_flag: String) -> void:
	assert_eq(gs.world.status(id), Director.CHANGED, id)
	assert_eq(_hook_of(gs, id), hook)
	assert_true(gs.flags.has(flag), flag)
	assert_true(gs.flags.has(canon_flag), "the canon still happens: " + canon_flag)
	var texts := gs.world.news.map(func(n: Dictionary) -> String: return n["text"])
	assert_true(texts.has(_db.canon.events[id]["hooks"][0]["news"]), "the hook's news")


## Walks next to `npc` and runs `action` with them.
func _do_with(gs: GameState, npc: String, action: String, location: String) -> void:
	var n: Dictionary = gs.npcs.npcs[npc]
	var at := Vector2i(int(n["x"]), int(n["y"]))
	var sides := {at + Vector2i(1, 0): true, at + Vector2i(-1, 0): true, at + Vector2i(0, 1): true, at + Vector2i(0, -1): true}
	if not sides.has(gs.player.pos()):
		assert_true(ToyMaps.walk_to(gs, _db, sides), "walk to " + npc)
	var r := Commands.interact(gs, _db, npc, action)
	assert_eq(r["error"], "")
	assert_eq(r["record"]["context"]["location"], location)


func _stage_foes(gs: GameState, event: String) -> Array:
	return gs.combat.ids().filter(func(id: String) -> bool:
		var m: Dictionary = gs.combat.monsters[id]
		return m["state"] == CombatState.HOSTILE and m.get("stage", "") == event)


## One step toward the stage foe, or a blow when next to it. Walks to the four
## side squares only (a diagonal square never attacks).
func _fight_turn(gs: GameState, db: DataDb, event: String) -> void:
	var foes := _stage_foes(gs, event)
	if foes.is_empty():
		Commands.wait(gs, db, 6)
		return
	var at := CombatState.pos_of(gs.combat.monsters[foes[0]])
	var d := at - gs.player.pos()
	if absi(d.x) + absi(d.y) == 1:
		FightBot.attack(gs, db, "e" if d.x > 0 else "w" if d.x < 0 else "s" if d.y > 0 else "n")
		return
	var sides := {at + Vector2i(1, 0): true, at + Vector2i(-1, 0): true, at + Vector2i(0, 1): true, at + Vector2i(0, -1): true}
	var path := Pathfind.path(db.maps, gs.player.area, gs.player.pos(), sides, MonsterSim.taken(gs, ""))
	if path["found"] and not (path["steps"] as Array).is_empty():
		FightBot.move(gs, db, path["steps"][0])
	else:
		Commands.wait(gs, db, 6)


func _frozen_db() -> DataDb:
	var db := DataDb.load_dir()
	ToyCombat.freeze(db)
	ToyCombat.always_hit(db)
	return db


func test_the_stages_are_loaded() -> void:
	assert_eq(_db.canon.events[FEAST]["stage"]["area"], "inn_interior")
	assert_eq(_db.canon.events[FIGHT]["stage"]["area"], "inn_interior")
	assert_eq(_db.canon.events[PYRES]["stage"]["area"], "inn_hill")
	for id: String in [FEAST, FIGHT, PYRES]:
		assert_has(_db.canon.stages, id)
	for id: String in [FEAST, PYRES]:
		var st: Dictionary = _db.canon.events[id]["stage"]
		assert_eq(st["kind"], "scene", id)
		for n: Dictionary in st["npcs"]:
			assert_true(_db.behaviour.npcs.has(n["npc"]), "%s can be placed by %s" % [n["npc"], id])
	var fight: Dictionary = _db.canon.events[FIGHT]["stage"]
	assert_eq(fight["foes"].size(), 1)
	assert_eq(fight["foes"][0]["enemy"], "regrika_blackpaw")
	assert_true(_db.combat.enemies["regrika_blackpaw"].has("escape"), "she cannot die")
	for w: Dictionary in fight["waves"]:
		for npc: String in w.get("allies", []):
			assert_true(_db.behaviour.npcs.has(npc), npc + " can be placed")
			assert_true(_db.behaviour.npcs[npc].has("combat"), npc + " can fight")
	for s: Dictionary in _db.combat.spawns:
		assert_ne(str(s["enemy"]), "regrika_blackpaw", "only a stage brings her")


func test_the_feast_fills_the_inn_on_the_evening_of_day_111() -> void:
	var gs := _copy(111)
	_wait_indoors_until(gs, _db, 18)
	_wait_for(gs, _db, FEAST, "inn_interior", INN_SPOT)
	var h := _hour(gs)
	assert_true(h >= 18 and h < 23, "evening")
	for npc: String in ["brunkr", "krshia", "erin_solstice", "klbkch"]:
		assert_eq(_area_of(gs, npc), "inn_interior", npc)


func test_talking_with_brunkr_at_the_feast_changes_it() -> void:
	var gs := _copy(111)
	_wait_indoors_until(gs, _db, 18)
	_wait_for(gs, _db, FEAST, "inn_interior", INN_SPOT)
	_do_with(gs, "brunkr", "talk_with_guest", "wandering_inn")
	ToyCanon.sleep_through(gs, _db, 111)
	_assert_changed(gs, FEAST, "player_ate_brunkrs_cake",
			"wandering_inn.earther_ate_brunkrs_cake", "wandering_inn.held_brunkrs_feast")
	assert_true(gs.world.relationship("brunkr", NpcSim.PLAYER) >= 1)
	assert_false(gs.world.is_alive(_db.canon, "brunkr"), "Venitra still kills him that night")


func test_the_new_floors_are_done_on_day_112() -> void:
	var gs := _copy(112)
	assert_false(gs.flags.has("wandering_inn.third_floor_built"), "not yet on day 112")
	ToyCanon.sleep_through(gs, _db, 112)
	assert_true(gs.flags.has("wandering_inn.third_floor_built"), "open on day 113")


func test_regrika_attacks_on_the_night_of_day_112() -> void:
	var gs := _copy(112)
	_wait_indoors_until(gs, _db, 20)
	_wait_for(gs, _db, FIGHT, "inn_interior", INN_SPOT)
	assert_true(_hour(gs) >= 20, "night")
	assert_eq(_stage_foes(gs, FIGHT).size(), 1)
	FightBot.wait_seconds(gs, _db, 36)
	for npc: String in ["halrac", "revi", "typhenous"]:
		assert_eq(_area_of(gs, npc), "inn_interior", npc)


func test_fighting_regrika_changes_the_event_and_she_escapes() -> void:
	var db := _frozen_db()
	var gs := _copy(112, db)
	_wait_indoors_until(gs, db, 20)
	_wait_for(gs, db, FIGHT, "inn_interior", INN_SPOT)
	var lines: Array = []
	for i in 4000:
		if _stage_foes(gs, FIGHT).is_empty() and not gs.combat.has_fight():
			break
		_fight_turn(gs, db, FIGHT)
		lines.append_array(gs.combat.lines)
	assert_true(_stage_foes(gs, FIGHT).is_empty(), "she is gone")
	assert_has(lines, db.combat.enemies["regrika_blackpaw"]["escape"]["line"])
	ToyCanon.sleep_through(gs, db, 112)
	assert_eq(gs.world.status(FIGHT), Director.CHANGED)
	assert_eq(_hook_of(gs, FIGHT), "player_fought_regrika")
	assert_true(gs.flags.has("wandering_inn.earther_fought_regrika"))
	assert_true(gs.flags.has("griffon_hunt.lost_ulrien"), "the canon still happens")
	assert_false(gs.world.is_alive(db.canon, "ulrien"))
	assert_true(gs.world.relationship("halrac", NpcSim.PLAYER) >= 2)


func test_no_fight_on_the_night_of_day_111() -> void:
	var gs := _copy(111)
	_wait_indoors_until(gs, _db, 20)
	for i in 3:
		Commands.wait(gs, _db, 1800)
		assert_false(gs.world.staged.has(FIGHT))


func test_the_pyres_burn_on_the_night_of_day_113() -> void:
	var gs := _copy(113)
	_wait_indoors_until(gs, _db, 19)
	_wait_for(gs, _db, PYRES, "inn_hill", HILL_SPOT)
	assert_true(_hour(gs) >= 19, "night")
	for npc: String in ["krshia", "halrac", "erin_solstice", "mrsha"]:
		assert_eq(_area_of(gs, npc), "inn_hill", npc)
	_do_with(gs, "krshia", "comfort_someone", "wandering_inn")
	ToyCanon.sleep_through(gs, _db, 113)
	_assert_changed(gs, PYRES, "player_mourned_at_the_pyres",
			"wandering_inn.earther_mourned_at_the_pyres", "wandering_inn.held_the_pyres_for_brunkr_and_ulrien")
	assert_true(gs.world.relationship("krshia", NpcSim.PLAYER) >= 1)


func test_ryoka_lyonette_and_mrsha_are_gone_from_the_inn_after_day_114() -> void:
	var gs := _copy(115)
	_wait_indoors_until(gs, _db, 20)
	for npc: String in ["ryoka_griffin", "lyonette", "mrsha"]:
		assert_ne(_area_of(gs, npc), "inn_interior", npc)
	assert_true(gs.world.is_alive(_db.canon, "ryoka_griffin"), "revived by Teriarch")
	assert_false(gs.flags.has("izril.winter"), "winter is over")
