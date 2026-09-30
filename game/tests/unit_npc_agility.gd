extends GutTest
## M17.7 (ADR 0027): an NPC fighter may have its own "agility" in the combat block of npc_behaviour.json;
## the turn order reads it, else initiative.npc_default. BehaviourDb checks it.

var _db: DataDb


func before_each() -> void:
	_db = DataDb.load_dir()


func test_the_shipped_data_is_valid() -> void:
	assert_eq(_db.errors.size(), 0, "\n".join(_db.errors))


func test_an_npc_without_agility_gets_the_default() -> void:
	var gs := GameState.new_game(1, _db)
	_db.behaviour.npcs["klbkch"]["combat"].erase("agility")
	assert_eq(Encounter.agility(gs, _db, Encounter.NPC + "klbkch"),
			int(_db.rules["combat"]["tactical"]["initiative"]["npc_default"]))


func test_an_npc_own_agility_is_read() -> void:
	var gs := GameState.new_game(1, _db)
	_db.behaviour.npcs["klbkch"]["combat"]["agility"] = 7
	assert_eq(Encounter.agility(gs, _db, Encounter.NPC + "klbkch"), 7)


func test_the_shipped_fighters_have_their_own_numbers() -> void:
	var gs := GameState.new_game(1, _db)
	var seen := {}
	for n: String in _db.behaviour.npcs:
		var c := _db.behaviour.combat_of(n)
		if c.is_empty():
			continue
		assert_true(c.has("agility"), "%s has an agility" % n)
		seen[Encounter.agility(gs, _db, Encounter.NPC + n)] = true
	assert_gt(seen.size(), 2, "not one number for everybody")
	assert_gt(Encounter.agility(gs, _db, Encounter.NPC + "klbkch"), Encounter.agility(gs, _db, Encounter.NPC + "zel_shivertail"))


func test_bad_agility_is_refused() -> void:
	var s := {"hp": 10, "accuracy": 3, "evasion": 3, "armor": 0, "damage": [1, 2], "agility": 0}
	assert_string_contains("\n".join(BehaviourDb.check_fight_stats("x", s)), "agility must be a number >= 1")
	s["agility"] = "fast"
	assert_string_contains("\n".join(BehaviourDb.check_fight_stats("x", s)), "agility")
	s["agility"] = 4
	assert_eq(BehaviourDb.check_fight_stats("x", s).size(), 0)
