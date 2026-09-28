extends GutTest
## Real Book 5 canon (game/data/canon/book5). With no player input, every
## b5. event in days FIRST_DAY–LAST_DAY happens as written: no drift. The
## game is slept to day FIRST_DAY - 1 once (before_all); each test starts
## from a copy of that save.

## First day with Book 5 canon (4.06 M: Magnolia's gathering, a guess).
const FIRST_DAY := 97
## Last day with extracted Book 5 canon (M13.2: 4.12, the building contract, day 102).
const LAST_DAY := 102

var _db: DataDb
var _base_json := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	var gs := GameState.new_game(1, _db)
	ToyCanon.sleep_through(gs, _db, FIRST_DAY - 1)
	_base_json = gs.to_json()


func _fresh() -> GameState:
	return GameState.from_json(_base_json)


static func _b5(id: String) -> bool:
	return id.begins_with("b5.")


func _b5_events() -> Array[String]:
	var out: Array[String] = []
	for id: String in _db.canon.events:
		var ev: Dictionary = _db.canon.events[id]
		if _b5(id) and int(ev["window"]["earliest"]) <= LAST_DAY and not _db.canon.alt_only.has(id):
			out.append(id)
	return out


func _sleep_to_last_day(gs: GameState) -> void:
	while gs.world.last_day < LAST_DAY:
		Commands.sleep(gs, _db, Rest.ANYWHERE)


func test_book5_loads() -> void:
	assert_eq(_db.canon.errors, [] as Array[String])
	assert_eq(_db.errors, [] as Array[String])
	assert_gte(_b5_events().size(), 22)
	for npc: String in ["tyrion_veltras", "patricia_melissar", "eliasor", "bethal", "thomast", "pryde", "wuvren", "zanthia",
			"venith_crusland", "maresar", "calac_crusland", "tengrip", "uleth", "siyal",
			"anith", "insill", "pekona", "dasha", "larr"]:
		assert_true(_db.canon.npcs.has(npc), npc)
	for loc: String in ["melissar_estate", "germina", "hellios", "house_of_minos", "manimar", "rast"]:
		assert_true(_db.canon.locations.has(loc), loc)
	assert_eq(_db.canon.locations["melissar_estate"]["parent"], "north_izril")


func test_book5_runs_as_canon() -> void:
	var gs := _fresh()
	assert_eq(gs.clock.day(), FIRST_DAY)
	_sleep_to_last_day(gs)
	var expected := _b5_events()
	for id: String in expected:
		assert_eq(gs.world.status(id), Director.DONE, id)
	var b5_history := gs.world.history.filter(func(h: Dictionary) -> bool: return _b5(h["event"]))
	assert_eq(b5_history.size(), expected.size(), "one history entry per event")
	assert_eq(gs.world.drift, 0.0)
	var rumor_events := expected.filter(func(id: String) -> bool:
			return int(_db.canon.events[id]["tier"]) == 1 and _db.canon.events[id].has("rumor"))
	rumor_events.sort()
	var rumors := gs.world.news.filter(func(n: Dictionary) -> bool: return n["kind"] == Director.RUMOR and _b5(n["event"])) \
			.map(func(n: Dictionary) -> String: return n["event"])
	rumors.sort()
	assert_eq(rumors, rumor_events, "a rumor for each tier 1 event")
	# M13.1: Magnolia's gathering, Xrn's plan, Lyonette's levels, Bird's birds, the soups, Ryoka near Celum.
	for f: String in ["izril_nobles.back_minos_against_flos", "izril_nobles.leave_goblin_lord_to_drakes",
			"germina.quarass_reported_dead", "patricia_melissar.murdered_by_an_assassin",
			"tyrion_veltras.saved_magnolia_from_a_dagger", "eliasor.heads_house_melissar", "magnolia.reforms_her_entourage",
			"xrn.plans_rhir_expedition", "klbkch.joins_xrns_plan", "lyonette.class_beast_tamer", "apista.pupating",
			"bird.hunts_birds_for_erin", "erin.sells_magic_soups", "liscor.adventurers_order_erins_soups",
			"izril.winter",
			# M13.2: Toren below, Vuliel Drae, Ryoka home, the Horns' gear, the talk in Celum, the contract, the job offer.
			"toren.disguised_as_a_masked_swordswoman", "liscor_dungeon.new_section_found", "ryoka.home_at_the_wandering_inn",
			"krshia.clan_holds_the_rihal_tome", "erin.hit_ilvriss_with_a_pan", "zel.knows_ryoka_did_not_kill_periss",
			"horns_of_hammerad.have_hedaults_gear", "horns_of_hammerad.lodge_in_the_inn_basement", "erin.and_ryoka_talked_it_out",
			"venitra.hunts_ryoka_near_liscor", "wandering_inn.door_range_known", "wandering_inn.expansion_planned",
			"ryoka.pays_for_the_inn_expansion", "erin.offered_safry_and_maran_jobs", "bird.accepted_the_inn_guard_job",
			"pawn.on_combat_duty"]:
		assert_true(gs.flags.has(f), f)
	# Ryoka is home: the road flags and the spellbook debt are gone. The build has not started (4.18).
	for f: String in ["erin.waits_for_ryoka", "ryoka.near_celum", "ryoka.heading_home_to_liscor", "ryoka.has_rihal_spellbook",
			"ryoka.holds_krshias_spellbook_debt", "toren.leads_undead", "wandering_inn.expansion_begun"]:
		assert_false(gs.flags.has(f), f)
	for f: String in ["wandering_inn.earther_heard_lyonettes_levels", "wandering_inn.earther_talked_birds_with_bird",
			"liscor.earther_helped_price_erins_soups", "liscor.earther_stood_with_ryoka_against_ilvriss",
			"wandering_inn.earther_toasted_the_horns", "wandering_inn.earther_weighed_in_on_the_building"]:
		assert_false(gs.flags.has(f), f)
	assert_false(gs.world.is_alive(_db.canon, "patricia_melissar"), "murdered at the gathering (4.06 M)")
	for npc: String in ["magnolia_reinhart", "tyrion_veltras", "eliasor", "xrn", "klbkch", "bird", "lyonette", "ryoka_griffin",
			"ilvriss", "toren", "anith", "pawn"]:
		assert_true(gs.world.is_alive(_db.canon, npc), npc + " lives")


func test_flos_chapters_are_history_only() -> void:
	# 4.00 K – 4.05 K and the Trey half of 4.06 put no events on the calendar (ADR 0020).
	for id: String in _db.canon.events:
		var ref: String = _db.canon.events[id]["canon_ref"]["chapter"]
		assert_false(ref in ["4.00K", "4.01K", "4.02K", "4.03K", "4.04K", "4.05K"], id)
	for npc: String in ["venith_crusland", "maresar", "calac_crusland", "tengrip", "uleth", "siyal"]:
		assert_has(_db.canon.npcs[npc]["tags"], "history_only", npc)
	for id: String in _db.canon.events:
		assert_false(JSON.stringify(_db.canon.events[id]["roles"]).contains("venith_crusland"), id)


func test_without_magnolia_there_is_no_gathering_or_murder() -> void:
	var gs := _fresh()
	assert_eq(Commands.kill_npc(gs, _db, "magnolia_reinhart"), "")
	_sleep_to_last_day(gs)
	assert_eq(gs.world.status("b5.a_northern_nobles_gather_over_flos"), Director.CANCELLED)
	assert_eq(gs.world.status("b5.b_patricia_melissar_murdered_at_the_gathering"), Director.CANCELLED)
	assert_true(gs.world.is_alive(_db.canon, "patricia_melissar"), "no gathering, no murder")
	assert_false(gs.flags.has("eliasor.heads_house_melissar"))
	assert_true(Director.happened(gs.world.status("b5.g_erin_sells_soup_samples_at_the_guild")), "Liscor goes on")


func test_without_bird_erin_still_sells_her_soups() -> void:
	var gs := _fresh()
	assert_eq(Commands.kill_npc(gs, _db, "bird"), "")
	_sleep_to_last_day(gs)
	assert_eq(gs.world.status("b5.f_bird_brings_erin_his_birds"), Director.CANCELLED)
	assert_false(gs.flags.has("bird.hunts_birds_for_erin"))
	assert_true(Director.happened(gs.world.status("b5.g_erin_sells_soup_samples_at_the_guild")))
	assert_true(Director.happened(gs.world.status("b5.e_lyonette_levels_and_apista_pupates")))

func test_without_ilvriss_ryoka_still_comes_home() -> void:
	var gs := _fresh()
	assert_eq(Commands.kill_npc(gs, _db, "ilvriss"), "")
	_sleep_to_last_day(gs)
	assert_eq(gs.world.status("b5.n_ilvriss_confronts_ryoka_in_the_street"), Director.CANCELLED)
	assert_false(gs.flags.has("erin.hit_ilvriss_with_a_pan"))
	for id: String in ["b5.m_ryoka_comes_home_to_liscor", "b5.p_ryoka_hands_the_horns_their_gear",
			"b5.t_klbkch_takes_the_building_contract"]:
		assert_true(Director.happened(gs.world.status(id)), id)


func test_without_ryoka_there_is_no_homecoming_and_no_contract() -> void:
	var gs := _fresh()
	assert_eq(Commands.kill_npc(gs, _db, "ryoka_griffin"), "")
	_sleep_to_last_day(gs)
	for id: String in ["b5.m_ryoka_comes_home_to_liscor", "b5.n_ilvriss_confronts_ryoka_in_the_street",
			"b5.p_ryoka_hands_the_horns_their_gear", "b5.q_erin_and_ryoka_talk_in_celum",
			"b5.t_klbkch_takes_the_building_contract", "b5.v_bird_takes_the_watch_and_pawn_goes_to_war"]:
		assert_eq(gs.world.status(id), Director.CANCELLED, id)
	assert_false(gs.flags.has("wandering_inn.expansion_planned"), "nobody pays for the build")
	assert_true(gs.flags.has("ryoka.has_rihal_spellbook"), "the tome never reaches Krshia")
	for id: String in ["b5.k_vuliel_drae_find_the_new_section", "b5.r_venitra_warns_the_goblin_lord",
			"b5.u_erin_offers_safry_and_maran_jobs"]:
		assert_true(Director.happened(gs.world.status(id)), id + " goes on")
