## Enemy abilities (M17.7, ADR 0027): the optional list `abilities` on an enemy
## in data/enemies.json, `[{"kind": ..., ...}]`. Three kinds were planned; the
## user asked for no shell, so two are built:
## - "shooter": the monster fights from range. It seeks cover and holds it (M17.6,
##   Encounter._hostile_turn). Needs a `ranged` entry.
## - "leap": {"name"?, "range" >= 2, "ap_q" 1..40, "cooldown" >= 0 rounds}. When its
##   target is not side by side and the leap is ready, the monster jumps to a free
##   tile beside the target (within `range`, king distance, with sight) for `ap_q`;
##   the move cap does not apply. Then it hits with the AP left. The cooldown
##   table is the encounter's (`encounter.cool`, key "ability:leap"); no new save state.
## All numbers are guesses (the enemy's confidence says so).
class_name MonsterAbilities
extends RefCounted

const SHOOTER := "shooter"
const LEAP := "leap"
const KINDS := [SHOOTER, LEAP]
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
				var complete := true
				for k: String in ["range", "ap_q", "cooldown"]:
					if not a.has(k) or not (a[k] is int or a[k] is float):
						out.append("%s ability leap: needs a number '%s'." % [where, k])
						complete = false
				if complete:
					if int(a.get("range", 0)) < 2:
						out.append("%s ability leap: range must be >= 2." % where)
					if int(a.get("ap_q", 0)) < 1 or int(a.get("ap_q", 0)) > 40:
						out.append("%s ability leap: ap_q must be 1 to 40." % where)
					if int(a.get("cooldown", -1)) < 0:
						out.append("%s ability leap: cooldown must be >= 0." % where)
	return out


static func leap_ready(gs: GameState, id: String) -> bool:
	return CombatSkills.rounds_left(gs, id, KEY + LEAP) == 0


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
