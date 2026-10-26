## Quests (M33.2, ADR 0044 "M33.2"): tasks from data/quests.json. A quest has a giver
## (a canon NPC), a gate (as a voice option: "flags", "not_flags", "days", "min_band"),
## steps, rewards and short texts (own words). The state is gs.quests (QuestState).
##
## Start: while the gate passes, the giver's talk menu offers "Ask about: <title>"
## (Interact.QUEST); the pick runs a talk and then `start`.
## Steps, in order: {"text", "flag"} passes once the flag is set; {"text", "did",
## "count"?} counts action records that match "did" (Director.record_matches, the
## event-hook matcher) made while it is the current step, `count` of them (default 1).
## Actions.perform sends every record to `after_action`; Commands._after and Night.run
## call `update` (flag steps, fails). A "go back to the giver" step is a did step on a
## talk action with context {"npc": giver}.
## Fail: the giver dies, a "fail.flags" flag is set, or the day passes "fail.after_day".
## Rewards, once, at the last step: "relationship" (with the giver), "coins" (copper),
## "goods" {good: count}, "flags" (a spell lesson's learn.flags can wait on one).
## No quests (toy dbs) = nothing happens. No gs.rng is used.
class_name Quests
extends RefCounted

const ASK := "Ask about: %s"
const NEW := "New task: %s."
const NEXT := "Task: %s"
const DONE_LINE := "Task done: %s."
const FAILED_LINE := "Task failed: %s."
const REWARD := "You get %s."
const UNKNOWN := "There is no such task."
const TAKEN := "You already took on that task."
const GONE := "That task is gone."
const NOT_NOW := "%s has no task for you now."
const NONE := "  No tasks yet."
const QUEST_FIELDS := ["title", "giver", "offer", "gate", "fail", "steps", "rewards", "done",
	"confidence", "canon_ref", "note"]
const STEP_FIELDS := ["text", "flag", "did", "count"]
const DID_FIELDS := ["action", "outcome", "context"]
const FAIL_FIELDS := ["flags", "after_day"]
const REWARD_FIELDS := ["relationship", "coins", "goods", "flags"]


static func on(db: DataDb) -> bool:
	return not db.quests.is_empty()


## The quests.json entry `id`, or {}.
static func quest(db: DataDb, id: String) -> Dictionary:
	return db.quests.get(id, {})


## The player's state of quest `id` (QuestState.entries), or {} (not taken on).
static func entry(gs: GameState, id: String) -> Dictionary:
	return gs.quests.entries.get(id, {})


## QuestState.ACTIVE / DONE / FAILED, or "" (not taken on).
static func status(gs: GameState, id: String) -> String:
	return String(entry(gs, id).get("status", ""))


## The quests `npc` offers now: [{"id", "label"}], file order.
static func offers(gs: GameState, db: DataDb, npc: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id: String in db.quests:
		if String(db.quests[id]["giver"]) == npc and why_not(gs, db, id) == "":
			out.append({"id": id, "label": ASK % db.quests[id]["title"]})
	return out


## Why quest `id` cannot start now ("" = it can). Not about the distance to the giver.
static func why_not(gs: GameState, db: DataDb, id: String) -> String:
	var q := quest(db, id)
	if q.is_empty():
		return UNKNOWN
	if not entry(gs, id).is_empty():
		return TAKEN
	if _failing(gs, db, id):
		return GONE
	var giver := String(q["giver"])
	if not Voice.passes(gs, db, q.get("gate", {}), giver):
		return NOT_NOW % db.canon.npcs[giver]["name"]
	return ""


## Takes on quest `id`: the giver says the offer, the first step shows. Lines go to
## gs.combat.lines. Returns "" or why not.
static func start(gs: GameState, db: DataDb, id: String) -> String:
	var why := why_not(gs, db, id)
	if why != "":
		return why
	var q := quest(db, id)
	gs.quests.entries[id] = {"status": QuestState.ACTIVE, "step": 0, "count": 0, "day": gs.clock.day(),
		"end_day": -1}
	var lines := gs.combat.lines
	lines.append(NEW % q["title"])
	lines.append(_say(db, String(q["giver"]), String(q["offer"])))
	if _flag_met(gs, q["steps"][0]):
		lines.append_array(_next(gs, db, id))
	else:
		lines.append(NEXT % q["steps"][0]["text"])
	return ""


## Counts the action record `rec` for each open quest whose current step is a did
## step it matches (Actions.perform calls this). Lines go to gs.combat.lines.
static func after_action(gs: GameState, db: DataDb, rec: Dictionary) -> void:
	if not on(db) or rec.is_empty():
		return
	for id: String in gs.quests.entries.keys():
		var e: Dictionary = gs.quests.entries[id]
		if e["status"] != QuestState.ACTIVE or quest(db, id).is_empty() or _failing(gs, db, id):
			continue
		var step: Dictionary = quest(db, id)["steps"][int(e["step"])]
		if step.has("did") and Director.record_matches(rec, step["did"]):
			e["count"] = int(e["count"]) + 1
			if int(e["count"]) >= int(step.get("count", 1)):
				gs.combat.lines.append_array(_next(gs, db, id))


## Fails the quests that cannot be done any more and passes flag steps whose flag is
## set. Returns the lines (task failed, next step, task done).
static func update(gs: GameState, db: DataDb) -> Array[String]:
	var lines: Array[String] = []
	if not on(db):
		return lines
	for id: String in gs.quests.entries.keys():
		var e: Dictionary = gs.quests.entries[id]
		if e["status"] != QuestState.ACTIVE or quest(db, id).is_empty():
			continue
		if _failing(gs, db, id):
			e["status"] = QuestState.FAILED
			e["end_day"] = gs.clock.day()
			lines.append(FAILED_LINE % quest(db, id)["title"])
		elif _flag_met(gs, quest(db, id)["steps"][int(e["step"])]):
			lines.append_array(_next(gs, db, id))
	return lines


## The journal's task lines: each open task's current step, then the done and failed ones.
static func journal_lines(gs: GameState, db: DataDb) -> Array[String]:
	var open: Array[String] = []
	var closed: Array[String] = []
	for id: String in gs.quests.entries:
		var q := quest(db, id)
		if q.is_empty():
			continue
		var e: Dictionary = gs.quests.entries[id]
		var st := String(e["status"])
		if st == QuestState.ACTIVE:
			var step: Dictionary = q["steps"][int(e["step"])]
			var need := int(step.get("count", 1))
			open.append("  %s: %s%s" % [q["title"], step["text"],
					" (%d/%d)" % [int(e["count"]), need] if need > 1 else ""])
		elif st == QuestState.DONE:
			closed.append("  Done: %s." % q["title"])
		elif st == QuestState.FAILED:
			closed.append("  Failed: %s." % q["title"])
	open.append_array(closed)
	if open.is_empty():
		open.append(NONE)
	return open


## The next step of quest `id` (met flag steps are passed at once), or the end.
static func _next(gs: GameState, db: DataDb, id: String) -> Array[String]:
	var e: Dictionary = gs.quests.entries[id]
	var steps: Array = quest(db, id)["steps"]
	e["step"] = int(e["step"]) + 1
	e["count"] = 0
	while int(e["step"]) < steps.size() and _flag_met(gs, steps[int(e["step"])]):
		e["step"] = int(e["step"]) + 1
	if int(e["step"]) >= steps.size():
		return _complete(gs, db, id)
	return [NEXT % steps[int(e["step"])]["text"]] as Array[String]


## Quest `id` is done: the rewards, the giver's last words.
static func _complete(gs: GameState, db: DataDb, id: String) -> Array[String]:
	var q := quest(db, id)
	var e: Dictionary = gs.quests.entries[id]
	e["status"] = QuestState.DONE
	e["step"] = (q["steps"] as Array).size() - 1
	e["end_day"] = gs.clock.day()
	var giver := String(q["giver"])
	var lines: Array[String] = [DONE_LINE % q["title"]]
	if String(q.get("done", "")) != "":
		lines.append(_say(db, giver, String(q["done"])))
	var r: Dictionary = q.get("rewards", {})
	var got: Array[String] = []
	var coins := int(r.get("coins", 0))
	if coins > 0:
		gs.economy.coins += coins
		got.append(Economy.format(db, coins))
	var goods: Dictionary = r.get("goods", {})
	for good: String in goods:
		gs.economy.add(good, int(goods[good]))
		got.append("%d %s" % [int(goods[good]), String(db.economy.goods[good].get("name", good)).to_lower()])
	if not got.is_empty():
		lines.append(REWARD % ", ".join(got))
	var rel := int(r.get("relationship", 0))
	if rel != 0:
		gs.world.add_relationship(giver, NpcSim.PLAYER, rel)
	for f: String in r.get("flags", []):
		gs.flags[f] = true
	return lines


static func _flag_met(gs: GameState, step: Dictionary) -> bool:
	return step.has("flag") and bool(gs.flags.get(String(step["flag"]), false))


## True if quest `id` can no longer be done: the giver is dead, a fail flag is set,
## or its last day has passed.
static func _failing(gs: GameState, db: DataDb, id: String) -> bool:
	var q := quest(db, id)
	if not gs.world.is_alive(db.canon, String(q["giver"])):
		return true
	var fail: Dictionary = q.get("fail", {})
	for f: String in fail.get("flags", []):
		if gs.flags.get(f, false):
			return true
	return fail.has("after_day") and gs.clock.day() > int(fail["after_day"])


## Speech of `npc` as a log line (Voice.say, or a plain form with no voice rules).
static func _say(db: DataDb, npc: String, text: String) -> String:
	if Voice.on(db):
		return Voice.say(db, npc, text)
	return "%s: \"%s\"" % [db.canon.npcs[npc]["name"], text]


## Checks data/quests.json. Returns the errors.
static func validate(db: DataDb) -> Array[String]:
	var errs: Array[String] = []
	var id_re := RegEx.create_from_string("^[a-z][a-z0-9_]*$")
	for id: String in db.quests:
		var at := "quests.json %s" % id
		if id_re.search(id) == null:
			errs.append("quests.json: bad quest id '%s' (lower case, digits, _)." % id)
		var q: Variant = db.quests[id]
		if not q is Dictionary:
			errs.append("%s: must be an object." % at)
			continue
		errs.append_array(_validate_quest(db, at, q))
	return errs


static func _validate_quest(db: DataDb, at: String, q: Dictionary) -> Array[String]:
	var errs: Array[String] = []
	for k: String in q:
		if not QUEST_FIELDS.has(k):
			errs.append("%s: unknown field '%s'." % [at, k])
	for f: String in ["title", "offer"]:
		if not (q.get(f) is String and String(q[f]).strip_edges() != ""):
			errs.append("%s: %s must be a non-empty string." % [at, f])
	if q.has("done") and not q["done"] is String:
		errs.append("%s: done must be a string." % at)
	if not db.canon.npcs.has(String(q.get("giver", ""))):
		errs.append("%s: unknown giver '%s'." % [at, q.get("giver", "")])
	if not DataDb.CONFIDENCE.has(String(q.get("confidence", ""))):
		errs.append("%s: confidence must be one of %s." % [at, DataDb.CONFIDENCE])
	if q.has("gate"):
		if q["gate"] is Dictionary:
			errs.append_array(Voice._gate(db, at + " gate", q["gate"], []))
		else:
			errs.append("%s: gate must be an object." % at)
	errs.append_array(_validate_fail(at, q.get("fail", {})))
	var steps: Variant = q.get("steps", [])
	if not steps is Array or (steps as Array).is_empty():
		errs.append("%s: needs at least one step." % at)
	else:
		for i in (steps as Array).size():
			errs.append_array(_validate_step(db, "%s step %d" % [at, i], steps[i]))
	errs.append_array(_validate_rewards(db, at, q.get("rewards", {})))
	return errs


static func _validate_fail(at: String, fail: Variant) -> Array[String]:
	var errs: Array[String] = []
	if not fail is Dictionary:
		return ["%s: fail must be an object." % at]
	for k: String in fail:
		if not FAIL_FIELDS.has(k):
			errs.append("%s fail: unknown field '%s'." % [at, k])
	if fail.has("flags") and not _strings(fail["flags"]):
		errs.append("%s fail: flags must be a list of flag names." % at)
	if fail.has("after_day") and not _whole(fail["after_day"], 1):
		errs.append("%s fail: after_day must be a day >= 1." % at)
	return errs


static func _validate_step(db: DataDb, at: String, s: Variant) -> Array[String]:
	if not s is Dictionary:
		return ["%s: must be an object." % at]
	var errs: Array[String] = []
	for k: String in s:
		if not STEP_FIELDS.has(k):
			errs.append("%s: unknown field '%s'." % [at, k])
	if not (s.get("text") is String and String(s["text"]).strip_edges() != ""):
		errs.append("%s: text must be a non-empty string." % at)
	var has_flag: bool = s.has("flag")
	var has_did: bool = s.has("did")
	if has_flag == has_did:
		errs.append(("%s has both a flag and a did." if has_flag else "%s needs a flag or a did.") % at)
	if has_flag and not (s["flag"] is String and String(s["flag"]) != ""):
		errs.append("%s: flag must be a flag name." % at)
	if has_flag and s.has("count"):
		errs.append("%s: count is only for a did step." % at)
	if s.has("count") and not _whole(s["count"], 1):
		errs.append("%s: count must be a whole number >= 1." % at)
	if has_did:
		errs.append_array(_validate_did(db, at, s["did"]))
	return errs


static func _validate_did(db: DataDb, at: String, d: Variant) -> Array[String]:
	if not d is Dictionary:
		return ["%s: did must be an object." % at]
	var errs: Array[String] = []
	for k: String in d:
		if not DID_FIELDS.has(k):
			errs.append("%s did: unknown field '%s'." % [at, k])
	var acts: Variant = d.get("action", [])
	if not _strings(acts) or (acts as Array).is_empty():
		errs.append("%s did: action must be a non-empty list of action ids." % at)
	else:
		for a: String in acts:
			if not db.actions.has(a):
				errs.append("%s did: unknown action '%s'." % [at, a])
	if d.has("outcome") and not _strings(d["outcome"]):
		errs.append("%s did: outcome must be a list." % at)
	if d.has("context") and not d["context"] is Dictionary:
		errs.append("%s did: context must be an object." % at)
	return errs


static func _validate_rewards(db: DataDb, at: String, r: Variant) -> Array[String]:
	if not r is Dictionary:
		return ["%s: rewards must be an object." % at]
	var errs: Array[String] = []
	for k: String in r:
		if not REWARD_FIELDS.has(k):
			errs.append("%s: unknown reward '%s'." % [at, k])
	if r.has("coins") and not _whole(r["coins"], 0):
		errs.append("%s rewards: coins must be a whole number >= 0." % at)
	if r.has("relationship") and not _whole(r["relationship"], -1000000):
		errs.append("%s rewards: relationship must be a whole number." % at)
	if r.has("flags") and not _strings(r["flags"]):
		errs.append("%s rewards: flags must be a list of flag names." % at)
	var goods: Variant = r.get("goods", {})
	if not goods is Dictionary:
		errs.append("%s rewards: goods must be {good: count}." % at)
	else:
		for g: String in goods:
			if not db.economy.goods.has(g):
				errs.append("%s rewards: unknown good '%s'." % [at, g])
			if not _whole(goods[g], 1):
				errs.append("%s rewards: good '%s' needs a count >= 1." % [at, g])
	return errs


static func _strings(v: Variant) -> bool:
	return v is Array and (v as Array).all(func(x: Variant) -> bool: return x is String and x != "")


## True for a whole number (JSON gives floats) of at least `low`.
static func _whole(v: Variant, low: int) -> bool:
	return (v is int or v is float) and float(v) == floorf(float(v)) and float(v) >= low
