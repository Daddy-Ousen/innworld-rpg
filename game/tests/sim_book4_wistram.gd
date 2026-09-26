extends GutTest
## M10.2 on the real Book 4 data (day 89). Erin moves the door's Celum end
## to Octavia's shop, and that night Ceria tells her the story of Wistram at
## the Frenzied Hare (the frame of the Wistram Days interludes). A player who
## sits and talks with them there changes the event.
## The game is slept to day 88 once (before_all); each test starts from a
## copy of that save.

const SEED := 20260927
const STORY := "b4.ceria_tells_erin_of_wistram"
const HOOK := "player_heard_the_wistram_story"
const TABLE_SPOT := Vector2i(12, 8)

var _db: DataDb
var _day89 := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])
	var gs := GameState.new_game(SEED, _db)
	ToyCanon.sleep_through(gs, _db, 88)
	_day89 = gs.to_json()


func _fresh() -> GameState:
	var gs := GameState.from_json(_day89)
	assert_eq(gs.clock.day(), 89)
	return gs


## Stands at the Hare's east table and waits (10 minutes a step, up to 20
## hours) until the story's stage starts.
func _wait_for_story(gs: GameState) -> void:
	gs.player.place("celum_frenzied_hare", TABLE_SPOT)
	Commands.settle(gs, _db)
	for i in 120:
		if gs.world.staged.has(STORY):
			break
		assert_true(Commands.wait(gs, _db, 600) >= 0, "wait")
	assert_true(gs.world.staged.has(STORY), "the story is staged")


func _area_of(gs: GameState, id: String) -> String:
	var n: Dictionary = gs.npcs.npcs.get(id, {})
	return "" if n.is_empty() else String(n["area"])


func _hour(gs: GameState) -> int:
	@warning_ignore("integer_division")
	return gs.clock.minute() / 60


func _hook_of(gs: GameState, id: String) -> String:
	var entry: Dictionary = gs.world.history.filter(func(h: Dictionary) -> bool: return h["event"] == id)[0]
	return str(entry.get("hook", ""))


func test_the_story_stage_is_loaded() -> void:
	assert_has(_db.canon.stages, STORY)
	var st: Dictionary = _db.canon.events[STORY]["stage"]
	assert_eq(st["area"], "celum_frenzied_hare")
	assert_eq(st["kind"], "scene")
	for n: Dictionary in st["npcs"]:
		assert_true(_db.behaviour.npcs.has(n["npc"]), "%s can be placed" % n["npc"])


func test_the_door_is_still_linked_to_the_hare_before_night_89() -> void:
	var gs := _fresh()
	assert_true(gs.flags.has("albez_door.linked_to_frenzied_hare"))
	assert_false(gs.flags.has("albez_door.anchor_at_stitchworks"))
	ToyCanon.sleep_through(gs, _db, 89)
	assert_false(gs.flags.has("albez_door.linked_to_frenzied_hare"))
	assert_true(gs.flags.has("albez_door.anchor_at_stitchworks"))
	# The Celum end is shown, but it stays dry until Erin's Level 30 (3.33).
	assert_false(gs.flags.has("erin.magical_grounds"))


func test_ceria_tells_the_story_at_night() -> void:
	var gs := _fresh()
	_wait_for_story(gs)
	var h := _hour(gs)
	assert_true(h >= 20 and h < 24, "in the evening")
	assert_eq(_area_of(gs, "ceria_springwalker"), "celum_frenzied_hare")
	assert_eq(_area_of(gs, "erin_solstice"), "celum_frenzied_hare")
	ToyCanon.sleep_through(gs, _db, 89)
	assert_eq(gs.world.status(STORY), Director.DONE)
	assert_true(gs.flags.has("erin.knows_of_wistram"))
	assert_false(gs.flags.has("frenzied_hare.earther_heard_of_wistram"))


func test_listening_changes_the_event() -> void:
	var gs := _fresh()
	_wait_for_story(gs)
	assert_eq(gs.player.pos(), TABLE_SPOT, "next to Ceria and Erin")
	var r := Commands.interact(gs, _db, "ceria_springwalker", "talk_with_guest")
	assert_eq(r["error"], "")
	assert_eq(r["record"]["context"]["location"], "frenzied_hare")
	ToyCanon.sleep_through(gs, _db, 89)
	assert_eq(gs.world.status(STORY), Director.CHANGED)
	assert_eq(_hook_of(gs, STORY), HOOK)
	assert_true(gs.flags.has("frenzied_hare.earther_heard_of_wistram"))
	assert_true(gs.flags.has("erin.knows_of_wistram"), "the canon still happens")
	assert_true(gs.world.relationship("ceria_springwalker", NpcSim.PLAYER) >= 2)
	var texts := gs.world.news.map(func(n: Dictionary) -> String: return n["text"])
	assert_true(texts.has(_db.canon.events[STORY]["hooks"][0]["news"]), "the hook's news")


func test_the_hare_table_alone_is_not_the_story() -> void:
	var gs := _fresh()
	gs.player.place("celum_frenzied_hare", TABLE_SPOT)
	Commands.settle(gs, _db)
	assert_eq(Commands.interact(gs, _db, "hare_table_east", "talk_with_guest")["error"], "")
	ToyCanon.sleep_through(gs, _db, 89)
	assert_eq(gs.world.status(STORY), Director.DONE, "talk with no one named does not count")


func test_no_story_on_another_day() -> void:
	var gs := _fresh()
	ToyCanon.sleep_through(gs, _db, 89)
	gs.player.place("celum_frenzied_hare", TABLE_SPOT)
	Commands.settle(gs, _db)
	for i in 16:
		Commands.wait(gs, _db, 3600)
		assert_false(gs.world.staged.has(STORY))
	assert_ne(_area_of(gs, "ceria_springwalker"), "celum_frenzied_hare")
