## XP formula (DESIGN §3.2, ADR 0002):
## xp = base × intensity × risk_mult × novelty_mult × conviction_mult × outcome_mult
##      × skill_mult (ADR 0003) × duress × window (M17.8, hidden: the player never sees them)
## All functions take the "xp" section of data/rules.json.
class_name Xp
extends RefCounted


static func clamp_intensity(intensity: float, rules: Dictionary) -> float:
	return clampf(intensity, float(rules["intensity_min"]), float(rules["intensity_max"]))


## 1.0 (safe) to 1 + risk_scale (deadly).
static func risk_mult(risk: float, rules: Dictionary) -> float:
	return 1.0 + float(rules["risk_scale"]) * clampf(risk, 0.0, 1.0)


static func outcome_mult(outcome: String, rules: Dictionary) -> float:
	return float(rules["outcome_mult"][outcome])


## Bonus for actions that match the player's declared focus.
static func conviction_mult(tags: Dictionary, focus: Array, rules: Dictionary) -> float:
	if focus.is_empty():
		return 1.0
	var match_mult := float(rules["conviction"]["match_mult"])
	return 1.0 + (match_mult - 1.0) * Tags.overlap(tags, focus)


## Falls when the same action was done recently; recovers with a half-life in days.
## The first time ever gives a bonus.
static func novelty_mult(log: ActionLog, action_id: String, now: int, rules: Dictionary) -> float:
	var n: Dictionary = rules["novelty"]
	if log.count(action_id) == 0:
		return float(n["first_time_bonus"])
	var window := float(n["window_days"]) * Clock.MINUTES_PER_DAY
	var half_life := float(n["half_life_days"]) * Clock.MINUTES_PER_DAY
	var w := 0.0
	for r: Dictionary in log.records:
		if r["action_id"] != action_id:
			continue
		var age := float(now - int(r["time"]))
		if age < 0.0 or age > window:
			continue
		w += pow(0.5, age / half_life)
	return maxf(float(n["floor"]), 1.0 / (1.0 + float(n["k"]) * w))


## Bonus from held skills' xp_mult effects. Each effect counts by the share
## of the record's tags it matches: 1 + (value − 1) × overlap.
static func skill_mult(tags: Dictionary, effects: Array) -> float:
	var m := 1.0
	for e: Dictionary in effects:
		m *= 1.0 + (float(e["value"]) - 1.0) * Tags.overlap(tags, e["tags"])
	return m


## M17.8: how hard a fight was for the player. `lost` is the share (0-1) of max HP lost at the
## lowest point, to foes only. rules.xp.duress: `floor` at nothing lost, rising in a straight line
## to 1.0 at `even_at` lost, then `per_percent` more for each 1% lost, at most `cap`. No "duress"
## block (toy dbs): 1.0.
static func duress_mult(lost: float, rules: Dictionary) -> float:
	var d: Dictionary = rules.get("duress", {})
	if d.is_empty():
		return 1.0
	var floor_m := float(d["floor"])
	var even := float(d["even_at"])
	var share := clampf(lost, 0.0, 1.0)
	if share < even:
		return lerpf(floor_m, 1.0, share / even) if even > 0.0 else 1.0
	return minf(1.0 + float(d["per_percent"]) * (share - even) * 100.0, float(d["cap"]))


## M17.9: how hard a working action was (hidden, like a fight's duress). The action's optional
## `duress` list holds entries {"key", "from", "to", "max"}: the context value `key` gives x1.0 at
## `from` or less, rising in a straight line to `max` at `to` or more. A missing key counts as 1.0.
## Entries multiply; the result is capped at rules.duress.cap (2.0). No floor below 1.0: an easy
## day pays the plain XP. `context` is the action's context (Actions.perform adds "cold").
static func work_duress(def: Dictionary, context: Dictionary, rules: Dictionary) -> float:
	var m := 1.0
	for e: Dictionary in def.get("duress", []):
		var key: String = e["key"]
		if not context.has(key):
			continue
		var t := clampf(inverse_lerp(float(e["from"]), float(e["to"]), float(context[key])), 0.0, 1.0)
		m *= lerpf(1.0, float(e["max"]), t)
	return minf(m, float((rules.get("duress", {}) as Dictionary).get("cap", 2.0)))


## M17.8: the multiplier of an XP window's boost tier (rules.xp.boosts {"1": 1.5, ...}); 1.0 for
## no window (boost 0) or an unknown tier.
static func boost_mult(boost: int, rules: Dictionary) -> float:
	return float((rules.get("boosts", {}) as Dictionary).get(str(boost), 1.0))


static func compute(base: float, intensity: float, risk_m: float, novelty_m: float,
		conviction_m: float, outcome_m: float, skill_m: float = 1.0, duress_m: float = 1.0,
		window_m: float = 1.0) -> float:
	return base * intensity * risk_m * novelty_m * conviction_m * outcome_m * skill_m * duress_m * window_m
