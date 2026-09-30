extends GutTest
## M17.3 (ADR 0027) core for the combat screen: the move range (Encounter.reach),
## what a click does (Encounter.plan_to), the hit chance shown before a blow
## (Combat.player_hit_chance) and the turn log for the replay (CombatState.turns).
## Toy arena (ToyCombat): 14×9 grass, a wall at x 6, y 3–5, an exit at 0,8.
## Agility: bird 5, goblin 3 like the player, crab 2.

var _db: DataDb


func before_each() -> void:
	_db = ToyCombat.db()
	ToyCombat.tactical(_db)
	ToyCombat.always_hit(_db)


func _game(at: Vector2i) -> GameState:
	var gs := ToyCombat.new_game(_db, 1)
	ToyCombat.to_arena(gs, _db, at)
	return gs


func _fight(gs: GameState, type: String, at: Vector2i) -> String:
	var id := ToyCombat.spawn(gs, _db, type, at)
	Commands.wait(gs, _db, 0)
	return id


func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


func test_no_reach_off_turn() -> void:
	var gs := _game(Vector2i(10, 4))
	assert_eq(Encounter.reach(gs, _db), {})
	assert_eq(Encounter.plan_to(gs, _db, Vector2i(11, 4)), {})


func test_reach_is_the_move_cap_around_the_player() -> void:
	var gs := _game(Vector2i(10, 4))
	_fight(gs, "crab", Vector2i(1, 0))
	assert_true(Encounter.is_player_turn(gs))
	var r := Encounter.reach(gs, _db)
	# the 4-step diamond (40 tiles) less 14,4 (off the map) and 6,4 (the wall)
	assert_eq(r.size(), 38)
	assert_false(r.has(Vector2i(6, 4)), "a wall")
	assert_false(r.has(Vector2i(10, 4)), "not the player's own tile")
	for at: Vector2i in r:
		var steps: Array = r[at]
		assert_eq(steps.size(), _manhattan(at, Vector2i(10, 4)), "shortest path to %s" % at)
		var walk := Vector2i(10, 4)
		for dir: String in steps:
			walk += PlayerState.DIRS[dir]
		assert_eq(walk, at)


func test_reach_shrinks_after_a_step() -> void:
	var gs := _game(Vector2i(10, 4))
	_fight(gs, "crab", Vector2i(1, 0))
	Commands.move(gs, _db, "e")
	var r := Encounter.reach(gs, _db)
	for at: Vector2i in r:
		assert_lte((r[at] as Array).size(), 3, "one step of the cap is used")
	assert_false(r.has(Vector2i(13, 7)), "4 steps away now")
	assert_true(r.has(Vector2i(12, 5)))


func test_reach_goes_around_monsters() -> void:
	var gs := _game(Vector2i(10, 4))
	var crab := _fight(gs, "crab", Vector2i(1, 0))
	ToyCombat.spawn(gs, _db, "goblin", Vector2i(11, 4), CombatState.IDLE)
	var r := Encounter.reach(gs, _db)
	assert_false(r.has(Vector2i(11, 4)), "a monster stands there")
	assert_eq((r[Vector2i(12, 4)] as Array).size(), 4, "around the goblin")
	assert_false(r.has(CombatState.pos_of(gs.combat.monsters[crab])))


func test_an_exit_tile_ends_a_path() -> void:
	var gs := _game(Vector2i(1, 7))
	_fight(gs, "crab", Vector2i(10, 1))
	var r := Encounter.reach(gs, _db)
	assert_true(r.has(Vector2i(0, 8)), "the exit (flee) is in reach")
	assert_eq((r[Vector2i(0, 8)] as Array).size(), 2)


func test_plan_to_a_tile_walks_there() -> void:
	var gs := _game(Vector2i(10, 4))
	_fight(gs, "crab", Vector2i(1, 0))
	assert_eq(Encounter.plan_to(gs, _db, Vector2i(11, 4)), {"steps": ["e"], "attack": "", "target": ""})
	assert_eq(Encounter.plan_to(gs, _db, Vector2i(6, 4)), {}, "a wall")
	assert_eq(Encounter.plan_to(gs, _db, Vector2i(13, 8)), {}, "too far")


func test_plan_to_a_foe_walks_next_to_it_then_attacks() -> void:
	var gs := _game(Vector2i(2, 4))
	var crab := _fight(gs, "crab", Vector2i(2, 6))
	var plan := Encounter.plan_to(gs, _db, Vector2i(2, 6))
	assert_eq(plan, {"steps": ["s"], "attack": "s", "target": crab})


func test_plan_to_a_foe_next_to_you_is_a_blow() -> void:
	var gs := _game(Vector2i(2, 5))
	var crab := _fight(gs, "crab", Vector2i(2, 6))
	assert_eq(Encounter.plan_to(gs, _db, Vector2i(2, 6)), {"steps": [], "attack": "s", "target": crab})


func test_plan_to_a_foe_with_too_little_ap_only_walks() -> void:
	var gs := _game(Vector2i(2, 4))
	var crab := _fight(gs, "crab", Vector2i(2, 6))
	gs.combat.encounter["ap_q"] = 8  # one step leaves 7 q, a blow costs 8
	assert_eq(Encounter.plan_to(gs, _db, Vector2i(2, 6)), {"steps": ["s"], "attack": "", "target": crab})


func test_plan_to_a_far_foe_does_nothing() -> void:
	var gs := _game(Vector2i(10, 4))
	_fight(gs, "crab", Vector2i(1, 0))
	assert_eq(Encounter.plan_to(gs, _db, Vector2i(1, 0)), {})


func test_plan_to_a_helper_does_nothing() -> void:
	var gs := _game(Vector2i(10, 4))
	_fight(gs, "crab", Vector2i(1, 0))
	ToyCombat.spawn(gs, _db, "goblin", Vector2i(11, 4), CombatState.ALLY)
	assert_eq(Encounter.plan_to(gs, _db, Vector2i(11, 4)), {})


func test_player_hit_chance_is_the_blow_formula() -> void:
	var d := ToyCombat.db()
	ToyCombat.tactical(d)
	var gs := ToyCombat.new_game(d, 1)
	ToyCombat.to_arena(gs, d, Vector2i(2, 4))
	var goblin := ToyCombat.spawn(gs, d, "goblin", Vector2i(2, 6))
	var dex := Stats.get_stat(gs, d, "dexterity")
	assert_almost_eq(Combat.player_hit_chance(gs, d, goblin), Combat.hit_chance(d, dex, 3), 0.0001)
	var malus := float(d.rules["combat"]["hit"]["throw_per_tile"]) * 2
	assert_almost_eq(Combat.player_hit_chance(gs, d, goblin, true, 3), Combat.hit_chance(d, dex, 3, -malus),
			0.0001)


func test_the_log_holds_the_player_then_the_foes_in_order() -> void:
	var gs := _game(Vector2i(2, 4))
	var crab := _fight(gs, "crab", Vector2i(2, 7))
	Commands.move(gs, _db, "s")
	assert_eq(gs.combat.turns.size(), 1)
	assert_eq(gs.combat.turns[0]["id"], "player")
	assert_eq(gs.combat.turns[0]["path"], [Vector2i(2, 5)])
	var hp := int(gs.combat.monsters[crab]["hp"])
	Commands.move(gs, _db, "s")  # walks to 2,6
	Commands.attack(gs, _db, "s")
	var blow: Dictionary = gs.combat.turns[0]
	assert_eq(blow["id"], "player")
	assert_eq(blow["strikes"].size(), 1)
	assert_eq(blow["strikes"][0]["target"], crab)
	assert_eq(int(blow["strikes"][0]["damage"]), hp - int(gs.combat.monsters[crab]["hp"]))
	assert_false(blow["lines"].is_empty(), "the hit line")
	var before := Combat.hp(gs, _db)
	Commands.end_turn(gs, _db)
	var crab_turn: Dictionary = gs.combat.turns[0]
	assert_eq(crab_turn["id"], crab)
	assert_eq(crab_turn["strikes"][0]["target"], "player")
	var dealt := 0
	for s: Dictionary in crab_turn["strikes"]:
		dealt += int(s["damage"])
	assert_eq(dealt, before - Combat.hp(gs, _db), "the log's damage is the HP lost")
	assert_eq(gs.combat.lines.slice(int(crab_turn["line_from"]), int(crab_turn["line_to"])),
			crab_turn["lines"])


func test_a_foe_that_walks_logs_its_steps() -> void:
	var gs := _game(Vector2i(2, 7))
	var bird := _fight(gs, "bird", Vector2i(5, 7))
	var t: Dictionary = gs.combat.turns[0]
	assert_eq(t["id"], bird)
	assert_eq(t["path"], [Vector2i(4, 7), Vector2i(3, 7)])
	assert_eq(t["strikes"].size(), 2, "two pecks")


func test_each_command_starts_a_new_log_and_it_is_not_saved() -> void:
	var gs := _game(Vector2i(2, 7))
	_fight(gs, "bird", Vector2i(5, 7))
	assert_false(gs.combat.turns.is_empty())
	assert_false(gs.combat.to_dict().has("turns"))
	Commands.block(gs, _db)
	for t: Dictionary in gs.combat.turns:
		assert_eq(t["id"], "player", "only the block so far")
		assert_false(t.has("_line0"), "closed")
