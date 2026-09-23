## The journal (J, M6.1): the day, the player's focus and how to play.
## Picking a focus ("Become an [Innkeeper]") calls Commands.set_focus with
## that class's main tags: matching actions give more XP (conviction,
## DESIGN §3.2). Presentation only; `lines` and `focus_choices` are static
## and headless, so tests can check them.
class_name Journal
extends PanelContainer

signal focus_changed

## A class tag is a main tag for a focus at this weight or more.
const FOCUS_MIN_WEIGHT := 0.5

var _gs: GameState
var _db: DataDb

@onready var _text: Label = %Text
@onready var _focus: ItemList = %Focus


func _ready() -> void:
	hide()
	_focus.item_activated.connect(choose)


func open(gs: GameState, db: DataDb) -> void:
	_gs = gs
	_db = db
	_text.text = "\n".join(lines(gs, db))
	_focus.clear()
	var current := 0
	for c: Dictionary in focus_choices(gs, db):
		var i := _focus.add_item(c["name"])
		_focus.set_item_metadata(i, c["tags"])
		if _same(c["tags"], gs.focus_tags):
			current = i
	show()
	_focus.select(current)
	_focus.grab_focus()


func close() -> void:
	hide()
	_focus.release_focus()


## Sets the focus of the list entry at `index`. Returns "" or an error text.
func choose(index: int) -> String:
	var err := Commands.set_focus(_gs, _db, _focus.get_item_metadata(index))
	_text.text = "\n".join(lines(_gs, _db))
	focus_changed.emit()
	return err


func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode in [KEY_ESCAPE, KEY_J]:
		close()
		get_viewport().set_input_as_handled()


## "No focus", then one entry per class the player can aim for: not a
## consolidation, no class prereqs, not declined. Data order.
static func focus_choices(gs: GameState, db: DataDb) -> Array[Dictionary]:
	var out: Array[Dictionary] = [{"name": "No focus", "tags": [] as Array[String]}]
	for id: String in db.classes:
		var c: Dictionary = db.classes[id]
		if c["consolidation"] != null or not (c["prereqs"].get("classes", []) as Array).is_empty() \
				or gs.progression.declined.has(id):
			continue
		out.append({"name": "Become %s" % c["name"], "tags": main_tags(c)})
	return out


## The class's tags at FOCUS_MIN_WEIGHT or more, strongest first.
static func main_tags(class_data: Dictionary) -> Array[String]:
	var weights: Dictionary = class_data["tag_weights"]
	var out: Array[String] = []
	for tag: String in weights:
		if float(weights[tag]) >= FOCUS_MIN_WEIGHT:
			out.append(tag)
	out.sort_custom(func(a: String, b: String) -> bool: return float(weights[a]) > float(weights[b]))
	return out


## The focus as the player picked it ("Become [Innkeeper]"), else its tags.
static func focus_name(gs: GameState, db: DataDb) -> String:
	if gs.focus_tags.is_empty():
		return "none"
	for c: Dictionary in focus_choices(gs, db):
		if _same(c["tags"], gs.focus_tags):
			return c["name"]
	return ", ".join(gs.focus_tags)


static func lines(gs: GameState, db: DataDb) -> Array[String]:
	var out: Array[String] = [
		"Day %d, %s." % [gs.clock.day(), gs.clock.time_string()],
		"Focus: %s" % focus_name(gs, db),
		"",
		"How to play:",
	]
	for h: String in SystemMessages.HINTS:
		out.append("  " + h)
	out.append("")
	out.append("Choose a focus (Enter). Actions that match it give more XP.")
	return out


static func _same(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for x: Variant in a:
		if not b.has(x):
			return false
	return true
