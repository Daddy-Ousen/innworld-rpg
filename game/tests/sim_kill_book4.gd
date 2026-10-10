extends GutTest
## M23.3 (ADR 0036): a key Book 4 NPC dies on day 85 and the book still runs.
## Threads that do not need the dead NPC go on; the dead NPC's own events
## cancel; alt events show in the history; drift stays in proportion. Key NPCs
## and events: docs/divergence/picks.md (plus Lyonette and Pisces). The game is
## slept to day 84 once (before_all); each test starts from a copy.

const FIRST_DAY := 85
const LAST_DAY := 96
## Book 4 canon events that did not happen (cancelled or mutated), and total
## drift (all books), at most. Before M23.3: Erin 85 / 88.25, Zel 83 / 78.5,
## Ceria 85 / 89.25, Teriarch 83 / 78, Klbkch 77 / 73, Lyonette 79 / 74.5, Pisces 85 / 84.75.
const CEILING := {
	"erin_solstice": [55, 59.0],
	"zel_shivertail": [14, 13.5],
	"ceria_springwalker": [15, 22.5],
	"teriarch": [2, 1.5],
	"klbkch": [6, 5.5],
	"lyonette": [5, 5.5],
	"pisces": [11, 15.0],
}
const ALTS := ["pawn_leads_mrsha_out_of_the_hive", "the_wagon_hides_from_the_goblin_army",
	"the_horns_hide_from_the_goblin_army", "erin_comes_home_without_the_door", "liscor_sends_wagons_to_esthelm"]
## The Esthelm relief, the homecoming and Christmas: they need Erin, not the others.
const ERINS_WINTER := ["erin_comes_home_to_the_wandering_inn", "erin_reaches_level_30",
	"the_wandering_inn_throws_a_homecoming_party", "erin_pitches_the_esthelm_relief", "the_relief_convoy_reaches_esthelm",
	"esthelm_sings_erins_carol", "erin_rides_home_and_names_christmas", "the_convoy_eats_at_the_wandering_inn",
	"erin_cooks_for_christmas", "liscor_and_celum_come_to_the_party", "the_christmas_presents",
	"erin_turns_down_three_gifts", "friends_come_home_at_the_solstice_dawn"]

var _db: DataDb
var _base_json := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	var gs := GameState.new_game(1, _db)
	ToyCanon.sleep_through(gs, _db, FIRST_DAY - 1)
	_base_json = gs.to_json()


## Kills `npc` on day 85, sleeps through day 96. Returns the game state.
func _run(npc: String) -> GameState:
	var gs := GameState.from_json(_base_json)
	assert_eq(gs.clock.day(), FIRST_DAY)
	if npc != "":
		assert_eq(Commands.kill_npc(gs, _db, npc), "")
	while gs.world.last_day < LAST_DAY:
		Commands.sleep(gs, _db, Rest.ANYWHERE)
	return gs


## Book 4 canon events (not alt events) that did not happen.
func _lost(gs: GameState) -> Array[String]:
	var out: Array[String] = []
	for id: String in _db.canon.events:
		if id.begins_with("b4.") and not _db.canon.alt_only.has(id) and not Director.happened(gs.world.status(id)):
			out.append(id)
	return out


func _check_ceiling(gs: GameState, npc: String) -> void:
	var lost := _lost(gs)
	assert_lte(lost.size(), int(CEILING[npc][0]), "%s: Book 4 events lost" % npc)
	assert_gt(gs.world.drift, 0.0)
	assert_lte(gs.world.drift, float(CEILING[npc][1]), "%s: drift" % npc)
	for id: String in _db.canon.events:
		if id.begins_with("b4.") and int(_db.canon.events[id]["window"]["latest"]) <= LAST_DAY \
				and not _db.canon.alt_only.has(id):
			assert_ne(gs.world.status(id), WorldState.PENDING, "%s is resolved" % id)


func _happened(gs: GameState, ids: Array) -> void:
	for id: String in ids:
		assert_true(Director.happened(gs.world.status("b4." + id)), id)


func _not_happened(gs: GameState, ids: Array) -> void:
	for id: String in ids:
		assert_false(Director.happened(gs.world.status("b4." + id)), id)


func _entry(gs: GameState, id: String) -> Dictionary:
	for h: Dictionary in gs.world.history:
		if h["event"] == id and h["outcome"] != Director.DELAYED:
			return h
	return {}


## The canon event mutated into `alt` on `day`, and the alt ran.
func _mutated(gs: GameState, id: String, alt: String, day: int) -> void:
	var e := _entry(gs, "b4." + id)
	assert_eq(e.get("outcome", ""), Director.MUTATED, id)
	assert_eq(e.get("via", ""), "b4." + alt, id)
	assert_eq(int(e.get("day", 0)), day, "%s mutates on its own day" % id)
	assert_eq(gs.world.status("b4." + alt), Director.DONE, alt)


func test_every_day_with_on_map_canon_has_a_hook() -> void:
	var on_map := {}
	for area: String in _db.maps.areas:
		on_map[_db.maps.areas[area]["location"]] = true
	var days := {}
	var hooked := {}
	for id: String in _db.canon.events:
		var ev: Dictionary = _db.canon.events[id]
		if not id.begins_with("b4.") or _db.canon.alt_only.has(id) or not on_map.has(ev["location"]):
			continue
		var day := int(ev["window"]["earliest"])
		days[day] = true
		for h: Dictionary in ev.get("hooks", []):
			for d in range(int(h["days"][0]), int(h["days"][1]) + 1):
				hooked[d] = true
	assert_eq(days.size(), 9)
	for day: int in days:
		assert_true(hooked.has(day), "day %d has a hook" % day)


func test_cooking_at_the_inn_on_the_solstice_changes_the_dawn() -> void:
	var gs := GameState.from_json(_base_json)
	ToyCanon.sleep_through(gs, _db, 95)
	assert_eq(gs.clock.day(), 96)
	gs.player.place("inn_interior", Vector2i(20, 2))
	Commands.settle(gs, _db)
	var r := Commands.interact(gs, _db, "stove", "cook_simple_meal")
	assert_eq(r["error"], "")
	ToyCanon.sleep_through(gs, _db, 96)
	var ev := _entry(gs, "b4.friends_come_home_at_the_solstice_dawn")
	assert_eq(ev["outcome"], Director.CHANGED)
	assert_eq(ev["hook"], "player_restocked_the_solstice_kitchen")
	assert_true(gs.flags.has("wandering_inn.earther_restocked_the_kitchen"))
	assert_true(gs.flags.has("erin.keeps_the_white_coin"), "the canon effects still happen")
	assert_almost_eq(gs.world.drift, 0.25, 0.000001)


func test_no_kill_never_runs_an_alt_event() -> void:
	var gs := _run("")
	assert_eq(_lost(gs), [] as Array[String])
	assert_eq(gs.world.drift, 0.0)
	for id: String in ALTS:
		assert_true(_db.canon.alt_only.has("b4." + id), id)
		assert_eq(gs.world.status("b4." + id), WorldState.PENDING, id)


func test_erin_dies_and_the_other_threads_go_on() -> void:
	var gs := _run("erin_solstice")
	_check_ceiling(gs, "erin_solstice")
	_mutated(gs, "teriarch_hides_the_wagon_in_a_snowstorm", "the_horns_hide_from_the_goblin_army", 89)
	_happened(gs, ["mrsha_flees_zels_scent", "mrsha_rescued_from_the_dungeon", "toren_watches_mrsha_fall",
		"rags_breaks_out_of_tremborags_mountain", "rags_robs_a_caravan_to_ostegrast", "ryoka_reads_magnolias_library",
		"ryoka_greets_laken_in_german", "laken_holds_court_in_the_merchants_guild", "ryoka_brings_food_and_presents_to_riverfarm",
		"riders_hold_back_the_dark_for_ryoka", "lyonette_finds_the_hidden_basement", "griffon_hunt_and_the_halfseekers_join_forces"])
	_not_happened(gs, ERINS_WINTER)


func test_zel_dies_and_erins_winter_goes_on() -> void:
	var gs := _run("zel_shivertail")
	_check_ceiling(gs, "zel_shivertail")
	_happened(gs, ERINS_WINTER)
	_happened(gs, ["the_gold_teams_fill_the_inn", "klbkch_and_erin_talk_on_the_roof", "the_free_queen_sends_help_to_esthelm",
		"teriarch_hides_the_wagon_in_a_snowstorm"])
	_not_happened(gs, ["mrsha_flees_zels_scent", "mrsha_falls_into_the_rift", "zel_scolds_erin_for_lyonette",
		"pawn_asks_zel_what_to_tell_the_dying", "xrn_names_wrymvr_as_sserys_killer"])
	assert_false(gs.flags.has("liscor.dungeon_rift_found"), "Mrsha never ran, so no one found the rift")


func test_ceria_dies_and_erin_comes_home_alone() -> void:
	var gs := _run("ceria_springwalker")
	_check_ceiling(gs, "ceria_springwalker")
	assert_eq(gs.world.status("b3.erin_goes_home_without_the_horns"), Director.DONE, "Book 3 hand-off")
	assert_eq(gs.world.status("b4.teriarch_stops_the_wagon"), Director.DONE)
	_mutated(gs, "teriarch_hides_the_wagon_in_a_snowstorm", "the_wagon_hides_from_the_goblin_army", 89)
	_mutated(gs, "erin_comes_home_to_the_wandering_inn", "erin_comes_home_without_the_door", 91)
	_mutated(gs, "the_wagons_gather_for_esthelm", "liscor_sends_wagons_to_esthelm", 92)
	assert_eq(int(_entry(gs, "b4.the_relief_convoy_reaches_esthelm")["day"]), 92, "the hand-off runs the same day")
	_happened(gs, ERINS_WINTER.filter(func(id: String) -> bool: return id != "erin_comes_home_to_the_wandering_inn"))
	_not_happened(gs, ["ceria_tells_erin_of_wistram", "erin_feeds_the_horns_corusdeer_soup", "the_door_runs_dry_and_the_mages_link_hands",
		"erin_pays_octavia_to_research_matches_and_penicillin"])
	assert_false(gs.flags.has("albez_door.at_wandering_inn"))


func test_teriarch_dies_and_the_wagon_hides_on_its_own() -> void:
	var gs := _run("teriarch")
	_check_ceiling(gs, "teriarch")
	assert_eq(gs.world.status("b4.teriarch_stops_the_wagon"), Director.CANCELLED)
	_mutated(gs, "teriarch_hides_the_wagon_in_a_snowstorm", "the_wagon_hides_from_the_goblin_army", 89)
	assert_true(gs.flags.has("goblin_army.on_the_liscor_road"))
	assert_false(gs.flags.has("erin.met_teriarch"))
	_happened(gs, ERINS_WINTER)
	_happened(gs, ["ceria_tells_erin_of_wistram", "erin_doubts_the_wistram_story", "the_horns_reach_esthelm"])
	assert_lt(gs.world.drift, float(_db.rules["director"]["unreliable_at"]), "one small bend, no warning")


func test_klbkch_dies_and_pawn_brings_mrsha_out_of_the_hive() -> void:
	var gs := _run("klbkch")
	_check_ceiling(gs, "klbkch")
	_mutated(gs, "mrsha_strays_into_the_hive", "pawn_leads_mrsha_out_of_the_hive", 85)
	assert_eq(int(_entry(gs, "b4.brunkr_calls_mrsha_a_doombringer")["day"]), 85, "a delayed hand-off keeps its day")
	_happened(gs, ERINS_WINTER)
	_happened(gs, ["mrsha_falls_into_the_rift", "mrsha_rescued_from_the_dungeon", "relc_and_klbkch_play_santa",
		"santa_catches_two_drake_thieves", "the_wagons_gather_for_esthelm"])
	_not_happened(gs, ["klbkch_and_erin_talk_on_the_roof", "the_free_queen_sends_help_to_esthelm",
		"pawn_asks_zel_what_to_tell_the_dying"])
	assert_false(gs.flags.has("antinium.expedition_to_esthelm"))


func test_lyonette_dies_and_erins_winter_goes_on() -> void:
	var gs := _run("lyonette")
	_check_ceiling(gs, "lyonette")
	_happened(gs, ERINS_WINTER)
	_happened(gs, ["mrsha_rescued_from_the_dungeon", "the_gold_teams_fill_the_inn", "the_door_runs_dry_and_the_mages_link_hands"])
	_not_happened(gs, ["lyonette_finds_the_hidden_basement", "zel_scolds_erin_for_lyonette", "lyonette_swears_an_oath_to_the_stars"])


func test_pisces_dies_and_liscor_alone_sends_the_relief() -> void:
	var gs := _run("pisces")
	_check_ceiling(gs, "pisces")
	assert_eq(gs.world.status("b3.erin_and_the_horns_leave_celum_without_the_door"), Director.DONE, "Book 3 hand-off")
	_mutated(gs, "erin_comes_home_to_the_wandering_inn", "erin_comes_home_without_the_door", 91)
	_mutated(gs, "the_wagons_gather_for_esthelm", "liscor_sends_wagons_to_esthelm", 92)
	_happened(gs, ERINS_WINTER.filter(func(id: String) -> bool: return id != "erin_comes_home_to_the_wandering_inn"))
	_happened(gs, ["teriarch_hides_the_wagon_in_a_snowstorm", "ceria_tells_erin_of_wistram", "erin_feeds_the_horns_corusdeer_soup",
		"erin_pitches_the_esthelm_relief"])
	assert_false(gs.flags.has("celum.sends_aid_to_esthelm"))
	assert_true(gs.flags.has("liscor.sends_aid_to_esthelm"))
