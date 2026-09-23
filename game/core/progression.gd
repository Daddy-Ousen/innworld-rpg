## The player's System state: hidden class pools, held classes, skills,
## open offers and the decline blacklist. Logic lives in ClassSystem,
## Levels and SkillSystem; this object only holds data.
class_name Progression
extends RefCounted

## Hidden candidate pools: class id → XP. Only classes the player does not
## hold (and did not decline) receive XP.
var pools: Dictionary = {}
## Held classes, in the order gained:
## id → {"level": int, "xp": float, "last_active_day": int}.
var classes: Dictionary = {}
## Held skills, in the order gained: {"id", "class", "level", "day"}.
var skills: Array[Dictionary] = []
## Declined class ids. Never offered again.
var declined: Array[String] = []
## Class ids the player lost (history only; a lost class can come back).
var lost: Array[String] = []
## Open offers, waiting for accept/decline: {"class", "kind", "day"}.
## kind is "new" or "consolidation".
var offers: Array[Dictionary] = []
## Classes allowed to pass their next capstone level (10, 20, 30).
var breakthroughs: Array[String] = []
## Clock time when the last night closed the action log.
## Records at or after this time belong to the current day.
var day_start: int = 0


func has_class(id: String) -> bool:
	return classes.has(id)


func level_of(id: String) -> int:
	return int(classes[id]["level"]) if classes.has(id) else 0


## Sum of all class levels (0 for an Earther with no class).
func total_level() -> int:
	var sum := 0
	for id: String in classes:
		sum += level_of(id)
	return sum


func has_skill(id: String) -> bool:
	return skills.any(func(s: Dictionary) -> bool: return s["id"] == id)


func has_offer(class_id: String) -> bool:
	return offer_index(class_id) != -1


func offer_index(class_id: String) -> int:
	for i in offers.size():
		if offers[i]["class"] == class_id:
			return i
	return -1


func to_dict() -> Dictionary:
	return {
		"pools": pools.duplicate(),
		"classes": classes.duplicate(true),
		"skills": skills.duplicate(true),
		"declined": declined.duplicate(),
		"lost": lost.duplicate(),
		"offers": offers.duplicate(true),
		"breakthroughs": breakthroughs.duplicate(),
		"day_start": day_start,
	}


## JSON turns ints into floats; cast the int fields back.
static func from_dict(d: Dictionary) -> Progression:
	var p := Progression.new()
	p.pools = (d.get("pools", {}) as Dictionary).duplicate()
	var cls: Dictionary = d.get("classes", {})
	for id: String in cls:
		var c: Dictionary = cls[id]
		p.classes[id] = {
			"level": int(c["level"]),
			"xp": float(c["xp"]),
			"last_active_day": int(c["last_active_day"]),
		}
	for s: Dictionary in d.get("skills", []):
		p.skills.append({"id": s["id"], "class": s["class"], "level": int(s["level"]), "day": int(s["day"])})
	p.declined.assign(d.get("declined", []))
	p.lost.assign(d.get("lost", []))
	for o: Dictionary in d.get("offers", []):
		p.offers.append({"class": o["class"], "kind": o["kind"], "day": int(o["day"])})
	p.breakthroughs.assign(d.get("breakthroughs", []))
	p.day_start = int(d.get("day_start", 0))
	return p
