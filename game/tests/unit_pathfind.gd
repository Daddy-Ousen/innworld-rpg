extends GutTest
## Pathfind (ADR 0006, 0008): grid paths with tiles to avoid, and routes
## between areas and off-map places.

var _db: DataDb


func before_all() -> void:
	_db = ToyNpcs.db()


func test_path_is_shortest_and_fixed() -> void:
	var r := Pathfind.path(_db.maps, "town", Vector2i(1, 1), {Vector2i(3, 1): true})
	assert_true(r["found"])
	assert_eq(r["steps"], ["e", "e"] as Array[String])
	assert_eq(Pathfind.path(_db.maps, "town", Vector2i(1, 1), {Vector2i(1, 1): true})["steps"],
			[] as Array[String], "already there")


func test_path_goes_around_avoided_tiles() -> void:
	var r := Pathfind.path(_db.maps, "town", Vector2i(1, 1), {Vector2i(3, 1): true},
			{Vector2i(2, 1): true})
	assert_eq(r["steps"], ["s", "e", "e", "n"] as Array[String])
	var shut := Pathfind.path(_db.maps, "shop", Vector2i(1, 1), {Vector2i(1, 2): true},
			{Vector2i(1, 2): true})
	assert_false(shut["found"], "an avoided goal cannot be reached")


func test_path_never_steps_on_an_exit_that_is_not_the_goal() -> void:
	var r := Pathfind.path(_db.maps, "town", Vector2i(5, 3), {Vector2i(6, 1): true})
	assert_eq(r["steps"], ["n", "e", "n"] as Array[String], "not through the door at 6,3")


func test_route_between_maps() -> void:
	var hops := Pathfind.route(_db.maps, _db.behaviour.entries, "field", "shop")
	assert_eq(hops.map(func(h: Dictionary) -> String: return h["to"]), ["town", "shop"])
	assert_eq(hops[0]["tiles"], {Vector2i(0, 1): true})
	assert_eq(hops[0]["arrive"], Vector2i(6, 2))
	assert_eq(hops[1]["tiles"], {Vector2i(6, 3): true})
	assert_eq(Pathfind.route(_db.maps, _db.behaviour.entries, "town", "town"), [] as Array[Dictionary])


func test_route_to_and_from_off_map_places() -> void:
	var entries := _db.behaviour.entries
	var hops := Pathfind.route(_db.maps, entries, "@city", "shop")
	assert_eq(hops.map(func(h: Dictionary) -> String: return h["to"]), ["town", "shop"])
	assert_eq(hops[0]["arrive"], Vector2i(1, 3), "the city's way in")
	var out := Pathfind.route(_db.maps, entries, "field", "@city")
	assert_eq(out.map(func(h: Dictionary) -> String: return h["to"]), ["town", "@city"])
	assert_eq(out[1]["tiles"], {Vector2i(1, 3): true})
	assert_eq(Pathfind.route(_db.maps, entries, "@nowhere", "town"), [] as Array[Dictionary])
