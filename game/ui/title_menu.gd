## The title screen (M6.1, the main scene): New game, Continue (the newest
## save), Load, Options (volumes, M12.1), Quit. With more than one start in rules.world.starts, New
## game first asks where the player arrives (M8.5), then who the player is (M30.5,
## CreatePlayer: name, look, background). Sets Session's game, then opens the game
## screen. Presentation only.
class_name TitleMenu
extends Control

signal entered_game

const GAME_SCENE := "res://world/main.tscn"

## Tests set this false and watch `entered_game` instead of a scene change.
var switch_scene := true
## Seed for a new game; below 0 takes one from the system clock.
var new_game_seed := -1

@onready var slots: SlotList = %Slots
@onready var options: OptionsMenu = %Options
@onready var _new_game: Button = %NewGame
@onready var _continue: Button = %Continue
@onready var _load: Button = %Load
@onready var _note: Label = %Note
@onready var _starts: VBoxContainer = %Starts
## M30.5: the "Who are you?" step (made in _ready). It sits in its own scroll box over the
## whole screen, so a big menu size (a phone) can still reach Begin.
var create: CreatePlayer
var create_box: ScrollContainer
## The start picked before the "Who are you?" step.
var _start_id := ""
## The New game, Continue, Load, Options and Quit buttons (hidden while choosing a start).
@onready var _menu: Array[Control] = [%NewGame, %Continue, %Load, %OptionsButton, %Quit]


func _ready() -> void:
	_new_game.pressed.connect(open_starts)
	_continue.pressed.connect(continue_game)
	_load.pressed.connect(open_load)
	%OptionsButton.pressed.connect(open_options)
	options.closed.connect(close_options)
	%Quit.pressed.connect(func() -> void: get_tree().quit())
	if not shows_quit(OS.has_feature("web")):
		_menu.erase(%Quit)
		%Quit.hide()
	create_box = ScrollContainer.new()
	create_box.name = "CreateBox"
	create_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	create_box.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	create_box.follow_focus = true  # keys and pads scroll to the focused button
	create_box.visible = false
	$Center.add_sibling(create_box)
	var middle := CenterContainer.new()
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	create_box.add_child(middle)
	create = CreatePlayer.new()
	create.visible = false
	middle.add_child(create)
	create.begun.connect(func(identity: Dictionary) -> void: new_game(_start_id, identity))
	create.cancelled.connect(close_create)
	slots.picked.connect(load_slot)
	slots.cancelled.connect(_focus_first)
	%Version.text = version_text()
	Audio.music(Audio.db.state_track("title"))
	Audio.ambience("")
	refresh()


## The build version (project setting application/config/version), for bug reports.
static func version_text() -> String:
	var v := String(ProjectSettings.get_setting("application/config/version", ""))
	return "" if v == "" else "v" + v


## Quit shows only outside a browser (ADR 0031): a web page cannot close itself.
static func shows_quit(web: bool) -> bool:
	return not web


## Continue and Load are off while there is no save.
func refresh() -> void:
	var none := SaveSlots.latest(Session.save_dir, Session.db) == ""
	_continue.disabled = none
	_load.disabled = none
	_focus_first()


## New game: the start chooser, or straight in when there is only one start.
func open_starts() -> void:
	var starts: Array = Session.db.rules.get("world", {}).get("starts", [])
	if starts.size() <= 1:
		open_create("")
		return
	for child: Node in _starts.get_children():
		if child is Button:
			_starts.remove_child(child)
			child.queue_free()
	for s: Dictionary in starts:
		var b := Button.new()
		b.name = "Start_" + String(s["id"])
		b.text = s["name"]
		b.pressed.connect(open_create.bind(String(s["id"])))
		_starts.add_child(b)
	var back := Button.new()
	back.name = "Back"
	back.text = "Back"
	back.pressed.connect(close_starts)
	_starts.add_child(back)
	_show_starts(true)
	(_starts.get_child(1) as Button).grab_focus()


## Options hides the menu buttons, so the keys stay in the panel.
func open_options() -> void:
	$Center.visible = false
	options.open()


func close_options() -> void:
	$Center.visible = true
	_focus_first()


func close_starts() -> void:
	_show_starts(false)
	_focus_first()


## M30.5: the "Who are you?" step for the start `start_id`.
func open_create(start_id: String) -> void:
	_start_id = start_id
	_show_starts(false)
	for c: Control in _menu:
		c.visible = false
	create.setup(Session.db)
	$Center.visible = false
	create_box.visible = true
	create.visible = true
	create.name_edit.grab_focus()


## Back from "Who are you?": to the start chooser when there is one, else the menu.
func close_create() -> void:
	create.visible = false
	create_box.visible = false
	$Center.visible = true
	if Session.db.rules.get("world", {}).get("starts", []).size() > 1:
		open_starts()
	else:
		_show_starts(false)
		_focus_first()


## Starts a new game at the start `start_id` ("" = the first) as `identity` (M30.5).
func new_game(start_id: String = "", identity: Dictionary = {}) -> void:
	Session.start_new_game(new_game_seed if new_game_seed >= 0 else int(Time.get_unix_time_from_system()),
			start_id, identity)
	_enter()


func _show_starts(on: bool) -> void:
	_starts.visible = on
	if create != null:
		create.visible = false
		create_box.visible = false
		$Center.visible = true
	for c: Control in _menu:
		c.visible = not on


func continue_game() -> void:
	var slot := SaveSlots.latest(Session.save_dir, Session.db)
	if slot != "":
		load_slot(slot)


func open_load() -> void:
	slots.open(SlotList.LOAD, Session.save_dir, Session.db)


func load_slot(slot: String) -> void:
	if not Session.load_slot(slot):
		_note.text = "That save cannot be loaded."
		_focus_first()
		return
	_enter()


func _enter() -> void:
	entered_game.emit()
	if switch_scene:
		get_tree().change_scene_to_file.call_deferred(GAME_SCENE)


func _focus_first() -> void:
	if is_inside_tree():
		(_new_game if _continue.disabled else _continue).grab_focus()
