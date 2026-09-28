extends GutTest
## M14.0 bag screen (ADR 0021): tool goods (hold, stow), leaving goods
## behind, the bag's rows and header, and the I key on the game screen.

const SEED := 20260928

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])


func _game() -> GameState:
	var gs := GameState.new_game(SEED, _db, "celum")
	Commands.settle(gs, _db)
	return gs


func _press(node: Node, code: Key) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	ev.keycode = code
	ev.pressed = true
	node._unhandled_input(ev)


func test_tool_goods_map_to_items() -> void:
	assert_eq(Economy.good_for_item(_db, "rolling_pin"), "rolling_pin")
	assert_eq(Economy.good_for_item(_db, "horseshoe"), "horseshoe")
	assert_eq(Economy.good_for_item(_db, "chair"), "", "a chair does not fit in the bag")
	assert_eq(Economy.good_for_item(_db, ""), "")


func test_hold_takes_a_tool_from_the_bag_and_stows_the_old_one() -> void:
	var gs := _game()
	gs.economy.add("rolling_pin", 1)
	gs.player.held = "stone"
	var before := gs.clock.total_minutes * 60 + gs.player.sub_seconds
	assert_eq(Commands.hold_good(gs, _db, "rolling_pin"), "")
	assert_eq(gs.player.held, "rolling_pin")
	assert_eq(gs.economy.count("rolling_pin"), 0)
	assert_eq(gs.economy.count("stone"), 1, "the stone went in the bag")
	assert_gt(gs.clock.total_minutes * 60 + gs.player.sub_seconds, before, "one turn passes")
	assert_true(gs.combat.lines.any(func(l: String) -> bool: return l.contains("stone in your bag")))


func test_hold_puts_a_chair_down_for_good() -> void:
	var gs := _game()
	gs.economy.add("horseshoe", 1)
	gs.player.held = "chair"
	assert_eq(Commands.hold_good(gs, _db, "horseshoe"), "")
	assert_eq(gs.player.held, "horseshoe")
	assert_eq(gs.economy.goods(), [] as Array[String], "the chair is gone, not in the bag")


func test_hold_refuses_food_and_missing_goods() -> void:
	var gs := _game()
	assert_string_contains(Commands.hold_good(gs, _db, "rolling_pin"), "You have no")
	gs.economy.add("bread", 1)
	assert_string_contains(Commands.hold_good(gs, _db, "bread"), "cannot hold")
	assert_eq(gs.economy.count("bread"), 1)


func test_stow_puts_the_held_tool_in_the_bag_but_not_a_chair() -> void:
	var gs := _game()
	assert_eq(Commands.stow(gs, _db), "You hold nothing.")
	gs.player.held = "chair"
	assert_string_contains(Commands.stow(gs, _db), "will not fit")
	assert_eq(gs.player.held, "chair")
	gs.player.held = "rolling_pin"
	assert_eq(Commands.stow(gs, _db), "")
	assert_eq(gs.player.held, "")
	assert_eq(gs.economy.count("rolling_pin"), 1)


func test_drop_good_leaves_one_behind() -> void:
	var gs := _game()
	gs.economy.add("bread", 2)
	assert_eq(Commands.drop_good(gs, _db, "bread"), "")
	assert_eq(gs.economy.count("bread"), 1)
	assert_eq(Commands.drop_good(gs, _db, "bread"), "")
	assert_string_contains(Commands.drop_good(gs, _db, "bread"), "You have no")


func test_bag_commands_are_refused_while_knocked_out_but_not_near_enemies() -> void:
	var gs := _game()
	gs.economy.add("rolling_pin", 1)
	Combat.set_hp(gs, _db, 0)
	assert_eq(Commands.hold_good(gs, _db, "rolling_pin"), Combat.REFUSED_DOWN)
	assert_eq(gs.economy.count("rolling_pin"), 1)


func test_rows_give_each_good_its_use() -> void:
	var gs := _game()
	for g: String in ["bread", "herbs", "healing_potion", "rolling_pin"]:
		gs.economy.add(g, 1)
	var by_good := {}
	for r: Dictionary in Bag.rows(gs, _db):
		by_good[r["good"]] = r
	assert_eq(by_good["bread"]["use"], Interact.USE_GOOD + "bread")
	assert_string_contains(by_good["bread"]["text"], "Eat")
	assert_eq(by_good["healing_potion"]["use"], Interact.USE_GOOD + "healing_potion")
	assert_string_contains(by_good["healing_potion"]["text"], "Drink")
	assert_eq(by_good["rolling_pin"]["use"], Interact.HOLD_GOOD + "rolling_pin")
	assert_eq(by_good["herbs"]["use"], "", "a trade good has no use here")
	assert_string_contains(by_good["herbs"]["text"], "Herbs x1")


func test_header_shows_coins_hand_and_an_empty_bag() -> void:
	var gs := _game()
	var h := Bag.header(gs, _db)
	assert_has(h, "In hand: nothing.")
	assert_has(h, "The bag is empty.")
	assert_true(h.any(func(l: String) -> bool: return l.contains("0c")), "the purse")
	gs.player.held = "chair"
	assert_has(Bag.header(gs, _db), "In hand: Chair (too big for the bag).")


func test_item_goods_are_checked() -> void:
	var e := EconomyDb.from_dicts({
		"a": {"name": "A", "confidence": "guess", "buy": 0, "sell": 0, "item": "no_such_item"},
		"b": {"name": "B", "confidence": "guess", "buy": 0, "sell": 0, "item": "stone", "food": true},
		"c": {"name": "C", "confidence": "guess", "buy": 0, "sell": 0, "item": "stone"},
	}, {})
	var errs := e.validate(_db)
	for want: String in ["unknown item 'no_such_item'", "no other use", "already has good"]:
		assert_true(errs.any(func(x: String) -> bool: return x.contains(want)), want)


func test_i_opens_the_bag_and_a_pick_runs_and_reopens_it() -> void:
	var session := get_node("/root/Session")
	var gs := _game()
	gs.economy.add("rolling_pin", 1)
	session.set_state(gs)
	var main: Node = add_child_autofree(load("res://world/main.tscn").instantiate())
	main.switch_scene = false
	_press(main, KEY_I)
	assert_true(main.bag.visible)
	assert_true(main.is_busy())
	main.bag.chosen.emit(Interact.HOLD_GOOD + "rolling_pin")
	assert_eq(session.gs.player.held, "rolling_pin")
	assert_true(main.bag.visible, "the bag opens again after a pick")
	main.bag.chosen.emit(Interact.STOW)
	assert_eq(session.gs.player.held, "")
	assert_eq(session.gs.economy.count("rolling_pin"), 1)
	_press(main.bag, KEY_I)
	assert_false(main.bag.visible)
	assert_false(main.is_busy())
