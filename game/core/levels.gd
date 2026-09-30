## Level curve and multi-class dilution (DESIGN §3.4, ADR 0003).
## Functions take the "levels" section of data/rules.json.
class_name Levels
extends RefCounted


## XP needed to go from `level` to level + 1 on the curve. Level 1 → 2 costs base_xp.
## M17.7: with "late_from" (a level) the curve turns gentler above it: growth
## "late_growth" per level instead of "growth". No "late_from" = one growth.
static func xp_to_next(level: int, rules: Dictionary) -> float:
	var lv := maxi(level, 1)
	var base := float(rules["base_xp"])
	var growth := float(rules["growth"])
	var late := int(rules.get("late_from", 0))
	if late > 0 and lv > late:
		return base * pow(growth, late - 1) * pow(float(rules.get("late_growth", growth)), lv - late)
	return base * pow(growth, lv - 1)


## M17.7 (ADR 0022, Ryoka's theory, 2.41): what the next level of ANY class costs
## follows the TOTAL level of all classes, not that class's own level. With one
## class this is the same number as xp_to_next(level).
static func cost(p: Progression, rules: Dictionary) -> float:
	return xp_to_next(maxi(p.total_level(), 1), rules)


## True at the hidden cap of total levels (rules.levels.total_cap; none = no cap).
## At the cap no class levels up and none is offered. Never shown to the player.
static func at_cap(p: Progression, rules: Dictionary) -> bool:
	var cap := int(rules.get("total_cap", 0))
	return cap > 0 and p.total_level() >= cap


static func is_capstone(level: int, rules: Dictionary) -> bool:
	for c: Variant in rules["capstones"]:
		if int(c) == level:
			return true
	return false


## Share of one record's XP that each held class gets. Returns {class_id: share}.
## The best-matching class decides how much XP counts at all (min(1, best));
## that amount is split between matching classes by their match score.
## So more classes that fit the same work → less XP for each.
static func class_shares(tags: Dictionary, held: Array, db: DataDb) -> Dictionary:
	var scores := {}
	var total := 0.0
	var best := 0.0
	for id: String in held:
		var s := Tags.match_score(tags, db.classes[id]["tag_weights"])
		if s > 0.0:
			scores[id] = s
			total += s
			best = maxf(best, s)
	var out := {}
	for id: String in scores:
		out[id] = minf(best, 1.0) * float(scores[id]) / total
	return out


## True if the class has enough XP for its next level, but that level is a
## capstone and no breakthrough was granted.
static func is_blocked(p: Progression, class_id: String, rules: Dictionary) -> bool:
	var level := p.level_of(class_id)
	return not at_cap(p, rules) and is_capstone(level + 1, rules) and not p.breakthroughs.has(class_id) \
			and float(p.classes[class_id]["xp"]) >= cost(p, rules)


## Spends the class's XP on levels. Returns the levels reached, in order.
## XP keeps building while a capstone blocks it.
static func level_up(p: Progression, class_id: String, rules: Dictionary) -> Array[int]:
	var c: Dictionary = p.classes[class_id]
	var gained: Array[int] = []
	while not at_cap(p, rules):
		var level := int(c["level"])
		var next := level + 1
		var capstone := is_capstone(next, rules)
		if capstone and not p.breakthroughs.has(class_id):
			break
		var need := cost(p, rules)
		if float(c["xp"]) < need:
			break
		c["xp"] = float(c["xp"]) - need
		c["level"] = next
		if capstone:
			p.breakthroughs.erase(class_id)
		gained.append(next)
	return gained
