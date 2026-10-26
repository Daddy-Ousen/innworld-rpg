## Enemy abilities (M17.7, ADR 0027): the optional list `abilities` on an enemy
## in data/enemies.json, `[{"kind": ..., ...}]`. Three kinds were planned; the
## user asked for no shell, so two were built; M32.3 (ADR 0044) adds three for the bosses:
## - "shooter": the monster fights from range. It seeks cover and holds it (M17.6,
##   Encounter._hostile_turn). Needs a `ranged` entry.
## - "leap": {"name"?, "range" >= 2, "ap_q" 1..40, "cooldown" >= 0 rounds}. When its
##   target is not side by side and the leap is ready, the monster jumps to a free
##   tile beside the target (within `range`, king distance, with sight) for `ap_q`;
##   the move cap does not apply. Then it hits with the AP left. The cooldown
##   table is the encounter's (`encounter.cool`, key "ability:leap"); no new save state.
## - "fear" (M32.3): {"name"?, "range" >= 1, "ap_q" 1..40}. At the start of the
##   player's turn, a hostile monster with fear in sight within `range` takes
##   `ap_q` of the player's AP. Several do not add up: the biggest counts.
## - "bile" (M32.3): {"name"?, "range" >= 1, "ap_q" 1..40, "cooldown" >= 0,
##   "chance" 0..1, "rounds" >= 1, "damage" [lo, hi]}. A spit at its target in
##   sight within `range` (before it walks or hits); on a hit the target is
##   poisoned: at the start of each of its next `rounds` turns it takes a
##   `damage` roll (no armor). The poison lives in `encounter.poison`
##   ({fighter id: {"rounds", "damage"}}) and ends with the encounter. A new
##   spit sets the rounds again; it does not add up.
## - "command" (M32.3): {"name"?, "radius" >= 1, "accuracy" >= 0, "tag"}.
##   Every other hostile monster with `tag` within `radius` (king distance) of a
##   hostile commander gets +`accuracy` to hit and does not run away
##   (flee_below). The best command counts; none on the commander itself.
## All numbers are guesses (the enemy's confidence says so).
class_name MonsterAbilities
extends RefCounted

const SHOOTER := "shooter"
const LEAP := "leap"
const FEAR := "fear"
const BILE := "bile"
const COMMAND := "command"
const KINDS := [SHOOTER, LEAP, FEAR, BILE, COMMAND]
const KEY := "ability:"


## The first ability of `kind` on enemy `e`, or {}.
static func find(e: Dictionary, kind: String) -> Dictionary:
	for a: Variant in e.get("abilities", []):
		if a is Dictionary and a.get("kind", "") == kind:
			return a
	return {}


static func is_shooter(e: Dictionary) -> bool:
	return not find(e, SHOOTER).is_empty()


## Problems with enemy `e`'s abilities (for CombatDb).
static func check(where: String, e: Dictionary) -> Array[String]:
	var out: Array[String] = []
	if not e.has("abilities"):
		return out
	if not e["abilities"] is Array:
		out.append("%s abilities: must be a list." % where)
		return out
	var seen := {}
	for a: Variant in e["abilities"]:
		if not a is Dictionary or not KINDS.has(a.get("kind", "")):
			out.append("%s abilities: each needs a kind of %s." % [where, KINDS])
			continue
		var kind: String = a["kind"]
		if seen.has(kind):
			out.append("%s abilities: '%s' twice." % [where, kind])
		seen[kind] = true
		if a.has("name") and not a["name"] is String:
			out.append("%s ability %s: name must be text." % [where, kind])
		match kind:
			SHOOTER:
				if not e.has("ranged"):
					out.append("%s ability shooter: needs a ranged entry." % where)
			LEAP:
				if _numbers(out, where, kind, a, ["range", "ap_q", "cooldown"]):
					if int(a["range"]) < 2:
						out.append("%s ability leap: range must be >= 2." % where)
					_check_ap(out, where, kind, a)
					_check_cooldown(out, where, kind, a)
			FEAR:
				if _numbers(out, where, kind, a, ["range", "ap_q"]):
					_check_at_least_1(out, where, kind, a, "range")
					_check_ap(out, where, kind, a)
			BILE:
				if _numbers(out, where, kind, a, ["range", "ap_q", "cooldown", "chance", "rounds"]):
					_check_at_least_1(out, where, kind, a, "range")
					_check_at_least_1(out, where, kind, a, "rounds")
					_check_ap(out, where, kind, a)
					_check_cooldown(out, where, kind, a)
					if float(a["chance"]) < 0.0 or float(a["chance"]) > 1.0:
						out.append("%s ability bile: chance must be 0 to 1." % where)
				var dmg: Variant = a.get("damage")
				if not dmg is Array or dmg.size() != 2 or not (dmg[0] is int or dmg[0] is float) \
						or not (dmg[1] is int or dmg[1] is float) or int(dmg[0]) < 0 or int(dmg[1]) < int(dmg[0]):
					out.append("%s ability bile: damage must be [lo, hi] with 0 <= lo <= hi." % where)
			COMMAND:
				if _numbers(out, where, kind, a, ["radius", "accuracy"]):
					_check_at_least_1(out, where, kind, a, "radius")
					if float(a["accuracy"]) < 0.0:
						out.append("%s ability command: accuracy must be >= 0." % where)
				if not a.get("tag") is String or String(a.get("tag", "")) == "":
					out.append("%s ability command: needs a tag." % where)
	return out


## True if every key in `keys` is a number on `a`; else notes each missing one.
static func _numbers(out: Array[String], where: String, kind: String, a: Dictionary, keys: Array) -> bool:
	var complete := true
	for k: String in keys:
		if not a.has(k) or not (a[k] is int or a[k] is float):
			out.append("%s ability %s: needs a number '%s'." % [where, kind, k])
			complete = false
	return complete


static func _check_at_least_1(out: Array[String], where: String, kind: String, a: Dictionary,
		key: String) -> void:
	if int(a[key]) < 1:
		out.append("%s ability %s: %s must be >= 1." % [where, kind, key])


static func _check_ap(out: Array[String], where: String, kind: String, a: Dictionary) -> void:
	if int(a["ap_q"]) < 1 or int(a["ap_q"]) > 40:
		out.append("%s ability %s: ap_q must be 1 to 40." % [where, kind])


static func _check_cooldown(out: Array[String], where: String, kind: String, a: Dictionary) -> void:
	if int(a["cooldown"]) < 0:
		out.append("%s ability %s: cooldown must be >= 0." % [where, kind])


## True if monster `id`'s ability `kind` has no cooldown running.
static func ready(gs: GameState, id: String, kind: String) -> bool:
	return CombatSkills.rounds_left(gs, id, KEY + kind) == 0


static func leap_ready(gs: GameState, id: String) -> bool:
	return ready(gs, id, LEAP)


## The tile a leap by monster `id` at target tile `at` lands on: a free tile beside
## `at` within the leap's range, in sight; the nearest, then the lower y and x.
## {"cell"} or {}.
static func leap_spot(gs: GameState, db: DataDb, id: String, at: Vector2i, a: Dictionary) -> Dictionary:
	var m: Dictionary = gs.combat.monsters[id]
	var area: String = m["area"]
	var pos := CombatState.pos_of(m)
	var taken := MonsterSim.taken(gs, id)
	var best := {}
	var best_d := 0
	for off: Vector2i in MonsterSim.ORTHO:
		var g := at + off
		if not db.maps.is_walkable(area, g) or taken.has(g) or not db.maps.exit_at(area, g).is_empty():
			continue
		var d := MonsterSim._dist(pos, g)
		if d < 1 or d > int(a["range"]) or not Cover.sight(db, area, pos, g):
			continue
		if best.is_empty() or d < best_d or (d == best_d and (g.y < best["cell"].y
				or (g.y == best["cell"].y and g.x < best["cell"].x))):
			best = {"cell": g}
			best_d = d
	return best


## Monster `id` jumps to `cell` (leap_spot): moves it, writes the line, starts the cooldown.
static func leap(gs: GameState, db: DataDb, id: String, cell: Vector2i, a: Dictionary) -> void:
	var m: Dictionary = gs.combat.monsters[id]
	m["x"] = cell.x
	m["y"] = cell.y
	var what := String(a.get("name", "Leap")).to_lower()
	gs.combat.lines.append("The %s makes a %s at you!" % [Combat.name_of(db, m), what])
	CombatSkills.start_cooldown(gs, id, KEY + LEAP, a)


# --- fear (M32.3) ---

## The player's turn starts: the strongest fear of a hostile monster in sight
## within its range takes its ap_q from the player's AP (encounter.ap_q), with a line.
static func apply_fear(gs: GameState, db: DataDb) -> void:
	var you := gs.player.pos()
	var best := 0
	var who := ""
	var what := ""
	for id in gs.combat.ids():
		var m: Dictionary = gs.combat.monsters[id]
		if m["state"] != CombatState.HOSTILE or m["area"] != gs.player.area:
			continue
		var a := find(db.combat.enemies[m["type"]], FEAR)
		if a.is_empty() or int(a["ap_q"]) <= best:
			continue
		var pos := CombatState.pos_of(m)
		if MonsterSim._dist(pos, you) > int(a["range"]) or not Cover.sight(db, m["area"], pos, you):
			continue
		best = int(a["ap_q"])
		who = Combat.name_of(db, m)
		what = String(a.get("name", "Fear")).to_lower()
	if best == 0:
		return
	var e := gs.combat.encounter
	var lost := mini(best, int(e["ap_q"]))
	e["ap_q"] = int(e["ap_q"]) - lost
	gs.combat.lines.append("The %s fixes you with its %s. Fear takes %s AP." % [who, what,
			str(float(lost) / Encounter.Q_PER_AP).trim_suffix(".0")])


# --- bile (M32.3) ---

## Monster `id` spits bile `a` at `target` (Combat.monster_target): a `chance`
## roll; a hit poisons the target for `rounds` turns. Starts the cooldown.
static func spit(gs: GameState, db: DataDb, id: String, target: Dictionary, a: Dictionary) -> void:
	var c := gs.combat
	var who := Combat.name_of(db, c.monsters[id])
	var what := String(a.get("name", "Bile")).to_lower()
	var victim := "you"
	match target["kind"]:
		Combat.NPC:
			victim = Combat.npc_name(db, target["id"])
		Combat.HELPER:
			victim = "the " + Combat.name_of(db, c.monsters[target["id"]])
	Combat.join(gs, id)
	CombatSkills.start_cooldown(gs, id, KEY + BILE, a)
	if gs.rng.randf() >= float(a["chance"]):
		c.lines.append("The %s spits %s at %s and misses." % [who, what, victim])
		return
	var poison: Dictionary = c.encounter.get("poison", {})
	poison[Encounter._target_id(target)] = {"rounds": int(a["rounds"]),
			"damage": (a["damage"] as Array).duplicate()}
	c.encounter["poison"] = poison
	c.lines.append("The %s spits %s at %s! It burns." % [who, what, victim])


## Fighter `who` (an Encounter order id) starts its turn: its poison bites once.
static func poison_tick(gs: GameState, db: DataDb, who: String) -> void:
	var c := gs.combat
	var poison: Dictionary = c.encounter.get("poison", {})
	if not poison.has(who):
		return
	var p: Dictionary = poison[who]
	p["rounds"] = int(p["rounds"]) - 1
	if int(p["rounds"]) <= 0:
		poison.erase(who)
	var dmg := Combat._roll(gs, p["damage"])
	if dmg <= 0:
		return
	if who == Encounter.PLAYER:
		if not Combat.is_down(gs):
			c.lines.append("The poison burns: %d damage." % dmg)
			Combat.damage_player(gs, db, dmg)
	elif who.begins_with(Encounter.NPC):
		var nid := who.substr(Encounter.NPC.length())
		if gs.npcs.npcs.has(nid) and not bool(gs.npcs.npcs[nid].get("down", false)):
			c.lines.append("The poison burns %s: %d damage." % [Combat.npc_name(db, nid), dmg])
			Combat.damage_npc(gs, db, nid, dmg)
	elif c.monsters.has(who):
		c.lines.append("The poison burns the %s: %d damage." % [Combat.name_of(db, c.monsters[who]), dmg])
		Combat.damage_monster(gs, db, who, dmg)


# --- command (M32.3) ---

## The best command over hostile monster `id`: the command ability (highest
## accuracy) of another hostile monster in its area, within that command's
## radius, whose tag `id` carries. {} if none.
static func command_over(gs: GameState, db: DataDb, id: String) -> Dictionary:
	var c := gs.combat
	if not c.monsters.has(id):
		return {}
	var m: Dictionary = c.monsters[id]
	if m["state"] != CombatState.HOSTILE:
		return {}
	var tags: Array = db.combat.enemies[m["type"]].get("tags", [])
	var pos := CombatState.pos_of(m)
	var best := {}
	for cid in c.ids():
		if cid == id:
			continue
		var o: Dictionary = c.monsters[cid]
		if o["state"] != CombatState.HOSTILE or o["area"] != m["area"]:
			continue
		var a := find(db.combat.enemies[o["type"]], COMMAND)
		if a.is_empty() or not tags.has(a["tag"]) \
				or MonsterSim._dist(pos, CombatState.pos_of(o)) > int(a["radius"]):
			continue
		if best.is_empty() or float(a["accuracy"]) > float(best["accuracy"]):
			best = a
	return best


## The accuracy points a command adds to monster `id`'s blows (0 if none).
static func command_bonus(gs: GameState, db: DataDb, id: String) -> int:
	return int(command_over(gs, db, id).get("accuracy", 0))
