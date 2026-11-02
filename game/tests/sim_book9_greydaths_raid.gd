extends GutTest
## M36.4 on the real Book 9 data (5.51 G, 5.52, 5.53, days 171 - 172): Tremborag shot by Elia and killed by Tyrion's
## lance, the Mountain City tribe broken up, the Necromancer's death spell on Osthia (not a kill), Tyrion's trebuchet
## plan and the letter that warns Olesm; then the rains end, Greydath tests the five Hobs, throws his sword at the
## inn's tower and maims Bird, and Olesm arrests the Hobs at the Hive. No fight stage, no hook (user pick,
## 2026-11-02). One kill: Tremborag. New map liscor_watch_cells (user pick): the four jailed Hobs, Erin (from her
## 5.54 arrest flag, M36.5) and Calruz stand at their cell bars by flag goals. Slept to day 171 once (before_all).

const SEED := 20261102
const CHAPTERS := ["5.51G", "5.52", "5.53"]
const TREMBORAG := "b9.tyrion_lances_tremborag"
const RAINS := "b9.the_rains_end"
const TOWER := "b9.greydath_throws_his_sword_at_the_tower"
const ARREST := "b9.olesm_arrests_the_hobs_at_the_hive"
const CELLS := "liscor_watch_cells"
## Where each prisoner stands at the bars (data/npc_behaviour.json).
const SPOTS := {"rabbiteater": Vector2i(10, 3), "shorthilt": Vector2i(14, 3), "erin_solstice": Vector2i(18, 3),
		"badarrow": Vector2i(14, 7), "headscratcher": Vector2i(18, 7), "calruz": Vector2i(20, 5)}
const JAILED_HOBS := ["headscratcher", "badarrow", "rabbiteater", "shorthilt"]

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


## Waits an hour at a time until `hour` of the day (bounded).
func _wait_until_hour(gs: GameState, hour: int) -> void:
	var guard := 0
	while gs.clock.minute() < hour * 60 and guard < 30:
		assert_true(Commands.wait(gs, _db, 3600) >= 0, "wait")
		guard += 1
	assert_lt(guard, 30, "the wait ended")


func _pos_of(gs: GameState, id: String) -> Vector2i:
	return NpcRoster.pos_of(gs.npcs.npcs[id])


func _area_of(gs: GameState, id: String) -> String:
	var n: Dictionary = gs.npcs.npcs.get(id, {})
	return "" if n.is_empty() else String(n["area"])


func _system(chapter: String) -> Array:
	var f := FileAccess.open("res://data/canon/book9/chapters/%s.json" % chapter, FileAccess.READ)
	var doc: Dictionary = JSON.parse_string(f.get_as_text())
	return doc["system"]


func test_the_batch_has_no_stage_no_hook_and_one_kill() -> void:
	var ids := _batch_ids()
	assert_eq(ids.size(), 28)
	var killed: Array[String] = []
	for id: String in ids:
		var ev: Dictionary = _db.canon.events[id]
		assert_false(ev.has("stage"), id + ": no stage (user pick)")
		assert_false(ev.has("hooks"), id + ": no hook (user pick)")
		assert_false(ev.has("xp_window"), id)
		assert_eq(ev["window"]["confidence"], "guess", id)
		assert_true(int(ev["window"]["earliest"]) >= 171 and int(ev["window"]["latest"]) <= 172, id)
		for n: String in ev["effects"].get("kill", []):
			killed.append(n)
		for dep: String in ev["depends_on"]:
			assert_true(_db.canon.events.has(dep), dep)
	assert_eq(killed, ["tremborag"] as Array[String], "only Tremborag dies by name")
	assert_eq(_db.canon.events[TREMBORAG]["window"]["earliest"], 172, "5.51 G is March Day 9")
	assert_eq(_db.canon.events[RAINS]["window"]["earliest"], 172, "5.53 is day 172 (guess)")
	assert_true(_db.canon.events[RAINS]["effects"]["clear_flags"].has("izril.rains"))


func test_staying_away_still_sets_the_canon_to_day_172() -> void:
	var gs := _fresh()
	assert_true(gs.flags.has("izril.rains"), "it still rains before 5.53")
	assert_true(gs.world.is_alive(_db.canon, "tremborag"))
	ToyCanon.sleep_through(gs, _db, 172)
	_has_all(gs, ["rags.swore_to_kill_tremborag", "reiss.let_quietstab_die_to_win_rags",
			"mountain_city.ambushed_by_rags", "tyrion.burned_magnolias_message", "tremborag.abandoned_by_his_tribe",
			"rags.sees_the_circle_of_goblin_killing", "tremborag.slain_by_tyrion",
			"flooded_waters.took_in_half_the_mountain_city", "osthia.struck_by_a_deathbolt",
			"north.told_the_goblin_lord_is_next", "eltistiman.nose_broken_by_erin",
			"liscor.knows_tyrion_drives_the_goblins_south", "durene.woke_after_the_goblin_battle",
			"laken.at_tyrions_camp", "tyrion.plans_to_breach_liscor_with_trebuchets", "olesm.knows_of_the_trebuchets",
			"drakes.warned_of_the_trebuchets", "tyrion.siege_in_four_days", "numbtongue.called_down_lightning",
			"redfang_hobs.know_greybeard_is_greydath", "greydath.tested_the_redfang_hobs", "izril.rains_ended",
			"wandering_inn.watchtower_smashed", "bird.lost_his_left_arms", "bird.in_the_queens_care",
			"redfang_hobs.in_watch_cells", "numbtongue.arrested_at_the_hive", "liscor.under_military_law"])
	assert_false(gs.flags.has("izril.rains"), "the rains have ended")
	assert_true(gs.flags.has("izril.flood"), "the Floodplains stay drowned until 5.59")
	assert_false(gs.world.is_alive(_db.canon, "tremborag"), "Tremborag is dead")
	for id: String in ["osthia_blackwing", "bird", "numbtongue", "greybeard", "calruz"]:
		assert_true(gs.world.is_alive(_db.canon, id), id + " lives")
	assert_true(gs.flags.has("calruz.awaits_trial"), "no verdict for Calruz")
	assert_false((_db.canon.events[ARREST]["effects"]["set_flags"] as Array).has("erin.in_watch_cells"),
			"5.53 does not jail Erin")
	assert_true(gs.flags.has("erin.in_watch_cells"), "she is jailed the same day in 5.54 (M36.5)")


func test_numbtongue_reaches_bard_25() -> void:
	var lines := _system("5.53")
	var bard := lines.filter(func(s: Dictionary) -> bool: return s["who"] == "numbtongue" and s["name"] == "[Bard]")
	assert_eq(bard.size(), 1)
	assert_eq(int(bard[0]["level"]), 25)
	assert_true(lines.any(func(s: Dictionary) -> bool: return s["name"] == "[Lightning Melody]"))
	assert_eq(_system("5.51G"), [], "5.51 G shows no System lines")


func test_the_cells_map_holds_prisoners_at_the_bars() -> void:
	assert_eq(_db.maps.errors, [] as Array[String])
	assert_true(_db.maps.areas.has(CELLS))
	var back := (_db.maps.areas[CELLS]["exits"] as Array).any(
			func(e: Dictionary) -> bool: return e["to"] == "liscor_watch_barracks")
	assert_true(back, "the stair goes back up to the barracks")
	var down := (_db.maps.areas["liscor_watch_barracks"]["exits"] as Array).any(
			func(e: Dictionary) -> bool: return e["to"] == CELLS)
	assert_true(down, "the barracks has a stair down to the cells")
	for npc: String in SPOTS:
		var at: Vector2i = SPOTS[npc]
		assert_true(_db.maps.is_walkable(CELLS, at), "%s stands at the bars %s" % [npc, at])
		var talk_from := 0
		for d: Vector2i in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
			var y := at.y + d.y
			if _db.maps.is_walkable(CELLS, at + d) and y >= 4 and y <= 6:
				talk_from += 1
		assert_gt(talk_from, 0, npc + " can be talked to from the corridor")
	var solid_bars := 0
	for o: Dictionary in _db.maps.areas[CELLS]["objects"]:
		if o["kind"] == "cage" and o.get("solid", false):
			solid_bars += 1
	assert_gt(solid_bars, 20, "the rest of the bars block the way")


func test_the_hobs_stand_in_the_cells_after_the_arrest() -> void:
	var gs := _fresh()
	ToyCanon.sleep_through(gs, _db, 172)
	gs.player.place("inn_interior", Vector2i(3, 3))
	_wait_until_hour(gs, 12)
	for id: String in JAILED_HOBS:
		assert_eq(_area_of(gs, id), CELLS, id + " is in the cells")
		assert_eq(_pos_of(gs, id), SPOTS[id], id + " stands at the bars")
	assert_eq(_area_of(gs, "calruz"), CELLS, "Calruz waits in the rune cell")
	assert_eq(_pos_of(gs, "calruz"), SPOTS["calruz"])
	assert_ne(_area_of(gs, "numbtongue"), CELLS, "Numbtongue gets away (5.54)")
	assert_eq(_area_of(gs, "erin_solstice"), CELLS, "Erin is jailed too (5.54, M36.5)")
	assert_eq(_pos_of(gs, "erin_solstice"), SPOTS["erin_solstice"])
	assert_ne(_area_of(gs, "bird"), "inn_watchtower", "no tower post once the tower is smashed")


func test_erin_is_in_her_cell_while_the_flag_holds() -> void:
	var gs := _fresh()
	ToyCanon.sleep_through(gs, _db, 172)
	gs.player.place("inn_interior", Vector2i(3, 3))
	gs.flags["erin.in_watch_cells"] = true  # set by her 5.54 arrest (M36.5)
	_wait_until_hour(gs, 12)
	assert_eq(_area_of(gs, "erin_solstice"), CELLS)
	assert_eq(_pos_of(gs, "erin_solstice"), SPOTS["erin_solstice"], "her cell is just before Calruz's")
	gs.flags["erin.freed_from_the_cells"] = true  # 5.57 (M36.6)
	gs.flags["redfang_hobs.freed_from_the_cells"] = true
	_wait_until_hour(gs, 16)
	assert_ne(_area_of(gs, "erin_solstice"), CELLS, "freed")
	for id: String in JAILED_HOBS:
		assert_ne(_area_of(gs, id), CELLS, id + " is freed")
	assert_eq(_area_of(gs, "calruz"), CELLS, "Calruz stays in his cell")
