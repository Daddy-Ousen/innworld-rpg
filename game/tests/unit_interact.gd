extends GutTest
## Interact: nearby objects and their actions (ADR 0006).

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
	assert_eq(opts[0], {"id": "dummy", "name": "Dummy", "actions": ["fight", "spar"], "npc": false})
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
