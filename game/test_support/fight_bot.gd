## Test helper for fights in combat mode (M17.2, ADR 0027). A sim sends its
## fight commands through act(), so one loop works in combat mode (AP, turns)
## and in world time (toy dbs): a command that combat mode refuses for AP,
## the move cap or the turn ends the player's turn, then runs once more.
## Not a test script itself (GUT skips scripts that do not extend GutTest).
class_name FightBot
extends RefCounted


## Runs `cmd` (sends one command; returns its String error or its result
## Dictionary with "error"). See the class note. Returns the last result.
static func act(gs: GameState, db: DataDb, cmd: Callable) -> Variant:
	var r: Variant = cmd.call()
	_note(gs)
	if Encounter.active(gs) and Encounter.TURN_REFUSALS.has(error_of(r)):
		Commands.end_turn(gs, db)
		_note(gs)
		r = cmd.call()
		_note(gs)
	return r


## M17.7: every command clears the combat lines, and act() may send two; a test that
## must see each line (a wave's text) sets `sink_on` and reads `sink`.
static var sink_on := false
static var sink: Array[String] = []


static func _note(gs: GameState) -> void:
	if sink_on:
		sink.append_array(gs.combat.lines)


## Lets `seconds` of world time pass: one wait, or in a fight, ended turns
## (a round is round_seconds) until they have passed. Stops early when a wait
## is refused (knocked out).
static func wait_seconds(gs: GameState, db: DataDb, seconds: int) -> void:
	var until := NpcSim.world_sec(gs) + seconds
	for i in seconds + 1:
		var left := until - NpcSim.world_sec(gs)
		if left <= 0 or Commands.wait(gs, db, left) < 0:
			return


## One step (or an attack, walking into a monster) through act().
static func move(gs: GameState, db: DataDb, dir: String) -> Dictionary:
	return act(gs, db, func() -> Dictionary: return Commands.move(gs, db, dir))


## One attack through act().
static func attack(gs: GameState, db: DataDb, dir: String) -> Dictionary:
	return act(gs, db, func() -> Dictionary: return Commands.attack(gs, db, dir))


## One throw through act().
static func throw(gs: GameState, db: DataDb, id: String) -> Dictionary:
	return act(gs, db, func() -> Dictionary: return Commands.throw(gs, db, id))


## One block through act().
static func block(gs: GameState, db: DataDb) -> String:
	return act(gs, db, func() -> String: return Commands.block(gs, db))


## One attack on NPC `npc` through act().
static func attack_npc(gs: GameState, db: DataDb, npc: String, confirmed: bool = true) -> Dictionary:
	return act(gs, db, func() -> Dictionary: return Commands.attack_npc(gs, db, npc, confirmed))


## The error of a command result (a String, or a Dictionary's "error"; a
## step that became an attack: that attack's error).
static func error_of(r: Variant) -> String:
	if r is String:
		return r
	if r is Dictionary:
		var d := r as Dictionary
		if String(d.get("error", "")) == "" and d.get("attack") is Dictionary:
			return String((d["attack"] as Dictionary).get("error", ""))
		return String(d.get("error", ""))
	return ""
