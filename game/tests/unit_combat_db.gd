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
	assert_eq(db.combat.enemies.keys().size(), 23)
	for id: String in ["goblin_grunt", "rock_crab", "razorbeak", "goblin_chieftain", "goblin_raid_leader",
			"adventurer_brawler", "adventurer_axeman", "goblin_feathered_chieftain", "zombie", "skeleton", "ghoul",
			"crypt_lord", "skinner", "antinium_worker", "antinium_soldier", "gazi_of_reim", "liscor_guardsman",
			"gnoll_hunter", "silverfang_gnoll_warrior", "snow_golem", "celum_mugger",
			"brilliant_swords_adventurer", "frenzied_hare_regular"]:
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


func test_bad_escape() -> void:
	var e := ToyCombat.enemies()
	e["goblin"]["escape"] = {"below": 0.0, "line": ""}
	e["crab"]["escape"] = {"line": "Gone."}
	var errs := _check(e, ToyCombat.items())
	assert_true(_has_error(errs, "goblin' escape: below must be > 0"))
	assert_true(_has_error(errs, "goblin' escape: line must be a non-empty string"))
	assert_true(_has_error(errs, "crab' escape: missing 'below'"))
	e["crab"]["escape"] = {"below": 0.5, "line": "The crab digs in and is gone."}
	e["goblin"].erase("escape")
	assert_eq(_check(e, ToyCombat.items()), [] as Array[String])


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


func _spawn_errors(spawn: Dictionary) -> Array[String]:
	var d := ToyCombat.db()
	var c := CombatDb.from_dicts(ToyCombat.enemies(), ToyCombat.items(), [spawn])
	return c.validate(d)


func _good_spawn() -> Dictionary:
	return {"id": "s", "area": "arena", "enemy": "goblin", "confidence": "guess", "count": [2, 3],
		"chance": 0.5, "cooldown_minutes": 60, "rects": [[10, 0, 4, 9]], "hours": [22, 6],
		"days": [1, 3], "when_flags": ["a"], "unless_flags": ["b"]}


func test_shipped_spawns() -> void:
	var db := DataDb.load_dir()
	var ids := db.combat.spawns.map(func(s: Dictionary) -> String: return s["id"])
	assert_eq(ids, ["crab_valley", "goblins_orchard", "goblins_hill", "razorbeak_nest", "crab_hill_unpatrolled"])
	var types := {}
	for s: Dictionary in db.combat.spawns:
		types[s["enemy"]] = true
		assert_eq(s["confidence"], "guess", s["id"])
	assert_eq(types.size(), 3, "all 3 enemy types spawn")


func test_good_toy_spawns_are_valid() -> void:
	assert_eq(_spawn_errors(_good_spawn()), [] as Array[String])
	var zone := _good_spawn()
	zone.erase("rects")
	zone["zone"] = "toy_corner"
	assert_eq(_spawn_errors(zone), [] as Array[String])
	var home := _good_spawn()
	home.erase("rects")
	home["home"] = [11, 4]
	home["count"] = [1, 1]
	assert_eq(_spawn_errors(home), [] as Array[String])


func test_bad_spawns() -> void:
	var cases := [
		[{"enemy": "dragon"}, "unknown enemy 'dragon'"],
		[{"count": [0, 2]}, "count must be at least 1"],
		[{"count": [3, 2]}, "count: must be [min, max]"],
		[{"chance": 2.0}, "chance: must be 0.0"],
		[{"cooldown_minutes": -1}, "cooldown_minutes"],
		[{"hours": [5, 5]}, "hours must be"],
		[{"days": [0, 2]}, "days must be"],
		[{"when_flags": "a"}, "when_flags must be a list"],
		[{"area": "moon"}, "unknown map 'moon'"],
		[{"rects": [[10, 0, 9, 9]]}, "rects must be"],
		[{"zone": "toy_corner"}, "exactly one of zone, rects or home"],
		[{"confidence": "sure"}, "confidence"],
	]
	for case: Array in cases:
		var bad := _good_spawn()
		bad.merge(case[0], true)
		assert_true(_has_error(_spawn_errors(bad), case[1]), case[1])
	var s := _good_spawn()
	s.erase("chance")
	assert_true(_has_error(_spawn_errors(s), "missing 'chance'"))
	s = _good_spawn()
	s.erase("rects")
	s["zone"] = "nest"
	assert_true(_has_error(_spawn_errors(s), "has no zone 'nest'"))
	s = _good_spawn()
	s.erase("rects")
	s["home"] = [6, 4]
	assert_true(_has_error(_spawn_errors(s), "home must be a walkable tile"))
	s["home"] = [11, 4]
	assert_true(_has_error(_spawn_errors(s), "exactly 1 monster"))
	var d := ToyCombat.db()
	var twice := CombatDb.from_dicts(ToyCombat.enemies(), ToyCombat.items(), [_good_spawn(), _good_spawn()])
	assert_true(_has_error(twice.validate(d), "duplicate id"))
