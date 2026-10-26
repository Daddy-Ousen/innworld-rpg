extends GutTest
## Spells that do something other than damage (M33.0, ADR 0044, SpellEffects): hold
## ([Astral Binding]), blink ([Flash Step]), hide ([Invisibility]) and wall ([Ice Wall]);
## their rounds, the save, and the data checks. Toy arena (ToyCombat, 14 x 9, a wall at
## x = 6, y = 3-5). Monsters act (not frozen) and always hit.

var _db: DataDb


func before_each() -> void:
	_db = ToyCombat.db()
	ToyCombat.tactical(_db)
	ToyCombat.always_hit(_db)
	_db.tags["magic"] = ""
	_db.actions["cast_spell"] = {"name": "Cast", "minutes": 5, "base_xp": 8, "risk": 0.5, "tags": {"magic": 1.0}}
	_db.spells = SpellDb.from_dicts({
		"bind": _spell("one", {"effect": "hold", "range": 5, "rounds": 1}),
		"step": _spell("tile", {"effect": "blink", "range": 3}),
		"veil": _spell("self", {"effect": "hide", "rounds": 2}),
		"ice": _spell("tile", {"effect": "wall", "range": 4, "length": 3, "rounds": 2}),
	})


func _spell(shape: String, extra: Dictionary) -> Dictionary:
	var s := {"name": "[S]", "shape": shape, "ap_q": 4, "mp": 1, "hit": "auto", "cooldown": 0,
		"canon_ref": {"book": 1, "confidence": "guess"}}
	s.merge(extra, true)
	return s


func _game(at: Vector2i) -> GameState:
	var gs := ToyCombat.new_game(_db)
	ToyCombat.to_arena(gs, _db, at)
	for id: String in ["bind", "step", "veil", "ice"]:
		gs.progression.spells.append(id)
	return gs


func _foe(gs: GameState, at: Vector2i) -> String:
	var id := ToyCombat.spawn(gs, _db, "goblin", at, CombatState.HOSTILE)
	gs.combat.monsters[id]["hp"] = 90
	return id


func _start(gs: GameState) -> void:
	Commands.wait(gs, _db, 0)
	assert_true(Encounter.is_player_turn(gs), "the fight is on and it is the player's turn")
	Combat.set_hp(gs, _db, 9999)


# --- hold ---

func test_a_bound_foe_loses_its_next_turn_then_acts() -> void:
	var gs := _game(Vector2i(2, 4))
	_foe(gs, Vector2i(2, 5))
	_start(gs)
	assert_eq(Commands.cast(gs, _db, "bind", Vector2i(2, 5))["error"], "")
	var hp := Combat.hp(gs, _db)
	Commands.end_turn(gs, _db)
	assert_eq(Combat.hp(gs, _db), hp, "held: no blow")
	assert_true(gs.combat.lines.any(func(l: String) -> bool: return l.contains("strains against")))
	assert_false(gs.combat.encounter.get("held", {}).has("m1"), "one round only")
	Commands.end_turn(gs, _db)
	assert_lt(Combat.hp(gs, _db), hp, "free again, it hits")


func test_a_hold_needs_a_foe() -> void:
	var gs := _game(Vector2i(2, 4))
	_foe(gs, Vector2i(2, 7))
	_start(gs)
	assert_eq(Commands.cast(gs, _db, "bind", Vector2i(3, 4))["error"], Spells.NO_FOE)


# --- blink ---

func test_a_blink_moves_the_player() -> void:
	var gs := _game(Vector2i(2, 4))
	_foe(gs, Vector2i(2, 7))
	_start(gs)
	assert_eq(Commands.cast(gs, _db, "step", Vector2i(4, 4))["error"], "")
	assert_eq(gs.player.pos(), Vector2i(4, 4))


func test_a_blink_lands_only_on_a_free_tile_in_range() -> void:
	var gs := _game(Vector2i(5, 4))
	_foe(gs, Vector2i(5, 6))
	_start(gs)
	assert_eq(Spells.why_not(gs, _db, "step", Vector2i(5, 6)), SpellEffects.NO_LANDING, "a foe stands there")
	assert_eq(Spells.why_not(gs, _db, "step", Vector2i(5, 8)), Spells.TOO_FAR)
	assert_eq(Spells.why_not(gs, _db, "step", Vector2i(5, 4)), SpellEffects.NO_LANDING, "not where you stand")


# --- hide ---

func test_hidden_the_foes_cannot_find_you_for_two_rounds() -> void:
	var gs := _game(Vector2i(2, 4))
	_foe(gs, Vector2i(2, 5))
	_start(gs)
	assert_eq(Commands.cast(gs, _db, "veil", gs.player.pos())["error"], "")
	assert_true(SpellEffects.hidden(gs))
	var hp := Combat.hp(gs, _db)
	Commands.end_turn(gs, _db)
	Commands.end_turn(gs, _db)
	assert_eq(Combat.hp(gs, _db), hp, "two rounds with no blow")
	assert_false(SpellEffects.hidden(gs))
	assert_true("You can be seen again." in gs.combat.lines)
	Commands.end_turn(gs, _db)
	assert_lt(Combat.hp(gs, _db), hp)


func test_a_blow_ends_the_hiding() -> void:
	var gs := _game(Vector2i(2, 4))
	_foe(gs, Vector2i(2, 5))
	_start(gs)
	Commands.cast(gs, _db, "veil", gs.player.pos())
	Commands.attack(gs, _db, "s")
	assert_false(SpellEffects.hidden(gs))


# --- wall ---

func test_an_ice_wall_stands_across_the_aim_and_blocks_the_way() -> void:
	var gs := _game(Vector2i(2, 4))
	_foe(gs, Vector2i(2, 8))
	_start(gs)
	assert_eq(Commands.cast(gs, _db, "ice", Vector2i(2, 6))["error"], "")
	var ice := SpellEffects.wall_tiles(gs)
	assert_eq(ice.size(), 3)
	for at: Vector2i in [Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6)]:
		assert_true(ice.has(at), str(at))
	assert_false(Movement.can_enter(gs, _db, gs.player.area, Vector2i(2, 6)))
	assert_true(MonsterSim._taken(gs, "").has(Vector2i(2, 6)), "monsters path round it")


func test_a_shot_across_the_ice_meets_full_cover() -> void:
	var gs := _game(Vector2i(2, 4))
	_foe(gs, Vector2i(2, 8))
	_start(gs)
	var area := gs.player.area
	assert_eq(Cover.details(gs, _db, area, Vector2i(2, 8), Vector2i(2, 4), true, Cover.FOE)["cover"], Cover.NONE)
	Commands.cast(gs, _db, "ice", Vector2i(2, 6))
	assert_eq(Cover.details(gs, _db, area, Vector2i(2, 8), Vector2i(2, 4), true, Cover.FOE)["cover"], Cover.FULL)


func test_the_ice_skips_taken_tiles_and_melts_after_its_rounds() -> void:
	var gs := _game(Vector2i(2, 4))
	_foe(gs, Vector2i(3, 6))
	_start(gs)
	Commands.cast(gs, _db, "ice", Vector2i(2, 6))
	assert_false(SpellEffects.wall_tiles(gs).has(Vector2i(3, 6)), "not on the foe")
	Commands.end_turn(gs, _db)
	Commands.end_turn(gs, _db)
	assert_true(SpellEffects.wall_tiles(gs).is_empty())
	assert_true("The ice wall melts away." in gs.combat.lines)


# --- save ---

func test_held_hidden_and_ice_survive_a_save() -> void:
	var gs := _game(Vector2i(2, 4))
	var g := _foe(gs, Vector2i(2, 8))
	_start(gs)
	Commands.cast(gs, _db, "ice", Vector2i(2, 6))
	gs.combat.encounter["held"] = {g: 1}
	gs.combat.encounter["hidden"] = 2
	var back := CombatState.from_dict(JSON.parse_string(JSON.stringify(gs.combat.to_dict())))
	gs.combat = back
	assert_true(SpellEffects.wall_tiles(gs).has(Vector2i(2, 6)))
	assert_true(SpellEffects.hidden(gs))
	assert_true(SpellEffects.skip_held(gs, _db, g))


# --- data ---

func test_bad_effect_data_is_reported() -> void:
	var bad := SpellDb.from_dicts({
		"a": _spell("line", {"effect": "hold", "length": 3, "rounds": 1}),
		"b": _spell("tile", {"effect": "wall", "range": 3, "rounds": 2}),
		"c": _spell("one", {"range": 3}),
		"d": _spell("self", {"effect": "teleport"}),
	})
	var errs := bad.validate(_db)
	assert_true(errs.any(func(e: String) -> bool: return e.contains("'a'") and e.contains("needs shape 'one'")))
	assert_true(errs.any(func(e: String) -> bool: return e.contains("'b'") and e.contains("length 1-5")))
	assert_true(errs.any(func(e: String) -> bool: return e.contains("'c'") and e.contains("damage must be")))
	assert_true(errs.any(func(e: String) -> bool: return e.contains("'d'") and e.contains("effect must be")))


func test_the_shipped_spells_have_the_four_new_kinds() -> void:
	var d := DataDb.load_dir()
	assert_eq(d.errors, [] as Array[String])
	assert_gte(d.spells.ids().size(), 17)
	var kinds := {}
	for id in d.spells.ids():
		kinds[SpellEffects.effect(d.spells.spells[id])] = id
	for k: String in SpellEffects.EFFECTS:
		assert_true(kinds.has(k), k)
