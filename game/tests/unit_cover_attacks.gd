extends GutTest
## M17.6 (ADR 0027): sight, cover and the pincer inside attacks: the player's blow and throw, spells,
## a foe's stone. Toy arena (ToyCombat): 14×9 grass, a wall (cover "wall") at x 6, y 3–5; a table (half)
## at 9,1. Real hit numbers (base 0.7, 0.05 per point); the toy goblin has accuracy 3, evasion 3.

var _db: DataDb


func before_each() -> void:
	_db = ToyCombat.db()
	ToyCombat.tactical(_db)
	_db.maps.tiles["wall"]["cover"] = Cover.WALL
	var areas := _db.maps.areas
	(areas["arena"]["objects"] as Array).append(
			{"id": "table", "at": [9, 1], "name": "Table", "actions": [], "solid": true, "kind": "table"})
	_db.maps = MapDb.from_dicts(_db.maps.tiles, areas)
	_db.maps.validate(_db)
	_db.tags["magic"] = ""
	_db.actions["cast_spell"] = {"name": "Cast", "minutes": 5, "base_xp": 8, "risk": 0.5, "tags": {"magic": 1.0}}
	_db.spells = SpellDb.from_dicts({
		"bolt": _spell("one", 8, 2, "auto"),
		"boom": _spell("blast", 12, 3, "auto"),
		"flicker": _spell("one", 4, 1, "roll"),
	})


func _spell(shape: String, ap_q: int, mp: int, hit: String) -> Dictionary:
	return {"name": "[S]", "shape": shape, "ap_q": ap_q, "mp": mp, "damage": [4, 4], "hit": hit,
		"range": 5, "radius": 1, "cooldown": 0, "intellect_div": 1000,
		"canon_ref": {"book": 1, "confidence": "guess"}}


func _game(at: Vector2i) -> GameState:
	var gs := ToyCombat.new_game(_db)
	ToyCombat.to_arena(gs, _db, at)
	for id: String in ["bolt", "boom", "flicker"]:
		gs.progression.spells.append(id)
	return gs


func _dex(gs: GameState) -> int:
	return Stats.get_stat(gs, _db, "dexterity")


func _throw_malus(dist: int) -> float:
	return float(_db.rules["combat"]["hit"]["throw_per_tile"]) * (dist - 1)


func test_a_thrown_item_loses_hit_chance_to_cover_on_the_far_side() -> void:
	var gs := _game(Vector2i(12, 1))
	var g := ToyCombat.spawn(gs, _db, "goblin", Vector2i(8, 1))  # the table at 9,1 is between-side
	assert_almost_eq(Combat.player_hit_chance(gs, _db, g, true, 4),
			Combat.hit_chance(_db, _dex(gs), 3, -_throw_malus(4) - 0.15), 0.0001)


func test_a_thrown_item_from_the_open_side_ignores_that_cover() -> void:
	var gs := _game(Vector2i(5, 1))
	var g := ToyCombat.spawn(gs, _db, "goblin", Vector2i(8, 1))
	assert_almost_eq(Combat.player_hit_chance(gs, _db, g, true, 3),
			Combat.hit_chance(_db, _dex(gs), 3, -_throw_malus(3)), 0.0001)


func test_a_blow_ignores_cover() -> void:
	var gs := _game(Vector2i(8, 2))
	var g := ToyCombat.spawn(gs, _db, "goblin", Vector2i(8, 1))
	assert_almost_eq(Combat.player_hit_chance(gs, _db, g), Combat.hit_chance(_db, _dex(gs), 3), 0.0001)


func test_a_helper_and_the_player_pincer_a_foe_for_plus_15() -> void:
	var gs := _game(Vector2i(8, 2))
	var g := ToyCombat.spawn(gs, _db, "goblin", Vector2i(8, 1))
	ToyCombat.spawn(gs, _db, "bird", Vector2i(8, 0), CombatState.ALLY)
	assert_almost_eq(Combat.player_hit_chance(gs, _db, g), Combat.hit_chance(_db, _dex(gs), 3, 0.15), 0.0001)


func test_a_throw_needs_sight() -> void:
	var gs := _game(Vector2i(4, 4))
	var g := ToyCombat.spawn(gs, _db, "goblin", Vector2i(7, 4))  # the wall at 6,4 is between
	gs.player.held = "stick"
	var r := Combat.throw_at(gs, _db, g)
	assert_eq(r["error"], Combat.NO_SIGHT)
	assert_eq(gs.player.held, "stick", "the item is kept")
	gs.player.place("arena", Vector2i(4, 2))
	gs.combat.monsters[g]["x"] = 7
	gs.combat.monsters[g]["y"] = 2
	assert_eq(Combat.throw_at(gs, _db, g)["error"], "")


func test_a_spell_at_one_or_a_blast_needs_sight_and_hides_no_target_list() -> void:
	var gs := _game(Vector2i(4, 4))
	var g := ToyCombat.spawn(gs, _db, "goblin", Vector2i(8, 4))
	ToyCombat.freeze(_db)
	Commands.wait(gs, _db, 0)
	assert_true(Encounter.is_player_turn(gs))
	assert_eq(Spells.why_not(gs, _db, "bolt", Vector2i(8, 4)), Combat.NO_SIGHT)
	assert_eq(Spells.why_not(gs, _db, "boom", Vector2i(8, 4)), Combat.NO_SIGHT)
	assert_true(Spells.one_targets(gs, _db, "bolt").is_empty(), "no target behind the wall")
	gs.player.place("arena", Vector2i(4, 1))
	gs.combat.monsters[g]["y"] = 1
	assert_eq(Spells.why_not(gs, _db, "bolt", Vector2i(8, 1)), "")
	assert_eq(Spells.one_targets(gs, _db, "bolt"), [g] as Array[String])


func test_a_rolled_spell_takes_cover_into_account_but_a_sure_one_does_not() -> void:
	var gs := _game(Vector2i(12, 1))
	var g := ToyCombat.spawn(gs, _db, "goblin", Vector2i(8, 1))
	assert_almost_eq(Spells.hit_chance(gs, _db, "flicker", g),
			Combat.hit_chance(_db, Stats.get_stat(gs, _db, Spells.INTELLECT), 3, -0.15), 0.0001)
	assert_eq(Spells.hit_chance(gs, _db, "bolt", g), 1.0)


## A goblin that cannot move: it throws its stone only when it sees the player.
func _stone_thrown(goblin: Vector2i, player: Vector2i) -> bool:
	_db.rules["combat"]["tactical"]["monster"]["move_cap_q"] = 0
	_db.combat.enemies["goblin"]["ranged"] = {"range": 6, "damage": [1, 1], "chance": 1.0}
	_db.rules["combat"]["hp_base"] = 500
	var gs := _game(player)
	ToyCombat.spawn(gs, _db, "goblin", goblin)
	Commands.wait(gs, _db, 0)
	var seen := "\n".join(gs.combat.lines)
	for _i in 3:
		Commands.end_turn(gs, _db)
		seen += "\n".join(gs.combat.lines)
	return seen.contains("throws a stone")


func test_a_foe_does_not_throw_through_a_wall() -> void:
	assert_false(_stone_thrown(Vector2i(4, 4), Vector2i(8, 4)), "the wall at 6,4 is between")


func test_a_foe_throws_when_it_sees_you() -> void:
	assert_true(_stone_thrown(Vector2i(4, 2), Vector2i(8, 2)))
