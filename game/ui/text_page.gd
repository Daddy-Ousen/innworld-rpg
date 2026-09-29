## A read-only page of text with a title (M15.2): the message history (L) and the help page (H).
## `toggle_key` opens and closes it with Esc. Presentation only.
class_name TextPage
extends PanelContainer

@export var title := "Page"
@export var toggle_key: Key = KEY_H

@onready var _title: Label = %Title
@onready var _text: Label = %Text
@onready var _scroll: ScrollContainer = %Scroll


func _ready() -> void:
	hide()


func open(lines: Array) -> void:
	_title.text = "[%s]   (%s or Esc to close)" % [title, OS.get_keycode_string(toggle_key)]
	_text.text = "\n".join(lines)
	_scroll.scroll_vertical = 0
	show()


func close() -> void:
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey or not event.pressed:
		return
	var key: Key = (event as InputEventKey).physical_keycode
	if key in [KEY_PAGEUP, KEY_PAGEDOWN]:
		var page := int(_scroll.size.y * 0.8)
		_scroll.scroll_vertical += page if key == KEY_PAGEDOWN else -page
		get_viewport().set_input_as_handled()
	elif not event.echo and key in [KEY_ESCAPE, toggle_key]:
		close()
		get_viewport().set_input_as_handled()
