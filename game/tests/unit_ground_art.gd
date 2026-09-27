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
	assert_eq(GroundArt.edge_piece({up: true, down: true}), null, "a one-cell strip keeps a hard edge")


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
