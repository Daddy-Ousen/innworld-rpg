extends GutTest
## M36.8 on the real Book 9 data (5.60, 5.61, days 175 - 176): Ilvriss moves the door to city hall, the tribes vote to
## go south, Erin sews a white flag; then the trebuchets fire on the east gate and the Solstice Goblins charge. User picks
## (2026-11-03): one fight stage (the barrage on liscor_gate, XP tier 1), no hook. No named kill. Slept to day 174 once.

const SEED := 20261105
const CHAPTERS := ["5.60", "5.61"]
const FIGHT := "b9.the_trebuchets_fire_on_the_east_gate"
const FOE_TYPES := ["zombie", "skeleton", "ghoul", "goblin_lord_soldier"]
const CAMP_SPOT := Vector2i(10, 12)

var _db: DataDb
var _base := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])
	assert_eq(_db.canon.errors, [] as Array[String])
	var gs := GameState.new_game(SEED, _db)
	ToyCanon.sleep_through(gs, _db, 174)
	_base = gs.to_json()


func _fresh() -> GameState:
	var gs := GameState.from_json(_base)
	assert_eq(gs.clock.day(), 175)
	return gs


func _batch_ids() -> Array[String]:
	var ids: Array[String] = []
	for id: String in _db.canon.events:
		var ref: Dictionary = _db.canon.events[id]["canon_ref"]
		if int(ref["book"]) == 9 and String(ref["chapter"]) in CHAPTERS and not _db.canon.alt_only.has(id):
			ids.append(id)
	return ids


func _has_all(gs: GameState, flags: Array) -> void:
	for f: String in flags:
		assert_true(gs.flags.has(f), f)


func _wait_for_stage(gs: GameState, db: DataDb, id: String, area: String, spot: Vector2i) -> void:
	gs.player.place(area, spot)
	Commands.settle(gs, db)
	for i in 160:
		if gs.world.staged.has(id):
			break
		assert_true(Commands.wait(gs, db, 600) >= 0, "wait")
	assert_true(gs.world.staged.has(id), id + " is staged")


func _area_of(gs: GameState, id: String) -> String:
	var n: Dictionary = gs.npcs.npcs.get(id, {})
	return "" if n.is_empty() else String(n["area"])


func _talk_to(gs: GameState, id: String) -> void:
	var n: Dictionary = gs.npcs.npcs[id]
	var area := String(n["area"])
	var at := Vector2i(int(n["x"]), int(n["y"]))
	var taken := {}
	for other: String in gs.npcs.in_area(area):
		taken[NpcRoster.pos_of(gs.npcs.npcs[other])] = true
	var spot := Vector2i(-1, -1)
	for d: Vector2i in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
		if not taken.has(at + d) and _db.maps.is_walkable(area, at + d):
			spot = at + d
			break
	assert_ne(spot, Vector2i(-1, -1), "a free side of " + id)
	gs.player.place(area, spot)
	var r := Commands.interact(gs, _db, id, "talk_with_guest")
	assert_eq(r["error"], "")


func _hook_of(gs: GameState, id: String) -> String:
	var entry: Dictionary = gs.world.history.filter(func(h: Dictionary) -> bool: return h["event"] == id)[0]
	return str(entry.get("hook", ""))


func _stage_foe(gs: GameState) -> String:
	var best := ""
	var best_d := 1 << 30
	for id: String in gs.combat.ids():
		var m: Dictionary = gs.combat.monsters[id]
		if m["state"] != CombatState.HOSTILE or m.get("stage", "") != FIGHT:
			continue
		var d := CombatState.pos_of(m) - gs.player.pos()
		if absi(d.x) + absi(d.y) < best_d:
			best_d = absi(d.x) + absi(d.y)
			best = id
	return best


func _fight_turn(gs: GameState, db: DataDb) -> void:
	var id := _stage_foe(gs)
	if id == "":
		Commands.wait(gs, db, 6)
		return
	var at := CombatState.pos_of(gs.combat.monsters[id])
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


func _system(chapter: String) -> Array:
	var f := FileAccess.open("res://data/canon/book9/chapters/%s.json" % chapter, FileAccess.READ)
	var doc: Dictionary = JSON.parse_string(f.get_as_text())
	return doc["system"]


func test_the_batch_has_one_fight_and_no_hook_or_kill() -> void:
	var ids := _batch_ids()
	assert_eq(ids.size(), 24)
	var fights: Array[String] = []
	for id: String in ids:
		var ev: Dictionary = _db.canon.events[id]
		if ev.has("stage"):
			fights.append(id)
			assert_eq(ev["stage"]["kind"], "fight")
			assert_true(_db.canon.foreshadows.has(id), id + " has a signpost")
		assert_false(ev.has("hooks"), id + ": no hook (user pick)")
		assert_eq(ev.has("xp_window"), id == FIGHT, id)
		assert_eq(ev["window"]["confidence"], "guess", id)
		assert_false(ev["effects"].has("kill"), id + ": no named kill")
		assert_true(int(ev["window"]["earliest"]) >= 175 and int(ev["window"]["latest"]) <= 176, id)
		for dep: String in ev["depends_on"]:
			assert_true(_db.canon.events.has(dep), dep)
	assert_eq(fights, [FIGHT] as Array[String])


func test_the_fight_data_is_sound() -> void:
	var ev: Dictionary = _db.canon.events[FIGHT]
	var st: Dictionary = ev["stage"]
	assert_eq(st["area"], "liscor_gate")
	assert_eq(int(ev["xp_window"]["boost"]), 1, "user pick: tier 1")
	assert_eq(ev["xp_window"]["hours"], st["hours"])
	for f: Dictionary in st["foes"]:
		assert_true(String(f["enemy"]) in FOE_TYPES, f["enemy"])
	for w: Dictionary in st["waves"]:
		for e: String in w.get("foes", []):
			assert_true(e in FOE_TYPES, e)
		for a: String in w.get("allies", []):
			assert_true(_db.behaviour.npcs[a].has("combat"), a + " has combat")


func test_the_barrage_is_staged_at_the_gate() -> void:
	var db := DataDb.load_dir()
	ToyCombat.freeze(db)
	var gs := _fresh()
	ToyCanon.sleep_through(gs, db, 175)
	assert_eq(gs.clock.day(), 176)
	_wait_for_stage(gs, db, FIGHT, "liscor_gate", CAMP_SPOT)
	@warning_ignore("integer_division")
	var h: int = gs.clock.minute() / 60
	assert_true(h >= 13 and h < 16, "in the afternoon")
	FightBot.wait_seconds(gs, db, 5)
	assert_eq(_area_of(gs, "relc"), "liscor_gate", "the Watch holds the gate")


func test_the_gate_can_be_held() -> void:
	var db := DataDb.load_dir()
	ToyCombat.freeze(db)
	ToyCombat.always_hit(db)
	var gs := _fresh()
	ToyCanon.sleep_through(gs, db, 175)
	_wait_for_stage(gs, db, FIGHT, "liscor_gate", CAMP_SPOT)
	for i in 4000:
		if _stage_foe(gs) == "" and not gs.combat.has_fight():
			break
		_fight_turn(gs, db)
	assert_eq(_stage_foe(gs), "", "the undead are down")
	ToyCanon.sleep_through(gs, db, 176)
	assert_true(gs.flags.has("liscor.east_gate_bowed_inward"), "the canon still happens")


func test_the_door_moves_to_city_hall_and_the_white_flag_is_made() -> void:
	var gs := _fresh()
	ToyCanon.sleep_through(gs, _db, 175)
	_has_all(gs, ["albez_door.at_liscor_city_hall", "adventurers.conscripted_to_hold_the_walls",
			"goblin_tribes.voted_to_go_south", "erin.made_a_white_flag", "antinium.plan_to_retake_liscor_after_it_falls",
			"laken.alliance_with_gralton_and_yitton_for_the_byres_children"])
	assert_false(gs.flags.has("albez_door.at_wandering_inn"), "the door leaves the inn")


func test_staying_away_still_fires_the_trebuchets_and_nobody_named_dies_on_day_176() -> void:
	var gs := _fresh()
	ToyCanon.sleep_through(gs, _db, 176)
	_has_all(gs, ["trebuchets.fired_three_volleys_on_liscor", "liscor.walls_cracked_but_standing",
			"antinium.burned_a_seventh_of_the_trebuchets", "goblins.solstice_goblins_answer_erin",
			"erin.called_for_a_truce_with_loud_voice", "garen.rejoined_rags_with_eight_redfangs"])
	for who: String in ["erin_solstice", "numbtongue", "rags", "yitton_byres"]:
		assert_true(gs.world.is_alive(_db.canon, who), who + " lives")


func test_systems_are_recorded() -> void:
	assert_eq(_system("5.60").size(), 2)
	assert_eq(_system("5.61").size(), 2)
