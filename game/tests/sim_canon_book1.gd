extends GutTest
## Real Book 1 canon (game/data/canon/book1). With no player input, every
## canon event in days 1–7 happens as written: no drift.

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()


func test_canon_loads_without_errors() -> void:
	assert_eq(_db.canon.errors, [] as Array[String])
	assert_gte(_db.canon.events.size(), 26)
	assert_gte(_db.canon.npcs.size(), 10)
	assert_gte(_db.canon.locations.size(), 15)


func test_first_week_runs_as_canon() -> void:
	var gs := GameState.new_game(1, _db)
	var rumors := 0
	while gs.world.last_day < 7:  # a sleep at 06:00 is a nap: loop on days
		var night := Commands.sleep(gs, _db)
		for line: String in night["lines"]:
			if line.begins_with("Rumor: "):
				rumors += 1
	var expected := 0
	var rumor_events := 0
	for id: String in _db.canon.events:
		var ev: Dictionary = _db.canon.events[id]
		if int(ev["window"]["earliest"]) <= 7 and not _db.canon.alt_only.has(id):
			expected += 1
			assert_eq(gs.world.status(id), Director.DONE, id)
			if int(ev["tier"]) == 1 and ev.has("rumor"):
				rumor_events += 1
	assert_eq(gs.world.history.size(), expected, "one history entry per event")
	assert_eq(gs.world.drift, 0.0)
	assert_eq(rumors, rumor_events)
	assert_gt(rumors, 0)


func test_killing_relc_bends_book1() -> void:
	var gs := GameState.new_game(1, _db)
	assert_eq(Commands.kill_npc(gs, _db, "relc"), "")
	ToyCanon.sleep_through(gs, _db, 7)
	assert_gt(gs.world.drift, 0.0)
	var outcomes := gs.world.history.map(func(h: Dictionary) -> String: return h["outcome"])
	assert_true(outcomes.has(Director.SUBSTITUTED) or outcomes.has(Director.CANCELLED))
