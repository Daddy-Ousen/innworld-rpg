## Moves the NPCs through their day (M4.4, ADR 0008). Each NPC follows the
## goal UtilityAi picks. Level of detail:
##   - In the player's area, NPCs walk one tile per rules.npc.step_seconds
##     (grid paths, around the player; they pass through each other).
##   - Elsewhere they jump to their goal's spot. An NPC whose way leads
##     through the player's area appears at that area's way in and walks.
##   - A gap longer than rules.npc.jump_seconds (a long action, a night):
##     everyone jumps to their goal's spot.
## Dead NPCs are removed. Time is in world seconds (clock minutes × 60 +
## the player's step seconds). No randomness.
class_name NpcSim
extends RefCounted

## Relationship id of the player (WorldState.relationships).
const PLAYER := "player"


static func world_sec(gs: GameState) -> int:
	return gs.clock.total_minutes * 60 + gs.player.sub_seconds


## Moves the NPCs up to now. Commands call this after every command that
## moves the clock.
static func sync(gs: GameState, db: DataDb) -> void:
	advance_to(gs, db, world_sec(gs))


## Moves the NPCs up to world second `to_sec`. The first call (a new or
## migrated game) puts every NPC at its goal's spot.
static func advance_to(gs: GameState, db: DataDb, to_sec: int) -> void:
	var r := gs.npcs
	if db.behaviour.is_empty() or db.maps.is_empty():
		return
	for id: String in r.npcs.keys():
		if not db.behaviour.npcs.has(id) or not gs.world.is_alive(db.canon, id):
			r.npcs.erase(id)
	var dt := to_sec - r.sec if r.is_placed() else 0
	var jump := not r.is_placed() or dt > int(db.rules["npc"]["jump_seconds"])
	var here := gs.player.area
	for id in db.behaviour.ids():
		if not gs.world.is_alive(db.canon, id):
			continue
		if not r.npcs.has(id):
			r.npcs[id] = {"area": "", "x": 0, "y": 0, "facing": "s", "goal": "",
				"route_i": 0, "carry": 0, "talked_day": 0}
		var n: Dictionary = r.npcs[id]
		var g := UtilityAi.pick(gs, db, id, to_sec)
		if g["goal"] != n["goal"]:
			n["goal"] = g["goal"]
			n["route_i"] = 0
		var t: Dictionary = g["target"]
		if t.has("stay"):
			n["carry"] = 0
		elif jump:
			_place_at_target(gs, db, n, t)
		elif here != "" and n["area"] == here:
			if NpcRoster.pos_of(n) == gs.player.pos():
				_put(gs, db, n, here, gs.player.pos())
			_walk(gs, db, n, t, maxi(dt, 0))
		else:
			_move_offscreen(gs, db, n, t)
	r.sec = maxi(to_sec, r.sec)


## The player talked with `npc` today: +rules.npc.talk_relationship, once
## per NPC per day. Returns true if the relationship changed.
static func note_talk(gs: GameState, db: DataDb, npc: String) -> bool:
	var n: Dictionary = gs.npcs.npcs.get(npc, {})
	if n.is_empty() or int(n["talked_day"]) == gs.clock.day():
		return false
	n["talked_day"] = gs.clock.day()
	gs.world.add_relationship(npc, PLAYER, int(db.rules["npc"]["talk_relationship"]))
	return true


## NPCs on or next to the player, nearest first, then by id.
static func near_player(gs: GameState) -> Array[String]:
	var out: Array[String] = []
	var p := gs.player
	if not p.is_placed():
		return out
	for id in gs.npcs.in_area(p.area):
		var d := NpcRoster.pos_of(gs.npcs.npcs[id]) - p.pos()
		if maxi(absi(d.x), absi(d.y)) <= 1:
			out.append(id)
	out.sort_custom(func(a: String, b: String) -> bool:
		var da := _dist(gs, a)
		var dbb := _dist(gs, b)
		return da < dbb or (da == dbb and a < b))
	return out


static func _dist(gs: GameState, id: String) -> int:
	var d := NpcRoster.pos_of(gs.npcs.npcs[id]) - gs.player.pos()
	return absi(d.x) + absi(d.y)


static func _place_at_target(gs: GameState, db: DataDb, n: Dictionary, t: Dictionary) -> void:
	n["carry"] = 0
	var area := BehaviourDb.target_area(t)
	if BehaviourDb.is_off_map(area):
		n["area"] = area
		return
	_put(gs, db, n, area, BehaviourDb.target_pos(t, int(n["route_i"])))


## Not in the player's area: jump to the goal's spot, unless the way there
## passes through the player's area; then appear at its way in.
static func _move_offscreen(gs: GameState, db: DataDb, n: Dictionary, t: Dictionary) -> void:
	var here := gs.player.area
	var to := BehaviourDb.target_area(t)
	if here != "" and to != n["area"]:
		for hop: Dictionary in Pathfind.route(db.maps, db.behaviour.entries, n["area"], to):
			if hop["to"] == here:
				n["carry"] = 0
				_put(gs, db, n, here, hop["arrive"])
				return
	_place_at_target(gs, db, n, t)


## Walks `n` (in the player's area) towards its goal for `dt` seconds.
static func _walk(gs: GameState, db: DataDb, n: Dictionary, t: Dictionary, dt: int) -> void:
	var step := int(db.rules["npc"]["step_seconds"])
	var area: String = n["area"]
	var to := BehaviourDb.target_area(t)
	var route_left: int = (t.get("route", []) as Array).size()
	n["carry"] = int(n["carry"]) + dt
	while true:
		var hop := {}
		var goals := {}
		if to == area:
			goals[BehaviourDb.target_pos(t, int(n["route_i"]))] = true
		else:
			var hops := Pathfind.route(db.maps, db.behaviour.entries, area, to)
			if hops.is_empty():
				_place_at_target(gs, db, n, t)
				return
			hop = hops[0]
			goals = hop["tiles"]
		var pos := NpcRoster.pos_of(n)
		if goals.has(pos):
			if not hop.is_empty():
				_leave(gs, db, n, hop, pos)
				return
			if route_left > 0:
				route_left -= 1
				n["route_i"] = (int(n["route_i"]) + 1) % (t["route"] as Array).size()
				continue
			n["carry"] = 0
			return
		if int(n["carry"]) < step:
			return
		n["carry"] = int(n["carry"]) - step
		var you := gs.player.pos()
		if goals.has(you) and goals.size() > 1:
			goals = goals.duplicate()
			goals.erase(you)
		var found := Pathfind.path(db.maps, area, pos, goals, {} if goals.has(you) else {you: true})
		if not found["found"]:
			if not Pathfind.path(db.maps, area, pos, goals)["found"]:
				_place_at_target(gs, db, n, t)
				return
			continue  # the player blocks every way: wait
		var dir: String = found["steps"][0]
		var next := pos + (PlayerState.DIRS[dir] as Vector2i)
		n["facing"] = dir
		if next == you:
			continue  # the player stands on the goal: wait next to them
		n["x"] = next.x
		n["y"] = next.y


## Steps off the map: through an exit to the next area, or out at the entry.
static func _leave(gs: GameState, db: DataDb, n: Dictionary, hop: Dictionary, pos: Vector2i) -> void:
	n["carry"] = 0
	if BehaviourDb.is_off_map(hop["to"]):
		n["area"] = hop["to"]
		return
	var e := db.maps.exit_at(n["area"], pos)
	_put(gs, db, n, hop["to"], MapDb.arrival(e, pos) if not e.is_empty() else hop["arrive"])


## Puts `n` on `at`, or on the nearest free tile if the player stands there.
static func _put(gs: GameState, db: DataDb, n: Dictionary, area: String, at: Vector2i) -> void:
	if area == gs.player.area and at == gs.player.pos():
		at = _free_near(gs, db, area, at)
	n["area"] = area
	n["x"] = at.x
	n["y"] = at.y


## Nearest walkable tile to `at` that is not the player's and not an exit
## (breadth-first, fixed order). `at` itself if there is none.
static func _free_near(gs: GameState, db: DataDb, area: String, at: Vector2i) -> Vector2i:
	var maps := db.maps
	var seen := {at: true}
	var queue: Array[Vector2i] = [at]
	var head := 0
	while head < queue.size():
		var cur := queue[head]
		head += 1
		for dir: String in Pathfind.ORDER:
			var next: Vector2i = cur + PlayerState.DIRS[dir]
			if seen.has(next) or not maps.is_walkable(area, next):
				continue
			seen[next] = true
			if next != gs.player.pos() and maps.exit_at(area, next).is_empty():
				return next
			queue.append(next)
	return at
