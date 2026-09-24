extends GutTest
## Real Book 1 canon (game/data/canon/book1). With no player input, every
## canon event in days 1–LAST_DAY happens as written: no drift.

## Last day with extracted canon (chapter 1.44R).
const LAST_DAY := 33
## The player arrives with the Great Ritual (night 7) and starts on day 8.
const ARRIVAL_DAY := 8

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()


func test_canon_loads_without_errors() -> void:
	assert_eq(_db.canon.errors, [] as Array[String])
	assert_gte(_db.canon.events.size(), 106)
	assert_gte(_db.canon.npcs.size(), 43)
	assert_gte(_db.canon.locations.size(), 41)


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
		if int(ev["window"]["earliest"]) <= LAST_DAY and not _db.canon.alt_only.has(id):
			expected += 1
			assert_eq(gs.world.status(id), Director.DONE, id)
			var seen := int(gs.world.events[id]["day"]) >= ARRIVAL_DAY
			if int(ev["tier"]) == 1 and ev.has("rumor") and seen:
				rumor_events += 1
	assert_eq(gs.world.history.size(), expected, "one history entry per event")
	assert_eq(gs.world.drift, 0.0)
	assert_eq(rumors, rumor_events, "rumors only from the day the player arrives")
	var news_events := []
	for id: String in _db.canon.events:
		if _db.canon.events[id].has("news") and int(gs.world.events.get(id, {}).get("day", 0)) >= ARRIVAL_DAY:
			news_events.append(id)
	news_events.sort()
	var heard := gs.world.news.filter(func(n: Dictionary) -> bool: return n["kind"] == Director.NEWS) 			.map(func(n: Dictionary) -> String: return n["event"])
	heard.sort()
	assert_eq(heard, news_events, "one news line per event with news")
	assert_gte(news_events.size(), 29)


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
	ToyCanon.sleep_through(gs, _db, LAST_DAY)
	assert_eq(int(gs.world.events["b1.ryoka_takes_the_high_passes_request"]["day"]), 30)
	assert_eq(gs.world.status("b1.teriarch_lays_a_geas_on_ryoka"), Director.DONE)
	assert_eq(gs.world.status("b1.ryoka_slips_away_from_magnolia"), Director.DONE)
	assert_eq(_db.canon.npcs["cave_dragon"]["name"], "Teriarch")
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
