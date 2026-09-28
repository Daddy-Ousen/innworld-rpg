extends GutTest
## M13.1 on the real Book 5 data (4.07, day 100). Three scenes: Lyonette
## shows her new levels in the morning, Bird brings his birds at noon, and
## Erin gives out soup samples in Liscor in the afternoon. A player who talks
## with Lyonette, talks birds with Bird, or helps price the soups changes
## each event.
## The game is slept to day 99 once (before_all); each test starts from a
## copy of that save.

const SEED := 20260928
const DAY := 100
const LYONETTE := "b5.e_lyonette_levels_and_apista_pupates"
const BIRD := "b5.f_bird_brings_erin_his_birds"
const SOUP := "b5.g_erin_sells_soup_samples_at_the_guild"
const INN_SPOT := Vector2i(12, 11)
const MARKET_SPOT := Vector2i(15, 13)

var _db: DataDb
var _day100 := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])
	var gs := GameState.new_game(SEED, _db)
	ToyCanon.sleep_through(gs, _db, DAY - 1)
	_day100 = gs.to_json()


func _fresh() -> GameState:
	var gs := GameState.from_json(_day100)
	assert_eq(gs.clock.day(), DAY)
	return gs


## Stands at `pos` in `area` and waits (10 minutes a step, up to 20 hours)
## until the event's stage starts.
func _wait_for(gs: GameState, event: String, area: String, pos: Vector2i) -> void:
	gs.player.place(area, pos)
	Commands.settle(gs, _db)
	for i in 120:
		if gs.world.staged.has(event):
			break
		assert_true(Commands.wait(gs, _db, 600) >= 0, "wait")
	assert_true(gs.world.staged.has(event), "%s is staged" % event)


func _area_of(gs: GameState, id: String) -> String:
	var n: Dictionary = gs.npcs.npcs.get(id, {})
	return "" if n.is_empty() else String(n["area"])


func _hour(gs: GameState) -> int:
	@warning_ignore("integer_division")
	return gs.clock.minute() / 60


func _hook_of(gs: GameState, id: String) -> String:
	var entry: Dictionary = gs.world.history.filter(func(h: Dictionary) -> bool: return h["event"] == id)[0]
	return str(entry.get("hook", ""))


func _assert_changed(gs: GameState, id: String, hook: String, flag: String, canon_flag: String) -> void:
	assert_eq(gs.world.status(id), Director.CHANGED, id)
	assert_eq(_hook_of(gs, id), hook)
	assert_true(gs.flags.has(flag), flag)
	assert_true(gs.flags.has(canon_flag), "the canon still happens: " + canon_flag)
	var texts := gs.world.news.map(func(n: Dictionary) -> String: return n["text"])
	assert_true(texts.has(_db.canon.events[id]["hooks"][0]["news"]), "the hook's news")


## Walks next to `npc` and runs `action` with them.
func _do_with(gs: GameState, npc: String, action: String, location: String) -> void:
	var n: Dictionary = gs.npcs.npcs[npc]
	var at := Vector2i(int(n["x"]), int(n["y"]))
	var sides := {at + Vector2i(1, 0): true, at + Vector2i(-1, 0): true, at + Vector2i(0, 1): true, at + Vector2i(0, -1): true}
	if not sides.has(gs.player.pos()):
		assert_true(ToyMaps.walk_to(gs, _db, sides), "walk to " + npc)
	var r := Commands.interact(gs, _db, npc, action)
	assert_eq(r["error"], "")
	assert_eq(r["record"]["context"]["location"], location)


func test_the_stages_are_loaded() -> void:
	assert_eq(_db.canon.events[LYONETTE]["stage"]["area"], "inn_interior")
	assert_eq(_db.canon.events[BIRD]["stage"]["area"], "inn_interior")
	assert_eq(_db.canon.events[SOUP]["stage"]["area"], "liscor_market")
	for id: String in [LYONETTE, BIRD, SOUP]:
		assert_has(_db.canon.stages, id)
		var st: Dictionary = _db.canon.events[id]["stage"]
		assert_eq(st["kind"], "scene", id)
		for n: Dictionary in st["npcs"]:
			assert_true(_db.behaviour.npcs.has(n["npc"]), "%s can be placed by %s" % [n["npc"], id])
	# The two inn scenes do not overlap.
	var a: Array = _db.canon.events[LYONETTE]["stage"]["hours"]
	var b: Array = _db.canon.events[BIRD]["stage"]["hours"]
	assert_true(int(a[1]) <= int(b[0]), "Lyonette's scene ends before Bird comes in")


func test_lyonette_shows_her_levels_in_the_morning() -> void:
	var gs := _fresh()
	_wait_for(gs, LYONETTE, "inn_interior", INN_SPOT)
	var h := _hour(gs)
	assert_true(h >= 9 and h < 12, "in the morning")
	assert_eq(_area_of(gs, "lyonette"), "inn_interior")
	assert_false(gs.world.staged.has(BIRD), "Bird is not here yet")


func test_talking_with_lyonette_changes_her_morning() -> void:
	var gs := _fresh()
	_wait_for(gs, LYONETTE, "inn_interior", INN_SPOT)
	_do_with(gs, "lyonette", "talk_with_guest", "wandering_inn")
	ToyCanon.sleep_through(gs, _db, DAY)
	_assert_changed(gs, LYONETTE, "player_talked_with_lyonette_about_her_levels",
			"wandering_inn.earther_heard_lyonettes_levels", "lyonette.class_beast_tamer")
	assert_true(gs.world.relationship("lyonette", NpcSim.PLAYER) >= 2)


func test_bird_brings_his_birds_at_noon() -> void:
	var gs := _fresh()
	_wait_for(gs, BIRD, "inn_interior", INN_SPOT)
	var h := _hour(gs)
	assert_true(h >= 12 and h < 14, "early afternoon")
	for npc: String in ["bird", "erin_solstice"]:
		assert_eq(_area_of(gs, npc), "inn_interior", npc)


func test_talking_birds_with_bird_changes_the_event() -> void:
	var gs := _fresh()
	_wait_for(gs, BIRD, "inn_interior", INN_SPOT)
	_do_with(gs, "bird", "talk_with_guest", "wandering_inn")
	ToyCanon.sleep_through(gs, _db, DAY)
	_assert_changed(gs, BIRD, "player_talked_birds_with_bird",
			"wandering_inn.earther_talked_birds_with_bird", "bird.hunts_birds_for_erin")
	assert_true(gs.world.relationship("bird", NpcSim.PLAYER) >= 2)


func test_erin_gives_out_soup_in_the_market() -> void:
	var gs := _fresh()
	_wait_for(gs, SOUP, "liscor_market", MARKET_SPOT)
	var h := _hour(gs)
	assert_true(h >= 14 and h < 17, "in the afternoon")
	for npc: String in ["erin_solstice", "selys", "relc"]:
		assert_eq(_area_of(gs, npc), "liscor_market", npc)
	ToyCanon.sleep_through(gs, _db, DAY)
	assert_eq(gs.world.status(SOUP), Director.DONE)
	assert_true(gs.flags.has("erin.sells_magic_soups"))
	var texts := gs.world.news.map(func(n: Dictionary) -> String: return n["text"])
	assert_true(texts.has(_db.canon.events[SOUP]["news"]), "Liscor hears of the soups")


func test_helping_price_the_soups_changes_the_event() -> void:
	var gs := _fresh()
	_wait_for(gs, SOUP, "liscor_market", MARKET_SPOT)
	_do_with(gs, "erin_solstice", "persuade", "liscor_market")
	ToyCanon.sleep_through(gs, _db, DAY)
	_assert_changed(gs, SOUP, "player_helped_price_erins_soups",
			"liscor.earther_helped_price_erins_soups", "liscor.adventurers_order_erins_soups")
	assert_true(gs.world.relationship("erin_solstice", NpcSim.PLAYER) >= 1)


func test_no_scenes_on_another_day() -> void:
	var gs := _fresh()
	ToyCanon.sleep_through(gs, _db, DAY)
	for area: String in ["inn_interior", "liscor_market"]:
		gs.player.place(area, INN_SPOT if area == "inn_interior" else MARKET_SPOT)
		Commands.settle(gs, _db)
		for i in 8:
			Commands.wait(gs, _db, 3600)
			for id: String in [LYONETTE, BIRD, SOUP]:
				assert_false(gs.world.staged.has(id), id)
