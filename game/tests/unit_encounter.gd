extends GutTest
## Tactical encounter (M17.1, ADR 0027): rounds, turn order by Agility, AP in
## quarter points, the move cap, attacks for 2 AP, end turn, monsters on AP.
## M17.2: block, throw, take and drop on AP, the guard lasts until your next
## turn, the turn ends by itself, fleeing through an exit, NPC fighters and
## brawls in the order (real data).
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


func test_combat_mode_is_on_in_the_real_data() -> void:
	var d := DataDb.load_dir()
	assert_true(Encounter.enabled(d), "M17.2 turns combat mode on")
	assert_eq(int(Encounter.rules(d)["initiative"]["npc_default"]), 3)


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
	for i in 2:
		assert_eq(Commands.attack(gs, _db, "e")["error"], "")
	assert_eq(int(_enc(gs)["ap_q"]), 8)
	assert_eq(Commands.attack(gs, _db, "e")["error"], "")
	assert_eq(int(gs.combat.monsters[crab]["hp"]), 27, "three hits of 1 through armor 4")
	assert_true(gs.combat.lines.has(Encounter.TURN_OVER), "0 AP: the turn ends by itself (M17.2)")
	assert_true(Combat.is_down(gs) or int(_enc(gs)["round"]) == 2, "the crab had its turn")


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
	assert_true(gs.action_log.records.any(func(r: Dictionary) -> bool:
		return r["action_id"] == "flee_danger"), "fled: the System sees it")


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


func test_block_costs_two_ap_and_lasts_until_your_next_turn() -> void:
	var gs := _game(Vector2i(2, 4))
	_fight(gs, "crab", Vector2i(3, 4))
	assert_eq(Commands.block(gs, _db), "")
	assert_eq(int(_enc(gs)["ap_q"]), 16)
	assert_eq(Commands.attack(gs, _db, "e")["error"], "")
	assert_true(gs.combat.blocking, "an attack does not drop the guard")
	var hp := Combat.hp(gs, _db)
	Commands.end_turn(gs, _db)
	assert_true(gs.combat.lines.any(func(l: String) -> bool: return l.contains("(blocked)")),
			str(gs.combat.lines))
	assert_eq(Combat.hp(gs, _db), hp - 6, "three crab blows of 5, halved")
	assert_true(Encounter.is_player_turn(gs))
	assert_false(gs.combat.blocking, "the guard drops when your next turn starts")


func test_take_drop_and_throw_cost_ap_and_no_time() -> void:
	var gs := _game(Vector2i(1, 2))
	var crab := _fight(gs, "crab", Vector2i(4, 2))
	var sec := NpcSim.world_sec(gs)
	assert_eq(Commands.take(gs, _db, "stick_pile"), "")
	assert_eq(gs.player.held, "stick")
	assert_eq(int(_enc(gs)["ap_q"]), 20, "take: 1 AP")
	assert_eq(Commands.drop(gs, _db), "")
	assert_eq(int(_enc(gs)["ap_q"]), 16, "drop: 1 AP")
	assert_eq(Commands.drop(gs, _db), "You hold nothing.")
	assert_eq(int(_enc(gs)["ap_q"]), 16, "a refused drop is free")
	Commands.take(gs, _db, "stick_pile")
	var hp := int(gs.combat.monsters[crab]["hp"])
	assert_eq(Commands.throw(gs, _db, crab)["error"], "")
	assert_eq(gs.player.held, "")
	assert_lt(int(gs.combat.monsters[crab]["hp"]), hp)
	assert_eq(int(_enc(gs)["ap_q"]), 4, "throw: 2 AP")
	assert_eq(NpcSim.world_sec(gs), sec, "no world time passes on your turn")
	assert_eq(Commands.block(gs, _db), Encounter.NO_AP)
	assert_true(Encounter.is_player_turn(gs), "1 AP still pays for an item")


func test_the_turn_goes_on_while_a_step_or_an_item_is_paid() -> void:
	var gs := _game(Vector2i(2, 1))
	_fight(gs, "crab", Vector2i(12, 7))
	for dir: String in ["s", "s", "s", "s"]:
		assert_true(Commands.move(gs, _db, dir)["moved"])
	assert_eq(Commands.move(gs, _db, "s")["error"], Encounter.NO_MOVE)
	Commands.block(gs, _db)
	Commands.block(gs, _db)
	assert_eq(int(_enc(gs)["ap_q"]), 4)
	assert_true(Encounter.is_player_turn(gs), "1 AP left: an item use still fits")
	var gs2 := _game(Vector2i(2, 1))
	_fight(gs2, "crab", Vector2i(12, 7))
	for i in 2:
		Commands.block(gs2, _db)
	assert_eq(Commands.move(gs2, _db, "s")["error"], "")
	assert_eq(Commands.move(gs2, _db, "s")["error"], "")
	assert_eq(int(_enc(gs2)["ap_q"]), 6)
	assert_true(Encounter.is_player_turn(gs2), "two steps left under the cap")
	Commands.move(gs2, _db, "s")
	Commands.move(gs2, _db, "s")
	assert_eq(int(_enc(gs2)["ap_q"]), 4)
	assert_true(Encounter.is_player_turn(gs2), "the cap is used, but an item use fits")


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


# --- Real data (M17.2): NPCs in the order ---

## An NPC with no pending canon event that needs them and no guard tag.
func _minor(gs: GameState, d: DataDb) -> String:
	var ids: Array = gs.npcs.npcs.keys()
	ids.sort()
	for id: String in ids:
		if not Brawl.is_major(gs, d, id) and not NpcReact.has_fight_tag(d, id):
			return id
	return ""


## Liscor market, day 1 morning, no monsters and every spawn on its cooldown.
func _market(d: DataDb) -> GameState:
	var gs := GameState.new_game(20260930, d)
	gs.player.place("liscor_market", Vector2i(5, 5))
	Commands.settle(gs, d)
	gs.combat.monsters.clear()
	gs.combat.fight = {}
	for s: Dictionary in d.combat.spawns:
		gs.combat.spawn_last[s["id"]] = gs.clock.total_minutes
	return gs


func _put(gs: GameState, id: String, at: Vector2i) -> void:
	var n: Dictionary = gs.npcs.npcs[id]
	n["area"] = gs.player.area
	n["x"] = at.x
	n["y"] = at.y


func test_a_brawl_starts_an_encounter_with_the_npc_in_the_order() -> void:
	var d := DataDb.load_dir()
	var gs := _market(d)
	var id := _minor(gs, d)
	for other in gs.npcs.in_area(gs.player.area):
		gs.npcs.npcs[other]["area"] = "liscor_gate"  # no witnesses, no guards
	_put(gs, id, Vector2i(6, 5))
	assert_eq(Commands.attack_npc(gs, d, id, true)["error"], "")
	assert_true(Encounter.active(gs), "an NPC the player hit is a fight")
	assert_true((_enc(gs)["order"] as Array).has(Encounter.NPC + id), str(_enc(gs)["order"]))
	assert_true(Encounter.is_player_turn(gs))
	var back := GameState.from_json(gs.to_json())
	assert_eq(back.combat.encounter["order"], _enc(gs)["order"], "the NPC's turn is saved")
	var hurt := false
	var killed := false
	for i in 200:
		Combat.set_hp(gs, d, 9999)
		var r := Commands.attack_npc(gs, d, id, true)
		hurt = hurt or Combat.hp(gs, d) < Stats.max_hp(gs, d)
		if r["killed"]:
			killed = true
			break
		if r["error"] != "":
			Commands.end_turn(gs, d)
			hurt = hurt or Combat.hp(gs, d) < Stats.max_hp(gs, d)
	assert_true(killed, "the NPC dies")
	assert_true(hurt, "it hit back on its turns")
	Commands.wait(gs, d, 0)
	assert_false(Encounter.active(gs), "the fight is over")


func test_a_guard_near_a_monster_takes_turns_in_the_order() -> void:
	var d := DataDb.load_dir()
	var gs := _market(d)
	_put(gs, "tkrn", Vector2i(9, 5))
	var foe := Combat.add_monster(gs, d, "goblin_grunt", Vector2i(8, 7))
	gs.combat.monsters[foe]["hp"] = 60  # above its max: it neither falls nor runs in round one
	Commands.wait(gs, d, 0)
	assert_true(Encounter.active(gs))
	assert_true((_enc(gs).get("order", []) as Array).has(Encounter.NPC + "tkrn"), str(_enc(gs)))
	for i in 60:
		if not gs.combat.monsters.has(foe) or not Encounter.active(gs):
			break
		Combat.set_hp(gs, d, 9999)
		Commands.end_turn(gs, d)
	assert_false(gs.combat.monsters.has(foe) and gs.combat.monsters[foe]["state"] == CombatState.HOSTILE,
			"the guard beats the goblin on its turns")
