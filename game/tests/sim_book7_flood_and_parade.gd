extends GutTest
## M19.6 on the real Book 7 data (5.12 – 5.15, days 137 – 140): the flood, the door end on
## Liscor's west wall, the Soldiers' dinner (day 138), the victory party (day 139) and the
## Vuliel Drae confession (day 140), each a scene stage in the inn with one talk hook,
## and the dungeon dive as events. The game is slept to day 138 once (before_all).

const SEED := 20261009
const DOOR_SPOT := Vector2i(3, 3)
const DINNER := "b7.klbkch_and_relc_visit_the_rebuilt_inn"
const PARTY := "b7.victory_party_at_the_inn"
const CONFESSION := "b7.vuliel_drae_confess_the_eggs"

var _db: DataDb
var _base := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])
	var gs := GameState.new_game(SEED, _db)
	ToyCanon.sleep_through(gs, _db, 137)
	_base = gs.to_json()


func _at_day(day: int) -> GameState:
	var gs := GameState.from_json(_base)
	if day > 138:
		ToyCanon.sleep_through(gs, _db, day - 1)
	assert_eq(gs.clock.day(), day)
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
	# Placed next to the NPC: a seated guest can block the walk in the crowded room.
	var n: Dictionary = gs.npcs.npcs[id]
	var at := Vector2i(int(n["x"]), int(n["y"]))
	var taken := {}
	for other: String in gs.npcs.in_area("inn_interior"):
		taken[NpcRoster.pos_of(gs.npcs.npcs[other])] = true
	var spot := Vector2i(-1, -1)
	for d: Vector2i in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
		if not taken.has(at + d):
			spot = at + d
			break
	assert_ne(spot, Vector2i(-1, -1), "a free side of " + id)
	gs.player.place("inn_interior", spot)
	var r := Commands.interact(gs, _db, id, "talk_with_guest")
	assert_eq(r["error"], "")


func test_the_three_stages_are_scenes_in_the_inn_without_windows() -> void:
	for id: String in [DINNER, PARTY, CONFESSION]:
		var ev: Dictionary = _db.canon.events[id]
		assert_eq(ev["stage"]["kind"], "scene", id)
		assert_eq(ev["stage"]["area"], "inn_interior", id)
		assert_false(ev.has("xp_window"), id)
		assert_eq(ev["hooks"].size(), 1, id)
		var seen := {}
		for n: Dictionary in ev["stage"]["npcs"]:
			assert_true(_db.behaviour.npcs.has(n["npc"]), n["npc"])
			var key := str(n["pos"])
			assert_false(seen.has(key), id + " tile used twice " + key)
			seen[key] = true


func test_the_flood_and_the_west_wall_door() -> void:
	var gs := _at_day(138)
	assert_true(gs.flags.has("izril.flood"), "water covers the low ground on day 138")
	assert_false(gs.flags.has("albez_door.anchor_at_liscor_wall"), "the door end is planned on day 138")
	ToyCanon.sleep_through(gs, _db, 138)
	assert_true(gs.flags.has("albez_door.anchor_at_liscor_wall"))
	assert_true(gs.flags.has("liscor.reimburses_defence_losses"))
	assert_true(gs.flags.has("olesm.is_strategist"))


func test_the_soldiers_dinner_has_a_klbkch_hook() -> void:
	var gs := _at_day(138)
	_wait_for_stage(gs, DINNER)
	@warning_ignore("integer_division")
	var h: int = gs.clock.minute() / 60
	assert_true(h >= 18 and h < 22, "evening hours")
	for id: String in ["klbkch", "relc", "pawn", "olesm", "octavia"]:
		assert_eq(_area_of(gs, id), "inn_interior", id)
	_talk_to(gs, "klbkch")
	ToyCanon.sleep_through(gs, _db, 138)
	assert_eq(gs.world.status(DINNER), Director.CHANGED)
	assert_true(gs.flags.has("wandering_inn.earther_heard_klbkch_on_the_repairs"))
	assert_true(gs.flags.has("antinium.workers_to_repair_inn"), "the repairs happen either way")


func test_the_victory_party_has_a_relc_hook() -> void:
	var gs := _at_day(139)
	_wait_for_stage(gs, PARTY)
	for id: String in ["relc", "embria_grasstongue", "ilvriss", "klbkch", "erin_solstice"]:
		assert_eq(_area_of(gs, id), "inn_interior", id)
	_talk_to(gs, "relc")
	ToyCanon.sleep_through(gs, _db, 139)
	assert_eq(gs.world.status(PARTY), Director.CHANGED)
	assert_true(gs.flags.has("wandering_inn.earther_watched_relc_and_embria"))
	assert_true(gs.flags.has("relc.has_his_spear"))
	assert_true(gs.flags.has("redfang.warned_by_embria"))
	assert_true(gs.flags.has("jelaqua.new_drake_body"))
	assert_false(gs.flags.has("jelaqua.body_broken"))


func test_the_confession_has_a_revi_hook() -> void:
	var gs := _at_day(140)
	_wait_for_stage(gs, CONFESSION)
	for id: String in ["revi", "halrac", "anith", "larr", "ylawes_byres"]:
		assert_eq(_area_of(gs, id), "inn_interior", id)
	_talk_to(gs, "revi")
	ToyCanon.sleep_through(gs, _db, 140)
	assert_eq(gs.world.status(CONFESSION), Director.CHANGED)
	assert_true(gs.flags.has("adventurers.earther_heard_the_vuliel_drae_confession"))
	assert_true(gs.flags.has("adventurers.know_vuliel_drae_guilt"))


func test_the_dive_runs_as_events() -> void:
	var gs := _at_day(140)
	ToyCanon.sleep_through(gs, _db, 140)
	for f: String in ["redfang.entered_dungeon", "dungeon.treasure_room_looted", "redfang.carry_three_artifacts",
			"redfang.badarrow_poisoned", "redfang.artifacts_recovered", "izril.tyrion_waits_for_the_rain_to_stop",
			"izril.goblin_hunt_declared", "bird.bow_broken", "erin.pays_goblins_weekly"]:
		assert_true(gs.flags.has(f), f)
	for id: String in ["rabbiteater", "headscratcher", "badarrow", "olesm", "relc", "erin_solstice"]:
		assert_true(gs.world.is_alive(_db.canon, id), id)
