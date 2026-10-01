extends GutTest
## M18.7 on the real Book 6 data (day 130): the battle of Invrisil, Zel's death,
## and Liscor's mourning (a scene stage in the inn with a talk hook with Erin).
## The game is slept to day 129 once (before_all); each test starts from a copy.

const SEED := 20261004
const DAY := 130
const MOURNING := "b6.liscor_mourns_zel"
const DEATH := "b6.zel_names_the_goblin_lord_reiss_and_dies"
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


func _wait_for_stage(gs: GameState) -> void:
	gs.player.place("inn_interior", DOOR_SPOT)
	Commands.settle(gs, _db)
	for i in 120:
		if gs.world.staged.has(MOURNING):
			break
		assert_true(Commands.wait(gs, _db, 600) >= 0, "wait")
	assert_true(gs.world.staged.has(MOURNING), "the mourning is staged")


func _talk_to(gs: GameState, id: String) -> void:
	var n: Dictionary = gs.npcs.npcs[id]
	var at := Vector2i(int(n["x"]), int(n["y"]))
	var sides := {at + Vector2i(1, 0): true, at + Vector2i(-1, 0): true, at + Vector2i(0, 1): true, at + Vector2i(0, -1): true}
	assert_true(ToyMaps.walk_to(gs, _db, sides), "walk to " + id)
	var r := Commands.interact(gs, _db, id, "talk_with_guest")
	assert_eq(r["error"], "")


func test_the_mourning_is_a_scene_in_the_inn_without_xp() -> void:
	var ev: Dictionary = _db.canon.events[MOURNING]
	assert_eq(ev["stage"]["kind"], "scene")
	assert_eq(ev["stage"]["area"], "inn_interior")
	assert_false(ev.has("xp_window"))
	assert_eq(ev["depends_on"], [DEATH])
	for n: Dictionary in ev["stage"]["npcs"]:
		assert_true(_db.behaviour.npcs.has(n["npc"]), n["npc"])


func test_zel_dies_and_the_goblin_lord_is_named() -> void:
	var gs := _fresh()
	ToyCanon.sleep_through(gs, _db, DAY)
	assert_false(gs.world.is_alive(_db.canon, "zel_shivertail"))
	for f: String in ["zel.dead_at_invrisil", "goblin_lord.named_reiss", "world.believes_the_goblin_lord_killed_zel",
			"azkerash.and_the_chosen_killed_zel", "liscor.mourns_zel", "antinium.grand_queen_mirror_open"]:
		assert_true(gs.flags.has(f), f)


func test_the_battle_kills_the_named_dead_only() -> void:
	var gs := _fresh()
	ToyCanon.sleep_through(gs, _db, DAY)
	for id: String in ["oom", "sir_evimore", "illbreath", "noface"]:
		assert_false(gs.world.is_alive(_db.canon, id), id)
	for id: String in ["goblin_lord", "snapjaw", "eater_of_spears", "bea", "kerash", "venitra", "ijvani", "azkerash", "osthia_blackwing",
			"magnolia_reinhart", "reynold", "thomast", "bethal", "klbkch", "erin_solstice"]:
		assert_true(gs.world.is_alive(_db.canon, id), id + " lives")


func test_the_mourning_stage_brings_erin_and_klbkch() -> void:
	var gs := _fresh()
	_wait_for_stage(gs)
	for id: String in ["erin_solstice", "lyonette", "mrsha", "klbkch"]:
		assert_eq(String(gs.npcs.npcs[id]["area"]), "inn_interior", id)


func test_sitting_with_erin_changes_the_mourning() -> void:
	var gs := _fresh()
	_wait_for_stage(gs)
	_talk_to(gs, "erin_solstice")
	ToyCanon.sleep_through(gs, _db, DAY)
	assert_eq(gs.world.status(MOURNING), Director.CHANGED)
	assert_true(gs.flags.has("wandering_inn.earther_shared_the_grief_with_erin"))
	assert_true(gs.flags.has("liscor.mourns_zel"), "the mourning happens either way")


func test_staying_away_leaves_the_night_unseen() -> void:
	var gs := _fresh()
	ToyCanon.sleep_through(gs, _db, DAY)
	assert_eq(gs.world.status(MOURNING), Director.DONE)
	assert_false(gs.flags.has("wandering_inn.earther_shared_the_grief_with_erin"))


func test_the_chosen_fixes_and_the_teleport_note() -> void:
	assert_true(String(_db.canon.npcs["oom"]["summary"]).contains("Acid Slime"))
	assert_true(String(_db.canon.npcs["bea"]["summary"]).contains("plague"))
	assert_true(String(_db.canon.npcs["kerash"]["summary"]).contains("magic sword"))
	var gs := _fresh()
	assert_true(gs.flags.has("azkerash.lost_some_teleport_scrolls"))
	assert_false(gs.flags.has("azkerash.lost_his_teleport_scrolls"))
