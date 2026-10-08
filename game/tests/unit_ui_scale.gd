extends GutTest
## M20.3 UI scale (ADR 0033): the Auto rule, the modes and the settings file,
## the panel fit, and the map and touch pad keeping their size under a bigger
## UI (user, 2026-10-05). Headless has no touch screen, so Auto is 1 here.

const TEST_FILE := "user://test_ui_scale.cfg"

var _session: Node


func before_each() -> void:
	_session = get_node_or_null("/root/Session")


func after_each() -> void:
	_session.set_ui_scale_mode(UiScale.AUTO)
	_session.set_touch_mode(TouchSettings.AUTO)


func _main() -> Node:
	_session.set_state(GameState.new_game(1, _session.db))
	var m: Node = load("res://world/main.tscn").instantiate()
	m.switch_scene = false
	add_child_autofree(m)
	return m


func test_auto_is_big_only_on_a_phone() -> void:
	assert_eq(UiScale.auto_factor(1080, 400, true), UiScale.BIG, "a phone: 2.7 in")
	assert_eq(UiScale.auto_factor(1080, 96 * 2.75, true), UiScale.BIG, "a phone browser: about 4 in")
	assert_eq(UiScale.auto_factor(1536, 192, true), 1.0, "a tablet: 8 in")
	assert_eq(UiScale.auto_factor(1080, 400, false), 1.0, "no touch screen: never big")
	assert_eq(UiScale.auto_factor(648, 96, false), 1.0, "a small desktop window")
	assert_eq(UiScale.auto_factor(1080, 0, true), 1.0, "no dpi: 1")


func test_mobile_os_is_bigger_and_see_through() -> void:
	var s := UiScale.new()
	assert_eq(s.factor(1080, 96, false, true), UiScale.MOBILE, "a phone OS: Auto is MOBILE, any dpi")
	assert_eq(s.factor(1080, 96, false, false), 1.0, "not mobile: unchanged")
	s.set_mode("1")
	assert_eq(s.factor(1080, 96, false, true), 1.0, "a fixed mode still wins")
	var theme := Theme.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.2, 0.2, 0.2, 0.96)
	theme.set_stylebox("panel", "PanelContainer", box)
	UiScale.set_box_alpha(theme, UiScale.MOBILE_ALPHA)
	UiScale.set_box_alpha(theme, UiScale.MOBILE_ALPHA)
	assert_almost_eq(box.bg_color.a, 0.96 * UiScale.MOBILE_ALPHA, 0.001, "twice is the same as once")
	UiScale.set_box_alpha(theme, 1.0)
	assert_almost_eq(box.bg_color.a, 0.96, 0.001, "1.0 restores the first alpha")


func test_modes_and_bad_values() -> void:
	var s := UiScale.new()
	assert_eq(s.factor(1080, 400, true), UiScale.BIG, "Auto follows the screen")
	s.set_mode("1.5")
	assert_eq(s.factor(1080, 400, true), 1.5)
	s.set_mode("1")
	assert_eq(s.factor(1080, 400, true), 1.0, "a fixed mode wins over Auto's rule")
	s.set_mode("3")
	assert_eq(s.mode, UiScale.AUTO, "an unknown mode reads as Auto")


func test_save_and_load_keep_other_settings() -> void:
	DirAccess.remove_absolute(TEST_FILE)
	assert_eq(UiScale.load_file(TEST_FILE).mode, UiScale.AUTO, "Auto when there is no file")
	var t := TouchSettings.new()
	t.set_mode(TouchSettings.ON)
	t.save(TEST_FILE)
	var s := UiScale.new()
	s.set_mode("2")
	assert_eq(s.save(TEST_FILE), OK)
	assert_eq(UiScale.load_file(TEST_FILE).mode, "2")
	assert_eq(TouchSettings.load_file(TEST_FILE).mode, TouchSettings.ON, "the touch mode stays")
	DirAccess.remove_absolute(TEST_FILE)


func test_a_panel_is_cut_to_a_small_view() -> void:
	assert_eq(UiScale.fitted(Vector2(600, 600), Vector2(1152, 648)), Vector2(600, 600), "room: design size")
	assert_eq(UiScale.fitted(Vector2(600, 600), Vector2(720, 324)), Vector2(600, 308), "a phone at 200%")
	assert_eq(UiScale.fitted(Vector2(600, 600), Vector2(10, 10)), Vector2.ZERO)


func test_the_map_keeps_its_size() -> void:
	assert_eq(UiScale.camera_zoom(1.0), 2.0, "as world_view.tscn")
	assert_eq(UiScale.camera_zoom(2.0), 1.0)
	assert_eq(UiScale.camera_zoom(1.5), 2.0 / 1.5)


func test_a_bigger_ui_keeps_the_map_and_the_pad() -> void:
	var m := _main()
	_session.set_touch_mode(TouchSettings.ON)
	watch_signals(_session)
	_session.set_ui_scale_mode("2")
	assert_signal_emitted(_session, "ui_scale_changed")
	assert_eq(get_window().content_scale_factor, 2.0, "menus, text and HUD at 200%")
	assert_eq(m.view.camera.zoom, Vector2.ONE, "the map stays the same size")
	assert_eq(m.touch.factor, 2.0)
	assert_eq(m.touch.get_node("Box").scale, Vector2(0.5, 0.5), "the pad stays the same size")
	assert_eq(m.touch.pad_width(), TouchControls.PAD_WIDTH / 2.0)
	m._process(0.0)
	assert_eq(m.hud.get_node("Bottom").offset_left, Hud.LOG_LEFT + TouchControls.PAD_WIDTH / 2.0,
			"the log makes room for the pad's real size")
	_session.set_ui_scale_mode(UiScale.AUTO)
	assert_eq(get_window().content_scale_factor, 1.0, "Auto on a desktop: 1")
	assert_eq(m.view.camera.zoom, Vector2(2, 2))


func test_a_freed_panel_lets_go_of_the_signals() -> void:
	var before: int = _session.ui_scale_changed.get_connections().size()
	var panel := PanelContainer.new()
	add_child(panel)
	UiScale.keep_fit(panel, Vector2(100, 100))
	assert_eq(_session.ui_scale_changed.get_connections().size(), before + 1)
	panel.free()
	assert_eq(_session.ui_scale_changed.get_connections().size(), before, "no call into a freed panel")


func test_options_menu_sets_the_scale() -> void:
	var o: OptionsMenu = add_child_autofree(load("res://ui/options_menu.tscn").instantiate())
	o.open()
	var pick: OptionButton = o.get_node("%UiScale")
	assert_eq(pick.get_item_text(pick.selected), "Auto")
	pick.item_selected.emit(2)
	assert_eq(_session.ui_scale.mode, "1.5")
	assert_eq(get_window().content_scale_factor, 1.5)
