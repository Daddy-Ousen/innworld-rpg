extends GutTest
## M19.2 on the real Book 7 data (5.00 – 5.03, days 133 – 135): the lunch after
## Zel's death (a scene stage in the inn, day 133), the Pallass crisis, the
## secret deal with Venim (a scene stage in the inn, day 134, the rains begin)
## and the lease. A player who talks with a guest changes the event. The game is
## slept to day 133 once (before_all); each test starts from a copy of that save.

const SEED := 20261007
const LUNCH_DAY := 133
const DEAL_DAY := 134
const LUNCH := "b7.erin_cheers_up_with_relc"
const DEAL := "b7.zevara_brings_venim_to_the_inn"
const DOOR_SPOT := Vector2i(3, 3)

var _db: DataDb
var _base := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])
	var gs := GameState.new_game(SEED, _db)
	ToyCanon.sleep_through(gs, _db, LUNCH_DAY - 1)
	_base = gs.to_json()


func _fresh() -> GameState:
	var gs := GameState.from_json(_base)
	assert_eq(gs.clock.day(), LUNCH_DAY)
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


func test_both_stages_are_scenes_in_the_inn() -> void:
	for id: String in [LUNCH, DEAL]:
		var ev: Dictionary = _db.canon.events[id]
		assert_eq(ev["stage"]["kind"], "scene", id)
		assert_eq(ev["stage"]["area"], "inn_interior", id)
		assert_false(ev.has("xp_window"), id)
		for n: Dictionary in ev["stage"]["npcs"]:
			assert_true(_db.behaviour.npcs.has(n["npc"]), n["npc"])


func test_the_lunch_brings_relc_and_ilvriss_to_the_inn() -> void:
	var gs := _fresh()
	_wait_for_stage(gs, LUNCH)
	@warning_ignore("integer_division")
	var h: int = gs.clock.minute() / 60
	assert_true(h >= 11 and h < 14, "lunch hours")
	for id: String in ["relc", "ilvriss", "mrsha", "jelaqua", "moore"]:
		assert_eq(_area_of(gs, id), "inn_interior", id)


func test_talking_to_relc_changes_the_lunch() -> void:
	var gs := _fresh()
	_wait_for_stage(gs, LUNCH)
	_talk_to(gs, "relc")
	ToyCanon.sleep_through(gs, _db, LUNCH_DAY)
	assert_eq(gs.world.status(LUNCH), Director.CHANGED)
	assert_true(gs.flags.has("wandering_inn.earther_ate_with_relc_after_zel"))
	assert_true(gs.flags.has("mrsha.eats_again"), "the lunch happens either way")


func test_staying_away_still_runs_the_crisis() -> void:
	var gs := _fresh()
	ToyCanon.sleep_through(gs, _db, LUNCH_DAY)
	assert_eq(gs.world.status(LUNCH), Director.DONE)
	assert_false(gs.flags.has("wandering_inn.earther_ate_with_relc_after_zel"))
	for f: String in ["izril.mourns_zel", "relc.eats_at_the_inn", "pallass.vengeance_parade_held",
			"relc.arrested_in_pallass", "pallass.link_cut_by_erin", "erin.insulted_errif"]:
		assert_true(gs.flags.has(f), f)
	assert_false(gs.flags.has("pallass.door_end_set_in_the_alley"), "the link was cut")
	assert_false(gs.flags.has("albez_door.anchor_at_pallass"), "the player does not walk into Pallass")


func test_the_deal_stage_and_the_rains() -> void:
	var gs := _fresh()
	ToyCanon.sleep_through(gs, _db, LUNCH_DAY)
	assert_eq(gs.clock.day(), DEAL_DAY)
	assert_false(gs.flags.has("izril.rains"), "no rain before the deal")
	_wait_for_stage(gs, DEAL)
	@warning_ignore("integer_division")
	var h: int = gs.clock.minute() / 60
	assert_true(h >= 20 and h < 24, "evening")
	for id: String in ["zevara", "venim", "lyonette"]:
		assert_eq(_area_of(gs, id), "inn_interior", id)
	_talk_to(gs, "venim")
	ToyCanon.sleep_through(gs, _db, DEAL_DAY)
	assert_eq(gs.world.status(DEAL), Director.CHANGED)
	assert_true(gs.flags.has("wandering_inn.earther_overheard_the_pallass_deal"))
	assert_true(gs.flags.has("venim.met_erin"), "the deal happens either way")
	assert_true(gs.flags.has("izril.rains"))
	assert_true(gs.flags.has("pallass.embargo_of_liscor_begun"))


func test_the_lease_and_the_rain_days_run() -> void:
	var gs := _fresh()
	ToyCanon.sleep_through(gs, _db, 135)
	for f: String in ["erin.pallass_lease_filed", "erin.low_on_coin", "redfang.told_they_are_guests",
			"hive.helps_erins_money_plan", "erin.learns_of_the_spring_flood", "liscor.closes_for_the_rains",
			"goblin_lord.turned_from_invrisil", "izril.rains"]:
		assert_true(gs.flags.has(f), f)
	assert_true(gs.world.is_alive(_db.canon, "riefel"), "Riefel has no death record")
