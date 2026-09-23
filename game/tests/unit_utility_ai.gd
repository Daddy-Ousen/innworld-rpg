extends GutTest
## UtilityAi (ADR 0008): scores from base, hours, days and flags; ties go
## to the goal listed first; nothing scores → stay (idle).

const HOUR := 3600

var _db: DataDb
var _gs: GameState


func before_each() -> void:
	_db = ToyNpcs.db()
	_gs = GameState.new(1)


func _day(day: int, hour: int) -> int:
	return (day - 1) * UtilityAi.SECONDS_PER_DAY + hour * HOUR


func test_hours_pick_the_goal() -> void:
	assert_eq(UtilityAi.pick(_gs, _db, "baker", _day(1, 7))["goal"], "off_map")
	assert_eq(UtilityAi.pick(_gs, _db, "baker", _day(1, 8))["goal"], "work")
	assert_eq(UtilityAi.pick(_gs, _db, "baker", _day(1, 11) + 3599)["goal"], "work")
	assert_eq(UtilityAi.pick(_gs, _db, "baker", _day(1, 12))["goal"], "off_map", "to is not inside")
	assert_eq(UtilityAi.pick(_gs, _db, "baker", _day(3, 9))["goal"], "work", "every day")


func test_hours_wrap_past_midnight() -> void:
	var g := {"goal": "sleep", "base": 1, "hours": [[22, 6, 2.0]]}
	assert_eq(UtilityAi.hour_mult(g, _day(1, 23)), 2.0)
	assert_eq(UtilityAi.hour_mult(g, _day(2, 0)), 2.0)
	assert_eq(UtilityAi.hour_mult(g, _day(2, 5)), 2.0)
	assert_eq(UtilityAi.hour_mult(g, _day(2, 6)), 0.0)
	assert_eq(UtilityAi.hour_mult(g, _day(2, 21)), 0.0)
	assert_eq(UtilityAi.hour_mult({"goal": "work", "base": 1}, _day(1, 3)), 1.0, "no hours: always")


func test_first_matching_hour_range_gives_the_mult() -> void:
	var g := {"goal": "work", "base": 2, "hours": [[6, 9, 1.5], [8, 12, 0.5]]}
	assert_eq(UtilityAi.score(_gs, g, _day(1, 8)), 3.0)
	assert_eq(UtilityAi.score(_gs, g, _day(1, 10)), 1.0)


func test_days_and_flags_rule_goals_out() -> void:
	var g := {"goal": "trade", "base": 5, "days": [8, 8], "when_flags": ["a"], "unless_flags": ["b"]}
	assert_eq(UtilityAi.score(_gs, g, _day(8, 10)), 0.0, "needs a")
	_gs.flags["a"] = true
	assert_eq(UtilityAi.score(_gs, g, _day(8, 10)), 5.0)
	assert_eq(UtilityAi.score(_gs, g, _day(7, 23)), 0.0, "before the days")
	assert_eq(UtilityAi.score(_gs, g, _day(9, 0)), 0.0, "after the days")
	_gs.flags["b"] = true
	assert_eq(UtilityAi.score(_gs, g, _day(8, 10)), 0.0, "blocked by b")


func test_ties_go_to_the_first_goal_and_nothing_means_stay() -> void:
	_db.behaviour = BehaviourDb.from_dicts({}, {"guard": ToyNpcs.npc([
		ToyNpcs.goal("patrol", 1, {"hours": [[6, 10, 1]], "target": {"area": "town", "pos": [1, 1]}}),
		ToyNpcs.goal("eat", 1, {"hours": [[6, 10, 1]], "target": {"area": "town", "pos": [2, 1]}}),
	])})
	assert_eq(UtilityAi.pick(_gs, _db, "guard", _day(1, 7))["goal"], "patrol")
	assert_eq(UtilityAi.pick(_gs, _db, "guard", _day(1, 11)), UtilityAi.IDLE)
