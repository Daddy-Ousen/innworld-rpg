## The player's text size (M15.0, ADR 0022). A user preference, not game
## state: saved in user://settings.cfg next to the volumes (AudioSettings),
## so a load does not change it. Pixel Operator is drawn on a 16 px grid,
## so the sizes are 16 and 32: other sizes blur. Pure except for `apply`,
## which sets the project theme's default size.
class_name TextSettings
extends RefCounted

const PATH := "user://settings.cfg"
const SECTION := "display"
const NORMAL := 16
const LARGE := 32

var large := false


## The settings in `path`, or the defaults (normal text) when there is none.
static func load_file(path: String = PATH) -> TextSettings:
	var s := TextSettings.new()
	var cfg := ConfigFile.new()
	if cfg.load(path) == OK:
		s.large = bool(cfg.get_value(SECTION, "large_text", false))
	return s


func save(path: String = PATH) -> Error:
	var cfg := ConfigFile.new()
	cfg.load(path)  # keep other sections
	cfg.set_value(SECTION, "large_text", large)
	return cfg.save(path)


func font_size() -> int:
	return LARGE if large else NORMAL


## Sets the default font size of the project theme. Every control that uses
## the theme size (no size override of its own) follows at once.
func apply() -> void:
	var path := String(ProjectSettings.get_setting("gui/theme/custom", ""))
	if path == "":
		return
	var theme: Theme = load(path)
	if theme != null:
		theme.default_font_size = font_size()
