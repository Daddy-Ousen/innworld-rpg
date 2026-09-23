## Canon data: NPCs, locations and canon events for every book in
## data/canon/book<N>/ (ADR 0004). Read-only after load. The full schema
## check is tools/validate_data.py; this loader only checks what the
## director needs to run safely.
class_name CanonDb
extends RefCounted

const SCHEMA_VERSION := 1

var npcs: Dictionary = {}
var locations: Dictionary = {}
var events: Dictionary = {}
## Event ids in run order: dependencies first, then window.earliest, then id.
var order: Array[String] = []
## Event id → ids of the events that list it in depends_on (in run order).
var dependents: Dictionary = {}
## Events that are a mutate target. They only run in place of another event.
var alt_only: Dictionary = {}
var errors: Array[String] = []


## Loads every book folder under `root` (sorted), e.g. res://data/canon/book1.
## A missing root gives an empty canon (no error).
static func load_root(root: String = "res://data/canon") -> CanonDb:
	var load_errors: Array[String] = []
	var n := {}
	var l := {}
	var e := {}
	if DirAccess.dir_exists_absolute(root):
		var books := Array(DirAccess.get_directories_at(root))
		books.sort()
		for book: String in books:
			_load_book(root.path_join(book), n, l, e, load_errors)
	var db := from_dicts(n, l, e)
	db.errors = load_errors + db.errors
	return db


static func _load_book(dir: String, n: Dictionary, l: Dictionary, e: Dictionary,
		errs: Array[String]) -> void:
	_merge(n, _read_json(dir.path_join("npcs.json"), errs).get("npcs", {}), "npc", dir, errs)
	_merge(l, _read_json(dir.path_join("locations.json"), errs).get("locations", {}),
			"location", dir, errs)
	var files := Array(DirAccess.get_files_at(dir.path_join("chapters")))
	files = files.filter(func(f: String) -> bool: return f.ends_with(".json"))
	files.sort()
	for f: String in files:
		var path := dir.path_join("chapters").path_join(f)
		_merge(e, _read_json(path, errs).get("events", {}), "event", path, errs)


static func _merge(into: Dictionary, from: Dictionary, kind: String, where: String,
		errs: Array[String]) -> void:
	for id: String in from:
		if into.has(id):
			errs.append("%s: duplicate %s id '%s'." % [where, kind, id])
		into[id] = from[id]


static func _read_json(path: String, errs: Array[String]) -> Dictionary:
	if not FileAccess.file_exists(path):
		errs.append("Canon file not found: %s" % path)
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or not json.data is Dictionary:
		errs.append("%s: invalid JSON at line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return {}
	var d: Dictionary = json.data
	if int(d.get("schema_version", -1)) != SCHEMA_VERSION:
		errs.append("%s: schema_version must be %d." % [path, SCHEMA_VERSION])
	return d


## Builds a canon db from dictionaries (toy tests) and checks it.
static func from_dicts(npc_map: Dictionary, location_map: Dictionary, event_map: Dictionary) -> CanonDb:
	var db := CanonDb.new()
	db.npcs = npc_map
	db.locations = location_map
	db.events = event_map
	for id: String in event_map:
		db._validate_event(id, event_map[id])
	db._build_order()
	return db


func is_valid() -> bool:
	return errors.is_empty()


## Mutate target of an on_fail step, or "".
static func mutate_target(step: String) -> String:
	return step.substr(7) if step.begins_with("mutate:") else ""


func _validate_event(id: String, ev: Dictionary) -> void:
	var where := "event '%s'" % id
	for field: String in ["tier", "window", "roles", "requires", "depends_on", "on_fail", "effects"]:
		if not ev.has(field):
			errors.append("%s: missing '%s'." % [where, field])
			return
	for dep: String in ev["depends_on"]:
		if not events.has(dep):
			errors.append("%s: depends on unknown event '%s'." % [where, dep])
	var on_fail: Array = ev["on_fail"]
	if on_fail.is_empty() or on_fail[-1] != "cancel":
		errors.append("%s: on_fail must end in 'cancel'." % where)
	for step: String in on_fail:
		var target := mutate_target(step)
		if target != "":
			if not events.has(target):
				errors.append("%s: mutate target '%s' is unknown." % [where, target])
			else:
				alt_only[target] = true
	for role: String in ev["roles"]:
		_check_npcs("%s role '%s'" % [where, role], ev["roles"][role].get("prefer", []))
	_check_npcs(where + " requires.alive", ev["requires"].get("alive", []))
	_check_npcs(where + " effects.kill", ev["effects"].get("kill", []))


func _check_npcs(where: String, ids: Array) -> void:
	for npc: String in ids:
		if not npcs.has(npc):
			errors.append("%s: unknown npc '%s'." % [where, npc])


## Topological order (Kahn). Among ready events: lowest window.earliest,
## then id. A cycle is an error; its events go last, sorted by id.
func _build_order() -> void:
	var waiting := {}
	for id: String in events:
		dependents[id] = []
	var ids := events.keys()
	ids.sort()
	for id: String in ids:
		var deps: Array = events[id].get("depends_on", []).filter(
				func(d: String) -> bool: return events.has(d))
		waiting[id] = deps.size()
		for d: String in deps:
			(dependents[d] as Array).append(id)
	var ready: Array = ids.filter(func(id: String) -> bool: return waiting[id] == 0)
	while not ready.is_empty():
		ready.sort_custom(_before)
		var id: String = ready.pop_front()
		order.append(id)
		for next: String in dependents[id]:
			waiting[next] -= 1
			if waiting[next] == 0:
				ready.append(next)
	if order.size() < ids.size():
		var rest := ids.filter(func(id: String) -> bool: return not order.has(id))
		errors.append("depends_on cycle among: %s." % ", ".join(rest))
		order.append_array(rest)
	for id: String in dependents:
		(dependents[id] as Array).sort_custom(func(a: String, b: String) -> bool:
			return order.find(a) < order.find(b))


func _before(a: String, b: String) -> bool:
	var ea := int(events[a]["window"]["earliest"])
	var eb := int(events[b]["window"]["earliest"])
	return ea < eb if ea != eb else a < b
