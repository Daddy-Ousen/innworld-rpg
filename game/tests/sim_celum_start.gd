extends GutTest
## M8.5: the Celum start (rules.world.starts). A new game can begin outside
## Celum's gate on day 8, 06:00, with the same world as the Liscor start.
## The player walks into the square and the Runners' Guild; Wesle guards
## the gate and Stenei works the guild counter (data/npc_behaviour.json).

const SEED := 20260925

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])


func _where(gs: GameState, id: String) -> String:
	var n: Dictionary = gs.npcs.npcs.get(id, {})
	if n.is_empty():
		return "gone"
	if BehaviourDb.is_off_map(n["area"]):
		return n["area"]
	return "%s %d,%d" % [n["area"], int(n["x"]), int(n["y"])]


func _wait_until(gs: GameState, minute: int) -> void:
	while gs.clock.minute() < minute:
		assert_true(Commands.wait(gs, _db, 60) >= 0, "wait")


func test_start_of_finds_by_id_first_by_default_and_nothing_for_unknown() -> void:
	assert_eq(Movement.start_of(_db)["id"], "liscor")
	assert_eq(Movement.start_of(_db, "celum")["id"], "celum")
	assert_eq(Movement.start_of(_db, "moon"), {})


func test_new_game_at_celum_starts_outside_its_gate_on_day_8() -> void:
	var gs := GameState.new_game(SEED, _db, "celum")
	assert_eq(gs.player.area, "celum_gate")
	assert_eq(gs.player.pos(), Vector2i(16, 4))
	assert_eq(gs.clock.day(), 8)
	assert_eq(gs.clock.time_string(), "06:00")
	assert_eq(Movement.location_at(gs, _db), "celum")


func test_unknown_or_empty_start_uses_the_first() -> void:
	for id: String in ["", "moon"]:
		var gs := GameState.new_game(SEED, _db, id)
		assert_eq(gs.player.area, "liscor_gate", "start '%s'" % id)


func test_both_starts_share_the_same_world() -> void:
	var liscor := GameState.new_game(SEED, _db, "liscor")
	var celum := GameState.new_game(SEED, _db, "celum")
	assert_eq(celum.flags, liscor.flags)
	assert_eq(celum.world.to_dict(), liscor.world.to_dict())
	assert_eq(celum.clock.total_minutes, liscor.clock.total_minutes)


func test_a_morning_in_celum() -> void:
	var gs := GameState.new_game(SEED, _db, "celum")
	_wait_until(gs, 9 * 60)
	assert_eq(_where(gs, "wesle"), "celum_gate 15,2", "on guard at the gate")
	assert_true(ToyMaps.walk_to_area(gs, _db, "celum_square"), "into the square")
	assert_eq(Movement.location_at(gs, _db), "celum")
	assert_true(ToyMaps.walk_to_area(gs, _db, "celum_runners_guild"), "into the guild")
	assert_eq(Movement.location_at(gs, _db), "celum_runners_guild")
	assert_eq(Winter.status(gs, _db), "", "no winter on day 8")
	assert_eq(_where(gs, "stenei"), "celum_runners_guild 10,2", "at the counter")
	var loaded := GameState.from_json(gs.to_json())
	assert_eq(loaded.to_json(), gs.to_json(), "save and load keep the Celum game")


func test_a_knockout_in_celum_wakes_outside_its_gate() -> void:
	var wake: Dictionary = _db.rules["combat"]["knockout"]["wake"]
	for area: String in ["celum_gate", "celum_square"]:
		assert_eq(wake[area]["area"], "celum_gate", area)
