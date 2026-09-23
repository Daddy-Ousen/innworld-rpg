## Upgrades old save dictionaries to the current GameState.SAVE_VERSION.
## Add one step per schema change: _migrate_1_to_2, _migrate_2_to_3, ...
class_name SaveMigrations
extends RefCounted


## Returns the migrated dictionary, or an empty dictionary if the save
## cannot be loaded (missing or newer version).
static func migrate(data: Dictionary) -> Dictionary:
	if not data.has("save_version"):
		push_error("Save has no save_version.")
		return {}
	var version := int(data["save_version"])
	if version > GameState.SAVE_VERSION:
		push_error("Save version %d is newer than supported %d." % [version, GameState.SAVE_VERSION])
		return {}
	var out := data.duplicate(true)
	# while version < GameState.SAVE_VERSION:
	# 	match version:
	# 		1: out = _migrate_1_to_2(out)
	# 	version += 1
	out["save_version"] = GameState.SAVE_VERSION
	return out
