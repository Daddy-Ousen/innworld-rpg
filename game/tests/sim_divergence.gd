extends GutTest
## ROADMAP M3 done-when: the three toy divergence scenarios give the
## expected history and drift (ToyCanon, ADR 0005).

const EPS := 0.000001
var _db: DataDb


func before_all() -> void:
	_db = ToyCanon.db()
	assert_eq(_db.canon.errors, [] as Array[String])


func _new_game() -> GameState:
	return GameState.new_game(7, _db)


func test_canon_runs_when_the_player_does_nothing() -> void:
	var gs := _new_game()
	ToyCanon.sleep_through(gs, _db, 7)
	assert_eq(ToyCanon.timeline(gs), [
		"D2 done e.king_crowned",
		"D3 done e.raid",
		"D4 done e.mentor_dies",
		"D5 done e.funeral",
		"D5 done e.patrol",
		"D5 done e.rebuild",
		"D6 done e.promotion",
		"D7 done e.parade",
	] as Array[String])
	assert_almost_eq(gs.world.drift, 0.0, EPS)
	assert_false(gs.world.is_alive(_db.canon, "mentor"))
	assert_eq(gs.world.status("e.mentor_survives"), WorldState.PENDING, "alt never runs on its own")
	assert_eq(gs.world.relationship("hero", "villain"), -3)
	assert_eq(gs.world.relationship("guard_a", "hero"), 1)


func test_save_a_doomed_npc() -> void:
	var gs := _new_game()
	ToyCanon.sleep_through(gs, _db, 1)
	Commands.set_flag(gs, "mentor.warned")  # day 2: the player warns the mentor
	ToyCanon.sleep_through(gs, _db, 7)
	assert_eq(ToyCanon.timeline(gs), [
		"D2 done e.king_crowned",
		"D3 done e.raid",
		"D4 mutated e.mentor_dies",
		"D4 done e.mentor_survives",
		"D4 cancelled e.funeral",
		"D5 done e.patrol",
		"D5 done e.rebuild",
		"D6 done e.promotion",
		"D7 done e.parade",
	] as Array[String])
	assert_eq(gs.world.history[2]["via"], "e.mentor_survives")
	assert_true(gs.world.is_alive(_db.canon, "mentor"))
	assert_true(gs.flags.get("mentor.wounded", false))
	assert_false(gs.flags.has("mentor.dead"))
	assert_almost_eq(gs.world.drift, 0.5 + 1.0, EPS, "mutated + cancelled funeral")


func test_kill_a_future_important_npc() -> void:
	var gs := _new_game()
	assert_eq(Commands.kill_npc(gs, _db, "guard_a"), "")  # day 1
	ToyCanon.sleep_through(gs, _db, 7)
	assert_eq(ToyCanon.timeline(gs), [
		"D1 killed player.kill",
		"D2 done e.king_crowned",
		"D3 done e.raid",
		"D4 done e.mentor_dies",
		"D5 done e.funeral",
		"D5 done e.rebuild",
		"D5 substituted e.patrol",
		"D6 cancelled e.promotion",
		"D6 cancelled e.parade",
	] as Array[String])
	assert_eq(gs.world.events["e.patrol"]["roles"], {"leader": "guard_b"})
	assert_eq(gs.world.relationship("guard_b", "hero"), 1, "effect follows the substitute")
	assert_eq(gs.world.relationship("guard_a", "hero"), 0)
	assert_string_contains(gs.world.history[7]["reason"], "guard_a is dead")
	assert_string_contains(gs.world.history[8]["reason"], "e.promotion was cancelled")
	assert_almost_eq(gs.world.drift, 0.25 + 1.0 + 1.0, EPS)


func test_prevent_an_event() -> void:
	var gs := _new_game()
	Commands.set_flag(gs, "village.walls_built")  # day 1
	ToyCanon.sleep_through(gs, _db, 7)
	assert_eq(ToyCanon.timeline(gs), [
		"D2 done e.king_crowned",
		"D3 delayed e.raid",
		"D4 done e.mentor_dies",
		"D4 delayed e.raid",
		"D5 done e.funeral",
		"D5 done e.patrol",
		"D5 cancelled e.raid",
		"D5 cancelled e.rebuild",
		"D6 done e.promotion",
		"D7 done e.parade",
	] as Array[String])
	assert_false(gs.flags.has("village.burned"))
	assert_almost_eq(gs.world.drift, 2.0, EPS)


func test_same_commands_give_the_same_history() -> void:
	var runs: Array[String] = []
	for i in 2:
		var gs := _new_game()
		Commands.kill_npc(gs, _db, "guard_a")
		Commands.set_flag(gs, "village.walls_built")
		ToyCanon.sleep_through(gs, _db, 3)
		Commands.set_flag(gs, "mentor.warned")
		ToyCanon.sleep_through(gs, _db, 8)
		runs.append(JSON.stringify(gs.world.to_dict()))
	assert_eq(runs[0], runs[1])
