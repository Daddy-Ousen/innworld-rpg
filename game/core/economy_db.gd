## Economy data (M8.6, ADR 0015): data/economy.json. Read-only after load.
##   goods: good id → {"name", "confidence", "buy" (copper; 0 = no shop sells it),
##          "sell" (copper a shop pays; 0 = no shop buys it), "canon_ref"?, and at
##          most one use: "food": true (eat it: fed today), "heal": HP (drink it),
##          "wear_flag": flag (worn at once when bought, sets the flag),
##          "eat_now": true (a meal eaten where it is bought), "teaches": spell id
##          (M17.5: read it once to learn the spell, Spells.read_book)}. M9.2: a food or
##          eat_now good may add "warm_minutes" (no cold for that long after
##          eating); any good may add "from_flag" (shops sell it only once
##          that flag is set). M14.0: a good with no use may add "item": an
##          items.json id (a tool you can hold from the bag, Economy.hold_good).
##   shops: shop id → {"name", "sells": [good], "buys": [good]}. A map object
##          names its shop with "shop".
##   yields: action id → {good: count} put in the bag when the action is done.
##   jobs: action id → {"pay": [min, max]} copper paid when the action is done.
##   recipes (M14.1, data/recipes.json): recipe id → {"action", "inputs": {good: n},
##          "outputs": {good: n}, "stations": [map object kind], "confidence"}.
##          See Cooking.
class_name EconomyDb
extends RefCounted

const SCHEMA_VERSION := 1
const GOOD_FIELDS := ["name", "confidence", "buy", "sell"]
const USES := ["food", "heal", "wear_flag", "eat_now", "teaches"]
const RECIPE_FIELDS := ["action", "inputs", "outputs", "stations", "confidence"]

var goods: Dictionary = {}
var shops: Dictionary = {}
var yields: Dictionary = {}
var jobs: Dictionary = {}
var recipes: Dictionary = {}
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
	var rd := {}
	var rpath := dir.path_join("recipes.json")
	if FileAccess.file_exists(rpath):
		var rjson := JSON.new()
		if rjson.parse(FileAccess.get_file_as_string(rpath)) != OK or not rjson.data is Dictionary:
			errs.append("%s: invalid JSON at line %d: %s" % [rpath, rjson.get_error_line(),
					rjson.get_error_message()])
		else:
			rd = rjson.data
			if int(rd.get("schema_version", -1)) != SCHEMA_VERSION:
				errs.append("%s: schema_version must be %d." % [rpath, SCHEMA_VERSION])
	var db := from_dicts(d.get("goods", {}), d.get("shops", {}), d.get("yields", {}), d.get("jobs", {}),
			rd.get("recipes", {}))
	db.errors = errs
	return db


## Builds an economy db from dictionaries (toy tests). Call validate() to check it.
static func from_dicts(good_map: Dictionary, shop_map: Dictionary, yield_map: Dictionary = {},
		job_map: Dictionary = {}, recipe_map: Dictionary = {}) -> EconomyDb:
	var db := EconomyDb.new()
	db.goods = good_map
	db.shops = shop_map
	db.yields = yield_map
	db.jobs = job_map
	db.recipes = recipe_map
	return db


func is_empty() -> bool:
	return goods.is_empty()


## Checks goods, shops, yields, jobs and recipes against the actions. Adds to and returns `errors`.
func validate(db: DataDb) -> Array[String]:
	var items_seen := {}
	for id: String in goods:
		_validate_good(id, goods[id])
		if goods[id].has("item"):
			var item: Variant = goods[id]["item"]
			if not db.combat.items.has(item):
				errors.append("good '%s': unknown item '%s'." % [id, item])
			elif items_seen.has(item):
				errors.append("good '%s': item '%s' already has good '%s'." % [id, item, items_seen[item]])
			else:
				items_seen[item] = id
			if _use_of(goods[id]) != "":
				errors.append("good '%s': an item good has no other use." % id)
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
	for id: String in recipes:
		_validate_recipe(id, recipes[id], db)
	return errors


## Recipe ids that use `action`, sorted.
func recipes_for(action: String) -> Array[String]:
	var out: Array[String] = []
	for id: String in recipes:
		if recipes[id].get("action", "") == action:
			out.append(id)
	out.sort()
	return out


## The good's use: one of USES, or "" (a trade good).
static func _use_of(g: Dictionary) -> String:
	for u: String in USES:
		if g.has(u):
			return u
	return ""


func use_of(good: String) -> String:
	return _use_of(goods.get(good, {}))


## True if shops may sell `good` now (its from_flag, if any, is set).
func on_sale(good: String, flags: Dictionary) -> bool:
	var f: String = goods.get(good, {}).get("from_flag", "")
	return f == "" or bool(flags.get(f, false))


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
	if g.has("teaches") and String(g["teaches"]).is_empty():
		errors.append("%s: teaches must be a spell id." % where)
	if g.has("heal") and int(g["heal"]) <= 0:
		errors.append("%s: heal must be > 0." % where)
	if g.has("warm_minutes"):
		if not _use_of(g) in ["food", "eat_now"]:
			errors.append("%s: warm_minutes needs food or eat_now." % where)
		if int(g["warm_minutes"]) <= 0:
			errors.append("%s: warm_minutes must be > 0." % where)
	if g.has("from_flag") and (not g["from_flag"] is String or String(g["from_flag"]).is_empty()):
		errors.append("%s: from_flag must be a flag name." % where)


func _validate_recipe(id: String, r: Variant, db: DataDb) -> void:
	var where := "recipe '%s'" % id
	if not r is Dictionary:
		errors.append("%s: must be an object." % where)
		return
	for f: String in RECIPE_FIELDS:
		if not r.has(f):
			errors.append("%s: missing '%s'." % [where, f])
			return
	if not db.actions.has(r["action"]):
		errors.append("%s: unknown action '%s'." % [where, r["action"]])
	if not DataDb.CONFIDENCE.has(r["confidence"]):
		errors.append("%s: confidence must be one of %s." % [where, DataDb.CONFIDENCE])
	for part: String in ["inputs", "outputs"]:
		var m: Variant = r[part]
		if not m is Dictionary or (m as Dictionary).is_empty():
			errors.append("%s: %s must be a non-empty object {good: count}." % [where, part])
			continue
		for g: String in m:
			if not goods.has(g) or not (m[g] is int or m[g] is float) or int(m[g]) <= 0:
				errors.append("%s %s: '%s' must be a known good with a count > 0." % [where, part, g])
			elif part == "outputs" and _use_of(goods[g]) in ["wear_flag", "eat_now"]:
				errors.append("%s outputs: '%s' cannot be kept in the bag." % [where, g])
	var st: Variant = r["stations"]
	if not st is Array or (st as Array).is_empty() \
			or (st as Array).any(func(k: Variant) -> bool: return not k is String or String(k).is_empty()):
		errors.append("%s: stations must be a non-empty list of object kinds." % where)
