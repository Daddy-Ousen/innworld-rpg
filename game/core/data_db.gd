## Loads and checks the JSON content in data/. Read-only after load.
class_name DataDb
extends RefCounted

const SCHEMA_VERSION := 1
const ACTION_FIELDS := ["name", "minutes", "base_xp", "risk", "tags"]
const RULE_FIELDS := {
	"clock": ["start_minute", "wake_minute", "min_sleep_minutes",
		"collapse_after_awake", "collapse_sleep_minutes"],
	"xp": ["intensity_min", "intensity_max", "risk_scale", "outcome_mult", "novelty", "conviction"],
}
const CONTEXT_TESTS := ["min", "max", "equals"]

var tags: Dictionary = {}
var actions: Dictionary = {}
var rules: Dictionary = {}
var errors: Array[String] = []


## Loads tags.json, actions.json and rules.json from `dir`. Errors are
## pushed and kept in `errors`.
static func load_dir(dir: String = "res://data") -> DataDb:
	var load_errors: Array[String] = []
	var t := _read_json(dir.path_join("tags.json"), load_errors)
	var a := _read_json(dir.path_join("actions.json"), load_errors)
	var r := _read_json(dir.path_join("rules.json"), load_errors)
	var db := from_dicts(t.get("tags", {}), a.get("actions", {}), r)
	db.errors = load_errors + db.errors
	for e in db.errors:
		push_error(e)
	return db


## Builds a db from dictionaries and validates it. Does not push errors.
static func from_dicts(tag_map: Dictionary, action_map: Dictionary, rule_map: Dictionary) -> DataDb:
	var db := DataDb.new()
	db.tags = tag_map
	db.actions = action_map
	db.rules = rule_map
	db.errors = Tags.validate_registry(tag_map)
	db._validate_rules()
	for id: String in action_map:
		db._validate_action(id, action_map[id])
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


func _check_tag_map(where: String, m: Dictionary) -> void:
	for tag: String in m:
		if not tags.has(tag):
			errors.append("%s: unknown tag '%s'." % [where, tag])
		elif float(m[tag]) <= 0.0:
			errors.append("%s: weight of '%s' must be > 0." % [where, tag])
