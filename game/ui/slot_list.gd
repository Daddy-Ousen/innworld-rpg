## A list of save slots (M6.1). SAVE mode lists the manual slots (a full
## slot is overwritten); LOAD mode also lists the autosave and greys out
## empty slots. Enter or a double click picks one; Escape cancels.
## Presentation only: the owner does the save or load.
class_name SlotList
extends PanelContainer

signal picked(slot: String)
signal cancelled

const SAVE := "save"
const LOAD := "load"

var mode := LOAD

@onready var _title: Label = %Title
@onready var _items: ItemList = %Items


func _ready() -> void:
	hide()
	_items.item_activated.connect(_on_activated)


## [{"slot", "text", "disabled"}] for a mode. Static, so tests can check it.
static func entries(list_mode: String, dir: String, db: DataDb) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var slots: Array[String] = SaveSlots.MANUAL if list_mode == SAVE else SaveSlots.all()
	for slot: String in slots:
		var i := SaveSlots.info(dir, slot, db)
		out.append({"slot": slot, "text": SaveSlots.label(i), "disabled": list_mode == LOAD and not i["ok"]})
	return out


func open(list_mode: String, dir: String, db: DataDb) -> void:
	mode = list_mode
	_title.text = ("Save to which slot?" if mode == SAVE else "Load which save?") + "   (Esc: back)"
	_items.clear()
	var first := -1
	for e: Dictionary in entries(mode, dir, db):
		var i := _items.add_item(e["text"])
		_items.set_item_metadata(i, e["slot"])
		_items.set_item_disabled(i, e["disabled"])
		if first < 0 and not e["disabled"]:
			first = i
	show()
	if first >= 0:
		_items.select(first)
	_items.grab_focus()


func close() -> void:
	hide()
	_items.release_focus()


func _on_activated(index: int) -> void:
	if _items.is_item_disabled(index):
		return
	close()
	picked.emit(String(_items.get_item_metadata(index)))


func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode == KEY_ESCAPE:
		close()
		cancelled.emit()
		get_viewport().set_input_as_handled()
