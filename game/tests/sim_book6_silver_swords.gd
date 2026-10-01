extends GutTest
## M18.6 on the real Book 6 data (4.43 – 4.47, days 128 – 129): the Silver Swords
## arrive at the inn into a cake fight (a scene stage), Ilvriss is there, and
## Zel's speech reaches Liscor. A player who talks with a guest changes the
## event. The game is slept to day 128 once (before_all); each test starts
## from a copy of that save.

const SEED := 20261003
const DAY := 129
const ARRIVAL := "b6.the_silver_swords_arrive_into_a_cake_fight"
const COUNCIL := "b6.liscor_council_hears_zels_speech"
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
		if gs.world.staged.has(ARRIVAL):
			break
		assert_true(Commands.wait(gs, _db, 600) >= 0, "wait")
	assert_true(gs.world.staged.has(ARRIVAL), "the arrival is staged")


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


func test_the_arrival_is_a_scene_in_the_inn() -> void:
	var ev: Dictionary = _db.canon.events[ARRIVAL]
	assert_eq(ev["stage"]["kind"], "scene")
	assert_eq(ev["stage"]["area"], "inn_interior")
	assert_false(ev.has("xp_window"))
	for n: Dictionary in ev["stage"]["npcs"]:
		assert_true(_db.behaviour.npcs.has(n["npc"]), n["npc"])


func test_the_silver_swords_and_ilvriss_come_to_the_inn() -> void:
	var gs := _fresh()
	_wait_for_stage(gs)
	@warning_ignore("integer_division")
	var h: int = gs.clock.minute() / 60
	assert_true(h >= 16 and h < 24, "sunset to midnight")
	for id: String in ["ylawes_byres", "yvlon_byres", "falene_skystrall", "dawil", "ilvriss", "badarrow", "jelaqua"]:
		assert_eq(_area_of(gs, id), "inn_interior", id)


func test_talking_to_dawil_changes_the_arrival() -> void:
	var gs := _fresh()
	_wait_for_stage(gs)
	_talk_to(gs, "dawil")
	ToyCanon.sleep_through(gs, _db, DAY)
	assert_eq(gs.world.status(ARRIVAL), Director.CHANGED)
	assert_true(gs.flags.has("wandering_inn.earther_talked_to_the_silver_swords"))
	assert_true(gs.flags.has("wandering_inn.ylawes_arrived"), "the arrival happens either way")
	assert_true(gs.world.relationship("dawil", NpcSim.PLAYER) >= 1)


func test_talking_to_ilvriss_changes_the_council() -> void:
	var gs := _fresh()
	_wait_for_stage(gs)
	_talk_to(gs, "ilvriss")
	ToyCanon.sleep_through(gs, _db, DAY)
	assert_eq(gs.world.status(COUNCIL), Director.CHANGED)
	assert_true(gs.flags.has("wandering_inn.earther_spoke_with_ilvriss_about_zel"))
	assert_true(gs.flags.has("liscor.council_emergency_meeting"))


func test_staying_away_leaves_the_night_unseen() -> void:
	var gs := _fresh()
	ToyCanon.sleep_through(gs, _db, DAY)
	assert_eq(gs.world.status(ARRIVAL), Director.DONE)
	assert_false(gs.flags.has("wandering_inn.earther_talked_to_the_silver_swords"))
	for f: String in ["wandering_inn.ylawes_arrived", "silver_swords.joined_the_calruz_search", "erin.level_33_magical_innkeeper",
			"erin.coin_is_mithril", "zel.speech_at_invrisil", "goblin_lord.ordered_to_attack_invrisil", "hawk.sent_with_the_pallass_anchor"]:
		assert_true(gs.flags.has(f), f)


func test_magnolia_and_the_goblin_lord_days_run_in_order() -> void:
	var gs := _fresh()
	ToyCanon.sleep_through(gs, _db, DAY)
	# 4.44 M is day 128 (before the speech), 4.46 is day 128, 4.47 day 129.
	var e: Dictionary = _db.canon.events
	assert_eq(int(e["b6.magnolia_pitches_a_world_coalition"]["window"]["earliest"]), 128)
	assert_eq(int(e["b6.goblin_lord_breaks_a_human_army_at_a_river_city"]["window"]["earliest"]), 128)
	assert_eq(int(e["b6.zel_speaks_to_magnolias_army"]["window"]["earliest"]), 129)
	assert_true(gs.flags.has("zel.wears_the_heartflame_breastplate"))
