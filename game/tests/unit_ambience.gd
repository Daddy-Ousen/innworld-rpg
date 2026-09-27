extends GutTest
## M12.4 (ADR 0019): area beds (AmbiencePick, Audio.ambience), object loops
## (objects.json "sound", Audio.place_loops) and the real data.

var _db: DataDb
var _gs: GameState
var _real: DataDb


func _audio() -> AudioDb:
	return AudioDb.from_dict({
		"ambience": {
			"by_map": {"shop": "tavern", "field": ""},
			"outdoor": "outdoor",
			"indoor": "",
			"beds": {
				"outdoor": {"day": "birds", "night": "crickets", "winter_day": "wind", "winter_night": "wind"},
				"tavern": {"day": "crowd"},
			},
		},
	})


func before_all() -> void:
	_real = DataDb.load_dir()


func before_each() -> void:
	_db = ToyMaps.db()
	_gs = ToyMaps.new_game(_db)
	_gs.clock.total_minutes = 12 * 60  # noon on day 1


func after_each() -> void:
	Audio.ambience("", 0.0)


func test_the_place_of_a_map() -> void:
	var a := _audio()
	assert_eq(a.ambience_place("shop", true), "tavern", "by map")
	assert_eq(a.ambience_place("field", false), "", "by map: silent")
	assert_eq(a.ambience_place("town", false), "outdoor")
	assert_eq(a.ambience_place("town", true), "", "indoor")


func test_bed_variants_fall_back_like_the_music() -> void:
	var a := _audio()
	assert_eq(AmbiencePick.bed_for(a, "outdoor", false, false), "birds")
	assert_eq(AmbiencePick.bed_for(a, "outdoor", true, false), "crickets")
	assert_eq(AmbiencePick.bed_for(a, "outdoor", true, true), "wind")
	assert_eq(AmbiencePick.bed_for(a, "tavern", true, true), "crowd", "only day")
	assert_eq(AmbiencePick.bed_for(a, "", false, false), "", "no place: silence")


func test_the_place_and_the_time_pick_the_bed() -> void:
	var a := _audio()
	assert_eq(AmbiencePick.bed(_gs, _db, a), "birds")
	_gs.clock.total_minutes = 23 * 60
	assert_eq(AmbiencePick.bed(_gs, _db, a), "crickets")
	_gs.player.place("shop", Vector2i(1, 1))
	assert_eq(AmbiencePick.bed(_gs, _db, a), "crowd")


func test_loop_of_an_object_kind() -> void:
	assert_eq(AmbiencePick.loop_of({"sound": {"cue": "fire", "radius": 3}}), {"cue": "fire", "radius": 3.0})
	assert_eq(AmbiencePick.loop_of({"sound": {"cue": "fire"}}),
			{"cue": "fire", "radius": AmbiencePick.DEFAULT_RADIUS}, "default radius")
	assert_eq(AmbiencePick.loop_of({"sound": {"cue": ""}}), {}, "no cue")
	assert_eq(AmbiencePick.loop_of({"region": [0, 0, 1, 1]}), {}, "no sound")
	assert_eq(AmbiencePick.loop_of(null), {})


func test_bad_ambience_data_is_reported() -> void:
	var a := AudioDb.from_dict({"schema_version": 1, "sounds": {}, "ambience": {
		"by_map": {"shop": "nowhere"}, "outdoor": "outdoor",
		"beds": {"outdoor": {"dawn": "", "day": "no_sound"}}}})
	var errs := "
".join(a.validate(false))
	assert_string_contains(errs, "ambience.by_map.shop: unknown place nowhere")
	assert_string_contains(errs, "ambience.beds.outdoor.dawn: variant must be one of")
	assert_string_contains(errs, "ambience.beds.outdoor.day: unknown sound no_sound")


# --- the real data ---

func test_every_real_map_has_a_place_with_a_day_bed_or_is_quiet() -> void:
	var real := _real
	var a := AudioDb.load_file()
	for key: String in a.data["ambience"]["by_map"]:
		assert_true(real.maps.areas.has(key), "by_map names a real map: " + key)
	for id: String in real.maps.areas:
		var place := a.ambience_place(id, real.maps.is_indoor(id))
		if place != "":
			assert_ne(AmbiencePick.bed_for(a, place, false, false), "", id + " has a day bed")
		if not real.maps.is_indoor(id):
			assert_ne(AmbiencePick.bed_for(a, place, true, true), "", id + " has a winter night bed")


func test_every_object_sound_is_a_looping_ambience_cue() -> void:
	var a := AudioDb.load_file()
	var art := WorldView.load_object_art()
	var n := 0
	for kind: String in art:
		var l := AmbiencePick.loop_of(art[kind])
		if l.is_empty():
			continue
		n += 1
		var def := a.sound(l["cue"])
		assert_false(def.is_empty(), kind + ": known cue " + String(l["cue"]))
		if def.is_empty():
			continue
		assert_eq(String(def["bus"]), "Ambience", kind)
		assert_gt(float(l["radius"]), 0.0, kind)
	assert_gte(n, 6, "fires, the well and the bee nest")


func test_every_ambience_sound_loops() -> void:
	var sounds: Dictionary = AudioDb.load_file().data["sounds"]
	for id: String in sounds:
		if String(sounds[id]["bus"]) != "Ambience":
			continue
		for f: String in sounds[id]["files"]:
			var s: Variant = load(AudioDb.path_of(f))
			assert_true(s is AudioStreamOggVorbis and (s as AudioStreamOggVorbis).loop, f + " loops")


func test_the_real_maps_have_their_loops() -> void:
	var real := _real
	var art := WorldView.load_object_art()
	var cues := AmbiencePick.loops_on(real.maps, "celum_square", art).map(func(l: Dictionary) -> String: return l["cue"])
	assert_eq(cues.count("amb_fire"), 2, "two braziers")
	assert_eq(cues.count("amb_water"), 1, "the well")
	var bees := AmbiencePick.loops_on(real.maps, "bee_cave", art)
	assert_eq(bees.size(), 1)
	assert_eq(String(bees[0]["cue"]), "amb_bees")
	assert_true(bees[0]["cell"] is Vector2i)


# --- the Audio autoload ---

func test_the_bed_cross_fades_and_loops() -> void:
	Audio.ambience("amb_birds", 0.0)
	var first := Audio.ambience_player()
	assert_eq(Audio.bed, "amb_birds")
	assert_true(first.playing)
	assert_eq(first.bus, &"Ambience")
	Audio.ambience("amb_birds")
	assert_eq(Audio.ambience_player(), first, "the same bed keeps its player")
	Audio.ambience("amb_crickets", 0.0)
	assert_ne(Audio.ambience_player(), first)
	assert_false(first.playing, "the old bed stops")
	Audio.ambience("", 0.0)
	assert_false(Audio.ambience_player().playing, "silence")


func test_an_unknown_bed_is_silent() -> void:
	Audio.ambience("no_such_bed", 0.0)
	assert_eq(Audio.bed, "no_such_bed")
	assert_false(Audio.ambience_player().playing)


func test_place_loops_puts_a_player_on_each_object() -> void:
	var parent: Node2D = add_child_autofree(Node2D.new())
	var n := Audio.place_loops(parent, [
		{"cue": "amb_fire", "cell": Vector2i(2, 3), "radius": 4.0},
		{"cue": "no_such_cue", "cell": Vector2i(0, 0), "radius": 4.0},
	], 32)
	assert_eq(n, 1, "the unknown cue is skipped")
	assert_eq(parent.get_child_count(), 1)
	var p := parent.get_child(0) as AudioStreamPlayer2D
	assert_eq(p.position, Vector2(80, 112), "the cell centre")
	assert_eq(p.max_distance, 128.0)
	assert_eq(p.bus, &"Ambience")
	assert_true(p.playing)
	Audio.place_loops(parent, [], 32)
	await wait_process_frames(1)
	assert_eq(parent.get_child_count(), 0, "a new map drops the old loops")


func test_the_view_sends_the_loops_of_a_new_map() -> void:
	var real := _real
	var v: WorldView = add_child_autofree(load("res://world/world_view.tscn").instantiate())
	v.setup(real.maps)
	watch_signals(v)
	var gs := GameState.new()
	gs.player.place("celum_square", Vector2i(1, 1))
	v.refresh(gs)
	assert_signal_emit_count(v, "area_loops", 1)
	var loops: Array = get_signal_parameters(v, "area_loops")[0]
	assert_eq(loops.size(), 3)
	v.refresh(gs)
	assert_signal_emit_count(v, "area_loops", 1, "same map, no new loops")
