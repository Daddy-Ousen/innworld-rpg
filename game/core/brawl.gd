## Attacking NPCs (M14.5, ADR 0021; save v17). Rules in rules.brawl.
##   The player can attack any NPC next to them (Commands.attack_npc). The NPC has the hit points
##   and armor of NpcReact.stats. At 0 HP the NPC is dead (Director.player_kill: the story bends).
##   Fate warning: a major NPC, one that a pending canon event still needs (is_major), gives the
##   first attack a warning instead (result "warn"); the UI shows it, and a confirmed attack sets
##   gs.flags["fate_warned.<npc>"], so the warning comes once per NPC.
##   Hostile: the first blow of a day makes the NPC hostile until the day ends (roster field
##   hostile_day). A hostile NPC that is up walks to the player and hits them (act, called from
##   NpcSim). While one is in the player's area it is danger (Combat.in_danger): no talk, sleep or
##   work, patrons leave.
##   Witnesses: the NPCs in the area. The first blow costs the victim's and the witnesses'
##   relationship, the town's and the victim's faction's reputation (Standing.add_reputation), and
##   guards who see it turn hostile too. A kill costs more. Rolls go through gs.rng.
## A db without rules.brawl (toy dbs) has none of this: an attack is refused.
class_name Brawl
extends RefCounted

const FATE_FLAG := "fate_warned."
const FIELDS := ["confidence", "act_seconds", "fate_delay", "fate_title", "fate_lines", "attack", "kill"]
const COSTS := ["victim", "witness", "town", "faction"]


static func rules(db: DataDb) -> Dictionary:
	return db.rules.get("brawl", {})


static func on(db: DataDb) -> bool:
	return not rules(db).is_empty()


## True if the story still needs `npc`: a pending canon event (one that runs on its own) names
## them in a role's prefer list or in requires.alive.
static func is_major(gs: GameState, db: DataDb, npc: String) -> bool:
	for id in db.canon.order:
		if db.canon.alt_only.has(id) or gs.world.status(id) != WorldState.PENDING:
			continue
		var ev: Dictionary = db.canon.events[id]
		if (ev["requires"].get("alive", []) as Array).has(npc):
			return true
		for role: String in ev["roles"]:
			if (ev["roles"][role].get("prefer", []) as Array).has(npc):
				return true
	return false


## True if attacking `npc` now must be confirmed first: a major NPC not warned yet.
static func needs_warning(gs: GameState, db: DataDb, npc: String) -> bool:
	return on(db) and not gs.flags.has(FATE_FLAG + npc) and is_major(gs, db, npc)


## The fate warning's lines for `npc` ("%s" is the name).
static func fate_lines(db: DataDb, npc: String) -> Array[String]:
	var out: Array[String] = []
	var name := Combat.npc_name(db, npc)
	for l: String in rules(db)["fate_lines"]:
		out.append(l % name if l.contains("%s") else l)
	return out


## The player attacks NPC `npc` next to them, with the held item or fists. One turn. Returns
## {"error", "target", "warn", "hit", "damage", "killed"}. "warn" = the fate warning must be
## confirmed first (nothing happened, no time passed): ask again with `confirmed` true.
static func attack(gs: GameState, db: DataDb, npc: String, confirmed: bool = false) -> Dictionary:
	var out := {"error": Combat.cannot_act(gs, db), "target": npc, "warn": false, "hit": false,
		"damage": 0, "killed": false}
	if out["error"] != "":
		return out
	if not on(db) or not NpcSim.near_player(gs).has(npc):
		out["error"] = "There is no '%s' here." % npc
		return out
	if needs_warning(gs, db, npc):
		if not confirmed:
			out["warn"] = true
			return out
		gs.flags[FATE_FLAG + npc] = true
	var n: Dictionary = gs.npcs.npcs[npc]
	var d := NpcRoster.pos_of(n) - gs.player.pos()
	gs.player.facing = ("e" if d.x > 0 else "w") if d.x != 0 else ("s" if d.y > 0 else "n")
	Movement.spend_turn(gs, db)
	var today := gs.clock.day()
	if int(n.get("hostile_day", 0)) != today:
		n["hostile_day"] = today
		_outrage(gs, db, npc, rules(db)["attack"])
		for w in witnesses(gs, db, npc):
			if NpcReact.has_fight_tag(db, w):
				gs.npcs.npcs[w]["hostile_day"] = today
	var s := NpcReact.stats(db, npc)
	var name := Combat.npc_name(db, npc)
	var held := gs.player.held
	var item: Dictionary = db.combat.items.get(held, {})
	var what := "The %s" % String(item["name"]).to_lower() if not item.is_empty() else "You"
	var c := gs.combat
	var cr: Dictionary = db.rules["combat"]
	var pos_bonus := Combat.position_bonus(gs, db, gs.player.pos(), NpcRoster.pos_of(n), false, Cover.FRIEND)
	out["hit"] = gs.rng.randf() < Combat.hit_chance(db, Stats.get_stat(gs, db, "dexterity"), int(s["evasion"]), pos_bonus)
	if not out["hit"]:
		c.lines.append("%s %s %s." % [what, "misses" if what != "You" else "miss", name])
		return out
	var weapon: Array = item["melee"] if not item.is_empty() else cr["unarmed"]["damage"]
	@warning_ignore("integer_division")
	var dmg := gs.rng.randi_range(int(weapon[0]), int(weapon[1])) \
			+ Stats.get_stat(gs, db, "strength") / int(cr["strength_div"]) - int(s["armor"])
	out["damage"] = maxi(dmg, int(cr["min_damage"]))
	c.lines.append("%s %s %s for %d." % [what, "hits" if what != "You" else "hit", name, out["damage"]])
	if not item.is_empty() and float(item["break_chance"]) > 0.0 and gs.rng.randf() < float(item["break_chance"]):
		gs.player.held = ""
		c.lines.append("The %s breaks." % String(item["name"]).to_lower())
	var left := Combat.npc_hp(gs, db, npc) - int(out["damage"])
	if left > 0:
		n["hp"] = left
		return out
	out["killed"] = true
	c.lines.append("%s dies." % name)
	_outrage(gs, db, npc, rules(db)["kill"])
	Director.player_kill(gs, db, npc)
	return out


## The NPCs in the player's area who see it (not the victim, not the fallen), by id.
static func witnesses(gs: GameState, db: DataDb, npc: String) -> Array[String]:
	var out: Array[String] = []
	for id in gs.npcs.in_area(gs.player.area):
		if id != npc and not bool(gs.npcs.npcs[id].get("down", false)):
			out.append(id)
	return out


## Applies a cost row of rules.brawl ("attack" or "kill"): relationships with the player and
## reputation (the town of the player's area, the victim's faction).
static func _outrage(gs: GameState, db: DataDb, npc: String, cost: Dictionary) -> void:
	if int(cost["victim"]) != 0:
		gs.world.add_relationship(npc, NpcSim.PLAYER, int(cost["victim"]))
	for w in witnesses(gs, db, npc):
		gs.world.add_relationship(w, NpcSim.PLAYER, int(cost["witness"]))
	Standing.add_reputation(gs, db, Standing.town_of(db, gs.player.area), int(cost["town"]))
	var faction: Variant = db.canon.npcs.get(npc, {}).get("faction", null)
	if faction != null:
		Standing.add_reputation(gs, db, String(faction), int(cost["faction"]))


## True if roster entry `n` is hostile to the player now: hit by them today and up.
static func is_hostile(gs: GameState, n: Dictionary) -> bool:
	return int(n.get("hostile_day", 0)) == gs.clock.day() and not bool(n.get("down", false))


## True if a hostile NPC is in the player's area (Combat.in_danger).
static func hostile_near(gs: GameState) -> bool:
	if not gs.player.is_placed():
		return false
	for id in gs.npcs.in_area(gs.player.area):
		if is_hostile(gs, gs.npcs.npcs[id]):
			return true
	return false


## Runs hostile NPC `id` (roster entry `n`, in the player's area) for `dt` seconds: one turn per
## act_seconds, a hit if next to the player, else a step towards them. Returns false if the NPC
## is not hostile (it follows its goal).
static func act(gs: GameState, db: DataDb, id: String, n: Dictionary, dt: int) -> bool:
	if not on(db) or not is_hostile(gs, n):
		return false
	var step := int(rules(db)["act_seconds"])
	n["carry"] = int(n["carry"]) + dt
	while int(n["carry"]) >= step:
		if Combat.is_down(gs):
			n["carry"] = 0
			break
		n["carry"] = int(n["carry"]) - step
		if _dist(NpcRoster.pos_of(n), gs.player.pos()) <= 1:
			_hit_player(gs, db, id)
		else:
			_step_towards_player(gs, db, n)
	return true


## One blow at the player with the NPC's fight stats against their dexterity; a raised guard
## lowers the chance and halves the damage (as for a monster).
static func _hit_player(gs: GameState, db: DataDb, id: String) -> void:
	var c := gs.combat
	var cr: Dictionary = db.rules["combat"]
	var s := NpcReact.stats(db, id)
	var who := Combat.npc_name(db, id)
	var bonus := -float(cr["block"]["hit_malus"]) if c.blocking else 0.0
	bonus += Combat.position_bonus(gs, db, NpcRoster.pos_of(gs.npcs.npcs[id]), gs.player.pos(), false, Cover.FOE)
	if gs.rng.randf() >= Combat.hit_chance(db, int(s["accuracy"]), Stats.get_stat(gs, db, "dexterity"), bonus):
		c.lines.append("%s swings at you and misses." % who)
		return
	var dmg := maxi(gs.rng.randi_range(int(s["damage"][0]), int(s["damage"][1])), int(cr["min_damage"]))
	if c.blocking:
		dmg = floori(dmg * float(cr["block"]["damage_mult"]))
	c.lines.append("%s hits you: %d damage%s." % [who, dmg, " (blocked)" if c.blocking else ""])
	Combat.damage_player(gs, db, dmg)


## One step to the nearest free tile next to the player (never through a monster).
static func _step_towards_player(gs: GameState, db: DataDb, n: Dictionary) -> void:
	var area: String = n["area"]
	var you := gs.player.pos()
	var avoid := {you: true}
	for mid in gs.combat.ids():
		if gs.combat.monsters[mid]["area"] == area:
			avoid[CombatState.pos_of(gs.combat.monsters[mid])] = true
	var goals := {}
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var g := you + Vector2i(dx, dy)
			if g != you and db.maps.is_walkable(area, g) and not avoid.has(g) and db.maps.exit_at(area, g).is_empty():
				goals[g] = true
	if goals.is_empty():
		return
	var found := Pathfind.path(db.maps, area, NpcRoster.pos_of(n), goals, avoid)
	if not found["found"] or (found["steps"] as Array).is_empty():
		return
	var dir: String = found["steps"][0]
	var next: Vector2i = NpcRoster.pos_of(n) + (PlayerState.DIRS[dir] as Vector2i)
	n["facing"] = dir
	n["x"] = next.x
	n["y"] = next.y


## King-move distance.
static func _dist(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


## Checks rules.brawl. Returns the errors.
static func validate(db: DataDb) -> Array[String]:
	var errs: Array[String] = []
	if not db.rules.has("brawl"):
		return errs
	var r: Variant = db.rules["brawl"]
	if not r is Dictionary:
		return ["rules.brawl: must be an object."] as Array[String]
	for f: String in FIELDS:
		if not (r as Dictionary).has(f):
			errs.append("rules.brawl: missing '%s'." % f)
	if not errs.is_empty():
		return errs
	if int(r["act_seconds"]) < 1 or float(r["fate_delay"]) < 0.0:
		errs.append("rules.brawl: act_seconds >= 1, fate_delay >= 0.")
	if not r["fate_lines"] is Array or (r["fate_lines"] as Array).is_empty():
		errs.append("rules.brawl.fate_lines: needs at least one line.")
	for row: String in ["attack", "kill"]:
		if not r[row] is Dictionary:
			errs.append("rules.brawl.%s: must be an object." % row)
			continue
		for k: String in COSTS:
			if not (r[row] as Dictionary).has(k) or int(r[row][k]) > 0:
				errs.append("rules.brawl.%s: '%s' is a cost, 0 or below." % [row, k])
	return errs
