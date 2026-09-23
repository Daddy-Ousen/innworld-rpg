extends GutTest
## BehaviourDb (ADR 0008): data/npc_behaviour.json loads and every bad
## entry is reported.


func _errors(entries: Dictionary, npcs: Dictionary) -> String:
	var d := ToyNpcs.db()
	d.behaviour = BehaviourDb.from_dicts(entries, npcs)
	return "\n".join(d.behaviour.validate(d))


func _one_goal(g: Dictionary) -> Dictionary:
	return {"guard": ToyNpcs.npc([g])}


func test_shipped_behaviour_is_valid() -> void:
	var db := DataDb.load_dir()
	assert_eq(db.behaviour.errors, [] as Array[String])
	assert_gte(db.behaviour.npcs.size(), 13, "about 13 NPCs")
	for id: String in db.behaviour.npcs:
		assert_true(db.canon.npcs.has(id), id)
	assert_false(db.behaviour.npcs.has("cave_dragon"), "the Dragon stays in its lair")


func test_toy_behaviour_is_valid() -> void:
	assert_eq(_errors(ToyNpcs.entries(), ToyNpcs.behaviour()), "")


func test_unknown_npc_and_goal() -> void:
	var e := _errors(ToyNpcs.entries(), {"ghost": ToyNpcs.npc([
			ToyNpcs.goal("haunt", 1, {"target": {"off_map": "city"}})])})
	assert_string_contains(e, "'ghost': unknown canon npc")
	assert_string_contains(e, "goal must be one of")


func test_bad_numbers() -> void:
	var e := _errors(ToyNpcs.entries(), _one_goal({"goal": "work", "base": 0,
			"hours": [[8, 8, 1]], "days": [3, 2], "target": {"off_map": "city"}}))
	assert_string_contains(e, "base must be")
	assert_string_contains(e, "hours must be")
	assert_string_contains(e, "days must be")


func test_bad_targets() -> void:
	var e := _errors(ToyNpcs.entries(), {"guard": ToyNpcs.npc([
		ToyNpcs.goal("work", 1, {"target": {"area": "town", "pos": [5, 1]}}),
		ToyNpcs.goal("work", 1, {"target": {"area": "town", "pos": [7, 2]}}),
		ToyNpcs.goal("work", 1, {"target": {"area": "moon", "pos": [1, 1]}}),
		ToyNpcs.goal("work", 1, {"target": {"area": "town", "route": [[1, 1]]}}),
		ToyNpcs.goal("work", 1, {"target": {"off_map": "sea"}}),
		ToyNpcs.goal("work", 1, {}),
	])})
	assert_string_contains(e, "goal 0 target: tile (5, 1) in 'town' is not walkable")
	assert_string_contains(e, "goal 1 target: tile (7, 2) in 'town' is an exit")
	assert_string_contains(e, "unknown map 'moon'")
	assert_string_contains(e, "at least 2 points")
	assert_string_contains(e, "off_map must name a place")
	assert_string_contains(e, "goal 5: needs a target")


func test_bad_entries() -> void:
	var e := _errors({"city": {"town": [5, 1]}, "sea": {"moon": [0, 0]}}, {})
	assert_string_contains(e, "entries 'city': tile (5, 1)")
	assert_string_contains(e, "entries 'sea': unknown map 'moon'")
