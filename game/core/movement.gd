## Grid movement (ADR 0006). One step moves one tile and costs
## rules.world.step_seconds; the clock moves in whole minutes, the rest
## waits in PlayerState.sub_seconds. Stepping onto an exit travels to the
## next map: a "travel" action for the exit's minutes (none for 0 minutes).
class_name Movement
extends RefCounted


## Puts an unplaced player (a migrated v3 save) at the first start.
## Returns false if the db has no maps.
static func ensure_placed(gs: GameState, db: DataDb) -> bool:
	if gs.player.is_placed():
		return true
	if db.maps.is_empty():
		return false
	place_at_start(gs, start_of(db))
	return true


## The start in rules.world.starts with this id (M8.5): {"id", "name",
## "area", "pos", "intro"}. "" gives the first start (the default); an
## unknown id gives {}.
static func start_of(db: DataDb, id: String = "") -> Dictionary:
	var starts: Array = db.rules.get("world", {}).get("starts", [])
	for s: Dictionary in starts:
		if id == "" or s["id"] == id:
			return s
	return {}


static func place_at_start(gs: GameState, start: Dictionary) -> void:
	gs.player.place(start["area"], Vector2i(int(start["pos"][0]), int(start["pos"][1])))


## Tries one step in `dir` (n, s, e, w). Returns
## {"moved": bool, "blocked": bool, "refused": bool, "exit_to": area or "", "minutes": int,
##  "npc": id of the NPC in the way or "", "monster": id of the monster in the way or "",
##  "fairy": id of the Frost Fairy in the way or "" (M8.W)}.
## refused: collapse is due, the player is knocked out, or there is no world.
## blocked: a wall, water, a solid object, an NPC, a monster, a fairy or the
## map edge. The player still turns to face `dir`. While slowed by fairy
## snow (M8.W), a step costs double time.
static func step(gs: GameState, db: DataDb, dir: String) -> Dictionary:
	var out := {"moved": false, "blocked": false, "refused": false, "exit_to": "", "minutes": 0,
		"npc": "", "monster": "", "fairy": ""}
	db.maps.sync_flags(gs.flags)
	if not PlayerState.DIRS.has(dir) or not ensure_placed(gs, db) \
			or gs.clock.is_collapse_due(db.rules["clock"]) or gs.player.hp == 0:
		out["refused"] = true
		return out
	var p := gs.player
	p.facing = dir
	var to := p.pos() + (PlayerState.DIRS[dir] as Vector2i)
	out["npc"] = gs.npcs.at(p.area, to)
	out["monster"] = gs.combat.at(p.area, to)
	if gs.winter.area == p.area:
		out["fairy"] = gs.winter.at(to)
	if not db.maps.is_walkable(p.area, to) or out["npc"] != "" or out["monster"] != "" \
			or out["fairy"] != "":
		out["blocked"] = true
		return out
	var e := db.maps.exit_at(p.area, to)
	if not e.is_empty() and int(e["minutes"]) > 0:
		var before := gs.clock.total_minutes
		if not _travel(gs, db, e):
			out["refused"] = true
			return out
		out["minutes"] = gs.clock.total_minutes - before
	else:
		out["minutes"] = _spend_seconds(gs, Winter.step_seconds(gs, int(db.rules["world"]["step_seconds"])))
	if e.is_empty():
		p.place(p.area, to)
	else:
		p.place(e["to"], MapDb.arrival(e, to))
		out["exit_to"] = e["to"]
	out["moved"] = true
	return out


## Zone id at the player's tile, or the map's canon location.
static func location_at(gs: GameState, db: DataDb) -> String:
	if not ensure_placed(gs, db):
		return ""
	var zone := db.maps.zone_at(gs.player.area, gs.player.pos())
	return zone if zone != "" else String(db.maps.areas[gs.player.area]["location"])


## Stands still for `seconds` (the world goes on). Returns the whole
## minutes the clock moved, or -1 if refused (collapse is due, knocked out,
## or seconds < 0).
static func wait(gs: GameState, db: DataDb, seconds: int) -> int:
	if seconds < 0 or gs.clock.is_collapse_due(db.rules["clock"]) or gs.player.hp == 0:
		return -1
	return _spend_seconds(gs, seconds)


## Spends one turn (a step's time) standing where you are: combat
## commands. Returns the whole minutes the clock moved.
static func spend_turn(gs: GameState, db: DataDb) -> int:
	return _spend_step(gs, db)


static func _spend_step(gs: GameState, db: DataDb) -> int:
	return _spend_seconds(gs, int(db.rules["world"]["step_seconds"]))


static func _spend_seconds(gs: GameState, seconds: int) -> int:
	var p := gs.player
	p.sub_seconds += seconds
	@warning_ignore("integer_division")
	var minutes := p.sub_seconds / 60
	p.sub_seconds %= 60
	gs.clock.advance(minutes)
	return minutes


## Travel XP is scaled by the trip's share of a full travel action
## (intensity, clamped to the XP rules' minimum).
static func _travel(gs: GameState, db: DataDb, e: Dictionary) -> bool:
	var minutes := int(e["minutes"])
	var full := int(db.actions["travel"]["minutes"])
	var rec := Actions.perform(gs, db, "travel", {
		"minutes": minutes,
		"intensity": float(minutes) / float(full),
		"context": {"from": gs.player.area, "to": e["to"]},
	})
	return not rec.is_empty()
