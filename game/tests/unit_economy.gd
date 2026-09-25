extends GutTest
## The economy (M8.6, ADR 0015) on the real data: coins, trade, haggling,
## yields, jobs, goods (food, potion, clothes, a meal), hunger and Erin's
## meals, and the save (v11).

const SEED := 20260925

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])


## A Celum game, the player next to `object_id` in `area`.
func _game_at(area: String, object_id: String, start: String = "celum") -> GameState:
	var gs := GameState.new_game(SEED, _db, start)
	_place_next_to(gs, area, object_id)
	return gs


func _place_next_to(gs: GameState, area: String, object_id: String) -> void:
	var at := Interact.object_of(_db, area, object_id)
	assert_false(at.is_empty(), "object %s in %s" % [object_id, area])
	var pos := Vector2i(int(at["at"][0]), int(at["at"][1]))
	for d: Vector2i in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
		if _db.maps.is_walkable(area, pos + d) and gs.npcs.at(area, pos + d) == "":
			gs.player.place(area, pos + d)
			Commands.settle(gs, _db)
			return
	fail_test("no free tile next to %s" % object_id)


func test_format_shows_silver_and_copper() -> void:
	assert_eq(Economy.format(_db, 0), "0c")
	assert_eq(Economy.format(_db, 4), "4c")
	assert_eq(Economy.format(_db, 10), "1s")
	assert_eq(Economy.format(_db, 14), "1s 4c")


func test_a_new_game_has_no_coins_and_is_fed_on_day_one() -> void:
	var gs := GameState.new_game(SEED, _db, "celum")
	assert_eq(gs.economy.coins, 0)
	assert_true(gs.economy.bag.is_empty())
	assert_true(Economy.is_fed(gs))
	assert_eq(gs.economy.hunger, 0)


func test_buy_needs_coins_then_puts_the_good_in_the_bag() -> void:
	var gs := _game_at("celum_square", "celum_stall")
	var r := Commands.buy(gs, _db, "celum_stall", "bread")
	assert_string_contains(r["error"], "cannot afford")
	Commands.give(gs, _db, 5)
	var before := gs.clock.total_minutes
	r = Commands.buy(gs, _db, "celum_stall", "bread")
	assert_eq(r["error"], "")
	assert_eq(r["record"]["action_id"], "buy_supplies")
	assert_eq(r["record"]["context"]["good"], "bread")
	assert_eq(gs.economy.coins, 2)
	assert_eq(gs.economy.count("bread"), 1)
	assert_eq(gs.clock.total_minutes - before, 5, "a trade takes trade_minutes")


func test_a_shop_only_trades_its_goods() -> void:
	var gs := _game_at("celum_square", "stitchworks_door")
	Commands.give(gs, _db, 100, "bread", 1)
	assert_string_contains(Commands.buy(gs, _db, "stitchworks_door", "bread")["error"], "does not sell")
	assert_string_contains(Commands.sell(gs, _db, "stitchworks_door", "bread")["error"], "does not buy")
	assert_string_contains(Commands.sell(gs, _db, "stitchworks_door", "herbs")["error"], "none to sell")
	Commands.give(gs, _db, 0, "herbs", 2)
	assert_eq(Commands.sell(gs, _db, "stitchworks_door", "herbs")["error"], "")
	assert_eq(gs.economy.coins, 103)
	assert_eq(gs.economy.count("herbs"), 1)


func test_trades_list_buys_and_only_goods_in_the_bag_to_sell() -> void:
	var gs := _game_at("celum_square", "celum_stall")
	var obj := Interact.object_of(_db, "celum_square", "celum_stall")
	var kinds := Economy.trades(gs, _db, obj).map(func(t: Dictionary) -> String: return t["kind"] + t["good"])
	assert_eq(kinds, ["buybread", "buyfirewood", "buywinter_clothes"])
	Commands.give(gs, _db, 0, "herbs", 1)
	kinds = Economy.trades(gs, _db, obj).map(func(t: Dictionary) -> String: return t["kind"] + t["good"])
	assert_has(kinds, "sellherbs")
	assert_eq(Economy.trades(gs, _db, Interact.object_of(_db, "celum_square", "celum_well")), [] as Array[Dictionary])


func test_haggling_gives_better_prices_there_for_the_day() -> void:
	var gs := _game_at("celum_square", "celum_stall")
	assert_eq(Economy.price(gs, _db, "celum_stall", "winter_clothes", Economy.BUY), 60)
	assert_eq(Commands.interact(gs, _db, "celum_stall", "haggle")["error"], "")
	assert_eq(Economy.price(gs, _db, "celum_stall", "winter_clothes", Economy.BUY), 54)
	assert_eq(Economy.price(gs, _db, "celum_stall", "herbs", Economy.SELL), 4)
	assert_eq(Economy.price(gs, _db, "krshia_stall", "winter_clothes", Economy.BUY), 60, "only that shop")
	gs.economy.haggled["celum_stall"] = gs.clock.day() - 1
	assert_eq(Economy.price(gs, _db, "celum_stall", "winter_clothes", Economy.BUY), 60, "only today")


func test_clothes_are_worn_and_a_meal_is_eaten_where_bought() -> void:
	var gs := _game_at("celum_square", "celum_stall")
	Commands.give(gs, _db, 100)
	assert_eq(Commands.buy(gs, _db, "celum_stall", "winter_clothes")["error"], "")
	assert_true(gs.flags.has("player.warm_clothes"))
	assert_eq(gs.economy.count("winter_clothes"), 0)
	_place_next_to(gs, "celum_square", "rats_tail_door")
	gs.economy.fed_day = -1
	assert_eq(Commands.buy(gs, _db, "rats_tail_door", "hot_meal")["error"], "")
	assert_true(Economy.is_fed(gs))
	assert_eq(gs.economy.count("hot_meal"), 0)
	assert_eq(gs.economy.coins, 35)


func test_foraging_puts_goods_in_the_bag() -> void:
	var gs := _game_at("floodplains_south", "blue_fruit_tree_1", "liscor")
	assert_eq(Commands.interact(gs, _db, "blue_fruit_tree_1", "forage_fruit")["error"], "")
	assert_eq(gs.economy.count("blue_fruit"), 2)
	_place_next_to(gs, "floodplains_south", "herb_patch")
	Commands.interact(gs, _db, "herb_patch", "gather_herbs")
	assert_eq(gs.economy.count("herbs"), 1)


func test_a_delivery_job_pays_within_its_range_the_same_for_the_same_seed() -> void:
	var pays: Array[int] = []
	for i in 2:
		var gs := _game_at("celum_runners_guild", "request_board")
		for j in 3:
			assert_eq(Commands.interact(gs, _db, "request_board", "deliver_parcel")["error"], "")
		pays.append(gs.economy.coins)
		assert_between(gs.economy.coins, 9, 18)
	assert_eq(pays[0], pays[1])


func test_eating_food_from_the_bag_feeds_you_and_ends_hunger() -> void:
	var gs := _game_at("celum_square", "celum_well")
	var full := Stats.max_hp(gs, _db)
	gs.economy.fed_day = -1
	gs.economy.hunger = 2
	assert_eq(Stats.max_hp(gs, _db), roundi(full * 0.8))
	assert_string_contains(Commands.use_good(gs, _db, "bread"), "no bread")
	Commands.give(gs, _db, 0, "bread", 1)
	assert_eq(Commands.use_good(gs, _db, "bread"), "")
	assert_true(Economy.is_fed(gs))
	assert_eq(gs.economy.hunger, 0)
	assert_eq(Stats.max_hp(gs, _db), full)
	assert_eq(gs.economy.count("bread"), 0)
	assert_eq(Commands.use_good(gs, _db, "herbs").is_empty(), false, "herbs are not eaten")


func test_a_potion_heals() -> void:
	var gs := _game_at("celum_square", "celum_well")
	Combat.set_hp(gs, _db, 5)
	Commands.give(gs, _db, 0, "healing_potion", 1)
	assert_eq(Commands.use_good(gs, _db, "healing_potion"), "")
	assert_eq(Combat.hp(gs, _db), 15)


func test_each_hungry_night_lowers_max_hp_down_to_the_floor() -> void:
	var gs := _game_at("celum_runners_guild", "guild_bench")
	var full := Stats.max_hp(gs, _db)
	for night in range(1, 8):
		Commands.wait(gs, _db, maxi(22 * 60 - gs.clock.minute(), 0) * 60)
		Commands.sleep(gs, _db)
		var want := 0 if night == 1 else night - 1  # day one is fed
		assert_eq(gs.economy.hunger, want, "night %d" % night)
	assert_eq(Stats.max_hp(gs, _db), roundi(full * 0.5), "never below the floor")
	assert_true(gs.morning.any(func(l: String) -> bool: return l.begins_with("You went to bed hungry")))


func test_a_nap_in_the_same_day_adds_no_hunger() -> void:
	var gs := _game_at("celum_runners_guild", "guild_bench")
	gs.economy.fed_day = -1
	var day := gs.clock.day()
	Commands.sleep(gs, _db)  # at 06:00: a nap, still the same day
	assert_eq(gs.clock.day(), day)
	assert_eq(gs.economy.hunger, 0)


func test_work_at_erins_inn_feeds_you_while_she_lives() -> void:
	var gs := _game_at("inn_interior", "broom", "liscor")
	gs.economy.fed_day = -1
	assert_eq(Commands.interact(gs, _db, "broom", "sweep_floor")["error"], "")
	Commands.wait(gs, _db, maxi(22 * 60 - gs.clock.minute(), 0) * 60)
	Commands.sleep(gs, _db)
	assert_eq(gs.economy.hunger, 0)
	assert_has(gs.morning, "You eat at the inn after your work.")
	gs.world.set_alive("erin_solstice", false)
	assert_eq(Commands.interact(gs, _db, "broom", "sweep_floor")["error"], "")
	Commands.wait(gs, _db, maxi(22 * 60 - gs.clock.minute(), 0) * 60)
	Commands.sleep(gs, _db)
	assert_eq(gs.economy.hunger, 1, "no Erin, no meal")


func test_the_economy_survives_save_and_load() -> void:
	var gs := _game_at("celum_square", "celum_stall")
	Commands.give(gs, _db, 23, "herbs", 2)
	Commands.interact(gs, _db, "celum_stall", "haggle")
	gs.economy.hunger = 1
	var copy := GameState.from_json(gs.to_json())
	assert_eq(copy.economy.to_dict(), gs.economy.to_dict())
	assert_eq(copy.to_json(), gs.to_json())


func test_a_v10_save_loads_with_an_empty_purse_and_fed() -> void:
	var d := _game_at("celum_square", "celum_stall").to_dict()
	d.erase("economy")
	d["save_version"] = 10
	var gs := GameState.from_dict(SaveMigrations.migrate(d))
	assert_eq(gs.save_version, GameState.SAVE_VERSION)
	assert_eq(gs.economy.coins, 0)
	assert_true(gs.economy.bag.is_empty())
	assert_true(Economy.is_fed(gs))
	assert_eq(gs.economy.hunger, 0)


func test_economy_data_errors_are_caught() -> void:
	var e := EconomyDb.from_dicts(
		{"a": {"name": "A", "confidence": "guess", "buy": 0, "sell": 1, "food": true, "heal": 2}},
		{"s": {"name": "S", "sells": ["a", "zz"], "buys": []}},
		{"no_such_action": {"a": 1}},
		{"haggle": {"pay": [5, 1]}})
	var errs := e.validate(_db)
	for want: String in ["at most one", "unknown good 'zz'", "no buy price", "unknown action 'no_such_action'",
			"pay must be"]:
		assert_true(errs.any(func(x: String) -> bool: return x.contains(want)), want)
