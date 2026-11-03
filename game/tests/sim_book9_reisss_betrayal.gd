extends GutTest
## M36.6 on the real Book 9 data (5.55 G, 5.56 G, 5.57, day 173): Reiss drills the horde, refuses nothing, betrays Rags
## with [Deathbolt] and breaks the Flooded Waters; Pyrite falls to seven bolts but lives; Garen cuts through three Human
## groups; the Cave Goblins reach the Floodplains; Zevara lets Erin out, she talks Numbtongue down and the Watch frees
## the four Hobs. No fight stage, no hook (user pick, 2026-11-02). No named kill: Geim, Helica and Sir Meilmen have no
## records, and Pyrite, Rags, Osthia and Numbtongue live. Slept to day 172 once (before_all).

const SEED := 20261104
const CHAPTERS := ["5.55G", "5.56G", "5.57"]
const FREED_ERIN := "b9.zevara_lets_erin_out"
const FREED_HOBS := "b9.the_watch_frees_the_four_hobs"
const CELLS := "liscor_watch_cells"
const JAILED_HOBS := ["headscratcher", "badarrow", "rabbiteater", "shorthilt"]

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


func _wait_until_hour(gs: GameState, hour: int) -> void:
	var guard := 0
	while gs.clock.minute() < hour * 60 and guard < 30:
		assert_true(Commands.wait(gs, _db, 3600) >= 0, "wait")
		guard += 1
	assert_lt(guard, 30, "the wait ended")


func _area_of(gs: GameState, id: String) -> String:
	var n: Dictionary = gs.npcs.npcs.get(id, {})
	return "" if n.is_empty() else String(n["area"])


func _system(chapter: String) -> Array:
	var f := FileAccess.open("res://data/canon/book9/chapters/%s.json" % chapter, FileAccess.READ)
	var doc: Dictionary = JSON.parse_string(f.get_as_text())
	return doc["system"]


func test_the_batch_has_no_stage_no_hook_and_no_kill() -> void:
	var ids := _batch_ids()
	assert_eq(ids.size(), 19)
	for id: String in ids:
		var ev: Dictionary = _db.canon.events[id]
		assert_false(ev.has("stage"), id + ": no stage (user pick)")
		assert_false(ev.has("hooks"), id + ": no hook (user pick)")
		assert_false(ev.has("xp_window"), id)
		assert_false(ev["effects"].has("kill"), id + ": no named kill")
		assert_eq(ev["window"]["confidence"], "guess", id)
		assert_eq([int(ev["window"]["earliest"]), int(ev["window"]["latest"])], [173, 173], id)
		for dep: String in ev["depends_on"]:
			assert_true(_db.canon.events.has(dep), dep)


func test_staying_away_still_sets_the_canon_on_day_173() -> void:
	var gs := _fresh()
	ToyCanon.sleep_through(gs, _db, 173)
	_has_all(gs, ["rags.drilled_the_combined_horde", "eater_goats.broken_by_pyrite", "osthia.false_death_revealed",
			"rags.refused_to_sack_liscor", "reiss.betrayed_rags", "rags.struck_by_a_deathbolt",
			"pyrite.struck_by_seven_deathbolts", "pyrite.fed_on_magestones_to_survive",
			"garen.killed_three_human_commanders", "flooded_waters.broken_by_reiss", "tyrion.believes_rags_dead",
			"rags.alive_in_the_high_passes", "pyrite.alive_with_rags", "cave_goblins.camp_at_liscor",
			"redfangs.crossed_the_pass", "liscor.offered_a_parley_for_the_hobs", "erin.freed_from_the_cells",
			"erin.negotiates_for_the_hobs", "albez_door.liscor_link_unconnected", "numbtongue.stood_down_for_erin",
			"cave_goblins.agreed_to_go_south", "redfang_hobs.freed_from_the_cells",
			"halfseekers.attacked_garen_on_the_road"])
	for id: String in ["rags", "pyrite", "garen", "goblin_lord", "osthia_blackwing", "numbtongue", "erin_solstice",
			"calruz"]:
		assert_true(gs.world.is_alive(_db.canon, id), id + " lives")
	assert_true(gs.flags.has("calruz.in_watch_prison"), "Calruz stays in his cell")


func test_pyrite_names_his_class_and_nobody_levels() -> void:
	assert_eq(_system("5.55G"), [])
	var lines := _system("5.56G")
	assert_eq(lines.size(), 1)
	assert_eq(lines[0]["who"], "pyrite")
	assert_eq(lines[0]["name"], "[Magestone Chieftain]")
	assert_eq(lines[0]["level"], null, "no level is given")
	assert_eq(_system("5.57"), [])


func test_erin_and_the_hobs_leave_the_cells_on_day_173() -> void:
	var gs := _fresh()
	gs.player.place("inn_interior", Vector2i(3, 3))
	assert_true(gs.flags.has("erin.in_watch_cells"))
	_wait_until_hour(gs, 12)
	assert_eq(_area_of(gs, "erin_solstice"), CELLS, "still in her cell at noon of day 173")
	ToyCanon.sleep_through(gs, _db, 173)
	gs.player.place("inn_interior", Vector2i(3, 3))
	_wait_until_hour(gs, 12)
	assert_ne(_area_of(gs, "erin_solstice"), CELLS, "freed")
	for id: String in JAILED_HOBS:
		assert_ne(_area_of(gs, id), CELLS, id + " is freed")
	assert_ne(_area_of(gs, "numbtongue"), "", "Numbtongue is back on the books")
	assert_eq(_area_of(gs, "calruz"), CELLS, "Calruz stays")


func test_erin_is_freed_before_the_hobs() -> void:
	var erin: Dictionary = _db.canon.events[FREED_ERIN]
	assert_false((erin["effects"]["set_flags"] as Array).has("redfang_hobs.freed_from_the_cells"))
	var hobs: Dictionary = _db.canon.events[FREED_HOBS]
	var chain: Array = hobs["depends_on"]
	assert_true(chain.has("b9.erin_talks_numbtongue_down"))
	assert_true(_db.canon.events["b9.erin_talks_numbtongue_down"]["depends_on"].has("b9.erin_sets_her_terms_on_the_wall"))
	assert_true(_db.canon.events["b9.erin_sets_her_terms_on_the_wall"]["depends_on"].has(FREED_ERIN))
