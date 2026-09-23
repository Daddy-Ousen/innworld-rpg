## The single source of truth for all game state.
## Anything not stored here does not exist after a load.
class_name GameState
extends RefCounted

const SAVE_VERSION := 1

var save_version: int = SAVE_VERSION
var rng: Rng
## Placeholder bag for M0. Real typed fields arrive in M1.
var data: Dictionary = {}


func _init(seed_value: int = 0) -> void:
	rng = Rng.new(seed_value)


func to_dict() -> Dictionary:
	return {
		"save_version": save_version,
		"rng": rng.to_dict(),
		"data": data.duplicate(true),
	}


static func from_dict(d: Dictionary) -> GameState:
	var gs := GameState.new()
	gs.save_version = int(d["save_version"])
	gs.rng = Rng.from_dict(d["rng"])
	gs.data = (d.get("data", {}) as Dictionary).duplicate(true)
	return gs


func to_json() -> String:
	return JSON.stringify(to_dict(), "\t")


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
