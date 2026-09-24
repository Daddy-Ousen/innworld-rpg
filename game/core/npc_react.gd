## NPCs near a fight (M6.5, ADR 0011). While a hostile monster is in the
## player's area (Combat.in_danger), the NPCs there react instead of
## following their goals:
##   - a fighter (an NPC with a rules.npc.react.fight_tags tag, or an ally
##     of the stage of a monster in the area) walks to the nearest hostile
##     monster within help_radius (a stage ally: its stage's monsters at
##     any distance) and hits it when side by side;
##   - any other NPC within flee_radius of a hostile monster steps away from
##     it; the rest stand still until the danger is over.
## A fighter with no monster in reach follows its goal. Fighters have hit
## points (M7.B, ADR 0013): monsters attack them too (Combat.monster_target),
## and at 0 HP they are down until the fight ends (never dead: only the
## director kills). Bystanders are never attacked. Each NPC acts once per
## react.act_seconds (its carry). Rolls go through gs.rng; NPCs act in id
## order (NpcSim), after the monsters.
class_name NpcReact
extends RefCounted


## True while NPCs in the player's area react (a hostile monster is here).
static func active(gs: GameState) -> bool:
	return Combat.in_danger(gs)


## Runs NPC `id` (in the player's area) for `dt` seconds of danger.
## Returns false if the NPC should follow its goal instead (a fighter with
## no monster in reach).
static func act(gs: GameState, db: DataDb, id: String, n: Dictionary, dt: int) -> bool:
	if bool(n.get("down", false)):
		n["carry"] = 0
		return true
	var rules: Dictionary = db.rules["npc"]["react"]
	var fighter := is_fighter(gs, db, id)
	if fighter and target(gs, db, id, n).is_empty():
		return false
	var step := int(rules["act_seconds"])
	n["carry"] = int(n["carry"]) + dt
	while int(n["carry"]) >= step:
		if not active(gs) or Combat.is_down(gs):
			n["carry"] = 0
			break
		n["carry"] = int(n["carry"]) - step
		if fighter:
			var foe := target(gs, db, id, n)
			if foe.is_empty():
				n["carry"] = 0
				return false
			_fight_turn(gs, db, id, n, foe)
		else:
			_flee_turn(gs, db, n)
	return true


## True if NPC `id` fights: a fight tag, or an ally of a staged monster here.
static func is_fighter(gs: GameState, db: DataDb, id: String) -> bool:
	return has_fight_tag(db, id) or is_ally(gs, db, id)


## True if NPC `id` has a tag in rules.npc.react.fight_tags (a guard).
static func has_fight_tag(db: DataDb, id: String) -> bool:
	var tags: Array = db.canon.npcs.get(id, {}).get("tags", [])
	for t: Variant in db.rules["npc"]["react"]["fight_tags"]:
		if tags.has(t):
			return true
	return false


## NPC `id`'s fight stats {"hp", "accuracy", "evasion", "armor", "damage"}:
## its own npc_behaviour "combat" block (M7.B), else rules.npc.react.fighter
## (a fight tag) or .ally.
static func stats(db: DataDb, id: String) -> Dictionary:
	var own := db.behaviour.combat_of(id)
	if not own.is_empty():
		return own
	var react: Dictionary = db.rules["npc"]["react"]
	return react["fighter"] if has_fight_tag(db, id) else react["ally"]


## True if NPC `id` is an ally of the stage of a monster in the player's area.
static func is_ally(gs: GameState, db: DataDb, id: String) -> bool:
	for m: Dictionary in gs.combat.monsters.values():
		if m["area"] == gs.player.area and Stage.allies_of(db, m).has(id):
			return true
	return false


## The hostile monster the fighter `id` (its roster entry `n`) goes for:
## the nearest within help_radius (king moves), or of a stage it is an ally
## of; ties to the lower id. "" if none.
static func target(gs: GameState, db: DataDb, id: String, n: Dictionary) -> String:
	var radius := int(db.rules["npc"]["react"]["help_radius"])
	var pos := NpcRoster.pos_of(n)
	var best := ""
	var best_d := 0
	for mid in gs.combat.in_state(CombatState.HOSTILE):
		var m: Dictionary = gs.combat.monsters[mid]
		if m["area"] != n["area"]:
			continue
		var d := _dist(pos, CombatState.pos_of(m))
		if (d <= radius or Stage.allies_of(db, m).has(id)) and (best == "" or d < best_d):
			best = mid
			best_d = d
	return best


## Side by side: hit the monster. Else one step towards a tile next to it.
static func _fight_turn(gs: GameState, db: DataDb, id: String, n: Dictionary, mid: String) -> void:
	var m: Dictionary = gs.combat.monsters[mid]
	var pos := NpcRoster.pos_of(n)
	var at := CombatState.pos_of(m)
	if _manhattan(pos, at) == 1:
		_hit(gs, db, id, mid)
		return
	var area: String = n["area"]
	var avoid := _blocked(gs)
	var goals := {}
	for off: Vector2i in MonsterSim.ORTHO:
		var g: Vector2i = at + off
		if db.maps.is_walkable(area, g) and not avoid.has(g):
			goals[g] = true
	if goals.is_empty():
		return
	var found := Pathfind.path(db.maps, area, pos, goals, avoid)
	if not found["found"] or (found["steps"] as Array).is_empty():
		return
	var dir: String = found["steps"][0]
	var next: Vector2i = pos + PlayerState.DIRS[dir]
	n["facing"] = dir
	n["x"] = next.x
	n["y"] = next.y


## One hit roll with the NPC's fight stats (see stats) against the
## monster's evasion and armor.
static func _hit(gs: GameState, db: DataDb, id: String, mid: String) -> void:
	var s := stats(db, id)
	var m: Dictionary = gs.combat.monsters[mid]
	var e: Dictionary = db.combat.enemies[m["type"]]
	var who := String(db.canon.npcs.get(id, {}).get("name", id))
	var foe := Combat.name_of(db, m)
	Combat.join(gs, mid)
	if gs.rng.randf() >= Combat.hit_chance(db, int(s["accuracy"]), int(e["evasion"])):
		gs.combat.lines.append("%s misses the %s." % [who, foe])
		return
	var dmg := maxi(gs.rng.randi_range(int(s["damage"][0]), int(s["damage"][1])) - int(e["armor"]),
			int(db.rules["combat"]["min_damage"]))
	gs.combat.lines.append("%s hits the %s for %d." % [who, foe, dmg])
	Combat.damage_monster(gs, db, mid, dmg)


## Within flee_radius of a hostile monster: step to the side tile farthest
## from the nearest one (Manhattan). Else stand still.
static func _flee_turn(gs: GameState, db: DataDb, n: Dictionary) -> void:
	var radius := int(db.rules["npc"]["react"]["flee_radius"])
	var pos := NpcRoster.pos_of(n)
	var near := Vector2i.ZERO
	var near_d := -1
	for mid in gs.combat.in_state(CombatState.HOSTILE):
		var m: Dictionary = gs.combat.monsters[mid]
		var d := _dist(pos, CombatState.pos_of(m))
		if m["area"] == n["area"] and d <= radius and (near_d < 0 or d < near_d):
			near = CombatState.pos_of(m)
			near_d = d
	if near_d < 0:
		return
	var avoid := _blocked(gs)
	var best := pos
	var best_d := _manhattan(pos, near)
	for i in MonsterSim.ORTHO.size():
		var at: Vector2i = pos + MonsterSim.ORTHO[i]
		if db.maps.is_walkable(n["area"], at) and not avoid.has(at) \
				and db.maps.exit_at(n["area"], at).is_empty() and _manhattan(at, near) > best_d:
			best = at
			best_d = _manhattan(at, near)
	n["x"] = best.x
	n["y"] = best.y


## Tiles an NPC may not step on: the player's and the monsters' (NPCs pass
## through each other, NpcSim).
static func _blocked(gs: GameState) -> Dictionary:
	var out := {gs.player.pos(): true}
	for mid in gs.combat.ids():
		var m: Dictionary = gs.combat.monsters[mid]
		if m["area"] == gs.player.area:
			out[CombatState.pos_of(m)] = true
	return out


static func _dist(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


static func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)
