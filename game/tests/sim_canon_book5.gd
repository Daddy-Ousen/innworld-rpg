extends GutTest
## Real Book 5 canon (game/data/canon/book5). With no player input, every
## b5. event in days FIRST_DAY–LAST_DAY happens as written: no drift. The
## game is slept to day FIRST_DAY - 1 once (before_all); each test starts
## from a copy of that save.

## First day with Book 5 canon (4.06 M: Magnolia's gathering, a guess).
const FIRST_DAY := 97
## Last day with extracted Book 5 canon (M13.1: 4.07, the soups, day 100).
const LAST_DAY := 100

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
	assert_gte(_b5_events().size(), 9)
	for npc: String in ["tyrion_veltras", "patricia_melissar", "eliasor", "bethal", "thomast", "pryde", "wuvren", "zanthia",
			"venith_crusland", "maresar", "calac_crusland", "tengrip", "uleth", "siyal"]:
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
			"erin.waits_for_ryoka", "ryoka.near_celum", "ryoka.heading_home_to_liscor", "izril.winter"]:
		assert_true(gs.flags.has(f), f)
	for f: String in ["wandering_inn.earther_heard_lyonettes_levels", "wandering_inn.earther_talked_birds_with_bird",
			"liscor.earther_helped_price_erins_soups"]:
		assert_false(gs.flags.has(f), f)
	assert_false(gs.world.is_alive(_db.canon, "patricia_melissar"), "murdered at the gathering (4.06 M)")
	for npc: String in ["magnolia_reinhart", "tyrion_veltras", "eliasor", "xrn", "klbkch", "bird", "lyonette", "ryoka_griffin"]:
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
