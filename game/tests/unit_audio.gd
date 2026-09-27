extends GutTest
## M12.0 audio spike (ADR 0019): sound cues, the Audio autoload and the
## view's `sounds` signal.

var _db: DataDb


func before_all() -> void:
	_db = ToyMaps.db()


func after_each() -> void:
	Audio.music("")


func test_footstep_by_ground_and_snow() -> void:
	assert_eq(SoundCues.footstep("grass"), "step_grass")
	assert_eq(SoundCues.footstep("wood_floor"), "step_wood")
	assert_eq(SoundCues.footstep("cobble"), "step_stone")
	assert_eq(SoundCues.footstep("grass", true), "step_snow", "snow covers grass")
	assert_eq(SoundCues.footstep("wood_floor", true), "step_wood", "no snow indoors")
	assert_eq(SoundCues.footstep("water"), "", "no step sound yet")


func test_a_hit_event_gives_a_hit_cue() -> void:
	var events: Array[Dictionary] = [
		{"type": AnimDiff.MOVE, "id": "a", "from": Vector2i.ZERO, "to": Vector2i.ONE, "dir": "s"},
		{"type": AnimDiff.HIT, "id": "a", "amount": 3},
	]
	assert_eq(SoundCues.from_events(events), ["hit"] as Array[String])


func test_every_cue_and_track_has_its_files() -> void:
	for cue: String in Audio.CUES:
		var def: Dictionary = Audio.CUES[cue]
		var dir := Audio.UI_DIR if def["bus"] == "UI" else Audio.SFX_DIR
		assert_true(AudioServer.get_bus_index(def["bus"]) > 0, "%s has a bus" % cue)
		for f: String in def["files"]:
			assert_true(ResourceLoader.exists(dir + f), dir + f)
	for id: String in Audio.TRACKS:
		assert_true(ResourceLoader.exists(Audio.MUSIC_DIR + Audio.TRACKS[id]["file"]), id)


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


func test_music_keeps_one_track_and_stops() -> void:
	Audio.music("title")
	assert_eq(Audio.track, "title")
	Audio.music("title")
	assert_eq(Audio.track, "title")
	Audio.music("")
	assert_eq(Audio.track, "")


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
