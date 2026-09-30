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
## "player" or monster ids], "tie": {id: roll}, "turn": index into order,
## "ap_q", "moved_q" (the player's, on their turn)}. Monsters take their whole
## turn at once, so their AP is never stored.
##
## Off unless rules.combat.tactical.enabled (M17.2 turns it on). NPCs still act
## in world time (once per round's seconds) until M17.2.
class_name Encounter
extends RefCounted

const PLAYER := "player"
const Q_PER_AP := 4
const NO_AP := "Not enough AP."
const NO_MOVE := "You cannot move further this turn."
const NOT_YOUR_TURN := "It is not your turn."
const NOT_YET := "Not in combat mode yet."
const NO_TURN := "There is no turn to end."
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
## on and a hostile monster is on the player's map; drops one whose fight is
## over (won, fled, knocked out).
static func sync(gs: GameState, db: DataDb) -> void:
	var c := gs.combat
	if active(gs):
		if not c.has_fight():
			c.encounter = {}
		return
	if enabled(db) and c.has_fight() and not Combat.is_down(gs) and _has_hostile(gs):
		c.encounter = {"round": 0, "order": [], "tie": {}, "turn": 0, "ap_q": 0, "moved_q": 0}
		_new_round(gs, db)
		_run_until_player(gs, db)


## The player's AP for a turn: ap_base_q, plus one AP for each of
## ap_total_levels the total class level has reached (silent; ADR 0022).
static func player_ap(gs: GameState, db: DataDb) -> int:
	var t := rules(db)
	var ap := int(t["ap_base_q"])
	var total := gs.progression.total_level()
	for lv: Variant in t.get("ap_total_levels", []):
		if total >= int(lv):
			ap += Q_PER_AP
	return ap


## Turn order value: the player's initiative stat; a monster's "agility", or
## initiative.by_act_seconds for its act_seconds, or initiative.monster_default.
static func agility(gs: GameState, db: DataDb, id: String) -> int:
	var ini: Dictionary = rules(db)["initiative"]
	if id == PLAYER:
		return Stats.get_stat(gs, db, String(ini["stat"]))
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
	if move and int(e["moved_q"]) + cost_q > int(rules(db)["move_cap_q"]):
		return NO_MOVE
	if int(e["ap_q"]) < cost_q:
		return NO_AP
	return ""


static func pay(gs: GameState, cost_q: int, move: bool) -> void:
	var e := gs.combat.encounter
	e["ap_q"] = int(e["ap_q"]) - cost_q
	if move:
		e["moved_q"] = int(e["moved_q"]) + cost_q


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


static func _has_hostile(gs: GameState) -> bool:
	for id in gs.combat.in_state(CombatState.HOSTILE):
		if gs.combat.monsters[id]["area"] == gs.player.area:
			return true
	return false


static func _is_fighter(gs: GameState, id: String) -> bool:
	if id == PLAYER:
		return true
	var m: Dictionary = gs.combat.monsters.get(id, {})
	return not m.is_empty() and m["area"] == gs.player.area and FIGHTERS.has(m["state"])


## Builds the round's order from who is on the map now. New fighters roll
## their tie now (in id order), so the order is the same on every replay.
static func _new_round(gs: GameState, db: DataDb) -> void:
	var e := gs.combat.encounter
	e["round"] = int(e["round"]) + 1
	var ids: Array[String] = [PLAYER]
	for id in gs.combat.ids():
		if _is_fighter(gs, id):
			ids.append(id)
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
		if not c.has_fight():
			c.encounter = {}
			return
		if Combat.is_down(gs):
			return
		var e := c.encounter
		var order: Array = e["order"]
		if int(e["turn"]) >= order.size():
			_end_round(gs, db)
			if not active(gs) or not c.has_fight():
				c.encounter = {}
				return
			_new_round(gs, db)
			continue
		var id: String = order[int(e["turn"])]
		if id == PLAYER:
			e["ap_q"] = player_ap(gs, db)
			e["moved_q"] = 0
			return
		if _is_fighter(gs, id):
			_monster_turn(gs, db, id)
			Combat.settle_if_over(gs, db)
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
		if gs.combat.monsters.has(id) and not _is_fighter(gs, id) \
				and gs.combat.monsters[id]["area"] == gs.player.area:
			MonsterSim._turn(gs, db, id)
	Commands._after(gs, db)


## One monster's whole turn on AP (monster.move_cap_q for moving).
static func _monster_turn(gs: GameState, db: DataDb, id: String) -> void:
	var t := rules(db)
	var ap := int(t["ap_base_q"])
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
				if c.monsters.has(id) and CombatState.pos_of(m) == before:
					break
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
			Combat.monster_attack(gs, db, id, false, 0.0, target)
			ap -= atk
			continue
		if not threw and e.has("ranged") and ap >= atk \
				and MonsterSim._dist(pos, at) <= int(e["ranged"]["range"]):
			threw = true
			if gs.rng.randf() < float(e["ranged"]["chance"]):
				Combat.monster_attack(gs, db, id, true, 0.0, target)
				ap -= atk
				continue
		if moved + step > cap or ap < step or not MonsterSim._step_next_to(gs, db, id, at):
			break
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
			Combat.helper_attack(gs, db, id, foe)
			ap -= atk
			continue
		if moved + step > cap or ap < step or not MonsterSim._step_next_to(gs, db, id, at):
			return
		moved += step
		ap -= step
