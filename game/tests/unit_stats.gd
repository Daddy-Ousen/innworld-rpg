extends GutTest
## Player stats (M5.1, ADR 0010): base stats per race, stat_mod skills, max HP.

var _db: DataDb


func before_each() -> void:
	_db = ToyCombat.db()


func _hold(gs: GameState, skill: String) -> void:
	gs.progression.skills.append({"id": skill, "class": "cook", "level": 1, "day": 1})


func test_default_base_stats_and_max_hp() -> void:
	var gs := ToyCombat.new_game(_db)
	var s := Stats.of(gs, _db)
	for stat: String in ["strength", "dexterity", "endurance", "perception", "speed"]:
		assert_eq(s[stat], 3, stat)
	assert_eq(Stats.max_hp(gs, _db), 20, "11 + 3 × 3")


func test_a_race_can_have_its_own_base_stats() -> void:
	_db.rules["combat"]["base_stats"]["drake"] = {"strength": 5, "dexterity": 3, "endurance": 4,
		"perception": 3, "speed": 3}
	var gs := ToyCombat.new_game(_db)
	gs.race = "drake"
	assert_eq(Stats.get_stat(gs, _db, "strength"), 5)
	assert_eq(Stats.max_hp(gs, _db), 23)


func test_stat_mod_skills_add_up() -> void:
	_db.skills["tough"] = {"name": "[Tough]", "rarity": "common", "pools": [], "tag_affinity": {},
		"effects": [{"type": "stat_mod", "stat": "endurance", "value": 2},
			{"type": "stat_mod", "stat": "presence", "value": 1}], "canon_ref": {}}
	var gs := ToyCombat.new_game(_db)
	_hold(gs, "knife_work")  # dexterity +1 (ToyData)
	_hold(gs, "tough")
	var s := Stats.of(gs, _db)
	assert_eq(s["dexterity"], 4)
	assert_eq(s["endurance"], 5)
	assert_eq(s["presence"], 1, "a stat with no base starts at 0")
	assert_eq(Stats.max_hp(gs, _db), 26)
	assert_eq(Combat.hp(gs, _db), 26, "full HP follows the new max")


func test_real_skills_use_known_stats() -> void:
	var real := DataDb.load_dir()
	var known := ["strength", "dexterity", "endurance", "perception", "speed", "presence", "intellect"]
	for id: String in real.skills:
		for e: Dictionary in real.skills[id]["effects"]:
			if e["type"] == "stat_mod":
				assert_has(known, e["stat"], "skill %s" % id)
