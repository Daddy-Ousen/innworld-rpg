extends GutTest
## M4.3 presentation smoke tests: the map view, the HUD and the main scene.
## M5.3: monster markers, HP in the HUD, combat keys and the knock-out.

var _db: DataDb


func before_all() -> void:
	_db = ToyMaps.db()


func _view() -> WorldView:
	var v: WorldView = add_child_autofree(load("res://world/world_view.tscn").instantiate())
	v.setup(_db.maps)
	return v


func test_tile_set_has_one_tile_per_tile_type() -> void:
	var atlas := {}
	var ts := WorldView.make_tile_set(_db.maps.tiles, atlas)
	assert_eq(atlas.size(), _db.maps.tiles.size())
	var source: TileSetAtlasSource = ts.get_source(0)
	for id: String in atlas:
		assert_true(source.has_tile(atlas[id]), id)


func test_cells_match_the_map() -> void:
	var v := _view()
	var gs := ToyMaps.new_game(_db)
	v.refresh(gs)
	assert_eq(v.area, "town")
	for y in 5:
		for x in 8:
			var cell := Vector2i(x, y)
			assert_eq(v.tiles.get_cell_atlas_coords(cell), v.atlas[_db.maps.tile_at("town", cell)],
					"cell %s" % cell)
	assert_eq(v.tiles.get_used_cells().size(), 40)


func test_player_marker_follows_the_player() -> void:
	var v := _view()
	var gs := ToyMaps.new_game(_db)
	v.refresh(gs)
	assert_eq(v.player.position, Vector2(1 * 16 + 8, 2 * 16 + 8))
	Commands.move(gs, _db, "e")
	v.refresh(gs)
	assert_eq(v.player.position, Vector2(2 * 16 + 8, 2 * 16 + 8))


func test_area_change_redraws() -> void:
	var v := _view()
	var gs := ToyMaps.new_game(_db)
	v.refresh(gs)
	gs.player.place("town", Vector2i(6, 2))
	Commands.move(gs, _db, "s")  # the shop door
	v.refresh(gs)
	assert_eq(v.area, "shop")
	assert_eq(v.tiles.get_used_cells().size(), 9)
	assert_eq(v.camera.limit_right, 3 * 16)


func test_hud_warns_when_tired() -> void:
	var gs := ToyMaps.new_game(_db)
	assert_eq(Hud.warning(gs, _db), "")
	gs.clock.awake_minutes = int(_db.rules["clock"]["collapse_after_awake"]) - 90
	assert_string_contains(Hud.warning(gs, _db), "collapse in 1h 30m")
	gs.clock.awake_minutes += 90
	assert_string_contains(Hud.warning(gs, _db), "cannot stay awake")


func test_hud_shows_day_time_and_place() -> void:
	var hud: Hud = add_child_autofree(load("res://ui/hud.tscn").instantiate())
	var real := DataDb.load_dir()
	var gs := GameState.new_game(1, real)
	hud.refresh(gs, real)
	var text: String = hud.get_node("%Status").text
	assert_string_contains(text, "Day 8")
	assert_string_contains(text, "06:00")
	assert_string_contains(text, "Liscor east gate")
	for i in 8:
		hud.add_lines(["line %d" % i])
	assert_eq((hud.get_node("%Log").text as String).split("\n").size(), Hud.LOG_LINES)


func test_main_scene_walks_uses_and_sleeps() -> void:
	var session := get_node_or_null("/root/Session")
	assert_not_null(session, "Session autoload")
	if session == null:
		return
	session.set_state(GameState.new_game(1, session.db))
	var main: Node = add_child_autofree(load("res://world/main.tscn").instantiate())
	var view: WorldView = main.get_node("WorldView")
	assert_eq(view.area, "liscor_gate")
	main.step("w")
	assert_eq(session.gs.player.pos(), Vector2i(2, 12))
	assert_eq(view.player.position, WorldView.cell_center(Vector2i(2, 12)))
	session.gs.player.place("inn_interior", Vector2i(20, 2))
	main.use("stove", "cook_stew")
	assert_eq(view.area, "inn_interior", "redrawn after the command")
	assert_eq(session.gs.action_log.records[-1]["action_id"], "cook_stew")
	main.sleep()
	assert_eq(session.gs.clock.day(), 9)
	assert_string_contains(main.hud.get_node("%Log").text, "You sleep")


func test_console_overlay_updates_the_session() -> void:
	var session := get_node_or_null("/root/Session")
	if session == null:
		fail_test("no Session autoload")
		return
	var main: Node = add_child_autofree(load("res://world/main.tscn").instantiate())
	main.toggle_console()
	assert_true(main.is_busy())
	var input: LineEdit = main.console_input
	input.text_submitted.emit("new 5")
	assert_eq(session.gs.rng.to_dict()["seed"], "5", "the console's new game is the session's game")
	input.text_submitted.emit("go w x3")
	assert_eq(main.get_node("WorldView").area, "liscor_market")
	main.toggle_console()
	assert_false(main.is_busy())


func _key(code: Key, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	ev.keycode = code
	ev.pressed = pressed
	Input.parse_input_event(ev)
	Input.flush_buffered_events()


func test_held_key_walks_and_repeats() -> void:
	var session := get_node_or_null("/root/Session")
	if session == null:
		fail_test("no Session autoload")
		return
	session.set_state(GameState.new_game(1, session.db))
	var main: Node = add_child_autofree(load("res://world/main.tscn").instantiate())
	_key(KEY_D, true)
	main._process(0.0)
	assert_eq(session.gs.player.pos(), Vector2i(4, 12), "first step at once")
	main._process(0.05)
	assert_eq(session.gs.player.pos(), Vector2i(4, 12), "waits for the repeat time")
	main._process(0.1)
	assert_eq(session.gs.player.pos(), Vector2i(5, 12))
	_key(KEY_D, false)
	main._process(0.5)
	assert_eq(session.gs.player.pos(), Vector2i(5, 12))


func test_use_menu_lists_and_uses() -> void:
	var session := get_node_or_null("/root/Session")
	if session == null:
		fail_test("no Session autoload")
		return
	session.set_state(GameState.new_game(1, session.db))
	session.gs.npcs.npcs.clear()  # objects only here; NPC talk is in unit_npc_sim
	var main: Node = add_child_autofree(load("res://world/main.tscn").instantiate())
	main.open_use_menu()
	assert_false(main.menu.visible, "nothing to use at the start")
	session.gs.player.place("inn_interior", Vector2i(20, 2))
	main.open_use_menu()
	assert_true(main.menu.visible)
	assert_true(main.is_busy(), "no walking while the menu is open")
	var items: ItemList = main.menu.get_node("%Items")
	assert_eq(items.item_count, 5, "four stove actions and Take Rolling pin")
	assert_string_contains(items.get_item_text(4), "Take Rolling pin")
	assert_string_contains(items.get_item_text(0), "Stove")
	items.item_activated.emit(0)
	assert_false(main.menu.visible)
	assert_eq(session.gs.action_log.records[-1]["action_id"], "cook_simple_meal")


func test_npc_markers_with_names() -> void:
	var d := ToyNpcs.db()
	var v: WorldView = add_child_autofree(load("res://world/world_view.tscn").instantiate())
	v.setup(d.maps, {"guard": "Guard"})
	var gs := ToyNpcs.new_game(d)
	v.refresh(gs)
	assert_eq(v.npcs.get_child_count(), 1, "only the guard is in town")
	var marker: Node2D = v.npcs.get_child(0)
	assert_eq(String(marker.name), "guard")
	assert_eq(marker.position, WorldView.cell_center(Vector2i(1, 1)))
	assert_eq((marker.get_child(1) as Label).text, "Guard")
	gs.player.place("field", Vector2i(3, 2))
	v.refresh(gs)
	assert_eq(v.npcs.get_child_count(), 1)
	assert_eq(String(v.npcs.get_child(0).name), "farmer")
	assert_eq((v.npcs.get_child(0).get_child(1) as Label).text, "farmer", "no name given: the id")


func test_space_waits_and_bumping_an_npc_says_who() -> void:
	var session := get_node_or_null("/root/Session")
	if session == null:
		fail_test("no Session autoload")
		return
	session.set_state(GameState.new_game(1, session.db))
	var main: Node = add_child_autofree(load("res://world/main.tscn").instantiate())
	var before: int = NpcSim.world_sec(session.gs)
	main.step(main.WAIT)
	assert_eq(NpcSim.world_sec(session.gs), before + 6, "one step of time")
	session.gs.player.place("liscor_gate", Vector2i(3, 13))  # Beilmark stands at 2,13
	main.step("w")
	main.step("w")
	var log_text: String = main.hud.get_node("%Log").text
	assert_string_contains(log_text, "Beilmark is in the way.")
	assert_eq(log_text.count("in the way"), 1, "said once")


func test_monster_markers_show_name_and_hp_and_hide_crabs() -> void:
	var d := ToyCombat.db()
	ToyCombat.freeze(d)
	ToyCombat.always_hit(d)
	var v: WorldView = add_child_autofree(load("res://world/world_view.tscn").instantiate())
	v.setup(d.maps, {}, d.combat.enemies)
	var gs := ToyCombat.new_game(d)
	ToyCombat.to_arena(gs, d, Vector2i(3, 7))
	var goblin := ToyCombat.spawn(gs, d, "goblin", Vector2i(4, 7))
	var crab := ToyCombat.spawn(gs, d, "crab", Vector2i(10, 1), CombatState.HIDDEN)
	v.refresh(gs)
	assert_eq(v.monsters.get_child_count(), 2)
	var g: Node2D = v.monsters.get_node(goblin)
	assert_eq(g.position, WorldView.cell_center(Vector2i(4, 7)))
	assert_eq((g.get_child(0) as ColorRect).color, WorldView.HOSTILE_EDGE)
	assert_eq((g.get_child(2) as ColorRect).color, Color.html("#00aa00"), "the enemy colour")
	assert_eq((g.get_child(3) as Label).text, "Goblin 8/8")
	var c: Node2D = v.monsters.get_node(crab)
	assert_eq(c.get_child_count(), 2, "a rock tile, no label")
	for child in c.get_children():
		assert_false(child is Label)
	Commands.attack(gs, d, "e")
	v.refresh(gs)
	var hp := int(gs.combat.monsters[goblin]["hp"])
	assert_lt(hp, 8)
	assert_eq((v.monsters.get_node(goblin).get_child(3) as Label).text, "Goblin %d/8" % hp)
	gs.combat.monsters[goblin]["state"] = CombatState.FLEE
	v.refresh(gs)
	assert_eq((v.monsters.get_node(goblin).get_child(0) as ColorRect).color, WorldView.FLEE_EDGE)


func test_hud_shows_hp_and_the_held_item() -> void:
	var real := DataDb.load_dir()
	var gs := GameState.new_game(1, real)
	assert_eq(Hud.health(gs, real), "HP 20/20 · Held: nothing")
	assert_false(Hud.is_low(gs, real))
	var hud: Hud = add_child_autofree(load("res://ui/hud.tscn").instantiate())
	hud.refresh(gs, real)
	var label: Label = hud.get_node("%Health")
	assert_false(label.has_theme_color_override("font_color"))
	gs.player.held = "chair"
	Combat.set_hp(gs, real, 5)
	assert_eq(Hud.health(gs, real), "HP 5/20 · Held: Chair")
	assert_true(Hud.is_low(gs, real), "5 of 20 is 25%")
	hud.refresh(gs, real)
	assert_eq(label.text, "HP 5/20 · Held: Chair")
	assert_eq(label.get_theme_color("font_color"), Hud.WARN_COLOR)
	Combat.set_hp(gs, real, 6)
	assert_false(Hud.is_low(gs, real))


## A new game on the Floodplains at `pos`, `minutes` after the start, with
## no monsters, and every spawn on its cooldown (the test places its own).
func _floodplains(session: Node, pos: Vector2i, minutes: int = 0) -> GameState:
	var gs := GameState.new_game(1, session.db)
	gs.clock.advance(minutes)
	gs.player.place("floodplains_south", pos)
	Commands.settle(gs, session.db)
	gs.combat.monsters.clear()
	gs.combat.fight = {}
	for s: Dictionary in session.db.combat.spawns:
		gs.combat.spawn_last[s["id"]] = gs.clock.total_minutes
	session.set_state(gs)
	return gs


func _log(main: Node) -> String:
	return main.hud.get_node("%Log").text


func test_bump_attacks_once_per_key_press() -> void:
	var session := get_node_or_null("/root/Session")
	if session == null:
		fail_test("no Session autoload")
		return
	var gs := _floodplains(session, Vector2i(14, 9))
	var main: Node = add_child_autofree(load("res://world/main.tscn").instantiate())
	var goblin: String = Commands.spawn_monster(gs, session.db, "goblin_grunt", Vector2i(15, 9))["id"]
	main._redraw()
	assert_eq(main.view.monsters.get_child_count(), 1, "the goblin is on the map")
	_key(KEY_D, true)
	main._process(0.0)
	assert_eq(int(gs.combat.fight["attacks"]), 1, "a bump attacks")
	assert_eq(gs.player.pos(), Vector2i(14, 9), "and does not move")
	assert_string_contains(_log(main), "Goblin")
	main._process(0.2)
	main._process(0.2)
	assert_eq(int(gs.combat.fight["attacks"]), 1, "holding the key does not attack again")
	_key(KEY_D, false)
	main._process(0.0)
	_key(KEY_D, true)
	main._process(0.0)
	_key(KEY_D, false)
	if gs.combat.monsters.has(goblin) and gs.combat.monsters[goblin]["state"] == CombatState.HOSTILE:
		assert_eq(int(gs.combat.fight["attacks"]), 2, "a new press attacks again")
	else:
		fail_test("the goblin left: %s" % [gs.combat.monsters.get(goblin)])


func test_take_block_throw_and_drop_keys() -> void:
	var session := get_node_or_null("/root/Session")
	if session == null:
		fail_test("no Session autoload")
		return
	var gs := _floodplains(session, Vector2i(14, 9))  # the loose stones are at 13,9
	var main: Node = add_child_autofree(load("res://world/main.tscn").instantiate())
	main.open_use_menu()
	var items: ItemList = main.menu.get_node("%Items")
	assert_eq(items.item_count, 1)
	assert_eq(items.get_item_text(0), "Loose stones — Take Stone")
	items.item_activated.emit(0)
	assert_eq(gs.player.held, "stone")
	assert_string_contains(main.hud.get_node("%Health").text, "Held: Stone")
	main.throw()
	assert_string_contains(_log(main), "There is nothing to throw at.")
	assert_eq(gs.player.held, "stone")
	Commands.spawn_monster(gs, session.db, "goblin_grunt", Vector2i(16, 9))
	main.block()
	assert_string_contains(_log(main), "You raise your guard.")
	main.throw()
	assert_eq(gs.player.held, "", "thrown")
	assert_eq(int(gs.combat.fight["throws"]), 1)
	main.drop()
	assert_string_contains(_log(main), "You hold nothing.")
	main.use("loose_stones_1", Interact.TAKE)
	main.drop()
	assert_string_contains(_log(main), "You put the stone down.")
	assert_eq(gs.player.held, "")


func test_a_knock_out_ends_the_day_and_opens_its_page() -> void:
	var session := get_node_or_null("/root/Session")
	if session == null:
		fail_test("no Session autoload")
		return
	var gs := _floodplains(session, Vector2i(14, 9), 14 * 60)  # 20:00, not a nap
	var main: Node = add_child_autofree(load("res://world/main.tscn").instantiate())
	Combat.set_hp(gs, session.db, 1)
	Commands.spawn_monster(gs, session.db, "goblin_grunt", Vector2i(15, 9))
	for i in 100:
		if main.dialog.visible:
			break
		main.step(main.WAIT)
	assert_true(main.dialog.visible, "the System speaks")
	assert_eq(main.dialog.current["kind"], SystemMessages.KNOCKOUT)
	assert_eq(session.gs.clock.day(), 9)
	assert_eq(session.gs.player.area, "inn_interior")
	assert_string_contains(_log(main), "Everything goes dark.")
	assert_true(main.is_busy())


func test_big_fights_label_few_monsters_and_show_bars() -> void:
	var d := ToyCombat.db()
	ToyCombat.freeze(d)
	d.combat.enemies["goblin"]["danger"] = 0.5
	var v: WorldView = add_child_autofree(load("res://world/world_view.tscn").instantiate())
	v.setup(d.maps, {}, d.combat.enemies)
	var gs := ToyCombat.new_game(d)
	ToyCombat.to_arena(gs, d, Vector2i(0, 4))
	var gobs: Array[String] = []
	for x in range(3, 11):
		gobs.append(ToyCombat.spawn(gs, d, "goblin", Vector2i(x, 1)))
	var boss := ToyCombat.spawn(gs, d, "crab", Vector2i(12, 7), CombatState.IDLE)
	var helper := ToyCombat.spawn(gs, d, "goblin", Vector2i(1, 4), CombatState.ALLY)
	var named := WorldView.labelled(gs, d.combat.enemies)
	assert_eq(named.size(), 5, "the crab (most dangerous), the helper and the 3 nearest goblins")
	assert_true(named.has(boss))
	assert_true(named.has(helper))
	for id in gobs.slice(0, 3):
		assert_true(named.has(id), id)
	v.refresh(gs)
	var far: Node2D = v.monsters.get_node(gobs[7])
	for child in far.get_children():
		assert_false(child is Label, "a far goblin has no label")
	assert_eq(far.get_child_count(), 5, "edge, ring, body and the HP bar (back, fill)")
	var h: Node2D = v.monsters.get_node(helper)
	assert_eq((h.get_child(0) as ColorRect).color, WorldView.ALLY_EDGE)


func test_a_fallen_npc_is_faded_and_a_hurt_one_has_a_bar() -> void:
	var d := ToyNpcs.db()
	var v: WorldView = add_child_autofree(load("res://world/world_view.tscn").instantiate())
	v.setup(d.maps, {"guard": "Guard"}, {}, {"guard": 20})
	var gs := ToyNpcs.new_game(d)
	v.refresh(gs)
	var g: Node2D = v.npcs.get_node("guard")
	assert_eq(g.get_child_count(), 2, "full HP: no bar")
	gs.npcs.npcs["guard"]["hp"] = 5
	v.refresh(gs)
	g = v.npcs.get_node("guard")
	assert_eq(g.get_child_count(), 4, "hurt: body, label and the bar")
	assert_eq((g.get_child(3) as ColorRect).color, WorldView.BAR_LOW_FILL)
	gs.npcs.npcs["guard"]["hp"] = 0
	gs.npcs.npcs["guard"]["down"] = true
	v.refresh(gs)
	g = v.npcs.get_node("guard")
	assert_eq((g.get_child(1) as Label).text, "Guard (down)")
	assert_almost_eq((g.get_child(0) as ColorRect).color.a, WorldView.DOWN_ALPHA, 0.001)


func test_hud_counts_the_foes_left_in_a_staged_fight() -> void:
	var real := DataDb.load_dir()
	var gs := GameState.new_game(1, real)
	gs.combat.stage_run = {"event": "b1.klbkch_dies_defending_erin", "start": 0, "next": 0}
	var waves: Array = real.canon.events["b1.klbkch_dies_defending_erin"]["stage"].get("waves", [])
	var total := 0
	for w: Dictionary in waves:
		total += (w.get("foes", []) as Array).size()
	assert_eq(Hud.health(gs, real), "HP 20/20 · Held: nothing · Foes left: %d" % total)
