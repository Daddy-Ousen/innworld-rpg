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
