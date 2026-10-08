extends GutTest
## M19.5 on the real Book 7 data (5.09 E - 5.11 E, days 130 - 142): Laken's thread is off-map
## news, and his banquet on day 142 is a scene stage on the new `riverfarm` map with two hooks
## (Ivolethe, the poisoned cup). No road leads to Riverfarm yet: the exit opens with a flag that
## no event sets. The game is slept to day 141 once (before_all).

const SEED := 20261010
const DAY := 142
const STAGE := "b7.laken_feasts_the_nobles_and_the_spring_court"
const SPOT := Vector2i(5, 12)
const GUESTS := ["laken_godart", "durene", "prost", "wiskeria", "rie", "gamel", "beniar", "bethal", "thomast",
		"sacra", "bevia_veniford", "rael_veniford", "oswalt", "tourant", "ivolethe"]

var _db: DataDb
var _base := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])
	assert_eq(_db.canon.errors, [] as Array[String])
	var gs := GameState.new_game(SEED, _db)
	ToyCanon.sleep_through(gs, _db, DAY - 1)
	_base = gs.to_json()


func _fresh() -> GameState:
	var gs := GameState.from_json(_base)
	assert_eq(gs.clock.day(), DAY)
	return gs


func _wait_for_stage(gs: GameState) -> void:
	gs.player.place("riverfarm", SPOT)
	Commands.settle(gs, _db)
	for i in 120:
		if gs.world.staged.has(STAGE):
			break
		assert_true(Commands.wait(gs, _db, 600) >= 0, "wait")
	assert_true(gs.world.staged.has(STAGE), "the banquet is staged")


func _talk_to(gs: GameState, id: String) -> void:
	var n: Dictionary = gs.npcs.npcs[id]
	var at := Vector2i(int(n["x"]), int(n["y"]))
	var sides := {at + Vector2i(1, 0): true, at + Vector2i(-1, 0): true, at + Vector2i(0, 1): true, at + Vector2i(0, -1): true}
	assert_true(ToyMaps.walk_to(gs, _db, sides), "walk to " + id)
	var r := Commands.interact(gs, _db, id, "talk_with_guest")
	assert_eq(r["error"], "")


func _hook_of(gs: GameState, id: String) -> String:
	var entry: Dictionary = gs.world.history.filter(func(h: Dictionary) -> bool: return h["event"] == id)[0]
	return str(entry.get("hook", ""))


func test_the_data_is_loaded() -> void:
	assert_true(_db.maps.areas.has("riverfarm"))
	assert_eq(_db.maps.areas["riverfarm"]["location"], "riverfarm")
	for id: String in ["b7.laken_names_the_mossbear_bismarck", "b7.laken_hears_zel_shivertail_is_dead",
			"b7.magnolias_letter_invites_laken_to_a_gathering", "b7.laken_cancels_the_great_hall_banquet", STAGE,
			"b7.the_fae_leave_and_bow_to_the_emperor_of_eyes", "b7.bethal_tells_magnolia_that_laken_passed"]:
		assert_true(_db.canon.events.has(id), id)
	var ev: Dictionary = _db.canon.events[STAGE]
	assert_eq(ev["stage"]["area"], "riverfarm")
	assert_eq(ev["stage"]["kind"], "scene")
	assert_eq((ev["hooks"] as Array).size(), 2)


func test_the_road_to_riverfarm_is_shut_until_its_flag() -> void:
	var at := Vector2i(0, 10)
	assert_eq(_db.maps.exit_at("celum_gate", at), {}, "no exit while the flag is off")
	_db.maps.sync_flags({"world.road_to_riverfarm": true})
	assert_eq(_db.maps.exit_at("celum_gate", at).get("to", ""), "riverfarm")
	_db.maps.sync_flags({})
	assert_eq(_db.maps.exit_at("riverfarm", Vector2i(0, 11)).get("to", ""), "celum_gate")


func test_laken_thread_events_set_their_flags() -> void:
	var gs := _fresh()
	for f: String in ["laken.has_lesser_bond_with_bismarck", "laken.heard_that_zel_shivertail_is_dead",
			"laken.invited_to_magnolias_gathering", "laken.moves_the_banquet_to_the_meadow",
			"riverfarm.builders_feud_ended"]:
		assert_true(gs.flags.has(f), f)


func test_the_banquet_fills_the_meadow_in_the_evening() -> void:
	var gs := _fresh()
	_wait_for_stage(gs)
	@warning_ignore("integer_division")
	var h: int = gs.clock.minute() / 60
	assert_true(h >= 18 and h < 24, "evening")
	for n: String in GUESTS:
		assert_true(gs.npcs.npcs.has(n), n + " exists")
		assert_eq(String(gs.npcs.npcs[n]["area"]), "riverfarm", n)


func test_talking_to_ivolethe_changes_the_scene() -> void:
	var gs := _fresh()
	_wait_for_stage(gs)
	_talk_to(gs, "ivolethe")
	ToyCanon.sleep_through(gs, _db, DAY)
	assert_eq(gs.world.status(STAGE), Director.CHANGED)
	assert_eq(_hook_of(gs, STAGE), "player_spoke_with_ivolethe_at_the_meadow_edge")
	assert_true(gs.flags.has("riverfarm.earther_heard_ivolethe_is_punished"))
	assert_true(gs.flags.has("fae.spring_court_left_riverfarm"), "the banquet happens either way")


func test_talking_to_rie_after_the_poisoned_cup() -> void:
	var gs := _fresh()
	_wait_for_stage(gs)
	_talk_to(gs, "rie")
	ToyCanon.sleep_through(gs, _db, DAY)
	assert_eq(_hook_of(gs, STAGE), "player_helped_after_the_poisoned_cup")
	assert_true(gs.flags.has("riverfarm.earther_helped_after_the_poisoned_cup"))


func test_staying_away_still_runs_the_banquet() -> void:
	var gs := _fresh()
	ToyCanon.sleep_through(gs, _db, DAY)
	for f: String in ["laken.was_offered_a_poisoned_cup", "magnolia.is_told_laken_passed", "riverfarm.held_the_banquet_in_the_meadow"]:
		assert_true(gs.flags.has(f), f)
	assert_false(gs.flags.has("riverfarm.earther_heard_ivolethe_is_punished"))
