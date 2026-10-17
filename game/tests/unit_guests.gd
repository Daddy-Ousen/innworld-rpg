extends GutTest
## Guests and serving (M14.2, ADR 0021): rules.inn, patrons at meal times,
## serving dishes for coin and reputation, canon guests, the night, and the
## v15 save. Real data.

const SEED := 20260929
const INN := "inn_interior"

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])


## A new game in the inn's common room, open, with `rep` reputation, just
## before `hour` on its first day.
func _game(rep: int = 80, hour: int = 7) -> GameState:
	var gs := GameState.new_game(SEED, _db)
	gs.flags["wandering_inn.open"] = true
	gs.flags["wandering_inn.has_regulars"] = true
	gs.flags.erase("wandering_inn.destroyed")
	gs.inn.reputation = rep
	gs.player.place(INN, Vector2i(12, 11))
	_to_hour(gs, hour)
	return gs


## Moves the clock (not backwards) to `hour` today and runs the command bookkeeping.
func _to_hour(gs: GameState, hour: int) -> void:
	var to := gs.clock.total_minutes - gs.clock.minute() + hour * 60
	if to > gs.clock.total_minutes:
		gs.clock.advance(to - gs.clock.total_minutes)
	Commands.settle(gs, _db)


func _wait_minutes(gs: GameState, minutes: int) -> void:
	gs.clock.advance(minutes)
	Commands.settle(gs, _db)


## Waits until every patron has come in.
func _all_arrived(gs: GameState) -> void:
	var last := 0
	for g in gs.inn.guests:
		last = maxi(last, int(g["arrive"]))
	if last > gs.clock.total_minutes:
		_wait_minutes(gs, last - gs.clock.total_minutes)


## Puts the player on a free tile next to patron `g`'s seat.
func _stand_by(gs: GameState, g: Dictionary) -> void:
	var seat := Vector2i(int(g["seat"][0]), int(g["seat"][1]))
	for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
			Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]:
		var at := seat + d
		if _db.maps.is_walkable(INN, at) and Guests.at(gs, INN, at) == "" and gs.npcs.at(INN, at) == "":
			gs.player.place(INN, at)
			return
	fail_test("no free tile next to %s" % g["id"])


func _lines(gs: GameState) -> String:
	return "\n".join(gs.combat.lines)


func test_the_inn_has_seats_and_patron_looks() -> void:
	assert_eq(Guests._seats(_db, INN).size(), 12)
	for race: String in Guests.rules(_db)["patron_races"]:
		assert_true(CharacterSprite.has_sheet("race_" + race), race)


func test_a_bad_inn_rule_is_an_error() -> void:
	var good: Dictionary = _db.rules["inn"]
	var bad := good.duplicate(true)
	bad["dishes"] = ["gold"]
	bad["meals"] = [{"name": "late", "hours": [23, 2]}]
	bad["patience_minutes"] = [0, 5]
	_db.rules["inn"] = bad
	var errs := Guests.validate(_db)
	_db.rules["inn"] = good
	assert_eq(errs.size(), 3, str(errs))
	_db.rules["inn"] = {"area": INN}
	errs = Guests.validate(_db)
	_db.rules["inn"] = good
	assert_true(errs.any(func(e: String) -> bool: return e.contains("missing")))


func test_a_seat_off_the_table_is_a_map_error() -> void:
	var m: Dictionary = _db.maps.areas[INN]
	var obj: Dictionary = m["objects"][4]
	var before: Array = obj["seats"]
	obj["seats"] = [[1, 1]]
	var errs := _db.maps.validate(_db)
	obj["seats"] = before
	assert_true(errs.any(func(e: String) -> bool: return e.contains("must be next to the object")), str(errs))


func test_patrons_come_at_meal_time() -> void:
	var gs := _game()
	var n := gs.inn.guests.size()
	assert_between(n, 3, 8, "reputation 80: 3-6 patrons, + canon flag bonus")
	assert_eq(gs.inn.guests_today, n)
	assert_string_contains(_lines(gs), "breakfast time")
	var seats := {}
	for g in gs.inn.guests:
		assert_true(Guests._seats(_db, INN).has(Vector2i(int(g["seat"][0]), int(g["seat"][1]))))
		seats[str(g["seat"])] = true
		assert_has(Guests.rules(_db)["dishes"], g["order"])
		assert_true(int(g["until"]) > int(g["arrive"]))
		assert_eq(int(g["paid"]), 0)
	assert_eq(seats.size(), n, "one patron per seat")
	var before := gs.inn.guests.duplicate(true)
	_wait_minutes(gs, 10)
	assert_eq(gs.inn.guests_today, n, "one roll per meal")
	assert_eq(gs.inn.guests.size(), before.size())


## A copy of rules.inn with a boycott list; the caller puts the real rules back.
func _with_boycott(list: Array) -> Dictionary:
	var good: Dictionary = _db.rules["inn"]
	var rules := good.duplicate(true)
	rules["race_boycott"] = list
	_db.rules["inn"] = rules
	return good


func _races(gs: GameState) -> Dictionary:
	var out := {}
	for g in gs.inn.guests:
		out[g["race"]] = int(out.get(g["race"], 0)) + 1
	return out


func test_a_boycott_keeps_one_race_away_while_its_flag_is_set() -> void:
	var good := _with_boycott([{"flag": "wandering_inn.test_boycott", "race": "drake", "factor": 0.0}])
	var shut := _game()
	shut.flags.erase("wandering_inn.test_boycott")
	var open_races := _races(shut)
	var seen := 0
	for s in [1, 2, 3, 4, 5, 6]:
		var gs := GameState.new_game(SEED + s, _db)
		gs.flags["wandering_inn.open"] = true
		gs.flags["wandering_inn.has_regulars"] = true
		gs.flags["wandering_inn.test_boycott"] = true
		gs.inn.reputation = 80
		gs.player.place(INN, Vector2i(12, 11))
		_to_hour(gs, 7)
		seen += gs.inn.guests.size()
		assert_false(_races(gs).has("drake"), "no Drake patrons while boycotted (seed %d)" % s)
	_db.rules["inn"] = good
	assert_gt(seen, 0, "other races still come")
	assert_true(open_races.size() > 0)


func test_a_boycott_factor_thins_a_race_but_does_not_end_it() -> void:
	var good: Dictionary = _db.rules["inn"]
	var rules := good.duplicate(true)
	rules["patron_races"] = {"drake": 10, "gnoll": 10}
	rules["race_boycott"] = [{"flag": "wandering_inn.test_boycott", "race": "drake", "factor": 0.1}]
	_db.rules["inn"] = rules
	var drakes := 0
	var gnolls := 0
	for s in range(1, 13):
		var gs := GameState.new_game(SEED + s, _db)
		gs.flags["wandering_inn.open"] = true
		gs.flags["wandering_inn.has_regulars"] = true
		gs.flags["wandering_inn.test_boycott"] = true
		gs.inn.reputation = 80
		gs.player.place(INN, Vector2i(12, 11))
		_to_hour(gs, 7)
		var r := _races(gs)
		drakes += int(r.get("drake", 0))
		gnolls += int(r.get("gnoll", 0))
	_db.rules["inn"] = good
	assert_gt(gnolls, drakes * 3, "Drakes are rare, not gone")


func test_with_every_race_boycotted_nobody_comes() -> void:
	var good: Dictionary = _db.rules["inn"]
	var rules := good.duplicate(true)
	rules["patron_races"] = {"drake": 1}
	rules["race_boycott"] = [{"flag": "wandering_inn.test_boycott", "race": "drake", "factor": 0.0}]
	_db.rules["inn"] = rules
	var gs := GameState.new_game(SEED, _db)
	gs.flags["wandering_inn.open"] = true
	gs.flags["wandering_inn.has_regulars"] = true
	gs.flags["wandering_inn.test_boycott"] = true
	gs.inn.reputation = 80
	gs.player.place(INN, Vector2i(12, 11))
	_to_hour(gs, 7)
	_db.rules["inn"] = good
	assert_eq(gs.inn.guests.size(), 0)


func test_a_bad_boycott_is_an_error_and_none_is_fine() -> void:
	assert_eq(Guests.validate(_db), [] as Array[String], "the real rules have no boycott list")
	var good: Dictionary = _with_boycott([{"flag": "x", "race": "elf", "factor": 0.5},
			{"flag": "", "race": "drake", "factor": 0.5}, {"flag": "x", "race": "drake", "factor": 1.5}])
	var errs := Guests.validate(_db)
	_db.rules["inn"] = good
	assert_eq(errs.size(), 3, str(errs))


func test_the_same_seed_brings_the_same_patrons() -> void:
	assert_eq(_game().inn.to_dict(), _game().inn.to_dict())


func test_rolling_patrons_leaves_the_game_rng_alone() -> void:
	var gs := _game(80, 6)
	gs.clock.advance(60)
	var rng := gs.rng.to_dict()
	Guests.sync(gs, _db)
	assert_false(gs.inn.guests.is_empty())
	assert_eq(gs.rng.to_dict(), rng)


func test_no_patrons_when_closed_away_or_between_meals() -> void:
	var gs := _game(80, 6)
	gs.flags.erase("wandering_inn.open")
	_to_hour(gs, 7)
	assert_eq(gs.inn.guests.size(), 0, "not open yet")
	gs = _game(80, 6)
	gs.flags["wandering_inn.destroyed"] = true
	_to_hour(gs, 7)
	assert_eq(gs.inn.guests.size(), 0, "blown up")
	gs.flags["wandering_inn.rebuilt"] = true
	_to_hour(gs, 12)
	assert_gt(gs.inn.guests.size(), 0, "rebuilt")
	gs = _game(80, 6)
	gs.player.place("inn_hill", Vector2i(16, 12))
	_to_hour(gs, 7)
	assert_eq(gs.inn.guests.size(), 0, "the player is outside")
	gs = _game(80, 10)
	assert_eq(gs.inn.guests.size(), 0, "between breakfast and lunch")


func test_serving_the_order_pays_and_raises_reputation() -> void:
	var gs := _game()
	_all_arrived(gs)
	var g: Dictionary = gs.inn.guests[0]
	_stand_by(gs, g)
	Commands.give(gs, _db, 0, g["order"], 1)
	var gid := Guests.GUEST + String(g["id"])
	var opt: Array = Interact.options(gs, _db).filter(func(o: Dictionary) -> bool: return o["id"] == gid)
	assert_eq(opt.size(), 1)
	assert_true(opt[0]["serve"][0]["ordered"])
	var price := roundi(int(_db.economy.goods[g["order"]]["sell"]) * 2.0)
	var coins := gs.economy.coins
	var r := Commands.serve(gs, _db, gid, g["order"])
	assert_eq(r["error"], "")
	assert_eq(r["record"]["action_id"], "serve_guests")
	assert_eq(gs.economy.coins, coins + price)
	assert_eq(gs.economy.count(g["order"]), 0)
	assert_eq(gs.inn.income_today, price)
	assert_eq(gs.inn.served_total, 1)
	assert_eq(Guests.reputation(gs, _db), 81)
	assert_string_contains(_lines(gs), "You serve")
	assert_eq(int(gs.inn.guest(g["id"])["paid"]), price)
	assert_eq(Commands.serve(gs, _db, gid, g["order"])["error"], "There is no guest waiting for food there.")
	for other in gs.inn.guests:
		if other["id"] != g["id"]:
			other["until"] = gs.clock.total_minutes + 1000  # the others wait on
	_wait_minutes(gs, 31)
	assert_true(gs.inn.guest(g["id"]).is_empty(), "ate and left")
	assert_eq(Guests.reputation(gs, _db), 81, "a fed patron leaves happy")


func test_another_dish_pays_less() -> void:
	var gs := _game()
	_all_arrived(gs)
	var g: Dictionary = gs.inn.guests[0]
	_stand_by(gs, g)
	var other := "stew" if g["order"] != "stew" else "pasta_dish"
	Commands.give(gs, _db, 0, other, 1)
	var coins := gs.economy.coins
	assert_eq(Commands.serve(gs, _db, Guests.GUEST + String(g["id"]), other)["error"], "")
	assert_eq(gs.economy.coins, coins + roundi(int(_db.economy.goods[other]["sell"]) * 2.0 * 0.5))


func test_serving_needs_the_dish_and_a_guest_next_to_you() -> void:
	var gs := _game()
	_all_arrived(gs)
	var g: Dictionary = gs.inn.guests[0]
	var gid := Guests.GUEST + String(g["id"])
	_stand_by(gs, g)
	assert_string_contains(Commands.serve(gs, _db, gid, g["order"])["error"], "You have no")
	Commands.give(gs, _db, 0, "flour", 1)
	assert_eq(Commands.serve(gs, _db, gid, "flour")["error"], "You cannot serve that.")
	gs.player.place(INN, Vector2i(20, 13))
	Commands.give(gs, _db, 0, g["order"], 1)
	assert_eq(Commands.serve(gs, _db, gid, g["order"])["error"], "There is no guest waiting for food there.")


func test_an_unserved_patron_leaves_and_the_inn_suffers() -> void:
	var gs := _game()
	var n := gs.inn.guests.size()
	_wait_minutes(gs, 200)
	assert_eq(gs.inn.guests.size(), 0)
	assert_eq(Guests.reputation(gs, _db), 80 - 2 * n)
	assert_string_contains(_lines(gs), "gives up waiting")


func test_patrons_who_give_up_while_you_are_away_cost_nothing() -> void:
	var gs := _game()
	gs.player.place("inn_hill", Vector2i(16, 12))
	_wait_minutes(gs, 200)
	assert_eq(gs.inn.guests.size(), 0)
	assert_eq(Guests.reputation(gs, _db), 80)


func test_a_seated_patron_blocks_a_step() -> void:
	var gs := _game()
	_all_arrived(gs)
	var g: Dictionary = gs.inn.guests[0]
	var seat := Vector2i(int(g["seat"][0]), int(g["seat"][1]))
	for dir: String in PlayerState.DIRS:
		var from: Vector2i = seat - PlayerState.DIRS[dir]
		if _db.maps.is_walkable(INN, from) and gs.npcs.at(INN, from) == "" and Guests.at(gs, INN, from) == "":
			gs.player.place(INN, from)
			var r := Commands.move(gs, _db, dir)
			assert_true(r["blocked"])
			assert_eq(gs.player.pos(), from)
			return
	fail_test("no tile next to the seat")


func test_a_fight_sends_the_patrons_away() -> void:
	var gs := _game()
	_all_arrived(gs)
	gs.player.place(INN, Vector2i(12, 11))
	var s := Commands.spawn_monster(gs, _db, "goblin_grunt", Vector2i(12, 10))
	assert_eq(s["error"], "")
	Commands.attack(gs, _db, "n")
	assert_true(Combat.in_danger(gs) or not gs.combat.monsters.has(s["id"]))
	assert_eq(gs.inn.guests.size(), 0)
	assert_string_contains(_lines(gs), "flee")
	assert_eq(Guests.reputation(gs, _db), 80)


func test_a_canon_guest_is_served_once_per_meal() -> void:
	var gs := _game(80, 19)
	var npc := "relc"
	gs.npcs.npcs[npc]["area"] = INN
	gs.npcs.npcs[npc]["x"] = 12
	gs.npcs.npcs[npc]["y"] = 10
	gs.npcs.npcs[npc]["goal"] = "visit_inn"
	assert_has(Guests.npc_guests(gs, _db), npc)
	Commands.give(gs, _db, 0, "stew", 2)
	var choices := Guests.serve_choices(gs, _db, npc)
	assert_eq(choices.size(), 1)
	assert_eq(int(choices[0]["pay"]), 16, "a canon guest pays full for any dish")
	var rel := gs.world.relationship(npc, NpcSim.PLAYER)
	var r := Guests.serve(gs, _db, npc, "stew")
	assert_eq(r["error"], "")
	assert_eq(gs.world.relationship(npc, NpcSim.PLAYER), rel + 1)
	assert_true((r["record"]["witnesses"] as Array).has(npc))
	assert_eq(Guests.serve(gs, _db, npc, "stew")["error"], "There is no guest waiting for food there.")
	gs.npcs.npcs[npc]["goal"] = "patrol"
	assert_false(Guests.npc_guests(gs, _db).has(npc))


func test_the_cook_context_counts_the_guests() -> void:
	var gs := _game()
	gs.player.place(INN, Vector2i(20, 2))
	var r := Commands.interact(gs, _db, "stove", "cook_simple_meal")
	assert_eq(r["error"], "")
	assert_eq(int(r["record"]["context"]["guests"]), Guests.count(gs, _db))
	assert_gt(int(r["record"]["context"]["guests"]), 0)


func test_the_night_reports_the_takings_and_empties_the_room() -> void:
	var gs := _game()
	_all_arrived(gs)
	var g: Dictionary = gs.inn.guests[0]
	_stand_by(gs, g)
	Commands.give(gs, _db, 0, g["order"], 1)
	Commands.serve(gs, _db, Guests.GUEST + String(g["id"]), g["order"])
	var lines := Guests.night(gs, _db)
	assert_eq(lines.size(), 1)
	assert_string_contains(lines[0], "The inn took in")
	assert_eq(gs.inn.guests.size(), 0)
	assert_eq(gs.inn.income_today, 0)
	assert_eq(gs.inn.guests_today, 0)
	assert_eq(gs.inn.served_total, 1)


func test_the_inn_is_saved_and_a_v14_save_loads() -> void:
	var gs := _game()
	var back := GameState.from_json(gs.to_json())
	assert_eq(back.inn.to_dict(), gs.inn.to_dict())
	var data := gs.to_dict()
	data.erase("inn")
	data["save_version"] = 14
	var old := GameState.from_dict(SaveMigrations.migrate(data))
	assert_eq(old.save_version, GameState.SAVE_VERSION)
	assert_eq(old.inn.guests.size(), 0)
	assert_eq(Guests.reputation(old, _db), 10)


func test_the_view_draws_patrons() -> void:
	var gs := _game()
	_all_arrived(gs)
	var v: WorldView = preload("res://world/world_view.tscn").instantiate()
	add_child_autofree(v)
	v.setup(_db.maps)
	v.refresh(gs)
	for g in gs.inn.guests:
		assert_not_null(v.npcs.get_node_or_null(NodePath("guest_" + String(g["id"]))), g["id"])


# --- M29.1: first guests (ADR 0044) -----------------------------------------

## A game at 7:00 on day 1 in the open inn, with `flags` set (no has_regulars unless given).
func _game_with(flags: Array, seed_add: int = 0) -> GameState:
	var gs := GameState.new_game(SEED + seed_add, _db)
	gs.flags.erase("wandering_inn.destroyed")
	gs.flags["wandering_inn.open"] = true
	for f: String in flags:
		gs.flags[f] = true
	gs.inn.reputation = 80
	gs.player.place(INN, Vector2i(12, 11))
	_to_hour(gs, 7)
	return gs


func test_no_patrons_before_the_inn_has_regulars() -> void:
	assert_false(Guests.patrons_come(_game_with([]), _db))
	for s in [0, 1, 2, 3]:
		assert_eq(_game_with([], s).inn.guests.size(), 0, "day-5 inn: nobody comes (seed %d)" % s)
	assert_gt(_game_with(["wandering_inn.has_regulars"]).inn.guests.size(), 0, "regulars: patrons come")
	assert_gt(_game_with(["wandering_inn.full_house"]).inn.guests.size(), 0, "any listed flag will do")


func test_goblin_patrons_only_once_goblins_pay() -> void:
	var seen_without := 0
	var seen_with := 0
	for s in range(0, 12):
		seen_without += int(_races(_game_with(["wandering_inn.has_regulars"], s)).get("goblin", 0))
		seen_with += int(_races(_game_with(["wandering_inn.has_regulars", "goblin_tribe.paying_guests"], s)).get("goblin", 0))
	assert_eq(seen_without, 0, "no Goblin patrons before Rags pays (1.25)")
	assert_gt(seen_with, 0, "Goblin patrons after")


func test_bad_patron_and_race_flags_are_errors() -> void:
	var good: Dictionary = _db.rules["inn"]
	var bad := good.duplicate(true)
	bad["patron_flags"] = [""]
	bad["race_flags"] = {"elf": "x", "drake": ""}
	_db.rules["inn"] = bad
	var errs := Guests.validate(_db)
	_db.rules["inn"] = good
	assert_eq(errs.size(), 3, str(errs))


func test_v21_save_after_the_regulars_event_gets_the_flag() -> void:
	var ran := {"save_version": 21, "flags": {"wandering_inn.open": true},
		"world": {"history": [{"day": 15, "event": "b1.inn_first_regulars", "outcome": "done", "roles": {}}]}}
	var out := SaveMigrations.migrate(ran)
	assert_eq(int(out["save_version"]), GameState.SAVE_VERSION)
	assert_true(out["flags"].has("wandering_inn.has_regulars"), "the event ran: regulars")
	var early := {"save_version": 21, "flags": {}, "world": {"history": [
		{"day": 15, "event": "b1.inn_first_regulars", "outcome": "cancelled", "roles": {}}]}}
	assert_false(SaveMigrations.migrate(early)["flags"].has("wandering_inn.has_regulars"), "cancelled: none")
	assert_false(SaveMigrations.migrate({"save_version": 21, "flags": {}, "world": {"history": []}})["flags"]
			.has("wandering_inn.has_regulars"), "before day 15: none")
