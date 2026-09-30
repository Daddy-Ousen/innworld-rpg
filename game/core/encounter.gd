## Tactical combat mode (M17.1, ADR 0027): a fight on the map runs in rounds.
## Everyone in it acts once per round, highest Agility first (the player's
## speed stat; a monster's "agility", else one from its act_seconds); ties go
## by a seeded roll made when the fighter first joins. A turn has AP in
## quarter points (rules.combat.tactical: 6 AP = 24 q); a tile costs 1 q and
## at most move_cap_q may go on moving; an attack costs attack_cost_q. AP
## does not carry over. Player actions take no world time; each round spends
## round_seconds once, at its end. A fighter who arrives mid-round joins at
## the next round (the order is rebuilt at each round's start).
##
## State (CombatState.encounter; {} = none): {"round", "order": [fighter ids,
## "player", monster ids or "npc:<id>"], "tie": {id: roll}, "turn": index into
## order, "ap_q", "moved_q" (the player's, on their turn)}. Monsters and NPCs
## take their whole turn at once, so their AP is never stored.
##
## M17.2: on in the real data. A brawl (an NPC the player hit, Brawl) starts
## one too. NPC fighters (Brawl-hostile NPCs, and NpcReact fighters with a foe
## in reach) get turns like monsters; bystanders still step away in world time
## at a round's end. A raised guard lasts until the player's next turn. The
## player's turn ends by itself when their AP pays for nothing (no step, no
## item use).
##
## M17.3 (the combat screen): `reach` and `plan_to` read what a click would do;
## each command logs what every fighter did, in order, in CombatState.turns
## ({"id", "path": cells stepped on, "strikes": [{"target", "hit", "damage",
## "ranged"}], "lines", "line_from", "line_to"}), so the screen can replay the turns one by one.
class_name Encounter
extends RefCounted

const PLAYER := "player"
const NPC := "npc:"
const Q_PER_AP := 4
const NO_AP := "Not enough AP."
const NO_MOVE := "You cannot move further this turn."
const NOT_YOUR_TURN := "It is not your turn."
const NO_TURN := "There is no turn to end."
const TURN_OVER := "Your turn is over."
## Refusals that ending the turn would fix (a test bot ends the turn on these).
const TURN_REFUSALS := [NO_AP, NO_MOVE, NOT_YOUR_TURN]
## Monster states that take part in the rounds.
const FIGHTERS := [CombatState.HOSTILE, CombatState.FLEE, CombatState.ALLY]
const MAX_STEPS := 10000


static func rules(db: DataDb) -> Dictionary:
	return db.rules["combat"].get("tactical", {})


static func enabled(db: DataDb) -> bool:
	return bool(rules(db).get("enabled", false))


static func active(gs: GameState) -> bool:
	return not gs.combat.encounter.is_empty()


static func is_player_turn(gs: GameState) -> bool:
	if not active(gs):
		return false
	var e := gs.combat.encounter
	var order: Array = e["order"]
	return int(e["turn"]) < order.size() and order[int(e["turn"])] == PLAYER


## Commands._after calls this last: starts an encounter when combat mode is
## on and a hostile monster or a hostile NPC (Brawl) is on the player's map;
## drops one whose fight is over (won, fled, knocked out).
static func sync(gs: GameState, db: DataDb) -> void:
	var c := gs.combat
	if active(gs):
		if _over(gs):
			c.encounter = {}
		return
	if enabled(db) and not Combat.is_down(gs) \
			and ((c.has_fight() and _has_hostile(gs)) or Brawl.hostile_near(gs)):
		c.encounter = {"round": 0, "order": [], "tie": {}, "turn": 0, "ap_q": 0, "moved_q": 0,
			"cool": {}, "move_bonus_q": 0}
		_new_round(gs, db)
		_run_until_player(gs, db)


## No fight is on and no hostile NPC is near.
static func _over(gs: GameState) -> bool:
	return not gs.combat.has_fight() and not Brawl.hostile_near(gs)


## The player's AP for a turn: ap_base_q, plus one AP for each of
## ap_total_levels the total class level has reached (silent; ADR 0022),
## plus the ap_mod Skills (M17.4).
static func player_ap(gs: GameState, db: DataDb) -> int:
	var t := rules(db)
	var ap := int(t["ap_base_q"]) + CombatSkills.ap_bonus_q(gs, db)
	var total := gs.progression.total_level()
	for lv: Variant in t.get("ap_total_levels", []):
		if total >= int(lv):
			ap += Q_PER_AP
	return ap


## Turn order value: the player's initiative stat; a monster's "agility", or
## initiative.by_act_seconds for its act_seconds, or initiative.monster_default;
## an NPC's initiative.npc_default (M17.2; own numbers come in M17.7).
static func agility(gs: GameState, db: DataDb, id: String) -> int:
	var ini: Dictionary = rules(db)["initiative"]
	if id == PLAYER:
		return Stats.get_stat(gs, db, String(ini["stat"]))
	if id.begins_with(NPC):
		return int(ini.get("npc_default", ini["monster_default"]))
	var e: Dictionary = db.combat.enemies[gs.combat.monsters[id]["type"]]
	if e.has("agility"):
		return int(e["agility"])
	return int((ini.get("by_act_seconds", {}) as Dictionary).get(str(int(e["act_seconds"])),
			ini["monster_default"]))


## Why the player cannot pay `cost_q` now ("" = they can). `move`: the cost
## counts against the move cap too.
static func check(gs: GameState, db: DataDb, cost_q: int, move: bool) -> String:
	if not is_player_turn(gs):
		return NOT_YOUR_TURN
	var e := gs.combat.encounter
	if move and int(e["moved_q"]) + cost_q > CombatSkills.move_cap_q(gs, db):
		return NO_MOVE
	if int(e["ap_q"]) < cost_q:
		return NO_AP
	return ""


static func pay(gs: GameState, cost_q: int, move: bool) -> void:
	var e := gs.combat.encounter
	e["ap_q"] = int(e["ap_q"]) - cost_q
	if move:
		e["moved_q"] = int(e["moved_q"]) + cost_q


## The tiles the player can walk to on this turn (M17.3): {cell: steps (n, e,
## s, w)}, breadth-first in Pathfind.ORDER (so the same state gives the same
## paths), within the AP left and the move cap left, over tiles
## Movement.can_enter allows. An exit tile ends a path (the step onto it leaves
## the map). {} when it is not the player's turn.
@warning_ignore("integer_division")
static func reach(gs: GameState, db: DataDb) -> Dictionary:
	if not is_player_turn(gs):
		return {}
	var t := rules(db)
	var e := gs.combat.encounter
	var budget := mini(int(e["ap_q"]), CombatSkills.move_cap_q(gs, db) - int(e["moved_q"])) \
			/ int(t["move_cost_q"])
	var area := gs.player.area
	var start := gs.player.pos()
	var came := {start: []}
	var out := {}
	var frontier: Array[Vector2i] = [start]
	for _i in budget:
		var next: Array[Vector2i] = []
		for at in frontier:
			if at != start and not db.maps.exit_at(area, at).is_empty():
				continue
			for dir: String in Pathfind.ORDER:
				var to: Vector2i = at + (PlayerState.DIRS[dir] as Vector2i)
				if came.has(to) or not Movement.can_enter(gs, db, area, to):
					continue
				var steps: Array = (came[at] as Array).duplicate()
				steps.append(dir)
				came[to] = steps
				out[to] = steps
				next.append(to)
		frontier = next
	return out


## What a click on `cell` would do on the player's turn (M17.3):
## {"steps": the walk, "attack": the direction of the blow after it, or "",
## "target": the unit hit ("" = a plain walk; a monster id, or NPC + id for a
## brawl foe)}. A tile in reach: walk there. A foe (a seen, not helping
## monster, or an NPC fighting the player): walk to the free side of it with
## the fewest steps (or stay, when next to it), then attack if the AP left pays
## for it (else "attack" is ""). {} when the click does nothing.
static func plan_to(gs: GameState, db: DataDb, cell: Vector2i) -> Dictionary:
	var r := reach(gs, db)
	if r.is_empty() and not is_player_turn(gs):
		return {}
	var area := gs.player.area
	var target := _foe_at(gs, db, cell)
	if target == "":
		return {"steps": r[cell], "attack": "", "target": ""} if r.has(cell) else {}
	var spots := {gs.player.pos(): []}
	for at: Vector2i in r:
		if db.maps.exit_at(area, at).is_empty():
			spots[at] = r[at]
	for at: Vector2i in spots:
		for dir: String in Pathfind.ORDER:
			if at + (PlayerState.DIRS[dir] as Vector2i) == cell:
				var t := rules(db)
				var steps: Array = spots[at]
				var left := int(gs.combat.encounter["ap_q"]) - steps.size() * int(t["move_cost_q"])
				return {"steps": steps, "attack": dir if left >= int(t["attack_cost_q"]) else "",
					"target": target}
	return {}


## The foe the player could attack on `cell`: a hostile or fleeing monster
## (not hidden, not a helper), or NPC + id for an NPC fighting the player
## (Brawl). "" if none.
static func _foe_at(gs: GameState, db: DataDb, cell: Vector2i) -> String:
	var area := gs.player.area
	var id := gs.combat.at(area, cell)
	if id != "":
		return id if [CombatState.HOSTILE, CombatState.FLEE].has(gs.combat.monsters[id]["state"]) else ""
	var npc := gs.npcs.at(area, cell)
	if npc != "" and Brawl.on(db) and Brawl.is_hostile(gs, gs.npcs.npcs[npc]):
		return NPC + npc
	return ""


## Turn log (M17.3): opens fighter `id`'s entry in CombatState.turns.
static func log_begin(gs: GameState, id: String) -> void:
	gs.combat.turns.append({"id": id, "path": [], "strikes": [], "lines": [],
		"_line0": gs.combat.lines.size()})


## Notes a step onto `cell` in the open entry.
static func log_step(gs: GameState, cell: Vector2i) -> void:
	if not gs.combat.turns.is_empty():
		(gs.combat.turns[-1]["path"] as Array).append(cell)


## Notes a blow at `target` (a fighter id) in the open entry.
static func log_strike(gs: GameState, target: String, damage: int, ranged: bool = false) -> void:
	if not gs.combat.turns.is_empty():
		(gs.combat.turns[-1]["strikes"] as Array).append(
				{"target": target, "hit": damage > 0, "damage": damage, "ranged": ranged})


## Closes the open entry: it keeps the combat lines written since log_begin
## ("lines", and their place in CombatState.lines: "line_from", "line_to").
## An entry with nothing in it is dropped.
static func log_end(gs: GameState) -> void:
	var c := gs.combat
	if c.turns.is_empty() or not c.turns[-1].has("_line0"):
		return
	var t: Dictionary = c.turns[-1]
	t["line_from"] = int(t["_line0"])
	t["line_to"] = c.lines.size()
	t["lines"] = c.lines.slice(int(t["_line0"]))
	t.erase("_line0")
	if (t["path"] as Array).is_empty() and (t["strikes"] as Array).is_empty() \
			and (t["lines"] as Array).is_empty():
		c.turns.pop_back()


## HP of fighter `id` now (0 = gone or down), for the log's damage.
static func hp_of(gs: GameState, db: DataDb, id: String) -> int:
	if id == PLAYER:
		return Combat.hp(gs, db)
	if id.begins_with(NPC):
		var npc := id.substr(NPC.length())
		return Combat.npc_hp(gs, db, npc) if gs.npcs.npcs.has(npc) else 0
	return int(gs.combat.monsters[id]["hp"]) if gs.combat.monsters.has(id) else 0


## Runs `hit` (a blow at `target`) and logs its damage from the HP change.
static func _logged_hit(gs: GameState, db: DataDb, target: String, hit: Callable,
		ranged: bool = false) -> void:
	var before := hp_of(gs, db, target)
	hit.call()
	log_strike(gs, target, maxi(before - hp_of(gs, db, target), 0), ranged)


## The fighter id of a monster_target result.
static func _target_id(target: Dictionary) -> String:
	match target["kind"]:
		Combat.PLAYER:
			return PLAYER
		Combat.NPC:
			return NPC + String(target["id"])
	return String(target["id"])


## The player ends their turn: everyone after them acts, rounds go on until
## it is the player's turn again (or the fight is over, or they are down).
## Returns "" or why not.
static func end_player_turn(gs: GameState, db: DataDb) -> String:
	if not is_player_turn(gs):
		return NO_TURN
	var e := gs.combat.encounter
	e["turn"] = int(e["turn"]) + 1
	e["ap_q"] = 0
	e["moved_q"] = 0
	_run_until_player(gs, db)
	return ""


## After a paid action: if the player's AP left pays for nothing (no step
## within the move cap, no item use), their turn ends ("Your turn is over.").
## Returns true if it ended.
static func maybe_end_turn(gs: GameState, db: DataDb) -> bool:
	if not is_player_turn(gs):
		return false
	var t := rules(db)
	var e := gs.combat.encounter
	var ap := int(e["ap_q"])
	var step := int(t["move_cost_q"])
	if (ap >= step and int(e["moved_q"]) + step <= CombatSkills.move_cap_q(gs, db)) \
			or ap >= int(t["item_cost_q"]):
		return false
	for id in CombatSkills.actions(gs, db):  # M17.4: a ready self Skill it can pay for
		var a := CombatSkills.action_of(db, id)
		if a["kind"] == CombatSkills.SELF and ap >= int(a["ap_q"]) \
				and CombatSkills.rounds_left(gs, PLAYER, id) == 0:
			return false
	gs.combat.lines.append(TURN_OVER)
	end_player_turn(gs, db)
	return true


static func _has_hostile(gs: GameState) -> bool:
	for id in gs.combat.in_state(CombatState.HOSTILE):
		if gs.combat.monsters[id]["area"] == gs.player.area:
			return true
	return false


static func _is_fighter(gs: GameState, db: DataDb, id: String) -> bool:
	if id == PLAYER:
		return true
	if id.begins_with(NPC):
		return npc_fights(gs, db, id.substr(NPC.length()))
	var m: Dictionary = gs.combat.monsters.get(id, {})
	return not m.is_empty() and m["area"] == gs.player.area and FIGHTERS.has(m["state"])


## True if NPC `npc` takes turns in the fight: alive, up, in the player's
## area, not held by a scene, and hostile to the player (Brawl) or a fighter
## with a foe in reach (NpcReact.target). `held`: Stage.scene_npcs_here, if
## the caller has it.
static func npc_fights(gs: GameState, db: DataDb, npc: String, held: Variant = null) -> bool:
	var n: Dictionary = gs.npcs.npcs.get(npc, {})
	if n.is_empty() or n["area"] != gs.player.area or bool(n.get("down", false)) \
			or not gs.world.is_alive(db.canon, npc):
		return false
	if ((held if held != null else Stage.scene_npcs_here(gs, db)) as Dictionary).has(npc):
		return false
	if Brawl.on(db) and Brawl.is_hostile(gs, n):
		return true
	return NpcReact.is_fighter(gs, db, npc) and NpcReact.target(gs, db, npc, n) != ""


## Builds the round's order from who is on the map now. New fighters roll
## their tie now (monsters in id order, then NPCs in id order), so the order
## is the same on every replay.
static func _new_round(gs: GameState, db: DataDb) -> void:
	var e := gs.combat.encounter
	e["round"] = int(e["round"]) + 1
	CombatSkills.tick(gs)
	var ids: Array[String] = [PLAYER]
	for id in gs.combat.ids():
		if _is_fighter(gs, db, id):
			ids.append(id)
	var held := Stage.scene_npcs_here(gs, db)
	for npc in gs.npcs.in_area(gs.player.area):
		if npc_fights(gs, db, npc, held):
			ids.append(NPC + npc)
	var tie: Dictionary = e["tie"]
	var kept := {}
	var agi := {}
	for id in ids:
		kept[id] = float(tie[id]) if tie.has(id) else gs.rng.randf()
		agi[id] = agility(gs, db, id)
	e["tie"] = kept
	ids.sort_custom(func(a: String, b: String) -> bool:
		return agi[a] > agi[b] or (agi[a] == agi[b] and kept[a] > kept[b]))
	e["order"] = ids
	e["turn"] = 0


## Runs turns from the current one until the player's (their AP is filled),
## ending rounds on the way. Stops when the player is down or the fight ends.
static func _run_until_player(gs: GameState, db: DataDb) -> void:
	var c := gs.combat
	for _i in MAX_STEPS:
		if not active(gs):
			return
		if _over(gs):
			c.encounter = {}
			return
		if Combat.is_down(gs):
			return
		var e := c.encounter
		var order: Array = e["order"]
		if int(e["turn"]) >= order.size():
			_end_round(gs, db)
			if not active(gs) or _over(gs):
				c.encounter = {}
				return
			_new_round(gs, db)
			continue
		var id: String = order[int(e["turn"])]
		if id == PLAYER:
			e["ap_q"] = player_ap(gs, db)
			e["moved_q"] = 0
			e["move_bonus_q"] = 0
			c.blocking = false  # a guard lasts until the player's next turn
			return
		if _is_fighter(gs, db, id):
			log_begin(gs, id)
			if id.begins_with(NPC):
				_npc_turn(gs, db, id.substr(NPC.length()))
			else:
				_monster_turn(gs, db, id)
			Combat.settle_if_over(gs, db)
			log_end(gs)
		if active(gs):
			e["turn"] = int(e["turn"]) + 1
	push_error("Encounter: too many turns in one go.")


## The round is over: its world time passes (the NPCs, spawns and stage waves
## move on in Commands._after), and monsters outside the fight (idle, hidden,
## going home) get their one ordinary turn, so an idle one can still notice
## the player and join.
static func _end_round(gs: GameState, db: DataDb) -> void:
	Movement._spend_seconds(gs, int(rules(db)["round_seconds"]))
	for id in gs.combat.ids():
		if gs.combat.monsters.has(id) and not _is_fighter(gs, db, id) \
				and gs.combat.monsters[id]["area"] == gs.player.area:
			MonsterSim._turn(gs, db, id)
	Commands._after(gs, db)


## One monster's whole turn on AP (monster.move_cap_q for moving; monster.ap_q
## if set, else ap_base_q; 0 = monsters skip their turns).
static func _monster_turn(gs: GameState, db: DataDb, id: String) -> void:
	var t := rules(db)
	var ap := int(t["monster"].get("ap_q", t["ap_base_q"]))
	if ap <= 0:
		return
	var cap := int(t["monster"]["move_cap_q"])
	var step := int(t["move_cost_q"])
	var atk := int(t["attack_cost_q"])
	var c := gs.combat
	var m: Dictionary = c.monsters[id]
	match m["state"]:
		CombatState.FLEE:
			var moved := 0
			while moved + step <= cap and c.monsters.has(id) and m["state"] == CombatState.FLEE:
				var before := CombatState.pos_of(m)
				MonsterSim._flee_turn(gs, db, id)
				moved += step
				if not c.monsters.has(id):
					break
				if CombatState.pos_of(m) == before:
					break
				log_step(gs, CombatState.pos_of(m))
		CombatState.ALLY:
			_ally_turn(gs, db, id, ap, cap, step, atk)
		CombatState.HOSTILE:
			_hostile_turn(gs, db, id, ap, cap, step, atk)


## A hostile monster: flee or give up as in MonsterSim (once per turn); else
## go for its target: one ranged roll from afar, steps (to the cap), then
## melee hits while AP lasts.
static func _hostile_turn(gs: GameState, db: DataDb, id: String, ap: int, cap: int, step: int,
		atk: int) -> void:
	var c := gs.combat
	var m: Dictionary = c.monsters[id]
	var e: Dictionary = db.combat.enemies[m["type"]]
	if MonsterSim._hostile_checks(gs, db, id):
		return
	var moved := 0
	var threw := false
	var reached := false
	while c.monsters.has(id) and m["state"] == CombatState.HOSTILE and not Combat.is_down(gs):
		var target := Combat.monster_target(gs, db, id)
		if target.is_empty():
			break
		var pos := CombatState.pos_of(m)
		var at: Vector2i = target["pos"]
		if MonsterSim._next_to(pos, at):
			reached = true
			if ap < atk:
				break
			m["chase"] = 0
			_logged_hit(gs, db, _target_id(target),
					func() -> void: Combat.monster_attack(gs, db, id, false, 0.0, target))
			ap -= atk
			continue
		if not threw and e.has("ranged") and ap >= atk \
				and MonsterSim._dist(pos, at) <= int(e["ranged"]["range"]):
			threw = true
			if gs.rng.randf() < float(e["ranged"]["chance"]):
				_logged_hit(gs, db, _target_id(target),
						func() -> void: Combat.monster_attack(gs, db, id, true, 0.0, target), true)
				ap -= atk
				continue
		if moved + step > cap or ap < step or not MonsterSim._step_next_to(gs, db, id, at):
			break
		log_step(gs, CombatState.pos_of(m))
		moved += step
		ap -= step
	if c.monsters.has(id) and not reached:
		m["chase"] = int(m["chase"]) + 1


## A helper: steps to the nearest hostile monster, then hits it while AP lasts.
static func _ally_turn(gs: GameState, db: DataDb, id: String, ap: int, cap: int, step: int,
		atk: int) -> void:
	var c := gs.combat
	var moved := 0
	while c.monsters.has(id):
		var foe := MonsterSim._nearest_hostile(gs, id)
		if foe == "":
			return
		var at := CombatState.pos_of(c.monsters[foe])
		if MonsterSim._next_to(CombatState.pos_of(c.monsters[id]), at):
			if ap < atk:
				return
			_logged_hit(gs, db, foe, func() -> void: Combat.helper_attack(gs, db, id, foe))
			ap -= atk
			continue
		if moved + step > cap or ap < step or not MonsterSim._step_next_to(gs, db, id, at):
			return
		log_step(gs, CombatState.pos_of(c.monsters[id]))
		moved += step
		ap -= step


## One NPC fighter's whole turn on AP (monster.move_cap_q for moving): a
## hostile NPC (Brawl) steps to the player and hits them; an NpcReact fighter
## steps to its foe and hits it, while AP lasts.
static func _npc_turn(gs: GameState, db: DataDb, npc: String) -> void:
	var t := rules(db)
	var ap := int(t["ap_base_q"])
	var cap := int(t["monster"]["move_cap_q"])
	var step := int(t["move_cost_q"])
	var atk := int(t["attack_cost_q"])
	var n: Dictionary = gs.npcs.npcs[npc]
	var moved := 0
	var angry := Brawl.on(db) and Brawl.is_hostile(gs, n)
	for _i in MAX_STEPS:
		if Combat.is_down(gs) or bool(n.get("down", false)):
			return
		var pos := NpcRoster.pos_of(n)
		if angry:
			if Brawl._dist(pos, gs.player.pos()) <= 1:
				if ap < atk:
					return
				_logged_hit(gs, db, PLAYER, func() -> void: Brawl._hit_player(gs, db, npc))
				ap -= atk
				continue
		else:
			var foe := NpcReact.target(gs, db, npc, n)
			if foe == "":
				return
			if NpcReact._manhattan(pos, CombatState.pos_of(gs.combat.monsters[foe])) == 1:
				var skill := CombatSkills.npc_pick(gs, db, npc, ap)  # M17.4
				if skill != "":
					ap -= CombatSkills.npc_use(gs, db, npc, skill, foe)
					continue
				if ap < atk:
					return
				_logged_hit(gs, db, foe, func() -> void: NpcReact._hit(gs, db, npc, foe))
				ap -= atk
				continue
		if moved + step > cap or ap < step:
			return
		if angry:
			Brawl._step_towards_player(gs, db, n)
		else:
			NpcReact._fight_turn(gs, db, npc, n, NpcReact.target(gs, db, npc, n))
		if NpcRoster.pos_of(n) == pos:
			return
		log_step(gs, NpcRoster.pos_of(n))
		moved += step
		ap -= step
