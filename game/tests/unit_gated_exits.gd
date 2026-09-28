extends GutTest
## M13.0 (ADR 0020): exits with when_flags / unless_flags. A hidden exit is
## plain floor for movement, paths and routes, and is not drawn.

const FLAG := "town.hatch_open"
const HATCH := Vector2i(3, 2)


## The toy maps plus a cellar under a hatch in town that opens with FLAG.
func _areas() -> Dictionary:
	var a := ToyMaps.areas()
	a["town"]["exits"].append({"id": "hatch", "at": [3, 2], "to": "cellar", "arrive": [1, 1],
		"minutes": 0, "when_flags": [FLAG]})
	a["cellar"] = ToyMaps.area("cellar", "toy_shop", ["www", "wgw", "wgw"], {}, [
		{"at": [1, 2], "to": "town", "arrive": [3, 1], "minutes": 0},
	], [])
	return a


func _db(areas: Dictionary = _areas()) -> DataDb:
	var d := ToyMaps.db()
	d.maps = MapDb.from_dicts(ToyMaps.tiles(), areas)
	d.maps.validate(d)
	return d


func _errors_with(change: Callable) -> String:
	var a := _areas()
	change.call(a)
	return "\n".join(_db(a).maps.errors)


func test_the_exit_is_hidden_until_the_flag_is_set() -> void:
	var d := _db()
	assert_eq(d.maps.errors, [] as Array[String])
	d.maps.sync_flags({})
	assert_true(d.maps.exit_at("town", HATCH).is_empty(), "hidden: plain floor")
	assert_eq(d.maps.raw_exit_at("town", HATCH)["id"], "hatch", "the validators still see it")
	assert_eq(d.maps.exits_on("town").size(), 2)
	var key := d.maps.overlay_key
	assert_true(d.maps.sync_flags({FLAG: true}), "a change")
	assert_ne(d.maps.overlay_key, key)
	assert_eq(d.maps.exit_at("town", HATCH)["to"], "cellar")
	assert_eq(d.maps.exits_on("town").size(), 3)


func test_unless_flags_hide_the_exit() -> void:
	var a := _areas()
	a["town"]["exits"][2].erase("when_flags")
	a["town"]["exits"][2]["unless_flags"] = ["town.hatch_nailed"]
	var d := _db(a)
	assert_eq(d.maps.errors, [] as Array[String])
	d.maps.sync_flags({})
	assert_false(d.maps.exit_at("town", HATCH).is_empty())
	d.maps.sync_flags({"town.hatch_nailed": true})
	assert_true(d.maps.exit_at("town", HATCH).is_empty())


func test_a_hidden_exit_is_floor_for_movement() -> void:
	var d := _db()
	var gs := ToyMaps.new_game(d)
	gs.player.place("town", HATCH + Vector2i.UP)
	assert_true(Commands.move(gs, d, "s")["moved"])
	assert_eq(gs.player.area, "town", "stepped onto plain floor")
	assert_eq(gs.player.pos(), HATCH)
	gs.flags[FLAG] = true
	Commands.move(gs, d, "n")
	Commands.move(gs, d, "s")
	assert_eq(gs.player.area, "cellar", "the hatch is open")


func test_paths_and_routes_skip_a_hidden_exit() -> void:
	var d := _db()
	d.maps.sync_flags({})
	assert_true(Pathfind.route(d.maps, {}, "town", "cellar").is_empty(), "no way down")
	var goal := {Vector2i(5, 2): true}
	var p := Pathfind.path(d.maps, "town", Vector2i(1, 2), goal)
	assert_true(p["found"])
	assert_eq(p["steps"], ["e", "e", "e", "e"], "walks over the hidden hatch")
	d.maps.sync_flags({FLAG: true})
	var hops := Pathfind.route(d.maps, {}, "town", "cellar")
	assert_eq(hops.size(), 1)
	assert_eq(hops[0]["to"], "cellar")
	assert_gt((Pathfind.path(d.maps, "town", Vector2i(1, 2), goal)["steps"] as Array).size(), 4,
			"an open exit is only entered as a goal")


func test_the_view_draws_only_open_exits() -> void:
	var d := _db()
	var gs := ToyMaps.new_game(d)
	var v: WorldView = add_child_autofree(load("res://world/world_view.tscn").instantiate())
	v.setup(d.maps)
	v.refresh(gs)
	assert_eq(_exit_marks(v), 2)
	gs.flags[FLAG] = true
	v.refresh(gs)
	assert_eq(_exit_marks(v), 3, "redrawn when the flag opens it")


func _exit_marks(v: WorldView) -> int:
	return v.marks.get_children().filter(func(c: Node) -> bool:
		return c is ColorRect and (c as ColorRect).color == WorldView.EXIT_COLOR).size()


func test_validation_of_gated_exits() -> void:
	assert_string_contains(_errors_with(func(a: Dictionary) -> void:
		a["town"]["exits"][2].erase("id")), "an exit with flags needs an id")
	assert_string_contains(_errors_with(func(a: Dictionary) -> void:
		a["town"]["exits"][0]["id"] = "hatch"), "duplicate exit id 'hatch'")
	assert_string_contains(_errors_with(func(a: Dictionary) -> void:
		a["town"]["exits"][2]["when_flags"] = "town.hatch_open"), "when_flags must be a list of strings")
	assert_string_contains(_errors_with(func(a: Dictionary) -> void:
		a["cellar"]["exits"][0]["id"] = "ladder"
		a["cellar"]["exits"][0]["when_flags"] = [FLAG]), "needs an exit back with no flags")
	assert_string_contains(_errors_with(func(a: Dictionary) -> void:
		a["town"]["overlays"] = [{"id": "rug", "tile": "grass", "rects": [[3, 2, 1, 1]],
			"when_flags": ["x"]}]), "covers an exit or an object")
