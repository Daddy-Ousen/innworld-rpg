## Monsters and the fight in progress (M5, ADR 0010). Part of GameState
## (save v6). Monsters only exist in the player's area; they are gone when
## the player leaves it and after a night.
##   monsters: id ("m" + number) → {"type": enemy id, "spawn": spawn id or "",
##             "group": pack id, "area", "x", "y", "hp", "state" (STATES),
##             "home_x", "home_y", "carry": world seconds not yet acted,
##             "chase": turns spent chasing, "scared": turns left scared,
##             "rolled_spot": the player already tried to spot it,
##             "pack": how many monsters its spawn placed together (1 if alone),
##             "stage": the canon event that staged it, or "" (M6.5)}.
##             State "ally" (M7.B): a helper that fights for the player.
##   fight: {} when there is none, else {"start": clock minute,
##          "foes": {monster id: type} (everyone who took part), "attacks",
##          "improvised" (attacks with a held item), "blocks", "throws",
##          "kills", "routed"}. Combat.end_fight turns it into action records.
##   lines: combat text from the last command (the UI shows it).
##   stage_run: {} or the staged fight in progress (M7.B): {"event": event id,
##              "start": world second it began, "next": index of its next wave}.
##   traps (M13.T, save v14): "<area>/<trap id>" → {"found", "spent",
##          "disarmed", "sprung"} (see Traps); only traps that changed. Unlike
##          monsters, traps keep their state when the player leaves.
##   encounter (M17.1, save v18): {} or the combat-mode rounds (see Encounter).
## Combat, MonsterSim, Traps and Encounter change this; nothing else does.
class_name CombatState
extends RefCounted

const HIDDEN := "hidden"
const IDLE := "idle"
const HOSTILE := "hostile"
const FLEE := "flee"
const HOME := "home"
const ALLY := "ally"
const STATES := [HIDDEN, IDLE, HOSTILE, FLEE, HOME, ALLY]
const MONSTER_INTS := ["x", "y", "hp", "home_x", "home_y", "carry", "chase", "scared", "pack"]
const FIGHT_INTS := ["start", "attacks", "improvised", "blocks", "throws", "kills", "routed"]

var next_id: int = 1
## World second the monsters were last moved to (-1 = never).
var sec: int = -1
## The area the monsters belong to (the player's area at the last sync).
var area: String = ""
## Clock minute of the last spawn check (-1 = never).
var checked: int = -1
## spawn id → clock minute it last placed monsters.
var spawn_last: Dictionary = {}
## The player raised their guard this turn (halves the next hits).
var blocking: bool = false
var lines: Array[String] = []
var monsters: Dictionary = {}
var fight: Dictionary = {}
var stage_run: Dictionary = {}
var traps: Dictionary = {}
var encounter: Dictionary = {}


func has_fight() -> bool:
	return not fight.is_empty()


## Monster ids in number order (m2 before m10).
func ids() -> Array[String]:
	var out: Array[String] = []
	out.assign(monsters.keys())
	out.sort_custom(func(a: String, b: String) -> bool: return a.substr(1).to_int() < b.substr(1).to_int())
	return out


## Id of the monster on `at` in `in_area`, or "".
func at(in_area: String, pos: Vector2i) -> String:
	for id in ids():
		var m: Dictionary = monsters[id]
		if m["area"] == in_area and int(m["x"]) == pos.x and int(m["y"]) == pos.y:
			return id
	return ""


## Ids of the monsters in `state`, in number order.
func in_state(state: String) -> Array[String]:
	var out: Array[String] = []
	for id in ids():
		if monsters[id]["state"] == state:
			out.append(id)
	return out


static func pos_of(m: Dictionary) -> Vector2i:
	return Vector2i(int(m["x"]), int(m["y"]))


func to_dict() -> Dictionary:
	var list := {}
	for id in ids():
		list[id] = (monsters[id] as Dictionary).duplicate()
	return {"next_id": next_id, "sec": sec, "area": area, "checked": checked,
		"spawn_last": spawn_last.duplicate(), "blocking": blocking, "lines": lines.duplicate(),
		"monsters": list, "fight": fight.duplicate(true), "stage_run": stage_run.duplicate(),
		"traps": traps.duplicate(true), "encounter": encounter.duplicate(true)}


## Accepts {} (a migrated v5 save): no monsters, no fight.
static func from_dict(d: Dictionary) -> CombatState:
	var c := CombatState.new()
	c.next_id = int(d.get("next_id", 1))
	c.sec = int(d.get("sec", -1))
	c.area = d.get("area", "")
	c.checked = int(d.get("checked", -1))
	for k: String in d.get("spawn_last", {}):
		c.spawn_last[k] = int(d["spawn_last"][k])
	c.blocking = bool(d.get("blocking", false))
	c.lines.assign(d.get("lines", []))
	for id: String in d.get("monsters", {}):
		var m: Dictionary = (d["monsters"][id] as Dictionary).duplicate()
		for k: String in MONSTER_INTS:
			m[k] = int(m.get(k, 0))
		m["rolled_spot"] = bool(m.get("rolled_spot", false))
		m["pack"] = maxi(int(m["pack"]), 1)
		m["stage"] = String(m.get("stage", ""))
		c.monsters[id] = m
	var f: Dictionary = (d.get("fight", {}) as Dictionary).duplicate(true)
	if not f.is_empty():
		for k: String in FIGHT_INTS:
			f[k] = int(f.get(k, 0))
	c.fight = f
	var run: Dictionary = (d.get("stage_run", {}) as Dictionary).duplicate()
	if not run.is_empty():
		run["start"] = int(run["start"])
		run["next"] = int(run["next"])
	c.stage_run = run
	for k: String in d.get("traps", {}):
		var s: Dictionary = (d["traps"][k] as Dictionary).duplicate()
		for field: String in ["found", "spent", "disarmed"]:
			if s.has(field):
				s[field] = bool(s[field])
		if s.has("sprung"):
			s["sprung"] = int(s["sprung"])
		c.traps[k] = s
	var e: Dictionary = (d.get("encounter", {}) as Dictionary).duplicate(true)
	if not e.is_empty():
		for k: String in ["round", "turn", "ap_q", "moved_q"]:
			e[k] = int(e.get(k, 0))
		var order: Array[String] = []
		order.assign(e.get("order", []))
		e["order"] = order
		var tie := {}
		for k: String in e.get("tie", {}):
			tie[k] = float(e["tie"][k])
		e["tie"] = tie
	c.encounter = e
	return c
