## The game screen: world map, HUD, "use" menu and the debug console
## overlay. Turns keys into Commands on Session.gs, then redraws.
## Presentation only (CLAUDE.md rule 1).
extends Node

## Seconds between steps while a direction key is held.
const STEP_REPEAT := 0.14
const MOVE_KEYS := {
	"n": [KEY_W, KEY_UP], "s": [KEY_S, KEY_DOWN], "e": [KEY_D, KEY_RIGHT], "w": [KEY_A, KEY_LEFT],
}

var _cooldown := 0.0

@onready var view: WorldView = $WorldView
@onready var hud: Hud = $HudLayer/HUD
@onready var menu: InteractMenu = $MenuLayer/InteractMenu
@onready var console_layer: CanvasLayer = $ConsoleLayer
@onready var console_input: LineEdit = $ConsoleLayer/DebugConsole.get_node("%Input")


func _ready() -> void:
	view.setup(Session.db.maps)
	Session.state_changed.connect(_redraw)
	menu.chosen.connect(use)
	console_layer.visible = false
	hud.add_lines(["You stand outside the east gate of Liscor, a walled city."])
	if not Session.db.is_valid():
		hud.add_lines(["Data errors: see the debug console (`)."])
	_redraw()


func _redraw() -> void:
	view.refresh(Session.gs)
	hud.refresh(Session.gs, Session.db)


## True while a menu or the console has the keyboard.
func is_busy() -> bool:
	return console_layer.visible or menu.visible


func _input(event: InputEvent) -> void:
	# Backtick before the console's LineEdit sees it.
	if event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode == KEY_QUOTELEFT:
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
		_:
			return
	get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if is_busy():
		return
	var dir := _held_direction()
	if dir == "":
		_cooldown = 0.0
	elif _cooldown == 0.0:
		step(dir)
		_cooldown = STEP_REPEAT


func _held_direction() -> String:
	for dir: String in MOVE_KEYS:
		for key: Key in MOVE_KEYS[dir]:
			if Input.is_physical_key_pressed(key):
				return dir
	return ""


func step(dir: String) -> void:
	var gs := Session.gs
	var r := Commands.move(gs, Session.db, dir)
	if r["refused"] and gs.clock.is_collapse_due(Session.db.rules["clock"]):
		hud.add_lines(["You are too tired to take another step."])
		sleep()
		return
	if r["exit_to"] != "":
		hud.add_lines(["You travel to %s (%d min)." % [
			Session.db.maps.areas[r["exit_to"]]["name"], int(r["minutes"])]])
	Session.changed()


func open_use_menu() -> void:
	if not menu.open(Interact.options(Session.gs, Session.db), Session.db):
		hud.add_lines(["There is nothing to use here."])


func use(object_id: String, action_id: String) -> void:
	var r := Commands.interact(Session.gs, Session.db, object_id, action_id)
	if r["error"] != "":
		hud.add_lines([r["error"]])
	else:
		hud.add_lines(["%s: %.1f XP." % [Session.db.actions[action_id]["name"], float(r["record"]["xp"])]])
	Session.changed()


## Ends the day (a collapse if the player is past the awake limit). The
## System dialog comes in M4.5; for now the night lines go to the log.
func sleep() -> void:
	var night := Commands.sleep(Session.gs, Session.db)
	var lines: Array = ["--- You sleep. ---"]
	lines.append_array(night["lines"])
	if (night["lines"] as Array).is_empty():
		lines.append("The System is silent.")
	lines.append("--- Day %d, %s. ---" % [Session.gs.clock.day(), Session.gs.clock.time_string()])
	hud.add_lines(lines)
	Session.changed()


func toggle_console() -> void:
	console_layer.visible = not console_layer.visible
	if console_layer.visible:
		menu.close()
		console_input.grab_focus()
	else:
		console_input.release_focus()
