## Class candidates, offers, accept/decline, loss and consolidation
## (DESIGN §3.3–3.4, ADR 0003).
class_name ClassSystem
extends RefCounted

const KIND_NEW := "new"
const KIND_CONSOLIDATION := "consolidation"


## Feeds one action record into the System:
## - held classes get XP by tag match, split between them (dilution);
## - held classes whose neglect tags match are marked active today;
## - every class the player does not hold and did not decline gets pool XP.
static func feed(gs: GameState, db: DataDb, record: Dictionary) -> void:
	var p := gs.progression
	var xp := float(record["xp"])
	var tags: Dictionary = record["tags"]
	var shares := Levels.class_shares(tags, p.classes.keys(), db)
	for id: String in shares:
		p.classes[id]["xp"] = float(p.classes[id]["xp"]) + xp * float(shares[id])
	for id: String in p.classes:
		var loss: Variant = db.classes[id]["loss"]
		if loss != null and xp > 0.0 and Tags.overlap(tags, loss["neglect_tags"]) > 0.0:
			var c: Dictionary = p.classes[id]
			c["last_active_day"] = maxi(int(c["last_active_day"]), int(record["day"]))
	for id: String in db.classes:
		if p.has_class(id) or p.declined.has(id):
			continue
		var score := Tags.match_score(tags, db.classes[id]["tag_weights"])
		if score > 0.0:
			p.pools[id] = float(p.pools.get(id, 0.0)) + xp * score


## True if nothing but the pool size stops this class from being offered:
## not held, not declined, not already offered, prereqs met, not excluded,
## race allowed.
static func can_offer(gs: GameState, db: DataDb, id: String) -> bool:
	var p := gs.progression
	if p.has_class(id) or p.declined.has(id) or p.has_offer(id) or Levels.at_cap(p, db.rules.get("levels", {})):
		return false
	var c: Dictionary = db.classes[id]
	var prereqs: Dictionary = c["prereqs"]
	for req: String in prereqs.get("classes", []):
		if not p.has_class(req):
			return false
	for flag: String in prereqs.get("flags", []):
		if not gs.flags.get(flag, false):
			return false
	for ex: String in c["excludes"]:
		if p.has_class(ex):
			return false
	for held: String in p.classes:
		if (db.classes[held]["excludes"] as Array).has(id):
			return false
	var races: Variant = c["race_limits"]
	if races != null and not (races["allow"] as Array).has(gs.race):
		return false
	return true


## Pool fill ratio (pool / threshold).
static func readiness(gs: GameState, db: DataDb, id: String) -> float:
	return float(gs.progression.pools.get(id, 0.0)) / float(db.classes[id]["offer_threshold"])


## Makes up to `budget` offers of new classes. Best-filled pools first; ties
## keep data order. Consolidation classes are never offered (see
## `consolidate_ready`). Returns the class ids offered.
static func make_offers(gs: GameState, db: DataDb, budget: int) -> Array[String]:
	var ready: Array[Dictionary] = []
	var index := 0
	for id: String in db.classes:
		index += 1
		if db.classes[id]["consolidation"] != null:
			continue
		var r := readiness(gs, db, id)
		if r >= 1.0 and can_offer(gs, db, id):
			ready.append({"id": id, "ratio": r, "index": index})
	ready.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["ratio"] != b["ratio"]:
			return a["ratio"] > b["ratio"]
		return a["index"] < b["index"])
	var offered: Array[String] = []
	for entry: Dictionary in ready.slice(0, maxi(budget, 0)):
		gs.progression.offers.append({"class": entry["id"], "kind": KIND_NEW, "day": gs.clock.day()})
		offered.append(entry["id"])
	return offered


## Lowest level that at least one `from` class must have before a consolidation
## can happen (rules.offers.consolidation_min_level).
static func consolidation_min_level(db: DataDb) -> int:
	return int(db.rules["offers"].get("consolidation_min_level", 10))


## True if the player holds every `from` class, one of them is at the minimum
## level, the pool is full and nothing else stops the class.
static func can_consolidate(gs: GameState, db: DataDb, id: String) -> bool:
	var cons: Variant = db.classes[id]["consolidation"]
	if cons == null or not (cons["from"] as Array).all(gs.progression.has_class):
		return false
	var best := 0
	for old: String in cons["from"]:
		best = maxi(best, gs.progression.level_of(old))
	if best < consolidation_min_level(db):
		return false
	return readiness(gs, db, id) >= 1.0 and can_offer(gs, db, id)


## Consolidates every class that can (no offer, no choice). Data order.
## Returns System messages.
static func consolidate_ready(gs: GameState, db: DataDb) -> Array[String]:
	var lines: Array[String] = []
	for id: String in db.classes:
		if can_consolidate(gs, db, id):
			lines.append_array(_consolidate(gs, db, id))
	return lines


## Command: accept an open offer. Returns System messages.
static func accept(gs: GameState, db: DataDb, id: String) -> Array[String]:
	var p := gs.progression
	var i := p.offer_index(id)
	if i == -1:
		return _msg("There is no offer for '%s'." % id)
	var offer: Dictionary = p.offers[i]
	p.offers.remove_at(i)
	if offer["kind"] == KIND_CONSOLIDATION:
		return _consolidate(gs, db, id)
	return _gain(gs, db, id, 1, [])


## Replaces the `from` classes with `id` at once.
static func _consolidate(gs: GameState, db: DataDb, id: String) -> Array[String]:
	var p := gs.progression
	var c: Dictionary = db.classes[id]
	var from_best := 0
	var names: Array[String] = []
	var lines: Array[String] = []
	for old: String in c["consolidation"]["from"]:
		from_best = maxi(from_best, p.level_of(old))
		p.classes.erase(old)
		p.breakthroughs.erase(old)
		names.append(db.classes[old]["name"])
		lines.append("%s is gone." % db.classes[old]["name"])
	lines.push_front("Your classes have consolidated: %s became %s." % [" and ".join(names), c["name"]])
	return _gain(gs, db, id, maxi(1, from_best - int(c["consolidation"]["level_cost"])), lines)


static func _gain(gs: GameState, db: DataDb, id: String, level: int, lines: Array[String]) -> Array[String]:
	var p := gs.progression
	var c: Dictionary = db.classes[id]
	p.classes[id] = {"level": level, "xp": 0.0, "last_active_day": gs.clock.day()}
	lines.insert(1 if lines.size() > 0 else 0, "Class gained: %s, level %d." % [c["name"], level])
	# Offers that the new class excludes are withdrawn (not blacklisted).
	for o: Dictionary in p.offers.duplicate():
		if not can_offer_ignoring_offer(gs, db, o["class"]):
			p.offers.erase(o)
			lines.append("The offer of %s is gone." % db.classes[o["class"]]["name"])
	for n in int(db.rules["skills"]["on_accept"]):
		var skill := SkillSystem.grant_random(gs, db, id, level)
		if skill != "":
			lines.append("Skill gained: %s." % db.skills[skill]["name"])
	return lines


## can_offer, but an open offer for `id` does not count against it.
static func can_offer_ignoring_offer(gs: GameState, db: DataDb, id: String) -> bool:
	var p := gs.progression
	var i := p.offer_index(id)
	if i == -1:
		return can_offer(gs, db, id)
	var offer: Dictionary = p.offers[i]
	p.offers.remove_at(i)
	var ok := can_offer(gs, db, id)
	p.offers.insert(i, offer)
	return ok


## Command: decline an open offer. The class id is blacklisted for good.
## Its pool stops growing; the same XP still flows to related classes,
## because every class fills from the same tags.
static func decline(gs: GameState, db: DataDb, id: String) -> Array[String]:
	var p := gs.progression
	var i := p.offer_index(id)
	if i == -1:
		return _msg("There is no offer for '%s'." % id)
	p.offers.remove_at(i)
	p.declined.append(id)
	return _msg("You declined %s. It will not be offered again." % db.classes[id]["name"])


## Night step 4a: a class not used for `neglect_days` loses one level per
## night. At level 0 it is lost and its pool starts again from 0.
static func check_loss(gs: GameState, db: DataDb, today: int) -> Array[String]:
	var p := gs.progression
	var lines: Array[String] = []
	for id: String in p.classes.keys():
		var loss: Variant = db.classes[id]["loss"]
		if loss == null:
			continue
		var c: Dictionary = p.classes[id]
		if today - int(c["last_active_day"]) < int(loss["neglect_days"]):
			continue
		c["level"] = int(c["level"]) - 1
		c["xp"] = 0.0
		var name: String = db.classes[id]["name"]
		if int(c["level"]) > 0:
			lines.append("%s fades from neglect: level %d." % [name, c["level"]])
			continue
		p.classes.erase(id)
		p.breakthroughs.erase(id)
		p.lost.append(id)
		p.pools[id] = 0.0
		lines.append("You lost the class %s." % name)
	return lines


## Lets a class pass its next capstone level. Canon events grant this (M3);
## the debug console can grant it too. Returns false if the class is not held.
static func grant_breakthrough(gs: GameState, id: String) -> bool:
	var p := gs.progression
	if not p.has_class(id):
		return false
	if not p.breakthroughs.has(id):
		p.breakthroughs.append(id)
	return true


static func _msg(text: String) -> Array[String]:
	var lines: Array[String] = [text]
	return lines
