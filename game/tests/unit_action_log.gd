extends GutTest


func _rec(id: String, time: int, xp: float, tags: Dictionary) -> Dictionary:
	return {"time": time, "day": time / 1440 + 1, "minute": time % 1440, "action_id": id,
		"tags": tags, "xp": xp}


func test_add_updates_counts_and_tag_totals() -> void:
	var log := ActionLog.new()
	log.add(_rec("cook_stew", 400, 10.0, {"cooking.stew": 0.6, "hospitality": 0.4}))
	log.add(_rec("cook_stew", 500, 5.0, {"cooking.stew": 1.0}))
	assert_eq(log.count("cook_stew"), 2)
	assert_eq(log.count("chop_wood"), 0)
	assert_almost_eq(float(log.tag_totals["cooking.stew"]), 11.0, 0.000001)
	assert_almost_eq(float(log.tag_totals["hospitality"]), 4.0, 0.000001)


func test_prune_drops_old_records_but_keeps_counts() -> void:
	var log := ActionLog.new()
	log.add(_rec("a", 0, 1.0, {"x": 1.0}))
	log.add(_rec("a", 1440 * 5, 1.0, {"x": 1.0}))
	log.prune(1440 * 8, 7)
	assert_eq(log.records.size(), 1)
	assert_eq(int(log.records[0]["time"]), 1440 * 5)
	assert_eq(log.count("a"), 2)


func test_round_trip_through_json() -> void:
	var log := ActionLog.new()
	log.add(_rec("a", 360, 7.25, {"x": 0.3, "y": 0.7}))
	var text := JSON.stringify(log.to_dict(), "", false, true)
	var copy := ActionLog.from_dict(JSON.parse_string(text))
	assert_eq(copy.to_dict(), log.to_dict())
