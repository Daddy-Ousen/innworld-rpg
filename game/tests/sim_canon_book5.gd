extends GutTest
## Real Book 5 canon (game/data/canon/book5). With no player input, every
## b5. event in days FIRST_DAY–LAST_DAY happens as written: no drift. The
## game is slept to day FIRST_DAY - 1 once (before_all); each test starts
## from a copy of that save.

## First day with Book 5 canon (4.06 M: Magnolia's gathering, a guess).
const FIRST_DAY := 97
## Last day with Book 5 canon (4.23 E, Riverfarm buries its dead: Laken's Day 70 = day 115,
## ADR 0028; Liscor's last day is 114).
const LAST_DAY := 115

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
			"anith", "insill", "pekona", "dasha", "larr",
			"ishkr", "yellow_splatters", "thrissiam_blackwing", "garusa_weatherfur", "osthia_blackwing",
			"wailant_strongheart", "viceria_strongheart",
			"quallet_marshhand", "kenjiro_murata", "aiko_nonomura", "luan_khumalo", "daly", "paige", "johanas", "quexa",
			"etretta_fulvrie", "calectus", "xalandrass", "exara", "ulvial", "zalthia_werskiv", "grishka",
			"timbor_parithad", "ulia_ovena", "wiskeria", "beniar", "sacra", "helm", "jelov", "tessia", "rehanna",
			"jeighya", "fabiel", "rie",
			"welsca_crimsonscale", "foliana", "peclir_im", "wil", "yerranola", "wullst", "regis_reinhart",
			"bea", "kerash", "oom"]:
		assert_true(_db.canon.npcs.has(npc), npc)
	assert_false(_db.canon.npcs.has("imenet"), "M13.7: 'Imenet' is Ijvani (4.28)")
	for loc: String in ["melissar_estate", "germina", "hellios", "house_of_minos", "manimar", "rast", "strongheart_farm", "windrest",
			"elvallian", "leadenfurt", "reinhart_estate", "esthelm_bear_cave"]:
		assert_true(_db.canon.locations.has(loc), loc)
	assert_eq(_db.canon.locations["melissar_estate"]["parent"], "north_izril")
	assert_eq(_db.canon.locations["strongheart_farm"]["parent"], "north_izril")


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
			# M13.2: Toren below, Vuliel Drae, Ryoka home, the Horns' gear, the talk in Celum, the contract, the job offer.
			"toren.disguised_as_a_masked_swordswoman", "liscor_dungeon.new_section_found",
			"krshia.clan_holds_the_rihal_tome", "erin.hit_ilvriss_with_a_pan", "zel.knows_ryoka_did_not_kill_periss",
			"horns_of_hammerad.have_hedaults_gear", "horns_of_hammerad.lodge_in_the_inn_basement", "erin.and_ryoka_talked_it_out",
			"venitra.hunts_ryoka_near_liscor", "wandering_inn.door_range_known", "wandering_inn.expansion_planned",
			"ryoka.pays_for_the_inn_expansion", "erin.offered_safry_and_maran_jobs", "bird.accepted_the_inn_guard_job",
			"pawn.on_combat_duty",
			# M13.3: the Hive's battle, the new staff, the firing, Pawn's faith, the Drake armies, the farm.
			"liscor.old_drakes_cheer_pawns_soldiers", "yellow_splatters.used_a_skill", "liscor_hive.losing_more_than_it_breeds",
			"pawn.lost_25_soldiers", "liscor_hive.soldier_memorial_wall", "belgrade.maimed_and_healed_by_xrn",
			"drassi.works_at_the_inn", "ishkr.works_at_the_inn", "pawn.has_erins_censer", "ryoka.taught_pawn_about_faiths",
			"erin.scolded_safry_and_maran_in_public", "safry.fired_from_the_inn", "maran.fired_from_the_inn",
			"lyonette.in_charge_of_the_staff", "lyonette.confronted_erin_about_toren", "ryoka.knows_lyonette_is_a_princess",
			"pawn.knows_lyonette_is_a_princess", "yellow_splatters.promoted_to_sergeant", "pawn.leads_soldiers_in_prayer",
			"wandering_inn.fed_pawns_soldiers", "tersk.learning_to_pray",
			"goblin_lord.ambushed_the_drake_armies", "drake_armies.destroyed_by_the_goblin_lord",
			"thrissiam_blackwing.risen_as_undead", "osthia_blackwing.captured_by_the_goblin_lord",
			"goblin_lord.resents_the_necromancer",
			"ryoka.teaches_garia_to_fight", "ryoka.saw_the_wind", "ivolethe.teaches_ryoka_faerie_magic",
			# M13.5: home from the farm, the innkeepers, the chess, the build, the bow, the undead; Laken's Riverfarm.
			"ryoka.back_from_the_strongheart_farm", "erin.threw_out_the_celum_innkeepers",
			"erin.played_the_unseen_opponent_all_night", "wandering_inn.expansion_begun", "bird.has_a_yew_bow",
			"erin.stocked_up_on_potions", "erin.asked_brunkr_to_train_lyonette",
			"liscor_dungeon.gold_teams_charted_the_trap_rooms", "liscor_dungeon.undead_climbed_out_of_the_rift",
			"laken.back_in_riverfarm", "prost.steward", "laken.took_in_windrest", "riverfarm.has_a_militia",
			"laken.half_tamed_the_mossbear", "beniar.poisoned_by_a_goblin_arrow", "sacra.unmasked_as_magnolias_spy",
			"wiskeria.leads_the_trackers", "laken.claimed_land_with_markers", "riverfarm.broke_the_goblin_attack",
			"wiskeria.lakens_general", "invrisil_nobles.write_to_laken",
			# M13.6: the slime, the Razorbeak, Ilvriss' agents, the knighting, the news, Regrika, the Council, Niers,
			# Magnolia's army, Royal Tax, the Pisces ban, the Creler nest, Venitra unmasked.
			"erin.keeps_a_slime_core", "mrsha.snatched_at_by_a_razorbeak", "erin.made_up_with_ryoka",
			"free_queen.experiments_to_make_a_queen", "relc.freed_ryoka_from_the_barracks", "lyonette.swore_brunkr_as_a_knight",
			"wandering_inn.healing_slime_loose_near_the_inn", "erin.agreed_to_a_pallass_door_anchor",
			"horns_of_hammerad.take_contracts_near_esthelm", "liscor.knows_the_drake_armies_fell",
			"drake_cities.warned_of_the_goblin_lord",
			"forgotten_wing.fundraiser_held", "niers.read_olesms_newsletter", "niers.plays_go", "niers.shook_off_his_boredom",
			"liscor.prepares_for_a_siege", "olesm.named_ryoka_to_regrika", "antinium.visitors_prepare_to_go_home",
			"goblin_lord.ordered_north_past_liscor", "leadenfurt.sends_magnolia_cavalry", "magnolia.has_reinhart_knights_and_golems",
			"lyonette.has_royal_tax", "brunkr.class_knight", "brunkr.arm_healed", "pisces.banned_from_raising_people_near_liscor",
			"ceria.knows_ice_wall", "termin.fled_north_from_the_goblin_lord", "horns_of_hammerad.burned_a_creler_nest",
			"venitra.seized_ryoka_in_liscor", "ryoka.knows_regrika_is_venitra",
			# M13.7: Imenet unmasked, the feast, the Word of Death, the chess, the murder, the new floors, the body, the
			# truth stones, the letter, the bone steak, the fight, Liscor burning, Celum's madness, Relc, Ivolethe, the
			# death and the revival, the accord, the pyres, Level 32, the truth told, the drums, Ryoka north, Celum.
			"ryoka.knows_imenet_is_ijvani", "wandering_inn.held_brunkrs_feast", "erin.baked_a_knight_cake",
			"xrn.met_ryoka", "azkerash.forbids_harming_ryoka", "azkerash.lost_at_chess_to_erin", "brunkr.murdered_by_venitra",
			"wandering_inn.third_floor_built", "bird.has_his_watchtower", "liscor.gnolls_mourn_brunkr",
			"regrika.passed_a_truth_stone", "ivolethe.foresaw_ryokas_death", "ryoka.left_a_goodbye_letter",
			"azkerash.ordered_ryokas_head", "erin.exposed_regrika_as_a_fake", "griffon_hunt.lost_ulrien",
			"venitra.cracked_by_halracs_arrows", "erin.spared_on_the_necromancers_order", "liscor.homes_burned_by_imenet",
			"ijvani.broken_and_pulled_home", "celum.mists_of_madness", "pisces.cracked_venitra_with_bone_fracture",
			"relc.fought_regrika_on_the_high_pass_road", "ivolethe.broke_faerie_law", "ryoka.killed_by_word_of_death",
			"ryoka.revived_by_teriarch", "venitra.burned_by_teriarch", "azkerash.accord_with_teriarch_over_ryoka",
			"ryoka.under_teriarchs_protection", "wandering_inn.held_the_pyres_for_brunkr_and_ulrien",
			"erin.inn_reinforced_structure", "erin.asked_ryoka_to_stay_away", "griffon_hunt.left_the_wandering_inn",
			"zel.knows_the_necromancer_lives", "ilvriss.knows_the_necromancer_killed_periss",
			"ivolethe.banished_by_the_faerie_king", "liscor.hears_the_goblin_lords_drums", "ryoka.ran_north_alone",
			"izril.spring", "azkerash.turns_to_the_goblins",
			"kerash.holds_the_necromancers_authority"]:
		assert_true(gs.flags.has(f), f)
	# Safry and Maran are gone; Pawn's Soldiers went back to the front; the armies no longer stand; the trip is made.
	for f: String in ["safry.works_at_the_inn", "maran.works_at_the_inn", "pawn.soldiers_back_on_patrol",
			"drake_armies.joined_below_the_high_pass", "ryoka.plans_to_visit_garias_farm", "ivolethe.will_teach_ryoka_at_the_farm",
			"ryoka.away_at_the_strongheart_farm", "mrsha.away_at_the_strongheart_farm", "venitra.turns_for_liscor",
			"brunkr.hand_infected",
			# M13.7: the disguises are over, the curse is lifted, the Chosen stay home, Ryoka has left, winter is over.
			"venitra.disguised_as_regrika_blackpaw", "ijvani.disguised_as_imenet", "liscor.hosts_regrika_blackpaw",
			"ryoka.under_word_of_death", "ivolethe.melting_as_winter_ends", "ivolethe.disguised_as_ryoka",
			"azkerash.readied_his_chosen_for_liscor", "ryoka.home_at_the_wandering_inn", "izril.winter",
			"frost_fairies.abroad", "winter.thaw_is_coming",
			# M18.3: 4.33 (Book 6, day 115) brings Lyonette and Mrsha home, so the sim's last day no longer has these.
			"lyonette.sheltering_in_celum", "mrsha.sheltering_in_celum"]:
		assert_false(gs.flags.has(f), f)
	for npc: String in ["garusa_weatherfur", "thrissiam_blackwing"]:
		assert_false(gs.world.is_alive(_db.canon, npc), npc + " dies below the High Pass (4.16)")
	assert_true(gs.world.is_alive(_db.canon, "osthia_blackwing"), "Osthia is taken alive")
	# Ryoka is home: the road flags and the spellbook debt are gone.
	for f: String in ["erin.waits_for_ryoka", "ryoka.near_celum", "ryoka.heading_home_to_liscor", "ryoka.has_rihal_spellbook",
			"ryoka.holds_krshias_spellbook_debt", "toren.leads_undead"]:
		assert_false(gs.flags.has(f), f)
	for f: String in ["wandering_inn.earther_heard_lyonettes_levels", "wandering_inn.earther_talked_birds_with_bird",
			"liscor.earther_helped_price_erins_soups", "liscor.earther_stood_with_ryoka_against_ilvriss",
			"wandering_inn.earther_toasted_the_horns", "wandering_inn.earther_weighed_in_on_the_building",
			"wandering_inn.earther_sat_with_pawn", "wandering_inn.earther_served_the_soldiers_soup",
			"wandering_inn.earther_watched_the_chess_marathon", "wandering_inn.earther_watched_bird_learn_the_bow",
			"floodplains.earther_fought_the_rift_undead", "wandering_inn.earther_saved_mrsha_from_a_razorbeak",
			"wandering_inn.earther_watched_brunkr_train_lyonette", "wandering_inn.earther_heard_the_armies_fell",
			"esthelm.earther_fought_the_creler_nest"]:
		assert_false(gs.flags.has(f), f)
	assert_false(gs.world.is_alive(_db.canon, "patricia_melissar"), "murdered at the gathering (4.06 M)")
	assert_false(gs.world.is_alive(_db.canon, "fabiel"), "killed by Goblins (4.21 E)")
	for npc: String in ["magnolia_reinhart", "tyrion_veltras", "eliasor", "xrn", "klbkch", "bird", "lyonette", "ryoka_griffin",
			"ilvriss", "toren", "anith", "pawn",
			"laken_godart", "durene", "gamel", "wiskeria", "beniar", "sacra", "halrac", "venitra", "ijvani", "foliana", "wullst", "hawk",
			"teriarch", "azkerash", "ivolethe", "jelaqua", "revi", "relc"]:
		assert_true(gs.world.is_alive(_db.canon, npc), npc + " lives")
	assert_false(gs.world.is_alive(_db.canon, "brunkr"), "murdered by Venitra (4.28)")
	assert_false(gs.world.is_alive(_db.canon, "ulrien"), "killed at the inn (4.29)")
	var death := gs.world.history.filter(func(h: Dictionary) -> bool: return h["event"] == "b5.zzzzw_ryoka_names_the_necromancer_and_dies")
	assert_eq(death.size(), 1, "Ryoka dies of the Word of Death (4.30) and Teriarch brings her back (4.31)")


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


func test_without_ryoka_there_is_no_homecoming_and_erin_pays_for_the_build() -> void:
	var gs := _fresh()
	assert_eq(Commands.kill_npc(gs, _db, "ryoka_griffin"), "")
	_sleep_to_last_day(gs)
	for id: String in ["b5.m_ryoka_comes_home_to_liscor", "b5.n_ilvriss_confronts_ryoka_in_the_street",
			"b5.p_ryoka_hands_the_horns_their_gear", "b5.q_erin_and_ryoka_talk_in_celum"]:
		assert_eq(gs.world.status(id), Director.CANCELLED, id)
	# M23.4: Erin pays the Hive herself, so the build still starts (4.18).
	assert_eq(gs.world.status("b5.t_klbkch_takes_the_building_contract"), Director.MUTATED)
	assert_eq(gs.world.status("b5.t_erin_pays_the_antinium_to_build_the_inn"), Director.DONE)
	assert_true(gs.flags.has("wandering_inn.expansion_planned"))
	assert_false(gs.flags.has("ryoka.pays_for_the_inn_expansion"))
	for id: String in ["b5.v_bird_takes_the_watch_and_pawn_goes_to_war", "b5.zze_the_workers_start_building_the_inn"]:
		assert_true(Director.happened(gs.world.status(id)), id)
	assert_eq(gs.world.status("b5.zzb_ryoka_and_mrsha_come_home_from_the_farm"), Director.CANCELLED)
	assert_true(gs.flags.has("ryoka.has_rihal_spellbook"), "the tome never reaches Krshia")
	for id: String in ["b5.k_vuliel_drae_find_the_new_section", "b5.r_venitra_warns_the_goblin_lord",
			"b5.u_erin_offers_safry_and_maran_jobs",
			# M13.3: the staff and Pawn's story go on without her.
			"b5.z_erins_new_staff_start_work", "b5.za_pawn_comes_back_from_the_front", "b5.zd_erin_fires_safry_and_maran",
			"b5.zg_pawns_soldiers_eat_bee_soup_at_the_inn"]:
		assert_true(Director.happened(gs.world.status(id)), id + " goes on")
	for id: String in ["b5.ze_ryoka_learns_lyonette_is_a_princess", "b5.zl_ryoka_brings_mrsha_to_the_strongheart_farm",
			"b5.zm_ryoka_sees_the_wind"]:
		assert_eq(gs.world.status(id), Director.CANCELLED, id)
	assert_false(gs.flags.has("mrsha.away_at_the_strongheart_farm"), "Mrsha stays at the inn")


func test_without_pawn_the_hive_still_fights_and_the_staff_still_start() -> void:
	var gs := _fresh()
	assert_eq(Commands.kill_npc(gs, _db, "pawn"), "")
	_sleep_to_last_day(gs)
	for id: String in ["b5.w_old_drakes_cheer_pawns_painted_soldiers", "b5.y_the_hive_holds_the_dungeon_front",
			"b5.za_pawn_comes_back_from_the_front", "b5.zf_pawn_leads_his_soldiers_in_prayer",
			"b5.zg_pawns_soldiers_eat_bee_soup_at_the_inn"]:
		assert_eq(gs.world.status(id), Director.CANCELLED, id)
	assert_false(gs.flags.has("pawn.lost_25_soldiers"))
	assert_false(gs.flags.has("yellow_splatters.promoted_to_sergeant"), "no one to promote him")
	for id: String in ["b5.z_erins_new_staff_start_work", "b5.zd_erin_fires_safry_and_maran",
			"b5.zl_ryoka_brings_mrsha_to_the_strongheart_farm", "b5.zj_the_drake_armies_are_destroyed"]:
		assert_true(Director.happened(gs.world.status(id)), id + " goes on")


func test_without_garusa_the_armies_still_fall() -> void:
	var gs := _fresh()
	assert_eq(Commands.kill_npc(gs, _db, "garusa_weatherfur"), "")
	_sleep_to_last_day(gs)
	assert_true(Director.happened(gs.world.status("b5.zj_the_drake_armies_are_destroyed")))
	assert_false(gs.world.is_alive(_db.canon, "thrissiam_blackwing"))
	assert_true(gs.flags.has("osthia_blackwing.captured_by_the_goblin_lord"))


func test_without_wiskeria_riverfarm_still_holds() -> void:
	var gs := _fresh()
	assert_eq(Commands.kill_npc(gs, _db, "wiskeria"), "")
	_sleep_to_last_day(gs)
	assert_eq(gs.world.status("b5.zzz_wiskeria_becomes_lakens_general"), Director.CANCELLED)
	assert_false(gs.flags.has("wiskeria.lakens_general"))
	for id: String in ["b5.zzw_odveig_is_unmasked_as_sacra", "b5.zzy_riverfarm_breaks_the_goblin_attack",
			"b5.zzza_riverfarm_buries_its_dead"]:
		assert_true(Director.happened(gs.world.status(id)), id + " goes on")


func test_without_laken_there_is_no_unseen_empire_arc() -> void:
	var gs := _fresh()
	assert_eq(Commands.kill_npc(gs, _db, "laken_godart"), "")
	_sleep_to_last_day(gs)
	for id: String in ["b5.zzm_laken_comes_home_to_riverfarm", "b5.zzn_laken_makes_prost_his_steward",
			"b5.zzy_riverfarm_breaks_the_goblin_attack", "b5.zzza_riverfarm_buries_its_dead"]:
		assert_eq(gs.world.status(id), Director.CANCELLED, id)
	assert_true(gs.world.is_alive(_db.canon, "fabiel"), "no Riverfarm, no ambush")
	assert_true(Director.happened(gs.world.status("b5.zzl_undead_climb_out_of_the_rift")), "Liscor goes on")


func test_without_halrac_the_undead_still_come_and_bird_still_gets_his_bow() -> void:
	var gs := _fresh()
	assert_eq(Commands.kill_npc(gs, _db, "halrac"), "")
	_sleep_to_last_day(gs)
	for id: String in ["b5.zzf_erin_buys_bird_a_bow_and_halrac_teaches_him", "b5.zzk_the_gold_teams_chart_the_trap_rooms",
			"b5.zzl_undead_climb_out_of_the_rift"]:
		assert_true(Director.happened(gs.world.status(id)), id)
	assert_true(gs.flags.has("bird.has_a_yew_bow"))


func test_without_venitra_there_is_no_regrika_but_liscor_still_hears() -> void:
	var gs := _fresh()
	assert_eq(Commands.kill_npc(gs, _db, "venitra"), "")
	_sleep_to_last_day(gs)
	for id: String in ["b5.zzzl_regrika_blackpaw_comes_to_liscor", "b5.zzzs_regrika_asks_the_council_for_a_runner",
			"b5.zzzzd_venitra_shows_ryoka_her_face"]:
		assert_false(Director.happened(gs.world.status(id)), id)
	for id: String in ["b5.zzzk_hawk_brings_word_the_drake_armies_fell", "b5.zzzr_the_liscor_council_plans_for_a_siege",
			"b5.zzzzc_the_horns_burn_a_creler_nest"]:
		assert_true(Director.happened(gs.world.status(id)), id)
	assert_false(gs.flags.has("ryoka.knows_regrika_is_venitra"))
	# M13.7: no Regrika, no murders; the inn is still finished and winter still ends.
	# M23.4: Imenet comes alone, so the Word of Death still falls and Teriarch still revives Ryoka.
	for npc: String in ["brunkr", "ulrien", "ryoka_griffin"]:
		assert_true(gs.world.is_alive(_db.canon, npc), npc + " lives")
	for id: String in ["b5.zzzzj_venitra_murders_brunkr", "b5.zzzzq_regrika_kills_ulrien_in_the_inn"]:
		assert_false(Director.happened(gs.world.status(id)), id)
	assert_true(Director.happened(gs.world.status("b5.zzzzw_ryoka_names_the_necromancer_and_dies")))
	for id: String in ["b5.zzzzk_the_workers_finish_the_third_floor_and_tower", "b5.zzzzzh_winter_ends_and_the_faeries_fly_north"]:
		assert_true(Director.happened(gs.world.status(id)), id)


func test_without_brunkr_there_is_no_knight_but_lyonette_still_levels() -> void:
	var gs := _fresh()
	assert_eq(Commands.kill_npc(gs, _db, "brunkr"), "")
	_sleep_to_last_day(gs)
	for id: String in ["b5.zzzg_brunkr_trains_lyonette_and_she_knights_him", "b5.zzzy_brunkr_wakes_a_knight"]:
		assert_false(Director.happened(gs.world.status(id)), id)
	assert_true(Director.happened(gs.world.status("b5.zzzx_lyonette_levels_and_gains_royal_tax")))
	assert_false(gs.flags.has("brunkr.class_knight"))
	# M13.7: no feast, no murder, so Erin never traps Regrika and Ulrien lives; Ryoka still runs and comes back.
	for id: String in ["b5.zzzzf_brunkrs_feast_at_the_inn", "b5.zzzzj_venitra_murders_brunkr",
			"b5.zzzzp_erin_feeds_regrika_a_steak_of_bone", "b5.zzzzq_regrika_kills_ulrien_in_the_inn",
			"b5.zzzzz_liscor_burns_brunkr_and_ulrien"]:
		assert_false(Director.happened(gs.world.status(id)), id)
	assert_true(gs.world.is_alive(_db.canon, "ulrien"), "no trap, no fight")
	for id: String in ["b5.zzzzh_the_necromancer_lays_word_of_death_on_ryoka", "b5.zzzzx_teriarch_revives_ryoka_and_burns_venitra",
			"b5.zzzzzg_ryoka_runs_north"]:
		assert_true(Director.happened(gs.world.status(id)), id)
	assert_true(gs.world.is_alive(_db.canon, "ryoka_griffin"))


func test_without_hawk_the_news_still_comes() -> void:
	var gs := _fresh()
	assert_eq(Commands.kill_npc(gs, _db, "hawk"), "")
	_sleep_to_last_day(gs)
	for id: String in ["b5.zzzk_hawk_brings_word_the_drake_armies_fell", "b5.zzzm_warnings_go_out_to_the_cities",
			"b5.zzzi_door_anchors_and_a_stone_for_pallass"]:
		assert_true(Director.happened(gs.world.status(id)), id)


func test_without_yvlon_there_is_no_bear_request_and_no_nest() -> void:
	var gs := _fresh()
	assert_eq(Commands.kill_npc(gs, _db, "yvlon_byres"), "")
	_sleep_to_last_day(gs)
	for id: String in ["b5.zzzza_ceria_learns_ice_wall_and_yvlon_takes_a_request", "b5.zzzzc_the_horns_burn_a_creler_nest"]:
		assert_false(Director.happened(gs.world.status(id)), id)
	assert_true(Director.happened(gs.world.status("b5.zzzz_the_guild_bans_pisces_from_raising_the_dead")), "the ban still comes")


func test_without_ulrien_the_inn_still_fights_regrika() -> void:
	var gs := _fresh()
	assert_eq(Commands.kill_npc(gs, _db, "ulrien"), "")
	_sleep_to_last_day(gs)
	for id: String in ["b5.zzzzq_regrika_kills_ulrien_in_the_inn", "b5.zzzzr_imenet_fights_zel_and_ilvriss_in_the_streets",
			"b5.zzzzz_liscor_burns_brunkr_and_ulrien"]:
		assert_true(Director.happened(gs.world.status(id)), id)
	assert_eq(str(gs.world.events["b5.zzzzq_regrika_kills_ulrien_in_the_inn"]["roles"].get("leader", "")), "", "no leader role")


func test_without_teriarch_ryoka_never_dies_in_his_cave() -> void:
	var gs := _fresh()
	assert_eq(Commands.kill_npc(gs, _db, "teriarch"), "")
	_sleep_to_last_day(gs)
	for id: String in ["b5.zzzzw_ryoka_names_the_necromancer_and_dies", "b5.zzzzx_teriarch_revives_ryoka_and_burns_venitra",
			"b5.zzzzy_teriarch_and_the_necromancer_strike_an_accord", "b5.zzzzze_teriarch_says_ivolethe_is_banished"]:
		assert_false(Director.happened(gs.world.status(id)), id)
	assert_true(gs.world.is_alive(_db.canon, "ryoka_griffin"))
	assert_true(gs.flags.has("ryoka.under_word_of_death"), "nobody lifts the curse")
	for id: String in ["b5.zzzzv_ivolethe_breaks_faerie_law_to_save_ryoka", "b5.zzzzz_liscor_burns_brunkr_and_ulrien",
			"b5.zzzzzf_the_goblin_lords_drums_reach_liscor"]:
		assert_true(Director.happened(gs.world.status(id)), id)


func test_without_ivolethe_ryoka_never_runs_for_the_dragon() -> void:
	var gs := _fresh()
	assert_eq(Commands.kill_npc(gs, _db, "ivolethe"), "")
	_sleep_to_last_day(gs)
	for id: String in ["b5.zzzzn_the_necromancer_warns_ryoka_and_ivolethe_strikes_ijvani",
			"b5.zzzzo_ryoka_writes_a_letter_and_runs_for_the_dragon", "b5.zzzzs_regrika_brings_madness_to_celum",
			"b5.zzzzw_ryoka_names_the_necromancer_and_dies"]:
		assert_false(Director.happened(gs.world.status(id)), id)
	assert_true(gs.world.is_alive(_db.canon, "ryoka_griffin"))
	for id: String in ["b5.zzzzq_regrika_kills_ulrien_in_the_inn", "b5.zzzzz_liscor_burns_brunkr_and_ulrien",
			"b5.zzzzza_erin_reaches_level_32"]:
		assert_true(Director.happened(gs.world.status(id)), id)
