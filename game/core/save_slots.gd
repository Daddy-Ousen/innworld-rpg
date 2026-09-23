## Save slots on disk (M6.1, ADR 0011): three manual slots and one
## autosave, each a GameState JSON file in one folder. Headless; the
## folder is a parameter so tests use their own.
class_name SaveSlots
extends RefCounted

const DEFAULT_DIR := "user://saves"
const AUTOSAVE := "autosave"
const MANUAL: Array[String] = ["1", "2", "3"]


## Manual slots first, then the autosave.
static func all() -> Array[String]:
	var out: Array[String] = MANUAL.duplicate()
	out.append(AUTOSAVE)
	return out


static func path(dir: String, slot: String) -> String:
	return dir.path_join("autosave.json" if slot == AUTOSAVE else "slot_%s.json" % slot)


static func exists(dir: String, slot: String) -> bool:
	return FileAccess.file_exists(path(dir, slot))


static func save(gs: GameState, dir: String, slot: String) -> Error:
	var err := DirAccess.make_dir_recursive_absolute(dir)
	if err != OK:
		return err
	return gs.save_to_file(path(dir, slot))


## The saved game, placed and synced (Commands.settle), or null if the slot
## is empty or the save cannot be read.
static func load_game(dir: String, slot: String, db: DataDb) -> GameState:
	if not exists(dir, slot):
		return null
	var gs := GameState.load_from_file(path(dir, slot))
	if gs != null:
		Commands.settle(gs, db)
	return gs


static func delete(dir: String, slot: String) -> void:
	if exists(dir, slot):
		DirAccess.remove_absolute(path(dir, slot))


## {"slot", "exists", "ok", "day", "time", "minutes", "place", "modified"}.
## "ok" is false for a file that cannot be read.
static func info(dir: String, slot: String, db: DataDb) -> Dictionary:
	var out := {"slot": slot, "exists": exists(dir, slot), "ok": false, "day": 0, "time": "",
		"minutes": 0, "place": "", "modified": 0}
	if not out["exists"]:
		return out
	out["modified"] = FileAccess.get_modified_time(path(dir, slot))
	var gs := GameState.load_from_file(path(dir, slot))
	if gs == null:
		return out
	out["ok"] = true
	out["day"] = gs.clock.day()
	out["time"] = gs.clock.time_string()
	out["minutes"] = gs.clock.total_minutes
	out["place"] = String(db.maps.areas.get(gs.player.area, {}).get("name", gs.player.area))
	return out


## "Slot 1 — Day 9, 14:20, The Wandering Inn" or "Slot 2 — empty".
static func label(i: Dictionary) -> String:
	var name := "Autosave" if i["slot"] == AUTOSAVE else "Slot %s" % i["slot"]
	if not i["exists"]:
		return "%s — empty" % name
	if not i["ok"]:
		return "%s — cannot be read" % name
	return "%s — Day %d, %s, %s" % [name, int(i["day"]), i["time"], i["place"]]


## The slot to continue from: the newest readable save (file time, then
## game time, then slot order). "" if there is none.
static func latest(dir: String, db: DataDb) -> String:
	var best := {}
	for slot: String in all():
		var i := info(dir, slot, db)
		if not i["ok"]:
			continue
		if best.is_empty() or int(i["modified"]) > int(best["modified"]) \
				or (int(i["modified"]) == int(best["modified"]) and int(i["minutes"]) > int(best["minutes"])):
			best = i
	return "" if best.is_empty() else String(best["slot"])
