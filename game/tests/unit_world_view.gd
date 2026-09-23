extends GutTest
## M4.3 presentation smoke tests: the map view, the HUD and the main scene.

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
	var main: Node = add_child_autofree(load("res://world/main.tscn").instantiate())
	main.open_use_menu()
	assert_false(main.menu.visible, "nothing to use at the start")
	session.gs.player.place("inn_interior", Vector2i(20, 2))
	main.open_use_menu()
	assert_true(main.menu.visible)
	assert_true(main.is_busy(), "no walking while the menu is open")
	var items: ItemList = main.menu.get_node("%Items")
	assert_eq(items.item_count, 4, "four stove actions")
	assert_string_contains(items.get_item_text(0), "Stove")
	items.item_activated.emit(0)
	assert_false(main.menu.visible)
	assert_eq(session.gs.action_log.records[-1]["action_id"], "cook_simple_meal")
