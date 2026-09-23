## Skills from weighted pools (DESIGN §3.5, ADR 0003).
## Pick weight = pool weight × (base_weight + affinity). Affinity is how much of
## the player's lifetime tag XP fits the skill's tag_affinity ("needs and desires").
class_name SkillSystem
extends RefCounted


## 0–1 (for affinity weights ≤ 1): share of lifetime tag XP that fits `tag_affinity`.
static func affinity(tag_affinity: Dictionary, tag_totals: Dictionary) -> float:
	var total := 0.0
	for tag: String in tag_totals:
		total += float(tag_totals[tag])
	if total <= 0.0:
		return 0.0
	var sum := 0.0
	for tag: String in tag_totals:
		sum += float(tag_totals[tag]) / total * Tags.match_weight(tag_affinity, tag)
	return sum


## Skills `class_id` can give at `level` that the player does not hold, in data
## order: [{"id", "weight"}]. `rare_only` keeps only rare skills.
static func candidates(gs: GameState, db: DataDb, class_id: String, level: int,
		rare_only: bool = false) -> Array[Dictionary]:
	var base := float(db.rules["skills"]["base_weight"])
	var out: Array[Dictionary] = []
	for id: String in db.skills:
		var s: Dictionary = db.skills[id]
		if gs.progression.has_skill(id) or (rare_only and s["rarity"] != "rare"):
			continue
		var pool_weight := 0.0
		for pool: Dictionary in s["pools"]:
			if pool["class"] == class_id and level >= int(pool["min_level"]) \
					and level <= int(pool["max_level"]):
				pool_weight = maxf(pool_weight, float(pool["weight"]))
		if pool_weight > 0.0:
			var aff := affinity(s["tag_affinity"], gs.action_log.tag_totals)
			out.append({"id": id, "weight": pool_weight * (base + aff)})
	return out


## Picks one skill with gs.rng and gives it. Capstones prefer rare skills.
## Returns the skill id, or "" if the pool is empty.
static func grant_random(gs: GameState, db: DataDb, class_id: String, level: int,
		prefer_rare: bool = false) -> String:
	var list := candidates(gs, db, class_id, level, prefer_rare)
	if list.is_empty() and prefer_rare:
		list = candidates(gs, db, class_id, level)
	var weights: Array = list.map(func(c: Dictionary) -> float: return c["weight"])
	var i := gs.rng.weighted_index(weights)
	if i < 0:
		return ""
	var id: String = list[i]["id"]
	gs.progression.skills.append({"id": id, "class": class_id, "level": level, "day": gs.clock.day()})
	return id


## Called once per level gained. Normal levels give a skill with
## chance_per_level; capstones always give one. Returns the skill id or "".
static func on_level(gs: GameState, db: DataDb, class_id: String, level: int) -> String:
	var capstone := Levels.is_capstone(level, db.rules["levels"])
	if not capstone and gs.rng.randf() >= float(db.rules["skills"]["chance_per_level"]):
		return ""
	return grant_random(gs, db, class_id, level, capstone)


## All xp_mult effects of the skills the player holds.
static func xp_effects(p: Progression, db: DataDb) -> Array:
	var out := []
	for held: Dictionary in p.skills:
		for e: Dictionary in db.skills[held["id"]]["effects"]:
			if e["type"] == "xp_mult":
				out.append(e)
	return out


## All stat_mod effects of the skills the player holds (Stats reads them).
static func stat_effects(p: Progression, db: DataDb) -> Array:
	var out := []
	for held: Dictionary in p.skills:
		for e: Dictionary in db.skills[held["id"]]["effects"]:
			if e["type"] == "stat_mod":
				out.append(e)
	return out
