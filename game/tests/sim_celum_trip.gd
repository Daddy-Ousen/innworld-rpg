extends GutTest
## M8.6 acceptance: a new player starts in Celum with no coins, earns them
## with deliveries for the Runners' Guild, buys bread and eats, rents a room
## at the Rat's Tail, walks the road south, sleeps on the camp bedroll,
## gathers herbs, walks on to Liscor and sells them at Krshia's stall.
## Same seed = same result.

const SEED := 20260925

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])


func _to_area(gs: GameState, area: String) -> void:
	assert_true(ToyMaps.walk_to_area(gs, _db, area), "walk to %s" % area)


func _next_to(gs: GameState, object_id: String) -> void:
	assert_true(ToyMaps.walk_next_to(gs, _db, object_id), "walk to %s" % object_id)


func _play() -> GameState:
	var gs := GameState.new_game(SEED, _db, "celum")
	_to_area(gs, "celum_square")
	_to_area(gs, "celum_runners_guild")
	_next_to(gs, "request_board")
	for i in 5:
		assert_eq(Commands.interact(gs, _db, "request_board", "deliver_parcel")["error"], "")
	assert_between(gs.economy.coins, 15, 30)
	_to_area(gs, "celum_square")
	_next_to(gs, "celum_stall")
	assert_eq(Commands.buy(gs, _db, "celum_stall", "bread")["error"], "")
	assert_eq(Commands.buy(gs, _db, "celum_stall", "bread")["error"], "")
	_next_to(gs, "rats_tail_door")
	var coins := gs.economy.coins
	assert_false(Commands.sleep(gs, _db, "rats_tail_door").is_empty(), "rent a room")
	assert_eq(gs.economy.coins, coins - 10)
	assert_eq(gs.economy.hunger, 0, "day one is fed")
	# Day two: eat, then the road south.
	assert_eq(Commands.use_good(gs, _db, "bread"), "")
	_to_area(gs, "celum_gate")
	_to_area(gs, "road_camp")
	_next_to(gs, "camp_herbs")
	assert_eq(Commands.interact(gs, _db, "camp_herbs", "gather_herbs")["error"], "")
	assert_eq(Commands.interact(gs, _db, "camp_herbs", "gather_herbs")["error"], "")
	_next_to(gs, "bedroll")
	var night := Commands.sleep(gs, _db, "bedroll")
	assert_false(night.is_empty(), "sleep at the camp")
	assert_eq(Combat.hp(gs, _db), Stats.max_hp(gs, _db), "the bedroll heals fully")
	assert_eq(gs.economy.hunger, 0)
	# Day three: eat, walk on to Liscor, sell the herbs.
	assert_eq(Commands.use_good(gs, _db, "bread"), "")
	_to_area(gs, "liscor_gate")
	_to_area(gs, "liscor_market")
	_next_to(gs, "krshia_counter")
	coins = gs.economy.coins
	assert_eq(Commands.sell(gs, _db, "krshia_counter", "herbs")["error"], "")
	assert_eq(Commands.sell(gs, _db, "krshia_counter", "herbs")["error"], "")
	assert_eq(gs.economy.coins, coins + 6)
	assert_eq(gs.economy.count("herbs"), 0)
	return gs


func test_celum_to_liscor_on_foot_with_coins_food_and_a_room() -> void:
	var gs := _play()
	assert_eq(gs.player.area, "liscor_market")
	assert_eq(gs.clock.day(), 10)


func test_same_seed_same_trip() -> void:
	assert_eq(_play().to_json(), _play().to_json())
