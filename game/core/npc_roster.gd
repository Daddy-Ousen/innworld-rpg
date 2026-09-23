## Where the NPCs are and what they do (M4.4, ADR 0008). Part of GameState.
## One entry per living NPC with behaviour data:
##   {"area": map id, "@" + off-map place, or "" (nowhere yet), "x", "y", "facing": n/e/s/w,
##    "goal": goal name, "route_i": next patrol point, "carry": step seconds
##    not yet spent, "talked_day": last day the player talked with them (0 = never)}.
## `sec` is the world second the NPCs were last moved to (-1 = not placed
## yet: a new or migrated game). NpcSim changes this; nothing else does.
class_name NpcRoster
extends RefCounted

const INT_FIELDS := ["x", "y", "route_i", "carry", "talked_day"]

var sec: int = -1
var npcs: Dictionary = {}


func is_placed() -> bool:
	return sec >= 0


## Id of the NPC standing on `at` in `area`, or "".
func at(area: String, pos: Vector2i) -> String:
	for id: String in npcs:
		var n: Dictionary = npcs[id]
		if n["area"] == area and int(n["x"]) == pos.x and int(n["y"]) == pos.y:
			return id
	return ""


## Ids of the NPCs in `area`, sorted.
func in_area(area: String) -> Array[String]:
	var out: Array[String] = []
	for id: String in npcs:
		if npcs[id]["area"] == area:
			out.append(id)
	out.sort()
	return out


static func pos_of(n: Dictionary) -> Vector2i:
	return Vector2i(int(n["x"]), int(n["y"]))


func to_dict() -> Dictionary:
	var list := {}
	var ids := npcs.keys()
	ids.sort()
	for id: String in ids:
		list[id] = (npcs[id] as Dictionary).duplicate()
	return {"sec": sec, "npcs": list}


## Accepts {} (a migrated v4 save): NPCs not placed yet.
static func from_dict(d: Dictionary) -> NpcRoster:
	var r := NpcRoster.new()
	r.sec = int(d.get("sec", -1))
	for id: String in d.get("npcs", {}):
		var n: Dictionary = (d["npcs"][id] as Dictionary).duplicate()
		for k: String in INT_FIELDS:
			n[k] = int(n.get(k, 0))
		r.npcs[id] = n
	return r
