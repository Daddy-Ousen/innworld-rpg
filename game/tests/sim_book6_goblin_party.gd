extends GutTest
## M18.5 on the real Book 6 data (4.42 L, day 128): Erin's party with the
## Goblins and the Antinium is a scene in the inn. A player who talks with
## one of the guests there changes the event.
## The game is slept to day 127 once (before_all); each test starts from a
## copy of that save.

const SEED := 20261002
const DAY := 128
const PARTY := "b6.the_goblin_party_at_the_inn"
const DOOR_SPOT := Vector2i(3, 3)

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


func _wait_for_party(gs: GameState) -> void:
	gs.player.place("inn_interior", DOOR_SPOT)
	Commands.settle(gs, _db)
	for i in 120:
		if gs.world.staged.has(PARTY):
			break
		assert_true(Commands.wait(gs, _db, 600) >= 0, "wait")
	assert_true(gs.world.staged.has(PARTY), "the party is staged")


func _area_of(gs: GameState, id: String) -> String:
	var n: Dictionary = gs.npcs.npcs.get(id, {})
	return "" if n.is_empty() else String(n["area"])


func test_the_party_is_a_scene_in_the_inn() -> void:
	var ev: Dictionary = _db.canon.events[PARTY]
	assert_eq(ev["stage"]["kind"], "scene")
	assert_eq(ev["stage"]["area"], "inn_interior")
	assert_false(ev.has("xp_window"))
	for n: Dictionary in ev["stage"]["npcs"]:
		assert_true(_db.behaviour.npcs.has(n["npc"]), n["npc"])


func test_guests_come_to_the_party_after_the_lunch_fight() -> void:
	var gs := _fresh()
	_wait_for_party(gs)
	@warning_ignore("integer_division")
	var h: int = gs.clock.minute() / 60
	assert_true(h >= 16 and h < 24, "afternoon to midnight")
	for id: String in ["numbtongue", "headscratcher", "yellow_splatters", "purple_smile", "ksmvr"]:
		assert_eq(_area_of(gs, id), "inn_interior", id)


func test_talking_to_a_guest_changes_the_party() -> void:
	var gs := _fresh()
	_wait_for_party(gs)
	var n: Dictionary = gs.npcs.npcs["numbtongue"]
	var at := Vector2i(int(n["x"]), int(n["y"]))
	var sides := {at + Vector2i(1, 0): true, at + Vector2i(-1, 0): true, at + Vector2i(0, 1): true, at + Vector2i(0, -1): true}
	assert_true(ToyMaps.walk_to(gs, _db, sides), "walk to Numbtongue")
	var r := Commands.interact(gs, _db, "numbtongue", "talk_with_guest")
	assert_eq(r["error"], "")
	ToyCanon.sleep_through(gs, _db, DAY)
	assert_eq(gs.world.status(PARTY), Director.CHANGED)
	assert_true(gs.flags.has("wandering_inn.earther_joined_the_goblin_party"))
	assert_true(gs.flags.has("wandering_inn.goblin_party_held"), "the party happens either way")
	var texts := gs.world.news.map(func(n: Dictionary) -> String: return n["text"])
	assert_true(texts.has(_db.canon.events[PARTY]["hooks"][0]["news"]))
	assert_true(gs.world.relationship("numbtongue", NpcSim.PLAYER) >= 1)


func test_staying_away_leaves_the_party_unseen() -> void:
	var gs := _fresh()
	ToyCanon.sleep_through(gs, _db, DAY)
	assert_eq(gs.world.status(PARTY), Director.DONE)
	assert_false(gs.flags.has("wandering_inn.earther_joined_the_goblin_party"))
	assert_true(gs.flags.has("wandering_inn.goblin_party_held"))
