## Spell data (M17.5, ADR 0027): data/spells.json. Read-only after load.
##   spells: spell id → {"name", "shape", "ap_q" (1-40), "mp" (1-10), "damage": [a, b],
##          "hit": "auto" | "roll", "cooldown" (rounds), "canon_ref", and by shape:
##          "one": "range" (tiles) - one foe in range;
##          "line": "length" (tiles) - a straight run from the caster that stops at
##            a wall; every foe on it is hit;
##          "blast": "range" (aim tile) and "radius" - every foe within radius of the
##            aim tile;
##          "around": the 8 tiles around the caster.
##          Optional "intellect_div" (damage + Intellect / div, default 3) and "learn":
##          {"teacher": canon npc id, "after_event": canon event id that must be done,
##          "minutes": study time, "book": good id (a good with "teaches": this spell)}.
##          A spell nobody teaches is for NPC casters only.
##          The names are canon; every number is a design guess (see canon_ref).
class_name SpellDb
extends RefCounted

const SCHEMA_VERSION := 1
const SHAPES := ["one", "line", "blast", "around"]
const HITS := ["auto", "roll"]
const FIELDS := ["name", "shape", "ap_q", "mp", "damage", "hit", "cooldown", "canon_ref"]

var spells: Dictionary = {}
var errors: Array[String] = []


## Loads `dir`/spells.json. A missing file gives empty data (toy dbs).
static func load_dir(dir: String = "res://data") -> SpellDb:
	var errs: Array[String] = []
	var d := {}
	var path := dir.path_join("spells.json")
	if FileAccess.file_exists(path):
		var json := JSON.new()
		if json.parse(FileAccess.get_file_as_string(path)) != OK or not json.data is Dictionary:
			errs.append("%s: invalid JSON at line %d: %s" % [path, json.get_error_line(),
					json.get_error_message()])
		else:
			d = json.data
			if int(d.get("schema_version", -1)) != SCHEMA_VERSION:
				errs.append("%s: schema_version must be %d." % [path, SCHEMA_VERSION])
	var db := from_dicts(d.get("spells", {}))
	db.errors = errs
	return db


## Builds a spell db from a dictionary (toy tests). Call validate() to check it.
static func from_dicts(spell_map: Dictionary) -> SpellDb:
	var db := SpellDb.new()
	db.spells = spell_map
	return db


func is_empty() -> bool:
	return spells.is_empty()


func has(id: String) -> bool:
	return spells.has(id)


## Spell ids in a fixed order (sorted).
func ids() -> Array[String]:
	var out: Array[String] = []
	out.assign(spells.keys())
	out.sort()
	return out


## Checks every spell against the canon (teachers, events) and the goods (books).
## Adds to and returns `errors`.
func validate(db: DataDb) -> Array[String]:
	for id: String in spells:
		_validate_spell(id, spells[id], db)
	for good: String in db.economy.goods:
		var g: Dictionary = db.economy.goods[good]
		if g.has("teaches") and String(g["teaches"]) != "":
			var sp: Variant = spells.get(g["teaches"])
			if sp == null:
				errors.append("good '%s': teaches unknown spell '%s'." % [good, g["teaches"]])
			elif String((sp as Dictionary).get("learn", {}).get("book", "")) != good:
				errors.append("good '%s': spell '%s' does not name it as its book." % [good, g["teaches"]])
	return errors


func _validate_spell(id: String, s: Variant, db: DataDb) -> void:
	var where := "spell '%s'" % id
	if not s is Dictionary:
		errors.append("%s: must be an object." % where)
		return
	for f: String in FIELDS:
		if not s.has(f):
			errors.append("%s: missing '%s'." % [where, f])
			return
	var shape := String(s["shape"])
	if not SHAPES.has(shape):
		errors.append("%s: shape must be one of %s." % [where, SHAPES])
	if int(s["ap_q"]) < 1 or int(s["ap_q"]) > 40:
		errors.append("%s: ap_q must be 1-40 (up to 10 AP)." % where)
	if int(s["mp"]) < 1 or int(s["mp"]) > 10:
		errors.append("%s: mp must be 1-10." % where)
	var dmg: Variant = s["damage"]
	if not dmg is Array or (dmg as Array).size() != 2 or int(dmg[0]) < 0 or int(dmg[0]) > int(dmg[1]) \
			or int(dmg[1]) < 1:
		errors.append("%s: damage must be [a, b] with 0 <= a <= b and b >= 1." % where)
	if not HITS.has(String(s["hit"])):
		errors.append("%s: hit must be one of %s." % [where, HITS])
	if int(s["cooldown"]) < 0:
		errors.append("%s: cooldown must be >= 0." % where)
	if int(s.get("intellect_div", 3)) < 1:
		errors.append("%s: intellect_div must be >= 1." % where)
	match shape:
		"one":
			if int(s.get("range", 0)) < 1:
				errors.append("%s: a one-foe spell needs range >= 1." % where)
		"line":
			if int(s.get("length", 0)) < 1:
				errors.append("%s: a line spell needs length >= 1." % where)
		"blast":
			if int(s.get("range", 0)) < 1 or int(s.get("radius", 0)) < 1:
				errors.append("%s: a blast spell needs range >= 1 and radius >= 1." % where)
	var ref: Variant = s["canon_ref"]
	if not ref is Dictionary or not (ref as Dictionary).has("book"):
		errors.append("%s: canon_ref needs 'book'." % where)
	elif not DataDb.CONFIDENCE.has(String(ref.get("confidence", ""))):
		errors.append("%s: canon_ref confidence must be one of %s." % [where, DataDb.CONFIDENCE])
	var learn: Variant = s.get("learn", {})
	if not learn is Dictionary:
		errors.append("%s: learn must be an object." % where)
		return
	if (learn as Dictionary).is_empty():
		return
	if int(learn.get("minutes", 0)) < 1:
		errors.append("%s learn: minutes must be >= 1." % where)
	if learn.has("teacher"):
		if not db.canon.npcs.has(String(learn["teacher"])):
			errors.append("%s learn: unknown teacher '%s'." % [where, learn["teacher"]])
		if learn.has("after_event") and not db.canon.events.has(String(learn["after_event"])):
			errors.append("%s learn: unknown after_event '%s'." % [where, learn["after_event"]])
	elif learn.has("after_event"):
		errors.append("%s learn: after_event needs a teacher." % where)
	if learn.has("book"):
		var good: String = String(learn["book"])
		if not db.economy.goods.has(good):
			errors.append("%s learn: unknown book '%s'." % [where, good])
		elif String(db.economy.goods[good].get("teaches", "")) != id:
			errors.append("%s learn: good '%s' must have \"teaches\": \"%s\"." % [where, good, id])
	if not learn.has("teacher") and not learn.has("book"):
		errors.append("%s learn: needs a teacher or a book." % where)
