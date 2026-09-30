## The commands presentation may send. UI and console call only these;
## they never change GameState directly (CLAUDE.md rule 1). Every command
## that moves the clock then runs _after: the monsters' turn and fight
## bookkeeping (Combat.sync), then the NPCs (NpcSim.sync; near a fight they
## react, M6.5), then the fight ends if no foe is left. Combat text of the
## last command is in gs.combat.lines.
class_name Commands
extends RefCounted


## Does an action. Returns the record, or {} if refused (see Actions.perform;
## also while knocked out or with enemies near: the reason is in gs.combat.lines).
static func perform(gs: GameState, db: DataDb, action_id: String, opts: Dictionary = {}) -> Dictionary:
	Combat.begin_command(gs)
	var why := Combat.refusal(gs)
	if why != "":
		gs.combat.lines.append(why)
		return {}
	var rec := Actions.perform(gs, db, action_id, opts)
	Combat.heal_after_action(gs, db, rec)
	Economy.after_action(gs, db, rec)
	Cooking.after_action(gs, db, rec)
	_after(gs, db)
	return rec


## Ends the day. If the player is past the awake limit, this is a collapse
## (anywhere). Knocked out, or a collapse with enemies near: a knock-out
## (see knock_out). With enemies near otherwise, or where the player may
## not sleep (Rest.place: outdoors, or a room they cannot pay for):
## refused, returns {} (the reason is in gs.combat.lines). `bed` is a bed
## object next to the player ("" = where you stand); a paid room is paid.
static func sleep(gs: GameState, db: DataDb, bed: String = "") -> Dictionary:
	Combat.begin_command(gs)
	var collapse := gs.clock.is_collapse_due(db.rules["clock"])
	if Combat.is_down(gs) or (collapse and Combat.in_danger(gs)):
		return knock_out(gs, db)
	if Combat.in_danger(gs):
		gs.combat.lines.append(Combat.REFUSED_DANGER)
		return {}
	var rest := Rest.place(gs, db, bed)
	if not collapse and rest["rest"] == "":
		gs.combat.lines.append(rest["error"])
		return {}
	if not collapse and int(rest["price"]) > 0:
		gs.economy.coins -= int(rest["price"])
		gs.combat.lines.append("You pay %s for the room." % Economy.format(db, int(rest["price"])))
	Combat.settle_fight(gs, db)
	var night := Night.run(gs, db, collapse, false, Rest.BED if collapse else String(rest["rest"]))
	_after(gs, db)
	return night


## Knocked unconscious: the fight ends (its records fail), and the day ends
## like a collapse; the player wakes at the normal time at a safe place.
static func knock_out(gs: GameState, db: DataDb) -> Dictionary:
	Combat.end_fight(gs, db, Combat.KNOCKED_OUT)
	var night := Night.run(gs, db, true, true)
	_after(gs, db)
	return night


static func accept_class(gs: GameState, db: DataDb, class_id: String) -> Array[String]:
	return ClassSystem.accept(gs, db, class_id)


static func decline_class(gs: GameState, db: DataDb, class_id: String) -> Array[String]:
	return ClassSystem.decline(gs, db, class_id)


## Journal focus ("I want to be an innkeeper"). Returns "" or an error text.
## An empty list clears the focus.
static func set_focus(gs: GameState, db: DataDb, tags: Array) -> String:
	for tag: Variant in tags:
		if not db.tags.has(tag):
			return "Unknown tag '%s'." % tag
	gs.focus_tags.assign(tags)
	return ""


## Debug / canon-event hook: lets a class pass its next capstone level.
static func grant_breakthrough(gs: GameState, class_id: String) -> bool:
	return ClassSystem.grant_breakthrough(gs, class_id)


## Debug (M17.4): gives the player skill `skill_id` (no class, today). Returns
## "" or an error text.
static func grant_skill(gs: GameState, db: DataDb, skill_id: String) -> String:
	if not db.skills.has(skill_id):
		return "Unknown skill '%s'." % skill_id
	if gs.progression.has_skill(skill_id):
		return "You already have %s." % String(db.skills[skill_id]["name"])
	gs.progression.skills.append({"id": skill_id, "class": "", "level": 0, "day": gs.clock.day()})
	return ""


## The player kills a canon NPC. Returns "" or an error text.
static func kill_npc(gs: GameState, db: DataDb, npc: String) -> String:
	var err := Director.player_kill(gs, db, npc)
	_after(gs, db)
	return err


## The player attacks the NPC `npc` next to them (M14.5, Brawl.attack). Returns {"error",
## "target", "warn", "hit", "damage", "killed"}; "warn" means the fate warning must be confirmed
## first (nothing happened): send it again with `confirmed` true. Works with enemies near.
static func attack_npc(gs: GameState, db: DataDb, npc: String, confirmed: bool = false) -> Dictionary:
	Combat.begin_command(gs)
	if Encounter.active(gs):
		var hit := func() -> Dictionary: return Brawl.attack(gs, db, npc, confirmed)
		return _encounter_act(gs, db, "attack_cost_q", hit,
				{"target": npc, "warn": false, "hit": false, "damage": 0, "killed": false}, Encounter.NPC)
	var r := Brawl.attack(gs, db, npc, confirmed)
	_after(gs, db)
	return r


## Sets a world flag (debug now; M4 interactions will call it). A false,
## 0 or null value clears the flag.
static func set_flag(gs: GameState, key: String, value: Variant = true) -> void:
	if not value:
		gs.flags.erase(key)
	else:
		gs.flags[key] = value


## Debug: adds coins (copper; negative takes, never below 0) and goods.
## Returns "" or an error text.
static func give(gs: GameState, db: DataDb, coins: int, good: String = "", count: int = 1) -> String:
	if good != "" and not db.economy.goods.has(good):
		return "Unknown good '%s'." % good
	gs.economy.coins = maxi(gs.economy.coins + coins, 0)
	if good != "":
		gs.economy.add(good, count)
	return ""


## One step on the world grid (n, s, e, w). See Movement.step. Stepping
## into a monster attacks it instead: the result then has "attack" (see
## Combat.player_attack). Stepping into a hidden monster (it looks like a
## rock) springs its ambush: the result has "ambush" (see MonsterSim.ambush).
## M13.T: a step (not through an exit) onto an armed trap springs it: the
## result has "sprung" (see Traps.on_step; {} if none). Walking into a found
## trap says so.
## M17.1 combat mode (Encounter): a step costs AP and counts against the move
## cap, and takes no time; walking into a seen monster is an attack for AP.
## When AP or the cap says no, nothing happens and the result has "error".
## M17.2: block, throw, take, drop, the bag and attack_npc cost AP too
## (rules.combat.tactical), and the turn ends by itself when the AP left pays
## for nothing.
static func move(gs: GameState, db: DataDb, dir: String) -> Dictionary:
	Combat.begin_command(gs)
	if Encounter.active(gs):
		return _encounter_move(gs, db, dir)
	var r := Movement.step(gs, db, dir)
	_after_step(gs, db, dir, r)
	_after(gs, db)
	return r


static func _after_step(gs: GameState, db: DataDb, dir: String, r: Dictionary) -> void:
	if r["fairy"] != "":
		Winter.swat(gs, db, r["fairy"])
	elif r["monster"] != "":
		if gs.combat.monsters[r["monster"]]["state"] == CombatState.HIDDEN:
			r["ambush"] = MonsterSim.ambush(gs, db, r["monster"])
		else:
			r["attack"] = Combat.player_attack(gs, db, dir)
	elif r["trap"] != "":
		gs.combat.lines.append(String(Traps.rules(db)["blocked_line"])
				% Traps.trap_of(gs, db, gs.player.area, r["trap"])["name"])
	elif r["moved"] and r["exit_to"] == "":
		r["sprung"] = Traps.on_step(gs, db)


static func _encounter_move(gs: GameState, db: DataDb, dir: String) -> Dictionary:
	var r := {"moved": false, "blocked": false, "refused": false, "exit_to": "", "minutes": 0,
		"npc": "", "monster": "", "fairy": "", "trap": "", "error": ""}
	if PlayerState.DIRS.has(dir):
		var foe := gs.combat.at(gs.player.area, gs.player.pos() + (PlayerState.DIRS[dir] as Vector2i))
		if foe != "" and gs.combat.monsters[foe]["state"] != CombatState.HIDDEN:
			r["blocked"] = true
			r["monster"] = foe
			r["attack"] = _encounter_attack(gs, db, dir)
			return r
	var cost := int(Encounter.rules(db)["move_cost_q"])
	var why := Encounter.check(gs, db, cost, true)
	if why != "":
		r["refused"] = true
		r["error"] = why
		gs.combat.lines.append(why)
		return r
	Encounter.log_begin(gs, Encounter.PLAYER)
	r.merge(Movement.step(gs, db, dir, false), true)
	if r["fairy"] != "":
		# M17.2: a swat is a swing (attack AP); free, a fairy in the way stalls the turn
		var atk := int(Encounter.rules(db)["attack_cost_q"])
		why = Encounter.check(gs, db, atk, false)
		if why != "":
			r["refused"] = true
			r["error"] = why
			gs.combat.lines.append(why)
			Encounter.log_end(gs)
			return r
		Encounter.pay(gs, atk, false)
	elif r["moved"]:
		Encounter.pay(gs, cost, true)
		if r["exit_to"] == "":
			Encounter.log_step(gs, gs.player.pos())
	_after_step(gs, db, dir, r)
	Encounter.log_end(gs)
	_after(gs, db)
	if r["moved"] or r["fairy"] != "":
		_auto_end(gs, db)
	return r


## Combat mode: an attack for attack_cost_q (see attack).
static func _encounter_attack(gs: GameState, db: DataDb, dir: String) -> Dictionary:
	var hit := func() -> Dictionary: return Combat.player_attack(gs, db, dir)
	return _encounter_act(gs, db, "attack_cost_q", hit,
			{"target": "", "hit": false, "damage": 0, "killed": false})


## Combat mode (M17.2): `act` (returns a result with "error") for the AP of
## rules.combat.tactical[`cost_key`]. Not the player's turn, or too little AP:
## nothing happens, the result is `empty` with that "error" (also in the log).
## Paid only when `act` worked (no "error", no fate "warn"); then the turn
## ends by itself if the AP left pays for nothing (Encounter.maybe_end_turn).
## M17.3: a blow (a result with "target" and "damage") goes into the turn log
## as the player's; `prefix` makes the target a fighter id (Encounter.NPC).
static func _encounter_act(gs: GameState, db: DataDb, cost_key: String, act: Callable,
		empty: Dictionary, prefix: String = "") -> Dictionary:
	return _encounter_act_q(gs, db, int(Encounter.rules(db)[cost_key]), cost_key == "throw_cost_q",
			act, empty, prefix)


## _encounter_act for `cost` q (M17.4: a Skill's ap_q). `ranged`: the logged
## blow is a throw.
static func _encounter_act_q(gs: GameState, db: DataDb, cost: int, ranged: bool, act: Callable,
		empty: Dictionary, prefix: String = "") -> Dictionary:
	var why := Encounter.check(gs, db, cost, false)
	if why != "":
		gs.combat.lines.append(why)
		var out := empty.duplicate()
		out["error"] = why
		return out
	Encounter.log_begin(gs, Encounter.PLAYER)
	var r: Dictionary = act.call()
	var paid: bool = r["error"] == "" and not r.get("warn", false)
	if paid:
		Encounter.pay(gs, cost, false)
		if String(r.get("target", "")) != "" and r.has("damage"):
			Encounter.log_strike(gs, prefix + String(r["target"]), int(r["damage"]), ranged)
	Encounter.log_end(gs)
	_after(gs, db)
	if paid:
		_auto_end(gs, db)
	return r


## Combat mode: an action that returns "" or an error text (see _encounter_act).
static func _encounter_do(gs: GameState, db: DataDb, cost_key: String, act: Callable) -> String:
	var wrap := func() -> Dictionary: return {"error": act.call()}
	return String(_encounter_act(gs, db, cost_key, wrap, {})["error"])


static func _auto_end(gs: GameState, db: DataDb) -> void:
	if Encounter.maybe_end_turn(gs, db):
		_after(gs, db)


## Stands still for `seconds`. Returns the minutes the clock moved, or -1
## if refused (see Movement.wait). In combat mode (M17.1) it ends the turn;
## -1 if there is no turn to end (knocked out).
static func wait(gs: GameState, db: DataDb, seconds: int) -> int:
	Combat.begin_command(gs)
	if Encounter.active(gs):
		var before := gs.clock.total_minutes
		var why := Encounter.end_player_turn(gs, db)
		_after(gs, db)
		return -1 if why != "" else gs.clock.total_minutes - before
	var minutes := Movement.wait(gs, db, seconds)
	_after(gs, db)
	return minutes


## Combat mode (M17.1): ends the player's turn; the others act and the next
## round starts. Returns "" or why not.
static func end_turn(gs: GameState, db: DataDb) -> String:
	Combat.begin_command(gs)
	var why := Encounter.end_player_turn(gs, db)
	_after(gs, db)
	return why


## Uses a nearby map object or talks to a nearby NPC. Returns
## {"record", "error"} (see Interact.perform). Refused while knocked out or
## with enemies near.
static func interact(gs: GameState, db: DataDb, object_id: String, action_id: String,
		opts: Dictionary = {}) -> Dictionary:
	Combat.begin_command(gs)
	var why := Combat.refusal(gs)
	if why != "":
		return {"record": {}, "error": why}
	var r := Interact.perform(gs, db, object_id, action_id, opts)
	Combat.heal_after_action(gs, db, r["record"])
	Economy.after_action(gs, db, r["record"], object_id)
	Cooking.after_action(gs, db, r["record"], object_id)
	_after(gs, db)
	return r


## Buys one `good` at the nearby shop object `object_id` (M8.6). Returns
## {"record", "error"}; what happened is in gs.combat.lines.
static func buy(gs: GameState, db: DataDb, object_id: String, good: String) -> Dictionary:
	return _shop_command(gs, db, func() -> Dictionary: return Economy.buy(gs, db, object_id, good))


## Sells one `good` from the bag at the nearby shop object `object_id`.
static func sell(gs: GameState, db: DataDb, object_id: String, good: String) -> Dictionary:
	return _shop_command(gs, db, func() -> Dictionary: return Economy.sell(gs, db, object_id, good))


## Eats or drinks a good from the bag (Economy.use_good). Returns "" or an error.
static func use_good(gs: GameState, db: DataDb, good: String) -> String:
	Combat.begin_command(gs)
	var why := Combat.refusal(gs)
	if why == "":
		why = Economy.use_good(gs, db, good)
	_after(gs, db)
	return why


## Bag screen (M14.0): a tool good from the bag into the hand
## (Economy.hold_good). Works with enemies near. Returns "" or an error.
static func hold_good(gs: GameState, db: DataDb, good: String) -> String:
	return _bag_command(gs, db, func() -> String: return Economy.hold_good(gs, db, good))


## Bag screen: the held item into the bag (Economy.stow). Returns "" or an error.
static func stow(gs: GameState, db: DataDb) -> String:
	return _bag_command(gs, db, func() -> String: return Economy.stow(gs, db))


## Bag screen: leaves one `good` behind (Economy.drop_good). Returns "" or an error.
static func drop_good(gs: GameState, db: DataDb, good: String) -> String:
	return _bag_command(gs, db, func() -> String: return Economy.drop_good(gs, db, good))


static func _bag_command(gs: GameState, db: DataDb, act: Callable) -> String:
	Combat.begin_command(gs)
	if Encounter.active(gs):
		var checked := func() -> String:
			var err := Combat.cannot_act(gs, db)
			return err if err != "" else String(act.call())
		return _encounter_do(gs, db, "item_cost_q", checked)
	var why := Combat.cannot_act(gs, db)
	if why == "":
		why = act.call()
	_after(gs, db)
	return why


## Takes the paid ride of the nearby object `object_id` (Economy.ride).
## Returns "" or an error.
static func ride(gs: GameState, db: DataDb, object_id: String) -> String:
	Combat.begin_command(gs)
	var why := Combat.refusal(gs)
	if why == "":
		why = Economy.ride(gs, db, object_id)
	_after(gs, db)
	return why


## Steps through the nearby magic door `object_id` (M10.0, Portal). Returns
## "" or why not. Refused while knocked out or with enemies near.
static func portal(gs: GameState, db: DataDb, object_id: String) -> String:
	Combat.begin_command(gs)
	var why := Combat.refusal(gs)
	if why == "":
		why = Portal.use(gs, db, object_id)
	_after(gs, db)
	return why


static func _shop_command(gs: GameState, db: DataDb, trade: Callable) -> Dictionary:
	Combat.begin_command(gs)
	var why := Combat.refusal(gs)
	if why != "":
		return {"record": {}, "error": why}
	var r: Dictionary = trade.call()
	_after(gs, db)
	return r


## Serves `good` from the bag to the guest `target` next to the player
## ("guest:<id>" for a patron, or a canon NPC id; M14.2, Guests.serve).
## Returns {"record", "error"}. Refused while knocked out or with enemies near.
static func serve(gs: GameState, db: DataDb, target: String, good: String) -> Dictionary:
	Combat.begin_command(gs)
	var why := Combat.refusal(gs)
	if why != "":
		return {"record": {}, "error": why}
	var r := Guests.serve(gs, db, target, good)
	Combat.heal_after_action(gs, db, r["record"])
	_after(gs, db)
	return r


## Attacks the monster next to the player in `dir`. Returns
## {"error", "target", "hit", "damage", "killed"} (see Combat.player_attack).
static func attack(gs: GameState, db: DataDb, dir: String) -> Dictionary:
	Combat.begin_command(gs)
	if Encounter.active(gs):
		return _encounter_attack(gs, db, dir)
	var r := Combat.player_attack(gs, db, dir)
	_after(gs, db)
	return r


## M17.4: uses the player's combat Skill `skill_id` on monster `target` (a
## strike's foe; "" for area and self Skills) for its ap_q. Only in a fight,
## on the player's turn. Returns CombatSkills.use's result, or {"error"}.
static func use_skill(gs: GameState, db: DataDb, skill_id: String, target: String = "") -> Dictionary:
	Combat.begin_command(gs)
	var empty := {"error": "", "skill": skill_id, "strikes": [], "healed": 0, "move_q": 0}
	var why := CombatSkills.why_not(gs, db, skill_id, target)
	if why != "":
		gs.combat.lines.append(why)
		empty["error"] = why
		return empty
	var cost := int(CombatSkills.action_of(db, skill_id)["ap_q"])
	var act := func() -> Dictionary: return CombatSkills.use(gs, db, skill_id, target)
	return _encounter_act_q(gs, db, cost, false, act, empty)


## Raises the guard for one turn. Returns "" or an error text.
static func block(gs: GameState, db: DataDb) -> String:
	Combat.begin_command(gs)
	if Encounter.active(gs):
		return _encounter_do(gs, db, "block_cost_q", func() -> String: return Combat.block(gs, db))
	var err := Combat.block(gs, db)
	_after(gs, db)
	return err


## Throws the held item at monster `target_id`. Returns
## {"error", "target", "hit", "damage", "killed"} (see Combat.throw_at).
static func throw(gs: GameState, db: DataDb, target_id: String) -> Dictionary:
	Combat.begin_command(gs)
	if Encounter.active(gs):
		var hit := func() -> Dictionary: return Combat.throw_at(gs, db, target_id)
		return _encounter_act(gs, db, "throw_cost_q", hit,
				{"target": target_id, "hit": false, "damage": 0, "killed": false})
	var r := Combat.throw_at(gs, db, target_id)
	_after(gs, db)
	return r


## Takes the item of a nearby map object (Interact.TAKE). A held item is
## put down first. Works with enemies near. Returns "" or an error text.
static func take(gs: GameState, db: DataDb, object_id: String) -> String:
	Combat.begin_command(gs)
	if Encounter.active(gs):
		return _encounter_do(gs, db, "item_cost_q", func() -> String: return Combat.take(gs, db, object_id))
	var err := Combat.take(gs, db, object_id)
	_after(gs, db)
	return err


## Puts the held item down. Returns "" or an error text.
static func drop(gs: GameState, db: DataDb) -> String:
	Combat.begin_command(gs)
	if Encounter.active(gs):
		return _encounter_do(gs, db, "item_cost_q", func() -> String: return Combat.drop(gs, db))
	var err := Combat.drop(gs, db)
	_after(gs, db)
	return err


## Debug: puts a hostile monster of `type` on the free tile `pos` in the
## player's area. Moves no time. Returns {"id", "error"}.
static func spawn_monster(gs: GameState, db: DataDb, type: String, pos: Vector2i) -> Dictionary:
	if not db.combat.enemies.has(type):
		return {"id": "", "error": "Unknown enemy '%s'." % type}
	var area := gs.player.area
	if not db.maps.is_walkable(area, pos) or pos == gs.player.pos() \
			or gs.npcs.at(area, pos) != "" or gs.combat.at(area, pos) != "":
		return {"id": "", "error": "That tile is not free."}
	return {"id": Combat.add_monster(gs, db, type, pos), "error": ""}


## Makes a loaded game ready to show: places the player (a migrated v3
## save) and the NPCs (a migrated v4 save). Moves no time.
static func settle(gs: GameState, db: DataDb) -> void:
	Movement.ensure_placed(gs, db)
	_after(gs, db)


static func _after(gs: GameState, db: DataDb) -> void:
	db.maps.sync_flags(gs.flags)
	Combat.sync(gs, db)
	NpcSim.sync(gs, db)
	Winter.sync(gs, db)
	Combat.settle_if_over(gs, db)
	Guests.sync(gs, db)
	Encounter.sync(gs, db)
