extends GutTest
## M28.9 on the real Book 8 data (5.43, Interlude - Niers, 5.44; days 162 - 163): the failed Gold-rank raid (Cassa
## dies), Vakk and twenty Gnolls sacrificed, Mrsha's grass magic and howl, Niers in Baleros, and the three-door battle
## (a fight stage on raskghar_camp with an XP window x3). Mrsha and Ceria are freed; Calruz goes to the Watch prison;
## Erin reaches [Magical Innkeeper] 36. M32.1: Nokha (flees) and Calruz (yields, last wave) fight on the map, the
## Horns come as one ally wave before him, and two hooks: standing with the Horns against Calruz, reaching the cages.
## The game is slept to day 162 once (before_all); each test starts from a copy.

const SEED := 20261016
const DAY := 163
const CHAPTERS := ["5.43", "interlude_niers", "5.44"]
const BATTLE := "b8.three_doors_open_on_the_raskghar_camp"
const HORNS_EVENT := "b8.the_horns_bring_down_calruz"
const RESCUE := "b8.lyonette_and_moore_take_back_mrsha"
const CALRUZ_HOOK := "player_stood_with_the_horns_against_calruz"
const CAGES_HOOK := "player_reached_the_cages"
const CAMP := "raskghar_camp"
const INN_DOOR := "albez_door"
const NEXT_TO_INN_DOOR := Vector2i(3, 12)
const CAMP_DOOR := "raskghar_door_north"
const CAGES := "raskghar_cages"
const CALRUZ := "calruz"
const NOKHA := "nokha_awakened"
const RASKGHAR := ["awakened_raskghar", "raskghar_armoured", "not_gnoll", CALRUZ, NOKHA]
const HORNS := ["ceria_springwalker", "yvlon_byres", "pisces", "ksmvr"]
const DOORS := ["raskghar_door_north", "raskghar_door_west", "raskghar_door_east"]
const CAPTIVE := ["mrsha.taken_by_the_raskghar", "ceria.taken_by_the_raskghar", "calruz.holds_ceria",
		"mrsha.caged_in_the_raskghar_camp"]

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


## Walks in through Erin's magic door (the inn's albez_door, link raskghar_camp), then waits for nightfall.
func _wait_for_battle(gs: GameState, db: DataDb) -> void:
	gs.player.place("inn_interior", NEXT_TO_INN_DOOR)
	Commands.settle(gs, db)
	assert_eq(Commands.portal(gs, db, INN_DOOR, CAMP), "", "Erin's door opens into the camp")
	assert_eq(gs.player.area, CAMP)
	for i in 160:
		if gs.world.staged.has(BATTLE):
			break
		assert_true(Commands.wait(gs, db, 600) >= 0, "wait")
	assert_true(gs.world.staged.has(BATTLE), "the battle is staged")


func _area_of(gs: GameState, id: String) -> String:
	var n: Dictionary = gs.npcs.npcs.get(id, {})
	return "" if n.is_empty() else String(n["area"])


func _stage_foe(gs: GameState) -> String:
	var best := ""
	var best_d := 1 << 30
	for id: String in gs.combat.ids():
		var m: Dictionary = gs.combat.monsters[id]
		if m["state"] != CombatState.HOSTILE or m.get("stage", "") != BATTLE:
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


func _hook_of(gs: GameState, id: String) -> String:
	var entry: Dictionary = gs.world.history.filter(func(h: Dictionary) -> bool: return h["event"] == id)[0]
	return str(entry.get("hook", ""))


## The cages object as data (shown or not).
func _cages() -> Dictionary:
	for o: Dictionary in _db.maps.areas[CAMP]["objects"]:
		if o["id"] == CAGES:
			return o
	return {}


func _system(chapter: String) -> Array:
	var f := FileAccess.open("res://data/canon/book8/chapters/%s.json" % chapter, FileAccess.READ)
	var doc: Dictionary = JSON.parse_string(f.get_as_text())
	return doc["system"]


func _near(a: Vector2i, b: Vector2i) -> bool:
	return absi(a.x - b.x) + absi(a.y - b.y) <= 1


func test_the_batch_has_one_stage_and_two_hooks() -> void:
	var ids := _batch_ids()
	assert_eq(ids.size(), 26)
	var stages: Array[String] = []
	var killed: Array[String] = []
	var hooks: Array[String] = []
	for id: String in ids:
		var ev: Dictionary = _db.canon.events[id]
		if ev.has("stage"):
			stages.append(id)
		for h: Dictionary in ev.get("hooks", []):
			hooks.append("%s %s" % [id, h["id"]])
			assert_eq(h["then"], "change", h["id"] + " keeps the canon and adds to it")
			assert_eq([int(h["days"][0]), int(h["days"][1])], [DAY, DAY], h["id"])
			assert_ne(String(h.get("news", "")), "", h["id"] + " has news")
		if id != BATTLE:
			assert_false(ev.has("xp_window"), id)
		for n: String in ev["effects"].get("kill", []):
			killed.append(n)
		assert_true(int(ev["window"]["earliest"]) >= 162 and int(ev["window"]["latest"]) <= DAY, id)
		if String(ev["canon_ref"]["chapter"]) == "interlude_niers":
			assert_eq(ev["location"], "baleros", id)
	assert_eq(stages, [BATTLE] as Array[String])
	hooks.sort()
	assert_eq(hooks, ["%s %s" % [RESCUE, CAGES_HOOK], "%s %s" % [HORNS_EVENT, CALRUZ_HOOK]] as Array[String])
	killed.sort()
	assert_eq(killed, ["cassa", "vakk"] as Array[String], "Cassa and Vakk die by name; Nokha only vanishes")


## M32.1: Calruz yields and Nokha flees (escape): neither can die on the map. Calruz is the one most dangerous foe of
## the battle, so the fight's records name him once he is in it (Combat.end_fight), and he looks like his NPC.
func test_calruz_and_nokha_cannot_die_and_calruz_names_the_fight() -> void:
	var foes: Dictionary = _db.combat.enemies
	for type: String in [CALRUZ, NOKHA]:
		assert_true(foes.has(type), type)
		assert_true(foes[type].has("escape"), type + " cannot die")
		assert_eq(int(foes[type]["canon_ref"]["book"]), 8, type)
	assert_false(foes[CALRUZ].has("look"), "drawn with his own NPC sheet (calruz)")
	assert_false(foes[NOKHA].has("ranged"), "Nokha is a swordswoman, not a caster")
	assert_lt(int(foes[NOKHA]["act_seconds"]), int(foes["awakened_raskghar"]["act_seconds"]), "Nokha is very fast")
	var types := {}
	var st: Dictionary = _db.canon.events[BATTLE]["stage"]
	for f: Dictionary in st["foes"]:
		types[f["enemy"]] = true
	for w: Dictionary in st["waves"]:
		for e: String in w.get("foes", []):
			types[e] = true
	for t: String in types:
		if t != CALRUZ:
			assert_lt(float(foes[t]["danger"]), float(foes[CALRUZ]["danger"]), t + " is less dangerous than Calruz")


func test_the_battle_stage_data_is_sound() -> void:
	var ev: Dictionary = _db.canon.events[BATTLE]
	var st: Dictionary = ev["stage"]
	assert_eq(st["area"], CAMP)
	assert_eq(st["kind"], "fight")
	assert_eq(int(ev["xp_window"]["boost"]), 3)
	assert_eq(ev["xp_window"]["hours"], st["hours"], "the XP window matches the stage hours")
	for f: String in st["when_flags"]:
		var setter := false
		for id: String in _db.canon.events:
			var other: Dictionary = _db.canon.events[id]
			if f in other["effects"].get("set_flags", []) and int(other["window"]["latest"]) < DAY:
				setter = true
		assert_true(setter, f + " is set by an earlier night")
	var walk := func(p: Array) -> bool: return _db.maps.is_walkable(CAMP, Vector2i(int(p[0]), int(p[1])))
	for f: Dictionary in st["foes"]:
		assert_true(String(f["enemy"]) in RASKGHAR, f["enemy"])
		assert_true(walk.call(f["pos"]), "foe tile %s" % [f["pos"]])
	var doors := {}
	for o: Dictionary in _db.maps.objects_on(CAMP):
		if o["id"] in DOORS:
			doors[o["id"]] = Vector2i(int(o["at"][0]), int(o["at"][1]))
	assert_eq(doors.size(), 3)
	var fronts := {}
	var last_foe := -1
	var last_ally_only := -1
	var waves: Array = st["waves"]
	for i in waves.size():
		var w: Dictionary = waves[i]
		assert_true(walk.call(w["from"]), "wave %d tile" % i)
		for e: String in w.get("foes", []):
			assert_true(e in RASKGHAR, e)
		if w.has("foes"):
			last_foe = i
		else:
			last_ally_only = i
			var from := Vector2i(int(w["from"][0]), int(w["from"][1]))
			for d: String in doors:
				if _near(from, doors[d]):
					fronts[d] = true
		for a: String in w.get("allies", []):
			assert_true(_db.behaviour.npcs.has(a), a)
			assert_true(_db.behaviour.npcs[a].has("combat"), a + " has combat")
	assert_eq(fronts.size(), 3, "allies come through all three doors")
	assert_true(last_ally_only < last_foe, "ally-only waves come before the last foe wave")
	assert_true(int(waves[0]["after_seconds"]) > 0, "the first allies are delayed")
	assert_eq(waves[last_foe].get("foes", []), [CALRUZ], "Calruz comes alone, in the last wave")
	var horns := -1
	var nokha := -1
	for i in waves.size():
		var allies: Array = waves[i].get("allies", [])
		if HORNS.all(func(h: String) -> bool: return allies.has(h)):
			horns = i
		if (waves[i].get("foes", []) as Array).has(NOKHA):
			nokha = i
	assert_true(horns >= 0, "the four Horns come as one wave")
	assert_true(horns < last_foe, "the Horns come before Calruz")
	assert_true(nokha >= 0 and nokha < horns, "Nokha comes before the Horns")
	for f: Dictionary in st["foes"]:
		assert_false(f["enemy"] in [CALRUZ, NOKHA], "Calruz and Nokha are not in the first foes")
	var cages := _cages()
	assert_false(cages.is_empty(), "the camp has the cages")
	assert_true(walk.call(cages["at"]), "the cages stand on the floor")
	assert_true(int(cages["at"][1]) >= 16, "the cages are at the back of the camp")
	assert_eq(cages["kind"], "cage")
	assert_eq(cages["actions"], ["comfort_someone"])
	assert_eq(cages["when_flags"], ["raskghar.camp_holds_the_gnoll_captives"], "gone once the captives are home")


func test_the_battle_opens_at_nightfall_with_the_adventurers() -> void:
	var db := DataDb.load_dir()
	ToyCombat.freeze(db)
	var gs := _fresh()
	_wait_for_battle(gs, db)
	@warning_ignore("integer_division")
	var h: int = gs.clock.minute() / 60
	assert_true(h >= 18 and h < 23, "nightfall")
	assert_eq(XpWindow.boost(gs, db), 3, "the XP window is open")
	var foes := gs.combat.ids().filter(func(id: String) -> bool: return gs.combat.monsters[id].get("stage", "") == BATTLE)
	assert_true(foes.size() >= 4, "Raskghar in the camp")
	for id: String in foes:
		assert_true(String(gs.combat.monsters[id]["type"]) in RASKGHAR, id)
	FightBot.wait_seconds(gs, db, 25)
	for n: String in ["jelaqua", "halrac", "ylawes_byres"]:
		assert_eq(_area_of(gs, n), CAMP, n)


func test_the_battle_can_be_fought_through() -> void:
	var db := DataDb.load_dir()
	ToyCombat.freeze(db)
	ToyCombat.always_hit(db)
	var gs := _fresh()
	_wait_for_battle(gs, db)
	var seen := {}
	for i in 5000:
		if _stage_foe(gs) == "" and not gs.combat.has_fight():
			break
		_fight_turn(gs, db)
		for n: String in HORNS:
			if _area_of(gs, n) == CAMP:
				seen[n] = true
		for id: String in gs.combat.ids():
			if gs.combat.monsters[id]["type"] in [CALRUZ, NOKHA]:
				seen[gs.combat.monsters[id]["type"]] = true
	assert_eq(_stage_foe(gs), "", "the Raskghar are down")
	assert_has(gs.combat.lines, db.combat.enemies[CALRUZ]["escape"]["line"], "Calruz yields")
	for n: String in HORNS + [CALRUZ, NOKHA]:
		assert_true(seen.has(n), n + " was in the battle")
	assert_false(gs.combat.ids().any(func(id: String) -> bool: return gs.combat.monsters[id]["type"] == NOKHA),
			"Nokha got away (the log keeps only the last lines)")
	var before := {}
	for n: String in HORNS:
		before[n] = gs.world.relationship(n, "player")
	ToyCanon.sleep_through(gs, db, DAY)
	assert_eq(gs.world.status(BATTLE), Director.DONE)
	assert_true(gs.flags.has("raskghar.camp_stormed_through_three_doors"))
	assert_true(gs.flags.has("calruz.in_watch_prison"), "the canon still happens")
	assert_true(gs.world.is_alive(db.canon, "calruz"), "Calruz lives for his trial")
	assert_true(gs.world.is_alive(db.canon, "nokha"), "Nokha only vanishes")
	assert_eq(gs.world.status(HORNS_EVENT), Director.CHANGED)
	assert_eq(_hook_of(gs, HORNS_EVENT), CALRUZ_HOOK)
	assert_true(gs.flags.has("horns_of_hammerad.earther_stood_with_them_against_calruz"))
	assert_true(gs.flags.has("calruz.beaten_by_the_horns"), "the Horns still bring him down")
	for n: String in HORNS:
		assert_gt(gs.world.relationship(n, "player"), int(before[n]), n + " remembers")
	assert_eq(gs.world.status(RESCUE), Director.DONE, "the cages were not reached")
	assert_true(gs.flags.has("mrsha.rescued_from_the_raskghar"))


func test_reaching_the_cages_changes_the_rescue() -> void:
	var gs := _fresh()
	gs.player.place("inn_interior", NEXT_TO_INN_DOOR)
	Commands.settle(gs, _db)
	assert_eq(Commands.portal(gs, _db, INN_DOOR, CAMP), "")
	var at := Vector2i(int(_cages()["at"][0]), int(_cages()["at"][1]))
	gs.player.place(CAMP, at + Vector2i(0, -1))
	Commands.settle(gs, _db)
	var shown := _db.maps.objects_on(CAMP).filter(func(o: Dictionary) -> bool: return o["id"] == CAGES)
	assert_eq(shown.size(), 1, "the cages stand while the captives are held")
	var before := gs.world.relationship("mrsha", "player")
	var r := Commands.interact(gs, _db, CAGES, "comfort_someone")
	assert_eq(r["error"], "")
	assert_eq(r["record"]["context"]["location"], CAMP)
	ToyCanon.sleep_through(gs, _db, DAY)
	assert_eq(gs.world.status(RESCUE), Director.CHANGED)
	assert_eq(_hook_of(gs, RESCUE), CAGES_HOOK)
	assert_true(gs.flags.has("wandering_inn.earther_reached_the_cages"))
	assert_true(gs.flags.has("mrsha.rescued_from_the_raskghar"), "Lyonette and Moore still free Mrsha")
	assert_gt(gs.world.relationship("mrsha", "player"), before)
	assert_eq(gs.world.status(HORNS_EVENT), Director.DONE, "no fight, no Calruz hook")
	Commands.settle(gs, _db)
	assert_false(_db.maps.objects_on(CAMP).any(func(o: Dictionary) -> bool: return o["id"] == CAGES),
			"the cages are empty and gone after the battle")


func test_erins_door_leads_into_the_camp_and_home_until_the_tribe_breaks() -> void:
	var gs := _fresh()
	gs.player.place("inn_interior", NEXT_TO_INN_DOOR)
	Commands.settle(gs, _db)
	assert_eq(Commands.portal(gs, _db, INN_DOOR, CAMP), "")
	assert_eq(gs.player.area, CAMP)
	var door := Vector2i.ZERO
	for o: Dictionary in _db.maps.objects_on(CAMP):
		if o["id"] == CAMP_DOOR:
			door = Vector2i(int(o["at"][0]), int(o["at"][1]))
	gs.player.place(CAMP, door + Vector2i(0, 1))
	Commands.settle(gs, _db)
	assert_eq(Commands.portal(gs, _db, CAMP_DOOR), "", "the north door goes home")
	assert_eq(gs.player.area, "inn_interior")
	var wake: Dictionary = _db.rules["combat"]["knockout"]["wake"]
	assert_eq(String(wake.get(CAMP, {}).get("area", "")), "inn_interior", "a knock-out in the camp wakes you at the inn")
	ToyCanon.sleep_through(gs, _db, DAY)
	assert_true(gs.flags.has("raskghar.broken"))
	gs.player.place("inn_interior", NEXT_TO_INN_DOOR)
	Commands.settle(gs, _db)
	assert_ne(Commands.portal(gs, _db, INN_DOOR, CAMP), "", "the camp link shuts once the tribe is broken")
	assert_eq(gs.player.area, "inn_interior")


func test_day_162_the_raid_fails_and_cassa_dies() -> void:
	var gs := _fresh()
	for f: String in ["raskghar.camp_raid_failed", "pisces.emergency_door_destroyed", "cave_goblins.desert_the_raskghar",
			"adventurers.have_no_new_plan"]:
		assert_true(gs.flags.has(f), f)
	for f: String in CAPTIVE:
		assert_true(gs.flags.has(f), f + " still set before the battle")
	assert_false(gs.world.is_alive(_db.canon, "cassa"), "Nokha kills Cassa in the raid")
	assert_true(gs.world.is_alive(_db.canon, "vakk"), "Vakk dies after midnight, on day 163")


func test_staying_away_still_frees_the_captives() -> void:
	var gs := _fresh()
	ToyCanon.sleep_through(gs, _db, DAY)
	assert_eq(gs.world.status(BATTLE), Director.DONE)
	for id: String in [HORNS_EVENT, RESCUE]:
		assert_eq(gs.world.status(id), Director.DONE, id + " runs as canon")
	for f: String in ["horns_of_hammerad.earther_stood_with_them_against_calruz", "wandering_inn.earther_reached_the_cages"]:
		assert_false(gs.flags.has(f), f)
	for f: String in CAPTIVE + ["calruz.alive_in_the_dungeon", "mrsha.recaptured_by_nokha"]:
		assert_false(gs.flags.has(f), f + " is cleared")
	for f: String in ["mrsha.rescued_from_the_raskghar", "ceria.freed_from_the_raskghar", "calruz.in_watch_prison",
			"calruz.awaits_trial", "raskghar.broken", "nokha.vanished_in_the_melee", "liscor.freed_gnolls_return",
			"liscor.thanks_the_goblins_for_the_victory", "erin.has_natural_allies_goblins",
			"wandering_inn.local_landmark_of_liscor", "wandering_inn.adventurer_hub", "wandering_inn.bridge_to_liscor_finished"]:
		assert_true(gs.flags.has(f), f)
	for n: String in ["vakk", "cassa"]:
		assert_false(gs.world.is_alive(_db.canon, n), n + " is dead")
	for n: String in ["calruz", "nokha", "mrsha", "ceria_springwalker", "elirr", "headscratcher", "moore", "pebblesnatch"]:
		assert_true(gs.world.is_alive(_db.canon, n), n)


func test_erin_reaches_level_36_with_two_skills() -> void:
	var seen := {}
	for ch: String in CHAPTERS:
		for s: Dictionary in _system(ch):
			assert_ne(s["who"], "ryoka_griffin", "Ryoka never levels")
			seen["%s %s" % [s["who"], s["name"]]] = s["level"]
	assert_eq(int(seen.get("erin_solstice [Magical Innkeeper]", -1)), 36)
	for k: String in ["erin_solstice [Natural Allies: Goblins]", "erin_solstice [Inn: Local Landmark: Liscor]",
			"calruz [Thick Skin]", "calruz [Whirlwind Cleave]"]:
		assert_true(seen.has(k), k)


func test_the_rain_and_flood_flags_do_not_change() -> void:
	var gs := _fresh()
	ToyCanon.sleep_through(gs, _db, DAY)
	for f: String in _rain_before:
		assert_eq(gs.flags.has(f), bool(_rain_before[f]), f)
	assert_true(gs.flags.has("izril.rains"), "it still rains in 5.43 - 5.44")
	assert_true(gs.flags.has("izril.flood"), "the flood is still up")
