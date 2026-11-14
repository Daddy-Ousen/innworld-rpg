extends GutTest
## Audit W3 (ADR 0053): the full screen setting, its Options box, and F11 / Alt+Enter.
## The real window is never touched: a Callable stands in (and a headless run skips it).

const TEST_FILE := "user://test_display_settings.cfg"

var _session: Node
var _old_path: String
var _old_display: DisplaySettings
var _calls: Array = []


func before_each() -> void:
	_session = get_node_or_null("/root/Session")
	_old_path = _session.display_settings_path
	_old_display = _session.display
	DirAccess.remove_absolute(TEST_FILE)
	_session.display_settings_path = TEST_FILE
	_session.display = DisplaySettings.new()
	_calls = []
	_session.window_handler = func(on: bool) -> void: _calls.append(on)
	UiScale.mobile_override = 0
	UiScale.web_override = 0


func after_each() -> void:
	_session.display_settings_path = _old_path
	_session.display = _old_display
	_session.window_handler = Callable()
	UiScale.mobile_override = -1
	UiScale.web_override = -1
	DirAccess.remove_absolute(TEST_FILE)


func _press(action: StringName) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	Input.flush_buffered_events()
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)
	Input.flush_buffered_events()


func test_defaults_to_a_window_and_a_bad_value_reads_as_a_window() -> void:
	assert_false(DisplaySettings.load_file(TEST_FILE).fullscreen, "no file")
	var cfg := ConfigFile.new()
	cfg.set_value("display", "fullscreen", "yes")
	cfg.save(TEST_FILE)
	assert_false(DisplaySettings.load_file(TEST_FILE).fullscreen, "a bad value")


func test_save_and_load_keep_other_settings() -> void:
	var u := UiScale.new()
	u.set_mode("2.5")
	u.save(TEST_FILE)
	var d := DisplaySettings.new()
	d.fullscreen = true
	assert_eq(d.save(TEST_FILE), OK)
	assert_true(DisplaySettings.load_file(TEST_FILE).fullscreen)
	assert_eq(UiScale.load_file(TEST_FILE).mode, "2.5", "the menu size stays")


func test_session_applies_saves_and_signals() -> void:
	watch_signals(_session)
	_session.set_fullscreen(true)
	assert_eq(_calls, [true])
	assert_signal_emitted(_session, "display_changed")
	assert_true(DisplaySettings.load_file(TEST_FILE).fullscreen, "saved")
	_session.set_fullscreen(true)
	assert_eq(_calls, [true], "no change, no call")
	_session.toggle_fullscreen()
	assert_eq(_calls, [true, false])
	assert_false(DisplaySettings.load_file(TEST_FILE).fullscreen)


func test_start_applies_the_saved_setting() -> void:
	var d := DisplaySettings.new()
	d.fullscreen = true
	d.save(TEST_FILE)
	_session.load_display_settings()
	assert_true(_session.display.fullscreen)
	assert_eq(_calls, [true], "applied at start")
	DisplaySettings.new().save(TEST_FILE)
	_calls = []
	_session.load_display_settings()
	assert_eq(_calls, [], "a window: the window is left alone")


func test_a_phone_and_the_web_have_no_full_screen() -> void:
	var d := DisplaySettings.new()
	d.fullscreen = true
	d.save(TEST_FILE)
	for flags: Array in [[1, 0], [0, 1]]:
		UiScale.mobile_override = flags[0]
		UiScale.web_override = flags[1]
		assert_false(DisplaySettings.available())
		_session.load_display_settings()
		assert_false(_session.display.fullscreen, "off")
		_session.set_fullscreen(true)
		assert_false(_session.display.fullscreen)
	assert_eq(_calls, [], "the window is never touched")
	var o: OptionsMenu = add_child_autofree(load("res://ui/options_menu.tscn").instantiate())
	o.open()
	assert_false((o.get_node("%Fullscreen") as CheckBox).visible, "hidden on the web (last flags)")
	UiScale.web_override = 0
	UiScale.mobile_override = 1
	o.open()
	assert_false((o.get_node("%Fullscreen") as CheckBox).visible, "hidden on a phone OS")


func test_options_box_shows_and_toggles_it() -> void:
	var o: OptionsMenu = add_child_autofree(load("res://ui/options_menu.tscn").instantiate())
	o.open()
	var box: CheckBox = o.get_node("%Fullscreen")
	assert_true(box.visible)
	assert_false(box.button_pressed)
	box.button_pressed = true
	assert_true(_session.display.fullscreen)
	assert_eq(_calls, [true])
	_session.toggle_fullscreen()  # F11 while the panel is up
	assert_false(box.button_pressed, "the box follows")


func test_the_fullscreen_action_is_f11_and_alt_enter() -> void:
	assert_true(InputMap.has_action(&"fullscreen"))
	var keys := []
	for ev: InputEvent in InputMap.action_get_events(&"fullscreen"):
		var k := ev as InputEventKey
		keys.append([k.physical_keycode, k.alt_pressed])
	assert_eq(keys, [[KEY_F11, false], [KEY_ENTER, true]])
	_press(&"fullscreen")
	assert_eq(_calls, [true], "the action toggles it")
	_press(&"fullscreen")
	assert_eq(_calls, [true, false])


func test_f11_works_on_the_title_screen_and_with_a_panel_open() -> void:
	var t: Node = add_child_autofree(load("res://ui/title_menu.tscn").instantiate())
	_press(&"fullscreen")
	assert_eq(_calls, [true], "title screen")
	t.queue_free()
	await get_tree().process_frame
	_session.set_state(GameState.new_game(1, _session.db))
	var m: Node = load("res://world/main.tscn").instantiate()
	m.switch_scene = false
	add_child_autofree(m)
	_press(&"sheet")  # the character page is up
	_press(&"fullscreen")
	assert_eq(_calls, [true, false], "in the game with a panel open")


func test_headless_never_touches_the_window() -> void:
	_session.window_handler = Callable()
	var before := DisplayServer.window_get_mode()
	_session.set_fullscreen(true)
	assert_eq(DisplayServer.window_get_mode(), before, "headless: no window call")
	assert_true(_session.display.fullscreen, "the setting still changes")
	_session.set_fullscreen(false)


func test_the_help_page_lists_f11() -> void:
	var found := false
	for line: String in SystemMessages.KEYS:
		found = found or line.begins_with("F11")
	assert_true(found)
