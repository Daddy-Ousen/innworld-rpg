## The single source of truth for all game state.
## Anything not stored here does not exist after a load.
class_name GameState
extends RefCounted

const SAVE_VERSION := 13

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
## Where the player is on the world grid.
var player: PlayerState
## Where the NPCs are and what they are doing (M4.4).
var npcs: NpcRoster
## Monsters in the player's area and the fight in progress (M5).
var combat: CombatState
## The cold and the Frost Fairies (M8.W).
var winter: WinterState
## Coins, goods and hunger (M8.6).
var economy: EconomyState


func _init(seed_value: int = 0) -> void:
	rng = Rng.new(seed_value)
	clock = Clock.new()
	action_log = ActionLog.new()
	progression = Progression.new()
	world = WorldState.new()
	player = PlayerState.new()
	npcs = NpcRoster.new()
	combat = CombatState.new()
	winter = WinterState.new()
	economy = EconomyState.new()


## A fresh game at the start time from data/rules.json, at the start place
## `start_id` of rules.world.starts (M8.5; "" or an unknown id = the first).
## The director first runs the canon days before the player arrives (ADR
## 0006), so that history exists; its rumors and news are not heard.
static func new_game(seed_value: int, db: DataDb, start_id: String = "") -> GameState:
	var gs := GameState.new(seed_value)
	gs.clock = Clock.new(int(db.rules["clock"]["start_minute"]))
	gs.progression.day_start = gs.clock.total_minutes
	gs.economy.fed_day = gs.clock.day()
	Director.run(gs, db, gs.clock.day() - 1)
	gs.world.news.clear()
	db.maps.sync_flags(gs.flags)
	var start := Movement.start_of(db, start_id)
	if not start.is_empty() and not db.maps.is_empty():
		Movement.place_at_start(gs, start)
	Movement.ensure_placed(gs, db)
	Combat.sync(gs, db)
	NpcSim.sync(gs, db)
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
		"player": player.to_dict(),
		"npcs": npcs.to_dict(),
		"combat": combat.to_dict(),
		"winter": winter.to_dict(),
		"economy": economy.to_dict(),
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
	gs.player = PlayerState.from_dict(d["player"])
	gs.npcs = NpcRoster.from_dict(d["npcs"])
	gs.combat = CombatState.from_dict(d["combat"])
	gs.winter = WinterState.from_dict(d["winter"])
	gs.economy = EconomyState.from_dict(d["economy"])
	return gs


## Keeps key order, and floats as exact f64 text (SaveCodec), so a loaded
## game plays on exactly like the one that was saved.
func to_json() -> String:
	return JSON.stringify(SaveCodec.encode(to_dict()), "\t", false)


## Returns null if the text is not valid JSON or the save cannot be migrated.
static func from_json(text: String) -> GameState:
	var json := JSON.new()
	var parsed: Variant = json.data if json.parse(text) == OK else null
	if not parsed is Dictionary:
		push_error("Save is not a JSON object.")
		return null
	var migrated := SaveMigrations.migrate(SaveCodec.decode(parsed))
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
