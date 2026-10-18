extends GutTest
## M29.4 (ADR 0044): one page at the end of the written story, shown once.

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])


func _game(canon_day: int) -> GameState:
	var gs := GameState.new_game(1, _db)
	gs.world.last_day = canon_day
	return gs


func test_last_canon_day_is_the_end_of_book_8() -> void:
	assert_gte(_db.canon.last_day(), 163)


func test_the_page_comes_once_after_the_last_canon_day() -> void:
	var gs := _game(_db.canon.last_day())
	var night := Night.run(gs, _db)
	assert_true(night["story_end"])
	var kinds: Array = SystemMessages.pages(night, gs, _db).map(func(p: Dictionary) -> String: return p["kind"])
	assert_eq(kinds, [SystemMessages.STORY_END, SystemMessages.MORNING])
	assert_true(gs.flags[Night.STORY_END_FLAG], "the flag is in the save")
	var again := Night.run(gs, _db)
	assert_false(again["story_end"], "only once")


func test_no_page_while_canon_days_remain() -> void:
	var gs := _game(_db.canon.last_day() - 1)
	var night := Night.run(gs, _db)
	assert_false(night["story_end"])
	assert_false(gs.flags.has(Night.STORY_END_FLAG))


func test_a_db_with_no_events_has_no_end() -> void:
	var canon := CanonDb.from_dicts({}, {}, {})
	assert_eq(canon.last_day(), 0)
