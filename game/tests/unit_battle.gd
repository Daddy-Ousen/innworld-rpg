extends GutTest
## Big battles (M7.B, ADR 0013) on the ToyNpcs world with toy combat and
## the ToyCombat arena: NPCs with hit points (down, not dead), monsters that
## go for fighting NPCs and helpers, helpers that fight for the player, and
## a staged fight in waves ("e.battle" in the arena, day 1–2, 06–22).

const EV := "e.battle"

var _db: DataDb


## ToyNpcs + toy combat + the arena (exit at 0,8 back to town), with `events`.
## A "hound" enemy (a goblin that acts every 6 s) serves as a helper.
func _make(events: Dictionary = {}) -> void:
	_db = ToyNpcs.combat_db(events)
	var areas := ToyMaps.areas()
	areas["arena"] = ToyMaps.area("arena", "toy_field", ToyCombat.ARENA, {}, [
		{"at": [0, 8], "to": "town", "arrive": [1, 1], "minutes": 0},
	], [])
	_db.maps = MapDb.from_dicts(ToyMaps.tiles(), areas)
	_db.maps.validate(_db)
	var enemies := ToyCombat.enemies()
	enemies["hound"] = (enemies["goblin"] as Dictionary).duplicate(true)
	enemies["hound"]["name"] = "Hound"
	_db.combat = CombatDb.from_dicts(enemies, ToyCombat.items())
	_db.combat.validate(_db)


func _wave(after: int, foes: Array, extra: Dictionary = {}) -> Dictionary:
	var w := {"after_seconds": after, "from": [13, 4], "foes": foes}
	w.merge(extra, true)
	return w


## The toy battle: one goblin at 10,4, then a wave of two goblins after
## 60 s, then one more with the farmer and a hound after 120 s (or when at
## most one foe is left).
func _battle(waves: Array = []) -> Dictionary:
	if waves.is_empty():
		waves = [_wave(60, ["goblin", "goblin"]),
			_wave(120, ["goblin"], {"left_at_most": 1, "allies": ["farmer"], "helpers": ["hound"],
				"line": "The farmer runs in with a hound."})]
	return {EV: ToyCanon.event(1, 2, {
		"stage": {"area": "arena", "hours": [6, 22], "foes": [{"enemy": "goblin", "pos": [10, 4]}],
			"waves": waves},
		"effects": {"set_flags": ["arena.battle"]}})}


## The player in the arena at 2,4 on day 1; one wait stages the battle.
func _in_arena(gs: GameState) -> void:
	gs.player.place("arena", Vector2i(2, 4))
	Commands.wait(gs, _db, 6)


func _foes(gs: GameState) -> Array[String]:
	return gs.combat.in_state(CombatState.HOSTILE)


func _kill(gs: GameState, id: String) -> void:
	Combat.damage_monster(gs, _db, id, 1000)


## Waits `seconds` in steps of 6 s.
func _wait(gs: GameState, seconds: int) -> void:
	for i in seconds / 6:
		Commands.wait(gs, _db, 6)


# --- NPC hit points and targets ---------------------------------------------

func test_react_stats_have_hit_points() -> void:
	_make()
	assert_eq(_db.behaviour.errors, [] as Array[String])
	assert_eq(int(NpcReact.stats(_db, "guard")["hp"]), 20, "a guard uses the fighter defaults")
	assert_eq(int(NpcReact.stats(_db, "farmer")["hp"]), 12, "anyone else the ally defaults")
	var real := DataDb.load_dir()
	assert_eq(int(NpcReact.stats(real, "klbkch")["hp"]), 80, "own combat block")


func test_a_monster_goes_for_the_nearest_fighting_npc() -> void:
	_make()
	var gs := ToyNpcs.new_game(_db)
	gs.player.place("town", Vector2i(6, 2))
	Commands.settle(gs, _db)
	gs.npcs.npcs["guard"]["x"] = 2
	gs.npcs.npcs["guard"]["y"] = 1
	var gob := ToyCombat.spawn(gs, _db, "goblin", Vector2i(2, 2))
	var t := Combat.monster_target(gs, _db, gob)
	assert_eq(t["kind"], Combat.NPC)
	assert_eq(t["id"], "guard")
	ToyCombat.always_hit(_db)
	var hit := Combat.monster_attack(gs, _db, gob, false, 0.0, t)
	assert_true(hit["hit"])
	assert_eq(Combat.npc_hp(gs, _db, "guard"), 18)
	assert_has(gs.combat.lines, "The Goblin attacks Guard: 2 damage.")
	assert_eq(Combat.hp(gs, _db), Stats.max_hp(gs, _db), "the player is untouched")


func test_a_bystander_is_never_a_target() -> void:
	_make()
	var gs := ToyNpcs.new_game(_db)
	gs.player.place("field", Vector2i(0, 2))
	Commands.settle(gs, _db)
	assert_eq(ToyNpcs.pos(gs, "farmer"), Vector2i(2, 1))
	var gob := ToyCombat.spawn(gs, _db, "goblin", Vector2i(3, 1))
	assert_eq(Combat.monster_target(gs, _db, gob)["kind"], Combat.PLAYER)


func test_an_npc_at_zero_hp_is_down_until_the_fight_ends() -> void:
	_make()
	ToyCombat.freeze(_db)
	var gs := ToyNpcs.new_game(_db)
	gs.player.place("town", Vector2i(6, 2))
	Commands.settle(gs, _db)
	var gob := ToyCombat.spawn(gs, _db, "goblin", Vector2i(6, 1))
	var at := ToyNpcs.pos(gs, "guard")
	assert_true(Combat.damage_npc(gs, _db, "guard", 100))
	assert_true(gs.npcs.npcs["guard"]["down"])
	assert_has(gs.combat.lines, "Guard falls.")
	assert_true(gs.world.is_alive(_db.canon, "guard"), "down, not dead")
	Commands.wait(gs, _db, 60)
	assert_eq(ToyNpcs.pos(gs, "guard"), at, "a fallen NPC lies still")
	assert_true(Combat.monster_target(gs, _db, gob)["kind"] == Combat.PLAYER, "and is no target")
	_kill(gs, gob)
	Commands.wait(gs, _db, 6)
	assert_false(gs.combat.has_fight())
	assert_false(gs.npcs.npcs["guard"]["down"], "up again after the fight")
	assert_eq(Combat.npc_hp(gs, _db, "guard"), 1)
	NpcSim.advance_to(gs, _db, NpcSim.world_sec(gs) + 10000)
	assert_eq(Combat.npc_hp(gs, _db, "guard"), 20, "a long gap (a night) heals")


# --- helpers ----------------------------------------------------------------

func test_a_helper_fights_foes_and_the_player_cannot_hit_it() -> void:
	_make()
	ToyCombat.always_hit(_db)
	_db.combat.enemies["goblin"]["act_seconds"] = 1000000
	var gs := ToyNpcs.new_game(_db)
	gs.player.place("arena", Vector2i(2, 4))
	Commands.settle(gs, _db)
	var gob := ToyCombat.spawn(gs, _db, "goblin", Vector2i(10, 4))
	var hound := ToyCombat.spawn(gs, _db, "hound", Vector2i(3, 4), CombatState.ALLY)
	assert_eq(Combat.name_of(_db, gs.combat.monsters[hound]), "allied Hound")
	assert_eq(Combat.nearest_foe(gs), gob, "a helper is no foe")
	var r := Commands.attack(gs, _db, "e")
	assert_eq(r["error"], Combat.REFUSED_HELPER % "Hound")
	gs.player.held = "stick"
	assert_eq(Combat.throw_at(gs, _db, hound)["error"], Combat.REFUSED_HELPER % "Hound")
	assert_false(Commands.move(gs, _db, "e")["moved"], "a helper blocks the way")
	var lines: Array[String] = []
	for i in 40:
		if not gs.combat.monsters.has(gob):
			break
		Commands.wait(gs, _db, 6)
		lines.append_array(gs.combat.lines)
	assert_false(gs.combat.monsters.has(gob), "the hound killed the goblin")
	assert_has(lines, "The allied Hound hits the Goblin for 2.")
	assert_false(gs.combat.monsters.has(hound), "helpers leave when the fight ends")
	assert_false(gs.combat.has_fight())


func test_a_foe_attacks_a_helper_next_to_it() -> void:
	_make()
	ToyCombat.always_hit(_db)
	var gs := ToyNpcs.new_game(_db)
	gs.player.place("arena", Vector2i(2, 4))
	Commands.settle(gs, _db)
	var gob := ToyCombat.spawn(gs, _db, "goblin", Vector2i(10, 4))
	var hound := ToyCombat.spawn(gs, _db, "hound", Vector2i(11, 4), CombatState.ALLY)
	var t := Combat.monster_target(gs, _db, gob)
	assert_eq(t["kind"], Combat.HELPER)
	Combat.monster_attack(gs, _db, gob, false, 0.0, t)
	assert_eq(int(gs.combat.monsters[hound]["hp"]), 6)
	assert_has(gs.combat.lines, "The Goblin attacks the allied Hound: 2 damage.")
	var kills := int(gs.combat.fight["kills"])
	Combat.damage_monster(gs, _db, hound, 100)
	assert_eq(int(gs.combat.fight["kills"]), kills, "a dead helper is no kill")


# --- waves ------------------------------------------------------------------

func test_toy_battle_data_is_valid() -> void:
	_make(_battle())
	assert_eq(_db.canon.errors, [] as Array[String])
	assert_eq(_db.combat.errors, [] as Array[String])


func test_waves_come_by_time() -> void:
	_make(_battle())
	ToyCombat.freeze(_db)
	var gs := ToyNpcs.new_game(_db)
	_in_arena(gs)
	assert_eq(_foes(gs).size(), 1)
	assert_eq(gs.combat.stage_run["event"], EV)
	assert_true(Stage.waves_left(gs, _db))
	assert_eq(Stage.foes_left(gs, _db), 4)
	_wait(gs, 48)
	assert_eq(_foes(gs).size(), 1, "not yet")
	_wait(gs, 12)
	assert_eq(_foes(gs).size(), 3, "wave 1 after 60 s")
	var near := 0
	for id in _foes(gs):
		if CombatState.pos_of(gs.combat.monsters[id]).x >= 12:
			near += 1
	assert_eq(near, 2, "at its from tile or next to it")
	_wait(gs, 60)
	assert_eq(_foes(gs).size(), 4, "wave 2 after 120 s")
	assert_false(Stage.waves_left(gs, _db))
	assert_eq(Stage.foes_left(gs, _db), 4)


func test_a_wave_comes_early_when_few_foes_are_left() -> void:
	_make(_battle())
	ToyCombat.freeze(_db)
	var gs := ToyNpcs.new_game(_db)
	_in_arena(gs)
	_wait(gs, 60)
	assert_eq(_foes(gs).size(), 3)
	_kill(gs, _foes(gs)[0])
	_kill(gs, _foes(gs)[0])
	Commands.wait(gs, _db, 6)
	assert_eq(_foes(gs).size(), 2, "one left: wave 2 comes before 120 s")
	assert_has(gs.combat.lines, "The farmer runs in with a hound.")


func test_a_wave_comes_at_once_when_the_map_is_clear() -> void:
	_make(_battle())
	ToyCombat.freeze(_db)
	var gs := ToyNpcs.new_game(_db)
	_in_arena(gs)
	_kill(gs, _foes(gs)[0])
	Commands.wait(gs, _db, 6)
	assert_true(gs.combat.has_fight(), "a staged fight with waves left goes on")
	assert_eq(_foes(gs).size(), 2, "wave 1 at once")


func test_max_on_map_holds_a_wave_back() -> void:
	_make(_battle())
	ToyCombat.freeze(_db)
	_db.rules["combat"]["stage"]["max_on_map"] = 3
	var gs := ToyNpcs.new_game(_db)
	_in_arena(gs)
	_wait(gs, 180)
	assert_eq(_foes(gs).size(), 3, "3 on the map: wave 2 waits")
	assert_true(Stage.waves_left(gs, _db))
	_kill(gs, _foes(gs)[0])
	Commands.wait(gs, _db, 6)
	assert_eq(_foes(gs).size(), 3, "room again: wave 2 comes")
	assert_false(Stage.waves_left(gs, _db))


func test_a_wave_brings_an_ally_from_another_area_and_a_helper() -> void:
	_make(_battle())
	ToyCombat.freeze(_db)
	var gs := ToyNpcs.new_game(_db)
	_in_arena(gs)
	assert_eq(ToyNpcs.area(gs, "farmer"), "field")
	_wait(gs, 120)
	assert_eq(ToyNpcs.area(gs, "farmer"), "arena", "moved into the fight")
	assert_true(NpcReact.is_ally(gs, _db, "farmer"), "a wave's ally is a stage ally")
	assert_eq(gs.combat.in_state(CombatState.ALLY).size(), 1, "the hound")


func test_an_ally_brought_in_during_a_long_step_stays_in_the_fight() -> void:
	_make(_battle([_wave(0, [], {"allies": ["farmer"], "line": "The farmer runs in."})]))
	ToyCombat.freeze(_db)
	var gs := ToyNpcs.new_game(_db)
	gs.player.place("arena", Vector2i(2, 4))
	Commands.wait(gs, _db, 600)  # longer than rules.npc.jump_seconds: the NPCs jump
	assert_true(gs.combat.has_fight())
	assert_eq(ToyNpcs.area(gs, "farmer"), "arena", "the wave's ally stays in the fight")
	_kill(gs, _foes(gs)[0])
	Commands.wait(gs, _db, 600)
	assert_false(gs.combat.has_fight())
	assert_eq(ToyNpcs.area(gs, "farmer"), "field", "after the fight it goes back to its goal")


func test_leaving_the_arena_drops_the_rest_of_the_stage() -> void:
	_make(_battle())
	ToyCombat.freeze(_db)
	var gs := ToyNpcs.new_game(_db)
	_in_arena(gs)
	gs.player.place("arena", Vector2i(1, 8))
	assert_true(ToyMaps.walk(gs, _db, ["w"]))
	assert_eq(gs.player.area, "town")
	assert_true(gs.combat.stage_run.is_empty())
	assert_false(gs.combat.has_fight())


func test_a_battle_is_the_same_with_the_same_seed_and_after_a_load() -> void:
	_make(_battle())
	var a := ToyNpcs.new_game(_db, 5)
	var b := ToyNpcs.new_game(_db, 5)
	_in_arena(a)
	_in_arena(b)
	_wait(a, 66)
	_wait(b, 66)
	assert_eq(a.to_json(), b.to_json(), "same seed, same battle")
	var c := GameState.from_json(a.to_json())
	assert_eq(c.combat.stage_run, a.combat.stage_run)
	_wait(a, 120)
	_wait(c, 120)
	assert_eq(c.to_json(), a.to_json(), "a loaded battle plays on the same")


func test_v8_save_migrates_to_v9() -> void:
	_make()
	var gs := ToyNpcs.new_game(_db)
	Commands.settle(gs, _db)
	var old := gs.to_dict()
	old["save_version"] = 8
	for n: Dictionary in old["npcs"]["npcs"].values():
		n.erase("hp")
		n.erase("down")
	(old["combat"] as Dictionary).erase("stage_run")
	var loaded := GameState.from_json(JSON.stringify(SaveCodec.encode(old)))
	assert_not_null(loaded)
	assert_eq(loaded.save_version, GameState.SAVE_VERSION)
	assert_eq(int(loaded.npcs.npcs["guard"]["hp"]), -1)
	assert_false(loaded.npcs.npcs["guard"]["down"])
	assert_eq(loaded.combat.stage_run, {})


func test_canon_and_combat_dbs_check_waves() -> void:
	_make(_battle([
		{"after_seconds": -1, "from": [13, 4], "foes": ["goblin"]},
		{"after_seconds": 5, "from": [6, 4], "foes": ["dragon"]},
		{"after_seconds": 5, "from": [13, 4]},
		{"after_seconds": 5, "from": [13, 4], "allies": ["nobody"]},
	]))
	var joined := "\n".join(_db.canon.errors + _db.combat.errors)
	assert_string_contains(joined, "wave 1: after_seconds must be a number >= 0")
	assert_string_contains(joined, "wave 2: unknown enemy 'dragon'")
	assert_string_contains(joined, "wave 2: from (6, 4) must be a walkable tile")
	assert_string_contains(joined, "wave 3: needs at least one foe, helper or ally")
	assert_string_contains(joined, "wave 4 allies: unknown npc 'nobody'")
