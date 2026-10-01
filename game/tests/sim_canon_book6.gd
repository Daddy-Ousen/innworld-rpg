extends GutTest
## Real Book 6 canon (game/data/canon/book6). With no player input, every
## b6. event in days FIRST_DAY–LAST_DAY happens as written: no drift. The
## game is slept to day FIRST_DAY - 1 once (before_all); each test starts
## from a copy of that save. LAST_DAY grows with each Book 6 batch.

## First day with Book 6 canon (4.32 G: the Goblin Lord's army passes Liscor, a guess).
const FIRST_DAY := 114
## Last day with Book 6 canon so far (M18.7: Antinium Wars Pt. 3 – 5, 4.48, 4.49; Zel dies on 130).
const LAST_DAY := 130

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
	assert_gte(_b6_events().size(), 110)
	for npc: String in ["goblin_lord", "the_fool", "xersia", "erille", "isodore", "nereshal", "cirille_bitterclaw", "kirust",
			"blighted_king", "blighted_queen", "keith", "chole", "eddy", "vincent", "cynthia"]:
		assert_true(_db.canon.npcs.has(npc), npc)
	for loc: String in ["wirclaw_village", "paranfer", "rie_estate", "neunham"]:
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
	rumors.sort()
	assert_eq(rumors, ["b6.garen_burns_the_empty_estate_and_a_northern_town",
			"b6.goblin_lord_breaks_a_human_army_at_a_river_city", "b6.goblin_lord_hits_esthelm_in_passing",
			"b6.goblins_burn_a_village_near_riverfarm",
			"b6.laken_relieves_rie_estate", "b6.rags_sacks_a_human_town", "b6.rose_knights_hit_the_flooded_waters_camp",
			"b6.the_rose_knights_lose_to_the_tree_trap_fort", "b6.zel_speaks_to_magnolias_army"])
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
	# M18.3: the goats, Bugear's death, the Redfang five in the inn.
	for f: String in ["eater_goats.ambushed_the_goblin_army", "redfang.survivors_became_hobgoblins", "bird.lost_the_duel_with_badarrow",
			"wirclaw_village.eater_goats_killed", "redfang.lost_bugear", "erin.bowed_to_the_goblins", "redfang.lodge_in_the_inn_basement",
			"zevara.stood_down_on_zels_order", "zel.moved_out_of_the_inn", "lyonette.back_at_the_inn"]:
		assert_true(gs.flags.has(f), f)
	assert_false(gs.world.is_alive(_db.canon, "bugear"), "killed by the Eater Goats (4.34)")
	for npc: String in ["headscratcher", "badarrow", "shorthilt", "rabbiteater", "numbtongue", "wirclaw", "bird"]:
		assert_true(gs.world.is_alive(_db.canon, npc), npc + " lives")
	# M18.4: Laken's days, the Raskghar, the ring and the chute, Esthelm, Zel's leaving, Magnolia.
	for f: String in ["riverfarm.beat_a_goblin_ambush", "riverfarm.builds_trebuchets", "trottvisk.protected_by_laken",
			"riverfarm.mutual_defence_plan", "laken.relieved_rie_estate", "rie.kneels_to_laken", "laken.has_imperial_levy",
			"ilvriss.drinks_daily_at_the_tailless_thief", "raskghar.named_by_krshia", "raskghar.cannot_level",
			"olesm.has_niers_ring_of_sight", "olesm.approved_the_rat_contract", "pisces.level_30_secret",
			"liscor_ruins.hidden_chute_found", "calruz.may_have_fallen_down_the_chute", "calruz.news_told_to_the_inn",
			"olesm.level_28_tactician", "esthelm.walls_held", "liscor.hears_the_esthelm_report", "zel.left_liscor",
			"zel.met_magnolia", "zel.allied_with_magnolia", "magnolia.learns_of_laken_godart", "rie.evacuating_her_estate",
			"reynold.wounded_by_the_goblin_vanguard", "bethal.hunts_the_neunham_raiders"]:
		assert_true(gs.flags.has(f), f)
	assert_false(gs.flags.has("liscor_dungeon.earther_helped_search_the_crypt"), "no player was in the crypt")
	for npc: String in ["laken_godart", "rie", "magnolia_reinhart", "reynold", "olesm", "pisces", "ilvriss", "krshia"]:
		assert_true(gs.world.is_alive(_db.canon, npc), npc + " lives")
	# M18.5: the Rose Knights, Greydath, the inn's bad days and the party, the Hive's kill zone.
	for f: String in ["flooded_waters.fought_the_rose_knights", "greybeard.is_greydath_of_blades", "flooded_waters.built_the_tree_fort",
			"rose_knights.retreat_from_the_lake", "garen.forbids_more_raids", "rie_estate.burned_by_garen", "erin.knows_house_walchais",
			"hive.painted_soldiers_hold_the_dungeon_front", "hive.soldiers_chose_yellow_splatters_over_pawn", "twin_stripes.turned_aberration",
			"hive.crypt_lords_killed_without_loss", "wandering_inn.antinium_brawl_at_lunch", "mrsha.stabbed_at_badarrow_with_a_wand",
			"wandering_inn.goblin_party_held", "mrsha.hates_goblins_but_no_longer_expects_attack", "hive.kill_zone_built_at_the_dungeon_front",
			"twin_stripes.cured_by_pawn", "purple_smile.is_sergeant"]:
		assert_true(gs.flags.has(f), f)
	for npc: String in ["greybeard", "bethal", "thomast", "yellow_splatters", "purple_smile", "twin_stripes", "belgrade", "anand", "pawn", "mrsha"]:
		assert_true(gs.world.is_alive(_db.canon, npc), npc + " lives")
	# No player was near the inn, so no hook ran.
	assert_false(gs.flags.has("wandering_inn.earther_joined_the_goblin_party"))
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
			"b6.rags_sacks_a_human_town", "b6.pyrite_throws_the_goblins_into_the_lake", "b6.lyonette_wakes_in_the_quiet_inn"]
	var at := -1
	for id: String in want:
		var i := seq.find(id)
		assert_gt(i, at, id)
		at = i
	assert_lt(seq.find("b6.eater_goats_attack_wirclaws_village"), seq.find("b6.erin_bows_to_the_redfang_and_feeds_them"))
	assert_lt(seq.find("b6.halfseekers_brawl_with_the_redfang"), seq.find("b6.zevara_backs_down_on_zels_order"))
	assert_lt(seq.find("b6.zevara_backs_down_on_zels_order"), seq.find("b6.redfang_sleep_in_the_inn_basement"))
	assert_lt(seq.find("b6.the_blighted_king_presents_the_earthers"), seq.find("b6.demon_assassins_hit_the_palace"))
	assert_lt(seq.find("b6.demons_teleport_into_the_palace"), seq.find("b6.the_fool_dies_in_toms_arms"))


func test_zel_goes_off_the_map_after_he_leaves() -> void:
	var gs := _fresh()
	while gs.world.last_day < 129:
		Commands.sleep(gs, _db, Rest.ANYWHERE)
	assert_true(gs.flags.has("zel.left_liscor"))
	var zel: Dictionary = gs.npcs.npcs["zel_shivertail"]
	assert_eq(String(zel["area"]), "@celum", "Zel is off the map with Magnolia")


func test_zel_dies_on_day_130() -> void:
	var gs := _fresh()
	_sleep_to_last_day(gs)
	assert_false(gs.world.is_alive(_db.canon, "zel_shivertail"))


func test_esthelm_is_news_only() -> void:
	var ev: Dictionary = _db.canon.events["b6.goblin_lord_hits_esthelm_in_passing"]
	assert_false(ev.has("stage"), "the text gives only a report (user answer, M18.4)")
	assert_false(ev.has("xp_window"))
	assert_eq(ev["tier"], 1)


func test_the_rose_knights_are_news_only() -> void:
	for id: String in ["b6.rose_knights_hit_the_flooded_waters_camp", "b6.the_rose_knights_lose_to_the_tree_trap_fort"]:
		assert_false(_db.canon.events[id].has("stage"), id)
		assert_false(_db.canon.events[id].has("xp_window"), id)


func test_greydath_is_a_flag_not_a_merge() -> void:
	assert_true(_db.canon.npcs.has("greybeard"))
	assert_false(_db.canon.npcs.has("greydath"))
	var gs := _fresh()
	_sleep_to_last_day(gs)
	assert_true(gs.flags.has("greybeard.is_greydath_of_blades"))


func test_the_party_and_the_arrival_are_the_new_stages() -> void:
	var staged: Array[String] = []
	for id: String in _b6_events():
		if _db.canon.events[id].has("stage") and int(_db.canon.events[id]["window"]["earliest"]) >= 127:
			staged.append(id)
	assert_eq(staged, ["b6.the_goblin_party_at_the_inn", "b6.the_silver_swords_arrive_into_a_cake_fight", "b6.liscor_mourns_zel"])


func test_raskghar_has_its_name() -> void:
	assert_eq(_db.combat.enemies["not_gnoll"]["name"], "Raskghar")


func test_erin_reaches_level_33_and_zel_speaks() -> void:
	var gs := _fresh()
	_sleep_to_last_day(gs)
	for f: String in ["erin.level_33_magical_innkeeper", "zel.speech_at_invrisil", "zel.wears_the_heartflame_breastplate",
			"goblin_lord.ordered_to_attack_invrisil", "ilvriss.dreamed_of_periss"]:
		assert_true(gs.flags.has(f), f)


func test_chapter_order_4_43_to_4_47() -> void:
	var order := {}
	for id: String in _b6_events():
		order[id] = _db.canon.rank[id]
	for ch: Array in [["4.43", 16], ["4.44M", 17], ["4.45", 18], ["4.46", 19], ["4.47", 20]]:
		var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/canon/book6/chapters/%s.json" % ch[0]))
		assert_eq(int(d["order"]), ch[1], ch[0])
