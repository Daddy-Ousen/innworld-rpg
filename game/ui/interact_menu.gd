## The "use" menu: one entry per nearby object action. Enter or a double
## click picks one; Escape closes. Presentation only.
class_name InteractMenu
extends PanelContainer

signal chosen(object_id: String, action_id: String)

@onready var _items: ItemList = %Items


func _ready() -> void:
	hide()
	_items.item_activated.connect(_on_activated)


## options: Interact.options(). Shows nothing and returns false if empty.
func open(options: Array[Dictionary], db: DataDb) -> bool:
	_items.clear()
	for o: Dictionary in options:
		for action_id: String in o["actions"]:
			var i := _items.add_item("%s — %s (%d min)" % [o["name"], db.actions[action_id]["name"],
					int(db.actions[action_id]["minutes"])])
			_items.set_item_metadata(i, [o["id"], action_id])
	if _items.item_count == 0:
		return false
	show()
	_items.select(0)
	_items.grab_focus()
	return true


func _on_activated(index: int) -> void:
	var pick: Array = _items.get_item_metadata(index)
	hide()
	chosen.emit(pick[0], pick[1])


func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()


func close() -> void:
	hide()
	_items.release_focus()
