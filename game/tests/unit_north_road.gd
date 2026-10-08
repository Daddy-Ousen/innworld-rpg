extends GutTest
## North road: Celum north gate -> road -> Invrisil -> Riverfarm. Map data only. Checks the chain
## is joined both ways, every exit and arrival tile can be walked on, and the compass rule holds
## (docs/WORLD_WIREFRAME.md: Riverfarm is entered from the Invrisil gate's west side).

const CHAIN: Array[String] = ["celum_square", "celum_main_street", "celum_north_gate", "road_to_invrisil",
		"invrisil_gate", "invrisil_square"]

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()


func _exit_to(area: String, to: String) -> Dictionary:
	for e: Dictionary in _db.maps.areas[area]["exits"]:
		if e["to"] == to:
			return e
	return {}


func _reach(area: String, from: Vector2i) -> Dictionary:
	var seen := {from: true}
	var todo: Array[Vector2i] = [from]
	var s := _db.maps.size(area)
	while not todo.is_empty():
		var p: Vector2i = todo.pop_back()
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var q := p + d
			if q.x < 0 or q.y < 0 or q.x >= s.x or q.y >= s.y or seen.has(q):
				continue
			if _db.maps.is_walkable(area, q):
				seen[q] = true
				todo.append(q)
	return seen


func test_the_data_loads_clean() -> void:
	assert_eq(_db.maps.errors, [] as Array[String])


func test_the_chain_is_joined_both_ways() -> void:
	for i in CHAIN.size() - 1:
		var a: String = CHAIN[i]
		var b: String = CHAIN[i + 1]
		assert_false(_exit_to(a, b).is_empty(), "%s -> %s" % [a, b])
		assert_false(_exit_to(b, a).is_empty(), "%s -> %s" % [b, a])


func test_riverfarm_joins_the_invrisil_gate_on_the_west_side() -> void:
	var out := _exit_to("invrisil_gate", "riverfarm")
	assert_false(out.is_empty())
	assert_eq(int(out["at"][0]), 0, "the road leaves the west edge")
	assert_false(_exit_to("riverfarm", "invrisil_gate").is_empty())
	assert_true(_db.maps.areas["celum_gate"]["exits"].filter(func(e: Dictionary) -> bool: return e["to"] == "riverfarm").is_empty(),
			"no Celum road to Riverfarm")


func test_each_arrival_reaches_every_exit_on_its_map() -> void:
	var maps: Array[String] = ["celum_north_gate", "road_to_invrisil", "invrisil_gate", "invrisil_square", "riverfarm"]
	for id in maps:
		for e: Dictionary in _db.maps.areas[id]["exits"]:
			var at := Vector2i(int(e["at"][0]), int(e["at"][1]))
			assert_true(_db.maps.is_walkable(id, at), "%s exit to %s is on a walkable tile" % [id, e["to"]])
		for src: Dictionary in _db.maps.areas.values():
			for e: Dictionary in src["exits"]:
				if e["to"] != id:
					continue
				var arrive := Vector2i(int(e["arrive"][0]), int(e["arrive"][1]))
				assert_true(_db.maps.is_walkable(id, arrive), "%s -> %s arrival" % [src["id"], id])
				var seen := _reach(id, arrive)
				for x: Dictionary in _db.maps.areas[id]["exits"]:
					assert_true(seen.has(Vector2i(int(x["at"][0]), int(x["at"][1]))),
							"%s: from %s you reach the exit to %s" % [id, src["id"], x["to"]])


func test_the_long_roads_ask_before_you_go() -> void:
	for pair: Array in [["celum_north_gate", "road_to_invrisil"], ["road_to_invrisil", "invrisil_gate"],
			["invrisil_gate", "riverfarm"]]:
		assert_true(TravelPrompt.is_long(int(_exit_to(pair[0], pair[1])["minutes"])), "%s" % [pair])
	assert_true(_db.maps.is_camp("road_to_invrisil"))
