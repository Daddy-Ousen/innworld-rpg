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


# --- M31.0 beats (ADR 0044 "M31.0")

const BEATS := [
	{"after_seconds": 0, "npc": "baker", "line": "Fresh bread for everyone!"},
	{"after_seconds": 0, "line": "Someone claps."},
	{"after_seconds": 60, "npc": "baker", "line": "Come back tomorrow."},
]


func _beat_scene() -> Dictionary:
	var st: Dictionary = _scene_events()["e.gathering"]["stage"].duplicate(true)
	st["beats"] = BEATS.duplicate(true)
	return _scene_events(st)


func test_scene_beats_play_one_at_a_time_when_due() -> void:
	_make(_beat_scene())
	assert_eq(_db.canon.errors, [] as Array[String])
	var gs := ToyNpcs.new_game(_db)
	_to_field(gs)
	assert_has(gs.combat.lines, "A small crowd gathers.")
	assert_has(gs.combat.lines, "Baker: Fresh bread for everyone!", "a due beat plays with the stage")
	assert_does_not_have(gs.combat.lines, "Someone claps.", "one beat per command")
	Commands.wait(gs, _db, 6)
	assert_has(gs.combat.lines, "Someone claps.", "no npc: the line alone")
	Commands.wait(gs, _db, 6)
	assert_false(gs.combat.lines.has("Baker: Come back tomorrow."), "not due yet")
	Commands.wait(gs, _db, 60)
	assert_has(gs.combat.lines, "Baker: Come back tomorrow.")
	assert_eq(gs.combat.stage_run["beat"], 3)
	Commands.wait(gs, _db, 60)
	assert_false(gs.combat.lines.has("Baker: Come back tomorrow."), "each beat plays once")


func test_a_scene_run_is_no_fight() -> void:
	_make(_beat_scene())
	var gs := ToyNpcs.new_game(_db)
	_to_field(gs)
	assert_eq(gs.combat.stage_run["event"], "e.gathering")
	assert_eq(Stage.foes_left(gs, _db), -1, "the HUD shows no foes")
	assert_false(Stage.waves_left(gs, _db))
	assert_false(gs.combat.has_fight())


func test_leaving_the_area_stops_the_beats() -> void:
	_make(_beat_scene())
	var gs := ToyNpcs.new_game(_db)
	_to_field(gs)
	assert_true(ToyMaps.walk_to_area(gs, _db, "town"))
	assert_eq(gs.combat.stage_run, {})
	assert_true(ToyMaps.walk_to_area(gs, _db, "field"))
	Commands.wait(gs, _db, 60)
	assert_false(gs.combat.lines.has("Someone claps."), "the scene does not start again")


func test_a_scene_without_beats_keeps_no_run() -> void:
	_make(_scene_events())
	var gs := ToyNpcs.new_game(_db)
	_to_field(gs)
	assert_eq(gs.combat.stage_run, {})


func test_fight_stage_beats_play_and_keep_the_hud() -> void:
	_make(_events(_stage({"beats": [{"after_seconds": 0, "npc": "farmer", "line": "Watch its club!"}]})))
	assert_eq(_db.canon.errors, [] as Array[String])
	var gs := ToyNpcs.new_game(_db)
	_to_field(gs)
	assert_has(gs.combat.lines, "Farmer: Watch its club!")
	assert_eq(Stage.foes_left(gs, _db), -1, "no waves: no foe count, as before")


func test_last_beat_names_the_speaker_for_the_bubble() -> void:
	_make(_beat_scene())
	var gs := ToyNpcs.new_game(_db)
	assert_eq(Stage.last_beat(gs, _db), {})
	_to_field(gs)
	assert_eq(Stage.last_beat(gs, _db),
		{"key": "e.gathering|1", "npc": "baker", "line": "Fresh bread for everyone!"})
	Commands.wait(gs, _db, 6)
	assert_eq(Stage.last_beat(gs, _db), {"key": "e.gathering|2", "npc": "", "line": "Someone claps."})


func test_the_beat_index_survives_save_and_load() -> void:
	_make(_beat_scene())
	var gs := ToyNpcs.new_game(_db)
	_to_field(gs)
	var loaded := GameState.from_json(gs.to_json())
	assert_eq(loaded.to_json(), gs.to_json())
	assert_eq(typeof(loaded.combat.stage_run["beat"]), TYPE_INT)
	var old := gs.to_dict()
	(old["combat"]["stage_run"] as Dictionary).erase("beat")
	var from_old := GameState.from_json(JSON.stringify(SaveCodec.encode(old)))
	assert_eq(from_old.combat.stage_run["beat"], 0, "an older save reads no beat as 0")


func test_canon_db_checks_the_beats() -> void:
	var scene: Dictionary = _scene_events()["e.gathering"]["stage"]
	var bad := {
		"e.not_list": ToyCanon.event(1, 1, {"stage": scene.merged({"beats": "x"}, true)}),
		"e.bad_time": ToyCanon.event(1, 1, {"stage": scene.merged(
			{"beats": [{"after_seconds": -1, "line": "Hi."}]}, true)}),
		"e.no_line": ToyCanon.event(1, 1, {"stage": scene.merged(
			{"beats": [{"after_seconds": 0}]}, true)}),
		"e.extra": ToyCanon.event(1, 1, {"stage": scene.merged(
			{"beats": [{"after_seconds": 0, "line": "Hi.", "mood": "sad"}]}, true)}),
		"e.back_in_time": ToyCanon.event(1, 1, {"stage": scene.merged(
			{"beats": [{"after_seconds": 30, "line": "Hi."}, {"after_seconds": 10, "line": "Bye."}]}, true)}),
		"e.not_placed": ToyCanon.event(1, 1, {"stage": scene.merged(
			{"beats": [{"after_seconds": 0, "npc": "guard", "line": "Hi."}]}, true)}),
		"e.fight_not_ally": ToyCanon.event(1, 1, {"stage": _stage(
			{"beats": [{"after_seconds": 0, "npc": "baker", "line": "Hi."}]})}),
	}
	var canon := CanonDb.from_dicts(ToyNpcs.npcs(), {}, bad)
	var text := "\n".join(canon.errors)
	assert_string_contains(text, "event 'e.not_list' stage: beats must be a list.")
	assert_string_contains(text, "event 'e.bad_time' stage beat 1: after_seconds must be a number >= 0.")
	assert_string_contains(text, "event 'e.no_line' stage beat 1: line must be a non-empty string.")
	assert_string_contains(text, "event 'e.extra' stage beat 1: unknown key 'mood'.")
	assert_string_contains(text, "event 'e.back_in_time' stage beat 2: after_seconds must not be less than the beat before.")
	assert_string_contains(text, "event 'e.not_placed' stage beat 1: npc 'guard' is not on the stage.")
	assert_string_contains(text, "event 'e.fight_not_ally' stage beat 1: npc 'baker' is not on the stage.")


func test_the_view_shows_a_beat_over_its_speaker_once() -> void:
	_make(_beat_scene())
	var gs := ToyNpcs.new_game(_db)
	_to_field(gs)
	var v: WorldView = add_child_autofree(load("res://world/world_view.tscn").instantiate())
	v.setup(_db.maps)
	v.refresh(gs, _db)
	assert_eq(v.bubbles.text_of("baker"), "Fresh bread for everyone!")
	v.bubbles.tick(ViewBubbles.HOLD + ViewBubbles.FADE + 0.1)
	await get_tree().process_frame
	v.refresh(gs, _db)
	assert_eq(v.bubbles.text_of("baker"), "", "each beat shows once")
