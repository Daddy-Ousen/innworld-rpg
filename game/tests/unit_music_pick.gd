extends GutTest
## M12.3 (ADR 0019): which track plays (MusicPick) and that the real data
## gives every map a mood.

var _db: DataDb
var _gs: GameState


func _audio() -> AudioDb:
	return AudioDb.from_dict({
		"moods": {"by_map": {"shop": "inn"}, "by_location": {"toy_field": "wilds"}, "default": "town"},
		"mood_tracks": {
			"inn": {"day": "inn_day", "night": "inn_night", "winter_night": "inn_snow"},
			"town": {"day": "town_day"},
			"wilds": {"day": "wilds_day", "winter_day": "wilds_snow"},
		},
		"states": {"fight": "fight", "battle": "battle", "scene": "scene"},
		"moments": [
			{"id": "party", "track": "party", "when_flags": ["party"], "unless_flags": ["over"],
				"areas": ["town"]},
			{"id": "raid", "track": "raid_theme", "stages": ["toy_raid"]},
		],
	})


func before_each() -> void:
	_db = ToyMaps.db()
	_gs = ToyMaps.new_game(_db)
	_gs.clock.total_minutes = 12 * 60  # noon on day 1


func _set_hour(h: int) -> void:
	_gs.clock.total_minutes = h * 60


func test_mood_by_map_then_location_then_default() -> void:
	var a := _audio()
	assert_eq(MusicPick.mood_of(a, _db.maps, "shop"), "inn", "by map")
	assert_eq(MusicPick.mood_of(a, _db.maps, "field"), "wilds", "by location")
	assert_eq(MusicPick.mood_of(a, _db.maps, "town"), "town", "default")


func test_variants_fall_back() -> void:
	var a := _audio()
	assert_eq(MusicPick.place_track(a, "inn", false, false), "inn_day")
	assert_eq(MusicPick.place_track(a, "inn", true, false), "inn_night")
	assert_eq(MusicPick.place_track(a, "inn", true, true), "inn_snow")
	assert_eq(MusicPick.place_track(a, "inn", false, true), "inn_day", "no winter_day: day")
	assert_eq(MusicPick.place_track(a, "town", true, true), "town_day", "only day")
	assert_eq(MusicPick.place_track(a, "wilds", true, true), "wilds_snow", "winter night: winter_day")
	assert_eq(MusicPick.place_track(a, "nowhere", false, false), "", "unknown mood: silence")


func test_the_place_and_the_time_pick_the_track() -> void:
	var a := _audio()
	assert_eq(MusicPick.track(_gs, _db, a), "town_day")
	_gs.player.place("shop", Vector2i(1, 1))
	assert_eq(MusicPick.track(_gs, _db, a), "inn_day")
	_set_hour(23)
	assert_eq(MusicPick.track(_gs, _db, a), "inn_night")


func test_a_fight_beats_the_place() -> void:
	_gs.combat.fight = {"attacks": 0, "throws": 0}
	assert_eq(MusicPick.states(_gs, _db), ["fight"] as Array[String])
	assert_eq(MusicPick.track(_gs, _db, _audio()), "fight")


func test_a_staged_battle_beats_a_fight_only_in_its_area() -> void:
	_db.canon.events["toy_raid"] = {"stage": {"area": "town", "waves": []}}
	_gs.combat.stage_run = {"event": "toy_raid", "next": 0}
	_gs.combat.monsters["m1"] = {"stage": "toy_raid", "state": CombatState.HOSTILE}
	_gs.combat.fight = {"attacks": 0, "throws": 0}
	var a := _audio()
	a.data["moments"] = []
	assert_eq(MusicPick.states(_gs, _db), ["battle", "fight"] as Array[String])
	assert_eq(MusicPick.track(_gs, _db, a), "battle")
	_gs.player.place("shop", Vector2i(1, 1))
	assert_eq(MusicPick.track(_gs, _db, a), "fight", "away from the battle")
	_gs.combat.monsters.clear()
	_gs.player.place("town", Vector2i(1, 2))
	assert_eq(MusicPick.states(_gs, _db), ["fight"] as Array[String], "no foes left: no battle")


func test_a_live_scene_plays_the_scene_track() -> void:
	_db.canon.events["toy_scene"] = {"stage": {"kind": "scene", "area": "town", "hours": [10, 14],
		"npcs": []}}
	_db.canon.stages.append("toy_scene")
	_gs.world.staged["toy_scene"] = _gs.clock.day()
	assert_eq(MusicPick.track(_gs, _db, _audio()), "scene")
	_set_hour(15)
	assert_eq(MusicPick.track(_gs, _db, _audio()), "town_day", "the scene is over")


func test_moments_need_their_flags_area_and_stage() -> void:
	var a := _audio()
	_gs.flags["party"] = true
	assert_eq(MusicPick.track(_gs, _db, a), "party")
	_gs.combat.fight = {"attacks": 0, "throws": 0}
	assert_eq(MusicPick.track(_gs, _db, a), "party", "a moment beats a fight")
	_gs.combat.fight = {}
	_gs.flags["over"] = true
	assert_eq(MusicPick.track(_gs, _db, a), "town_day", "unless_flags")
	_gs.flags.erase("over")
	_gs.player.place("shop", Vector2i(1, 1))
	assert_eq(MusicPick.track(_gs, _db, a), "inn_day", "wrong area")
	_gs.combat.stage_run = {"event": "toy_raid", "next": 0}
	assert_eq(MusicPick.track(_gs, _db, a), "raid_theme", "its stage is on")


func test_every_real_map_has_a_mood_with_a_day_track() -> void:
	var real := DataDb.load_dir()
	var a := AudioDb.load_file()
	for area: String in real.maps.areas:
		var mood := MusicPick.mood_of(a, real.maps, area)
		assert_ne(mood, "", area)
		assert_ne(MusicPick.place_track(a, mood, false, false), "", "%s has a day track" % area)
	for state in ["title", "fight", "battle", "scene"]:
		assert_ne(a.state_track(state), "", state)


func test_the_game_screen_plays_the_place_music() -> void:
	var real := Session.db
	var gs := GameState.new_game(1, real)
	var want := MusicPick.track(gs, real, Audio.db)
	assert_ne(want, "")
	Session.set_state(gs)
	var main: Node = add_child_autofree(load("res://world/main.tscn").instantiate())
	main.switch_scene = false
	assert_eq(Audio.track, want)
	Audio.music("", 0.0)
