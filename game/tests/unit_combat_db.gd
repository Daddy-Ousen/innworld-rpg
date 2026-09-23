extends GutTest
## Combat data checks (M5.1, ADR 0010): data/enemies.json, data/items.json
## and the rules' knock-out wake spots.


func _check(enemies: Dictionary, items: Dictionary, d: DataDb = null) -> Array[String]:
	if d == null:
		d = ToyCombat.db()
	var c := CombatDb.from_dicts(enemies, items)
	return c.validate(d)


func _has_error(errors: Array[String], part: String) -> bool:
	for e in errors:
		if e.contains(part):
			return true
	return false


func test_shipped_combat_data_is_valid() -> void:
	var db := DataDb.load_dir()
	assert_eq(db.combat.errors, [] as Array[String])
	assert_eq(db.combat.enemies.keys().size(), 3)
	for id: String in ["goblin_grunt", "rock_crab", "razorbeak"]:
		assert_true(db.combat.enemies.has(id), id)
	for id: String in ["chair", "rolling_pin", "stone", "seed_core"]:
		assert_true(db.combat.items.has(id), id)
	assert_has(db.combat.enemies["rock_crab"]["scared_by"], "repels_crab")


func test_toy_data_is_valid() -> void:
	assert_eq(_check(ToyCombat.enemies(), ToyCombat.items()), [] as Array[String])


func test_missing_enemy_field() -> void:
	var e := ToyCombat.enemies()
	e["goblin"].erase("hp")
	assert_true(_has_error(_check(e, ToyCombat.items()), "missing 'hp'"))


func test_bad_enemy_values() -> void:
	var e := ToyCombat.enemies()
	e["goblin"]["damage"] = [3, 1]
	e["goblin"]["behaviour"] = "swarm"
	e["goblin"]["confidence"] = "sure"
	e["goblin"]["danger"] = 1.5
	e["goblin"]["act_seconds"] = 0
	var errs := _check(e, ToyCombat.items())
	assert_true(_has_error(errs, "damage"))
	assert_true(_has_error(errs, "behaviour"))
	assert_true(_has_error(errs, "confidence"))
	assert_true(_has_error(errs, "danger"))
	assert_true(_has_error(errs, "act_seconds"))


func test_scared_by_needs_an_item_tag_and_scare_turns() -> void:
	var e := ToyCombat.enemies()
	e["goblin"]["scared_by"] = ["garlic"]
	e["crab"].erase("scare_turns")
	var errs := _check(e, ToyCombat.items())
	assert_true(_has_error(errs, "'garlic'"))
	assert_true(_has_error(errs, "scare_turns"))


func test_bad_ranged_and_ambush() -> void:
	var e := ToyCombat.enemies()
	e["goblin"]["ranged"] = {"range": 1, "damage": [1, 1], "chance": 2.0}
	e["crab"]["ambush"] = {"spot_radius": 0}
	var errs := _check(e, ToyCombat.items())
	assert_true(_has_error(errs, "ranged: range"))
	assert_true(_has_error(errs, "ranged chance"))
	assert_true(_has_error(errs, "ambush: missing 'hit_bonus'"))


func test_bad_items() -> void:
	var it := ToyCombat.items()
	it["stick"]["throw_range"] = 0
	it["vase"]["break_chance"] = 1.5
	it["stink"].erase("tags")
	var errs := _check(ToyCombat.enemies(), it)
	assert_true(_has_error(errs, "throw_range"))
	assert_true(_has_error(errs, "break_chance"))
	assert_true(_has_error(errs, "item 'stink': missing 'tags'"))


func test_wake_spot_must_be_a_walkable_tile() -> void:
	var d := ToyCombat.db()
	d.rules["combat"]["knockout"]["wake"] = {
		"field": {"area": "town", "pos": [0, 0]},
		"moon": {"area": "town", "pos": [1, 2]},
		"town": {"area": "nowhere", "pos": [1, 1]},
	}
	var errs := _check(ToyCombat.enemies(), ToyCombat.items(), d)
	assert_true(_has_error(errs, "'field': pos must be a walkable tile"))
	assert_true(_has_error(errs, "'moon': unknown area"))
	assert_true(_has_error(errs, "unknown wake area 'nowhere'"))


func test_a_missing_file_gives_empty_data() -> void:
	var c := CombatDb.load_dir("res://no_such_dir")
	assert_true(c.is_empty())
	assert_eq(c.errors, [] as Array[String])
