## NPC behaviour data (M4.4, ADR 0008): data/npc_behaviour.json. Design
## data next to the canon NPCs (their schema stays as it is). Read-only
## after load.
##   entries: off-map place → {map id → [x, y]}: where NPCs from that place
##            (e.g. "liscor", the city beyond the maps) come in and go out.
##   npcs: canon NPC id → {"confidence", "notes"?, "goals": [goal, ...]}.
##   goal: {"goal": name from GOALS, "base": score > 0,
##          "hours"?: [[from, to, mult], ...]  (whole hours 0–24; from > to wraps
##                    past midnight; no matching range = score 0),
##          "days"?: [first, last], "when_flags"?: [...], "unless_flags"?: [...],
##          "target": {"off_map": place} | {"area", "pos": [x, y]}
##                  | {"area", "route": [[x, y], ...]} (a patrol loop)}.
## An NPC in an off-map place has the area "@" + place.
class_name BehaviourDb
extends RefCounted

const SCHEMA_VERSION := 1
const OFF_MAP_PREFIX := "@"
const GOALS := ["sleep", "work", "guard_post", "patrol", "trade", "eat", "visit_inn",
	"forage", "travel", "off_map"]

## "@" + place → {area id → Vector2i}.
var entries: Dictionary = {}
## npc id → {"confidence", "goals"}.
var npcs: Dictionary = {}
var errors: Array[String] = []


## Loads `dir`/npc_behaviour.json. A missing file gives an empty db (toy data).
static func load_dir(dir: String = "res://data") -> BehaviourDb:
	var path := dir.path_join("npc_behaviour.json")
	if not FileAccess.file_exists(path):
		return BehaviourDb.new()
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or not json.data is Dictionary:
		var bad := BehaviourDb.new()
		bad.errors.append("%s: invalid JSON at line %d: %s" % [path, json.get_error_line(),
				json.get_error_message()])
		return bad
	var d: Dictionary = json.data
	var db := from_dicts(d.get("entries", {}), d.get("npcs", {}))
	if int(d.get("schema_version", -1)) != SCHEMA_VERSION:
		db.errors.append("%s: schema_version must be %d." % [path, SCHEMA_VERSION])
	return db


## Builds a behaviour db from dictionaries (toy tests). Call validate() to check it.
static func from_dicts(entry_map: Dictionary, npc_map: Dictionary) -> BehaviourDb:
	var db := BehaviourDb.new()
	for place: String in entry_map:
		var ways := {}
		var m: Variant = entry_map[place]
		if m is Dictionary:
			for area: String in m:
				var a: Variant = m[area]
				ways[area] = Vector2i(int(a[0]), int(a[1])) if _pos_ok(a) else Vector2i(-1, -1)
		db.entries[OFF_MAP_PREFIX + place] = ways
	db.npcs = npc_map
	return db


func is_empty() -> bool:
	return npcs.is_empty()


## NPC ids in a fixed order (sorted).
func ids() -> Array[String]:
	var out: Array[String] = []
	out.assign(npcs.keys())
	out.sort()
	return out


func goals_of(npc: String) -> Array:
	return npcs[npc]["goals"]


## The tile a target sends an NPC to (a route: point `route_i`), or (-1, -1) off-map.
static func target_pos(target: Dictionary, route_i: int = 0) -> Vector2i:
	if target.has("pos"):
		return Vector2i(int(target["pos"][0]), int(target["pos"][1]))
	if target.has("route"):
		var route: Array = target["route"]
		var p: Array = route[posmod(route_i, route.size())]
		return Vector2i(int(p[0]), int(p[1]))
	return Vector2i(-1, -1)


## Map id of a target, or "@" + place for off-map.
static func target_area(target: Dictionary) -> String:
	if target.has("off_map"):
		return OFF_MAP_PREFIX + String(target["off_map"])
	return String(target.get("area", ""))


static func is_off_map(area: String) -> bool:
	return area.begins_with(OFF_MAP_PREFIX)


## Checks entries and goals against the canon NPCs and the maps. Appends
## to `errors` and returns them.
func validate(db: DataDb) -> Array[String]:
	for place: String in entries:
		var where := "npc_behaviour entries '%s'" % place.substr(1)
		if (entries[place] as Dictionary).is_empty():
			errors.append("%s: needs {map: [x, y], ...}." % where)
		for area: String in entries[place]:
			if not db.maps.areas.has(area):
				errors.append("%s: unknown map '%s'." % [where, area])
			else:
				_check_tile(where, area, entries[place][area], db)
	for id: String in npcs:
		_validate_npc(id, npcs[id], db)
	for a: Variant in db.rules.get("npc", {}).get("talk_actions", []):
		if not db.actions.has(a):
			errors.append("rules.npc.talk_actions: unknown action '%s'." % a)
	return errors


func _validate_npc(id: String, n: Variant, db: DataDb) -> void:
	var where := "npc_behaviour '%s'" % id
	if not db.canon.npcs.has(id):
		errors.append("%s: unknown canon npc." % where)
	if not n is Dictionary:
		errors.append("%s: must be an object." % where)
		return
	if not DataDb.CONFIDENCE.has(n.get("confidence", "")):
		errors.append("%s: confidence must be one of %s." % [where, DataDb.CONFIDENCE])
	var goals: Variant = n.get("goals", [])
	if not goals is Array or (goals as Array).is_empty():
		errors.append("%s: needs at least one goal." % where)
		return
	for i in (goals as Array).size():
		var g: Variant = goals[i]
		if not g is Dictionary:
			errors.append("%s goal %d: must be an object." % [where, i])
			continue
		_validate_goal("%s goal %d" % [where, i], g, db)


func _validate_goal(where: String, g: Dictionary, db: DataDb) -> void:
	if not GOALS.has(g.get("goal", "")):
		errors.append("%s: goal must be one of %s." % [where, GOALS])
	var base: Variant = g.get("base")
	if not (base is float or base is int) or float(base) <= 0.0:
		errors.append("%s: base must be a number > 0." % where)
	for h: Variant in g.get("hours", []):
		if not h is Array or (h as Array).size() != 3 or not _hour_ok(h[0]) or not _hour_ok(h[1]) \
				or int(h[0]) == int(h[1]) or float(h[2]) < 0.0:
			errors.append("%s: hours must be [from, to, mult] with 0 <= from != to <= 24, mult >= 0." % where)
	if g.has("days"):
		var days: Variant = g["days"]
		if not days is Array or (days as Array).size() != 2 or int(days[0]) < 1 \
				or int(days[0]) > int(days[1]):
			errors.append("%s: days must be [first, last] with 1 <= first <= last." % where)
	for key: String in ["when_flags", "unless_flags"]:
		var flags: Variant = g.get(key, [])
		if not flags is Array or not (flags as Array).all(func(f: Variant) -> bool: return f is String):
			errors.append("%s: %s must be a list of strings." % [where, key])
	var t: Variant = g.get("target")
	if not t is Dictionary:
		errors.append("%s: needs a target." % where)
		return
	if t.has("off_map"):
		if not t["off_map"] is String or not entries.has(OFF_MAP_PREFIX + String(t["off_map"])):
			errors.append("%s target: off_map must name a place in entries." % where)
		return
	var area: String = t.get("area", "")
	if not db.maps.areas.has(area):
		errors.append("%s target: unknown map '%s'." % [where, area])
		return
	if t.has("pos") == t.has("route"):
		errors.append("%s target: needs off_map, or an area with pos or route." % where)
	elif t.has("pos"):
		_check_tile(where + " target", area, t["pos"], db)
	elif not t["route"] is Array or (t["route"] as Array).size() < 2:
		errors.append("%s target: a route needs at least 2 points." % where)
	else:
		for p: Variant in t["route"]:
			_check_tile(where + " route", area, p, db)


## A tile an NPC can stand on: walkable, not an exit.
func _check_tile(where: String, area: String, a: Variant, db: DataDb) -> void:
	if a is Vector2i:
		a = [a.x, a.y]
	if not _pos_ok(a):
		errors.append("%s: position must be [x, y]." % where)
		return
	var at := Vector2i(int(a[0]), int(a[1]))
	if not db.maps.in_bounds(area, at) or not db.maps.is_walkable(area, at):
		errors.append("%s: tile %s in '%s' is not walkable." % [where, at, area])
	elif not db.maps.exit_at(area, at).is_empty():
		errors.append("%s: tile %s in '%s' is an exit." % [where, at, area])


static func _pos_ok(a: Variant) -> bool:
	return a is Array and (a as Array).size() == 2


static func _hour_ok(h: Variant) -> bool:
	return (h is float or h is int) and int(h) >= 0 and int(h) <= 24
