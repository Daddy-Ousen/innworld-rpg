extends GutTest
## M11.1 tiles and objects (ADR 0018): soft terrain edges (GroundArt), the
## ground borrowed under props, object art from data/objects.json, and that
## every real tile and map object has art.

const T := "lpc_terrains"


## grass (z 3, edges) around a dirt patch (z 2, edges), a wall (art, no z),
## a rock (prop, no sprite) and "void" (no art at all).
func _tiles() -> Dictionary:
	return {
		"grass": {"name": "Grass", "walk": true, "color": "#00ff00",
			"sprite": {"sheet": T, "cells": [[1, 10]], "edges": [0, 7], "z": 3}},
		"dirt": {"name": "Dirt", "walk": true, "color": "#996633",
			"sprite": {"sheet": T, "cells": [[1, 3]], "edges": [0, 0], "z": 2}},
		"wall": {"name": "Wall", "walk": false, "color": "#444444",
			"sprite": {"sheet": "lpc_atlas", "cells": [[17, 24]]}},
		"rock": {"name": "Rock", "walk": false, "color": "#777777",
			"prop": {"sheet": "lpc_atlas", "region": [28, 26, 1, 1]}},
		"void": {"name": "Void", "walk": false, "color": "#000000"},
	}


func _maps(rows: Array) -> MapDb:
	var a := ToyMaps.area("m", "toy_town", rows, {}, [], [])
	a["legend"] = {"g": "grass", "d": "dirt", "w": "wall", "^": "rock", "x": "void"}
	return MapDb.from_dicts(_tiles(), {"m": a})


func test_edge_pieces_follow_the_lpc_block() -> void:
	var up := GroundArt.UP
	var down := GroundArt.DOWN
	var left := GroundArt.LEFT
	var right := GroundArt.RIGHT
	assert_eq(GroundArt.edge_piece({}), null)
	assert_eq(GroundArt.edge_piece({up: true}), Vector2i(1, 2), "top edge of the ring")
	assert_eq(GroundArt.edge_piece({down: true}), Vector2i(1, 4))
	assert_eq(GroundArt.edge_piece({left: true}), Vector2i(0, 3))
	assert_eq(GroundArt.edge_piece({right: true}), Vector2i(2, 3))
	assert_eq(GroundArt.edge_piece({up: true, left: true}), Vector2i(0, 2), "outer corner")
	assert_eq(GroundArt.edge_piece({down: true, right: true, Vector2i(1, 1): true}), Vector2i(2, 4))
	assert_eq(GroundArt.edge_piece({Vector2i(1, 1): true}), Vector2i(1, 0), "inner corner")
	assert_eq(GroundArt.edge_piece({Vector2i(-1, -1): true}), Vector2i(2, 1))
	assert_eq(GroundArt.edge_piece({up: true, down: true}), null, "a one-cell strip has no single piece")


func test_strips_and_tips_get_one_piece_per_corner_or_side() -> void:
	var up := GroundArt.UP
	var down := GroundArt.DOWN
	var left := GroundArt.LEFT
	var right := GroundArt.RIGHT
	assert_eq(GroundArt.edge_pieces({up: true, down: true}), [Vector2i(1, 2), Vector2i(1, 4)] as Array[Vector2i])
	assert_eq(GroundArt.edge_pieces({left: true, right: true}), [Vector2i(0, 3), Vector2i(2, 3)] as Array[Vector2i])
	assert_eq(GroundArt.edge_pieces({up: true, left: true, right: true}),
			[Vector2i(0, 2), Vector2i(2, 2)] as Array[Vector2i], "a tip: both top corners")
	assert_eq(GroundArt.edge_pieces({up: true, down: true, left: true, right: true}).size(), 4, "an island")
	assert_eq(GroundArt.edge_pieces({up: true, left: true}), [Vector2i(0, 2)] as Array[Vector2i])
	assert_true(GroundArt.edge_pieces({}).is_empty())


## A 3×6 block (96×192): the plain fill is opaque green; the top piece (1,2) is
## see-through on its top row and has a red bank on its second row; the bottom piece
## (1,4) the same at the bottom.
func _block_sheet() -> Image:
	var img := Image.create(96, 192, false, Image.FORMAT_RGBA8)
	img.fill(Color.GREEN)
	for x in 32:
		img.set_pixel(32 + x, 64, Color(0, 0, 0, 0))
		img.set_pixel(32 + x, 65, Color.RED)
		img.set_pixel(32 + x, 128 + 31, Color(0, 0, 0, 0))
		img.set_pixel(32 + x, 128 + 30, Color.RED)
	return img


func test_mix_is_see_through_where_any_piece_is_and_keeps_every_bank() -> void:
	var cells: Array[Vector2i] = [Vector2i(1, 2), Vector2i(1, 4)]
	var m := GroundArt.mix(_block_sheet(), cells, Vector2i(1, 5), 32)
	assert_eq(m.get_pixel(5, 0).a, 0.0, "top row is see-through")
	assert_eq(m.get_pixel(5, 1), Color.RED, "top bank")
	assert_eq(m.get_pixel(5, 31).a, 0.0, "bottom row is see-through")
	assert_eq(m.get_pixel(5, 30), Color.RED, "bottom bank")
	assert_eq(m.get_pixel(5, 15), Color.GREEN, "the middle is the fill")


func test_higher_ground_draws_a_soft_edge_over_lower_ground() -> void:
	var plan := GroundArt.plan(_maps(["ggggg", "ggdgg", "ggggg"]), "m", false)
	assert_eq(plan.size(), 15)
	assert_eq(plan[Vector2i(2, 1)], {"base": [T, Vector2i(1, 3)]}, "the lower dirt draws no edge")
	assert_eq(plan[Vector2i(2, 0)]["base"], [T, Vector2i(1, 3)], "dirt goes under the grass edge")
	assert_eq(plan[Vector2i(2, 0)]["over"], [T, Vector2i(0, 7) + Vector2i(1, 4)], "dirt is below: bottom edge")
	assert_eq(plan[Vector2i(1, 1)]["over"], [T, Vector2i(0, 7) + Vector2i(2, 3)], "dirt to the right")
	assert_eq(plan[Vector2i(1, 0)]["over"], [T, Vector2i(0, 7) + Vector2i(1, 0)], "dirt on a corner")
	assert_false(plan[Vector2i(4, 1)].has("over"), "no lower neighbour: plain grass")
	assert_eq(plan[Vector2i(4, 1)]["base"], [T, Vector2i(1, 10)])


func test_a_one_cell_strip_is_a_mix_and_a_view_draws_it() -> void:
	var maps := _maps(["ddd", "ggg", "ddd"])
	var plan := GroundArt.plan(maps, "m", false)
	var mixed: Dictionary = plan[Vector2i(1, 1)]["mix"]
	assert_eq(mixed["fill"], Vector2i(0, 7) + Vector2i(1, 5))
	assert_eq((mixed["cells"] as Array).size(), 2)
	assert_false(plan[Vector2i(1, 1)].has("over"))
	var v: WorldView = add_child_autofree(load("res://world/world_view.tscn").instantiate())
	v.setup(maps)
	var gs := GameState.new(1)
	gs.player.place("m", Vector2i(0, 0))
	v.refresh(gs)
	var spots := []
	for sprite: Sprite2D in v.mixes.get_children():
		spots.append(sprite.position)
	assert_eq(spots, [Vector2(0, 32), Vector2(32, 32), Vector2(64, 32)], "one mixed sprite per strip cell")


func _cliff_maps(rows: Array) -> MapDb:
	var tiles := _tiles()
	tiles["cliff"] = {"name": "Cliff", "walk": false, "color": "#775533",
		"cliff": {"sheet": "cliffs", "block": [0, 0]}, "winter_cliff": {"sheet": "cliffs", "block": [6, 0]}}
	var a := ToyMaps.area("m", "toy_town", rows, {}, [], [])
	a["legend"] = {"g": "grass", "^": "cliff"}
	return MapDb.from_dicts(tiles, {"m": a})


func test_cliff_cells_draw_the_piece_for_their_place_in_the_mass() -> void:
	var plan := GroundArt.plan(_cliff_maps(["ggggg", "g^^^g", "g^^^g", "g^^^g", "ggggg"]), "m", false)
	var over := func(x: int, y: int) -> Vector2i:
		var entry: Dictionary = plan[Vector2i(x, y)]
		return (entry["over"] if entry.has("over") else entry["base"])[1]
	assert_eq(over.call(1, 1), Vector2i(0, 0), "top left rim")
	assert_eq(over.call(2, 1), Vector2i(1, 0), "top rim")
	assert_eq(over.call(3, 1), Vector2i(2, 0), "top right rim")
	assert_eq(over.call(2, 2), Vector2i(1, 2), "the upper half of the face (one cell of mass below)")
	assert_eq(over.call(2, 3), Vector2i(1, 3), "the front face")
	assert_eq(over.call(1, 3), Vector2i(0, 3), "front face, left end")
	assert_eq(plan[Vector2i(2, 3)]["base"], [T, Vector2i(1, 10)], "grass under the piece")
	assert_eq(plan[Vector2i(2, 3)]["over"][0], "cliffs")


func test_a_cliff_along_the_map_edge_shows_no_rim_or_face() -> void:
	var plan := GroundArt.plan(_cliff_maps(["^^^^", "^^^^", "^^^^", "gggg"]), "m", false)
	assert_eq(plan[Vector2i(1, 0)]["base"], ["cliffs", Vector2i(1, 1)], "top surface: the map edge is mass")
	assert_eq(plan[Vector2i(0, 0)]["base"], ["cliffs", Vector2i(1, 1)], "no left end on the edge")
	assert_eq(plan[Vector2i(0, 1)]["base"], ["cliffs", Vector2i(1, 2)], "upper face; no left end on the edge")
	assert_eq(plan[Vector2i(1, 2)]["over"], ["cliffs", Vector2i(1, 3)], "grass below: front face")


func test_cliff_winter_look_and_a_missing_sheet() -> void:
	var maps := _cliff_maps(["ggg", "g^g", "ggg"])
	assert_eq(GroundArt.cliff_look(maps.tiles["cliff"], true)["block"], Vector2i(6, 0))
	assert_eq(GroundArt.cliff_look(maps.tiles["cliff"], false)["block"], Vector2i(0, 0))
	var def: Dictionary = (maps.tiles["cliff"] as Dictionary).duplicate(true)
	def["cliff"]["sheet"] = "no_such_sheet"
	assert_eq(GroundArt.cliff_look(def, false), {}, "no sheet: the colour square")
	assert_eq(GroundArt.cliff_look({"walk": true}, false), {})


func _house_maps(rows: Array, extra: Dictionary = {}) -> MapDb:
	var tiles := _tiles()
	var house := {"sheet": "houses", "block": [0, 0]}
	tiles["home"] = {"name": "House", "walk": false, "color": "#775533", "house": house,
		"winter_house": {"sheet": "houses", "block": [20, 0]}}
	tiles["home_b"] = {"name": "House", "walk": false, "color": "#775533", "house": {"sheet": "houses", "block": [0, 0], "group": 1}}
	tiles["home_door"] = {"name": "Door", "walk": true, "color": "#c49a5a", "house": {"sheet": "houses", "block": [0, 0], "door": true}}
	tiles["ruin"] = {"name": "Ruin", "walk": false, "color": "#555555", "house": {"sheet": "houses", "block": [15, 0], "see_through": true}}
	var a := ToyMaps.area("m", "toy_town", rows, {}, [], [])
	a["legend"] = {"g": "grass", "h": "home", "b": "home_b", "d": "home_door", "r": "ruin"}
	a["legend"].merge(extra, true)
	return MapDb.from_dicts(tiles, {"m": a})


func _piece(plan: Dictionary, x: int, y: int) -> Vector2i:
	var entry: Dictionary = plan[Vector2i(x, y)]
	return (entry["over"] if entry.has("over") else entry["base"])[1]


func test_house_cells_draw_roof_upper_wall_and_lower_wall() -> void:
	var plan := GroundArt.plan(_house_maps(["ggggg", "ghhhg", "ghhhg", "ghhhg", "ghhhg", "ggggg"]), "m", false)
	assert_eq(_piece(plan, 1, 1), Vector2i(0, 0), "roof top, left end")
	assert_eq(_piece(plan, 2, 1), Vector2i(1, 0), "roof top")
	assert_eq(_piece(plan, 3, 1), Vector2i(2, 0), "roof top, right end")
	assert_eq(_piece(plan, 2, 2), Vector2i(1, 1), "roof fill")
	assert_eq(_piece(plan, 1, 2), Vector2i(0, 1), "roof fill, left end")
	assert_eq(_piece(plan, 2, 3), Vector2i(3, 2), "upper wall with a window (even column)")
	assert_eq(_piece(plan, 1, 3), Vector2i(0, 2), "upper wall, left end")
	assert_eq(_piece(plan, 2, 4), Vector2i(1, 3), "lower wall")
	assert_eq(_piece(plan, 3, 4), Vector2i(2, 3), "lower wall, right end")
	assert_eq(plan[Vector2i(2, 4)]["base"][0], "houses")
	assert_false(plan[Vector2i(2, 4)].has("over"), "a house is opaque: no ground under it")


func test_a_small_house_and_a_map_edge_band() -> void:
	var plan := GroundArt.plan(_house_maps(["hhh", "ggg"]), "m", false)
	assert_eq(_piece(plan, 1, 0), Vector2i(1, 3), "one row of house: the lower wall")
	assert_eq(_piece(plan, 0, 0), Vector2i(1, 3), "the map edge is house, so no left end")
	plan = GroundArt.plan(_house_maps(["ggg", "hhh", "hhh"]), "m", false)
	assert_eq(_piece(plan, 1, 1), Vector2i(1, 0), "roof top; the band goes on past the map edge")
	assert_eq(_piece(plan, 1, 2), Vector2i(1, 1), "roof fill along the edge")
	plan = GroundArt.plan(_house_maps(["gggggg", "ghhhhg", "ghhhhg", "gggggg"]), "m", false)
	assert_eq(_piece(plan, 2, 1), Vector2i(3, 2), "two rows: upper wall with a window on an even column")
	assert_eq(_piece(plan, 3, 1), Vector2i(1, 2), "no window on an odd column")
	assert_eq(_piece(plan, 4, 1), Vector2i(2, 2), "right end")
	assert_eq(_piece(plan, 2, 2), Vector2i(1, 3))


func test_two_groups_side_by_side_are_two_houses() -> void:
	var plan := GroundArt.plan(_house_maps(["gggggg", "ghhbbg", "ghhbbg", "ghhbbg", "gggggg"]), "m", false)
	assert_eq(_piece(plan, 2, 1), Vector2i(2, 0), "the first house ends at its own right end")
	assert_eq(_piece(plan, 3, 1), Vector2i(0, 0), "the second house starts with a left end")
	var one := GroundArt.plan(_house_maps(["gggggg", "ghhhhg", "ghhhhg", "ghhhhg", "gggggg"]), "m", false)
	assert_eq(_piece(one, 2, 1), Vector2i(1, 0), "one group: one long roof")


func test_a_door_draws_the_door_and_the_wall_above_draws_its_top() -> void:
	var plan := GroundArt.plan(_house_maps(["gggggg", "ghhhbg", "ghhbbg", "ghdbbg", "gggggg"]), "m", false)
	assert_eq(_piece(plan, 2, 3), Vector2i(4, 3), "door")
	assert_eq(_piece(plan, 2, 2), Vector2i(4, 2), "door top on the upper wall")
	assert_eq(_piece(plan, 2, 1), Vector2i(1, 0), "roof above; a door joins its neighbours' house")
	assert_eq(_piece(plan, 1, 3), Vector2i(0, 3), "wall next to the door")


func test_ruins_borrow_ground_and_break_their_top() -> void:
	var plan := GroundArt.plan(_house_maps(["ggg", "grg", "grg", "ggg"]), "m", false)
	assert_eq(plan[Vector2i(1, 1)]["base"], [T, Vector2i(1, 10)], "grass shows through the broken top")
	assert_eq(plan[Vector2i(1, 1)]["over"][0], "houses")
	assert_eq(_piece(plan, 1, 1), Vector2i(15, 0), "two rows of ruin: the top is the broken row")
	assert_eq(_piece(plan, 1, 2), Vector2i(15, 3))


func test_house_winter_look_and_a_missing_sheet() -> void:
	var maps := _house_maps(["ghg"])
	assert_eq(GroundArt.house_look(maps.tiles["home"], true)["block"], Vector2i(20, 0))
	assert_eq(GroundArt.house_look(maps.tiles["home"], false)["block"], Vector2i(0, 0))
	assert_eq(GroundArt.house_look(maps.tiles["home_door"], false)["door"], true)
	assert_eq(GroundArt.house_look(maps.tiles["home"], false)["key"], GroundArt.house_look(maps.tiles["home_b"], false)["key"])
	var def: Dictionary = (maps.tiles["home"] as Dictionary).duplicate(true)
	def["house"]["sheet"] = "no_such_sheet"
	assert_eq(GroundArt.house_look(def, false), {}, "no sheet: the colour square")
	assert_eq(GroundArt.house_look({"walk": true}, false), {})


func test_no_tree_stands_in_front_of_a_house_or_a_wall() -> void:
	var maps := MapDb.load_dir()
	for area: String in maps.areas:
		var size := maps.size(area)
		for y in size.y:
			for x in size.x:
				if maps.tile_at(area, Vector2i(x, y)) != "tree":
					continue
				for k in range(1, 5):
					var def: Dictionary = maps.tiles.get(maps.tile_at(area, Vector2i(x, y - k)), {})
					assert_false(def.has("house") or maps.tile_at(area, Vector2i(x, y - k)) == "city_wall",
						"%s: the tree at (%d, %d) hides the wall at (%d, %d)" % [area, x, y, x, y - k])


func test_ground_with_no_z_keeps_hard_edges_and_props_borrow_ground() -> void:
	var plan := GroundArt.plan(_maps(["wggg", "w^gx", "wggd"]), "m", false)
	assert_false(plan[Vector2i(1, 0)].has("over"), "a wall (no z) is not lower ground")
	assert_eq(plan[Vector2i(0, 1)], {"base": ["lpc_atlas", Vector2i(17, 24)]})
	assert_eq(plan[Vector2i(1, 1)]["base"], [T, Vector2i(1, 10)], "the rock stands on the grass above it")
	assert_false(plan.has(Vector2i(3, 1)), "no art: left out (the colour square)")
	assert_true(plan[Vector2i(2, 1)].has("over"), "grass on a corner of the dirt")


func test_missing_sheet_or_winter_art_falls_back() -> void:
	var tiles := _tiles()
	tiles["dirt"]["sprite"]["sheet"] = "no_such_sheet"
	tiles["grass"]["winter_sprite"] = {"sheet": T, "cells": [[22, 10]], "edges": [21, 7], "z": 3}
	var a := ToyMaps.area("m", "toy_town", ["gd"], {}, [], [])
	a["legend"] = {"g": "grass", "d": "dirt"}
	var maps := MapDb.from_dicts(tiles, {"m": a})
	var plan := GroundArt.plan(maps, "m", false)
	assert_false(plan.has(Vector2i(1, 0)))
	assert_false(plan[Vector2i(0, 0)].has("over"), "no art next door: no edge")
	assert_eq(GroundArt.plan(maps, "m", true)[Vector2i(0, 0)]["base"], [T, Vector2i(22, 10)], "snow")


func test_object_look_reads_objects_json_entries() -> void:
	var kinds := {
		"stove": {"sheet": "lpc_interior", "region": [352, 256, 32, 32]},
		"fire": {"sheet": "tavern_cooking", "region": [224, 224, 32, 32], "frames": 4,
			"winter_region": [224, 192, 32, 32]},
		"ghost": {"sheet": "no_such_sheet", "region": [0, 0, 32, 32]},
	}
	var stove := WorldView.object_look({"kind": "stove"}, kinds)
	assert_eq(stove["region"], Rect2(352, 256, 32, 32))
	assert_eq(stove["frames"], 1)
	assert_eq(WorldView.object_look({"kind": "fire"}, kinds)["frames"], 4)
	assert_eq(WorldView.object_look({"kind": "fire"}, kinds, true)["region"], Rect2(224, 192, 32, 32))
	assert_eq(WorldView.object_look({"kind": "ghost"}, kinds), {}, "missing sheet: square")
	assert_eq(WorldView.object_look({"kind": "nope"}, kinds), {})
	assert_eq(WorldView.object_look({}, kinds), {}, "no kind: square")


func test_objects_with_art_are_sprites_and_fires_animate() -> void:
	var d := ToyMaps.db()
	d.maps.areas["town"]["objects"][0]["kind"] = "fire"
	var v: WorldView = add_child_autofree(load("res://world/world_view.tscn").instantiate())
	v.setup(d.maps)
	v.object_art = {"fire": {"sheet": "tavern_cooking", "region": [224, 224, 32, 32], "frames": 4}}
	v.refresh(ToyMaps.new_game(d))
	assert_eq(v.props.get_child_count(), 1, "the stove is a sprite")
	var s: Sprite2D = v.props.get_child(0)
	assert_eq(s.position, WorldView.cell_center(Vector2i(2, 3)))
	assert_eq(s.region_rect, Rect2(224, 224, 32, 32))
	var labels := v.marks.get_children().filter(func(n: Node) -> bool: return n is Label)
	assert_eq(labels.size(), 1, "only the dummy (no kind) keeps its square and letter")
	v._process(1.0 / WorldView.ANIM_FPS + 0.001)
	assert_eq(s.region_rect.position.x, 256.0, "next frame")
	v._process(3.0 / WorldView.ANIM_FPS)
	assert_eq(s.region_rect.position.x, 224.0, "frames wrap")


func test_view_draws_soft_edges_in_the_edges_layer() -> void:
	var v: WorldView = add_child_autofree(load("res://world/world_view.tscn").instantiate())
	v.setup(_maps(["ggggg", "ggdgg", "ggggg"]))
	var gs := GameState.new(1)
	gs.player.place("m", Vector2i(0, 0))
	v.refresh(gs)
	assert_eq(v.edges.get_cell_atlas_coords(Vector2i(2, 0)), Vector2i(1, 11))
	assert_eq(v.tiles.get_cell_atlas_coords(Vector2i(2, 0)), Vector2i(1, 3), "dirt under the edge")
	assert_eq(v.edges.get_cell_source_id(Vector2i(4, 1)), -1, "no edge on plain grass")


func test_every_real_tile_and_map_object_has_art() -> void:
	var maps := MapDb.load_dir()
	for id: String in maps.tiles:
		var def: Dictionary = maps.tiles[id]
		var has_art := false
		for key: String in ["sprite", "winter_sprite"]:
			if not def.has(key):
				continue
			var sp: Dictionary = def[key]
			var path := WorldView.sheet_path(sp["sheet"])
			assert_ne(path, "", "tile %s: sheet %s" % [id, sp["sheet"]])
			if path == "":
				continue
			var cells := Vector2i((load(path) as Texture2D).get_size()) / WorldView.TILE
			var used: Array = sp["cells"].duplicate()
			if sp.has("edges"):
				used.append([sp["edges"][0] + 2, sp["edges"][1] + 5])
			for c: Array in used:
				assert_true(int(c[0]) < cells.x and int(c[1]) < cells.y, "tile %s: cell %s inside %s" % [id, c, sp["sheet"]])
			has_art = true
		has_art = has_art or def.has("prop")
		for key: String in ["cliff", "winter_cliff"]:
			if def.has(key):
				var look := GroundArt.cliff_look({"cliff": def[key]}, false)
				assert_false(look.is_empty(), "tile %s: %s sheet exists" % [id, key])
				if not look.is_empty():
					var size := (load(WorldView.sheet_path(look["sheet"])) as Texture2D).get_size() / WorldView.TILE
					var b: Vector2i = look["block"]
					assert_true(b.x + 3 <= int(size.x) and b.y + 4 <= int(size.y), "tile %s: %s block inside the sheet" % [id, key])
				has_art = true
		for key: String in ["house", "winter_house"]:
			if def.has(key):
				var look := GroundArt.house_look({"house": def[key]}, false)
				assert_false(look.is_empty(), "tile %s: %s sheet exists" % [id, key])
				if not look.is_empty():
					var size := (load(WorldView.sheet_path(look["sheet"])) as Texture2D).get_size() / WorldView.TILE
					var b: Vector2i = look["block"]
					assert_true(b.x + 5 <= int(size.x) and b.y + 4 <= int(size.y), "tile %s: %s block inside the sheet" % [id, key])
				has_art = true
		assert_true(has_art, "tile %s has art" % id)
	var kinds := WorldView.load_object_art()
	assert_gt(kinds.size(), 0)
	for kind: String in kinds:
		var art: Dictionary = kinds[kind]
		var path := WorldView.sheet_path(art["sheet"])
		assert_ne(path, "", "kind %s: sheet %s" % [kind, art["sheet"]])
		if path == "":
			continue
		var r: Array = art["region"]
		var size := (load(path) as Texture2D).get_size()
		var right := int(r[0]) + int(r[2]) * int(art.get("frames", 1))
		assert_true(right <= size.x and int(r[1]) + int(r[3]) <= size.y, "kind %s: region inside the sheet" % kind)
	for area: String in maps.areas:
		for o: Dictionary in maps.areas[area]["objects"]:
			assert_false(WorldView.object_look(o, kinds).is_empty(), "%s: object %s has art" % [area, o["id"]])
