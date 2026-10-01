extends GutTest
## M18.4 on the real Book 6 data (4.37 O, day 126): Olesm and Pisces search
## the Ruins crypt for Calruz and find the hidden chute. A scene on the hall
## puts both in the Ruins hall in the afternoon. A player who talks with them
## changes the event. The game is slept to day 125 once (before_all).

const SEED := 20261001
const DAY := 126
const SEARCH := "b6.olesm_and_pisces_find_the_hidden_chute"
const HALL_SPOT := Vector2i(15, 15)

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


func _wait_for_search(gs: GameState) -> void:
	gs.player.place("liscor_ruins_hall", HALL_SPOT)
	Commands.settle(gs, _db)
	for i in 120:
		if gs.world.staged.has(SEARCH):
			break
		assert_true(Commands.wait(gs, _db, 600) >= 0, "wait")
	assert_true(gs.world.staged.has(SEARCH), "the search is staged")


func _area_of(gs: GameState, id: String) -> String:
	var n: Dictionary = gs.npcs.npcs.get(id, {})
	return "" if n.is_empty() else String(n["area"])


func test_the_scene_is_loaded() -> void:
	var ev: Dictionary = _db.canon.events[SEARCH]
	assert_eq(ev["stage"]["kind"], "scene")
	assert_eq(ev["stage"]["area"], "liscor_ruins_hall")
	assert_false(ev.has("xp_window"))
	assert_true(_db.maps.areas.has(ev["stage"]["area"]))
	for n: Dictionary in ev["stage"]["npcs"]:
		assert_true(_db.behaviour.npcs.has(n["npc"]), n["npc"])


func test_olesm_and_pisces_come_to_the_hall_in_the_afternoon() -> void:
	var gs := _fresh()
	assert_true(gs.flags.get("ruins.vault_found_looted", false), "the vault is open by day 126")
	_wait_for_search(gs)
	@warning_ignore("integer_division")
	var h: int = gs.clock.minute() / 60
	assert_true(h >= 13 and h < 17, "in the afternoon")
	assert_eq(_area_of(gs, "olesm"), "liscor_ruins_hall")
	assert_eq(_area_of(gs, "pisces"), "liscor_ruins_hall")


func test_talking_with_olesm_changes_the_search() -> void:
	var gs := _fresh()
	_wait_for_search(gs)
	var n: Dictionary = gs.npcs.npcs["olesm"]
	var at := Vector2i(int(n["x"]), int(n["y"]))
	var sides := {at + Vector2i(1, 0): true, at + Vector2i(-1, 0): true, at + Vector2i(0, 1): true, at + Vector2i(0, -1): true}
	assert_true(ToyMaps.walk_to(gs, _db, sides), "walk to Olesm")
	var r := Commands.interact(gs, _db, "olesm", "talk_with_guest")
	assert_eq(r["error"], "")
	ToyCanon.sleep_through(gs, _db, DAY)
	assert_eq(gs.world.status(SEARCH), Director.CHANGED)
	assert_true(gs.flags.has("liscor_dungeon.earther_helped_search_the_crypt"))
	assert_true(gs.flags.has("liscor_ruins.hidden_chute_found"), "the chute is found either way")
	assert_true(gs.world.relationship("olesm", NpcSim.PLAYER) >= 2)


func test_the_illusion_wall_goes_after_the_night() -> void:
	var gs := _fresh()
	assert_false(gs.flags.has("liscor_ruins.hidden_chute_found"))
	ToyCanon.sleep_through(gs, _db, DAY)
	assert_eq(gs.world.status(SEARCH), Director.DONE)
	assert_true(gs.flags.has("liscor_ruins.hidden_chute_found"))
	assert_true(gs.flags.has("calruz.news_told_to_the_inn"))
