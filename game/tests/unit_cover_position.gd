extends GutTest
## M17.6 (ADR 0027): monsters use cover and position. A shooter walks to a tile with cover against
## the player, shoots from it and holds it; melee monsters, when two tiles beside the player are
## equally near, take the one that closes a pincer. Toy arena (ToyCombat): 14×9 grass, a wall
## (cover "wall") at x 6, y 3–5; a table (half) at 9,1.

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
	_db.rules["combat"]["hp_base"] = 500
	_db.combat.enemies["goblin"]["lose_radius"] = 99
	_db.combat.enemies["goblin"]["chase_turns"] = 99
	# a shooter: its stone (3) hurts more than its blow (2)
	_db.combat.enemies["goblin"]["ranged"] = {"range": 6, "damage": [3, 3], "chance": 1.0}


func _game(at: Vector2i) -> GameState:
	var gs := ToyCombat.new_game(_db)
	ToyCombat.to_arena(gs, _db, at)
	return gs


func _pos(gs: GameState, id: String) -> Vector2i:
	return CombatState.pos_of(gs.combat.monsters[id])


func _round(gs: GameState) -> void:
	Commands.end_turn(gs, _db)


func test_cover_spot_finds_the_tile_behind_the_table() -> void:
	var gs := _game(Vector2i(5, 1))
	var g := ToyCombat.spawn(gs, _db, "goblin", Vector2i(12, 1))
	var spot := MonsterSim.cover_spot(gs, _db, g, Vector2i(5, 1), 4, 6)
	assert_eq(spot["cell"], Vector2i(10, 1), "the table 9,1 is west of it, toward the player")
	assert_eq(spot["steps"], 2)


func test_cover_spot_respects_budget_range_and_sight() -> void:
	var gs := _game(Vector2i(5, 1))
	var g := ToyCombat.spawn(gs, _db, "goblin", Vector2i(12, 1))
	assert_true(MonsterSim.cover_spot(gs, _db, g, Vector2i(5, 1), 1, 6).is_empty(), "one step is not enough")
	assert_true(MonsterSim.cover_spot(gs, _db, g, Vector2i(5, 1), 4, 4).is_empty(), "10,1 is 5 away: out of range 4")
	gs.combat.monsters[g]["x"] = 10
	assert_true(MonsterSim.cover_spot(gs, _db, g, Vector2i(5, 1), 4, 6).is_empty(), "already in cover")


func test_a_shooter_walks_to_cover_shoots_and_holds_it() -> void:
	var gs := _game(Vector2i(5, 1))
	var g := ToyCombat.spawn(gs, _db, "goblin", Vector2i(12, 1))
	Commands.wait(gs, _db, 0)
	assert_true(Encounter.is_player_turn(gs))
	_round(gs)
	assert_eq(_pos(gs, g), Vector2i(10, 1), "it took the covered tile")
	assert_string_contains("\n".join(gs.combat.lines), "throws a stone")
	_round(gs)
	_round(gs)
	assert_eq(_pos(gs, g), Vector2i(10, 1), "it holds its cover instead of walking up")
	for _i in 6:
		_round(gs)
	assert_lt(_pos(gs, g).x, 10, "after hold_rounds it closes in")


func test_a_brute_with_a_thrown_rock_does_not_seek_cover() -> void:
	_db.combat.enemies["goblin"]["ranged"]["damage"] = [1, 1]  # weaker than its blow: not a shooter
	assert_false(MonsterSim.is_shooter(_db.combat.enemies["goblin"]))
	var gs := _game(Vector2i(5, 1))
	var g := ToyCombat.spawn(gs, _db, "goblin", Vector2i(12, 1))
	Commands.wait(gs, _db, 0)
	_round(gs)
	assert_ne(_pos(gs, g), Vector2i(10, 1), "it walks on instead of taking the table")
	var real := DataDb.load_dir()
	for id in ["goblin_lord_archer", "goblin_lord_shaman"]:
		assert_true(MonsterSim.is_shooter(real.combat.enemies[id]), id)
	for id in ["goblin_grunt", "goblin_chieftain", "crypt_lord"]:
		assert_false(MonsterSim.is_shooter(real.combat.enemies[id]), id)


func test_hold_rounds_zero_turns_cover_seeking_off() -> void:
	_db.rules["combat"]["tactical"]["cover"]["hold_rounds"] = 0
	var gs := _game(Vector2i(5, 1))
	var g := ToyCombat.spawn(gs, _db, "goblin", Vector2i(12, 1))
	Commands.wait(gs, _db, 0)
	_round(gs)
	assert_ne(_pos(gs, g), Vector2i(10, 1))


func test_a_shooter_without_cover_near_it_advances_as_before() -> void:
	var gs := _game(Vector2i(2, 7))
	var g := ToyCombat.spawn(gs, _db, "goblin", Vector2i(12, 7))
	Commands.wait(gs, _db, 0)
	_round(gs)
	assert_lt(_pos(gs, g).x, 12, "no cover anywhere near: it walks toward the player")


func test_a_flanked_shooter_is_hit_without_the_cover_malus() -> void:
	var gs := _game(Vector2i(5, 1))
	var g := ToyCombat.spawn(gs, _db, "goblin", Vector2i(10, 1))
	assert_eq(Cover.against(_db, "arena", _pos(gs, g), gs.player.pos()), Cover.HALF, "player west: the table covers it")
	gs.player.place("arena", Vector2i(12, 1))
	assert_eq(Cover.against(_db, "arena", _pos(gs, g), gs.player.pos()), Cover.NONE, "player east: the flank")


## A crab (no ranged attack) stands west of the player at 7,4; a second crab comes from the north-east.
func _second_crab(start: Vector2i) -> Vector2i:
	var gs := _game(Vector2i(8, 4))
	ToyCombat.spawn(gs, _db, "crab", Vector2i(7, 4))
	var b := ToyCombat.spawn(gs, _db, "crab", start)
	Commands.wait(gs, _db, 0)
	_round(gs)
	return _pos(gs, b)


func test_of_two_equally_near_sides_a_monster_takes_the_one_that_closes_the_pincer() -> void:
	# from 10,2: the north side 8,3 and the east side 9,4 are both 3 steps away; the crab at 7,4 is west
	assert_eq(_second_crab(Vector2i(10, 2)), Vector2i(9, 4))


func test_a_clearly_nearer_side_still_wins() -> void:
	# from 8,1 the north side 8,3 is 2 steps, the east side 9,4 much further
	assert_eq(_second_crab(Vector2i(8, 1)), Vector2i(8, 3))


## Real data (floodplains_south has trees): an archer near a tree finds a covered firing tile that
## sees the player and is in range.
func test_a_real_archer_finds_cover_behind_a_tree() -> void:
	var real := DataDb.load_dir()
	var area := "floodplains_south"
	var gs := GameState.new_game(3, real)
	var e: Dictionary = real.combat.enemies["goblin_lord_archer"]
	var size := real.maps.size(area)
	var checked := 0
	for y in range(3, size.y - 3):
		for x in range(6, size.x - 3):
			if real.maps.tile_at(area, Vector2i(x, y)) != "tree":
				continue
			var shooter := Vector2i(x + 1, y + 2)
			var you := Vector2i(x - 4, y)
			if not (Movement.can_enter(gs, real, area, shooter) and Movement.can_enter(gs, real, area, you)
					and real.maps.exit_at(area, shooter).is_empty()):
				continue
			gs.player.place(area, you)
			var id := Combat.add_monster(gs, real, "goblin_lord_archer", shooter, CombatState.HOSTILE)
			var spot := MonsterSim.cover_spot(gs, real, id, you, 4, int(e["ranged"]["range"]))
			if not spot.is_empty():
				var cell: Vector2i = spot["cell"]
				assert_gt(Cover.rank(Cover.against(real, area, cell, you)), 0, "the tile has cover from the player")
				assert_true(Cover.sight(real, area, cell, you))
				assert_lte(MonsterSim._dist(cell, you), int(e["ranged"]["range"]))
				checked += 1
			gs.combat.monsters.erase(id)
	assert_gt(checked, 0, "at least one tree gave a covered firing tile")
