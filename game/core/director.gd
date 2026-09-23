## World director (DESIGN §4.4, night step 5; ADR 0005). Runs the canon
## events that are due, and patches the story when their conditions fail:
## substitute, delay, mutate, cancel, then propagation to dependent events.
## Pure functions over GameState + DataDb. No randomness: every choice is
## ordered by data and id.
class_name Director
extends RefCounted

## Event outcomes (history "outcome"; the last four are also event statuses).
const DONE := "done"
const SUBSTITUTED := "substituted"
const MUTATED := "mutated"
const CANCELLED := "cancelled"
const DELAYED := "delayed"
const KILLED := "killed"

## Failure kinds from evaluate().
## wait: may still come true (a flag, a pending dependency).
## role: a role has no living preferred NPC (substitute can fix it).
## hard: can never come true (a required NPC is dead, a dependency failed).
const FAIL_WAIT := "wait"
const FAIL_ROLE := "role"
const FAIL_HARD := "hard"

## Anonymous role fillers are "*" + the first fallback tag, e.g. "*rock_crab".
const ANONYMOUS := "*"
const UNRELIABLE_LINE := "The future you remember no longer feels certain."


## Runs every day from world.last_day + 1 up to `through_day`.
## Returns the lines for the morning summary (T1 rumors, drift warning).
static func run(gs: GameState, db: DataDb, through_day: int) -> Array[String]:
	var lines: Array[String] = []
	var w := gs.world
	var drift_before := w.drift
	for day in range(w.last_day + 1, through_day + 1):
		_run_day(gs, db, day, lines)
		w.last_day = day
	var limit := float(db.rules["director"]["unreliable_at"])
	if drift_before < limit and w.drift >= limit:
		lines.append(UNRELIABLE_LINE)
	return lines


## Checks one event now. Returns {"fails": [{"kind", "why"}], "roles": {role: npc},
## "open": [roles with no living preferred NPC]}.
static func evaluate(gs: GameState, db: DataDb, id: String) -> Dictionary:
	var canon := db.canon
	var w := gs.world
	var ev: Dictionary = canon.events[id]
	var fails: Array[Dictionary] = []
	var req: Dictionary = ev["requires"]
	for npc: String in req.get("alive", []):
		if not w.is_alive(canon, npc):
			fails.append(_fail(FAIL_HARD, "%s is dead" % npc))
	for f: String in req.get("flags", []):
		if not gs.flags.get(f, false):
			fails.append(_fail(FAIL_WAIT, "needs %s" % f))
	for f: String in req.get("not_flags", []):
		if gs.flags.get(f, false):
			fails.append(_fail(FAIL_WAIT, "blocked by %s" % f))
	for dep: String in ev["depends_on"]:
		var s := w.status(dep)
		if s == WorldState.PENDING:
			fails.append(_fail(FAIL_WAIT, "waits for %s" % dep))
		elif s != DONE and s != SUBSTITUTED:
			fails.append(_fail(FAIL_HARD, "%s was %s" % [dep, s]))
	var roles := {}
	var open: Array[String] = []
	for name: String in ev["roles"]:
		var r: Dictionary = ev["roles"][name]
		var prefer: Array = r.get("prefer", [])
		if prefer.is_empty():
			roles[name] = ANONYMOUS + str(r["fallback_tags"][0])
			continue
		for npc: String in prefer:
			if w.is_alive(canon, npc) and not roles.values().has(npc):
				roles[name] = npc
				break
		if not roles.has(name) and not r.get("optional", false):
			open.append(name)
			fails.append(_fail(FAIL_ROLE, "no %s" % name))
	return {"fails": fails, "roles": roles, "open": open}


## Walks the event's on_fail list. `soft` = false during propagation:
## substitute and delay cannot help an event whose dependency failed.
static func resolve(gs: GameState, db: DataDb, id: String, day: int, check: Dictionary,
		lines: Array[String], soft: bool = true) -> void:
	var w := gs.world
	var ev: Dictionary = db.canon.events[id]
	var reason := "; ".join((check["fails"] as Array).map(func(f: Dictionary) -> String: return f["why"]))
	for step: String in ev["on_fail"]:
		if step == "substitute":
			var fails: Array = check["fails"]
			if soft and not (check["open"] as Array).is_empty() and not _has(check, FAIL_HARD) \
					and _substitute(gs, db, ev, check):
				check["fails"] = fails.filter(func(f: Dictionary) -> bool: return f["kind"] != FAIL_ROLE)
				check["open"] = []
				if (check["fails"] as Array).is_empty():
					_fire(gs, db, id, day, SUBSTITUTED, check["roles"], lines)
					return
		elif step == "delay":
			var limit := int(ev.get("delay_limit", db.rules["director"]["default_delay_limit"]))
			var latest := w.latest(id, ev)
			if soft and _only(check, FAIL_WAIT) and latest < int(ev["window"]["latest"]) + limit:
				w.events[id] = {"status": WorldState.PENDING, "latest": latest + 1}
				_log(gs, db, id, day, DELAYED, {}, "", reason)
				return
		elif step == "cancel":
			break
		else:
			var alt := CanonDb.mutate_target(step)
			if alt != "" and w.status(alt) == WorldState.PENDING:
				var alt_check := evaluate(gs, db, alt)
				if (alt_check["fails"] as Array).is_empty():
					_close(gs, db, id, day, MUTATED, {}, alt, reason)
					_fire(gs, db, alt, day, DONE, alt_check["roles"], lines)
					_propagate(gs, db, id, day, lines)
					return
	_close(gs, db, id, day, CANCELLED, {}, "", reason)
	_propagate(gs, db, id, day, lines)


## The player kills an NPC (M5 combat will call this). Returns "" or an error.
static func player_kill(gs: GameState, db: DataDb, npc: String) -> String:
	if not db.canon.npcs.has(npc):
		return "Unknown NPC '%s'." % npc
	if not gs.world.is_alive(db.canon, npc):
		return "%s is already dead." % db.canon.npcs[npc]["name"]
	gs.world.set_alive(npc, false)
	gs.world.history.append({"day": gs.clock.day(), "event": "player.kill", "outcome": KILLED,
			"roles": {"victim": npc}})
	return ""


## Fires everything that can fire (repeated until stable, so same-day chains
## work), then resolves the events that cannot wait any more.
static func _run_day(gs: GameState, db: DataDb, day: int, lines: Array[String]) -> void:
	var order := db.canon.order
	while true:
		var changed := false
		for id in order:
			if _is_due(gs, db, id, day):
				var check := evaluate(gs, db, id)
				if (check["fails"] as Array).is_empty():
					_fire(gs, db, id, day, DONE, check["roles"], lines)
					changed = true
		if changed:
			continue
		for id in order:
			if not _is_due(gs, db, id, day):
				continue
			var check := evaluate(gs, db, id)
			if (check["fails"] as Array).is_empty():
				_fire(gs, db, id, day, DONE, check["roles"], lines)
				changed = true
			elif not _can_wait(gs, db, id, day, check):
				resolve(gs, db, id, day, check, lines)
				changed = true
		if not changed:
			return


static func _is_due(gs: GameState, db: DataDb, id: String, day: int) -> bool:
	return not db.canon.alt_only.has(id) \
			and gs.world.status(id) == WorldState.PENDING \
			and int(db.canon.events[id]["window"]["earliest"]) <= day


## Only "wait" failures (plus role gaps) and the window is still open.
static func _can_wait(gs: GameState, db: DataDb, id: String, day: int, check: Dictionary) -> bool:
	var kinds := (check["fails"] as Array).map(func(f: Dictionary) -> String: return f["kind"])
	return kinds.has(FAIL_WAIT) and not kinds.has(FAIL_HARD) \
			and day < gs.world.latest(id, db.canon.events[id])


static func _only(check: Dictionary, kind: String) -> bool:
	return (check["fails"] as Array).all(func(f: Dictionary) -> bool: return f["kind"] == kind)


static func _has(check: Dictionary, kind: String) -> bool:
	return (check["fails"] as Array).any(func(f: Dictionary) -> bool: return f["kind"] == kind)


## Fills the open roles with the living NPC that matches most fallback tags
## (at least one; not already in the event; ties → lowest id).
static func _substitute(gs: GameState, db: DataDb, ev: Dictionary, check: Dictionary) -> bool:
	var roles: Dictionary = check["roles"]
	var ids := db.canon.npcs.keys()
	ids.sort()
	for name: String in check["open"]:
		var tags: Array = ev["roles"][name]["fallback_tags"]
		var best := ""
		var best_score := 0
		for npc: String in ids:
			if roles.values().has(npc) or not gs.world.is_alive(db.canon, npc):
				continue
			var npc_tags: Array = db.canon.npcs[npc].get("tags", [])
			var score := tags.filter(func(t: String) -> bool: return npc_tags.has(t)).size()
			if score > best_score:
				best = npc
				best_score = score
		if best == "":
			return false
		roles[name] = best
	return true


static func _fire(gs: GameState, db: DataDb, id: String, day: int, outcome: String,
		roles: Dictionary, lines: Array[String]) -> void:
	var ev: Dictionary = db.canon.events[id]
	_close(gs, db, id, day, outcome, roles, "", "")
	_apply_effects(gs, ev, roles)
	if int(ev["tier"]) == 1 and ev.has("rumor"):
		lines.append("Rumor: %s" % ev["rumor"])


## Effects on flags, NPCs and relationships. An NPC id in kill/relationship
## that a role replaced (substitute, or a later prefer) means the replacement.
static func _apply_effects(gs: GameState, ev: Dictionary, roles: Dictionary) -> void:
	var fx: Dictionary = ev["effects"]
	for f: String in fx.get("set_flags", []):
		gs.flags[f] = true
	for f: String in fx.get("clear_flags", []):
		gs.flags.erase(f)
	var remap := {}
	for name: String in roles:
		for npc: String in ev["roles"][name].get("prefer", []):
			if npc != roles[name] and not roles.values().has(npc):
				remap[npc] = roles[name]
	for npc: String in fx.get("kill", []):
		gs.world.set_alive(remap.get(npc, npc), false)
	for rel: Dictionary in fx.get("relationship", []):
		gs.world.add_relationship(remap.get(rel["from"], rel["from"]),
				remap.get(rel["to"], rel["to"]), int(rel["delta"]))


## Sets the final status, logs history and adds drift.
static func _close(gs: GameState, db: DataDb, id: String, day: int, outcome: String,
		roles: Dictionary, via: String, reason: String) -> void:
	gs.world.events[id] = {"status": outcome, "day": day, "roles": roles.duplicate()}
	_log(gs, db, id, day, outcome, roles, via, reason)


static func _log(gs: GameState, db: DataDb, id: String, day: int, outcome: String,
		roles: Dictionary, via: String, reason: String) -> void:
	var entry := {"day": day, "event": id, "outcome": outcome, "roles": roles.duplicate()}
	if via != "":
		entry["via"] = via
	if reason != "":
		entry["reason"] = reason
	gs.world.history.append(entry)
	var rules: Dictionary = db.rules["director"]
	var tier := str(int(db.canon.events[id]["tier"]))
	gs.world.drift += float(rules["drift"].get(outcome, 0.0)) * float(rules["tier_weight"].get(tier, 1.0))


## A cancelled or mutated event never happened: every pending event that
## depends on it fails for good now (recursively).
static func _propagate(gs: GameState, db: DataDb, id: String, day: int, lines: Array[String]) -> void:
	for dep: String in db.canon.dependents[id]:
		if db.canon.alt_only.has(dep) or gs.world.status(dep) != WorldState.PENDING:
			continue
		var why := "%s was %s" % [id, gs.world.status(id)]
		var check := {"fails": [_fail(FAIL_HARD, why)], "roles": {}, "open": []}
		resolve(gs, db, dep, day, check, lines, false)


static func _fail(kind: String, why: String) -> Dictionary:
	return {"kind": kind, "why": why}
