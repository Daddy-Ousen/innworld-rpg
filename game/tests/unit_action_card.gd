extends GutTest
## M34.0 (ADR 0045): the use menu is an action card. With 2+ targets near, the
## player picks the target first, then a big button. A drag never picks. Attack
## needs a hold on touch and a Yes / No with keys.

const SEED := 20260929

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])


func _npc(id: String, extra: Dictionary = {}) -> Dictionary:
	var o := {"id": id, "name": id, "npc": true, "actions": ["talk_with_guest"], "sleep": false, "item": "",
		"price": 0, "trades": [] as Array[Dictionary], "ride": {}, "attack": true, "standing": "friend"}
	o.merge(extra, true)
	return o


func _bed() -> Dictionary:
	return {"id": "bed", "name": "Bed", "npc": false, "actions": [], "sleep": true, "item": "",
		"price": 0, "trades": [] as Array[Dictionary], "ride": {}}


func _menu(touch: bool) -> InteractMenu:
	var m: InteractMenu = add_child_autofree(load("res://ui/interact_menu.tscn").instantiate())
	m.touch_override = 1 if touch else 0
	return m


func _texts(m: InteractMenu) -> Array[String]:
	var out: Array[String] = []
	for r: Dictionary in m.rows():
		out.append(String(r["text"]))
	return out


func _index_of(m: InteractMenu, part: String) -> int:
	var rows := m.rows()
	for i in rows.size():
		if String(rows[i]["text"]).contains(part):
			return i
	return -1


func test_one_target_opens_its_actions_at_once() -> void:
	var m := _menu(false)
	assert_true(m.open([_npc("erin_solstice")] as Array[Dictionary], _db))
	assert_eq(m.page, InteractMenu.ACTIONS)
	assert_string_contains(m.title_text(), "erin_solstice")
	assert_string_contains(m.title_text(), "friend")
	assert_true(_index_of(m, "Talk") >= 0, str(_texts(m)))
	assert_false(_texts(m).any(func(t: String) -> bool: return t.contains(" — ")), "no name prefix on a card")


func test_two_targets_ask_who_first_then_back_returns() -> void:
	var m := _menu(false)
	assert_true(m.open([_bed(), _npc("erin_solstice")] as Array[Dictionary], _db))
	assert_eq(m.page, InteractMenu.TARGETS)
	assert_eq(m.rows().size(), 2)
	assert_string_contains(m.rows()[1]["text"], "erin_solstice (friend)")
	m.pick(1)
	assert_eq(m.page, InteractMenu.ACTIONS)
	assert_true(m.visible)
	m.back()
	assert_eq(m.page, InteractMenu.TARGETS, "Back goes to the target list")
	m.back()
	assert_false(m.visible, "Back on the first page closes")


func test_a_pick_emits_the_object_and_the_action() -> void:
	var m := _menu(false)
	watch_signals(m)
	m.open([_bed()] as Array[Dictionary], _db)
	assert_eq(m.page, InteractMenu.ACTIONS)
	m.pick(_index_of(m, "Sleep"))
	assert_signal_emitted_with_parameters(m, "chosen", ["bed", Interact.SLEEP])
	assert_false(m.visible)


func test_a_drag_never_picks() -> void:
	var m := _menu(true)
	watch_signals(m)
	m.open([_bed()] as Array[Dictionary], _db)
	var b: InteractMenu.CardButton = m.buttons()[_index_of(m, "Sleep")]
	b.press_at(Vector2(10, 10))
	b.move_to(Vector2(10, 10 + InteractMenu.DRAG + 4), Vector2(0, InteractMenu.DRAG + 4))
	b.pressed.emit()
	assert_signal_not_emitted(m, "chosen", "a finger that moved scrolls, it does not pick")
	assert_true(m.visible)
	b.press_at(Vector2(10, 10))
	b.move_to(Vector2(12, 13), Vector2(2, 3))
	b.pressed.emit()
	assert_signal_emitted(m, "chosen", "a small wobble still picks")


func test_attack_is_its_own_last_row() -> void:
	var m := _menu(false)
	m.open([_npc("erin_solstice")] as Array[Dictionary], _db)
	var rows := m.rows()
	assert_eq(rows[-1]["action"], Interact.ATTACK)
	assert_eq(rows[-1]["group"], InteractMenu.ATTACK_GROUP)
	assert_eq(rows.filter(func(r: Dictionary) -> bool: return r["action"] == Interact.ATTACK).size(), 1)


func test_keys_attack_asks_yes_or_no() -> void:
	var m := _menu(false)
	watch_signals(m)
	m.open([_npc("erin_solstice")] as Array[Dictionary], _db)
	m.pick(m.rows().size() - 1)
	assert_eq(m.page, InteractMenu.CONFIRM)
	assert_signal_not_emitted(m, "chosen")
	assert_string_contains(m.title_text(), "Attack erin_solstice?")
	m.confirm(false)
	assert_eq(m.page, InteractMenu.ACTIONS, "No goes back to the card")
	m.pick(m.rows().size() - 1)
	m.confirm(true)
	assert_signal_emitted_with_parameters(m, "chosen", ["erin_solstice", Interact.ATTACK])


func test_touch_attack_needs_a_hold() -> void:
	var m := _menu(true)
	watch_signals(m)
	m.open([_npc("erin_solstice")] as Array[Dictionary], _db)
	var b: InteractMenu.HoldButton = m.buttons()[-1]
	assert_string_contains(b.text, "Hold")
	b.button_down.emit()
	b._process(InteractMenu.HOLD * 0.5)
	b.button_up.emit()
	b.pressed.emit()
	assert_signal_not_emitted(m, "chosen", "a short tap does not attack")
	b.button_down.emit()
	b._process(InteractMenu.HOLD * 0.6)
	b._process(InteractMenu.HOLD * 0.6)
	assert_signal_emitted_with_parameters(m, "chosen", ["erin_solstice", Interact.ATTACK])


## M34.1: a shop's trades are one Shop button (the shop screen has the goods).
func test_a_shop_is_one_shop_button() -> void:
	var gs := GameState.new_game(SEED, _db, "celum")
	var o := {"id": "celum_stall", "name": "Stall", "npc": false, "actions": [], "sleep": false, "item": "",
		"price": 0, "ride": {}, "trades": [
			{"kind": Economy.BUY, "good": "bread", "name": "Bread", "price": 3, "bulk": 5},
			{"kind": Economy.SELL, "good": "herbs", "name": "Herbs", "price": 2, "have": 4}] as Array[Dictionary]}
	var picks: Array = InteractMenu.action_rows(o, _db, gs).map(func(r: Dictionary) -> String: return r["action"])
	assert_eq(picks, [InteractMenu.SHOP])


func test_the_card_shows_the_target_face() -> void:
	var m := _menu(false)
	var face: TextureRect = m.get_node("%Face")
	m.open([_bed(), _npc("erin_solstice")] as Array[Dictionary], _db)
	assert_false(face.visible, "the target list has no face")
	m.pick(1)
	assert_true(face.visible, "Erin's card shows her face")
	m.back()
	m.pick(0)
	assert_false(face.visible, "a bed has no face")


func test_the_bag_is_one_card() -> void:
	var m := _menu(false)
	var gs := GameState.new_game(SEED, _db, "celum")
	Commands.give(gs, _db, 0, "bread", 2)
	assert_true(m.open_bag(gs, _db))
	assert_eq(m.page, InteractMenu.ACTIONS)
	var i := _index_of(m, "Bread")
	assert_true(i >= 0, str(_texts(m)))
	assert_eq(m.rows()[i]["object"], "bag")
	assert_eq(m.rows()[i]["action"], Interact.USE_GOOD + "bread")


func test_buttons_are_tall_enough_for_a_thumb() -> void:
	var m := _menu(true)
	m.open([_npc("erin_solstice")] as Array[Dictionary], _db)
	for b: Button in m.buttons():
		assert_gte(b.custom_minimum_size.y, InteractMenu.ROW_H)
		assert_eq(b.action_mode, BaseButton.ACTION_MODE_BUTTON_RELEASE, "fires on release")
