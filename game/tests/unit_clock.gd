extends GutTest

const RULES := {
	"start_minute": 360, "wake_minute": 360, "min_sleep_minutes": 240,
	"collapse_after_awake": 2160, "collapse_sleep_minutes": 720,
}


func _clock() -> Clock:
	return Clock.new(360)


func test_start_is_day_one_at_six() -> void:
	var c := _clock()
	assert_eq(c.day(), 1)
	assert_eq(c.minute(), 360)
	assert_eq(c.time_string(), "06:00")


func test_advance_crosses_midnight() -> void:
	var c := _clock()
	c.advance(1200)
	assert_eq(c.day(), 2)
	assert_eq(c.minute(), 120)
	assert_eq(c.awake_minutes, 1200)


func test_negative_advance_is_refused() -> void:
	var c := _clock()
	c.advance(-5)
	assert_eq(c.total_minutes, 360)
	assert_push_error("negative")


func test_sleep_in_evening_wakes_next_morning() -> void:
	var c := _clock()
	c.advance(960) # 22:00
	var passed := c.sleep(RULES)
	assert_eq(passed, 1)
	assert_eq(c.day(), 2)
	assert_eq(c.minute(), 360)
	assert_eq(c.awake_minutes, 0)
	assert_false(c.last_sleep_collapsed)


func test_sleep_after_midnight_gets_min_sleep() -> void:
	var c := _clock()
	c.advance(1260) # day 2, 03:00
	var passed := c.sleep(RULES)
	assert_eq(passed, 0)
	assert_eq(c.day(), 2)
	assert_eq(c.minute(), 420) # 07:00


func test_time_never_goes_back() -> void:
	var c := _clock()
	c.advance(1600) # day 2, 04:40
	var before := c.total_minutes
	c.sleep(RULES)
	assert_gt(c.total_minutes, before)


func test_collapse_after_36_hours() -> void:
	var c := _clock()
	c.advance(2159)
	assert_false(c.is_collapse_due(RULES))
	c.advance(1)
	assert_true(c.is_collapse_due(RULES))
	var before := c.total_minutes
	c.sleep(RULES, true)
	assert_eq(c.total_minutes, before + 720)
	assert_true(c.last_sleep_collapsed)
	assert_false(c.is_collapse_due(RULES))


func test_round_trip() -> void:
	var c := _clock()
	c.advance(500)
	c.sleep(RULES, true)
	c.advance(30)
	var copy := Clock.from_dict(JSON.parse_string(JSON.stringify(c.to_dict())))
	assert_eq(copy.to_dict(), c.to_dict())
