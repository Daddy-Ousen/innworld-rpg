## NPC voices (M30, ADR 0044 "M30.0"): own greetings by band, lines after events,
## own talk options and map barks, from data/voices.json. Hints and flavour only:
## a voice has no state and changes nothing by itself (an option runs a normal
## action). Picks use a stable hash of "day|npc|kind", never gs.rng, so a voice
## does not shift the RNG stream (canon and balance sims keep their numbers).
## No rules.voice = no voices at all (toy dbs).
##
## Gates (lines and options), as in data/talk.json: "flags" (all set),
## "not_flags" (none set), "days" [from, to], "min_band" (regard at or above the
## band's minimum in rules.standing.bands; "stranger" is the band with label "").
## Text in square brackets is an action, not speech ("[Toren rattles.]").
##
## M30.4: an option may also have "set_flags" [flag] (set once the option is done),
## "relationship" (added to the NPC's relationship with the player) and "page"
## {"title", "lines"} (a text page the screen shows). Its own not_flags make it a
## one-time talk (the Earther meetings), so a voice still keeps no state.
class_name Voice
extends RefCounted

const STRANGER := "stranger"
const RULE_FIELDS := ["bark_tiles", "bark_minutes", "max_words", "line"]
const ENTRY_FIELDS := ["confidence", "canon_ref", "greet", "idle", "lines", "options", "note"]
const GATE_FIELDS := ["flags", "not_flags", "days", "min_band"]
const OPTION_FIELDS := ["id", "label", "action", "context", "set_flags", "relationship", "page"]
const FNV_OFFSET := 2166136261
const FNV_PRIME := 16777619


static func rules(db: DataDb) -> Dictionary:
	return db.rules.get("voice", {})


static func on(db: DataDb) -> bool:
	return not rules(db).is_empty()


## The voices.json entry of `npc`, or {} (no voice, or voices off).
static func of(db: DataDb, npc: String) -> Dictionary:
	return db.voices.get(npc, {}) if on(db) else {}


## The greet key of the NPC's band now: STRANGER for the "" band, else its label.
static func band_key(gs: GameState, db: DataDb, npc: String) -> String:
	var label := String(Standing.band(gs, db, npc)["label"])
	return STRANGER if label == "" else label


## The NPC's own greeting for the band they are in now, as a log line, or "" (none:
## the caller uses the generic band line).
static func greet(gs: GameState, db: DataDb, npc: String) -> String:
	var lines: Array = (of(db, npc).get("greet", {}) as Dictionary).get(band_key(gs, db, npc), [])
	if lines.is_empty():
		return ""
	return say(db, npc, pick(lines, "%d|%s|greet" % [gs.clock.day(), npc]))


## Every own line of `npc` whose gate passes now (texts, file order).
static func lines_now(gs: GameState, db: DataDb, npc: String) -> Array[String]:
	var out: Array[String] = []
	for l: Dictionary in of(db, npc).get("lines", []):
		if passes(gs, db, l, npc):
			out.append(String(l["text"]))
	return out


## One own line of `npc` for today as a log line, or "" (none: the caller falls back
## to a talk topic).
static func line(gs: GameState, db: DataDb, npc: String) -> String:
	var texts := lines_now(gs, db, npc)
	if texts.is_empty():
		return ""
	return say(db, npc, pick(texts, "%d|%s|line" % [gs.clock.day(), npc]))


## The NPC's own talk options open now: [{"id", "label", "action"}], file order.
static func options(gs: GameState, db: DataDb, npc: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for o: Dictionary in of(db, npc).get("options", []):
		if passes(gs, db, o, npc):
			out.append({"id": String(o["id"]), "label": String(o["label"]), "action": String(o["action"])})
	return out


## The option `id` of `npc` (its JSON), or {}.
static func option(db: DataDb, npc: String, id: String) -> Dictionary:
	for o: Dictionary in of(db, npc).get("options", []):
		if String(o["id"]) == id:
			return o
	return {}


## M30.4: what a done option `opt` of `npc` changes: its set_flags and relationship.
## Returns its page {"title", "lines"}, or {} (none).
static func apply(gs: GameState, db: DataDb, npc: String, opt: Dictionary) -> Dictionary:
	for f: String in opt.get("set_flags", []):
		gs.flags[f] = true
	var rel := int(opt.get("relationship", 0))
	if rel != 0:
		gs.world.add_relationship(npc, NpcSim.PLAYER, rel)
	if not opt.has("page"):
		return {}
	var lines: Array[String] = []
	lines.assign(opt["page"]["lines"])
	return {"title": String(opt["page"]["title"]), "lines": lines}


## The map bark of `npc` for this game minute: one idle line per rules.voice.bark_minutes
## bucket, or "". Pure: the view calls it; nothing reads gs.rng or state.
static func bark(db: DataDb, day: int, npc: String, minute: int) -> String:
	var idle: Array = of(db, npc).get("idle", [])
	if idle.is_empty():
		return ""
	return pick(idle, "%d|%s|%d" % [day, npc, bark_bucket(db, minute)])


## The bark bucket of a minute of the day (a new bark may show when it changes).
static func bark_bucket(db: DataDb, minute: int) -> int:
	@warning_ignore("integer_division")
	return minute / maxi(int(rules(db).get("bark_minutes", 20)), 1)


## Speech as a log line ("Relc: \"...\""); an action in brackets stays as it is.
static func say(db: DataDb, npc: String, text: String) -> String:
	if text.begins_with("["):
		return text
	return String(rules(db)["line"]) % [db.canon.npcs[npc]["name"], text]


## A stable pick from `list` by `key` (FNV-1a, 32 bit).
static func pick(list: Array, key: String) -> String:
	return String(list[hash32(key) % list.size()])


static func hash32(key: String) -> int:
	var h := FNV_OFFSET
	for b in key.to_utf8_buffer():
		h = ((h ^ b) * FNV_PRIME) & 0xFFFFFFFF
	return h


## True if a line or option gate passes for `npc` now.
static func passes(gs: GameState, db: DataDb, g: Dictionary, npc: String) -> bool:
	for f: String in g.get("flags", []):
		if not gs.flags.get(f, false):
			return false
	for f: String in g.get("not_flags", []):
		if gs.flags.get(f, false):
			return false
	var days: Array = g.get("days", [])
	var day := gs.clock.day()
	if days.size() == 2 and (day < int(days[0]) or day > int(days[1])):
		return false
	var band := String(g.get("min_band", ""))
	return band == "" or Standing.regard(gs, db, npc) >= band_min(db, band)


## The lowest regard of the band `key` (STRANGER = the "" band). A very high number for
## an unknown band (the validator stops that).
static func band_min(db: DataDb, key: String) -> int:
	var label := "" if key == STRANGER else key
	for b: Array in Standing.rules(db).get("bands", []):
		if String(b[1]) == label:
			return int(b[0])
	return 1 << 30


## Greet keys the data may use: STRANGER and every non-empty band label.
static func band_keys(db: DataDb) -> Array[String]:
	var out: Array[String] = [STRANGER]
	for b: Array in Standing.rules(db).get("bands", []):
		if String(b[1]) != "":
			out.append(String(b[1]))
	return out


## Checks rules.voice and data/voices.json. Returns the errors.
static func validate(db: DataDb) -> Array[String]:
	var errs: Array[String] = []
	if not on(db):
		if not db.voices.is_empty():
			errs.append("voices.json has voices, but rules.voice is missing.")
		return errs
	var r := rules(db)
	for f: String in RULE_FIELDS:
		if not r.has(f):
			errs.append("rules.voice: missing '%s'." % f)
	if not errs.is_empty():
		return errs
	for f: String in ["bark_tiles", "bark_minutes", "max_words"]:
		if int(r[f]) < 1:
			errs.append("rules.voice.%s must be >= 1." % f)
	if String(r["line"]).count("%s") != 2:
		errs.append("rules.voice.line needs two %s (name, text).")
	for id: String in db.voices:
		errs.append_array(_validate_entry(db, id, db.voices[id]))
	return errs


static func _validate_entry(db: DataDb, id: String, v: Variant) -> Array[String]:
	var errs: Array[String] = []
	var at := "voice '%s'" % id
	if not v is Dictionary:
		return ["%s: must be an object." % at] as Array[String]
	var e: Dictionary = v
	if not db.canon.npcs.has(id):
		errs.append("%s: unknown canon npc." % at)
	for k: String in e:
		if not ENTRY_FIELDS.has(k):
			errs.append("%s: unknown field '%s'." % [at, k])
	if not DataDb.CONFIDENCE.has(e.get("confidence", "")):
		errs.append("%s: confidence must be one of %s." % [at, DataDb.CONFIDENCE])
	if e.has("canon_ref") and not e["canon_ref"] is Dictionary:
		errs.append("%s: canon_ref must be an object." % at)
	var greet: Variant = e.get("greet", {})
	if not greet is Dictionary:
		errs.append("%s: greet must be an object." % at)
	else:
		var keys := band_keys(db)
		for k: String in greet:
			if not keys.has(k):
				errs.append("%s: greet key '%s' is not one of %s." % [at, k, keys])
			errs.append_array(_texts(db, "%s greet.%s" % [at, k], greet[k]))
	errs.append_array(_texts(db, at + " idle", e.get("idle", [])))
	var lines: Variant = e.get("lines", [])
	if not lines is Array:
		errs.append("%s: lines must be a list." % at)
	else:
		for i in (lines as Array).size():
			var l: Variant = lines[i]
			var lat := "%s lines[%d]" % [at, i]
			if not l is Dictionary or not (l as Dictionary).has("text"):
				errs.append("%s: must be an object with text." % lat)
				continue
			errs.append_array(_texts(db, lat, [l["text"]]))
			errs.append_array(_gate(db, lat, l, ["text"]))
	var opts: Variant = e.get("options", [])
	if not opts is Array:
		errs.append("%s: options must be a list." % at)
		return errs
	var seen := {}
	for i in (opts as Array).size():
		var o: Variant = opts[i]
		var oat := "%s options[%d]" % [at, i]
		if not o is Dictionary:
			errs.append("%s: must be an object." % oat)
			continue
		var od: Dictionary = o
		var before := errs.size()
		for f: String in ["id", "label", "action"]:
			if not od.get(f, null) is String or String(od[f]).strip_edges() == "":
				errs.append("%s: %s must be a non-empty string." % [oat, f])
		if errs.size() > before:
			continue
		if seen.has(od["id"]):
			errs.append("%s: option id '%s' is used twice." % [oat, od["id"]])
		seen[od["id"]] = true
		if not db.actions.has(od["action"]):
			errs.append("%s: unknown action '%s'." % [oat, od["action"]])
		if od.has("context") and not od["context"] is Dictionary:
			errs.append("%s: context must be an object." % oat)
		errs.append_array(_effects(db, oat, od))
		errs.append_array(_gate(db, oat, od, OPTION_FIELDS))
	return errs


## M30.4: set_flags (strings), relationship (a whole number), page {title, lines}.
static func _effects(db: DataDb, at: String, o: Dictionary) -> Array[String]:
	var errs: Array[String] = []
	if o.has("set_flags") and not (o["set_flags"] is Array \
			and (o["set_flags"] as Array).all(func(x: Variant) -> bool: return x is String)):
		errs.append("%s: set_flags must be a list of strings." % at)
	if o.has("relationship"):
		var r: Variant = o["relationship"]
		if not ((r is int) or (r is float and is_equal_approx(float(r), roundf(float(r))))):
			errs.append("%s: relationship must be a whole number." % at)
	if o.has("page"):
		var p: Variant = o["page"]
		if not (p is Dictionary and (p as Dictionary).get("title", null) is String \
				and String(p["title"]).strip_edges() != "" and (p as Dictionary).get("lines", null) is Array \
				and not (p["lines"] as Array).is_empty()):
			errs.append("%s: page must be {title, lines} with a title and at least one line." % at)
		else:
			errs.append_array(_texts(db, at + " page", p["lines"]))
	return errs


## Each text: a non-empty string of at most rules.voice.max_words words.
static func _texts(db: DataDb, at: String, list: Variant) -> Array[String]:
	var errs: Array[String] = []
	if not list is Array:
		return ["%s: must be a list of strings." % at] as Array[String]
	var most := int(rules(db)["max_words"])
	for t: Variant in list:
		if not t is String or String(t).strip_edges() == "":
			errs.append("%s: texts must be non-empty strings." % at)
		elif String(t).split(" ", false).size() > most:
			errs.append("%s: '%s' has more than %d words." % [at, t, most])
	return errs


static func _gate(db: DataDb, at: String, g: Dictionary, own: Array) -> Array[String]:
	var errs: Array[String] = []
	for k: String in g:
		if not GATE_FIELDS.has(k) and not own.has(k):
			errs.append("%s: unknown field '%s'." % [at, k])
	for f: String in ["flags", "not_flags"]:
		if g.has(f) and not (g[f] is Array and (g[f] as Array).all(func(x: Variant) -> bool: return x is String)):
			errs.append("%s: %s must be a list of strings." % [at, f])
	if g.has("days"):
		var d: Variant = g["days"]
		if not (d is Array and (d as Array).size() == 2 and int(d[0]) >= 1 and int(d[0]) <= int(d[1])):
			errs.append("%s: days must be [from, to] with 1 <= from <= to." % at)
	if g.has("min_band") and not band_keys(db).has(String(g["min_band"])):
		errs.append("%s: min_band '%s' is not one of %s." % [at, g["min_band"], band_keys(db)])
	return errs
