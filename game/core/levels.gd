## Level curve and multi-class dilution (DESIGN §3.4, ADR 0003).
## Functions take the "levels" section of data/rules.json.
class_name Levels
extends RefCounted


## XP needed to go from `level` to level + 1. Level 1 → 2 costs base_xp.
static func xp_to_next(level: int, rules: Dictionary) -> float:
	return float(rules["base_xp"]) * pow(float(rules["growth"]), maxi(level, 1) - 1)


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
	return is_capstone(level + 1, rules) and not p.breakthroughs.has(class_id) \
			and float(p.classes[class_id]["xp"]) >= xp_to_next(level, rules)


## Spends the class's XP on levels. Returns the levels reached, in order.
## XP keeps building while a capstone blocks it.
static func level_up(p: Progression, class_id: String, rules: Dictionary) -> Array[int]:
	var c: Dictionary = p.classes[class_id]
	var gained: Array[int] = []
	while true:
		var level := int(c["level"])
		var next := level + 1
		var capstone := is_capstone(next, rules)
		if capstone and not p.breakthroughs.has(class_id):
			break
		var need := xp_to_next(level, rules)
		if float(c["xp"]) < need:
			break
		c["xp"] = float(c["xp"]) - need
		c["level"] = next
		if capstone:
			p.breakthroughs.erase(class_id)
		gained.append(next)
	return gained
