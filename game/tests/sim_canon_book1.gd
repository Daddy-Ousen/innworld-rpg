extends GutTest
## Real Book 1 canon (game/data/canon/book1). With no player input, every
## canon event in days 1–LAST_DAY happens as written: no drift. CanonDb
## merges all books, so the counts here look at b1. events only (M8.0).

## Last day with extracted canon (chapter 1.63, the end of Book 1).
const LAST_DAY := 41
## The player arrives with the Great Ritual (night 7) and starts on day 8.
const ARRIVAL_DAY := 8

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()


func test_canon_loads_without_errors() -> void:
	assert_eq(_db.canon.errors, [] as Array[String])
	assert_gte(_db.canon.events.size(), 151)
	assert_gte(_db.canon.npcs.size(), 50)
	assert_gte(_db.canon.locations.size(), 44)


func test_new_game_starts_after_the_great_ritual() -> void:
	var gs := GameState.new_game(1, _db)
	assert_eq(gs.clock.day(), ARRIVAL_DAY)
	assert_eq(gs.clock.time_string(), "06:00")
	assert_eq(gs.world.last_day, ARRIVAL_DAY - 1, "canon days 1-7 are history")
	assert_eq(gs.world.status("b1.erin_arrives"), Director.DONE)
	assert_eq(gs.world.status("b1.erin_walks_to_liscor"), WorldState.PENDING, "day 8: still ahead")
	assert_true(gs.morning.is_empty(), "the player did not hear the old rumors")
	assert_true(gs.world.news.is_empty(), "nor the old news")
	assert_eq(gs.player.area, "liscor_gate")


func test_book1_runs_as_canon() -> void:
	var gs := GameState.new_game(1, _db)
	var rumors := 0
	while gs.world.last_day < LAST_DAY:  # a sleep at 06:00 is a nap: loop on days
		var night := Commands.sleep(gs, _db)
		for line: String in night["lines"]:
			if line.begins_with("Rumor: "):
				rumors += 1
	var expected := 0
	var rumor_events := 0
	for id: String in _db.canon.events:
		var ev: Dictionary = _db.canon.events[id]
		if _b1(id) and int(ev["window"]["earliest"]) <= LAST_DAY and not _db.canon.alt_only.has(id):
			expected += 1
			assert_eq(gs.world.status(id), Director.DONE, id)
	for id: String in _db.canon.events:  # any book: Book 2 starts on day 41
		var ev: Dictionary = _db.canon.events[id]
		var seen := Director.happened(gs.world.status(id)) and int(gs.world.events[id]["day"]) >= ARRIVAL_DAY
		if int(ev["tier"]) == 1 and ev.has("rumor") and seen:
			rumor_events += 1
	var b1_history := gs.world.history.filter(func(h: Dictionary) -> bool: return _b1(h["event"]))
	assert_eq(b1_history.size(), expected, "one history entry per event")
	assert_eq(gs.world.drift, 0.0)
	assert_eq(rumors, rumor_events, "rumors only from the day the player arrives")
	var news_events := []
	for id: String in _db.canon.events:
		if _b1(id) and _db.canon.events[id].has("news") and int(gs.world.events.get(id, {}).get("day", 0)) >= ARRIVAL_DAY:
			news_events.append(id)
	news_events.sort()
	var heard := gs.world.news.filter(func(n: Dictionary) -> bool: return n["kind"] == Director.NEWS and _b1(n["event"])) 			.map(func(n: Dictionary) -> String: return n["event"])
	heard.sort()
	assert_eq(heard, news_events, "one news line per event with news")
	assert_gte(news_events.size(), 34)


func test_killing_relc_bends_book1() -> void:
	var gs := GameState.new_game(1, _db)
	assert_eq(Commands.kill_npc(gs, _db, "relc"), "")
	ToyCanon.sleep_through(gs, _db, LAST_DAY)
	assert_gt(gs.world.drift, 0.0)
	var outcomes := gs.world.history.map(func(h: Dictionary) -> String: return h["outcome"])
	assert_true(outcomes.has(Director.SUBSTITUTED) or outcomes.has(Director.CANCELLED))


func test_killing_klbkch_sends_another_guard() -> void:
	var gs := GameState.new_game(1, _db)
	assert_eq(Commands.kill_npc(gs, _db, "klbkch"), "")
	ToyCanon.sleep_through(gs, _db, LAST_DAY)
	assert_eq(gs.world.status("b1.klbkch_saves_erin"), Director.SUBSTITUTED)
	assert_ne(gs.world.events["b1.klbkch_saves_erin"]["roles"]["rescuer"], "klbkch")
	assert_eq(gs.world.status("b1.klbkch_punches_relc"), Director.CANCELLED)
	assert_eq(gs.world.status("b1.erin_names_the_inn"), Director.DONE, "Erin's week goes on")
	assert_gt(gs.world.drift, 0.0)


func test_killing_the_free_queen_keeps_workers_home() -> void:
	var gs := GameState.new_game(1, _db)
	assert_eq(Commands.kill_npc(gs, _db, "free_queen"), "")
	ToyCanon.sleep_through(gs, _db, LAST_DAY)
	assert_eq(gs.world.status("b1.queen_allows_workers_visit"), Director.CANCELLED)
	assert_eq(gs.world.status("b1.workers_learn_chess"), Director.CANCELLED, "no Workers without her leave")
	assert_eq(gs.world.status("b1.rags_brings_goblins_to_eat"), Director.DONE, "the Goblins still come")
	assert_eq(gs.world.status("b1.klbkch_is_reborn"), Director.CANCELLED, "no Queen, no Rite")
	assert_false(gs.world.is_alive(_db.canon, "klbkch"))
	assert_eq(gs.world.status("b1.workers_name_themselves"), Director.CANCELLED, "no chess club to guard the inn")
	assert_eq(gs.world.status("b1.rags_kills_skinner"), Director.DONE, "the Goblins still kill Skinner")
	assert_gt(gs.world.drift, 0.0)


func test_klbkch_dies_on_day_21_and_the_watch_leaves_the_inn() -> void:
	var gs := GameState.new_game(1, _db)
	ToyCanon.sleep_through(gs, _db, 20)
	assert_true(gs.world.is_alive(_db.canon, "klbkch"), "alive on day 20")
	assert_false(gs.flags.has("liscor_watch.no_inn_patrols"))
	ToyCanon.sleep_through(gs, _db, 21)
	assert_eq(gs.world.status("b1.klbkch_dies_defending_erin"), Director.DONE)
	assert_false(gs.world.is_alive(_db.canon, "klbkch"))
	assert_false(gs.world.is_alive(_db.canon, "designated_worker"))
	assert_true(gs.flags.has("liscor_watch.no_inn_patrols"))
	assert_true(gs.flags.has("pawn.named"))
	assert_lt(gs.world.relationship("relc", "erin_solstice"), 0, "Relc blames Erin")
	assert_eq(gs.world.drift, 0.0)


func test_with_klbkch_dead_another_guard_dies_in_the_raid() -> void:
	var gs := GameState.new_game(1, _db)
	assert_eq(Commands.kill_npc(gs, _db, "klbkch"), "")
	ToyCanon.sleep_through(gs, _db, LAST_DAY)
	assert_eq(gs.world.status("b1.klbkch_dies_defending_erin"), Director.SUBSTITUTED)
	var rescuer: String = gs.world.events["b1.klbkch_dies_defending_erin"]["roles"]["rescuer"]
	assert_ne(rescuer, "klbkch")
	assert_has(_db.canon.npcs[rescuer]["tags"], "senior_guard")
	assert_false(gs.world.is_alive(_db.canon, rescuer), "the stand-in dies in his place")
	assert_eq(gs.world.status("b1.hive_chess_aberration"), Director.CANCELLED, "no Klbkch, no chess in the Hive")
	assert_gt(gs.world.drift, 0.0)


func test_days_25_to_28_heal_ryoka_and_bring_gazi_and_the_skeleton() -> void:
	var gs := GameState.new_game(1, _db)
	ToyCanon.sleep_through(gs, _db, 24)
	assert_true(gs.flags.has("ryoka.leg_crushed"), "still crushed on day 24")
	ToyCanon.sleep_through(gs, _db, 28)
	for id: String in ["b1.pisces_mends_ryokas_leg", "b1.erin_burns_shield_spider_nest", "b1.gazi_comes_to_liscor",
			"b1.relc_makes_up_with_erin", "b1.pisces_pays_with_a_skeleton", "b1.adventurers_attack_goblins_at_inn"]:
		assert_eq(gs.world.status(id), Director.DONE, id)
	assert_eq(int(gs.world.events["b1.pisces_mends_ryokas_leg"]["day"]), 25)
	assert_true(gs.flags.has("ryoka.leg_healed"))
	assert_false(gs.flags.has("ryoka.leg_crushed"), "the leg is mended")
	assert_true(gs.flags.has("liscor.gazi_in_city"))
	assert_false(gs.flags.has("relc.ignores_erin"), "Relc speaks to Erin again")
	assert_true(gs.flags.has("relc.blames_erin"), "design: he does not come every evening yet")
	assert_true(gs.flags.has("wandering_inn.has_skeleton"))
	assert_eq(int(gs.world.events["b1.pisces_pays_with_a_skeleton"]["day"]), 27)
	assert_eq(int(gs.world.events["b1.adventurers_attack_goblins_at_inn"]["day"]), 28)
	assert_eq(gs.world.drift, 0.0)


func test_ryoka_meets_the_dragon_and_slips_away_from_magnolia() -> void:
	var gs := GameState.new_game(1, _db)
	ToyCanon.sleep_through(gs, _db, 33)
	assert_eq(int(gs.world.events["b1.ryoka_takes_the_high_passes_request"]["day"]), 30)
	assert_eq(gs.world.status("b1.teriarch_lays_a_geas_on_ryoka"), Director.DONE)
	assert_eq(gs.world.status("b1.ryoka_slips_away_from_magnolia"), Director.DONE)
	assert_eq(gs.world.events["b1.teriarch_lays_a_geas_on_ryoka"]["roles"]["dragon"], "teriarch")
	assert_eq(_db.canon.npcs["cave_dragon"]["name"], "The Dragon", "not confirmed to be Teriarch")
	assert_true(gs.flags.has("ryoka.geas_to_find_azkerash"))
	assert_true(gs.flags.has("ryoka.bound_for_esthelm"))
	assert_false(gs.flags.has("ryoka.blocked_by_guilds"), "the Guilds let her work again")
	assert_eq(gs.world.drift, 0.0)


func test_without_pisces_ryokas_leg_stays_broken_but_erins_week_goes_on() -> void:
	var gs := GameState.new_game(1, _db)
	assert_eq(Commands.kill_npc(gs, _db, "pisces"), "")
	ToyCanon.sleep_through(gs, _db, LAST_DAY)
	assert_eq(gs.world.status("b1.pisces_mends_ryokas_leg"), Director.CANCELLED)
	assert_true(gs.flags.has("ryoka.leg_crushed"), "no one mends it")
	for id: String in ["b1.ryoka_outruns_relc", "b1.magnolia_shuts_ryoka_out", "b1.ryoka_runs_the_high_passes",
			"b1.ryoka_slips_away_from_magnolia", "b1.relc_makes_up_with_erin", "b1.pisces_pays_with_a_skeleton"]:
		assert_eq(gs.world.status(id), Director.CANCELLED, id)
	assert_false(gs.flags.has("wandering_inn.has_skeleton"))
	for id: String in ["b1.erin_burns_shield_spider_nest", "b1.gazi_comes_to_liscor", "b1.pawn_builds_an_outhouse",
			"b1.adventurers_attack_goblins_at_inn"]:
		assert_true(Director.happened(gs.world.status(id)), id)
	assert_gt(gs.world.drift, 0.0)


func test_days_34_to_37_bring_the_horns_and_take_pawn() -> void:
	var gs := GameState.new_game(1, _db)
	ToyCanon.sleep_through(gs, _db, 37)
	var days := {
		"b1.ceria_teaches_ryoka_light": 34, "b1.pisces_tests_erin_and_rags": 34, "b1.erin_tells_krshia_of_her_world": 34,
		"b1.erin_names_the_skeleton_toren": 34, "b1.ryoka_runs_from_esthelm": 34, "b1.thief_burns_market_street": 34,
		"b1.ksmvr_takes_pawn": 35, "b1.horns_lodge_at_the_inn": 35, "b1.rags_kills_the_feathered_chieftain": 35,
		"b1.rags_band_chases_ryoka": 35, "b1.pawn_returns_maimed": 36, "b1.erin_sings_through_the_night": 36,
		"b1.ksmvr_backs_down_outside_liscor": 36, "b1.pawn_goes_home_to_the_hive": 37, "b1.gazi_hunts_for_ryoka": 37,
		"b1.calruz_shows_erin_hammer_blow": 37}
	for id: String in days:
		assert_eq(gs.world.status(id), Director.DONE, id)
		assert_eq(int(gs.world.events[id]["day"]), days[id], id)
	for f: String in ["horns_of_hammerad.stay_at_inn", "pawn.judged_individual", "pawn.maimed", "toren.named",
			"krshia.knows_erin_otherworld", "ryoka.in_blood_fields", "gazi.hunts_ryoka", "calruz.will_train_erin"]:
		assert_true(gs.flags.has(f), f)
	for f: String in ["pawn.taken_for_judgment", "liscor.gazi_in_city", "ryoka.has_speed_potion", "ryoka.bound_for_esthelm"]:
		assert_false(gs.flags.has(f), f)
	assert_eq(gs.world.events["b1.rags_kills_the_feathered_chieftain"]["roles"]["chieftain"], "rags")
	assert_eq(_db.canon.npcs["relc"]["name"], "Relc Grasstongue")
	assert_eq(_db.canon.npcs["toren"]["name"], "Toren")
	assert_eq(gs.world.drift, 0.0)


func test_without_ksmvr_pawn_keeps_his_arms_and_the_inn_goes_on() -> void:
	var gs := GameState.new_game(1, _db)
	assert_eq(Commands.kill_npc(gs, _db, "ksmvr"), "")
	ToyCanon.sleep_through(gs, _db, LAST_DAY)
	for id: String in ["b1.ksmvr_takes_pawn", "b1.pawn_returns_maimed", "b1.erin_sings_through_the_night",
			"b1.ksmvr_backs_down_outside_liscor"]:
		assert_eq(gs.world.status(id), Director.CANCELLED, id)
	assert_false(gs.flags.has("pawn.maimed"))
	for id: String in ["b1.horns_lodge_at_the_inn", "b1.captains_plan_at_the_inn", "b1.olesm_solves_erins_puzzle",
			"b1.toren_guards_sleeping_erin", "b1.calruz_shows_erin_hammer_blow", "b1.rags_kills_the_feathered_chieftain"]:
		assert_true(Director.happened(gs.world.status(id)), id)
	assert_gt(gs.world.drift, 0.0)

func test_days_38_to_41_end_book1() -> void:
	var gs := GameState.new_game(1, _db)
	ToyCanon.sleep_through(gs, _db, 38)
	assert_false(gs.world.is_alive(_db.canon, "klbkch"), "still dead on day 38")
	assert_false(gs.world.is_alive(_db.canon, "toriska"), "Persua pushed her onto a root")
	ToyCanon.sleep_through(gs, _db, LAST_DAY)
	var days := {
		"b1.silver_merchant_stops_ryoka": 38, "b1.gazi_fights_silverfang_warriors": 38, "b1.persua_ambushes_ryoka": 38,
		"b1.ryoka_breaks_the_geas": 38, "b1.calruz_trains_erin": 38, "b1.olesm_joins_the_expedition": 38,
		"b1.pawn_waits_for_the_queen": 39, "b1.expedition_enters_the_ruins": 39,
		"b1.expedition_breaks_the_crypt_ambush": 39, "b1.skinner_wakes_in_the_ruins": 39,
		"b1.skinner_leads_the_dead_into_liscor": 39, "b1.workers_name_themselves": 39,
		"b1.knight_dies_holding_the_door": 39, "b1.watch_holds_market_street": 39, "b1.klbkch_is_reborn": 39,
		"b1.rags_kills_skinner": 39, "b1.erin_mourns_the_workers": 40, "b1.toren_hides_skinners_eye": 40,
		"b1.pisces_studies_the_crypt_lord": 40, "b1.magnolia_visits_yvlon": 41, "b1.ryoka_returns_to_liscor": 41}
	for id: String in days:
		assert_eq(gs.world.status(id), Director.DONE, id)
		assert_eq(int(gs.world.events[id]["day"]), days[id], id)
	assert_true(gs.world.is_alive(_db.canon, "klbkch"), "the Rite brings him back")
	for npc: String in ["gerial", "sostrom", "cervial_dermondy", "toriska"]:
		assert_false(gs.world.is_alive(_db.canon, npc), npc)
	for npc: String in ["calruz", "ceria_springwalker", "olesm", "yvlon_byres", "persua", "claudeil"]:
		assert_true(gs.world.is_alive(_db.canon, npc), npc + " is alive in the data")
	for f: String in ["calruz.missing", "ceria.missing", "olesm.missing", "skinner.dead", "klbkch.reborn",
			"ryoka.geas_broken", "ryoka.back_in_liscor", "antinium_hive.workers_named", "magnolia.gone_north"]:
		assert_true(gs.flags.has(f), f)
	for f: String in ["horns_of_hammerad.stay_at_inn", "ryoka.geas_to_find_azkerash", "ryoka.bound_for_liscor",
			"gnolls.warriors_coming", "persua.trails_ryoka"]:
		assert_false(gs.flags.has(f), f)
	assert_eq(gs.world.drift, 0.0)


func test_without_rags_the_worm_still_falls_out_of_the_canon() -> void:
	var gs := GameState.new_game(1, _db)
	assert_eq(Commands.kill_npc(gs, _db, "rags"), "")
	ToyCanon.sleep_through(gs, _db, LAST_DAY)
	assert_eq(gs.world.status("b1.rags_kills_skinner"), Director.CANCELLED)
	assert_eq(gs.world.status("b1.toren_hides_skinners_eye"), Director.CANCELLED, "no worm, no eye")
	assert_false(gs.flags.has("skinner.dead"))
	for id: String in ["b1.skinner_leads_the_dead_into_liscor", "b1.klbkch_is_reborn", "b1.erin_mourns_the_workers",
			"b1.ryoka_returns_to_liscor"]:
		assert_true(Director.happened(gs.world.status(id)), id)
	assert_gt(gs.world.drift, 0.0)


static func _b1(id: String) -> bool:
	return id.begins_with("b1.")
