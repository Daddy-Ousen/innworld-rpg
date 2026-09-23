extends GutTest


func _db(events: Dictionary, npcs: Dictionary = {}) -> CanonDb:
	return CanonDb.from_dicts(npcs, {}, events)


func test_order_puts_dependencies_first_then_earliest_then_id() -> void:
	var c := _db({
		"b.late_root": ToyCanon.event(1, 1),
		"a.child": ToyCanon.event(1, 1, {"depends_on": ["b.late_root"]}),
		"c.day2": ToyCanon.event(2, 2),
		"a.day2": ToyCanon.event(2, 2),
	})
	assert_eq(c.errors, [] as Array[String])
	assert_eq(c.order, ["b.late_root", "a.child", "a.day2", "c.day2"] as Array[String])
	assert_eq(c.dependents["b.late_root"], ["a.child"])
	assert_eq(c.dependents["a.child"], [])


func test_mutate_targets_are_alt_only() -> void:
	var c := _db({
		"e.main": ToyCanon.event(1, 1, {"on_fail": ["mutate:e.alt", "cancel"]}),
		"e.alt": ToyCanon.event(1, 1),
	})
	assert_true(c.is_valid())
	assert_true(c.alt_only.has("e.alt"))
	assert_false(c.alt_only.has("e.main"))


func test_bad_references_are_errors() -> void:
	var c := _db({
		"e.one": ToyCanon.event(1, 1, {
			"depends_on": ["e.nope"],
			"on_fail": ["mutate:e.gone", "delay"],
			"roles": {"r": ToyCanon.role(["ghost"], [])},
			"requires": ToyCanon.req(["phantom"]),
			"effects": {"kill": ["shade"]},
		}),
	})
	var text := "\n".join(c.errors)
	for part in ["e.nope", "e.gone", "end in 'cancel'", "ghost", "phantom", "shade"]:
		assert_string_contains(text, part)


func test_missing_field_is_an_error() -> void:
	var ev := ToyCanon.event(1, 1)
	ev.erase("on_fail")
	assert_string_contains("\n".join(_db({"e.x": ev}).errors), "missing 'on_fail'")


func test_cycle_is_an_error_and_order_is_still_complete() -> void:
	var c := _db({
		"e.a": ToyCanon.event(1, 1, {"depends_on": ["e.b"]}),
		"e.b": ToyCanon.event(1, 1, {"depends_on": ["e.a"]}),
		"e.c": ToyCanon.event(1, 1),
	})
	assert_string_contains("\n".join(c.errors), "cycle")
	assert_eq(c.order, ["e.c", "e.a", "e.b"] as Array[String])


func test_missing_root_gives_an_empty_canon() -> void:
	var c := CanonDb.load_root("res://no_such_dir")
	assert_true(c.is_valid())
	assert_true(c.events.is_empty())


func test_shipped_book1_loads() -> void:
	var c := CanonDb.load_root()
	assert_eq(c.errors, [] as Array[String])
	assert_true(c.events.has("b1.erin_arrives"))
	assert_true(c.npcs.has("erin_solstice"))
	assert_true(c.locations.has("wandering_inn"))
	assert_eq(c.order.size(), c.events.size())
	assert_eq(c.order[0], "b1.erin_arrives")
