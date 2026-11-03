extends GutTest
## M36.7 on the real Book 9 data (5.58, 5.59, Interlude – Pebblesnatch and Garry, days 173 - 174): the Halfseekers
## charge Garen's host, the Gold teams hold the door, the five Hobs overthrow Garen (he lives and rides north), Jelaqua
## takes a Raskghar body; then the Flooded Waters reach the inn, Erin reaches [Magical Innkeeper] 37, the flood flag
## clears, and Garry wins the Goblin cooking contest. User picks (2026-11-03): one fight stage (the Halfseekers against
## Garen's host on road_camp, XP tier 1), no hook. No named kill. Slept to day 172 once (before_all).

const SEED := 20261105
const CHAPTERS := ["5.58", "5.59", "interlude_pebblesnatch_and_garry"]
const FIGHT := "b9.the_halfseekers_charge_the_redfangs"
const FOE_TYPES := ["redfang_warrior", "redfang_hob"]
const CAMP_SPOT := Vector2i(16, 12)

var _db: DataDb
var _base := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])
	assert_eq(_db.canon.errors, [] as Array[String])
	var gs := GameState.new_game(SEED, _db)
	ToyCanon.sleep_through(gs, _db, 172)
	_base = gs.to_json()


func _fresh() -> GameState:
	var gs := GameState.from_json(_base)
	assert_eq(gs.clock.day(), 173)
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
	assert_eq(ids.size(), 17)
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
		assert_true(int(ev["window"]["earliest"]) >= 173 and int(ev["window"]["latest"]) <= 174, id)
		for dep: String in ev["depends_on"]:
			assert_true(_db.canon.events.has(dep), dep)
	assert_eq(fights, [FIGHT] as Array[String])


func test_the_fight_data_is_sound() -> void:
	var ev: Dictionary = _db.canon.events[FIGHT]
	var st: Dictionary = ev["stage"]
	assert_eq(st["area"], "road_camp")
	assert_eq(int(ev["xp_window"]["boost"]), 1, "user pick: tier 1")
	assert_eq(ev["xp_window"]["hours"], st["hours"])
	for f: Dictionary in st["foes"]:
		assert_true(String(f["enemy"]) in FOE_TYPES, f["enemy"])
	var allies: Array = []
	for w: Dictionary in st["waves"]:
		for e: String in w.get("foes", []):
			assert_true(e in FOE_TYPES, e)
		for a: String in w.get("allies", []):
			assert_true(_db.behaviour.npcs[a].has("combat"), a + " has combat")
			allies.append(a)
	for a: String in ["jelaqua", "moore", "seborn"]:
		assert_true(allies.has(a), a)


func test_the_halfseekers_fight_the_redfangs_at_dusk() -> void:
	var db := DataDb.load_dir()
	ToyCombat.freeze(db)
	var gs := _fresh()
	_wait_for_stage(gs, db, FIGHT, "road_camp", CAMP_SPOT)
	@warning_ignore("integer_division")
	var h: int = gs.clock.minute() / 60
	assert_true(h >= 18 and h < 21, "at dusk")
	var foes := gs.combat.ids().filter(func(id: String) -> bool: return gs.combat.monsters[id].get("stage", "") == FIGHT)
	assert_true(foes.size() >= 3, "Redfangs on the road")
	FightBot.wait_seconds(gs, db, 5)
	assert_eq(_area_of(gs, "jelaqua"), "road_camp", "the Halfseekers charge in")


func test_the_host_can_be_fought_through() -> void:
	var db := DataDb.load_dir()
	ToyCombat.freeze(db)
	ToyCombat.always_hit(db)
	var gs := _fresh()
	_wait_for_stage(gs, db, FIGHT, "road_camp", CAMP_SPOT)
	for i in 4000:
		if _stage_foe(gs) == "" and not gs.combat.has_fight():
			break
		_fight_turn(gs, db)
	assert_eq(_stage_foe(gs), "", "the Redfangs are down")
	ToyCanon.sleep_through(gs, db, 173)
	assert_true(gs.flags.has("garen.overthrown_by_the_five_hobs"), "the canon still happens")


func test_staying_away_still_overthrows_garen() -> void:
	var gs := _fresh()
	ToyCanon.sleep_through(gs, _db, 173)
	_has_all(gs, ["halfseekers.charged_the_redfang_host", "wings_of_pallass.fought_the_redfangs",
			"garen.struck_erin_on_the_road", "garen.overthrown_by_the_five_hobs", "redfangs.follow_the_five_hobs",
			"garen.rode_north_alone", "jelaqua.wears_a_raskghar_body", "erin.teeth_mended_by_pisces",
			"flooded_waters_tribe.flees_south"])
	assert_false(gs.flags.has("garen.hit_squad_hunts_erin"), "Garen's order is dropped")
	assert_true(gs.flags.has("izril.flood"), "the flood waits for day 174")
	assert_true(gs.world.is_alive(_db.canon, "garen"), "Garen lives")
	assert_true(gs.world.is_alive(_db.canon, "jelaqua"), "Jelaqua lives")
	assert_eq(gs.world.status(FIGHT), Director.DONE)


func test_day_174_ends_the_flood_and_fills_the_inn() -> void:
	var gs := _fresh()
	ToyCanon.sleep_through(gs, _db, 174)
	_has_all(gs, ["erin.refuses_the_goblin_cave_door", "gold_teams.will_flee_when_the_army_comes",
			"wandering_inn.no_killing_goblins_sign", "goblins.camp_around_the_inn", "izril.floodplains_muddy",
			"liscor.most_cannot_cross_the_door", "redscar.reconciled_with_spiderslicer",
			"wandering_inn.goblin_party_on_day_174", "garry.won_the_goblin_cooking_contest",
			"garry.cooks_for_the_hive"])
	assert_false(gs.flags.has("izril.flood"), "ADR 0047: the flood flag clears on day 174")
	for id: String in ["garen", "erin_solstice", "garry", "redscar", "headscratcher", "numbtongue"]:
		assert_true(gs.world.is_alive(_db.canon, id), id + " lives")


func test_the_system_lines_are_recorded() -> void:
	var erin: Array = _system("5.59").filter(func(s: Dictionary) -> bool: return s["who"] == "erin_solstice")
	assert_eq(erin.size(), 1)
	assert_eq(int(erin[0]["level"]), 37)
	assert_eq(_system("5.58").size(), 2)
	var cook: Array = _system("interlude_pebblesnatch_and_garry").filter(func(s: Dictionary) -> bool: return s["who"] == "garry")
	assert_eq(int(cook[0]["level"]), 17)
