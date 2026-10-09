## Breakthroughs (M22, ADR 0035): the key that lets a class pass a capstone
## level (10, 20, 30). A key is earned by a moment, not by XP. Three sources:
## 1. a hard moment (rules.levels.breakthrough: a fitting record that passes
##    `need` of the risk / duress / window bars),
## 2. a class trial (classes.json `breakthrough.trials`),
## 3. a canon moment (a hook with a `breakthrough` effect, usually `then: boon`).
## A moment only counts while the class waits one level under a capstone
## without a key. Pure functions over GameState + DataDb; no RNG, no save data
## beyond Progression.breakthroughs.
class_name Breakthrough
extends RefCounted

## The record values a bar or a trial `min` can test.
const BARS := ["risk", "duress", "window"]
## Defaults for a record made before M17.8 / M17.9 (no window, no duress).
const BAR_DEFAULTS := {"risk": 0.0, "duress": 1.0, "window": 1.0}
const KEY_LINE := "Breakthrough: %s can grow past level %d."


## rules.levels.breakthrough, or {} (then source 1 is off).
static func rules_of(db: DataDb) -> Dictionary:
	return db.rules.get("levels", {}).get("breakthrough", {})


## The capstone the class waits for: its next level, if that is a capstone, it
## has no key and the hidden total cap is not reached. Else 0.
static func waiting_for(p: Progression, class_id: String, level_rules: Dictionary) -> int:
	if not p.has_class(class_id) or p.breakthroughs.has(class_id) or Levels.at_cap(p, level_rules):
		return 0
	var next := p.level_of(class_id) + 1
	return next if Levels.is_capstone(next, level_rules) else 0


## Source 1: the record fits the class, did not fail, and passes `need` bars.
static func is_hard_moment(r: Dictionary, class_def: Dictionary, bt: Dictionary, capstone: int) -> bool:
	if bt.is_empty() or r.get("outcome", "success") == "fail":
		return false
	if Tags.match_score(r["tags"], class_def["tag_weights"]) < float(bt.get("min_match", 0.5)):
		return false
	var bars: Dictionary = bt.get("bars", {})
	var passed := 0
	for key: String in bars:
		if _value(r, key) >= float(bars[key]):
			passed += 1
	return passed >= int(bt.get("need", {}).get(str(capstone), 1))


## Source 2: the record matches the trial like a hook's `did` entry, passes
## every `min` bar, and the trial counts for this capstone (`at`; none = all).
static func passes_trial(r: Dictionary, trial: Dictionary, capstone: int) -> bool:
	var at: Array = trial.get("at", [])
	if not at.is_empty() and not at.any(func(c: Variant) -> bool: return int(c) == capstone):
		return false
	if not Director.record_matches(r, trial):
		return false
	var mins: Dictionary = trial.get("min", {})
	for key: String in mins:
		if _value(r, key) < float(mins[key]):
			return false
	return true


## True if one of the records earns the class its key for `capstone`
## (sources 1 and 2).
static func earned(db: DataDb, class_id: String, records: Array[Dictionary], capstone: int) -> bool:
	var def: Dictionary = db.classes[class_id]
	var block: Dictionary = def.get("breakthrough", {})
	var bt := rules_of(db)
	var by_default: bool = block.get("default", true)
	for r in records:
		if by_default and is_hard_moment(r, def, bt, capstone):
			return true
		for trial: Dictionary in block.get("trials", []):
			if passes_trial(r, trial, capstone):
				return true
	return false


## Night step 2: if the class waits for a capstone and today's records earn
## the key, grants it. Returns the key line, or "".
static func check_records(gs: GameState, db: DataDb, class_id: String,
		records: Array[Dictionary]) -> String:
	var capstone := waiting_for(gs.progression, class_id, db.rules["levels"])
	if capstone == 0 or not earned(db, class_id, records, capstone):
		return ""
	gs.progression.breakthroughs.append(class_id)
	return key_line(db, class_id, capstone - 1)


## Source 3 (a hook effect): {"class": id} or {"tags": {tag: weight}}. With
## tags, the held class that fits best gets the key (ties: the class gained
## first). The class must wait for a capstone, or nothing happens. Returns the
## class id that got the key, or "".
static func grant(gs: GameState, db: DataDb, spec: Dictionary) -> String:
	var p := gs.progression
	var id: String = spec.get("class", "")
	if spec.has("tags"):
		var best := 0.0
		for cid: String in p.classes:
			var s := Tags.match_score(spec["tags"], db.classes[cid]["tag_weights"])
			if s > best:
				best = s
				id = cid
	if id == "" or waiting_for(p, id, db.rules["levels"]) == 0:
		return ""
	p.breakthroughs.append(id)
	return id


## Shown once when a class reaches the level under a capstone: the class hint,
## else the rules hint with the class name. "" if there is no hint.
static func hint(db: DataDb, class_id: String) -> String:
	var def: Dictionary = db.classes[class_id]
	var own: String = def.get("breakthrough", {}).get("hint", "")
	if own != "":
		return own
	var text: String = rules_of(db).get("hint", "")
	return text % def["name"] if text.contains("%s") else text


static func key_line(db: DataDb, class_id: String, level: int) -> String:
	return KEY_LINE % [db.classes[class_id]["name"], level]


static func _value(r: Dictionary, key: String) -> float:
	return float(r.get(key, BAR_DEFAULTS.get(key, 0.0)))


## Checks rules.levels.breakthrough, the classes' `breakthrough` blocks and the
## `breakthrough` effects of canon hooks (classes and tags must exist).
static func validate(db: DataDb) -> Array[String]:
	var out: Array[String] = []
	var level_rules: Dictionary = db.rules.get("levels", {})
	var capstones: Array = level_rules.get("capstones", [])
	var bt := rules_of(db)
	if not bt.is_empty():
		var where := "rules.levels.breakthrough"
		var m := float(bt.get("min_match", -1.0))
		if m <= 0.0:
			out.append("%s: min_match must be > 0." % where)
		var bars: Dictionary = bt.get("bars", {})
		if bars.is_empty():
			out.append("%s: bars must name at least one of %s." % [where, BARS])
		for key: String in bars:
			if not BARS.has(key):
				out.append("%s: unknown bar '%s' (use %s)." % [where, key, BARS])
		var need: Dictionary = bt.get("need", {})
		for c: Variant in capstones:
			var n := int(need.get(str(int(c)), 0))
			if n < 1 or n > bars.size():
				out.append("%s: need for %d must be 1-%d (the number of bars)." % [where, int(c), bars.size()])
		if not bt.get("hint", "") is String:
			out.append("%s: hint must be a string." % where)
	for id: String in db.classes:
		var block: Variant = db.classes[id].get("breakthrough")
		if block == null:
			continue
		var where := "class '%s' breakthrough" % id
		if not block is Dictionary:
			out.append("%s: must be an object." % where)
			continue
		if not block.get("hint", "") is String or not block.get("default", true) is bool:
			out.append("%s: hint must be a string and default a bool." % where)
		var trials: Variant = block.get("trials", [])
		if not trials is Array:
			out.append("%s: trials must be a list." % where)
			continue
		if not block.get("default", true) and (trials as Array).is_empty():
			out.append("%s: default false needs at least one trial." % where)
		for t: Variant in trials:
			out.append_array(_validate_trial(db, where, t, capstones))
	for eid: String in db.canon.events:
		for hook: Dictionary in db.canon.events[eid].get("hooks", []):
			var fx: Dictionary = hook.get("effects", {})
			if fx.has("breakthrough"):
				out.append_array(_validate_effect(db, "event '%s' hook '%s'" % [eid, hook["id"]],
						fx["breakthrough"]))
	return out


static func _validate_trial(db: DataDb, where: String, t: Variant, capstones: Array) -> Array[String]:
	var out: Array[String] = []
	if not t is Dictionary or (t.get("action", []) as Array).is_empty():
		out.append("%s: each trial needs an action list." % where)
		return out
	for a: String in t["action"]:
		if not db.actions.has(a):
			out.append("%s trial: unknown action '%s'." % [where, a])
	var mins: Dictionary = t.get("min", {})
	for key: String in mins:
		if not BARS.has(key):
			out.append("%s trial: unknown min '%s' (use %s)." % [where, key, BARS])
	for c: Variant in t.get("at", []):
		if not capstones.any(func(x: Variant) -> bool: return int(x) == int(c)):
			out.append("%s trial: at %s is not a capstone level." % [where, str(c)])
	return out


static func _validate_effect(db: DataDb, where: String, spec: Variant) -> Array[String]:
	var out: Array[String] = []
	if not spec is Dictionary or (spec as Dictionary).size() != 1 \
			or not (spec.has("class") or spec.has("tags")):
		out.append("%s: breakthrough must be {\"class\": id} or {\"tags\": {...}}." % where)
		return out
	if spec.has("class") and not db.classes.has(spec["class"]):
		out.append("%s: breakthrough names unknown class '%s'." % [where, spec["class"]])
	if spec.has("tags"):
		if (spec["tags"] as Dictionary).is_empty():
			out.append("%s: breakthrough tags are empty." % where)
		for tag: String in spec["tags"]:
			if not db.tags.has(tag):
				out.append("%s: breakthrough names unknown tag '%s'." % [where, tag])
	return out
