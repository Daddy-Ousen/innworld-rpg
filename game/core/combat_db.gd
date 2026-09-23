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
##   spawns: where monsters appear (M5.2).
class_name CombatDb
extends RefCounted

const SCHEMA_VERSION := 1
const BEHAVIOURS := ["pack", "ambush", "territorial"]
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


## Checks items, enemies and the rules' knock-out wake spots (against the
## maps). Adds to and returns `errors`.
func validate(db: DataDb) -> Array[String]:
	var item_tags := {}
	for id: String in items:
		_validate_item(id, items[id])
		for tag: Variant in items[id].get("tags", []):
			item_tags[tag] = true
	for id: String in enemies:
		_validate_enemy(id, enemies[id], item_tags)
	_validate_rules(db)
	return errors


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
