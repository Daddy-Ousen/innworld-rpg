## Tap the world (M34.3, ADR 0045). Outside a fight, a touch tap on a person
## or a thing walks the player next to it, then opens its action card (M34.0);
## a tap next to it opens the card at once; a tap on the floor walks there.
## Each step is a normal move command (MainScreen.step), one every
## STEP_REPEAT, so time and the seed work as with keys (rule 3). The path is
## found again before each step, so a person who moves is followed and someone
## in the way is walked around. A new tap, the stick or a key, Cancel, a panel,
## a fight, a new map or a blocked step ends the walk.
## Presentation only (CLAUDE.md rule 1).
class_name MainTap
extends RefCounted

## The most steps one tap walks.
const MAX_STEPS := 80
## A finger that moved more than this (viewport pixels) between down and up did not tap.
const SLOP := 24.0

## The tapped cell ("none" = no walk), and the Interact option id there ("" = the floor).
var goal := MainAim.NO_CELL
var target := ""
var _area := ""
var _steps := 0

## The MainScreen (untyped: a typed back link makes a script cycle that leaks at exit).
var _m


func _init(screen: Node) -> void:
	_m = screen


func walking() -> bool:
	return goal != MainAim.NO_CELL


func cancel() -> void:
	goal = MainAim.NO_CELL
	target = ""
	_steps = 0


## A tap on `cell` of the map: open the card of what is there when it is near,
## else walk there (the first step now). Nothing in a fight.
func tap(cell: Vector2i) -> void:
	cancel()
	var gs := Session.gs
	var db := Session.db
	if not gs.player.is_placed() or Encounter.active(gs):
		return
	var id := target_at(gs, db, cell)
	if id != "" and _near(id):
		_m.panels.open_target(id)
		return
	if id == "" and (cell == gs.player.pos() or not db.maps.is_walkable(gs.player.area, cell)):
		return
	goal = cell
	target = id
	_area = gs.player.area
	next()


## One step of the walk, or the card at its end.
func next() -> void:
	var gs := Session.gs
	var db := Session.db
	if not walking():
		return
	if Encounter.active(gs) or gs.player.area != _area or _steps >= MAX_STEPS:
		cancel()
		return
	if target != "" and _near(target):
		var id := target
		cancel()
		_m.panels.open_target(id)
		return
	var at := _target_cell(gs)
	if at == MainAim.NO_CELL:  # the person left the map
		cancel()
		return
	var goals := Pathfind.around(at) if target != "" else {at: true}
	var p := Pathfind.path(db.maps, gs.player.area, gs.player.pos(), goals, _people(gs))
	if not p["found"] or (p["steps"] as Array).is_empty():
		cancel()  # there (the floor), or no way
		return
	var from := gs.player.pos()
	_steps += 1
	_m.step(String(p["steps"][0]))
	if gs.player.pos() == from and gs.player.area == _area:
		cancel()  # someone in the way, too tired, or the long-road question
	elif target == "" and gs.player.pos() == goal:
		cancel()


## The Interact option id of what stands on `cell`: an NPC, a seated patron
## (Guests.GUEST + id), a map object, or "".
static func target_at(gs: GameState, db: DataDb, cell: Vector2i) -> String:
	var area := gs.player.area
	var npc := gs.npcs.at(area, cell)
	if npc != "":
		return npc
	var g := Guests.at(gs, area, cell)
	if g != "":
		return Guests.GUEST + g
	for o: Dictionary in db.maps.objects_on(area):
		if Vector2i(int(o["at"][0]), int(o["at"][1])) == cell:
			return String(o["id"])
	return ""


## True when `id` has a card now (it is near and has buttons).
func _near(id: String) -> bool:
	for t: Dictionary in InteractMenu.targets(Interact.options(Session.gs, Session.db), Session.db, Session.gs):
		if t["id"] == id:
			return true
	return false


## Where the target stands now: an NPC may have moved; objects and patrons stay.
func _target_cell(gs: GameState) -> Vector2i:
	if gs.npcs.npcs.has(target):
		var n: Dictionary = gs.npcs.npcs[target]
		return NpcRoster.pos_of(n) if String(n.get("area", "")) == gs.player.area else MainAim.NO_CELL
	return goal


## Squares a path goes around: people and monsters on this map.
func _people(gs: GameState) -> Dictionary:
	var out := {}
	for id in gs.npcs.in_area(gs.player.area):
		out[NpcRoster.pos_of(gs.npcs.npcs[id])] = true
	for m: Dictionary in gs.combat.monsters.values():
		if m.get("area", "") == gs.player.area:
			out[CombatState.pos_of(m)] = true
	return out
