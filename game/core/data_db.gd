## Loads and checks the JSON content in data/. Read-only after load.
class_name DataDb
extends RefCounted

const SCHEMA_VERSION := 1
const ACTION_FIELDS := ["name", "minutes", "base_xp", "risk", "tags"]
const RULE_FIELDS := {
	"clock": ["start_minute", "wake_minute", "min_sleep_minutes",
		"collapse_after_awake", "collapse_sleep_minutes"],
	"xp": ["intensity_min", "intensity_max", "risk_scale", "outcome_mult", "novelty", "conviction"],
	"levels": ["base_xp", "growth", "capstones"],
	"offers": ["max_per_night"],
	"skills": ["on_accept", "chance_per_level", "base_weight"],
	"director": ["default_delay_limit", "drift", "tier_weight", "unreliable_at"],
	"world": ["starts", "step_seconds"],
	"npc": ["step_seconds", "jump_seconds", "talk_actions", "talk_relationship", "react"],
	"combat": ["base_stats", "hp_base", "hp_per_endurance", "unarmed", "hit", "strength_div",
		"min_damage", "block", "spot", "spawn", "jump_seconds", "max_turns_per_sync",
		"heal_actions", "night_heal", "knockout", "xp", "spare_tags", "stage"],
}
const CONTEXT_TESTS := ["min", "max", "equals"]
## rules.winter (M8.W, optional).
const WINTER_FIELDS := ["flag", "warned_flag", "clothes_flag", "cold", "fairies"]
const WINTER_COLD_FIELDS := ["every_minutes", "damage", "floor_hp", "clothes_mult", "warm_radius",
	"line", "morning_line"]
const WINTER_FAIRY_FIELDS := ["name", "chance", "count", "min_distance", "act_seconds", "iron_tag",
	"iron_radius", "talk_action", "safe_talks_per_day", "annoy_chance", "snow_damage", "slow_steps",
	"lines", "swat_line", "snow_line"]
## rules.economy (M8.6, optional).
const ECONOMY_FIELDS := ["copper_per_silver", "trade_minutes", "eat_minutes", "haggle_share", "rest",
	"hunger"]
const ECONOMY_REST_FIELDS := ["bed", "floor", "refused_line", "poor_line"]
const ECONOMY_HUNGER_FIELDS := ["step", "floor", "inn_location", "inn_npc", "inn_work_actions",
	"hungry_line", "fed_line"]
## rules.portal (M10.0, optional).
const PORTAL_FIELDS := ["trips_per_day", "minutes", "line", "dry_line", "spent_line"]
const CLASS_FIELDS := ["name", "tag_weights", "offer_threshold", "prereqs", "excludes",
	"race_limits", "loss", "consolidation", "canon_ref"]
const SKILL_FIELDS := ["name", "rarity", "pools", "tag_affinity", "effects", "canon_ref"]
const RARITIES := ["common", "uncommon", "rare"]
const CONFIDENCE := ["confirmed", "likely", "guess"]
## Effect type → fields it needs (ADR 0002).
const EFFECT_FIELDS := {
	"xp_mult": ["tags", "value"],
	"stat_mod": ["stat", "value"],
	"action_unlock": ["action"],
	"passive_trigger": ["trigger", "special"],
}

var tags: Dictionary = {}
var actions: Dictionary = {}
var rules: Dictionary = {}
var classes: Dictionary = {}
var skills: Dictionary = {}
## Canon NPCs, locations and events (data/canon/book<N>/). Empty in toy dbs.
var canon: CanonDb = CanonDb.new()
## Tiles and world maps (data/tiles.json, data/maps/). Empty in toy dbs.
var maps: MapDb = MapDb.new()
## NPC goals and schedules (data/npc_behaviour.json). Empty in toy dbs.
var behaviour: BehaviourDb = BehaviourDb.new()
## Enemies, improvised items and spawns (data/enemies.json, data/items.json). Empty in toy dbs.
var combat: CombatDb = CombatDb.new()
## Goods, shops, yields and jobs (data/economy.json, M8.6). Empty in toy dbs.
var economy: EconomyDb = EconomyDb.new()
var errors: Array[String] = []


## Loads tags, actions, rules, classes and skills JSON from `dir`, the
## canon from `dir`/canon, the maps, the NPC behaviour and the combat data. Errors are
## pushed and kept in `errors`.
static func load_dir(dir: String = "res://data") -> DataDb:
	var load_errors: Array[String] = []
	var t := _read_json(dir.path_join("tags.json"), load_errors)
	var a := _read_json(dir.path_join("actions.json"), load_errors)
	var r := _read_json(dir.path_join("rules.json"), load_errors)
	var c := _read_json(dir.path_join("classes.json"), load_errors)
	var s := _read_json(dir.path_join("skills.json"), load_errors)
	var db := from_dicts(t.get("tags", {}), a.get("actions", {}), r,
			c.get("classes", {}), s.get("skills", {}))
	db.canon = CanonDb.load_root(dir.path_join("canon"))
	db.maps = MapDb.load_dir(dir)
	db.combat = CombatDb.load_dir(dir)
	db.economy = EconomyDb.load_dir(dir)
	db.economy.validate(db)
	db.maps.validate(db)  # map objects name combat items and shops
	db.behaviour = BehaviourDb.load_dir(dir)
	db.behaviour.validate(db)
	db.combat.validate(db)
	db.errors = load_errors + db.errors + db.canon.errors + db.maps.errors + db.behaviour.errors \
			+ db.combat.errors + db.economy.errors
	for e in db.errors:
		push_error(e)
	return db


## Builds a db from dictionaries and validates it. Does not push errors.
static func from_dicts(tag_map: Dictionary, action_map: Dictionary, rule_map: Dictionary,
		class_map: Dictionary = {}, skill_map: Dictionary = {}) -> DataDb:
	var db := DataDb.new()
	db.tags = tag_map
	db.actions = action_map
	db.rules = rule_map
	db.classes = class_map
	db.skills = skill_map
	db.errors = Tags.validate_registry(tag_map)
	db._validate_rules()
	for id: String in action_map:
		db._validate_action(id, action_map[id])
	for id: String in class_map:
		db._validate_class(id, class_map[id])
	for id: String in skill_map:
		db._validate_skill(id, skill_map[id])
	return db


func is_valid() -> bool:
	return errors.is_empty()


static func _read_json(path: String, errs: Array[String]) -> Dictionary:
	if not FileAccess.file_exists(path):
		errs.append("Data file not found: %s" % path)
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or not json.data is Dictionary:
		errs.append("%s: invalid JSON at line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return {}
	var d: Dictionary = json.data
	if int(d.get("schema_version", -1)) != SCHEMA_VERSION:
		errs.append("%s: schema_version must be %d." % [path, SCHEMA_VERSION])
	return d


func _validate_rules() -> void:
	for section: String in RULE_FIELDS:
		if not rules.has(section):
			errors.append("rules: missing section '%s'." % section)
			continue
		for field: String in RULE_FIELDS[section]:
			if not (rules[section] as Dictionary).has(field):
				errors.append("rules.%s: missing '%s'." % [section, field])
	if rules.has("winter"):  # optional (M8.W): toy dbs have no winter
		_validate_winter(rules["winter"])
	if rules.has("economy"):  # optional (M8.6): toy dbs have no economy
		_validate_economy(rules["economy"])
	if rules.has("portal"):  # optional (M10.0): only maps with a portal need it
		_validate_portal(rules["portal"])


## rules.portal (M10.0): see Portal.
func _validate_portal(p: Variant) -> void:
	if not p is Dictionary:
		errors.append("rules.portal: must be an object.")
		return
	for field: String in PORTAL_FIELDS:
		if not (p as Dictionary).has(field):
			errors.append("rules.portal: missing '%s'." % field)
			return
	if int(p["trips_per_day"]) < 0 or int(p["minutes"]) < 1:
		errors.append("rules.portal: trips_per_day must be >= 0 and minutes >= 1.")


## rules.winter (M8.W): see Winter.
func _validate_winter(w: Dictionary) -> void:
	var need := {"": WINTER_FIELDS, "cold": WINTER_COLD_FIELDS, "fairies": WINTER_FAIRY_FIELDS}
	for part: String in need:
		var d: Variant = w if part == "" else w.get(part, null)
		var where := "rules.winter" + ("" if part == "" else "." + part)
		if not d is Dictionary:
			errors.append("%s: must be an object." % where)
			continue
		for field: String in need[part]:
			if not (d as Dictionary).has(field):
				errors.append("%s: missing '%s'." % [where, field])
	if errors.any(func(e: String) -> bool: return e.begins_with("rules.winter")):
		return
	var cold: Dictionary = w["cold"]
	if int(cold["every_minutes"]) < 1 or int(cold["damage"]) < 1 or int(cold["floor_hp"]) < 1:
		errors.append("rules.winter.cold: every_minutes, damage and floor_hp must be >= 1.")
	if float(cold["clothes_mult"]) < 1.0:
		errors.append("rules.winter.cold: clothes_mult must be >= 1 (a longer tick).")
	var f: Dictionary = w["fairies"]
	if float(f["chance"]) < 0.0 or float(f["chance"]) > 1.0 or float(f["annoy_chance"]) < 0.0 \
			or float(f["annoy_chance"]) > 1.0:
		errors.append("rules.winter.fairies: chance and annoy_chance must be 0.0-1.0.")
	var count: Variant = f["count"]
	if not count is Array or (count as Array).size() != 2 or int(count[0]) < 1 or int(count[0]) > int(count[1]):
		errors.append("rules.winter.fairies: count must be [min, max] with 1 <= min <= max.")
	if not actions.has(f["talk_action"]):
		errors.append("rules.winter.fairies: unknown talk_action '%s'." % f["talk_action"])
	if not f["lines"] is Array or (f["lines"] as Array).is_empty():
		errors.append("rules.winter.fairies: lines must be a non-empty list.")
	if int(f["act_seconds"]) < 1:
		errors.append("rules.winter.fairies: act_seconds must be >= 1.")


## rules.economy (M8.6): see Economy and Rest.
func _validate_economy(e: Dictionary) -> void:
	var need := {"": ECONOMY_FIELDS, "rest": ECONOMY_REST_FIELDS, "hunger": ECONOMY_HUNGER_FIELDS}
	for part: String in need:
		var d: Variant = e if part == "" else e.get(part, null)
		var where := "rules.economy" + ("" if part == "" else "." + part)
		if not d is Dictionary:
			errors.append("%s: must be an object." % where)
			continue
		for field: String in need[part]:
			if not (d as Dictionary).has(field):
				errors.append("%s: missing '%s'." % [where, field])
	if errors.any(func(x: String) -> bool: return x.begins_with("rules.economy")):
		return
	if int(e["copper_per_silver"]) < 1:
		errors.append("rules.economy: copper_per_silver must be >= 1.")
	var h: Dictionary = e["hunger"]
	if float(h["floor"]) <= 0.0 or float(h["floor"]) > 1.0 or float(h["step"]) < 0.0:
		errors.append("rules.economy.hunger: floor must be in (0, 1] and step >= 0.")
	for a: Variant in h["inn_work_actions"]:
		if not actions.has(a):
			errors.append("rules.economy.hunger: unknown inn work action '%s'." % a)
	var r: Dictionary = e["rest"]
	if float(r["floor"]) <= 0.0 or float(r["floor"]) > float(r["bed"]):
		errors.append("rules.economy.rest: floor must be > 0 and <= bed.")


func _validate_action(id: String, a: Dictionary) -> void:
	var missing := false
	for field: String in ACTION_FIELDS:
		if not a.has(field):
			errors.append("action '%s': missing '%s'." % [id, field])
			missing = true
	if missing:
		return
	if int(a["minutes"]) < 0:
		errors.append("action '%s': minutes must be >= 0." % id)
	if float(a["risk"]) < 0.0 or float(a["risk"]) > 1.0:
		errors.append("action '%s': risk must be 0.0–1.0." % id)
	if (a["tags"] as Dictionary).is_empty():
		errors.append("action '%s': needs at least one tag." % id)
	_check_tag_map("action '%s' tags" % id, a["tags"])
	for rule: Dictionary in a.get("context", []):
		var where := "action '%s' context '%s'" % [id, rule.get("key", "?")]
		if not rule.has("key"):
			errors.append("%s: missing 'key'." % where)
		var tests := CONTEXT_TESTS.filter(func(t: String) -> bool: return rule.has(t))
		if tests.size() != 1:
			errors.append("%s: needs exactly one of min/max/equals." % where)
		if not rule.has("add_tags") and not rule.has("add_risk"):
			errors.append("%s: needs add_tags or add_risk." % where)
		_check_tag_map(where, rule.get("add_tags", {}))


func _validate_class(id: String, c: Dictionary) -> void:
	var where := "class '%s'" % id
	if not _has_fields(where, c, CLASS_FIELDS):
		return
	if (c["tag_weights"] as Dictionary).is_empty():
		errors.append("%s: needs at least one tag weight." % where)
	_check_tag_map(where + " tag_weights", c["tag_weights"])
	if float(c["offer_threshold"]) <= 0.0:
		errors.append("%s: offer_threshold must be > 0." % where)
	var prereqs: Dictionary = c["prereqs"]
	_check_class_ids(where + " prereqs", prereqs.get("classes", []), id)
	for f: Variant in prereqs.get("flags", []):
		if not f is String:
			errors.append("%s prereqs: flags must be strings." % where)
	_check_class_ids(where + " excludes", c["excludes"], id)
	var races: Variant = c["race_limits"]
	if races != null and (not races is Dictionary or (races.get("allow", []) as Array).is_empty()):
		errors.append("%s: race_limits must be null or {\"allow\": [...]}." % where)
	var loss: Variant = c["loss"]
	if loss != null:
		if int(loss.get("neglect_days", 0)) <= 0:
			errors.append("%s loss: neglect_days must be > 0." % where)
		_check_tag_list(where + " loss", loss.get("neglect_tags", []))
	var cons: Variant = c["consolidation"]
	if cons != null:
		var from: Array = cons.get("from", [])
		if from.size() < 2:
			errors.append("%s consolidation: 'from' needs at least 2 classes." % where)
		_check_class_ids(where + " consolidation", from, id)
		if int(cons.get("level_cost", -1)) < 0:
			errors.append("%s consolidation: level_cost must be >= 0." % where)
	_check_canon_ref(where, c["canon_ref"])


func _validate_skill(id: String, s: Dictionary) -> void:
	var where := "skill '%s'" % id
	if not _has_fields(where, s, SKILL_FIELDS):
		return
	if not RARITIES.has(s["rarity"]):
		errors.append("%s: rarity must be one of %s." % [where, RARITIES])
	var pools: Array = s["pools"]
	if pools.is_empty():
		errors.append("%s: needs at least one pool." % where)
	for p: Dictionary in pools:
		if not classes.has(p.get("class", "")):
			errors.append("%s pool: unknown class '%s'." % [where, p.get("class", "")])
		var lo := int(p.get("min_level", 0))
		if lo < 1 or lo > int(p.get("max_level", 0)):
			errors.append("%s pool: needs 1 <= min_level <= max_level." % where)
		if float(p.get("weight", 0.0)) <= 0.0:
			errors.append("%s pool: weight must be > 0." % where)
	_check_tag_map(where + " tag_affinity", s["tag_affinity"])
	for e: Dictionary in s["effects"]:
		var type: String = e.get("type", "")
		if not EFFECT_FIELDS.has(type):
			errors.append("%s: unknown effect type '%s'." % [where, type])
			continue
		if not _has_fields("%s effect '%s'" % [where, type], e, EFFECT_FIELDS[type]):
			continue
		match type:
			"xp_mult":
				_check_tag_list(where + " xp_mult", e["tags"])
				if float(e["value"]) <= 0.0:
					errors.append("%s xp_mult: value must be > 0." % where)
			"action_unlock":
				if not actions.has(e["action"]):
					errors.append("%s action_unlock: unknown action '%s'." % [where, e["action"]])
	_check_canon_ref(where, s["canon_ref"])


func _has_fields(where: String, d: Dictionary, fields: Array) -> bool:
	var ok := true
	for field: String in fields:
		if not d.has(field):
			errors.append("%s: missing '%s'." % [where, field])
			ok = false
	return ok


func _check_class_ids(where: String, ids: Array, self_id: String) -> void:
	for cid: Variant in ids:
		if cid == self_id:
			errors.append("%s: a class cannot name itself." % where)
		elif not classes.has(cid):
			errors.append("%s: unknown class '%s'." % [where, cid])


func _check_tag_list(where: String, list: Array) -> void:
	if list.is_empty():
		errors.append("%s: needs at least one tag." % where)
	for tag: Variant in list:
		if not tags.has(tag):
			errors.append("%s: unknown tag '%s'." % [where, tag])


func _check_canon_ref(where: String, ref: Variant) -> void:
	if not ref is Dictionary or not (ref as Dictionary).has("book"):
		errors.append("%s: canon_ref needs 'book'." % where)
	elif not CONFIDENCE.has((ref as Dictionary).get("confidence", "")):
		errors.append("%s: canon_ref confidence must be one of %s." % [where, CONFIDENCE])


func _check_tag_map(where: String, m: Dictionary) -> void:
	for tag: String in m:
		if not tags.has(tag):
			errors.append("%s: unknown tag '%s'." % [where, tag])
		elif float(m[tag]) <= 0.0:
			errors.append("%s: weight of '%s' must be > 0." % [where, tag])
