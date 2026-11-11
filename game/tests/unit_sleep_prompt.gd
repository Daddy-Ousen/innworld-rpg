extends GutTest
## Audit D1 / D2 (ADR 0051) on the main scene: a sleep the player starts asks first (wake time,
## hours; "Stay awake" and Back change nothing), and R opens the Rest panel (1 hour, 3 hours,
## until the next meal, Cancel). Headless, `confirm_sleep` is off by default (sims sleep at once).

var _session: Node


func before_each() -> void:
	_session = get_node_or_null("/root/Session")


## A main scene in the inn at the bed, `hour` of day 4.
func _main(hour: float = 8.0, area: String = "inn_interior", at: Vector2i = Vector2i(20, 13)) -> Node:
	var gs := GameState.new_game(4, _session.db)
	gs.player.place(area, at)
	gs.npcs.npcs.clear()
	Commands.settle(gs, _session.db)
	gs.clock.total_minutes = int(hour * 60.0) + Clock.MINUTES_PER_DAY * 3
	gs.clock.awake_minutes = 0
	_session.set_state(gs)
	var m: Node = load("res://world/main.tscn").instantiate()
	m.switch_scene = false
	m.confirm_sleep = true
	return add_child_autofree(m)


func _action(action: StringName) -> InputEventAction:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	return ev


func _texts(m: Node) -> Array:
	var out := []
	for r: Dictionary in m.menu.rows():
		out.append(r["text"])
	return out


func test_the_question_is_off_headless_by_default() -> void:
	var m: Node = load("res://world/main.tscn").instantiate()
	add_child_autofree(m)
	assert_false(m.confirm_sleep)


func test_z_asks_with_the_wake_time_and_hours() -> void:
	var m := _main(8.0)
	var before: int = _session.gs.clock.total_minutes
	m._unhandled_input(_action(&"sleep"))
	assert_true(m.menu.visible, "the question is up")
	assert_eq(m.menu.page, InteractMenu.ASK)
	assert_string_contains(m.menu.title_text(), "Sleep until 06:00?")
	assert_string_contains(m.menu.title_text(), "22 h")
	assert_eq(_texts(m), ["Sleep"])
	assert_eq(m.menu.buttons()[0].has_focus(), true, "Sleep has the focus")
	assert_true(m.is_busy(), "the map takes no walk input")
	assert_eq(_session.gs.clock.total_minutes, before, "nothing happened yet")


func test_stay_awake_changes_nothing() -> void:
	var m := _main(8.0)
	var before: int = _session.gs.clock.total_minutes
	var day: int = _session.gs.clock.day()
	m._unhandled_input(_action(&"sleep"))
	m.menu._close.pressed.emit()
	assert_false(m.menu.visible)
	assert_false(m.dialog.visible)
	assert_false(m.is_busy())
	assert_eq(_session.gs.clock.total_minutes, before)
	assert_eq(_session.gs.clock.day(), day)


func test_the_back_action_answers_stay_awake() -> void:
	var m := _main(8.0)
	var before: int = _session.gs.clock.total_minutes
	m._unhandled_input(_action(&"sleep"))
	m.menu._unhandled_input(_action(&"back"))
	assert_false(m.menu.visible)
	assert_eq(_session.gs.clock.total_minutes, before)


func test_sleep_runs_the_night() -> void:
	var m := _main(8.0)
	var day: int = _session.gs.clock.day()
	m._unhandled_input(_action(&"sleep"))
	m.menu.pick(0)
	assert_false(m.menu.visible)
	assert_eq(_session.gs.clock.day(), day + 1, "the night ran")
	assert_eq(_session.gs.clock.time_string(), "06:00")
	assert_true(m.dialog.visible)


func test_a_beds_sleep_action_asks_too() -> void:
	var m := _main(21.0)
	var before: int = _session.gs.clock.total_minutes
	m.use("bed", Interact.SLEEP)
	assert_true(m.menu.visible)
	assert_string_contains(m.menu.title_text(), "9 h")
	assert_eq(_session.gs.clock.total_minutes, before)


func test_a_refused_sleep_asks_nothing() -> void:
	var m := _main(21.0, "celum_gate", Vector2i(16, 8))
	var before: int = _session.gs.clock.total_minutes
	m._unhandled_input(_action(&"sleep"))
	assert_false(m.menu.visible, "no question")
	assert_false(m.dialog.visible)
	assert_eq(_session.gs.clock.total_minutes, before)
	assert_string_contains(m.hud.get_node("%Log").text, String(_session.db.rules["economy"]["rest"]["refused_line"]))


func test_a_collapse_does_not_ask() -> void:
	var m := _main(21.0)
	_session.gs.clock.awake_minutes = int(_session.db.rules["clock"]["collapse_after_awake"])
	m._unhandled_input(_action(&"sleep"))
	assert_false(m.menu.visible, "no question")
	assert_true(m.dialog.visible, "the night ran")


func test_the_question_waits_while_a_panel_has_the_screen() -> void:
	var m := _main(8.0)
	m.sheet.open(_session.gs, _session.db)
	var before: int = _session.gs.clock.total_minutes
	m._unhandled_input(_action(&"sleep"))
	assert_false(m.menu.visible, "the sheet has the keyboard")
	assert_eq(_session.gs.clock.total_minutes, before)


# --- the Rest panel -----------------------------------------------------------

func test_r_opens_the_rest_panel_with_its_options() -> void:
	var m := _main(15.0, "celum_gate", Vector2i(16, 8))
	m._unhandled_input(_action(&"rest"))
	assert_true(m.menu.visible)
	assert_eq(m.menu.page, InteractMenu.ASK)
	assert_eq(_texts(m), ["Rest 1 hour", "Rest 3 hours", "Rest until 18:00 (dinner)"])
	assert_true(m.is_busy())


func test_a_rest_pick_moves_the_clock_and_logs_it() -> void:
	var m := _main(15.0, "celum_gate", Vector2i(16, 8))
	var before: int = _session.gs.clock.total_minutes
	m._unhandled_input(_action(&"rest"))
	m.menu.pick(0)
	assert_eq(_session.gs.clock.total_minutes, before + 60)
	assert_false(m.menu.visible)
	assert_string_contains(m.hud.get_node("%Log").text, "You rest for 1 hour.")


func test_rest_until_the_meal_ends_at_the_meal() -> void:
	var m := _main(15.0, "celum_gate", Vector2i(16, 8))
	m._unhandled_input(_action(&"rest"))
	m.menu.pick(2)
	assert_eq(_session.gs.clock.time_string(), "18:00")


func test_cancel_rests_not() -> void:
	var m := _main(15.0, "celum_gate", Vector2i(16, 8))
	var before: int = _session.gs.clock.total_minutes
	m._unhandled_input(_action(&"rest"))
	m.menu._unhandled_input(_action(&"back"))
	assert_false(m.menu.visible)
	assert_eq(_session.gs.clock.total_minutes, before)


func test_rest_is_refused_with_enemies_near() -> void:
	var m := _main(15.0, "celum_gate", Vector2i(16, 8))
	var gs: GameState = _session.gs
	Combat.add_monster(gs, _session.db, "goblin_grunt", Vector2i(16, 4), CombatState.HOSTILE)
	var before := gs.clock.total_minutes
	m._unhandled_input(_action(&"rest"))
	assert_false(m.menu.visible, "no panel")
	assert_eq(gs.clock.total_minutes, before)
	assert_string_contains(m.hud.get_node("%Log").text, Combat.REFUSED_DANGER)


func test_a_rest_that_ends_in_a_collapse_runs_the_tired_night() -> void:
	var m := _main(15.0, "celum_gate", Vector2i(16, 8))
	_session.gs.clock.awake_minutes = int(_session.db.rules["clock"]["collapse_after_awake"]) - 20
	m._unhandled_input(_action(&"rest"))
	m.menu.pick(1)
	assert_true(m.dialog.visible, "the collapse flow ran")
	assert_true(_session.gs.clock.last_sleep_collapsed)
