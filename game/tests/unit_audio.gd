extends GutTest
## M12 audio (ADR 0019): sound cues, the Audio autoload (variants, pitch,
## cross-fade) and the view's `sounds` signal.

var _db: DataDb
var _audio: AudioDb


func before_all() -> void:
	_db = ToyMaps.db()
	_audio = AudioDb.load_file()


func after_each() -> void:
	Audio.music("", 0.0)


func test_footstep_by_ground_and_snow() -> void:
	var snowy := {"winter_color": "#ffffff"}
	assert_eq(SoundCues.footstep(_audio, "grass"), "step_grass")
	assert_eq(SoundCues.footstep(_audio, "wood_floor"), "step_wood")
	assert_eq(SoundCues.footstep(_audio, "cobble"), "step_stone")
	assert_eq(SoundCues.footstep(_audio, "grass", snowy, true), "step_snow", "snow covers grass")
	assert_eq(SoundCues.footstep(_audio, "grass", {}, true), "step_grass", "a tile that stays green")
	assert_eq(SoundCues.footstep(_audio, "water", snowy, true), "", "no step sound, no snow either")


func test_the_real_tiles_turn_to_snow_outdoors_only() -> void:
	var real := DataDb.load_dir()
	var grass: Dictionary = real.maps.tiles["grass"]
	assert_eq(SoundCues.footstep(_audio, "grass", grass, true), "step_snow")
	assert_eq(SoundCues.footstep(_audio, "wood_floor", real.maps.tiles["wood_floor"], true), "step_wood")


func test_a_hit_event_gives_a_hit_cue() -> void:
	var events: Array[Dictionary] = [
		{"type": AnimDiff.MOVE, "id": "a", "from": Vector2i.ZERO, "to": Vector2i.ONE, "dir": "s"},
		{"type": AnimDiff.HIT, "id": "a", "amount": 3},
	]
	assert_eq(SoundCues.from_events(_audio, events), ["hit"] as Array[String])


func test_the_bus_layout_has_four_buses_under_master() -> void:
	for bus in ["Music", "Ambience", "SFX", "UI"]:
		var i := AudioServer.get_bus_index(bus)
		assert_gt(i, 0, bus)
		assert_eq(AudioServer.get_bus_send(i), &"Master", bus)


func test_variants_and_pitch_go_round_in_a_fixed_order() -> void:
	var files := ["a", "b", "c"]
	assert_eq([0, 1, 2, 3].map(func(n: int) -> String: return Audio.variant(files, n)),
			["a", "b", "c", "a"])
	assert_eq(Audio.pitch(0), 1.0)
	assert_eq(Audio.pitch(Audio.PITCH.size()), 1.0)


func test_play_counts_known_cues_and_skips_unknown_ones() -> void:
	var before := int(Audio.plays.get("hit", 0))
	assert_true(Audio.play("hit"))
	assert_eq(int(Audio.plays["hit"]), before + 1)
	assert_false(Audio.play("no_such_cue"))
	assert_true(Audio.play_key("ui", "confirm"))
	assert_false(Audio.play_key("ui", "no_such_key"))


func test_music_cross_fades_to_a_new_track() -> void:
	Audio.music("title", 0.0)
	var first := Audio.music_player()
	assert_eq(Audio.track, "title")
	assert_true(first.playing)
	Audio.music("title")
	assert_eq(Audio.music_player(), first, "the same track keeps its player")
	Audio.music("", 0.2)
	assert_eq(Audio.track, "")
	assert_ne(Audio.music_player(), first, "the other player takes over")
	assert_true(first.playing, "the old track fades out, it does not stop at once")
	await wait_seconds(0.4)
	assert_false(first.playing, "stopped after the fade")


func test_a_new_track_fades_in_from_silence() -> void:
	Audio.music("title", 0.5)
	assert_almost_eq(Audio.music_player().volume_db, Audio.SILENT_DB, 0.5)
	await wait_seconds(0.7)
	assert_almost_eq(Audio.music_player().volume_db, float(_audio.track("title")["volume_db"]), 0.5)


func test_an_unknown_track_is_silent() -> void:
	Audio.music("no_such_track", 0.0)
	assert_eq(Audio.track, "no_such_track")
	assert_false(Audio.music_player().playing)


func test_back_buttons_are_known() -> void:
	var b: Button = autofree(Button.new())
	b.text = "Back"
	assert_true(Audio.is_back(b))
	b.text = "Accept"
	assert_false(Audio.is_back(b))


func test_the_view_sends_a_footstep_for_a_step() -> void:
	var v: WorldView = add_child_autofree(load("res://world/world_view.tscn").instantiate())
	v.setup(_db.maps)
	var gs := ToyMaps.new_game(_db)
	v.refresh(gs)
	watch_signals(v)
	Commands.move(gs, _db, "e")
	v.refresh(gs)
	assert_signal_emitted_with_parameters(v, "sounds", [["step_grass"] as Array[String]])
	v.refresh(gs)
	assert_signal_emit_count(v, "sounds", 1, "no step, no sound")
