extends GutTest
## M18.2 on the real Book 6 data (4.32 G, day 114): the Goblin Lord's army
## marches past Liscor at night. A scene on the inn hill puts Erin and Bird
## outside. A player who talks with them there changes the event.
## The game is slept to day 113 once (before_all); each test starts from a
## copy of that save.

const SEED := 20261001
const DAY := 114
const MARCH := "b6.goblin_lord_army_marches_past_liscor"
const HILL_SPOT := Vector2i(16, 14)

var _db: DataDb
var _base := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])
	var gs := GameState.new_game(SEED, _db)
	ToyCanon.sleep_through(gs, _db, DAY - 1)
	_base = gs.to_json()


func _fresh() -> GameState:
	var gs := GameState.from_json(_base)
	assert_eq(gs.clock.day(), DAY)
	return gs


func _wait_for_march(gs: GameState) -> void:
	gs.player.place("inn_hill", HILL_SPOT)
	Commands.settle(gs, _db)
	for i in 120:
		if gs.world.staged.has(MARCH):
			break
		assert_true(Commands.wait(gs, _db, 600) >= 0, "wait")
	assert_true(gs.world.staged.has(MARCH), "the march is staged")


func _area_of(gs: GameState, id: String) -> String:
	var n: Dictionary = gs.npcs.npcs.get(id, {})
	return "" if n.is_empty() else String(n["area"])


func test_the_march_comes_at_night_with_erin_and_bird_outside() -> void:
	var gs := _fresh()
	_wait_for_march(gs)
	@warning_ignore("integer_division")
	var h: int = gs.clock.minute() / 60
	assert_true(h >= 22 and h < 24, "late at night")
	assert_eq(_area_of(gs, "erin_solstice"), "inn_hill")
	assert_eq(_area_of(gs, "bird"), "inn_hill")


func test_talking_with_bird_changes_the_night() -> void:
	var gs := _fresh()
	_wait_for_march(gs)
	var n: Dictionary = gs.npcs.npcs["bird"]
	var at := Vector2i(int(n["x"]), int(n["y"]))
	var sides := {at + Vector2i(1, 0): true, at + Vector2i(-1, 0): true, at + Vector2i(0, 1): true, at + Vector2i(0, -1): true}
	assert_true(ToyMaps.walk_to(gs, _db, sides), "walk to Bird")
	var r := Commands.interact(gs, _db, "bird", "talk_with_guest")
	assert_eq(r["error"], "")
	ToyCanon.sleep_through(gs, _db, DAY)
	assert_eq(gs.world.status(MARCH), Director.CHANGED)
	assert_true(gs.flags.has("wandering_inn.earther_watched_the_goblin_army_pass"))
	assert_true(gs.flags.has("goblin_lord_army.passed_liscor"), "the army passes either way")
	var texts := gs.world.news.map(func(n: Dictionary) -> String: return n["text"])
	assert_true(texts.has(_db.canon.events[MARCH]["hooks"][0]["news"]))
	assert_true(gs.world.relationship("bird", NpcSim.PLAYER) >= 1)


func test_staying_away_leaves_the_march_unseen() -> void:
	var gs := _fresh()
	ToyCanon.sleep_through(gs, _db, DAY)
	assert_eq(gs.world.status(MARCH), Director.DONE)
	assert_false(gs.flags.has("wandering_inn.earther_watched_the_goblin_army_pass"))
	assert_true(gs.flags.has("goblin_lord_army.passed_liscor"))
