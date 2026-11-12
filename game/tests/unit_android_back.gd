extends GutTest
## Audit B5 (ADR 0052): the Android Back button acts as Esc, and the game saves when the app goes to
## the background. The OS sends NOTIFICATION_WM_GO_BACK_REQUEST / NOTIFICATION_APPLICATION_PAUSED to the
## nodes under the root window; the Session autoload turns them into the `back` action and an autosave.
## Here the notification goes through `root.propagate_notification`, the way the Window sends it.

const SAVE_DIR := "user://test_saves_back"
const SEED := 20260929

var _session: Node
var _old_dir := ""
var _quits := 0


func before_each() -> void:
	_session = get_node_or_null("/root/Session")
	_old_dir = _session.save_dir
	_session.save_dir = SAVE_DIR
	_clear_saves()
	_quits = 0
	_session.quit_handler = func() -> void: _quits += 1


func after_each() -> void:
	_session.quit_handler = Callable()
	_clear_saves()
	_session.save_dir = _old_dir
	Input.action_release(&"back")


func _clear_saves() -> void:
	for slot: String in SaveSlots.all():
		SaveSlots.delete(SAVE_DIR, slot)


func _main(hour: float = 8.0, area: String = "inn_interior", at: Vector2i = Vector2i(20, 13)) -> Node:
	var gs := GameState.new_game(4, _session.db)
	gs.player.place(area, at)
	gs.npcs.npcs.clear()
	Commands.settle(gs, _session.db)
	gs.clock.total_minutes = int(hour * 60.0) + Clock.MINUTES_PER_DAY * 3
	gs.clock.awake_minutes = 0
	_session.set_state(gs)
	var m: Node = load("res://world/main.tscn").instantiate()
	m.switch_scene = false
	m.confirm_sleep = true
	add_child_autofree(m)
	m._process(0.0)
	return m


func _title() -> TitleMenu:
	var t: TitleMenu = load("res://ui/title_menu.tscn").instantiate()
	t.switch_scene = false
	return add_child_autofree(t)


## The Android Back button: the OS notification, then the queued input events.
func _back() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	Input.flush_buffered_events()


func _pause() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_APPLICATION_PAUSED)


# --- Part 1: Back on the game screen ---------------------------------------------------------


func test_back_with_nothing_open_opens_the_pause_menu() -> void:
	var m := _main()
	assert_false(m.is_busy())
	_back()
	assert_true(m.pause.visible)
	assert_eq(_quits, 0, "never quits from the game screen")


func test_back_on_the_pause_menu_closes_it() -> void:
	var m := _main()
	m.pause.open()
	_back()
	assert_false(m.pause.visible)
	assert_false(Input.is_action_pressed(&"back"), "the press is let go again")
	assert_eq(_quits, 0)


func test_back_closes_one_panel_only() -> void:
	var m := _main()
	var panels := {
		"journal": func() -> void: m.journal.open(_session.gs, _session.db),
		"bag": func() -> void: m.bag.open(_session.gs, _session.db),
		"sheet": func() -> void: m.sheet.open(_session.gs, _session.db),
		"log": func() -> void: m.message_log.open(["a line"]),
		"help": func() -> void: m.help.open(SystemMessages.KEYS),
	}
	for key: String in panels:
		(panels[key] as Callable).call()
		var panel: Control = m.get(key if key not in ["log"] else "message_log")
		assert_true(panel.visible, "%s opened" % key)
		_back()
		assert_false(panel.visible, "Back closed %s" % key)
		assert_false(m.pause.visible, "and did not open the pause menu after %s" % key)


func test_back_closes_options_and_the_slot_list_inside_the_pause_menu() -> void:
	var m := _main()
	m.pause.open()
	m.pause.open_options()
	assert_true(m.pause.options.visible)
	_back()
	assert_false(m.pause.options.visible)
	assert_true(m.pause.visible, "the pause menu stays; Back closed Options only")
	m.pause.open_save()
	assert_true(m.pause.slots.visible)
	_back()
	assert_false(m.pause.slots.visible)
	assert_true(m.pause.visible)
	m.pause.open_load()
	_back()
	assert_false(m.pause.slots.visible)
	assert_true(m.pause.visible)


func test_back_closes_a_card_and_the_shop() -> void:
	var gs := GameState.new_game(SEED, _session.db, "celum")
	_session.set_state(gs)
	gs.npcs.npcs.clear()
	var at := Interact.object_of(_session.db, "celum_square", "celum_stall")
	var pos := Vector2i(int(at["at"][0]), int(at["at"][1]))
	for d: Vector2i in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
		if _session.db.maps.is_walkable("celum_square", pos + d):
			gs.player.place("celum_square", pos + d)
			break
	gs.economy.coins = 50
	var m: Node = add_child_autofree(load("res://world/main.tscn").instantiate())
	m.switch_scene = false
	m.open_use_menu()
	assert_true(m.menu.visible, "the card opened")
	_back()
	assert_false(m.pause.visible, "Back on a card does not open the pause menu")
	for i in 3:  # a card may have a target list in front of it
		if not m.menu.visible:
			break
		_back()
	assert_false(m.menu.visible, "the card is closed")
	assert_false(m.pause.visible)
	# The shop: Back leaves it and shows the shop's card again (as Esc does).
	m.open_use_menu()
	var menu: InteractMenu = m.menu
	if menu.page == InteractMenu.TARGETS:
		for i in menu.rows().size():
			if menu.rows()[i]["object"] == "celum_stall":
				menu.pick(i)
				break
	for i in menu.rows().size():
		if menu.rows()[i]["action"] == InteractMenu.SHOP:
			menu.pick(i)
			break
	assert_true(m.shop.visible)
	_back()
	assert_false(m.shop.visible, "Back closed the shop")
	assert_false(m.pause.visible, "and did not open the pause menu")


func test_back_answers_the_sleep_question_with_stay_awake() -> void:
	var m := _main(8.0)
	var before: int = _session.gs.clock.total_minutes
	m._unhandled_input(_press(&"sleep"))
	assert_true(m.menu.visible, "the sleep question is up")
	_back()
	assert_false(m.menu.visible)
	assert_false(m.pause.visible)
	assert_eq(_session.gs.clock.total_minutes, before, "nothing changed")


func test_back_closes_the_rest_panel() -> void:
	var m := _main(8.0)
	var before: int = _session.gs.clock.total_minutes
	m.open_rest()
	assert_true(m.menu.visible, "the Rest panel is up")
	_back()
	assert_false(m.menu.visible)
	assert_false(m.pause.visible)
	assert_eq(_session.gs.clock.total_minutes, before)


func test_back_answers_the_long_road_question_with_stay() -> void:
	var m := _main()
	m.travel.ask("Here", "There", 600)
	assert_true(m.travel.visible)
	assert_true(m.is_busy())
	_back()
	assert_false(m.travel.visible, "Back said no to the long road")
	assert_false(m.pause.visible)


func test_back_does_not_throw_away_a_class_offer() -> void:
	var m := _main()
	var db: DataDb = _session.db
	var class_id: String = db.classes.keys()[0]
	_session.gs.progression.offers.append({"class": class_id, "kind": ClassSystem.KIND_NEW, "day": 1})
	m.dialog.open(SystemMessages.offer_pages(_session.gs, db), _session.gs, db)
	assert_true(m.dialog.visible)
	_back()
	assert_true(m.dialog.visible, "the offer waits for Accept or Decline")
	assert_true(_session.gs.progression.has_offer(class_id))
	assert_false(m.pause.visible)


func test_back_lets_an_armed_skill_go() -> void:
	var m := _main()
	m.aim.armed = "slash"
	_back()
	assert_eq(m.aim.armed, "", "the skill is let go")
	assert_false(m.pause.visible, "and the pause menu stays shut")
	_back()
	assert_true(m.pause.visible, "the next Back opens it")


# --- Part 1: Back on the title screen ---------------------------------------------------------


func test_title_back_closes_who_are_you() -> void:
	var t := _title()
	t.open_create("")
	assert_true(t.create_box.visible)
	_back()
	assert_false(t.create_box.visible)
	assert_true(t.at_root() or t._starts.visible, "back at the menu or the start list")
	assert_eq(_quits, 0)


func test_title_back_closes_the_start_list() -> void:
	var t := _title()
	t._show_starts(true)
	assert_true(t._starts.visible)
	_back()
	assert_false(t._starts.visible)
	assert_true(t.at_root())
	assert_eq(_quits, 0)


func test_title_back_closes_options_and_the_load_list() -> void:
	var t := _title()
	t.open_options()
	assert_true(t.options.visible)
	_back()
	assert_false(t.options.visible)
	assert_true(t.at_root())
	t.slots.open(SlotList.LOAD, SAVE_DIR, _session.db)
	assert_true(t.slots.visible)
	_back()
	assert_false(t.slots.visible)
	assert_eq(_quits, 0, "a sub-page never quits the app")


func test_title_root_back_quits_through_the_hook() -> void:
	var t := _title()
	assert_true(t.at_root())
	_back()
	assert_eq(_quits, 1, "the root menu quits (the normal Android rule)")


func test_the_hook_defaults_to_quit() -> void:
	_session.quit_handler = Callable()
	assert_false(_session.quit_handler.is_valid(), "tests replace it; the real one calls get_tree().quit()")


func _press(action: StringName) -> InputEventAction:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	return ev


# --- Part 2: save when the app is paused ------------------------------------------------------


func test_pause_saves_the_autosave_on_the_game_screen() -> void:
	var m := _main(14.0)
	assert_false(SaveSlots.exists(SAVE_DIR, SaveSlots.AUTOSAVE))
	_pause()
	assert_true(SaveSlots.exists(SAVE_DIR, SaveSlots.AUTOSAVE), "the autosave was written")
	var loaded := SaveSlots.load_game(SAVE_DIR, SaveSlots.AUTOSAVE, _session.db)
	assert_not_null(loaded)
	assert_eq(loaded.clock.day(), _session.gs.clock.day())
	assert_eq(loaded.clock.total_minutes, _session.gs.clock.total_minutes)
	assert_eq(loaded.clock.time_string(), "14:00")
	assert_not_null(m)


func test_a_second_pause_overwrites_it() -> void:
	var m := _main(14.0)
	_pause()
	Commands.wait(_session.gs, _session.db, 3600)
	var later: int = _session.gs.clock.total_minutes
	_pause()
	var loaded := SaveSlots.load_game(SAVE_DIR, SaveSlots.AUTOSAVE, _session.db)
	assert_eq(loaded.clock.total_minutes, later, "the newer state replaced the older one")
	assert_not_null(m)


func test_pause_on_the_title_screen_saves_nothing() -> void:
	_title()
	_pause()
	assert_false(SaveSlots.exists(SAVE_DIR, SaveSlots.AUTOSAVE))


func test_pause_before_any_screen_saves_nothing() -> void:
	_pause()
	assert_false(SaveSlots.exists(SAVE_DIR, SaveSlots.AUTOSAVE))


func test_pause_after_the_game_screen_left_saves_nothing() -> void:
	var m := _main()
	m.free()
	_pause()
	assert_false(SaveSlots.exists(SAVE_DIR, SaveSlots.AUTOSAVE), "the game screen is gone")


func test_a_failed_save_does_not_crash() -> void:
	var m := _main()
	_session.save_dir = "user://test_saves_back/blocked.json/inside"  # a file stands where a folder must be
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var f := FileAccess.open(SAVE_DIR + "/blocked.json", FileAccess.WRITE)
	f.store_string("x")
	f.close()
	_pause()  # logs a warning, returns
	assert_engine_error("Could not create directory")  # the failing save's own log line
	assert_push_warning("Save on pause failed")
	assert_not_null(m)
	assert_true(is_instance_valid(m))
	DirAccess.remove_absolute(SAVE_DIR + "/blocked.json")


func test_pause_during_the_night_dialog_saves_the_morning() -> void:
	var m := _main(21.0)
	var day: int = _session.gs.clock.day()
	m.sleep_now()
	assert_true(m.dialog.visible, "the night's System dialog is up")
	_pause()
	var loaded := SaveSlots.load_game(SAVE_DIR, SaveSlots.AUTOSAVE, _session.db)
	assert_eq(loaded.clock.day(), day + 1, "the saved game is already in the morning")
	assert_eq(loaded.clock.time_string(), "06:00")


func test_pause_during_the_long_road_walk_saves_the_start_of_the_road() -> void:
	var m := _main()
	var area: String = _session.gs.player.area
	var minutes: int = _session.gs.clock.total_minutes
	m.travel.ask("Here", "There", 600)  # the walk has not made the step yet
	_pause()
	var loaded := SaveSlots.load_game(SAVE_DIR, SaveSlots.AUTOSAVE, _session.db)
	assert_eq(loaded.player.area, area)
	assert_eq(loaded.clock.total_minutes, minutes, "the move is made only when the walk ends")
