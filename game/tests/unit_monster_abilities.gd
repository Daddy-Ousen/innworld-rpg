extends GutTest
## M17.7 (ADR 0027): enemy abilities. The "shooter" ability replaces the derived rule of M17.6; the
## "leap" ability jumps beside a target that is not side by side (range, sight, AP, cooldown in rounds).
## M32.3 (ADR 0044): "fear" takes the player's AP when the monster is in sight, "bile" poisons for some rounds,
## "command" gives tagged foes near the commander more accuracy and stops them running.
## Toy arena (ToyCombat): 14×9 grass, a wall (cover "wall") at x 6, y 3–5. The toy goblin: hp 8, hits for 2.

var _db: DataDb


func before_each() -> void:
	_db = ToyCombat.db()
	ToyCombat.tactical(_db)
	_db.maps.tiles["wall"]["cover"] = Cover.WALL
	_db.rules["combat"]["hp_base"] = 500
	var g: Dictionary = _db.combat.enemies["goblin"]
	g["lose_radius"] = 99
	g["chase_turns"] = 99
	g.erase("ranged")
	g["abilities"] = [{"kind": "leap", "name": "Leap", "range": 5, "ap_q": 8, "cooldown": 3}]


func _game(at: Vector2i) -> GameState:
	var gs := ToyCombat.new_game(_db)
	ToyCombat.to_arena(gs, _db, at)
	return gs


func _pos(gs: GameState, id: String) -> Vector2i:
	return CombatState.pos_of(gs.combat.monsters[id])


func _text(gs: GameState) -> String:
	return "\n".join(gs.combat.lines)


# --- data ---

func test_the_shipped_abilities_are_valid_and_placed() -> void:
	var real := DataDb.load_dir()
	assert_eq(real.errors.size(), 0, "\n".join(real.errors))
	for id in ["goblin_lord_archer", "goblin_lord_shaman"]:
		assert_true(MonsterAbilities.is_shooter(real.combat.enemies[id]), id)
	for id in ["goblin_grunt", "goblin_chieftain", "crypt_lord", "rock_crab"]:
		assert_false(MonsterAbilities.is_shooter(real.combat.enemies[id]), id)
	assert_false(MonsterAbilities.find(real.combat.enemies["ghoul"], MonsterAbilities.LEAP).is_empty())
	assert_false(MonsterAbilities.find(real.combat.enemies["shield_spider"], MonsterAbilities.LEAP).is_empty())
	assert_true(MonsterAbilities.find(real.combat.enemies["rock_crab"], MonsterAbilities.LEAP).is_empty(), "no shell, no leap")
	# M32.3: the bosses
	assert_false(MonsterAbilities.find(real.combat.enemies["skinner"], MonsterAbilities.FEAR).is_empty(), "Skinner's red eyes")
	assert_false(MonsterAbilities.find(real.combat.enemies["crypt_lord"], MonsterAbilities.BILE).is_empty(), "the Crypt Lord's bile")
	assert_false(real.combat.enemies["crypt_lord"].has("ranged"), "the bile replaces the old thrown stone")
	var lord := MonsterAbilities.find(real.combat.enemies["goblin_lord"], MonsterAbilities.COMMAND)
	assert_eq(String(lord.get("tag", "")), "goblin", "the Goblin Lord commands Goblins")
	assert_true(real.combat.enemies["goblin_lord"].has("escape"), "the Goblin Lord cannot die on the map")
	var regrika: Dictionary = real.combat.enemies["regrika_blackpaw"]
	assert_false(MonsterAbilities.find(regrika, MonsterAbilities.LEAP).is_empty(), "Regrika charges")
	assert_true(int(regrika.get("agility", 0)) >= 8, "Regrika is fast")


func _errors(abilities: Variant, ranged: bool = true) -> String:
	var e := {"abilities": abilities}
	if ranged:
		e["ranged"] = {"range": 3, "damage": [1, 1], "chance": 0.5}
	return "\n".join(MonsterAbilities.check("enemy 'x'", e))


func test_bad_abilities_are_refused() -> void:
	assert_string_contains(_errors("leap"), "must be a list")
	assert_string_contains(_errors([{"kind": "shell"}]), "each needs a kind")
	assert_string_contains(_errors([{"kind": "shooter"}, {"kind": "shooter"}]), "twice")
	assert_string_contains(_errors([{"kind": "shooter"}], false), "needs a ranged entry")
	assert_string_contains(_errors([{"kind": "leap", "range": 1, "ap_q": 8, "cooldown": 1}]), "range must be >= 2")
	assert_string_contains(_errors([{"kind": "leap", "range": 3, "ap_q": 0, "cooldown": 1}]), "ap_q must be 1 to 40")
	assert_string_contains(_errors([{"kind": "leap", "range": 3, "ap_q": 8, "cooldown": -1}]), "cooldown must be >= 0")
	assert_string_contains(_errors([{"kind": "leap", "range": 3}]), "needs a number 'ap_q'")
	assert_eq(_errors([{"kind": "leap", "range": 3, "ap_q": 8, "cooldown": 2}, {"kind": "shooter"}]), "")
	# M32.3
	assert_string_contains(_errors([{"kind": "fear", "range": 0, "ap_q": 8}]), "fear: range must be >= 1")
	assert_string_contains(_errors([{"kind": "fear", "range": 4, "ap_q": 50}]), "fear: ap_q must be 1 to 40")
	assert_string_contains(_errors([{"kind": "fear", "range": 4}]), "fear: needs a number 'ap_q'")
	var bile := {"kind": "bile", "range": 3, "ap_q": 8, "cooldown": 3, "chance": 0.5, "rounds": 2, "damage": [1, 2]}
	assert_eq(_errors([bile]), "")
	assert_string_contains(_errors([bile.merged({"chance": 1.5}, true)]), "bile: chance must be 0 to 1")
	assert_string_contains(_errors([bile.merged({"rounds": 0}, true)]), "bile: rounds must be >= 1")
	assert_string_contains(_errors([bile.merged({"damage": [3, 1]}, true)]), "bile: damage must be")
	assert_string_contains(_errors([bile.merged({"damage": 2}, true)]), "bile: damage must be")
	var command := {"kind": "command", "radius": 5, "accuracy": 2, "tag": "goblin"}
	assert_eq(_errors([command]), "")
	assert_string_contains(_errors([command.merged({"tag": ""}, true)]), "command: needs a tag")
	assert_string_contains(_errors([command.merged({"radius": 0}, true)]), "command: radius must be >= 1")
	assert_string_contains(_errors([command.merged({"accuracy": -1}, true)]), "command: accuracy must be >= 0")


func test_combat_db_reports_bad_abilities() -> void:
	_db.combat.enemies["goblin"]["abilities"] = [{"kind": "shell"}]
	_db.combat.errors.clear()
	_db.combat.validate(_db)
	assert_string_contains("\n".join(_db.combat.errors), "enemy 'goblin' abilities")


# --- leap ---

func test_a_leap_closes_the_gap_and_hits_in_the_same_turn() -> void:
	var gs := _game(Vector2i(2, 1))
	var g := ToyCombat.spawn(gs, _db, "goblin", Vector2i(7, 1))  # 5 tiles east: the walk would need 4 steps and more
	Commands.wait(gs, _db, 0)
	Commands.end_turn(gs, _db)
	var d := _pos(gs, g) - Vector2i(2, 1)
	assert_eq(absi(d.x) + absi(d.y), 1, "side by side after one turn")
	assert_string_contains(_text(gs), "makes a leap at you")
	assert_string_contains(_text(gs), "Goblin attacks you")


func test_a_leap_costs_ap_and_ignores_the_move_cap() -> void:
	var gs := _game(Vector2i(2, 1))
	var g := ToyCombat.spawn(gs, _db, "goblin", Vector2i(7, 1))
	_db.rules["combat"]["tactical"]["monster"]["move_cap_q"] = 0  # it cannot walk at all
	Commands.wait(gs, _db, 0)
	Commands.end_turn(gs, _db)
	assert_eq(absi((_pos(gs, g) - Vector2i(2, 1)).x), 1, "it still jumped beside the player")


func test_the_cooldown_stops_a_second_leap_until_it_is_over() -> void:
	var gs := _game(Vector2i(2, 1))
	var g := ToyCombat.spawn(gs, _db, "goblin", Vector2i(7, 1))
	Commands.wait(gs, _db, 0)
	Commands.end_turn(gs, _db)
	assert_gt(CombatSkills.rounds_left(gs, g, "ability:leap"), 0, "the cooldown runs")
	assert_false(MonsterAbilities.leap_ready(gs, g))
	for _i in 4:
		Commands.end_turn(gs, _db)
	assert_true(MonsterAbilities.leap_ready(gs, g), "ready again after the rounds")


func test_a_wall_blocks_the_leap() -> void:
	var gs := _game(Vector2i(9, 4))
	var g := ToyCombat.spawn(gs, _db, "goblin", Vector2i(3, 4))  # the wall at 6,4 is between; every landing tile is on the far side
	var a := MonsterAbilities.find(_db.combat.enemies["goblin"], MonsterAbilities.LEAP)
	assert_true(MonsterAbilities.leap_spot(gs, _db, g, Vector2i(9, 4), a).is_empty(), "no sight to a landing tile")
	a["range"] = 8
	assert_true(MonsterAbilities.leap_spot(gs, _db, g, Vector2i(9, 4), a).is_empty(), "still no sight")


func test_a_leap_out_of_range_does_not_happen() -> void:
	var gs := _game(Vector2i(2, 1))
	var g := ToyCombat.spawn(gs, _db, "goblin", Vector2i(12, 1))
	var a := MonsterAbilities.find(_db.combat.enemies["goblin"], MonsterAbilities.LEAP)
	assert_true(MonsterAbilities.leap_spot(gs, _db, g, Vector2i(2, 1), a).is_empty(), "10 tiles is past range 5")


func test_a_leap_picks_the_nearest_free_side() -> void:
	var gs := _game(Vector2i(2, 1))
	var g := ToyCombat.spawn(gs, _db, "goblin", Vector2i(7, 1))
	var a := MonsterAbilities.find(_db.combat.enemies["goblin"], MonsterAbilities.LEAP)
	assert_eq(MonsterAbilities.leap_spot(gs, _db, g, Vector2i(2, 1), a)["cell"], Vector2i(3, 1))
	ToyCombat.spawn(gs, _db, "crab", Vector2i(3, 1))  # taken: the next nearest side
	assert_eq(MonsterAbilities.leap_spot(gs, _db, g, Vector2i(2, 1), a)["cell"], Vector2i(2, 0))


# --- fear (M32.3) ---

func _fear_goblin() -> void:
	_db.combat.enemies["goblin"]["abilities"] = [{"kind": "fear", "name": "Red eyes", "range": 6, "ap_q": 8}]
	_db.rules["combat"]["tactical"]["monster"]["move_cap_q"] = 0  # it stays where it is


func test_fear_takes_ap_when_the_player_sees_it() -> void:
	_fear_goblin()
	var gs := _game(Vector2i(2, 1))
	ToyCombat.spawn(gs, _db, "goblin", Vector2i(7, 1))
	Commands.wait(gs, _db, 0)
	Commands.end_turn(gs, _db)
	assert_true(Encounter.is_player_turn(gs))
	assert_eq(int(gs.combat.encounter["ap_q"]), Encounter.player_ap(gs, _db) - 8)
	assert_string_contains(_text(gs), "fixes you with its red eyes. Fear takes 2 AP")


func test_a_wall_or_distance_stops_the_fear() -> void:
	_fear_goblin()
	var gs := _game(Vector2i(9, 4))
	ToyCombat.spawn(gs, _db, "goblin", Vector2i(3, 4))  # 6 tiles, but the wall at 6,4 is between
	Commands.wait(gs, _db, 0)
	Commands.end_turn(gs, _db)
	assert_eq(int(gs.combat.encounter["ap_q"]), Encounter.player_ap(gs, _db), "no sight, no fear")
	var far := _game(Vector2i(1, 1))
	ToyCombat.spawn(far, _db, "goblin", Vector2i(9, 1))  # 8 tiles: past range 6
	Commands.wait(far, _db, 0)
	Commands.end_turn(far, _db)
	assert_eq(int(far.combat.encounter["ap_q"]), Encounter.player_ap(far, _db), "too far, no fear")


func test_two_fears_do_not_add_up() -> void:
	_fear_goblin()
	var gs := _game(Vector2i(2, 1))
	ToyCombat.spawn(gs, _db, "goblin", Vector2i(5, 1))
	ToyCombat.spawn(gs, _db, "goblin", Vector2i(5, 2))
	Commands.wait(gs, _db, 0)
	Commands.end_turn(gs, _db)
	assert_eq(int(gs.combat.encounter["ap_q"]), Encounter.player_ap(gs, _db) - 8, "the biggest fear counts once")


# --- bile (M32.3) ---

func _bile_goblin(chance: float) -> void:
	_db.combat.enemies["goblin"]["abilities"] = [{"kind": "bile", "name": "Bile", "range": 3, "ap_q": 4,
			"cooldown": 5, "chance": chance, "rounds": 2, "damage": [2, 2]}]
	_db.rules["combat"]["tactical"]["monster"]["move_cap_q"] = 0  # it cannot walk up to hit


func test_bile_poisons_the_player_for_its_rounds() -> void:
	_bile_goblin(1.0)
	var gs := _game(Vector2i(2, 1))
	ToyCombat.spawn(gs, _db, "goblin", Vector2i(4, 1))  # 2 tiles: in range, not side by side
	Commands.wait(gs, _db, 0)
	var hp0 := Combat.hp(gs, _db)
	Commands.end_turn(gs, _db)
	assert_string_contains(_text(gs), "spits bile at you! It burns.")
	assert_string_contains(_text(gs), "The poison burns: 2 damage.")
	assert_eq(Combat.hp(gs, _db), hp0 - 2, "one bite at the start of the player's turn")
	assert_eq(int(gs.combat.encounter["poison"][Encounter.PLAYER]["rounds"]), 1)
	Commands.end_turn(gs, _db)
	assert_eq(Combat.hp(gs, _db), hp0 - 4, "the second bite")
	assert_false((gs.combat.encounter.get("poison", {}) as Dictionary).has(Encounter.PLAYER), "the poison is over")
	Commands.end_turn(gs, _db)
	assert_eq(Combat.hp(gs, _db), hp0 - 4, "no third bite; the cooldown stops a new spit")


func test_a_missed_spit_does_not_poison() -> void:
	_bile_goblin(0.0)
	var gs := _game(Vector2i(2, 1))
	ToyCombat.spawn(gs, _db, "goblin", Vector2i(4, 1))
	Commands.wait(gs, _db, 0)
	var hp0 := Combat.hp(gs, _db)
	Commands.end_turn(gs, _db)
	assert_string_contains(_text(gs), "spits bile at you and misses.")
	assert_eq(Combat.hp(gs, _db), hp0)
	assert_false((gs.combat.encounter.get("poison", {}) as Dictionary).has(Encounter.PLAYER))


func test_poison_bites_a_monster_and_can_fell_it() -> void:
	var gs := _game(Vector2i(2, 1))
	var g := ToyCombat.spawn(gs, _db, "goblin", Vector2i(8, 8))
	Commands.wait(gs, _db, 0)
	gs.combat.encounter["poison"] = {g: {"rounds": 3, "damage": [3, 3]}}
	var hp0 := int(gs.combat.monsters[g]["hp"])
	MonsterAbilities.poison_tick(gs, _db, g)
	assert_eq(int(gs.combat.monsters[g]["hp"]), hp0 - 3)
	gs.combat.encounter["poison"][g]["damage"] = [99, 99]
	MonsterAbilities.poison_tick(gs, _db, g)
	assert_false(gs.combat.monsters.has(g), "the poison killed it")


# --- command (M32.3) ---

func _lord() -> void:
	var lord: Dictionary = _db.combat.enemies["goblin"].duplicate(true)
	lord["name"] = "Lord"
	lord["abilities"] = [{"kind": "command", "radius": 3, "accuracy": 2, "tag": "goblin"}]
	_db.combat.enemies["lord"] = lord


func test_command_helps_tagged_foes_in_its_radius() -> void:
	_lord()
	var gs := _game(Vector2i(1, 8))
	var l := ToyCombat.spawn(gs, _db, "lord", Vector2i(5, 1))
	var near := ToyCombat.spawn(gs, _db, "goblin", Vector2i(7, 2))
	var far := ToyCombat.spawn(gs, _db, "goblin", Vector2i(12, 1))
	var crab := ToyCombat.spawn(gs, _db, "crab", Vector2i(5, 2))
	assert_eq(MonsterAbilities.command_bonus(gs, _db, near), 2)
	assert_eq(MonsterAbilities.command_bonus(gs, _db, far), 0, "out of the radius")
	assert_eq(MonsterAbilities.command_bonus(gs, _db, crab), 0, "not a Goblin")
	assert_eq(MonsterAbilities.command_bonus(gs, _db, l), 0, "not on itself")
	gs.combat.monsters.erase(l)
	assert_eq(MonsterAbilities.command_bonus(gs, _db, near), 0, "the lord is gone")


func test_command_turns_a_miss_into_a_hit() -> void:
	_lord()
	var gs := _game(Vector2i(2, 1))
	var g := ToyCombat.spawn(gs, _db, "goblin", Vector2i(3, 1))
	_db.combat.enemies["goblin"]["accuracy"] = Stats.get_stat(gs, _db, "dexterity")
	_db.rules["combat"]["hit"] = {"base": 0.0, "per_point": 0.5, "min": 0.0, "max": 1.0}
	assert_false(Combat.monster_attack(gs, _db, g)["hit"], "even odds at base 0: no hit")
	ToyCombat.spawn(gs, _db, "lord", Vector2i(4, 1))
	assert_true(Combat.monster_attack(gs, _db, g)["hit"], "+2 accuracy: a sure hit")


func test_a_commanded_foe_does_not_run() -> void:
	_lord()
	var gs := _game(Vector2i(2, 1))
	var g := ToyCombat.spawn(gs, _db, "goblin", Vector2i(3, 1))
	Combat.damage_monster(gs, _db, g, 5)  # 3 of 8 HP left: below flee_below 0.5
	var l := ToyCombat.spawn(gs, _db, "lord", Vector2i(4, 1))
	assert_false(MonsterSim._hostile_checks(gs, _db, g))
	assert_eq(gs.combat.monsters[g]["state"], CombatState.HOSTILE, "it stands by its lord")
	gs.combat.monsters.erase(l)
	assert_true(MonsterSim._hostile_checks(gs, _db, g))
	assert_eq(gs.combat.monsters[g]["state"], CombatState.FLEE, "without the lord it runs")
