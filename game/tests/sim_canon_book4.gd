extends GutTest
## Real Book 4 canon (game/data/canon/book4). With no player input, every
## b4. event in days FIRST_DAY–LAST_DAY happens as written: no drift. The
## game is slept to day FIRST_DAY - 1 once (before_all); each test starts
## from a copy of that save.

## First day with Book 4 canon (3.26 G and 3.27 M both fall on day 85, before
## the end of Book 3).
const FIRST_DAY := 85
## Last day with extracted Book 4 canon (M10.4: to 3.39; all four chapters fall on day 93).
const LAST_DAY := 93

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
	assert_gte(_b4_events().size(), 78)
	for npc: String in ["tremborag", "ulvama", "noears", "pyrite", "redscar", "greybeard", "termin", "poisonbite",
			"cognita", "illphres", "calvaron", "montressa_du_valeross", "beatrice", "charles_de_trevalier", "amerys", "feor", "umbral",
			"hedault", "merec", "raisha", "regisand_curle"]:
		assert_true(_db.canon.npcs.has(npc), npc)
	for loc: String in ["liscor_dungeon_rift", "tremborags_mountain", "north_izril", "celum_liscor_road", "village_of_the_dead",
			"hedault_house", "invrisil_merchants_guild"]:
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
			"toren.in_liscor_dungeon", "toren.spared_mrsha", "toren.heading_to_liscor", "mrsha.at_the_wandering_inn",
			# M10.2: the door anchor moves, the old man on the road, the Wistram story, Rags goes south.
			"albez_door.anchor_at_stitchworks", "octavia.researches_baking_powder", "erin.met_teriarch",
			"ceria.teriarch_marked_a_spell", "erin.knows_of_wistram", "rags.class_chieftain", "rags.heading_south",
			"rags.wants_to_see_erin", "north_izril.goblins_rob_caravans", "rags.tribe_turns_north",
				# M10.3: Esthelm, the homecoming, Level 30, the relief, Ryoka in Invrisil.
				"esthelm.fed_by_erin", "erin.home_at_the_inn", "albez_door.at_wandering_inn", "albez_door.reopened_by_mage_link",
				"erin.apologised_to_lyonette", "erin.magical_grounds", "erin.class_magical_innkeeper", "esthelm_relief.planned",
				"albez_door.second_door_in_stitchworks", "antinium.expedition_to_esthelm", "esthelm.sings_erins_carol",
				"ryoka.holds_magnolias_seal", "ryoka.suspects_laken_is_an_earther", "toren.in_liscor_dungeon",
					# M10.4: Erin home, Ryoka and Laken, Valceif, the Go lesson, Christmas.
					"erin.back_from_esthelm", "ryoka.met_laken", "ryoka.grieves_valceif", "riverfarm.relief_convoy_ordered",
					"erin.taught_go", "brunkr.hand_infected", "christmas.word_spreads_in_liscor_and_celum"]:
		assert_true(gs.flags.has(f), f)
	for f: String in ["mrsha.missing", "mrsha.fell_into_the_dungeon", "mrsha.ran_from_liscor", "rags.at_tremborags_mountain",
			"floodplains.earther_searched_for_mrsha", "dungeon_rift.earther_held_the_rope",
			"albez_door.linked_to_frenzied_hare", "rags.leader_class", "frenzied_hare.earther_heard_of_wistram",
			"erin.on_wagon_south", "erin.left_celum", "erin.in_celum", "erin.stranded_north", "erin.left_liscor",
			"ivolethe.banished_from_magnolias_land", "wandering_inn.earther_stood_by_lyonette", "esthelm_relief.earther_backed_the_plan",
			"erin.at_esthelm", "erin.promised_to_teach_go", "laken.left_for_invrisil", "floodplains.earther_helped_against_the_crab"]:
		assert_false(gs.flags.has(f), f)
	for npc: String in ["toren", "mrsha", "rags", "garen", "tremborag", "pyrite", "brunkr", "teriarch", "octavia"]:
		assert_true(gs.world.is_alive(_db.canon, npc), npc + " lives")
	assert_false(gs.world.is_alive(_db.canon, "valceif_godfrey"), "killed by bandits (3.37)")
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


func test_wistram_days_are_history_only() -> void:
	var gs := _fresh()
	for npc: String in ["illphres", "calvaron"]:
		assert_false(gs.world.is_alive(_db.canon, npc), npc + " died before the story")
	for npc: String in ["cognita", "montressa_du_valeross", "beatrice", "charles_de_trevalier", "amerys", "feor"]:
		assert_true(gs.world.is_alive(_db.canon, npc), npc)
	# No Wistram Days chapter puts events on the calendar.
	for id: String in _db.canon.events:
		var ch: String = _db.canon.events[id]["canon_ref"]["chapter"]
		assert_false(ch.begins_with("interlude_wistram_days"), id)


func test_the_road_goes_on_without_octavia() -> void:
	var gs := _fresh()
	# Killed after 3.25 (day 87), where Erin still says goodbye to her.
	ToyCanon.sleep_through(gs, _db, 88)
	assert_eq(Commands.kill_npc(gs, _db, "octavia"), "")
	ToyCanon.sleep_through(gs, _db, 89)
	assert_eq(gs.world.status("b4.erin_hires_octavia_for_baking_powder"), Director.CANCELLED)
	assert_true(gs.flags.has("albez_door.anchor_at_stitchworks"), "the door still moves")
	assert_true(Director.happened(gs.world.status("b4.ceria_tells_erin_of_wistram")), "the story is still told")
