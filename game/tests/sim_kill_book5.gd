extends GutTest
## M23.4 (ADR 0036): a key Book 5 NPC dies and the book still runs.
## Izril: the NPC dies on day 97 and the game sleeps through day 115.
## Baleros (the Earthers' thread, days 77 – 90): Ken or Quallet dies on day 78.
## Threads that do not need the dead NPC go on; the dead NPC's own events
## cancel; alt events show in the history; drift stays in proportion. Key NPCs
## and events: docs/divergence/picks.md. The game is slept once (before_all);
## each test starts from a copy.

const FIRST_DAY := 97
const LAST_DAY := 115
const BALEROS_DAY := 78
## Book 5 canon events that did not happen (cancelled or mutated), and total
## drift (all books), at most. Before M23.4: Ryoka 34 / 33.5, Erin 30 / 31,
## Laken 15 / 14.5, Venitra 30 / 29.5, Lyonette 12 / 12, Ken 7 / 6.5, Quallet 6 / 6.
const CEILING := {
	"ryoka_griffin": [31, 30.0],
	"erin_solstice": [30, 31.0],
	"laken_godart": [15, 14.0],
	"venitra": [20, 19.0],
	"lyonette": [8, 8.5],
	"kenjiro_murata": [3, 3.0],
	"quallet_marshhand": [0, 0.5],
}
const ALTS := ["zt_luan_and_aiko_go_to_the_last_light", "t_erin_pays_the_antinium_to_build_the_inn",
	"zzzl_imenet_comes_to_liscor_alone", "zzzzd_imenet_seizes_ryoka_in_an_alley",
	"zzzzx_teriarch_revives_ryoka_and_flies_her_home", "zzzzzj_the_necromancer_calls_his_servants_home",
	"zzzzz_the_gnolls_burn_brunkr", "zzo_durene_drives_off_a_mossbear", "zzp_riverfarm_takes_in_windrest"]
## Ryoka's run for the Dragon and its end: needs Ryoka, not Erin or Venitra.
const RYOKAS_RUN := ["zzzzh_the_necromancer_lays_word_of_death_on_ryoka",
	"zzzzn_the_necromancer_warns_ryoka_and_ivolethe_strikes_ijvani", "zzzzo_ryoka_writes_a_letter_and_runs_for_the_dragon",
	"zzzzw_ryoka_names_the_necromancer_and_dies", "zzzzy_teriarch_and_the_necromancer_strike_an_accord",
	"zzzzzb_erin_sends_ryoka_away", "zzzzzd_ryoka_tells_krshia_and_zel_the_truth", "zzzzzg_ryoka_runs_north"]
## The Gnoll murders and Regrika's fight at the inn: need Venitra and Erin.
const REGRIKAS_END := ["zzzzj_venitra_murders_brunkr", "zzzzl_brunkrs_body_is_found_in_the_rift",
	"zzzzm_klbkch_truth_tests_the_feast_guests", "zzzzp_erin_feeds_regrika_a_steak_of_bone",
	"zzzzq_regrika_kills_ulrien_in_the_inn", "zzzzr_imenet_fights_zel_and_ilvriss_in_the_streets"]
## Laken's Riverfarm thread.
const RIVERFARM := ["zzm_laken_comes_home_to_riverfarm", "zzr_laken_raises_a_militia",
	"zzy_riverfarm_breaks_the_goblin_attack", "zzz_wiskeria_becomes_lakens_general"]
## The Red Cross and the United Nations company.
const LAST_LIGHT := ["zu_the_red_cross_company_is_founded", "zx_zalthia_burns_the_red_cross_camp",
	"zz_okasha_restarts_genevas_heart_and_she_leads_them_out", "zza_the_united_nations_company_is_founded"]

var _db: DataDb
var _base_json := ""
var _baleros_json := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	var gs := GameState.new_game(1, _db)
	ToyCanon.sleep_through(gs, _db, BALEROS_DAY - 1)
	_baleros_json = gs.to_json()
	ToyCanon.sleep_through(gs, _db, FIRST_DAY - 1)
	_base_json = gs.to_json()


## Kills `npc` (if any) on the first day of `base`, sleeps through day 115.
func _run(npc: String, base := "") -> GameState:
	var gs := GameState.from_json(_base_json if base == "" else base)
	if npc != "":
		assert_eq(Commands.kill_npc(gs, _db, npc), "")
	while gs.world.last_day < LAST_DAY:
		Commands.sleep(gs, _db, Rest.ANYWHERE)
	return gs


## Book 5 canon events (not alt events) that did not happen.
func _lost(gs: GameState) -> Array[String]:
	var out: Array[String] = []
	for id: String in _db.canon.events:
		if id.begins_with("b5.") and not _db.canon.alt_only.has(id) and not Director.happened(gs.world.status(id)):
			out.append(id)
	return out


func _check_ceiling(gs: GameState, npc: String) -> void:
	var lost := _lost(gs)
	assert_lte(lost.size(), int(CEILING[npc][0]), "%s: Book 5 events lost" % npc)
	assert_gt(gs.world.drift, 0.0)
	assert_lte(gs.world.drift, float(CEILING[npc][1]), "%s: drift" % npc)
	for id: String in _db.canon.events:
		if id.begins_with("b5.") and int(_db.canon.events[id]["window"]["latest"]) <= LAST_DAY \
				and not _db.canon.alt_only.has(id):
			assert_ne(gs.world.status(id), WorldState.PENDING, "%s is resolved" % id)


func _happened(gs: GameState, ids: Array) -> void:
	for id: String in ids:
		assert_true(Director.happened(gs.world.status("b5." + id)), id)


func _not_happened(gs: GameState, ids: Array) -> void:
	for id: String in ids:
		assert_false(Director.happened(gs.world.status("b5." + id)), id)


func _entry(gs: GameState, id: String) -> Dictionary:
	for h: Dictionary in gs.world.history:
		if h["event"] == id and h["outcome"] != Director.DELAYED:
			return h
	return {}


## The canon event mutated into `alt` on `day`, and the alt ran.
func _mutated(gs: GameState, id: String, alt: String, day: int) -> void:
	var e := _entry(gs, "b5." + id)
	assert_eq(e.get("outcome", ""), Director.MUTATED, id)
	assert_eq(e.get("via", ""), "b5." + alt, id)
	assert_eq(int(e.get("day", 0)), day, "%s mutates on its own day" % id)
	assert_eq(gs.world.status("b5." + alt), Director.DONE, alt)


func test_every_day_with_on_map_canon_has_a_hook() -> void:
	var on_map := {}
	for area: String in _db.maps.areas:
		on_map[_db.maps.areas[area]["location"]] = true
	var days := {}
	var hooked := {}
	for id: String in _db.canon.events:
		var ev: Dictionary = _db.canon.events[id]
		if not id.begins_with("b5.") or _db.canon.alt_only.has(id) or not on_map.has(ev["location"]):
			continue
		var day := int(ev["window"]["earliest"])
		days[day] = true
		for h: Dictionary in ev.get("hooks", []):
			for d in range(int(h["days"][0]), int(h["days"][1]) + 1):
				hooked[d] = true
	assert_eq(days.size(), 16)
	for day: int in days:
		assert_true(hooked.has(day), "day %d has a hook" % day)


func test_washing_up_on_the_first_staff_day_changes_it() -> void:
	var gs := GameState.from_json(_base_json)
	ToyCanon.sleep_through(gs, _db, 102)
	assert_eq(gs.clock.day(), 103)
	gs.player.place("inn_interior", Vector2i(22, 2))
	Commands.settle(gs, _db)
	var r := Commands.interact(gs, _db, "wash_basin", "wash_dishes")
	assert_eq(r["error"], "")
	ToyCanon.sleep_through(gs, _db, 103)
	var ev := _entry(gs, "b5.z_erins_new_staff_start_work")
	assert_eq(ev["outcome"], Director.CHANGED)
	assert_eq(ev["hook"], "player_helped_train_the_new_staff")
	assert_true(gs.flags.has("wandering_inn.earther_trained_the_new_staff"))
	assert_true(gs.flags.has("drassi.works_at_the_inn"), "the canon effects still happen")


func test_no_kill_never_runs_an_alt_event() -> void:
	var gs := _run("")
	assert_eq(_lost(gs), [] as Array[String])
	assert_eq(gs.world.drift, 0.0)
	for id: String in ALTS:
		assert_true(_db.canon.alt_only.has("b5." + id), id)
		assert_eq(gs.world.status("b5." + id), WorldState.PENDING, id)


func test_ryoka_dies_and_erin_pays_for_the_inn() -> void:
	var gs := _run("ryoka_griffin")
	_check_ceiling(gs, "ryoka_griffin")
	_mutated(gs, "t_klbkch_takes_the_building_contract", "t_erin_pays_the_antinium_to_build_the_inn", 102)
	assert_eq(int(_entry(gs, "b5.v_bird_takes_the_watch_and_pawn_goes_to_war")["day"]), 102, "the hand-off runs the same day")
	_mutated(gs, "zzzzzj_the_necromancer_turns_to_the_goblins", "zzzzzj_the_necromancer_calls_his_servants_home", 114)
	assert_true(gs.flags.has("azkerash.turns_to_the_goblins"))
	_happened(gs, ["v_bird_takes_the_watch_and_pawn_goes_to_war", "zze_the_workers_start_building_the_inn",
		"zzzzk_the_workers_finish_the_third_floor_and_tower", "zzzl_regrika_blackpaw_comes_to_liscor"])
	_happened(gs, REGRIKAS_END)
	_happened(gs, RIVERFARM)
	_not_happened(gs, RYOKAS_RUN)
	_not_happened(gs, ["m_ryoka_comes_home_to_liscor", "zzzzd_venitra_shows_ryoka_her_face",
		"zzzzs_regrika_brings_madness_to_celum", "zzzzv_ivolethe_breaks_faerie_law_to_save_ryoka"])


func test_erin_dies_and_the_gnolls_burn_brunkr_alone() -> void:
	var gs := _run("erin_solstice")
	_check_ceiling(gs, "erin_solstice")
	_mutated(gs, "zzzzz_liscor_burns_brunkr_and_ulrien", "zzzzz_the_gnolls_burn_brunkr", 113)
	assert_true(gs.world.is_alive(_db.canon, "ulrien"), "no one exposed Regrika at the inn")
	_happened(gs, RYOKAS_RUN.filter(func(id: String) -> bool: return id != "zzzzzb_erin_sends_ryoka_away"))
	_happened(gs, ["zzzzj_venitra_murders_brunkr", "zzzzx_teriarch_revives_ryoka_and_burns_venitra",
		"zzzzzj_the_necromancer_turns_to_the_goblins", "zzzzzi_lyonette_and_mrsha_shelter_in_celum"])
	_happened(gs, RIVERFARM)
	_not_happened(gs, ["t_klbkch_takes_the_building_contract", "zzzzp_erin_feeds_regrika_a_steak_of_bone",
		"zzzzq_regrika_kills_ulrien_in_the_inn", "zzzzza_erin_reaches_level_32"])


func test_laken_dies_and_riverfarm_goes_on_without_him() -> void:
	var gs := _run("laken_godart")
	_check_ceiling(gs, "laken_godart")
	_mutated(gs, "zzo_a_mossbear_raids_riverfarm", "zzo_durene_drives_off_a_mossbear", 104)
	_mutated(gs, "zzp_laken_takes_in_windrest", "zzp_riverfarm_takes_in_windrest", 105)
	assert_true(gs.flags.has("windrest.burned_by_goblins"))
	_happened(gs, RYOKAS_RUN)
	_happened(gs, REGRIKAS_END)
	_not_happened(gs, RIVERFARM)
	assert_lt(gs.world.drift, 15.0)


func test_venitra_dies_and_imenet_comes_alone() -> void:
	var gs := _run("venitra")
	_check_ceiling(gs, "venitra")
	_mutated(gs, "zzzl_regrika_blackpaw_comes_to_liscor", "zzzl_imenet_comes_to_liscor_alone", 110)
	_mutated(gs, "zzzzd_venitra_shows_ryoka_her_face", "zzzzd_imenet_seizes_ryoka_in_an_alley", 111)
	var word := _entry(gs, "b5.zzzzh_the_necromancer_lays_word_of_death_on_ryoka")
	assert_eq(word["outcome"], Director.SUBSTITUTED)
	assert_true((word["roles"] as Dictionary).values().has("ijvani"), "the Necromancer speaks through Ijvani")
	_mutated(gs, "zzzzx_teriarch_revives_ryoka_and_burns_venitra", "zzzzx_teriarch_revives_ryoka_and_flies_her_home", 112)
	assert_true(gs.world.is_alive(_db.canon, "ryoka_griffin"), "Teriarch revives her")
	assert_true(gs.world.is_alive(_db.canon, "brunkr"), "no Venitra, no murder")
	_happened(gs, RYOKAS_RUN)
	_happened(gs, ["zzzzi_erin_beats_imenet_at_chess", "zzzzg_a_standoff_over_ryoka_at_the_feast",
		"zzzzzj_the_necromancer_turns_to_the_goblins", "zzzzf_brunkrs_feast_at_the_inn"])
	_not_happened(gs, REGRIKAS_END)
	_not_happened(gs, ["zzzzs_regrika_brings_madness_to_celum", "zzzzu_relc_holds_regrika_on_the_road",
		"zzzzv_ivolethe_breaks_faerie_law_to_save_ryoka", "zzzzze_teriarch_says_ivolethe_is_banished"])


func test_lyonette_dies_and_the_inn_scenes_go_on() -> void:
	var gs := _run("lyonette")
	_check_ceiling(gs, "lyonette")
	_happened(gs, ["za_pawn_comes_back_from_the_front", "zd_erin_fires_safry_and_maran",
		"zg_pawns_soldiers_eat_bee_soup_at_the_inn", "zzc_erin_throws_out_the_celum_innkeepers"])
	_happened(gs, RYOKAS_RUN)
	_happened(gs, REGRIKAS_END)
	_not_happened(gs, ["zzzg_brunkr_trains_lyonette_and_she_knights_him", "zzzy_brunkr_wakes_a_knight",
		"zzzzzi_lyonette_and_mrsha_shelter_in_celum"])


func test_ken_dies_and_luan_and_aiko_go_to_the_last_light() -> void:
	var gs := _run("kenjiro_murata", _baleros_json)
	_check_ceiling(gs, "kenjiro_murata")
	_mutated(gs, "zt_ken_luan_and_aiko_go_to_the_last_light", "zt_luan_and_aiko_go_to_the_last_light", 84)
	assert_eq(int(_entry(gs, "b5.zu_the_red_cross_company_is_founded")["day"]), 85, "the hand-off keeps its day")
	_happened(gs, LAST_LIGHT)
	_not_happened(gs, ["zp_ken_becomes_the_companys_negotiator", "zw_the_red_cross_medics_carry_the_wounded"])


func test_quallet_dies_and_etretta_leads_the_fist_to_the_valley() -> void:
	var gs := _run("quallet_marshhand", _baleros_json)
	_check_ceiling(gs, "quallet_marshhand")
	var march := _entry(gs, "b5.zo_gravetenders_fist_reaches_the_valley_battle")
	assert_eq(march["outcome"], Director.SUBSTITUTED)
	assert_eq(march["roles"]["captain"], "etretta_fulvrie")
	_happened(gs, LAST_LIGHT)
	_happened(gs, ["zp_ken_becomes_the_companys_negotiator", "zt_ken_luan_and_aiko_go_to_the_last_light"])
