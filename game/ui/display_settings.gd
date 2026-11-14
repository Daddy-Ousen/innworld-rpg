## The full screen setting (audit W3, ADR 0053). A user preference, not game state: saved in
## user://settings.cfg (section "display", key "fullscreen") next to the menu size. Desktop only:
## a phone OS and the web build have no window mode to switch. Borderless full screen, not exclusive.
## Pure except `apply`, which `Session` calls (and never in a headless run).
class_name DisplaySettings
extends RefCounted

const PATH := "user://settings.cfg"
const SECTION := "display"

var fullscreen := false


## The settings in `path`, or a window when there is none. A bad value reads as a window.
static func load_file(path: String = PATH) -> DisplaySettings:
	var s := DisplaySettings.new()
	var cfg := ConfigFile.new()
	if cfg.load(path) == OK:
		var v: Variant = cfg.get_value(SECTION, "fullscreen", false)
		s.fullscreen = v is bool and v
	return s


func save(path: String = PATH) -> Error:
	var cfg := ConfigFile.new()
	cfg.load(path)  # keep other sections
	cfg.set_value(SECTION, "fullscreen", fullscreen)
	return cfg.save(path)


## True when the full screen switch makes sense: a desktop build (not a phone OS, not the web).
static func available() -> bool:
	return UiScale.is_desktop()


## Puts the real window in (or out of) borderless full screen. A headless run has no window: nothing happens.
static func apply_window(on: bool) -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED)
