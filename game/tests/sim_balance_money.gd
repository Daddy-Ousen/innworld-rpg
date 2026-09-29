extends GutTest
## M14.8 probe (ADR 0021): does the inn pay for itself? Two weeks at the inn on
## several seeds, the way `sim_inn_service` plays a week: cook between meals,
## serve every patron, sleep in the bed. Ingredients are charged at Krshia's
## shelf price and the player eats three loaves a day. Logs takings, costs and
## reputation by day; loose asserts only. Set BALANCE_LOG to a file path.

const SEEDS := [14002, 14008, 20260923]
const INN := "inn_interior"
const DAYS := 14
const SHOP := "krshia_stall"
const BREAD_A_DAY := 3
const COOKING := [["cook_stew"], ["cook_stew", "cook_pasta"]]

var _db: DataDb
## Copper spent on ingredients and food in the current run.
var _spent := 0


func before_all() -> void:
	_db = DataDb.load_dir()


func _hour(gs: GameState) -> float:
	return gs.clock.minute() / 60.0


func _place_by(gs: GameState, target: Vector2i) -> bool:
	for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
			Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]:
		var at := target + d
		if _db.maps.is_walkable(INN, at) and Guests.at(gs, INN, at) == "" and gs.npcs.at(INN, at) == "":
			gs.player.place(INN, at)
			return true
	return false


## Puts `count` of `good` in the bag and charges the shelf price.
func _stock(gs: GameState, good: String, count: int) -> void:
	_spent += count * Economy.price(gs, _db, SHOP, good, Economy.BUY)
	Commands.give(gs, _db, 0, good, count)


func _inputs_of(action: String) -> Dictionary:
	for id: String in _db.economy.recipes:
		if _db.economy.recipes[id]["action"] == action:
			return _db.economy.recipes[id]["inputs"]
	return {}


func _cook(gs: GameState, actions: Array) -> void:
	gs.player.place(INN, Vector2i(20, 2))
	for a: String in actions:
		for good: String in _inputs_of(a):
			_stock(gs, good, int(_inputs_of(a)[good]))
		if Commands.interact(gs, _db, "stove", a)["error"] != "":
			return


func _waiting(gs: GameState) -> bool:
	return gs.inn.guests.any(func(g: Dictionary) -> bool: return int(g["paid"]) == 0)


## Serves every waiting patron until the meal is over. Returns dishes served.
func _serve_meal(gs: GameState, until_hour: int) -> int:
	var served := 0
	var guard := 0
	while (_hour(gs) < until_hour or _waiting(gs)) and guard < 200:
		guard += 1
		for g in Guests.present(gs):
			if int(g["paid"]) > 0 or not _place_by(gs, Vector2i(int(g["seat"][0]), int(g["seat"][1]))):
				continue
			var gid := Guests.GUEST + String(g["id"])
			var choices := Guests.serve_choices(gs, _db, gid)
			if not choices.is_empty() and Commands.serve(gs, _db, gid, choices[0]["good"])["error"] == "":
				served += 1
		Commands.wait(gs, _db, 600)
	return served


func _wait_to(gs: GameState, hour: int) -> void:
	var guard := 0
	while _hour(gs) < hour and guard < 200:
		guard += 1
		Commands.wait(gs, _db, 600)


## Plays DAYS days. Returns {"rows", "earned", "spent", "week2_earned", "week2_spent", "rep"}.
func _run(seed_: int) -> Dictionary:
	_spent = 0
	var gs := GameState.new_game(seed_, _db)
	gs.player.place(INN, Vector2i(12, 11))
	Commands.settle(gs, _db)
	_stock(gs, "stew", 0)  # no-op charge; keeps the helper in one place
	Commands.give(gs, _db, 0, "stew", 3)  # left from yesterday
	var start_coins := gs.economy.coins
	var rows: Array[String] = []
	var week2_from_coins := 0
	var week2_from_spent := 0
	for day in DAYS:
		if day == 7:
			week2_from_coins = gs.economy.coins
			week2_from_spent = _spent
		var before := gs.economy.coins
		var spent_before := _spent
		var served := 0
		var meals: Array = Guests.rules(_db)["meals"]
		for i in meals.size():
			_wait_to(gs, int(meals[i]["hours"][0]))
			served += _serve_meal(gs, int(meals[i]["hours"][1]))
			if i < COOKING.size():
				_cook(gs, COOKING[i])
		_spent += BREAD_A_DAY * Economy.price(gs, _db, SHOP, "bread", Economy.BUY)
		gs.player.place(INN, Vector2i(20, 13))
		Commands.sleep(gs, _db, "bed")
		rows.append("seed %d day %2d  served %2d  took %3d  spent %3d  reputation %3d" % [seed_, day + 1,
				served, gs.economy.coins - before, _spent - spent_before, Guests.reputation(gs, _db)])
		gs.player.place(INN, Vector2i(12, 11))
		Commands.settle(gs, _db)
	return {"rows": rows, "earned": gs.economy.coins - start_coins, "spent": _spent,
			"week2_earned": gs.economy.coins - week2_from_coins, "week2_spent": _spent - week2_from_spent,
			"rep": Guests.reputation(gs, _db)}


func test_the_inn_pays_for_its_food_by_week_two() -> void:
	var lines: Array[String] = []
	for s: int in SEEDS:
		var r := _run(s)
		lines.append_array(r["rows"])
		lines.append("seed %d total: took %d, spent %d; week 2: took %d, spent %d" % [s, r["earned"],
				r["spent"], r["week2_earned"], r["week2_spent"]])
		assert_gt(int(r["week2_earned"]), int(r["week2_spent"]), "seed %d: week 2 takings cover the food" % s)
		assert_gt(int(r["earned"]), int(r["spent"]), "seed %d: the inn is in profit" % s)
		assert_gt(int(r["rep"]), 10, "seed %d: the inn's name grows" % s)
	var path := OS.get_environment("BALANCE_LOG")
	if path != "":
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_string("\n".join(lines) + "\n")
