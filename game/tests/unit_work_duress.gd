extends GutTest
## M17.9 (ADR 0027 "M17.9"): hidden work duress. A hard working day pays more XP, like a hard
## fight: the crowd at the inn (cooking, serving, dishes) and the winter cold (travel, running,
## hauling, foraging, watch). Never below x1.0; capped at rules.xp.duress.cap. Fights keep their
## own duress (M17.8).

const EPS := 0.0001

var _db: DataDb
var _xp: Dictionary


func before_all() -> void:
	_db = DataDb.load_dir()
	_xp = _db.rules["xp"]


func _def(entries: Array) -> Dictionary:
	return {"duress": entries}


func test_a_straight_line_from_to() -> void:
	var d := _def([{"key": "guests", "from": 2, "to": 12, "max": 2.0}])
	assert_almost_eq(Xp.work_duress(d, {"guests": 0}, _xp), 1.0, EPS, "an empty inn: plain XP")
	assert_almost_eq(Xp.work_duress(d, {"guests": 2}, _xp), 1.0, EPS)
	assert_almost_eq(Xp.work_duress(d, {"guests": 7}, _xp), 1.5, EPS, "half way")
	assert_almost_eq(Xp.work_duress(d, {"guests": 12}, _xp), 2.0, EPS)
	assert_almost_eq(Xp.work_duress(d, {"guests": 40}, _xp), 2.0, EPS, "no more past `to`")
	assert_almost_eq(Xp.work_duress(d, {}, _xp), 1.0, EPS, "no context key: 1.0")
	assert_almost_eq(Xp.work_duress({}, {"guests": 12}, _xp), 1.0, EPS, "no duress list: 1.0")


func test_entries_multiply_up_to_the_cap() -> void:
	var d := _def([{"key": "a", "from": 0, "to": 1, "max": 1.5}, {"key": "b", "from": 0, "to": 1, "max": 1.2}])
	assert_almost_eq(Xp.work_duress(d, {"a": 1, "b": 1}, _xp), 1.8, EPS)
	var big := _def([{"key": "a", "from": 0, "to": 1, "max": 2.0}, {"key": "b", "from": 0, "to": 1, "max": 2.0}])
	assert_almost_eq(Xp.work_duress(big, {"a": 1, "b": 1}, _xp), float(_xp["duress"]["cap"]), EPS, "capped")
	assert_almost_eq(Xp.work_duress(big, {"a": 1, "b": 1}, {}), 2.0, EPS, "toy rules: cap 2.0")


func test_a_busy_inn_pays_more_for_cooking() -> void:
	var gs := GameState.new_game(1, _db)
	var quiet := Actions.perform(gs, _db, "cook_stew", {"context": {"guests": 1}})
	var gs2 := GameState.new_game(1, _db)
	var busy := Actions.perform(gs2, _db, "cook_stew", {"context": {"guests": 12}})
	assert_almost_eq(float(quiet["duress"]), 1.0, EPS)
	assert_almost_eq(float(busy["duress"]), 2.0, EPS, "a dinner rush")
	assert_true(float(busy["xp"]) > float(quiet["xp"]), "the rush pays more")
	assert_false((busy["context"] as Dictionary).has("cold"), "the record keeps the context as given")


func test_the_crowd_does_not_touch_other_work() -> void:
	var gs := GameState.new_game(1, _db)
	var r := Actions.perform(gs, _db, "talk_with_guest", {"context": {"guests": 20}})
	assert_almost_eq(float(r["duress"]), 1.0, EPS, "talking is not harder in a crowd")


func test_the_winter_cold_pays_more_for_outdoor_work() -> void:
	var gs := GameState.new_game(1, _db)
	assert_false(_db.maps.is_indoor(gs.player.area), "the start is outdoors")
	var warm := Actions.perform(gs, _db, "carry_water")
	gs.flags[_db.rules["winter"]["flag"]] = true
	assert_eq(Winter.status(gs, _db), "cold")
	var cold := Actions.perform(gs, _db, "carry_water")
	assert_almost_eq(float(warm["duress"]), 1.0, EPS, "no winter: plain XP")
	assert_almost_eq(float(cold["duress"]), 1.5, EPS, "hauling water in the snow")
	var inside := Actions.perform(gs, _db, "sweep_floor")
	assert_almost_eq(float(inside["duress"]), 1.0, EPS, "sweeping has no cold entry")


func test_a_fight_keeps_its_own_duress() -> void:
	var gs := GameState.new_game(1, _db)
	gs.flags[_db.rules["winter"]["flag"]] = true
	var r := Actions.perform(gs, _db, "travel", {"duress": 0.5})
	assert_almost_eq(float(r["duress"]), 0.5, EPS, "a caller's duress (Combat.end_fight) wins")


func test_every_shipped_entry_is_well_formed() -> void:
	assert_eq(_db.errors, [] as Array[String])
	var n := 0
	for id: String in _db.actions:
		for e: Dictionary in _db.actions[id].get("duress", []):
			assert_true(["guests", "cold"].has(e["key"]), "%s: a known context key" % id)
			n += 1
	assert_gte(n, 10, "crowd and cold entries ship")


func test_bad_entries_are_load_errors() -> void:
	var a := {"name": "A", "minutes": 10, "base_xp": 5, "risk": 0.0, "tags": {"cooking": 1.0},
		"duress": [{"key": "guests", "from": 5, "to": 5, "max": 2.0}, {"key": "cold", "from": 0, "to": 1, "max": 0.5},
			{"key": "x"}]}
	var db := DataDb.from_dicts({"cooking": ""}, {"a": a}, _db.rules)
	assert_true(db.errors.any(func(x: String) -> bool: return x.contains("to must be more than from")))
	assert_true(db.errors.any(func(x: String) -> bool: return x.contains("never lowers XP")))
	assert_true(db.errors.any(func(x: String) -> bool: return x.contains("needs key, from, to and max")))
