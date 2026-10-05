## When the on-screen touch controls show (M20.1, ADR 0032). A user
## preference, not game state: saved in user://settings.cfg next to the
## volumes and the text size, so a load does not change it. Pure.
class_name TouchSettings
extends RefCounted

const PATH := "user://settings.cfg"
const SECTION := "touch"
## Auto: show on a touch screen (or after the first touch). On / Off: always / never.
const AUTO := "auto"
const ON := "on"
const OFF := "off"
const MODES: Array[String] = [AUTO, ON, OFF]

var mode := AUTO


## The settings in `path`, or the defaults (Auto) when there is none. An
## unknown mode reads as Auto.
static func load_file(path: String = PATH) -> TouchSettings:
	var s := TouchSettings.new()
	var cfg := ConfigFile.new()
	if cfg.load(path) == OK:
		s.set_mode(String(cfg.get_value(SECTION, "mode", AUTO)))
	return s


func save(path: String = PATH) -> Error:
	var cfg := ConfigFile.new()
	cfg.load(path)  # keep other sections
	cfg.set_value(SECTION, "mode", mode)
	return cfg.save(path)


func set_mode(m: String) -> void:
	mode = m if MODES.has(m) else AUTO


## True when the controls show. `touch_screen`: the device has a touch
## screen, or the player has touched it.
func shows(touch_screen: bool) -> bool:
	return mode == ON or (mode == AUTO and touch_screen)
