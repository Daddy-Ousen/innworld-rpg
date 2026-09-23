## Small hand-made canon for world director tests (ADR 0005). Three chains,
## one per ROADMAP M3 scenario, plus a T1 rumor:
##   save a doomed NPC:  mentor_dies (day 4, kills mentor) → funeral (day 5);
##                       blocked by mentor.warned → mutates to mentor_survives.
##   kill a future NPC:  patrol (day 5, prefers guard_a) → promotion (day 6,
##                       needs guard_a alive) → parade (day 7).
##   prevent an event:   raid (day 3, goblins; blocked by village.walls_built,
##                       delay limit 2) → rebuild (days 5–6).
##   T1:                 king_crowned (day 2) with a rumor.
class_name ToyCanon
extends RefCounted


## ToyData rules + this canon.
static func db() -> DataDb:
	var d := ToyData.db()
	d.canon = canon()
	return d


static func canon() -> CanonDb:
	return CanonDb.from_dicts(npcs(), {}, events())


static func npcs() -> Dictionary:
	return {
		"hero": npc(["human", "hero"]),
		"mentor": npc(["human", "mage", "mentor"]),
		"guard_a": npc(["drake", "guard", "senior"]),
		"guard_b": npc(["gnoll", "guard"]),
		"guard_c": npc(["human", "guard"]),
		"villain": npc(["undead", "mage"]),
		"far_king": npc(["royal"]),
	}


static func events() -> Dictionary:
	return {
		"e.king_crowned": event(2, 2, {"tier": 1,
			"roles": {"king": role(["far_king"], ["royal"])},
			"on_fail": ["substitute", "cancel"],
			"effects": {"set_flags": ["far.new_king"]},
			"rumor": "A new king was crowned far away."}),
		"e.mentor_dies": event(4, 4, {
			"roles": {"victim": role(["mentor"], [])},
			"requires": req(["mentor"], [], ["mentor.warned"]),
			"on_fail": ["mutate:e.mentor_survives", "cancel"],
			"effects": {"kill": ["mentor"], "set_flags": ["mentor.dead"]}}),
		"e.mentor_survives": event(4, 4, {
			"roles": {"victim": role(["mentor"], [])},
			"requires": req(["mentor"]),
			"effects": {"set_flags": ["mentor.wounded"]}}),
		"e.funeral": event(5, 5, {
			"roles": {"mourner": role(["hero"], ["human"])},
			"requires": req([], ["mentor.dead"]),
			"depends_on": ["e.mentor_dies"],
			"effects": {"relationship": [{"from": "hero", "to": "villain", "delta": -3}]}}),
		"e.patrol": event(5, 5, {
			"roles": {"leader": role(["guard_a"], ["drake", "guard", "senior"])},
			"on_fail": ["substitute", "cancel"],
			"effects": {"set_flags": ["patrol.done"],
				"relationship": [{"from": "guard_a", "to": "hero", "delta": 1}]}}),
		"e.promotion": event(6, 6, {
			"roles": {"officer": role(["guard_a"], ["guard"])},
			"requires": req(["guard_a"]),
			"depends_on": ["e.patrol"],
			"on_fail": ["substitute", "cancel"],
			"effects": {"set_flags": ["guard_a.promoted"]}}),
		"e.parade": event(7, 7, {
			"depends_on": ["e.promotion"],
			"on_fail": ["delay", "cancel"],
			"effects": {"set_flags": ["parade.held"]}}),
		"e.raid": event(3, 3, {
			"roles": {"raiders": role([], ["goblin"])},
			"requires": req([], [], ["village.walls_built"]),
			"on_fail": ["delay", "cancel"],
			"delay_limit": 2,
			"effects": {"set_flags": ["village.burned"]}}),
		"e.rebuild": event(5, 6, {
			"depends_on": ["e.raid"],
			"effects": {"set_flags": ["village.rebuilt"]}}),
	}


static func npc(tags: Array, alive: bool = true) -> Dictionary:
	return {"name": "NPC", "tags": tags, "alive_at_start": alive}


static func role(prefer: Array, fallback: Array, optional: bool = false) -> Dictionary:
	return {"prefer": prefer, "fallback_tags": fallback, "optional": optional}


static func req(alive: Array = [], flags: Array = [], not_flags: Array = []) -> Dictionary:
	return {"alive": alive, "flags": flags, "not_flags": not_flags}


## A tier 2 event in window [earliest, latest] with no roles, no requirements,
## on_fail ["cancel"] and no effects; `extra` overrides fields.
static func event(earliest: int, latest: int, extra: Dictionary = {}) -> Dictionary:
	var e := {
		"tier": 2,
		"window": {"earliest": earliest, "latest": latest, "confidence": "guess"},
		"location": "toy",
		"roles": {},
		"requires": req(),
		"depends_on": [],
		"on_fail": ["cancel"],
		"effects": {},
	}
	e.merge(extra, true)
	return e


## Sleeps until the director has run through `day`.
static func sleep_through(gs: GameState, db: DataDb, day: int) -> void:
	while gs.world.last_day < day:
		Commands.sleep(gs, db)


## Compact history: ["D4 mutated e.mentor_dies", ...].
static func timeline(gs: GameState) -> Array[String]:
	var out: Array[String] = []
	for h: Dictionary in gs.world.history:
		out.append("D%d %s %s" % [int(h["day"]), h["outcome"], h["event"]])
	return out
