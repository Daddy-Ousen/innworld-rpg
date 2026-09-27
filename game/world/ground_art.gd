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
class_name GroundArt
extends RefCounted

const UP := Vector2i(0, -1)
const DOWN := Vector2i(0, 1)
const LEFT := Vector2i(-1, 0)
const RIGHT := Vector2i(1, 0)
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
			if WorldView.sprite_def(def, winter, "prop").is_empty():
				continue
			for d in AROUND:
				var n: Dictionary = looks.get(cell + d, {})
				if not n.is_empty() and not borrowed.has(cell + d):
					borrowed[cell] = n
					break
	for cell: Vector2i in borrowed:
		looks[cell] = borrowed[cell]
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
			var piece: Variant = edge_piece(low)
			if piece != null:
				entry["base"] = [under["sheet"], WorldView.pick_cell(under["cells"], cell)]
				entry["over"] = [lk["sheet"], (lk["edges"] as Vector2i) + (piece as Vector2i)]
		out[cell] = entry
	return out


## The edge piece (offset in the 3×6 block) for a cell whose lower neighbours
## are the keys of `low` (directions), or null for none. A cell with lower
## ground on two opposite sides keeps a hard edge (LPC has no piece for it).
static func edge_piece(low: Dictionary) -> Variant:
	var n := low.has(UP)
	var s := low.has(DOWN)
	var w := low.has(LEFT)
	var e := low.has(RIGHT)
	if (n and s) or (w and e):
		return null
	if n and w:
		return Vector2i(0, 2)
	if n and e:
		return Vector2i(2, 2)
	if s and w:
		return Vector2i(0, 4)
	if s and e:
		return Vector2i(2, 4)
	if n:
		return Vector2i(1, 2)
	if s:
		return Vector2i(1, 4)
	if w:
		return Vector2i(0, 3)
	if e:
		return Vector2i(2, 3)
	if low.has(Vector2i(1, 1)):
		return Vector2i(1, 0)
	if low.has(Vector2i(-1, 1)):
		return Vector2i(2, 0)
	if low.has(Vector2i(1, -1)):
		return Vector2i(1, 1)
	if low.has(Vector2i(-1, -1)):
		return Vector2i(2, 1)
	return null
