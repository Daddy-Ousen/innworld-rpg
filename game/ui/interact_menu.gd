## The "use" menu: one entry per nearby object action, plus "Sleep" for a
## bed (Interact.SLEEP; "Rent a room" for a paid one) and "Take <item>" for
## an object with an item (Interact.TAKE). A shop lists its trades instead
## of the bare buy and sell actions (Interact.BUY / SELL + good), a wagon
## its ride (Interact.RIDE), a magic door its trip (Interact.PORTAL). open_bag lists the goods in the bag
## (Interact.USE_GOOD + good). Enter or a double click picks one; Escape
## closes. Presentation only.
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
		var trades: Array = o.get("trades", [])
		for t: Dictionary in trades:
			var i := _items.add_item("%s — %s %s (%s)" % [o["name"],
					"Buy" if t["kind"] == Economy.BUY else "Sell", t["name"], Economy.format(db, int(t["price"]))])
			_items.set_item_metadata(i, [o["id"], (Interact.BUY if t["kind"] == Economy.BUY
					else Interact.SELL) + String(t["good"])])
		if not (o.get("ride", {}) as Dictionary).is_empty():
			var r: Dictionary = o["ride"]
			@warning_ignore("integer_division")
			var i := _items.add_item("%s — Ride to %s (%s, %d h)" % [o["name"], db.maps.areas[r["to"]]["name"],
					Economy.format(db, int(r["price"])), int(r["minutes"]) / 60])
			_items.set_item_metadata(i, [o["id"], Interact.RIDE])
		if not (o.get("portal", {}) as Dictionary).is_empty():
			var i := _items.add_item("%s — To %s (%d left today)" % [o["name"],
					db.maps.areas[o["portal"]["to"]]["name"], Portal.trips_left(Session.gs, db)])
			_items.set_item_metadata(i, [o["id"], Interact.PORTAL])
		for action_id: String in o["actions"]:
			if not trades.is_empty() and action_id in [Economy.BUY_ACTION, Economy.SELL_ACTION]:
				continue
			var i := _items.add_item("%s — %s (%d min)" % [o["name"], db.actions[action_id]["name"],
					int(db.actions[action_id]["minutes"])])
			_items.set_item_metadata(i, [o["id"], action_id])
		if o["sleep"]:
			var i := _items.add_item(("%s — Sleep (end the day)" % o["name"]) if int(o.get("price", 0)) == 0
					else "%s — Rent a room and sleep (%s)" % [o["name"], Economy.format(db, int(o["price"]))])
			_items.set_item_metadata(i, [o["id"], Interact.SLEEP])
		if o["item"] != "":
			var i := _items.add_item("%s — Take %s" % [o["name"],
					db.combat.items.get(o["item"], {}).get("name", o["item"])])
			_items.set_item_metadata(i, [o["id"], Interact.TAKE])
	if _items.item_count == 0:
		return false
	show()
	_items.select(0)
	_items.grab_focus()
	return true


## The bag: one entry per good you can eat or drink. Returns false if none.
func open_bag(gs: GameState, db: DataDb) -> bool:
	_items.clear()
	for g in gs.economy.goods():
		var use := db.economy.use_of(g)
		if use not in ["food", "heal"]:
			continue
		var i := _items.add_item("%s — %s (%d left)" % [db.economy.goods[g]["name"],
				"Eat" if use == "food" else "Drink", gs.economy.count(g)])
		_items.set_item_metadata(i, ["bag", Interact.USE_GOOD + g])
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
