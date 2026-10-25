extends GutTest
## M28.6 on the real Book 8 data (5.33 B, Interlude - Blackmage, 5.34, 5.35 H, days 157 - 159): the Grand Queen's
## proxy, Bird the [Singer], Wistram's search teams, the first Raskghar raid on Liscor and the inn (a fight stage on
## inn_hill with an XP window x3), Headscratcher the [Berserker], Yvlon's bone-braced arms and the Pallass teams.
## One talk hook (5.35 H). M32.1: a fight hook on the raid (the player held the inn).
## The game is slept to day 158 once (before_all); each test starts from a copy.

const SEED := 20261016
const DAY := 159
const CHAPTERS := ["5.33B", "interlude_blackmage", "5.34", "5.35H"]
const RAID := "b8.raskghar_raid_the_wandering_inn"
const GUARD := "b8.the_redfangs_guard_the_door_after_the_raid"
const HOOK := "player_stood_with_headscratcher_after_the_raid"
const RAID_HOOK := "player_held_the_inn_in_the_night_raid"
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


func _hook_of(gs: GameState, id: String) -> String:
	var entry: Dictionary = gs.world.history.filter(func(h: Dictionary) -> bool: return h["event"] == id)[0]
	return str(entry.get("hook", ""))


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


func test_the_batch_has_one_stage_and_two_hooks() -> void:
	var ids := _batch_ids()
	assert_eq(ids.size(), 37)
	var stages: Array[String] = []
	var hooks: Array[String] = []
	for id: String in ids:
		var ev: Dictionary = _db.canon.events[id]
		if ev.has("stage"):
			stages.append(id)
		for h: Dictionary in ev.get("hooks", []):
			hooks.append(String(h["id"]))
		assert_ne(ev["location"], "raskghar_camp", id)
		assert_false(ev["effects"].has("kill"), id)
		assert_true(int(ev["window"]["earliest"]) >= 157 and int(ev["window"]["latest"]) <= DAY, id)
	assert_eq(stages, [RAID] as Array[String])
	hooks.sort()
	assert_eq(hooks, [RAID_HOOK, HOOK] as Array[String])
	var h: Dictionary = _db.canon.events[RAID]["hooks"][0]
	assert_eq(h["id"], RAID_HOOK)
	assert_eq(h["then"], "change", "the raid still happens")
	assert_eq([int(h["days"][0]), int(h["days"][1])], [DAY, DAY])
	assert_ne(String(h.get("news", "")), "")
	assert_eq(String(_db.canon.events[GUARD]["canon_ref"]["chapter"]), "5.35H")


func test_the_raid_stage_data_is_sound() -> void:
	var ev: Dictionary = _db.canon.events[RAID]
	var st: Dictionary = ev["stage"]
	assert_eq(st["area"], "inn_hill")
	assert_eq(st["kind"], "fight")
	assert_eq(int(ev["xp_window"]["boost"]), 3)
	assert_eq(ev["xp_window"]["hours"], st["hours"], "the XP window matches the stage hours")
	assert_ne(st["area"], "raskghar_camp")
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


func test_the_raid_comes_at_night_with_the_defenders() -> void:
	var db := DataDb.load_dir()
	ToyCombat.freeze(db)
	var gs := _fresh()
	_wait_for_raid(gs, db)
	@warning_ignore("integer_division")
	var h: int = gs.clock.minute() / 60
	assert_true(h >= 21 and h < 24, "late night")
	var foes := gs.combat.ids().filter(func(id: String) -> bool: return gs.combat.monsters[id].get("stage", "") == RAID)
	assert_true(foes.size() >= 3, "Raskghar on the hill")
	for id: String in foes:
		assert_true(String(gs.combat.monsters[id]["type"]) in RASKGHAR, id)
	FightBot.wait_seconds(gs, db, 25)
	for n: String in ["bird", "badarrow", "shorthilt"]:
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
	var before := gs.world.relationship("erin_solstice", "player")
	ToyCanon.sleep_through(gs, db, DAY)
	assert_eq(gs.world.status(RAID), Director.CHANGED)
	assert_eq(_hook_of(gs, RAID), RAID_HOOK)
	assert_true(gs.flags.has("wandering_inn.earther_held_the_inn_in_the_night_raid"))
	assert_gt(gs.world.relationship("erin_solstice", "player"), before)
	assert_true(gs.flags.has("wandering_inn.raided_by_raskghar"))
	assert_true(gs.flags.has("headscratcher.is_a_berserker"), "the canon still happens")


func test_staying_away_still_sets_the_canon_flags() -> void:
	var gs := _fresh()
	for f: String in ["free_antinium.rejoined_the_hives", "bird.is_a_singer", "bird.has_a_new_composite_bow",
			"wistram.search_teams_for_earthers", "wistram.team_bound_for_liscor", "aaron_vanwell.protected_by_the_revivalists"]:
		assert_true(gs.flags.has(f), f)
	assert_false(gs.flags.has("bird.bow_broken"), "the new bow replaces the broken one")
	ToyCanon.sleep_through(gs, _db, DAY)
	assert_eq(gs.world.status(RAID), Director.DONE)
	assert_false(gs.flags.has("wandering_inn.earther_stood_with_the_redfangs"))
	assert_false(gs.flags.has("wandering_inn.earther_held_the_inn_in_the_night_raid"))
	for f: String in ["izril.moons_nearly_full", "raskghar.awakened_by_the_moons", "liscor.raided_by_raskghar",
			"wandering_inn.raided_by_raskghar", "headscratcher.is_a_berserker", "numbtongue.is_a_bard",
			"rabbiteater.wears_the_liquid_cloak", "yvlon.arms_braced_with_bone", "pisces.may_use_raskghar_and_goblin_bones",
			"liscor.gnolls_missing_after_the_raid", "liscor.cooperation_bounties_on_the_dungeon",
			"dungeon.raskghar_main_camp_is_vast", "pallass.sends_adventurers_to_liscor"]:
		assert_true(gs.flags.has(f), f)
	assert_false(gs.flags.has("yvlon.shield_arm_broken"), "Pisces sets the arm the same night")
	for n: String in ["headscratcher", "bird", "yvlon_byres", "krshia", "erin_solstice"]:
		assert_true(gs.world.is_alive(_db.canon, n), n)


func test_the_rain_and_flood_flags_do_not_change() -> void:
	var gs := _fresh()
	ToyCanon.sleep_through(gs, _db, DAY)
	for f: String in _rain_before:
		assert_eq(gs.flags.has(f), bool(_rain_before[f]), f)
	assert_true(gs.flags.has("izril.rains"), "it still rains in 5.33 - 5.35")


func test_talking_to_headscratcher_or_bird_changes_the_guard_event() -> void:
	var gs := _fresh()
	Commands.settle(gs, _db)
	var who := ""
	for n: String in ["headscratcher", "bird"]:
		var area := _area_of(gs, n)
		if area != "" and _db.maps.areas.has(area) and String(_db.maps.areas[area]["location"]) == "wandering_inn":
			who = n
			break
	assert_ne(who, "", "Headscratcher or Bird is at the inn")
	var npc: Dictionary = gs.npcs.npcs[who]
	var at := Vector2i(int(npc["x"]), int(npc["y"]))
	var placed := false
	for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if _db.maps.is_walkable(String(npc["area"]), at + d):
			gs.player.place(String(npc["area"]), at + d)
			placed = true
			break
	assert_true(placed, "a free side square")
	var r := Commands.interact(gs, _db, who, "talk_with_guest")
	assert_eq(r["error"], "")
	ToyCanon.sleep_through(gs, _db, DAY)
	assert_eq(gs.world.status(GUARD), Director.CHANGED)
	assert_eq(_hook_of(gs, GUARD), HOOK)
	assert_true(gs.flags.has("wandering_inn.earther_stood_with_the_redfangs"))
	assert_true(gs.flags.has("redfang.guard_the_inn_after_the_raid"), "the canon still happens")


func test_level_records_show_the_new_classes() -> void:
	var seen := {}
	for ch: String in CHAPTERS:
		for s: Dictionary in _system(ch):
			assert_ne(s["who"], "ryoka_griffin", "Ryoka never levels")
			seen["%s %s" % [s["who"], s["name"]]] = s["level"]
	assert_eq(int(seen.get("bird [Singer]", -1)), 7)
	assert_true(seen.has("bird [Soothing Melody]"))
	assert_true(seen.has("headscratcher [Berserker]"))
	assert_eq(int(seen.get("headscratcher [Warrior]", -1)), 20)
	assert_eq(int(seen.get("aaron_vanwell [Mage]", -1)), 18)
	assert_true(seen.has("aaron_vanwell [Engineer]"))
