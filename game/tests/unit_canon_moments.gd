extends GutTest
## M12.5 (ADR 0019): canon moments have their own music, and the Local News
## page plays a sad sting when tonight's news tells of a death.

const KLBKCH := "b1.klbkch_dies_defending_erin"
const BANQUET := "b2.frost_faeries_accept_the_banquet"
const TORISKA := "b1.persua_ambushes_ryoka"  # a death with no news

var _db: DataDb
var _audio: AudioDb
var _gs: GameState


func before_all() -> void:
	_db = DataDb.load_dir()
	_audio = AudioDb.load_file()


func before_each() -> void:
	_gs = GameState.new_game(1, _db)


func _at(day: int, hour: int) -> void:
	_gs.clock.total_minutes = (day - 1) * 24 * 60 + hour * 60


func test_at_least_six_moments_with_real_tracks_and_stages() -> void:
	var moments: Array = _audio.data["moments"]
	assert_gte(moments.size(), 6)
	var ids := {}
	for mo: Dictionary in moments:
		assert_false(ids.has(mo["id"]), "%s is listed once" % mo["id"])
		ids[mo["id"]] = true
		assert_true(_audio.data["music"].has(mo["track"]), "%s has a real track" % mo["id"])
		assert_false((mo.get("stages", []) as Array).is_empty(), "%s ends with its stage" % mo["id"])
		for id: String in mo.get("stages", []):
			assert_true(_db.canon.stages.has(id), "%s is a real canon stage" % id)
	assert_eq(_audio.validate(), [] as Array[String])


func test_a_staged_fight_moment_beats_the_battle_music() -> void:
	_at(21, 12)
	_gs.player.place("inn_interior", Vector2i(5, 5))
	var before := MusicPick.track(_gs, _db, _audio)
	_gs.combat.stage_run = {"event": KLBKCH, "start": 0, "next": 0}
	assert_eq(MusicPick.track(_gs, _db, _audio), "lament")
	_gs.combat.stage_run = {}
	assert_eq(MusicPick.track(_gs, _db, _audio), before, "the fight is over")


func test_a_live_scene_moment_plays_its_track() -> void:
	_at(48, 20)
	assert_eq(_gs.clock.day(), 48)
	_gs.player.place("inn_hill", Vector2i(5, 5))
	_gs.world.staged[BANQUET] = 48
	assert_eq(MusicPick.track(_gs, _db, _audio), "faerie_night")
	_gs.player.place("inn_interior", Vector2i(5, 5))
	assert_ne(MusicPick.track(_gs, _db, _audio), "faerie_night", "only on the stage area")


func _night(event: String, outcome: String = Director.DONE) -> Dictionary:
	return {"events": [{"day": 21, "event": event, "outcome": outcome, "roles": {}}], "news": ["x"]}


func test_news_deaths_needs_a_news_event_that_killed() -> void:
	assert_eq(SystemMessages.news_deaths(_night(KLBKCH), _gs, _db), [] as Array[String],
			"nobody is dead yet")
	_gs.world.set_alive("klbkch", false)
	assert_eq(SystemMessages.news_deaths(_night(KLBKCH), _gs, _db), ["klbkch"] as Array[String])
	assert_eq(SystemMessages.news_deaths(_night(KLBKCH, Director.CANCELLED), _gs, _db),
			[] as Array[String], "a cancelled event killed nobody")
	_gs.world.set_alive("toriska", false)
	assert_eq(SystemMessages.news_deaths(_night(TORISKA), _gs, _db), [] as Array[String],
			"that death is not in the news")


func test_the_news_page_carries_the_deaths() -> void:
	_gs.world.set_alive("klbkch", false)
	var news: Array = SystemMessages.pages(_night(KLBKCH), _gs, _db).filter(
			func(p: Dictionary) -> bool: return p["kind"] == SystemMessages.NEWS)
	assert_eq(news.size(), 1)
	assert_eq(news[0]["deaths"], ["klbkch"] as Array[String])


func test_page_sound_plays_the_death_cue_only_for_deaths() -> void:
	var toy := AudioDb.from_dict({"pages": {"open": "chime", "news": "book", "death": "sad"}})
	var page := SystemMessages.page(SystemMessages.NEWS, "Local News", ["x"])
	assert_eq(SoundCues.page_sound(toy, page), "book")
	page["deaths"] = ["klbkch"]
	assert_eq(SoundCues.page_sound(toy, page), "sad")
	var no_death := AudioDb.from_dict({"pages": {"open": "chime", "news": "book"}})
	assert_eq(SoundCues.page_sound(no_death, page), "book", "no death cue: the news cue")


func test_the_system_dialog_plays_the_sad_sting() -> void:
	var d: SystemDialog = add_child_autofree(load("res://ui/system_dialog.tscn").instantiate())
	var before := int(Audio.plays.get("sad_sting", 0))
	var page := SystemMessages.page(SystemMessages.NEWS, "Local News", ["x"])
	page["deaths"] = ["klbkch"]
	d.open([page] as Array[Dictionary], _gs, _db)
	assert_eq(int(Audio.plays.get("sad_sting", 0)), before + 1)
