extends GutTest
## M12.1 (ADR 0019): volume settings (user://, not game state) and the
## Options panel in the title and pause menus.

const PATH := "user://test_settings_unit.cfg"


func after_each() -> void:
	DirAccess.remove_absolute(PATH)
	Audio.load_settings()  # back to the test settings file (gut_pre_run)


func test_defaults_without_a_file() -> void:
	DirAccess.remove_absolute(PATH)
	var s := AudioSettings.load_file(PATH)
	assert_eq(s.volumes, AudioSettings.DEFAULTS)
	assert_false(s.muted)


func test_save_and_load_round_trip() -> void:
	var s := AudioSettings.new()
	s.set_volume("Music", 0.25)
	s.set_volume("SFX", 3.0)  # kept in 0..1
	s.set_volume("Nope", 0.5)  # unknown bus: ignored
	s.muted = true
	assert_eq(s.save(PATH), OK)
	var t := AudioSettings.load_file(PATH)
	assert_eq(t.volume("Music"), 0.25)
	assert_eq(t.volume("SFX"), 1.0)
	assert_false(t.volumes.has("Nope"))
	assert_true(t.muted)


func test_apply_sets_the_buses() -> void:
	var s := AudioSettings.new()
	s.set_volume("Music", 0.5)
	s.set_volume("UI", 0.0)
	s.apply()
	var music := AudioServer.get_bus_index("Music")
	assert_almost_eq(AudioServer.get_bus_volume_db(music), linear_to_db(0.5), 0.01)
	assert_false(AudioServer.is_bus_mute(music))
	assert_true(AudioServer.is_bus_mute(AudioServer.get_bus_index("UI")), "0 = muted")
	s.muted = true
	s.apply()
	assert_true(AudioServer.is_bus_mute(0), "mute all mutes Master")
	AudioSettings.new().apply()
	assert_false(AudioServer.is_bus_mute(0))


func test_audio_saves_each_change() -> void:
	Audio.settings_path = PATH
	Audio.load_settings()
	Audio.set_volume("Ambience", 0.4)
	Audio.set_muted(true)
	var t := AudioSettings.load_file(PATH)
	assert_eq(t.volume("Ambience"), 0.4)
	assert_true(t.muted)
	Audio.settings_path = "user://test_settings.cfg"


func test_settings_are_not_in_the_save() -> void:
	var gs := GameState.new_game(1, DataDb.load_dir())
	var text := JSON.stringify(gs.to_dict())
	assert_false(text.contains("volume"), "volumes are user settings, not game state")


func test_options_panel_sliders_change_the_volume() -> void:
	Audio.settings_path = PATH
	Audio.load_settings()
	var o: OptionsMenu = add_child_autofree(load("res://ui/options_menu.tscn").instantiate())
	assert_false(o.visible)
	o.open()
	assert_true(o.visible)
	assert_eq(o.sliders.size(), AudioSettings.BUSES.size())
	assert_eq((o.sliders["Music"] as HSlider).value, Audio.settings.volume("Music"))
	(o.sliders["Music"] as HSlider).value = 0.3
	assert_almost_eq(Audio.settings.volume("Music"), 0.3, 0.001)
	assert_almost_eq(AudioSettings.load_file(PATH).volume("Music"), 0.3, 0.001, "saved")
	watch_signals(o)
	o.close()
	assert_signal_emitted(o, "closed")
	Audio.settings_path = "user://test_settings.cfg"


func test_pause_menu_opens_and_closes_options() -> void:
	var p: PauseMenu = add_child_autofree(load("res://ui/pause_menu.tscn").instantiate())
	p.open()
	p.open_options()
	assert_true(p.options.visible)
	assert_false(p.get_node("%Panel").visible)
	p.options.close()
	assert_true(p.get_node("%Panel").visible)
	p.open_options()
	p.close()
	assert_false(p.options.visible, "closing the pause menu closes options")


func test_title_menu_opens_and_closes_options() -> void:
	var t: TitleMenu = add_child_autofree(load("res://ui/title_menu.tscn").instantiate())
	t.switch_scene = false
	t.open_options()
	assert_true(t.options.visible)
	assert_false(t.get_node("Center").visible)
	t.options.close()
	assert_true(t.get_node("Center").visible)
