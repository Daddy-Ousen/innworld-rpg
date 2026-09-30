extends GutTest
## Casting spells in combat (M17.5, ADR 0027): AP and MP cost, the four shapes, walls
## stop a line, allies are never hit, cooldowns, armor, fight records, save v20 and NPC
## casters (real data).
## Toy arena (ToyCombat, 14 x 9, a wall at x = 6, y = 3-5): monsters frozen. Toy spells
## add no Intellect bonus (intellect_div 1000). The player has 6 MP (Intellect 3).

var _db: DataDb


func before_each() -> void:
	_db = ToyCombat.db()
	ToyCombat.tactical(_db)
	ToyCombat.always_hit(_db)
	ToyCombat.freeze(_db)
	_db.tags["magic"] = ""
	_db.actions["cast_spell"] = {"name": "Cast", "minutes": 5, "base_xp": 8, "risk": 0.5, "tags": {"magic": 1.0}}
	_db.spells = SpellDb.from_dicts({
		"bolt": _spell("one", 8, 2, {"range": 5, "damage": [4, 4]}),
		"gust": _spell("line", 8, 1, {"length": 5, "damage": [3, 3], "cooldown": 1}),
		"boom": _spell("blast", 12, 3, {"range": 5, "radius": 1, "damage": [5, 5]}),
		"burst": _spell("around", 8, 1, {"damage": [2, 2]}),
		"flicker": _spell("one", 4, 1, {"range": 5, "damage": [4, 4], "hit": "roll"}),
	})


func _spell(shape: String, ap_q: int, mp: int, extra: Dictionary) -> Dictionary:
	var s := {"name": "[S]", "shape": shape, "ap_q": ap_q, "mp": mp, "damage": [1, 1], "hit": "auto",
		"cooldown": 0, "intellect_div": 1000, "canon_ref": {"book": 1, "confidence": "guess"}}
	s.merge(extra, true)
	return s


func _game(at: Vector2i, spells: Array = ["bolt", "gust", "boom", "burst", "flicker"]) -> GameState:
	var gs := ToyCombat.new_game(_db)
	ToyCombat.to_arena(gs, _db, at)
	for id: String in spells:
		gs.progression.spells.append(id)
	return gs


func _foe(gs: GameState, type: String, at: Vector2i, hp: int = 30, state: String = CombatState.HOSTILE) -> String:
	var id := ToyCombat.spawn(gs, _db, type, at, state)
	gs.combat.monsters[id]["hp"] = hp
	return id


func _start(gs: GameState) -> void:
	Commands.wait(gs, _db, 0)
	assert_true(Encounter.is_player_turn(gs), "the fight is on and it is the player's turn")


func _hp(gs: GameState, id: String) -> int:
	return int(gs.combat.monsters[id]["hp"])


# --- One foe ---

func test_a_spell_costs_ap_and_mp_and_hurts_the_foe() -> void:
	var gs := _game(Vector2i(2, 4))
	var g := _foe(gs, "goblin", Vector2i(2, 7))
	_start(gs)
	var r := Commands.cast(gs, _db, "bolt", Vector2i(2, 7))
	assert_eq(r["error"], "")
	assert_eq(_hp(gs, g), 26)
	assert_eq(Mana.current(gs, _db), 4, "2 MP")
	assert_eq(int(gs.combat.encounter["ap_q"]), 16, "2 AP of 6")
	assert_true("You cast [S]." in gs.combat.lines)


func test_the_turn_log_has_a_ranged_blow_and_the_tiles() -> void:
	var gs := _game(Vector2i(2, 4))
	var g := _foe(gs, "goblin", Vector2i(2, 7))
	_start(gs)
	Commands.cast(gs, _db, "bolt", Vector2i(2, 7))
	var turn: Dictionary = gs.combat.turns[0]
	assert_eq(turn["id"], Encounter.PLAYER)
	assert_eq(turn["strikes"].size(), 1)
	assert_eq(turn["strikes"][0]["target"], g)
	assert_true(turn["strikes"][0]["ranged"])
	assert_eq(turn["strikes"][0]["damage"], 4)
	assert_eq(turn["cells"], [Vector2i(2, 7)] as Array[Vector2i])


func test_a_foe_out_of_range_is_refused_and_costs_nothing() -> void:
	var gs := _game(Vector2i(1, 1))
	_foe(gs, "goblin", Vector2i(9, 1))
	_start(gs)
	var r := Commands.cast(gs, _db, "bolt", Vector2i(9, 1))
	assert_eq(r["error"], Spells.TOO_FAR)
	assert_eq(Mana.current(gs, _db), 6)
	assert_eq(int(gs.combat.encounter["ap_q"]), 24)


func test_an_empty_tile_is_no_target() -> void:
	var gs := _game(Vector2i(2, 4))
	_foe(gs, "goblin", Vector2i(2, 7))
	_start(gs)
	assert_eq(Commands.cast(gs, _db, "bolt", Vector2i(3, 7))["error"], Spells.NO_FOE)


func test_too_little_mana_is_refused() -> void:
	var gs := _game(Vector2i(2, 4))
	_foe(gs, "goblin", Vector2i(2, 7))
	_start(gs)
	Mana.set_mp(gs, _db, 1)
	assert_eq(Commands.cast(gs, _db, "bolt", Vector2i(2, 7))["error"], Spells.NO_MP)
	assert_eq(Mana.current(gs, _db), 1)
	assert_eq(int(gs.combat.encounter["ap_q"]), 24)


func test_too_little_ap_is_refused() -> void:
	var gs := _game(Vector2i(2, 4))
	_foe(gs, "goblin", Vector2i(2, 7))
	_start(gs)
	gs.combat.encounter["ap_q"] = 4
	assert_eq(Commands.cast(gs, _db, "bolt", Vector2i(2, 7))["error"], Encounter.NO_AP)
	assert_eq(Mana.current(gs, _db), 6)


func test_an_unknown_spell_is_refused() -> void:
	var gs := _game(Vector2i(2, 4), [])
	_foe(gs, "goblin", Vector2i(2, 7))
	_start(gs)
	assert_eq(Commands.cast(gs, _db, "bolt", Vector2i(2, 7))["error"], Spells.NOT_KNOWN)
	assert_eq(Commands.cast(gs, _db, "nope", Vector2i(2, 7))["error"], Spells.NOT_KNOWN)


func test_a_spell_is_for_fights_only() -> void:
	var gs := _game(Vector2i(2, 4))
	assert_eq(Commands.cast(gs, _db, "bolt", Vector2i(2, 7))["error"], Spells.NOT_IN_FIGHT)


func test_armor_cuts_spell_damage_to_at_least_one() -> void:
	var gs := _game(Vector2i(2, 4))
	var c := _foe(gs, "crab", Vector2i(2, 7))
	_start(gs)
	Commands.cast(gs, _db, "bolt", Vector2i(2, 7))
	assert_eq(_hp(gs, c), 29, "4 - armor 4 = 0, at least 1")


func test_intellect_adds_to_spell_damage() -> void:
	_db.spells.spells["bolt"]["intellect_div"] = 1
	var gs := _game(Vector2i(2, 4))
	var g := _foe(gs, "goblin", Vector2i(2, 7))
	_start(gs)
	Commands.cast(gs, _db, "bolt", Vector2i(2, 7))
	assert_eq(_hp(gs, g), 23, "4 + Intellect 3")


func test_a_roll_spell_can_miss_and_still_costs() -> void:
	ToyCombat.never_hit(_db)
	var gs := _game(Vector2i(2, 4))
	var g := _foe(gs, "goblin", Vector2i(2, 7))
	_start(gs)
	var r := Commands.cast(gs, _db, "flicker", Vector2i(2, 7))
	assert_eq(r["error"], "")
	assert_eq(_hp(gs, g), 30)
	assert_eq(Mana.current(gs, _db), 5)
	assert_eq(int(gs.combat.encounter["ap_q"]), 20)


func test_hit_chance_is_one_for_an_auto_spell() -> void:
	var gs := _game(Vector2i(2, 4))
	var g := _foe(gs, "goblin", Vector2i(2, 7))
	assert_eq(Spells.hit_chance(gs, _db, "bolt", g), 1.0)


# --- Shapes ---

func test_a_line_hits_every_foe_on_it_and_stops_at_a_wall() -> void:
	var gs := _game(Vector2i(3, 4))
	var a := _foe(gs, "goblin", Vector2i(4, 4))
	var b := _foe(gs, "goblin", Vector2i(5, 4))
	var behind := _foe(gs, "goblin", Vector2i(7, 4))
	_start(gs)
	var r := Commands.cast(gs, _db, "gust", Vector2i(9, 4))
	assert_eq(r["error"], "")
	assert_eq(_hp(gs, a), 27)
	assert_eq(_hp(gs, b), 27)
	assert_eq(_hp(gs, behind), 30, "the wall at x = 6 stops the line")
	assert_eq(r["cells"], [Vector2i(4, 4), Vector2i(5, 4)] as Array[Vector2i])


func test_a_line_needs_a_direction_and_a_foe_on_it() -> void:
	var gs := _game(Vector2i(3, 4))
	_foe(gs, "goblin", Vector2i(3, 8))
	_start(gs)
	assert_eq(Commands.cast(gs, _db, "gust", Vector2i(3, 4))["error"], Spells.NO_DIR)
	assert_eq(Commands.cast(gs, _db, "gust", Vector2i(5, 4))["error"], Spells.NO_FOE_LINE)
	assert_eq(Commands.cast(gs, _db, "gust", Vector2i(3, 6))["error"], "", "south: the foe at (3,8) is 4 away")


func test_a_line_length_is_limited() -> void:
	_db.spells.spells["gust"]["length"] = 2
	var gs := _game(Vector2i(3, 0))
	var near := _foe(gs, "goblin", Vector2i(3, 2))
	var far := _foe(gs, "goblin", Vector2i(3, 3))
	_start(gs)
	Commands.cast(gs, _db, "gust", Vector2i(3, 8))
	assert_eq(_hp(gs, near), 27)
	assert_eq(_hp(gs, far), 30)


func test_a_blast_hits_the_foes_round_the_aim_tile() -> void:
	var gs := _game(Vector2i(2, 1))
	var a := _foe(gs, "goblin", Vector2i(5, 1))
	var b := _foe(gs, "goblin", Vector2i(6, 2))
	var out := _foe(gs, "goblin", Vector2i(8, 1))
	_start(gs)
	var r := Commands.cast(gs, _db, "boom", Vector2i(5, 1))
	assert_eq(r["error"], "")
	assert_eq(_hp(gs, a), 25)
	assert_eq(_hp(gs, b), 25)
	assert_eq(_hp(gs, out), 30)
	assert_eq(Mana.current(gs, _db), 3)


func test_a_blast_aim_must_be_in_range_and_hit_a_foe() -> void:
	var gs := _game(Vector2i(2, 1))
	_foe(gs, "goblin", Vector2i(5, 1))
	_start(gs)
	assert_eq(Commands.cast(gs, _db, "boom", Vector2i(12, 1))["error"], Spells.TOO_FAR)
	assert_eq(Commands.cast(gs, _db, "boom", Vector2i(2, 5))["error"], Spells.NO_FOE)


func test_an_around_spell_hits_the_eight_tiles() -> void:
	var gs := _game(Vector2i(2, 4))
	var side := _foe(gs, "goblin", Vector2i(3, 4))
	var diag := _foe(gs, "goblin", Vector2i(1, 3))
	var two := _foe(gs, "goblin", Vector2i(2, 6))
	_start(gs)
	Commands.cast(gs, _db, "burst", Vector2i(0, 0))
	assert_eq(_hp(gs, side), 28)
	assert_eq(_hp(gs, diag), 28)
	assert_eq(_hp(gs, two), 30)


func test_an_around_spell_needs_a_foe_next_to_you() -> void:
	var gs := _game(Vector2i(2, 4))
	_foe(gs, "goblin", Vector2i(2, 7))
	_start(gs)
	assert_eq(Commands.cast(gs, _db, "burst", Vector2i(2, 4))["error"], Spells.NO_FOE_NEAR)


func test_helpers_are_never_hit() -> void:
	var gs := _game(Vector2i(2, 1))
	var foe := _foe(gs, "goblin", Vector2i(5, 1))
	var friend := _foe(gs, "goblin", Vector2i(6, 1), 30, CombatState.ALLY)
	_start(gs)
	Commands.cast(gs, _db, "boom", Vector2i(5, 1))
	assert_eq(_hp(gs, foe), 25)
	assert_eq(_hp(gs, friend), 30, "an allied monster in the blast is spared")


# --- Cooldown, save, records ---

func test_a_cooldown_counts_rounds() -> void:
	var gs := _game(Vector2i(3, 4))
	_foe(gs, "goblin", Vector2i(4, 4), 90)
	_start(gs)
	Commands.cast(gs, _db, "gust", Vector2i(9, 4))
	var again := Commands.cast(gs, _db, "gust", Vector2i(9, 4))
	assert_true(String(again["error"]).begins_with("[S] is not ready"))
	assert_eq(CombatSkills.rounds_left(gs, Encounter.PLAYER, "spell:gust"), 1)
	Commands.end_turn(gs, _db)
	assert_eq(CombatSkills.rounds_left(gs, Encounter.PLAYER, "spell:gust"), 0, "a new round takes one off")
	assert_eq(Commands.cast(gs, _db, "gust", Vector2i(9, 4))["error"], "")


func test_a_spell_cooldown_never_blocks_a_skill_of_the_same_name() -> void:
	var gs := _game(Vector2i(3, 4))
	_foe(gs, "goblin", Vector2i(4, 4), 90)
	_start(gs)
	Commands.cast(gs, _db, "gust", Vector2i(9, 4))
	assert_eq(CombatSkills.rounds_left(gs, Encounter.PLAYER, "gust"), 0)


func test_mana_and_cooldowns_survive_a_save() -> void:
	var gs := _game(Vector2i(3, 4))
	_foe(gs, "goblin", Vector2i(4, 4), 90)
	_start(gs)
	Commands.cast(gs, _db, "gust", Vector2i(9, 4))
	var back := GameState.from_json(gs.to_json())
	assert_eq(Mana.current(back, _db), 5)
	assert_eq(CombatSkills.rounds_left(back, Encounter.PLAYER, "spell:gust"), 1)
	assert_eq(back.progression.spells.size(), 5)


func test_the_turn_stays_open_while_a_spell_is_castable() -> void:
	var gs := _game(Vector2i(2, 4), ["flicker"])
	_foe(gs, "goblin", Vector2i(2, 7), 90)
	_start(gs)
	gs.combat.encounter["ap_q"] = 8
	gs.combat.encounter["moved_q"] = 4
	assert_eq(Spells.castable(gs, _db), ["flicker"] as Array[String])
	assert_false(Encounter.maybe_end_turn(gs, _db), "a 1 AP spell can still be paid")
	Mana.set_mp(gs, _db, 0)
	assert_eq(Spells.castable(gs, _db), [] as Array[String])


func test_a_fight_with_casts_writes_a_magic_record() -> void:
	var gs := _game(Vector2i(2, 4))
	_foe(gs, "goblin", Vector2i(2, 7), 4)
	_start(gs)
	Commands.cast(gs, _db, "bolt", Vector2i(2, 7))
	assert_false(Encounter.active(gs), "the foe died, the fight is over")
	var ids: Array = gs.action_log.records.map(func(r: Dictionary) -> String: return r["action_id"])
	assert_true(ids.has("cast_spell"), "the casts became [Cast a spell at an enemy]")


func test_a_kill_by_spell_counts_as_a_kill() -> void:
	var gs := _game(Vector2i(2, 4))
	_foe(gs, "goblin", Vector2i(2, 7), 4)
	_start(gs)
	Commands.cast(gs, _db, "bolt", Vector2i(2, 7))
	assert_true("The Goblin dies." in gs.combat.lines)


func test_the_same_seed_gives_the_same_fight() -> void:
	var lines: Array = []
	for i in 2:
		var gs := _game(Vector2i(2, 1))
		ToyCombat.never_hit(_db)
		_foe(gs, "goblin", Vector2i(5, 1), 90)
		_start(gs)
		Commands.cast(gs, _db, "flicker", Vector2i(5, 1))
		lines.append(str(gs.combat.lines) + str(gs.rng.randf()))
	assert_eq(lines[0], lines[1])


# --- Real data ---

func test_the_shipped_spells_load_with_their_numbers_in_range() -> void:
	var d := DataDb.load_dir()
	assert_eq(d.errors, [] as Array[String])
	for id in d.spells.ids():
		var s: Dictionary = d.spells.spells[id]
		assert_between(int(s["mp"]), 1, 10, id)
		assert_between(int(s["ap_q"]), 1, 40, id)
	assert_eq(String(d.spells.spells["frozen_wind"]["shape"]), "line")
	assert_eq(String(d.spells.spells["fireball"]["shape"]), "blast")


func test_ceria_casts_in_a_fight_only_with_her_canon() -> void:
	var d := DataDb.load_dir()
	var gs := GameState.new_game(20260930, d)
	assert_eq(Spells.of_npc(gs, d, "ceria_springwalker"), [] as Array[String], "not before the canon")
	gs.world.events["b1.gazi_hunts_for_ryoka"] = {"status": Spells.DONE}
	assert_eq(Spells.of_npc(gs, d, "ceria_springwalker"), ["flashfire"] as Array[String])
	gs.world.events["b2.ceria_reveals_earthers_reforms_horns"] = {"status": Spells.DONE}
	assert_eq(Spells.of_npc(gs, d, "ceria_springwalker"), ["flashfire", "ice_spike"] as Array[String])
	assert_eq(Spells.of_npc(gs, d, "pisces"), [] as Array[String])


func test_an_npc_caster_casts_at_a_foe_from_afar() -> void:
	var d := DataDb.load_dir()
	var gs := GameState.new_game(20260930, d)
	gs.player.place("liscor_market", Vector2i(5, 5))
	Commands.settle(gs, d)
	gs.combat.monsters.clear()
	gs.combat.fight = {}
	for s: Dictionary in d.combat.spawns:
		gs.combat.spawn_last[s["id"]] = gs.clock.total_minutes
	gs.world.events["b2.ceria_reveals_earthers_reforms_horns"] = {"status": Spells.DONE}
	gs.world.add_relationship("ceria_springwalker", NpcSim.PLAYER, 20)
	var n: Dictionary = gs.npcs.npcs["ceria_springwalker"]
	n["area"] = gs.player.area
	n["x"] = 9
	n["y"] = 5
	var foe := Combat.add_monster(gs, d, "goblin_grunt", Vector2i(5, 9))
	gs.combat.monsters[foe]["hp"] = 400
	Commands.wait(gs, d, 0)
	var cast := false
	for i in 20:
		if not Encounter.active(gs) or not gs.combat.monsters.has(foe):
			break
		cast = cast or gs.combat.lines.any(func(l: String) -> bool: return l.ends_with("casts [Ice Spike]."))
		if cast:
			break
		Combat.set_hp(gs, d, 9999)
		Commands.end_turn(gs, d)
	assert_true(cast, "Ceria casts [Ice Spike]")
	assert_lt(Spells.npc_mp(gs, d, "ceria_springwalker"), 12, "and it cost her mana")


func test_bad_npc_spell_data_is_an_error() -> void:
	var d := DataDb.load_dir()
	var fight: Dictionary = d.behaviour.npcs["pisces"]["combat"]
	fight["spells"] = [{"id": "nope"}, {"id": "frozen_wind", "after_event": "no.such.event"}]
	fight["mp"] = 0
	d.behaviour.errors.clear()
	var errs := d.behaviour.validate(d)
	assert_true(errs.any(func(e: String) -> bool: return e.contains("pisces") and e.contains("needs mp")))
	assert_true(errs.any(func(e: String) -> bool: return e.contains("nope") and e.contains("not a spell")))
	assert_true(errs.any(func(e: String) -> bool: return e.contains("unknown after_event")))
