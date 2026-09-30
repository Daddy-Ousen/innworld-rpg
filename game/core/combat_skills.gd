## Skills in combat (M17.4, ADR 0027). Three skill effects:
## - "ap_mod" {"value_q"}: AP per turn, for good (quarter points);
## - "combat_action" {"kind", "ap_q", "cooldown", ...}: an active Skill used on
##   the player's turn (Commands.use_skill), or by an NPC ally on theirs;
## and the class field "combat": {"move_ap_mod_q"} raises the move cap
## ([Runner], ADR 0022).
##
## Kinds: "strike" hits one foe side by side ("hits" rolls; "hit_bonus",
## "damage_mult", "damage_bonus"; "thrown": throws the held item, in its
## throw range; "sure_hit": never misses). "area" (shape "around") strikes
## every foe on the 8 tiles around, one roll each. "self": "heal" (a share of
## max HP) and "move_q" (more move cap for this turn).
##
## A used Skill cools down for "cooldown" rounds: CombatState.encounter
## "cool" = {fighter id: {skill id: rounds left}}; each round's start takes one
## off. Only monsters are Skill targets (a brawl foe is hit with plain blows).
## NPC allies use the strike and area Skills of their npc_behaviour combat
## "skills" ({"id", "after_event"?, "until_event"?}: the canon event must be
## done / not yet done) when a foe is side by side.
class_name CombatSkills
extends RefCounted

const ACTION := "combat_action"
const STRIKE := "strike"
const AREA := "area"
const SELF := "self"
const NOT_IN_FIGHT := "Only in a fight."
const UNKNOWN := "You do not have that Skill."
const COOLING := "%s is not ready (%d more round%s)."
const NO_FOE := "There is no foe there."
const NO_FOE_NEAR := "There is no foe next to you."
const DONE := "done"


## The combat_action effect of skill `id`, or {}.
static func action_of(db: DataDb, id: String) -> Dictionary:
	for e: Dictionary in db.skills.get(id, {}).get("effects", []):
		if e["type"] == ACTION:
			return e
	return {}


## The player's Skills with a combat action, in skills.json order.
static func actions(gs: GameState, db: DataDb) -> Array[String]:
	var out: Array[String] = []
	for id: String in db.skills:
		if gs.progression.has_skill(id) and not action_of(db, id).is_empty():
			out.append(id)
	return out


## AP per turn from the player's ap_mod Skills (quarter points).
static func ap_bonus_q(gs: GameState, db: DataDb) -> int:
	var out := 0
	for held: Dictionary in gs.progression.skills:
		for e: Dictionary in db.skills[held["id"]]["effects"]:
			if e["type"] == "ap_mod":
				out += int(e["value_q"])
	return out


## The player's move cap this turn: rules move_cap_q, plus the move_ap_mod_q
## of each class they hold, plus a self Skill's move_q this turn.
static func move_cap_q(gs: GameState, db: DataDb) -> int:
	var out := int(Encounter.rules(db)["move_cap_q"])
	for c: String in gs.progression.classes:
		out += int(db.classes.get(c, {}).get("combat", {}).get("move_ap_mod_q", 0))
	return out + int(gs.combat.encounter.get("move_bonus_q", 0))


## Rounds before `fighter` may use skill `id` again (0 = ready).
static func rounds_left(gs: GameState, fighter: String, id: String) -> int:
	return int(gs.combat.encounter.get("cool", {}).get(fighter, {}).get(id, 0))


## Each cooldown goes down one (a new round starts); finished ones go.
static func tick(gs: GameState) -> void:
	var cool: Dictionary = gs.combat.encounter.get("cool", {})
	for fighter: String in cool.keys():
		var own: Dictionary = cool[fighter]
		for id: String in own.keys():
			var left := int(own[id]) - 1
			if left > 0:
				own[id] = left
			else:
				own.erase(id)
		if own.is_empty():
			cool.erase(fighter)
	gs.combat.encounter["cool"] = cool


static func start_cooldown(gs: GameState, fighter: String, id: String, a: Dictionary) -> void:
	var rounds := int(a.get("cooldown", 0))
	if rounds <= 0:
		return
	var cool: Dictionary = gs.combat.encounter.get("cool", {})
	var own: Dictionary = cool.get(fighter, {})
	own[id] = rounds
	cool[fighter] = own
	gs.combat.encounter["cool"] = cool


## A monster a Skill may hit: on the player's map, seen, not a helper.
static func _is_foe(gs: GameState, id: String) -> bool:
	if not gs.combat.monsters.has(id):
		return false
	var m: Dictionary = gs.combat.monsters[id]
	return m["area"] == gs.player.area \
			and not [CombatState.HIDDEN, CombatState.ALLY].has(m["state"])


## The foes on the 8 tiles around `at`, in id order.
static func foes_around(gs: GameState, at: Vector2i) -> Array[String]:
	var out: Array[String] = []
	for id in gs.combat.ids():
		if _is_foe(gs, id):
			var d: Vector2i = CombatState.pos_of(gs.combat.monsters[id]) - at
			if maxi(absi(d.x), absi(d.y)) == 1:
				out.append(id)
	return out


## Why the player cannot use skill `id` on `target` (a monster id; "" for
## area and self Skills) now; "" = they can.
static func why_not(gs: GameState, db: DataDb, id: String, target: String = "") -> String:
	if not Encounter.active(gs):
		return NOT_IN_FIGHT
	var a := action_of(db, id)
	if a.is_empty() or not gs.progression.has_skill(id):
		return UNKNOWN
	if not Encounter.is_player_turn(gs):
		return Encounter.NOT_YOUR_TURN
	var left := rounds_left(gs, Encounter.PLAYER, id)
	if left > 0:
		return COOLING % [String(db.skills[id]["name"]), left, "" if left == 1 else "s"]
	if int(gs.combat.encounter["ap_q"]) < int(a["ap_q"]):
		return Encounter.NO_AP
	match String(a["kind"]):
		STRIKE:
			if not _is_foe(gs, target):
				return NO_FOE
			var dist := Combat._dist(gs.player.pos(), CombatState.pos_of(gs.combat.monsters[target]))
			if bool(a.get("thrown", false)):
				if gs.player.held == "":
					return "You hold nothing to throw."
				if dist > int(db.combat.items[gs.player.held]["throw_range"]):
					return "Too far to throw."
				if not Cover.sight(db, gs.player.area, gs.player.pos(), CombatState.pos_of(gs.combat.monsters[target])):
					return Combat.NO_SIGHT
			elif MonsterSim._manhattan(gs.player.pos(), CombatState.pos_of(gs.combat.monsters[target])) != 1:
				return NO_FOE
		AREA:
			if foes_around(gs, gs.player.pos()).is_empty():
				return NO_FOE_NEAR
	return Combat.cannot_act(gs, db)


## The foes skill `id` could hit now (for the screen): strike, the foes in
## reach; area, the foes around. [] for self Skills or when it cannot be used.
static func targets(gs: GameState, db: DataDb, id: String) -> Array[String]:
	var out: Array[String] = []
	var a := action_of(db, id)
	if a.is_empty():
		return out
	match String(a["kind"]):
		STRIKE:
			for m in gs.combat.ids():
				if why_not(gs, db, id, m) == "":
					out.append(m)
		AREA:
			if why_not(gs, db, id) == "":
				out = foes_around(gs, gs.player.pos())
	return out


## The player's chance to hit monster `unit` with skill `id` (1.0 for sure_hit).
static func hit_chance(gs: GameState, db: DataDb, id: String, unit: String) -> float:
	var a := action_of(db, id)
	if bool(a.get("sure_hit", false)):
		return 1.0
	var thrown := bool(a.get("thrown", false))
	var dist := Combat._dist(gs.player.pos(), CombatState.pos_of(gs.combat.monsters[unit]))
	return Combat.player_hit_chance(gs, db, unit, thrown, dist if thrown else 1,
			float(a.get("hit_bonus", 0.0)))


## The damage and hit mods of an action, for Combat._strike / NpcReact._hit.
static func mods(a: Dictionary) -> Dictionary:
	return {"hit_bonus": float(a.get("hit_bonus", 0.0)), "damage_mult": float(a.get("damage_mult", 1.0)),
		"damage_bonus": int(a.get("damage_bonus", 0)), "sure_hit": bool(a.get("sure_hit", false))}


## The player uses skill `id` (why_not must be ""): writes the lines and the
## turn log's blows, starts the cooldown. The caller pays the AP. Returns
## {"error": "", "skill", "strikes": [monster ids hit at], "healed", "move_q"}.
static func use(gs: GameState, db: DataDb, id: String, target: String = "") -> Dictionary:
	var a := action_of(db, id)
	var out := {"error": "", "skill": id, "strikes": [], "healed": 0, "move_q": 0}
	gs.combat.lines.append("You use %s." % String(db.skills[id]["name"]))
	start_cooldown(gs, Encounter.PLAYER, id, a)
	var m := mods(a)
	match String(a["kind"]):
		STRIKE:
			var thrown := bool(a.get("thrown", false))
			var blow := func() -> void: Combat.strike_at(gs, db, target, m)
			if thrown:
				blow = func() -> void: Combat.throw_at(gs, db, target, m)
			for _i in maxi(int(a.get("hits", 1)), 1):
				if not gs.combat.monsters.has(target):
					break
				(out["strikes"] as Array).append(target)
				Encounter._logged_hit(gs, db, target, blow, thrown)
		AREA:
			for foe in foes_around(gs, gs.player.pos()):
				(out["strikes"] as Array).append(foe)
				Encounter._logged_hit(gs, db, foe, func() -> void: Combat.strike_at(gs, db, foe, m))
		SELF:
			var heal := roundi(Stats.max_hp(gs, db) * float(a.get("heal", 0.0)))
			if heal > 0:
				var before := Combat.hp(gs, db)
				Combat.set_hp(gs, db, mini(before + heal, Stats.max_hp(gs, db)))
				out["healed"] = Combat.hp(gs, db) - before
				gs.combat.lines.append("You recover %d HP." % out["healed"])
			var move := int(a.get("move_q", 0))
			if move > 0:
				var e := gs.combat.encounter
				e["move_bonus_q"] = int(e.get("move_bonus_q", 0)) + move
				out["move_q"] = move
				gs.combat.lines.append("You can move further this turn.")
	return out


## NPC `npc`'s Skills it may use now (canon events allow them), in data order.
static func of_npc(gs: GameState, db: DataDb, npc: String) -> Array[String]:
	var out: Array[String] = []
	for s: Dictionary in db.behaviour.combat_of(npc).get("skills", []):
		var after := String(s.get("after_event", ""))
		var until := String(s.get("until_event", ""))
		if after != "" and gs.world.status(after) != DONE:
			continue
		if until != "" and gs.world.status(until) == DONE:
			continue
		if not action_of(db, String(s["id"])).is_empty():
			out.append(String(s["id"]))
	return out


## The Skill NPC ally `npc` (standing at `at`) uses on `foe` (side by side)
## with `ap` q left: the first ready strike (not thrown) or area Skill it can
## pay for; "" = a plain blow.
static func npc_pick(gs: GameState, db: DataDb, npc: String, ap: int) -> String:
	for id in of_npc(gs, db, npc):
		var a := action_of(db, id)
		if rounds_left(gs, Encounter.NPC + npc, id) > 0 or int(a["ap_q"]) > ap:
			continue
		if (String(a["kind"]) == STRIKE and not bool(a.get("thrown", false))) or String(a["kind"]) == AREA:
			return id
	return ""


## NPC ally `npc` uses skill `id` on `foe` (or on the foes around it, for an
## area Skill). Returns the AP it costs.
static func npc_use(gs: GameState, db: DataDb, npc: String, id: String, foe: String) -> int:
	var a := action_of(db, id)
	gs.combat.lines.append("%s uses %s." % [Combat.npc_name(db, npc), String(db.skills[id]["name"])])
	start_cooldown(gs, Encounter.NPC + npc, id, a)
	var m := mods(a)
	var hit := func(t: String) -> void:
		Encounter._logged_hit(gs, db, t, func() -> void: NpcReact._hit(gs, db, npc, t, m))
	if String(a["kind"]) == AREA:
		for t in foes_around(gs, NpcRoster.pos_of(gs.npcs.npcs[npc])):
			if gs.combat.monsters[t]["state"] != CombatState.ALLY:
				hit.call(t)
	else:
		for _i in maxi(int(a.get("hits", 1)), 1):
			if not gs.combat.monsters.has(foe):
				break
			hit.call(foe)
	return int(a["ap_q"])
