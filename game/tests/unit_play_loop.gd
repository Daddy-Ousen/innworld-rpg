extends GutTest
## M6.1 play loop (ADR 0011): title menu, pause menu (Esc), journal key,
## welcome page, autosave. Saves go to the test folder (gut_pre_run.gd).

var _session: Node


func before_each() -> void:
	_session = get_node_or_null("/root/Session")
	if _session != null:
		for slot: String in SaveSlots.all():
			SaveSlots.delete(_session.save_dir, slot)


func _press(node: Node, code: Key) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	ev.keycode = code
	ev.pressed = true
	node._unhandled_input(ev)


func _title() -> TitleMenu:
	var t: TitleMenu = load("res://ui/title_menu.tscn").instantiate()
	t.switch_scene = false
	return add_child_autofree(t)


func _main() -> Node:
	var m: Node = load("res://world/main.tscn").instantiate()
	m.switch_scene = false
	return add_child_autofree(m)


func test_tests_save_to_the_test_folder() -> void:
	assert_not_null(_session, "Session autoload")
	assert_eq(_session.save_dir, "user://test_saves")


func test_title_without_saves_offers_only_a_new_game() -> void:
	var t := _title()
	assert_true(t.get_node("%Continue").disabled)
	assert_true(t.get_node("%Load").disabled)
	assert_false(t.get_node("%NewGame").disabled)


func test_title_new_game_starts_fresh_with_the_seed() -> void:
	var t := _title()
	t.new_game_seed = 42
	watch_signals(t)
	t.new_game()
	assert_signal_emitted(t, "entered_game")
	assert_eq(_session.gs.rng.to_dict()["seed"], "42")
	assert_eq(_session.gs.clock.day(), 8)
	assert_true(_session.fresh)


func test_title_continue_loads_the_newest_save() -> void:
	var gs := GameState.new_game(9, _session.db)
	gs.clock.advance(90)
	SaveSlots.save(gs, _session.save_dir, "2")
	var t := _title()
	assert_false(t.get_node("%Continue").disabled)
	_session.set_state(GameState.new_game(1, _session.db))
	watch_signals(t)
	t.continue_game()
	assert_signal_emitted(t, "entered_game")
	assert_eq(_session.gs.to_json(), SaveSlots.load_game(_session.save_dir, "2", _session.db).to_json())
	assert_false(_session.fresh, "a loaded game gets no welcome page")


func test_title_load_list_greys_out_empty_slots() -> void:
	SaveSlots.save(GameState.new_game(1, _session.db), _session.save_dir, "1")
	var entries := SlotList.entries(SlotList.LOAD, _session.save_dir, _session.db)
	assert_eq(entries.size(), 4)
	assert_false(entries[0]["disabled"])
	assert_true(entries[1]["disabled"])
	assert_true(entries[3]["disabled"], "no autosave yet")
	assert_eq(SlotList.entries(SlotList.SAVE, _session.save_dir, _session.db).size(), 3, "no saving over the autosave")


func test_new_game_opens_the_welcome_page_then_autosaves() -> void:
	_session.start_new_game(3)
	var main := _main()
	var dialog: SystemDialog = main.dialog
	assert_true(dialog.visible)
	assert_eq(dialog.current["kind"], SystemMessages.WELCOME)
	assert_false(_session.fresh)
	dialog.choose(SystemMessages.NEXT)
	assert_false(main.is_busy())
	assert_true(SaveSlots.exists(_session.save_dir, SaveSlots.AUTOSAVE), "autosave when the dialog closes")


func test_escape_opens_the_pause_menu_and_saves_and_loads() -> void:
	_session.set_state(GameState.new_game(4, _session.db))
	var main := _main()
	assert_false(main.dialog.visible, "no welcome page for a game that is not fresh")
	_press(main, KEY_ESCAPE)
	var pause: PauseMenu = main.pause
	assert_true(pause.visible)
	assert_true(main.is_busy())
	var saved: String = _session.gs.to_json()
	assert_true(pause.save_to("1"))
	assert_false(pause.visible)
	assert_string_contains(main.hud.get_node("%Log").text, "Saved to slot 1.")
	Commands.wait(_session.gs, _session.db, 3600)
	pause.open()
	assert_true(pause.load_from("1"))
	assert_eq(_session.gs.to_json(), SaveSlots.load_game(_session.save_dir, "1", _session.db).to_json())
	assert_eq(_session.gs.clock.day(), 8)
	assert_eq(_session.gs.clock.time_string(), "06:00", "back to the saved time")
	assert_eq(JSON.parse_string(saved)["clock"], JSON.parse_string(_session.gs.to_json())["clock"])


func test_escape_closes_the_pause_menu() -> void:
	_session.set_state(GameState.new_game(4, _session.db))
	var main := _main()
	main.pause.open()
	_press(main.pause, KEY_ESCAPE)
	assert_false(main.pause.visible)
	assert_false(main.is_busy())


func test_pause_save_list_and_back() -> void:
	_session.set_state(GameState.new_game(4, _session.db))
	var main := _main()
	var pause: PauseMenu = main.pause
	pause.open()
	pause.open_save()
	assert_true(pause.slots.visible)
	assert_false(pause.get_node("%Panel").visible)
	_press(pause.slots, KEY_ESCAPE)
	assert_false(pause.slots.visible)
	assert_true(pause.get_node("%Panel").visible, "Esc in the slot list goes back to the menu")
	assert_true(pause.visible)


func test_quit_to_title_autosaves() -> void:
	_session.set_state(GameState.new_game(4, _session.db))
	var main := _main()
	main.pause.open()
	main.pause.quit_to_title()
	assert_true(SaveSlots.exists(_session.save_dir, SaveSlots.AUTOSAVE))
	assert_false(main.pause.visible)


func test_j_opens_the_journal() -> void:
	_session.set_state(GameState.new_game(4, _session.db))
	var main := _main()
	_press(main, KEY_J)
	assert_true(main.journal.visible)
	assert_true(main.is_busy())
	_press(main.journal, KEY_J)
	assert_false(main.journal.visible)


func test_welcome_page_has_the_hints() -> void:
	var p := SystemMessages.welcome_page()
	assert_eq(p["kind"], SystemMessages.WELCOME)
	assert_eq(p["choices"], [SystemMessages.NEXT] as Array[String])
	for h: String in SystemMessages.HINTS:
		assert_has(p["lines"], h)
