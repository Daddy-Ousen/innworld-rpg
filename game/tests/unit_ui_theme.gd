extends GutTest
## M14.6 (ADR 0021): one project theme with a pixel font for every menu.

const THEME_PATH := "res://ui/theme.tres"
const TEXT_PATH := "user://test_text_settings_unit.cfg"


func test_project_uses_the_theme() -> void:
	assert_eq(ProjectSettings.get_setting("gui/theme/custom"), THEME_PATH)


func test_theme_has_the_pixel_font() -> void:
	var theme: Theme = load(THEME_PATH)
	assert_not_null(theme)
	assert_not_null(theme.default_font)
	assert_true(theme.default_font.resource_path.begins_with("res://assets/fonts/"))
	assert_gt(theme.default_font_size, 0)


func test_theme_skins_the_controls_we_use() -> void:
	var theme: Theme = load(THEME_PATH)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		assert_true(theme.has_stylebox(state, "Button"), "Button " + state)
	for style in ["panel", "selected", "hovered"]:
		assert_true(theme.has_stylebox(style, "ItemList"), "ItemList " + style)
	assert_true(theme.has_stylebox("panel", "PanelContainer"))
	assert_true(theme.has_stylebox("normal", "LineEdit"))


func test_menus_pick_up_the_theme() -> void:
	var menu: Control = load("res://ui/pause_menu.tscn").instantiate()
	add_child_autofree(menu)
	var button: Button = menu.find_child("Resume", true, false)
	assert_not_null(button)
	assert_eq(button.get_theme_font("font", "Button"), (load(THEME_PATH) as Theme).default_font)
	assert_true(button.get_theme_stylebox("normal") is StyleBoxFlat)


func test_font_licence_is_shipped() -> void:
	assert_true(FileAccess.file_exists("res://assets/fonts/CC0-PixelOperator.txt"))


## M15.0 (ADR 0022): Pixel Operator is drawn on a 16 px grid. Other sizes
## blur or give uneven letters, so every size we set is a multiple of 16.
func test_font_is_pixel_operator() -> void:
	var theme: Theme = load(THEME_PATH)
	assert_eq(theme.default_font.resource_path, "res://assets/fonts/PixelOperator.ttf")
	assert_eq(theme.default_font_size % 16, 0)


func test_text_size_defaults_to_normal() -> void:
	DirAccess.remove_absolute(TEXT_PATH)
	var s := TextSettings.load_file(TEXT_PATH)
	assert_false(s.large)
	assert_eq(s.font_size(), 16)


func test_text_size_round_trip_keeps_the_volumes() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", 0.25)
	cfg.save(TEXT_PATH)
	var s := TextSettings.new()
	s.large = true
	assert_eq(s.save(TEXT_PATH), OK)
	assert_true(TextSettings.load_file(TEXT_PATH).large)
	assert_eq(AudioSettings.load_file(TEXT_PATH).volume("Music"), 0.25)
	DirAccess.remove_absolute(TEXT_PATH)


func test_large_text_sets_the_theme_size() -> void:
	var theme: Theme = load(THEME_PATH)
	Session.set_large_text(true)
	assert_eq(theme.default_font_size, 32)
	Session.set_large_text(false)
	assert_eq(theme.default_font_size, 16)


func test_options_menu_has_the_large_text_box() -> void:
	var menu: Control = load("res://ui/options_menu.tscn").instantiate()
	add_child_autofree(menu)
	var box := menu.find_child("LargeText", true, false) as CheckBox
	assert_not_null(box)
	menu.call("open")
	assert_false(box.button_pressed)
	box.button_pressed = true
	assert_true(Session.text.large)
	box.button_pressed = false
	assert_false(Session.text.large)


func test_menu_font_sizes_fit_the_pixel_grid() -> void:
	for path in ["res://ui/hud.tscn", "res://ui/system_dialog.tscn", "res://ui/title_menu.tscn"]:
		var root: Node = load(path).instantiate()
		for node in root.find_children("*", "Control", true, false):
			var c := node as Control
			if c.has_theme_font_size_override("font_size"):
				assert_eq(c.get_theme_font_size("font_size") % 16, 0, "%s %s" % [path, c.name])
		root.free()
