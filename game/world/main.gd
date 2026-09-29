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
## Presentation only (CLAUDE.md rule 1).
extends Node

## Seconds between steps while a direction key is held.
const STEP_REPEAT := 0.14
const TITLE_SCENE := "res://ui/title_menu.tscn"
const WAIT := "wait"
const MOVE_KEYS := {
	"n": [KEY_W, KEY_UP], "s": [KEY_S, KEY_DOWN], "e": [KEY_D, KEY_RIGHT], "w": [KEY_A, KEY_LEFT],
	WAIT: [KEY_SPACE],
}

var _cooldown := 0.0
## The NPC the player last bumped into (say it once, not every repeat).
var _bumped := ""
## The direction of the last bump attack. That key must be let go before it
## moves or attacks again.
var _attack_dir := ""
## Tests set this false: quit to title then only autosaves.
var switch_scene := true

@onready var view: WorldView = $WorldView
@onready var hud: Hud = $HudLayer/HUD
@onready var menu: InteractMenu = $MenuLayer/InteractMenu
@onready var sheet: CharacterSheet = $MenuLayer/CharacterSheet
@onready var journal: Journal = $MenuLayer/Journal
@onready var bag: Bag = $MenuLayer/Bag
@onready var message_log: TextPage = $MenuLayer/MessageLog
@onready var help: TextPage = $MenuLayer/Help
@onready var pause: PauseMenu = $MenuLayer/PauseMenu
@onready var dialog: SystemDialog = $SystemLayer/SystemDialog
@onready var console_layer: CanvasLayer = $ConsoleLayer
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
	view.setup(Session.db.maps, names, Session.db.combat.enemies, max_hp,
			String(Winter.rules(Session.db).get("flag", "")), races)
	view.sounds.connect(Audio.play_cues)
	view.area_loops.connect(func(loops: Array) -> void:
		Audio.place_loops(view.loop_spots, loops, WorldView.TILE))
	Session.state_changed.connect(_redraw)
	menu.chosen.connect(use)
	bag.chosen.connect(use_from_bag)
	dialog.closed.connect(_on_dialog_closed)
	dialog.struck.connect(attack_npc.bind(true))
	journal.focus_changed.connect(Session.changed)
	pause.message.connect(func(line: String) -> void: hud.add_lines([line]))
	pause.quit_requested.connect(quit_to_title)
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
	view.refresh(Session.gs, Session.db)
	hud.refresh(Session.gs, Session.db)
	Audio.music(MusicPick.track(Session.gs, Session.db, Audio.db))
	Audio.ambience(AmbiencePick.bed(Session.gs, Session.db, Audio.db))


## True while a menu, the sheet, the journal, the bag, the System dialog or
## the console has the keyboard.
func is_busy() -> bool:
	return console_layer.visible or menu.visible or sheet.visible or journal.visible \
			or bag.visible or pause.visible or dialog.visible or message_log.visible or help.visible


func _input(event: InputEvent) -> void:
	# Backtick before the console's LineEdit sees it. Not while the System
	# dialog waits for an answer.
	if event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode == KEY_QUOTELEFT and not dialog.visible:
		toggle_console()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if is_busy() or not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_E:
			open_use_menu()
		KEY_Z:
			sleep()
		KEY_F:
			open_bag()
		KEY_C:
			sheet.open(Session.gs, Session.db)
		KEY_J:
			journal.open(Session.gs, Session.db)
		KEY_I:
			bag.open(Session.gs, Session.db)
		KEY_L:
			message_log.open(_history_lines())
		KEY_H:
			help.open(SystemMessages.KEYS)
		KEY_ESCAPE:
			pause.open()
		KEY_B:
			block()
		KEY_T:
			throw()
		KEY_X:
			drop()
		_:
			return
	get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if is_busy():
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
	for dir: String in MOVE_KEYS:
		for key: Key in MOVE_KEYS[dir]:
			if Input.is_physical_key_pressed(key):
				return dir
	return ""


## One step in `dir` (n, s, e, w), or WAIT for one step of time. A step
## into a monster attacks it (or springs a hidden one).
func step(dir: String) -> void:
	var gs := Session.gs
	var db := Session.db
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
	_command_error(_sound_if_ok(Commands.block(Session.gs, Session.db), "block"))


## Throws the held item at the nearest monster you can see (T).
func throw() -> void:
	if Session.gs.player.held == "":
		hud.add_lines(["You hold nothing to throw."])
		return
	var target := Combat.nearest_foe(Session.gs)
	if target == "":
		hud.add_lines(["There is nothing to throw at."])
		return
	_command_error(_sound_if_ok(Commands.throw(Session.gs, Session.db, target)["error"], "throw"))


## Puts the held item down (X).
func drop() -> void:
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
func _finish() -> void:
	var gs := Session.gs
	hud.add_lines(gs.combat.lines)
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
	if action_id == Interact.PORTAL:
		_command_error(_action_sound_if_ok(Commands.portal(gs, db, object_id), action_id))
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
	var night := Commands.sleep(Session.gs, Session.db, bed)
	if night.is_empty():  # refused: enemies near, outdoors, or no coins for the room
		hud.add_lines(Session.gs.combat.lines)
		Session.changed()
		return
	Audio.play_cues([SoundCues.action_cue(Audio.db, Interact.SLEEP)])
	_show_night(night)


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
