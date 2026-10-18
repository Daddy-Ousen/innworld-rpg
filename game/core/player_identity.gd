## Who the player is (M30.5, ADR 0044): a name, a look preset and an Earth background,
## chosen on the New game screen. Data in data/backgrounds.json (DataDb.creation):
## "looks" [{id, name}] (sheets in assets/characters/<id>.png, the first is the old
## "player" look) and "backgrounds" {id: {name, blurb, class}}. A background starts its
## class pool at "pool_start" of the class's offer_threshold and sets the flag
## FLAG + id, so voice lines can name it. No gs.rng is used. Old saves (v22) get
## DEFAULT_NAME, DEFAULT_LOOK and no background. Ryoka never levels; the player is not her.
class_name PlayerIdentity
extends RefCounted

const DEFAULT_NAME := "Earther"
const DEFAULT_LOOK := "player"
const MAX_NAME := 20
const FLAG := "background."
const BACKGROUND_FIELDS := ["name", "blurb", "class"]


## The name as stored: edges trimmed, at most MAX_NAME characters, DEFAULT_NAME when empty.
static func clean_name(text: String) -> String:
	var s := text.strip_edges().left(MAX_NAME).strip_edges()
	return DEFAULT_NAME if s == "" else s


## The look preset ids, in screen order ([DEFAULT_LOOK] when there is no creation data).
static func looks(db: DataDb) -> Array[String]:
	var out: Array[String] = []
	for l: Dictionary in db.creation.get("looks", []):
		out.append(String(l["id"]))
	if out.is_empty():
		out.append(DEFAULT_LOOK)
	return out


## Background id → {name, blurb, class}; {} with no creation data.
static func backgrounds(db: DataDb) -> Dictionary:
	return db.creation.get("backgrounds", {})


## Sets who the player is in a fresh game. `id` keys (all optional): "name", "look",
## "background". An unknown look gives DEFAULT_LOOK, an unknown background none.
static func apply(gs: GameState, db: DataDb, id: Dictionary) -> void:
	var p := gs.player
	p.name = clean_name(String(id.get("name", "")))
	var look := String(id.get("look", DEFAULT_LOOK))
	p.look = look if looks(db).has(look) else DEFAULT_LOOK
	var bg := String(id.get("background", ""))
	p.background = bg if backgrounds(db).has(bg) else ""
	if p.background == "":
		return
	gs.flags[FLAG + p.background] = true
	var cls := String(backgrounds(db)[p.background]["class"])
	var start := float(db.creation["pool_start"]) * float(db.classes[cls]["offer_threshold"])
	gs.progression.pools[cls] = maxf(float(gs.progression.pools.get(cls, 0.0)), start)


## Who the player is, to follow "You are ": "Mara, an Earther, once a nurse", or "an Earther"
## (the default name, no background).
static func who(gs: GameState, db: DataDb) -> String:
	var p := gs.player
	var out := "an Earther" if p.name == DEFAULT_NAME else "%s, an Earther" % p.name
	if p.background != "" and backgrounds(db).has(p.background):
		out += ", once a %s" % String(backgrounds(db)[p.background]["name"]).to_lower()
	return out


## The sheet line: who() as a sentence ("Mara, an Earther, once a nurse.").
static func line(gs: GameState, db: DataDb) -> String:
	var w := who(gs, db)
	return w.left(1).to_upper() + w.substr(1) + "."


## Checks data/backgrounds.json. Returns the errors ([] with no creation data).
static func validate(db: DataDb) -> Array[String]:
	var errs: Array[String] = []
	var c := db.creation
	if c.is_empty():
		return errs
	var ps: Variant = c.get("pool_start", null)
	if not (ps is float or ps is int) or float(ps) < 0.0 or float(ps) > 1.0:
		errs.append("backgrounds.json: pool_start must be a number from 0 to 1.")
	if not DataDb.CONFIDENCE.has(c.get("confidence", "")):
		errs.append("backgrounds.json: confidence must be one of %s." % [DataDb.CONFIDENCE])
	var seen := {}
	var ls: Variant = c.get("looks", [])
	if not ls is Array or (ls as Array).is_empty():
		errs.append("backgrounds.json: looks must be a non-empty list.")
	else:
		for l: Variant in ls:
			if not l is Dictionary or not (l as Dictionary).get("id", null) is String \
					or String((l as Dictionary).get("name", "")).strip_edges() == "":
				errs.append("backgrounds.json: each look needs an id and a name.")
				continue
			if seen.has(l["id"]):
				errs.append("backgrounds.json: look '%s' is listed twice." % l["id"])
			seen[l["id"]] = true
		if not seen.has(DEFAULT_LOOK):
			errs.append("backgrounds.json: looks must keep '%s' (old saves use it)." % DEFAULT_LOOK)
	var bgs: Variant = c.get("backgrounds", {})
	if not bgs is Dictionary:
		errs.append("backgrounds.json: backgrounds must be an object.")
		return errs
	for id: String in bgs:
		var b: Variant = bgs[id]
		var at := "backgrounds.json: background '%s'" % id
		if not b is Dictionary:
			errs.append("%s must be an object." % at)
			continue
		for k: String in b:
			if not BACKGROUND_FIELDS.has(k):
				errs.append("%s: unknown field '%s'." % [at, k])
		for k: String in BACKGROUND_FIELDS:
			if not (b as Dictionary).get(k, null) is String or String(b[k]).strip_edges() == "":
				errs.append("%s: %s must be a non-empty string." % [at, k])
		if (b as Dictionary).get("class", null) is String and not db.classes.has(b["class"]):
			errs.append("%s: unknown class '%s'." % [at, b["class"]])
	return errs
