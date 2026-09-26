## Where the player is on the world grid (ADR 0006). Part of GameState.
## An empty area means "not placed yet" (a migrated v3 save); Movement
## places the player at rules.world.start before the first move.
class_name PlayerState
extends RefCounted

const DIRS := {"n": Vector2i(0, -1), "s": Vector2i(0, 1), "e": Vector2i(1, 0), "w": Vector2i(-1, 0)}

var area: String = ""
var x: int = 0
var y: int = 0
## Last direction the player moved or tried to move: n, s, e or w.
var facing: String = "s"
## Step time not yet spent on the clock (the clock counts whole minutes).
var sub_seconds: int = 0
## Hit points (M5). -1 = full (the max comes from Stats, so it is not
## stored); 0 = knocked out. Combat.set_hp keeps this rule.
var hp: int = -1
## The improvised item the player holds (data/items.json id), or "".
var held: String = ""
## M10.0 (ADR 0017): the day of the last trip through a magic door (-1 =
## none) and the trips made on that day (Portal).
var portal_day: int = -1
var portal_trips: int = 0


func is_placed() -> bool:
	return area != ""


func pos() -> Vector2i:
	return Vector2i(x, y)


func place(to_area: String, at: Vector2i) -> void:
	area = to_area
	x = at.x
	y = at.y


func to_dict() -> Dictionary:
	return {"area": area, "x": x, "y": y, "facing": facing, "sub_seconds": sub_seconds,
		"hp": hp, "held": held, "portal_day": portal_day, "portal_trips": portal_trips}


## Accepts {} (a migrated v3 save): a player who is not placed yet.
static func from_dict(d: Dictionary) -> PlayerState:
	var p := PlayerState.new()
	p.area = d.get("area", "")
	p.x = int(d.get("x", 0))
	p.y = int(d.get("y", 0))
	p.facing = d.get("facing", "s")
	p.sub_seconds = int(d.get("sub_seconds", 0))
	p.hp = int(d.get("hp", -1))
	p.held = d.get("held", "")
	p.portal_day = int(d.get("portal_day", -1))
	p.portal_trips = int(d.get("portal_trips", 0))
	return p
