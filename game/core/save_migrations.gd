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
	while version < GameState.SAVE_VERSION:
		match version:
			1: out = _migrate_1_to_2(out)
			2: out = _migrate_2_to_3(out)
			3: out = _migrate_3_to_4(out)
			4: out = _migrate_4_to_5(out)
			5: out = _migrate_5_to_6(out)
			6: out = _migrate_6_to_7(out)
			7: out = _migrate_7_to_8(out)
			8: out = _migrate_8_to_9(out)
			9: out = _migrate_9_to_10(out)
		version += 1
	out["save_version"] = GameState.SAVE_VERSION
	return out


## v2 (M1 part 2): race, flags, progression (classes, skills, offers) and
## the morning summary. A v1 save is an Earther with no class yet.
static func _migrate_1_to_2(d: Dictionary) -> Dictionary:
	d["race"] = "human"
	d["flags"] = {}
	d["progression"] = {"day_start": int(d["clock"]["total_minutes"])}
	d["morning"] = []
	return d


## v3 (M3): the world director's state. A v2 save has a world where no
## canon event has run yet; the director catches up on the next night.
static func _migrate_2_to_3(d: Dictionary) -> Dictionary:
	d["world"] = {}
	return d


## v4 (M4.2): the player's place on the world grid. A v3 save has a player
## who is not placed yet; Movement puts them at rules.world.start.
static func _migrate_3_to_4(d: Dictionary) -> Dictionary:
	d["player"] = {}
	return d


## v5 (M4.4): NPCs on the world grid. A v4 save has no NPCs yet; NpcSim
## puts them at their goal spots on the next command. v5 also writes floats
## as exact f64 text (SaveCodec); plain numbers in old saves still load.
static func _migrate_4_to_5(d: Dictionary) -> Dictionary:
	d["npcs"] = {}
	return d


## v6 (M5.1): hit points, the held item and combat (monsters, the fight).
## A v5 save has a player at full HP holding nothing, and no monsters.
static func _migrate_5_to_6(d: Dictionary) -> Dictionary:
	var player: Dictionary = d["player"]
	player["hp"] = -1
	player["held"] = ""
	d["combat"] = {}
	return d


## v7 (M6.4): action records keep their context (canon event hooks match
## on it), and the world keeps the news the player heard. Old records get
## an empty context; a v6 save has heard no news.
static func _migrate_6_to_7(d: Dictionary) -> Dictionary:
	for r: Dictionary in d["action_log"].get("records", []):
		if not r.has("context"):
			r["context"] = {}
	(d["world"] as Dictionary)["news"] = []
	return d


## v8 (M6.5): canon fights on the map. The world notes the events it
## staged (none in a v7 save); a monster notes its stage event ("" = none).
static func _migrate_7_to_8(d: Dictionary) -> Dictionary:
	(d["world"] as Dictionary)["staged"] = {}
	for m: Dictionary in (d["combat"] as Dictionary).get("monsters", {}).values():
		m["stage"] = ""
	return d


## v9 (M7.B): big battles. NPCs have hit points (full) and are not down;
## the fight has no staged waves in progress.
static func _migrate_8_to_9(d: Dictionary) -> Dictionary:
	for n: Dictionary in (d["npcs"] as Dictionary).get("npcs", {}).values():
		n["hp"] = -1
		n["down"] = false
	(d["combat"] as Dictionary)["stage_run"] = {}
	return d

## v10 (M8.W): winter. No cold felt yet and no Frost Fairies about.
static func _migrate_9_to_10(d: Dictionary) -> Dictionary:
	d["winter"] = {}
	return d
