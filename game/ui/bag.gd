## The bag screen (I, M14.0, ADR 0021): coins, the held item and every good
## you carry. Enter uses the picked good (eat, drink, or hold a tool), X
## leaves one behind, P puts the held item in the bag. I or Esc closes.
## A pick is sent as `chosen` with an Interact menu pick (USE_GOOD,
## HOLD_GOOD, DROP_GOOD + good, or STOW); the game screen runs the command
## and opens the bag again. `header` and `rows` are static and headless, so
## tests can check them. Presentation only.
class_name Bag
extends PanelContainer

signal chosen(action_id: String)

@onready var _header: Label = %Header
@onready var _items: ItemList = %Items


func _ready() -> void:
	hide()
	_items.item_activated.connect(_on_activated)


func open(gs: GameState, db: DataDb) -> void:
	_header.text = "\n".join(header(gs, db))
	var keep := _items.get_selected_items()
	_items.clear()
	for r: Dictionary in rows(gs, db):
		var i := _items.add_item(r["text"])
		_items.set_item_metadata(i, r)
	show()
	if _items.item_count > 0:
		_items.select(mini(keep[0] if not keep.is_empty() else 0, _items.item_count - 1))
	_items.grab_focus()


func close() -> void:
	hide()
	_items.release_focus()


## The good picked in the list, or "".
func selected_good() -> String:
	var sel := _items.get_selected_items()
	return "" if sel.is_empty() else String(_items.get_item_metadata(sel[0])["good"])


func _on_activated(index: int) -> void:
	var use: String = _items.get_item_metadata(index)["use"]
	if use != "":
		chosen.emit(use)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"back") or event.is_action_pressed(&"bag"):
		close()
	elif event.is_action_pressed(&"drop"):
		if selected_good() != "":
			chosen.emit(Interact.DROP_GOOD + selected_good())
	elif event.is_action_pressed(&"stow"):
		chosen.emit(Interact.STOW)
	else:
		return
	get_viewport().set_input_as_handled()


static func header(gs: GameState, db: DataDb) -> Array[String]:
	var out: Array[String] = []
	if Economy.on(db):
		out.append(Hud.purse(gs, db))
	var held := gs.player.held
	if held == "":
		out.append("In hand: nothing.")
	else:
		var name: String = db.combat.items[held]["name"]
		out.append("In hand: %s%s." % [name, "" if Economy.good_for_item(db, held) != ""
				else " (too big for the bag)"])
	if Economy.on(db) and not Economy.is_fed(gs):
		out.append("You have not eaten today.")
	if gs.economy.goods().is_empty():
		out.append("The bag is empty.")
	return out


## One row per good in the bag, in id order: {"good", "text", "use"}. "use"
## is the menu pick for Enter, or "" (a trade good: sell it at a shop).
static func rows(gs: GameState, db: DataDb) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for g: String in gs.economy.goods():
		var good: Dictionary = db.economy.goods.get(g, {})
		var verb := ""
		var use := ""
		match db.economy.use_of(g):
			"food":
				verb = "Eat"
				use = Interact.USE_GOOD + g
			"heal":
				verb = "Drink"
				use = Interact.USE_GOOD + g
			"teaches":  # M17.5: a spellbook
				verb = "Read"
				use = Interact.USE_GOOD + g
			_:
				if good.has("item"):
					verb = "Hold"
					use = Interact.HOLD_GOOD + g
		out.append({"good": g, "use": use, "text": "%s x%d%s" % [good.get("name", g), gs.economy.count(g),
				"" if verb == "" else "   (Enter: %s)" % verb]})
	return out
