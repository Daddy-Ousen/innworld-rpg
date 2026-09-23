## Monsters on the map (M5.2, ADR 0010): spawn tables, monster turns and
## their AI. Combat.sync calls run() after every command, so monsters only
## live in the player's area. Each monster acts once per its enemy's
## act_seconds of world time (a "carry" budget), in id order. All rolls go
## through gs.rng; tiles and ids are always visited in a fixed order.
##
## States (CombatState.STATES):
##   hidden  — an ambusher that looks like a rock. The player may spot it
##             once (a roll when within ambush.spot_radius); next to the
##             player, or bumped, it springs out with ambush.hit_bonus.
##   idle    — turns hostile when the player comes within aggro_radius (a
##             territorial monster: of its home). A pack turns hostile together.
##   hostile — flees when hurt below flee_below or when half its pack is
##             gone; gives up when the player is past lose_radius (from its
##             home, for a territorial monster: a leash) or after chase_turns
##             (fewer for a fast player): an ambusher hides again, others go home.
##             Else it attacks when next to the player, may throw from
##             range, or steps closer (around monsters, NPCs and the player).
##   flee    — steps away from the player and is gone at the map edge or an
##             exit. A scared monster calms down after scare_turns.
##   home    — walks back to its home tile, then idle.
class_name MonsterSim
extends RefCounted

const ORTHO := [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]


## Moves the monsters in the player's area up to world second `now`.
## `entered`: the player just came into the area (no turns, a spawn check).
## A gap longer than combat.jump_seconds with no hostile monster gives no
## turns. Spawns are checked on entering and every spawn.check_minutes.
static func run(gs: GameState, db: DataDb, now: int, entered: bool) -> void:
	var c := gs.combat
	if db.combat.is_empty() or db.maps.is_empty() or not gs.player.is_placed():
		return
	var rules: Dictionary = db.rules["combat"]
	var dt := 0 if entered or c.sec < 0 else maxi(now - c.sec, 0)
	_spot(gs, db)
	if dt > 0:
		if dt > int(rules["jump_seconds"]) and not Combat.in_danger(gs):
			_drop_carry(c)
		else:
			_turns(gs, db, dt)
	if entered or c.checked < 0 \
			or gs.clock.total_minutes - c.checked >= int(rules["spawn"]["check_minutes"]):
		c.checked = gs.clock.total_minutes
		spawn_check(gs, db)


## Rolls every spawn of the player's area that is open now (see
## spawn_open). Returns the ids of the new monsters.
static func spawn_check(gs: GameState, db: DataDb) -> Array[String]:
	var out: Array[String] = []
	var c := gs.combat
	var cap := int(db.rules["combat"]["spawn"]["max_monsters"])
	for s: Dictionary in db.combat.spawns:
		if s["area"] != gs.player.area or not spawn_open(gs, s):
			continue
		if gs.rng.randf() >= float(s["chance"]):
			continue
		var n := mini(gs.rng.randi_range(int(s["count"][0]), int(s["count"][1])), cap - c.monsters.size())
		var tiles := spawn_tiles(gs, db, s)
		var e: Dictionary = db.combat.enemies[s["enemy"]]
		var state := CombatState.HIDDEN if e["behaviour"] == "ambush" else CombatState.IDLE
		var group := "m%d" % c.next_id
		var placed: Array[String] = []
		for i in maxi(n, 0):
			if tiles.is_empty():
				break
			var at: Vector2i = tiles.pop_at(0 if s.has("home") else gs.rng.randi_range(0, tiles.size() - 1))
			placed.append(Combat.add_monster(gs, db, s["enemy"], at, state, s["id"], group))
		for id in placed:
			c.monsters[id]["pack"] = placed.size()
		if not placed.is_empty():
			c.spawn_last[s["id"]] = gs.clock.total_minutes
			out.append_array(placed)
	return out


## True if spawn `s` may roll now: its hours, days and flags fit, its
## cooldown has passed and none of its monsters is still here.
static func spawn_open(gs: GameState, s: Dictionary) -> bool:
	var now := gs.clock.total_minutes
	if gs.combat.spawn_last.has(s["id"]) \
			and now - int(gs.combat.spawn_last[s["id"]]) < int(s["cooldown_minutes"]):
		return false
	for m: Dictionary in gs.combat.monsters.values():
		if m["spawn"] == s["id"]:
			return false
	if s.has("hours"):
		@warning_ignore("integer_division")
		var hour := gs.clock.minute() / 60
		var from := int(s["hours"][0])
		var to := int(s["hours"][1])
		if not ((hour >= from and hour < to) if from < to else (hour >= from or hour < to)):
			return false
	if s.has("days") and (gs.clock.day() < int(s["days"][0]) or gs.clock.day() > int(s["days"][1])):
		return false
	for f: String in s.get("when_flags", []):
		if not gs.flags.get(f, false):
			return false
	for f: String in s.get("unless_flags", []):
		if gs.flags.get(f, false):
			return false
	return true


## Free tiles spawn `s` may use, in row order: its home, or the tiles of
## its rects (or its zone's rects) that are walkable, not an exit, not
## taken, and at least spawn.min_distance (king moves) from the player.
static func spawn_tiles(gs: GameState, db: DataDb, s: Dictionary) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var area: String = s["area"]
	var taken := _taken(gs, "")
	var far := int(db.rules["combat"]["spawn"]["min_distance"])
	var rects: Array = []
	if s.has("home"):
		rects = [[int(s["home"][0]), int(s["home"][1])]]
	elif s.has("zone"):
		rects = db.maps.areas[area]["zones"].get(s["zone"], [])
	else:
		rects = s.get("rects", [])
	var seen := {}
	for r: Array in rects:
		var rect := MapDb.rect_of(r)
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				var at := Vector2i(x, y)
				if seen.has(at):
					continue
				seen[at] = true
				if db.maps.is_walkable(area, at) and db.maps.exit_at(area, at).is_empty() \
						and not taken.has(at) and _dist(at, gs.player.pos()) >= far:
					out.append(at)
	return out


## A hidden monster springs out at the player (next to it, or bumped by a
## step): it turns hostile and attacks with its ambush hit_bonus.
## Returns {"hit", "damage"} (see Combat.monster_attack).
static func ambush(gs: GameState, db: DataDb, id: String) -> Dictionary:
	var m: Dictionary = gs.combat.monsters[id]
	var e: Dictionary = db.combat.enemies[m["type"]]
	m["state"] = CombatState.HOSTILE
	m["chase"] = 0
	m["rolled_spot"] = true
	gs.combat.lines.append("A %s bursts out of hiding!" % Combat.name_of(db, m))
	Combat.join(gs, id)
	return Combat.monster_attack(gs, db, id, false, float(e.get("ambush", {}).get("hit_bonus", 0.0)))


## Spot rolls: a hidden monster within its ambush.spot_radius gets one roll
## (spot.base + spot.per_point × perception). Seen, it is idle.
static func _spot(gs: GameState, db: DataDb) -> void:
	var c := gs.combat
	var spot: Dictionary = db.rules["combat"]["spot"]
	for id in c.in_state(CombatState.HIDDEN):
		var m: Dictionary = c.monsters[id]
		var a: Dictionary = db.combat.enemies[m["type"]].get("ambush", {})
		if m["rolled_spot"] or a.is_empty() \
				or _dist(CombatState.pos_of(m), gs.player.pos()) > int(a["spot_radius"]):
			continue
		m["rolled_spot"] = true
		var chance := float(spot["base"]) + float(spot["per_point"]) * Stats.get_stat(gs, db, "perception")
		if gs.rng.randf() < chance:
			m["state"] = CombatState.IDLE
			c.lines.append("You spot a %s among the rocks." % Combat.name_of(db, m))


## Gives every monster `dt` more seconds and runs their turns, round by
## round in id order, until no one has a full turn left. Stops when the
## player is down or after combat.max_turns_per_sync turns.
static func _turns(gs: GameState, db: DataDb, dt: int) -> void:
	var c := gs.combat
	for id in c.ids():
		c.monsters[id]["carry"] = int(c.monsters[id]["carry"]) + dt
	var cap := int(db.rules["combat"]["max_turns_per_sync"])
	var turns := 0
	var acted := true
	while acted:
		acted = false
		for id in c.ids():
			if Combat.is_down(gs) or turns >= cap:
				_drop_carry(c)
				return
			if not c.monsters.has(id):
				continue
			var m: Dictionary = c.monsters[id]
			var act := int(db.combat.enemies[m["type"]]["act_seconds"])
			if int(m["carry"]) < act:
				continue
			m["carry"] = int(m["carry"]) - act
			turns += 1
			acted = true
			_turn(gs, db, id)


static func _drop_carry(c: CombatState) -> void:
	for m: Dictionary in c.monsters.values():
		m["carry"] = 0


static func _turn(gs: GameState, db: DataDb, id: String) -> void:
	var m: Dictionary = gs.combat.monsters[id]
	match m["state"]:
		CombatState.HIDDEN:
			if _next_to(CombatState.pos_of(m), gs.player.pos()):
				ambush(gs, db, id)
		CombatState.IDLE, CombatState.HOME:
			if _provoked(gs, db, m):
				_aggro(gs, db, id)
			elif m["state"] == CombatState.HOME:
				_go_home(gs, db, id)
		CombatState.HOSTILE:
			_hostile_turn(gs, db, id)
		CombatState.FLEE:
			_flee_turn(gs, db, id)


## The player is within aggro_radius (of the home, for a territorial monster).
static func _provoked(gs: GameState, db: DataDb, m: Dictionary) -> bool:
	var e: Dictionary = db.combat.enemies[m["type"]]
	var from := CombatState.pos_of(m)
	if e["behaviour"] == "territorial":
		from = Vector2i(int(m["home_x"]), int(m["home_y"]))
	return _dist(from, gs.player.pos()) <= int(e["aggro_radius"])


## Monster `id` turns hostile; a pack turns hostile together.
static func _aggro(gs: GameState, db: DataDb, id: String) -> void:
	var c := gs.combat
	var m: Dictionary = c.monsters[id]
	var ids: Array[String] = [id]
	if db.combat.enemies[m["type"]]["behaviour"] == "pack":
		ids = []
		for other in c.ids():
			var o: Dictionary = c.monsters[other]
			if o["group"] == m["group"] and o["state"] != CombatState.HOSTILE \
					and o["state"] != CombatState.FLEE:
				ids.append(other)
	for other in ids:
		c.monsters[other]["state"] = CombatState.HOSTILE
		c.monsters[other]["chase"] = 0
		Combat.join(gs, other)
	var who := Combat.name_of(db, m)
	c.lines.append("%d %ss come at you!" % [ids.size(), who] if ids.size() > 1
			else "A %s comes at you!" % who)


static func _hostile_turn(gs: GameState, db: DataDb, id: String) -> void:
	var c := gs.combat
	var m: Dictionary = c.monsters[id]
	var e: Dictionary = db.combat.enemies[m["type"]]
	var pos := CombatState.pos_of(m)
	var you := gs.player.pos()
	if _beaten(c, m, e):
		m["state"] = CombatState.FLEE
		if c.has_fight():
			c.fight["routed"] += 1
		c.lines.append("The %s runs away." % Combat.name_of(db, m))
		return
	var d := _dist(pos, you)
	var leash := d
	if e["behaviour"] == "territorial":
		leash = _dist(Vector2i(int(m["home_x"]), int(m["home_y"])), you)
	if leash > int(e["lose_radius"]) or int(m["chase"]) >= _chase_limit(gs, db, e):
		_give_up(gs, db, id)
		return
	if _next_to(pos, you):
		m["chase"] = 0
		Combat.monster_attack(gs, db, id)
		return
	m["chase"] = int(m["chase"]) + 1
	if e.has("ranged") and d <= int(e["ranged"]["range"]) \
			and gs.rng.randf() < float(e["ranged"]["chance"]):
		Combat.monster_attack(gs, db, id, true)
		return
	var goals := {}
	var taken := _taken(gs, id)
	for off: Vector2i in ORTHO:
		var at := you + off
		if db.maps.is_walkable(gs.player.area, at) and not taken.has(at):
			goals[at] = true
	if not goals.is_empty():
		_step_to(gs, db, id, goals)


## Hurt below flee_below, or half its pack is dead or running.
static func _beaten(c: CombatState, m: Dictionary, e: Dictionary) -> bool:
	if float(m["hp"]) < float(e["flee_below"]) * float(e["hp"]):
		return true
	var pack := int(m.get("pack", 1))
	if e["behaviour"] != "pack" or pack < 2:
		return false
	var standing := 0
	for o: Dictionary in c.monsters.values():
		if o["group"] == m["group"] and o["state"] != CombatState.FLEE:
			standing += 1
	return standing * 2 <= pack


## chase_turns, minus the player's speed above the default race's speed.
static func _chase_limit(gs: GameState, db: DataDb, e: Dictionary) -> int:
	var base := int(db.rules["combat"]["base_stats"]["default"].get("speed", 0))
	return int(e["chase_turns"]) - maxi(Stats.get_stat(gs, db, "speed") - base, 0)


## An ambusher hides again where it is; any other monster goes home.
static func _give_up(gs: GameState, db: DataDb, id: String) -> void:
	var m: Dictionary = gs.combat.monsters[id]
	m["chase"] = 0
	var who := Combat.name_of(db, m)
	if db.combat.enemies[m["type"]]["behaviour"] == "ambush":
		m["state"] = CombatState.HIDDEN
		m["rolled_spot"] = false
		gs.combat.lines.append("The %s gives up and goes still." % who)
	else:
		m["state"] = CombatState.HOME
		gs.combat.lines.append("The %s gives up the chase." % who)


static func _flee_turn(gs: GameState, db: DataDb, id: String) -> void:
	var c := gs.combat
	var m: Dictionary = c.monsters[id]
	if int(m["scared"]) > 0:
		m["scared"] = int(m["scared"]) - 1
		if int(m["scared"]) == 0:
			_give_up(gs, db, id)
			return
	var pos := CombatState.pos_of(m)
	var area: String = m["area"]
	var size := db.maps.size(area)
	if pos.x == 0 or pos.y == 0 or pos.x == size.x - 1 or pos.y == size.y - 1 \
			or not db.maps.exit_at(area, pos).is_empty():
		c.lines.append("The %s is gone." % Combat.name_of(db, m))
		c.monsters.erase(id)
		return
	var you := gs.player.pos()
	var taken := _taken(gs, id)
	var best := pos
	var best_d := _manhattan(pos, you)
	for off: Vector2i in ORTHO:
		var at := pos + off
		if db.maps.is_walkable(area, at) and not taken.has(at) and _manhattan(at, you) > best_d:
			best = at
			best_d = _manhattan(at, you)
	m["x"] = best.x
	m["y"] = best.y


## Walks one step towards home; idle when there (or when the way is shut).
static func _go_home(gs: GameState, db: DataDb, id: String) -> void:
	var m: Dictionary = gs.combat.monsters[id]
	var home := Vector2i(int(m["home_x"]), int(m["home_y"]))
	if CombatState.pos_of(m) == home or not _step_to(gs, db, id, {home: true}):
		m["state"] = CombatState.IDLE
		m["chase"] = 0


## One step along the shortest path to any tile in `goals`, around the
## player, NPCs and other monsters. Returns false if there is no way.
static func _step_to(gs: GameState, db: DataDb, id: String, goals: Dictionary) -> bool:
	var m: Dictionary = gs.combat.monsters[id]
	var pos := CombatState.pos_of(m)
	var found := Pathfind.path(db.maps, m["area"], pos, goals, _taken(gs, id))
	if not found["found"] or (found["steps"] as Array).is_empty():
		return false
	var next: Vector2i = pos + PlayerState.DIRS[found["steps"][0]]
	m["x"] = next.x
	m["y"] = next.y
	return true


## Tiles in the player's area held by the player, an NPC or a monster
## other than `except_id`: {Vector2i: true}.
static func _taken(gs: GameState, except_id: String) -> Dictionary:
	var area := gs.player.area
	var out := {gs.player.pos(): true}
	for id in gs.npcs.in_area(area):
		out[NpcRoster.pos_of(gs.npcs.npcs[id])] = true
	for id in gs.combat.ids():
		var m: Dictionary = gs.combat.monsters[id]
		if id != except_id and m["area"] == area:
			out[CombatState.pos_of(m)] = true
	return out


## Side by side (not diagonal): melee reach, for monsters and the player.
static func _next_to(a: Vector2i, b: Vector2i) -> bool:
	return _manhattan(a, b) == 1


## King-move distance.
static func _dist(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


static func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)
