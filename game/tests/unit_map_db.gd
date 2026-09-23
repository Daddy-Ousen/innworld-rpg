extends GutTest
## MapDb: loading, lookups and validation (ADR 0006).

var _real: DataDb
var _toy: DataDb


func before_all() -> void:
	_real = DataDb.load_dir()
	_toy = ToyMaps.db()


func test_real_maps_load_without_errors() -> void:
	assert_eq(_real.maps.errors, [] as Array[String])
	assert_eq(_real.errors, [] as Array[String])
	for id: String in ["liscor_gate", "liscor_market", "floodplains_south", "inn_hill", "inn_interior"]:
		assert_true(_real.maps.areas.has(id), id)


func test_real_map_items_and_the_razorbeak_nest() -> void:
	var items := {}
	for area: String in _real.maps.areas:
		for o: Dictionary in _real.maps.areas[area]["objects"]:
			if o.has("item"):
				items["%s/%s" % [area, o["id"]]] = o["item"]
	assert_eq(items["floodplains_south/blue_fruit_tree_1"], "seed_core")
	assert_eq(items["floodplains_south/blue_fruit_tree_2"], "seed_core")
	assert_eq(items["floodplains_south/loose_stones_1"], "stone")
	assert_eq(items["inn_interior/stove"], "rolling_pin")
	assert_eq(items["inn_interior/table"], "chair")
	assert_eq(items["inn_hill/loose_stones"], "stone")
	assert_eq(_real.maps.zone_at("floodplains_south", Vector2i(21, 16)), "razorbeak_nests")


func test_real_exits_lead_back() -> void:
	for id: String in _real.maps.areas:
		for e: Dictionary in _real.maps.areas[id]["exits"]:
			var back: Array = _real.maps.areas[e["to"]]["exits"].filter(
					func(b: Dictionary) -> bool: return b["to"] == id)
			assert_false(back.is_empty(), "%s → %s has a way back" % [id, e["to"]])


## Every exit and every object can be reached from every way into the map.
func test_real_maps_are_connected() -> void:
	var entries := {}
	for id: String in _real.maps.areas:
		for e: Dictionary in _real.maps.areas[id]["exits"]:
			var r := MapDb.rect_of(e["at"])
			if not entries.has(e["to"]):
				entries[e["to"]] = []
			entries[e["to"]].append(MapDb.arrival(e, r.position))
	for id: String in _real.maps.areas:
		var m: Dictionary = _real.maps.areas[id]
		for from: Vector2i in entries.get(id, []):
			for e: Dictionary in m["exits"]:
				var goal := {MapDb.rect_of(e["at"]).position: true}
				assert_true(Pathfind.path(_real.maps, id, from, goal)["found"],
						"%s: %s reaches exit to %s" % [id, from, e["to"]])
			for o: Dictionary in m["objects"]:
				var goals := Pathfind.around(Vector2i(int(o["at"][0]), int(o["at"][1])))
				assert_true(Pathfind.path(_real.maps, id, from, goals)["found"],
						"%s: %s reaches %s" % [id, from, o["id"]])


func test_real_start_is_outside_the_east_gate() -> void:
	var start: Dictionary = _real.rules["world"]["start"]
	assert_eq(start["area"], "liscor_gate")
	assert_eq(_real.maps.areas["liscor_gate"]["location"], "liscor_east_gate")


func test_lookups() -> void:
	var m := _toy.maps
	assert_eq(_toy.maps.errors, [] as Array[String])
	assert_eq(m.size("town"), Vector2i(8, 5))
	assert_eq(m.tile_at("town", Vector2i(0, 0)), "wall")
	assert_eq(m.tile_at("town", Vector2i(5, 1)), "water")
	assert_eq(m.tile_at("town", Vector2i(-1, 0)), "")
	assert_eq(m.tile_at("town", Vector2i(8, 0)), "")
	assert_true(m.is_walkable("town", Vector2i(1, 1)))
	assert_false(m.is_walkable("town", Vector2i(5, 1)), "water")
	assert_false(m.is_walkable("town", Vector2i(2, 3)), "solid stove")
	assert_true(m.is_walkable("town", Vector2i(4, 1)), "the dummy is not solid")
	assert_eq(m.exit_at("town", Vector2i(7, 2))["to"], "field")
	assert_true(m.exit_at("town", Vector2i(1, 1)).is_empty())
	assert_eq(m.zone_at("town", Vector2i(3, 1)), "toy_corner")
	assert_eq(m.zone_at("town", Vector2i(3, 2)), "")


func test_objects_near_sorts_by_distance_then_id() -> void:
	var near := _toy.maps.objects_near("town", Vector2i(3, 2))
	assert_eq(near.map(func(o: Dictionary) -> String: return o["id"]), ["dummy", "stove"])
	assert_eq(_toy.maps.objects_near("town", Vector2i(4, 1))[0]["id"], "dummy", "standing on it")
	assert_true(_toy.maps.objects_near("town", Vector2i(6, 1)).is_empty())


func test_arrival_keeps_the_offset_in_a_wide_exit() -> void:
	var e := {"at": [0, 11, 1, 2], "arrive": [30, 11]}
	assert_eq(MapDb.arrival(e, Vector2i(0, 12)), Vector2i(30, 12))


func _errors_with(change: Callable) -> String:
	var areas := ToyMaps.areas()
	var tiles := ToyMaps.tiles()
	change.call(areas, tiles)
	var d := ToyMaps.db()
	d.maps = MapDb.from_dicts(tiles, areas)
	return "\n".join(d.maps.validate(d))


func test_validation_errors() -> void:
	assert_string_contains(_errors_with(func(a: Dictionary, _t: Dictionary) -> void:
		a["town"]["rows"][2] = "wgg"), "width 3, expected 8")
	assert_string_contains(_errors_with(func(a: Dictionary, _t: Dictionary) -> void:
		a["town"]["rows"][2] = "wggggggX"), "'X' is not in the legend")
	assert_string_contains(_errors_with(func(a: Dictionary, _t: Dictionary) -> void:
		a["town"]["legend"]["~"] = "lava"), "unknown tile 'lava'")
	assert_string_contains(_errors_with(func(a: Dictionary, _t: Dictionary) -> void:
		a["town"]["location"] = "nowhere"), "unknown canon location 'nowhere'")
	assert_string_contains(_errors_with(func(a: Dictionary, _t: Dictionary) -> void:
		a["town"]["exits"][0]["to"] = "moon"), "unknown map")
	assert_string_contains(_errors_with(func(a: Dictionary, _t: Dictionary) -> void:
		a["town"]["exits"][0]["arrive"] = [9, 9]), "is not walkable")
	assert_string_contains(_errors_with(func(a: Dictionary, _t: Dictionary) -> void:
		a["field"]["exits"][0]["arrive"] = [7, 2]), "is an exit")
	assert_string_contains(_errors_with(func(a: Dictionary, _t: Dictionary) -> void:
		a["town"]["objects"][0]["actions"] = ["juggle"]), "unknown action 'juggle'")
	assert_string_contains(_errors_with(func(a: Dictionary, _t: Dictionary) -> void:
		a["town"]["objects"][1]["id"] = "stove"), "duplicate id")
	assert_string_contains(_errors_with(func(a: Dictionary, _t: Dictionary) -> void:
		a["town"]["zones"]["toy_corner"] = [[6, 1, 5, 1]]), "inside the map")
	assert_string_contains(_errors_with(func(_a: Dictionary, t: Dictionary) -> void:
		t["grass"]["walk"] = "yes"), "walk must be true or false")
	assert_string_contains(_errors_with(func(a: Dictionary, _t: Dictionary) -> void:
		a["town"].erase("objects")), "missing 'objects'")
	assert_string_contains(_errors_with(func(a: Dictionary, _t: Dictionary) -> void:
		a["town"]["objects"][0]["sleep"] = "yes"), "sleep must be true or false")
	assert_string_contains(_errors_with(func(a: Dictionary, _t: Dictionary) -> void:
		a["town"]["objects"][0]["item"] = "sword"), "unknown item 'sword'")


func test_start_must_be_walkable() -> void:
	var d := ToyMaps.db()
	d.rules["world"]["start"] = {"area": "town", "pos": [0, 0]}
	d.maps = MapDb.from_dicts(ToyMaps.tiles(), ToyMaps.areas())
	assert_string_contains("\n".join(d.maps.validate(d)), "walkable tile of 'town'")
	d.rules["world"]["start"] = {"area": "moon", "pos": [0, 0]}
	d.maps = MapDb.from_dicts(ToyMaps.tiles(), ToyMaps.areas())
	assert_string_contains("\n".join(d.maps.validate(d)), "unknown area 'moon'")


func test_travel_exits_need_the_travel_action() -> void:
	var d := ToyMaps.db()
	d.actions.erase("travel")
	d.maps = MapDb.from_dicts(ToyMaps.tiles(), ToyMaps.areas())
	assert_string_contains("\n".join(d.maps.validate(d)), "needs the action 'travel'")
