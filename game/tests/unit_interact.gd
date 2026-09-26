extends GutTest
## Interact: nearby objects and their actions (ADR 0006), and taking
## items from map objects (M5.2, ADR 0010).

var _db: DataDb


func before_all() -> void:
	_db = ToyMaps.db()


func _new_game() -> GameState:
	return ToyMaps.new_game(_db)


func test_options_list_nearby_objects() -> void:
	var gs := _new_game()
	gs.player.place("town", Vector2i(6, 1))
	assert_true(Interact.options(gs, _db).is_empty(), "nothing here")
	gs.player.place("town", Vector2i(3, 2))
	var opts := Interact.options(gs, _db)
	assert_eq(opts.size(), 2)
	assert_eq(opts[0], {"id": "dummy", "name": "Dummy", "actions": ["fight", "spar"], "npc": false,
		"sleep": false, "item": "", "price": 0, "trades": [] as Array[Dictionary], "ride": {}, "portal": {}})
	assert_eq(opts[1]["id"], "stove")


func test_perform_does_the_action_with_map_context() -> void:
	var gs := _new_game()
	gs.player.place("town", Vector2i(1, 3))
	var start := gs.clock.total_minutes
	var r := Commands.interact(gs, _db, "stove", "cook")
	assert_eq(r["error"], "")
	assert_eq(r["record"]["action_id"], "cook")
	assert_eq(gs.clock.total_minutes, start + 60)


func test_object_and_zone_context_reach_the_action() -> void:
	var gs := _new_game()
	gs.player.place("town", Vector2i(3, 2))  # next to the dummy, outside the zone
	var tags: Dictionary = Interact.perform(gs, _db, "dummy", "spar")["record"]["tags"]
	assert_true(tags.has("hospitality"), "object context weapon=stick")
	assert_false(tags.has("cooking"))
	gs.player.place("town", Vector2i(3, 1))  # in zone toy_corner
	tags = Interact.perform(gs, _db, "dummy", "spar")["record"]["tags"]
	assert_true(tags.has("cooking"), "zone context")


func test_caller_context_is_merged_last() -> void:
	var gs := _new_game()
	gs.player.place("town", Vector2i(3, 2))
	var r := Interact.perform(gs, _db, "dummy", "spar", {"context": {"weapon": "sword"}})
	assert_false((r["record"]["tags"] as Dictionary).has("hospitality"))


func test_errors() -> void:
	var gs := _new_game()
	gs.player.place("town", Vector2i(6, 1))
	assert_string_contains(Interact.perform(gs, _db, "stove", "cook")["error"], "no 'stove' here")
	gs.player.place("town", Vector2i(1, 3))
	assert_string_contains(Interact.perform(gs, _db, "stove", "fight")["error"], "cannot fight")
	gs.clock.awake_minutes = int(_db.rules["clock"]["collapse_after_awake"])
	assert_string_contains(Interact.perform(gs, _db, "stove", "cook")["error"], "too tired")
	assert_true(gs.action_log.records.is_empty())


# --- take items (M5.2) ---------------------------------------------------------

func _arena_game(d: DataDb) -> GameState:
	var gs := ToyCombat.new_game(d)
	ToyCombat.to_arena(gs, d, Vector2i(1, 2))
	return gs


func test_options_show_the_item_to_take() -> void:
	var d := ToyCombat.db()
	var opts := Interact.options(_arena_game(d), d)
	assert_eq(opts.map(func(o: Dictionary) -> String: return o["id"]), ["stick_pile", "stink_bush"])
	assert_eq(opts[0]["item"], "stick")
	assert_eq(opts[1]["item"], "stink")


func test_take_holds_the_item_and_costs_a_turn() -> void:
	var d := ToyCombat.db()
	var gs := _arena_game(d)
	var before := NpcSim.world_sec(gs)
	assert_eq(Commands.take(gs, d, "stick_pile"), "")
	assert_eq(gs.player.held, "stick")
	assert_eq(NpcSim.world_sec(gs) - before, 6)
	assert_eq(gs.combat.lines, ["You take the stick."] as Array[String])


func test_take_replaces_the_held_item_and_drop_empties_the_hands() -> void:
	var d := ToyCombat.db()
	var gs := _arena_game(d)
	Commands.take(gs, d, "stick_pile")
	assert_eq(Commands.take(gs, d, "stink_bush"), "")
	assert_eq(gs.player.held, "stink")
	assert_eq(gs.combat.lines, ["You put the stick down.", "You take the stink bomb."] as Array[String])
	assert_eq(Commands.drop(gs, d), "")
	assert_eq(gs.player.held, "")


func test_take_errors() -> void:
	var d := ToyCombat.db()
	var gs := _arena_game(d)
	assert_string_contains(Commands.take(gs, d, "sword_rack"), "no 'sword_rack' here")
	gs.player.place("arena", Vector2i(10, 8))
	assert_string_contains(Commands.take(gs, d, "stick_pile"), "no 'stick_pile' here")
	gs.player.place("town", Vector2i(3, 2))
	Combat.sync(gs, d)
	assert_eq(Commands.take(gs, d, "dummy"), "There is nothing to take at the dummy.")
	assert_eq(gs.player.held, "")
	Combat.set_hp(gs, d, 0)
	assert_eq(Commands.take(gs, d, "dummy"), Combat.REFUSED_DOWN)


func test_take_works_with_enemies_near() -> void:
	var d := ToyCombat.db()
	ToyCombat.freeze(d)
	var gs := _arena_game(d)
	ToyCombat.spawn(gs, d, "goblin", Vector2i(4, 4))
	assert_true(Combat.in_danger(gs))
	assert_eq(Commands.take(gs, d, "stick_pile"), "")
	assert_eq(gs.player.held, "stick")
