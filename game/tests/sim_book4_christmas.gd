extends GutTest
## M10.5 on the real Book 4 data (days 93-96, 3.40-3.42 and Interlude - Winter
## Solstice). Ryoka trades the wand to Hedault and runs Laken's food to
## Riverfarm. On day 94 Relc and Klbkch play Santa and catch two Drake thieves in
## the market; a player who fights beside them changes that event. On Christmas
## (day 95) Erin runs crying from her own party; a player who comforts her in the
## snow changes that event. The solstice (day 96) ends Book 4. The game is slept
## to day 93 once (before_all); each test starts from a copy of that save.

const SEED := 20260927
const SANTA := "b4.santa_catches_two_drake_thieves"
const SNOW := "b4.erin_sings_and_runs_into_the_snow"
const MARKET_SPOT := Vector2i(12, 16)
const HILL_SPOT := Vector2i(19, 16)

var _db: DataDb
var _day93 := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])
	var gs := GameState.new_game(SEED, _db)
	ToyCanon.sleep_through(gs, _db, 92)
	_day93 = gs.to_json()


func _copy(day: int, db: DataDb = null) -> GameState:
	var d := _db if db == null else db
	var gs := GameState.from_json(_day93)
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
		if m["state"] != CombatState.HOSTILE or m.get("stage", "") != SANTA:
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


func test_the_new_data_is_loaded() -> void:
	var per_chapter := {"3.40": 7, "3.41": 9, "3.42": 11, "interlude_winter_solstice": 5}
	for ch: String in per_chapter:
		var n := 0
		for id: String in _db.canon.events:
			if _db.canon.events[id]["canon_ref"]["book"] == 4 and _db.canon.events[id]["canon_ref"]["chapter"] == ch:
				n += 1
		assert_eq(n, per_chapter[ch], ch)
	for npc: String in ["anabelle", "tamaroth"]:
		assert_true(_db.canon.npcs.has(npc), npc)
	for loc: String in ["crag_pig", "invrisil_runners_guild", "riverfarm_road"]:
		assert_true(_db.canon.locations.has(loc), loc)
	assert_true(_db.combat.enemies.has("liscor_house_thief"))
	for id: String in [SANTA, SNOW]:
		assert_has(_db.canon.stages, id)
	var st: Dictionary = _db.canon.events[SANTA]["stage"]
	assert_eq(st["area"], "liscor_market")
	for w: Dictionary in st["waves"]:
		for npc: String in w["allies"]:
			assert_true(_db.behaviour.npcs.has(npc), npc + " can be placed")
	assert_eq(_db.canon.events[SNOW]["stage"]["kind"], "scene")
	for p: Dictionary in _db.canon.events[SNOW]["stage"]["npcs"]:
		assert_true(_db.behaviour.npcs.has(p["npc"]), p["npc"] + " can be placed")


func test_ryoka_runs_to_riverfarm_and_turns_for_home() -> void:
	var gs := _copy(93)
	ToyCanon.sleep_through(gs, _db, 93)
	for f: String in ["hedault.owes_the_horns_a_debt", "hedault.owns_the_albez_wand", "ryoka.knows_laken_is_an_emperor",
			"wistram.knows_of_two_more_earthers", "ryoka.running_to_riverfarm", "durene.got_her_first_present"]:
		assert_true(gs.flags.has(f), f)
	assert_false(gs.flags.has("ryoka.heading_home_to_liscor"), "Riverfarm first")
	assert_false(gs.flags.has("ryoka.will_return_to_hedault_tomorrow"), "she went back")
	ToyCanon.sleep_through(gs, _db, 95)
	assert_true(gs.flags.has("ryoka.at_riverfarm"), "she stays at Riverfarm over Christmas")
	assert_true(gs.flags.has("riverfarm.fed_for_two_weeks"))
	assert_true(gs.flags.has("ryoka.missed_christmas"))
	ToyCanon.sleep_through(gs, _db, 96)
	assert_false(gs.flags.has("ryoka.at_riverfarm"))
	assert_true(gs.flags.has("ryoka.heading_home_to_liscor"), "M11 clears it when she arrives")
	assert_true(gs.flags.has("ryoka.escaped_the_solstice_wood"))
	assert_true(gs.world.is_alive(_db.canon, "ryoka_griffin"))


func test_christmas_and_the_solstice_at_the_inn() -> void:
	var gs := _copy(94)
	ToyCanon.sleep_through(gs, _db, 96)
	for f: String in ["octavia.makes_matches", "mrsha.sells_matches", "wandering_inn.gift_pile_ready", "liscor.santa_caught_two_thieves",
			"wandering_inn.hosts_christmas", "zel.knows_wrymvr_killed_sserys", "klbkch.wears_erins_scarf",
			"tyrion_veltras.hears_of_erin", "lyonette.swore_an_oath_to_the_stars", "erin.has_the_white_coin",
			"wandering_inn.kitchen_eaten_bare", "octavia.researches_penicillin", "brunkr.hand_infected"]:
		assert_true(gs.flags.has(f), f)
	assert_false(gs.flags.has("octavia.researches_matches"), "the matches work")
	for npc: String in ["erin_solstice", "zel_shivertail", "klbkch", "xrn", "brunkr", "toren", "octavia"]:
		assert_true(gs.world.is_alive(_db.canon, npc), npc + " lives")
	var rumors := gs.world.news.filter(func(n: Dictionary) -> bool: return n["kind"] == Director.RUMOR).map(
			func(n: Dictionary) -> String: return n["event"])
	assert_has(rumors, "b4.xrn_names_wrymvr_as_sserys_killer")


func test_no_santa_fight_the_day_before() -> void:
	var gs := _copy(93)
	gs.clock.advance(12 * 60)  # 18:00
	gs.player.place("liscor_market", MARKET_SPOT)
	Commands.settle(gs, _db)
	Commands.wait(gs, _db, 3600)
	assert_false(gs.world.staged.has(SANTA))


func test_the_thieves_run_into_relc_and_klbkch() -> void:
	var db := DataDb.load_dir()
	ToyCombat.freeze(db)  # M17.2: two thieves on AP knock an idle player out before the Santas come
	var gs := _copy(94, db)
	_wait_for(gs, db, SANTA, "liscor_market", MARKET_SPOT)
	var h: int = gs.clock.minute() / 60
	assert_true(h >= 18 and h < 22, "evening")
	var foes := gs.combat.ids().filter(func(id: String) -> bool: return gs.combat.monsters[id].get("stage", "") == SANTA)
	assert_eq(foes.size(), 2)
	assert_eq(gs.combat.monsters[foes[0]]["type"], "liscor_house_thief")
	FightBot.wait_seconds(gs, db, 36)  # the Santas come 30 seconds later
	assert_eq(_area_of(gs, "relc"), "liscor_market")
	assert_eq(_area_of(gs, "klbkch"), "liscor_market")


func test_fighting_the_thieves_changes_the_event() -> void:
	var db := DataDb.load_dir()
	ToyCombat.freeze(db)
	ToyCombat.always_hit(db)
	var gs := _copy(94, db)
	_wait_for(gs, db, SANTA, "liscor_market", MARKET_SPOT)
	for i in 3000:
		if _stage_foe(gs) == "" and not gs.combat.has_fight():
			break
		_fight_turn(gs, db)
	assert_eq(_stage_foe(gs), "", "the thieves are down or gone")
	ToyCanon.sleep_through(gs, db, 94)
	assert_eq(gs.world.status(SANTA), Director.CHANGED)
	assert_eq(_hook_of(gs, SANTA), "player_helped_santa_catch_the_thieves")
	assert_true(gs.flags.has("liscor.earther_helped_santa_catch_thieves"))
	assert_true(gs.flags.has("liscor.santa_caught_two_thieves"), "the canon still happens")
	assert_true(gs.world.relationship("relc", NpcSim.PLAYER) >= 2)
	assert_true(gs.world.relationship("klbkch", NpcSim.PLAYER) >= 2)


func test_without_relc_there_is_no_santa_but_christmas_comes() -> void:
	var gs := _copy(94)
	assert_eq(Commands.kill_npc(gs, _db, "relc"), "")
	ToyCanon.sleep_through(gs, _db, 95)
	assert_eq(gs.world.status("b4.relc_and_klbkch_play_santa"), Director.CANCELLED)
	assert_eq(gs.world.status(SANTA), Director.CANCELLED)
	for id: String in ["b4.erin_cooks_for_christmas", "b4.liscor_and_celum_come_to_the_party", SNOW,
			"b4.xrn_names_wrymvr_as_sserys_killer", "b4.lyonette_swears_an_oath_to_the_stars"]:
		assert_eq(gs.world.status(id), Director.DONE, id)


func test_erin_runs_out_into_the_snow_on_christmas_night() -> void:
	var gs := _copy(95)
	_wait_for(gs, _db, SNOW, "inn_hill", HILL_SPOT)
	var h: int = gs.clock.minute() / 60
	assert_true(h >= 19 and h < 23, "evening")
	assert_eq(_area_of(gs, "erin_solstice"), "inn_hill")


func test_no_snow_scene_on_day_94() -> void:
	var gs := _copy(94)
	gs.clock.advance(13 * 60)  # 19:00
	gs.player.place("inn_hill", HILL_SPOT)
	Commands.settle(gs, _db)
	Commands.wait(gs, _db, 3600)
	assert_false(gs.world.staged.has(SNOW))


func test_comforting_erin_changes_the_event() -> void:
	var gs := _copy(95)
	_wait_for(gs, _db, SNOW, "inn_hill", HILL_SPOT)
	var r := Commands.interact(gs, _db, "erin_solstice", "comfort_someone")
	assert_eq(r["error"], "")
	assert_eq(r["record"]["context"]["location"], "wandering_inn")
	ToyCanon.sleep_through(gs, _db, 95)
	assert_eq(gs.world.status(SNOW), Director.CHANGED)
	assert_eq(_hook_of(gs, SNOW), "player_comforted_erin_in_the_snow")
	assert_true(gs.flags.has("wandering_inn.someone_followed_erin_into_the_snow"))
	assert_true(gs.flags.has("erin.cried_for_home_at_christmas"), "the canon still happens")
	assert_true(gs.world.relationship("erin_solstice", NpcSim.PLAYER) >= 3)
