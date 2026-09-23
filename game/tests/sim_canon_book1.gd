extends GutTest
## Real Book 1 canon (game/data/canon/book1). With no player input, every
## canon event in days 1–LAST_DAY happens as written: no drift.

## Last day with extracted canon (chapter 1.25).
const LAST_DAY := 19
## The player arrives with the Great Ritual (night 7) and starts on day 8.
const ARRIVAL_DAY := 8

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()


func test_canon_loads_without_errors() -> void:
	assert_eq(_db.canon.errors, [] as Array[String])
	assert_gte(_db.canon.events.size(), 62)
	assert_gte(_db.canon.npcs.size(), 27)
	assert_gte(_db.canon.locations.size(), 30)


func test_new_game_starts_after_the_great_ritual() -> void:
	var gs := GameState.new_game(1, _db)
	assert_eq(gs.clock.day(), ARRIVAL_DAY)
	assert_eq(gs.clock.time_string(), "06:00")
	assert_eq(gs.world.last_day, ARRIVAL_DAY - 1, "canon days 1-7 are history")
	assert_eq(gs.world.status("b1.erin_arrives"), Director.DONE)
	assert_eq(gs.world.status("b1.erin_walks_to_liscor"), WorldState.PENDING, "day 8: still ahead")
	assert_true(gs.morning.is_empty(), "the player did not hear the old rumors")
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
