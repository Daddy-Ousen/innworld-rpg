## XP formula (DESIGN §3.2, ADR 0002):
## xp = base × intensity × risk_mult × novelty_mult × conviction_mult × outcome_mult
##      × skill_mult (ADR 0003)
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


static func compute(base: float, intensity: float, risk_m: float, novelty_m: float,
		conviction_m: float, outcome_m: float, skill_m: float = 1.0) -> float:
	return base * intensity * risk_m * novelty_m * conviction_m * outcome_m * skill_m
