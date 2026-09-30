extends GutTest

const EPS := 0.000001
var _xp: Dictionary


func before_all() -> void:
	_xp = DataDb.load_dir().rules["xp"]


func _log_with(times: Array, id := "a") -> ActionLog:
	var log := ActionLog.new()
	for t in times:
		log.add({"time": t, "action_id": id, "tags": {"x": 1.0}, "xp": 1.0})
	return log


func test_risk_mult_range() -> void:
	assert_almost_eq(Xp.risk_mult(0.0, _xp), 1.0, EPS)
	assert_almost_eq(Xp.risk_mult(1.0, _xp), 4.0, EPS)
	assert_almost_eq(Xp.risk_mult(5.0, _xp), 4.0, EPS)


func test_outcome_mult() -> void:
	assert_eq(Xp.outcome_mult("success", _xp), 1.0)
	assert_eq(Xp.outcome_mult("fail", _xp), 0.5)


func test_intensity_is_clamped() -> void:
	assert_eq(Xp.clamp_intensity(10.0, _xp), 3.0)
	assert_eq(Xp.clamp_intensity(0.0, _xp), 0.25)
	assert_eq(Xp.clamp_intensity(1.5, _xp), 1.5)


func test_conviction_mult() -> void:
	var tags := {"cooking.stew": 0.5, "combat": 0.5}
	assert_almost_eq(Xp.conviction_mult(tags, [], _xp), 1.0, EPS)
	assert_almost_eq(Xp.conviction_mult(tags, ["cooking"], _xp), 1.125, EPS)
	assert_almost_eq(Xp.conviction_mult(tags, ["cooking", "combat"], _xp), 1.25, EPS)


func test_novelty_first_time_bonus() -> void:
	assert_almost_eq(Xp.novelty_mult(ActionLog.new(), "a", 0, _xp), 1.5, EPS)


func test_novelty_falls_with_repetition() -> void:
	# One record right now: w = 1 → 1 / 1.35
	assert_almost_eq(Xp.novelty_mult(_log_with([1000]), "a", 1000, _xp), 1.0 / 1.35, EPS)
	var twice := Xp.novelty_mult(_log_with([1000, 1000]), "a", 1000, _xp)
	assert_almost_eq(twice, 1.0 / 1.7, EPS)


func test_novelty_recovers_over_days() -> void:
	# Two days old = one half-life: w = 0.5
	var v := Xp.novelty_mult(_log_with([0]), "a", 2880, _xp)
	assert_almost_eq(v, 1.0 / 1.175, EPS)
	# Outside the 7-day window: full novelty, but no first-time bonus.
	assert_almost_eq(Xp.novelty_mult(_log_with([0]), "a", 1440 * 8, _xp), 1.0, EPS)


func test_novelty_ignores_other_actions() -> void:
	var log := _log_with([1000], "b")
	assert_almost_eq(Xp.novelty_mult(log, "a", 1000, _xp), 1.5, EPS)


func test_novelty_has_a_floor() -> void:
	var times := []
	for i in 200:
		times.append(1000)
	assert_almost_eq(Xp.novelty_mult(_log_with(times), "a", 1000, _xp), 0.1, EPS)


func test_compute_multiplies_everything() -> void:
	assert_almost_eq(Xp.compute(10.0, 2.0, 1.5, 0.5, 1.25, 0.75), 14.0625, EPS)


func test_skill_mult_counts_by_tag_overlap() -> void:
	var effects := [{"tags": ["cooking"], "value": 1.2}, {"tags": ["hospitality"], "value": 2.0}]
	var tags := {"cooking.stew": 0.5, "combat": 0.5}
	assert_almost_eq(Xp.skill_mult(tags, effects), 1.1, 0.000001)
	assert_almost_eq(Xp.skill_mult(tags, []), 1.0, 0.000001)


# --- M17.8: duress (how hard a fight was) and the window factor (hidden) ---

func test_duress_follows_the_users_curve() -> void:
	assert_almost_eq(Xp.duress_mult(0.0, _xp), 0.5, EPS, "nothing lost: half")
	assert_almost_eq(Xp.duress_mult(0.05, _xp), 0.75, EPS, "half way to 10% lost")
	assert_almost_eq(Xp.duress_mult(0.10, _xp), 1.0, EPS, "10% lost: normal")
	assert_almost_eq(Xp.duress_mult(0.30, _xp), 1.2, EPS, "+1 point per 1% more")
	assert_almost_eq(Xp.duress_mult(0.86, _xp), 1.76, EPS, "the user's example")
	assert_almost_eq(Xp.duress_mult(1.0, _xp), 1.9, EPS, "a knock-out")


func test_duress_is_capped_and_clamped() -> void:
	var r := {"duress": {"floor": 0.5, "even_at": 0.1, "per_percent": 0.02, "cap": 2.0}}
	assert_almost_eq(Xp.duress_mult(0.9, r), 2.0, EPS, "capped at x2.0")
	assert_almost_eq(Xp.duress_mult(-1.0, _xp), 0.5, EPS, "less than nothing is nothing")
	assert_almost_eq(Xp.duress_mult(7.0, _xp), 1.9, EPS, "more than everything is everything")


func test_no_duress_block_means_one() -> void:
	assert_almost_eq(Xp.duress_mult(0.0, {}), 1.0, EPS)
	assert_almost_eq(Xp.duress_mult(0.0, ToyData.db().rules["xp"]), 1.0, EPS, "toy worlds keep their numbers")


func test_boost_tiers() -> void:
	assert_almost_eq(Xp.boost_mult(0, _xp), 1.0, EPS, "no window")
	assert_almost_eq(Xp.boost_mult(1, _xp), 1.5, EPS)
	assert_almost_eq(Xp.boost_mult(2, _xp), 2.0, EPS)
	assert_almost_eq(Xp.boost_mult(3, _xp), 3.0, EPS)
	assert_almost_eq(Xp.boost_mult(9, _xp), 1.0, EPS, "an unknown tier pays nothing extra")


func test_compute_takes_duress_and_window_last() -> void:
	assert_almost_eq(Xp.compute(10.0, 2.0, 1.5, 1.0, 1.0, 1.0, 1.0, 0.5, 2.0), 30.0, EPS)
	assert_almost_eq(Xp.compute(10.0, 2.0, 1.5, 1.0, 1.0, 1.0), 30.0, EPS, "old calls keep their result")


func test_a_record_keeps_duress_and_window() -> void:
	var db := DataDb.load_dir()
	var gs := GameState.new_game(1, db)
	var plain := Actions.perform(gs, db, "cook_stew", {"minutes": 0})
	assert_eq(float(plain["duress"]), 1.0)
	assert_eq(float(plain["window"]), 1.0)
	var gs2 := GameState.new_game(1, db)
	var boosted := Actions.perform(gs2, db, "cook_stew", {"minutes": 0, "duress": 0.5, "window": 2.0})
	assert_almost_eq(float(boosted["xp"]), float(plain["xp"]), EPS, "x0.5 times x2.0 is x1.0")
	var gs3 := GameState.new_game(1, db)
	var half := Actions.perform(gs3, db, "cook_stew", {"minutes": 0, "duress": 0.5})
	assert_almost_eq(float(half["xp"]), float(plain["xp"]) * 0.5, EPS)
