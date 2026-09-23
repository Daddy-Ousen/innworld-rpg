## The "do an action" command. Builds the action record, computes XP,
## logs it and spends the time.
class_name Actions
extends RefCounted


## Applies the action's context rules. Returns {"tags": normalised, "risk_add": float}.
static func resolve(def: Dictionary, context: Dictionary) -> Dictionary:
	var tags: Dictionary = (def["tags"] as Dictionary).duplicate()
	var risk_add := 0.0
	for rule: Dictionary in def.get("context", []):
		if not _rule_applies(rule, context):
			continue
		var add: Dictionary = rule.get("add_tags", {})
		for tag: String in add:
			tags[tag] = float(tags.get(tag, 0.0)) + float(add[tag])
		risk_add += float(rule.get("add_risk", 0.0))
	return {"tags": Tags.normalize(tags), "risk_add": risk_add}


static func _rule_applies(rule: Dictionary, context: Dictionary) -> bool:
	var key: String = rule["key"]
	if not context.has(key):
		return false
	var v: Variant = context[key]
	if rule.has("equals"):
		var want: Variant = rule["equals"]
		if (typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT) and typeof(want) == TYPE_FLOAT:
			return is_equal_approx(float(v), float(want))
		return v == want
	if rule.has("min"):
		return float(v) >= float(rule["min"])
	return float(v) <= float(rule["max"])


## Does `action_id` now. Options (all optional):
##   intensity: float, risk: float (overrides the action's base risk),
##   outcome: "success" | "partial" | "fail", context: Dictionary, witnesses: Array,
##   minutes: int (overrides the action's minutes, e.g. travel between maps),
##   allow_collapsed: bool (log it even when a collapse is due: the records
##   of a fight that ends the day, Combat.end_fight).
## Returns the record, or {} if the action is refused (unknown, or collapse due).
static func perform(gs: GameState, db: DataDb, action_id: String, opts: Dictionary = {}) -> Dictionary:
	if not db.actions.has(action_id):
		push_error("Unknown action '%s'." % action_id)
		return {}
	if gs.clock.is_collapse_due(db.rules["clock"]) and not opts.get("allow_collapsed", false):
		return {}
	var xp_rules: Dictionary = db.rules["xp"]
	var outcome: String = opts.get("outcome", "success")
	if not (xp_rules["outcome_mult"] as Dictionary).has(outcome):
		push_error("Unknown outcome '%s'." % outcome)
		return {}

	var def: Dictionary = db.actions[action_id]
	var resolved := resolve(def, opts.get("context", {}))
	var tags: Dictionary = resolved["tags"]
	var risk := clampf(float(opts.get("risk", def["risk"])) + float(resolved["risk_add"]), 0.0, 1.0)
	var intensity := Xp.clamp_intensity(float(opts.get("intensity", 1.0)), xp_rules)
	var now := gs.clock.total_minutes
	var novelty := Xp.novelty_mult(gs.action_log, action_id, now, xp_rules)
	var conviction := Xp.conviction_mult(tags, gs.focus_tags, xp_rules)
	var skill_m := Xp.skill_mult(tags, SkillSystem.xp_effects(gs.progression, db))
	var xp := Xp.compute(float(def["base_xp"]), intensity, Xp.risk_mult(risk, xp_rules),
			novelty, conviction, Xp.outcome_mult(outcome, xp_rules), skill_m)

	var record := {
		"time": now,
		"day": gs.clock.day(),
		"minute": gs.clock.minute(),
		"action_id": action_id,
		"tags": tags,
		"intensity": intensity,
		"risk": risk,
		"novelty": novelty,
		"conviction": conviction,
		"skill_mult": skill_m,
		"outcome": outcome,
		"witnesses": (opts.get("witnesses", []) as Array).duplicate(),
		"xp": xp,
	}
	gs.action_log.add(record)
	gs.clock.advance(maxi(int(opts.get("minutes", def["minutes"])), 0))
	gs.action_log.prune(gs.clock.total_minutes, int(xp_rules["novelty"]["window_days"]))
	return record
