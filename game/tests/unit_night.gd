extends GutTest

const EPS := 0.000001
var _db: DataDb


func before_all() -> void:
	_db = ToyData.db()


func _new_game() -> GameState:
	return GameState.new_game(11, _db)


func test_close_day_takes_only_todays_records() -> void:
	var gs := _new_game()
	Actions.perform(gs, _db, "cook")
	assert_eq(Night.close_day(gs).size(), 1)
	assert_eq(gs.progression.day_start, gs.clock.total_minutes)
	Actions.perform(gs, _db, "fight")
	var today := Night.close_day(gs)
	assert_eq(today.size(), 1)
	assert_eq(today[0]["action_id"], "fight")


func test_night_resolves_offers_and_advances_the_day() -> void:
	var gs := _new_game()
	for i in 3:
		Actions.perform(gs, _db, "cook")
	assert_true(gs.progression.pools.is_empty(), "pools fill at night, not during the day")
	var night := Night.run(gs, _db)
	assert_eq(night["records"], 3)
	assert_eq(night["days_passed"], 1)
	assert_eq(gs.clock.day(), 2)
	assert_eq(gs.clock.time_string(), "06:00")
	assert_true((night["offers"] as Array).has("cook"))
	assert_eq(gs.morning, night["lines"])
	assert_string_contains("\n".join(gs.morning), "Class offered")


func test_offers_per_night_are_capped() -> void:
	var gs := _new_game()
	gs.progression.pools = {"cook": 99.0, "innkeeper": 99.0, "warrior": 99.0, "pacifist": 99.0}
	var night := Night.run(gs, _db)
	assert_eq((night["offers"] as Array).size(), 2)


func test_levels_and_skills_happen_at_night() -> void:
	var gs := _new_game()
	ToyData.give_class(gs, "cook", 1)
	gs.progression.classes["cook"]["xp"] = 95.0
	Actions.perform(gs, _db, "cook")  # 15 XP with the first-time bonus
	assert_eq(gs.progression.level_of("cook"), 1)
	var night := Night.run(gs, _db)
	assert_eq(gs.progression.level_of("cook"), 2)
	assert_string_contains(night["lines"][0], "level 2")
	assert_eq(gs.progression.skills.size(), 1, "chance_per_level = 1.0 in toy rules")


func test_breakthrough_message_only_once() -> void:
	var gs := _new_game()
	ToyData.give_class(gs, "cook", 2, 190.0)
	Actions.perform(gs, _db, "cook")  # +15 → 205 ≥ 200 for the capstone level 3
	var first := Night.run(gs, _db)
	assert_string_contains("\n".join(first["lines"]), "breakthrough")
	Actions.perform(gs, _db, "cook")
	var second := Night.run(gs, _db)
	assert_false("\n".join(second["lines"]).contains("breakthrough"))


func test_collapse_night() -> void:
	var gs := _new_game()
	gs.clock.advance(int(_db.rules["clock"]["collapse_after_awake"]))
	assert_eq(Actions.perform(gs, _db, "cook"), {}, "action refused")
	var night := Commands.sleep(gs, _db)
	assert_true(gs.clock.last_sleep_collapsed)
	assert_string_contains(night["lines"][0], "collapsed")
	assert_false(Actions.perform(gs, _db, "cook").is_empty(), "awake again")


func test_commands_set_focus_checks_tags() -> void:
	var gs := _new_game()
	assert_eq(Commands.set_focus(gs, _db, ["cooking"]), "")
	assert_eq(gs.focus_tags, ["cooking"] as Array[String])
	assert_string_contains(Commands.set_focus(gs, _db, ["nope"]), "Unknown tag")
	assert_eq(gs.focus_tags, ["cooking"] as Array[String], "unchanged after an error")
	Commands.set_focus(gs, _db, [])
	assert_true(gs.focus_tags.is_empty())


func test_knock_out_night_wakes_at_the_normal_time() -> void:
	var gs := _new_game()
	gs.clock.advance(14 * 60)  # 20:00
	var night := Night.run(gs, _db, true, true)
	assert_eq(night["lines"][0], Night.KNOCKOUT_LINE)
	assert_true(night["knocked_out"])
	assert_true(night["collapsed"], "a knock-out counts as a collapse")
	assert_eq(gs.clock.day(), 2)
	assert_eq(gs.clock.time_string(), "06:00", "not the 12 h collapse sleep")
	assert_true(gs.clock.last_sleep_collapsed)


func test_a_collapse_still_sleeps_long() -> void:
	var gs := _new_game()
	gs.clock.advance(14 * 60)
	var start := gs.clock.total_minutes
	var night := Night.run(gs, _db, true)
	assert_false(night["knocked_out"])
	assert_eq(night["lines"][0], Night.COLLAPSE_LINE)
	assert_eq(gs.clock.total_minutes - start, int(_db.rules["clock"]["collapse_sleep_minutes"]))
