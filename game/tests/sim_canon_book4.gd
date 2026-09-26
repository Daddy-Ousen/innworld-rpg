extends GutTest
## Real Book 4 canon (game/data/canon/book4). With no player input, every
## b4. event in days FIRST_DAY–LAST_DAY happens as written: no drift. The
## game is slept to day FIRST_DAY - 1 once (before_all); each test starts
## from a copy of that save.

## First day with Book 4 canon (3.26 G and 3.27 M both fall on day 85, before
## the end of Book 3).
const FIRST_DAY := 85
## Last day with extracted Book 4 canon (M10.1: 3.26 G – 3.29 G).
const LAST_DAY := 90

var _db: DataDb
var _base_json := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	var gs := GameState.new_game(1, _db)
	ToyCanon.sleep_through(gs, _db, FIRST_DAY - 1)
	_base_json = gs.to_json()


func _fresh() -> GameState:
	return GameState.from_json(_base_json)


static func _b4(id: String) -> bool:
	return id.begins_with("b4.")


func _b4_events() -> Array[String]:
	var out: Array[String] = []
	for id: String in _db.canon.events:
		var ev: Dictionary = _db.canon.events[id]
		if _b4(id) and int(ev["window"]["earliest"]) <= LAST_DAY and not _db.canon.alt_only.has(id):
			out.append(id)
	return out


func _area_of(gs: GameState, id: String) -> String:
	var n: Dictionary = gs.npcs.npcs.get(id, {})
	return "gone" if n.is_empty() else String(n["area"])


func test_book4_loads() -> void:
	assert_eq(_db.canon.errors, [] as Array[String])
	assert_eq(_db.errors, [] as Array[String])
	assert_gte(_b4_events().size(), 17)
	for npc: String in ["tremborag", "ulvama", "noears", "pyrite", "redscar", "greybeard"]:
		assert_true(_db.canon.npcs.has(npc), npc)
	for loc: String in ["liscor_dungeon_rift", "tremborags_mountain", "north_izril"]:
		assert_true(_db.canon.locations.has(loc), loc)
	# Tremborag's mountain is not the Goblin lair of Book 2.
	assert_ne(_db.canon.locations["tremborags_mountain"]["parent"], "goblin_mountain_lair")


func test_book4_runs_as_canon() -> void:
	var gs := _fresh()
	assert_eq(gs.clock.day(), FIRST_DAY)
	while gs.world.last_day < LAST_DAY:
		Commands.sleep(gs, _db, Rest.ANYWHERE)
	var expected := _b4_events()
	for id: String in expected:
		assert_eq(gs.world.status(id), Director.DONE, id)
	var b4_history := gs.world.history.filter(func(h: Dictionary) -> bool: return _b4(h["event"]))
	assert_eq(b4_history.size(), expected.size(), "one history entry per event")
	assert_eq(gs.world.drift, 0.0)
	var rumor_events := expected.filter(func(id: String) -> bool:
			return int(_db.canon.events[id]["tier"]) == 1 and _db.canon.events[id].has("rumor"))
	rumor_events.sort()
	var rumors := gs.world.news.filter(func(n: Dictionary) -> bool: return n["kind"] == Director.RUMOR and _b4(n["event"])) \
			.map(func(n: Dictionary) -> String: return n["event"])
	rumors.sort()
	assert_eq(rumors, rumor_events, "a rumor for each tier 1 event")
	var news_events := expected.filter(func(id: String) -> bool: return _db.canon.events[id].has("news"))
	news_events.sort()
	var heard := gs.world.news.filter(func(n: Dictionary) -> bool: return n["kind"] == Director.NEWS and _b4(n["event"])) \
			.map(func(n: Dictionary) -> String: return n["event"])
	heard.sort()
	assert_eq(heard, news_events, "one news line per event with news")
	# The state after 3.29 G (M10.1).
	for f: String in ["rags.defied_tremborag", "pyrite.named", "rags.leads_her_own_tribe", "tremborag.hunts_rags",
			"tremborag.captives_freed", "garen.stays_with_tremborag", "rags.pike_squares", "north_izril.knows_of_tremborag",
			"griffon_hunt.allied_with_halfseekers", "mrsha.met_the_free_queen", "mrsha.called_a_doombringer",
			"mrsha.rescued_from_the_dungeon", "liscor.dungeon_rift_found", "lyonette.searched_for_mrsha",
			"toren.in_liscor_dungeon", "toren.spared_mrsha", "toren.heading_to_liscor", "mrsha.at_the_wandering_inn"]:
		assert_true(gs.flags.has(f), f)
	for f: String in ["mrsha.missing", "mrsha.fell_into_the_dungeon", "mrsha.ran_from_liscor", "rags.at_tremborags_mountain",
			"floodplains.earther_searched_for_mrsha", "dungeon_rift.earther_held_the_rope"]:
		assert_false(gs.flags.has(f), f)
	for npc: String in ["toren", "mrsha", "rags", "garen", "tremborag", "pyrite", "brunkr"]:
		assert_true(gs.world.is_alive(_db.canon, npc), npc + " lives")
	# Mrsha sleeps at the inn again; Rags is far away in the north.
	Commands.wait(gs, _db, 3600)
	assert_eq(_area_of(gs, "mrsha"), "inn_interior", "Mrsha is home")


func test_rags_no_longer_forages_near_liscor() -> void:
	var gs := _fresh()
	assert_true(gs.flags.has("rags.tribe_turns_north"))
	for i in 6:
		Commands.wait(gs, _db, 3600)
		assert_ne(_area_of(gs, "rags"), "floodplains_south", "hour %d" % i)


func test_mrsha_is_found_even_without_lyonette() -> void:
	var gs := _fresh()
	assert_eq(Commands.kill_npc(gs, _db, "lyonette"), "")
	ToyCanon.sleep_through(gs, _db, FIRST_DAY)
	assert_eq(gs.world.status("b4.lyonette_searches_the_snow_for_mrsha"), Director.CANCELLED)
	assert_true(Director.happened(gs.world.status("b4.mrsha_rescued_from_the_dungeon")), "the rescue still happens")
	assert_false(gs.flags.has("mrsha.missing"))


func test_without_tremborag_the_north_is_quiet() -> void:
	var gs := _fresh()
	assert_eq(Commands.kill_npc(gs, _db, "tremborag"), "")
	ToyCanon.sleep_through(gs, _db, LAST_DAY)
	for id: String in ["b4.redfang_coalition_reaches_tremborags_mountain", "b4.rags_breaks_out_of_tremborags_mountain",
			"b4.rags_invents_pike_squares"]:
		assert_eq(gs.world.status(id), Director.CANCELLED, id)
	assert_true(Director.happened(gs.world.status("b4.mrsha_rescued_from_the_dungeon")), "Liscor's day is its own")
	assert_gt(gs.world.drift, 0.0)
