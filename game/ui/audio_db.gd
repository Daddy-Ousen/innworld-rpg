## The audio data from data/audio.json (M12.1, ADR 0019): which files a
## sound cue or a music track plays, and which cue or track goes with a
## tile, an action, a fight event, a page, a mood or a canon moment.
## Pure (no nodes). `validate` lists every problem; the game still runs with
## bad data (a bad cue is silent). Presentation only.
class_name AudioDb
extends RefCounted

const PATH := "res://data/audio.json"
const DIR := "res://assets/audio/"
const SCHEMA_VERSION := 1
const BUSES := ["Music", "Ambience", "SFX", "UI"]
## Sections that map a key to a sound cue.
const CUE_MAPS := ["footsteps", "actions", "combat", "pages", "ui", "ambience"]
const MOOD_VARIANTS := ["day", "night", "winter_day", "winter_night"]
## The footstep key for snow-covered ground.
const WINTER_STEP := "winter"

var data: Dictionary = {}
## Problems found while reading the file (a missing or broken file).
var load_errors: Array[String] = []


static func load_file(path: String = PATH) -> AudioDb:
	var db := AudioDb.new()
	if not FileAccess.file_exists(path):
		db.load_errors.append("missing " + path)
		return db
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		db.data = parsed
	else:
		db.load_errors.append("not a JSON object: " + path)
	return db


static func from_dict(d: Dictionary) -> AudioDb:
	var db := AudioDb.new()
	db.data = d
	return db


func sound(cue: String) -> Dictionary:
	return _section("sounds").get(cue, {})


func track(id: String) -> Dictionary:
	return _section("music").get(id, {})


## The cue for `key` in a cue map ("" = none), e.g. cue("ui", "move").
func cue(section: String, key: String) -> String:
	return String(_section(section).get(key, ""))


func has_key(section: String, key: String) -> bool:
	return _section(section).has(key)


## The cue an enemy type makes for `event` (hurt, gone; "" = none).
func enemy_cue(type: String, event: String) -> String:
	var e: Variant = _section("enemies").get(type, {})
	return String(e.get(event, "")) if e is Dictionary else ""


## The track for a state (title, fight, battle, scene; "" = none).
func state_track(state: String) -> String:
	return String(_section("states").get(state, ""))


## The full path of a file in the audio folder.
static func path_of(file: String) -> String:
	return DIR + file


func _section(key: String) -> Dictionary:
	var v: Variant = data.get(key, {})
	return v if v is Dictionary else {}


## Every problem in the data. `check_files` also checks that each file exists.
func validate(check_files: bool = true) -> Array[String]:
	var errs: Array[String] = load_errors.duplicate()
	if data.is_empty():
		return errs
	if int(data.get("schema_version", 0)) != SCHEMA_VERSION:
		errs.append("schema_version must be %d" % SCHEMA_VERSION)
	for key in ["sounds", "music", "moods", "mood_tracks", "states", "enemies"] + CUE_MAPS:
		if not data.get(key, {}) is Dictionary:
			errs.append("%s must be an object" % key)
	if not data.get("moments", []) is Array:
		errs.append("moments must be a list")
	var sounds := _section("sounds")
	for id: String in sounds:
		var s: Variant = sounds[id]
		if not s is Dictionary:
			errs.append("sounds.%s must be an object" % id)
			continue
		if not BUSES.has(s.get("bus", "")):
			errs.append("sounds.%s.bus must be one of %s" % [id, BUSES])
		var files: Variant = s.get("files", [])
		if not files is Array or (files as Array).is_empty():
			errs.append("sounds.%s.files must be a non-empty list" % id)
			continue
		for f: Variant in files:
			_check_file(errs, "sounds.%s" % id, f, check_files)
	var music := _section("music")
	for id: String in music:
		var t: Variant = music[id]
		if not t is Dictionary:
			errs.append("music.%s must be an object" % id)
			continue
		_check_file(errs, "music.%s" % id, t.get("file", null), check_files)
	for section: String in CUE_MAPS:
		var m := _section(section)
		for key: String in m:
			_check_ref(errs, "%s.%s" % [section, key], m[key], sounds, "sound")
	var enemies := _section("enemies")
	for type: String in enemies:
		if not enemies[type] is Dictionary:
			errs.append("enemies.%s must be an object" % type)
			continue
		for event: String in enemies[type]:
			_check_ref(errs, "enemies.%s.%s" % [type, event], enemies[type][event], sounds, "sound")
	var moods := _section("mood_tracks")
	for mood: String in moods:
		if not moods[mood] is Dictionary:
			errs.append("mood_tracks.%s must be an object" % mood)
			continue
		for variant: String in moods[mood]:
			if not MOOD_VARIANTS.has(variant):
				errs.append("mood_tracks.%s.%s: variant must be one of %s" % [mood, variant, MOOD_VARIANTS])
			_check_ref(errs, "mood_tracks.%s.%s" % [mood, variant], moods[mood][variant], music, "track")
	var states := _section("states")
	for state: String in states:
		_check_ref(errs, "states.%s" % state, states[state], music, "track")
	var place := _section("moods")
	for by in ["by_map", "by_location"]:
		var m: Variant = place.get(by, {})
		if not m is Dictionary:
			errs.append("moods.%s must be an object" % by)
			continue
		for key: String in m:
			_check_ref(errs, "moods.%s.%s" % [by, key], m[key], moods, "mood")
	_check_ref(errs, "moods.default", place.get("default", ""), moods, "mood")
	var moments: Variant = data.get("moments", [])
	if moments is Array:
		for i in (moments as Array).size():
			var mo: Variant = moments[i]
			if not mo is Dictionary or String(mo.get("id", "")) == "":
				errs.append("moments[%d] needs an id" % i)
				continue
			_check_ref(errs, "moments.%s.track" % mo["id"], mo.get("track", ""), music, "track")
			for key in ["when_flags", "unless_flags", "areas", "stages"]:
				if not mo.get(key, []) is Array:
					errs.append("moments.%s.%s must be a list" % [mo["id"], key])
	return errs


static func _check_file(errs: Array[String], where: String, f: Variant, check_files: bool) -> void:
	if not f is String or String(f) == "":
		errs.append("%s: a file must be a non-empty string" % where)
	elif check_files and not ResourceLoader.exists(path_of(f)):
		errs.append("%s: missing file %s" % [where, path_of(f)])


## `v` must be "" or a key of `known`.
static func _check_ref(errs: Array[String], where: String, v: Variant, known: Dictionary, what: String) -> void:
	if not v is String:
		errs.append("%s must be a string" % where)
	elif String(v) != "" and not known.has(v):
		errs.append("%s: unknown %s %s" % [where, what, v])
