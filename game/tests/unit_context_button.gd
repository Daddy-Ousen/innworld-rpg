extends GutTest
## M34.2 (ADR 0045): the context button replaces Use. It names the nearest
## target's main action and the target; a tap opens that target's card. Chips
## open the other targets near. More, Bag and the button sit bottom right;
## Menu and Back sit top right.

const SEED := 20260929

var _session: Node


func before_each() -> void:
	_session = get_node_or_null("/root/Session")
	_session.set_touch_mode(TouchSettings.ON)


func after_each() -> void:
	_session.set_touch_mode(TouchSettings.AUTO)
	_session.touch_seen = false
	_session.apply_ui_scale()


func _touch() -> TouchControls:
	var t := TouchControls.new()
	t.size = Vector2(1152, 648)
	add_child_autofree(t)
	return t


func _t(id: String, verb: String = "Talk", look: String = "") -> Dictionary:
	return {"id": id, "verb": verb, "name": id.capitalize(), "look": look}


func _main_at(area: String, object_id: String) -> Node:
	var db: DataDb = _session.db
	var gs := GameState.new_game(SEED, db, "celum")
	_session.set_state(gs)
	gs.npcs.npcs.clear()
	var at := Interact.object_of(db, area, object_id)
	var pos := Vector2i(int(at["at"][0]), int(at["at"][1]))
	for d: Vector2i in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
		if db.maps.is_walkable(area, pos + d):
			gs.player.place(area, pos + d)
			break
	var m: Node = load("res://world/main.tscn").instantiate()
	m.switch_scene = false
	add_child_autofree(m)
	m._process(0.0)
	return m


func test_verbs_name_the_main_action() -> void:
	var base := {"id": "x", "name": "X", "npc": false, "actions": [], "sleep": false, "item": "", "price": 0,
		"trades": [] as Array[Dictionary], "ride": {}, "portal": {}}
	var with := func(extra: Dictionary) -> Dictionary:
		var o := base.duplicate(true)
		o.merge(extra, true)
		return o
	assert_eq(InteractMenu.verb_of(with.call({"npc": true, "serve": []})), "Talk")
	assert_eq(InteractMenu.verb_of(with.call({"npc": true, "serve": [{"ordered": true}]})), "Serve")
	assert_eq(InteractMenu.verb_of(with.call({"guest": true})), "Serve")
	assert_eq(InteractMenu.verb_of(with.call({"trades": [{"kind": Economy.BUY}]})), "Shop")
	assert_eq(InteractMenu.verb_of(with.call({"sleep": true})), "Sleep")
	assert_eq(InteractMenu.verb_of(with.call({"portal": {"links": []}})), "Door")
	assert_eq(InteractMenu.verb_of(with.call({"ride": {"to": "a"}})), "Ride")
	assert_eq(InteractMenu.verb_of(with.call({"item": "stone"})), "Take")
	assert_eq(InteractMenu.verb_of(with.call({"actions": ["cook_simple_meal"], "item": "pin"})), "Use")


func test_the_button_shows_the_nearest_target() -> void:
	var t := _touch()
	assert_true(t.context.disabled, "nothing near")
	assert_eq(t.context.text, "-")
	t.set_targets([_t("erin"), _t("bed", "Sleep")] as Array[Dictionary])
	assert_false(t.context.disabled)
	assert_eq(t.context.text, "Talk\nErin")
	assert_eq(t.chip_ids(), ["bed"] as Array[String], "the other target is a chip")


func test_a_tap_opens_the_target_and_a_chip_opens_its_own() -> void:
	var t := _touch()
	watch_signals(t)
	t.set_targets([_t("erin"), _t("bed", "Sleep"), _t("stove", "Use")] as Array[Dictionary])
	t.context.pressed.emit()
	assert_signal_emitted_with_parameters(t, "context_pressed", ["erin"])
	t.press_chip(1)
	assert_signal_emitted_with_parameters(t, "context_pressed", ["stove"], 1)


func test_many_targets_end_with_all() -> void:
	var t := _touch()
	var many: Array[Dictionary] = []
	for id: String in ["a", "b", "c", "d", "e", "f"]:
		many.append(_t(id))
	t.set_targets(many)
	assert_eq(t.chip_ids(), ["b", "c", ""] as Array[String], "CHIPS chips, the last is All")
	assert_eq(t.chips.get_child_count(), TouchControls.CHIPS)
	assert_eq((t.chips.get_child(0) as Button).text, "All", "All is the far left chip")


func test_a_chip_shows_a_face_or_a_short_name() -> void:
	var t := _touch()
	t.set_targets([_t("x"), _t("market_stall", "Shop"), _t("erin", "Talk", "erin_solstice")] as Array[Dictionary])
	var near: Button = t.chips.get_child(t.chips.get_child_count() - 1)
	assert_eq(near.text, "Marke", "no face: the first letters")
	var far: Button = t.chips.get_child(0)
	if Portrait.texture("erin_solstice") != null:
		assert_not_null(far.icon, "an NPC chip shows the face")


func test_layout_bottom_right_and_menu_top_right() -> void:
	var t := _touch()
	t.sync(true, false, false, false)
	assert_eq(t.column.get_child(t.column.get_child_count() - 1), t.context, "the context button is at the bottom")
	assert_gt(t.context.custom_minimum_size.y, TouchControls.SIZE, "and bigger than the others")
	assert_eq(t.column.anchor_top, 1.0, "the column sits on the bottom edge")
	assert_eq(t.menu_button.anchor_top, 0.0, "Menu at the top")
	assert_eq(t.menu_button.anchor_left, 1.0, "on the right")
	assert_true(t.menu_button.visible)
	t.sync(true, true, false, false)
	assert_false(t.menu_button.visible, "a panel open: Menu hides")
	assert_true(t.back.visible, "and Back shows")
	assert_eq(t.back.anchor_top, 0.0, "Back at the top right too")


func test_chips_hide_while_more_is_open() -> void:
	var t := _touch()
	t.set_targets([_t("a"), _t("b")] as Array[Dictionary])
	t.sync(true, false, false, false)
	assert_true(t.chips.visible)
	t.more.visible = true
	t.sync(true, false, false, false)
	assert_false(t.chips.visible, "the More grid uses that room")


func test_game_screen_context_opens_the_card() -> void:
	var m := _main_at("celum_square", "celum_stall")
	var t: TouchControls = m.touch
	assert_string_contains(t.context.text, "Shop", t.context.text)
	t.context.pressed.emit()
	var menu: InteractMenu = m.menu
	assert_true(menu.visible)
	assert_eq(menu.page, InteractMenu.ACTIONS, "the target's card at once")
	assert_eq(menu.rows()[0]["action"], InteractMenu.SHOP)


func test_game_screen_context_follows_the_player() -> void:
	var m := _main_at("celum_square", "celum_stall")
	var gs: GameState = _session.gs
	var t: TouchControls = m.touch
	assert_false(t.context.disabled)
	var far := Vector2i(-1, -1)
	for y in 24:
		for x in 32:
			var p := Vector2i(x, y)
			if far == Vector2i(-1, -1) and _session.db.maps.is_walkable("celum_square", p) \
					and _session.db.maps.objects_near("celum_square", p).is_empty():
				far = p
	assert_ne(far, Vector2i(-1, -1), "an empty spot")
	gs.player.place("celum_square", far)
	m._process(0.0)
	assert_true(t.context.disabled, "nothing near: the button is off")
	assert_eq(t.context.text, "-")
