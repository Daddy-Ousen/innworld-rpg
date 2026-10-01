extends GutTest
## Real Book 6 canon (game/data/canon/book6). With no player input, every
## b6. event in days FIRST_DAY–LAST_DAY happens as written: no drift. The
## game is slept to day FIRST_DAY - 1 once (before_all); each test starts
## from a copy of that save. LAST_DAY grows with each Book 6 batch.

## First day with Book 6 canon (4.32 G: the Goblin Lord's army passes Liscor, a guess).
const FIRST_DAY := 114
## Last day with Book 6 canon so far (M18.2: 1.05 C, the Fool's death in Paranfer).
const LAST_DAY := 121

var _db: DataDb
var _base_json := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	var gs := GameState.new_game(1, _db)
	ToyCanon.sleep_through(gs, _db, FIRST_DAY - 1)
	_base_json = gs.to_json()


func _fresh() -> GameState:
	return GameState.from_json(_base_json)


static func _b6(id: String) -> bool:
	return id.begins_with("b6.")


func _b6_events() -> Array[String]:
	var out: Array[String] = []
	for id: String in _db.canon.events:
		var ev: Dictionary = _db.canon.events[id]
		if _b6(id) and int(ev["window"]["earliest"]) <= LAST_DAY and not _db.canon.alt_only.has(id):
			out.append(id)
	return out


func _sleep_to_last_day(gs: GameState) -> void:
	while gs.world.last_day < LAST_DAY:
		Commands.sleep(gs, _db, Rest.ANYWHERE)


func test_book6_loads() -> void:
	assert_eq(_db.canon.errors, [] as Array[String])
	assert_eq(_db.errors, [] as Array[String])
	assert_gte(_b6_events().size(), 16)
	for npc: String in ["goblin_lord", "the_fool", "xersia", "erille", "isodore", "nereshal", "cirille_bitterclaw", "kirust",
			"blighted_king", "blighted_queen", "keith", "chole", "eddy", "vincent", "cynthia"]:
		assert_true(_db.canon.npcs.has(npc), npc)
	for loc: String in ["wirclaw_village", "paranfer"]:
		assert_true(_db.canon.locations.has(loc), loc)
	assert_eq(_db.canon.locations["paranfer"]["parent"], "rhir")


func test_book6_runs_as_canon() -> void:
	var gs := _fresh()
	assert_eq(gs.clock.day(), FIRST_DAY)
	_sleep_to_last_day(gs)
	var expected := _b6_events()
	for id: String in expected:
		assert_eq(gs.world.status(id), Director.DONE, id)
	var history := gs.world.history.filter(func(h: Dictionary) -> bool: return _b6(h["event"]))
	assert_eq(history.size(), expected.size(), "one history entry per event")
	assert_eq(gs.world.drift, 0.0)
	var rumors := gs.world.news.filter(func(n: Dictionary) -> bool: return n["kind"] == Director.RUMOR and _b6(n["event"])) \
			.map(func(n: Dictionary) -> String: return n["event"])
	assert_eq(rumors, ["b6.rags_sacks_a_human_town"])
	# M18.2: the march, the mountain, Rags's raid, Tom's weeks in Paranfer.
	for f: String in ["goblin_lord_army.passed_liscor", "wandering_inn.survived_goblin_arrows",
			"liscor.watched_the_goblin_army_pass", "garen.refuses_to_kneel_to_the_goblin_lord",
			"rags.seeks_the_undercrawlers", "flooded_waters.undercrawlers_massacred", "rags.sacked_a_human_town",
			"pyrite.wounded_at_the_town", "flooded_waters.played_in_the_lake",
			"tom.in_paranfer", "tom.swore_off_clowning", "blighted_king.appraised_the_earthers", "the_fool.befriended_tom",
			"tom.saved_princess_erille", "tom.killed_two_demon_assassins", "demons.teleported_into_paranfer",
			"the_fool.betrayed_the_court", "tom.killed_the_demon_archer", "demon_mage.escaped_paranfer",
			"blighted_king.stabbed_but_lives", "tom.promised_to_protect_erille", "tom.regained_the_hero_class"]:
		assert_true(gs.flags.has(f), f)
	assert_false(gs.flags.has("tom.lost_the_hero_class"), "Tom has his [Hero] class again")
	# No player was near the inn, so no hook ran.
	assert_false(gs.flags.has("wandering_inn.earther_watched_the_goblin_army_pass"))
	assert_false(gs.world.is_alive(_db.canon, "xersia"), "thrown into the sky (1.04 C)")
	assert_false(gs.world.is_alive(_db.canon, "the_fool"), "burned by Tom (1.05 C)")
	for npc: String in ["tom", "erille", "blighted_king", "nereshal", "rags", "pyrite", "garen", "richard", "emily", "cirille_bitterclaw"]:
		assert_true(gs.world.is_alive(_db.canon, npc), npc + " lives")


func test_the_march_is_a_scene_at_the_inn() -> void:
	var st: Dictionary = _db.canon.events["b6.goblin_lord_army_marches_past_liscor"]["stage"]
	assert_eq(st["kind"], "scene")
	assert_eq(st["area"], "inn_hill")
	assert_false(_db.canon.events["b6.goblin_lord_army_marches_past_liscor"].has("xp_window"))
	for n: Dictionary in st["npcs"]:
		assert_true(_db.behaviour.npcs.has(n["npc"]), n["npc"])


func test_chapter_order_runs_the_book_in_order() -> void:
	# Same-day events follow the chapter order (M18.0): 4.32 G's day-115 events run before 4.33's later.
	var gs := _fresh()
	_sleep_to_last_day(gs)
	var seq := gs.world.history.filter(func(h: Dictionary) -> bool: return _b6(h["event"])) \
			.map(func(h: Dictionary) -> String: return h["event"])
	var want := ["b6.rags_chooses_to_hunt_the_undercrawlers", "b6.rags_finds_the_undercrawlers_hanged",
			"b6.rags_sacks_a_human_town", "b6.pyrite_throws_the_goblins_into_the_lake"]
	var at := -1
	for id: String in want:
		var i := seq.find(id)
		assert_gt(i, at, id)
		at = i
	assert_lt(seq.find("b6.the_blighted_king_presents_the_earthers"), seq.find("b6.demon_assassins_hit_the_palace"))
	assert_lt(seq.find("b6.demons_teleport_into_the_palace"), seq.find("b6.the_fool_dies_in_toms_arms"))
