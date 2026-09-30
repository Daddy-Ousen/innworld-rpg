extends GutTest
## Tactical combat numbers (M17.0, ADR 0027). The user's AP rules (ADR 0022) as data in rules.combat.tactical.
## AP is stored in quarter points: 6 AP = 24 q, one tile = 1 q.

var _t: Dictionary


func before_all() -> void:
	var db := DataDb.load_dir()
	assert_eq(db.errors.size(), 0, "real data loads clean")
	_t = db.rules["combat"].get("tactical", {})


func test_ap_rules_match_the_user() -> void:
	assert_eq(int(_t["ap_base_q"]), 24, "6 AP per turn")
	assert_eq(int(_t["move_cost_q"]), 1, "0.25 AP per tile")
	assert_eq(int(_t["move_cap_q"]), 4, "at most 1 AP (4 tiles) on movement")
	assert_eq(int(_t["attack_cost_q"]), 8, "a normal attack is 2 AP")
	assert_eq(int(_t["block_cost_q"]), 8)
	assert_eq(int(_t["throw_cost_q"]), 8)


func test_ap_grows_at_total_levels() -> void:
	var levels: Array = (_t["ap_total_levels"] as Array).map(func(v): return int(v))
	assert_eq(levels, [10, 25, 50, 75])


func test_round_and_initiative() -> void:
	assert_eq(int(_t["round_seconds"]), 6, "one round = 6 s of world time")
	assert_eq(_t["initiative"]["stat"], "speed", "Agility is the speed stat")
	assert_eq(_t["initiative"]["ties"], "rng")
	assert_eq(int(_t["monster"]["move_cap_q"]), 4)


func test_mana_regen_and_sleep() -> void:
	assert_eq(int(_t["mp"]["regen_minutes"]), 10, "1 MP per 10 minutes awake")
	assert_eq(float(_t["mp"]["sleep_refill"]), 1.0, "a full sleep refills MP")


func test_hp_scale_waits_for_m17_7() -> void:
	assert_eq(float(_t["hp_scale"]), 1.0)
