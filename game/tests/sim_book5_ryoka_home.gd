extends GutTest
## M13.2 on the real Book 5 data (4.08 T – 4.12, days 101–102). Three scenes:
## Ilvriss corners Ryoka in a Liscor street (day 101, early afternoon), Ryoka
## hands the Horns their new gear at the inn (day 101, evening), and Klbkch
## prices the inn's new floors while Pisces tests the door (day 102,
## afternoon). A player who talks with them changes each event. From day 102
## Ryoka and the Horns live at the inn, and the rift ropes to the new dungeon
## section are open.
## The game is slept to day 100 once (before_all); each test starts from a
## copy of that save.

const SEED := 20260928
const DAY := 101
const STREET := "b5.n_ilvriss_confronts_ryoka_in_the_street"
const GEAR := "b5.p_ryoka_hands_the_horns_their_gear"
const CONTRACT := "b5.t_klbkch_takes_the_building_contract"
const INN_SPOT := Vector2i(12, 11)
const MARKET_SPOT := Vector2i(15, 13)
const RIFT_ROPES := Vector2i(12, 12)

var _db: DataDb
var _day101 := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])
	var gs := GameState.new_game(SEED, _db)
	ToyCanon.sleep_through(gs, _db, DAY - 1)
	_day101 = gs.to_json()


func _fresh() -> GameState:
	var gs := GameState.from_json(_day101)
	assert_eq(gs.clock.day(), DAY)
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


## Walks next to `npc` and runs `action` with them.
func _do_with(gs: GameState, npc: String, action: String, location: String) -> void:
	var n: Dictionary = gs.npcs.npcs[npc]
	var at := Vector2i(int(n["x"]), int(n["y"]))
	var sides := {at + Vector2i(1, 0): true, at + Vector2i(-1, 0): true, at + Vector2i(0, 1): true, at + Vector2i(0, -1): true}
	if not sides.has(gs.player.pos()):
		assert_true(ToyMaps.walk_to(gs, _db, sides), "walk to " + npc)
	var r := Commands.interact(gs, _db, npc, action)
	assert_eq(r["error"], "")
	assert_eq(r["record"]["context"]["location"], location)


func test_the_stages_are_loaded() -> void:
	assert_eq(_db.canon.events[STREET]["stage"]["area"], "liscor_market")
	assert_eq(_db.canon.events[GEAR]["stage"]["area"], "inn_interior")
	assert_eq(_db.canon.events[CONTRACT]["stage"]["area"], "inn_interior")
	for id: String in [STREET, GEAR, CONTRACT]:
		assert_has(_db.canon.stages, id)
		var st: Dictionary = _db.canon.events[id]["stage"]
		assert_eq(st["kind"], "scene", id)
		for n: Dictionary in st["npcs"]:
			assert_true(_db.behaviour.npcs.has(n["npc"]), "%s can be placed by %s" % [n["npc"], id])
	# The two day-101 scenes do not overlap.
	var a: Array = _db.canon.events[STREET]["stage"]["hours"]
	var b: Array = _db.canon.events[GEAR]["stage"]["hours"]
	assert_true(int(a[1]) <= int(b[0]), "the street is over before the party")


func test_ilvriss_corners_ryoka_in_the_early_afternoon() -> void:
	var gs := _fresh()
	_wait_for(gs, STREET, "liscor_market", MARKET_SPOT)
	var h := _hour(gs)
	assert_true(h >= 12 and h < 15, "early afternoon")
	for npc: String in ["ryoka_griffin", "ilvriss", "zel_shivertail", "zevara", "erin_solstice"]:
		assert_eq(_area_of(gs, npc), "liscor_market", npc)
	assert_false(gs.world.staged.has(GEAR), "the party is later")


func test_standing_with_ryoka_changes_the_standoff() -> void:
	var gs := _fresh()
	_wait_for(gs, STREET, "liscor_market", MARKET_SPOT)
	_do_with(gs, "ryoka_griffin", "comfort_someone", "liscor_market")
	ToyCanon.sleep_through(gs, _db, DAY)
	_assert_changed(gs, STREET, "player_stood_with_ryoka_in_the_street",
			"liscor.earther_stood_with_ryoka_against_ilvriss", "erin.hit_ilvriss_with_a_pan")
	assert_true(gs.world.relationship("ryoka_griffin", NpcSim.PLAYER) >= 2)


func test_the_horns_get_their_gear_in_the_evening() -> void:
	var gs := _fresh()
	_wait_for(gs, GEAR, "inn_interior", INN_SPOT)
	assert_true(_hour(gs) >= 18, "in the evening")
	for npc: String in ["ryoka_griffin", "ceria_springwalker", "pisces", "yvlon_byres", "ksmvr"]:
		assert_eq(_area_of(gs, npc), "inn_interior", npc)
	ToyCanon.sleep_through(gs, _db, DAY)
	assert_eq(gs.world.status(GEAR), Director.DONE)
	assert_true(gs.flags.has("horns_of_hammerad.have_hedaults_gear"))
	assert_false(gs.flags.has("ryoka.carries_the_horns_relics"), "the bag is empty")


func test_toasting_the_horns_changes_the_party() -> void:
	var gs := _fresh()
	_wait_for(gs, GEAR, "inn_interior", INN_SPOT)
	_do_with(gs, "ceria_springwalker", "talk_with_guest", "wandering_inn")
	ToyCanon.sleep_through(gs, _db, DAY)
	_assert_changed(gs, GEAR, "player_toasted_the_horns_new_gear",
			"wandering_inn.earther_toasted_the_horns", "yvlon.has_enchanted_arms_and_armour")
	assert_true(gs.world.relationship("ceria_springwalker", NpcSim.PLAYER) >= 1)


func test_klbkch_prices_the_new_floors_on_day_102() -> void:
	var gs := _fresh()
	ToyCanon.sleep_through(gs, _db, DAY)
	_wait_for(gs, CONTRACT, "inn_interior", INN_SPOT)
	var h := _hour(gs)
	assert_true(h >= 13 and h < 17, "in the afternoon")
	for npc: String in ["klbkch", "erin_solstice", "ryoka_griffin", "pisces"]:
		assert_eq(_area_of(gs, npc), "inn_interior", npc)


func test_weighing_in_changes_the_contract() -> void:
	var gs := _fresh()
	ToyCanon.sleep_through(gs, _db, DAY)
	_wait_for(gs, CONTRACT, "inn_interior", INN_SPOT)
	_do_with(gs, "klbkch", "persuade", "wandering_inn")
	ToyCanon.sleep_through(gs, _db, DAY + 1)
	_assert_changed(gs, CONTRACT, "player_weighed_in_on_the_inn_plans",
			"wandering_inn.earther_weighed_in_on_the_building", "wandering_inn.expansion_planned")
	assert_true(gs.world.relationship("klbkch", NpcSim.PLAYER) >= 1)
	assert_false(gs.flags.has("wandering_inn.expansion_begun"), "the Antinium start in 4.18")


func test_ryoka_and_the_horns_eat_at_the_inn_from_day_102() -> void:
	var gs := _fresh()
	ToyCanon.sleep_through(gs, _db, DAY)
	gs.player.place("inn_interior", INN_SPOT)
	Commands.settle(gs, _db)
	while _hour(gs) < 19:
		assert_true(Commands.wait(gs, _db, 1800) >= 0, "wait")
	for npc: String in ["ryoka_griffin", "ceria_springwalker", "pisces", "yvlon_byres", "ksmvr"]:
		assert_eq(_area_of(gs, npc), "inn_interior", npc)
		assert_eq(gs.npcs.npcs[npc]["goal"], "eat", npc)


func test_the_rift_ropes_open_after_vuliel_drae_go_down() -> void:
	var gs := _fresh()
	_db.maps.sync_flags(gs.flags)
	assert_true(_db.maps.exit_at("dungeon_rift", RIFT_ROPES).is_empty(), "day 101: not found yet")
	ToyCanon.sleep_through(gs, _db, DAY)
	assert_true(gs.flags.has("liscor_dungeon.new_section_found"))
	_db.maps.sync_flags(gs.flags)
	assert_eq(_db.maps.exit_at("dungeon_rift", RIFT_ROPES)["to"], "liscor_depths", "day 102: the ropes")
	Commands.wait(gs, _db, 600)
	assert_eq(_area_of(gs, "toren"), "liscor_depths", "Toren walks the rune hall")


func test_no_scenes_on_another_day() -> void:
	var gs := _fresh()
	ToyCanon.sleep_through(gs, _db, DAY + 1)
	for area: String in ["inn_interior", "liscor_market"]:
		gs.player.place(area, INN_SPOT if area == "inn_interior" else MARKET_SPOT)
		Commands.settle(gs, _db)
		for i in 8:
			Commands.wait(gs, _db, 3600)
			for id: String in [STREET, GEAR, CONTRACT]:
				assert_false(gs.world.staged.has(id), id)
