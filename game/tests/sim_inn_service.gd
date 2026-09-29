extends GutTest
## M14.2 (ADR 0021): a week at the inn. Between meals the player buys
## ingredients (given here) and cooks stew and pasta at the stove; they serve
## the patrons at every meal and sleeps in the inn's bed. Serving earns coin
## and the inn's reputation grows. Real data, real commands.

const SEED := 14002
const INN := "inn_interior"
const DAYS := 7
## What to cook after breakfast and after lunch (the stove takes time; guests do not wait).
const COOKING := [["cook_stew"], ["cook_stew", "cook_pasta"]]

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])


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


## Cooks at the stove between meals: `actions` in order. Stops at a refusal
## (a canon fight in the inn, or too tired).
func _cook(gs: GameState, actions: Array) -> void:
	Commands.give(gs, _db, 0, "meat", 1)
	Commands.give(gs, _db, 0, "vegetables", 3)
	Commands.give(gs, _db, 0, "dry_pasta", 1)
	gs.player.place(INN, Vector2i(20, 2))
	for a: String in actions:
		if Commands.interact(gs, _db, "stove", a)["error"] != "":
			return


## Serves every waiting patron, until the meal is over. Returns the dishes served.
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
			if choices.is_empty():
				continue
			if Commands.serve(gs, _db, gid, choices[0]["good"])["error"] == "":
				served += 1
		Commands.wait(gs, _db, 600)
	return served


## True while a patron has not been served yet (they may still be on the way).
func _waiting(gs: GameState) -> bool:
	return gs.inn.guests.any(func(g: Dictionary) -> bool: return int(g["paid"]) == 0)


func _wait_to(gs: GameState, hour: int) -> void:
	var guard := 0
	while _hour(gs) < hour and guard < 200:
		guard += 1
		Commands.wait(gs, _db, 600)


func test_a_week_of_serving_earns_coin_and_a_name() -> void:
	var gs := GameState.new_game(SEED, _db)
	gs.player.place(INN, Vector2i(12, 11))
	Commands.settle(gs, _db)
	assert_true(Guests.is_open(gs, _db), "Book 1 day 8: the inn is open")
	Commands.give(gs, _db, 0, "stew", 3)  # left from yesterday
	var coins := gs.economy.coins
	var served := 0
	var takings: Array[String] = []
	for day in DAYS:
		var meals: Array = Guests.rules(_db)["meals"]
		for i in meals.size():
			_wait_to(gs, int(meals[i]["hours"][0]))
			served += _serve_meal(gs, int(meals[i]["hours"][1]))
			if i < COOKING.size():
				_cook(gs, COOKING[i])
		gs.player.place(INN, Vector2i(20, 13))
		var night := Commands.sleep(gs, _db, "bed")
		assert_false(night.is_empty(), "slept on day %d" % day)
		for line: String in night.get("lines", []):
			if line.begins_with("The inn took in"):
				takings.append(line)
		gs.player.place(INN, Vector2i(12, 11))
		Commands.settle(gs, _db)
	gut.p("served %d, coins %d, reputation %d" % [served, gs.economy.coins - coins, Guests.reputation(gs, _db)])
	assert_gt(served, DAYS, "more than one guest a day")
	assert_eq(gs.inn.served_total, served)
	assert_gt(gs.economy.coins - coins, 0)
	assert_gt(Guests.reputation(gs, _db), 10, "the inn's name grows")
	assert_gt(takings.size(), 0, "the morning tells the takings")
