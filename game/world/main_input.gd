## Keys and mouse on the game screen (M26.0, split from main.gd). Held keys
## (WASD/arrows walk, Space waits) are read each frame by MainScreen._process
## through `held_direction`. A key press opens a panel, runs a command or picks
## a combat Skill (keys 1-9, M17.4); Esc lets an armed Skill go, else opens the
## pause menu. In a fight the mouse hovers, clicks and taps (MainAim). Any key or
## click skips a running replay (M17.3).
## Presentation only (CLAUDE.md rule 1).
class_name MainInput
extends RefCounted

## Where the last touch went down outside a fight (M34.3; INF = none).
var _tap_from := Vector2.INF

## Held input actions (project.godot [input], M20.0): direction -> action.
const MOVE_ACTIONS := {
	"n": &"move_n", "s": &"move_s", "e": &"move_e", "w": &"move_w", "wait": &"wait",
}
## Skill bar slots: action -> slot (keys 1-9).
const SKILL_ACTIONS: Array[StringName] = [
	&"skill_1", &"skill_2", &"skill_3", &"skill_4", &"skill_5", &"skill_6", &"skill_7", &"skill_8",
	&"skill_9",
]

## The MainScreen (untyped: a typed back link makes a script cycle that leaks at exit).
var _m


func _init(screen: Node) -> void:
	_m = screen


## Backtick before the console's LineEdit sees it. Not while the System
## dialog waits for an answer.
func console_key(event: InputEvent) -> void:
	if event.is_action_pressed(&"console") and not _m.dialog.visible:
		_m.toggle_console()
		_m.get_viewport().set_input_as_handled()


func unhandled(event: InputEvent) -> void:
	if _m.view.is_replaying() and (event is InputEventKey or event is InputEventAction \
			or event is InputEventMouseButton) and event.is_pressed() and not event.is_echo():
		_m.skip_replay()
		_m.get_viewport().set_input_as_handled()
		return
	if event is InputEventMouse:
		mouse(event)
		return
	if _m.is_busy() or not event.is_pressed() or event.is_echo():
		return
	for i in SKILL_ACTIONS.size():
		if event.is_action_pressed(SKILL_ACTIONS[i]):
			var ids: Array[String] = _m.bar.skills().ids()
			if i < ids.size():
				_m.pick_skill(ids[i])
			_m.get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed(&"back") and _m.aim.armed != "":
		_m.aim.disarm()
		_m.get_viewport().set_input_as_handled()
		return
	if not _key(event):
		return
	_m.get_viewport().set_input_as_handled()


## Runs the panel or command of a pressed key; false if the key has none.
func _key(event: InputEvent) -> bool:
	var gs := Session.gs
	var db := Session.db
	if event.is_action_pressed(&"use"):
		_m.open_use_menu()
	elif event.is_action_pressed(&"sleep"):
		_m.sleep()
	elif event.is_action_pressed(&"eat"):
		_m.panels.open_bag()
	elif event.is_action_pressed(&"sheet"):
		_m.sheet.open(gs, db)
	elif event.is_action_pressed(&"journal"):
		_m.journal.open(gs, db)
	elif event.is_action_pressed(&"bag"):
		_m.bag.open(gs, db)
	elif event.is_action_pressed(&"log"):
		_m.message_log.open(_m.panels.history_lines())
	elif event.is_action_pressed(&"help"):
		_m.help.open(SystemMessages.KEYS)
	elif event.is_action_pressed(&"back"):
		_m.pause.open()
	elif event.is_action_pressed(&"block"):
		_m.block()
	elif event.is_action_pressed(&"throw"):
		_m.throw()
	elif event.is_action_pressed(&"drop"):
		_m.drop()
	else:
		return false
	return true


## The held direction key (n, s, e, w, or MainScreen.WAIT), or "".
func held_direction() -> String:
	for dir: String in MOVE_ACTIONS:
		if Input.is_action_pressed(MOVE_ACTIONS[dir]):
			return dir
	return ""


## Mouse in a fight (M17.3): the hover preview, a left click walks or
## attacks, a right click stops a walk. Outside a fight, a touch tap walks
## and acts (M34.3, world_tap).
func mouse(event: InputEventMouse) -> void:
	if _m.is_busy():
		return
	if not Encounter.is_player_turn(Session.gs):
		world_tap(event)
		return
	# The event's own position: a touch moves no mouse pointer.
	var view: WorldView = _m.view
	var cell := view.cell_at(view.get_canvas_transform().affine_inverse() * event.position)
	if event is InputEventMouseMotion:
		_m.hover(cell)
	elif event is InputEventMouseButton and event.pressed:
		_tap_from = Vector2.INF
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.device == InputEvent.DEVICE_ID_EMULATION:
				_m.tap(cell)
			else:
				_m.click(cell)
			_m.get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_m.cancel()
			_m.get_viewport().set_input_as_handled()


## M34.3: outside a fight, a touch tap on the map (Controls: Tap + stick) walks
## to what is there and opens its card (MainScreen.tap_world). It acts when the
## finger lifts, and only when it did not move the stick or slide.
func world_tap(event: InputEventMouse) -> void:
	if not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT \
			or event.device != InputEvent.DEVICE_ID_EMULATION:
		return
	if not Session.tap_walk_on() or Encounter.active(Session.gs):
		_tap_from = Vector2.INF
		return
	if event.pressed:
		_tap_from = event.position
		return
	var from := _tap_from
	_tap_from = Vector2.INF
	if from == Vector2.INF or event.position.distance_to(from) > MainTap.SLOP or _m.touch.stick_walked:
		return
	var view: WorldView = _m.view
	_m.tap_world(view.cell_at(view.get_canvas_transform().affine_inverse() * event.position))
	_m.get_viewport().set_input_as_handled()
