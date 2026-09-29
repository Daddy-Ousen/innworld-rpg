## The crowd of passers-by (M16.4, ADR 0024): decoration for a city street. View only: it is
## never in GameState, has no collision and no talk. Pure: reads a map's "crowd" dictionary,
## builds no nodes, so it runs headless.
## A map may have "crowd": {"lanes": [{"path": [[x, y], ...], "walkers": n, "looks": ["race_drake", ...],
## "hours"?: [from, to]}]}. Walkers of a lane walk its path to the end and back (ping-pong),
## one cell per STEP_SEC of real time, spread evenly along it. A one-cell path is a walker
## who stands there. The lane shows only within its hours (default DAY_HOURS; from > to wraps
## past midnight).
class_name Crowd
extends RefCounted

const STEP_SEC := 0.7
const DAY_HOURS := [6, 22]
## Most walkers a map may show (one sprite each).
const MAX_WALKERS := 12


## The cells of a waypoint list, every cell between two waypoints included (king steps: a
## diagonal first, then straight). Repeated cells in a row are dropped.
static func cells(path: Array) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for p: Variant in path:
		var to := Vector2i(int(p[0]), int(p[1]))
		if out.is_empty():
			out.append(to)
			continue
		var at: Vector2i = out[out.size() - 1]
		while at != to:
			at += Vector2i(signi(to.x - at.x), signi(to.y - at.y))
			out.append(at)
	return out


## The cells a walker visits over one round trip: the path, then back without repeating the ends.
static func chain(path: Array) -> Array[Vector2i]:
	var c := cells(path)
	for i in range(c.size() - 2, 0, -1):
		c.append(c[i])
	return c


## How many walkers a lane has (at least 0, and the map total is limited by `budget`).
static func count(lane: Dictionary, budget: int = MAX_WALKERS) -> int:
	return clampi(int(lane.get("walkers", 1)), 0, budget)


## The look (a sheet id) of walker `i` in `lane`, "" when the lane names none.
static func look_of(lane: Dictionary, i: int) -> String:
	var looks: Array = lane.get("looks", [])
	return "" if looks.is_empty() else String(looks[i % looks.size()])


## Where walker `i` of `n` is after `t` real seconds: {"cell", "prev" (the cell before, for the
## glide), "dir" ("n", "e", "s", "w"), "step" (an int that changes when the walker moves)}.
static func walker(lane: Dictionary, i: int, n: int, t: float) -> Dictionary:
	var c := chain(lane.get("path", []))
	if c.is_empty():
		return {"cell": Vector2i.ZERO, "prev": Vector2i.ZERO, "dir": "s", "step": 0}
	var offset := int(i * c.size() / maxi(n, 1))
	var step := int(floor(t / STEP_SEC)) + offset
	var here: Vector2i = c[posmod(step, c.size())]
	var prev: Vector2i = c[posmod(step - 1, c.size())]
	return {"cell": here, "prev": prev, "dir": facing(here - prev), "step": step if c.size() > 1 else 0}


## "n", "e", "s" or "w" for a step (a sideways part wins a tie; no step: "s").
static func facing(d: Vector2i) -> String:
	if d == Vector2i.ZERO:
		return "s"
	if absi(d.x) >= absi(d.y):
		return "e" if d.x > 0 else "w"
	return "s" if d.y > 0 else "n"


## Whether a lane shows at `hour` (0-23).
static func active(lane: Dictionary, hour: int) -> bool:
	var h: Array = lane.get("hours", DAY_HOURS)
	var from := int(h[0])
	var to := int(h[1])
	return hour >= from and hour < to if from <= to else hour >= from or hour < to
