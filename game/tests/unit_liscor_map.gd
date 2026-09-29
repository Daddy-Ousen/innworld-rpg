extends GutTest
## M16.4 (ADR 0024): Liscor is a set of district maps joined by streets. Every one can be
## reached from the east gate, exits go both ways, every enterable-looking door says what it
## is, and each map has a mood and an ambience bed.

## The city maps (M16.4.1 streets; M16.4.2-4 rooms are added to ROOMS as they land).
const STREETS := ["liscor_gate", "liscor_market", "liscor_plaza", "liscor_guild_street", "liscor_watch",
		"liscor_homes"]
const ROOMS: Array[String] = ["liscor_adventurers_guild", "liscor_mages_guild", "liscor_watch_barracks",
		"liscor_watch_office", "liscor_tailless_thief", "liscor_gnoll_tavern"]

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


func test_every_city_map_is_reachable_from_the_east_gate() -> void:
	for id: String in _city():
		if id == "liscor_gate":
			continue
		assert_false(Pathfind.route(_db.maps, {}, "liscor_gate", id).is_empty(), "%s: a way in" % id)
		assert_false(Pathfind.route(_db.maps, {}, id, "liscor_gate").is_empty(), "%s: a way out" % id)


func test_streets_are_joined_the_way_the_plan_says() -> void:
	var joins := {
		"liscor_gate": ["liscor_market"],
		"liscor_market": ["liscor_gate", "liscor_plaza"],
		"liscor_plaza": ["liscor_market", "liscor_guild_street", "liscor_watch", "liscor_homes"],
		"liscor_guild_street": ["liscor_plaza"],
		"liscor_watch": ["liscor_plaza"],
		"liscor_homes": ["liscor_plaza"],
	}
	for id: String in joins:
		var to := {}
		for e: Dictionary in _db.maps.areas[id]["exits"]:
			if not String(e["to"]).begins_with("liscor_") or _city().has(e["to"]):
				to[e["to"]] = true
		for want: String in joins[id]:
			assert_true(to.has(want), "%s has an exit to %s" % [id, want])


func test_every_city_exit_has_a_way_back() -> void:
	for id: String in _city():
		for e: Dictionary in _db.maps.areas[id]["exits"]:
			var back := (_db.maps.areas[e["to"]]["exits"] as Array).any(
					func(b: Dictionary) -> bool: return b["to"] == id)
			assert_true(back, "%s -> %s: the way back exists" % [id, e["to"]])


func test_every_door_says_what_it_is() -> void:
	for id: String in _city():
		var area: Dictionary = _db.maps.areas[id]
		var size := _db.maps.size(id)
		for y in size.y:
			for x in size.x:
				var cell := Vector2i(x, y)
				if _db.maps.tile_at(id, cell) != "stone_door":
					continue
				var e := _db.maps.raw_exit_at(id, cell)
				var named := e.has("sign")
				if not named:
					for o: Dictionary in area["objects"]:
						var d := Vector2i(int(o["at"][0]), int(o["at"][1])) - cell
						named = named or (o.has("sign") and maxi(absi(d.x), absi(d.y)) <= 1)
				assert_true(named, "%s door %s has a sign or a plaque" % [id, cell])


func test_every_city_map_has_a_mood_and_an_ambience_bed() -> void:
	var moods: Dictionary = _audio.data["moods"]["by_map"]
	var beds: Dictionary = _audio.data["ambience"]["by_map"]
	for id: String in _city():
		assert_true(moods.has(id), "%s: a music mood" % id)
	for id: String in STREETS:
		if id != "liscor_gate":
			assert_eq(beds.get(id, ""), "market", "%s: crowd sounds" % id)


func test_selys_works_at_the_guild_desk() -> void:
	var goals: Array = _db.behaviour.npcs["selys"]["goals"]
	var work := goals.filter(func(g: Dictionary) -> bool: return g["goal"] == "work")
	assert_eq(work.size(), 1)
	var target: Dictionary = work[0]["target"]
	assert_eq(target["area"], "liscor_adventurers_guild")
	var at := Vector2i(int(target["pos"][0]), int(target["pos"][1]))
	assert_true(_db.maps.is_walkable("liscor_adventurers_guild", at), "the desk spot is free floor")
	var next_to_desk := false
	for o: Dictionary in _db.maps.areas["liscor_adventurers_guild"]["objects"]:
		if o["kind"] == "counter":
			var d := Vector2i(int(o["at"][0]), int(o["at"][1])) - at
			next_to_desk = next_to_desk or maxi(absi(d.x), absi(d.y)) == 1
	assert_true(next_to_desk, "Selys stands beside the reception desk, so the player can talk to her")


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
