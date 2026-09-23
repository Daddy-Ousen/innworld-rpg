## World maps (ADR 0006): tile types from data/tiles.json and one grid map
## per area from data/maps/<area>.json. Read-only after load.
class_name MapDb
extends RefCounted

const SCHEMA_VERSION := 1
const TILE_FIELDS := ["name", "walk", "color"]
const MAP_FIELDS := ["id", "name", "location", "confidence", "legend", "rows", "zones",
	"exits", "objects"]
const EXIT_FIELDS := ["at", "to", "arrive", "minutes"]
const OBJECT_FIELDS := ["id", "at", "name", "actions"]

## tile id → {"name", "walk", "color"}.
var tiles: Dictionary = {}
## area id → map dictionary (the JSON file).
var areas: Dictionary = {}
var errors: Array[String] = []
## area id → {Vector2i: object} for solid objects.
var _solid: Dictionary = {}


## Loads `dir`/tiles.json and every `dir`/maps/*.json (sorted). A missing
## file or folder gives an empty db; validate() reports what is missing.
static func load_dir(dir: String = "res://data") -> MapDb:
	var load_errors: Array[String] = []
	var t := {}
	var path := dir.path_join("tiles.json")
	if FileAccess.file_exists(path):
		t = _read_json(path, load_errors).get("tiles", {})
	var a := {}
	var maps_dir := dir.path_join("maps")
	if DirAccess.dir_exists_absolute(maps_dir):
		var files := Array(DirAccess.get_files_at(maps_dir)).filter(
				func(f: String) -> bool: return f.ends_with(".json"))
		files.sort()
		for f: String in files:
			var m := _read_json(maps_dir.path_join(f), load_errors)
			if m.is_empty():
				continue
			var id: String = m.get("id", "")
			if id != f.get_basename():
				load_errors.append("maps/%s: id '%s' must match the file name." % [f, id])
			a[f.get_basename()] = m
	var db := from_dicts(t, a)
	db.errors = load_errors
	return db


## Builds a map db from dictionaries (toy tests). Call validate() to check it.
static func from_dicts(tile_map: Dictionary, area_map: Dictionary) -> MapDb:
	var db := MapDb.new()
	db.tiles = tile_map
	db.areas = area_map
	for id: String in area_map:
		var solid := {}
		for o: Dictionary in area_map[id].get("objects", []):
			if o.get("solid", false) and o.get("at", []).size() == 2:
				solid[Vector2i(int(o["at"][0]), int(o["at"][1]))] = o
		db._solid[id] = solid
	return db


static func _read_json(path: String, errs: Array[String]) -> Dictionary:
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or not json.data is Dictionary:
		errs.append("%s: invalid JSON at line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return {}
	var d: Dictionary = json.data
	if int(d.get("schema_version", -1)) != SCHEMA_VERSION:
		errs.append("%s: schema_version must be %d." % [path, SCHEMA_VERSION])
	return d


func is_empty() -> bool:
	return areas.is_empty()


func size(area: String) -> Vector2i:
	var rows: Array = areas[area]["rows"]
	return Vector2i((rows[0] as String).length() if not rows.is_empty() else 0, rows.size())


func in_bounds(area: String, at: Vector2i) -> bool:
	var s := size(area)
	return at.x >= 0 and at.y >= 0 and at.x < s.x and at.y < s.y


## Tile id at `at`, or "" outside the map.
func tile_at(area: String, at: Vector2i) -> String:
	if not in_bounds(area, at):
		return ""
	var row: String = areas[area]["rows"][at.y]
	if at.x >= row.length():
		return ""
	return areas[area]["legend"].get(row[at.x], "")


## True if the tile can be walked on and no solid object stands on it.
func is_walkable(area: String, at: Vector2i) -> bool:
	var walk: Variant = tiles.get(tile_at(area, at), {}).get("walk", false)
	return walk is bool and walk \
			and not _solid.get(area, {}).has(at)


## The exit whose rect holds `at`, or {}.
func exit_at(area: String, at: Vector2i) -> Dictionary:
	for e: Dictionary in areas[area]["exits"]:
		if rect_of(e["at"]).has_point(at):
			return e
	return {}


## Where a step onto `at` inside exit `e` lands: arrive + the offset in the rect.
static func arrival(e: Dictionary, at: Vector2i) -> Vector2i:
	var r := rect_of(e["at"])
	return Vector2i(int(e["arrive"][0]), int(e["arrive"][1])) + (at - r.position)


## The first zone (by id) with a rect that holds `at`, or "".
func zone_at(area: String, at: Vector2i) -> String:
	var zones: Dictionary = areas[area]["zones"]
	var ids := zones.keys()
	ids.sort()
	for id: String in ids:
		for r: Array in zones[id]:
			if rect_of(r).has_point(at):
				return id
	return ""


## Objects on or next to `at` (8 neighbours), nearest first, then by id.
func objects_near(area: String, at: Vector2i) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for o: Dictionary in areas[area]["objects"]:
		var d := _dist(at, _vec(o["at"]))
		if d <= 1:
			out.append(o)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var da := _dist(at, _vec(a["at"]))
		var dbb := _dist(at, _vec(b["at"]))
		return da < dbb or (da == dbb and String(a["id"]) < String(b["id"])))
	return out


## [x, y] or [x, y, w, h] → Rect2i (w and h default to 1).
static func rect_of(a: Array) -> Rect2i:
	var w := int(a[2]) if a.size() == 4 else 1
	var h := int(a[3]) if a.size() == 4 else 1
	return Rect2i(int(a[0]), int(a[1]), w, h)


static func _vec(a: Array) -> Vector2i:
	return Vector2i(int(a[0]), int(a[1]))


static func _dist(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


## Checks tiles and maps against each other, the actions, the canon
## locations and rules.world.start. Appends to `errors` and returns them.
func validate(db: DataDb) -> Array[String]:
	for id: String in tiles:
		_validate_tile(id, tiles[id])
	for id: String in areas:
		_validate_map(id, areas[id], db)
	var start: Dictionary = db.rules.get("world", {}).get("start", {})
	var area: String = start.get("area", "")
	if not areas.has(area):
		errors.append("rules.world.start: unknown area '%s'." % area)
	elif not _pos_ok(start.get("pos", [])) or not is_walkable(area, _vec(start["pos"])):
		errors.append("rules.world.start: pos must be a walkable tile of '%s'." % area)
	return errors


func _validate_tile(id: String, t: Dictionary) -> void:
	for f: String in TILE_FIELDS:
		if not t.has(f):
			errors.append("tile '%s': missing '%s'." % [id, f])
	if t.has("walk") and not t["walk"] is bool:
		errors.append("tile '%s': walk must be true or false." % id)
	if t.has("color") and not Color.html_is_valid(str(t["color"])):
		errors.append("tile '%s': color must be a #rrggbb colour." % id)


func _validate_map(id: String, m: Dictionary, db: DataDb) -> void:
	var where := "map '%s'" % id
	var missing := false
	for f: String in MAP_FIELDS:
		if not m.has(f):
			errors.append("%s: missing '%s'." % [where, f])
			missing = true
	if missing:
		return
	if not DataDb.CONFIDENCE.has(m["confidence"]):
		errors.append("%s: confidence must be one of %s." % [where, DataDb.CONFIDENCE])
	if not db.canon.locations.has(m["location"]):
		errors.append("%s: unknown canon location '%s'." % [where, m["location"]])
	var legend: Dictionary = m["legend"]
	for ch: String in legend:
		if ch.length() != 1:
			errors.append("%s legend: key '%s' must be one character." % [where, ch])
		if not tiles.has(legend[ch]):
			errors.append("%s legend: unknown tile '%s'." % [where, legend[ch]])
	var rows: Array = m["rows"]
	if rows.is_empty():
		errors.append("%s: needs at least one row." % where)
		return
	var width := (rows[0] as String).length()
	for y in rows.size():
		var row: String = rows[y]
		if row.length() != width:
			errors.append("%s row %d: width %d, expected %d." % [where, y, row.length(), width])
			return
		for ch in row:
			if not legend.has(ch):
				errors.append("%s row %d: '%s' is not in the legend." % [where, y, ch])
				return
	var bounds := Rect2i(Vector2i.ZERO, size(id))
	for zone: String in m["zones"]:
		if not db.canon.locations.has(zone):
			errors.append("%s zone: unknown canon location '%s'." % [where, zone])
		for r: Variant in m["zones"][zone]:
			if not _rect_ok(r) or not bounds.encloses(rect_of(r)):
				errors.append("%s zone '%s': rects must be [x, y, w, h] inside the map." % [where, zone])
	for e: Dictionary in m["exits"]:
		_validate_exit(where, id, e, bounds, db)
	var seen := {}
	for o: Dictionary in m["objects"]:
		_validate_object(where, o, bounds, seen, db)


func _validate_exit(where: String, id: String, e: Dictionary, bounds: Rect2i, db: DataDb) -> void:
	for f: String in EXIT_FIELDS:
		if not e.has(f):
			errors.append("%s exit: missing '%s'." % [where, f])
			return
	where = "%s exit to '%s'" % [where, e["to"]]
	if not _rect_ok(e["at"]) or not bounds.encloses(rect_of(e["at"])):
		errors.append("%s: 'at' must be [x, y] or [x, y, w, h] inside the map." % where)
		return
	if int(e["minutes"]) < 0:
		errors.append("%s: minutes must be >= 0." % where)
	elif int(e["minutes"]) > 0 and not db.actions.has("travel"):
		errors.append("%s: minutes > 0 needs the action 'travel'." % where)
	if not areas.has(e["to"]):
		errors.append("%s: unknown map." % where)
		return
	if not _pos_ok(e["arrive"]):
		errors.append("%s: arrive must be [x, y]." % where)
		return
	var r := rect_of(e["at"])
	for yy in range(r.position.y, r.end.y):
		for xx in range(r.position.x, r.end.x):
			var from := Vector2i(xx, yy)
			if not is_walkable(id, from):
				errors.append("%s: tile %s is not walkable." % [where, from])
			var to := arrival(e, from)
			if not in_bounds(e["to"], to) or not is_walkable(e["to"], to):
				errors.append("%s: arrive tile %s is not walkable." % [where, to])
			elif not exit_at(e["to"], to).is_empty():
				errors.append("%s: arrive tile %s is an exit." % [where, to])


func _validate_object(where: String, o: Dictionary, bounds: Rect2i, seen: Dictionary,
		db: DataDb) -> void:
	for f: String in OBJECT_FIELDS:
		if not o.has(f):
			errors.append("%s object: missing '%s'." % [where, f])
			return
	where = "%s object '%s'" % [where, o["id"]]
	if seen.has(o["id"]):
		errors.append("%s: duplicate id." % where)
	seen[o["id"]] = true
	if not _pos_ok(o["at"]) or not bounds.has_point(_vec(o["at"])):
		errors.append("%s: 'at' must be [x, y] inside the map." % where)
	if (o["actions"] as Array).is_empty():
		errors.append("%s: needs at least one action." % where)
	for a: Variant in o["actions"]:
		if not db.actions.has(a):
			errors.append("%s: unknown action '%s'." % [where, a])
	if o.has("context") and not o["context"] is Dictionary:
		errors.append("%s: context must be an object." % where)


static func _pos_ok(a: Variant) -> bool:
	return a is Array and (a as Array).size() == 2


static func _rect_ok(a: Variant) -> bool:
	return a is Array and ((a as Array).size() == 2 or (a as Array).size() == 4)
