## A read-only page of text with a title (M15.2): the message history (L) and the help page (H).
## `toggle_action` (an input action, M20.0) closes it, as Esc does. Presentation only.
class_name TextPage
extends PanelContainer

@export var title := "Page"
@export var toggle_action: StringName = &"help"

## The panel's size (the .tscn offsets) when the view has room (M20.3).
const DESIGN_SIZE := Vector2(560, 400)
@onready var _title: Label = %Title
@onready var _text: Label = %Text
@onready var _scroll: ScrollContainer = %Scroll


func _ready() -> void:
	hide()
	UiScale.keep_fit(self, DESIGN_SIZE)  # M20.3: cut to a small view


func open(lines: Array) -> void:
	_title.text = "[%s]   (%s or Esc to close)" % [title, InputNames.key_of(toggle_action)]
	_text.text = "\n".join(lines)
	_scroll.scroll_vertical = 0
	show()


func close() -> void:
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var down := event.is_action_pressed(&"page_down", true)
	if down or event.is_action_pressed(&"page_up", true):
		var page := int(_scroll.size.y * 0.8)
		_scroll.scroll_vertical += page if down else -page
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"back") or event.is_action_pressed(toggle_action):
		close()
		get_viewport().set_input_as_handled()
