extends GutTest
## Travel between Celum and Liscor (M8.6, ADR 0015): the road through the
## roadside camp (10 h each way) and the paid wagon ride (8 h, no cold).

const SEED := 20260925
const ROAD_MINUTES := 600

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])


func _game(start: String, area: String, pos: Vector2i) -> GameState:
	var gs := GameState.new_game(SEED, _db, start)
	gs.player.place(area, pos)
	Commands.settle(gs, _db)
	return gs


func _step_onto_exit(gs: GameState, dir: String, to: String, arrive: Vector2i) -> void:
	var before := gs.clock.total_minutes
	var r := Commands.move(gs, _db, dir)
	assert_eq(r["exit_to"], to)
	assert_eq(gs.player.area, to)
	assert_eq(gs.player.pos(), arrive)
	assert_between(gs.clock.total_minutes - before, ROAD_MINUTES, ROAD_MINUTES + 1)


func test_the_road_south_from_celum_reaches_the_camp_then_liscor() -> void:
	var gs := _game("celum", "celum_gate", Vector2i(16, 18))
	_step_onto_exit(gs, "s", "road_camp", Vector2i(16, 1))
	gs.player.place("road_camp", Vector2i(17, 22))
	_step_onto_exit(gs, "s", "liscor_gate", Vector2i(17, 1))


func test_the_road_north_from_liscor_reaches_the_camp_then_celum() -> void:
	var gs := _game("liscor", "liscor_gate", Vector2i(16, 1))
	_step_onto_exit(gs, "n", "road_camp", Vector2i(16, 22))
	gs.player.place("road_camp", Vector2i(16, 1))
	_step_onto_exit(gs, "n", "celum_gate", Vector2i(16, 18))


func test_the_camp_is_a_campsite_outdoors() -> void:
	assert_true(_db.maps.is_camp("road_camp"))
	assert_false(_db.maps.is_indoor("road_camp"))
	assert_false(_db.maps.is_camp("celum_gate"))


func test_the_wagon_needs_coins() -> void:
	var gs := _game("celum", "celum_gate", Vector2i(17, 5))
	assert_string_contains(Commands.ride(gs, _db, "celum_wagon"), "cannot afford")
	assert_eq(gs.player.area, "celum_gate")


func test_the_wagon_takes_you_to_the_other_gate_without_cold() -> void:
	var gs := _game("celum", "celum_gate", Vector2i(17, 5))
	gs.flags["izril.winter"] = true
	Commands.give(gs, _db, 45)
	var before := gs.clock.total_minutes
	var hp := Combat.hp(gs, _db)
	assert_eq(Commands.ride(gs, _db, "celum_wagon"), "")
	assert_eq(gs.player.area, "liscor_gate")
	assert_eq(gs.player.pos(), Vector2i(17, 9))
	assert_eq(gs.clock.total_minutes - before, 480)
	assert_eq(gs.economy.coins, 5)
	assert_eq(Combat.hp(gs, _db), hp, "a covered ride does not chill")
	var last: Dictionary = gs.action_log.records[-1]
	assert_eq(last["action_id"], "travel")
	assert_true(last["context"]["ride"])


func test_walking_the_road_in_winter_is_cold() -> void:
	var gs := _game("celum", "celum_gate", Vector2i(16, 18))
	gs.flags["izril.winter"] = true
	Commands.settle(gs, _db)
	var hp := Combat.hp(gs, _db)
	Commands.move(gs, _db, "s")
	assert_lt(Combat.hp(gs, _db), hp)


func test_a_ride_from_liscor_goes_to_celum() -> void:
	var gs := _game("liscor", "liscor_gate", Vector2i(17, 9))
	Commands.give(gs, _db, 40)
	assert_eq(Commands.ride(gs, _db, "liscor_wagon"), "")
	assert_eq(gs.player.area, "celum_gate")
	assert_eq(gs.player.pos(), Vector2i(17, 5))


func test_a_knock_out_at_the_camp_wakes_by_the_campfire() -> void:
	var gs := _game("liscor", "road_camp", Vector2i(16, 20))
	Commands.knock_out(gs, _db)
	assert_eq(gs.player.area, "road_camp")
	assert_eq(gs.player.pos(), Vector2i(19, 14))


func test_bad_shop_room_ride_and_camp_fields_are_errors() -> void:
	var areas := _db.maps.areas.duplicate(true)
	var objs: Array = areas["celum_gate"]["objects"]
	objs.append({"id": "bad_shop", "at": [2, 2], "name": "X", "actions": [], "shop": "celum_stall"})
	objs.append({"id": "bad_shop2", "at": [3, 2], "name": "X", "actions": [], "shop": "nowhere"})
	objs.append({"id": "bad_room", "at": [4, 2], "name": "X", "actions": [], "price": 5})
	objs.append({"id": "bad_ride", "at": [5, 2], "name": "X", "actions": [],
		"ride": {"to": "liscor_gate", "pos": [0, 0], "minutes": 0, "price": 1}})
	areas["celum_gate"]["camp"] = "yes"
	var errs := MapDb.from_dicts(_db.maps.tiles, areas).validate(_db)
	for want: String in ["needs the action 'buy_supplies'", "needs the action 'sell_goods'",
			"unknown shop 'nowhere'", "price needs", "ride pos must be", "ride needs minutes",
			"camp must be true or false"]:
		assert_true(errs.any(func(x: String) -> bool: return x.contains(want)), want)
