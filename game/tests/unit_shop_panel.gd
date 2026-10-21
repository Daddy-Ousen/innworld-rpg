extends GutTest
## M34.1 (ADR 0045): the shop screen. Buy and Sell tabs, one card per good, a
## count strip (- / + / Max) and one big Buy or Sell button. The picks are the
## trade picks the use menu always sent (Interact.trade_action).

const SEED := 20260929

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])


func _game(coins: int = 0) -> GameState:
	var gs := GameState.new_game(SEED, _db, "celum")
	gs.economy.coins = coins
	return gs


func _stall(gs: GameState) -> Dictionary:
	var trades: Array[Dictionary] = [
		{"kind": Economy.BUY, "good": "bread", "name": "Bread", "price": 3, "bulk": 5},
		{"kind": Economy.BUY, "good": "hot_meal", "name": "Hot meal", "price": 4, "bulk": 0}]
	if gs.economy.count("herbs") > 0:
		trades.append({"kind": Economy.SELL, "good": "herbs", "name": "Herbs", "price": 2,
				"have": gs.economy.count("herbs")})
	return {"id": "stall", "name": "Stall", "npc": false, "actions": [], "sleep": false, "item": "",
		"price": 0, "ride": {}, "trades": trades}


func _panel() -> ShopPanel:
	return add_child_autofree(load("res://ui/shop_panel.tscn").instantiate())


func _index_of(p: ShopPanel, good: String) -> int:
	var rows := p.rows()
	for i in rows.size():
		if rows[i]["good"] == good:
			return i
	return -1


func test_buy_tab_first_with_one_card_per_good() -> void:
	var gs := _game(30)
	var p := _panel()
	assert_true(p.open(_stall(gs), _db, gs))
	assert_true(p.visible)
	assert_eq(p.tab, Economy.BUY)
	assert_eq(p.rows().map(func(r: Dictionary) -> String: return r["good"]), ["bread", "hot_meal"])
	assert_string_contains(p.rows()[0]["text"], "Bread")
	assert_string_contains(p.rows()[0]["text"], Economy.format(_db, 3))
	assert_false(p.deal_enabled(), "no strip before a card is picked")


func test_pick_count_and_buy_sends_the_trade_pick() -> void:
	var gs := _game(30)
	var p := _panel()
	watch_signals(p)
	p.open(_stall(gs), _db, gs)
	p.pick(_index_of(p, "bread"))
	assert_eq(p.good, "bread")
	assert_eq(p.count, 1)
	p.step_count(1)
	p.step_count(1)
	assert_eq(p.deal_text(), "Buy 3 for %s" % Economy.format(_db, 9))
	p.deal()
	assert_signal_emitted_with_parameters(p, "chosen", ["stall", "buy:bread#3"])
	p.step_count(-5)
	assert_eq(p.count, 1, "never under one")


func test_max_is_what_the_coins_pay_for() -> void:
	var gs := _game(10)
	var p := _panel()
	p.open(_stall(gs), _db, gs)
	p.pick(_index_of(p, "bread"))
	p.set_max()
	assert_eq(p.count, 3, "10 coins buy 3 bread at 3")
	p.step_count(1)
	assert_eq(p.count, 3, "+ stops at what you can pay")
	p.pick(_index_of(p, "hot_meal"))
	p.set_max()
	assert_eq(p.count, 1, "a meal eaten there is always one")


func test_no_coins_no_buy() -> void:
	var gs := _game(2)
	var p := _panel()
	watch_signals(p)
	p.open(_stall(gs), _db, gs)
	p.pick(_index_of(p, "bread"))
	assert_false(p.deal_enabled())
	assert_eq(p.deal_text(), "Not enough coins")
	p.deal()
	assert_signal_not_emitted(p, "chosen")


func test_sell_tab_lists_the_bag_and_sells_all() -> void:
	var gs := _game()
	Commands.give(gs, _db, 0, "herbs", 4)
	var p := _panel()
	watch_signals(p)
	p.open(_stall(gs), _db, gs)
	p.show_tab(Economy.SELL)
	assert_eq(p.rows().size(), 1)
	assert_string_contains(p.rows()[0]["text"], "have 4")
	p.pick(0)
	p.set_max()
	assert_eq(p.deal_text(), "Sell 4 for %s" % Economy.format(_db, 8))
	p.sell_all(0)
	assert_signal_emitted_with_parameters(p, "chosen", ["stall", "sell:herbs#4"])


func test_a_shop_with_nothing_to_buy_opens_on_sell() -> void:
	var gs := _game()
	var o := {"id": "buyer", "name": "Buyer", "trades": [
		{"kind": Economy.SELL, "good": "herbs", "name": "Herbs", "price": 2, "have": 1}] as Array[Dictionary]}
	Commands.give(gs, _db, 0, "herbs", 1)
	var p := _panel()
	p.open(o, _db, gs)
	assert_eq(p.tab, Economy.SELL)
	p.show_tab(Economy.BUY)
	assert_eq(p.rows().size(), 0, "an empty Buy tab")


func test_no_trades_opens_nothing() -> void:
	var gs := _game()
	var p := _panel()
	assert_false(p.open({"id": "well", "name": "Well", "trades": [] as Array[Dictionary]}, _db, gs))
	assert_false(p.visible)


func test_open_again_keeps_the_tab_good_and_count() -> void:
	var gs := _game(30)
	var p := _panel()
	p.open(_stall(gs), _db, gs)
	p.pick(_index_of(p, "bread"))
	p.step_count(1)
	p.step_count(1)
	p.step_count(1)
	gs.economy.coins = 7  # after a deal: fewer coins
	p.open(_stall(gs), _db, gs)
	assert_eq(p.good, "bread")
	assert_eq(p.count, 2, "the count is clamped to what you can now pay")
	p.close()
	p.open(_stall(gs), _db, gs)
	assert_eq(p.good, "", "a new visit starts fresh")


func test_hold_plus_counts_fast() -> void:
	var gs := _game(300)
	var p := _panel()
	p.open(_stall(gs), _db, gs)
	p.pick(_index_of(p, "bread"))
	var plus: ShopPanel.StepButton = p._plus
	plus.button_down.emit()
	assert_eq(p.count, 2, "one step on press")
	plus._process(ShopPanel.REPEAT_WAIT * 0.5)
	assert_eq(p.count, 2, "no repeat before the wait")
	plus._process(ShopPanel.REPEAT_WAIT * 0.5 + ShopPanel.REPEAT_EVERY * 3.5)
	assert_eq(p.count, 5, "three repeats after the wait")
	plus.button_up.emit()
	plus._process(1.0)
	assert_eq(p.count, 5, "stops when let go")


func test_cards_are_drag_safe_buttons() -> void:
	var gs := _game(30)
	var p := _panel()
	p.open(_stall(gs), _db, gs)
	for b: Button in p.cards():
		assert_true(b is InteractMenu.CardButton)
		assert_eq(b.action_mode, BaseButton.ACTION_MODE_BUTTON_RELEASE, "fires on release")
		assert_gte(b.custom_minimum_size.y, InteractMenu.ROW_H)
	var c: InteractMenu.CardButton = p.cards()[0]
	c.press_at(Vector2(10, 10))
	c.move_to(Vector2(10, 10 + InteractMenu.DRAG + 4), Vector2(0, InteractMenu.DRAG + 4))
	c.pressed.emit()
	assert_eq(p.good, "", "a drag scrolls, it does not pick")


func test_back_sends_the_shop_id() -> void:
	var gs := _game(30)
	var p := _panel()
	watch_signals(p)
	p.open(_stall(gs), _db, gs)
	p.back()
	assert_false(p.visible)
	assert_signal_emitted_with_parameters(p, "went_back", ["stall"])


func test_the_card_has_one_shop_button() -> void:
	var gs := _game()
	Commands.give(gs, _db, 0, "herbs", 4)
	var o := _stall(gs)
	var rows := InteractMenu.action_rows(o, _db, gs)
	var trade := rows.filter(func(r: Dictionary) -> bool: return r["group"] == "trade")
	assert_eq(trade.size(), 1, "one Shop button, not a row per good")
	assert_eq(trade[0]["action"], InteractMenu.SHOP)
	assert_eq(trade[0]["text"], "Shop (1 to sell)")
	var m: InteractMenu = add_child_autofree(load("res://ui/interact_menu.tscn").instantiate())
	watch_signals(m)
	m.open([o] as Array[Dictionary], _db)
	m.pick(0)
	assert_signal_emitted(m, "shop_opened")
	assert_signal_not_emitted(m, "chosen", "Shop is not a command")
	assert_false(m.visible)


## The real game screen: Shop opens the panel, a deal runs and the panel stays
## open with new counts; Back shows the shop's card again.
func test_game_screen_buys_and_stays_open() -> void:
	var session := get_node_or_null("/root/Session")
	if session == null:
		fail_test("no Session autoload")
		return
	var gs := GameState.new_game(SEED, session.db, "celum")
	session.set_state(gs)
	gs.npcs.npcs.clear()  # only the stall near
	var at := Interact.object_of(session.db, "celum_square", "celum_stall")
	var pos := Vector2i(int(at["at"][0]), int(at["at"][1]))
	for d: Vector2i in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
		if session.db.maps.is_walkable("celum_square", pos + d):
			gs.player.place("celum_square", pos + d)
			break
	gs.economy.coins = 50
	var main: Node = add_child_autofree(load("res://world/main.tscn").instantiate())
	main.open_use_menu()
	var menu: InteractMenu = main.menu
	if menu.page == InteractMenu.TARGETS:
		for i in menu.rows().size():
			if menu.rows()[i]["object"] == "celum_stall":
				menu.pick(i)
				break
	var shop_row := -1
	for i in menu.rows().size():
		if menu.rows()[i]["action"] == InteractMenu.SHOP:
			shop_row = i
	assert_true(shop_row >= 0, "the stall's card has a Shop button")
	menu.pick(shop_row)
	var shop: ShopPanel = main.shop
	assert_true(shop.visible)
	assert_true(main.is_busy(), "no walking while shopping")
	shop.pick(_index_of(shop, "bread"))
	shop.step_count(1)
	shop.deal()
	assert_eq(gs.economy.count("bread"), 2)
	assert_true(shop.visible, "the shop stays open after a deal")
	assert_string_contains(shop.sub_text(), "You buy 2 bread", "what the deal did")
	assert_string_contains(shop.sub_text(), "left.")
	assert_string_contains(shop.rows()[_index_of(shop, "bread")]["text"], "have 2")
	assert_eq(shop.good, "bread")
	shop.back()
	assert_false(shop.visible)
	assert_true(menu.visible)
	assert_eq(menu.page, InteractMenu.ACTIONS, "Back shows the stall's card")
	assert_eq(menu.title_text().begins_with(String(at["name"])), true)
