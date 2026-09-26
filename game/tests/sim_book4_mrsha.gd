extends GutTest
## M10.1 on the real Book 4 data (3.27 M, day 85). Two scenes: Lyonette
## searches the snowy floodplains for Mrsha, and the rescuers gather at the
## rift that drops into Liscor's dungeon. A player who searches with
## Lyonette, or holds the rope at the rift, changes each event.
## The game is slept to day 84 once (before_all); each test starts from a
## copy of that save.

const SEED := 20260926
const SEARCH := "b4.lyonette_searches_the_snow_for_mrsha"
const RESCUE := "b4.mrsha_rescued_from_the_dungeon"
const FIELD_SPOT := Vector2i(11, 14)
const RIFT_SPOT := Vector2i(9, 9)

var _db: DataDb
var _day85 := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])
	var gs := GameState.new_game(SEED, _db)
	ToyCanon.sleep_through(gs, _db, 84)
	_day85 = gs.to_json()


func _fresh() -> GameState:
	var gs := GameState.from_json(_day85)
	assert_eq(gs.clock.day(), 85)
	return gs


## Stands at `pos` in `area` and waits (10 minutes a step, up to 20 hours)
## until the event's stage starts.
func _wait_for(gs: GameState, event: String, area: String, pos: Vector2i) -> void:
	gs.player.place(area, pos)
	Commands.settle(gs, _db)
	for i in 120:
		if gs.world.staged.has(event):
			break
		assert_true(Commands.wait(gs, _db, 600) >= 0, "wait")
	assert_true(gs.world.staged.has(event), "%s is staged" % event)


func _area_of(gs: GameState, id: String) -> String:
	var n: Dictionary = gs.npcs.npcs.get(id, {})
	return "" if n.is_empty() else String(n["area"])


func _hour(gs: GameState) -> int:
	@warning_ignore("integer_division")
	return gs.clock.minute() / 60


func _hook_of(gs: GameState, id: String) -> String:
	var entry: Dictionary = gs.world.history.filter(func(h: Dictionary) -> bool: return h["event"] == id)[0]
	return str(entry.get("hook", ""))


func _assert_changed(gs: GameState, id: String, hook: String, flag: String, canon_flag: String) -> void:
	assert_eq(gs.world.status(id), Director.CHANGED, id)
	assert_eq(_hook_of(gs, id), hook)
	assert_true(gs.flags.has(flag), flag)
	assert_true(gs.flags.has(canon_flag), "the canon still happens: " + canon_flag)
	var texts := gs.world.news.map(func(n: Dictionary) -> String: return n["text"])
	assert_true(texts.has(_db.canon.events[id]["hooks"][0]["news"]), "the hook's news")


func test_the_rift_and_the_stages_are_loaded() -> void:
	assert_true(_db.maps.areas.has("dungeon_rift"), "the rift map")
	assert_false(_db.maps.is_indoor("dungeon_rift"), "out in the snow")
	var exits: Array = _db.maps.areas["floodplains_south"]["exits"]
	assert_eq(exits.filter(func(e: Dictionary) -> bool: return e["to"] == "dungeon_rift").size(), 1, "a path from the floodplains")
	assert_eq(_db.canon.events[SEARCH]["stage"]["area"], "floodplains_south")
	assert_eq(_db.canon.events[RESCUE]["stage"]["area"], "dungeon_rift")
	for id: String in [SEARCH, RESCUE]:
		assert_has(_db.canon.stages, id)
		assert_eq(_db.canon.events[id]["stage"]["kind"], "scene", id)
		for n: Dictionary in _db.canon.events[id]["stage"]["npcs"]:
			assert_true(_db.behaviour.npcs.has(n["npc"]), "%s can be placed by %s" % [n["npc"], id])


func test_lyonette_searches_the_snow() -> void:
	var gs := _fresh()
	_wait_for(gs, SEARCH, "floodplains_south", FIELD_SPOT)
	var h := _hour(gs)
	assert_true(h >= 11 and h < 16, "by day")
	assert_eq(_area_of(gs, "lyonette"), "floodplains_south")


func test_searching_with_lyonette_changes_the_event() -> void:
	var gs := _fresh()
	_wait_for(gs, SEARCH, "floodplains_south", FIELD_SPOT)
	var r := Commands.interact(gs, _db, "lyonette", "comfort_someone")
	assert_eq(r["error"], "")
	assert_eq(r["record"]["context"]["location"], "floodplains_of_liscor")
	ToyCanon.sleep_through(gs, _db, 85)
	_assert_changed(gs, SEARCH, "player_searched_the_snow_with_lyonette",
			"floodplains.earther_searched_for_mrsha", "lyonette.searched_for_mrsha")
	assert_true(gs.world.relationship("lyonette", NpcSim.PLAYER) >= 2)


func test_the_rescuers_gather_at_the_rift() -> void:
	var gs := _fresh()
	_wait_for(gs, RESCUE, "dungeon_rift", RIFT_SPOT)
	var h := _hour(gs)
	assert_true(h >= 14 and h < 20, "late in the day")
	for npc: String in ["zel_shivertail", "klbkch", "krshia", "lyonette"]:
		assert_eq(_area_of(gs, npc), "dungeon_rift", npc)
	ToyCanon.sleep_through(gs, _db, 85)
	assert_eq(gs.world.status(RESCUE), Director.DONE)
	assert_true(gs.flags.has("mrsha.rescued_from_the_dungeon"))
	assert_false(gs.flags.has("mrsha.missing"))


func test_holding_the_rope_changes_the_rescue() -> void:
	var gs := _fresh()
	_wait_for(gs, RESCUE, "dungeon_rift", RIFT_SPOT)
	assert_true(ToyMaps.walk_next_to(gs, _db, "rift_rope_anchor"), "walk to the rope")
	assert_eq(Commands.interact(gs, _db, "rift_rope_anchor", "keep_watch")["error"], "")
	ToyCanon.sleep_through(gs, _db, 85)
	_assert_changed(gs, RESCUE, "player_held_the_rope_at_the_rift",
			"dungeon_rift.earther_held_the_rope", "mrsha.rescued_from_the_dungeon")
	assert_eq(gs.world.relationship("mrsha", NpcSim.PLAYER), 2)


func test_no_scene_on_another_day() -> void:
	var gs := _fresh()
	ToyCanon.sleep_through(gs, _db, 85)
	gs.player.place("dungeon_rift", RIFT_SPOT)
	Commands.settle(gs, _db)
	for i in 12:
		Commands.wait(gs, _db, 3600)
		assert_false(gs.world.staged.has(RESCUE))
	assert_ne(_area_of(gs, "zel_shivertail"), "dungeon_rift")
