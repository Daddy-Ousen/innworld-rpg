## Turn-based combat on the world grid (M5, ADR 0010). There is no combat
## mode: every player command is one turn of world.step_seconds, and the
## monsters act after it (MonsterSim). The fight keeps counts; when it
## ends, end_fight writes one action record per kind of action used, so the
## System sees attack / block / throw / improvise / flee without a record
## per turn. All rolls go through gs.rng.
## M7.B (ADR 0013): NPCs who fight have hit points and fall at 0 (down, not
## dead: only the director kills); hostile monsters go for the nearest of
## the player, a fighting NPC and a helper (a monster in state "ally" that
## fights for the player). A fight's end stands the fallen up and sends the
## helpers away.
class_name Combat
extends RefCounted

const WON := "won"
const FLED := "fled"
const KNOCKED_OUT := "knocked_out"
const OUTCOMES := {WON: "success", FLED: "partial", KNOCKED_OUT: "fail"}
const REFUSED_DANGER := "Not with enemies near."
const REFUSED_DOWN := "You are knocked out."
const REFUSED_TIRED := "You are too tired."
const KNOCKED_OUT_LINE := "You are knocked out."
const REFUSED_HELPER := "The %s fights on your side."
## monster_target kinds.
const PLAYER := "player"
const NPC := "npc"
const HELPER := "helper"


## Every command starts here: last command's combat text goes, and a
## raised guard drops (block lasts one turn).
static func begin_command(gs: GameState) -> void:
	gs.combat.lines.clear()
	gs.combat.blocking = false


## Current hit points.
static func hp(gs: GameState, db: DataDb) -> int:
	var most := Stats.max_hp(gs, db)
	return most if gs.player.hp < 0 else mini(gs.player.hp, most)


## Sets hit points, clamped to 0..max. Full is stored as -1.
static func set_hp(gs: GameState, db: DataDb, value: int) -> void:
	gs.player.hp = -1 if value >= Stats.max_hp(gs, db) else maxi(value, 0)


static func is_down(gs: GameState) -> bool:
	return gs.player.hp == 0


## A fight is on and at least one monster is still hostile.
static func in_danger(gs: GameState) -> bool:
	return gs.combat.has_fight() and not gs.combat.in_state(CombatState.HOSTILE).is_empty()


## Why a non-combat command (an action, a use, a sleep) is refused now, or "".
static func refusal(gs: GameState) -> String:
	if is_down(gs):
		return REFUSED_DOWN
	if in_danger(gs):
		return REFUSED_DANGER
	return ""


## Adds a monster of `type` at `pos` in the player's area. Returns its id,
## or "" for an unknown type. A hostile monster starts (or joins) the fight.
static func add_monster(gs: GameState, db: DataDb, type: String, pos: Vector2i,
		state: String = CombatState.HOSTILE, spawn: String = "", group: String = "") -> String:
	if not db.combat.enemies.has(type) or not CombatState.STATES.has(state):
		return ""
	var c := gs.combat
	var id := "m%d" % c.next_id
	c.next_id += 1
	c.monsters[id] = {"type": type, "spawn": spawn, "group": group if group != "" else id,
		"area": gs.player.area, "x": pos.x, "y": pos.y, "hp": int(db.combat.enemies[type]["hp"]),
		"state": state, "home_x": pos.x, "home_y": pos.y, "carry": 0, "chase": 0, "scared": 0,
		"rolled_spot": false, "pack": 1, "stage": ""}
	if state == CombatState.HOSTILE:
		join(gs, id)
	return id


## Starts the fight if there is none, and counts monster `id` in it.
static func join(gs: GameState, id: String) -> void:
	var c := gs.combat
	if not c.has_fight():
		c.fight = {"start": gs.clock.total_minutes, "foes": {}, "attacks": 0, "improvised": 0,
			"blocks": 0, "throws": 0, "kills": 0, "routed": 0}
	c.fight["foes"][id] = c.monsters[id]["type"]


## A monster's name for the combat text ("allied Goblin" for a helper).
static func name_of(db: DataDb, m: Dictionary) -> String:
	var kind := String(db.combat.enemies[m["type"]]["name"])
	return "allied " + kind if m["state"] == CombatState.ALLY else kind


static func npc_name(db: DataDb, id: String) -> String:
	return String(db.canon.npcs.get(id, {}).get("name", id))


## Current hit points of NPC `id` (in the roster); max from NpcReact.stats.
static func npc_hp(gs: GameState, db: DataDb, id: String) -> int:
	var n: Dictionary = gs.npcs.npcs[id]
	var most := int(NpcReact.stats(db, id)["hp"])
	return most if int(n["hp"]) < 0 else mini(int(n["hp"]), most)


## NPC `id` takes `amount` damage. At 0 HP it is down ("X falls."): it lies
## still until the fight ends. Returns true if it fell.
static func damage_npc(gs: GameState, db: DataDb, id: String, amount: int) -> bool:
	var n: Dictionary = gs.npcs.npcs[id]
	if bool(n.get("down", false)) or amount <= 0:
		return false
	var left := npc_hp(gs, db, id) - amount
	if left > 0:
		n["hp"] = left
		return false
	n["hp"] = 0
	n["down"] = true
	gs.combat.lines.append("%s falls." % npc_name(db, id))
	return true


## Who hostile monster `id` goes for: the nearest (king moves) of the
## player (not down), a standing NPC in the area who fights
## (NpcReact.is_fighter) and a helper. Ties: the player, then NPCs by id,
## then helpers by id. Returns {"kind": PLAYER | NPC | HELPER, "id", "pos"},
## or {} if there is no one.
static func monster_target(gs: GameState, db: DataDb, id: String) -> Dictionary:
	var from := CombatState.pos_of(gs.combat.monsters[id])
	var area := gs.player.area
	var cands: Array[Dictionary] = []
	if not is_down(gs):
		cands.append({"kind": PLAYER, "id": "", "pos": gs.player.pos()})
	for nid in gs.npcs.in_area(area):
		var n: Dictionary = gs.npcs.npcs[nid]
		if not bool(n.get("down", false)) and NpcReact.is_fighter(gs, db, nid):
			cands.append({"kind": NPC, "id": nid, "pos": NpcRoster.pos_of(n)})
	for hid in gs.combat.in_state(CombatState.ALLY):
		var h: Dictionary = gs.combat.monsters[hid]
		if h["area"] == area:
			cands.append({"kind": HELPER, "id": hid, "pos": CombatState.pos_of(h)})
	var best := {}
	var best_d := 0
	for c: Dictionary in cands:
		var d := _dist(from, c["pos"])
		if best.is_empty() or d < best_d:
			best = c
			best_d = d
	return best


## The monster to throw at (M5.3): the nearest seen (not hidden) monster in
## the player's area, hostile ones first. Ties go to the lower id. "" if none.
static func nearest_foe(gs: GameState) -> String:
	var best := ""
	var best_rank := 0
	for id in gs.combat.ids():
		var m: Dictionary = gs.combat.monsters[id]
		if m["area"] != gs.player.area or m["state"] == CombatState.HIDDEN \
				or m["state"] == CombatState.ALLY:
			continue
		var rank := _dist(gs.player.pos(), CombatState.pos_of(m)) \
				+ (0 if m["state"] == CombatState.HOSTILE else 100000)
		if best == "" or rank < best_rank:
			best = id
			best_rank = rank
	return best


static func hit_chance(db: DataDb, accuracy: int, evasion: int, bonus: float = 0.0) -> float:
	var h: Dictionary = db.rules["combat"]["hit"]
	return clampf(float(h["base"]) + float(h["per_point"]) * (accuracy - evasion) + bonus,
			float(h["min"]), float(h["max"]))


static func _roll(gs: GameState, r: Array) -> int:
	return gs.rng.randi_range(int(r[0]), int(r[1]))


## Why the player cannot take a combat turn now, or "".
static func _cannot_act(gs: GameState, db: DataDb) -> String:
	if is_down(gs):
		return REFUSED_DOWN
	if gs.clock.is_collapse_due(db.rules["clock"]):
		return REFUSED_TIRED
	return ""


## The player attacks the monster next to them in `dir` (n, s, e, w), with
## the held item or fists. Returns {"error", "target", "hit", "damage", "killed"}.
static func player_attack(gs: GameState, db: DataDb, dir: String) -> Dictionary:
	var out := {"error": _cannot_act(gs, db), "target": "", "hit": false, "damage": 0, "killed": false}
	if out["error"] != "":
		return out
	if not PlayerState.DIRS.has(dir):
		out["error"] = "Unknown direction '%s'." % dir
		return out
	gs.player.facing = dir
	var target := gs.combat.at(gs.player.area, gs.player.pos() + (PlayerState.DIRS[dir] as Vector2i))
	if target == "":
		out["error"] = "There is nothing to attack there."
		return out
	if gs.combat.monsters[target]["state"] == CombatState.ALLY:
		out["error"] = REFUSED_HELPER % String(db.combat.enemies[gs.combat.monsters[target]["type"]]["name"])
		return out
	Movement.spend_turn(gs, db)
	return _strike(gs, db, target, false, 1)


## The player throws the held item at monster `id` (within the item's
## throw_range, counted in king moves). The item is gone either way.
static func throw_at(gs: GameState, db: DataDb, id: String) -> Dictionary:
	var out := {"error": _cannot_act(gs, db), "target": id, "hit": false, "damage": 0, "killed": false}
	if out["error"] != "":
		return out
	var c := gs.combat
	if gs.player.held == "":
		out["error"] = "You hold nothing to throw."
		return out
	if not c.monsters.has(id) or c.monsters[id]["area"] != gs.player.area:
		out["error"] = "There is no '%s' here." % id
		return out
	if c.monsters[id]["state"] == CombatState.ALLY:
		out["error"] = REFUSED_HELPER % String(db.combat.enemies[c.monsters[id]["type"]]["name"])
		return out
	var dist := _dist(gs.player.pos(), CombatState.pos_of(c.monsters[id]))
	if dist > int(db.combat.items[gs.player.held]["throw_range"]):
		out["error"] = "Too far to throw."
		return out
	Movement.spend_turn(gs, db)
	return _strike(gs, db, id, true, dist)


## One attack by the player. Attacking wakes a hidden or calm monster.
static func _strike(gs: GameState, db: DataDb, id: String, thrown: bool, dist: int) -> Dictionary:
	var c := gs.combat
	var rules: Dictionary = db.rules["combat"]
	var m: Dictionary = c.monsters[id]
	var e: Dictionary = db.combat.enemies[m["type"]]
	var who := name_of(db, m)
	if [CombatState.HIDDEN, CombatState.IDLE, CombatState.HOME].has(m["state"]):
		m["state"] = CombatState.HOSTILE
	join(gs, id)
	var held := gs.player.held
	var item: Dictionary = db.combat.items.get(held, {})
	var f: Dictionary = c.fight
	if thrown:
		f["throws"] += 1
	else:
		f["attacks"] += 1
		if not item.is_empty():
			f["improvised"] += 1
	var bonus := -float(rules["hit"]["throw_per_tile"]) * (dist - 1) if thrown else 0.0
	var dex := Stats.get_stat(gs, db, "dexterity")
	var out := {"error": "", "target": id, "hit": false, "damage": 0, "killed": false}
	out["hit"] = gs.rng.randf() < hit_chance(db, dex, int(e["evasion"]), bonus)
	var what := "The %s" % String(item["name"]).to_lower() if not item.is_empty() else "You"
	if out["hit"]:
		var weapon: Array = rules["unarmed"]["damage"]
		if not item.is_empty():
			weapon = item["throw"] if thrown else item["melee"]
		@warning_ignore("integer_division")
		var dmg := _roll(gs, weapon) + Stats.get_stat(gs, db, "strength") / int(rules["strength_div"]) \
				- int(e["armor"])
		out["damage"] = maxi(dmg, int(rules["min_damage"]))
		c.lines.append("%s %s the %s for %d." % [what, "hits" if what != "You" else "hit", who, out["damage"]])
		out["killed"] = damage_monster(gs, db, id, out["damage"])
	else:
		c.lines.append("%s %s the %s." % [what, "misses" if what != "You" else "miss", who])
	if not item.is_empty() and not out["killed"] and (thrown or out["hit"]) and _scares(item, e):
		m["state"] = CombatState.FLEE
		m["scared"] = int(e["scare_turns"])
		c.fight["routed"] += 1
		c.lines.append("The %s panics and backs away." % who)
	if thrown:
		gs.player.held = ""
	elif out["hit"] and not item.is_empty() and float(item["break_chance"]) > 0.0 \
			and gs.rng.randf() < float(item["break_chance"]):
		gs.player.held = ""
		c.lines.append("The %s breaks." % String(item["name"]).to_lower())
	return out


static func _scares(item: Dictionary, e: Dictionary) -> bool:
	for tag: Variant in item["tags"]:
		if (e["scared_by"] as Array).has(tag):
			return true
	return false


## The player raises their guard for this turn. Returns "" or an error.
static func block(gs: GameState, db: DataDb) -> String:
	var err := _cannot_act(gs, db)
	if err != "":
		return err
	gs.combat.blocking = true
	Movement.spend_turn(gs, db)
	gs.combat.lines.append("You raise your guard.")
	return ""


## The player puts the held item down (it is gone). Returns "" or an error.
static func drop(gs: GameState, db: DataDb) -> String:
	var err := _cannot_act(gs, db)
	if err != "":
		return err
	if gs.player.held == "":
		return "You hold nothing."
	gs.combat.lines.append("You put the %s down." % String(db.combat.items[gs.player.held]["name"]).to_lower())
	gs.player.held = ""
	Movement.spend_turn(gs, db)
	return ""


## Monster `id` attacks the player (`ranged`: its ranged attack), or the
## `target` from monster_target (M7.B). The player's raised guard lowers the
## hit chance and halves the damage. Returns {"hit", "damage"}.
static func monster_attack(gs: GameState, db: DataDb, id: String, ranged: bool = false,
		bonus: float = 0.0, target: Dictionary = {}) -> Dictionary:
	if target.get("kind", PLAYER) != PLAYER:
		return _attack_other(gs, db, id, ranged, target)
	var c := gs.combat
	var rules: Dictionary = db.rules["combat"]
	var m: Dictionary = c.monsters[id]
	var e: Dictionary = db.combat.enemies[m["type"]]
	var who := name_of(db, m)
	join(gs, id)
	if c.blocking:
		bonus -= float(rules["block"]["hit_malus"])
		c.fight["blocks"] += 1
	var out := {"hit": false, "damage": 0}
	out["hit"] = gs.rng.randf() < hit_chance(db, int(e["accuracy"]),
			Stats.get_stat(gs, db, "dexterity"), bonus)
	var how := "throws a stone at you" if ranged else "attacks you"
	if not out["hit"]:
		c.lines.append("The %s %s and misses." % [who, how])
		return out
	var dmg := maxi(_roll(gs, e["ranged"]["damage"] if ranged else e["damage"]), int(rules["min_damage"]))
	if c.blocking:
		dmg = floori(dmg * float(rules["block"]["damage_mult"]))
	out["damage"] = dmg
	c.lines.append("The %s %s: %d damage%s." % [who, how, dmg, " (blocked)" if c.blocking else ""])
	damage_player(gs, db, dmg)
	return out


## Monster `id` attacks a fighting NPC or a helper (see monster_target):
## its accuracy against their evasion, its damage minus their armor.
static func _attack_other(gs: GameState, db: DataDb, id: String, ranged: bool,
		target: Dictionary) -> Dictionary:
	var c := gs.combat
	var rules: Dictionary = db.rules["combat"]
	var e: Dictionary = db.combat.enemies[c.monsters[id]["type"]]
	var who := name_of(db, c.monsters[id])
	join(gs, id)
	var tid: String = target["id"]
	var stats: Dictionary
	var victim: String
	if target["kind"] == NPC:
		stats = NpcReact.stats(db, tid)
		victim = npc_name(db, tid)
	else:
		stats = db.combat.enemies[c.monsters[tid]["type"]]
		victim = "the " + name_of(db, c.monsters[tid])
	var out := {"hit": false, "damage": 0}
	out["hit"] = gs.rng.randf() < hit_chance(db, int(e["accuracy"]), int(stats["evasion"]))
	var how := "throws a stone at" if ranged else "attacks"
	if not out["hit"]:
		c.lines.append("The %s %s %s and misses." % [who, how, victim])
		return out
	var dmg := maxi(_roll(gs, e["ranged"]["damage"] if ranged else e["damage"]) - int(stats["armor"]),
			int(rules["min_damage"]))
	out["damage"] = dmg
	c.lines.append("The %s %s %s: %d damage." % [who, how, victim, dmg])
	if target["kind"] == NPC:
		damage_npc(gs, db, tid, dmg)
	else:
		damage_monster(gs, db, tid, dmg)
	return out


## Helper `id` (state ally) hits the hostile monster `foe` next to it: its
## accuracy against the foe's evasion, its damage minus the foe's armor.
## A kill counts for the fight. Returns true if the foe died.
static func helper_attack(gs: GameState, db: DataDb, id: String, foe: String) -> bool:
	var c := gs.combat
	var e: Dictionary = db.combat.enemies[c.monsters[id]["type"]]
	var f: Dictionary = db.combat.enemies[c.monsters[foe]["type"]]
	var who := name_of(db, c.monsters[id])
	var what := name_of(db, c.monsters[foe])
	join(gs, foe)
	if gs.rng.randf() >= hit_chance(db, int(e["accuracy"]), int(f["evasion"])):
		c.lines.append("The %s misses the %s." % [who, what])
		return false
	var dmg := maxi(_roll(gs, e["damage"]) - int(f["armor"]), int(db.rules["combat"]["min_damage"]))
	c.lines.append("The %s hits the %s for %d." % [who, what, dmg])
	return damage_monster(gs, db, foe, dmg)


static func damage_player(gs: GameState, db: DataDb, amount: int) -> void:
	if amount <= 0 or is_down(gs):
		return
	set_hp(gs, db, hp(gs, db) - amount)
	if is_down(gs):
		gs.combat.lines.append(KNOCKED_OUT_LINE)


## Returns true if the monster died (it is removed; a foe counts as a kill,
## a helper does not).
static func damage_monster(gs: GameState, db: DataDb, id: String, amount: int) -> bool:
	var c := gs.combat
	var m: Dictionary = c.monsters[id]
	m["hp"] = int(m["hp"]) - amount
	if int(m["hp"]) > 0:
		return false
	c.lines.append("The %s dies." % name_of(db, m))
	var foe: bool = m["state"] != CombatState.ALLY
	c.monsters.erase(id)
	if c.has_fight() and foe:
		c.fight["kills"] += 1
	return true


## Ends the fight (WON, FLED or KNOCKED_OUT) and writes its action records:
## melee with fists, melee with a held item (context weapon "improvised"),
## blocks and throws, each once with intensity = count / count_per_intensity;
## plus flee_danger when the player got away. Risk = the most dangerous
## foe's danger. Every record's context has "enemy" (that foe's type),
## "location" and "killed" (a foe died, by anyone's hand; M6.5). A won fight
## where foes ran and none died, against a foe with a combat.spare_tags tag,
## adds spare_foe (the player let them go). Records take no time (the turns
## already did). Returns them.
static func end_fight(gs: GameState, db: DataDb, cause: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var c := gs.combat
	if not c.has_fight():
		return out
	var f: Dictionary = c.fight
	c.fight = {}
	var danger := 0.0
	var enemy := ""
	var foe_ids: Array = (f["foes"] as Dictionary).keys()
	foe_ids.sort_custom(func(a: String, b: String) -> bool: return a.substr(1).to_int() < b.substr(1).to_int())
	for id: String in foe_ids:
		var type: String = f["foes"][id]
		var d := float(db.combat.enemies.get(type, {}).get("danger", 0.0))
		if enemy == "" or d > danger:
			danger = d
			enemy = type
	var xp_rules: Dictionary = db.rules["combat"]["xp"]
	var killed := int(f["kills"]) > 0
	var base := {"enemy": enemy, "location": Movement.location_at(gs, db), "killed": killed}
	var improvised := base.merged({"weapon": "improvised"})
	var parts := [
		["attack_melee", int(f["attacks"]) - int(f["improvised"]), base],
		["attack_melee", int(f["improvised"]), improvised],
		["block_attack", int(f["blocks"]), base],
		["throw_object", int(f["throws"]), improvised],
	]
	for part: Array in parts:
		if int(part[1]) <= 0:
			continue
		var intensity := minf(float(part[1]) / float(xp_rules["count_per_intensity"]),
				float(xp_rules["max_intensity"]))
		out.append_array(_record(gs, db, part[0], intensity, danger, OUTCOMES[cause], part[2]))
	if cause == FLED:
		out.append_array(_record(gs, db, "flee_danger", 1.0, danger, "success", base))
		c.lines.append("You got away.")
	elif cause == WON:
		if not killed and int(f["routed"]) > 0 and _spares(db, (f["foes"] as Dictionary).values()):
			out.append_array(_record(gs, db, "spare_foe", 1.0, danger, "success", base))
			c.lines.append("You let them go.")
		c.lines.append("The fight is over.")
	after_fight(gs)
	return out


## The fight is over (any end): fallen NPCs get up with 1 HP, helpers
## leave, and the staged fight (its waves) is done.
static func after_fight(gs: GameState) -> void:
	var c := gs.combat
	for id: String in gs.npcs.npcs:
		var n: Dictionary = gs.npcs.npcs[id]
		if bool(n.get("down", false)):
			n["down"] = false
			n["hp"] = 1
	for id in c.in_state(CombatState.ALLY):
		c.monsters.erase(id)
	c.stage_run = {}


## True if an enemy type in `types` has a tag in rules.combat.spare_tags.
static func _spares(db: DataDb, types: Array) -> bool:
	var tags: Array = db.rules["combat"]["spare_tags"]
	for type: Variant in types:
		for t: Variant in db.combat.enemies.get(type, {}).get("tags", []):
			if tags.has(t):
				return true
	return false


static func _record(gs: GameState, db: DataDb, action_id: String, intensity: float, risk: float,
		outcome: String, context: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not db.actions.has(action_id):
		return out
	var rec := Actions.perform(gs, db, action_id, {"minutes": 0, "intensity": intensity, "risk": risk,
		"outcome": outcome, "context": context.duplicate(), "allow_collapsed": true})
	if not rec.is_empty():
		out.append(rec)
	return out


## Bookkeeping after every command (Commands._after): leaving the area
## ends the fight as fled and the monsters stay behind (they are gone);
## then the monsters act and spawn (MonsterSim.run); a fight with no
## hostile or fleeing monster left ends (see settle_fight).
static func sync(gs: GameState, db: DataDb) -> void:
	var c := gs.combat
	var now := NpcSim.world_sec(gs)
	var entered := c.area != gs.player.area
	if entered:
		if c.has_fight():
			end_fight(gs, db, FLED)
		c.monsters.clear()
		c.area = gs.player.area
	MonsterSim.run(gs, db, now, entered)
	settle_if_over(gs, db)
	c.sec = now


## Ends a fight with no hostile or fleeing monster left (see settle_fight).
## Commands._after calls it again after the NPCs, who may kill the last foe.
## A staged fight with waves still to come (M7.B) is not over.
static func settle_if_over(gs: GameState, db: DataDb) -> void:
	var c := gs.combat
	if c.has_fight() and not is_down(gs) and c.in_state(CombatState.HOSTILE).is_empty() \
			and c.in_state(CombatState.FLEE).is_empty() and not Stage.waves_left(gs, db):
		settle_fight(gs, db)


## Ends a fight that is not lost: won if any foe died or ran off, else fled
## (they gave up the chase). Commands.sleep calls it before the night.
static func settle_fight(gs: GameState, db: DataDb) -> void:
	if not gs.combat.has_fight():
		return
	var f := gs.combat.fight
	end_fight(gs, db, WON if int(f["kills"]) + int(f["routed"]) > 0 else FLED)


## Night step (Night.run): monsters and the fight are gone; the player
## heals (a sleep to night_heal.sleep of max HP, a collapse to
## night_heal.collapse, a knock-out to knockout.wake_hp_frac); a knocked-out
## player wakes at the nearest safe place (knockout.wake, by area).
static func night(gs: GameState, db: DataDb, collapsed: bool, knocked_out: bool) -> void:
	var c := gs.combat
	var rules: Dictionary = db.rules["combat"]
	c.monsters.clear()
	c.fight = {}
	c.stage_run = {}
	c.blocking = false
	var share := float(rules["night_heal"]["sleep"])
	if knocked_out:
		share = float(rules["knockout"]["wake_hp_frac"])
	elif collapsed:
		share = float(rules["night_heal"]["collapse"])
	var target := maxi(ceili(Stats.max_hp(gs, db) * share), 1)
	set_hp(gs, db, maxi(hp(gs, db), target))
	if knocked_out:
		var w: Dictionary = rules["knockout"]["wake"].get(gs.player.area, {})
		if not w.is_empty() and db.maps.areas.has(w["area"]):
			gs.player.place(w["area"], Vector2i(int(w["pos"][0]), int(w["pos"][1])))
	c.area = gs.player.area


## The player takes the item of the nearby map object `object_id` (see
## Interact.options). A held item is put down first (it is gone). One turn.
## Returns "" or an error.
static func take(gs: GameState, db: DataDb, object_id: String) -> String:
	var err := _cannot_act(gs, db)
	if err != "":
		return err
	var found := {}
	for o: Dictionary in Interact.options(gs, db):
		if o["id"] == object_id and not o["npc"]:
			found = o
			break
	if found.is_empty():
		return "There is no '%s' here." % object_id
	if found["item"] == "":
		return "There is nothing to take at the %s." % String(found["name"]).to_lower()
	var c := gs.combat
	if gs.player.held != "":
		c.lines.append("You put the %s down." % String(db.combat.items[gs.player.held]["name"]).to_lower())
	gs.player.held = found["item"]
	c.lines.append("You take the %s." % String(db.combat.items[gs.player.held]["name"]).to_lower())
	Movement.spend_turn(gs, db)
	return ""


## Heals after an action in rules.combat.heal_actions (bandage_wound).
static func heal_after_action(gs: GameState, db: DataDb, rec: Dictionary) -> void:
	if rec.is_empty():
		return
	var amount := int(db.rules["combat"]["heal_actions"].get(rec["action_id"], 0))
	if amount <= 0:
		return
	var before := hp(gs, db)
	set_hp(gs, db, before + amount)
	if hp(gs, db) > before:
		gs.combat.lines.append("You recover %d HP." % (hp(gs, db) - before))


## King-move distance.
static func _dist(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))
