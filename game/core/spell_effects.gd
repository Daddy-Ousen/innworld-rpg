## Spells that do something other than damage (M33.0, ADR 0044). A spell's
## "effect" (default "damage") picks what Spells.use does with the tiles it reaches:
## - "hold" (shape "one", "rounds"): the foe hit loses its next `rounds` turns
##   ([Astral Binding]). A "roll" spell can miss.
## - "blink" (shape "tile", "range"): the player jumps to a free tile in range and
##   in sight ([Flash Step]). Free = the player could step there; not an exit.
## - "hide" (shape "self", "rounds"): monsters cannot pick the player as a target
##   for `rounds` rounds ([Invisibility]). A blow, Skill or spell that strikes a
##   foe ends it at once (Commands._encounter_act_q).
## - "wall" (shape "tile", "range", "length", "rounds"): ice on up to `length` free
##   tiles across the aim tile (square to the line from the caster) for `rounds`
##   rounds ([Ice Wall]). No one can step onto it; a ranged attack across it
##   meets full cover. It does not block sight.
## The state lives in combat.encounter ("held": {monster id: rounds}, "hidden":
## rounds, "walls": [[x, y, rounds]]), so it ends with the fight and saves with
## it (no save version change). Rounds count down at the start of the player's
## turn (hide, walls) or the held foe's turn (hold).
class_name SpellEffects
extends RefCounted

const DAMAGE := "damage"
const HOLD := "hold"
const BLINK := "blink"
const HIDE := "hide"
const WALL := "wall"
const EFFECTS := [DAMAGE, HOLD, BLINK, HIDE, WALL]
## The shape each non-damage effect must have.
const SHAPE_OF := {HOLD: "one", BLINK: "tile", HIDE: "self", WALL: "tile"}

const NO_LANDING := "You cannot land there."
const NO_ROOM := "There is no room for a wall there."


static func effect(s: Dictionary) -> String:
	return String(s.get("effect", DAMAGE))


static func is_damage(s: Dictionary) -> bool:
	return effect(s) == DAMAGE


# --- hold ---

## Spell `sid` binds monster `foe` (a "roll" spell rolls to hit, like a damage spell).
static func hold(gs: GameState, db: DataDb, sid: String, foe: String) -> void:
	var c := gs.combat
	var s := Spells.spell(db, sid)
	var m: Dictionary = c.monsters[foe]
	var who := Combat.name_of(db, m)
	if [CombatState.HIDDEN, CombatState.IDLE, CombatState.HOME].has(m["state"]):
		m["state"] = CombatState.HOSTILE
	Combat.join(gs, foe)
	var roll := gs.rng.randf()
	if String(s["hit"]) != "auto" and roll >= Spells.hit_chance(gs, db, sid, foe):
		c.lines.append("Your %s misses the %s." % [Spells.name_of(db, sid), who])
		return
	var held: Dictionary = c.encounter.get("held", {})
	held[foe] = maxi(int(held.get(foe, 0)), int(s["rounds"]))
	c.encounter["held"] = held
	c.lines.append("Bands of light hold the %s fast." % who)


## Monster `id` starts its turn: true (and one round less) if it is held, so it
## does nothing this turn.
static func skip_held(gs: GameState, db: DataDb, id: String) -> bool:
	var held: Dictionary = gs.combat.encounter.get("held", {})
	if not held.has(id) or not gs.combat.monsters.has(id):
		return false
	var left := int(held[id]) - 1
	if left <= 0:
		held.erase(id)
	else:
		held[id] = left
	gs.combat.lines.append("The %s strains against the binding." % Combat.name_of(db, gs.combat.monsters[id]))
	return true


# --- blink ---

## Why the player cannot blink to `aim` ("" = they can): free, not an exit.
static func landing_error(gs: GameState, db: DataDb, aim: Vector2i) -> String:
	var area := gs.player.area
	if aim == gs.player.pos() or not Movement.can_enter(gs, db, area, aim) \
			or not db.maps.exit_at(area, aim).is_empty():
		return NO_LANDING
	return ""


static func blink(gs: GameState, aim: Vector2i) -> void:
	gs.player.place(gs.player.area, aim)
	gs.combat.lines.append("You flash across the ground.")


# --- hide ---

static func hide(gs: GameState, db: DataDb, sid: String) -> void:
	gs.combat.encounter["hidden"] = int(Spells.spell(db, sid)["rounds"])
	gs.combat.lines.append("You fade from sight.")


static func hidden(gs: GameState) -> bool:
	return int(gs.combat.encounter.get("hidden", 0)) > 0


## The player struck a foe: they are seen again.
static func reveal(gs: GameState) -> void:
	if hidden(gs):
		gs.combat.encounter.erase("hidden")
		gs.combat.lines.append("You can be seen again.")


# --- wall ---

## The tiles an ice wall from `origin` aimed at `aim` covers: up to `length`
## tiles across the aim tile, square to the caster's side (Spells.direction),
## each free (the player could step there, no exit, not the caster's tile).
static func wall_cells(gs: GameState, db: DataDb, sid: String, aim: Vector2i, origin: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var dir := Spells.direction(origin, aim)
	if dir == Vector2i.ZERO:
		return out
	var across := Vector2i(dir.y, dir.x)
	@warning_ignore("integer_division")
	var half := int(Spells.spell(db, sid)["length"]) / 2
	var area := gs.player.area
	for k in range(-half, int(Spells.spell(db, sid)["length"]) - half):
		var at := aim + across * k
		if at != origin and Movement.can_enter(gs, db, area, at) and db.maps.exit_at(area, at).is_empty():
			out.append(at)
	return out


static func wall(gs: GameState, db: DataDb, sid: String, tiles: Array[Vector2i]) -> void:
	var walls: Array = gs.combat.encounter.get("walls", [])
	var rounds := int(Spells.spell(db, sid)["rounds"])
	for at in tiles:
		walls.append([at.x, at.y, rounds])
	gs.combat.encounter["walls"] = walls
	gs.combat.lines.append("A wall of ice rises.")


## The ice tiles in the player's area now (fights happen there).
static func wall_tiles(gs: GameState) -> Dictionary:
	var out := {}
	for w: Array in gs.combat.encounter.get("walls", []):
		out[Vector2i(int(w[0]), int(w[1]))] = true
	return out


static func is_wall(gs: GameState, area: String, at: Vector2i) -> bool:
	return area == gs.player.area and wall_tiles(gs).has(at)


## True if an ice tile stands strictly between `from` and `target`.
static func walled(gs: GameState, area: String, from: Vector2i, target: Vector2i) -> bool:
	if area != gs.player.area:
		return false
	var ice := wall_tiles(gs)
	if ice.is_empty():
		return false
	for at in Cover.line(from, target):
		if ice.has(at):
			return true
	return false


# --- rounds ---

## The player's turn starts: hide and ice count down one round.
static func player_turn_starts(gs: GameState) -> void:
	var e := gs.combat.encounter
	if e.has("hidden"):
		var left := int(e["hidden"]) - 1
		if left <= 0:
			e.erase("hidden")
			gs.combat.lines.append("You can be seen again.")
		else:
			e["hidden"] = left
	if e.has("walls"):
		var kept: Array = []
		for w: Array in e["walls"]:
			if int(w[2]) > 1:
				kept.append([int(w[0]), int(w[1]), int(w[2]) - 1])
		if kept.size() < (e["walls"] as Array).size():
			gs.combat.lines.append("The ice wall melts away." if kept.is_empty() else "Part of the ice wall melts.")
		if kept.is_empty():
			e.erase("walls")
		else:
			e["walls"] = kept
