extends GutTest

const EPS := 0.000001
var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()


func _new_game() -> GameState:
	return GameState.new_game(7, _db)


func _start() -> int:
	return int(_db.rules["clock"]["start_minute"])


func test_perform_logs_record_and_spends_time() -> void:
	var gs := _new_game()
	var rec := Actions.perform(gs, _db, "cook_stew", {"witnesses": ["relc"]})
	assert_eq(rec["action_id"], "cook_stew")
	assert_eq(rec["time"], _start())
	assert_eq(rec["day"], gs.clock.day())
	assert_eq(rec["minute"], _start() % Clock.MINUTES_PER_DAY)
	assert_eq(rec["outcome"], "success")
	assert_eq(rec["witnesses"], ["relc"])
	# First time: 10 base × 1.5 novelty bonus.
	assert_almost_eq(float(rec["xp"]), 15.0, EPS)
	assert_eq(gs.clock.total_minutes, _start() + 90)
	assert_eq(gs.action_log.records.size(), 1)


func test_context_adds_tags() -> void:
	var gs := _new_game()
	var rec := Actions.perform(gs, _db, "cook_stew", {"context": {"guests": 12, "location": "wandering_inn"}})
	var tags: Dictionary = rec["tags"]
	assert_almost_eq(float(tags["cooking.stew"]), 1.0 / 1.7, EPS)
	assert_almost_eq(float(tags["hospitality"]), 0.7 / 1.7, EPS)


func test_context_rule_not_met_adds_nothing() -> void:
	var gs := _new_game()
	var rec := Actions.perform(gs, _db, "cook_stew", {"context": {"guests": 3, "location": "road"}})
	assert_eq(rec["tags"], {"cooking.stew": 1.0})


func test_repetition_gives_less_xp() -> void:
	var gs := _new_game()
	var first := float(Actions.perform(gs, _db, "sweep_floor")["xp"])
	var second := float(Actions.perform(gs, _db, "sweep_floor")["xp"])
	var third := float(Actions.perform(gs, _db, "sweep_floor")["xp"])
	assert_gt(first, second)
	assert_gt(second, third)


func test_risk_option_and_outcome() -> void:
	var gs := _new_game()
	# attack_melee base 8, risk 1.0 → ×4, first time ×1.5, fail ×0.5 = 24
	var rec := Actions.perform(gs, _db, "attack_melee", {"risk": 1.0, "outcome": "fail"})
	assert_almost_eq(float(rec["xp"]), 24.0, EPS)
	assert_eq(rec["risk"], 1.0)


func test_intensity_is_clamped_in_record() -> void:
	var gs := _new_game()
	var rec := Actions.perform(gs, _db, "chop_wood", {"intensity": 99.0})
	assert_eq(rec["intensity"], 3.0)


func test_focus_raises_xp() -> void:
	var plain := _new_game()
	var focused := _new_game()
	focused.focus_tags = ["cooking"]
	var a := float(Actions.perform(plain, _db, "cook_stew")["xp"])
	var b := float(Actions.perform(focused, _db, "cook_stew")["xp"])
	assert_almost_eq(b, a * 1.25, EPS)


func test_unknown_action_is_refused() -> void:
	var gs := _new_game()
	assert_eq(Actions.perform(gs, _db, "fly_to_moon"), {})
	assert_push_error("Unknown action")
	assert_eq(gs.clock.total_minutes, _start())


func test_unknown_outcome_is_refused() -> void:
	var gs := _new_game()
	assert_eq(Actions.perform(gs, _db, "cook_stew", {"outcome": "meh"}), {})
	assert_push_error("Unknown outcome")


func test_no_action_while_collapse_is_due() -> void:
	var gs := _new_game()
	gs.clock.advance(2160)
	var before := gs.clock.total_minutes
	assert_eq(Actions.perform(gs, _db, "cook_stew"), {})
	assert_eq(gs.clock.total_minutes, before)


func test_old_records_are_pruned() -> void:
	var gs := _new_game()
	Actions.perform(gs, _db, "cook_stew")
	gs.clock.total_minutes += 8 * Clock.MINUTES_PER_DAY
	Actions.perform(gs, _db, "sweep_floor")
	assert_eq(gs.action_log.records.size(), 1)
	assert_eq(gs.action_log.count("cook_stew"), 1)


## Same seed + same commands = same result, also across a save/load.
func test_deterministic_across_save_and_load() -> void:
	var script := ["cook_stew", "sweep_floor", "cook_stew", "haggle", "cook_stew", "play_chess"]
	var a := _new_game()
	var b := _new_game()
	for i in script.size():
		Actions.perform(a, _db, script[i], {"context": {"guests": i * 3}})
		Actions.perform(b, _db, script[i], {"context": {"guests": i * 3}})
		if i == 2:
			b = GameState.from_json(b.to_json())
	assert_eq(b.to_dict(), a.to_dict())
