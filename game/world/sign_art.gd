## Door and shop signs for one map (M16.3, ADR 0023). Pure: reads MapDb, builds
## no nodes, so it runs headless. `WorldView` draws what `marks` returns.
## A map object or an exit may have "sign": {"icon": <key of data/objects.json "signs">,
## "text"?: label}. Marks:
##   "sign"  a hanging sign (icon + label) for a signed exit or object;
##   "arrow" one per cell of an exit with no sign and nothing standing on it, pointing to
##           the nearest map edge (the way out); the first cell also holds the label;
##   "label" text only, for an exit under an object (stairs, a door prop).
## A label reads "To <destination map name>" unless the sign gives its own text.
## Where a sign hangs ("place"): "here" for a plaque (the sign is the whole object),
## "right" / "left" on a wall next to a door, or "above" the cell.
class_name SignArt
extends RefCounted

const PLAQUE := "plaque"
## Labels show fully within FULL cells of the player (king moves) and fade out by GONE cells.
const FULL := 2
const GONE := 4


## data/objects.json "signs": icon id -> [x, y, w, h] pixels on the "signs" sheet ({} when missing).
static func load_table(path: String = WorldView.OBJECT_ART_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not d is Dictionary or not (d as Dictionary).get("signs", {}) is Dictionary:
		return {}
	return (d as Dictionary).get("signs", {})


## The sheet region of an icon, or an empty Rect2 (size 0) when the icon or its art is missing.
static func icon_region(table: Dictionary, icon: String) -> Rect2:
	var r: Variant = table.get(icon)
	if not r is Array or (r as Array).size() != 4 or WorldView.sheet_path("signs") == "":
		return Rect2()
	return Rect2(r[0], r[1], r[2], r[3])


## 0..1: how much of a label shows when the player is `dist` cells away (king moves).
static func label_alpha(dist: int) -> float:
	if dist <= FULL:
		return 1.0
	if dist >= GONE:
		return 0.0
	return 1.0 - float(dist - FULL) / float(GONE - FULL)


static func king_dist(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


## Every mark on `area`: {"kind": "sign" | "arrow" | "label", "cell", "icon", "text", "dir": Vector2i,
## "place", "source": "exit" | "object", "id"}. Hidden exits and flag-hidden objects give none.
static func marks(maps: MapDb, area: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var objects := maps.objects_on(area)
	var standing := {}
	for o: Dictionary in objects:
		standing[Vector2i(int(o["at"][0]), int(o["at"][1]))] = true
	for e: Dictionary in maps.exits_on(area):
		var r := MapDb.rect_of(e["at"])
		var sign_def: Dictionary = e.get("sign", {}) if e.get("sign", {}) is Dictionary else {}
		var text := String(sign_def.get("text", "")) if not sign_def.is_empty() else ""
		if text == "":
			text = _to_text(maps, String(e["to"]), not sign_def.is_empty())
		var first := r.position
		if not sign_def.is_empty():
			out.append({"kind": "sign", "cell": first, "icon": String(sign_def.get("icon", "")), "text": text,
				"dir": Vector2i.ZERO, "place": _place(maps, area, first), "source": "exit", "id": String(e.get("id", ""))})
			continue
		var covered := false
		for yy in range(r.position.y, r.end.y):
			for xx in range(r.position.x, r.end.x):
				covered = covered or standing.has(Vector2i(xx, yy))
		if covered:
			out.append({"kind": "label", "cell": first, "icon": "", "text": text, "dir": Vector2i.ZERO,
				"place": "above", "source": "exit", "id": String(e.get("id", ""))})
			continue
		for yy in range(r.position.y, r.end.y):
			for xx in range(r.position.x, r.end.x):
				var cell := Vector2i(xx, yy)
				out.append({"kind": "arrow", "cell": cell, "icon": "", "text": text if cell == first else "",
					"dir": edge_dir(maps.size(area), cell), "place": "above", "source": "exit",
					"id": String(e.get("id", ""))})
	for o: Dictionary in objects:
		var s: Variant = o.get("sign", {})
		if not s is Dictionary or (s as Dictionary).is_empty():
			continue
		var cell := Vector2i(int(o["at"][0]), int(o["at"][1]))
		var label := String((s as Dictionary).get("text", ""))
		out.append({"kind": "sign", "cell": cell, "icon": String((s as Dictionary).get("icon", "")),
			"text": label if label != "" else String(o.get("name", "")), "dir": Vector2i.ZERO,
			"place": "here" if String(o.get("kind", "")) == PLAQUE else _place(maps, area, cell),
			"source": "object", "id": String(o["id"])})
	return out


## "To <map name>" (a signed exit shows the bare name).
static func _to_text(maps: MapDb, to: String, bare: bool) -> String:
	var place := String(maps.areas.get(to, {}).get("name", to))
	return place if bare else "To " + place


## Where the sign at `cell` hangs: on a wall cell to the right, then the left, else above.
static func _place(maps: MapDb, area: String, cell: Vector2i) -> String:
	for side: Array in [["right", Vector2i.RIGHT], ["left", Vector2i.LEFT]]:
		var n: Vector2i = cell + (side[1] as Vector2i)
		if maps.in_bounds(area, n) and not bool(maps.tiles.get(maps.tile_at(area, n), {}).get("walk", false)):
			return side[0]
	return "above"


## The way from `cell` to the nearest map edge (ties: down, up, left, right).
static func edge_dir(size: Vector2i, cell: Vector2i) -> Vector2i:
	var best := Vector2i.DOWN
	var best_d := size.y - 1 - cell.y
	for c: Array in [[Vector2i.UP, cell.y], [Vector2i.LEFT, cell.x], [Vector2i.RIGHT, size.x - 1 - cell.x]]:
		if int(c[1]) < best_d:
			best = c[0]
			best_d = int(c[1])
	return best
