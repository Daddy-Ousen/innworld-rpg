extends GutTest
## M16.4 (ADR 0024): the Liscor rooms hold the NPCs the schedules put there. Grows with
## each room sub-milestone (M16.4.2 guild desk; M16.4.3 Watch barracks; M16.4.4 taverns).

const SEED := 20260929

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()


## Waits a minute at a time until `minute` of the day (bounded).
func _wait_until(gs: GameState, minute: int) -> void:
	var guard := 0
	while gs.clock.minute() < minute and guard < 1500:
		assert_true(Commands.wait(gs, _db, 60) >= 0, "wait")
		guard += 1
	assert_lt(guard, 1500, "the wait ended")


func _new_game() -> GameState:
	var gs := GameState.new_game(SEED, _db)
	gs.player.place("inn_interior", Vector2i(3, 3))  # out of the way, indoors, not in the doorway
	return gs


func test_selys_is_at_the_guild_desk_in_working_hours() -> void:
	var gs := _new_game()
	_wait_until(gs, 11 * 60)
	var n: Dictionary = gs.npcs.npcs["selys"]
	assert_eq(n["area"], "liscor_adventurers_guild", "Selys is at work")
	assert_eq(NpcRoster.pos_of(n), Vector2i(10, 3), "at the desk")


func test_selys_is_not_at_the_guild_at_lunch() -> void:
	var gs := _new_game()
	_wait_until(gs, 12 * 60 + 30)
	assert_ne(gs.npcs.npcs["selys"]["area"], "liscor_adventurers_guild")


func _at(gs: GameState, id: String, area: String, pos: Vector2i) -> void:
	var n: Dictionary = gs.npcs.npcs[id]
	assert_eq(n["area"], area, "%s is in %s" % [id, area])
	assert_eq(NpcRoster.pos_of(n), pos, "%s at their spot" % id)


func test_the_watch_is_in_the_barracks_and_the_office() -> void:
	var gs := _new_game()
	_wait_until(gs, 12 * 60 + 20)
	_at(gs, "zevara", "liscor_watch_office", Vector2i(5, 4))
	_at(gs, "relc", "liscor_watch_barracks", Vector2i(5, 5))


func test_the_desk_sergeant_takes_the_afternoon_and_evening_shift() -> void:
	var gs := _new_game()
	_wait_until(gs, 20 * 60)
	_at(gs, "beilmark", "liscor_watch_barracks", Vector2i(10, 10))


func test_klbkch_writes_the_ledger_late() -> void:
	var gs := _new_game()
	_wait_until(gs, 23 * 60 + 50)
	_at(gs, "klbkch", "liscor_watch_barracks", Vector2i(17, 6))


func test_krshia_eats_at_the_gnoll_tavern_in_the_evening() -> void:
	var gs := _new_game()
	_wait_until(gs, 20 * 60 + 30)
	_at(gs, "krshia", "liscor_gnoll_tavern", Vector2i(8, 7))
