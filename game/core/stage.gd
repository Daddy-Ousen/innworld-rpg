## Canon fights on the map (M6.5, ADR 0011). A canon event with a `stage`
## puts its foes on the map when the player is in the stage area at the
## stage hours, on a day of the event's window (with delays), while the
## event is pending, every NPC in its requires.alive lives, and the stage
## flags fit. Each event stages once (world.staged). The foes are hostile
## monsters with "stage" = the event id; stage allies fight next to the
## player (NpcReact). The fight's action records reach the event through its
## hooks (Director), so a stage never changes canon by itself.
class_name Stage
extends RefCounted


## Stages every event that is open now. Returns the staged event ids.
static func check(gs: GameState, db: DataDb) -> Array[String]:
	var out: Array[String] = []
	for id in db.canon.stages:
		if is_open(gs, db, id):
			run(gs, db, id)
			out.append(id)
	return out


## True if event `id` would stage now (see the class comment).
static func is_open(gs: GameState, db: DataDb, id: String) -> bool:
	var w := gs.world
	var ev: Dictionary = db.canon.events[id]
	var st: Dictionary = ev["stage"]
	if w.staged.has(id) or w.status(id) != WorldState.PENDING or gs.player.area != st["area"]:
		return false
	var day := gs.clock.day()
	if day < int(ev["window"]["earliest"]) or day > w.latest(id, ev):
		return false
	if not MonsterSim.in_hours(gs, st["hours"]):
		return false
	for f: String in st.get("when_flags", []):
		if not gs.flags.get(f, false):
			return false
	for f: String in st.get("unless_flags", []):
		if gs.flags.get(f, false):
			return false
	for npc: String in ev["requires"].get("alive", []):
		if not w.is_alive(db.canon, npc):
			return false
	return true


## Stages event `id`: notes it, shows its line and puts each foe on its tile
## (or the nearest free one) as one hostile pack. Returns the monster ids.
static func run(gs: GameState, db: DataDb, id: String) -> Array[String]:
	var st: Dictionary = db.canon.events[id]["stage"]
	var c := gs.combat
	gs.world.staged[id] = gs.clock.day()
	if st.get("line", "") != "":
		c.lines.append(st["line"])
	var group := "m%d" % c.next_id
	var placed: Array[String] = []
	for foe: Dictionary in st["foes"]:
		var at := free_near(gs, db, Vector2i(int(foe["pos"][0]), int(foe["pos"][1])))
		var mid := Combat.add_monster(gs, db, foe["enemy"], at, CombatState.HOSTILE, "", group)
		if mid != "":
			c.monsters[mid]["stage"] = id
			placed.append(mid)
	for mid in placed:
		c.monsters[mid]["pack"] = placed.size()
	return placed


## Allies of the stage of monster `m` (NPC ids), or [].
static func allies_of(db: DataDb, m: Dictionary) -> Array:
	var id: String = m.get("stage", "")
	if id == "" or not db.canon.events.has(id):
		return []
	return db.canon.events[id].get("stage", {}).get("allies", [])


## `at` if it is free (walkable, not an exit, no player, NPC or monster),
## else the nearest free tile (breadth-first, fixed order); `at` if none.
static func free_near(gs: GameState, db: DataDb, at: Vector2i) -> Vector2i:
	var area := gs.player.area
	var taken := MonsterSim.taken(gs, "")
	var seen := {at: true}
	var queue: Array[Vector2i] = [at]
	var head := 0
	while head < queue.size():
		var cur := queue[head]
		head += 1
		if db.maps.is_walkable(area, cur) and db.maps.exit_at(area, cur).is_empty() \
				and not taken.has(cur):
			return cur
		for dir: String in Pathfind.ORDER:
			var next: Vector2i = cur + PlayerState.DIRS[dir]
			if not seen.has(next) and db.maps.is_walkable(area, next):
				seen[next] = true
				queue.append(next)
	return at
