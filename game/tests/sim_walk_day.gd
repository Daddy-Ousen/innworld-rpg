extends GutTest
## M4.2 acceptance: a first day on the real maps. From the Liscor east gate
## to the market (buy), out to the stream (water), up to the inn (cook),
## then sleep. Same seed = same result; a save/load mid-walk changes nothing.

const SEED := 20260923

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])


## The day in legs, so a test can stop between them.
func _legs() -> Array[Callable]:
	return [
		func(gs: GameState) -> void: _to_area(gs, "liscor_market"),
		func(gs: GameState) -> void: _use(gs, "krshia_counter", "buy_supplies"),
		func(gs: GameState) -> void: _use(gs, "krshia_counter", "haggle"),
		func(gs: GameState) -> void: _to_area(gs, "liscor_gate"),
		func(gs: GameState) -> void: _to_area(gs, "floodplains_south"),
		func(gs: GameState) -> void: _use(gs, "stream_bank", "carry_water"),
		func(gs: GameState) -> void: _to_area(gs, "inn_hill"),
		func(gs: GameState) -> void: _to_area(gs, "inn_interior"),
		func(gs: GameState) -> void: _use(gs, "stove", "cook_stew"),
		func(gs: GameState) -> void: _use(gs, "broom", "sweep_floor"),
	]


func _to_area(gs: GameState, area: String) -> void:
	assert_true(ToyMaps.walk_to_area(gs, _db, area), "walk to %s" % area)


func _use(gs: GameState, object_id: String, action_id: String) -> void:
	assert_true(ToyMaps.walk_next_to(gs, _db, object_id), "walk to %s" % object_id)
	var r := Commands.interact(gs, _db, object_id, action_id)
	assert_eq(r["error"], "", "%s at %s" % [action_id, object_id])


func _play(gs: GameState, from_leg: int = 0, to_leg: int = -1) -> void:
	var legs := _legs()
	for i in range(from_leg, legs.size() if to_leg < 0 else to_leg):
		legs[i].call(gs)


func test_first_day_walk() -> void:
	var gs := GameState.new_game(SEED, _db)
	var start := gs.clock.total_minutes
	_play(gs)
	assert_eq(gs.player.area, "inn_interior")
	var ids := gs.action_log.records.map(func(r: Dictionary) -> String: return r["action_id"])
	assert_eq(ids, ["travel", "buy_supplies", "haggle", "travel", "travel", "carry_water",
			"travel", "cook_stew", "sweep_floor"])
	var buy: Dictionary = gs.action_log.records[1]
	assert_true((buy["tags"] as Dictionary).has("social.conversation"), "market context")
	var stew: Dictionary = gs.action_log.records[7]
	assert_true((stew["tags"] as Dictionary).has("hospitality"), "inn context")
	var spent := gs.clock.total_minutes - start
	gut.p("walk day: %d min, now %s" % [spent, gs.clock.time_string()])
	assert_gt(spent, 10 + 30 + 20 + 10 + 20 + 30 + 20 + 90 + 30, "actions + travel + steps")
	var night := Commands.sleep(gs, _db)
	assert_eq(night["records"], 9)
	assert_eq(gs.clock.day(), 9)


func test_same_seed_same_day() -> void:
	var a := GameState.new_game(SEED, _db)
	var b := GameState.new_game(SEED, _db)
	_play(a)
	_play(b)
	Commands.sleep(a, _db)
	Commands.sleep(b, _db)
	assert_eq(a.to_json(), b.to_json())


func test_save_and_load_mid_walk_changes_nothing() -> void:
	var straight := GameState.new_game(SEED, _db)
	_play(straight)
	Commands.sleep(straight, _db)

	var gs := GameState.new_game(SEED, _db)
	_play(gs, 0, 5)
	var loaded := GameState.from_json(gs.to_json())
	assert_eq(loaded.player.to_dict(), gs.player.to_dict())
	_play(loaded, 5)
	Commands.sleep(loaded, _db)
	assert_eq(_diff(loaded.to_dict(), straight.to_dict(), "gs"), [] as Array[String])
	assert_eq(loaded.to_json(), straight.to_json())


## Differences between two states. Exact, floats too (save v5 writes
## floats as f64 text, ADR 0008).
func _diff(a: Variant, b: Variant, path: String) -> Array[String]:
	var out: Array[String] = []
	if a is Dictionary and b is Dictionary:
		if (a as Dictionary).keys() != (b as Dictionary).keys():
			out.append("%s: keys %s vs %s" % [path, a.keys(), b.keys()])
			return out
		for k: Variant in a:
			out.append_array(_diff(a[k], b[k], "%s.%s" % [path, k]))
	elif a is Array and b is Array:
		if a.size() != b.size():
			out.append("%s: size %d vs %d" % [path, a.size(), b.size()])
			return out
		for i in a.size():
			out.append_array(_diff(a[i], b[i], "%s[%d]" % [path, i]))
	elif typeof(a) != typeof(b) or a != b:
		out.append("%s: %s vs %s" % [path, a, b])
	return out
