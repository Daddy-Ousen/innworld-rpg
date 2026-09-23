## The commands presentation may send. UI and console call only these;
## they never change GameState directly (CLAUDE.md rule 1).
class_name Commands
extends RefCounted


## Does an action. Returns the record, or {} if refused (see Actions.perform).
static func perform(gs: GameState, db: DataDb, action_id: String, opts: Dictionary = {}) -> Dictionary:
	return Actions.perform(gs, db, action_id, opts)


## Ends the day. If the player is past the awake limit, this is a collapse.
static func sleep(gs: GameState, db: DataDb) -> Dictionary:
	return Night.run(gs, db, gs.clock.is_collapse_due(db.rules["clock"]))


## Knocked unconscious: the day ends like a collapse.
static func knock_out(gs: GameState, db: DataDb) -> Dictionary:
	return Night.run(gs, db, true)


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
	return Director.player_kill(gs, db, npc)


## Sets a world flag (debug now; M4 interactions will call it). A false,
## 0 or null value clears the flag.
static func set_flag(gs: GameState, key: String, value: Variant = true) -> void:
	if not value:
		gs.flags.erase(key)
	else:
		gs.flags[key] = value


## One step on the world grid (n, s, e, w). See Movement.step.
static func move(gs: GameState, db: DataDb, dir: String) -> Dictionary:
	return Movement.step(gs, db, dir)


## Uses a nearby map object. Returns {"record", "error"} (see Interact.perform).
static func interact(gs: GameState, db: DataDb, object_id: String, action_id: String,
		opts: Dictionary = {}) -> Dictionary:
	return Interact.perform(gs, db, object_id, action_id, opts)
