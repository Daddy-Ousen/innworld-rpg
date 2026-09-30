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


# --- Casting (M17.5) --------------------------------------------------------
# A spell costs AP (ap_q) and MP (mp) and may cool down for `cooldown` rounds
# (the cooldown table key is "spell:<id>", so it never meets a Skill id). Only
# monsters that are foes are hit (never allies, helpers or NPCs); walls stop a
# line; there is no line of sight for `one` and `blast` yet. Damage:
# roll(damage) + Intellect / intellect_div - armor (at least min_damage). The
# player's "roll" spells hit like a blow with Intellect as accuracy.

const KEY := "spell:"
const NOT_IN_FIGHT := "Only in a fight."
const NOT_KNOWN := "You do not know that spell."
const NO_MP := "Not enough mana."
const NO_FOE := "There is no foe there."
const NO_FOE_NEAR := "There is no foe next to you."
const NO_FOE_LINE := "There is no foe in that line."
const TOO_FAR := "Too far."
const NO_DIR := "Pick a direction."
const INTELLECT := "intellect"


## The tiles spell `id` reaches when the caster stands at `origin` and aims at
## `aim`: one = the aim tile; blast = the square of `radius` round the aim tile;
## around = the 8 tiles round the caster; line = up to `length` tiles from the
## caster toward the aim (the way with the larger gap), stopping at a wall.
static func cells(gs: GameState, db: DataDb, id: String, aim: Vector2i, origin: Vector2i) -> Array[Vector2i]:
	var s := spell(db, id)
	var out: Array[Vector2i] = []
	match String(s.get("shape", "")):
		"one":
			out.append(aim)
		"blast":
			var r := int(s["radius"])
			for dx in range(-r, r + 1):
				for dy in range(-r, r + 1):
					out.append(aim + Vector2i(dx, dy))
		"around":
			for dx in range(-1, 2):
				for dy in range(-1, 2):
					if dx != 0 or dy != 0:
						out.append(origin + Vector2i(dx, dy))
		"line":
			var dir := direction(origin, aim)
			var at := origin
			if dir != Vector2i.ZERO:
				for _i in int(s["length"]):
					at += dir
					if not db.maps.is_walkable(gs.player.area, at):
						break
					out.append(at)
	return out


## The side (n, s, e or w) from `from` toward `to`: the axis with the larger gap
## (x on a tie); (0, 0) when they are the same tile.
static func direction(from: Vector2i, to: Vector2i) -> Vector2i:
	var d := to - from
	if d == Vector2i.ZERO:
		return Vector2i.ZERO
	if absi(d.x) >= absi(d.y):
		return Vector2i(signi(d.x), 0)
	return Vector2i(0, signi(d.y))


## The foes standing on `tiles`, in id order.
static func foes_in(gs: GameState, tiles: Array[Vector2i]) -> Array[String]:
	var out: Array[String] = []
	for id in gs.combat.ids():
		if CombatSkills._is_foe(gs, id) and tiles.has(CombatState.pos_of(gs.combat.monsters[id])):
			out.append(id)
	return out


## The foes spell `id` would hit if the player cast it at `aim` now (for the screen).
static func foes_hit(gs: GameState, db: DataDb, id: String, aim: Vector2i) -> Array[String]:
	return foes_in(gs, cells(gs, db, id, aim, gs.player.pos()))


static func ready(gs: GameState, fighter: String, id: String) -> bool:
	return CombatSkills.rounds_left(gs, fighter, KEY + id) == 0


## Why the player cannot cast spell `id` at all now, whatever the aim (fight, known,
## their turn, cooldown, AP, MP, up and awake); "" = they may pick a target.
static func resource_error(gs: GameState, db: DataDb, id: String) -> String:
	if not Encounter.active(gs):
		return NOT_IN_FIGHT
	if not db.spells.has(id) or not knows(gs, id):
		return NOT_KNOWN
	if not Encounter.is_player_turn(gs):
		return Encounter.NOT_YOUR_TURN
	var s := spell(db, id)
	var left := CombatSkills.rounds_left(gs, Encounter.PLAYER, KEY + id)
	if left > 0:
		return CombatSkills.COOLING % [name_of(db, id), left, "" if left == 1 else "s"]
	if int(gs.combat.encounter["ap_q"]) < int(s["ap_q"]):
		return Encounter.NO_AP
	if Mana.current(gs, db) < int(s["mp"]):
		return NO_MP
	return Combat.cannot_act(gs, db)


## Why the player cannot cast spell `id` at `aim` (a tile) now; "" = they can.
static func why_not(gs: GameState, db: DataDb, id: String, aim: Vector2i) -> String:
	var why := resource_error(gs, db, id)
	if why != "":
		return why
	var s := spell(db, id)
	var here := gs.player.pos()
	var none := foes_in(gs, cells(gs, db, id, aim, here)).is_empty()
	match String(s["shape"]):
		"one", "blast":
			if Combat._dist(here, aim) > int(s["range"]):
				return TOO_FAR
			if not Cover.sight(db, gs.player.area, here, aim):
				return Combat.NO_SIGHT
			if none:
				return NO_FOE
		"line":
			if aim == here:
				return NO_DIR
			if none:
				return NO_FOE_LINE
		"around":
			if none:
				return NO_FOE_NEAR
	return ""


## The foes a "one" spell could hit now: in range, seen, not helpers (for the screen).
static func one_targets(gs: GameState, db: DataDb, id: String) -> Array[String]:
	var out: Array[String] = []
	var range_ := int(spell(db, id).get("range", 0))
	for foe in gs.combat.ids():
		var at := CombatState.pos_of(gs.combat.monsters[foe])
		if CombatSkills._is_foe(gs, foe) and Combat._dist(gs.player.pos(), at) <= range_ \
				and Cover.sight(db, gs.player.area, gs.player.pos(), at):
			out.append(foe)
	return out


## The tile to aim at for a key press toward `dir` (a unit step): the first foe along
## that side within range for a "one" or "blast" spell, else the neighbour tile
## (a "line" spell shoots that way; "around" ignores the aim).
static func aim_for_dir(gs: GameState, db: DataDb, id: String, dir: Vector2i) -> Vector2i:
	var here := gs.player.pos()
	var s := spell(db, id)
	if ["one", "blast"].has(String(s["shape"])):
		for k in range(1, int(s["range"]) + 1):
			var at := here + dir * k
			if not foes_in(gs, [at] as Array[Vector2i]).is_empty():
				return at
	return here + dir


## The player's chance to hit foe `unit` with spell `id`: 1.0 for an "auto" spell,
## else Intellect against the foe's evasion.
static func hit_chance(gs: GameState, db: DataDb, id: String, unit: String) -> float:
	if String(spell(db, id)["hit"]) == "auto":
		return 1.0
	return _chance(gs, db, Stats.get_stat(gs, db, INTELLECT), unit, gs.player.pos())


## The chance of a rolled spell hit from `from` (M17.6: cover and the pincer count).
static func _chance(gs: GameState, db: DataDb, accuracy: int, unit: String, from: Vector2i) -> float:
	var m: Dictionary = gs.combat.monsters[unit]
	var evasion := int(db.combat.enemies[m["type"]]["evasion"])
	return Combat.hit_chance(db, accuracy, evasion,
			Combat.position_bonus(gs, db, from, CombatState.pos_of(m), true, Cover.FRIEND))


## The player casts spell `id` at `aim` (why_not must be ""): MP is paid here, the
## cooldown starts, every foe on the spell's tiles is hit (each logged in the turn
## log as a ranged blow; the tiles go in the entry's "cells"). The caller pays the AP.
## Returns {"error", "spell", "strikes": [monster ids], "cells": [tiles]}.
static func use(gs: GameState, db: DataDb, id: String, aim: Vector2i) -> Dictionary:
	var s := spell(db, id)
	var out := {"error": "", "spell": id, "strikes": [], "cells": []}
	Mana.spend(gs, db, int(s["mp"]))
	gs.combat.lines.append("You cast %s." % name_of(db, id))
	CombatSkills.start_cooldown(gs, Encounter.PLAYER, KEY + id, s)
	var tiles := cells(gs, db, id, aim, gs.player.pos())
	out["cells"] = tiles
	if not gs.combat.turns.is_empty():
		gs.combat.turns[-1]["cells"] = tiles
	for foe in foes_in(gs, tiles):
		(out["strikes"] as Array).append(foe)
		Encounter._logged_hit(gs, db, foe, func() -> void: _hit_monster(gs, db, foe, id, ""), true)
	if gs.combat.has_fight():
		gs.combat.fight["casts"] = int(gs.combat.fight.get("casts", 0)) + 1
	return out


## One spell hit on monster `id`. `npc` = the casting NPC's id, "" = the player.
## The hit roll is made for an auto spell too, so the random stream does not change.
static func _hit_monster(gs: GameState, db: DataDb, id: String, spell_id: String, npc: String) -> void:
	var c := gs.combat
	var s := spell(db, spell_id)
	var m: Dictionary = c.monsters[id]
	var e: Dictionary = db.combat.enemies[m["type"]]
	var who := Combat.name_of(db, m)
	var by := "Your" if npc == "" else "%s's" % Combat.npc_name(db, npc)
	var intellect := Stats.get_stat(gs, db, INTELLECT) if npc == "" \
			else int(db.rules["combat"]["base_stats"]["default"].get(INTELLECT, 3))
	var accuracy := intellect if npc == "" else int(NpcReact.stats(db, npc)["accuracy"])
	if npc == "":
		if [CombatState.HIDDEN, CombatState.IDLE, CombatState.HOME].has(m["state"]):
			m["state"] = CombatState.HOSTILE
		Combat.join(gs, id)
	var roll := gs.rng.randf()
	var from := gs.player.pos() if npc == "" else NpcRoster.pos_of(gs.npcs.npcs[npc])
	var hit := String(s["hit"]) == "auto" or roll < _chance(gs, db, accuracy, id, from)
	if not hit:
		c.lines.append("%s %s misses the %s." % [by, name_of(db, spell_id), who])
		return
	@warning_ignore("integer_division")
	var raw := gs.rng.randi_range(int(s["damage"][0]), int(s["damage"][1])) \
			+ intellect / int(s.get("intellect_div", 3))
	var dmg := maxi(raw - int(e["armor"]), int(db.rules["combat"]["min_damage"]))
	c.lines.append("%s %s hits the %s for %d." % [by, name_of(db, spell_id), who, dmg])
	Combat.damage_monster(gs, db, id, dmg)


## The player's known spells that AP and MP pay for now and that are ready, whatever
## the target (Encounter.maybe_end_turn keeps the turn open for them).
static func castable(gs: GameState, db: DataDb) -> Array[String]:
	var out: Array[String] = []
	var ap := int(gs.combat.encounter.get("ap_q", 0))
	for id in known(gs, db):
		var s := spell(db, id)
		if ready(gs, Encounter.PLAYER, id) and ap >= int(s["ap_q"]) and Mana.current(gs, db) >= int(s["mp"]):
			out.append(id)
	return out


# --- NPC casters -------------------------------------------------------------
# npc_behaviour "combat": {"mp": n, "spells": [{"id", "after_event"?, "until_event"?}]}.
# An NPC's MP is full when it first casts in a fight and is kept in the encounter
# ("npc_mp"); it does not come back inside a fight and is not kept after it.

## NPC `npc`'s spells its canon events allow now, in data order.
static func of_npc(gs: GameState, db: DataDb, npc: String) -> Array[String]:
	var out: Array[String] = []
	for s: Dictionary in db.behaviour.combat_of(npc).get("spells", []):
		var after := String(s.get("after_event", ""))
		var until := String(s.get("until_event", ""))
		if after != "" and gs.world.status(after) != DONE:
			continue
		if until != "" and gs.world.status(until) == DONE:
			continue
		if db.spells.has(String(s["id"])):
			out.append(String(s["id"]))
	return out


static func npc_mp(gs: GameState, db: DataDb, npc: String) -> int:
	var table: Dictionary = gs.combat.encounter.get("npc_mp", {})
	if table.has(npc):
		return int(table[npc])
	return int(db.behaviour.combat_of(npc).get("mp", 0))


static func _npc_spend(gs: GameState, db: DataDb, npc: String, amount: int) -> void:
	var table: Dictionary = gs.combat.encounter.get("npc_mp", {})
	table[npc] = npc_mp(gs, db, npc) - amount
	gs.combat.encounter["npc_mp"] = table


## The spell NPC `npc` casts at foe `foe` with `ap` q left, or "" (a plain blow):
## the first one that is ready, paid for, and reaches (one / blast: the foe in range;
## around: a foe next to the NPC; line: a foe on the line toward it).
static func npc_pick(gs: GameState, db: DataDb, npc: String, ap: int, foe: String) -> String:
	var from := NpcRoster.pos_of(gs.npcs.npcs[npc])
	var at := CombatState.pos_of(gs.combat.monsters[foe])
	for id in of_npc(gs, db, npc):
		var s := spell(db, id)
		if not ready(gs, Encounter.NPC + npc, id) or int(s["ap_q"]) > ap or int(s["mp"]) > npc_mp(gs, db, npc):
			continue
		var reach := true
		match String(s["shape"]):
			"one", "blast":
				reach = Combat._dist(from, at) <= int(s["range"]) and Cover.sight(db, gs.player.area, from, at)
			_:
				reach = not foes_in(gs, cells(gs, db, id, at, from)).is_empty()
		if reach:
			return id
	return ""


## NPC `npc` casts spell `id` at foe `foe` (see npc_pick). Returns the AP it costs.
static func npc_use(gs: GameState, db: DataDb, npc: String, id: String, foe: String) -> int:
	var s := spell(db, id)
	var from := NpcRoster.pos_of(gs.npcs.npcs[npc])
	_npc_spend(gs, db, npc, int(s["mp"]))
	gs.combat.lines.append("%s casts %s." % [Combat.npc_name(db, npc), name_of(db, id)])
	CombatSkills.start_cooldown(gs, Encounter.NPC + npc, KEY + id, s)
	var tiles := cells(gs, db, id, CombatState.pos_of(gs.combat.monsters[foe]), from)
	if not gs.combat.turns.is_empty():
		gs.combat.turns[-1]["cells"] = tiles
	for t in foes_in(gs, tiles):
		Encounter._logged_hit(gs, db, t, func() -> void: _hit_monster(gs, db, t, id, npc), true)
	return int(s["ap_q"])
