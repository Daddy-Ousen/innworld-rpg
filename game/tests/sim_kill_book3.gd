extends GutTest
## M23.2 (ADR 0036): a key Book 3 NPC dies on day 72 and the book still runs.
## Threads that do not need the dead NPC go on; the dead NPC's own events
## cancel; substitutes and alt events show in the history; drift stays in
## proportion. Key NPCs and events: docs/divergence/picks.md (plus Yvlon and
## Ksmvr for the Albez chain). The game is slept to day 40 and day 71 once
## (before_all); each test starts from a copy.

const FIRST_DAY := 72
const LAST_DAY := 91
## Book 3 canon events that did not happen (cancelled or mutated), and total
## drift (all books), at most. Before M23.2: Erin 52 / 113, Octavia 49 / 110,
## Ceria 40 / 101.5, Pisces 39 / 100.5, Lyonette 34 / 81, Yvlon 33 / 94.5, Ksmvr 31 / 92.5.
const CEILING := {
	"erin_solstice": [27, 74.0],
	"octavia": [4, 5.0],
	"ceria_springwalker": [30, 92.0],
	"pisces": [9, 56.0],
	"lyonette": [19, 66.5],
	"yvlon_byres": [3, 3.0],
	"ksmvr": [1, 1.5],
}
const ALTS := ["horns_dig_into_albez_by_hand", "horns_climb_out_of_the_pit_by_hand", "horns_outlast_the_flame_guardian",
	"reynold_fetches_ryoka_from_celum", "pawn_resolves_alone_to_tell_klbkch", "pawn_takes_twenty_soldiers_above_ground",
	"erin_and_the_horns_leave_celum_without_the_door", "erin_goes_home_without_the_horns",
	"the_horns_leave_celum_without_erin"]

var _db: DataDb
var _base_json := ""
var _book2_json := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	var gs := GameState.new_game(1, _db)
	ToyCanon.sleep_through(gs, _db, 40)
	_book2_json = gs.to_json()
	ToyCanon.sleep_through(gs, _db, FIRST_DAY - 1)
	_base_json = gs.to_json()


## Kills `npc` on the first day of `json`, sleeps through day 91. Returns {"gs", "lines"}.
func _run(npc: String, json: String = "") -> Dictionary:
	var gs := GameState.from_json(_base_json if json == "" else json)
	if json == "":
		assert_eq(gs.clock.day(), FIRST_DAY)
	if npc != "":
		assert_eq(Commands.kill_npc(gs, _db, npc), "")
	var lines: Array[String] = []
	while gs.world.last_day < LAST_DAY:
		lines.append_array(Commands.sleep(gs, _db, Rest.ANYWHERE)["lines"])
	return {"gs": gs, "lines": lines}


## Book 3 canon events (not alt events) that did not happen.
func _lost(gs: GameState) -> Array[String]:
	var out: Array[String] = []
	for id: String in _db.canon.events:
		if id.begins_with("b3.") and not _db.canon.alt_only.has(id) and not Director.happened(gs.world.status(id)):
			out.append(id)
	return out


func _check_ceiling(gs: GameState, npc: String) -> void:
	var lost := _lost(gs)
	assert_lte(lost.size(), int(CEILING[npc][0]), "%s: Book 3 events lost" % npc)
	assert_gt(gs.world.drift, 0.0)
	assert_lte(gs.world.drift, float(CEILING[npc][1]), "%s: drift" % npc)
	for id: String in _db.canon.events:
		if id.begins_with("b3.") and int(_db.canon.events[id]["window"]["latest"]) <= LAST_DAY \
				and not _db.canon.alt_only.has(id):
			assert_ne(gs.world.status(id), WorldState.PENDING, "%s is resolved" % id)


func _happened(gs: GameState, ids: Array) -> void:
	for id: String in ids:
		assert_true(Director.happened(gs.world.status("b3." + id)), id)


func _not_happened(gs: GameState, ids: Array) -> void:
	for id: String in ids:
		assert_false(Director.happened(gs.world.status("b3." + id)), id)


func _entry(gs: GameState, id: String) -> Dictionary:
	for h: Dictionary in gs.world.history:
		if h["event"] == id and h["outcome"] != Director.DELAYED:
			return h
	return {}


## The canon event mutated into `alt` on `day`, and the alt ran.
func _mutated(gs: GameState, id: String, alt: String, day: int) -> void:
	var e := _entry(gs, "b3." + id)
	assert_eq(e.get("outcome", ""), Director.MUTATED, id)
	assert_eq(e.get("via", ""), "b3." + alt, id)
	assert_eq(int(e.get("day", 0)), day, "%s mutates on its own day" % id)
	assert_eq(gs.world.status("b3." + alt), Director.DONE, alt)


func test_every_day_with_on_map_canon_has_a_hook() -> void:
	var on_map := {}
	for area: String in _db.maps.areas:
		on_map[_db.maps.areas[area]["location"]] = true
	var days := {}
	var hooked := {}
	for id: String in _db.canon.events:
		var ev: Dictionary = _db.canon.events[id]
		if not id.begins_with("b3.") or _db.canon.alt_only.has(id) or not on_map.has(ev["location"]):
			continue
		var day := int(ev["window"]["earliest"])
		days[day] = true
		for h: Dictionary in ev.get("hooks", []):
			for d in range(int(h["days"][0]), int(h["days"][1]) + 1):
				hooked[d] = true
	assert_eq(days.size(), 23)
	for day: int in days:
		assert_true(hooked.has(day), "day %d has a hook" % day)


func test_playing_chess_at_the_inn_on_day_81_changes_pawns_supper() -> void:
	var gs := GameState.from_json(_base_json)
	ToyCanon.sleep_through(gs, _db, 80)
	assert_eq(gs.clock.day(), 81)
	gs.player.place("inn_interior", Vector2i(5, 6))
	Commands.settle(gs, _db)
	var r := Commands.interact(gs, _db, "chess_table", "play_chess")
	assert_eq(r["error"], "")
	ToyCanon.sleep_through(gs, _db, 81)
	var ev := _entry(gs, "b3.pawn_eats_eggs_and_bacon_at_lyonettes_inn")
	assert_eq(ev["outcome"], Director.CHANGED)
	assert_eq(ev["hook"], "player_kept_pawn_company")
	assert_true(gs.flags.has("wandering_inn.earther_kept_pawn_company"))
	assert_true(gs.flags.has("pawn.will_take_the_soldiers_above"), "the canon effects still happen")
	assert_almost_eq(gs.world.drift, 0.25, 0.000001)


func test_no_kill_never_runs_an_alt_event() -> void:
	var gs: GameState = _run("")["gs"]
	assert_eq(_lost(gs), [] as Array[String])
	assert_eq(gs.world.drift, 0.0)
	for id: String in ALTS:
		assert_true(_db.canon.alt_only.has("b3." + id), id)
		assert_eq(gs.world.status("b3." + id), WorldState.PENDING, id)


func test_erin_dies_and_ryokas_thread_goes_on() -> void:
	var r := _run("erin_solstice")
	var gs: GameState = r["gs"]
	_check_ceiling(gs, "erin_solstice")
	_happened(gs, ["ryoka_befriends_ivolethe", "ryoka_beats_persua_in_the_runners_guild", "ryoka_runs_to_ocre_to_find_ceria",
		"ressa_takes_ryoka_from_ocre", "magnolia_questions_ryoka", "magnolia_kills_nemor_and_his_assassins",
		"horns_dig_gold_from_the_burnt_vault", "horns_reach_celum", "lyonette_reopens_the_inn",
		"pawns_soldiers_stop_a_street_battle", "the_last_battle_of_esthelm"])
	_not_happened(gs, ["erin_feeds_crepes_to_the_frost_faeries", "ryoka_pays_octavia_to_keep_helping_erin",
		"erin_stages_romeo_and_juliet", "the_horns_give_erin_the_albez_door"])
	_mutated(gs, "erin_leaves_celum_on_the_wagon", "the_horns_leave_celum_without_erin", 87)
	assert_true(gs.flags.has("horns_of_hammerad.bound_for_liscor"))
	assert_false(gs.flags.has("erin.left_celum"))


func test_octavia_dies_and_erins_celum_goes_on() -> void:
	var gs: GameState = _run("octavia")["gs"]
	_check_ceiling(gs, "octavia")
	_happened(gs, ["erin_hires_jasi_at_the_frenzied_hare", "erin_stages_romeo_and_juliet", "horns_watch_hamlet_at_the_frenzied_hare",
		"pisces_severs_torens_link_to_erin", "erin_stages_frozen", "the_horns_give_erin_the_albez_door",
		"erin_leaves_celum_on_the_wagon", "most_frost_faeries_leave_ryoka", "ryoka_befriends_ivolethe"])
	_not_happened(gs, ["erin_and_octavia_brew_corusdeer_soup", "erin_brews_thickskin_soup",
		"ryoka_pays_octavia_to_keep_helping_erin", "erin_says_goodbye_to_octavia"])
	assert_true(gs.flags.has("erin.has_albez_door"))


func test_ceria_dies_and_reynold_fetches_ryoka_from_celum() -> void:
	var gs: GameState = _run("ceria_springwalker")["gs"]
	_check_ceiling(gs, "ceria_springwalker")
	assert_eq(gs.world.status("b3.horns_run_out_of_coin_at_albez"), Director.CANCELLED, "Ceria leads the Horns")
	_mutated(gs, "ressa_takes_ryoka_from_ocre", "reynold_fetches_ryoka_from_celum", 76)
	_happened(gs, ["ryoka_glimpses_the_wind_from_the_coach", "ryoka_arrives_at_magnolias_estate", "magnolia_questions_ryoka",
		"magnolia_kills_nemor_and_his_assassins", "erin_stages_romeo_and_juliet", "erin_says_goodbye_to_octavia",
		"pawns_soldiers_stop_a_street_battle"])
	_mutated(gs, "erin_leaves_celum_on_the_wagon", "erin_goes_home_without_the_horns", 87)
	assert_true(gs.flags.has("erin.on_wagon_south"))
	assert_false(gs.flags.has("horns_of_hammerad.has_albez_treasure"))
	assert_false(gs.flags.has("ryoka.carries_the_horns_relics"), "no relics without the Ocre visit")


func test_pisces_dies_and_the_horns_dig_albez_by_hand() -> void:
	var gs: GameState = _run("pisces")["gs"]
	_check_ceiling(gs, "pisces")
	_mutated(gs, "pisces_raises_skeletons_to_dig_albez", "horns_dig_into_albez_by_hand", 72)
	_mutated(gs, "pisces_builds_a_bone_stair_out_of_the_pit", "horns_climb_out_of_the_pit_by_hand", 73)
	assert_eq(int(_entry(gs, "b3.horns_wipe_out_a_creler_nest")["day"]), 72, "the hand-off runs the same day")
	_happened(gs, ["horns_teleported_into_the_insanity_pit", "horns_break_into_warmage_thresks_vault",
		"yvlon_shatters_the_flame_guardian", "horns_dig_gold_from_the_burnt_vault", "ocre_parades_the_horns_of_hammerad",
		"ryoka_runs_to_ocre_to_find_ceria", "ressa_takes_ryoka_from_ocre", "horns_reach_celum",
		"horns_watch_hamlet_at_the_frenzied_hare", "erin_stages_frozen", "erin_says_goodbye_to_octavia"])
	_not_happened(gs, ["pisces_confesses_he_made_toren_to_level", "pisces_and_ksmvr_recover_the_albez_door",
		"the_horns_give_erin_the_albez_door"])
	_mutated(gs, "erin_leaves_celum_on_the_wagon", "erin_and_the_horns_leave_celum_without_the_door", 87)
	assert_true(gs.flags.has("erin.on_wagon_south"))
	assert_true(gs.flags.has("horns_of_hammerad.bound_for_liscor"))
	assert_false(gs.flags.has("erin.has_albez_door"))


func test_lyonette_dies_and_pawns_thread_goes_on() -> void:
	var gs: GameState = _run("lyonette")["gs"]
	_check_ceiling(gs, "lyonette")
	_mutated(gs, "pawn_resolves_to_tell_klbkch_of_his_class", "pawn_resolves_alone_to_tell_klbkch", 76)
	assert_eq(int(_entry(gs, "b3.klbkch_nearly_kills_pawn_over_god")["day"]), 76)
	_mutated(gs, "pawn_brings_twenty_soldiers_to_the_inn", "pawn_takes_twenty_soldiers_above_ground", 82)
	_happened(gs, ["soldiers_kill_each_other_for_heaven", "pawn_takes_command_of_the_wounded_soldiers",
		"zevara_lets_twenty_soldiers_above_ground", "pawn_leads_the_soldiers_on_patrol", "klbkch_praises_pawns_patrol",
		"pawn_buys_cheese_for_the_soldiers", "the_antinium_delegation_arrives", "pawns_soldiers_stop_a_street_battle",
		"zel_shield_walls_the_scaleling_attack"])
	_not_happened(gs, ["lyonette_reopens_the_inn", "the_soldiers_paint_themselves", "mrsha_runs_back_to_the_inn",
		"zel_takes_a_room_at_the_wandering_inn"])
	assert_false(gs.flags.has("liscor_hive.soldiers_painted"))


func test_yvlon_dies_and_the_horns_outlast_the_flame_guardian() -> void:
	var gs: GameState = _run("yvlon_byres")["gs"]
	_check_ceiling(gs, "yvlon_byres")
	_mutated(gs, "yvlon_shatters_the_flame_guardian", "horns_outlast_the_flame_guardian", 74)
	assert_eq(int(_entry(gs, "b3.ocre_guards_shoot_at_ksmvr")["day"]), 74, "a delayed hand-off keeps its dependents")
	_happened(gs, ["horns_dig_gold_from_the_burnt_vault", "horns_bank_their_treasure_in_ocre", "horns_ride_a_wagon_out_of_remendia",
		"pisces_confesses_he_made_toren_to_level", "the_horns_give_erin_the_albez_door", "erin_leaves_celum_on_the_wagon"])
	assert_false(gs.flags.has("yvlon.armor_fused_to_arms"))
	assert_lt(gs.world.drift, float(_db.rules["director"]["unreliable_at"]), "one small bend, no warning")


func test_ksmvr_dies_and_ceria_helps_dig_up_the_door() -> void:
	var gs: GameState = _run("ksmvr")["gs"]
	_check_ceiling(gs, "ksmvr")
	var door := _entry(gs, "b3.pisces_and_ksmvr_recover_the_albez_door")
	assert_eq(door["outcome"], Director.SUBSTITUTED)
	assert_eq(door["roles"]["antinium"], "ceria_springwalker", "Ceria goes with Pisces")
	_happened(gs, ["horns_bank_their_treasure_in_ocre", "ocre_parades_the_horns_of_hammerad", "the_horns_give_erin_the_albez_door",
		"erin_leaves_celum_on_the_wagon"])
	_not_happened(gs, ["ocre_guards_shoot_at_ksmvr"])


func test_ksmvr_dies_in_book_2_and_the_horns_still_go_to_albez() -> void:
	var gs: GameState = _run("ksmvr", _book2_json)["gs"]
	assert_true(Director.happened(gs.world.status("b2.horns_of_hammerad_fight_off_the_goblin_raid")))
	assert_true(Director.happened(gs.world.status("b2.horns_of_hammerad_claim_the_albez_map")))
	_happened(gs, ["horns_run_out_of_coin_at_albez", "horns_dig_gold_from_the_burnt_vault", "horns_reach_celum",
		"the_horns_give_erin_the_albez_door"])
	assert_lte(_lost(gs).size(), 1, "only the Ocre volley at Ksmvr")
