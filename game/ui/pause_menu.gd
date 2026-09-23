## The pause menu (Esc, M6.1): Resume, Save, Load, Quit to title. Save and
## load go through Session and work at any time, also in a fight (the save
## holds the fight). Presentation only.
class_name PauseMenu
extends Control

## A line for the HUD log ("Saved to slot 1.").
signal message(text: String)
signal quit_requested

@onready var slots: SlotList = %Slots
@onready var _panel: PanelContainer = %Panel
@onready var _resume: Button = %Resume


func _ready() -> void:
	hide()
	_resume.pressed.connect(close)
	%Save.pressed.connect(open_save)
	%Load.pressed.connect(open_load)
	%Quit.pressed.connect(quit_to_title)
	slots.picked.connect(_on_picked)
	slots.cancelled.connect(_show_buttons)


func open() -> void:
	show()
	_show_buttons()


func close() -> void:
	slots.close()
	hide()


func open_save() -> void:
	_panel.hide()
	slots.open(SlotList.SAVE, Session.save_dir, Session.db)


func open_load() -> void:
	_panel.hide()
	slots.open(SlotList.LOAD, Session.save_dir, Session.db)


func save_to(slot: String) -> bool:
	var ok := Session.save_slot(slot) == OK
	message.emit("Saved to slot %s." % slot if ok else "Save failed.")
	close()
	return ok


func load_from(slot: String) -> bool:
	var ok := Session.load_slot(slot)
	message.emit("Loaded. Day %d, %s." % [Session.gs.clock.day(), Session.gs.clock.time_string()]
			if ok else "That save cannot be loaded.")
	close()
	return ok


func quit_to_title() -> void:
	close()
	quit_requested.emit()


func _on_picked(slot: String) -> void:
	if slots.mode == SlotList.SAVE:
		save_to(slot)
	else:
		load_from(slot)


func _show_buttons() -> void:
	_panel.show()
	if is_inside_tree():
		_resume.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if visible and not slots.visible and event is InputEventKey and event.pressed \
			and not event.echo and event.physical_keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()
