## Combat data (M5, ADR 0010): data/enemies.json and data/items.json.
## Read-only after load.
##   enemies: type id → {"name", "confidence", "canon_ref"?, "tags", "color",
##            "danger" 0–1 (the XP risk of a fight), "behaviour" (BEHAVIOURS),
##            "hp", "armor", "accuracy", "evasion", "damage": [min, max],
##            "act_seconds" (one turn per this many world seconds),
##            "aggro_radius", "lose_radius", "chase_turns", "flee_below" 0–1,
##            "scared_by": [item tag, ...], "scare_turns" (needed if scared_by),
##            "ranged"?: {"range", "damage", "chance"}, "ambush"?: {"spot_radius", "hit_bonus"}}.
##   items: item id → {"name", "confidence", "canon_ref"?, "melee": [min, max],
##          "throw": [min, max], "throw_range", "break_chance" 0–1, "tags": [...]}.
##   spawns: [{"id", "area": map id, "enemy": enemy id, "confidence",
##            "count": [min, max], "chance" 0–1, "cooldown_minutes",
##            one of "zone" (a zone of the map) | "rects": [[x, y, w, h], ...]
##            | "home": [x, y] (one monster that lives there),
##            "hours"?: [from, to] (whole hours 0–24; from > to wraps),
##            "days"?: [first, last], "when_flags"?, "unless_flags"?, "note"?}]
##            (MonsterSim.spawn_check).
class_name CombatDb
extends RefCounted

const SCHEMA_VERSION := 1
const BEHAVIOURS := ["pack", "ambush", "territorial"]
const SPAWN_FIELDS := ["id", "area", "enemy", "confidence", "count", "chance", "cooldown_minutes"]
const ENEMY_FIELDS := ["name", "confidence", "tags", "color", "danger", "behaviour", "hp", "armor",
	"accuracy", "evasion", "damage", "act_seconds", "aggro_radius", "lose_radius", "chase_turns",
	"flee_below", "scared_by"]
const ITEM_FIELDS := ["name", "confidence", "melee", "throw", "throw_range", "break_chance", "tags"]

var enemies: Dictionary = {}
var items: Dictionary = {}
var spawns: Array = []
var errors: Array[String] = []


## Loads `dir`/enemies.json and `dir`/items.json. A missing file gives
## empty data (toy dbs).
static func load_dir(dir: String = "res://data") -> CombatDb:
	var errs: Array[String] = []
	var e := _read_json(dir.path_join("enemies.json"), errs)
	var i := _read_json(dir.path_join("items.json"), errs)
	var db := from_dicts(e.get("enemies", {}), i.get("items", {}), e.get("spawns", []))
	db.errors = errs
	return db


## Builds a combat db from dictionaries (toy tests). Call validate() to check it.
static func from_dicts(enemy_map: Dictionary, item_map: Dictionary, spawn_list: Array = []) -> CombatDb:
	var db := CombatDb.new()
	db.enemies = enemy_map
	db.items = item_map
	db.spawns = spawn_list
	return db


func is_empty() -> bool:
	return enemies.is_empty()


static func _read_json(path: String, errs: Array[String]) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or not json.data is Dictionary:
		errs.append("%s: invalid JSON at line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return {}
	var d: Dictionary = json.data
	if int(d.get("schema_version", -1)) != SCHEMA_VERSION:
		errs.append("%s: schema_version must be %d." % [path, SCHEMA_VERSION])
	return d


## Checks items, enemies, spawns, canon event stages (M6.5) and the rules'
## knock-out wake spots (against the maps). Adds to and returns `errors`.
func validate(db: DataDb) -> Array[String]:
	var item_tags := {}
	for id: String in items:
		_validate_item(id, items[id])
		for tag: Variant in items[id].get("tags", []):
			item_tags[tag] = true
	for id: String in enemies:
		_validate_enemy(id, enemies[id], item_tags)
	var seen := {}
	for i in spawns.size():
		if not spawns[i] is Dictionary:
			errors.append("spawn %d: must be an object." % i)
			continue
		_validate_spawn(spawns[i], seen, db)
	for id: String in db.canon.stages:
		_validate_stage(id, db.canon.events[id]["stage"], db)
	_validate_rules(db)
	return errors


## A canon event stage (CanonDb checks its shape): known enemies, a known
## map, and foes on walkable tiles that are not exits. Waves (M7.B): known
## foe and helper enemies, a `from` tile like a foe's, and allies with
## npc_behaviour (only NPCs in the roster can be moved into the fight).
func _validate_stage(event_id: String, st: Dictionary, db: DataDb) -> void:
	var where := "event '%s' stage" % event_id
	var foes: Variant = st.get("foes", [])
	if not foes is Array:
		return
	for f: Variant in foes:
		if f is Dictionary and not enemies.has(f.get("enemy", "")):
			errors.append("%s: unknown enemy '%s'." % [where, f.get("enemy", "")])
	var waves: Array = st.get("waves", []) if st.get("waves", []) is Array else []
	for i in waves.size():
		var w: Variant = waves[i]
		if not w is Dictionary:
			continue
		var ww := "%s wave %d" % [where, i + 1]
		for key: String in ["foes", "helpers"]:
			for type: Variant in w.get(key, []):
				if not enemies.has(type):
					errors.append("%s: unknown enemy '%s'." % [ww, type])
		for npc: Variant in w.get("allies", []):
			if not db.behaviour.is_empty() and not db.behaviour.npcs.has(npc):
				errors.append("%s: ally '%s' has no npc_behaviour entry." % [ww, npc])
	if db.maps.is_empty():
		return
	var area: String = st.get("area", "")
	if not db.maps.areas.has(area):
		errors.append("%s: unknown map '%s'." % [where, area])
		return
	for f: Variant in foes:
		if not f is Dictionary or not f.get("pos", null) is Array or (f["pos"] as Array).size() != 2:
			continue
		var at := Vector2i(int(f["pos"][0]), int(f["pos"][1]))
		if not db.maps.is_walkable(area, at) or not db.maps.exit_at(area, at).is_empty():
			errors.append("%s: foe pos %s must be a walkable tile in '%s', not an exit." % [where, at, area])
	for i in waves.size():
		var w: Variant = waves[i]
		if not w is Dictionary or not w.get("from", null) is Array or (w["from"] as Array).size() != 2:
			continue
		var at := Vector2i(int(w["from"][0]), int(w["from"][1]))
		if not db.maps.is_walkable(area, at) or not db.maps.exit_at(area, at).is_empty():
			errors.append("%s wave %d: from %s must be a walkable tile in '%s', not an exit."
					% [where, i + 1, at, area])


func _validate_spawn(s: Dictionary, seen: Dictionary, db: DataDb) -> void:
	var where := "spawn '%s'" % s.get("id", "?")
	if not _has_fields(where, s, SPAWN_FIELDS):
		return
	if seen.has(s["id"]):
		errors.append("%s: duplicate id." % where)
	seen[s["id"]] = true
	_check_confidence(where, s)
	if not enemies.has(s["enemy"]):
		errors.append("%s: unknown enemy '%s'." % [where, s["enemy"]])
	_check_range(where + " count", s["count"])
	if s["count"] is Array and (s["count"] as Array).size() == 2 and int(s["count"][0]) < 1:
		errors.append("%s: count must be at least 1." % where)
	_check_share(where + " chance", s["chance"])
	if int(s["cooldown_minutes"]) < 0:
		errors.append("%s: cooldown_minutes must be >= 0." % where)
	var h: Variant = s.get("hours", [0, 1])
	if not h is Array or (h as Array).size() != 2 or int(h[0]) < 0 or int(h[1]) > 24 \
			or int(h[0]) == int(h[1]):
		errors.append("%s: hours must be [from, to] with 0 <= from != to <= 24." % where)
	var days: Variant = s.get("days", [1, 1])
	if not days is Array or (days as Array).size() != 2 or int(days[0]) < 1 or int(days[0]) > int(days[1]):
		errors.append("%s: days must be [first, last] with 1 <= first <= last." % where)
	for key: String in ["when_flags", "unless_flags"]:
		var flags: Variant = s.get(key, [])
		if not flags is Array or not (flags as Array).all(func(f: Variant) -> bool: return f is String):
			errors.append("%s: %s must be a list of strings." % [where, key])
	var places := ["zone", "rects", "home"].filter(func(k: String) -> bool: return s.has(k))
	if places.size() != 1:
		errors.append("%s: needs exactly one of zone, rects or home." % where)
		return
	if db.maps.is_empty():
		return
	if not db.maps.areas.has(s["area"]):
		errors.append("%s: unknown map '%s'." % [where, s["area"]])
		return
	var area: String = s["area"]
	var bounds := Rect2i(Vector2i.ZERO, db.maps.size(area))
	match places[0]:
		"zone":
			if not (db.maps.areas[area]["zones"] as Dictionary).has(s["zone"]):
				errors.append("%s: map '%s' has no zone '%s'." % [where, area, s["zone"]])
		"rects":
			var rects: Variant = s["rects"]
			if not rects is Array or (rects as Array).is_empty() or not (rects as Array).all(
					func(r: Variant) -> bool: return r is Array and (r as Array).size() == 4 \
							and bounds.encloses(MapDb.rect_of(r))):
				errors.append("%s: rects must be [[x, y, w, h], ...] inside the map." % where)
		"home":
			var p: Variant = s["home"]
			if not p is Array or (p as Array).size() != 2 \
					or not db.maps.is_walkable(area, Vector2i(int(p[0]), int(p[1]))):
				errors.append("%s: home must be a walkable tile in '%s'." % [where, area])
			elif s["count"] is Array and int(s["count"][1]) != 1:
				errors.append("%s: a home spawn places exactly 1 monster." % where)


func _validate_item(id: String, it: Dictionary) -> void:
	var where := "item '%s'" % id
	if not _has_fields(where, it, ITEM_FIELDS):
		return
	_check_confidence(where, it)
	_check_range(where + " melee", it["melee"])
	_check_range(where + " throw", it["throw"])
	if int(it["throw_range"]) < 1:
		errors.append("%s: throw_range must be >= 1." % where)
	_check_share(where + " break_chance", it["break_chance"])
	if not it["tags"] is Array:
		errors.append("%s: tags must be a list." % where)


func _validate_enemy(id: String, e: Dictionary, item_tags: Dictionary) -> void:
	var where := "enemy '%s'" % id
	if not _has_fields(where, e, ENEMY_FIELDS):
		return
	_check_confidence(where, e)
	if not BEHAVIOURS.has(e["behaviour"]):
		errors.append("%s: behaviour must be one of %s." % [where, BEHAVIOURS])
	if int(e["hp"]) < 1:
		errors.append("%s: hp must be >= 1." % where)
	if int(e["act_seconds"]) < 1:
		errors.append("%s: act_seconds must be >= 1." % where)
	for f: String in ["armor", "aggro_radius", "lose_radius", "chase_turns"]:
		if int(e[f]) < 0:
			errors.append("%s: %s must be >= 0." % [where, f])
	_check_share(where + " danger", e["danger"])
	_check_share(where + " flee_below", e["flee_below"])
	_check_range(where + " damage", e["damage"])
	var scared: Array = e["scared_by"]
	for tag: Variant in scared:
		if not item_tags.has(tag):
			errors.append("%s scared_by: no item has the tag '%s'." % [where, tag])
	if not scared.is_empty() and int(e.get("scare_turns", 0)) < 1:
		errors.append("%s: scared_by needs scare_turns >= 1." % where)
	if e.has("ranged"):
		var r: Dictionary = e["ranged"]
		if not _has_fields(where + " ranged", r, ["range", "damage", "chance"]):
			return
		if int(r["range"]) < 2:
			errors.append("%s ranged: range must be >= 2." % where)
		_check_range(where + " ranged damage", r["damage"])
		_check_share(where + " ranged chance", r["chance"])
	if e.has("ambush"):
		var a: Dictionary = e["ambush"]
		if _has_fields(where + " ambush", a, ["spot_radius", "hit_bonus"]):
			if int(a["spot_radius"]) < 1:
				errors.append("%s ambush: spot_radius must be >= 1." % where)
			_check_share(where + " ambush hit_bonus", a["hit_bonus"])


func _validate_rules(db: DataDb) -> void:
	var c: Dictionary = db.rules.get("combat", {})
	if c.is_empty():
		return  # DataDb reports the missing section
	_check_range("rules.combat.unarmed damage", c["unarmed"].get("damage", null))
	if int(c["stage"].get("max_on_map", 0)) < 1:
		errors.append("rules.combat.stage.max_on_map must be >= 1.")
	if db.maps.is_empty():
		return
	var wake: Dictionary = c["knockout"].get("wake", {})
	for from: String in wake:
		var w: Dictionary = wake[from]
		var where := "rules.combat.knockout.wake '%s'" % from
		if not db.maps.areas.has(from):
			errors.append("%s: unknown area." % where)
		var to: String = w.get("area", "")
		var p: Variant = w.get("pos", null)
		if not db.maps.areas.has(to):
			errors.append("%s: unknown wake area '%s'." % [where, to])
		elif not p is Array or (p as Array).size() != 2 \
				or not db.maps.is_walkable(to, Vector2i(int(p[0]), int(p[1]))):
			errors.append("%s: pos must be a walkable tile in '%s'." % [where, to])


func _has_fields(where: String, d: Dictionary, fields: Array) -> bool:
	var ok := true
	for field: String in fields:
		if not d.has(field):
			errors.append("%s: missing '%s'." % [where, field])
			ok = false
	return ok


func _check_confidence(where: String, d: Dictionary) -> void:
	if not DataDb.CONFIDENCE.has(d["confidence"]):
		errors.append("%s: confidence must be one of %s." % [where, DataDb.CONFIDENCE])


func _check_range(where: String, v: Variant) -> void:
	if not v is Array or (v as Array).size() != 2 or int(v[0]) < 0 or int(v[0]) > int(v[1]):
		errors.append("%s: must be [min, max] with 0 <= min <= max." % where)


func _check_share(where: String, v: Variant) -> void:
	if float(v) < 0.0 or float(v) > 1.0:
		errors.append("%s: must be 0.0–1.0." % where)
