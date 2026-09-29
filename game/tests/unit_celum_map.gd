extends GutTest
## M16.5 (ADR 0025): Celum is a set of district maps joined by streets. Every one can be
## reached from the gate, exits go both ways, every door says what it is, and each map
## has a mood and (streets) an ambience bed.

const STREETS := ["celum_gate", "celum_square", "celum_main_street", "celum_stitchworks_street",
		"celum_hare_street", "celum_poor_quarter"]
const ROOMS: Array[String] = ["celum_runners_guild", "celum_frenzied_hare", "celum_stitchworks"]

var _db: DataDb
var _audio: AudioDb


func before_all() -> void:
	_db = DataDb.load_dir()
	_audio = AudioDb.load_file()


func _city() -> Array[String]:
	var out: Array[String] = []
	out.append_array(STREETS)
	out.append_array(ROOMS)
	return out


func test_the_real_data_loads_clean() -> void:
	assert_eq(_db.maps.errors, [] as Array[String])
	for id: String in _city():
		assert_true(_db.maps.areas.has(id), id)


func test_every_city_map_is_reachable_from_the_gate() -> void:
	for id: String in _city():
		if id == "celum_gate":
			continue
		assert_false(Pathfind.route(_db.maps, {}, "celum_gate", id).is_empty(), "%s: a way in" % id)
		assert_false(Pathfind.route(_db.maps, {}, id, "celum_gate").is_empty(), "%s: a way out" % id)


func test_streets_are_joined_the_way_the_plan_says() -> void:
	var joins := {
		"celum_gate": ["celum_square"],
		"celum_square": ["celum_gate", "celum_main_street", "celum_stitchworks_street", "celum_hare_street"],
		"celum_main_street": ["celum_square", "celum_runners_guild"],
		"celum_stitchworks_street": ["celum_square", "celum_stitchworks"],
		"celum_hare_street": ["celum_square", "celum_poor_quarter", "celum_frenzied_hare"],
		"celum_poor_quarter": ["celum_hare_street"],
	}
	for id: String in joins:
		var to := {}
		for e: Dictionary in _db.maps.areas[id]["exits"]:
			to[e["to"]] = true
		for want: String in joins[id]:
			assert_true(to.has(want), "%s has an exit to %s" % [id, want])


func test_every_city_exit_has_a_way_back() -> void:
	for id: String in _city():
		for e: Dictionary in _db.maps.areas[id]["exits"]:
			if not _city().has(e["to"]):
				continue
			var back := (_db.maps.areas[e["to"]]["exits"] as Array).any(
					func(b: Dictionary) -> bool: return b["to"] == id)
			assert_true(back, "%s -> %s: the way back exists" % [id, e["to"]])


func test_every_arrival_is_free_floor_and_not_on_an_exit() -> void:
	for id: String in _city():
		for e: Dictionary in _db.maps.areas[id]["exits"]:
			if not _city().has(e["to"]):
				continue
			var at := Vector2i(int(e["arrive"][0]), int(e["arrive"][1]))
			assert_true(_db.maps.is_walkable(e["to"], at), "%s -> %s arrives on free floor" % [id, e["to"]])
			assert_true(_db.maps.raw_exit_at(e["to"], at).is_empty(), "%s -> %s arrives beside its exit" % [id, e["to"]])


func test_every_house_door_says_what_it_is() -> void:
	for id: String in STREETS:
		var area: Dictionary = _db.maps.areas[id]
		var size := _db.maps.size(id)
		for y in size.y:
			for x in size.x:
				var cell := Vector2i(x, y)
				if not ["brick_door", "plain_door", "stone_door"].has(_db.maps.tile_at(id, cell)):
					continue
				var e := _db.maps.raw_exit_at(id, cell)
				var named := e.has("sign")
				if not named:
					for o: Dictionary in area["objects"]:
						var d := Vector2i(int(o["at"][0]), int(o["at"][1])) - cell
						named = named or (o.has("sign") and maxi(absi(d.x), absi(d.y)) <= 1)
				assert_true(named, "%s door %s has a sign or a plaque" % [id, cell])


func test_the_moved_doors_are_gone_from_the_square() -> void:
	var to := (_db.maps.areas["celum_square"]["exits"] as Array).map(func(e: Dictionary) -> String: return e["to"])
	for gone: String in ["celum_runners_guild", "celum_frenzied_hare", "celum_stitchworks"]:
		assert_false(to.has(gone), "%s has its door on a street now" % gone)
	assert_true(Interact.object_of(_db, "celum_stitchworks_street", "stitchworks_door").has("shop"), "the shop door moved")
	assert_true(Interact.object_of(_db, "celum_square", "stitchworks_door").is_empty(), "no second shop door")


func test_off_map_walkers_still_arrive_on_the_square() -> void:
	var at: Vector2i = _db.behaviour.entries[BehaviourDb.OFF_MAP_PREFIX + "celum"]["celum_square"]
	assert_true(_db.maps.is_walkable("celum_square", at), "the east edge cell is free")


func test_every_city_map_has_a_mood_and_streets_an_ambience_bed() -> void:
	var moods: Dictionary = _audio.data["moods"]["by_map"]
	var beds: Dictionary = _audio.data["ambience"]["by_map"]
	for id: String in _city():
		assert_true(moods.has(id), "%s: a music mood" % id)
	for id: String in STREETS:
		if id != "celum_gate":
			assert_eq(beds.get(id, ""), "market", "%s: crowd sounds" % id)


func test_every_schedule_spot_in_the_city_is_free_floor() -> void:
	var n := 0
	for npc: String in _db.behaviour.npcs:
		for g: Dictionary in _db.behaviour.npcs[npc]["goals"]:
			var t: Dictionary = g.get("target", {})
			if not t.has("pos") or not _city().has(t.get("area", "")):
				continue
			n += 1
			var at := Vector2i(int(t["pos"][0]), int(t["pos"][1]))
			assert_true(_db.maps.is_walkable(t["area"], at), "%s: %s %s is free floor" % [npc, t["area"], at])
	assert_gt(n, 10, "the city holds scheduled spots")
