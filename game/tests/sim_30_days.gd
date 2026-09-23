extends GutTest
## M1 acceptance: 30 days of scripted actions with a fixed seed give the same
## offers, levels and skills every run, and a declined class never returns.

const SEED := 20260923
const DAYS := 30
## Offers the script accepts. Every other offer is declined.
const ACCEPT := ["innkeeper", "cook", "strategist"]

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()


## One scripted day: inn work every day, plus chess, trade, foraging and
## fights on some days. Context and risk vary with the day.
func _play_day(gs: GameState, day: int) -> void:
	var guests := mini(2 + day, 20)
	var inn := {"guests": guests, "location": "wandering_inn"}
	var plan: Array = [
		["cook_stew", {"context": inn}],
		["serve_guests", {"context": inn}],
		["clean_room", {"context": inn}],
		["sweep_floor", {}],
		["wash_dishes", {}],
		["talk_with_guest", {"context": inn}],
		["carry_water", {}],
	]
	if day % 2 == 0:
		plan.append(["bake_bread", {}])
		plan.append(["buy_supplies", {"context": {"location": "market"}}])
		plan.append(["haggle", {}])
	else:
		plan.append(["cook_pasta", {"context": inn}])
		plan.append(["chop_wood", {}])
	if day % 3 == 0:
		plan.append(["play_chess", {"context": {"opponent_skill": 3}}])
		plan.append(["play_chess", {"context": {"opponent_skill": 5}}])
		plan.append(["teach_chess", {}])
	if day % 4 == 1:
		plan.append(["forage_fruit", {}])
	if day % 6 == 5:
		plan.append(["attack_melee", {"risk": 0.8, "outcome": "partial"}])
		plan.append(["block_attack", {"risk": 0.8}])
		plan.append(["flee_danger", {}])
		plan.append(["bandage_wound", {}])
	for step: Array in plan:
		Commands.perform(gs, _db, step[0], step[1])


## Plays `from_day`..`to_day` and answers offers the next morning.
## Returns a trace of everything the System did.
func _run(gs: GameState, from_day: int, to_day: int) -> Array[String]:
	var trace: Array[String] = []
	for day in range(from_day, to_day + 1):
		_play_day(gs, day)
		var night := Commands.sleep(gs, _db)
		for line: String in night["lines"]:
			trace.append("d%d %s" % [day, line])
		for id: String in night["offers"]:
			var answer := Commands.accept_class(gs, _db, id) if ACCEPT.has(id) \
					else Commands.decline_class(gs, _db, id)
			for line: String in answer:
				trace.append("d%d %s" % [day, line])
	return trace


func _levels(gs: GameState) -> Dictionary:
	var out := {}
	for id: String in gs.progression.classes:
		out[id] = gs.progression.level_of(id)
	return out


func test_30_days_are_deterministic() -> void:
	var a := GameState.new_game(SEED, _db)
	var trace_a := _run(a, 1, DAYS)
	var b := GameState.new_game(SEED, _db)
	var trace_b := _run(b, 1, DAYS)
	gut.p("\n".join(trace_a))
	gut.p("levels: %s  skills: %d  declined: %s" % [_levels(a), a.progression.skills.size(), a.progression.declined])
	assert_eq(trace_a, trace_b)
	assert_eq(a.to_json(), b.to_json())
	assert_eq(a.clock.day(), GameState.new_game(SEED, _db).clock.day() + DAYS)


func test_30_days_reach_a_class_levels_and_skills() -> void:
	var gs := GameState.new_game(SEED, _db)
	_run(gs, 1, DAYS)
	var p := gs.progression
	assert_true(p.has_class("innkeeper"), "the inn life gives [Innkeeper]")
	assert_gte(p.level_of("innkeeper"), 3)
	assert_gte(p.skills.size(), 3)
	assert_false(p.declined.is_empty(), "the script declines something")
	for id: String in p.declined:
		assert_false(p.has_class(id))


func test_save_and_load_mid_run_changes_nothing() -> void:
	var straight := GameState.new_game(SEED, _db)
	var trace_straight := _run(straight, 1, DAYS)

	var gs := GameState.new_game(SEED, _db)
	var trace := _run(gs, 1, 15)
	var loaded := GameState.from_json(gs.to_json())
	trace.append_array(_run(loaded, 16, DAYS))
	assert_eq(trace, trace_straight)
	assert_eq(loaded.to_json(), straight.to_json())


func test_other_seed_still_deterministic() -> void:
	var a := GameState.new_game(7, _db)
	var b := GameState.new_game(7, _db)
	assert_eq(_run(a, 1, 10), _run(b, 1, 10))
