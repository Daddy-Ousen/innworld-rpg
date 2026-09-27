## What changed on screen after a command, for WorldView's animations
## (M11.3, ADR 0018). `snapshot` notes who is in the player's area; `events`
## compares two snapshots. Pure and headless (no nodes), so tests can check
## it. Presentation only: never changes GameState (CLAUDE.md rule 1).
##
## A snapshot: {"area", "attacks": the player's attacks + throws in the fight
## so far (-1 = no fight), "units": {id: {"kind": "player" / "npc" /
## "monster", "cell", "hp" (-1 = not known), "down", "side": "us" (the player,
## NPCs, helpers) / "them" (hostile monsters) / "calm", "type" (monsters)}}}.
## Hidden monsters are left out (they look like rocks).
##
## Events, in this order: {"type": "move", "id", "from", "to", "dir"} (one
## cell, also diagonal; a longer jump has no event), {"type": "hit", "id",
## "amount"}, {"type": "fall", "id"}, {"type": "gone", "id", "cell",
## "monster_type"} (a monster that died, fled or left), then {"type": "swing",
## "id", "dir"}. The sim keeps no list of who hit whom, so swings are a guess:
## the player swings when their attack count grows (or, with no fight left,
## when they did not move and the monster in front of them was hit or is
## gone: the blow that ended the fight); a monster swings at a
## hit or gone unit of the other side next to it (king move) when it did not
## move. NPCs never swing (helpers in a fight are monsters).
class_name AnimDiff
extends RefCounted

const PLAYER := "@player"
const MOVE := "move"
const HIT := "hit"
const FALL := "fall"
const GONE := "gone"
const SWING := "swing"


## The player's area now. `player_max_hp` turns the player's "full" hp (-1)
## into a number (0 = not known).
static func snapshot(gs: GameState, player_max_hp: int = 0) -> Dictionary:
	var area := gs.player.area
	var units := {}
	var hp := gs.player.hp
	if hp < 0:
		hp = player_max_hp if player_max_hp > 0 else -1
	units[PLAYER] = {"kind": "player", "cell": gs.player.pos(), "hp": hp, "down": hp == 0,
			"side": "us"}
	for id in gs.npcs.in_area(area):
		var n: Dictionary = gs.npcs.npcs[id]
		units[id] = {"kind": "npc", "cell": NpcRoster.pos_of(n), "hp": int(n.get("hp", -1)),
				"down": bool(n.get("down", false)), "side": "us"}
	for id in gs.combat.ids():
		var m: Dictionary = gs.combat.monsters[id]
		if m["area"] != area or m["state"] == CombatState.HIDDEN:
			continue
		var side := "calm"
		if m["state"] == CombatState.ALLY:
			side = "us"
		elif m["state"] == CombatState.HOSTILE:
			side = "them"
		units[id] = {"kind": "monster", "cell": CombatState.pos_of(m), "hp": int(m["hp"]),
				"down": false, "side": side, "type": String(m["type"])}
	var f := gs.combat.fight
	var attacks := int(f["attacks"]) + int(f["throws"]) if gs.combat.has_fight() else -1
	return {"area": area, "attacks": attacks, "units": units, "facing": gs.player.facing}


## The events from `before` to `after` (none after an area change or with
## no `before`).
static func events(before: Dictionary, after: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if before.is_empty() or before["area"] != after["area"]:
		return out
	var b: Dictionary = before["units"]
	var a: Dictionary = after["units"]
	var moved := {}
	var victims: Array[String] = []
	for id: String in a:
		if not b.has(id):
			continue
		var c0: Vector2i = b[id]["cell"]
		var c1: Vector2i = a[id]["cell"]
		if c0 != c1:
			moved[id] = true
			if king(c0, c1) == 1:
				out.append({"type": MOVE, "id": id, "from": c0, "to": c1, "dir": dir_of(c1 - c0)})
		var hp0 := int(b[id]["hp"])
		var hp1 := int(a[id]["hp"])
		if hp0 >= 0 and hp1 >= 0 and hp1 < hp0:
			out.append({"type": HIT, "id": id, "amount": hp0 - hp1})
			victims.append(id)
		if bool(a[id]["down"]) and not bool(b[id]["down"]):
			out.append({"type": FALL, "id": id})
	for id: String in b:
		if not a.has(id) and b[id]["kind"] == "monster":
			out.append({"type": GONE, "id": id, "cell": b[id]["cell"], "monster_type": b[id]["type"]})
			victims.append(id)
	out.append_array(_swings(before, after, moved, victims))
	return out


static func _swings(before: Dictionary, after: Dictionary, moved: Dictionary,
		victims: Array[String]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var b: Dictionary = before["units"]
	var a: Dictionary = after["units"]
	var you: Vector2i = a[PLAYER]["cell"]
	var front: Vector2i = you + PlayerState.DIRS.get(after["facing"], Vector2i.ZERO)
	var more := int(after["attacks"]) > maxi(int(before["attacks"]), 0)
	var ended := int(after["attacks"]) < 0 and not moved.has(PLAYER) \
			and victims.any(func(v: String) -> bool:
				return b.has(v) and b[v]["cell"] == front and b[v]["kind"] == "monster" and b[v]["side"] != "us")
	if more or ended:
		out.append({"type": SWING, "id": PLAYER, "dir": after["facing"]})
	var swung := {}
	for v in victims:
		var unit: Dictionary = a.get(v, b[v])
		var at: Vector2i = unit["cell"]
		var foe := "them" if unit["side"] == "us" else "us"
		for id: String in a:
			var u: Dictionary = a[id]
			if u["kind"] != "monster" or u["side"] != foe or moved.has(id) or swung.has(id) \
					or king(u["cell"], at) != 1:
				continue
			swung[id] = true
			out.append({"type": SWING, "id": id, "dir": dir_of(at - (u["cell"] as Vector2i))})
	return out


static func king(p: Vector2i, q: Vector2i) -> int:
	return maxi(absi(p.x - q.x), absi(p.y - q.y))


## The facing (n, s, e, w) of a step `d`; a diagonal faces left or right.
static func dir_of(d: Vector2i) -> String:
	if d.x != 0 and absi(d.x) >= absi(d.y):
		return "e" if d.x > 0 else "w"
	return "s" if d.y > 0 else "n"
