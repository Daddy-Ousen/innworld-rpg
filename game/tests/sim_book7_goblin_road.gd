extends GutTest
## M19.8 on the real Book 7 data (5.19 G, 5.20 G, days 141 - 143): Garen and Tremborag bar Dwarfhalls Rest,
## Rags's march, the road battle, Kerrig kept, Welca away, Rags turns south, [Chieftain] 20. All off the map:
## no stage, no hook, no xp_window. Slept to day 140 once (before_all).

const SEED := 20261011

var _db: DataDb
var _base := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])
	var gs := GameState.new_game(SEED, _db)
	ToyCanon.sleep_through(gs, _db, 139)
	_base = gs.to_json()


func _at_day(day: int) -> GameState:
	var gs := GameState.from_json(_base)
	if day > 140:
		ToyCanon.sleep_through(gs, _db, day - 1)
	assert_eq(gs.clock.day(), day)
	return gs


func _batch_ids() -> Array[String]:
	var ids: Array[String] = []
	for id: String in _db.canon.events:
		var ref: Dictionary = _db.canon.events[id]["canon_ref"]
		if int(ref["book"]) == 7 and String(ref["chapter"]) in ["5.19G", "5.20G"]:
			ids.append(id)
	return ids


func test_the_batch_is_off_map_and_in_order() -> void:
	var ids := _batch_ids()
	assert_eq(ids.size(), 21)
	for id: String in ids:
		var ev: Dictionary = _db.canon.events[id]
		assert_false(ev.has("stage"), id)
		assert_false(ev.has("hooks"), id)
		assert_false(ev.has("xp_window"), id)
		assert_true(int(ev["window"]["earliest"]) >= 141 and int(ev["window"]["latest"]) <= 143, id)
		assert_false(ev["effects"].has("kill"), id)
		for dep: String in ev["depends_on"]:
			assert_true(_db.canon.events.has(dep), dep)
			assert_true(int(_db.canon.events[dep]["window"]["earliest"]) <= int(ev["window"]["earliest"]), id + " after " + dep)
	assert_true(_db.canon.events.has("b7.garen_and_tremborag_agree_to_hold_the_mountain"))
	assert_eq(_db.canon.events["b7.garen_and_tremborag_agree_to_hold_the_mountain"]["window"]["earliest"], 141)
	assert_eq(_db.canon.events["b7.rags_reaches_chieftain_level_20"]["window"]["earliest"], 143)


func test_day_141_is_the_mountain() -> void:
	var gs := _at_day(141)
	ToyCanon.sleep_through(gs, _db, 141)
	for f: String in ["garen.feels_the_goblin_lord_coming", "dwarfhalls_rest.barred_against_the_goblin_lord",
			"tremborag.refused_the_goblin_lord", "garen.carries_a_key_to_velans_secret"]:
		assert_true(gs.flags.has(f), f)
	assert_false(gs.flags.has("humans.army_routed_on_the_road"))


func test_day_142_is_the_march_and_the_road_battle() -> void:
	var gs := _at_day(142)
	ToyCanon.sleep_through(gs, _db, 142)
	for f: String in ["flooded_waters.left_the_lake_camp", "flooded_waters.makes_fly_whisks", "pyrite.saved_welca",
			"rags.chose_redfang_style_punishment", "pyrite.casts_stone_magic_by_chewing_gems", "pyrite.wields_kerrigs_flame_battleaxe",
			"humans.army_routed_on_the_road", "frostfeeder.saved_by_flooded_waters", "welca.escaped_the_goblins",
			"kerrig.beat_five_hobs_unarmed", "flooded_waters.burned_the_human_dead", "rags.heads_south_away_from_the_humans"]:
		assert_true(gs.flags.has(f), f)
	assert_false(gs.flags.has("rags.chieftain_level_20"))


func test_day_143_rags_reaches_level_20_and_nobody_named_dies() -> void:
	var gs := _at_day(143)
	ToyCanon.sleep_through(gs, _db, 143)
	assert_true(gs.flags.has("rags.chieftain_level_20"))
	assert_true(gs.flags.has("rags.has_tribe_scavenger_armor"))
	for id: String in ["rags", "pyrite", "garen", "tremborag", "redscar", "kerrig_louis", "welca_caveis"]:
		assert_true(gs.world.is_alive(_db.canon, id), id)
