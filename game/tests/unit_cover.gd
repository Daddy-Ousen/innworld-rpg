extends GutTest
## M17.6 (ADR 0027): cover levels, sight, cover by side, the pincer. Core only (Cover).
## Toy arena (ToyCombat): 14×9 grass, a wall at x 6, y 3–5. Here the wall tile is "wall" cover, and a
## few objects are added: a table (half) at 9,1, a wagon (full) at 9,7, a plain solid box at 2,6.

var _db: DataDb


func before_each() -> void:
	_db = ToyCombat.db()
	_db.maps.tiles["wall"]["cover"] = Cover.WALL
	var areas := _db.maps.areas
	for o: Dictionary in [
		{"id": "table", "at": [9, 1], "name": "Table", "actions": [], "solid": true, "kind": "table"},
		{"id": "wagon", "at": [9, 7], "name": "Wagon", "actions": [], "solid": true, "kind": "wagon"},
		{"id": "box", "at": [2, 6], "name": "Box", "actions": [], "solid": true},
		{"id": "crate", "at": [3, 6], "name": "Crate", "actions": [], "solid": true, "kind": "table", "cover": "full"},
	]:
		(areas["arena"]["objects"] as Array).append(o)
	_db.maps = MapDb.from_dicts(_db.maps.tiles, areas)
	_db.maps.validate(_db)


func _lvl(x: int, y: int) -> String:
	return Cover.level(_db, "arena", Vector2i(x, y))


func test_levels_from_tile_kind_override_and_none() -> void:
	assert_eq(_lvl(6, 4), Cover.WALL, "a tile")
	assert_eq(_lvl(9, 1), Cover.HALF, "an object by its kind (real rules table)")
	assert_eq(_lvl(9, 7), Cover.FULL)
	assert_eq(_lvl(2, 6), Cover.NONE, "a solid object with no kind entry")
	assert_eq(_lvl(3, 6), Cover.FULL, "the object's own cover beats its kind")
	assert_eq(_lvl(0, 0), Cover.NONE, "grass")
	assert_eq(_lvl(-1, 0), Cover.NONE, "off the map")


func test_the_higher_level_of_tile_and_object_counts() -> void:
	var areas := _db.maps.areas
	(areas["arena"]["objects"] as Array).append(
			{"id": "post", "at": [6, 4], "name": "Post", "actions": [], "solid": true, "cover": "half"})
	_db.maps = MapDb.from_dicts(_db.maps.tiles, areas)
	assert_eq(_lvl(6, 4), Cover.WALL)


func test_line_is_the_same_both_ways_and_leaves_out_the_ends() -> void:
	var a := Vector2i(1, 1)
	var b := Vector2i(12, 6)
	var ab := Cover.line(a, b)
	var ba := Cover.line(b, a)
	assert_eq(ab, ba)
	assert_false(ab.has(a))
	assert_false(ab.has(b))
	assert_eq(Cover.line(Vector2i(2, 2), Vector2i(3, 2)).size(), 0, "side by side: nothing between")
	assert_eq(Cover.line(Vector2i(0, 4), Vector2i(4, 4)), [Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4)] as Array[Vector2i])


func test_a_wall_blocks_sight_a_low_object_does_not() -> void:
	assert_false(Cover.sight(_db, "arena", Vector2i(3, 4), Vector2i(9, 4)), "through the wall at 6,4")
	assert_false(Cover.sight(_db, "arena", Vector2i(9, 4), Vector2i(3, 4)), "and back")
	assert_true(Cover.sight(_db, "arena", Vector2i(3, 2), Vector2i(9, 2)), "above the wall")
	assert_true(Cover.sight(_db, "arena", Vector2i(9, 0), Vector2i(9, 2)), "over the table at 9,1")
	assert_true(Cover.sight(_db, "arena", Vector2i(9, 4), Vector2i(9, 8)), "past the wagon's column")
	assert_false(Cover.sight(_db, "arena", Vector2i(5, 4), Vector2i(7, 4)), "wall between")
	assert_true(Cover.sight(_db, "arena", Vector2i(5, 4), Vector2i(6, 4)), "a wall tile is not between itself and a neighbour")


func test_sight_rule_off_lets_everything_through() -> void:
	_db.rules["combat"]["tactical"]["cover"]["sight"] = false
	assert_true(Cover.sight(_db, "arena", Vector2i(3, 4), Vector2i(9, 4)))


func test_cover_faces_the_shooter() -> void:
	var t := Vector2i(8, 1)  # the table at 9,1 is east of it
	assert_eq(Cover.against(_db, "arena", t, Vector2i(12, 1)), Cover.HALF, "shooter east: covered")
	assert_eq(Cover.against(_db, "arena", t, Vector2i(4, 1)), Cover.NONE, "shooter west: the flank")
	assert_eq(Cover.against(_db, "arena", t, Vector2i(8, 5)), Cover.NONE, "shooter south")
	assert_eq(Cover.against(_db, "arena", t, t), Cover.NONE, "on the same tile")


func test_a_shot_along_the_larger_gap_uses_that_side_only() -> void:
	var t := Vector2i(8, 1)
	assert_eq(Cover.against(_db, "arena", t, Vector2i(12, 3)), Cover.HALF, "mostly east")
	assert_eq(Cover.against(_db, "arena", t, Vector2i(9, 6)), Cover.NONE, "mostly south, the table is east")


func test_a_diagonal_shot_takes_the_better_of_two_sides() -> void:
	var t := Vector2i(8, 7)  # the wagon 9,7 is east; south 8,8 is grass
	assert_eq(Cover.against(_db, "arena", t, Vector2i(10, 9)), Cover.FULL, "equal gaps: east side counts")
	assert_eq(Cover.against(_db, "arena", t, Vector2i(6, 9)), Cover.NONE, "the other diagonal has none")


func test_a_wall_next_to_the_target_is_full_cover_when_the_shooter_sees_it() -> void:
	var t := Vector2i(7, 4)  # the wall 6,4 is west
	assert_eq(Cover.against(_db, "arena", t, Vector2i(3, 5)), Cover.WALL)
	assert_eq(Cover.details(_gs(), _db, "arena", Vector2i(3, 5), t, true, "")["bonus"], -0.30)


func _gs() -> GameState:
	var gs := ToyCombat.new_game(_db, 1)
	ToyCombat.to_arena(gs, _db, Vector2i(12, 1))
	return gs


func test_ranged_bonus_by_level_and_melee_ignores_cover() -> void:
	var gs := _gs()
	var shooter := Vector2i(12, 1)
	assert_almost_eq(Cover.hit_bonus(gs, _db, "arena", shooter, Vector2i(8, 1), true, ""), -0.15, 0.0001)
	assert_almost_eq(Cover.hit_bonus(gs, _db, "arena", shooter, Vector2i(8, 1), false, ""), 0.0, 0.0001, "melee")
	assert_almost_eq(Cover.hit_bonus(gs, _db, "arena", Vector2i(10, 9), Vector2i(8, 7), true, ""), -0.30, 0.0001)
	assert_almost_eq(Cover.hit_bonus(gs, _db, "arena", Vector2i(4, 1), Vector2i(8, 1), true, ""), 0.0, 0.0001, "flanked cover")


func test_the_pincer_needs_two_fighters_of_one_side_on_opposite_tiles() -> void:
	var gs := _gs()  # the player stands at 12,1
	var a := ToyCombat.spawn(gs, _db, "goblin", Vector2i(11, 1))
	assert_false(Cover.pincered(gs, _db, "arena", gs.player.pos(), Cover.FOE), "one goblin")
	var b := ToyCombat.spawn(gs, _db, "goblin", Vector2i(13, 1))
	assert_true(Cover.pincered(gs, _db, "arena", gs.player.pos(), Cover.FOE), "east and west")
	assert_false(Cover.pincered(gs, _db, "arena", gs.player.pos(), Cover.FRIEND))
	assert_almost_eq(Cover.hit_bonus(gs, _db, "arena", Vector2i(11, 1), gs.player.pos(), false, Cover.FOE), 0.15, 0.0001)
	gs.combat.monsters[b]["y"] = 2  # north and east of nothing: not opposite
	assert_false(Cover.pincered(gs, _db, "arena", gs.player.pos(), Cover.FOE))
	gs.combat.monsters[a]["state"] = CombatState.FLEE
	assert_eq(Cover.side_at(gs, _db, "arena", Vector2i(11, 1)), "", "a fleeing monster is on no side")


func test_a_helper_and_the_player_pincer_a_foe() -> void:
	var gs := _gs()
	var foe := ToyCombat.spawn(gs, _db, "crab", Vector2i(11, 1))
	var helper := ToyCombat.spawn(gs, _db, "bird", Vector2i(10, 1), CombatState.ALLY)
	assert_eq(Cover.side_at(gs, _db, "arena", Vector2i(10, 1)), Cover.FRIEND)
	assert_true(gs.combat.monsters.has(foe) and gs.combat.monsters.has(helper))
	assert_true(Cover.pincered(gs, _db, "arena", Vector2i(11, 1), Cover.FRIEND), "helper 10,1 and player 12,1 bracket 11,1")
	gs.player.place("arena", Vector2i(12, 2))
	assert_false(Cover.pincered(gs, _db, "arena", Vector2i(11, 1), Cover.FRIEND), "the player stepped off the line")


func test_bad_cover_data_is_refused() -> void:
	var tiles := ToyMaps.tiles()
	tiles["wall"]["cover"] = "stone"
	var areas := ToyCombat.db().maps.areas
	(areas["arena"]["objects"] as Array).append(
			{"id": "bad", "at": [4, 4], "name": "Bad", "actions": [], "cover": "half"})
	var d := ToyCombat.db()
	d.maps = MapDb.from_dicts(tiles, areas)
	d.rules["combat"]["tactical"]["cover"]["kinds"]["x"] = "tall"
	d.rules["combat"]["tactical"]["cover"]["half"] = 2.0
	var errs := d.maps.validate(d)
	var text := "\n".join(errs)
	assert_string_contains(text, "tile 'wall': cover must be one of")
	assert_string_contains(text, "object 'bad': cover must be one of")
	assert_string_contains(text, "kind 'x' has an unknown level")
	assert_string_contains(text, "'half' must be a number from 0 to 1")


func test_the_real_data_has_cover_and_loads_clean() -> void:
	var real := DataDb.load_dir()
	assert_eq(real.errors.size(), 0, "\n".join(real.errors))
	assert_eq(Cover.rules(real)["half"], 0.15)
	assert_eq(real.maps.tiles["city_wall"]["cover"], Cover.WALL)
	assert_eq(real.maps.tiles["tree"]["cover"], Cover.FULL)
	assert_eq(real.maps.tiles["rock"]["cover"], Cover.HALF)
	assert_false(real.maps.tiles["grass"].has("cover"))
	# every solid object kind in the maps has a cover entry or is left out on purpose
	var free := ["campfire", "stairs"]
	for area: String in real.maps.areas:
		for o: Dictionary in real.maps.areas[area]["objects"]:
			if o.get("solid", false) and not o.has("cover"):
				var kind := String(o.get("kind", ""))
				assert_true(Cover.rules(real)["kinds"].has(kind) or free.has(kind),
						"%s/%s (%s) has no cover entry" % [area, o["id"], kind])
