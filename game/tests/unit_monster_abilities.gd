extends GutTest
## M17.7 (ADR 0027): enemy abilities. The "shooter" ability replaces the derived rule of M17.6; the
## "leap" ability jumps beside a target that is not side by side (range, sight, AP, cooldown in rounds).
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
