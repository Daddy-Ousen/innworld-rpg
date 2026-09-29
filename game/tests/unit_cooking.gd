extends GutTest
## Cooking (M14.1, ADR 0021): data/recipes.json, Cooking.after_action, the
## menu hint and the shops that sell ingredients. Real data.

const SEED := 20260929

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])


func _game_at(area: String, object_id: String) -> GameState:
	var gs := GameState.new_game(SEED, _db, "celum")
	_stand_next_to(gs, area, object_id)
	return gs


func _stand_next_to(gs: GameState, area: String, object_id: String) -> void:
	var at := Interact.object_of(_db, area, object_id)
	assert_false(at.is_empty(), "object %s in %s" % [object_id, area])
	var pos := Vector2i(int(at["at"][0]), int(at["at"][1]))
	for d: Vector2i in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
		if _db.maps.is_walkable(area, pos + d) and gs.npcs.at(area, pos + d) == "":
			gs.player.place(area, pos + d)
			Commands.settle(gs, _db)
			return
	fail_test("no free tile next to %s" % object_id)


func _lines(gs: GameState) -> String:
	return "\n".join(gs.combat.lines)


func test_recipes_load_and_name_known_things() -> void:
	assert_eq(_db.economy.recipes.size(), 4)
	for id: String in _db.economy.recipes:
		assert_true(_db.actions.has(_db.economy.recipes[id]["action"]), id)
	assert_eq(_db.economy.recipes_for("cook_stew"), ["stew"] as Array[String])
	assert_eq(_db.economy.recipes_for("sweep_floor"), [] as Array[String])


func test_every_station_kind_is_a_real_map_object_kind() -> void:
	var kinds := {}
	for area: String in _db.maps.areas:
		for o: Dictionary in _db.maps.objects_on(area):
			kinds[o.get("kind", "")] = true
	for id: String in _db.economy.recipes:
		for k: String in _db.economy.recipes[id]["stations"]:
			assert_true(kinds.has(k), "recipe %s station %s" % [id, k])


func test_a_bad_recipe_is_an_error() -> void:
	var goods := {"flour": {"name": "Flour", "confidence": "guess", "buy": 1, "sell": 0}}
	var bad := {
		"no_action": {"action": "nope", "inputs": {"flour": 1}, "outputs": {"flour": 1}, "stations": ["stove"], "confidence": "guess"},
		"no_good": {"action": "cook_stew", "inputs": {"gold": 1}, "outputs": {"flour": 1}, "stations": ["stove"], "confidence": "guess"},
		"zero": {"action": "cook_stew", "inputs": {"flour": 0}, "outputs": {"flour": 1}, "stations": ["stove"], "confidence": "guess"},
		"no_out": {"action": "cook_stew", "inputs": {"flour": 1}, "outputs": {}, "stations": ["stove"], "confidence": "guess"},
		"no_station": {"action": "cook_stew", "inputs": {"flour": 1}, "outputs": {"flour": 1}, "stations": [], "confidence": "guess"},
		"missing": {"action": "cook_stew"},
	}
	var e := EconomyDb.from_dicts(goods, {}, {}, {}, bad)
	e.validate(_db)
	for id: String in bad:
		assert_true(e.errors.any(func(x: String) -> bool: return x.begins_with("recipe '%s'" % id)), id)


func test_cooking_at_the_stove_turns_ingredients_into_dishes() -> void:
	var gs := _game_at("inn_interior", "stove")
	Commands.give(gs, _db, 0, "meat", 2)
	Commands.give(gs, _db, 0, "vegetables", 5)
	var r := Commands.interact(gs, _db, "stove", "cook_stew")
	assert_eq(r["error"], "")
	assert_eq(gs.economy.count("stew"), 3)
	assert_eq(gs.economy.count("meat"), 1)
	assert_eq(gs.economy.count("vegetables"), 3)
	assert_string_contains(_lines(gs), "You make 3 stew.")
	assert_true(float(r["record"]["xp"]) > 0.0, "still earns XP")


func test_one_cook_uses_one_batch_and_a_short_bag_is_practice() -> void:
	var gs := _game_at("inn_interior", "stove")
	Commands.give(gs, _db, 0, "flour", 3)
	Commands.interact(gs, _db, "stove", "bake_bread")
	assert_eq(gs.economy.count("bread"), 4)
	assert_eq(gs.economy.count("flour"), 1)
	var r := Commands.interact(gs, _db, "stove", "bake_bread")
	assert_eq(r["error"], "")
	assert_eq(gs.economy.count("bread"), 4, "no second batch")
	assert_eq(gs.economy.count("flour"), 1)
	assert_string_contains(_lines(gs), "only practice")
	assert_string_contains(_lines(gs), "2 flour")


func test_no_ingredients_is_practice_with_xp() -> void:
	var gs := _game_at("inn_interior", "stove")
	var r := Commands.interact(gs, _db, "stove", "cook_pasta")
	assert_eq(r["error"], "")
	assert_true(gs.economy.bag.is_empty())
	assert_true(float(r["record"]["xp"]) > 0.0)
	assert_string_contains(_lines(gs), "lack the ingredients")


func test_a_campfire_cooks_a_simple_meal_but_not_a_stew() -> void:
	var gs := _game_at("road_camp", "campfire")
	Commands.give(gs, _db, 0, "vegetables", 2)
	Commands.give(gs, _db, 0, "meat", 1)
	Commands.interact(gs, _db, "campfire", "cook_simple_meal")
	assert_eq(gs.economy.count("simple_meal"), 1)
	assert_eq(gs.economy.count("vegetables"), 1)
	gs.combat.lines.clear()
	# A stew is a stove recipe: the action is not on the campfire, so use the command.
	Commands.perform(gs, _db, "cook_stew")
	assert_eq(gs.economy.count("stew"), 0, "no station: no stew")
	assert_string_contains(_lines(gs), "no place to cook")


func test_a_cook_action_with_no_recipe_is_left_alone() -> void:
	var gs := _game_at("inn_interior", "stove")
	Commands.perform(gs, _db, "sweep_floor")
	assert_false(_lines(gs).contains("practice"))


func test_the_dish_is_food_you_can_eat() -> void:
	var gs := _game_at("inn_interior", "stove")
	Commands.give(gs, _db, 0, "stew", 1)
	gs.economy.fed_day = -1
	assert_eq(Commands.use_good(gs, _db, "stew"), "")
	assert_true(Economy.is_fed(gs))
	assert_eq(gs.economy.count("stew"), 0)


func test_the_menu_hint_says_what_you_need_or_what_you_make() -> void:
	var gs := _game_at("inn_interior", "stove")
	assert_eq(Cooking.hint(gs, _db, "cook_stew", "stove"), "needs 1 meat, 2 vegetables")
	Commands.give(gs, _db, 0, "meat", 1)
	Commands.give(gs, _db, 0, "vegetables", 2)
	assert_eq(Cooking.hint(gs, _db, "cook_stew", "stove"), "makes 3 stew")
	assert_eq(Cooking.hint(gs, _db, "cook_stew", "campfire"), "", "not a campfire recipe")
	assert_eq(Cooking.hint(gs, _db, "sweep_floor", "stove"), "")


func test_the_markets_sell_the_ingredients() -> void:
	var gs := _game_at("liscor_market", "krshia_counter")
	Commands.give(gs, _db, 50)
	for good in ["flour", "vegetables", "meat", "dry_pasta"]:
		assert_eq(Commands.buy(gs, _db, "krshia_counter", good)["error"], "", good)
		assert_eq(gs.economy.count(good), 1)
	var celum := _game_at("celum_square", "celum_stall")
	Commands.give(celum, _db, 50)
	assert_eq(Commands.buy(celum, _db, "celum_stall", "meat")["error"], "")
	assert_string_contains(Commands.buy(celum, _db, "celum_stall", "dry_pasta")["error"], "does not sell")


func test_a_market_to_stove_to_table_loop() -> void:
	var gs := _game_at("liscor_market", "krshia_counter")
	Commands.give(gs, _db, 30)
	Commands.buy(gs, _db, "krshia_counter", "meat")
	Commands.buy(gs, _db, "krshia_counter", "vegetables")
	Commands.buy(gs, _db, "krshia_counter", "vegetables")
	var spent := 30 - gs.economy.coins
	assert_eq(spent, 10)
	_stand_next_to(gs, "inn_interior", "stove")
	Commands.interact(gs, _db, "stove", "cook_stew")
	assert_eq(gs.economy.count("stew"), 3)
	var worth := 3 * int(_db.economy.goods["stew"]["sell"])
	assert_true(worth > spent, "a stew batch is worth more than its ingredients")
	gs.economy.fed_day = -1
	assert_eq(Commands.use_good(gs, _db, "stew"), "")
	assert_eq(gs.economy.count("stew"), 2)
