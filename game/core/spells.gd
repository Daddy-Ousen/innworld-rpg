## Spells (M17.5, ADR 0027): data/spells.json (SpellDb). The player learns a spell
## from a teacher next to them (Commands.learn_spell) or by reading a spellbook
## good once (Economy.use_good); a spell never comes from nothing. Learning takes
## the spell's "learn.minutes" as the action [Study a spell], so it feeds the
## hidden [Mage] pool, and sets the flag `player.knows_spell` (the [Mage]
## prerequisite). Casting is in the second half of this file.
class_name Spells
extends RefCounted

const KNOWS_FLAG := "player.knows_spell"
const STUDY_ACTION := "study_spell"
const DONE := "done"
const UNKNOWN := "There is no such spell."
const KNOWN := "You already know %s."
const CANNOT_TEACH := "%s cannot teach you that."
const NOT_YET := "%s will not teach you that yet."
const NOT_HERE := "%s is not next to you."


static func spell(db: DataDb, id: String) -> Dictionary:
	return db.spells.spells.get(id, {})


static func name_of(db: DataDb, id: String) -> String:
	return String(spell(db, id).get("name", id))


## The spells the player knows, in the order learned (ids the data still has).
static func known(gs: GameState, db: DataDb) -> Array[String]:
	var out: Array[String] = []
	for id in gs.progression.spells:
		if db.spells.has(id):
			out.append(id)
	return out


static func knows(gs: GameState, id: String) -> bool:
	return gs.progression.has_spell(id)


## Spells teacher `npc` will teach the player now (its canon event is done), that
## the player does not know yet, in id order.
static func teachable(gs: GameState, db: DataDb, npc: String) -> Array[String]:
	var out: Array[String] = []
	for id in db.spells.ids():
		if teach_error(gs, db, npc, id) == "":
			out.append(id)
	return out


## Why `npc` cannot teach spell `id` now ("" = they can). Not about the distance.
static func teach_error(gs: GameState, db: DataDb, npc: String, id: String) -> String:
	if not db.spells.has(id):
		return UNKNOWN
	var who := String(db.canon.npcs.get(npc, {}).get("name", npc))
	var learn: Dictionary = spell(db, id).get("learn", {})
	if String(learn.get("teacher", "")) != npc:
		return CANNOT_TEACH % who
	var after := String(learn.get("after_event", ""))
	if after != "" and gs.world.status(after) != DONE:
		return NOT_YET % who
	if knows(gs, id):
		return KNOWN % name_of(db, id)
	return ""


## The player learns spell `id` from teacher `npc` (next to them). Takes the
## spell's study time. Returns "" or why not.
static func learn_from_teacher(gs: GameState, db: DataDb, npc: String, id: String) -> String:
	var why := teach_error(gs, db, npc, id)
	if why != "":
		return why
	if not NpcSim.near_player(gs).has(npc):
		return NOT_HERE % String(db.canon.npcs.get(npc, {}).get("name", npc))
	return _study(gs, db, id, [npc])


## The player reads spellbook good `good` (Economy.use_good): learns its spell,
## the book is used up by the caller. Returns "" or why not.
static func read_book(gs: GameState, db: DataDb, good: String) -> String:
	var id := String(db.economy.goods.get(good, {}).get("teaches", ""))
	if not db.spells.has(id):
		return UNKNOWN
	if knows(gs, id):
		return KNOWN % name_of(db, id)
	return _study(gs, db, id, [])


static func _study(gs: GameState, db: DataDb, id: String, witnesses: Array) -> String:
	var minutes := int(spell(db, id).get("learn", {}).get("minutes", 60))
	var rec := Actions.perform(gs, db, STUDY_ACTION, {"minutes": minutes, "witnesses": witnesses})
	if rec.is_empty():
		return Combat.REFUSED_TIRED
	learn(gs, db, id)
	return ""


## Adds spell `id` to the player's spells and sets the [Mage] prerequisite flag.
## No time, no check (debug and tests); Commands.grant_spell checks the id.
static func learn(gs: GameState, db: DataDb, id: String) -> void:
	if not knows(gs, id):
		gs.progression.spells.append(id)
	gs.flags[KNOWS_FLAG] = true
	gs.combat.lines.append("You learn %s." % name_of(db, id))
