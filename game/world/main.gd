## The game screen: world map, HUD, "use" menu, character sheet, System
## dialog and the debug console overlay. Turns keys into Commands on
## Session.gs, then redraws. Held keys: WASD/arrows walk, Space waits
## (one step of time). Walking into a monster attacks it, once per key
## press (holding the key does not attack again). B blocks, T throws the
## held item at the nearest monster, X drops it. After every command the
## combat text goes to the log; a knocked-out player gets the night at once
## (Commands.knock_out) and the System dialog. Esc opens the pause menu
## (save, load, quit to title), J the journal, I the bag (M14.0), L the message
## history and H the key list (M15.2). A new game opens with the
## welcome page; the game autosaves each time the System dialog closes
## (each morning) and on quit.
## M17.3 (ADR 0027), in a fight: the CombatBar shows the turn order, AP and
## End turn; on the player's turn the map shows the move range and, under the
## mouse, the path and hit chance of a click (Encounter.plan_to). A left click
## walks there (a step per STEP_REPEAT) and hits a foe at the end; a right
## click stops the walk. When others acted in a command, the view replays
## their turns (the log lines come with each turn); any key or click skips
## the replay. Replays are off headless (`replay_turns`), so the sims that
## drive this scene see each command's end state at once.
## M17.4: keys 1-9 (or the Skill bar's buttons) use a combat Skill. A self or
## area Skill, or a strike with one foe in reach, fires at once; else the
## strike is armed: gold frames show its foes, and a click on one (or a
## direction key towards it) uses it. Esc, a right click or the same key again
## lets it go.
## Presentation only (CLAUDE.md rule 1).
extends Node

## Seconds between steps while a direction key is held.
const STEP_REPEAT := 0.14
const TITLE_SCENE := "res://ui/title_menu.tscn"
const WAIT := "wait"
const NO_CELL := Vector2i(-1, -1)
## Held input actions (project.godot [input], M20.0): direction -> action.
const MOVE_ACTIONS := {
	"n": &"move_n", "s": &"move_s", "e": &"move_e", "w": &"move_w", WAIT: &"wait",
}
## Skill bar slots: action -> slot (keys 1-9).
const SKILL_ACTIONS: Array[StringName] = [
	&"skill_1", &"skill_2", &"skill_3", &"skill_4", &"skill_5", &"skill_6", &"skill_7", &"skill_8",
	&"skill_9",
]

var _cooldown := 0.0
## The NPC the player last bumped into (say it once, not every repeat).
var _bumped := ""
## The direction of the last bump attack. That key must be let go before it
## moves or attacks again.
var _attack_dir := ""
## Tests set this false: quit to title then only autosaves.
var switch_scene := true

## A long road (TravelPrompt.LONG_MINUTES) asks first and plays a short walk
## (user, 2026-10-08). Off headless-only: sims that drive this scene step at once.
var confirm_travel := DisplayServer.get_name() != "headless"
## M17.3: replay the others' turns after a command (off headless; tests may
## turn it on).
var replay_turns := DisplayServer.get_name() != "headless"
## A click's walk still to go (M17.3): steps, then the blow ("" = none) at
## `_walk_target`.
var _walk: Array[String] = []
var _walk_attack := ""
var _walk_target := ""
## The cell under the mouse (M17.3).
var _hover := NO_CELL
## The cell of the last touch tap that showed a plan (M20.1).
var _tapped := NO_CELL
## A replay's log lines: one list per turn-log entry, then the rest.
var _replay_lines: Array = []
var _replay_tail: Array = []
## The next redraw follows a replay (WorldView.refresh `replayed`).
var _replayed := false
## The strike Skill waiting for its target (M17.4; "" = none).
var _armed := ""

@onready var view: WorldView = $WorldView
@onready var hud: Hud = $HudLayer/HUD
@onready var bar: CombatBar = $HudLayer/CombatBar
@onready var menu: InteractMenu = $MenuLayer/InteractMenu
@onready var sheet: CharacterSheet = $MenuLayer/CharacterSheet
@onready var journal: Journal = $MenuLayer/Journal
@onready var bag: Bag = $MenuLayer/Bag
@onready var message_log: TextPage = $MenuLayer/MessageLog
@onready var help: TextPage = $MenuLayer/Help
@onready var pause: PauseMenu = $MenuLayer/PauseMenu
@onready var dialog: SystemDialog = $SystemLayer/SystemDialog
@onready var touch: TouchControls = $TouchLayer/TouchControls
@onready var console_layer: CanvasLayer = $ConsoleLayer
var travel: TravelPrompt
var _travel_dir := ""
@onready var console_input: LineEdit = $ConsoleLayer/DebugConsole.get_node("%Input")


func _ready() -> void:
	var names := {}
	var races := {}
	for id: String in Session.db.canon.npcs:
		names[id] = Session.db.canon.npcs[id]["name"]
		races[id] = String(Session.db.canon.npcs[id].get("race", ""))
	var max_hp := {}
	for id in Session.db.behaviour.ids():
		max_hp[id] = int(NpcReact.stats(Session.db, id)["hp"])
	view.audio = Audio.db
	view.setup(Session.db.maps, names, Combat.scaled_enemies(Session.db), max_hp,
			String(Winter.rules(Session.db).get("flag", "")), races,
			String(Rains.rules(Session.db).get("season_flag", "")))
	view.sounds.connect(Audio.play_cues)
	view.area_loops.connect(func(loops: Array) -> void:
		Audio.place_loops(view.loop_spots, loops, WorldView.TILE))
	Session.state_changed.connect(_redraw)
	menu.chosen.connect(use)
	bag.chosen.connect(use_from_bag)
	dialog.closed.connect(_on_dialog_closed)
	dialog.struck.connect(attack_npc.bind(true))
	travel = TravelPrompt.new()
	$SystemLayer.add_child(travel)
	travel.cancelled.connect(_on_travel_cancelled)
	travel.arrived.connect(_on_travel_arrived)
	bar.end_turn.connect(end_turn)
	bar.skill.connect(pick_skill)
	view.replay_step.connect(_on_replay_step)
	view.replay_done.connect(_on_replay_done)
	pause.message.connect(func(line: String) -> void: hud.add_lines([line]))
	pause.quit_requested.connect(quit_to_title)
	touch.cancel_pressed.connect(cancel)
	Session.touch_changed.connect(_sync_touch)
	Session.ui_scale_changed.connect(_apply_ui_scale)
	_apply_ui_scale()
	console_layer.visible = false
	hud.add_lines([_day_line()])
	if not Session.db.is_valid():
		hud.add_lines(["Data errors: see the debug console (`)."])
	_redraw()
	if Session.fresh:
		Session.fresh = false
		var start := Movement.start_of(Session.db, Session.start_id)
		dialog.open([SystemMessages.welcome_page(start)] as Array[Dictionary], Session.gs, Session.db)


func _redraw() -> void:
	if view.is_replaying():
		return  # the redraw comes when the replay ends
	_tapped = NO_CELL  # a new state: the next tap shows its plan first
	view.refresh(Session.gs, Session.db, _replayed)
	_replayed = false
	hud.refresh(Session.gs, Session.db)
	bar.refresh(Session.gs, Session.db)
	_update_overlay()
	Audio.music(MusicPick.track(Session.gs, Session.db, Audio.db))
	Audio.ambience(AmbiencePick.bed(Session.gs, Session.db, Audio.db))


## True while a menu, the sheet, the journal, the bag, the System dialog or
## the console has the keyboard.
func is_busy() -> bool:
	return console_layer.visible or menu.visible or sheet.visible or journal.visible \
			or bag.visible or pause.visible or dialog.visible or message_log.visible or help.visible 			or travel.visible \
			or view.is_replaying()


## The UI scale factor changed (M20.3): the map and the touch pad keep their
## size on the screen (user, 2026-10-05).
func _apply_ui_scale() -> void:
	var f := get_window().content_scale_factor
	view.camera.zoom = Vector2.ONE * UiScale.camera_zoom(f)
	touch.set_factor(f)


## Shows the touch controls that fit now (M20.1) and makes room for the pad
## in the HUD.
func _sync_touch() -> void:
	var shown := Session.touch_shown()
	var panel_open := menu.visible or sheet.visible or journal.visible or bag.visible \
			or pause.visible or message_log.visible or help.visible
	touch.sync(shown, panel_open, dialog.visible or console_layer.visible,
			_armed != "" or _walking(), Encounter.is_player_turn(Session.gs))
	hud.make_room_left(touch.pad_width() if shown else 0.0)


func _input(event: InputEvent) -> void:
	# Backtick before the console's LineEdit sees it. Not while the System
	# dialog waits for an answer.
	if event.is_action_pressed(&"console") and not dialog.visible:
		toggle_console()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if view.is_replaying() and (event is InputEventKey or event is InputEventAction \
			or event is InputEventMouseButton) and event.is_pressed() and not event.is_echo():
		skip_replay()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouse:
		_mouse(event)
		return
	if is_busy() or not event.is_pressed() or event.is_echo():
		return
	for i in SKILL_ACTIONS.size():
		if event.is_action_pressed(SKILL_ACTIONS[i]):
			var ids := bar.skills().ids()
			if i < ids.size():
				pick_skill(ids[i])
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed(&"back") and _armed != "":
		disarm()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"use"):
		open_use_menu()
	elif event.is_action_pressed(&"sleep"):
		sleep()
	elif event.is_action_pressed(&"eat"):
		open_bag()
	elif event.is_action_pressed(&"sheet"):
		sheet.open(Session.gs, Session.db)
	elif event.is_action_pressed(&"journal"):
		journal.open(Session.gs, Session.db)
	elif event.is_action_pressed(&"bag"):
		bag.open(Session.gs, Session.db)
	elif event.is_action_pressed(&"log"):
		message_log.open(_history_lines())
	elif event.is_action_pressed(&"help"):
		help.open(SystemMessages.KEYS)
	elif event.is_action_pressed(&"back"):
		pause.open()
	elif event.is_action_pressed(&"block"):
		block()
	elif event.is_action_pressed(&"throw"):
		throw()
	elif event.is_action_pressed(&"drop"):
		drop()
	else:
		return
	get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_sync_touch()
	_cooldown = maxf(_cooldown - delta, 0.0)
	if is_busy():
		return
	if _walking():
		if _cooldown == 0.0:
			_walk_next()
			_cooldown = STEP_REPEAT
		return
	var dir := _held_direction()
	if dir != _attack_dir:
		_attack_dir = ""
	if dir == "":
		_cooldown = 0.0
	elif _cooldown == 0.0 and _attack_dir == "":
		step(dir)
		_cooldown = STEP_REPEAT


func _held_direction() -> String:
	for dir: String in MOVE_ACTIONS:
		if Input.is_action_pressed(MOVE_ACTIONS[dir]):
			return dir
	return ""


## One step in `dir` (n, s, e, w), or WAIT for one step of time. A step
## into a monster attacks it (or springs a hidden one).
func step(dir: String) -> void:
	skip_replay()
	var gs := Session.gs
	var db := Session.db
	if _armed != "" and dir != WAIT:
		_attack_dir = dir  # the key must be let go before it acts again
		if _armed_spell() != "":  # M17.5: toward that side (a line shoots that way)
			cast_spell(_armed_spell(), Spells.aim_for_dir(gs, db, _armed_spell(), PlayerState.DIRS[dir]))
			return
		var foe := gs.combat.at(gs.player.area, gs.player.pos() + (PlayerState.DIRS[dir] as Vector2i))
		if CombatSkills.targets(gs, db, _armed).has(foe):
			use_skill(_armed, foe)
		else:
			hud.add_lines([CombatSkills.NO_FOE])
		return
	if dir != WAIT and _ask_travel(dir):
		return
	var was_indoor := db.maps.is_indoor(gs.player.area)
	var r := {"refused": Commands.wait(gs, db, int(db.rules["world"]["step_seconds"])) < 0,
			"exit_to": "", "npc": ""} if dir == WAIT else Commands.move(gs, db, dir)
	if r["refused"] and gs.clock.is_collapse_due(db.rules["clock"]):
		hud.add_lines(["You are too tired to take another step."])
		sleep()
		return
	if r["npc"] != "" and r["npc"] != _bumped:
		hud.add_lines(["%s is in the way." % db.canon.npcs[r["npc"]]["name"]])
	_bumped = r["npc"]
	if r["exit_to"] != "":
		Audio.play_cues([SoundCues.door_cue(Audio.db, was_indoor, db.maps.is_indoor(r["exit_to"]))])
		hud.add_lines(["You travel to %s (%d min)." % [
			Session.db.maps.areas[r["exit_to"]]["name"], int(r["minutes"])]])
	if r.has("attack") or r.has("ambush"):
		_attack_dir = dir
		if r.has("attack") and r["attack"]["error"] != "":
			hud.add_lines([r["attack"]["error"]])
	_finish()


## A step onto a long road (10 h between Celum, the camp and Liscor) opens the
## TravelPrompt instead and returns true; the step is made after the walk.
func _ask_travel(dir: String) -> bool:
	if not confirm_travel or not PlayerState.DIRS.has(dir):
		return false
	var gs := Session.gs
	var db := Session.db
	var e := db.maps.exit_at(gs.player.area, gs.player.pos() + (PlayerState.DIRS[dir] as Vector2i))
	if e.is_empty() or not TravelPrompt.is_long(int(e["minutes"])):
		return false
	_travel_dir = dir
	_attack_dir = dir  # the key must be let go before it acts again
	_cancel_walk()
	travel.ask(String(db.maps.areas[gs.player.area]["name"]), String(db.maps.areas[e["to"]]["name"]),
			int(e["minutes"]))
	return true


func _on_travel_cancelled() -> void:
	_travel_dir = ""


## The walk is over and the screen is covered: make the step.
func _on_travel_arrived() -> void:
	var dir := _travel_dir
	_travel_dir = ""
	var was := confirm_travel
	confirm_travel = false
	step(dir)
	confirm_travel = was


## Raises the guard for one turn (B).
func block() -> void:
	skip_replay()
	_command_error(_sound_if_ok(Commands.block(Session.gs, Session.db), "block"))


## Throws the held item at the nearest monster you can see (T).
func throw() -> void:
	skip_replay()
	if Session.gs.player.held == "":
		hud.add_lines(["You hold nothing to throw."])
		return
	var target := Combat.nearest_foe(Session.gs)
	if target == "":
		hud.add_lines(["There is nothing to throw at."])
		return
	_command_error(_sound_if_ok(Commands.throw(Session.gs, Session.db, target)["error"], "throw"))


## Picks combat Skill `id` (a key 1-9 or its button, M17.4): a self or area
## Skill, or a strike with one foe in reach, is used at once; a strike with
## more foes is armed (picking it again lets it go).
func pick_skill(id: String) -> void:
	skip_replay()
	if id.begins_with(Spells.KEY):  # M17.5: a spell in the same bar
		pick_spell(id.substr(Spells.KEY.length()))
		return
	var gs := Session.gs
	var db := Session.db
	var a := CombatSkills.action_of(db, id)
	if a.is_empty() or not Encounter.is_player_turn(gs):
		return
	if _armed == id:
		disarm()
		return
	if a["kind"] != CombatSkills.STRIKE:
		use_skill(id)
		return
	var foes := CombatSkills.targets(gs, db, id)
	if foes.is_empty():
		var why := CombatSkills.why_not(gs, db, id, Combat.nearest_foe(gs))
		hud.add_lines([why if why != "" else CombatSkills.NO_FOE])
		return
	if foes.size() == 1:
		use_skill(id, foes[0])
		return
	_cancel_walk()
	_armed = id
	bar.skills().set_armed(id)
	_update_overlay()


## Picks spell `sid` (a key 1-9 or its button, M17.5): an "around" spell, or a "one"
## spell with one foe in range, is cast at once; the others are armed and wait for a
## click (a tile), or a direction key (picking it again lets it go).
func pick_spell(sid: String) -> void:
	skip_replay()
	var gs := Session.gs
	var db := Session.db
	if not Spells.knows(gs, sid) or not Encounter.is_player_turn(gs):
		return
	if _armed == Spells.KEY + sid:
		disarm()
		return
	var why := Spells.resource_error(gs, db, sid)
	if why != "":
		hud.add_lines([why])
		return
	match String(Spells.spell(db, sid)["shape"]):
		"around":
			cast_spell(sid, gs.player.pos())
			return
		"one":
			var foes := Spells.one_targets(gs, db, sid)
			if foes.is_empty():
				hud.add_lines([Spells.NO_FOE])
				return
			if foes.size() == 1:
				cast_spell(sid, CombatState.pos_of(gs.combat.monsters[foes[0]]))
				return
	_cancel_walk()
	_armed = Spells.KEY + sid
	bar.skills().set_armed(_armed)
	_update_overlay()


## The armed spell's id, or "" (nothing armed, or a Skill).
func _armed_spell() -> String:
	return _armed.substr(Spells.KEY.length()) if _armed.begins_with(Spells.KEY) else ""


## Casts spell `sid` at tile `aim`. A cast that works lets the spell go; a refused one
## keeps it armed so the player can pick another tile.
func cast_spell(sid: String, aim: Vector2i) -> void:
	skip_replay()
	_cancel_walk()
	var r := Commands.cast(Session.gs, Session.db, sid, aim)
	if r["error"] == "":
		_armed = ""
		bar.skills().set_armed("")
	_command_error(_sound_if_ok(String(r["error"]), "throw"))


## Lets the armed Skill go.
func disarm() -> void:
	_armed = ""
	bar.skills().set_armed("")
	_update_overlay()


func armed_skill() -> String:
	return _armed


## Uses combat Skill `id` on monster `target` ("" for area and self Skills).
func use_skill(id: String, target: String = "") -> void:
	skip_replay()
	_cancel_walk()
	_armed = ""
	bar.skills().set_armed("")
	var thrown := bool(CombatSkills.action_of(Session.db, id).get("thrown", false))
	var r := Commands.use_skill(Session.gs, Session.db, id, target)
	_command_error(_sound_if_ok(String(r["error"]), "throw" if thrown else "swing"))


## Puts the held item down (X).
func drop() -> void:
	skip_replay()
	_command_error(_sound_if_ok(Commands.drop(Session.gs, Session.db), "drop"))


## Plays the "combat" cue `key` when a command worked (no error); returns
## the error (M12.2).
func _sound_if_ok(err: String, key: String) -> String:
	if err == "":
		Audio.play_key("combat", key)
	return err


## Plays the sound of a use-menu action when it worked; returns the error.
func _action_sound_if_ok(err: String, action_id: String) -> String:
	if err == "":
		Audio.play_cues([SoundCues.action_cue(Audio.db, action_id)])
	return err


## After a combat command: its error (too tired: the day ends), else the
## combat text.
func _command_error(err: String) -> void:
	if err != "":
		hud.add_lines([err])
		if Session.gs.clock.is_collapse_due(Session.db.rules["clock"]):
			sleep()
			return
	_finish()


## After every command: the combat text goes to the log; a knocked-out
## player loses the day at once (Commands.knock_out); then redraw.
## M17.3: when others acted, their turns replay first (see _start_replay).
func _finish() -> void:
	var gs := Session.gs
	if replay_turns and _others_acted(gs):
		_start_replay(gs)
		return
	hud.add_lines(gs.combat.lines)
	_settle()


## The end of a command (after its replay): a knock-out, else a redraw.
func _settle() -> void:
	var gs := Session.gs
	if Combat.is_down(gs):
		_show_night(Commands.knock_out(gs, Session.db))
		return
	Session.changed()


func open_use_menu() -> void:
	if not menu.open(Interact.options(Session.gs, Session.db), Session.db):
		hud.add_lines(["There is nothing to use here."])


## The bag (F): eat or drink something you carry.
func open_bag() -> void:
	if not menu.open_bag(Session.gs, Session.db):
		hud.add_lines(["You have nothing to eat or drink. (Coins: %s)" % Economy.format(Session.db,
				Session.gs.economy.coins)])


## A pick on the bag screen: runs it like a use-menu pick, then shows the
## bag again (not when the player went down or the day ended).
func use_from_bag(action_id: String) -> void:
	use("bag", action_id)
	if not Combat.is_down(Session.gs) and not dialog.visible:
		bag.open(Session.gs, Session.db)


func use(object_id: String, action_id: String) -> void:
	skip_replay()
	var gs := Session.gs
	var db := Session.db
	if action_id == Interact.SLEEP:
		sleep(object_id)
		return
	if action_id == Interact.ATTACK:
		attack_npc(object_id)
		return
	if action_id.begins_with(Interact.BUY) or action_id.begins_with(Interact.SELL):
		var buying := action_id.begins_with(Interact.BUY)
		var good := action_id.substr((Interact.BUY if buying else Interact.SELL).length())
		var r := Commands.buy(gs, db, object_id, good) if buying else Commands.sell(gs, db, object_id, good)
		_command_error(_action_sound_if_ok(r["error"], action_id))
		return
	if action_id.begins_with(Interact.LEARN):  # M17.5: a teacher's lesson
		_command_error(Commands.learn_spell(gs, db, object_id, action_id.substr(Interact.LEARN.length())))
		return
	if action_id.begins_with(Interact.USE_GOOD):
		_command_error(_action_sound_if_ok(
				Commands.use_good(gs, db, action_id.substr(Interact.USE_GOOD.length())), action_id))
		return
	if action_id.begins_with(Interact.HOLD_GOOD):
		_command_error(Commands.hold_good(gs, db, action_id.substr(Interact.HOLD_GOOD.length())))
		return
	if action_id.begins_with(Interact.DROP_GOOD):
		_command_error(_sound_if_ok(
				Commands.drop_good(gs, db, action_id.substr(Interact.DROP_GOOD.length())), "drop"))
		return
	if action_id == Interact.STOW:
		_command_error(Commands.stow(gs, db))
		return
	if action_id.begins_with(Interact.SERVE):
		var s := Commands.serve(gs, db, object_id, action_id.substr(Interact.SERVE.length()))
		_command_error(_action_sound_if_ok(s["error"], Guests.SERVE_ACTION))
		return
	if action_id == Interact.RIDE:
		_command_error(_action_sound_if_ok(Commands.ride(gs, db, object_id), action_id))
		return
	if Interact.is_portal_action(action_id):
		_command_error(_action_sound_if_ok(
				Commands.portal(gs, db, object_id, Interact.portal_link_of(action_id)), Interact.PORTAL))
		return
	if action_id == Interact.TAKE:
		_command_error(_action_sound_if_ok(Commands.take(Session.gs, Session.db, object_id), action_id))
		return
	var r := Commands.interact(Session.gs, Session.db, object_id, action_id)
	_action_sound_if_ok(r["error"], action_id)
	if r["error"] != "":
		hud.add_lines([r["error"]])
		if Session.gs.clock.is_collapse_due(Session.db.rules["clock"]):
			sleep()
			return
	else:
		hud.add_lines(["%s." % Session.db.actions[action_id]["name"]])
	_finish()


## Attacks the NPC next to you (M14.5). A major NPC's first attack shows the fate warning
## instead; its Strike answer comes back here with `confirmed`.
func attack_npc(npc: String, confirmed: bool = false) -> void:
	skip_replay()
	var r := Commands.attack_npc(Session.gs, Session.db, npc, confirmed)
	if r["warn"]:
		dialog.open([SystemMessages.fate_page(Session.db, npc)] as Array[Dictionary], Session.gs, Session.db)
		return
	if r["error"] != "":
		_command_error(r["error"])
		return
	Audio.play_key("combat", "hit" if r["hit"] else "swing")
	_finish()


## Ends the day (a collapse if the player is past the awake limit, a
## knock-out if they are down) and shows the night in the System dialog.
## `bed`: the bed picked in the use menu ("" = where you stand, Z).
func sleep(bed: String = "") -> void:
	skip_replay()
	_cancel_walk()
	var night := Commands.sleep(Session.gs, Session.db, bed)
	if night.is_empty():  # refused: enemies near, outdoors, or no coins for the room
		hud.add_lines(Session.gs.combat.lines)
		Session.changed()
		return
	Audio.play_cues([SoundCues.action_cue(Audio.db, Interact.SLEEP)])
	_show_night(night)


## Ends the player's turn (the End turn button; Space does it through step).
func end_turn() -> void:
	skip_replay()
	_cancel_walk()
	_command_error(Commands.end_turn(Session.gs, Session.db))


## True if a fighter other than the player acted in the last command.
static func _others_acted(gs: GameState) -> bool:
	for t: Dictionary in gs.combat.turns:
		if t["id"] != Encounter.PLAYER:
			return true
	return false


## Replays the command's turn log; each entry's log lines (with any lines
## written between entries) go to the HUD as it starts, the rest at the end.
func _start_replay(gs: GameState) -> void:
	_cancel_walk()
	view.overlay.clear()
	var lines := gs.combat.lines
	_replay_lines = []
	var at := 0
	for t: Dictionary in gs.combat.turns:
		var to := maxi(int(t.get("line_to", at)), at)
		_replay_lines.append(lines.slice(at, to))
		at = to
	_replay_tail = lines.slice(at)
	view.replay(gs.combat.turns.duplicate(true))


func _on_replay_step(index: int) -> void:
	if index < _replay_lines.size():
		hud.add_lines(_replay_lines[index])
		_replay_lines[index] = []
	var turns := Session.gs.combat.turns
	if index < turns.size():
		bar.show_acting(String(turns[index]["id"]))


func _on_replay_done() -> void:
	_close_replay()


## Ends a running replay at once (a key, a click or a command).
func skip_replay() -> void:
	if not view.is_replaying():
		return
	view.skip_replay()
	_close_replay()


func _close_replay() -> void:
	for chunk: Array in _replay_lines:
		hud.add_lines(chunk)
	hud.add_lines(_replay_tail)
	_replay_lines = []
	_replay_tail = []
	_replayed = true
	_settle()


## Mouse in a fight (M17.3): the hover preview, a left click walks or
## attacks, a right click stops a walk.
func _mouse(event: InputEventMouse) -> void:
	if is_busy() or not Encounter.is_player_turn(Session.gs):
		return
	# The event's own position: a touch moves no mouse pointer.
	var cell := view.cell_at(view.get_canvas_transform().affine_inverse() * event.position)
	if event is InputEventMouseMotion:
		hover(cell)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.device == InputEvent.DEVICE_ID_EMULATION:
				tap(cell)
			else:
				click(cell)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			cancel()
			get_viewport().set_input_as_handled()


## A tap on `cell` in a fight (M20.1): a touch has no hover, so the first tap
## shows the plan (path, hit chance) and a second tap on the same cell acts.
func tap(cell: Vector2i) -> void:
	if _tapped == cell:
		_tapped = NO_CELL
		click(cell)
	else:
		_tapped = cell
		hover(cell)


## Stops a click's walk and disarms a Skill (a right click, or Cancel on touch).
func cancel() -> void:
	_tapped = NO_CELL
	_cancel_walk()
	if _armed != "":
		disarm()


## The mouse is over `cell`: show what a click there would do.
func hover(cell: Vector2i) -> void:
	_hover = cell
	_show_plan()


## A click on `cell` in a fight: walk the plan's steps, then its blow.
func click(cell: Vector2i) -> void:
	skip_replay()
	var gs := Session.gs
	if not Encounter.is_player_turn(gs):
		return
	if _armed != "":
		if _armed_spell() != "":
			cast_spell(_armed_spell(), cell)
			return
		var foe := gs.combat.at(gs.player.area, cell)
		if CombatSkills.targets(gs, Session.db, _armed).has(foe):
			use_skill(_armed, foe)
		else:
			disarm()
		return
	var plan := Encounter.plan_to(gs, Session.db, cell)
	if plan.is_empty():
		return
	_walk.assign(plan["steps"])
	_walk_attack = String(plan["attack"])
	_walk_target = String(plan["target"])
	if _walk_target != "" and _walk_attack == "" and _walk.is_empty():
		hud.add_lines([Encounter.NO_AP])
		return
	_walk_next()
	_cooldown = STEP_REPEAT


func _walking() -> bool:
	return not _walk.is_empty() or _walk_attack != ""


func _cancel_walk() -> void:
	_walk.clear()
	_walk_attack = ""
	_walk_target = ""


## One step of a click's walk, or its blow at the end. The walk stops when a
## step does not move the player (someone in the way, no AP) or the turn ends.
func _walk_next() -> void:
	var gs := Session.gs
	if not Encounter.is_player_turn(gs):
		_cancel_walk()
		return
	if not _walk.is_empty():
		var at := gs.player.pos()
		var area := gs.player.area
		step(_walk.pop_front())
		if gs.player.pos() == at or gs.player.area != area:
			_cancel_walk()
		return
	var dir := _walk_attack
	var target := _walk_target
	_cancel_walk()
	if target.begins_with(Encounter.NPC):
		attack_npc(target.substr(Encounter.NPC.length()))
	elif dir != "":
		step(dir)  # a step into the foe hits it


## The move range on the player's turn (exits in yellow), and the hover plan.
func _update_overlay() -> void:
	var gs := Session.gs
	if not Encounter.is_player_turn(gs):
		view.overlay.clear()
		if _armed != "":
			_armed = ""
			bar.skills().set_armed("")
		return
	var marks: Array[Vector2i] = []
	if _armed_spell() != "":  # M17.5: gold frames for a "one" spell; the others preview on hover
		var sid := _armed_spell()
		if Spells.resource_error(gs, Session.db, sid) != "":  # AP or MP ran out
			_armed = ""
			bar.skills().set_armed("")
		elif String(Spells.spell(Session.db, sid)["shape"]) == "one":
			for foe in Spells.one_targets(gs, Session.db, sid):
				marks.append(CombatState.pos_of(gs.combat.monsters[foe]))
			if marks.is_empty():
				_armed = ""
				bar.skills().set_armed("")
	elif _armed != "":
		for foe in CombatSkills.targets(gs, Session.db, _armed):
			marks.append(CombatState.pos_of(gs.combat.monsters[foe]))
		if marks.is_empty():  # nothing left to hit (the foe fell, AP ran out)
			_armed = ""
			bar.skills().set_armed("")
	view.overlay.show_marks(marks)
	var reach := Encounter.reach(gs, Session.db)
	var exits := {}
	for cell: Vector2i in reach:
		if not Session.db.maps.exit_at(gs.player.area, cell).is_empty():
			exits[cell] = true
	view.overlay.show_reach(reach, exits)
	var covers := {}  # M17.6: bars on the tile edges that have cover beside them
	var stand: Array = reach.keys()
	stand.append(gs.player.pos())
	for cell: Vector2i in stand:
		var sides := Cover.sides(Session.db, gs.player.area, cell)
		if not sides.is_empty():
			covers[cell] = sides
	view.overlay.show_covers(covers)
	_show_plan()


## M17.5: the tiles the armed spell would hit if cast at the hovered tile (orange), and
## over the first foe in them the hit chance (one foe) or the number of foes.
func _show_spell_plan(sid: String) -> void:
	var gs := Session.gs
	var db := Session.db
	var s := Spells.spell(db, sid)
	var here := gs.player.pos()
	var shape := String(s["shape"])
	if shape in ["one", "blast"] and (Combat._dist(here, _hover) > int(s["range"])
			or not Cover.sight(db, gs.player.area, here, _hover)):  # M17.6: no sight through a wall
		view.overlay.clear_plan()
		return
	var tiles := Spells.cells(gs, db, sid, _hover, here)
	view.overlay.show_preview(tiles)
	var foes := Spells.foes_in(gs, tiles)
	if foes.is_empty():
		view.overlay.clear_plan()
		return
	var at := CombatState.pos_of(gs.combat.monsters[foes[0]])
	var text := _with_note("%d%%" % roundi(Spells.hit_chance(gs, db, sid, foes[0]) * 100.0),
			Cover.note(gs, db, gs.player.area, here, at, String(s["hit"]) != "auto", Cover.FRIEND)) if shape == "one" \
			else "%d foe%s" % [foes.size(), "" if foes.size() == 1 else "s"]
	view.overlay.show_plan([] as Array[Vector2i], true, at, text)


## The path and hit chance of a click on the hovered cell.
func _show_plan() -> void:
	var gs := Session.gs
	var db := Session.db
	view.overlay.show_preview([] as Array[Vector2i])
	if _armed_spell() != "":
		_show_spell_plan(_armed_spell())
		return
	if _armed != "":  # M17.4: the armed Skill's hit chance on the foe under the mouse
		var foe := gs.combat.at(gs.player.area, _hover)
		if CombatSkills.targets(gs, db, _armed).has(foe):
			view.overlay.show_plan([] as Array[Vector2i], true, _hover,
					"%d%%" % roundi(CombatSkills.hit_chance(gs, db, _armed, foe) * 100.0))
		else:
			view.overlay.clear_plan()
		return
	var plan := Encounter.plan_to(gs, db, _hover) if Encounter.is_player_turn(gs) else {}
	if plan.is_empty():
		view.overlay.clear_plan()
		return
	var cells: Array[Vector2i] = []
	var at := gs.player.pos()
	for dir: String in plan["steps"]:
		at += PlayerState.DIRS[dir]
		cells.append(at)
	var target := String(plan["target"])
	if target == "":
		view.overlay.show_plan(cells, false)
		return
	var text := _with_note("%d%%" % roundi(Combat.player_hit_chance(gs, db, target) * 100.0),
			Cover.note(gs, db, gs.player.area, at, _hover, false, Cover.FRIEND)) \
			if plan["attack"] != "" else Encounter.NO_AP
	var held: Dictionary = db.combat.items.get(gs.player.held, {})
	if not held.is_empty() and target == Combat.nearest_foe(gs):
		var dist := AnimDiff.king(gs.player.pos(), _hover)
		var note := Cover.note(gs, db, gs.player.area, gs.player.pos(), _hover, true, Cover.FRIEND)
		if dist <= int(held["throw_range"]) and note != "no sight":  # M17.6: a wall blocks a throw
			text += "  " + _with_note("T: %d%%" % roundi(Combat.player_hit_chance(gs, db, target, true, dist) * 100.0), note)
	view.overlay.show_plan(cells, true, _hover, text)


## "45%" + "half cover" -> "45% (half cover)" (M17.6).
func _with_note(text: String, note: String) -> String:
	return text if note == "" else "%s (%s)" % [text, note]


func _show_night(night: Dictionary) -> void:
	var what := "You sleep."
	if night["knocked_out"]:
		what = "Everything goes dark."
	elif night["collapsed"]:
		what = "You collapse."
	hud.add_lines([what])
	Session.changed()
	dialog.open(SystemMessages.pages(night, Session.gs, Session.db), Session.gs, Session.db)


## The message history, newest first (the L page).
func _history_lines() -> Array:
	var lines: Array = hud.history()
	lines.reverse()
	return lines


## "Day 3, 06:00." with the day counted from the player's arrival (M15.1).
func _day_line() -> String:
	return "Day %d, %s." % [Clock.player_day(Session.gs.clock.day(), Session.db.rules["clock"]),
			Session.gs.clock.time_string()]


func _on_dialog_closed() -> void:
	hud.add_lines([_day_line()])
	if Session.autosave() != OK:
		hud.add_lines(["Autosave failed."])
	Session.changed()


## Autosaves, then goes back to the title screen.
func quit_to_title() -> void:
	Session.autosave()
	if switch_scene:
		get_tree().change_scene_to_file.call_deferred(TITLE_SCENE)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Session.autosave()


func toggle_console() -> void:
	console_layer.visible = not console_layer.visible
	if console_layer.visible:
		menu.close()
		sheet.close()
		journal.close()
		bag.close()
		pause.close()
		console_input.grab_focus()
	else:
		console_input.release_focus()
