extends GutTest

const EPS := 0.000001
var _db: DataDb


func before_all() -> void:
	_db = ToyData.db()


func _rules() -> Dictionary:
	return _db.rules["levels"]


func test_toy_data_is_valid() -> void:
	assert_eq(_db.errors, [] as Array[String])


func test_xp_to_next_grows_exponentially() -> void:
	assert_almost_eq(Levels.xp_to_next(1, _rules()), 100.0, EPS)
	assert_almost_eq(Levels.xp_to_next(2, _rules()), 200.0, EPS)
	assert_almost_eq(Levels.xp_to_next(4, _rules()), 800.0, EPS)


func test_capstones_come_from_rules() -> void:
	assert_true(Levels.is_capstone(3, _rules()))
	assert_false(Levels.is_capstone(2, _rules()))
	var shipped: Dictionary = DataDb.load_dir().rules["levels"]
	assert_true(Levels.is_capstone(10, shipped))
	assert_true(Levels.is_capstone(20, shipped))


func test_one_class_gets_xp_by_match() -> void:
	var stew := {"cooking.stew": 1.0}
	assert_almost_eq(float(Levels.class_shares(stew, ["cook"], _db)["cook"]), 1.0, EPS)
	assert_almost_eq(float(Levels.class_shares(stew, ["innkeeper"], _db)["innkeeper"]), 0.5, EPS)


func test_more_matching_classes_dilute_each_other() -> void:
	var shares := Levels.class_shares({"cooking.stew": 1.0}, ["cook", "innkeeper", "warrior"], _db)
	assert_almost_eq(float(shares["cook"]), 1.0 / 1.5, EPS)
	assert_almost_eq(float(shares["innkeeper"]), 0.5 / 1.5, EPS)
	assert_false(shares.has("warrior"), "no match → no share")


func test_level_up_spends_xp_over_several_levels() -> void:
	var gs := GameState.new()
	ToyData.give_class(gs, "cook", 1, 150.0)
	var gained := Levels.level_up(gs.progression, "cook", _rules())
	assert_eq(gained, [2] as Array[int])
	assert_almost_eq(float(gs.progression.classes["cook"]["xp"]), 50.0, EPS)


func test_capstone_needs_breakthrough() -> void:
	var gs := GameState.new()
	ToyData.give_class(gs, "cook", 1, 350.0)
	var p := gs.progression
	assert_eq(Levels.level_up(p, "cook", _rules()), [2] as Array[int])
	assert_eq(p.level_of("cook"), 2, "level 3 is a capstone")
	assert_true(Levels.is_blocked(p, "cook", _rules()))
	assert_almost_eq(float(p.classes["cook"]["xp"]), 250.0, EPS, "XP keeps building")

	assert_true(ClassSystem.grant_breakthrough(gs, "cook"))
	assert_eq(Levels.level_up(p, "cook", _rules()), [3] as Array[int])
	assert_false(p.breakthroughs.has("cook"), "a breakthrough is used up")
	assert_almost_eq(float(p.classes["cook"]["xp"]), 50.0, EPS)


func test_breakthrough_needs_a_held_class() -> void:
	assert_false(ClassSystem.grant_breakthrough(GameState.new(), "cook"))


# --- M17.7: the cost follows the total level, a gentler late curve, the hidden cap ---

func test_one_class_pays_the_same_as_the_curve() -> void:
	var gs := GameState.new()
	ToyData.give_class(gs, "cook", 2, 0.0)
	assert_almost_eq(Levels.cost(gs.progression, _rules()), Levels.xp_to_next(2, _rules()), EPS)


func test_a_second_class_makes_every_level_cost_more() -> void:
	var gs := GameState.new()
	ToyData.give_class(gs, "cook", 2, 0.0)
	ToyData.give_class(gs, "warrior", 1, 0.0)
	assert_eq(gs.progression.total_level(), 3)
	assert_almost_eq(Levels.cost(gs.progression, _rules()), Levels.xp_to_next(3, _rules()), EPS, "total 3, not class 2")


func test_level_up_charges_the_total_level_price() -> void:
	var gs := GameState.new()
	ToyData.give_class(gs, "cook", 1, 0.0)
	ToyData.give_class(gs, "warrior", 1, 150.0)  # total 2: the next level costs 200, not the class price 100
	assert_eq(Levels.level_up(gs.progression, "warrior", _rules()), [] as Array[int])
	gs.progression.classes["warrior"]["xp"] = 260.0
	assert_eq(Levels.level_up(gs.progression, "warrior", _rules()), [2] as Array[int])
	assert_almost_eq(float(gs.progression.classes["warrior"]["xp"]), 60.0, EPS, "200 paid")


func test_the_curve_is_gentler_after_late_from() -> void:
	var r := {"base_xp": 40, "growth": 1.25, "late_from": 10, "late_growth": 1.12}
	assert_almost_eq(Levels.xp_to_next(1, r), 40.0, EPS)
	assert_almost_eq(Levels.xp_to_next(10, r), 40.0 * pow(1.25, 9), EPS, "level 10 is on the old curve")
	assert_almost_eq(Levels.xp_to_next(11, r), 40.0 * pow(1.25, 9) * 1.12, EPS)
	assert_almost_eq(Levels.xp_to_next(20, r), 40.0 * pow(1.25, 9) * pow(1.12, 10), EPS)
	assert_lt(Levels.xp_to_next(30, r), 40.0 * pow(1.25, 29) / 5.0, "far below the old curve")
	var shipped: Dictionary = DataDb.load_dir().rules["levels"]
	assert_eq(int(shipped["late_from"]), 10)
	assert_eq(int(shipped["total_cap"]), 100)


func test_no_late_from_means_one_growth() -> void:
	assert_almost_eq(Levels.xp_to_next(12, _rules()), 100.0 * pow(2.0, 11), 0.001)


func test_the_hidden_cap_stops_levels_and_offers() -> void:
	var gs := GameState.new()
	var r := _rules().duplicate()
	r["total_cap"] = 3
	ToyData.give_class(gs, "cook", 2, 100000.0)
	ToyData.give_class(gs, "warrior", 1, 0.0)
	assert_true(Levels.at_cap(gs.progression, r))
	assert_eq(Levels.level_up(gs.progression, "cook", r), [] as Array[int], "XP stays")
	assert_almost_eq(float(gs.progression.classes["cook"]["xp"]), 100000.0, EPS)
	assert_false(Levels.is_blocked(gs.progression, "cook", r))
	var below := _rules().duplicate()
	below["total_cap"] = 4
	assert_false(Levels.at_cap(gs.progression, below))
	assert_false(Levels.at_cap(gs.progression, _rules()), "no total_cap: no cap")


func test_no_class_is_offered_at_the_cap() -> void:
	var gs := GameState.new()
	assert_true(ClassSystem.can_offer(gs, _db, "cook"))
	_db.rules["levels"]["total_cap"] = 1
	ToyData.give_class(gs, "warrior", 1, 0.0)
	assert_false(ClassSystem.can_offer(gs, _db, "cook"))
	_db.rules["levels"].erase("total_cap")
