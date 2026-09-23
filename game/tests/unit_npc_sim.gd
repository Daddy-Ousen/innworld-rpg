extends GutTest
## NpcSim (ADR 0008) on the ToyNpcs world: placing, walking, waiting for
## the player, leaving and coming in, level of detail, death, talk.

var _db: DataDb


func before_all() -> void:
	_db = ToyNpcs.db()
	assert_eq(_db.maps.errors, [] as Array[String])
	assert_eq(_db.behaviour.errors, [] as Array[String])


func _wait(gs: GameState, seconds: int, times: int = 1) -> void:
	for i in times:
		assert_true(Commands.wait(gs, _db, seconds) >= 0, "wait")


func test_new_game_puts_npcs_at_their_goal_spots() -> void:
	var gs := ToyNpcs.new_game(_db)
	assert_true(gs.npcs.is_placed())
	assert_eq(ToyNpcs.area(gs, "guard"), "town")
	assert_eq(ToyNpcs.pos(gs, "guard"), Vector2i(1, 1))
	assert_eq(gs.npcs.npcs["guard"]["goal"], "patrol")
	assert_eq(ToyNpcs.area(gs, "farmer"), "field")
	assert_eq(ToyNpcs.pos(gs, "farmer"), Vector2i(2, 1))
	assert_eq(ToyNpcs.area(gs, "baker"), "@city", "off-map before 08:00")
	assert_eq(gs.npcs.in_area("town"), ["guard"] as Array[String])


func test_npc_walks_one_tile_per_step_seconds() -> void:
	var gs := ToyNpcs.new_game(_db)
	gs.player.place("town", Vector2i(6, 1))
	_wait(gs, 4)
	assert_eq(ToyNpcs.pos(gs, "guard"), Vector2i(1, 1), "4 s: not yet")
	_wait(gs, 4)
	assert_eq(ToyNpcs.pos(gs, "guard"), Vector2i(2, 1), "8 s: one step")
	assert_eq(gs.npcs.npcs["guard"]["facing"], "e")
	_wait(gs, 8)
	assert_eq(ToyNpcs.pos(gs, "guard"), Vector2i(3, 1), "patrol point reached")
	_wait(gs, 8)
	assert_eq(ToyNpcs.pos(gs, "guard"), Vector2i(2, 1), "and back")


func test_npc_waits_while_the_player_stands_on_its_way() -> void:
	var gs := ToyNpcs.new_game(_db)
	gs.player.place("town", Vector2i(3, 1))
	_wait(gs, 8)
	assert_eq(ToyNpcs.pos(gs, "guard"), Vector2i(2, 1))
	_wait(gs, 8, 3)
	assert_eq(ToyNpcs.pos(gs, "guard"), Vector2i(2, 1), "waits next to the player")
	gs.player.place("town", Vector2i(6, 1))
	_wait(gs, 8)
	assert_eq(ToyNpcs.pos(gs, "guard"), Vector2i(3, 1))


func test_npc_goes_around_the_player() -> void:
	var gs := ToyNpcs.new_game(_db)
	gs.player.place("town", Vector2i(2, 1))
	_wait(gs, 8)
	assert_eq(ToyNpcs.pos(gs, "guard"), Vector2i(1, 2), "down and around")


func test_player_cannot_walk_into_an_npc() -> void:
	var gs := ToyNpcs.new_game(_db)
	var r := Commands.move(gs, _db, "n")
	assert_true(r["blocked"])
	assert_eq(r["npc"], "guard")
	assert_eq(gs.player.pos(), Vector2i(1, 2))


func test_npc_comes_in_at_the_entry_and_walks_through_the_door() -> void:
	var gs := ToyNpcs.new_game(_db)
	gs.player.place("town", Vector2i(6, 1))
	_wait(gs, 2 * 3600 - 6)  # a long wait: 07:59:54
	assert_eq(ToyNpcs.area(gs, "baker"), "@city")
	_wait(gs, 6)  # 08:00: to work, through town
	assert_eq(ToyNpcs.area(gs, "baker"), "town")
	assert_eq(ToyNpcs.pos(gs, "baker"), Vector2i(1, 3), "the city's way in")
	_wait(gs, 6, 12)
	assert_eq(ToyNpcs.area(gs, "baker"), "shop", "walked out through the door")
	assert_eq(ToyNpcs.pos(gs, "baker"), Vector2i(1, 1))


func test_npc_leaves_at_the_entry() -> void:
	var gs := ToyNpcs.new_game(_db)
	gs.player.place("town", Vector2i(6, 1))
	_wait(gs, 16 * 3600 - 6)  # 21:59:54
	assert_eq(ToyNpcs.area(gs, "guard"), "town")
	var at := ToyNpcs.pos(gs, "guard")
	_wait(gs, 6)  # 22:00: off duty
	assert_eq(ToyNpcs.area(gs, "guard"), "town", "walks out, does not vanish")
	_wait(gs, 6, 10)
	assert_eq(ToyNpcs.area(gs, "guard"), "@city", "left from %s via 1,3" % at)


func test_other_areas_jump_and_long_gaps_jump() -> void:
	var gs := ToyNpcs.new_game(_db)
	gs.player.place("field", Vector2i(3, 2))
	_wait(gs, 2 * 3600 - 6)
	_wait(gs, 6)  # 08:00, a short step
	assert_eq(ToyNpcs.area(gs, "baker"), "shop", "not on the player's way: jumps")
	assert_eq(ToyNpcs.pos(gs, "baker"), Vector2i(1, 1))
	_wait(gs, 4 * 3600)  # 12:00
	assert_eq(ToyNpcs.area(gs, "baker"), "@city")


func test_npc_on_the_players_arrival_tile_steps_aside() -> void:
	var gs := ToyNpcs.new_game(_db)
	gs.npcs.npcs["guard"]["x"] = 5
	gs.npcs.npcs["guard"]["y"] = 2
	gs.player.place("shop", Vector2i(1, 1))
	assert_true(Commands.move(gs, _db, "s")["moved"], "through the shop door")
	assert_eq(gs.player.area, "town")
	assert_eq(gs.player.pos(), Vector2i(5, 2))
	assert_ne(ToyNpcs.pos(gs, "guard"), Vector2i(5, 2))


func test_dead_npcs_are_gone() -> void:
	var gs := ToyNpcs.new_game(_db)
	assert_eq(Commands.kill_npc(gs, _db, "guard"), "")
	assert_false(gs.npcs.npcs.has("guard"))
	assert_true(Commands.move(gs, _db, "n")["moved"], "no one in the way now")
	_wait(gs, 3600)
	assert_false(gs.npcs.npcs.has("guard"), "and they stay gone")


func test_talk_to_an_npc() -> void:
	var gs := ToyNpcs.new_game(_db)
	var opts := Interact.options(gs, _db)
	assert_eq(opts.map(func(o: Dictionary) -> String: return o["id"]), ["stove", "guard"],
			"objects first, then NPCs")
	assert_eq(opts[1], {"id": "guard", "name": "Guard", "actions": ["chat"], "npc": true,
		"sleep": false})
	var r := Commands.interact(gs, _db, "guard", "chat")
	assert_eq(r["error"], "")
	assert_eq(r["record"]["witnesses"], ["guard"])
	assert_eq(gs.world.relationship("guard", NpcSim.PLAYER), 1)
	assert_string_contains(Commands.interact(gs, _db, "guard", "fight")["error"], "with Guard")


func test_talk_counts_once_per_npc_per_day() -> void:
	var gs := ToyNpcs.new_game(_db)
	for i in 2:
		gs.player.place("town", ToyNpcs.pos(gs, "guard") + Vector2i(0, 1))
		assert_eq(Commands.interact(gs, _db, "guard", "chat")["error"], "")
	assert_eq(gs.world.relationship("guard", NpcSim.PLAYER), 1, "once today")
	Commands.sleep(gs, _db)
	assert_eq(ToyNpcs.area(gs, "guard"), "town", "back on patrol at 06:00")
	gs.player.place("town", ToyNpcs.pos(gs, "guard") + Vector2i(0, 1))
	assert_eq(Commands.interact(gs, _db, "guard", "chat")["error"], "")
	assert_eq(gs.world.relationship("guard", NpcSim.PLAYER), 2, "again the next day")


func test_night_moves_npcs_to_their_morning_spots() -> void:
	var gs := ToyNpcs.new_game(_db)
	_wait(gs, 17 * 3600)  # 23:00
	assert_eq(ToyNpcs.area(gs, "guard"), "@city")
	assert_eq(ToyNpcs.area(gs, "farmer"), "@city")
	Commands.sleep(gs, _db)
	assert_eq(gs.clock.time_string(), "06:00")
	assert_eq(ToyNpcs.area(gs, "guard"), "town")
	assert_eq(ToyNpcs.area(gs, "farmer"), "field")


func test_same_commands_same_npcs_and_save_load_changes_nothing() -> void:
	var a := _play(ToyNpcs.new_game(_db, 7), 0, 40)
	var b := ToyNpcs.new_game(_db, 7)
	b = _play(b, 0, 17)
	b = GameState.from_json(b.to_json())
	b = _play(b, 17, 40)
	assert_eq(b.to_json(), a.to_json())


## Walks the player east and west along row 2 while the NPCs go about.
@warning_ignore("integer_division")
func _play(gs: GameState, from: int, to: int) -> GameState:
	for i in range(from, to):
		if i == 20:
			_wait(gs, 2 * 3600)
		Commands.move(gs, _db, "e" if (i / 5) % 2 == 0 else "w")
	return gs
