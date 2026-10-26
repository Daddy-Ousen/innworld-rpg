extends GutTest
## M33.1: Erin's food and drink from the Books (ADR 0044 "M33.1").

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()


func _cook(action: String, bag: Dictionary) -> GameState:
	var gs := GameState.new_game(1, _db, "celum")
	var at := Interact.object_of(_db, "inn_interior", "stove")
	gs.player.place("inn_interior", Vector2i(int(at["at"][0]), int(at["at"][1]) + 1))
	Commands.settle(gs, _db)
	for g: String in bag:
		gs.economy.add(g, bag[g])
	Commands.interact(gs, _db, "stove", action)
	return gs


func test_new_dishes_come_from_the_stove() -> void:
	assert_eq(_cook("make_juice", {"blue_fruit": 2}).economy.count("blue_fruit_juice"), 2)
	assert_eq(_cook("fry_burgers", {"meat": 1, "flour": 1, "potatoes": 1}).economy.count("hamburger_and_fries"), 2)
	assert_eq(_cook("warm_honey_milk", {"milk": 1, "honey": 1}).economy.count("ashfire_honey_milk"), 2)
	assert_eq(_cook("mix_milkshake", {"milk": 2, "honey": 1}).economy.count("milkshake"), 3)
	assert_eq(_cook("mix_faerie_drink", {"ale": 1, "faerie_nectar": 1}).economy.count("faerie_flower_drink"), 2)


func test_canon_ingredients_wait_for_their_flag() -> void:
	var gs := GameState.new_game(1, _db, "celum")
	for g: String in ["honey", "potatoes", "faerie_nectar"]:
		assert_false(_db.economy.on_sale(g, gs.flags), "%s is not on sale yet" % g)
	gs.flags["erin.has_ashfire_honey"] = true
	assert_true(_db.economy.on_sale("honey", gs.flags))


func test_the_inn_serves_the_new_dishes() -> void:
	var dishes: Array = _db.rules["inn"]["dishes"]
	for d: String in ["blue_fruit_juice", "hamburger_and_fries", "ashfire_honey_milk", "milkshake", "faerie_flower_drink"]:
		assert_true(dishes.has(d), d)
		assert_true(_db.economy.goods.has(d), d)
