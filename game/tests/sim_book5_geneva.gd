extends GutTest
## M13.4: Geneva in Baleros (1.02 D – 1.06 D), off-map, placeholder days 77–90.
## The game is slept to day 76 once (Geneva's 1.01 D is done); each test starts
## from a copy of that save.

const START_DAY := 76
const LAST_DAY := 90

var _db: DataDb
var _base_json := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	var gs := GameState.new_game(1, _db)
	ToyCanon.sleep_through(gs, _db, START_DAY)
	_base_json = gs.to_json()


func _fresh() -> GameState:
	return GameState.from_json(_base_json)


func _sleep_to_last_day(gs: GameState) -> void:
	while gs.world.last_day < LAST_DAY:
		Commands.sleep(gs, _db, Rest.ANYWHERE)


func _geneva_events() -> Array[String]:
	var out: Array[String] = []
	for id: String in _db.canon.events:
		var ch: String = _db.canon.events[id]["canon_ref"]["chapter"]
		if id.begins_with("b5.") and ch in ["1.02D", "1.03D", "1.04D", "1.05D", "1.06D"]:
			out.append(id)
	return out


func test_the_arc_is_off_map_and_before_day_91() -> void:
	var ids := _geneva_events()
	assert_eq(ids.size(), 14)
	for id: String in ids:
		var ev: Dictionary = _db.canon.events[id]
		assert_eq(ev["location"], "baleros", id)
		assert_false(ev.has("stage"), id)
		assert_between(int(ev["window"]["earliest"]), START_DAY + 1, LAST_DAY, id)
	assert_true(_db.canon.events["b5.zza_the_united_nations_company_is_founded"].has("rumor"))


func test_the_arc_runs_as_canon() -> void:
	var gs := _fresh()
	assert_true(gs.flags.has("geneva.called_the_last_light"), "1.01 D is done")
	_sleep_to_last_day(gs)
	for id: String in _geneva_events():
		assert_eq(gs.world.status(id), Director.DONE, id)
	for f: String in ["earthers.in_gravetenders_fist", "gravetenders_fist.clears_the_valley_battlefield",
			"geneva.saved_luan", "calectus.guards_geneva",
			"earthers.americans_executed_for_desertion", "kenjiro_murata.with_geneva", "daly.stays_with_gravetenders_fist",
			"red_cross_company.founded", "geneva.saved_a_war_walker", "kenjiro_murata.red_cross_medic",
			"red_cross_company.camp_burned", "quexa.lost_a_leg_and_her_tail", "geneva.led_everyone_off_the_battlefield",
			"earthers.know_okasha_lives_in_geneva", "united_nations_company.founded", "razorshard_armor.ruined"]:
		assert_true(gs.flags.has(f), f)
	assert_false(gs.flags.has("luan_khumalo.has_an_arrowhead_inside"), "Geneva took it out")
	assert_false(gs.flags.has("kenjiro_murata.speaks_for_gravetenders_fist"), "Ken left the company")
	for npc: String in ["johanas", "ulvial", "etretta_fulvrie"]:
		assert_false(gs.world.is_alive(_db.canon, npc), npc + " dies")
	for npc: String in ["geneva_scala", "okasha", "kenjiro_murata", "luan_khumalo", "aiko_nonomura", "quallet_marshhand"]:
		assert_true(gs.world.is_alive(_db.canon, npc), npc + " lives")
	var rumors := gs.world.news.filter(func(n: Dictionary) -> bool:
			return n["kind"] == Director.RUMOR and n["event"] == "b5.zza_the_united_nations_company_is_founded")
	assert_eq(rumors.size(), 1, "Liscor hears of the United Nations")


func test_without_geneva_there_is_no_red_cross() -> void:
	var gs := _fresh()
	assert_eq(Commands.kill_npc(gs, _db, "geneva_scala"), "")
	_sleep_to_last_day(gs)
	for id: String in ["b5.zr_geneva_cuts_the_arrowhead_out_of_luan", "b5.zt_ken_luan_and_aiko_go_to_the_last_light",
			"b5.zu_the_red_cross_company_is_founded", "b5.zv_geneva_saves_a_war_walker",
			"b5.zx_zalthia_burns_the_red_cross_camp", "b5.zz_okasha_restarts_genevas_heart_and_she_leads_them_out",
			"b5.zza_the_united_nations_company_is_founded"]:
		assert_eq(gs.world.status(id), Director.CANCELLED, id)
	assert_true(gs.flags.has("luan_khumalo.has_an_arrowhead_inside"), "no one takes it out")
	assert_false(gs.flags.has("united_nations_company.founded"))
	for id: String in ["b5.zp_ken_becomes_the_companys_negotiator", "b5.zs_dullahans_behead_the_deserting_americans",
			"b5.zy_the_valley_battle_breaks_its_lines"]:
		assert_true(Director.happened(gs.world.status(id)), id + " goes on")


func test_without_ken_geneva_still_saves_luan_but_founds_nothing() -> void:
	var gs := _fresh()
	assert_eq(Commands.kill_npc(gs, _db, "kenjiro_murata"), "")
	_sleep_to_last_day(gs)
	for id: String in ["b5.zp_ken_becomes_the_companys_negotiator", "b5.zt_ken_luan_and_aiko_go_to_the_last_light",
			"b5.zu_the_red_cross_company_is_founded", "b5.zw_the_red_cross_medics_carry_the_wounded",
			"b5.zx_zalthia_burns_the_red_cross_camp", "b5.zza_the_united_nations_company_is_founded"]:
		assert_eq(gs.world.status(id), Director.CANCELLED, id)
	for id: String in ["b5.zr_geneva_cuts_the_arrowhead_out_of_luan", "b5.zv_geneva_saves_a_war_walker",
			"b5.zs_dullahans_behead_the_deserting_americans"]:
		assert_true(Director.happened(gs.world.status(id)), id + " goes on")


func test_without_luan_the_three_still_reach_geneva() -> void:
	var gs := _fresh()
	assert_eq(Commands.kill_npc(gs, _db, "luan_khumalo"), "")
	_sleep_to_last_day(gs)
	assert_eq(gs.world.status("b5.zq_centaurs_shoot_luan_with_an_evercut_arrow"), Director.CANCELLED)
	assert_eq(gs.world.status("b5.zr_geneva_cuts_the_arrowhead_out_of_luan"), Director.CANCELLED)
	for id: String in ["b5.zt_ken_luan_and_aiko_go_to_the_last_light", "b5.zu_the_red_cross_company_is_founded",
			"b5.zza_the_united_nations_company_is_founded"]:
		assert_true(Director.happened(gs.world.status(id)), id + " goes on")
