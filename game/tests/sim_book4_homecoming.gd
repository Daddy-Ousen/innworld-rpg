extends GutTest
## M10.3 on the real Book 4 data (days 90-93). The wagon reaches Esthelm and
## then the inn (day 91). Zel scolds Erin in the common room; that night Erin
## reaches Level 30 and the Albez door starts to run. On day 92 she asks for
## help for Esthelm at breakfast and then leaves with the relief convoy. A
## player who stands by Lyonette, or who talks the plan over, changes those
## two scenes. The game is slept to day 90 once (before_all); each test starts
## from a copy of that save.

const SEED := 20260927
const SCOLD := "b4.zel_scolds_erin_for_lyonette"
const SCOLD_HOOK := "player_stood_by_lyonette"
const PITCH := "b4.erin_pitches_the_esthelm_relief"
const PITCH_HOOK := "player_backed_erins_relief_plan"
const SCOLD_SPOT := Vector2i(10, 11)
const PITCH_SPOT := Vector2i(11, 7)
const INN_DOOR := "albez_door"
const NEXT_TO_INN_DOOR := Vector2i(3, 12)

var _db: DataDb
var _day90 := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])
	var gs := GameState.new_game(SEED, _db)
	ToyCanon.sleep_through(gs, _db, 89)
	_day90 = gs.to_json()


func _fresh(day: int = 90) -> GameState:
	var gs := GameState.from_json(_day90)
	if day > 90:
		ToyCanon.sleep_through(gs, _db, day - 1)
	assert_eq(gs.clock.day(), day)
	return gs


## Stands at `spot` in the inn and waits (10 minutes a step, up to 20 hours)
## until the event's stage starts.
func _wait_for(gs: GameState, id: String, spot: Vector2i) -> void:
	gs.player.place("inn_interior", spot)
	Commands.settle(gs, _db)
	for i in 120:
		if gs.world.staged.has(id):
			break
		assert_true(Commands.wait(gs, _db, 600) >= 0, "wait")
	assert_true(gs.world.staged.has(id), "%s is staged" % id)


func _area_of(gs: GameState, id: String) -> String:
	var n: Dictionary = gs.npcs.npcs.get(id, {})
	return "gone" if n.is_empty() else String(n["area"])


func _hour(gs: GameState) -> int:
	@warning_ignore("integer_division")
	return gs.clock.minute() / 60


func _hook_of(gs: GameState, id: String) -> String:
	var entry: Dictionary = gs.world.history.filter(func(h: Dictionary) -> bool: return h["event"] == id)[0]
	return str(entry.get("hook", ""))


func test_the_scenes_are_loaded() -> void:
	for id: String in [SCOLD, PITCH]:
		assert_has(_db.canon.stages, id)
		var st: Dictionary = _db.canon.events[id]["stage"]
		assert_eq(st["area"], "inn_interior")
		assert_eq(st["kind"], "scene")
		for n: Dictionary in st["npcs"]:
			assert_true(_db.behaviour.npcs.has(n["npc"]), "%s can be placed" % n["npc"])
	assert_true(_db.classes.has("magical_innkeeper"))
	assert_true(_db.skills.has("inn_magical_grounds"))
	assert_true(_db.canon.npcs.has("umbral"))


func test_erin_arrives_home_on_day_91() -> void:
	var gs := _fresh()
	for f: String in ["erin.on_wagon_south", "erin.left_celum", "erin.stranded_north", "erin.left_liscor"]:
		assert_true(gs.flags.has(f), f)
	ToyCanon.sleep_through(gs, _db, 90)
	assert_true(gs.flags.has("esthelm.fed_by_erin"))
	assert_true(gs.flags.has("esthelm.believes_the_purple_eyed_skeleton_died"))
	assert_true(gs.flags.has("erin.on_wagon_south"), "still on the wagon on the night of day 90")
	assert_false(gs.flags.has("erin.home_at_the_inn"))
	ToyCanon.sleep_through(gs, _db, 91)
	assert_true(gs.flags.has("erin.home_at_the_inn"))
	for f: String in ["erin.on_wagon_south", "erin.left_celum", "erin.in_celum", "erin.stranded_north", "erin.left_liscor"]:
		assert_false(gs.flags.has(f), f)
	assert_true(gs.world.is_alive(_db.canon, "toren"), "Toren lives")


func test_zel_scolds_erin_at_the_inn() -> void:
	var gs := _fresh(91)
	_wait_for(gs, SCOLD, SCOLD_SPOT)
	var h := _hour(gs)
	assert_true(h >= 17 and h < 19, "in the early evening")
	for who: String in ["erin_solstice", "zel_shivertail", "lyonette"]:
		assert_eq(_area_of(gs, who), "inn_interior", who)
	ToyCanon.sleep_through(gs, _db, 91)
	assert_eq(gs.world.status(SCOLD), Director.DONE)
	assert_true(gs.flags.has("erin.apologised_to_lyonette"))
	assert_false(gs.flags.has("wandering_inn.earther_stood_by_lyonette"))


func test_speaking_up_in_the_scene_changes_it() -> void:
	var gs := _fresh(91)
	_wait_for(gs, SCOLD, SCOLD_SPOT)
	# Lyonette is already in the room at her own post, so the stage does not move her;
	# Zel and Erin are brought in and stand next to the player.
	var r := Commands.interact(gs, _db, "zel_shivertail", "persuade")
	assert_eq(r["error"], "")
	assert_eq(r["record"]["context"]["location"], "wandering_inn")
	ToyCanon.sleep_through(gs, _db, 91)
	assert_eq(gs.world.status(SCOLD), Director.CHANGED)
	assert_eq(_hook_of(gs, SCOLD), SCOLD_HOOK)
	assert_true(gs.flags.has("wandering_inn.earther_stood_by_lyonette"))
	assert_true(gs.flags.has("erin.apologised_to_lyonette"), "the canon still happens")
	assert_true(gs.world.relationship("lyonette", NpcSim.PLAYER) >= 2)


func test_no_scolding_without_zel() -> void:
	var gs := _fresh(91)
	assert_eq(Commands.kill_npc(gs, _db, "zel_shivertail"), "")
	ToyCanon.sleep_through(gs, _db, 91)
	assert_eq(gs.world.status(SCOLD), Director.CANCELLED)
	assert_true(gs.flags.has("erin.home_at_the_inn"), "Erin still comes home")


func test_the_door_runs_after_level_30() -> void:
	var gs := _fresh(91)
	gs.player.place("inn_interior", NEXT_TO_INN_DOOR)
	Commands.settle(gs, _db)
	assert_ne(Commands.portal(gs, _db, INN_DOOR), "", "no door in the inn on day 91")
	ToyCanon.sleep_through(gs, _db, 91)
	assert_true(gs.flags.has("albez_door.at_wandering_inn"))
	assert_true(gs.flags.has("erin.magical_grounds"))
	assert_true(gs.flags.has("erin.class_magical_innkeeper"))
	assert_eq(gs.clock.day(), 92)
	gs.player.place("inn_interior", NEXT_TO_INN_DOOR)
	Commands.settle(gs, _db)
	assert_eq(Commands.portal(gs, _db, INN_DOOR), "", "the door carries the player to Celum")
	assert_eq(gs.player.area, "celum_stitchworks")


func test_erin_pitches_the_relief_at_breakfast() -> void:
	var gs := _fresh(92)
	_wait_for(gs, PITCH, PITCH_SPOT)
	var h := _hour(gs)
	assert_true(h >= 7 and h < 9, "at breakfast")
	for who: String in ["erin_solstice", "ceria_springwalker", "pisces"]:
		assert_eq(_area_of(gs, who), "inn_interior", who)
	ToyCanon.sleep_through(gs, _db, 92)
	assert_eq(gs.world.status(PITCH), Director.DONE)
	assert_true(gs.flags.has("esthelm_relief.planned"))
	assert_false(gs.flags.has("esthelm_relief.earther_backed_the_plan"))


func test_talking_the_plan_over_changes_the_event() -> void:
	var gs := _fresh(92)
	_wait_for(gs, PITCH, PITCH_SPOT)
	var r := Commands.interact(gs, _db, "ceria_springwalker", "persuade")
	assert_eq(r["error"], "")
	ToyCanon.sleep_through(gs, _db, 92)
	assert_eq(gs.world.status(PITCH), Director.CHANGED)
	assert_eq(_hook_of(gs, PITCH), PITCH_HOOK)
	assert_true(gs.flags.has("esthelm_relief.earther_backed_the_plan"))
	assert_true(gs.flags.has("esthelm_relief.planned"), "the canon still happens")


func test_no_scenes_on_other_days() -> void:
	var gs := _fresh(90)
	gs.player.place("inn_interior", SCOLD_SPOT)
	Commands.settle(gs, _db)
	for i in 16:
		Commands.wait(gs, _db, 3600)
		assert_false(gs.world.staged.has(SCOLD))
		assert_false(gs.world.staged.has(PITCH))


func test_erin_is_at_esthelm_after_the_convoy() -> void:
	var gs := _fresh(93)
	assert_true(gs.flags.has("erin.at_esthelm"))
	for i in 4:
		Commands.wait(gs, _db, 3600)
		assert_ne(_area_of(gs, "erin_solstice"), "inn_interior", "hour %d" % i)
		assert_ne(_area_of(gs, "erin_solstice"), "celum_frenzied_hare", "hour %d" % i)


func test_ryoka_and_laken_meet_in_invrisil_on_day_93() -> void:
	var gs := _fresh(92)
	assert_true(gs.flags.has("ivolethe.banished_from_magnolias_land"))
	ToyCanon.sleep_through(gs, _db, 93)
	assert_false(gs.flags.has("ivolethe.banished_from_magnolias_land"))
	for f: String in ["ryoka.researched_magnolias_library", "ryoka.holds_magnolias_seal", "ryoka.delivered_remendia_packages",
			"laken.reached_invrisil", "ryoka.suspects_laken_is_an_earther", "esthelm.snow_has_stopped"]:
		assert_true(gs.flags.has(f), f)
