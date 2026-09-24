## Canon data: NPCs, locations and canon events for every book in
## data/canon/book<N>/ (ADR 0004). Read-only after load. The full schema
## check is tools/validate_data.py; this loader only checks what the
## director needs to run safely.
class_name CanonDb
extends RefCounted

const SCHEMA_VERSION := 1
## Hook results (besides "mutate:<id>").
const HOOK_CANCEL := "cancel"
const HOOK_CHANGE := "change"

var npcs: Dictionary = {}
var locations: Dictionary = {}
var events: Dictionary = {}
## Event ids in run order: dependencies first, then window.earliest, then id.
var order: Array[String] = []
## Event id → ids of the events that list it in depends_on (in run order).
var dependents: Dictionary = {}
## Events that are a mutate target (of on_fail or a hook). They only run in
## place of another event.
var alt_only: Dictionary = {}
## Events with a `stage` (a canon fight on the map, M6.5), in run order.
var stages: Array[String] = []
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
	var hook_ids := {}
	for hook: Dictionary in ev.get("hooks", []):
		_validate_hook(where, hook, hook_ids)
	if ev.has("stage"):
		_validate_stage(where, ev["stage"])


## A canon fight on the map (M6.5, ADR 0011): {"area", "hours": [from, to],
## "foes": [{"enemy", "pos": [x, y]}], "allies"?: [npc ids],
## "when_flags"?, "unless_flags"?, "line"?, "note"?}. CombatDb.validate checks
## the enemies and the map.
func _validate_stage(where: String, st: Variant) -> void:
	var sw := where + " stage"
	if not st is Dictionary:
		errors.append("%s: must be an object." % sw)
		return
	for field: String in ["area", "hours", "foes"]:
		if not (st as Dictionary).has(field):
			errors.append("%s: missing '%s'." % [sw, field])
			return
	var h: Variant = st["hours"]
	if not h is Array or (h as Array).size() != 2 or int(h[0]) < 0 or int(h[1]) > 24 \
			or int(h[0]) == int(h[1]):
		errors.append("%s: hours must be [from, to] with 0 <= from != to <= 24." % sw)
	var foes: Variant = st["foes"]
	if not foes is Array or (foes as Array).is_empty():
		errors.append("%s: foes must be a non-empty list." % sw)
	else:
		for f: Variant in foes:
			if not f is Dictionary or not (f as Dictionary).has("enemy") \
					or not f.get("pos", null) is Array or (f["pos"] as Array).size() != 2:
				errors.append("%s: each foe needs 'enemy' and 'pos': [x, y]." % sw)
	_check_npcs(sw + " allies", st.get("allies", []))


## A player hook (M6.4, ADR 0011): {"id", "did": [{"action": [ids],
## "outcome"?: [..], "context"?: {key: value or [values]}}], "days": [from, to],
## "then": "cancel" | "change" | "mutate:<id>", "effects"? (change only), "news"?}.
func _validate_hook(where: String, hook: Dictionary, seen: Dictionary) -> void:
	for field: String in ["id", "did", "days", "then"]:
		if not hook.has(field):
			errors.append("%s hook: missing '%s'." % [where, field])
			return
	var hw := "%s hook '%s'" % [where, hook["id"]]
	if seen.has(hook["id"]):
		errors.append("%s: duplicate hook id." % hw)
	seen[hook["id"]] = true
	if (hook["did"] as Array).is_empty():
		errors.append("%s: 'did' is empty." % hw)
	for m: Dictionary in hook["did"]:
		if (m.get("action", []) as Array).is_empty():
			errors.append("%s: a 'did' entry has no action." % hw)
	var days: Array = hook["days"]
	if days.size() != 2 or int(days[0]) < 1 or int(days[1]) < int(days[0]):
		errors.append("%s: 'days' must be [from, to] with 1 <= from <= to." % hw)
	var then: String = hook["then"]
	var target := mutate_target(then)
	if target != "":
		if not events.has(target):
			errors.append("%s: mutate target '%s' is unknown." % [hw, target])
		else:
			alt_only[target] = true
	elif then == HOOK_CHANGE:
		if not hook.has("effects"):
			errors.append("%s: 'change' needs effects." % hw)
		_check_npcs(hw + " effects.kill", hook.get("effects", {}).get("kill", []))
	elif then != HOOK_CANCEL:
		errors.append("%s: 'then' must be cancel, change or mutate:<id>." % hw)


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
	for id in order:
		if events[id].has("stage"):
			stages.append(id)


func _before(a: String, b: String) -> bool:
	var ea := int(events[a]["window"]["earliest"])
	var eb := int(events[b]["window"]["earliest"])
	return ea < eb if ea != eb else a < b
