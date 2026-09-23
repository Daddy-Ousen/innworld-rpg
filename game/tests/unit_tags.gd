extends GutTest


func test_parent_of() -> void:
	assert_eq(Tags.parent_of("cooking.stew"), "cooking")
	assert_eq(Tags.parent_of("a.b.c"), "a.b")
	assert_eq(Tags.parent_of("cooking"), "")


func test_matches_self_and_children_only() -> void:
	assert_true(Tags.matches("cooking", "cooking"))
	assert_true(Tags.matches("cooking", "cooking.stew"))
	assert_false(Tags.matches("cook", "cooking"))
	assert_false(Tags.matches("cooking.stew", "cooking"))


func test_match_weight_uses_most_specific_key() -> void:
	var w := {"cooking": 0.5, "cooking.stew": 2.0}
	assert_eq(Tags.match_weight(w, "cooking.stew"), 2.0)
	assert_eq(Tags.match_weight(w, "cooking.stew.beef"), 2.0)
	assert_eq(Tags.match_weight(w, "cooking.pasta"), 0.5)
	assert_eq(Tags.match_weight(w, "combat"), 0.0)


func test_normalize_sums_to_one() -> void:
	var n := Tags.normalize({"a": 1.0, "b": 3.0})
	assert_almost_eq(float(n["a"]), 0.25, 0.000001)
	assert_almost_eq(float(n["b"]), 0.75, 0.000001)
	assert_eq(Tags.normalize({}), {})


func test_overlap_counts_matching_weight_once() -> void:
	var tags := {"cooking.stew": 0.5, "combat.melee": 0.3, "social": 0.2}
	assert_almost_eq(Tags.overlap(tags, ["cooking"]), 0.5, 0.000001)
	assert_almost_eq(Tags.overlap(tags, ["cooking", "cooking.stew"]), 0.5, 0.000001)
	assert_almost_eq(Tags.overlap(tags, ["cooking", "combat"]), 0.8, 0.000001)
	assert_eq(Tags.overlap(tags, []), 0.0)


func test_validate_registry_finds_missing_parent_and_bad_names() -> void:
	assert_eq(Tags.validate_registry({"a": "", "a.b": ""}), [] as Array[String])
	var errors := Tags.validate_registry({"x.y": "", "Bad Tag": ""})
	assert_eq(errors.size(), 2)
	assert_string_contains(errors[0], "parent")
