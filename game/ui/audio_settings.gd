## The player's volume settings (M12.1, ADR 0019). A user preference, not
## game state (rule 2 covers game state): saved in user://settings.cfg, not
## in a save slot, so a load does not change the volumes. Pure except for
## `apply`, which sets the AudioServer buses.
class_name AudioSettings
extends RefCounted

const PATH := "user://settings.cfg"
const SECTION := "audio"
const BUSES := ["Master", "Music", "Ambience", "SFX", "UI"]
## Linear volume 0..1 per bus.
const DEFAULTS := {"Master": 1.0, "Music": 0.7, "Ambience": 0.8, "SFX": 1.0, "UI": 0.8}

var volumes: Dictionary = DEFAULTS.duplicate()
var muted := false


## The settings in `path`, or the defaults when there is no file. Unknown
## buses are left out; volumes are kept in 0..1.
static func load_file(path: String = PATH) -> AudioSettings:
	var s := AudioSettings.new()
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return s
	for bus: String in BUSES:
		s.set_volume(bus, float(cfg.get_value(SECTION, bus.to_lower(), DEFAULTS[bus])))
	s.muted = bool(cfg.get_value(SECTION, "muted", false))
	return s


func save(path: String = PATH) -> Error:
	var cfg := ConfigFile.new()
	cfg.load(path)  # keep other sections
	for bus: String in BUSES:
		cfg.set_value(SECTION, bus.to_lower(), volumes[bus])
	cfg.set_value(SECTION, "muted", muted)
	return cfg.save(path)


func set_volume(bus: String, linear: float) -> void:
	if BUSES.has(bus):
		volumes[bus] = clampf(linear, 0.0, 1.0)


func volume(bus: String) -> float:
	return float(volumes.get(bus, 0.0))


## Sets each bus's volume; a bus at 0 is muted, and `muted` mutes Master.
func apply() -> void:
	for bus: String in BUSES:
		var i := AudioServer.get_bus_index(bus)
		if i < 0:
			continue
		var v := volume(bus)
		AudioServer.set_bus_mute(i, v <= 0.0 or (bus == "Master" and muted))
		if v > 0.0:
			AudioServer.set_bus_volume_db(i, linear_to_db(v))
