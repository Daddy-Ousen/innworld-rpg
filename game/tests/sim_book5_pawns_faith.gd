extends GutTest
## M13.3 on the real Book 5 data (4.13 L – 4.17, days 101–111). Two scenes:
## Pawn comes back to the inn after the Hive's battle (day 104, midday to
## afternoon) and his Soldiers eat bee soup on the inn's hill (day 106, night).
## A player who talks with them changes each event. From day 104 Drassi and
## Ishkr work at the inn; from day 106 Ryoka and Mrsha are away at the
## Strongheart farm.
## The game is slept to the morning of day 103 once (before_all); each test
## starts from a copy of that save.

const SEED := 20260928
const DAY := 103
const PAWN := "b5.za_pawn_comes_back_from_the_front"
const SOUP := "b5.zg_pawns_soldiers_eat_bee_soup_at_the_inn"
const INN_SPOT := Vector2i(12, 11)
const HILL_SPOT := Vector2i(15, 13)

var _db: DataDb
var _day103 := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])
	var gs := GameState.new_game(SEED, _db)
	ToyCanon.sleep_through(gs, _db, DAY - 1)
	_day103 = gs.to_json()


func _fresh() -> GameState:
	var gs := GameState.from_json(_day103)
	assert_eq(gs.clock.day(), DAY)
	return gs


## Sleeps until the morning of `day`.
func _morning_of(gs: GameState, day: int) -> void:
	ToyCanon.sleep_through(gs, _db, day - 1)
	assert_eq(gs.clock.day(), day)


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


## Waits in `area` until `hour` (half an hour a step).
func _wait_until(gs: GameState, area: String, pos: Vector2i, hour: int) -> void:
	gs.player.place(area, pos)
	Commands.settle(gs, _db)
	while _hour(gs) < hour:
		assert_true(Commands.wait(gs, _db, 1800) >= 0, "wait")


func test_the_stages_are_loaded() -> void:
	assert_eq(_db.canon.events[PAWN]["stage"]["area"], "inn_interior")
	assert_eq(_db.canon.events[SOUP]["stage"]["area"], "inn_hill")
	for id: String in [PAWN, SOUP]:
		assert_has(_db.canon.stages, id)
		var st: Dictionary = _db.canon.events[id]["stage"]
		assert_eq(st["kind"], "scene", id)
		for n: Dictionary in st["npcs"]:
			assert_true(_db.behaviour.npcs.has(n["npc"]), "%s can be placed by %s" % [n["npc"], id])
	assert_eq(_db.maps.areas["inn_hill"]["location"], "wandering_inn", "a hook on the hill counts as the inn")


func test_pawn_comes_back_at_midday_on_day_104() -> void:
	var gs := _fresh()
	_morning_of(gs, 104)
	_wait_for(gs, PAWN, "inn_interior", INN_SPOT)
	var h := _hour(gs)
	assert_true(h >= 12 and h < 16, "midday to afternoon")
	for npc: String in ["pawn", "lyonette", "ryoka_griffin"]:
		assert_eq(_area_of(gs, npc), "inn_interior", npc)


func test_sitting_with_pawn_changes_his_return() -> void:
	var gs := _fresh()
	_morning_of(gs, 104)
	_wait_for(gs, PAWN, "inn_interior", INN_SPOT)
	_do_with(gs, "pawn", "comfort_someone", "wandering_inn")
	ToyCanon.sleep_through(gs, _db, 104)
	_assert_changed(gs, PAWN, "player_sat_with_pawn_after_the_battle",
			"wandering_inn.earther_sat_with_pawn", "pawn.has_erins_censer")
	assert_true(gs.world.relationship("pawn", NpcSim.PLAYER) >= 1)


func test_the_soldiers_eat_soup_on_the_hill_on_day_106() -> void:
	var gs := _fresh()
	_morning_of(gs, 106)
	_wait_for(gs, SOUP, "inn_hill", HILL_SPOT)
	assert_true(_hour(gs) >= 19, "at night")
	for npc: String in ["pawn", "tersk", "lyonette"]:
		assert_eq(_area_of(gs, npc), "inn_hill", npc)


func test_serving_the_soup_changes_the_night() -> void:
	var gs := _fresh()
	_morning_of(gs, 106)
	_wait_for(gs, SOUP, "inn_hill", HILL_SPOT)
	_do_with(gs, "tersk", "talk_with_guest", "wandering_inn")
	ToyCanon.sleep_through(gs, _db, 106)
	_assert_changed(gs, SOUP, "player_served_soup_to_pawns_soldiers",
			"wandering_inn.earther_served_the_soldiers_soup", "tersk.learning_to_pray")
	assert_true(gs.world.relationship("tersk", NpcSim.PLAYER) >= 1)


func test_drassi_and_ishkr_work_at_the_inn_from_day_104() -> void:
	var gs := _fresh()
	_wait_until(gs, "inn_interior", INN_SPOT, 11)
	for npc: String in ["drassi", "ishkr"]:
		assert_ne(_area_of(gs, npc), "inn_interior", npc + ": the first day's hires show the next morning")
	_morning_of(gs, 104)
	_wait_until(gs, "inn_interior", INN_SPOT, 11)
	for npc: String in ["drassi", "ishkr"]:
		assert_eq(_area_of(gs, npc), "inn_interior", npc)
		assert_eq(gs.npcs.npcs[npc]["goal"], "work", npc)


func test_ryoka_and_mrsha_are_away_at_the_farm_from_day_106() -> void:
	var gs := _fresh()
	_morning_of(gs, 106)
	assert_true(gs.flags.has("ryoka.away_at_the_strongheart_farm"))
	_wait_until(gs, "inn_interior", INN_SPOT, 19)
	for npc: String in ["ryoka_griffin", "mrsha"]:
		assert_ne(_area_of(gs, npc), "inn_interior", npc)


func test_no_scenes_on_day_105() -> void:
	var gs := _fresh()
	_morning_of(gs, 105)
	for area: String in ["inn_interior", "inn_hill"]:
		gs.player.place(area, INN_SPOT if area == "inn_interior" else HILL_SPOT)
		Commands.settle(gs, _db)
		for i in 8:
			Commands.wait(gs, _db, 3600)
			for id: String in [PAWN, SOUP]:
				assert_false(gs.world.staged.has(id), id)
