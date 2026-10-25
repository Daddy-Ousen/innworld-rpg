extends GutTest
## M28.7 on the real Book 8 data (5.36, 5.37 G, 5.38; days 151 - 161): the first great dive, Pebblesnatch spared,
## Greydath and Rags spared "an hour to run" in the north, the second night raid, and the daylight raid on the inn
## (a fight stage on inn_hill with an XP window x3). Mrsha and Ceria are taken; Calruz is revealed. M32.1: one fight
## hook on the daylight raid (the player fought it; Mrsha is still taken).
## The game is slept to day 160 once (before_all); each test starts from a copy.

const SEED := 20261016
const DAY := 161
const CHAPTERS := ["5.36", "5.37G", "5.38"]
const RAID := "b8.raskghar_raid_the_inn_by_daylight"
const RAID_HOOK := "player_fought_the_daylight_raid"
const MOON := "raskghar.awakened_by_the_moons"
const HILL_SPOT := Vector2i(16, 13)
const RASKGHAR := ["awakened_raskghar", "raskghar_armoured", "not_gnoll", "cave_goblin"]

var _db: DataDb
var _base := ""
var _rain_before := {}


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])
	assert_eq(_db.canon.errors, [] as Array[String])
	var gs := GameState.new_game(SEED, _db)
	ToyCanon.sleep_through(gs, _db, DAY - 1)
	_base = gs.to_json()
	for f: String in ["izril.rains", "izril.flood"]:
		_rain_before[f] = gs.flags.has(f)


func _fresh() -> GameState:
	var gs := GameState.from_json(_base)
	assert_eq(gs.clock.day(), DAY)
	return gs


func _batch_ids() -> Array[String]:
	var ids: Array[String] = []
	for id: String in _db.canon.events:
		var ref: Dictionary = _db.canon.events[id]["canon_ref"]
		if int(ref["book"]) == 8 and String(ref["chapter"]) in CHAPTERS and not _db.canon.alt_only.has(id):
			ids.append(id)
	return ids


func _wait_for_raid(gs: GameState, db: DataDb) -> void:
	gs.player.place("inn_hill", HILL_SPOT)
	Commands.settle(gs, db)
	for i in 160:
		if gs.world.staged.has(RAID):
			break
		assert_true(Commands.wait(gs, db, 600) >= 0, "wait")
	assert_true(gs.world.staged.has(RAID), "the raid is staged")


func _area_of(gs: GameState, id: String) -> String:
	var n: Dictionary = gs.npcs.npcs.get(id, {})
	return "" if n.is_empty() else String(n["area"])


func _stage_foe(gs: GameState) -> String:
	var best := ""
	var best_d := 1 << 30
	for id: String in gs.combat.ids():
		var m: Dictionary = gs.combat.monsters[id]
		if m["state"] != CombatState.HOSTILE or m.get("stage", "") != RAID:
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
	var f := FileAccess.open("res://data/canon/book8/chapters/%s.json" % chapter, FileAccess.READ)
	var doc: Dictionary = JSON.parse_string(f.get_as_text())
	return doc["system"]


func test_the_batch_has_one_stage_and_one_hook() -> void:
	var ids := _batch_ids()
	assert_eq(ids.size(), 41)
	var stages: Array[String] = []
	var killed: Array[String] = []
	for id: String in ids:
		var ev: Dictionary = _db.canon.events[id]
		if ev.has("stage"):
			stages.append(id)
		if id != RAID:
			assert_false(ev.has("hooks"), id + " has no hook")
		assert_ne(ev["location"], "raskghar_camp", id)
		for n: String in ev["effects"].get("kill", []):
			killed.append(n)
		assert_true(int(ev["window"]["earliest"]) >= 151 and int(ev["window"]["latest"]) <= DAY, id)
	assert_eq(stages, [RAID] as Array[String])
	var hooks: Array = _db.canon.events[RAID]["hooks"]
	assert_eq(hooks.size(), 1)
	assert_eq(hooks[0]["id"], RAID_HOOK)
	assert_eq(hooks[0]["then"], "change", "Mrsha is still taken")
	assert_eq([int(hooks[0]["days"][0]), int(hooks[0]["days"][1])], [DAY, DAY])
	assert_ne(String(hooks[0].get("news", "")), "")
	assert_eq(killed, ["fess"] as Array[String], "only Fess dies by name")
	for id: String in ["b8.the_great_raid_dives_the_rift", "b8.greydath_duels_garen"]:
		assert_false(_db.canon.events[id].has("stage"), id + " is a plain event")
		assert_false(_db.canon.events[id].has("xp_window"), id)


func test_the_daylight_stage_data_is_sound() -> void:
	var ev: Dictionary = _db.canon.events[RAID]
	var st: Dictionary = ev["stage"]
	assert_eq(st["area"], "inn_hill")
	assert_eq(st["kind"], "fight")
	assert_eq(int(ev["xp_window"]["boost"]), 3)
	assert_eq(ev["xp_window"]["hours"], st["hours"], "the XP window matches the stage hours")
	assert_true(int(st["hours"][0]) >= 6 and int(st["hours"][1]) <= 20, "daylight hours")
	assert_true(MOON in ev["requires"]["flags"], "the full moons drive the raid")
	for f: Dictionary in st["foes"]:
		assert_true(String(f["enemy"]) in RASKGHAR, f["enemy"])
	var last_foe := -1
	var last_ally_only := -1
	var waves: Array = st["waves"]
	for i in waves.size():
		var w: Dictionary = waves[i]
		for e: String in w.get("foes", []):
			assert_true(e in RASKGHAR, e)
		if w.has("foes"):
			last_foe = i
		else:
			last_ally_only = i
		for a: String in w.get("allies", []):
			assert_true(_db.behaviour.npcs.has(a), a)
			assert_true(_db.behaviour.npcs[a].has("combat"), a + " has combat")
	assert_true(last_ally_only < last_foe, "ally-only waves come before the last foe wave")
	assert_true(int(waves[0]["after_seconds"]) > 0, "the first allies are delayed")


func test_the_raid_comes_by_day_with_the_defenders() -> void:
	var db := DataDb.load_dir()
	ToyCombat.freeze(db)
	var gs := _fresh()
	_wait_for_raid(gs, db)
	@warning_ignore("integer_division")
	var h: int = gs.clock.minute() / 60
	assert_true(h >= 15 and h < 18, "late afternoon")
	var foes := gs.combat.ids().filter(func(id: String) -> bool: return gs.combat.monsters[id].get("stage", "") == RAID)
	assert_true(foes.size() >= 3, "Raskghar on the hill")
	for id: String in foes:
		assert_true(String(gs.combat.monsters[id]["type"]) in RASKGHAR, id)
	FightBot.wait_seconds(gs, db, 25)
	for n: String in ["lyonette", "bird"]:
		assert_eq(_area_of(gs, n), "inn_hill", n)


func test_the_raid_can_be_fought_through() -> void:
	var db := DataDb.load_dir()
	ToyCombat.freeze(db)
	ToyCombat.always_hit(db)
	var gs := _fresh()
	_wait_for_raid(gs, db)
	for i in 4000:
		if _stage_foe(gs) == "" and not gs.combat.has_fight():
			break
		_fight_turn(gs, db)
	assert_eq(_stage_foe(gs), "", "the Raskghar are down")
	var before := gs.world.relationship("lyonette", "player")
	ToyCanon.sleep_through(gs, db, DAY)
	assert_eq(gs.world.status(RAID), Director.CHANGED)
	var entry: Dictionary = gs.world.history.filter(func(h: Dictionary) -> bool: return h["event"] == RAID)[0]
	assert_eq(str(entry.get("hook", "")), RAID_HOOK)
	assert_true(gs.flags.has("wandering_inn.earther_fought_the_daylight_raid"))
	assert_gt(gs.world.relationship("lyonette", "player"), before)
	assert_true(gs.flags.has("wandering_inn.raided_by_daylight"))
	assert_true(gs.flags.has("mrsha.taken_by_the_raskghar"), "the canon still happens")


func test_the_dive_night_and_north_flags_are_set_by_day_161() -> void:
	var gs := _fresh()
	for f: String in ["dungeon.first_great_raid", "pebblesnatch.spared_by_the_redfangs", "calruz.found_cerias_mark",
			"klbkch.lends_painted_soldiers_to_the_inn", "liscor.second_night_raid_repelled", "halrac.caught_birds_arrow",
			"griffon_hunt.dives_with_the_horns", "greydath.alive_and_seen", "rags.spared_an_hour_to_run",
			"tyrion.plan_runs_fourteen_days", "rags.is_chieftain_level_24", "flooded_waters.driven_out_of_lancrel"]:
		assert_true(gs.flags.has(f), f)
	for f: String in ["lancrel.fallen_to_goblins", "halfseekers.dive_with_the_horns", "griffon_hunt.dives_with_the_silver_swords"]:
		assert_false(gs.flags.has(f), f + " is cleared")
	assert_true(gs.flags.has("izril.moons_nearly_full"), "not yet full before day 161")
	for n: String in ["pebblesnatch", "greybeard", "garen", "rags", "redscar", "minerva", "calruz"]:
		assert_true(gs.world.is_alive(_db.canon, n), n)


func test_staying_away_still_takes_mrsha_and_ceria() -> void:
	var gs := _fresh()
	ToyCanon.sleep_through(gs, _db, DAY)
	assert_eq(gs.world.status(RAID), Director.DONE)
	assert_false(gs.flags.has("wandering_inn.earther_fought_the_daylight_raid"))
	for f: String in ["izril.moons_full", MOON, "liscor.walls_held_by_day", "wandering_inn.raided_by_daylight",
			"mrsha.taken_by_the_raskghar", "ceria.taken_by_the_raskghar", "raskghar.ordered_to_take_mrsha_and_ceria",
			"liscor.knows_a_one_armed_minotaur_leads_the_raskghar", "calruz.revealed_as_the_raskghar_great_chieftain",
			"calruz.alive_in_the_dungeon", "calruz.holds_ceria", "mrsha.caged_in_the_raskghar_camp",
			"bird.apologised_to_halrac", "wandering_inn.bear_traps_buried"]:
		assert_true(gs.flags.has(f), f)
	assert_false(gs.flags.has("izril.moons_nearly_full"), "the moons are full now")
	assert_false(gs.flags.has("mrsha.sent_to_celum_for_the_night"), "Mrsha came home at dawn")
	assert_false(gs.world.is_alive(_db.canon, "fess"), "Fess dies on the trap")
	for n: String in ["mrsha", "ceria_springwalker", "calruz", "lyonette", "erin_solstice", "halrac", "bird"]:
		assert_true(gs.world.is_alive(_db.canon, n), n)


func test_the_rain_and_flood_flags_do_not_change() -> void:
	var gs := _fresh()
	ToyCanon.sleep_through(gs, _db, DAY)
	for f: String in _rain_before:
		assert_eq(gs.flags.has(f), bool(_rain_before[f]), f)
	assert_true(gs.flags.has("izril.rains"), "it still rains in 5.36 - 5.38")
	assert_true(gs.flags.has("izril.flood"), "the flood is still up")


func test_level_records_show_rags_at_24() -> void:
	var seen := {}
	for ch: String in CHAPTERS:
		for s: Dictionary in _system(ch):
			assert_ne(s["who"], "ryoka_griffin", "Ryoka never levels")
			seen["%s %s" % [s["who"], s["name"]]] = s["level"]
	assert_eq(int(seen.get("rags [Chieftain]", -1)), 24)
	for k: String in ["rags [Tribe: Rapid Reload]", "rags [Flashfire Spellcraft]", "rags [Burning Blades]",
			"redscar [Raid Leader]", "halrac [Arrow Grab]"]:
		assert_true(seen.has(k), k)
