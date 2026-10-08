extends GutTest
## Real Book 7 canon (game/data/canon/book7). With no player input, every
## b7. event in days FIRST_DAY–LAST_DAY happens as written: no drift. The
## game is slept to day FIRST_DAY - 1 once (before_all); each test starts
## from a copy of that save. M19.9: Book 7 is complete.

## First day with Book 7 canon (5.09 E: Laken's Day 85 is day 130).
const FIRST_DAY := 130
## Last day with Book 7 canon (M19.8: 5.20 G, Rags is a Level 20 Chieftain on day 143).
const LAST_DAY := 143

var _db: DataDb
var _base_json := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	var gs := GameState.new_game(1, _db)
	ToyCanon.sleep_through(gs, _db, FIRST_DAY - 1)
	_base_json = gs.to_json()


func _fresh() -> GameState:
	return GameState.from_json(_base_json)


static func _b7(id: String) -> bool:
	return id.begins_with("b7.")


func _b7_events() -> Array[String]:
	var out: Array[String] = []
	for id: String in _db.canon.events:
		var ev: Dictionary = _db.canon.events[id]
		if _b7(id) and int(ev["window"]["earliest"]) <= LAST_DAY and not _db.canon.alt_only.has(id):
			out.append(id)
	return out


func _sleep_to_last_day(gs: GameState) -> void:
	while gs.world.last_day < LAST_DAY:
		Commands.sleep(gs, _db, Rest.ANYWHERE)


func test_book7_loads() -> void:
	assert_eq(_db.canon.errors, [] as Array[String])
	assert_eq(_db.errors, [] as Array[String])
	assert_eq(_b7_events().size(), 191)
	for loc: String in ["riverfarm", "northern_swamp", "northern_high_road", "liscor_city_hall", "pallass_archive"]:
		assert_true(_db.canon.locations.has(loc), loc)


func test_book7_runs_as_canon() -> void:
	var gs := _fresh()
	assert_eq(gs.clock.day(), FIRST_DAY)
	_sleep_to_last_day(gs)
	var expected := _b7_events()
	for id: String in expected:
		assert_eq(gs.world.status(id), Director.DONE, id)
	var history := gs.world.history.filter(func(h: Dictionary) -> bool: return _b7(h["event"]))
	assert_eq(history.size(), expected.size(), "one history entry per event")
	assert_eq(gs.world.drift, 0.0)
	# Canon dead: nobody named dies in Book 7 (M19.2 – M19.8 have no kill effects).
	for id: String in expected:
		var kills: Array = _db.canon.events[id].get("effects", {}).get("kill", [])
		assert_eq(kills.size(), 0, id)


func test_the_rains_and_the_door_follow_the_book() -> void:
	var gs := _fresh()
	_sleep_to_last_day(gs)
	for f: String in ["izril.rains", "izril.flood", "pallass.embargo_lifted", "albez_door.anchor_at_pallass",
			"albez_door.anchor_at_liscor_wall", "pisces.killed_selys_kidnappers"]:
		assert_true(gs.flags.has(f), f)


func test_book7_stages_are_the_inn_and_the_plaza() -> void:
	var staged: Array[String] = []
	for id: String in _b7_events():
		if _db.canon.events[id].has("stage"):
			staged.append(id)
	assert_eq(staged.size(), 11)
	var windows: Array[String] = []
	for id: String in staged:
		if _db.canon.events[id].has("xp_window"):
			windows.append(id)
	assert_eq(windows, ["b7.face_eater_moths_attack_the_inn_and_liscor"], "only the moths give an XP window")
	for id: String in staged:
		for n: Dictionary in _db.canon.events[id]["stage"].get("npcs", []):
			assert_true(_db.behaviour.npcs.has(n["npc"]), id + ": " + String(n["npc"]))


func test_chapter_order_runs_the_book_in_order() -> void:
	var gs := _fresh()
	_sleep_to_last_day(gs)
	var seq := gs.world.history.filter(func(h: Dictionary) -> bool: return _b7(h["event"])) \
			.map(func(h: Dictionary) -> String: return h["event"])
	# Same-day chapter order (M18.0): the moth attack (5.07) comes before its aftermath, which follows the parade's day.
	assert_lt(seq.find("b7.face_eater_moths_attack_the_inn_and_liscor"), seq.find("b7.the_inn_after_the_moths"))
	assert_lt(seq.find("b7.the_inn_after_the_moths"), seq.find("b7.victory_party_at_the_inn"))
	assert_lt(seq.find("b7.victory_party_at_the_inn"), seq.find("b7.vuliel_drae_confess_the_eggs"))
	assert_lt(seq.find("b7.zel_funeral_in_the_plaza"), seq.find("b7.selys_haggles_with_jelaqua_at_the_inn"))
	assert_lt(seq.find("b7.rags_breaks_camp_and_marches_west"), seq.find("b7.rags_reaches_chieftain_level_20"))
