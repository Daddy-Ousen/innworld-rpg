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
