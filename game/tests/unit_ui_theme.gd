extends GutTest
## M14.6 (ADR 0021): one project theme with a pixel font for every menu.

const THEME_PATH := "res://ui/theme.tres"


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
	assert_true(FileAccess.file_exists("res://assets/fonts/OFL-PixelifySans.txt"))
