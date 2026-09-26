extends GutTest
## Real Book 3 canon (game/data/canon/book3). With no player input, every
## b3. event in days FIRST_DAY–LAST_DAY happens as written: no drift. The
## game is slept to day FIRST_DAY - 1 once (before_all); each test starts
## from a copy of that save.

## First day with Book 3 canon (Laken's placeholder thread starts on day 71).
const FIRST_DAY := 71
## Last day with extracted Book 3 canon (M9.1: 3.00 E – 3.05 L, 1.00 D, 1.01 D;
## M9.2: 3.06 L – 3.14; M9.3: 3.15 – 3.20 T).
const LAST_DAY := 80

var _db: DataDb
var _base_json := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	var gs := GameState.new_game(1, _db)
	ToyCanon.sleep_through(gs, _db, FIRST_DAY - 1)
	_base_json = gs.to_json()


func _fresh() -> GameState:
	return GameState.from_json(_base_json)


static func _b3(id: String) -> bool:
	return id.begins_with("b3.")


func _b3_events() -> Array[String]:
	var out: Array[String] = []
	for id: String in _db.canon.events:
		var ev: Dictionary = _db.canon.events[id]
		if _b3(id) and int(ev["window"]["earliest"]) <= LAST_DAY and not _db.canon.alt_only.has(id):
			out.append(id)
	return out


func _where(gs: GameState, id: String) -> String:
	var n: Dictionary = gs.npcs.npcs.get(id, {})
	if n.is_empty():
		return "gone"
	if BehaviourDb.is_off_map(n["area"]):
		return "off map"
	return "%s %d,%d" % [n["area"], int(n["x"]), int(n["y"])]


func test_book3_loads() -> void:
	assert_eq(_db.canon.errors, [] as Array[String])
	assert_eq(_db.errors, [] as Array[String])
	assert_gte(_b3_events().size(), 117)
	for npc: String in ["laken_godart", "durene", "prost", "yesel", "ivolethe", "geneva_scala", "okasha",
			"thriss", "belgrade", "anand", "garry", "nemor", "frostwing", "gamel", "jasi", "ylawes_byres",
			"esthelm_florist", "grunter", "headscratcher", "badarrow", "numbtongue", "rabbiteater"]:
		assert_true(_db.canon.npcs.has(npc), npc)
	for loc: String in ["riverfarm", "celum_adventurers_guild", "ocre", "first_landing", "road_to_invrisil"]:
		assert_true(_db.canon.locations.has(loc), loc)
	# Laken's Earth friend Teresa is not an NPC; `teresa` stays Trey's twin (book2).
	assert_true(_db.canon.npcs["teresa"]["tags"].has("reim"))


func test_book3_runs_as_canon() -> void:
	var gs := _fresh()
	assert_eq(gs.clock.day(), FIRST_DAY)
	while gs.world.last_day < LAST_DAY:
		Commands.sleep(gs, _db, Rest.ANYWHERE)
	var expected := _b3_events()
	for id: String in expected:
		assert_eq(gs.world.status(id), Director.DONE, id)
	var b3_history := gs.world.history.filter(func(h: Dictionary) -> bool: return _b3(h["event"]))
	assert_eq(b3_history.size(), expected.size(), "one history entry per event")
	assert_eq(gs.world.drift, 0.0)
	var rumor_events := expected.filter(func(id: String) -> bool:
			return int(_db.canon.events[id]["tier"]) == 1 and _db.canon.events[id].has("rumor"))
	rumor_events.sort()
	var rumors := gs.world.news.filter(func(n: Dictionary) -> bool: return n["kind"] == Director.RUMOR and _b3(n["event"])) \
			.map(func(n: Dictionary) -> String: return n["event"])
	rumors.sort()
	assert_eq(rumors, rumor_events, "a rumor for each tier 1 event")
	var news_events := expected.filter(func(id: String) -> bool: return _db.canon.events[id].has("news"))
	news_events.sort()
	var heard := gs.world.news.filter(func(n: Dictionary) -> bool: return n["kind"] == Director.NEWS and _b3(n["event"])) \
			.map(func(n: Dictionary) -> String: return n["event"])
	heard.sort()
	assert_eq(heard, news_events, "one news line per event with news")
	# The state at the end of M9.3.
	for f: String in ["laken.emperor", "durene.revealed_half_troll", "durene.paladin", "laken.found_buried_gold",
			"horns_of_hammerad.gone_to_albez", "horns_of_hammerad.in_ocre", "horns_of_hammerad.has_albez_treasure",
			"yvlon.armor_fused_to_arms", "erin.makes_corusdeer_soup", "ryoka.banned_from_runners_guild",
			"ryoka.gone_to_magnolia", "magnolia.allied_with_ryoka", "magnolia.gone_to_first_landing",
			"liscor_hive.soldiers_died_for_heaven", "pawn.cares_for_the_soldiers", "pawn.allowed_to_pray",
			"riverfarm.buried_by_avalanche", "laken.rules_riverfarm", "laken.left_for_invrisil",
			"ryoka.friends_with_ivolethe", "ryoka.magic_stalled", "persua.beaten_by_ryoka", "persua.swore_to_kill_ryoka",
			"celum_runners_guild.buried_in_snow", "ryoka.asked_to_leave_celum", "ryoka.learning_to_run_like_the_wind",
			"liscor.goblin_army_passed", "wandering_inn.reopened_by_lyonette", "pawn.will_tell_klbkch_of_his_class",
			"geneva.died_and_lives_through_okasha", "geneva.called_the_last_light",
			"ryoka.in_celum", "erin.in_celum", "lyonette.works_at_inn", "mrsha.in_selys_care",
			"erin.staged_a_play", "jasi.works_at_frenzied_hare", "grev.lives_at_frenzied_hare", "ylawes.at_esthelm",
			"esthelm.saved", "goblin_lord.vanguard_routed", "silver_swords.at_esthelm", "toren.heading_to_liscor",
			"redfang_band.left_esthelm"]:
		assert_true(gs.flags.has(f), f)
	for f: String in ["ryoka.gained_first_class", "celum.earther_stood_with_ryoka",
			"wandering_inn.earther_kept_lyonette_going", "frenzied_hare.earther_sat_with_ryoka",
			"horns_of_hammerad.trapped_in_albez", "pawn.may_not_pray", "frenzied_hare.earther_saw_the_play",
			"esthelm.earther_held_the_barricade"]:
		assert_false(gs.flags.has(f), f)
	assert_false(gs.world.is_alive(_db.canon, "thriss"), "Okasha killed Thriss")
	assert_true(gs.world.is_alive(_db.canon, "geneva_scala"), "Geneva lives on through Okasha")
	assert_true(gs.world.is_alive(_db.canon, "persua"), "Persua was beaten, not killed")
	assert_false(gs.world.is_alive(_db.canon, "nemor"), "Magnolia killed Nemor")
	for npc: String in ["grunter", "rocksoup", "esthelm_florist", "goblin_vanguard_commander"]:
		assert_false(gs.world.is_alive(_db.canon, npc), npc + " died at Esthelm")
	for npc: String in ["ylawes_byres", "headscratcher", "badarrow", "numbtongue", "rabbiteater", "toren"]:
		assert_true(gs.world.is_alive(_db.canon, npc), npc + " lives")
	# That evening Lyonette keeps the inn; Ryoka has gone north to Magnolia,
	# the Horns are far away in Ocre and Mrsha is with Selys.
	for i in 200:
		if gs.clock.minute() >= 20 * 60:
			break
		Commands.wait(gs, _db, 3600)
	assert_gte(gs.clock.minute(), 20 * 60, "evening")
	assert_eq(_where(gs, "lyonette").get_slice(" ", 0), "inn_interior", "Lyonette keeps the inn")
	for npc: String in ["ryoka_griffin", "ceria_springwalker", "pisces", "ksmvr", "mrsha"]:
		assert_eq(_where(gs, npc), "off map", npc)


func test_remote_threads_do_not_need_liscor_or_celum() -> void:
	var gs := _fresh()
	for npc: String in ["erin_solstice", "ryoka_griffin", "lyonette", "ceria_springwalker"]:
		assert_eq(Commands.kill_npc(gs, _db, npc), "", npc)
	ToyCanon.sleep_through(gs, _db, LAST_DAY)
	for id: String in ["b3.laken_makes_durene_a_paladin", "b3.baleros_hears_of_the_last_light",
			"b3.laken_sets_out_for_invrisil"]:
		assert_eq(gs.world.status(id), Director.DONE, id)
	for id: String in ["b3.horns_run_out_of_coin_at_albez", "b3.ryoka_befriends_ivolethe",
			"b3.ryoka_beats_persua_in_the_runners_guild", "b3.lyonette_reopens_the_inn"]:
		assert_eq(gs.world.status(id), Director.CANCELLED, id)
	assert_true(Director.happened(gs.world.status("b3.goblin_army_marches_past_liscor")), "the army still marches")


func test_without_persua_there_is_no_guild_fight() -> void:
	var gs := _fresh()
	assert_eq(Commands.kill_npc(gs, _db, "persua"), "")
	ToyCanon.sleep_through(gs, _db, LAST_DAY)
	for id: String in ["b3.persua_flaunts_her_courier_skill", "b3.ryoka_beats_persua_in_the_runners_guild",
			"b3.frost_faeries_bury_the_celum_runners_guild", "b3.celum_watch_asks_ryoka_to_leave"]:
		assert_eq(gs.world.status(id), Director.CANCELLED, id)
	for id: String in ["b3.ryoka_befriends_ivolethe", "b3.lyonette_reopens_the_inn", "b3.laken_makes_durene_a_paladin"]:
		assert_eq(gs.world.status(id), Director.DONE, id)
	assert_false(gs.flags.has("celum_runners_guild.buried_in_snow"))
	assert_gt(gs.world.drift, 0.0)
