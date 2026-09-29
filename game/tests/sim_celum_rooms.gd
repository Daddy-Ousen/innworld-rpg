extends GutTest
## M16.5 (ADR 0025): the Celum rooms hold the NPCs the schedules put there.

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


func _at(gs: GameState, id: String, area: String, pos: Vector2i) -> void:
	var n: Dictionary = gs.npcs.npcs[id]
	assert_eq(n["area"], area, "%s is in %s" % [id, area])
	assert_eq(NpcRoster.pos_of(n), pos, "%s at their spot" % id)


func test_stenei_octavia_and_agnes_are_at_work_at_noon() -> void:
	var gs := GameState.new_game(SEED, _db, "celum")
	_wait_until(gs, 12 * 60)
	_at(gs, "stenei", "celum_runners_guild", Vector2i(10, 2))
	_at(gs, "octavia", "celum_stitchworks", Vector2i(4, 2))
	_at(gs, "agnes", "celum_frenzied_hare", Vector2i(6, 3))
