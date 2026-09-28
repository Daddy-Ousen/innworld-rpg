## Traps (M13.T, ADR 0020): the trapped rooms of Liscor's dungeon (4.08 T,
## 4.19). A map lists its traps in "traps" (they are not objects):
##   {"id", "at": [x, y], "name", "damage": [min, max], "hidden": bool,
##    "spot": 0..1 (base chance a search finds it), "disarm": 0..1 (base
##    chance to disarm it), "once": bool (spent for good once it fires),
##    "rearm_minutes"? (a trap that is not once: spent this long, then armed
##    again; without it the trap fires on every step), "drop_to"?: {"to",
##    "pos"} (a pit: the player falls to that map tile), "line"? (the text
##    when it fires), "when_flags"?, "unless_flags"?}.
## Stepping onto an armed trap springs it: seeded damage (Combat.damage_player;
## it can knock the player out) and the trap is found. A found, armed trap
## blocks the player like a wall. A search (rules.traps.search_action) rolls
## each hidden trap near the player against spot + spot_per_point × perception;
## a disarm (rules.traps.disarm_action) rolls disarm + disarm_per_point ×
## dexterity; a failed disarm springs the trap.
## State (save v14): CombatState.traps, "<area>/<id>" → {"found", "spent",
## "disarmed", "sprung": clock minute it last fired}; only traps that changed.
class_name Traps
extends RefCounted

## Interact option ids: the search, and "trap:<id>" for a found trap nearby.
const SEARCH := "search"
const TRAP := "trap:"


static func rules(db: DataDb) -> Dictionary:
	return db.rules.get("traps", {})


## The traps of `area` whose flags hold now.
static func traps_on(gs: GameState, db: DataDb, area: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not db.maps.areas.has(area):
		return out
	for t: Dictionary in db.maps.areas[area].get("traps", []):
		if MapDb.flags_hold(t, gs.flags):
			out.append(t)
	return out


## The trap `id` of `area` if it is on now, else {}.
static func trap_of(gs: GameState, db: DataDb, area: String, id: String) -> Dictionary:
	for t in traps_on(gs, db, area):
		if t["id"] == id:
			return t
	return {}


## The trap on `at` in `area` (on now), or {}.
static func trap_at(gs: GameState, db: DataDb, area: String, at: Vector2i) -> Dictionary:
	for t in traps_on(gs, db, area):
		if _pos(t) == at:
			return t
	return {}


static func key(area: String, id: String) -> String:
	return "%s/%s" % [area, id]


## {"found", "spent", "disarmed", "sprung"} of trap `t` in `area`. A trap
## that is not hidden counts as found.
static func state(gs: GameState, area: String, t: Dictionary) -> Dictionary:
	var s: Dictionary = gs.combat.traps.get(key(area, t["id"]), {})
	return {"found": bool(s.get("found", false)) or not bool(t["hidden"]),
		"spent": bool(s.get("spent", false)), "disarmed": bool(s.get("disarmed", false)),
		"sprung": int(s.get("sprung", -1))}


## True if trap `t` fires when stepped on now: not disarmed, and not spent
## (a spent trap with rearm_minutes is armed again after them).
static func is_armed(gs: GameState, area: String, t: Dictionary) -> bool:
	var s := state(gs, area, t)
	if s["disarmed"]:
		return false
	if not s["spent"]:
		return true
	return not bool(t["once"]) and t.has("rearm_minutes") \
			and gs.clock.total_minutes >= int(s["sprung"]) + int(t["rearm_minutes"])


## True if a found, armed trap is on `at`: the player will not step there.
static func blocks(gs: GameState, db: DataDb, area: String, at: Vector2i) -> bool:
	var t := trap_at(gs, db, area, at)
	return not t.is_empty() and state(gs, area, t)["found"] and is_armed(gs, area, t)


## After a step: springs the armed trap under the player. Returns {} or
## {"id", "name", "damage", "drop_to": map id or ""}.
static func on_step(gs: GameState, db: DataDb) -> Dictionary:
	var area := gs.player.area
	var t := trap_at(gs, db, area, gs.player.pos())
	if t.is_empty() or not is_armed(gs, area, t):
		return {}
	var out := _spring(gs, db, area, t)
	out["drop_to"] = ""
	if t.has("drop_to") and not Combat.is_down(gs):
		var d: Dictionary = t["drop_to"]
		gs.player.place(d["to"], Vector2i(int(d["pos"][0]), int(d["pos"][1])))
		out["drop_to"] = d["to"]
	return out


## Searches for traps around the player (the search action). Returns
## {"record", "error", "found": [trap ids]}; the lines say what was found.
static func search(gs: GameState, db: DataDb) -> Dictionary:
	var r := rules(db)
	var area := gs.player.area
	var rec := Actions.perform(gs, db, r["search_action"], {"context": _context(gs, db)})
	if rec.is_empty():
		return {"record": {}, "error": "You are too tired.", "found": []}
	var chance_add := float(r["spot_per_point"]) * Stats.get_stat(gs, db, "perception")
	var found: Array[String] = []
	for t in traps_on(gs, db, area):
		if _dist(_pos(t), gs.player.pos()) > int(r["search_radius"]) \
				or state(gs, area, t)["found"] or not is_armed(gs, area, t):
			continue
		if gs.rng.randf() < clampf(float(t["spot"]) + chance_add, 0.0, 1.0):
			_mark(gs, area, t, "found", true)
			found.append(t["id"])
			gs.combat.lines.append(String(r["found_line"]) % t["name"])
	if found.is_empty():
		gs.combat.lines.append(r["none_line"])
	return {"record": rec, "error": "", "found": found}


## Tries to disarm the found trap `id` next to the player (the disarm
## action). Returns {"record", "error", "disarmed": bool, "damage": int}.
## A failure springs the trap (the record's outcome is "fail").
static func disarm(gs: GameState, db: DataDb, id: String) -> Dictionary:
	var r := rules(db)
	var area := gs.player.area
	var t := trap_of(gs, db, area, id)
	if t.is_empty() or _dist(_pos(t), gs.player.pos()) > 1 \
			or not state(gs, area, t)["found"] or not is_armed(gs, area, t):
		return {"record": {}, "error": "There is no trap to disarm there.", "disarmed": false, "damage": 0}
	var chance := clampf(float(t["disarm"])
			+ float(r["disarm_per_point"]) * Stats.get_stat(gs, db, "dexterity"), 0.0, 1.0)
	var ok := gs.rng.randf() < chance
	var ctx := _context(gs, db)
	ctx["trap"] = id
	var rec := Actions.perform(gs, db, r["disarm_action"],
			{"context": ctx, "outcome": "success" if ok else "fail"})
	if rec.is_empty():
		return {"record": {}, "error": "You are too tired.", "disarmed": false, "damage": 0}
	if ok:
		_mark(gs, area, t, "disarmed", true)
		gs.combat.lines.append(String(r["disarmed_line"]) % t["name"])
		return {"record": rec, "error": "", "disarmed": true, "damage": 0}
	gs.combat.lines.append(String(r["disarm_fail_line"]) % t["name"])
	return {"record": rec, "error": "", "disarmed": false, "damage": _spring(gs, db, area, t)["damage"]}


## Interact options (M13.T): the search on a map with traps, and each found,
## armed trap next to the player. Shaped like Interact.options entries.
static func options(gs: GameState, db: DataDb) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var r := rules(db)
	var area := gs.player.area
	var here := traps_on(gs, db, area)
	if r.is_empty() or here.is_empty():
		return out
	for t in here:
		if _dist(_pos(t), gs.player.pos()) <= 1 and state(gs, area, t)["found"] \
				and is_armed(gs, area, t):
			out.append(_option(TRAP + String(t["id"]), t["name"], r["disarm_action"]))
	out.append(_option(SEARCH, r["search_name"], r["search_action"]))
	return out


## Fires trap `t`: damage, found, spent. Returns {"id", "name", "damage"}.
static func _spring(gs: GameState, db: DataDb, area: String, t: Dictionary) -> Dictionary:
	var dmg := gs.rng.randi_range(int(t["damage"][0]), int(t["damage"][1]))
	gs.combat.lines.append(String(t.get("line", rules(db)["sprung_line"])).replace("%s", t["name"]))
	_mark(gs, area, t, "found", true)
	if bool(t["once"]) or t.has("rearm_minutes"):
		_mark(gs, area, t, "spent", true)
		_mark(gs, area, t, "sprung", gs.clock.total_minutes)
	Combat.damage_player(gs, db, dmg)
	return {"id": t["id"], "name": t["name"], "damage": dmg}


static func _mark(gs: GameState, area: String, t: Dictionary, field: String, value: Variant) -> void:
	var k := key(area, t["id"])
	var s: Dictionary = gs.combat.traps.get(k, {})
	s[field] = value
	gs.combat.traps[k] = s


static func _context(gs: GameState, db: DataDb) -> Dictionary:
	var ctx := {"location": db.maps.areas[gs.player.area]["location"]}
	var zone := db.maps.zone_at(gs.player.area, gs.player.pos())
	if zone != "":
		ctx["zone"] = zone
	return ctx


static func _option(id: String, name: String, action: String) -> Dictionary:
	return {"id": id, "name": name, "actions": [action], "npc": false, "trap": true, "sleep": false,
		"item": "", "price": 0, "trades": [] as Array[Dictionary], "ride": {}}


static func _pos(t: Dictionary) -> Vector2i:
	return Vector2i(int(t["at"][0]), int(t["at"][1]))


static func _dist(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))
