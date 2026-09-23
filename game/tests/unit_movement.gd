extends GutTest
## Movement: walls, exits, time cost, sub-minute carry, collapse (ADR 0006).

var _db: DataDb


func before_all() -> void:
	_db = ToyMaps.db()
	assert_eq(_db.maps.errors, [] as Array[String])


func _new_game() -> GameState:
	return ToyMaps.new_game(_db)


func test_new_game_places_the_player_at_the_start() -> void:
	var gs := _new_game()
	assert_eq(gs.player.area, "town")
	assert_eq(gs.player.pos(), Vector2i(1, 2))


func test_a_step_moves_one_tile_and_turns() -> void:
	var gs := _new_game()
	var r := Movement.step(gs, _db, "n")
	assert_true(r["moved"])
	assert_eq(gs.player.pos(), Vector2i(1, 1))
	assert_eq(gs.player.facing, "n")


func test_walls_water_and_solid_objects_block() -> void:
	var gs := _new_game()
	var start := gs.clock.total_minutes
	var r := Movement.step(gs, _db, "w")
	assert_true(r["blocked"], "wall")
	assert_false(r["moved"])
	assert_eq(gs.player.facing, "w", "the player still turns")
	assert_eq(gs.player.sub_seconds, 0, "a blocked step costs no time")
	gs.player.place("town", Vector2i(4, 1))
	assert_true(Movement.step(gs, _db, "e")["blocked"], "water")
	gs.player.place("town", Vector2i(2, 2))
	assert_true(Movement.step(gs, _db, "s")["blocked"], "solid stove")
	assert_eq(gs.clock.total_minutes, start)


func test_steps_cost_seconds_and_carry_the_rest() -> void:
	var gs := _new_game()
	var start := gs.clock.total_minutes
	for i in 9:
		assert_true(ToyMaps.walk(gs, _db, ["e" if i % 2 == 0 else "w"]))
	assert_eq(gs.clock.total_minutes, start, "9 × 6 s is under a minute")
	assert_eq(gs.player.sub_seconds, 54)
	var r := Movement.step(gs, _db, "e")
	assert_eq(r["minutes"], 1)
	assert_eq(gs.clock.total_minutes, start + 1)
	assert_eq(gs.clock.awake_minutes, 1)
	assert_eq(gs.player.sub_seconds, 0)


func test_exit_with_minutes_travels() -> void:
	var gs := _new_game()
	gs.player.place("town", Vector2i(6, 2))
	var start := gs.clock.total_minutes
	var r := Movement.step(gs, _db, "e")
	assert_true(r["moved"])
	assert_eq(r["exit_to"], "field")
	assert_eq(r["minutes"], 30)
	assert_eq(gs.player.area, "field")
	assert_eq(gs.player.pos(), Vector2i(1, 1))
	assert_eq(gs.clock.total_minutes, start + 30)
	var rec: Dictionary = gs.action_log.records[-1]
	assert_eq(rec["action_id"], "travel")
	assert_almost_eq(float(rec["intensity"]), 0.25, 0.000001, "30 of 120 minutes")


func test_door_with_zero_minutes_costs_one_step() -> void:
	var gs := _new_game()
	gs.player.place("town", Vector2i(6, 2))
	var r := Movement.step(gs, _db, "s")
	assert_eq(r["exit_to"], "shop")
	assert_eq(gs.player.pos(), Vector2i(1, 1))
	assert_eq(gs.player.sub_seconds, 6)
	assert_true(gs.action_log.records.is_empty(), "no travel action for a door")
	assert_true(ToyMaps.walk(gs, _db, ["s"]))
	assert_eq(gs.player.area, "town")
	assert_eq(gs.player.pos(), Vector2i(5, 2))


func test_collapse_due_refuses_a_step() -> void:
	var gs := _new_game()
	gs.clock.awake_minutes = int(_db.rules["clock"]["collapse_after_awake"])
	var r := Movement.step(gs, _db, "n")
	assert_true(r["refused"])
	assert_eq(gs.player.pos(), Vector2i(1, 2))


func test_collapse_due_refuses_an_exit() -> void:
	var gs := _new_game()
	gs.player.place("town", Vector2i(6, 2))
	gs.clock.awake_minutes = int(_db.rules["clock"]["collapse_after_awake"])
	assert_true(Movement.step(gs, _db, "e")["refused"])
	assert_eq(gs.player.area, "town")
	assert_true(gs.action_log.records.is_empty())


func test_unknown_direction_is_refused() -> void:
	var gs := _new_game()
	assert_true(Movement.step(gs, _db, "up")["refused"])


func test_location_is_the_zone_or_the_map_location() -> void:
	var gs := _new_game()
	assert_eq(Movement.location_at(gs, _db), "toy_town")
	gs.player.place("town", Vector2i(3, 1))
	assert_eq(Movement.location_at(gs, _db), "toy_corner")


func test_unplaced_player_is_placed_on_first_move() -> void:
	var gs := _new_game()
	gs.player = PlayerState.new()
	assert_false(gs.player.is_placed())
	assert_true(Movement.step(gs, _db, "n")["moved"])
	assert_eq(gs.player.pos(), Vector2i(1, 1))


func test_no_world_refuses() -> void:
	var d := ToyData.db()
	var gs := GameState.new_game(1, d)
	assert_false(gs.player.is_placed())
	assert_true(Movement.step(gs, d, "n")["refused"])
	assert_eq(Movement.location_at(gs, d), "")


func test_pathfind_is_shortest_and_avoids_other_exits() -> void:
	var r := Pathfind.path(_db.maps, "town", Vector2i(1, 2), {Vector2i(5, 2): true})
	assert_true(r["found"])
	assert_eq(r["steps"].size(), 4)
	# From 5,2 to 6,1 without stepping on the shop door at 6,3.
	var r2 := Pathfind.path(_db.maps, "town", Vector2i(5, 3), {Vector2i(6, 1): true})
	assert_true(r2["found"])
	assert_false(r2["steps"].has("s"))
	var none := Pathfind.path(_db.maps, "town", Vector2i(1, 2), {Vector2i(5, 1): true})
	assert_false(none["found"], "water is not a goal you can reach")
