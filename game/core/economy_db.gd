## Economy data (M8.6, ADR 0015): data/economy.json. Read-only after load.
##   goods: good id → {"name", "confidence", "buy" (copper; 0 = no shop sells it),
##          "sell" (copper a shop pays; 0 = no shop buys it), "canon_ref"?, and at
##          most one use: "food": true (eat it: fed today), "heal": HP (drink it),
##          "wear_flag": flag (worn at once when bought, sets the flag),
##          "eat_now": true (a meal eaten where it is bought)}.
##   shops: shop id → {"name", "sells": [good], "buys": [good]}. A map object
##          names its shop with "shop".
##   yields: action id → {good: count} put in the bag when the action is done.
##   jobs: action id → {"pay": [min, max]} copper paid when the action is done.
class_name EconomyDb
extends RefCounted

const SCHEMA_VERSION := 1
const GOOD_FIELDS := ["name", "confidence", "buy", "sell"]
const USES := ["food", "heal", "wear_flag", "eat_now"]

var goods: Dictionary = {}
var shops: Dictionary = {}
var yields: Dictionary = {}
var jobs: Dictionary = {}
var errors: Array[String] = []


## Loads `dir`/economy.json. A missing file gives empty data (toy dbs).
static func load_dir(dir: String = "res://data") -> EconomyDb:
	var errs: Array[String] = []
	var d := {}
	var path := dir.path_join("economy.json")
	if FileAccess.file_exists(path):
		var json := JSON.new()
		if json.parse(FileAccess.get_file_as_string(path)) != OK or not json.data is Dictionary:
			errs.append("%s: invalid JSON at line %d: %s" % [path, json.get_error_line(),
					json.get_error_message()])
		else:
			d = json.data
			if int(d.get("schema_version", -1)) != SCHEMA_VERSION:
				errs.append("%s: schema_version must be %d." % [path, SCHEMA_VERSION])
	var db := from_dicts(d.get("goods", {}), d.get("shops", {}), d.get("yields", {}), d.get("jobs", {}))
	db.errors = errs
	return db


## Builds an economy db from dictionaries (toy tests). Call validate() to check it.
static func from_dicts(good_map: Dictionary, shop_map: Dictionary, yield_map: Dictionary = {},
		job_map: Dictionary = {}) -> EconomyDb:
	var db := EconomyDb.new()
	db.goods = good_map
	db.shops = shop_map
	db.yields = yield_map
	db.jobs = job_map
	return db


func is_empty() -> bool:
	return goods.is_empty()


## Checks goods, shops, yields and jobs against the actions. Adds to and returns `errors`.
func validate(db: DataDb) -> Array[String]:
	for id: String in goods:
		_validate_good(id, goods[id])
	for id: String in shops:
		var s: Dictionary = shops[id]
		var where := "shop '%s'" % id
		for f: String in ["name", "sells", "buys"]:
			if not s.has(f):
				errors.append("%s: missing '%s'." % [where, f])
		for g: Variant in s.get("sells", []):
			if not goods.has(g):
				errors.append("%s: sells unknown good '%s'." % [where, g])
			elif int(goods[g]["buy"]) <= 0:
				errors.append("%s: sells '%s', which has no buy price." % [where, g])
		for g: Variant in s.get("buys", []):
			if not goods.has(g):
				errors.append("%s: buys unknown good '%s'." % [where, g])
			elif int(goods[g]["sell"]) <= 0 or _use_of(goods[g]) in ["wear_flag", "eat_now"]:
				errors.append("%s: cannot buy '%s' (no sell price, or it is not kept)." % [where, g])
	for a: String in yields:
		if not db.actions.has(a):
			errors.append("yields: unknown action '%s'." % a)
		for g: String in (yields[a] as Dictionary):
			if not goods.has(g) or int(yields[a][g]) <= 0:
				errors.append("yields '%s': '%s' must be a known good with a count > 0." % [a, g])
	for a: String in jobs:
		if not db.actions.has(a):
			errors.append("jobs: unknown action '%s'." % a)
		var pay: Variant = (jobs[a] as Dictionary).get("pay", null)
		if not pay is Array or (pay as Array).size() != 2 or int(pay[0]) < 0 or int(pay[1]) < int(pay[0]):
			errors.append("jobs '%s': pay must be [min, max] with 0 <= min <= max." % a)
	return errors


## The good's use: one of USES, or "" (a trade good).
static func _use_of(g: Dictionary) -> String:
	for u: String in USES:
		if g.has(u):
			return u
	return ""


func use_of(good: String) -> String:
	return _use_of(goods.get(good, {}))


func _validate_good(id: String, g: Dictionary) -> void:
	var where := "good '%s'" % id
	for f: String in GOOD_FIELDS:
		if not g.has(f):
			errors.append("%s: missing '%s'." % [where, f])
			return
	if not DataDb.CONFIDENCE.has(g["confidence"]):
		errors.append("%s: confidence must be one of %s." % [where, DataDb.CONFIDENCE])
	if int(g["buy"]) < 0 or int(g["sell"]) < 0:
		errors.append("%s: prices must be >= 0." % where)
	if USES.filter(func(u: String) -> bool: return g.has(u)).size() > 1:
		errors.append("%s: at most one of %s." % [where, USES])
	if g.has("heal") and int(g["heal"]) <= 0:
		errors.append("%s: heal must be > 0." % where)
