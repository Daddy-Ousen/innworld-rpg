extends GutTest
## M10.4 on the real Book 4 data (day 93, 3.36-3.39). Ryoka meets Laken in
## Invrisil and learns Valceif is dead. Erin rides home from Esthelm in the
## night of day 92, treats Brunkr's arm, teaches Go and tells two cities about
## Christmas. On the morning of day 93 a Rock Crab rises near the inn; a player
## who fights it beside Erin and Lyonette changes that event. The game is slept
## to day 90 once (before_all); each test starts from a copy of that save.

const SEED := 20260927
const CRAB := "b4.lyonette_and_erin_harvest_honey_and_a_crab_dies"
const CRAB_SPOT := Vector2i(11, 10)

var _db: DataDb
var _day90 := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])
	var gs := GameState.new_game(SEED, _db)
	ToyCanon.sleep_through(gs, _db, 89)
	_day90 = gs.to_json()


func _copy(day: int, db: DataDb = null) -> GameState:
	var d := _db if db == null else db
	var gs := GameState.from_json(_day90)
	ToyCanon.sleep_through(gs, d, day - 1)
	assert_eq(gs.clock.day(), day)
	return gs


func _wait_for(gs: GameState, db: DataDb, event: String, area: String, pos: Vector2i) -> void:
	gs.player.place(area, pos)
	Commands.settle(gs, db)
	for i in 120:
		if gs.world.staged.has(event):
			break
		assert_true(Commands.wait(gs, db, 600) >= 0, "wait")
	assert_true(gs.world.staged.has(event), "%s is staged" % event)


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
		if m["state"] != CombatState.HOSTILE or m.get("stage", "") != CRAB:
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
	var path := Pathfind.path(db.maps, gs.player.area, gs.player.pos(), Pathfind.around(at), MonsterSim.taken(gs, ""))
	if path["found"] and not (path["steps"] as Array).is_empty():
		FightBot.move(gs, db, path["steps"][0])
	else:
		Commands.wait(gs, db, 6)


func test_the_new_data_is_loaded() -> void:
	var per_chapter := {"3.36": 6, "3.37": 6, "3.38": 7, "3.39": 8}
	for ch: String in per_chapter:
		var n := 0
		for id: String in _db.canon.events:
			if _db.canon.events[id]["canon_ref"]["book"] == 4 and _db.canon.events[id]["canon_ref"]["chapter"] == ch:
				n += 1
		assert_eq(n, per_chapter[ch], ch)
	for npc: String in ["hedault", "merec", "raisha", "regisand_curle"]:
		assert_true(_db.canon.npcs.has(npc), npc)
	for loc: String in ["hedault_house", "invrisil_merchants_guild"]:
		assert_true(_db.canon.locations.has(loc), loc)
	assert_has(_db.canon.stages, CRAB)
	var st: Dictionary = _db.canon.events[CRAB]["stage"]
	assert_eq(st["area"], "floodplains_south")
	assert_eq(st.get("kind", "fight"), "fight")
	for w: Dictionary in st["waves"]:
		for npc: String in w["allies"]:
			assert_true(_db.behaviour.npcs.has(npc), npc + " can be placed")
	# The slime scene moved to day 92 so Erin can leave Esthelm before dawn on day 93.
	assert_eq(int(_db.canon.events["b4.ceria_stops_erin_touching_a_slime"]["window"]["earliest"]), 92)


func test_valceif_dies_when_ryoka_hears() -> void:
	var gs := _copy(93)
	assert_true(gs.world.is_alive(_db.canon, "valceif_godfrey"), "alive on the morning of day 93")
	ToyCanon.sleep_through(gs, _db, 93)
	assert_false(gs.world.is_alive(_db.canon, "valceif_godfrey"))
	for f: String in ["ryoka.grieves_valceif", "ryoka.met_laken", "ryoka.met_hedault", "horns_of_hammerad.relics_appraised",
			"ryoka.faces_repair_bill_for_the_buckler", "ryoka.knows_reynold_is_ordered_to_follow", "riverfarm.relief_convoy_ordered",
			"ryoka.running_to_riverfarm", "krshia.knows_ryoka_is_coming"]:  # M10.5: Riverfarm before home
		assert_true(gs.flags.has(f), f)
	assert_false(gs.flags.has("laken.left_for_invrisil"), "Laken has arrived")
	assert_true(gs.world.is_alive(_db.canon, "ryoka_griffin"))
	assert_true(gs.world.is_alive(_db.canon, "laken_godart"))


func test_erin_is_home_on_day_93() -> void:
	var gs := _copy(93)
	assert_true(gs.flags.has("erin.back_from_esthelm"))
	assert_false(gs.flags.has("erin.at_esthelm"))
	assert_true(gs.flags.has("esthelm_relief.planned"), "the relief stays as history")
	assert_true(gs.flags.has("esthelm.garrisoned_by_hired_adventurers"))
	assert_true(gs.flags.has("erin.announces_christmas"))


func test_day_93_at_the_inn_and_in_liscor() -> void:
	var gs := _copy(93)
	ToyCanon.sleep_through(gs, _db, 93)
	for f: String in ["erin.helped_harvest_ashfire_honey", "erin.killed_a_rock_crab_with_bees", "erin.knows_honey_and_salt_water_cleaning",
			"brunkr.treated_with_honey_and_salt_water", "krshia.accepts_lyonettes_effort", "erin.taught_go", "liscor.plays_go",
			"olesm.newsletter_has_twenty_readers", "octavia.researches_matches", "octavia.researches_penicillin",
			"erin.paid_octavia_36_gold", "celum_actors.join_christmas_gifts", "relc.returns_to_the_inn",
			"krshia.sells_octavias_potions", "griffon_hunt.maps_the_dungeon_rotation", "christmas.word_spreads_in_liscor_and_celum",
			"north_izril.hears_esthelm_has_risen"]:
		assert_true(gs.flags.has(f), f)
	assert_false(gs.flags.has("erin.promised_to_teach_go"), "the promise is kept")
	assert_true(gs.flags.has("brunkr.hand_infected"), "the infection is not cured yet")
	for npc: String in ["brunkr", "toren", "octavia", "krshia", "relc"]:
		assert_true(gs.world.is_alive(_db.canon, npc), npc + " lives")
	var rumors := gs.world.news.filter(func(n: Dictionary) -> bool: return n["kind"] == Director.RUMOR).map(
			func(n: Dictionary) -> String: return n["event"])
	assert_has(rumors, "b4.erin_sleeps_at_the_table_and_christmas_spreads")


func test_no_crab_scene_without_lyonette() -> void:
	var gs := _copy(93)
	assert_eq(Commands.kill_npc(gs, _db, "lyonette"), "")
	gs.clock.advance(4 * 60)  # 10:00
	gs.player.place("floodplains_south", CRAB_SPOT)
	Commands.settle(gs, _db)
	Commands.wait(gs, _db, 60)
	assert_false(gs.world.staged.has(CRAB))
	ToyCanon.sleep_through(gs, _db, 93)
	assert_eq(gs.world.status(CRAB), Director.CANCELLED)


func test_no_crab_scene_the_day_before() -> void:
	var gs := _copy(92)
	gs.clock.advance(4 * 60)
	gs.player.place("floodplains_south", CRAB_SPOT)
	Commands.settle(gs, _db)
	Commands.wait(gs, _db, 60)
	assert_false(gs.world.staged.has(CRAB))


func test_the_crab_waits_on_the_floodplains_with_erin_and_lyonette() -> void:
	var gs := _copy(93)
	_wait_for(gs, _db, CRAB, "floodplains_south", CRAB_SPOT)
	var h: int = gs.clock.minute() / 60
	assert_true(h >= 10 and h < 12, "mid-morning")
	var foes := gs.combat.ids().filter(func(id: String) -> bool: return gs.combat.monsters[id].get("stage", "") == CRAB)
	assert_eq(foes.size(), 1)
	assert_eq(gs.combat.monsters[foes[0]]["type"], "rock_crab")
	Commands.wait(gs, _db, 6)
	assert_eq(_area_of(gs, "erin_solstice"), "floodplains_south")
	assert_eq(_area_of(gs, "lyonette"), "floodplains_south")


func test_fighting_the_crab_changes_the_event() -> void:
	var db := DataDb.load_dir()
	ToyCombat.freeze(db)
	ToyCombat.always_hit(db)
	var gs := _copy(93, db)
	_wait_for(gs, db, CRAB, "floodplains_south", CRAB_SPOT)
	for i in 3000:
		if _stage_foe(gs) == "" and not gs.combat.has_fight():
			break
		_fight_turn(gs, db)
	assert_eq(_stage_foe(gs), "", "the crab is gone")
	ToyCanon.sleep_through(gs, db, 93)
	assert_eq(gs.world.status(CRAB), Director.CHANGED)
	assert_eq(_hook_of(gs, CRAB), "player_fought_the_rock_crab")
	assert_true(gs.flags.has("floodplains.earther_helped_against_the_crab"))
	assert_true(gs.flags.has("erin.killed_a_rock_crab_with_bees"), "the canon still happens")
	assert_true(gs.world.relationship("erin_solstice", NpcSim.PLAYER) >= 2)
	assert_true(gs.world.relationship("lyonette", NpcSim.PLAYER) >= 2)


func test_the_messages_come_even_without_valceif() -> void:
	var gs := _copy(93)
	assert_eq(Commands.kill_npc(gs, _db, "valceif_godfrey"), "")
	ToyCanon.sleep_through(gs, _db, 93)
	assert_eq(gs.world.status("b4.ryoka_learns_valceif_is_dead"), Director.CANCELLED)
	assert_true(Director.happened(gs.world.status("b4.ryoka_sends_replies_to_liscor")), "Ryoka still answers Liscor")
	assert_true(Director.happened(gs.world.status("b4.erin_and_ryoka_chat_across_the_mages_guilds")))
