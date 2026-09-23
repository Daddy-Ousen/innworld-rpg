## Grid paths inside one map (breadth-first search, fixed direction order,
## so the same map gives the same path). Exit tiles are only entered when
## they are a goal, so a path never leaves the map by accident. route()
## finds the chain of maps between two areas (M4.4).
class_name Pathfind
extends RefCounted

const ORDER := ["n", "e", "s", "w"]


## Shortest path from `from` to any tile in `goals` ({Vector2i: true}),
## never through a tile in `avoid` ({Vector2i: true}, e.g. where people stand).
## Returns {"found": bool, "steps": Array[String]} (steps are n/e/s/w).
static func path(maps: MapDb, area: String, from: Vector2i, goals: Dictionary,
		avoid: Dictionary = {}) -> Dictionary:
	if goals.has(from):
		return {"found": true, "steps": [] as Array[String]}
	var came := {from: null}
	var queue: Array[Vector2i] = [from]
	var head := 0
	while head < queue.size():
		var at := queue[head]
		head += 1
		for dir: String in ORDER:
			var next: Vector2i = at + PlayerState.DIRS[dir]
			if came.has(next) or avoid.has(next) or not maps.is_walkable(area, next):
				continue
			var goal := goals.has(next)
			if not goal and not maps.exit_at(area, next).is_empty():
				continue
			came[next] = [at, dir]
			if goal:
				return {"found": true, "steps": _unwind(came, next)}
			queue.append(next)
	return {"found": false, "steps": [] as Array[String]}


## Goals for "stand next to this object" (the 8 tiles around it, and the tile itself).
static func around(at: Vector2i) -> Dictionary:
	var goals := {}
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			goals[at + Vector2i(dx, dy)] = true
	return goals


## The shortest chain of hops from area `from` to area `to`. Maps link by
## their exits; an off-map place ("@" + place, BehaviourDb.entries) links
## to the maps it has entry tiles on. Neighbours are tried in exit order,
## then places by id, so the result is fixed. Each hop:
## {"from", "to", "tiles": {Vector2i: true} to step on in `from`,
##  "arrive": Vector2i in `to` (unused when `to` is off-map)}.
## Returns [] if from == to or there is no way.
static func route(maps: MapDb, entries: Dictionary, from: String, to: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if from == to:
		return out
	var came := {from: null}
	var queue: Array[String] = [from]
	var head := 0
	while head < queue.size():
		var at := queue[head]
		head += 1
		for hop: Dictionary in _hops(maps, entries, at):
			if came.has(hop["to"]):
				continue
			came[hop["to"]] = hop
			if hop["to"] == to:
				var a: String = to
				while came[a] != null:
					out.push_front(came[a])
					a = came[a]["from"]
				return out
			queue.append(hop["to"])
	return out


static func _hops(maps: MapDb, entries: Dictionary, area: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if entries.has(area):
		var ids: Array = (entries[area] as Dictionary).keys()
		ids.sort()
		for a: String in ids:
			if maps.areas.has(a):
				out.append({"from": area, "to": a, "tiles": {}, "arrive": entries[area][a]})
		return out
	if not maps.areas.has(area):
		return out
	for e: Dictionary in maps.areas[area]["exits"]:
		var r := MapDb.rect_of(e["at"])
		var tiles := {}
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				tiles[Vector2i(x, y)] = true
		out.append({"from": area, "to": e["to"], "tiles": tiles,
				"arrive": MapDb.arrival(e, r.position)})
	var places := entries.keys()
	places.sort()
	for place: String in places:
		if (entries[place] as Dictionary).has(area):
			out.append({"from": area, "to": place, "tiles": {entries[place][area]: true},
					"arrive": Vector2i.ZERO})
	return out


static func _unwind(came: Dictionary, to: Vector2i) -> Array[String]:
	var steps: Array[String] = []
	var at := to
	while came[at] != null:
		steps.push_front(came[at][1])
		at = came[at][0]
	return steps
