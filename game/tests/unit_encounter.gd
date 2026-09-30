extends GutTest
## Tactical encounter (M17.1, ADR 0027): rounds, turn order by Agility, AP in
## quarter points, the move cap, attacks for 2 AP, end turn, monsters on AP.
## Toy arena (ToyCombat): 14×9 grass, a wall at x 6, y 3–5, an exit at 0,8.
## Toy agility: bird (4 s turns) 5, goblin (6 s) 3 like the player, crab (8 s) 2.

var _db: DataDb


func before_each() -> void:
	_db = ToyCombat.db()
	ToyCombat.tactical(_db)
	ToyCombat.always_hit(_db)


func _game(at: Vector2i, seed_value: int = 1) -> GameState:
	var gs := ToyCombat.new_game(_db, seed_value)
	ToyCombat.to_arena(gs, _db, at)
	return gs


## Puts a hostile monster down and lets the encounter start (a 0 s wait).
func _fight(gs: GameState, type: String, at: Vector2i) -> String:
	var id := ToyCombat.spawn(gs, _db, type, at)
	Commands.wait(gs, _db, 0)
	return id


func _enc(gs: GameState) -> Dictionary:
	return gs.combat.encounter


func test_rules_switch_is_off_in_the_real_data() -> void:
	assert_false(Encounter.enabled(DataDb.load_dir()), "M17.2 turns combat mode on")


func test_switched_off_there_is_no_encounter() -> void:
	var d := ToyCombat.db()
	var gs := ToyCombat.new_game(d)
	ToyCombat.to_arena(gs, d, Vector2i(2, 4))
	ToyCombat.spawn(gs, d, "crab", Vector2i(3, 4))
	Commands.wait(gs, d, 0)
	assert_false(Encounter.active(gs))


func test_a_hostile_monster_starts_an_encounter() -> void:
	var gs := _game(Vector2i(2, 4))
	var crab := _fight(gs, "crab", Vector2i(2, 6))
	assert_true(Encounter.active(gs))
	assert_eq(int(_enc(gs)["round"]), 1)
	assert_eq(_enc(gs)["order"], ["player", crab], "the crab (Agility 2) goes after the player (3)")
	assert_true(Encounter.is_player_turn(gs))
	assert_eq(int(_enc(gs)["ap_q"]), 24, "6 AP")


func test_a_faster_monster_acts_before_the_player() -> void:
	var gs := _game(Vector2i(2, 7))
	var bird := _fight(gs, "bird", Vector2i(5, 7))
	assert_eq(_enc(gs)["order"][0], bird, "Agility 5 goes first")
	assert_true(Encounter.is_player_turn(gs))
	assert_eq(CombatState.pos_of(gs.combat.monsters[bird]), Vector2i(3, 7), "two steps (2 q)")
	assert_eq(Combat.hp(gs, _db), Stats.max_hp(gs, _db) - 2, "then two pecks with the 22 q left")


func test_ties_are_rolled_from_the_seed() -> void:
	var a := _game(Vector2i(2, 4), 7)
	var b := _game(Vector2i(2, 4), 7)
	_fight(a, "goblin", Vector2i(2, 7))
	_fight(b, "goblin", Vector2i(2, 7))
	assert_eq(_enc(a)["order"], _enc(b)["order"])
	assert_eq(_enc(a)["tie"], _enc(b)["tie"])
	assert_eq((_enc(a)["tie"] as Dictionary).size(), 2)


func test_an_attack_costs_two_ap() -> void:
	var gs := _game(Vector2i(2, 4))
	var crab := _fight(gs, "crab", Vector2i(3, 4))
	for i in 3:
		assert_eq(Commands.attack(gs, _db, "e")["error"], "")
	assert_eq(int(_enc(gs)["ap_q"]), 0)
	var r := Commands.attack(gs, _db, "e")
	assert_eq(r["error"], Encounter.NO_AP)
	assert_eq(int(gs.combat.monsters[crab]["hp"]), 27, "three hits of 1 through armor 4")


func test_moving_stops_at_the_move_cap() -> void:
	var gs := _game(Vector2i(2, 7))
	_fight(gs, "crab", Vector2i(2, 5))
	for i in 4:
		assert_true(Commands.move(gs, _db, "e")["moved"])
	var r := Commands.move(gs, _db, "e")
	assert_false(r["moved"])
	assert_eq(r["error"], Encounter.NO_MOVE)
	assert_eq(gs.player.pos(), Vector2i(6, 7))
	assert_eq(int(_enc(gs)["ap_q"]), 20)
	assert_eq(int(_enc(gs)["moved_q"]), 4)


func test_move_attack_move_attack() -> void:
	var gs := _game(Vector2i(2, 4))
	var crab := _fight(gs, "crab", Vector2i(4, 4))
	assert_true(Commands.move(gs, _db, "e")["moved"])
	assert_eq(Commands.attack(gs, _db, "e")["error"], "")
	assert_true(Commands.move(gs, _db, "n")["moved"])
	assert_true(Commands.move(gs, _db, "e")["moved"])
	assert_eq(Commands.attack(gs, _db, "s")["error"], "")
	assert_eq(int(_enc(gs)["ap_q"]), 5, "24 - 3 moves - 2 attacks")
	assert_eq(int(gs.combat.monsters[crab]["hp"]), 28)


func test_walking_into_a_monster_attacks_for_two_ap() -> void:
	var gs := _game(Vector2i(2, 4))
	var crab := _fight(gs, "crab", Vector2i(3, 4))
	var r := Commands.move(gs, _db, "e")
	assert_false(r["moved"])
	assert_eq(r["attack"]["error"], "")
	assert_eq(int(_enc(gs)["ap_q"]), 16)
	assert_eq(int(gs.combat.monsters[crab]["hp"]), 29)


func test_player_actions_take_no_time_and_a_round_takes_six_seconds() -> void:
	var gs := _game(Vector2i(2, 4))
	_fight(gs, "crab", Vector2i(3, 4))
	var start := NpcSim.world_sec(gs)
	Commands.attack(gs, _db, "e")
	Commands.move(gs, _db, "s")
	assert_eq(NpcSim.world_sec(gs), start, "AP actions spend no world time")
	assert_eq(Commands.end_turn(gs, _db), "")
	assert_eq(NpcSim.world_sec(gs), start + 6)
	assert_eq(int(_enc(gs)["round"]), 2)
	assert_true(Encounter.is_player_turn(gs))
	assert_eq(int(_enc(gs)["ap_q"]), 24, "AP is full again; nothing carries over")


func test_a_monster_walks_then_attacks_with_the_ap_left() -> void:
	_db.combat.enemies["goblin"].erase("ranged")
	_db.combat.enemies["goblin"]["agility"] = 1
	var gs := _game(Vector2i(2, 7))
	var gob := _fight(gs, "goblin", Vector2i(6, 7))
	Commands.end_turn(gs, _db)
	assert_eq(CombatState.pos_of(gs.combat.monsters[gob]), Vector2i(3, 7), "three steps")
	assert_eq(Combat.hp(gs, _db), Stats.max_hp(gs, _db) - 4, "then two hits of 2 (21 q left)")


func test_a_monster_moves_at_most_four_tiles() -> void:
	_db.combat.enemies["goblin"].erase("ranged")
	_db.combat.enemies["goblin"]["agility"] = 1
	var gs := _game(Vector2i(2, 7))
	var gob := _fight(gs, "goblin", Vector2i(8, 7))
	Commands.end_turn(gs, _db)
	assert_eq(CombatState.pos_of(gs.combat.monsters[gob]), Vector2i(4, 7))
	assert_eq(Combat.hp(gs, _db), Stats.max_hp(gs, _db))


func test_a_monster_that_arrives_mid_round_joins_the_next_round() -> void:
	_db.combat.enemies["bird"]["lose_radius"] = 20
	var gs := _game(Vector2i(2, 4))
	var crab := _fight(gs, "crab", Vector2i(2, 6))
	var bird := ToyCombat.spawn(gs, _db, "bird", Vector2i(10, 7))
	assert_false((_enc(gs)["order"] as Array).has(bird), "not in this round")
	Commands.end_turn(gs, _db)
	assert_eq(_enc(gs)["order"], [bird, "player", crab])
	assert_eq(int(_enc(gs)["round"]), 2)


func test_the_encounter_ends_with_the_last_foe() -> void:
	var gs := _game(Vector2i(2, 4))
	var gob := _fight(gs, "goblin", Vector2i(3, 4))
	gs.combat.monsters[gob]["hp"] = 1
	if not Encounter.is_player_turn(gs):
		Commands.end_turn(gs, _db)
	Commands.attack(gs, _db, "e")
	assert_false(gs.combat.monsters.has(gob))
	assert_false(Encounter.active(gs))
	assert_false(gs.combat.has_fight())


func test_leaving_the_map_ends_the_encounter() -> void:
	var gs := _game(Vector2i(1, 8))
	_fight(gs, "crab", Vector2i(4, 4))
	assert_true(Commands.move(gs, _db, "w")["moved"])
	assert_eq(gs.player.area, "town")
	assert_false(Encounter.active(gs))


func test_a_knock_out_ends_the_encounter() -> void:
	var gs := _game(Vector2i(2, 4))
	_fight(gs, "crab", Vector2i(3, 4))
	Combat.set_hp(gs, _db, 1)
	Commands.end_turn(gs, _db)
	assert_true(Combat.is_down(gs))
	Commands.knock_out(gs, _db)
	assert_false(Encounter.active(gs))


func test_one_more_ap_at_total_level_ten() -> void:
	var gs := _game(Vector2i(2, 4))
	assert_eq(Encounter.player_ap(gs, _db), 24)
	gs.progression.classes["warrior"] = {"level": 9, "xp": 0.0}
	assert_eq(Encounter.player_ap(gs, _db), 24)
	gs.progression.classes["cook"] = {"level": 1, "xp": 0.0}
	assert_eq(Encounter.player_ap(gs, _db), 28, "total level 10: +1 AP")


func test_old_fight_commands_wait_for_m17_2() -> void:
	var gs := _game(Vector2i(2, 4))
	_fight(gs, "crab", Vector2i(3, 4))
	assert_eq(Commands.block(gs, _db), Encounter.NOT_YET)
	assert_eq(int(_enc(gs)["ap_q"]), 24)


func test_wait_ends_the_turn() -> void:
	var gs := _game(Vector2i(2, 4))
	_fight(gs, "crab", Vector2i(2, 6))
	Commands.wait(gs, _db, 60)
	assert_eq(int(_enc(gs)["round"]), 2)


func test_the_encounter_survives_save_and_load() -> void:
	var gs := _game(Vector2i(2, 4))
	_fight(gs, "crab", Vector2i(3, 4))
	Commands.attack(gs, _db, "e")
	var back := GameState.from_json(gs.to_json())
	var e: Dictionary = back.combat.encounter
	assert_eq(e["order"], _enc(gs)["order"])
	assert_eq(e["round"], 1)
	assert_eq(e["turn"], _enc(gs)["turn"])
	assert_eq(e["ap_q"], 16)
	assert_eq(e["moved_q"], 0)
	assert_eq((e["tie"] as Dictionary).keys(), (_enc(gs)["tie"] as Dictionary).keys())
	assert_true(Encounter.is_player_turn(back))


func test_a_v17_save_loads_with_no_encounter() -> void:
	var gs := _game(Vector2i(2, 4))
	var data := gs.to_dict()
	(data["combat"] as Dictionary).erase("encounter")
	data["save_version"] = 17
	var back := GameState.from_dict(SaveMigrations.migrate(data))
	assert_eq(back.save_version, GameState.SAVE_VERSION)
	assert_eq(back.combat.encounter, {})
