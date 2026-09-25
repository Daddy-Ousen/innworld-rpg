## Canon fights and scenes on the map (M6.5, ADR 0011; scenes M8.2). A canon
## event with a `stage` puts its foes (or, for a "scene" stage, its NPCs) on
## the map when the player is in the stage area at the stage hours, on a day
## of the event's window (with delays), while the event is pending, every
## NPC in its requires.alive lives, and the stage flags fit. Each event
## stages once (world.staged). The foes are hostile monsters with "stage" =
## the event id; stage allies fight next to the player (NpcReact). The
## fight's action records reach the event through its hooks (Director), so a
## stage never changes canon by itself.
##
## A "scene" stage (M8.2) has no fight: it moves its `npcs` (canon NPCs) into
## the stage area with no monster involved, for a crowd or gathering the
## player can walk into. It has no waves and never affects Combat.
##
## Waves (M7.B, ADR 0013): a fight stage's `waves` come after its first foes,
## in order, while the player stays in the stage area (combat.stage_run). The
## next wave comes when its after_seconds have passed since the stage began,
## or when at most left_at_most of the stage's foes are still on the map, or
## when none are; but it waits while rules.combat.stage.max_on_map of them
## are on the map. A wave brings foes (hostile), helpers (monsters in state
## ally) and allies (canon NPCs; one in another area is moved in) at its
## `from` tile or the nearest free one. The fight does not end while waves
## are left (Combat.settle_if_over).
class_name Stage
extends RefCounted


## Stages every event that is open now. Returns the staged event ids.
static func check(gs: GameState, db: DataDb) -> Array[String]:
	var out: Array[String] = []
	for id in db.canon.stages:
		if is_open(gs, db, id):
			run(gs, db, id)
			out.append(id)
	tick(gs, db)
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
## (or the nearest free one) as one hostile pack, or — for a "scene" stage —
## moves in its npcs with no fight. Returns the monster ids (fight) or the
## npc ids moved (scene).
static func run(gs: GameState, db: DataDb, id: String) -> Array[String]:
	var st: Dictionary = db.canon.events[id]["stage"]
	var c := gs.combat
	gs.world.staged[id] = gs.clock.day()
	if st.get("line", "") != "":
		c.lines.append(st["line"])
	if st.get("kind", "fight") == "scene":
		var moved: Array[String] = []
		for n: Dictionary in st["npcs"]:
			var at := Vector2i(int(n["pos"][0]), int(n["pos"][1]))
			if place_npc(gs, db, n["npc"], at):
				moved.append(n["npc"])
		return moved
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
	if not (st.get("waves", []) as Array).is_empty():
		c.stage_run = {"event": id, "start": NpcSim.world_sec(gs), "next": 0}
	return placed


## Sends in the next wave of the staged fight in progress, if it is due
## (see the class comment). Leaving the stage area drops the rest.
## Returns the new monster ids.
static func tick(gs: GameState, db: DataDb) -> Array[String]:
	var out: Array[String] = []
	var c := gs.combat
	if c.stage_run.is_empty():
		return out
	var id: String = c.stage_run["event"]
	var st: Dictionary = db.canon.events.get(id, {}).get("stage", {})
	if st.is_empty() or gs.player.area != st["area"]:
		c.stage_run = {}
		return out
	var waves: Array = st.get("waves", [])
	var next := int(c.stage_run["next"])
	if next >= waves.size():
		return out
	var w: Dictionary = waves[next]
	var here := foes_here(gs, id)
	if here >= int(db.rules["combat"]["stage"]["max_on_map"]):
		return out
	var elapsed := NpcSim.world_sec(gs) - int(c.stage_run["start"])
	if here > 0 and elapsed < int(w["after_seconds"]) and here > int(w.get("left_at_most", -1)):
		return out
	c.stage_run["next"] = next + 1
	return send_wave(gs, db, id, w)


## Puts wave `w` of event `id`'s stage on the map. Returns the new monster ids.
static func send_wave(gs: GameState, db: DataDb, id: String, w: Dictionary) -> Array[String]:
	var c := gs.combat
	var from := Vector2i(int(w["from"][0]), int(w["from"][1]))
	if w.get("line", "") != "":
		c.lines.append(w["line"])
	var placed: Array[String] = []
	var group := "m%d" % c.next_id
	for type: String in w.get("foes", []):
		var mid := Combat.add_monster(gs, db, type, free_near(gs, db, from), CombatState.HOSTILE, "", group)
		if mid != "":
			c.monsters[mid]["stage"] = id
			placed.append(mid)
	for mid in placed:
		c.monsters[mid]["pack"] = placed.size()
	for type: String in w.get("helpers", []):
		var hid := Combat.add_monster(gs, db, type, free_near(gs, db, from), CombatState.ALLY)
		if hid != "":
			c.monsters[hid]["stage"] = id
			placed.append(hid)
	for npc: String in w.get("allies", []):
		place_npc(gs, db, npc, from)
	return placed


## Moves canon npc `npc` to `at` (or the nearest free tile) in the player's
## area, if it is alive and not already there. True if moved.
static func place_npc(gs: GameState, db: DataDb, npc: String, at: Vector2i) -> bool:
	var n: Dictionary = gs.npcs.npcs.get(npc, {})
	if n.is_empty() or n["area"] == gs.player.area or not gs.world.is_alive(db.canon, npc):
		return false
	var pos := free_near(gs, db, at)
	n["area"] = gs.player.area
	n["x"] = pos.x
	n["y"] = pos.y
	n["carry"] = 0
	return true


## True while `id` is a live scene stage (M8.2): staged today, the player
## in its area, and still within its hours. Its npcs hold their ground
## instead of following their normal schedule (NpcSim.advance_to).
static func is_scene_live(gs: GameState, db: DataDb, id: String) -> bool:
	var ev: Dictionary = db.canon.events.get(id, {})
	var st: Dictionary = ev.get("stage", {})
	if st.get("kind", "fight") != "scene":
		return false
	if int(gs.world.staged.get(id, -1)) != gs.clock.day() or gs.player.area != st["area"]:
		return false
	return MonsterSim.in_hours(gs, st["hours"])


## NPC ids held in place by a live scene stage right now (M8.2).
static func scene_npcs_here(gs: GameState, db: DataDb) -> Dictionary:
	var out := {}
	for id in db.canon.stages:
		if is_scene_live(gs, db, id):
			for n: Dictionary in db.canon.events[id]["stage"]["npcs"]:
				out[n["npc"]] = true
	return out


## Stage foes of event `id` still on the map (not helpers).
static func foes_here(gs: GameState, id: String) -> int:
	var count := 0
	for m: Dictionary in gs.combat.monsters.values():
		if m["stage"] == id and m["state"] != CombatState.ALLY:
			count += 1
	return count


## True while the staged fight in progress has waves still to come.
static func waves_left(gs: GameState, db: DataDb) -> bool:
	var run := gs.combat.stage_run
	if run.is_empty():
		return false
	var waves: Array = db.canon.events.get(run["event"], {}).get("stage", {}).get("waves", [])
	return int(run["next"]) < waves.size()


## Foes of the staged fight in progress still to beat: those on the map
## plus those in the waves to come. -1 if no staged fight is on.
static func foes_left(gs: GameState, db: DataDb) -> int:
	var run := gs.combat.stage_run
	if run.is_empty():
		return -1
	var id: String = run["event"]
	var left := foes_here(gs, id)
	var waves: Array = db.canon.events.get(id, {}).get("stage", {}).get("waves", [])
	for i in range(int(run["next"]), waves.size()):
		left += (waves[i].get("foes", []) as Array).size()
	return left


## Allies of the stage of monster `m` (NPC ids): the stage's and every
## wave's. [] if it has no stage.
static func allies_of(db: DataDb, m: Dictionary) -> Array:
	var id: String = m.get("stage", "")
	if id == "" or not db.canon.events.has(id):
		return []
	var st: Dictionary = db.canon.events[id].get("stage", {})
	var out: Array = (st.get("allies", []) as Array).duplicate()
	for w: Dictionary in st.get("waves", []):
		for a: String in w.get("allies", []):
			if not out.has(a):
				out.append(a)
	return out


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
