extends GutTest
## M4.4 acceptance: one day (day 8) with the real NPCs. The player waits at
## the Liscor east gate, goes to the market at noon, buys and talks to
## Krshia, walks home to the inn and sleeps. NPCs follow their schedules
## (data/npc_behaviour.json). Same seed = same result; a save/load mid-day
## changes nothing.

const SEED := 20260923

var _db: DataDb
## Notes the legs write while they run (for the checks).
var _seen := {}


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])


func _legs() -> Array[Callable]:
	return [
		func(gs: GameState) -> void: _check_gate_morning(gs),
		func(gs: GameState) -> void: _wait_until(gs, 8 * 60 + 30, "liscor_gate"),
		func(gs: GameState) -> void: _check_gate_patrol(gs),
		func(gs: GameState) -> void: _to_area(gs, "liscor_market"),
		func(gs: GameState) -> void: _wait_until(gs, 12 * 60 + 5, "liscor_market"),
		func(gs: GameState) -> void: _check_market_noon(gs),
		func(gs: GameState) -> void: _use(gs, "krshia_counter", "buy_supplies"),
		func(gs: GameState) -> void: _talk(gs, "krshia", "talk_with_guest"),
		func(gs: GameState) -> void: _to_area(gs, "liscor_gate"),
		func(gs: GameState) -> void: _to_area(gs, "floodplains_south"),
		func(gs: GameState) -> void: _to_area(gs, "inn_hill"),
		func(gs: GameState) -> void: _to_area(gs, "inn_interior"),
		func(gs: GameState) -> void: _wait_until(gs, 18 * 60 + 10, "inn_interior"),
		func(gs: GameState) -> void: _check_inn_evening(gs),
		func(gs: GameState) -> void: Commands.sleep(gs, _db),
	]


func _play(gs: GameState, from_leg: int = 0, to_leg: int = -1) -> void:
	var legs := _legs()
	for i in range(from_leg, legs.size() if to_leg < 0 else to_leg):
		legs[i].call(gs)


func _where(gs: GameState, id: String) -> String:
	var n: Dictionary = gs.npcs.npcs.get(id, {})
	if n.is_empty():
		return "gone"
	if BehaviourDb.is_off_map(n["area"]):
		return n["area"]
	return "%s %d,%d" % [n["area"], int(n["x"]), int(n["y"])]


## Waits a minute at a time until `minute` of the day, noting which NPCs
## showed up in `area` meanwhile (_seen[area]).
func _wait_until(gs: GameState, minute: int, area: String) -> void:
	var seen: Dictionary = _seen.get(area, {})
	while gs.clock.minute() < minute:
		assert_true(Commands.wait(gs, _db, 60) >= 0, "wait")
		for id in gs.npcs.in_area(area):
			seen[id] = true
	_seen[area] = seen


func _to_area(gs: GameState, area: String) -> void:
	assert_true(ToyMaps.walk_to_area(gs, _db, area), "walk to %s" % area)


func _use(gs: GameState, object_id: String, action_id: String) -> void:
	assert_true(ToyMaps.walk_next_to(gs, _db, object_id), "walk to %s" % object_id)
	assert_eq(Commands.interact(gs, _db, object_id, action_id)["error"], "")


func _talk(gs: GameState, npc: String, action_id: String) -> void:
	var at := NpcRoster.pos_of(gs.npcs.npcs[npc])
	var goals := Pathfind.around(at)
	goals.erase(at)
	assert_true(ToyMaps.walk_to(gs, _db, goals), "walk to %s" % npc)
	assert_eq(Commands.interact(gs, _db, npc, action_id)["error"], "", "talk to %s" % npc)


func _check_gate_morning(gs: GameState) -> void:
	assert_eq(gs.clock.day(), 8)
	assert_eq(_where(gs, "beilmark"), "liscor_gate 2,13", "on guard at the gate")
	assert_eq(_where(gs, "zevara"), "@liscor", "not yet at the gate")
	assert_eq(_where(gs, "krshia"), "@liscor", "before the market opens")
	assert_eq(_where(gs, "erin_solstice"), "inn_interior 20,2", "cooking breakfast")
	assert_eq(_where(gs, "rags"), "@wilds")


func _check_gate_patrol(gs: GameState) -> void:
	var seen: Dictionary = _seen["liscor_gate"]
	assert_true(seen.has("zevara"), "Zevara checked the gate at 07:00")
	assert_true(seen.has("erin_solstice"), "Erin walked past on her way into Liscor")
	assert_eq(_where(gs, "erin_solstice"), "@liscor")
	for id: String in ["relc", "klbkch", "beilmark"]:
		assert_true(_where(gs, id).begins_with("liscor_gate"), "%s at the gate: %s" % [id, _where(gs, id)])
	assert_eq(_where(gs, "zevara"), "@liscor", "back in the barracks")
	assert_eq(_where(gs, "rags"), "floodplains_south 5,19", "foraging (not seen, jumped)")


func _check_market_noon(gs: GameState) -> void:
	assert_eq(_where(gs, "krshia"), "liscor_market 10,5")
	assert_eq(_where(gs, "lism"), "liscor_market 20,5")
	assert_eq(_where(gs, "erin_solstice"), "liscor_market 20,8", "at Lism's stall (canon day 8)")
	assert_eq(_where(gs, "selys"), "liscor_market 14,14", "walked in for lunch")


func _check_inn_evening(gs: GameState) -> void:
	assert_true((_seen["inn_interior"] as Dictionary).has("erin_solstice"), "Erin came home")
	assert_eq(_where(gs, "erin_solstice"), "inn_interior 20,2", "cooking dinner")
	assert_eq(_where(gs, "klbkch"), "inn_interior 10,8", "the Watch visits (flag from day 5)")
	assert_eq(_where(gs, "relc"), "inn_interior 8,8", "not thrown out yet (day 9)")


func test_npc_day() -> void:
	var gs := GameState.new_game(SEED, _db)
	_seen = {}
	_play(gs)
	assert_eq(gs.clock.day(), 9)
	assert_eq(gs.world.relationship("krshia", NpcSim.PLAYER), 1, "talked with Krshia")
	assert_eq(_where(gs, "relc"), "inn_hill 16,13", "day 9 dawn: Relc brings his gift")
	assert_eq(_where(gs, "goblin_chieftain"), "@wilds")
	assert_true(Commands.wait(gs, _db, 14 * 3600) >= 0, "day 9 goes by")
	Commands.sleep(gs, _db)
	assert_eq(gs.clock.day(), 10)
	assert_eq(gs.world.status("b1.erin_kills_chieftain"), Director.DONE)
	assert_eq(_where(gs, "goblin_chieftain"), "gone", "dead NPCs leave the world")


func test_same_seed_same_npcs() -> void:
	var a := GameState.new_game(SEED, _db)
	var b := GameState.new_game(SEED, _db)
	_play(a)
	_play(b)
	assert_eq(a.to_json(), b.to_json())


func test_save_and_load_mid_day_changes_nothing() -> void:
	var straight := GameState.new_game(SEED, _db)
	_play(straight)
	var gs := GameState.new_game(SEED, _db)
	_play(gs, 0, 5)
	var loaded := GameState.from_json(gs.to_json())
	assert_eq(loaded.to_json(), gs.to_json())
	_play(loaded, 5)
	assert_eq(loaded.to_json(), straight.to_json())
