## Winter (M8.W, ADR 0014): the cold on the player and the Frost Fairies in
## the player's area. Part of GameState (save v10).
class_name WinterState
extends RefCounted

## World second of the last Winter.sync (-1 = not yet).
var sec: int = -1
## Seconds the player has spent in the cold (outdoors, not by a fire) since
## the last cold tick. Warmth resets it.
var chill: int = 0
## The area the fairies below belong to ("" = none rolled yet).
var area: String = ""
## Fairy id ("f1", ...) → {"x", "y"} in `area`.
var fairies: Dictionary = {}
var next_id: int = 1
## Steps left that cost double (snow dropped by an annoyed fairy).
var slowed: int = 0
## World second until which a warm meal (a good with warm_minutes, M9.2)
## keeps the cold off. -1 = none.
var warm_until: int = -1


func ids() -> Array[String]:
	var out: Array[String] = []
	out.assign(fairies.keys())
	out.sort_custom(func(a: String, b: String) -> bool: return a.substr(1).to_int() < b.substr(1).to_int())
	return out


## The fairy at `at`, or "".
func at(pos: Vector2i) -> String:
	for id in ids():
		if Vector2i(int(fairies[id]["x"]), int(fairies[id]["y"])) == pos:
			return id
	return ""


static func pos_of(f: Dictionary) -> Vector2i:
	return Vector2i(int(f["x"]), int(f["y"]))


func to_dict() -> Dictionary:
	return {"sec": sec, "chill": chill, "area": area, "fairies": fairies.duplicate(true),
		"next_id": next_id, "slowed": slowed, "warm_until": warm_until}


## Accepts {} (a migrated v9 save): no cold yet, no fairies.
static func from_dict(d: Dictionary) -> WinterState:
	var w := WinterState.new()
	w.sec = int(d.get("sec", -1))
	w.chill = int(d.get("chill", 0))
	w.area = d.get("area", "")
	for id: String in (d.get("fairies", {}) as Dictionary):
		var f: Dictionary = d["fairies"][id]
		w.fairies[id] = {"x": int(f["x"]), "y": int(f["y"])}
	w.next_id = int(d.get("next_id", 1))
	w.slowed = int(d.get("slowed", 0))
	w.warm_until = int(d.get("warm_until", -1))
	return w
