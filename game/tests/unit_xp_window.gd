extends GutTest
## M17.8 (ADR 0027): hidden XP windows on canon events. A window is open while its event is PENDING,
## today is inside its day window and the hour is inside its hours; the highest boost counts; it
## multiplies the XP of every action. Hand-made events in a copy of the real canon.

const EVENT := "b1.skinner_leads_the_dead_into_liscor"
const OTHER := "b1.rags_kills_skinner"
const EPS := 0.000001
var _db: DataDb


func before_each() -> void:
	_db = DataDb.load_dir()


func _at(day: int, hour: int) -> GameState:
	var gs := GameState.new_game(1, _db)
	gs.clock.total_minutes = (day - 1) * Clock.MINUTES_PER_DAY + hour * 60
	return gs


func test_the_shipped_data_is_valid_and_has_the_skinner_windows() -> void:
	assert_eq(_db.errors.size(), 0, "\n".join(_db.errors))
	assert_has(_db.canon.windows, EVENT)
	assert_has(_db.canon.windows, OTHER)
	assert_eq(int(_db.canon.events[EVENT]["xp_window"]["boost"]), 2)


func test_open_on_the_evening_of_the_skinner_day() -> void:
	assert_eq(XpWindow.boost(_at(39, 20), _db), 2)
	assert_almost_eq(XpWindow.mult(_at(39, 20), _db), 2.0, EPS)


func test_open_after_midnight_until_the_hours_end() -> void:
	assert_eq(XpWindow.boost(_at(40, 3), _db), 2, "still the Skinner night")
	assert_eq(XpWindow.boost(_at(40, 6), _db), 0, "six in the morning: over")


func test_closed_outside_the_hours_and_days() -> void:
	assert_eq(XpWindow.boost(_at(39, 12), _db), 0, "noon of the same day")
	assert_eq(XpWindow.boost(_at(38, 20), _db), 0, "the day before")
	assert_eq(XpWindow.boost(_at(41, 20), _db), 0, "the day after the window")
	assert_almost_eq(XpWindow.mult(_at(10, 20), _db), 1.0, EPS)


func test_closed_once_the_event_has_resolved() -> void:
	var gs := _at(39, 20)
	gs.world.events[EVENT] = {"status": "done"}
	gs.world.events[OTHER] = {"status": "done"}
	assert_eq(XpWindow.boost(gs, _db), 0, "the night resolved them: no double dipping")
	gs.world.events[OTHER] = {"status": "pending"}
	assert_eq(XpWindow.boost(gs, _db), 2, "the other one still holds it open")


func test_the_highest_boost_wins_and_they_do_not_multiply() -> void:
	_db.canon.events[EVENT]["xp_window"]["boost"] = 3
	assert_eq(XpWindow.boost(_at(39, 20), _db), 3, "one x3 and one x2: x3")
	assert_almost_eq(XpWindow.mult(_at(39, 20), _db), 3.0, EPS)


func test_no_hours_means_all_day() -> void:
	_db.canon.events[EVENT]["xp_window"].erase("hours")
	_db.canon.events[OTHER]["xp_window"].erase("hours")
	assert_eq(XpWindow.boost(_at(39, 12), _db), 2)


func test_a_delayed_event_keeps_its_window_open_longer() -> void:
	var gs := _at(42, 20)
	assert_eq(XpWindow.boost(gs, _db), 0)
	gs.world.events[EVENT] = {"status": "pending", "latest": 43}
	assert_eq(XpWindow.boost(gs, _db), 2, "world.latest() counts delays")


func test_an_action_pays_the_window_factor() -> void:
	var plain := GameState.new_game(1, _db)
	var a := Actions.perform(plain, _db, "cook_stew", {"minutes": 0})
	var night := _at(39, 20)
	var b := Actions.perform(night, _db, "cook_stew", {"minutes": 0})
	assert_eq(float(a["window"]), 1.0)
	assert_eq(float(b["window"]), 2.0)
	assert_almost_eq(float(b["xp"]), float(a["xp"]) * 2.0, EPS, "all actions, not only fights")


func test_a_toy_world_has_no_windows() -> void:
	var toy := ToyData.db()
	assert_true(toy.canon.windows.is_empty())
	assert_almost_eq(XpWindow.mult(GameState.new(), toy), 1.0, EPS)


func test_bad_windows_are_refused() -> void:
	var c := CanonDb.new()
	c._validate_xp_window("event 'x'", "two")
	c._validate_xp_window("event 'x'", {"boost": 0})
	c._validate_xp_window("event 'x'", {"boost": 1.5})
	c._validate_xp_window("event 'x'", {"boost": 2, "hours": [5, 5]})
	c._validate_xp_window("event 'x'", {"boost": 2, "hours": [1, 30]})
	c._validate_xp_window("event 'x'", {"boost": 2, "extra": 1})
	assert_eq(c.errors.size(), 6, "\n".join(c.errors))
	c.errors.clear()
	c._validate_xp_window("event 'x'", {"boost": 2, "hours": [18, 6]})
	c._validate_xp_window("event 'x'", {"boost": 3})
	assert_eq(c.errors.size(), 0)


func test_an_unknown_boost_tier_is_an_error() -> void:
	_db.canon.events[EVENT]["xp_window"]["boost"] = 9
	assert_string_contains("\n".join(XpWindow.validate(_db)), "no tier 9")
