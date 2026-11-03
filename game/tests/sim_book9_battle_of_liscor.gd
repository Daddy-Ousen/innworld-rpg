extends GutTest
## M36.9 on the real Book 9 data (5.62 and Interlude - Thereafter, days 176 - 180): the battle of Liscor. User picks
## (2026-11-03): one fight stage (the gate battle on liscor_gate, 17 - 21, XP tier 2), no hook. Ten named kills; Numbtongue,
## Purple Smile and Osthia live. Slept to day 174 once (before_all); each test starts from a copy.

const SEED := 20261105
const CHAPTERS := ["5.62", "interlude_thereafter"]
const FIGHT := "b9.the_east_gate_breaks_and_the_drakes_sortie"
const KILLS := ["headscratcher", "yellow_splatters", "spiderslicer", "shorthilt", "garen", "goblin_lord", "eater_of_spears", "noears", "pyrite", "sir_vumat"]
const FOE_TYPES := ["zombie", "ghoul", "goblin_lord_soldier", "draug"]
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


func test_the_batch_has_one_fight_no_hook_and_ten_kills() -> void:
	var ids := _batch_ids()
	assert_eq(ids.size(), 41)
	var fights: Array[String] = []
	var killed: Array[String] = []
	for id: String in ids:
		var ev: Dictionary = _db.canon.events[id]
		if ev.has("stage"):
			fights.append(id)
			assert_eq(ev["stage"]["kind"], "fight")
			assert_true(_db.canon.foreshadows.has(id), id + " has a signpost")
		assert_false(ev.has("hooks"), id + ": no hook (user pick)")
		assert_eq(ev.has("xp_window"), id == FIGHT, id)
		assert_eq(ev["window"]["confidence"], "guess", id)
		assert_true(int(ev["window"]["earliest"]) >= 176 and int(ev["window"]["latest"]) <= 180, id)
		for n: String in ev["effects"].get("kill", []):
			killed.append(n)
			assert_true(ev["requires"]["alive"].has(n), id + ": the victim must be alive")
		for dep: String in ev["depends_on"]:
			assert_true(_db.canon.events.has(dep), dep)
	assert_eq(fights, [FIGHT] as Array[String])
	killed.sort()
	var want: Array = KILLS.duplicate()
	want.sort()
	assert_eq(killed, want, "ten named dead, nobody else")


func test_the_fight_data_is_sound() -> void:
	var ev: Dictionary = _db.canon.events[FIGHT]
	var st: Dictionary = ev["stage"]
	assert_eq(st["area"], "liscor_gate")
	assert_eq(st["hours"], [17.0, 21.0])
	assert_eq(int(ev["xp_window"]["boost"]), 2, "user pick: tier 2")
	assert_eq(ev["xp_window"]["hours"], st["hours"])
	for f: Dictionary in st["foes"]:
		assert_true(String(f["enemy"]) in FOE_TYPES, f["enemy"])
	for w: Dictionary in st["waves"]:
		for e: String in w.get("foes", []):
			assert_true(e in FOE_TYPES, e)
		for a: String in w.get("allies", []):
			assert_true(_db.behaviour.npcs[a].has("combat"), a + " has combat")


func test_the_battle_is_staged_at_the_gate_in_the_evening() -> void:
	var db := DataDb.load_dir()
	ToyCombat.freeze(db)
	var gs := _fresh()
	ToyCanon.sleep_through(gs, db, 175)
	assert_eq(gs.clock.day(), 176)
	_wait_for_stage(gs, db, FIGHT, "liscor_gate", CAMP_SPOT)
	@warning_ignore("integer_division")
	var h: int = gs.clock.minute() / 60
	assert_true(h >= 17 and h < 21, "in the evening")
	FightBot.wait_seconds(gs, db, 5)
	assert_eq(_area_of(gs, "relc"), "liscor_gate", "the Watch holds the breach")


func test_the_breach_can_be_held() -> void:
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
	assert_eq(_stage_foe(gs), "", "the dead are down")
	ToyCanon.sleep_through(gs, db, 176)
	assert_true(gs.flags.has("liscor.east_gate_torn_open"), "the canon still happens")


func test_staying_away_the_ten_die_and_the_rest_live() -> void:
	var gs := _fresh()
	ToyCanon.sleep_through(gs, _db, 176)
	_has_all(gs, ["battle_of_liscor.begun", "battle_of_liscor.the_dead_rise", "azkerash.possessed_reiss_in_the_battle",
			"azkerash.link_to_reiss_broken", "liscor.east_gate_torn_open", "garen.killed_by_relc_at_the_gate",
			"reiss.killed_by_tyrion", "wandering_inn.third_floor_destroyed", "tyrion.marched_to_the_blood_fields",
			"battle_of_liscor.over", "reiss.buried_by_erin", "erin.refused_the_general_class",
			"numbtongue.speared_in_the_battle", "purple_smile.missing_after_the_battle"])
	for who: String in KILLS:
		assert_false(gs.world.is_alive(_db.canon, who), who + " dies")
	for who: String in ["numbtongue", "purple_smile", "rags", "badarrow", "rabbiteater", "redscar", "snapjaw", "poisonbite",
			"ulvama", "pebblesnatch", "erin_solstice", "pawn", "calruz", "tyrion_veltras", "azkerash", "relc", "klbkch", "zevara"]:
		assert_true(gs.world.is_alive(_db.canon, who), who + " lives")


func test_thereafter_sets_the_aftermath() -> void:
	var gs := _fresh()
	ToyCanon.sleep_through(gs, _db, 180)
	_has_all(gs, ["rags.great_chieftain_title", "goblins.survivors_follow_rags_up_the_mountain", "greydath.left_his_greatsword_with_rags",
			"rags.holds_garens_key", "pawn.refused_the_rite_of_anastases", "osthia.alive_after_the_battle",
			"laken.took_goblin_prisoners_north", "azkerash.survived_secret_kept_by_ilvriss",
			"antinium.tunnel_kept_and_extended_to_link_all_hives", "wandering_inn.closed_and_barred",
			"calruz.accepts_any_punishment", "halfseekers.burned_garens_body", "magnolia.said_nobody_won",
			"erill.paid_the_circle_of_thorns", "toren.hoards_the_battles_dead", "blighted_king.orders_a_second_summoning",
			"ryoka.heard_the_news_at_reizmelt"])
	assert_true(gs.world.is_alive(_db.canon, "calruz"), "Calruz has no verdict")
	assert_true(gs.world.is_alive(_db.canon, "ryoka_griffin"))


func test_systems_are_recorded() -> void:
	var s62 := _system("5.62")
	assert_eq(s62.size(), 5)
	var general := s62.filter(func(x: Dictionary) -> bool: return x["who"] == "erin_solstice" and str(x["name"]).begins_with("[General]"))
	assert_eq(general.size(), 1)
	assert_eq(int(general[0]["level"]), 6)
	assert_eq(_system("interlude_thereafter").size(), 0, "no class or level records for Ryoka or Rags")
