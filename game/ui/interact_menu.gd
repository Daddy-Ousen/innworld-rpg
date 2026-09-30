## The "use" menu: one entry per nearby object action, plus "Sleep" for a
## bed (Interact.SLEEP; "Rent a room" for a paid one) and "Take <item>" for
## an object with an item (Interact.TAKE). A shop lists its trades instead
## of the bare buy and sell actions (Interact.BUY / SELL + good), a wagon
## its ride (Interact.RIDE), a magic door its trip (Interact.PORTAL). open_bag lists the goods in the bag
## (Interact.USE_GOOD + good). A guest lists the dishes you can serve them
## (Interact.SERVE + good, M14.2). An NPC shows their standing band, e.g. "Erin (friend)" (M14.3),
## and an Attack row last, in red (Interact.ATTACK, M14.5). An NPC or a patron shows their face beside
## the list while their row is selected (Portrait, M14.7). Enter or a double click picks one; Escape
## closes. Presentation only.
class_name InteractMenu
extends PanelContainer

signal chosen(object_id: String, action_id: String)

## Row index → the look (sheet id) of the object the row is for, "" for no face.
var _looks: Array[String] = []

@onready var _items: ItemList = %Items
@onready var _face: TextureRect = %Face


func _ready() -> void:
	hide()
	_items.item_activated.connect(_on_activated)
	_items.item_selected.connect(_show_face)


## options: Interact.options(). Shows nothing and returns false if empty.
func open(options: Array[Dictionary], db: DataDb) -> bool:
	_items.clear()
	_looks.clear()
	for o: Dictionary in options:
		var rows_before := _items.item_count
		var label := String(o["name"])
		if String(o.get("standing", "")) != "":
			label += " (%s)" % o["standing"]
		var trades: Array = o.get("trades", [])
		for t: Dictionary in trades:
			var i := _items.add_item("%s — %s %s (%s)" % [label,
					"Buy" if t["kind"] == Economy.BUY else "Sell", t["name"], Economy.format(db, int(t["price"]))])
			_items.set_item_metadata(i, [o["id"], (Interact.BUY if t["kind"] == Economy.BUY
					else Interact.SELL) + String(t["good"])])
		if not (o.get("ride", {}) as Dictionary).is_empty():
			var r: Dictionary = o["ride"]
			@warning_ignore("integer_division")
			var i := _items.add_item("%s — Ride to %s (%s, %d h)" % [label, db.maps.areas[r["to"]]["name"],
					Economy.format(db, int(r["price"])), int(r["minutes"]) / 60])
			_items.set_item_metadata(i, [o["id"], Interact.RIDE])
		if not (o.get("portal", {}) as Dictionary).is_empty():
			var i := _items.add_item("%s — To %s (%d left today)" % [label,
					db.maps.areas[o["portal"]["to"]]["name"], Portal.trips_left(Session.gs, db)])
			_items.set_item_metadata(i, [o["id"], Interact.PORTAL])
		for c: Dictionary in o.get("serve", []):
			var i := _items.add_item("%s — Serve %s (%s%s)" % [label, String(c["name"]).to_lower(),
					"ordered, " if c["ordered"] else "", Economy.format(db, int(c["pay"]))])
			_items.set_item_metadata(i, [o["id"], Interact.SERVE + String(c["good"])])
		if o.get("guest", false) and not (o["serve"] as Array).any(func(c: Dictionary) -> bool: return c["ordered"]):
			var want := String(db.economy.goods[o["order"]]["name"]).to_lower()
			var i := _items.add_item("%s — Wants %s (you have none)" % [label, want])
			_items.set_item_metadata(i, [o["id"], Interact.SERVE + String(o["order"])])
		for action_id: String in o["actions"]:
			if not trades.is_empty() and action_id in [Economy.BUY_ACTION, Economy.SELL_ACTION]:
				continue
			var hint := "" if Session.gs == null else Cooking.hint(Session.gs, db, action_id,
					String(Interact.object_of(db, Session.gs.player.area, o["id"]).get("kind", "")))
			var i := _items.add_item("%s — %s (%d min%s)" % [label, db.actions[action_id]["name"],
					int(db.actions[action_id]["minutes"]), "" if hint == "" else "; " + hint])
			_items.set_item_metadata(i, [o["id"], action_id])
		if o["sleep"]:
			var i := _items.add_item(("%s — Sleep (end the day)" % label) if int(o.get("price", 0)) == 0
					else "%s — Rent a room and sleep (%s)" % [label, Economy.format(db, int(o["price"]))])
			_items.set_item_metadata(i, [o["id"], Interact.SLEEP])
		if o["item"] != "":
			var i := _items.add_item("%s — Take %s" % [label,
					db.combat.items.get(o["item"], {}).get("name", o["item"])])
			_items.set_item_metadata(i, [o["id"], Interact.TAKE])
		for sid: String in o.get("teach", []):  # M17.5: a teacher's spells
			var i := _items.add_item("%s — Learn %s (%s)" % [label, Spells.name_of(db, sid),
					_hours(int(Spells.spell(db, sid).get("learn", {}).get("minutes", 60)))])
			_items.set_item_metadata(i, [o["id"], Interact.LEARN + sid])
		if o.get("attack", false):  # the last row of an NPC, in red (M14.5)
			var i := _items.add_item("%s — Attack" % label)
			_items.set_item_metadata(i, [o["id"], Interact.ATTACK])
			_items.set_item_custom_fg_color(i, Color(0.9, 0.35, 0.3))
		var look := look_of(o, db, Session.gs)
		for _row in range(rows_before, _items.item_count):
			_looks.append(look)
	if _items.item_count == 0:
		return false
	show()
	_items.select(0)
	_show_face(0)
	_items.grab_focus()
	return true


## "2 h" or "90 min".
static func _hours(minutes: int) -> String:
	@warning_ignore("integer_division")
	return "%d h" % (minutes / 60) if minutes % 60 == 0 else "%d min" % minutes


## The look (sheet id) of an Interact option's object: an NPC's own or race look, a patron's look,
## else "" (an object has no face).
static func look_of(o: Dictionary, db: DataDb, gs: GameState) -> String:
	if o.get("npc", false):
		return Portrait.look_of_npc(db, String(o["id"]))
	if o.get("guest", false) and gs != null:
		var pid := String(o["id"]).trim_prefix(Guests.GUEST)
		for g: Dictionary in Guests.present(gs):
			if g["id"] == pid:
				return String(g.get("look", ""))
	return ""


func _show_face(index: int) -> void:
	Portrait.show_in(_face, _looks[index] if index < _looks.size() else "")


## The bag: one entry per good you can eat, drink or read. Returns false if none.
func open_bag(gs: GameState, db: DataDb) -> bool:
	_items.clear()
	_looks.clear()
	_show_face(0)
	for g in gs.economy.goods():
		var use := db.economy.use_of(g)
		if use not in ["food", "heal", "teaches"]:
			continue
		var i := _items.add_item("%s — %s (%d left)" % [db.economy.goods[g]["name"],
				{"food": "Eat", "heal": "Drink", "teaches": "Read"}[use], gs.economy.count(g)])
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
