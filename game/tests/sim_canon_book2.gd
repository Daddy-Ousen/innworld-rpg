extends GutTest
## Real Book 2 canon (game/data/canon/book2). With no player input, every
## b2. event in days FIRST_DAY–LAST_DAY happens as written: no drift. The
## game is slept to day FIRST_DAY - 1 once (before_all); each test starts
## from a copy of that save.

## First day with Book 2 canon (the magic call and 2.00 are day 41).
const FIRST_DAY := 41
## Last day with extracted Book 2 canon (M8.7: the whole book, through 2.48, day 71).
const LAST_DAY := 71
const ARRIVAL_DAY := 8

var _db: DataDb
var _base_json := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	var gs := GameState.new_game(1, _db)
	ToyCanon.sleep_through(gs, _db, FIRST_DAY - 1)
	_base_json = gs.to_json()


func _fresh() -> GameState:
	return GameState.from_json(_base_json)


static func _b2(id: String) -> bool:
	return id.begins_with("b2.")


func _b2_events() -> Array[String]:
	var out: Array[String] = []
	for id: String in _db.canon.events:
		var ev: Dictionary = _db.canon.events[id]
		if _b2(id) and int(ev["window"]["earliest"]) <= LAST_DAY and not _db.canon.alt_only.has(id):
			out.append(id)
	return out


func test_book2_loads() -> void:
	assert_eq(_db.canon.errors, [] as Array[String])
	assert_eq(_db.errors, [] as Array[String])
	assert_gte(_b2_events().size(), 21)
	for npc: String in ["octavia", "peslas"]:
		assert_true(_db.canon.npcs.has(npc), npc)
	for loc: String in ["wistram_academy", "invrisil", "tailless_thief", "stitchworks"]:
		assert_true(_db.canon.locations.has(loc), loc)


func test_book2_runs_as_canon() -> void:
	var gs := _fresh()
	assert_eq(gs.clock.day(), FIRST_DAY)
	var rumors := 0
	while gs.world.last_day < LAST_DAY:
		var night := Commands.sleep(gs, _db, Rest.ANYWHERE)
		for line: String in night["lines"]:
			if line.begins_with("Rumor: "):
				rumors += 1
	var expected := _b2_events()
	for id: String in expected:
		assert_eq(gs.world.status(id), Director.DONE, id)
	var b2_history := gs.world.history.filter(func(h: Dictionary) -> bool: return _b2(h["event"]))
	assert_eq(b2_history.size(), expected.size(), "one history entry per event")
	assert_eq(gs.world.drift, 0.0)
	var rumor_events := expected.filter(func(id: String) -> bool:
			return int(_db.canon.events[id]["tier"]) == 1 and _db.canon.events[id].has("rumor"))
	assert_eq(rumors, rumor_events.size(), "a rumor for each tier 1 event")
	var news_events := expected.filter(func(id: String) -> bool: return _db.canon.events[id].has("news"))
	news_events.sort()
	var heard := gs.world.news.filter(func(n: Dictionary) -> bool: return n["kind"] == Director.NEWS and _b2(n["event"])) \
			.map(func(n: Dictionary) -> String: return n["event"])
	heard.sort()
	assert_eq(heard, news_events, "one news line per event with news")
	# The state at the end of M8.1.
	for f: String in ["ceria.rescued", "olesm.rescued", "gazi.lost_an_eye", "gazi.gone_to_reim", "izril.winter",
			"ryoka.back_in_celum", "erin.became_a_warrior", "ceria.will_lodge_at_inn", "liscor.winter_prices"]:
		assert_true(gs.flags.has(f), f)
	for f: String in ["ceria.missing", "olesm.missing", "gazi.hunts_ryoka", "ryoka.bound_for_celum", "ksmvr.deposed"]:
		assert_false(gs.flags.has(f), f)
	assert_true(gs.flags.has("calruz.missing"), "Calruz is still missing")
	assert_true(gs.world.is_alive(_db.canon, "calruz"))
	assert_true(gs.world.is_alive(_db.canon, "gazi_pathseeker"))
	# The end of Book 2 (M8.7): Erin stranded in Celum, Toren gone, Rags barred
	# from the inn, Esthelm burned, the Liscor dungeon open.
	for f: String in ["erin.stranded_north", "erin.left_liscor", "erin.in_celum", "toren.left_erin",
			"rags.banned_from_inn", "esthelm.burned", "liscor_dungeon.opened", "ryoka.took_on_the_gnoll_debt",
			"ryoka.hunted_by_venitra", "garen.hit_squad_hunts_erin", "teriarch.copied_the_iphone"]:
		assert_true(gs.flags.has(f), f)
	for f: String in ["toren.missing", "ksmvr.deposed"]:
		assert_false(gs.flags.has(f), f)
	# That night Erin sleeps at the Frenzied Hare and Toren is off the map.
	for i in 200:
		if gs.clock.minute() >= 23 * 60:
			break
		Commands.wait(gs, _db, 3600)
	assert_gte(gs.clock.minute(), 23 * 60, "late at night")
	assert_eq(_where(gs, "erin_solstice").get_slice(" ", 0), "celum_frenzied_hare", "Erin at the Hare")
	assert_eq(_where(gs, "toren"), "off map", "Toren gone")


func _where(gs: GameState, id: String) -> String:
	var n: Dictionary = gs.npcs.npcs.get(id, {})
	if n.is_empty():
		return "gone"
	if BehaviourDb.is_off_map(n["area"]):
		return "off map"
	return "%s %d,%d" % [n["area"], int(n["x"]), int(n["y"])]


func test_without_pisces_no_one_hears_ceria() -> void:
	var gs := _fresh()
	assert_eq(Commands.kill_npc(gs, _db, "pisces"), "")
	ToyCanon.sleep_through(gs, _db, LAST_DAY)
	assert_eq(gs.world.status("b2.ceria_calls_pisces_from_the_ruins"), Director.CANCELLED)
	for id: String in ["b2.erin_leads_the_rescue_into_the_ruins", "b2.ceria_and_olesm_found_in_the_coffins",
			"b2.gazi_attacks_outside_the_ruins", "b2.ceria_will_lodge_at_the_inn"]:
		assert_eq(gs.world.status(id), Director.CANCELLED, id)
	assert_true(gs.flags.has("ceria.missing"), "no one finds her")
	assert_true(gs.flags.has("gazi.hunts_ryoka"), "Gazi never got her chance")
	for id: String in ["b2.winter_arrives_with_the_frost_fairies", "b2.ryoka_reaches_celum_in_the_snow",
			"b2.erin_visits_the_tailless_thief"]:
		assert_true(Director.happened(gs.world.status(id)), id)
	assert_gt(gs.world.drift, 0.0)
