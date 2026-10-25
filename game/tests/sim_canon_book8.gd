extends GutTest
## Real Book 8 canon (game/data/canon/book8). With no player input, every
## b8. event in days FIRST_DAY–LAST_DAY happens as written: no drift. The
## game is slept to day FIRST_DAY - 1 once (before_all); each test starts
## from a copy of that save. M28: Book 8 is complete.

## First day with Book 8 canon (5.21 E).
const FIRST_DAY := 143
## Last day with Book 8 canon (5.44: the three-door battle and its aftermath).
const LAST_DAY := 163
const STAGES: Array[String] = [
	"b8.raskghar_raid_the_wandering_inn",
	"b8.raskghar_raid_the_inn_by_daylight",
	"b8.three_doors_open_on_the_raskghar_camp",
]
const KILLS := {
	"b8.fess_dies_on_a_scraped_trap": "fess",
	"b8.the_gold_captains_count_their_dead_after_the_ambush": "rebat",
	"b8.the_gold_rank_raid_on_the_raskghar_camp_fails": "cassa",
	"b8.vakk_and_twenty_gnolls_are_sacrificed": "vakk",
}

var _db: DataDb
var _base_json := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	var gs := GameState.new_game(1, _db)
	ToyCanon.sleep_through(gs, _db, FIRST_DAY - 1)
	_base_json = gs.to_json()


func _fresh() -> GameState:
	return GameState.from_json(_base_json)


static func _b8(id: String) -> bool:
	return id.begins_with("b8.")


func _b8_events() -> Array[String]:
	var out: Array[String] = []
	for id: String in _db.canon.events:
		var ev: Dictionary = _db.canon.events[id]
		if _b8(id) and int(ev["window"]["earliest"]) <= LAST_DAY and not _db.canon.alt_only.has(id):
			out.append(id)
	return out


func _sleep_to_last_day(gs: GameState) -> void:
	while gs.world.last_day < LAST_DAY:
		Commands.sleep(gs, _db, Rest.ANYWHERE)


func test_book8_loads() -> void:
	assert_eq(_db.canon.errors, [] as Array[String])
	assert_eq(_db.errors, [] as Array[String])
	assert_eq(_b8_events().size(), 269)
	for loc: String in _db.canon.locations:
		assert_true(_db.canon.locations[loc] is Dictionary, loc)


func test_book8_runs_as_canon() -> void:
	var gs := _fresh()
	assert_eq(gs.clock.day(), FIRST_DAY)
	_sleep_to_last_day(gs)
	var expected := _b8_events()
	for id: String in expected:
		assert_eq(gs.world.status(id), Director.DONE, id)
	var history := gs.world.history.filter(func(h: Dictionary) -> bool: return _b8(h["event"]))
	assert_eq(history.size(), expected.size(), "one history entry per event")
	assert_eq(gs.world.drift, 0.0)


func test_book8_dead_are_the_four_named() -> void:
	var killers := {}
	for id: String in _b8_events():
		for who: String in _db.canon.events[id].get("effects", {}).get("kill", []):
			killers[id] = who
	assert_eq(killers, KILLS)
	var gs := _fresh()
	_sleep_to_last_day(gs)
	for who: String in KILLS.values():
		assert_false(gs.world.is_alive(_db.canon, who), who + " is dead")


func test_book8_stages_are_the_three_fights() -> void:
	var staged: Array[String] = []
	var windows: Array[String] = []
	for id: String in _b8_events():
		var ev: Dictionary = _db.canon.events[id]
		if ev.has("stage"):
			staged.append(id)
		if ev.has("xp_window"):
			windows.append(id)
	assert_eq(staged, STAGES)
	assert_eq(windows, STAGES, "each fight gives an XP window")
	for id: String in staged:
		for n: Dictionary in _db.canon.events[id]["stage"].get("npcs", []):
			assert_true(_db.behaviour.npcs.has(n["npc"]), id + ": " + String(n["npc"]))


func test_the_moons_the_boycott_and_the_captives_follow_the_book() -> void:
	var gs := _fresh()
	_sleep_to_last_day(gs)
	for f: String in ["izril.moons_full", "wandering_inn.drake_boycott",
			"calruz.revealed_as_the_raskghar_great_chieftain", "calruz.in_watch_prison"]:
		assert_true(gs.flags.has(f), f)
	assert_false(gs.flags.has("izril.moons_nearly_full"), "the nearly-full moons give way to the full moons")
	# Mrsha and Ceria are taken in 5.38 and freed in 5.44: the flags are cleared again.
	for f: String in ["mrsha.taken_by_the_raskghar", "ceria.taken_by_the_raskghar"]:
		assert_false(gs.flags.has(f), f)


func test_chapter_order_runs_the_book_in_order() -> void:
	var gs := _fresh()
	_sleep_to_last_day(gs)
	var seq := gs.world.history.filter(func(h: Dictionary) -> bool: return _b8(h["event"])) \
			.map(func(h: Dictionary) -> String: return h["event"])
	assert_lt(seq.find("b8.raskghar_raid_the_wandering_inn"), seq.find("b8.raskghar_raid_the_inn_by_daylight"))
	assert_lt(seq.find("b8.raskghar_raid_the_inn_by_daylight"), seq.find("b8.three_doors_open_on_the_raskghar_camp"))
	assert_lt(seq.find("b8.three_doors_open_on_the_raskghar_camp"), seq.find("b8.calruz_is_taken_to_the_watch_prison"))
	assert_lt(seq.find("b8.calruz_is_taken_to_the_watch_prison"), seq.find("b8.erin_becomes_a_level_36_magical_innkeeper"))
