extends GutTest

var _rules: Dictionary


func before_all() -> void:
	_rules = DataDb.load_dir().rules


func _action(tags: Dictionary) -> Dictionary:
	return {"name": "X", "minutes": 10, "base_xp": 5, "risk": 0.0, "tags": tags}


func test_shipped_data_is_valid() -> void:
	var db := DataDb.load_dir()
	assert_eq(db.errors, [] as Array[String])
	assert_gte(db.actions.size(), 30)
	assert_true(db.tags.has("cooking.stew"))


func test_unknown_action_tag_is_an_error() -> void:
	var db := DataDb.from_dicts({"cooking": ""}, {"a": _action({"cookin": 1.0})}, _rules)
	assert_false(db.is_valid())
	assert_string_contains(db.errors[0], "cookin")


func test_unknown_context_tag_is_an_error() -> void:
	var a := _action({"cooking": 1.0})
	a["context"] = [{"key": "guests", "min": 5, "add_tags": {"hospitalty": 0.5}}]
	var db := DataDb.from_dicts({"cooking": ""}, {"a": a}, _rules)
	assert_false(db.is_valid())
	assert_string_contains(db.errors[0], "hospitalty")


func test_context_rule_needs_exactly_one_test() -> void:
	var a := _action({"cooking": 1.0})
	a["context"] = [{"key": "guests", "min": 5, "max": 9, "add_tags": {"cooking": 0.5}}]
	var db := DataDb.from_dicts({"cooking": ""}, {"a": a}, _rules)
	assert_false(db.is_valid())


func test_missing_field_is_an_error() -> void:
	var a := _action({"cooking": 1.0})
	a.erase("minutes")
	var db := DataDb.from_dicts({"cooking": ""}, {"a": a}, _rules)
	assert_false(db.is_valid())
	assert_string_contains(db.errors[0], "minutes")


func test_risk_out_of_range_is_an_error() -> void:
	var a := _action({"cooking": 1.0})
	a["risk"] = 1.5
	var db := DataDb.from_dicts({"cooking": ""}, {"a": a}, _rules)
	assert_false(db.is_valid())


func test_tag_without_parent_is_an_error() -> void:
	var db := DataDb.from_dicts({"cooking.stew": ""}, {}, _rules)
	assert_false(db.is_valid())


func test_missing_rule_is_an_error() -> void:
	var rules := _rules.duplicate(true)
	(rules["clock"] as Dictionary).erase("wake_minute")
	var db := DataDb.from_dicts({}, {}, rules)
	assert_false(db.is_valid())
	assert_string_contains(db.errors[0], "wake_minute")
