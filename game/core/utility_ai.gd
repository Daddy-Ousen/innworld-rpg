## NPC goal choice (DESIGN §4.5, ADR 0008): score each goal, the best wins.
## score = base × hour mult, or 0 if the day, when_flags or unless_flags
## rule it out. Ties go to the goal listed first. No randomness.
class_name UtilityAi
extends RefCounted

const SECONDS_PER_DAY := Clock.MINUTES_PER_DAY * 60
## Returned when no goal scores above 0: the NPC stays where it is.
const IDLE := {"goal": "idle", "base": 0.0, "target": {"stay": true}}


## The goal `npc` follows at world second `sec` (a goal dictionary from
## BehaviourDb; IDLE if nothing scores).
static func pick(gs: GameState, db: DataDb, npc: String, sec: int) -> Dictionary:
	var best := IDLE
	var best_score := 0.0
	for g: Dictionary in db.behaviour.goals_of(npc):
		var s := score(gs, g, sec)
		if s > best_score:
			best = g
			best_score = s
	return best


static func score(gs: GameState, g: Dictionary, sec: int) -> float:
	@warning_ignore("integer_division")
	var day := sec / SECONDS_PER_DAY + 1
	if g.has("days") and (day < int(g["days"][0]) or day > int(g["days"][1])):
		return 0.0
	for f: String in g.get("when_flags", []):
		if not gs.flags.get(f, false):
			return 0.0
	for f: String in g.get("unless_flags", []):
		if gs.flags.get(f, false):
			return 0.0
	return float(g["base"]) * hour_mult(g, sec)


## The mult of the first "hours" range that holds the hour of `sec`; 1 if
## the goal has no hours, 0 if no range holds it.
static func hour_mult(g: Dictionary, sec: int) -> float:
	if not g.has("hours"):
		return 1.0
	@warning_ignore("integer_division")
	var hour := posmod(sec, SECONDS_PER_DAY) / 3600
	for h: Array in g["hours"]:
		var from := int(h[0])
		var to := int(h[1])
		var inside := (hour >= from and hour < to) if from < to else (hour >= from or hour < to)
		if inside:
			return float(h[2])
	return 0.0
