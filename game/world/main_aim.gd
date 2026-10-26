## Combat aiming on the game screen (M26.0, split from main.gd). In a fight
## (M17.3) the map shows the move range on the player's turn and, under the
## mouse, the path and hit chance of a click (Encounter.plan_to). A left click
## walks there (MainScreen steps it every STEP_REPEAT) and hits a foe at the
## end. A touch has no hover: the first tap shows the plan, a second tap on the
## same cell acts (M20.1). M17.4 / M17.5: a strike Skill or a spell with more
## than one foe is armed: gold frames show its foes, and a click (or a
## direction key) uses it. M17.6: cover bars on the tile edges.
## Commands go back through MainScreen. Presentation only (CLAUDE.md rule 1).
class_name MainAim
extends RefCounted

const NO_CELL := Vector2i(-1, -1)

## The strike Skill, or Spells.KEY + spell, waiting for its target ("" = none).
var armed := ""
## A click's walk still to go: steps, then the blow ("" = none) at `walk_target`.
var walk: Array[String] = []
var walk_attack := ""
var walk_target := ""
## The cell under the mouse.
var hover_cell := NO_CELL
## The cell of the last touch tap that showed a plan (M20.1).
var tapped := NO_CELL

## The MainScreen (untyped: a typed back link makes a script cycle that leaks at exit).
var _m


func _init(screen: Node) -> void:
	_m = screen


## Picks combat Skill `id` (a key 1-9 or its button, M17.4): a self or area
## Skill, or a strike with one foe in reach, is used at once; a strike with
## more foes is armed (picking it again lets it go).
func pick_skill(id: String) -> void:
	_m.skip_replay()
	if id.begins_with(Spells.KEY):  # M17.5: a spell in the same bar
		pick_spell(id.substr(Spells.KEY.length()))
		return
	var gs := Session.gs
	var db := Session.db
	var a := CombatSkills.action_of(db, id)
	if a.is_empty() or not Encounter.is_player_turn(gs):
		return
	if armed == id:
		disarm()
		return
	if a["kind"] != CombatSkills.STRIKE:
		_m.use_skill(id)
		return
	var foes := CombatSkills.targets(gs, db, id)
	if foes.is_empty():
		var why := CombatSkills.why_not(gs, db, id, Combat.nearest_foe(gs))
		_m.hud.add_lines([why if why != "" else CombatSkills.NO_FOE])
		return
	if foes.size() == 1:
		_m.use_skill(id, foes[0])
		return
	_arm(id)


## Picks spell `sid` (a key 1-9 or its button, M17.5): an "around" spell, or a "one"
## spell with one foe in range, is cast at once; the others are armed and wait for a
## click (a tile), or a direction key (picking it again lets it go).
func pick_spell(sid: String) -> void:
	_m.skip_replay()
	var gs := Session.gs
	var db := Session.db
	if not Spells.knows(gs, sid) or not Encounter.is_player_turn(gs):
		return
	if armed == Spells.KEY + sid:
		disarm()
		return
	var why := Spells.resource_error(gs, db, sid)
	if why != "":
		_m.hud.add_lines([why])
		return
	match String(Spells.spell(db, sid)["shape"]):
		"around", "self":  # M33.0: "self" ([Invisibility]) needs no aim
			_m.cast_spell(sid, gs.player.pos())
			return
		"one":
			var foes := Spells.one_targets(gs, db, sid)
			if foes.is_empty():
				_m.hud.add_lines([Spells.NO_FOE])
				return
			if foes.size() == 1:
				_m.cast_spell(sid, CombatState.pos_of(gs.combat.monsters[foes[0]]))
				return
	_arm(Spells.KEY + sid)


func _arm(key: String) -> void:
	cancel_walk()
	armed = key
	_m.bar.skills().set_armed(key)
	update_overlay()


## The armed spell's id, or "" (nothing armed, or a Skill).
func armed_spell() -> String:
	return armed.substr(Spells.KEY.length()) if armed.begins_with(Spells.KEY) else ""


## Lets the armed Skill go (no overlay redraw: the command that used it redraws).
func let_go() -> void:
	armed = ""
	_m.bar.skills().set_armed("")


## Lets the armed Skill go.
func disarm() -> void:
	let_go()
	update_overlay()


## A direction key while a Skill or spell is armed: use it towards that side.
func aim_dir(dir: String) -> void:
	var gs := Session.gs
	var db := Session.db
	var sid := armed_spell()
	if sid != "":  # M17.5: toward that side (a line shoots that way)
		_m.cast_spell(sid, Spells.aim_for_dir(gs, db, sid, PlayerState.DIRS[dir]))
		return
	var foe := gs.combat.at(gs.player.area, gs.player.pos() + (PlayerState.DIRS[dir] as Vector2i))
	if CombatSkills.targets(gs, db, armed).has(foe):
		_m.use_skill(armed, foe)
	else:
		_m.hud.add_lines([CombatSkills.NO_FOE])


## A tap on `cell` in a fight (M20.1): a touch has no hover, so the first tap
## shows the plan (path, hit chance) and a second tap on the same cell acts.
## True when a walk started.
func tap(cell: Vector2i) -> bool:
	if tapped == cell:
		tapped = NO_CELL
		return click(cell)
	tapped = cell
	hover(cell)
	return false


## Stops a click's walk and disarms a Skill (a right click, or Cancel on touch).
func cancel() -> void:
	tapped = NO_CELL
	cancel_walk()
	if armed != "":
		disarm()


## The mouse is over `cell`: show what a click there would do.
func hover(cell: Vector2i) -> void:
	hover_cell = cell
	show_plan()


## A click on `cell` in a fight: walk the plan's steps, then its blow.
## True when a walk started (its first step is made now).
func click(cell: Vector2i) -> bool:
	_m.skip_replay()
	var gs := Session.gs
	if not Encounter.is_player_turn(gs):
		return false
	if armed != "":
		if armed_spell() != "":
			_m.cast_spell(armed_spell(), cell)
			return false
		var foe := gs.combat.at(gs.player.area, cell)
		if CombatSkills.targets(gs, Session.db, armed).has(foe):
			_m.use_skill(armed, foe)
		else:
			disarm()
		return false
	var plan := Encounter.plan_to(gs, Session.db, cell)
	if plan.is_empty():
		return false
	walk.assign(plan["steps"])
	walk_attack = String(plan["attack"])
	walk_target = String(plan["target"])
	if walk_target != "" and walk_attack == "" and walk.is_empty():
		_m.hud.add_lines([Encounter.NO_AP])
		return false
	walk_next()
	return true


func walking() -> bool:
	return not walk.is_empty() or walk_attack != ""


func cancel_walk() -> void:
	walk.clear()
	walk_attack = ""
	walk_target = ""


## One step of a click's walk, or its blow at the end. The walk stops when a
## step does not move the player (someone in the way, no AP) or the turn ends.
func walk_next() -> void:
	var gs := Session.gs
	if not Encounter.is_player_turn(gs):
		cancel_walk()
		return
	if not walk.is_empty():
		var at := gs.player.pos()
		var area := gs.player.area
		_m.step(walk.pop_front())
		if gs.player.pos() == at or gs.player.area != area:
			cancel_walk()
		return
	var dir := walk_attack
	var target := walk_target
	cancel_walk()
	if target.begins_with(Encounter.NPC):
		_m.attack_npc(target.substr(Encounter.NPC.length()))
	elif dir != "":
		_m.step(dir)  # a step into the foe hits it


## The move range on the player's turn (exits in yellow), and the hover plan.
func update_overlay() -> void:
	var gs := Session.gs
	var overlay: CombatOverlay = _m.view.overlay
	if not Encounter.is_player_turn(gs):
		overlay.clear()
		if armed != "":
			let_go()
		return
	var marks: Array[Vector2i] = []
	if armed_spell() != "":  # M17.5: gold frames for a "one" spell; the others preview on hover
		var sid := armed_spell()
		if Spells.resource_error(gs, Session.db, sid) != "":  # AP or MP ran out
			let_go()
		elif String(Spells.spell(Session.db, sid)["shape"]) == "one":
			for foe in Spells.one_targets(gs, Session.db, sid):
				marks.append(CombatState.pos_of(gs.combat.monsters[foe]))
			if marks.is_empty():
				let_go()
	elif armed != "":
		for foe in CombatSkills.targets(gs, Session.db, armed):
			marks.append(CombatState.pos_of(gs.combat.monsters[foe]))
		if marks.is_empty():  # nothing left to hit (the foe fell, AP ran out)
			let_go()
	overlay.show_marks(marks)
	var reach := Encounter.reach(gs, Session.db)
	var exits := {}
	for cell: Vector2i in reach:
		if not Session.db.maps.exit_at(gs.player.area, cell).is_empty():
			exits[cell] = true
	overlay.show_reach(reach, exits)
	var covers := {}  # M17.6: bars on the tile edges that have cover beside them
	var stand: Array = reach.keys()
	stand.append(gs.player.pos())
	for cell: Vector2i in stand:
		var sides := Cover.sides(Session.db, gs.player.area, cell)
		if not sides.is_empty():
			covers[cell] = sides
	overlay.show_covers(covers)
	show_plan()


## M17.5: the tiles the armed spell would hit if cast at the hovered tile (orange), and
## over the first foe in them the hit chance (one foe) or the number of foes.
func _show_spell_plan(sid: String) -> void:
	var gs := Session.gs
	var db := Session.db
	var overlay: CombatOverlay = _m.view.overlay
	var s := Spells.spell(db, sid)
	var here := gs.player.pos()
	var shape := String(s["shape"])
	if shape in ["one", "blast", "tile"] and (Combat._dist(here, hover_cell) > int(s["range"])
			or not Cover.sight(db, gs.player.area, here, hover_cell)):  # M17.6: no sight through a wall
		overlay.clear_plan()
		return
	var tiles := Spells.cells(gs, db, sid, hover_cell, here)
	overlay.show_preview(tiles)
	var foes := Spells.foes_in(gs, tiles)
	if foes.is_empty():
		overlay.clear_plan()
		return
	var at := CombatState.pos_of(gs.combat.monsters[foes[0]])
	var text := _with_note("%d%%" % roundi(Spells.hit_chance(gs, db, sid, foes[0]) * 100.0),
			Cover.note(gs, db, gs.player.area, here, at, String(s["hit"]) != "auto", Cover.FRIEND)) if shape == "one" \
			else "%d foe%s" % [foes.size(), "" if foes.size() == 1 else "s"]
	overlay.show_plan([] as Array[Vector2i], true, at, text)


## The path and hit chance of a click on the hovered cell.
func show_plan() -> void:
	var gs := Session.gs
	var db := Session.db
	var overlay: CombatOverlay = _m.view.overlay
	overlay.show_preview([] as Array[Vector2i])
	if armed_spell() != "":
		_show_spell_plan(armed_spell())
		return
	if armed != "":  # M17.4: the armed Skill's hit chance on the foe under the mouse
		var foe := gs.combat.at(gs.player.area, hover_cell)
		if CombatSkills.targets(gs, db, armed).has(foe):
			overlay.show_plan([] as Array[Vector2i], true, hover_cell,
					"%d%%" % roundi(CombatSkills.hit_chance(gs, db, armed, foe) * 100.0))
		else:
			overlay.clear_plan()
		return
	var plan := Encounter.plan_to(gs, db, hover_cell) if Encounter.is_player_turn(gs) else {}
	if plan.is_empty():
		overlay.clear_plan()
		return
	var cells: Array[Vector2i] = []
	var at := gs.player.pos()
	for dir: String in plan["steps"]:
		at += PlayerState.DIRS[dir]
		cells.append(at)
	var target := String(plan["target"])
	if target == "":
		overlay.show_plan(cells, false)
		return
	var text := _with_note("%d%%" % roundi(Combat.player_hit_chance(gs, db, target) * 100.0),
			Cover.note(gs, db, gs.player.area, at, hover_cell, false, Cover.FRIEND)) \
			if plan["attack"] != "" else Encounter.NO_AP
	var held: Dictionary = db.combat.items.get(gs.player.held, {})
	if not held.is_empty() and target == Combat.nearest_foe(gs):
		var dist := AnimDiff.king(gs.player.pos(), hover_cell)
		var note := Cover.note(gs, db, gs.player.area, gs.player.pos(), hover_cell, true, Cover.FRIEND)
		if dist <= int(held["throw_range"]) and note != "no sight":  # M17.6: a wall blocks a throw
			text += "  " + _with_note("T: %d%%" % roundi(Combat.player_hit_chance(gs, db, target, true, dist) * 100.0), note)
	overlay.show_plan(cells, true, hover_cell, text)


## "45%" + "half cover" -> "45% (half cover)" (M17.6).
static func _with_note(text: String, note: String) -> String:
	return text if note == "" else "%s (%s)" % [text, note]
