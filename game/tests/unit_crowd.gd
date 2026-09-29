extends GutTest
## M16.4 (ADR 0024): the crowd of passers-by. `Crowd` is pure (paths, ping-pong, hours);
## `WorldView` draws it in real time, view only.


func test_cells_fill_in_the_straight_and_diagonal_runs() -> void:
	assert_eq(Crowd.cells([[0, 0], [3, 0]]), [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)])
	assert_eq(Crowd.cells([[0, 0], [2, 2]]), [Vector2i(0, 0), Vector2i(1, 1), Vector2i(2, 2)], "a diagonal")
	assert_eq(Crowd.cells([[0, 0], [2, 1]]), [Vector2i(0, 0), Vector2i(1, 1), Vector2i(2, 1)], "diagonal, then straight")
	assert_eq(Crowd.cells([[1, 1], [1, 1]]), [Vector2i(1, 1)], "a repeated waypoint adds nothing")
	assert_eq(Crowd.cells([]), [] as Array[Vector2i])


func test_chain_goes_there_and_back_without_repeating_the_ends() -> void:
	assert_eq(Crowd.chain([[0, 0], [3, 0]]).size(), 6)
	assert_eq(Crowd.chain([[0, 0], [3, 0]]), [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
			Vector2i(2, 0), Vector2i(1, 0)])
	assert_eq(Crowd.chain([[4, 4]]), [Vector2i(4, 4)], "one cell: stands there")
	assert_eq(Crowd.chain([[0, 0], [1, 0]]).size(), 2)


func test_walkers_are_the_same_for_the_same_time_and_spread_along_the_path() -> void:
	var lane := {"path": [[0, 0], [7, 0]], "walkers": 4}
	var a := Crowd.walker(lane, 1, 4, 3.0)
	assert_eq(a, Crowd.walker(lane, 1, 4, 3.0), "deterministic")
	var seen := {}
	for i in 4:
		seen[Crowd.walker(lane, i, 4, 0.0)["cell"]] = true
	assert_eq(seen.size(), 4, "four walkers, four different cells")
	var later := Crowd.walker(lane, 0, 4, Crowd.STEP_SEC * 2.0 + 0.01)
	assert_eq(later["cell"], Vector2i(2, 0), "one cell per STEP_SEC")
	assert_eq(later["prev"], Vector2i(1, 0))
	assert_eq(later["dir"], "e")
	assert_ne(later["step"], Crowd.walker(lane, 0, 4, 0.0)["step"])
	var back := Crowd.walker(lane, 0, 1, Crowd.STEP_SEC * 9.0 + 0.01)
	assert_eq(back["cell"], Vector2i(5, 0), "turned round at the end")
	assert_eq(back["dir"], "w")


func test_a_lone_cell_never_moves() -> void:
	var lane := {"path": [[4, 4]], "walkers": 1}
	assert_eq(Crowd.walker(lane, 0, 1, 0.0)["step"], 0)
	assert_eq(Crowd.walker(lane, 0, 1, 99.0)["step"], 0, "no step, so no glide")
	assert_eq(Crowd.walker(lane, 0, 1, 99.0)["cell"], Vector2i(4, 4))


func test_facing_and_looks_and_counts() -> void:
	assert_eq(Crowd.facing(Vector2i(1, 0)), "e")
	assert_eq(Crowd.facing(Vector2i(-1, 1)), "w")
	assert_eq(Crowd.facing(Vector2i(0, -1)), "n")
	assert_eq(Crowd.facing(Vector2i(0, 1)), "s")
	assert_eq(Crowd.facing(Vector2i.ZERO), "s")
	var lane := {"looks": ["race_drake", "race_gnoll"], "walkers": 30}
	assert_eq(Crowd.look_of(lane, 0), "race_drake")
	assert_eq(Crowd.look_of(lane, 3), "race_gnoll", "looks repeat")
	assert_eq(Crowd.look_of({}, 0), "")
	assert_eq(Crowd.count(lane), Crowd.MAX_WALKERS, "capped")
	assert_eq(Crowd.count(lane, 3), 3)
	assert_eq(Crowd.count({"walkers": -2}), 0)


func test_hours_wrap_past_midnight() -> void:
	assert_true(Crowd.active({}, 6))
	assert_true(Crowd.active({}, 21))
	assert_false(Crowd.active({}, 22), "night")
	assert_false(Crowd.active({}, 3))
	var late := {"hours": [20, 4]}
	assert_true(Crowd.active(late, 23))
	assert_true(Crowd.active(late, 2))
	assert_false(Crowd.active(late, 12))


func _view(lane: Dictionary) -> WorldView:
	var a := ToyMaps.areas()
	a["town"]["crowd"] = {"lanes": [lane]}
	var v: WorldView = add_child_autofree(load("res://world/world_view.tscn").instantiate())
	v.setup(MapDb.from_dicts(ToyMaps.tiles(), a))
	return v


func _walkers(v: WorldView) -> Array:
	return v.props.get_children().filter(func(n: Node) -> bool: return n.has_meta("crowd"))


func test_the_view_draws_walkers_that_move_and_hide_at_night() -> void:
	var v := _view({"path": [[1, 2], [5, 2]], "walkers": 2, "looks": ["race_drake", "no_such_sheet"]})
	var gs := GameState.new(1)
	gs.player.place("town", Vector2i(1, 1))
	gs.clock.total_minutes = 12 * 60
	v.refresh(gs)
	var walkers := _walkers(v)
	assert_eq(walkers.size(), 1, "a look with no sheet gives no walker")
	var w: Node2D = walkers[0]
	assert_true(w.get_child(0) is CharacterSprite)
	assert_eq(w.get_child_count(), 1, "no label")
	assert_true(w.visible)
	var start := w.position
	v._process(Crowd.STEP_SEC * 2.0 + 0.01)
	assert_ne(w.position, start, "it walked")
	gs.clock.total_minutes = 23 * 60
	v.refresh(gs)
	assert_false(w.visible, "asleep at night")
	gs.clock.total_minutes = 8 * 60
	v.refresh(gs)
	assert_true(w.visible)


func test_a_map_with_no_crowd_draws_none() -> void:
	var v: WorldView = add_child_autofree(load("res://world/world_view.tscn").instantiate())
	v.setup(ToyMaps.db().maps)
	var gs := GameState.new(1)
	gs.player.place("town", Vector2i(1, 1))
	v.refresh(gs)
	assert_eq(_walkers(v).size(), 0)


func test_every_real_lane_walks_on_free_ground_with_real_looks() -> void:
	var maps := MapDb.load_dir()
	var lanes := 0
	for id: String in maps.areas:
		var data: Variant = maps.areas[id].get("crowd", {})
		if not data is Dictionary or (data as Dictionary).is_empty():
			continue
		var total := 0
		var solid := {}
		for o: Dictionary in maps.areas[id]["objects"]:
			if o.get("solid", false):
				solid[Vector2i(int(o["at"][0]), int(o["at"][1]))] = true
		for lane: Dictionary in (data as Dictionary)["lanes"]:
			lanes += 1
			total += int(lane.get("walkers", 1))
			assert_false((lane["looks"] as Array).is_empty(), "%s: a lane names looks" % id)
			for look: String in lane["looks"]:
				assert_true(CharacterSprite.has_sheet(look), "%s: look %s has a sheet" % [id, look])
			for c: Vector2i in Crowd.cells(lane["path"]):
				var tile := maps.tile_at(id, c)
				assert_true(bool(maps.tiles.get(tile, {}).get("walk", false)), "%s: lane cell %s is walkable" % [id, c])
				assert_false(solid.has(c), "%s: lane cell %s is free of solid objects" % [id, c])
		assert_lte(total, Crowd.MAX_WALKERS, "%s: at most %d walkers" % [id, Crowd.MAX_WALKERS])
	assert_gt(lanes, 0, "some real map has a crowd")
