extends GutTest
## M8.7: the end of Book 2 moves people. Toren drags Erin north on day 70
## (erin.stranded_north, erin.left_liscor: she is off the map); from day 71
## (erin.in_celum) she cooks, serves and sleeps at the Frenzied Hare in
## Celum. Toren leaves the inn for good (toren.left_erin) and Rags may no
## longer visit it (rags.banned_from_inn). All of it is npc_behaviour data;
## here the flags are set by hand, so the test does not wait for day 70.

const SEED := 20260926

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])


func _where(gs: GameState, id: String) -> String:
	var n: Dictionary = gs.npcs.npcs.get(id, {})
	if n.is_empty():
		return "gone"
	if BehaviourDb.is_off_map(n["area"]):
		return "off map"
	return "%s %d,%d" % [n["area"], int(n["x"]), int(n["y"])]


func _wait_hours(gs: GameState, hours: int) -> void:
	for i in hours:
		assert_true(Commands.wait(gs, _db, 3600) >= 0, "wait")


func _wait_until(gs: GameState, minute: int) -> void:
	while gs.clock.minute() < minute:
		assert_true(Commands.wait(gs, _db, 60) >= 0, "wait")


func _flag(gs: GameState, flags: Array) -> void:
	for f: String in flags:
		gs.flags[f] = true


func test_without_the_flags_erin_sleeps_at_her_inn() -> void:
	var gs := GameState.new_game(SEED, _db)
	_wait_until(gs, 23 * 60)
	assert_eq(_where(gs, "erin_solstice"), "inn_interior 18,13")


func test_stranded_erin_is_off_the_map() -> void:
	var gs := GameState.new_game(SEED, _db)
	_wait_until(gs, 18 * 60)
	_flag(gs, ["erin.left_liscor", "erin.stranded_north"])
	_wait_until(gs, 23 * 60)
	assert_eq(_where(gs, "erin_solstice"), "off map")


func test_erin_in_celum_sleeps_and_works_at_the_hare() -> void:
	var gs := GameState.new_game(SEED, _db, "celum")
	_wait_until(gs, 18 * 60)
	_flag(gs, ["erin.left_liscor", "erin.stranded_north", "erin.in_celum"])
	_wait_until(gs, 23 * 60)
	assert_eq(_where(gs, "erin_solstice"), "celum_frenzied_hare 16,9", "asleep at the Hare")
	assert_false(Commands.sleep(gs, _db, Rest.ANYWHERE).is_empty(), "sleep to morning")
	_wait_until(gs, 8 * 60)
	assert_eq(gs.clock.day(), 9)
	assert_eq(_where(gs, "erin_solstice"), "celum_frenzied_hare 16,2", "at the stove")
	_wait_until(gs, 14 * 60)
	assert_eq(_where(gs, "erin_solstice"), "celum_square 3,12", "at Stitchworks after lunch")
	var loaded := GameState.from_json(gs.to_json())
	assert_eq(loaded.to_json(), gs.to_json(), "save and load keep Erin in Celum")


func test_toren_leaves_the_inn() -> void:
	var gs := GameState.new_game(SEED, _db)
	_flag(gs, ["wandering_inn.has_skeleton"])
	_wait_hours(gs, 3)
	assert_eq(_where(gs, "toren"), "inn_interior 14,4", "working at the inn")
	_flag(gs, ["toren.left_erin"])
	_wait_hours(gs, 3)
	assert_eq(_where(gs, "toren"), "off map", "gone")


func test_banned_rags_does_not_visit_the_inn() -> void:
	var gs := GameState.new_game(SEED, _db)
	_flag(gs, ["erin.spared_rags", "rags.banned_from_inn"])
	_wait_until(gs, 17 * 60)
	assert_ne(_where(gs, "rags"), "inn_hill 6,18")


func test_the_hare_door_room_and_bar() -> void:
	var gs := GameState.new_game(SEED, _db, "celum")
	assert_true(ToyMaps.walk_to_area(gs, _db, "celum_square"), "into the square")
	assert_true(ToyMaps.walk_to_area(gs, _db, "celum_frenzied_hare"), "into the Hare")
	assert_eq(Movement.location_at(gs, _db), "frenzied_hare")
	assert_true(_db.maps.is_indoor(gs.player.area), "indoor")
	gs.economy.coins = 20
	assert_true(ToyMaps.walk_next_to(gs, _db, "hare_bar"), "to the bar")
	assert_eq(Commands.buy(gs, _db, "hare_bar", "hot_meal")["error"], "")
	assert_true(ToyMaps.walk_next_to(gs, _db, "hare_room"), "to the room")
	var coins := gs.economy.coins
	assert_false(Commands.sleep(gs, _db, "hare_room").is_empty(), "rent the room")
	assert_eq(gs.economy.coins, coins - 6, "the room costs 6c")
	assert_true(ToyMaps.walk_to_area(gs, _db, "celum_square"), "back out")
