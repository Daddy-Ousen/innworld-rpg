extends GutTest
## M36.5 on the real Book 9 data (5.54, Interlude – Krshia, days 172 - 173): Erin fights the Watch and is jailed,
## Numbtongue gets away, the five Queens save Bird, the Hives plan to retake Liscor, Olesm shames the Assembly on the
## scrying, Typhenous lets thieves steal the door and Numbtongue kills them on the north shore; then the door is back,
## Zevara takes the Celum stone, the Gnolls vote to stay and Mrsha throws [Everdawn's Radiance]. User picks
## (2026-11-02): a fight stage for the door thieves on road_camp (the flood covers the Floodplains map), XP tier 1;
## two scene hooks: the jail visit (liscor_watch_cells, day 173: the cells fill when day 172 resolves) and the Gnolls' spark (liscor_market, day 173).
## No named kill. Slept to day 171 once (before_all).

const SEED := 20261103
const CHAPTERS := ["5.54", "interlude_krshia"]
const ARREST := "b9.erin_fights_the_watch_and_is_jailed"
const JAIL := "b9.erin_is_still_in_her_cell"
const JAIL_HOOK := "player_visited_erin_in_the_cells"
const THIEVES := "b9.numbtongue_ambushes_the_door_thieves"
const GNOLLS := "b9.mrsha_throws_everdawns_radiance"
const GNOLL_HOOK := "player_carried_the_gnolls_spark"
const THIEF_TYPES := ["brothers_thug", "chell_sister"]
const CAMP_SPOT := Vector2i(16, 12)

var _db: DataDb
var _base := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])
	assert_eq(_db.canon.errors, [] as Array[String])
	var gs := GameState.new_game(SEED, _db)
	ToyCanon.sleep_through(gs, _db, 171)
	_base = gs.to_json()


func _fresh() -> GameState:
	var gs := GameState.from_json(_base)
	assert_eq(gs.clock.day(), 172)
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
		if m["state"] != CombatState.HOSTILE or m.get("stage", "") != THIEVES:
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


func test_the_batch_has_one_fight_two_scenes_two_hooks_and_no_kill() -> void:
	var ids := _batch_ids()
	assert_eq(ids.size(), 15)
	var fights: Array[String] = []
	var scenes: Array[String] = []
	var hooks: Array[String] = []
	for id: String in ids:
		var ev: Dictionary = _db.canon.events[id]
		if ev.has("stage"):
			if ev["stage"]["kind"] == "scene":
				scenes.append(id)
			else:
				fights.append(id)
			assert_true(_db.canon.foreshadows.has(id), id + " has a signpost")
		for h: Dictionary in ev.get("hooks", []):
			hooks.append(String(h["id"]))
		assert_eq(ev.has("xp_window"), id == THIEVES, id + ": only the fight has an XP window")
		assert_eq(ev["window"]["confidence"], "guess", id)
		assert_false(ev["effects"].has("kill"), id + ": no named kill")
		assert_true(int(ev["window"]["earliest"]) >= 172 and int(ev["window"]["latest"]) <= 173, id)
		for dep: String in ev["depends_on"]:
			assert_true(_db.canon.events.has(dep), dep)
	scenes.sort()
	hooks.sort()
	assert_eq(fights, [THIEVES] as Array[String])
	assert_eq(scenes, [JAIL, GNOLLS] as Array[String])
	assert_eq(hooks, [GNOLL_HOOK, JAIL_HOOK] as Array[String])
	var days: Array = _db.canon.events[JAIL]["hooks"][0]["days"]
	assert_eq([int(days[0]), int(days[1])], [173, 173], "the cells fill once day 172 is done")


func test_the_fight_data_is_sound() -> void:
	var ev: Dictionary = _db.canon.events[THIEVES]
	var st: Dictionary = ev["stage"]
	assert_eq(st["area"], "road_camp", "user pick: the Floodplains map is under water")
	assert_eq(int(ev["xp_window"]["boost"]), 1, "user pick: tier 1")
	assert_eq(ev["xp_window"]["hours"], st["hours"], "the XP window matches the stage hours")
	for f: Dictionary in st["foes"]:
		assert_true(String(f["enemy"]) in THIEF_TYPES, f["enemy"])
	for w: Dictionary in st["waves"]:
		for e: String in w.get("foes", []):
			assert_true(e in THIEF_TYPES, e)
		for a: String in w.get("allies", []):
			assert_true(_db.behaviour.npcs[a].has("combat"), a + " has combat")
	assert_true((st["waves"][0]["allies"] as Array).has("numbtongue"))
	assert_true(int(st["waves"][0]["after_seconds"]) > 0, "Numbtongue comes a little late")


func test_the_thieves_land_at_night_and_numbtongue_comes() -> void:
	var db := DataDb.load_dir()
	ToyCombat.freeze(db)
	var gs := _fresh()
	_wait_for_stage(gs, db, THIEVES, "road_camp", CAMP_SPOT)
	@warning_ignore("integer_division")
	var h: int = gs.clock.minute() / 60
	assert_true(h >= 22 and h < 24, "late at night")
	var foes := gs.combat.ids().filter(func(id: String) -> bool: return gs.combat.monsters[id].get("stage", "") == THIEVES)
	assert_true(foes.size() >= 3, "thieves on the shore")
	FightBot.wait_seconds(gs, db, 25)
	assert_eq(_area_of(gs, "numbtongue"), "road_camp", "Numbtongue joins the fight")


func test_the_thieves_can_be_fought_through() -> void:
	var db := DataDb.load_dir()
	ToyCombat.freeze(db)
	ToyCombat.always_hit(db)
	var gs := _fresh()
	_wait_for_stage(gs, db, THIEVES, "road_camp", CAMP_SPOT)
	for i in 4000:
		if _stage_foe(gs) == "" and not gs.combat.has_fight():
			break
		_fight_turn(gs, db)
	assert_eq(_stage_foe(gs), "", "the thieves are down")
	ToyCanon.sleep_through(gs, db, 172)
	assert_true(gs.flags.has("numbtongue.won_back_the_door"), "the canon still happens")


func test_staying_away_still_sets_the_canon_to_day_173() -> void:
	var gs := _fresh()
	ToyCanon.sleep_through(gs, _db, 172)
	_has_all(gs, ["erin.in_watch_cells", "erin.punched_olesm", "numbtongue.escaped_the_watch",
			"bird.saved_by_the_five_queens", "antinium.plan_to_retake_liscor_after_the_breach",
			"reiss.ordered_to_take_liscor", "calruz.spoke_to_erin_in_the_cells", "niers.marked_the_inn_on_his_map",
			"walled_cities.pledged_armies_to_liscor", "typhenous.betrayed_the_inn", "albez_door.pallass_stone_shattered",
			"numbtongue.won_back_the_door", "door_thieves.all_dead"])
	assert_false(gs.flags.has("albez_door.at_wandering_inn"), "the door is gone in the night")
	assert_false(gs.flags.has("albez_door.anchor_at_pallass"), "the Pallass link is lost")
	ToyCanon.sleep_through(gs, _db, 173)
	_has_all(gs, ["krshia.knows_the_door_was_stolen", "albez_door.at_wandering_inn", "albez_door.celum_stone_taken",
			"gold_teams.mean_to_leave_liscor", "krshia.knows_mrsha_can_cast", "liscor_gnolls.stay_to_defend_liscor",
			"liscor.lit_by_everdawns_radiance", "zevara.called_off_the_exodus"])
	assert_false(gs.flags.has("albez_door.stolen"))
	assert_eq(gs.world.status(JAIL), Director.DONE)
	assert_eq(gs.world.status(GNOLLS), Director.DONE)
	for id: String in ["bird", "numbtongue", "osthia_blackwing", "calruz", "erin_solstice"]:
		assert_true(gs.world.is_alive(_db.canon, id), id + " lives")
	assert_true(gs.flags.has("erin.in_watch_cells"), "Erin was jailed (freed on day 173, 5.57, M36.6)")
	assert_ne(_area_of(gs, "numbtongue"), "liscor_watch_cells")
	assert_true(gs.flags.has("numbtongue.stood_down_for_erin"), "Erin talks him down on day 173 (5.57, M36.6)")


func test_krshia_becomes_a_royal_shopkeeper() -> void:
	var lines := _system("interlude_krshia")
	var names: Array = lines.map(func(s: Dictionary) -> String: return s["name"])
	assert_eq(names, ["[Royal Shopkeeper]", "[Imperial Appraiser]", "[Silvertouched Wares]"])
	for s: Dictionary in lines:
		assert_eq(s["who"], "krshia")
	assert_eq(_system("5.54"), [], "5.54 shows no System lines")


func test_visiting_the_cells_changes_the_second_day() -> void:
	var gs := _fresh()
	ToyCanon.sleep_through(gs, _db, 172)
	_wait_for_stage(gs, _db, JAIL, "liscor_watch_cells", Vector2i(5, 5))
	for id: String in ["erin_solstice", "headscratcher", "calruz"]:
		assert_eq(_area_of(gs, id), "liscor_watch_cells", id)
	var before := gs.world.relationship("erin_solstice", "player")
	_talk_to(gs, "erin_solstice")
	ToyCanon.sleep_through(gs, _db, 173)
	assert_eq(gs.world.status(JAIL), Director.CHANGED)
	assert_eq(_hook_of(gs, JAIL), JAIL_HOOK)
	assert_true(gs.flags.has("wandering_inn.earther_visited_the_cells"))
	assert_true(gs.flags.has("erin.second_day_in_the_cells"), "the canon still happens")
	assert_gt(gs.world.relationship("erin_solstice", "player"), before)


func test_carrying_the_spark_changes_the_gnolls_sunset() -> void:
	var gs := _fresh()
	ToyCanon.sleep_through(gs, _db, 172)
	_wait_for_stage(gs, _db, GNOLLS, "liscor_market", Vector2i(10, 10))
	for id: String in ["krshia", "mrsha", "beilmark"]:
		assert_eq(_area_of(gs, id), "liscor_market", id)
	var before := gs.world.relationship("krshia", "player")
	_talk_to(gs, "krshia")
	ToyCanon.sleep_through(gs, _db, 173)
	assert_eq(gs.world.status(GNOLLS), Director.CHANGED)
	assert_eq(_hook_of(gs, GNOLLS), GNOLL_HOOK)
	assert_true(gs.flags.has("liscor.earther_carried_the_gnolls_spark"))
	assert_true(gs.flags.has("liscor.lit_by_everdawns_radiance"), "the canon still happens")
	assert_gt(gs.world.relationship("krshia", "player"), before)
