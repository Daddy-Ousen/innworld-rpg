## The title screen (M6.1, the main scene): New game, Continue (the newest
## save), Load, Quit. Sets Session's game, then opens the game screen.
## Presentation only.
class_name TitleMenu
extends Control

signal entered_game

const GAME_SCENE := "res://world/main.tscn"

## Tests set this false and watch `entered_game` instead of a scene change.
var switch_scene := true
## Seed for a new game; below 0 takes one from the system clock.
var new_game_seed := -1

@onready var slots: SlotList = %Slots
@onready var _new_game: Button = %NewGame
@onready var _continue: Button = %Continue
@onready var _load: Button = %Load
@onready var _note: Label = %Note


func _ready() -> void:
	_new_game.pressed.connect(new_game)
	_continue.pressed.connect(continue_game)
	_load.pressed.connect(open_load)
	%Quit.pressed.connect(func() -> void: get_tree().quit())
	slots.picked.connect(load_slot)
	slots.cancelled.connect(_focus_first)
	refresh()


## Continue and Load are off while there is no save.
func refresh() -> void:
	var none := SaveSlots.latest(Session.save_dir, Session.db) == ""
	_continue.disabled = none
	_load.disabled = none
	_focus_first()


func new_game() -> void:
	Session.start_new_game(new_game_seed if new_game_seed >= 0 else int(Time.get_unix_time_from_system()))
	_enter()


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
