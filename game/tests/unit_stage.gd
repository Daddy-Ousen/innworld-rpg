extends GutTest
## Canon stages (M6.5, ADR 0011) on the ToyNpcs world with toy combat: a
## toy event "e.ambush" (day 1–2) stages a Goblin in the field at 06–12,
## with the farmer as its ally; its change hook rewards a won fight.

const EV := "e.ambush"
const FOE_AT := Vector2i(3, 2)

var _db: DataDb


func _stage(extra: Dictionary = {}) -> Dictionary:
	var st := {"area": "field", "hours": [6, 12], "foes": [{"enemy": "goblin", "pos": [3, 2]}],
		"allies": ["farmer"], "line": "A goblin jumps out of the grass."}
	st.merge(extra, true)
	return st


func _events(stage: Dictionary = {}, window: Array = [1, 2]) -> Dictionary:
	if stage.is_empty():
		stage = _stage()
	return {EV: ToyCanon.event(window[0], window[1], {
		"requires": ToyCanon.req(["farmer"]),
		"stage": stage,
		"effects": {"set_flags": ["field.ambushed"]},
		"hooks": [{"id": "fought_goblin",
			"did": [{"action": ["attack_melee"], "outcome": ["success"], "context": {"enemy": "goblin"}}],
			"days": [1, 2], "then": "change",
			"effects": {"set_flags": ["farmer.saved"],
				"relationship": [{"from": "farmer", "to": "player", "delta": 2}]},
			"news": "A stranger fought the goblin in the field."}]})}


func _make(events: Dictionary = {}) -> void:
	_db = ToyNpcs.combat_db(events if not events.is_empty() else _events())
	ToyCombat.freeze(_db)


## Puts the player in the field at `pos` and lets one step of time pass.
func _to_field(gs: GameState, pos: Vector2i = Vector2i(0, 0)) -> void:
	gs.player.place("field", pos)
	Commands.wait(gs, _db, 6)


func _staged(gs: GameState) -> Array[String]:
	var out: Array[String] = []
	for id in gs.combat.ids():
		if gs.combat.monsters[id]["stage"] != "":
			out.append(id)
	return out


func test_toy_stage_data_is_valid() -> void:
	_make()
	assert_eq(_db.canon.errors, [] as Array[String])
	assert_eq(_db.combat.errors, [] as Array[String])
	assert_eq(_db.canon.stages, [EV] as Array[String])


func test_a_stage_puts_its_foes_on_the_map() -> void:
	_make()
	var gs := ToyNpcs.new_game(_db)
	assert_true(_staged(gs).is_empty(), "not in town")
	_to_field(gs)
	var ids := _staged(gs)
	assert_eq(ids.size(), 1)
	var m: Dictionary = gs.combat.monsters[ids[0]]
	assert_eq(m["type"], "goblin")
	assert_eq(m["stage"], EV)
	assert_eq(m["spawn"], "")
	assert_eq(CombatState.pos_of(m), FOE_AT)
	assert_eq(gs.world.staged, {EV: 1})
	assert_true(Combat.in_danger(gs), "the foe is hostile at once")
	assert_has(gs.combat.lines, "A goblin jumps out of the grass.")


func test_a_stage_runs_once() -> void:
	_make()
	var gs := ToyNpcs.new_game(_db)
	_to_field(gs)
	assert_true(ToyMaps.walk_to_area(gs, _db, "town"), "fled to town")
	assert_true(gs.combat.monsters.is_empty())
	_to_field(gs)
	assert_true(_staged(gs).is_empty(), "no second stage")
	assert_eq(gs.world.staged, {EV: 1})


func test_a_stage_needs_its_hours() -> void:
	_make()
	var gs := ToyNpcs.new_game(_db)
	gs.clock.advance(6 * 60)  # 12:00
	_to_field(gs)
	assert_true(_staged(gs).is_empty())
	assert_false(Stage.is_open(gs, _db, EV))


func test_a_stage_needs_its_window_and_a_pending_event() -> void:
	_make(_events(_stage(), [2, 2]))
	var gs := ToyNpcs.new_game(_db)
	_to_field(gs)
	assert_true(_staged(gs).is_empty(), "day 1 is before the window")
	_make()
	gs = ToyNpcs.new_game(_db)
	ToyCanon.sleep_through(gs, _db, 1)
	assert_eq(gs.world.status(EV), Director.DONE, "the event ran on night 1")
	_to_field(gs)
	assert_true(_staged(gs).is_empty(), "no stage for an event that ran")


func test_a_stage_needs_its_flags() -> void:
	_make(_events(_stage({"when_flags": ["field.goblins_near"], "unless_flags": ["field.fenced"]})))
	var gs := ToyNpcs.new_game(_db)
	assert_false(Stage.is_open(gs, _db, EV))
	gs.player.place("field", Vector2i(0, 0))
	assert_false(Stage.is_open(gs, _db, EV), "needs the when flag")
	Commands.set_flag(gs, "field.goblins_near")
	assert_true(Stage.is_open(gs, _db, EV))
	Commands.set_flag(gs, "field.fenced")
	assert_false(Stage.is_open(gs, _db, EV), "blocked by the unless flag")


func test_a_stage_needs_the_event_npcs_alive() -> void:
	_make()
	var gs := ToyNpcs.new_game(_db)
	assert_eq(Commands.kill_npc(gs, _db, "farmer"), "")
	_to_field(gs)
	assert_true(_staged(gs).is_empty())


func test_a_foe_on_a_taken_tile_stands_next_to_it() -> void:
	_make()
	var gs := ToyNpcs.new_game(_db)
	gs.player.place("field", FOE_AT)
	var at := Stage.free_near(gs, _db, FOE_AT)
	assert_ne(at, FOE_AT)
	assert_eq(maxi(absi(at.x - FOE_AT.x), absi(at.y - FOE_AT.y)), 1)
	Commands.wait(gs, _db, 6)
	var ids := _staged(gs)
	assert_eq(ids.size(), 1)
	assert_ne(CombatState.pos_of(gs.combat.monsters[ids[0]]), FOE_AT)


func test_winning_the_staged_fight_changes_the_event() -> void:
	_make()
	ToyCombat.always_hit(_db)
	var gs := ToyNpcs.new_game(_db)
	_to_field(gs, FOE_AT + Vector2i(0, -1))
	var foe := _staged(gs)[0]
	for i in 10:
		if not gs.combat.monsters.has(foe):
			break
		Commands.attack(gs, _db, "s")
	assert_false(gs.combat.has_fight(), "the fight is won")
	ToyCanon.sleep_through(gs, _db, 1)
	assert_eq(gs.world.status(EV), Director.CHANGED)
	assert_true(gs.flags.has("field.ambushed"), "the event still ran")
	assert_true(gs.flags.has("farmer.saved"))
	assert_eq(gs.world.relationship("farmer", NpcSim.PLAYER), 2)
	assert_eq(gs.world.news[-1]["text"], "A stranger fought the goblin in the field.")


func test_running_from_the_staged_fight_leaves_canon() -> void:
	_make()
	var gs := ToyNpcs.new_game(_db)
	_to_field(gs)
	assert_true(ToyMaps.walk_to_area(gs, _db, "town"))
	ToyCanon.sleep_through(gs, _db, 1)
	assert_eq(gs.world.status(EV), Director.DONE)
	assert_false(gs.flags.has("farmer.saved"))


func test_stage_state_survives_save_and_load() -> void:
	_make()
	var gs := ToyNpcs.new_game(_db)
	_to_field(gs)
	var loaded := GameState.from_json(gs.to_json())
	assert_eq(loaded.to_json(), gs.to_json())
	assert_eq(loaded.world.staged, {EV: 1})
	assert_eq(typeof(loaded.world.staged[EV]), TYPE_INT)
	assert_eq(loaded.combat.monsters[_staged(gs)[0]]["stage"], EV)


func test_v7_save_migrates_to_v8() -> void:
	_make()
	var gs := ToyNpcs.new_game(_db)
	_to_field(gs)
	var old := gs.to_dict()
	old["save_version"] = 7
	(old["world"] as Dictionary).erase("staged")
	for m: Dictionary in old["combat"]["monsters"].values():
		m.erase("stage")
	var loaded := GameState.from_json(JSON.stringify(SaveCodec.encode(old)))
	assert_not_null(loaded)
	assert_eq(loaded.save_version, GameState.SAVE_VERSION)
	assert_eq(loaded.world.staged, {})
	for m: Dictionary in loaded.combat.monsters.values():
		assert_eq(m["stage"], "")


func test_canon_db_checks_the_stage_shape() -> void:
	var bad := {
		"e.no_foes": ToyCanon.event(1, 1, {"stage": {"area": "field", "hours": [6, 12]}}),
		"e.bad_hours": ToyCanon.event(1, 1, {"stage": _stage({"hours": [12, 12]})}),
		"e.bad_foe": ToyCanon.event(1, 1, {"stage": _stage({"foes": [{"enemy": "goblin"}]})}),
		"e.bad_ally": ToyCanon.event(1, 1, {"stage": _stage({"allies": ["nobody"]})}),
	}
	var canon := CanonDb.from_dicts(ToyNpcs.npcs(), {}, bad)
	var text := "\n".join(canon.errors)
	assert_string_contains(text, "event 'e.no_foes' stage: missing 'foes'.")
	assert_string_contains(text, "event 'e.bad_hours' stage: hours must be")
	assert_string_contains(text, "event 'e.bad_foe' stage: each foe needs 'enemy' and 'pos'")
	assert_string_contains(text, "event 'e.bad_ally' stage allies: unknown npc 'nobody'.")


## A scene stage (M8.2) with the toy baker (npc_behaviour, normally off-map
## or in the shop) moved into the field with no fight. The area is not the
## toy game's start area (town), so the player must walk in for it to fire.
func _scene_events(stage: Dictionary = {}, window: Array = [1, 2]) -> Dictionary:
	if stage.is_empty():
		stage = {"area": "field", "hours": [6, 22], "kind": "scene",
			"npcs": [{"npc": "baker", "pos": [2, 1]}], "line": "A small crowd gathers."}
	return {"e.gathering": ToyCanon.event(window[0], window[1],
		{"stage": stage, "effects": {"set_flags": ["field.gathered"]}})}


func test_a_scene_stage_moves_its_npcs_in_with_no_fight() -> void:
	_make(_scene_events())
	var gs := ToyNpcs.new_game(_db)
	assert_ne(ToyNpcs.area(gs, "baker"), "field", "not there yet")
	_to_field(gs)
	assert_eq(gs.world.staged, {"e.gathering": 1})
	assert_eq(ToyNpcs.area(gs, "baker"), "field")
	assert_ne(ToyNpcs.pos(gs, "baker"), ToyNpcs.pos(gs, "farmer"),
		"the farmer works at (2,1); baker takes the nearest free tile instead")
	assert_true(gs.combat.monsters.is_empty(), "a scene has no monsters")
	assert_has(gs.combat.lines, "A small crowd gathers.")


func test_a_scene_stage_runs_once() -> void:
	_make(_scene_events())
	var gs := ToyNpcs.new_game(_db)
	_to_field(gs)
	assert_eq(gs.world.staged, {"e.gathering": 1})
	Commands.wait(gs, _db, 6)
	assert_eq(gs.world.staged, {"e.gathering": 1}, "did not stage again")
	assert_does_not_have(gs.combat.lines, "A small crowd gathers.", "no second line")


func test_canon_db_checks_the_scene_stage_shape() -> void:
	var bad := {
		"e.bad_kind": ToyCanon.event(1, 1, {"stage": {"area": "town", "hours": [6, 12], "kind": "party"}}),
		"e.no_npcs": ToyCanon.event(1, 1,
			{"stage": {"area": "town", "hours": [6, 12], "kind": "scene"}}),
		"e.bad_npc": ToyCanon.event(1, 1, {"stage": _scene_events()["e.gathering"]["stage"]
			.merged({"npcs": [{"npc": "baker"}]}, true)}),
		"e.unknown_npc": ToyCanon.event(1, 1, {"stage": _scene_events()["e.gathering"]["stage"]
			.merged({"npcs": [{"npc": "nobody", "pos": [2, 2]}]}, true)}),
		"e.scene_with_waves": ToyCanon.event(1, 1, {"stage": _scene_events()["e.gathering"]["stage"]
			.merged({"waves": [{"after_seconds": 0, "allies": ["baker"]}]}, true)}),
	}
	var canon := CanonDb.from_dicts(ToyNpcs.npcs(), {}, bad)
	var text := "\n".join(canon.errors)
	assert_string_contains(text, "event 'e.bad_kind' stage: kind must be 'fight' or 'scene'.")
	assert_string_contains(text, "event 'e.no_npcs' stage: missing 'npcs'.")
	assert_string_contains(text, "event 'e.bad_npc' stage: each npc entry needs 'npc' and 'pos'")
	assert_string_contains(text, "event 'e.unknown_npc' stage npcs: unknown npc 'nobody'.")
	assert_string_contains(text, "event 'e.scene_with_waves' stage: a scene stage cannot have waves.")


func test_combat_db_checks_scene_npc_tiles() -> void:
	var base: Dictionary = _scene_events()["e.gathering"]["stage"]
	var events := {
		"e.on_an_exit": ToyCanon.event(1, 1,
			{"stage": base.merged({"npcs": [{"npc": "baker", "pos": [0, 1]}]}, true)}),
	}
	_make(events)
	var text := "\n".join(_db.combat.errors)
	assert_string_contains(text, "event 'e.on_an_exit' stage: npc pos")


func test_combat_db_checks_stage_enemies_and_tiles() -> void:
	var events := {
		"e.unknown_enemy": ToyCanon.event(1, 1, {"stage": _stage({"foes": [{"enemy": "dragon", "pos": [1, 1]}]})}),
		"e.unknown_map": ToyCanon.event(1, 1, {"stage": _stage({"area": "moon"})}),
		"e.on_a_wall": ToyCanon.event(1, 1, {"stage": _stage({"area": "town",
			"foes": [{"enemy": "goblin", "pos": [0, 0]}]})}),
		"e.on_an_exit": ToyCanon.event(1, 1, {"stage": _stage({"area": "town",
			"foes": [{"enemy": "goblin", "pos": [7, 2]}]})}),
	}
	_make(events)
	var text := "\n".join(_db.combat.errors)
	assert_string_contains(text, "event 'e.unknown_enemy' stage: unknown enemy 'dragon'.")
	assert_string_contains(text, "event 'e.unknown_map' stage: unknown map 'moon'.")
	assert_string_contains(text, "event 'e.on_a_wall' stage: foe pos")
	assert_string_contains(text, "event 'e.on_an_exit' stage: foe pos")
