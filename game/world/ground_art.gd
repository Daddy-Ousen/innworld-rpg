## Ground art for one map (M11.1, ADR 0018): which sheet cell each map cell
## draws, with soft edges between terrains. Pure: reads MapDb, builds no nodes,
## so it runs headless.
## A tile's "sprite" (or "winter_sprite") may have "edges": [x, y], the top-left
## cell of an LPC terrain block (3 cells wide, 6 high: rows 0-1 inner corners,
## rows 2-4 the edge ring, row 5 fills), and "z" (a number). A cell whose
## terrain has edges draws a soft edge where a side or corner neighbour has a
## different terrain with a lower z: the neighbour's ground goes under, the
## edge piece over. Neighbours with no "z" (walls, buildings) keep hard edges.
## A tile with a prop and no sprite (a tree, a rock) borrows the ground of a
## neighbour, so a rock on a cave floor stands on cave floor.
## A tile may have "cliff": {"sheet", "block": [x, y]} (and "winter_cliff"): the
## top-left cell of a 3×4 cliff block (tools/build_cliffs.py). Cliff cells of one
## block form a wall mass; each cell draws the piece for its place in the mass
## (see `cliff_piece`) over the ground borrowed from a neighbour.
class_name GroundArt
extends RefCounted

const UP := Vector2i(0, -1)
const DOWN := Vector2i(0, 1)
const LEFT := Vector2i(-1, 0)
const RIGHT := Vector2i(1, 0)
## The plain fill piece of an edge block (3×6): row 5, middle.
const FILL := Vector2i(1, 5)
## Sides first, then corners: the first lower neighbour gives the ground under an edge.
const AROUND: Array[Vector2i] = [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1),
	Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]


## The ground look of a tile def: {"sheet", "cells": Array[Vector2i],
## "edges": Vector2i (or absent), "z": float (or absent), "key"}; {} = no art.
## Two tiles with the same key are one terrain (no edge between them).
static func look(def: Dictionary, winter: bool) -> Dictionary:
	var sp := WorldView.sprite_def(def, winter)
	if sp.is_empty() or WorldView.sheet_path(String(sp.get("sheet", ""))) == "":
		return {}
	var cells: Array[Vector2i] = []
	for c: Array in sp.get("cells", []):
		cells.append(Vector2i(int(c[0]), int(c[1])))
	if cells.is_empty():
		return {}
	var out := {"sheet": String(sp["sheet"]), "cells": cells, "key": "%s|%s" % [sp["sheet"], cells]}
	if sp.get("edges") is Array and (sp["edges"] as Array).size() == 2:
		out["edges"] = Vector2i(int(sp["edges"][0]), int(sp["edges"][1]))
		out["key"] = "%s|%s" % [sp["sheet"], out["edges"]]
	if sp.has("z"):
		out["z"] = float(sp["z"])
	return out


## The cliff look of a tile def: {"sheet", "block": Vector2i, "key"}; {} = none.
static func cliff_look(def: Dictionary, winter: bool) -> Dictionary:
	var cliff: Variant = def.get("winter_cliff") if winter and def.has("winter_cliff") else def.get("cliff")
	if not cliff is Dictionary or WorldView.sheet_path(String((cliff as Dictionary).get("sheet", ""))) == "":
		return {}
	var block: Array = cliff.get("block", [])
	if block.size() != 2:
		return {}
	return {"sheet": String(cliff["sheet"]), "block": Vector2i(int(block[0]), int(block[1])),
		"key": "%s|%s" % [cliff["sheet"], block]}


## The piece (column 0-2, row 0-3 of the 3×4 block) for a cell of a wall mass.
## `same(dir)` says whether the neighbour there is in the same mass (the map
## edge counts as the mass, so a wall along the edge shows no rim or face).
## Row 3 is the front face (nothing of the mass below), row 2 the face's upper
## half (one cell of mass below), row 0 the top rim (no mass above), row 1 the
## top surface. Column 0 / 2 = no mass to the left / right.
static func cliff_piece(same: Callable) -> Vector2i:
	var row := 1
	if not same.call(DOWN):
		row = 3
	elif not same.call(DOWN * 2):
		row = 2
	elif not same.call(UP):
		row = 0
	var col := 1
	if not same.call(LEFT):
		col = 0
	elif not same.call(RIGHT):
		col = 2
	return Vector2i(col, row)


## cell → {"base": [sheet, Vector2i]} plus "over": [sheet, Vector2i] where a
## soft edge is drawn. Cells with no art are left out (the colour square).
static func plan(maps: MapDb, area: String, winter: bool) -> Dictionary:
	var size := maps.size(area)
	var looks := {}
	var by_tile := {}
	for y in size.y:
		for x in size.x:
			var cell := Vector2i(x, y)
			var t := maps.tile_at(area, cell)
			if not by_tile.has(t):
				by_tile[t] = look(maps.tiles.get(t, {}), winter)
			looks[cell] = by_tile[t]
	var borrowed := {}
	for y in size.y:
		for x in size.x:
			var cell := Vector2i(x, y)
			if not (looks[cell] as Dictionary).is_empty():
				continue
			var def: Dictionary = maps.tiles.get(maps.tile_at(area, cell), {})
			if WorldView.sprite_def(def, winter, "prop").is_empty() and cliff_look(def, winter).is_empty():
				continue
			for d in AROUND:
				var n: Dictionary = looks.get(cell + d, {})
				if not n.is_empty() and not borrowed.has(cell + d):
					borrowed[cell] = n
					break
	for cell: Vector2i in borrowed:
		looks[cell] = borrowed[cell]
	var cliffs := {}
	for cell: Vector2i in looks:
		var cl := cliff_look(maps.tiles.get(maps.tile_at(area, cell), {}), winter)
		if not cl.is_empty():
			cliffs[cell] = cl
	var out := {}
	for cell: Vector2i in looks:
		var lk: Dictionary = looks[cell]
		if lk.is_empty():
			continue
		var entry := {"base": [lk["sheet"], WorldView.pick_cell(lk["cells"], cell)]}
		if lk.has("edges") and lk.has("z"):
			var low := {}
			var under := {}
			for d in AROUND:
				var n: Dictionary = looks.get(cell + d, {})
				if n.has("z") and n["key"] != lk["key"] and float(n["z"]) < float(lk["z"]):
					low[d] = true
					if under.is_empty():
						under = n
			var pieces := edge_pieces(low)
			if not pieces.is_empty():
				entry["base"] = [under["sheet"], WorldView.pick_cell(under["cells"], cell)]
				var block: Vector2i = lk["edges"]
				if pieces.size() == 1:
					entry["over"] = [lk["sheet"], block + pieces[0]]
				else:
					var cells: Array[Vector2i] = []
					for p in pieces:
						cells.append(block + p)
					entry["mix"] = {"sheet": lk["sheet"], "cells": cells, "fill": block + FILL}
		out[cell] = entry
	for cell: Vector2i in cliffs:
		var cl: Dictionary = cliffs[cell]
		var same := func(d: Vector2i) -> bool:
			var n: Vector2i = cell + d
			return n.x < 0 or n.y < 0 or n.x >= size.x or n.y >= size.y 					or (cliffs.get(n, {}) as Dictionary).get("key", "") == cl["key"]
		var art := [cl["sheet"], (cl["block"] as Vector2i) + cliff_piece(same)]
		var entry: Dictionary = out.get(cell, {})
		entry.erase("mix")
		if entry.is_empty():
			entry["base"] = art
		else:
			entry["over"] = art
		out[cell] = entry
	return out


## The edge pieces (offsets in the 3×6 block) for a cell whose lower neighbours
## are the keys of `low` (directions): none, one, or several. A cell with lower
## ground on opposite sides (a one-cell strip) or on three or four sides has no
## single LPC piece, so it gets one piece per corner or side and the view mixes
## them (`mix`). Corners come first (NW, NE, SW, SE), then sides no corner covers.
static func edge_pieces(low: Dictionary) -> Array[Vector2i]:
	var n := low.has(UP)
	var s := low.has(DOWN)
	var w := low.has(LEFT)
	var e := low.has(RIGHT)
	var out: Array[Vector2i] = []
	var covered := {}
	for corner: Array in [[n, w, Vector2i(0, 2), UP, LEFT], [n, e, Vector2i(2, 2), UP, RIGHT],
			[s, w, Vector2i(0, 4), DOWN, LEFT], [s, e, Vector2i(2, 4), DOWN, RIGHT]]:
		if corner[0] and corner[1]:
			out.append(corner[2])
			covered[corner[3]] = true
			covered[corner[4]] = true
	for side: Array in [[n, Vector2i(1, 2), UP], [s, Vector2i(1, 4), DOWN],
			[w, Vector2i(0, 3), LEFT], [e, Vector2i(2, 3), RIGHT]]:
		if side[0] and not covered.has(side[2]):
			out.append(side[1])
	if not out.is_empty():
		return out
	for diagonal: Array in [[Vector2i(1, 1), Vector2i(1, 0)], [Vector2i(-1, 1), Vector2i(2, 0)],
			[Vector2i(1, -1), Vector2i(1, 1)], [Vector2i(-1, -1), Vector2i(2, 1)]]:
		if low.has(diagonal[0]):
			out.append(diagonal[1])
			return out
	return out


## The single piece for a cell with one edge case, or null (kept for callers
## and tests that want one piece; several pieces = `edge_pieces`).
static func edge_piece(low: Dictionary) -> Variant:
	var pieces := edge_pieces(low)
	return pieces[0] if pieces.size() == 1 else null


## One tile made of several edge pieces of one block: a pixel is see-through
## where any piece is (the lower ground shows there), and takes the colour of
## the piece that differs from the plain fill (the bank), else the fill. `sheet`
## is the sheet image, `cells` the piece cells, `fill` the block's plain fill cell.
static func mix(sheet: Image, cells: Array[Vector2i], fill: Vector2i, tile: int) -> Image:
	var out := Image.create(tile, tile, false, Image.FORMAT_RGBA8)
	var parts: Array[Image] = []
	for c in cells:
		parts.append(sheet.get_region(Rect2i(c * tile, Vector2i(tile, tile))))
	var plain := sheet.get_region(Rect2i(fill * tile, Vector2i(tile, tile)))
	for y in tile:
		for x in tile:
			var base := plain.get_pixel(x, y)
			var colour := base
			var see_through := false
			for part in parts:
				var px := part.get_pixel(x, y)
				if px.a < 0.5:
					see_through = true
					break
				if colour == base and px != base:
					colour = px
			if not see_through:
				out.set_pixel(x, y, colour)
	return out
