extends GutTest

const SAVE_PATH := "user://test_save.json"


func after_each() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func test_new_state_has_current_save_version() -> void:
	assert_eq(GameState.new().save_version, GameState.SAVE_VERSION)


func test_save_and_load_round_trip() -> void:
	var db := DataDb.load_dir()
	var gs := GameState.new_game(99, db)
	gs.focus_tags = ["cooking"]
	Actions.perform(gs, db, "cook_stew", {"context": {"guests": 12}, "witnesses": ["relc"]})
	gs.clock.sleep(db.rules["clock"])
	gs.rng.randi()
	assert_eq(gs.save_to_file(SAVE_PATH), OK)

	var loaded := GameState.load_from_file(SAVE_PATH)
	assert_not_null(loaded)
	assert_eq(loaded.to_dict(), gs.to_dict())
	assert_eq(loaded.rng.randi(), gs.rng.randi())


func test_newer_save_version_is_rejected() -> void:
	var d := GameState.new().to_dict()
	d["save_version"] = GameState.SAVE_VERSION + 1
	assert_null(GameState.from_json(JSON.stringify(d)))
	assert_push_error("newer than supported")


func test_invalid_json_is_rejected() -> void:
	assert_null(GameState.from_json("not json"))
	assert_push_error("not a JSON object")


func test_progression_survives_save_and_load() -> void:
	var db := DataDb.load_dir()
	var gs := GameState.new_game(5, db)
	gs.flags["met_relc"] = true
	gs.progression.pools["cook"] = 12.5
	gs.progression.classes["innkeeper"] = {"level": 3, "xp": 41.25, "last_active_day": 2}
	gs.progression.skills.append({"id": "basic_cooking", "class": "innkeeper", "level": 1, "day": 1})
	gs.progression.offers.append({"class": "cook", "kind": "new", "day": 2})
	gs.progression.declined.append("warrior")
	gs.morning.append("Hello.")
	var loaded := GameState.from_json(gs.to_json())
	assert_eq(loaded.to_json(), gs.to_json())
	assert_eq(loaded.progression.level_of("innkeeper"), 3)
	assert_eq(typeof(loaded.progression.classes["innkeeper"]["level"]), TYPE_INT)


func test_v1_save_migrates_to_current() -> void:
	var v1 := {
		"save_version": 1,
		"rng": Rng.new(3).to_dict(),
		"clock": {"total_minutes": 2000, "awake_minutes": 100, "last_sleep_collapsed": false},
		"action_log": {"records": [], "action_counts": {}, "tag_totals": {}},
		"focus_tags": [],
	}
	var gs := GameState.from_json(JSON.stringify(v1))
	assert_not_null(gs)
	assert_eq(gs.save_version, GameState.SAVE_VERSION)
	assert_eq(gs.race, "human")
	assert_true(gs.progression.classes.is_empty())
	assert_eq(gs.progression.day_start, 2000)


func test_v2_save_migrates_to_v3_with_an_untouched_world() -> void:
	var d := GameState.new().to_dict()
	d["save_version"] = 2
	d.erase("world")
	var gs := GameState.from_json(JSON.stringify(d))
	assert_not_null(gs)
	assert_eq(gs.save_version, GameState.SAVE_VERSION)
	assert_true(gs.world.history.is_empty())
	assert_eq(gs.world.last_day, 0)
	assert_eq(gs.world.status("b1.erin_arrives"), WorldState.PENDING)


func test_v3_save_migrates_to_v4_with_an_unplaced_player() -> void:
	var db := DataDb.load_dir()
	var d := GameState.new_game(2, db).to_dict()
	d["save_version"] = 3
	d.erase("player")
	var gs := GameState.from_json(JSON.stringify(d))
	assert_not_null(gs)
	assert_eq(gs.save_version, GameState.SAVE_VERSION)
	assert_false(gs.player.is_placed())
	assert_true(Movement.ensure_placed(gs, db), "placed at the start on first use")
	assert_eq(gs.player.area, db.rules["world"]["start"]["area"])


func test_player_survives_save_and_load() -> void:
	var gs := GameState.new(4)
	gs.player.place("inn_hill", Vector2i(15, 20))
	gs.player.facing = "n"
	gs.player.sub_seconds = 42
	var loaded := GameState.from_json(gs.to_json())
	assert_eq(loaded.player.to_dict(), gs.player.to_dict())
	assert_eq(typeof(loaded.player.x), TYPE_INT)


func test_world_survives_save_and_load() -> void:
	var gs := GameState.new(4)
	gs.world.set_alive("relc", false)
	gs.world.add_relationship("relc", "pisces", -2)
	gs.world.events["b1.x"] = {"status": "pending", "latest": 6}
	gs.world.events["b1.y"] = {"status": "substituted", "day": 5, "roles": {"guard": "klbkch"}}
	gs.world.history.append({"day": 5, "event": "b1.y", "outcome": "substituted",
			"roles": {"guard": "klbkch"}})
	gs.world.drift = 1.25
	gs.world.last_day = 5
	var loaded := GameState.from_json(gs.to_json())
	assert_eq(loaded.to_json(), gs.to_json())
	assert_eq(loaded.world.relationship("relc", "pisces"), -2)
	assert_eq(typeof(loaded.world.events["b1.x"]["latest"]), TYPE_INT)
	assert_eq(typeof(loaded.world.history[0]["day"]), TYPE_INT)


func test_floats_survive_save_and_load_exactly() -> void:
	var gs := GameState.new(4)
	var rng := Rng.new(11)
	var values: Array[float] = []
	for i in 300:
		values.append(rng.randf() * pow(10.0, rng.randi_range(-4, 5)))
	for i in values.size():
		gs.progression.pools["c%d" % i] = values[i]
	gs.world.drift = 0.1 + 0.2
	var text := gs.to_json()
	assert_string_contains(text, SaveCodec.float_to_text(0.1 + 0.2))
	var loaded := GameState.from_json(text)
	for i in values.size():
		assert_eq(loaded.progression.pools["c%d" % i], values[i])
	assert_eq(loaded.world.drift, 0.1 + 0.2)
	assert_eq(loaded.to_json(), text)


func test_save_codec_keeps_ints_and_strings() -> void:
	var d := {"i": 3, "s": "12.5", "f": -0.0, "a": [1.5, "x", {"n": 2.25}]}
	var enc: Dictionary = SaveCodec.encode(d)
	assert_eq(enc["i"], 3)
	assert_eq(enc["s"], "12.5")
	assert_eq(enc["f"], "f64:8000000000000000")
	assert_eq(SaveCodec.decode(enc), d)
	assert_eq(SaveCodec.float_to_text(0.5), "f64:3fe0000000000000")


func test_v4_save_migrates_to_v5_with_npcs_not_placed_yet() -> void:
	var db := DataDb.load_dir()
	var d := GameState.new_game(2, db).to_dict()
	d["save_version"] = 4
	d.erase("npcs")
	var gs := GameState.from_json(JSON.stringify(d, "", false, true))  # v4: plain float numbers
	assert_not_null(gs)
	assert_eq(gs.save_version, GameState.SAVE_VERSION)
	assert_false(gs.npcs.is_placed())
	Commands.settle(gs, db)
	assert_true(gs.npcs.is_placed(), "placed on the first command")
	assert_eq(gs.npcs.to_dict(), GameState.new_game(2, db).npcs.to_dict())


func test_npcs_survive_save_and_load() -> void:
	var gs := GameState.new(4)
	gs.npcs.sec = 12345
	gs.npcs.npcs["relc"] = {"area": "liscor_gate", "x": 3, "y": 10, "facing": "e", "goal": "patrol",
		"route_i": 2, "carry": 5, "talked_day": 8}
	gs.npcs.npcs["rags"] = {"area": "@wilds", "x": 0, "y": 0, "facing": "s", "goal": "off_map",
		"route_i": 0, "carry": 0, "talked_day": 0}
	var loaded := GameState.from_json(gs.to_json())
	assert_eq(loaded.to_json(), gs.to_json())
	assert_eq(loaded.npcs.at("liscor_gate", Vector2i(3, 10)), "relc")
	assert_eq(typeof(loaded.npcs.npcs["relc"]["route_i"]), TYPE_INT)


func test_v5_save_migrates_to_v6_with_full_hp_and_no_monsters() -> void:
	var db := DataDb.load_dir()
	var d := GameState.new_game(2, db).to_dict()
	d["save_version"] = 5
	d.erase("combat")
	(d["player"] as Dictionary).erase("hp")
	(d["player"] as Dictionary).erase("held")
	var gs := GameState.from_json(JSON.stringify(SaveCodec.encode(d)))
	assert_not_null(gs)
	assert_eq(gs.save_version, GameState.SAVE_VERSION)
	assert_eq(gs.player.hp, -1)
	assert_eq(gs.player.held, "")
	assert_true(gs.combat.monsters.is_empty())
	assert_false(gs.combat.has_fight())
	Commands.settle(gs, db)
	assert_eq(gs.combat.area, gs.player.area)
