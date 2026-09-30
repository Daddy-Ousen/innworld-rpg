extends GutTest
## Skills in combat (M17.4, ADR 0027): ap_mod, the [Runner] move cap, strike,
## area and self combat actions, cooldowns in rounds, save v19, and NPC
## allies' Skills (real data).
## Toy arena (ToyCombat): monsters frozen, every blow hits, an unarmed blow does
## 4 (strength adds nothing). Toy Skills are named "[S]".

var _db: DataDb


func before_each() -> void:
	_db = ToyCombat.db()
	ToyCombat.tactical(_db)
	ToyCombat.always_hit(_db)
	ToyCombat.freeze(_db)
	_db.rules["combat"]["unarmed"]["damage"] = [4, 4]
	_db.rules["combat"]["strength_div"] = 1000
	_skill("power", {"kind": "strike", "ap_q": 12, "cooldown": 2, "damage_mult": 2.0})
	_skill("thrice", {"kind": "strike", "ap_q": 16, "cooldown": 3, "hits": 3})
	_skill("sure_throw", {"kind": "strike", "ap_q": 8, "cooldown": 1, "thrown": true, "sure_hit": true})
	_skill("cleave", {"kind": "area", "shape": "around", "ap_q": 16, "cooldown": 3})
	_skill("mend", {"kind": "self", "ap_q": 8, "cooldown": 5, "heal": 0.5})
	_skill("sprint", {"kind": "self", "ap_q": 2, "cooldown": 3, "move_q": 4})
	_db.skills["stamina"] = ToyData._skill("common", [], {}, [{"type": "ap_mod", "value_q": 4}])


func _skill(id: String, action: Dictionary) -> void:
	var a := {"type": "combat_action"}
	a.merge(action)
	_db.skills[id] = ToyData._skill("common", [], {}, [a])


func _give(gs: GameState, id: String) -> void:
	gs.progression.skills.append({"id": id, "class": "warrior", "level": 1, "day": 1})


func _game(at: Vector2i, seed_value: int = 1) -> GameState:
	var gs := ToyCombat.new_game(_db, seed_value)
	ToyCombat.to_arena(gs, _db, at)
	return gs


## A hostile monster at `at` with `hp` (above its max: it neither falls nor
## runs); the encounter starts.
func _foe(gs: GameState, type: String, at: Vector2i, hp: int = 30) -> String:
	var id := ToyCombat.spawn(gs, _db, type, at)
	gs.combat.monsters[id]["hp"] = hp
	return id


func _start(gs: GameState) -> void:
	Commands.wait(gs, _db, 0)
	assert_true(Encounter.is_player_turn(gs), "the fight is on and it is the player's turn")


func _hp(gs: GameState, id: String) -> int:
	return int(gs.combat.monsters[id]["hp"])


# --- AP and move cap ---

func test_an_ap_mod_skill_adds_ap_every_turn() -> void:
	var gs := _game(Vector2i(2, 4))
	_give(gs, "stamina")
	assert_eq(Encounter.player_ap(gs, _db), 28, "6 AP + 1")
	_foe(gs, "goblin", Vector2i(2, 7))
	_start(gs)
	assert_eq(int(gs.combat.encounter["ap_q"]), 28)


func test_the_runner_class_moves_eight_tiles() -> void:
	_db.classes["runner"] = ToyData._class({"combat": 1.0}, 50, {"combat": {"move_ap_mod_q": 4}})
	var gs := _game(Vector2i(1, 7))
	assert_eq(CombatSkills.move_cap_q(gs, _db), 4)
	ToyData.give_class(gs, "runner")
	assert_eq(CombatSkills.move_cap_q(gs, _db), 8, "2 AP of movement")
	_foe(gs, "goblin", Vector2i(12, 1))
	_start(gs)
	assert_eq(Encounter.reach(gs, _db).size() > 0, true)
	for i in 8:
		assert_true(Commands.move(gs, _db, "e")["moved"], "step %d" % (i + 1))
	assert_eq(gs.player.pos(), Vector2i(9, 7))
	assert_eq(Commands.move(gs, _db, "e")["error"], Encounter.NO_MOVE)


# --- Strike ---

func test_a_strike_skill_hits_harder_and_costs_its_ap() -> void:
	var gs := _game(Vector2i(2, 4))
	_give(gs, "power")
	var g := _foe(gs, "goblin", Vector2i(2, 5))
	_start(gs)
	var r := Commands.use_skill(gs, _db, "power", g)
	assert_eq(r["error"], "")
	assert_eq(_hp(gs, g), 22, "4 x 2 = 8")
	assert_eq(int(gs.combat.encounter["ap_q"]), 12, "3 AP spent")
	assert_true(gs.combat.lines.has("You use [S]."), str(gs.combat.lines))
	var log: Array = gs.combat.turns[-1]["strikes"]
	assert_eq(log.size(), 1, "the blow is in the turn log")
	assert_eq(int(log[0]["damage"]), 8)


func test_a_skill_cools_down_for_its_rounds() -> void:
	var gs := _game(Vector2i(2, 4))
	_give(gs, "power")
	var g := _foe(gs, "goblin", Vector2i(2, 5))
	_start(gs)
	Commands.use_skill(gs, _db, "power", g)
	assert_eq(CombatSkills.rounds_left(gs, Encounter.PLAYER, "power"), 2)
	var again := Commands.use_skill(gs, _db, "power", g)
	assert_eq(again["error"], "[S] is not ready (2 more rounds).")
	assert_eq(_hp(gs, g), 22, "a refused Skill does nothing")
	assert_eq(Commands.end_turn(gs, _db), "")
	assert_eq(CombatSkills.rounds_left(gs, Encounter.PLAYER, "power"), 1)
	assert_eq(Commands.use_skill(gs, _db, "power", g)["error"], "[S] is not ready (1 more round).")
	Commands.end_turn(gs, _db)
	assert_eq(CombatSkills.rounds_left(gs, Encounter.PLAYER, "power"), 0)
	assert_eq(Commands.use_skill(gs, _db, "power", g)["error"], "")
	assert_eq(_hp(gs, g), 14)


func test_a_many_hit_strike_rolls_each_blow() -> void:
	var gs := _game(Vector2i(2, 4))
	_give(gs, "thrice")
	var g := _foe(gs, "goblin", Vector2i(3, 4))
	_start(gs)
	var r := Commands.use_skill(gs, _db, "thrice", g)
	assert_eq((r["strikes"] as Array).size(), 3)
	assert_eq(_hp(gs, g), 18)
	assert_eq(gs.player.facing, "e", "the player turns to the foe")


func test_a_many_hit_strike_stops_when_the_foe_falls() -> void:
	var gs := _game(Vector2i(2, 4))
	_give(gs, "thrice")
	var g := _foe(gs, "goblin", Vector2i(3, 4), 30)
	_start(gs)
	gs.combat.monsters[g]["hp"] = 4
	var r := Commands.use_skill(gs, _db, "thrice", g)
	assert_eq((r["strikes"] as Array).size(), 1)
	assert_false(gs.combat.monsters.has(g))


func test_a_melee_strike_needs_a_foe_side_by_side() -> void:
	var gs := _game(Vector2i(2, 4))
	_give(gs, "power")
	var g := _foe(gs, "goblin", Vector2i(3, 5))
	_start(gs)
	assert_eq(CombatSkills.why_not(gs, _db, "power", g), CombatSkills.NO_FOE, "a diagonal is not in reach")
	assert_eq(CombatSkills.targets(gs, _db, "power"), [] as Array[String])
	assert_eq(CombatSkills.why_not(gs, _db, "power", "nobody"), CombatSkills.NO_FOE)


func test_a_sure_throw_never_misses_and_uses_the_held_item() -> void:
	ToyCombat.never_hit(_db)
	var gs := _game(Vector2i(2, 4))
	_give(gs, "sure_throw")
	var g := _foe(gs, "goblin", Vector2i(2, 7))
	_start(gs)
	assert_eq(CombatSkills.why_not(gs, _db, "sure_throw", g), "You hold nothing to throw.")
	gs.player.held = "stick"
	assert_eq(CombatSkills.hit_chance(gs, _db, "sure_throw", g), 1.0)
	assert_eq(CombatSkills.targets(gs, _db, "sure_throw"), [g] as Array[String])
	var r := Commands.use_skill(gs, _db, "sure_throw", g)
	assert_eq(r["error"], "")
	assert_eq(_hp(gs, g), 28, "the stick's throw does 2")
	assert_eq(gs.player.held, "", "the item is gone")
	assert_true(gs.combat.turns[-1]["strikes"][0]["ranged"], "logged as a throw")


# --- Area ---

func test_an_area_skill_hits_every_foe_around() -> void:
	var gs := _game(Vector2i(2, 4))
	_give(gs, "cleave")
	var a := _foe(gs, "goblin", Vector2i(3, 4))
	var b := _foe(gs, "goblin", Vector2i(3, 5))
	var c := _foe(gs, "goblin", Vector2i(1, 3))
	var far := _foe(gs, "goblin", Vector2i(5, 4))
	_start(gs)
	assert_eq(CombatSkills.targets(gs, _db, "cleave").size(), 3)
	var r := Commands.use_skill(gs, _db, "cleave")
	assert_eq(r["error"], "")
	assert_eq([_hp(gs, a), _hp(gs, b), _hp(gs, c), _hp(gs, far)], [26, 26, 26, 30])
	assert_eq((gs.combat.turns[-1]["strikes"] as Array).size(), 3)


func test_an_area_skill_needs_a_foe_around() -> void:
	var gs := _game(Vector2i(2, 4))
	_give(gs, "cleave")
	_foe(gs, "goblin", Vector2i(5, 4))
	_start(gs)
	assert_eq(Commands.use_skill(gs, _db, "cleave")["error"], CombatSkills.NO_FOE_NEAR)
	assert_eq(int(gs.combat.encounter["ap_q"]), 24, "nothing paid")


# --- Self ---

func test_a_self_skill_heals() -> void:
	var gs := _game(Vector2i(2, 4))
	_give(gs, "mend")
	_foe(gs, "goblin", Vector2i(2, 7))
	_start(gs)
	var most := Stats.max_hp(gs, _db)
	Combat.set_hp(gs, _db, 1)
	var r := Commands.use_skill(gs, _db, "mend")
	assert_eq(r["error"], "")
	assert_eq(Combat.hp(gs, _db), mini(1 + roundi(most * 0.5), most))
	assert_eq(int(r["healed"]), Combat.hp(gs, _db) - 1)


func test_a_self_skill_moves_further_this_turn_only() -> void:
	var gs := _game(Vector2i(1, 7))
	_give(gs, "sprint")
	_foe(gs, "goblin", Vector2i(12, 1))
	_start(gs)
	assert_eq(Commands.use_skill(gs, _db, "sprint")["error"], "")
	assert_eq(CombatSkills.move_cap_q(gs, _db), 8)
	for i in 8:
		assert_true(Commands.move(gs, _db, "e")["moved"], "step %d" % (i + 1))
	Commands.end_turn(gs, _db)
	assert_eq(CombatSkills.move_cap_q(gs, _db), 4, "the bonus is gone next turn")


func test_the_turn_stays_open_while_a_self_skill_can_be_paid() -> void:
	var gs := _game(Vector2i(2, 4))
	_foe(gs, "goblin", Vector2i(2, 7))
	_start(gs)
	var e := gs.combat.encounter
	e["ap_q"] = 2
	e["moved_q"] = 4
	_give(gs, "sprint")
	assert_false(Encounter.maybe_end_turn(gs, _db), "0.5 AP pays for the sprint")
	gs.progression.skills.clear()
	assert_true(Encounter.maybe_end_turn(gs, _db))


# --- Refusals, seeds, saves ---

func test_skills_are_refused_outside_a_fight_and_without_the_skill() -> void:
	var gs := _game(Vector2i(2, 4))
	_give(gs, "mend")
	assert_eq(Commands.use_skill(gs, _db, "mend")["error"], CombatSkills.NOT_IN_FIGHT)
	_foe(gs, "goblin", Vector2i(2, 7))
	_start(gs)
	assert_eq(Commands.use_skill(gs, _db, "power")["error"], CombatSkills.UNKNOWN)
	gs.combat.encounter["ap_q"] = 4
	assert_eq(Commands.use_skill(gs, _db, "mend")["error"], Encounter.NO_AP)


func test_the_same_seed_gives_the_same_fight() -> void:
	_db.rules["combat"]["hit"]["min"] = 0.1
	_db.rules["combat"]["hit"]["max"] = 0.95
	var lines := []
	for i in 2:
		var gs := _game(Vector2i(2, 4), 11)
		_give(gs, "thrice")
		var g := _foe(gs, "goblin", Vector2i(2, 5))
		_start(gs)
		Commands.use_skill(gs, _db, "thrice", g)
		lines.append(gs.combat.lines.duplicate())
	assert_eq(lines[0], lines[1])


func test_cooldowns_are_saved() -> void:
	var gs := _game(Vector2i(2, 4))
	_give(gs, "power")
	var g := _foe(gs, "goblin", Vector2i(2, 5))
	_start(gs)
	Commands.use_skill(gs, _db, "power", g)
	var back := GameState.from_json(gs.to_json())
	assert_eq(CombatSkills.rounds_left(back, Encounter.PLAYER, "power"), 2)


func test_a_v18_save_with_a_fight_gets_empty_cooldowns() -> void:
	var gs := _game(Vector2i(2, 4))
	_foe(gs, "goblin", Vector2i(2, 7))
	_start(gs)
	var data := gs.to_dict()
	var e: Dictionary = data["combat"]["encounter"]
	e.erase("cool")
	e.erase("move_bonus_q")
	data["save_version"] = 18
	var back := GameState.from_dict(SaveMigrations.migrate(data))
	assert_eq(back.save_version, GameState.SAVE_VERSION)
	assert_eq(back.combat.encounter["cool"], {})
	assert_eq(int(back.combat.encounter["move_bonus_q"]), 0)


func test_bad_combat_actions_are_data_errors() -> void:
	var skills := {"bad": ToyData._skill("common", [], {}, [
		{"type": "combat_action", "kind": "fly", "ap_q": 99, "cooldown": -1}])}
	var d := DataDb.from_dicts({}, {}, ToyData.db().rules, {}, skills)
	var text := "\n".join(d.errors)
	assert_string_contains(text, "kind must be one of")
	assert_string_contains(text, "ap_q must be 1-40")
	assert_string_contains(text, "cooldown must be >= 0")


# --- Real data ---

func test_the_real_combat_skills_load() -> void:
	var d := DataDb.load_dir()
	assert_eq(d.errors, [] as Array[String])
	for id: String in ["power_strike", "unerring_throw", "quick_strike", "triple_thrust", "whirlwind_cleave",
			"mirage_cut", "minotaur_punch", "fast_sprint", "quick_recovery"]:
		assert_false(CombatSkills.action_of(d, id).is_empty(), id)
	assert_eq(int(d.skills["lesser_stamina"]["effects"][0]["value_q"]), 4)
	assert_eq(int(d.classes["runner"]["combat"]["move_ap_mod_q"]), 4)


func test_erin_learns_her_skills_with_the_canon() -> void:
	var d := DataDb.load_dir()
	var gs := GameState.new_game(1, d)
	assert_eq(CombatSkills.of_npc(gs, d, "erin_solstice"), [] as Array[String], "not before 1.56")
	gs.world.events["b1.calruz_trains_erin"] = {"status": CombatSkills.DONE}
	assert_eq(CombatSkills.of_npc(gs, d, "erin_solstice"), ["power_strike"] as Array[String])
	gs.world.events["b2.battle_at_the_wandering_inn"] = {"status": CombatSkills.DONE}
	assert_eq(CombatSkills.of_npc(gs, d, "erin_solstice"), ["minotaur_punch"] as Array[String],
			"[Power Strike] became [Minotaur Punch]")


func test_relc_uses_triple_thrust_in_a_fight() -> void:
	var d := DataDb.load_dir()
	var gs := GameState.new_game(20260930, d)
	gs.player.place("liscor_market", Vector2i(5, 5))
	Commands.settle(gs, d)
	gs.combat.monsters.clear()
	gs.combat.fight = {}
	for s: Dictionary in d.combat.spawns:
		gs.combat.spawn_last[s["id"]] = gs.clock.total_minutes
	var n: Dictionary = gs.npcs.npcs["relc"]
	n["area"] = gs.player.area
	n["x"] = 9
	n["y"] = 5
	var foe := Combat.add_monster(gs, d, "goblin_grunt", Vector2i(8, 7))
	gs.combat.monsters[foe]["hp"] = 200
	Commands.wait(gs, d, 0)
	var used := false
	for i in 20:
		if not Encounter.active(gs) or not gs.combat.monsters.has(foe):
			break
		used = used or gs.combat.lines.any(func(l: String) -> bool: return l.ends_with("uses [Triple Thrust]."))
		if used:
			break
		Combat.set_hp(gs, d, 9999)
		Commands.end_turn(gs, d)
	assert_true(used, "Relc uses his Skill")
	assert_gt(CombatSkills.rounds_left(gs, Encounter.NPC + "relc", "triple_thrust"), 0, "and it cools down")
