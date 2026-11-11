extends GutTest
## Audit D2 (ADR 0051): Commands.rest passes time in chunks of Rest.CHUNK minutes and stops early
## when the player is needed. Pure time: no XP, no action record, no heal. Also the next-meal
## helper, the Rest panel rows and Rest.sleep_plan (the sleep question, audit D1).

const SEED := 20261111

var _real: DataDb
var _toy: DataDb


func before_all() -> void:
	_real = DataDb.load_dir()
	assert_eq(_real.errors, [] as Array[String])


func before_each() -> void:
	_toy = ToyCombat.db()
	_toy.combat.enemies["goblin"]["ranged"]["chance"] = 0.0


func _arena(pos: Vector2i = Vector2i(1, 4)) -> GameState:
	var gs := ToyCombat.new_game(_toy, SEED)
	ToyCombat.to_arena(gs, _toy, pos)
	return gs


## A real-db game at `hour` of day 4, standing in `area`.
func _real_game(area: String, pos: Vector2i, hour: float, start: String = "celum") -> GameState:
	var gs := GameState.new_game(SEED, _real, start)
	gs.player.place(area, pos)
	Commands.settle(gs, _real)
	gs.clock.total_minutes = int(hour * 60.0) + Clock.MINUTES_PER_DAY * 3
	gs.clock.awake_minutes = 0
	return gs


func test_it_rests_the_asked_time_when_nothing_happens() -> void:
	var gs := _arena()
	var before := gs.clock.total_minutes
	var r := Commands.rest(gs, _toy, 60)
	assert_eq(r["error"], "")
	assert_eq(r["stop"], "")
	assert_eq(r["minutes"], 60)
	assert_eq(gs.clock.total_minutes, before + 60)
	assert_eq(gs.combat.lines[0], "You rest for 1 hour.")


func test_an_odd_time_ends_on_the_minute() -> void:
	var gs := _arena()
	var before := gs.clock.total_minutes
	var r := Commands.rest(gs, _toy, 25)
	assert_eq(r["minutes"], 25, "two chunks of 10 and one of 5")
	assert_eq(gs.clock.total_minutes, before + 25)
	assert_eq(gs.combat.lines[0], "You rest for 25 min.")


func test_it_is_pure_time_no_action_record_no_xp_no_heal() -> void:
	var gs := _arena()
	gs.player.hp = 3
	var records := gs.action_log.records.size()
	var progress := gs.progression.to_dict().duplicate(true)
	Commands.rest(gs, _toy, 120)
	assert_eq(gs.action_log.records.size(), records, "no action record")
	assert_eq(gs.player.hp, 3, "no heal")
	assert_eq(gs.progression.to_dict(), progress, "no XP")


func test_a_hostile_near_refuses_the_rest() -> void:
	var gs := _arena()
	Combat.add_monster(gs, _toy, "goblin", Vector2i(6, 4), CombatState.HOSTILE)
	var before := gs.clock.total_minutes
	var r := Commands.rest(gs, _toy, 60)
	assert_eq(r["error"], Combat.REFUSED_DANGER)
	assert_eq(r["minutes"], 0)
	assert_eq(gs.clock.total_minutes, before)
	assert_has(gs.combat.lines, Combat.REFUSED_DANGER)


func test_a_staged_fight_that_starts_stops_the_rest() -> void:
	# ToyNpcs: the event e.ambush stages a goblin in the field at 06:00 - 12:00 (day 1 - 2).
	var db := ToyNpcs.combat_db({"e.ambush": ToyCanon.event(1, 2, {
		"requires": ToyCanon.req(["farmer"]),
		"stage": {"area": "field", "hours": [6, 12], "foes": [{"enemy": "goblin", "pos": [3, 2]}],
			"allies": ["farmer"], "line": "A goblin jumps out of the grass."},
		"effects": {"set_flags": ["field.ambushed"]}})})
	ToyCombat.freeze(db)
	var gs := ToyNpcs.new_game(db)
	gs.player.place("field", Vector2i(0, 0))
	gs.clock.total_minutes = 5 * 60
	Commands.settle(gs, db)
	assert_false(Combat.in_danger(gs), "calm at 05:00")
	var r := Commands.rest(gs, db, 180)
	assert_eq(r["stop"], "danger")
	assert_lt(int(r["minutes"]), 180, "it stopped early")
	assert_true(Combat.in_danger(gs))
	assert_has(gs.combat.lines, "Something comes near.")
	assert_has(gs.combat.lines, "A goblin jumps out of the grass.")


func test_a_collapse_due_stops_the_rest() -> void:
	var gs := _arena()
	var rules: Dictionary = _toy.rules["clock"]
	gs.clock.awake_minutes = int(rules["collapse_after_awake"]) - 25
	var r := Commands.rest(gs, _toy, 120)
	assert_eq(r["stop"], "tired")
	assert_eq(r["minutes"], 25)
	assert_true(gs.clock.is_collapse_due(rules))
	assert_has(gs.combat.lines, "You are too tired to rest on.")
	# Already due: nothing moves, the stop is still "tired".
	var again := Commands.rest(gs, _toy, 60)
	assert_eq(again["minutes"], 0)
	assert_eq(again["stop"], "tired")


func test_the_winter_cold_stops_the_rest() -> void:
	var gs := _real_game("celum_gate", Vector2i(16, 8), 12.0)
	gs.flags["izril.winter"] = true
	var hp := gs.player.hp
	var r := Commands.rest(gs, _real, 600)
	assert_lt(int(r["minutes"]), 600, "it stopped early")
	if gs.player.hp < hp:
		assert_eq(r["stop"], "hurt")
		assert_has(gs.combat.lines, "You are hurt.")
	else:
		assert_eq(r["stop"], "event", "the cold only warned: the world's line stops the rest")


func test_the_same_seed_and_commands_give_the_same_state() -> void:
	var a := _real_game("celum_gate", Vector2i(16, 8), 9.0)
	var b := _real_game("celum_gate", Vector2i(16, 8), 9.0)
	for gs in [a, b]:
		Commands.rest(gs, _real, 180)
		Commands.rest(gs, _real, 40)
	assert_eq(a.to_dict(), b.to_dict())


# --- next meal and the panel rows ---------------------------------------------

func _meal_at(hour: float) -> Dictionary:
	var gs := _real_game("celum_gate", Vector2i(16, 8), hour)
	return Rest.next_meal(gs, _real)


func test_next_meal_before_breakfast() -> void:
	var m := _meal_at(6.0)
	assert_eq(m["name"], "breakfast")
	assert_eq(m["minutes"], 60)
	assert_eq(m["hour"], "07:00")


func test_next_meal_at_eleven_is_lunch() -> void:
	var m := _meal_at(11.0)
	assert_eq(m["name"], "lunch")
	assert_eq(m["minutes"], 60)


func test_next_meal_at_three_is_dinner() -> void:
	var m := _meal_at(15.0)
	assert_eq(m["name"], "dinner")
	assert_eq(m["minutes"], 180)
	assert_eq(m["hour"], "18:00")


func test_next_meal_at_night_is_tomorrows_breakfast() -> void:
	var m := _meal_at(23.0)
	assert_eq(m["name"], "breakfast")
	assert_eq(m["minutes"], 480)


func test_the_hour_a_meal_starts_the_next_start_is_the_following_meal() -> void:
	var m := _meal_at(7.0)
	assert_eq(m["name"], "lunch", "breakfast has begun; the next start is lunch")
	assert_eq(m["minutes"], 300)


func test_a_db_without_inn_rules_has_no_meal_option() -> void:
	var gs := _arena()
	_toy.rules.erase("inn")
	assert_eq(Rest.next_meal(gs, _toy), {})
	var rows := Rest.options(gs, _toy)
	assert_eq(rows.size(), 2, "1 hour and 3 hours only")
	assert_eq(rows[0]["text"], "Rest 1 hour")
	assert_eq(rows[1]["text"], "Rest 3 hours")
	assert_eq(rows[1]["minutes"], 180)


func test_the_panel_rows_with_a_meal() -> void:
	var gs := _real_game("celum_gate", Vector2i(16, 8), 15.0)
	var rows := Rest.options(gs, _real)
	assert_eq(rows.size(), 3)
	assert_eq(rows[2]["text"], "Rest until 18:00 (dinner)")
	assert_eq(rows[2]["minutes"], 180)


# --- the sleep question ----------------------------------------------------------

func test_sleep_plan_asks_with_the_wake_time_and_hours() -> void:
	var gs := _real_game("celum_gate", Vector2i(16, 8), 21.0)
	var plan := Rest.sleep_plan(gs, _real, Rest.ANYWHERE)
	assert_eq(plan["mode"], Rest.ASK)
	assert_eq(plan["title"], "Sleep until 06:00?")
	assert_eq(plan["sub"], "9 h")


func test_sleep_plan_at_eight_says_22_hours() -> void:
	var gs := _real_game("celum_gate", Vector2i(16, 8), 8.0)
	var plan := Rest.sleep_plan(gs, _real, Rest.ANYWHERE)
	assert_eq(plan["mode"], Rest.ASK)
	assert_eq(plan["sub"], "22 h")


func test_sleep_plan_outdoors_is_refused_and_changes_nothing() -> void:
	var gs := _real_game("celum_gate", Vector2i(16, 8), 21.0)
	var before := gs.to_dict()
	assert_eq(Rest.sleep_plan(gs, _real)["mode"], Rest.REFUSED)
	assert_eq(gs.to_dict(), before)


func test_sleep_plan_collapse_is_now() -> void:
	var gs := _real_game("celum_gate", Vector2i(16, 8), 21.0)
	gs.clock.awake_minutes = int(_real.rules["clock"]["collapse_after_awake"])
	assert_eq(Rest.sleep_plan(gs, _real)["mode"], Rest.NOW)


func test_sleep_plan_danger_is_refused() -> void:
	var gs := _arena()
	Combat.add_monster(gs, _toy, "goblin", Vector2i(6, 4), CombatState.HOSTILE)
	assert_eq(Rest.sleep_plan(gs, _toy)["mode"], Rest.REFUSED)
