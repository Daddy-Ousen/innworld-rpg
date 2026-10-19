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
## End turn; a click walks and hits (MainAim). When others acted in a command,
## the view replays their turns (the log lines come with each turn); any key or
## click skips the replay. Replays are off headless (`replay_turns`), so the
## sims that drive this scene see each command's end state at once.
## M17.4: keys 1-9 (or the Skill bar's buttons) use a combat Skill (MainAim).
## M26.0 (ADR 0040): the parts live in their own scripts: MainInput (keys and
## mouse), MainAim (combat aiming, a click's walk, the turn overlay),
## MainTravel (the long-road prompt) and MainPanels (panels, touch pad, night
## and morning). This script runs the commands and the replay.
## Presentation only (CLAUDE.md rule 1).
class_name MainScreen
extends Node

## Seconds between steps while a direction key is held.
const STEP_REPEAT := 0.14
const TITLE_SCENE := "res://ui/title_menu.tscn"
const WAIT := "wait"

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
## A replay's log lines: one list per turn-log entry, then the rest.
var _replay_lines: Array = []
var _replay_tail: Array = []
## The next redraw follows a replay (WorldView.refresh `replayed`).
var _replayed := false

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
@onready var console_input: LineEdit = $ConsoleLayer/DebugConsole.get_node("%Input")
var travel: TravelPrompt

var controls: MainInput
var aim: MainAim
var road: MainTravel
var panels: MainPanels


func _ready() -> void:
	controls = MainInput.new(self)
	aim = MainAim.new(self)
	panels = MainPanels.new(self)
	road = MainTravel.new(self, $SystemLayer)
	travel = road.prompt
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
	bag.chosen.connect(panels.use_from_bag)
	dialog.closed.connect(panels.on_dialog_closed)
	dialog.struck.connect(attack_npc.bind(true))
	bar.end_turn.connect(end_turn)
	bar.skill.connect(pick_skill)
	view.replay_step.connect(_on_replay_step)
	view.replay_done.connect(_on_replay_done)
	pause.message.connect(func(line: String) -> void: hud.add_lines([line]))
	pause.quit_requested.connect(quit_to_title)
	touch.cancel_pressed.connect(cancel)
	Session.touch_changed.connect(panels.sync_touch)
	Session.ui_scale_changed.connect(panels.apply_ui_scale)
	panels.apply_ui_scale()
	console_layer.visible = false
	hud.add_lines([panels.day_line()])
	if not Session.db.is_valid():
		hud.add_lines(["Data errors: see the debug console (`)."])
	_redraw()
	if Session.fresh:
		Session.fresh = false
		var start := Movement.start_of(Session.db, Session.start_id)
		dialog.open([SystemMessages.welcome_page(start,
				PlayerIdentity.who(Session.gs, Session.db))] as Array[Dictionary], Session.gs, Session.db)


func _redraw() -> void:
	if view.is_replaying():
		return  # the redraw comes when the replay ends
	aim.tapped = MainAim.NO_CELL  # a new state: the next tap shows its plan first
	view.refresh(Session.gs, Session.db, _replayed)
	_replayed = false
	hud.refresh(Session.gs, Session.db)
	bar.refresh(Session.gs, Session.db)
	aim.update_overlay()
	Audio.music(MusicPick.track(Session.gs, Session.db, Audio.db))
	Audio.ambience(AmbiencePick.bed(Session.gs, Session.db, Audio.db))


## True while a menu, the sheet, the journal, the bag, the System dialog or
## the console has the keyboard.
func is_busy() -> bool:
	return panels.is_busy()


func toggle_console() -> void:
	panels.toggle_console()


func open_use_menu() -> void:
	panels.open_use_menu()


func pick_skill(id: String) -> void:
	aim.pick_skill(id)


func armed_skill() -> String:
	return aim.armed


func hover(cell: Vector2i) -> void:
	aim.hover(cell)


## A click on `cell` in a fight (MainAim.click); a walk steps every STEP_REPEAT.
func click(cell: Vector2i) -> void:
	if aim.click(cell):
		_cooldown = STEP_REPEAT


## A touch tap on `cell` in a fight (MainAim.tap).
func tap(cell: Vector2i) -> void:
	if aim.tap(cell):
		_cooldown = STEP_REPEAT


func cancel() -> void:
	aim.cancel()


func _walking() -> bool:
	return aim.walking()


func _input(event: InputEvent) -> void:
	controls.console_key(event)


func _unhandled_input(event: InputEvent) -> void:
	controls.unhandled(event)


func _process(delta: float) -> void:
	panels.sync_touch()
	_cooldown = maxf(_cooldown - delta, 0.0)
	if is_busy():
		return
	if aim.walking():
		if _cooldown == 0.0:
			aim.walk_next()
			_cooldown = STEP_REPEAT
		return
	var dir := controls.held_direction()
	if dir != _attack_dir:
		_attack_dir = ""
	if dir == "":
		_cooldown = 0.0
	elif _cooldown == 0.0 and _attack_dir == "":
		step(dir)
		_cooldown = STEP_REPEAT


## One step in `dir` (n, s, e, w), or WAIT for one step of time. A step
## into a monster attacks it (or springs a hidden one).
func step(dir: String) -> void:
	skip_replay()
	var gs := Session.gs
	var db := Session.db
	if aim.armed != "" and dir != WAIT:
		_attack_dir = dir  # the key must be let go before it acts again
		aim.aim_dir(dir)
		return
	if dir != WAIT and road.ask(dir):
		_attack_dir = dir  # the key must be let go before it acts again
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


## Casts spell `sid` at tile `at` (M17.5). A cast that works lets the spell go; a refused
## one keeps it armed so the player can pick another tile.
func cast_spell(sid: String, at: Vector2i) -> void:
	skip_replay()
	aim.cancel_walk()
	var r := Commands.cast(Session.gs, Session.db, sid, at)
	if r["error"] == "":
		aim.let_go()
	_command_error(_sound_if_ok(String(r["error"]), "throw"))


## Uses combat Skill `id` on monster `target` ("" for area and self Skills).
func use_skill(id: String, target: String = "") -> void:
	skip_replay()
	aim.cancel_walk()
	aim.let_go()
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
		panels.show_night(Commands.knock_out(gs, Session.db))
		return
	Session.changed()


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
	if action_id == Interact.APPRAISE:  # M25.3: no time passes
		sheet.open_lines(NpcSheet.lines(gs, db, object_id))
		return
	if Interact.is_trade_action(action_id):
		var t := Interact.trade_parts(action_id)
		var r := Commands.buy(gs, db, object_id, t["good"], t["count"]) if t["buying"] \
				else Commands.sell(gs, db, object_id, t["good"], t["count"])
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
	action_id = Interact.action_of(Session.db, object_id, action_id)  # M30.1: an NPC's own option
	_action_sound_if_ok(r["error"], action_id)
	if r["error"] != "":
		hud.add_lines([r["error"]])
		if Session.gs.clock.is_collapse_due(Session.db.rules["clock"]):
			sleep()
			return
	else:
		hud.add_lines(["%s." % Session.db.actions[action_id]["name"]])
	_finish()
	if r.has("page"):  # M30.4: an own option's talk page, with the NPC's face
		dialog.open([SystemMessages.talk_page(object_id, r["page"])] as Array[Dictionary],
				Session.gs, Session.db)


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
	aim.cancel_walk()
	var night := Commands.sleep(Session.gs, Session.db, bed)
	if night.is_empty():  # refused: enemies near, outdoors, or no coins for the room
		hud.add_lines(Session.gs.combat.lines)
		Session.changed()
		return
	Audio.play_cues([SoundCues.action_cue(Audio.db, Interact.SLEEP)])
	panels.show_night(night)


## Ends the player's turn (the End turn button; Space does it through step).
func end_turn() -> void:
	skip_replay()
	aim.cancel_walk()
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
	aim.cancel_walk()
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


## Autosaves, then goes back to the title screen.
func quit_to_title() -> void:
	Session.autosave()
	if switch_scene:
		get_tree().change_scene_to_file.call_deferred(TITLE_SCENE)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Session.autosave()
