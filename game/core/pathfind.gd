## Grid paths inside one map (breadth-first search, fixed direction order,
## so the same map gives the same path). Exit tiles are only entered when
## they are a goal, so a path never leaves the map by accident.
class_name Pathfind
extends RefCounted

const ORDER := ["n", "e", "s", "w"]


## Shortest path from `from` to any tile in `goals` ({Vector2i: true}).
## Returns {"found": bool, "steps": Array[String]} (steps are n/e/s/w).
static func path(maps: MapDb, area: String, from: Vector2i, goals: Dictionary) -> Dictionary:
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
			if came.has(next) or not maps.is_walkable(area, next):
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


static func _unwind(came: Dictionary, to: Vector2i) -> Array[String]:
	var steps: Array[String] = []
	var at := to
	while came[at] != null:
		steps.push_front(came[at][1])
		at = came[at][0]
	return steps
