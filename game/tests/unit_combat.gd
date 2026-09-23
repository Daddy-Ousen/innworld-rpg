extends GutTest
## Combat core (M5.1, ADR 0010) on the toy world: hits, damage, block,
## throw, items, kills, knock-out, fight records, danger refusals, healing.

const EAST := Vector2i(2, 2)
const NORTH := Vector2i(1, 1)

var _db: DataDb


func before_each() -> void:
	_db = ToyCombat.db()
	ToyCombat.freeze(_db)  # monster turns are tested in unit_monster_sim


func _game(seed_value: int = 1) -> GameState:
	return ToyCombat.new_game(_db, seed_value)


func _records(gs: GameState, action_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for r: Dictionary in gs.action_log.records:
		if r["action_id"] == action_id:
			out.append(r)
	return out


func test_toy_combat_data_is_valid() -> void:
	assert_eq(_db.combat.errors, [] as Array[String])
	assert_eq(_db.errors, [] as Array[String])


func test_hit_chance_clamps() -> void:
	var real := DataDb.load_dir()
	assert_almost_eq(Combat.hit_chance(real, 3, 3), 0.7, 0.000001)
	assert_almost_eq(Combat.hit_chance(real, 3, 5), 0.6, 0.000001)
	assert_almost_eq(Combat.hit_chance(real, 100, 0), 0.95, 0.000001)
	assert_almost_eq(Combat.hit_chance(real, 0, 100), 0.1, 0.000001)


func test_armor_leaves_the_minimum_damage() -> void:
	ToyCombat.always_hit(_db)
	var gs := _game()
	var crab := ToyCombat.spawn(gs, _db, "crab", EAST)
	var r := Commands.attack(gs, _db, "e")
	assert_eq(r["error"], "")
	assert_true(r["hit"])
	assert_eq(r["damage"], 1, "fists 1–2 + strength 1 − armor 4 → the minimum")
	assert_eq(gs.combat.monsters[crab]["hp"], 29)


func test_held_item_and_strength_add_damage() -> void:
	ToyCombat.always_hit(_db)
	var gs := _game()
	ToyCombat.spawn(gs, _db, "goblin", EAST)
	var fists := Commands.attack(gs, _db, "e")
	assert_between(int(fists["damage"]), 2, 3, "fists 1–2 + strength 3/3")
	gs.player.held = "stick"
	var stick := Commands.attack(gs, _db, "e")
	assert_eq(stick["damage"], 4, "stick 3 + strength 1")
	assert_eq(gs.combat.fight["attacks"], 2)
	assert_eq(gs.combat.fight["improvised"], 1)


func test_an_item_can_break_on_a_hit() -> void:
	ToyCombat.always_hit(_db)
	var gs := _game()
	ToyCombat.spawn(gs, _db, "crab", EAST)
	gs.player.held = "vase"
	Commands.attack(gs, _db, "e")
	assert_eq(gs.player.held, "")
	assert_has(gs.combat.lines, "The vase breaks.")


func test_a_miss_does_no_damage_and_keeps_the_item() -> void:
	ToyCombat.never_hit(_db)
	var gs := _game()
	var gob := ToyCombat.spawn(gs, _db, "goblin", EAST)
	gs.player.held = "vase"
	var r := Commands.attack(gs, _db, "e")
	assert_false(r["hit"])
	assert_eq(gs.combat.monsters[gob]["hp"], 8)
	assert_eq(gs.player.held, "vase")


func test_attack_needs_a_monster_and_costs_a_turn() -> void:
	var gs := _game()
	assert_ne(Commands.attack(gs, _db, "e")["error"], "", "nothing there")
	ToyCombat.spawn(gs, _db, "goblin", EAST)
	var before := gs.clock.total_minutes * 60 + gs.player.sub_seconds
	Commands.attack(gs, _db, "e")
	assert_eq(gs.clock.total_minutes * 60 + gs.player.sub_seconds - before,
			int(_db.rules["world"]["step_seconds"]))
	assert_eq(gs.player.facing, "e")


func test_a_kill_removes_the_monster_and_wins_the_fight() -> void:
	ToyCombat.always_hit(_db)
	var gs := _game()
	var gob := ToyCombat.spawn(gs, _db, "goblin", EAST)
	gs.player.held = "stick"
	Commands.attack(gs, _db, "e")
	var r := Commands.attack(gs, _db, "e")
	assert_true(r["killed"])
	assert_false(gs.combat.monsters.has(gob))
	assert_false(gs.combat.has_fight(), "no hostile left: the fight is over")
	assert_has(gs.combat.lines, "The Goblin dies.")
	assert_has(gs.combat.lines, "The fight is over.")
	var recs := _records(gs, "attack_melee")
	assert_eq(recs.size(), 1, "one record for the whole fight (both hits were with the stick)")
	assert_eq(recs[0]["outcome"], "success")
	assert_true((recs[0]["tags"] as Dictionary).has("combat.improvise"))
	assert_almost_eq(float(recs[0]["risk"]), 0.5, 0.000001, "risk = the goblin's danger")
	assert_almost_eq(float(recs[0]["intensity"]), 0.5, 0.000001, "2 attacks / 4 per intensity")


func test_block_lowers_the_damage_and_counts() -> void:
	ToyCombat.always_hit(_db)
	var gs := _game()
	var gob := ToyCombat.spawn(gs, _db, "goblin", EAST)
	assert_eq(Commands.block(gs, _db), "")
	assert_true(gs.combat.blocking)
	var blocked := Combat.monster_attack(gs, _db, gob)
	assert_eq(blocked["damage"], 1, "2 halved")
	assert_eq(gs.combat.fight["blocks"], 1)
	Combat.begin_command(gs)
	assert_false(gs.combat.blocking, "the guard lasts one turn")
	var open := Combat.monster_attack(gs, _db, gob)
	assert_eq(open["damage"], 2)
	assert_eq(Combat.hp(gs, _db), Stats.max_hp(gs, _db) - 3)


func test_throw_needs_an_item_and_range_and_spends_it() -> void:
	ToyCombat.always_hit(_db)
	var gs := _game()
	var far := ToyCombat.spawn(gs, _db, "goblin", Vector2i(5, 2))
	assert_eq(Commands.throw(gs, _db, far)["error"], "You hold nothing to throw.")
	gs.player.held = "stick"
	assert_eq(Commands.throw(gs, _db, far)["error"], "Too far to throw.")
	assert_eq(gs.player.held, "stick")
	var near := ToyCombat.spawn(gs, _db, "goblin", Vector2i(4, 2))
	var r := Commands.throw(gs, _db, near)
	assert_eq(r["error"], "")
	assert_eq(r["damage"], 3, "throw 2 + strength 1")
	assert_eq(gs.player.held, "", "a thrown item is gone")
	assert_eq(gs.combat.fight["throws"], 1)


func test_a_thrown_scare_item_scares_even_on_a_miss() -> void:
	ToyCombat.never_hit(_db)
	var gs := _game()
	var crab := ToyCombat.spawn(gs, _db, "crab", Vector2i(4, 2))
	gs.player.held = "stink"
	Commands.throw(gs, _db, crab)
	assert_eq(gs.combat.monsters[crab]["state"], CombatState.FLEE)
	assert_eq(gs.combat.monsters[crab]["scared"], 12)
	assert_has(gs.combat.lines, "The Crab panics and backs away.")


func test_a_scare_item_does_nothing_to_other_enemies() -> void:
	ToyCombat.always_hit(_db)
	var gs := _game()
	var gob := ToyCombat.spawn(gs, _db, "goblin", EAST)
	gs.player.held = "stink"
	Commands.attack(gs, _db, "e")
	assert_eq(gs.combat.monsters[gob]["state"], CombatState.HOSTILE)


func test_attacking_wakes_a_hidden_monster() -> void:
	ToyCombat.always_hit(_db)
	var gs := _game()
	var crab := ToyCombat.spawn(gs, _db, "crab", EAST, CombatState.HIDDEN)
	assert_false(gs.combat.has_fight(), "a hidden crab is no fight yet")
	Commands.attack(gs, _db, "e")
	assert_eq(gs.combat.monsters[crab]["state"], CombatState.HOSTILE)
	assert_true(Combat.in_danger(gs))


func test_a_monster_blocks_a_step_and_a_bump_attacks() -> void:
	ToyCombat.always_hit(_db)
	var gs := _game()
	var gob := ToyCombat.spawn(gs, _db, "goblin", EAST)
	var r := Commands.move(gs, _db, "e")
	assert_false(r["moved"])
	assert_true(r["blocked"])
	assert_eq(r["monster"], gob)
	assert_true(r["attack"]["hit"])
	assert_eq(gs.player.pos(), Vector2i(1, 2))
	assert_eq(gs.combat.fight["attacks"], 1)


func test_knocked_out_refuses_everything_but_knock_out() -> void:
	var gs := _game()
	var gob := ToyCombat.spawn(gs, _db, "goblin", EAST)
	Combat.damage_player(gs, _db, 999)
	assert_true(Combat.is_down(gs))
	assert_eq(Combat.hp(gs, _db), 0)
	assert_has(gs.combat.lines, Combat.KNOCKED_OUT_LINE)
	assert_true(Commands.move(gs, _db, "s")["refused"])
	assert_eq(Commands.wait(gs, _db, 6), -1)
	assert_eq(Commands.attack(gs, _db, "e")["error"], Combat.REFUSED_DOWN)
	assert_eq(Commands.block(gs, _db), Combat.REFUSED_DOWN)
	assert_true(Commands.perform(gs, _db, "cook").is_empty())
	assert_has(gs.combat.lines, Combat.REFUSED_DOWN)
	assert_eq(Commands.interact(gs, _db, "dummy", "fight")["error"], Combat.REFUSED_DOWN)
	assert_true(gs.combat.monsters.has(gob))


func test_knock_out_fails_the_fight_and_wakes_at_six_with_low_hp() -> void:
	ToyCombat.always_hit(_db)
	var gs := _game()
	gs.clock.advance(14 * 60)  # 20:00 (a sleep at 06:00 is only a nap)
	ToyCombat.spawn(gs, _db, "goblin", EAST)
	Commands.attack(gs, _db, "e")
	Combat.damage_player(gs, _db, 999)
	var day := gs.clock.day()
	var night := Commands.knock_out(gs, _db)
	assert_true(night["knocked_out"])
	assert_true(night["collapsed"])
	assert_eq(night["lines"][0], Night.KNOCKOUT_LINE)
	assert_eq(gs.clock.day(), day + 1)
	assert_eq(gs.clock.time_string(), "06:00")
	assert_true(gs.clock.last_sleep_collapsed)
	assert_eq(Combat.hp(gs, _db), 5, "25% of 20")
	assert_true(gs.combat.monsters.is_empty())
	assert_false(gs.combat.has_fight())
	var recs := _records(gs, "attack_melee")
	assert_eq(recs.size(), 1)
	assert_eq(recs[0]["outcome"], "fail")
	assert_eq(night["records"], 1, "the fight's record is part of the night")


func test_knock_out_wakes_at_the_safe_place_for_the_area() -> void:
	var gs := _game()
	gs.clock.advance(14 * 60)
	var here := gs.player.pos()
	Combat.damage_player(gs, _db, 999)
	Commands.knock_out(gs, _db)
	assert_eq(gs.player.area, "town", "town has no wake spot: you wake where you fell")
	assert_eq(gs.player.pos(), here)
	assert_true(ToyMaps.walk_to_area(gs, _db, "field"))
	gs.clock.advance(12 * 60)
	Combat.damage_player(gs, _db, 999)
	Commands.knock_out(gs, _db)
	assert_eq(gs.player.area, "shop")
	assert_eq(gs.player.pos(), Vector2i(1, 1))


func test_fleeing_ends_the_fight_with_one_record_per_action() -> void:
	ToyCombat.always_hit(_db)
	var gs := _game()
	var gob := ToyCombat.spawn(gs, _db, "goblin", NORTH)
	var other := ToyCombat.spawn(gs, _db, "goblin", Vector2i(3, 2))
	Commands.attack(gs, _db, "n")
	gs.player.held = "stick"
	Commands.attack(gs, _db, "n")
	Commands.block(gs, _db)
	Combat.monster_attack(gs, _db, gob)
	gs.player.held = "stick"
	Commands.throw(gs, _db, other)
	var before := gs.clock.total_minutes
	assert_true(ToyMaps.walk_to(gs, _db, {Vector2i(1, 3): true}))
	assert_true(Combat.in_danger(gs), "still hostiles in town")
	assert_eq(gs.clock.total_minutes, before, "one 6 s step")
	# Go around the second goblin to the east exit.
	var path := Pathfind.path(_db.maps, "town", gs.player.pos(), {Vector2i(7, 2): true},
			{Vector2i(3, 2): true, NORTH: true})
	assert_true(path["found"])
	for dir: String in path["steps"]:
		Commands.move(gs, _db, dir)
	assert_eq(gs.player.area, "field")
	assert_false(gs.combat.has_fight())
	assert_true(gs.combat.monsters.is_empty(), "the monsters stay behind")
	assert_has(gs.combat.lines, "You got away.")
	var melee := _records(gs, "attack_melee")
	assert_eq(melee.size(), 2, "fists and improvised")
	assert_false((melee[0]["tags"] as Dictionary).has("combat.improvise"))
	assert_true((melee[1]["tags"] as Dictionary).has("combat.improvise"))
	for r in melee:
		assert_eq(r["outcome"], "partial")
	var blocks := _records(gs, "block_attack")
	assert_eq(blocks.size(), 1)
	assert_true((blocks[0]["tags"] as Dictionary).has("combat.block"))
	var throws := _records(gs, "throw_object")
	assert_eq(throws.size(), 1)
	assert_true((throws[0]["tags"] as Dictionary).has("combat.thrown"))
	assert_true((throws[0]["tags"] as Dictionary).has("combat.improvise"))
	var flee := _records(gs, "flee_danger")
	assert_eq(flee.size(), 1)
	assert_eq(flee[0]["outcome"], "success")
	assert_true((flee[0]["tags"] as Dictionary).has("running.escape"))


func test_fight_records_take_no_time() -> void:
	ToyCombat.always_hit(_db)
	var gs := _game()
	ToyCombat.spawn(gs, _db, "goblin", EAST)
	gs.player.held = "stick"
	Commands.attack(gs, _db, "e")
	var before := gs.clock.total_minutes
	Commands.attack(gs, _db, "e")  # the kill ends the fight: the records are written now
	assert_eq(_records(gs, "attack_melee").size(), 1)
	assert_lte(gs.clock.total_minutes - before, 1, "only the 6 s turn")


func test_enemies_near_refuse_actions_uses_and_sleep() -> void:
	var gs := _game()
	gs.clock.advance(14 * 60)
	ToyCombat.spawn(gs, _db, "goblin", Vector2i(5, 3))
	assert_true(Combat.in_danger(gs))
	assert_true(Commands.perform(gs, _db, "cook").is_empty())
	assert_eq(gs.combat.lines, [Combat.REFUSED_DANGER] as Array[String])
	assert_true(ToyMaps.walk_next_to(gs, _db, "dummy"))
	assert_eq(Commands.interact(gs, _db, "dummy", "fight")["error"], Combat.REFUSED_DANGER)
	var day := gs.clock.day()
	assert_true(Commands.sleep(gs, _db).is_empty())
	assert_eq(gs.clock.day(), day)


func test_a_collapse_with_enemies_near_is_a_knock_out() -> void:
	var gs := _game()
	gs.clock.advance(int(_db.rules["clock"]["collapse_after_awake"]))
	ToyCombat.spawn(gs, _db, "goblin", Vector2i(3, 2))
	var night := Commands.sleep(gs, _db)
	assert_true(night["knocked_out"])
	assert_eq(gs.clock.time_string(), "06:00")


func test_bandage_heals_and_a_night_heals() -> void:
	var gs := _game()
	Combat.set_hp(gs, _db, 4)
	Commands.perform(gs, _db, "bandage_wound")
	assert_eq(Combat.hp(gs, _db), 10, "+6")
	assert_has(gs.combat.lines, "You recover 6 HP.")
	gs.clock.advance(14 * 60)
	Commands.sleep(gs, _db)
	assert_eq(gs.player.hp, -1, "a night's sleep heals to full")
	Combat.set_hp(gs, _db, 3)
	gs.clock.advance(int(_db.rules["clock"]["collapse_after_awake"]))
	Commands.sleep(gs, _db)
	assert_eq(Combat.hp(gs, _db), 10, "a collapse heals to half")


func test_set_hp_stores_full_as_minus_one() -> void:
	var gs := _game()
	assert_eq(Combat.hp(gs, _db), 20)
	Combat.set_hp(gs, _db, 25)
	assert_eq(gs.player.hp, -1)
	Combat.set_hp(gs, _db, -4)
	assert_eq(gs.player.hp, 0)


func test_unknown_monster_type_is_refused() -> void:
	var gs := _game()
	assert_eq(Combat.add_monster(gs, _db, "dragon", EAST), "")
	assert_ne(Commands.spawn_monster(gs, _db, "dragon", EAST)["error"], "")
	assert_ne(Commands.spawn_monster(gs, _db, "goblin", Vector2i(0, 0))["error"], "", "a wall")
	assert_ne(Commands.spawn_monster(gs, _db, "goblin", gs.player.pos())["error"], "")
	var ok := Commands.spawn_monster(gs, _db, "goblin", EAST)
	assert_eq(ok["error"], "")
	assert_eq(gs.combat.at("town", EAST), ok["id"])
	assert_ne(Commands.spawn_monster(gs, _db, "goblin", EAST)["error"], "", "taken")


func test_monster_ids_sort_by_number() -> void:
	var gs := _game()
	gs.combat.next_id = 9
	var a := ToyCombat.spawn(gs, _db, "goblin", EAST)
	var b := ToyCombat.spawn(gs, _db, "goblin", NORTH)
	assert_eq([a, b], ["m9", "m10"])
	assert_eq(gs.combat.ids(), ["m9", "m10"] as Array[String])


func _play(seed_value: int) -> String:
	var gs := _game(seed_value)
	var gob := ToyCombat.spawn(gs, _db, "goblin", EAST)
	for i in 6:
		Commands.attack(gs, _db, "e")
		if gs.combat.monsters.has(gob):
			Combat.monster_attack(gs, _db, gob)
	return gs.to_json()


func test_same_seed_same_fight() -> void:
	assert_eq(_play(7), _play(7))
	assert_ne(_play(7), _play(8))


func test_combat_state_survives_save_and_load() -> void:
	var gs := _game()
	var gob := ToyCombat.spawn(gs, _db, "goblin", EAST)
	ToyCombat.spawn(gs, _db, "crab", NORTH, CombatState.HIDDEN)
	gs.player.held = "stick"
	Commands.attack(gs, _db, "e")
	Commands.block(gs, _db)
	Combat.monster_attack(gs, _db, gob)
	var text := gs.to_json()
	var loaded := GameState.from_json(text)
	assert_eq(loaded.to_json(), text)
	assert_eq(typeof(loaded.combat.monsters[gob]["hp"]), TYPE_INT)
	assert_eq(typeof(loaded.combat.fight["attacks"]), TYPE_INT)
	assert_eq(loaded.player.held, "stick")
	assert_eq(loaded.player.hp, gs.player.hp)
	assert_true(loaded.combat.blocking)
