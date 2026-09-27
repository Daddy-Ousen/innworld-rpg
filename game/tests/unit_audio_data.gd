extends GutTest
## M12.1 (ADR 0019): data/audio.json and its checks (AudioDb).


func _toy() -> Dictionary:
	return {
		"schema_version": 1,
		"sounds": {"step": {"bus": "SFX", "files": ["ui/ui_ok.wav"]}},
		"music": {"calm": {"file": "music/old_tower_inn.mp3"}},
		"moods": {"by_map": {"town": "inn"}, "by_location": {}, "default": "inn"},
		"mood_tracks": {"inn": {"day": "calm"}},
		"states": {"title": "calm", "fight": ""},
		"moments": [{"id": "feast", "track": "calm", "when_flags": ["feast"]}],
		"footsteps": {"grass": "step"},
		"actions": {}, "combat": {}, "enemies": {"goblin": {"hurt": "step"}},
		"pages": {}, "ui": {}, "ambience": {},
	}


func test_the_real_file_has_no_errors() -> void:
	var a := AudioDb.load_file()
	assert_eq(a.validate(), [] as Array[String])
	assert_false(a.data.is_empty())


func test_every_sound_and_track_file_exists() -> void:
	var a := AudioDb.load_file()
	for cue: String in a.data["sounds"]:
		for f: String in a.sound(cue)["files"]:
			assert_true(ResourceLoader.exists(AudioDb.path_of(f)), f)
	for id: String in a.data["music"]:
		assert_true(ResourceLoader.exists(AudioDb.path_of(a.track(id)["file"])), id)


func test_a_good_toy_file_passes() -> void:
	assert_eq(AudioDb.from_dict(_toy()).validate(), [] as Array[String])


func test_lookups() -> void:
	var a := AudioDb.from_dict(_toy())
	assert_eq(a.cue("footsteps", "grass"), "step")
	assert_eq(a.cue("footsteps", "water"), "")
	assert_eq(a.cue("no_section", "x"), "")
	assert_eq(a.state_track("title"), "calm")
	assert_eq(a.state_track("battle"), "")
	assert_true(a.sound("nope").is_empty())


func test_bad_references_are_reported() -> void:
	var d := _toy()
	d["footsteps"]["snow"] = "no_cue"
	d["states"]["fight"] = "no_track"
	d["moods"]["by_map"]["cave"] = "no_mood"
	d["mood_tracks"]["inn"]["dusk"] = "calm"
	d["enemies"]["goblin"]["hurt"] = "no_cue"
	d["moments"].append({"track": "calm"})
	var errs := AudioDb.from_dict(d).validate()
	for part in ["footsteps.snow: unknown sound no_cue", "states.fight: unknown track no_track",
			"moods.by_map.cave: unknown mood no_mood", "mood_tracks.inn.dusk: variant",
			"enemies.goblin.hurt: unknown sound no_cue", "moments[1] needs an id"]:
		assert_true(errs.any(func(e: String) -> bool: return e.contains(part)), part)
	assert_eq(errs.size(), 6, str(errs))


func test_bad_sounds_and_missing_files_are_reported() -> void:
	var d := _toy()
	d["sounds"]["loud"] = {"bus": "Speakers", "files": ["sfx/nothing_here.ogg"]}
	d["sounds"]["empty"] = {"bus": "SFX", "files": []}
	d["music"]["gone"] = {"file": "music/nothing_here.mp3"}
	d["schema_version"] = 2
	var errs := AudioDb.from_dict(d).validate()
	for part in ["sounds.loud.bus", "sounds.loud: missing file", "sounds.empty.files",
			"music.gone: missing file", "schema_version"]:
		assert_true(errs.any(func(e: String) -> bool: return e.contains(part)), part)
	assert_false(AudioDb.from_dict(d).validate(false).any(func(e: String) -> bool:
		return e.contains("missing file")), "file checks can be turned off")


func test_a_missing_file_is_one_error() -> void:
	var a := AudioDb.load_file("res://data/no_such_audio.json")
	assert_eq(a.validate().size(), 1)
	assert_eq(a.cue("ui", "move"), "", "still usable: silent")
