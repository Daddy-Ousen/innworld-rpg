extends GutTest
## M19.3 on the real Book 7 data (5.04 – 5.06 M, days 135 – 136): the Players of
## Celum play at the inn (a scene stage, day 135, one talk hook), the Grand Theatre
## and Erin's level, Toren and Vuliel Drae in the dungeon, Griffon Hunt, and Mrsha
## the Druid. The game is slept to day 135 once (before_all); each test starts from
## a copy of that save.

const SEED := 20261008
const PLAY_DAY := 135
const PLAY := "b7.players_of_celum_perform_at_the_inn"
const DOOR_SPOT := Vector2i(3, 3)

var _db: DataDb
var _base := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])
	var gs := GameState.new_game(SEED, _db)
	ToyCanon.sleep_through(gs, _db, PLAY_DAY - 1)
	_base = gs.to_json()


func _fresh() -> GameState:
	var gs := GameState.from_json(_base)
	assert_eq(gs.clock.day(), PLAY_DAY)
	return gs


func _wait_for_stage(gs: GameState, id: String) -> void:
	gs.player.place("inn_interior", DOOR_SPOT)
	Commands.settle(gs, _db)
	for i in 120:
		if gs.world.staged.has(id):
			break
		assert_true(Commands.wait(gs, _db, 600) >= 0, "wait")
	assert_true(gs.world.staged.has(id), id + " is staged")


func _area_of(gs: GameState, id: String) -> String:
	var n: Dictionary = gs.npcs.npcs.get(id, {})
	return "" if n.is_empty() else String(n["area"])


func _talk_to(gs: GameState, id: String) -> void:
	var n: Dictionary = gs.npcs.npcs[id]
	var at := Vector2i(int(n["x"]), int(n["y"]))
	var sides := {at + Vector2i(1, 0): true, at + Vector2i(-1, 0): true, at + Vector2i(0, 1): true, at + Vector2i(0, -1): true}
	assert_true(ToyMaps.walk_to(gs, _db, sides), "walk to " + id)
	var r := Commands.interact(gs, _db, id, "talk_with_guest")
	assert_eq(r["error"], "")


func test_the_play_is_a_scene_in_the_inn_without_a_window() -> void:
	var ev: Dictionary = _db.canon.events[PLAY]
	assert_eq(ev["stage"]["kind"], "scene")
	assert_eq(ev["stage"]["area"], "inn_interior")
	assert_false(ev.has("xp_window"))
	for n: Dictionary in ev["stage"]["npcs"]:
		assert_true(_db.behaviour.npcs.has(n["npc"]), n["npc"])


func test_the_players_come_to_the_inn_at_night() -> void:
	var gs := _fresh()
	_wait_for_stage(gs, PLAY)
	@warning_ignore("integer_division")
	var h: int = gs.clock.minute() / 60
	assert_true(h >= 19 and h < 24, "night hours")
	for id: String in ["wesle", "jasi", "octavia", "badarrow", "shorthilt"]:
		assert_eq(_area_of(gs, id), "inn_interior", id)


func test_talking_to_wesle_changes_the_play() -> void:
	var gs := _fresh()
	_wait_for_stage(gs, PLAY)
	_talk_to(gs, "wesle")
	ToyCanon.sleep_through(gs, _db, PLAY_DAY)
	assert_eq(gs.world.status(PLAY), Director.CHANGED)
	assert_true(gs.flags.has("wandering_inn.earther_watched_the_players_perform"))
	assert_true(gs.flags.has("players_of_celum.perform_nightly_at_the_inn"), "the play happens either way")


func test_the_theatre_and_the_far_threads_run() -> void:
	var gs := _fresh()
	ToyCanon.sleep_through(gs, _db, 136)
	for f: String in ["octavia.makes_fire_matches", "players_of_celum.agree_to_play_at_the_inn",
			"redfang.work_as_inn_security", "redfang.bronze_team_application_filed",
			"wandering_inn.grand_theatre", "toren.second_self_wears_the_mask",
			"toren.has_a_dungeon_inn", "griffon_hunt.found_cursed_jewellery",
			"halrac.admits_the_team_failed_ulrien", "liscor.sewer_slime_killed",
			"vuliel_drae.dives_the_dungeon", "toren.guides_vuliel_drae",
			"mrsha.learned_grow_grass", "mrsha.is_a_druid", "wandering_inn.creler_egg_destroyed"]:
		assert_true(gs.flags.has(f), f)
	assert_true(gs.world.is_alive(_db.canon, "toren"))
	assert_true(gs.world.is_alive(_db.canon, "mrsha"))


func test_records_are_fixed() -> void:
	var n: Dictionary = _db.canon.npcs
	var names: Array = []
	for c: Dictionary in n["toren"]["classes"]:
		names.append(c["name"])
	assert_true(names.has("[Skeleton Knight]"))
	assert_true(names.has("[Sword Dancer]"))
	names = []
	for c: Dictionary in n["wesle"]["classes"]:
		names.append(c["name"])
	assert_true(names.has("[Actor]"))
