extends GutTest
## M17.7 (ADR 0027): rules.combat.tactical.hp_scale multiplies maximum HP of the player, monsters and
## NPCs, and the flat HP numbers outside fights (bandage, potions, cold, fairy snow, traps). Damage,
## armor and accuracy stay. Toy arena (ToyCombat): goblin hp 8, crab hp 30 (armor 4); the toy scale is 1.0
## by default, each test sets its own.

var _db: DataDb


func before_each() -> void:
	_db = ToyCombat.db()
	ToyCombat.tactical(_db)


func _scale(x: float) -> void:
	_db.rules["combat"]["tactical"]["hp_scale"] = x


func _game() -> GameState:
	var gs := ToyCombat.new_game(_db, 1)
	ToyCombat.to_arena(gs, _db, Vector2i(2, 4))
	return gs


func test_helpers() -> void:
	_scale(2.0)
	assert_eq(Combat.hp_scale(_db), 2.0)
	assert_eq(Combat.scaled_hp(_db, 6), 12)
	assert_eq(Combat.scaled_hp(_db, 1), 2)
	_scale(0.1)
	assert_eq(Combat.scaled_hp(_db, 3), 1, "at least 1")
	_scale(1.5)
	assert_eq(Combat.scaled_hp(_db, 5), 8, "rounded")


func test_the_shipped_scale_is_read_from_rules() -> void:
	var real := DataDb.load_dir()
	assert_eq(Combat.hp_scale(real), float(real.rules["combat"]["tactical"]["hp_scale"]))


func test_player_max_hp_doubles() -> void:
	var gs := _game()
	var one := Stats.max_hp(gs, _db)
	_scale(2.0)
	assert_eq(Stats.max_hp(gs, _db), one * 2)
	assert_eq(Combat.hp(gs, _db), one * 2, "a full player (hp -1) is full at the new maximum")


func test_a_monster_spawns_with_scaled_hp_and_its_ratios_follow() -> void:
	_scale(2.0)
	var gs := _game()
	var g := ToyCombat.spawn(gs, _db, "goblin", Vector2i(2, 7))
	assert_eq(int(gs.combat.monsters[g]["hp"]), 16)
	assert_eq(Combat.foe_max_hp(_db, _db.combat.enemies["goblin"]), 16)
	# flee_below 0.5: not beaten at 9 of 16, beaten at 7
	gs.combat.monsters[g]["hp"] = 9
	assert_false(MonsterSim._beaten(_db, gs.combat, gs.combat.monsters[g], _db.combat.enemies["goblin"]))
	gs.combat.monsters[g]["hp"] = 7
	assert_true(MonsterSim._beaten(_db, gs.combat, gs.combat.monsters[g], _db.combat.enemies["goblin"]))


func test_damage_is_not_scaled() -> void:
	_scale(2.0)
	ToyCombat.always_hit(_db)
	var gs := _game()
	var g := ToyCombat.spawn(gs, _db, "goblin", Vector2i(2, 5))
	Commands.wait(gs, _db, 0)
	FightBot.attack(gs, _db, "s")
	var m: Dictionary = gs.combat.monsters[g]
	assert_lt(int(m["hp"]), 16)
	assert_gte(int(m["hp"]), 16 - 6, "fists 1-2 plus strength: a few HP, not doubled")


func test_npc_fight_stats_scale_hp_only() -> void:
	var before: Dictionary = NpcReact.stats(_db, "guard").duplicate()
	_scale(2.0)
	var after := NpcReact.stats(_db, "guard")
	assert_eq(int(after["hp"]), int(before["hp"]) * 2)
	assert_eq(int(after["accuracy"]), int(before["accuracy"]))
	assert_eq(int(after["armor"]), int(before["armor"]))
	assert_eq(after["damage"], before["damage"])


func test_a_bandage_heals_by_the_scale() -> void:
	_scale(2.0)
	var gs := _game()
	Combat.set_hp(gs, _db, 4)
	var base := int(_db.rules["combat"]["heal_actions"]["bandage_wound"])
	Combat.heal_after_action(gs, _db, {"action_id": "bandage_wound"})
	assert_eq(Combat.hp(gs, _db), 4 + base * 2)
