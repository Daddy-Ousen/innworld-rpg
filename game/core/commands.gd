## The commands presentation may send. UI and console call only these;
## they never change GameState directly (CLAUDE.md rule 1). Every command
## that moves the clock then runs _after: the monsters' turn and fight
## bookkeeping (Combat.sync), then the NPCs (NpcSim.sync). Combat text of
## the last command is in gs.combat.lines.
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
	_after(gs, db)
	return rec


## Ends the day. If the player is past the awake limit, this is a collapse.
## Knocked out, or a collapse with enemies near: a knock-out (see knock_out).
## With enemies near otherwise: refused, returns {} (the reason is in
## gs.combat.lines).
static func sleep(gs: GameState, db: DataDb) -> Dictionary:
	Combat.begin_command(gs)
	var collapse := gs.clock.is_collapse_due(db.rules["clock"])
	if Combat.is_down(gs) or (collapse and Combat.in_danger(gs)):
		return knock_out(gs, db)
	if Combat.in_danger(gs):
		gs.combat.lines.append(Combat.REFUSED_DANGER)
		return {}
	Combat.settle_fight(gs, db)
	var night := Night.run(gs, db, collapse)
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


## The player kills a canon NPC. Returns "" or an error text.
static func kill_npc(gs: GameState, db: DataDb, npc: String) -> String:
	var err := Director.player_kill(gs, db, npc)
	_after(gs, db)
	return err


## Sets a world flag (debug now; M4 interactions will call it). A false,
## 0 or null value clears the flag.
static func set_flag(gs: GameState, key: String, value: Variant = true) -> void:
	if not value:
		gs.flags.erase(key)
	else:
		gs.flags[key] = value


## One step on the world grid (n, s, e, w). See Movement.step. Stepping
## into a monster attacks it instead: the result then has "attack" (see
## Combat.player_attack).
static func move(gs: GameState, db: DataDb, dir: String) -> Dictionary:
	Combat.begin_command(gs)
	var r := Movement.step(gs, db, dir)
	if r["monster"] != "":
		r["attack"] = Combat.player_attack(gs, db, dir)
	_after(gs, db)
	return r


## Stands still for `seconds`. Returns the minutes the clock moved, or -1
## if refused (see Movement.wait).
static func wait(gs: GameState, db: DataDb, seconds: int) -> int:
	Combat.begin_command(gs)
	var minutes := Movement.wait(gs, db, seconds)
	_after(gs, db)
	return minutes


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
	_after(gs, db)
	return r


## Attacks the monster next to the player in `dir`. Returns
## {"error", "target", "hit", "damage", "killed"} (see Combat.player_attack).
static func attack(gs: GameState, db: DataDb, dir: String) -> Dictionary:
	Combat.begin_command(gs)
	var r := Combat.player_attack(gs, db, dir)
	_after(gs, db)
	return r


## Raises the guard for one turn. Returns "" or an error text.
static func block(gs: GameState, db: DataDb) -> String:
	Combat.begin_command(gs)
	var err := Combat.block(gs, db)
	_after(gs, db)
	return err


## Throws the held item at monster `target_id`. Returns
## {"error", "target", "hit", "damage", "killed"} (see Combat.throw_at).
static func throw(gs: GameState, db: DataDb, target_id: String) -> Dictionary:
	Combat.begin_command(gs)
	var r := Combat.throw_at(gs, db, target_id)
	_after(gs, db)
	return r


## Puts the held item down. Returns "" or an error text.
static func drop(gs: GameState, db: DataDb) -> String:
	Combat.begin_command(gs)
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
	Combat.sync(gs, db)
	NpcSim.sync(gs, db)
