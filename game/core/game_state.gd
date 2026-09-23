## The single source of truth for all game state.
## Anything not stored here does not exist after a load.
class_name GameState
extends RefCounted

const SAVE_VERSION := 3

var save_version: int = SAVE_VERSION
var rng: Rng
var clock: Clock
var action_log: ActionLog
## Tags of the focus the player declared in the journal (conviction bonus).
var focus_tags: Array[String] = []
## The player's race (class race_limits). Earthers are human.
var race: String = "human"
## World flags (class prereqs, canon events). flag → value.
var flags: Dictionary = {}
## Classes, levels, skills, offers, blacklist.
var progression: Progression
## System messages from the last night, shown in the morning.
var morning: Array[String] = []
## Canon events, NPC fates, history and drift (world director).
var world: WorldState


func _init(seed_value: int = 0) -> void:
	rng = Rng.new(seed_value)
	clock = Clock.new()
	action_log = ActionLog.new()
	progression = Progression.new()
	world = WorldState.new()


## A fresh game at the start time from data/rules.json.
static func new_game(seed_value: int, db: DataDb) -> GameState:
	var gs := GameState.new(seed_value)
	gs.clock = Clock.new(int(db.rules["clock"]["start_minute"]))
	gs.progression.day_start = gs.clock.total_minutes
	return gs


func to_dict() -> Dictionary:
	return {
		"save_version": save_version,
		"rng": rng.to_dict(),
		"clock": clock.to_dict(),
		"action_log": action_log.to_dict(),
		"focus_tags": focus_tags.duplicate(),
		"race": race,
		"flags": flags.duplicate(true),
		"progression": progression.to_dict(),
		"morning": morning.duplicate(),
		"world": world.to_dict(),
	}


static func from_dict(d: Dictionary) -> GameState:
	var gs := GameState.new()
	gs.save_version = int(d["save_version"])
	gs.rng = Rng.from_dict(d["rng"])
	gs.clock = Clock.from_dict(d["clock"])
	gs.action_log = ActionLog.from_dict(d["action_log"])
	gs.focus_tags.assign(d.get("focus_tags", []))
	gs.race = d["race"]
	gs.flags = (d["flags"] as Dictionary).duplicate(true)
	gs.progression = Progression.from_dict(d["progression"])
	gs.morning.assign(d["morning"])
	gs.world = WorldState.from_dict(d["world"])
	return gs


## Keeps key order and full float precision, so a loaded game plays on
## exactly like the one that was saved.
func to_json() -> String:
	return JSON.stringify(to_dict(), "\t", false, true)


## Returns null if the text is not valid JSON or the save cannot be migrated.
static func from_json(text: String) -> GameState:
	var json := JSON.new()
	var parsed: Variant = json.data if json.parse(text) == OK else null
	if not parsed is Dictionary:
		push_error("Save is not a JSON object.")
		return null
	var migrated := SaveMigrations.migrate(parsed)
	if migrated.is_empty():
		return null
	return GameState.from_dict(migrated)


func save_to_file(path: String) -> Error:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(to_json())
	f.close()
	return OK


static func load_from_file(path: String) -> GameState:
	if not FileAccess.file_exists(path):
		push_error("Save file not found: %s" % path)
		return null
	return GameState.from_json(FileAccess.get_file_as_string(path))
