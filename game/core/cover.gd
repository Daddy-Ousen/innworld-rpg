## Cover, sight and flanking (M17.6, ADR 0027). Pure functions of the map and
## the fighters' places; nothing is saved.
##
## Levels: "none", "half", "full", "wall". A tile has one in data/tiles.json
## ("cover"); a solid object has one in its own "cover" field, else by its kind
## in rules.combat.tactical.cover.kinds. The higher level of a tile and the solid
## object on it counts.
## - Sight: a straight line between two tile centres. A "wall" tile strictly
##   between blocks it (rules.combat.tactical.cover.sight; on by default).
## - Cover: for a RANGED attack, the tiles next to the target on the side(s)
##   that face the shooter. "half" lowers the hit chance by cover.half, "full"
##   and "wall" by cover.full. A shot from where the target has no cover on
##   the facing sides gets none (that is the flank). Melee ignores cover.
## - Pincer: a target with two fighters of the attacker's side on opposite
##   tiles (north and south, or east and west) is hit cover.flank more often,
##   by any attack from that side.
class_name Cover
extends RefCounted

const NONE := "none"
const HALF := "half"
const FULL := "full"
const WALL := "wall"
const LEVELS := [NONE, HALF, FULL, WALL]
## The two sides of a fight: the player's (the player, helpers, NPCs that
## fight for them) and the foes' (hostile monsters, NPCs hostile to the player).
const FRIEND := "friend"
const FOE := "foe"


static func rules(db: DataDb) -> Dictionary:
	return db.rules["combat"]["tactical"].get("cover", {})


static func rank(level: String) -> int:
	return LEVELS.find(level)


## The cover level of tile `at` in `area`.
static func level(db: DataDb, area: String, at: Vector2i) -> String:
	var best := String(db.maps.tiles.get(db.maps.tile_at(area, at), {}).get("cover", NONE))
	var o := db.maps.solid_at(area, at)
	if not o.is_empty():
		var l := String(o["cover"]) if o.has("cover") \
				else String(rules(db).get("kinds", {}).get(String(o.get("kind", "")), NONE))
		if rank(l) > rank(best):
			best = l
	return best


static func blocks_sight(db: DataDb, area: String, at: Vector2i) -> bool:
	return level(db, area, at) == WALL


## The tiles strictly between `a` and `b` on the line of sight (Bresenham;
## always walked from the smaller end, so both ways give the same tiles).
static func line(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	if b.y < a.y or (b.y == a.y and b.x < a.x):
		var t := a
		a = b
		b = t
	var out: Array[Vector2i] = []
	var dx := absi(b.x - a.x)
	var dy := -absi(b.y - a.y)
	var sx := 1 if a.x < b.x else -1
	var sy := 1 if a.y < b.y else -1
	var err := dx + dy
	var at := a
	for _i in 4096:
		if at == b:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			at.x += sx
		if e2 <= dx:
			err += dx
			at.y += sy
		if at != b:
			out.append(at)
	return out


## True if `from` sees `to` (no sight-blocking tile between them).
static func sight(db: DataDb, area: String, from: Vector2i, to: Vector2i) -> bool:
	if not bool(rules(db).get("sight", true)):
		return true
	for at in line(from, to):
		if blocks_sight(db, area, at):
			return false
	return true


## The best cover a target at `target` has against a shooter at `from`:
## the tiles next to it on the side(s) that face the shooter.
static func against(db: DataDb, area: String, target: Vector2i, from: Vector2i) -> String:
	var d := from - target
	var sides: Array[Vector2i] = []
	if absi(d.x) >= absi(d.y) and d.x != 0:
		sides.append(Vector2i(signi(d.x), 0))
	if absi(d.y) >= absi(d.x) and d.y != 0:
		sides.append(Vector2i(0, signi(d.y)))
	var best := NONE
	for s in sides:
		var l := level(db, area, target + s)
		if rank(l) > rank(best):
			best = l
	return best


## Which side the fighter on tile `at` is on: FRIEND, FOE, or "" (nobody, or
## someone who is not in the fight).
static func side_at(gs: GameState, db: DataDb, area: String, at: Vector2i) -> String:
	if gs.player.area == area and gs.player.pos() == at:
		return FRIEND
	var mid := gs.combat.at(area, at)
	if mid != "":
		match String(gs.combat.monsters[mid]["state"]):
			CombatState.ALLY:
				return FRIEND
			CombatState.HOSTILE:
				return FOE
		return ""
	var nid := gs.npcs.at(area, at)
	if nid != "":
		if Brawl.on(db) and Brawl.is_hostile(gs, gs.npcs.npcs[nid]):
			return FOE
		if Encounter.active(gs) and Encounter.npc_fights(gs, db, nid):
			return FRIEND
	return ""


## True if `target` has fighters of `side` on two opposite tiles.
static func pincered(gs: GameState, db: DataDb, area: String, target: Vector2i, side: String) -> bool:
	for d: Vector2i in [Vector2i(1, 0), Vector2i(0, 1)]:
		if side_at(gs, db, area, target + d) == side and side_at(gs, db, area, target - d) == side:
			return true
	return false


## What position does to an attack by `side` from `from` on the fighter at
## `target`: {"cover": level (ranged only, else none), "flank": bool,
## "bonus": hit chance added (negative for cover)}.
static func details(gs: GameState, db: DataDb, area: String, from: Vector2i, target: Vector2i,
		ranged: bool, side: String) -> Dictionary:
	var r := rules(db)
	var out := {"cover": NONE, "flank": false, "bonus": 0.0}
	if r.is_empty():
		return out
	if ranged:
		out["cover"] = against(db, area, target, from)
		match out["cover"]:
			HALF:
				out["bonus"] -= float(r["half"])
			FULL, WALL:
				out["bonus"] -= float(r["full"])
	if side != "" and pincered(gs, db, area, target, side):
		out["flank"] = true
		out["bonus"] += float(r["flank"])
	return out


static func hit_bonus(gs: GameState, db: DataDb, area: String, from: Vector2i, target: Vector2i,
		ranged: bool, side: String) -> float:
	return float(details(gs, db, area, from, target, ranged, side)["bonus"])


## The screen's word for a level: "" for none, else "half cover" / "full cover".
static func word(l: String) -> String:
	return "" if l == NONE else ("half cover" if l == HALF else "full cover")
