extends GutTest
## M23.1 (ADR 0036): a key Book 2 NPC dies on day 41 and the book still runs.
## Threads that do not need the dead NPC go on; the dead NPC's own events
## cancel; substitutes and alt events show in the history; drift stays in
## proportion. Key NPCs and events: docs/divergence/picks.md. The game is
## slept to day FIRST_DAY - 1 once (before_all); each test starts from a copy.

const FIRST_DAY := 41
const LAST_DAY := 71
## Book 2 canon events that did not happen (cancelled or mutated), and total
## drift (all books), at most. Before M23.1: Erin 140 / 261.5, Ryoka 76 / 127,
## Toren 77 / 135, Rags 42 / 40.5, Ceria 42 / 136, Pisces 30 / 124.5, Yvlon 7 / 107.5.
const CEILING := {
	"erin_solstice": [109, 162.0],
	"ryoka_griffin": [64, 104.0],
	"toren": [57, 117.0],
	"rags": [27, 26.0],
	"ceria_springwalker": [25, 122.0],
	"pisces": [13, 11.5],
	"yvlon_byres": [4, 4.0],
}

var _db: DataDb
var _base_json := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	var gs := GameState.new_game(1, _db)
	ToyCanon.sleep_through(gs, _db, FIRST_DAY - 1)
	_base_json = gs.to_json()


## Kills `npc` on day 41, sleeps through day 71. Returns {"gs", "lines"}.
func _run(npc: String) -> Dictionary:
	var gs := GameState.from_json(_base_json)
	assert_eq(gs.clock.day(), FIRST_DAY)
	if npc != "":
		assert_eq(Commands.kill_npc(gs, _db, npc), "")
	var lines: Array[String] = []
	while gs.world.last_day < LAST_DAY:
		lines.append_array(Commands.sleep(gs, _db, Rest.ANYWHERE)["lines"])
	return {"gs": gs, "lines": lines}


## Book 2 canon events (not alt events) that did not happen.
func _lost(gs: GameState) -> Array[String]:
	var out: Array[String] = []
	for id: String in _db.canon.events:
		if id.begins_with("b2.") and not _db.canon.alt_only.has(id) and not Director.happened(gs.world.status(id)):
			out.append(id)
	return out


func _check_ceiling(gs: GameState, npc: String) -> void:
	var lost := _lost(gs)
	assert_lte(lost.size(), int(CEILING[npc][0]), "%s: Book 2 events lost" % npc)
	assert_gt(gs.world.drift, 0.0)
	assert_lte(gs.world.drift, float(CEILING[npc][1]), "%s: drift" % npc)
	for id: String in _db.canon.events:
		if id.begins_with("b2.") and int(_db.canon.events[id]["window"]["latest"]) <= LAST_DAY \
				and not _db.canon.alt_only.has(id):
			assert_ne(gs.world.status(id), WorldState.PENDING, "%s is resolved" % id)


func _happened(gs: GameState, ids: Array) -> void:
	for id: String in ids:
		assert_true(Director.happened(gs.world.status("b2." + id)), id)


func _not_happened(gs: GameState, ids: Array) -> void:
	for id: String in ids:
		assert_false(Director.happened(gs.world.status("b2." + id)), id)


func _entry(gs: GameState, id: String) -> Dictionary:
	for h: Dictionary in gs.world.history:
		if h["event"] == id:
			return h
	return {}


func test_every_day_with_on_map_canon_has_a_hook() -> void:
	var on_map := {}
	for area: String in _db.maps.areas:
		on_map[_db.maps.areas[area]["location"]] = true
	var days := {}
	var hooked := {}
	for id: String in _db.canon.events:
		var ev: Dictionary = _db.canon.events[id]
		if not id.begins_with("b2.") or _db.canon.alt_only.has(id) or not on_map.has(ev["location"]):
			continue
		var day := int(ev["window"]["earliest"])
		days[day] = true
		for h: Dictionary in ev.get("hooks", []):
			for d in range(int(h["days"][0]), int(h["days"][1]) + 1):
				hooked[d] = true
	assert_eq(days.size(), 22)
	for day: int in days:
		assert_true(hooked.has(day), "day %d has a hook" % day)


func test_playing_chess_at_the_inn_on_day_47_changes_klbkchs_lesson() -> void:
	var gs := GameState.from_json(_base_json)
	ToyCanon.sleep_through(gs, _db, 46)
	assert_eq(gs.clock.day(), 47)
	gs.player.place("inn_interior", Vector2i(5, 6))
	Commands.settle(gs, _db)
	var r := Commands.interact(gs, _db, "chess_table", "play_chess")
	assert_eq(r["error"], "")
	ToyCanon.sleep_through(gs, _db, 47)
	var ev := _entry(gs, "b2.klbkch_tries_forcing_chess_on_workers")
	assert_eq(ev["outcome"], Director.CHANGED)
	assert_eq(ev["hook"], "player_taught_the_workers_chess")
	assert_true(gs.flags.has("wandering_inn.earther_taught_workers_chess"))
	assert_true(gs.flags.has("klbkch.tried_forcing_chess_on_workers"), "the canon effects still happen")
	assert_almost_eq(gs.world.drift, 0.25, 0.000001)


func test_no_kill_never_runs_an_alt_event() -> void:
	var gs: GameState = _run("")["gs"]
	assert_eq(_lost(gs), [] as Array[String])
	assert_eq(gs.world.drift, 0.0)
	for id: String in ["b2.ceria_reforms_the_horns_short_handed", "b2.goblin_lord_overruns_the_stone_spears",
			"b2.erin_winters_in_liscor"]:
		assert_true(_db.canon.alt_only.has(id), id)
		assert_eq(gs.world.status(id), WorldState.PENDING, id)


func test_erin_dies_and_the_other_threads_go_on() -> void:
	var r := _run("erin_solstice")
	var gs: GameState = r["gs"]
	_check_ceiling(gs, "erin_solstice")
	assert_eq((r["lines"] as Array).count(Director.UNRELIABLE_LINE), 1, "the drift warning comes once")
	var rescue := _entry(gs, "b2.erin_leads_the_rescue_into_the_ruins")
	assert_eq(rescue["outcome"], Director.SUBSTITUTED)
	assert_eq(rescue["roles"]["host"], "klbkch", "Klbkch leads the Ruins rescue")
	_happened(gs, ["ceria_and_olesm_found_in_the_coffins", "pisces_restores_the_call_log",
		"ryoka_runs_north_for_gold", "ryoka_reaches_celum_in_the_snow", "ryoka_confronts_teriarch",
		"ryoka_detects_curse_dreamcatcher", "hawk_gives_blood_fields_briefing",
		"rags_builds_crossbows", "rags_ambushes_jawbreaker_chief", "rags_defeats_garen_wins_red_fang", "rags_burns_esthelm",
		"ceria_reforms_the_horns_of_hammerad", "ksmvr_joins_the_horns_of_hammerad", "horns_of_hammerad_claim_the_albez_map",
		"ryoka_escapes_with_mrsha_gains_first_class", "ryoka_returns_with_mrsha", "ryoka_tells_liscor_the_stone_spears_are_gone",
		"magnolia_plans_to_bring_zel_north", "drake_assembly_silences_zel", "niers_maps_the_dangersense_alarms"])
	_not_happened(gs, ["ryoka_meets_erin", "erin_takes_in_lyonette", "battle_at_the_wandering_inn",
		"toren_drags_erin_north_and_leaves_her", "gazi_attacks_outside_the_ruins"])
	assert_eq(gs.world.status("b2.erin_winters_in_liscor"), WorldState.PENDING, "no Erin, no winter in Liscor")
	assert_true(gs.flags.has("esthelm.burned"))
	assert_true(gs.flags.has("horns_of_hammerad.reformed"))


func test_ryoka_dies_and_the_goblin_lord_still_comes_on_day_65() -> void:
	var gs: GameState = _run("ryoka_griffin")["gs"]
	_check_ceiling(gs, "ryoka_griffin")
	var army := _entry(gs, "b2.goblin_lords_army_destroys_stone_spears_camp")
	assert_eq(army["outcome"], Director.MUTATED)
	assert_eq(army["via"], "b2.goblin_lord_overruns_the_stone_spears")
	assert_eq(int(army["day"]), 65, "the alt runs on its own day, not when the chain broke")
	assert_eq(gs.world.status("b2.goblin_lord_overruns_the_stone_spears"), Director.DONE)
	assert_true(gs.world.is_alive(_db.canon, "urksh"), "the alt kills no one")
	_happened(gs, ["drake_assembly_silences_zel", "magnolia_plans_to_bring_zel_north",
		"valceif_delivers_chessboard_to_erin", "niers_astoragon_revealed_as_opponent",
		"erin_prepares_faerie_banquet", "battle_at_the_wandering_inn", "toren_drags_erin_north_and_leaves_her"])
	_not_happened(gs, ["ryoka_escapes_with_mrsha_gains_first_class", "ryoka_returns_with_mrsha",
		"azkerash_sends_venitra_after_ryoka"])
	assert_true(gs.flags.has("stone_spears.tribe_devastated"))


func test_toren_dies_and_erin_winters_in_liscor() -> void:
	var gs: GameState = _run("toren")["gs"]
	_check_ceiling(gs, "toren")
	var drag := _entry(gs, "b2.toren_drags_erin_north_and_leaves_her")
	assert_eq(drag["outcome"], Director.MUTATED)
	assert_eq(int(drag["day"]), 70)
	assert_eq(gs.world.status("b2.erin_winters_in_liscor"), Director.DONE)
	assert_true(gs.flags.has("erin.wintered_in_liscor"))
	assert_false(gs.flags.has("erin.stranded_north"))
	_happened(gs, ["rags_builds_crossbows", "rags_burns_esthelm", "valceif_delivers_chessboard_to_erin",
		"ryoka_arrives_exhausted_reunites", "ryoka_detects_curse_dreamcatcher", "erin_iphone_concert_night",
		"erin_declares_protection_of_lyonette", "battle_at_the_wandering_inn", "halfseekers_reveal_species_offer_ceria"])
	_not_happened(gs, ["toren_blows_up_the_inn", "antinium_rebuild_inn_in_a_day", "erin_reaches_celum"])


func test_rags_dies_and_ryokas_thread_goes_on() -> void:
	var gs: GameState = _run("rags")["gs"]
	_check_ceiling(gs, "rags")
	_happened(gs, ["ryoka_returns_with_mrsha", "erin_and_ryoka_fight_over_magnolia", "klbkch_shares_hive_secrets_with_ryoka",
		"ryoka_learns_of_the_faerie_flower_drink", "toren_drags_erin_north_and_leaves_her", "erin_takes_over_the_frenzied_hares_kitchen"])
	_not_happened(gs, ["rags_burns_esthelm", "erin_throws_relc_out_to_protect_the_goblins"])
	assert_false(gs.flags.has("esthelm.burned"))


func test_ceria_dies_and_the_horns_stay_broken() -> void:
	var gs: GameState = _run("ceria_springwalker")["gs"]
	_check_ceiling(gs, "ceria_springwalker")
	assert_eq(gs.world.status("b2.ceria_reforms_the_horns_of_hammerad"), Director.CANCELLED)
	assert_eq(gs.world.status("b2.ceria_reforms_the_horns_short_handed"), WorldState.PENDING, "Ceria founds the Horns")
	assert_eq(gs.world.status("b2.ksmvr_joins_the_horns_of_hammerad"), Director.CANCELLED)
	assert_false(gs.flags.has("horns_of_hammerad.reformed"))
	_happened(gs, ["rags_builds_crossbows", "ryoka_val_morning_run_courier_advice", "hawk_gives_blood_fields_briefing",
		"erin_iphone_concert_night", "erin_prepares_faerie_banquet", "battle_at_the_wandering_inn", "pisces_restores_the_call_log"])


func test_yvlon_dies_and_ceria_reforms_the_horns_short_handed() -> void:
	var gs: GameState = _run("yvlon_byres")["gs"]
	_check_ceiling(gs, "yvlon_byres")
	var reform := _entry(gs, "b2.ceria_reforms_the_horns_of_hammerad")
	assert_eq(reform["outcome"], Director.MUTATED)
	assert_eq(reform["via"], "b2.ceria_reforms_the_horns_short_handed")
	_happened(gs, ["ceria_reforms_the_horns_short_handed", "ksmvr_joins_the_horns_of_hammerad",
		"horns_of_hammerad_fight_off_the_goblin_raid", "horns_of_hammerad_claim_the_albez_map"])
	assert_true(gs.flags.has("horns_of_hammerad.short_handed"))
	assert_lt(gs.world.drift, float(_db.rules["director"]["unreliable_at"]), "one small bend, no warning")


func test_pisces_dies_and_relc_carries_selys_warning() -> void:
	var gs: GameState = _run("pisces")["gs"]
	_check_ceiling(gs, "pisces")
	var warn := _entry(gs, "b2.selys_recruits_pisces_to_warn_erin")
	assert_eq(warn["outcome"], Director.SUBSTITUTED)
	assert_eq(warn["roles"]["mage"], "relc")
	_happened(gs, ["erin_rushes_to_rescue_lyonette", "erin_takes_in_lyonette", "battle_at_the_wandering_inn",
		"ceria_reforms_the_horns_short_handed", "horns_of_hammerad_claim_the_albez_map"])
	_not_happened(gs, ["ceria_calls_pisces_from_the_ruins", "pisces_restores_the_call_log"])
