extends GutTest
## A long road (10 h between Celum, the camp and Liscor) asks first and plays a short
## walk before the move (user, 2026-10-08). Short exits and headless sims are unchanged.

var _session: Node


func before_each() -> void:
	_session = get_node_or_null("/root/Session")


func _main(area: String, at: Vector2i) -> Node:
	var gs := GameState.new_game(4, _session.db)
	gs.player.place(area, at)
	Commands.settle(gs, _session.db)
	_session.set_state(gs)
	var m: Node = load("res://world/main.tscn").instantiate()
	m.switch_scene = false
	m.confirm_travel = true
	return add_child_autofree(m)


func test_duration_text() -> void:
	assert_eq(TravelPrompt.duration_text(600), "10 hours")
	assert_eq(TravelPrompt.duration_text(60), "1 hour")
	assert_eq(TravelPrompt.duration_text(90), "1 hour 30 min")


func test_only_long_roads_ask() -> void:
	assert_true(TravelPrompt.is_long(600))
	assert_false(TravelPrompt.is_long(180))
	for id: String in _session.db.maps.areas:
		for e: Dictionary in _session.db.maps.areas[id]["exits"]:
			if id in ["celum_gate", "road_camp", "liscor_gate"] and e["to"] in ["celum_gate", "road_camp", "liscor_gate"]:
				assert_true(TravelPrompt.is_long(int(e["minutes"])), "%s -> %s" % [id, e["to"]])


func test_celum_to_camp_asks_and_stay_keeps_you_there() -> void:
	var m := _main("celum_gate", Vector2i(16, 18))
	m.step("s")
	assert_true(m.travel.visible, "the question is up")
	assert_eq(_session.gs.player.area, "celum_gate", "nothing moved yet")
	var before: int = _session.gs.clock.total_minutes
	m.travel._on_stay()
	assert_false(m.travel.visible)
	assert_eq(_session.gs.player.area, "celum_gate")
	assert_eq(_session.gs.clock.total_minutes, before, "no time passed")


func test_travel_then_the_walk_makes_the_move() -> void:
	var m := _main("celum_gate", Vector2i(16, 18))
	m.step("s")
	m.travel._on_go()
	assert_eq(_session.gs.player.area, "celum_gate", "the move waits for the end of the walk")
	m.travel.skip()
	assert_eq(_session.gs.player.area, "road_camp")
	assert_true(m.confirm_travel, "the prompt is back on for the next road")


func test_camp_to_liscor_and_back_ask_too() -> void:
	var m := _main("road_camp", Vector2i(16, 22))
	m.step("s")
	assert_true(m.travel.visible)
	m.travel._on_go()
	m.travel.skip()
	assert_eq(_session.gs.player.area, "liscor_gate")
	m.step("n")
	assert_true(m.travel.visible, "liscor to the camp asks")
	m.travel._on_stay()
	m.step("w")
	assert_false(m.travel.visible, "a plain step does not ask")


func test_the_prompt_is_off_headless_by_default() -> void:
	var m: Node = load("res://world/main.tscn").instantiate()
	add_child_autofree(m)
	assert_false(m.confirm_travel)
