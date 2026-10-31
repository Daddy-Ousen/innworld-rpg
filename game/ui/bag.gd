## The bag screen (I, M14.0, ADR 0021): coins, the held item and every good
## you carry, as cards like the shop (M34.0 / M34.1, ADR 0045 "Bag screen").
## A card uses its good (eat, drink, read, hold a tool); "Leave 1" next to it
## leaves one behind; "Put the held item in the bag" stows it. With keys: Enter
## uses the focused card, X leaves one behind, P stows, I or Esc closes.
## A pick is sent as `chosen` with an Interact menu pick (USE_GOOD,
## HOLD_GOOD, DROP_GOOD + good, or STOW); the game screen runs the command
## and opens the bag again. `header` and `rows` are static and headless, so
## tests can check them. Presentation only.
class_name Bag
extends PanelContainer

signal chosen(action_id: String)

const PICKED_COLOR := Color(1.0, 0.85, 0.4)

@onready var _header: Label = %Header
@onready var _scroll: ScrollContainer = %Scroll
@onready var _items: GridContainer = %Items
@onready var _buttons: Control = %Buttons

var _rows: Array[Dictionary] = []
var _cards: Array[InteractMenu.CardButton] = []
var _picked := ""


func _ready() -> void:
	hide()
	%Close.pressed.connect(close)
	%LeaveOne.pressed.connect(leave_one)  # M20.1: X and P as buttons (touch, mouse)
	%Stow.pressed.connect(stow)
	get_viewport().size_changed.connect(_fit)
	Session.ui_scale_changed.connect(_fit)


func _exit_tree() -> void:
	# The viewport and Session outlive the panel.
	if get_viewport().size_changed.is_connected(_fit):
		get_viewport().size_changed.disconnect(_fit)
	if Session.ui_scale_changed.is_connected(_fit):
		Session.ui_scale_changed.disconnect(_fit)


func open(gs: GameState, db: DataDb) -> void:
	_header.text = "\n".join(header(gs, db))
	_rows = rows(gs, db)
	if not _rows.any(func(r: Dictionary) -> bool: return r["good"] == _picked):
		_picked = ""  # the picked good is gone: the first one is picked
	_fill()
	%Stow.visible = gs.player.held != ""
	_buttons.visible = %Stow.visible or not _rows.is_empty()
	%LeaveOne.visible = not _rows.is_empty()
	show()
	_size_buttons()
	_fit()
	# The new cards and the wrapped header have their size one frame later.
	if not get_tree().process_frame.is_connected(_fit):
		get_tree().process_frame.connect(_fit, CONNECT_ONE_SHOT)
	if not _cards.is_empty():
		_cards[maxi(_rows.map(func(r: Dictionary) -> String: return r["good"]).find(_picked), 0)].grab_focus()


func close() -> void:
	hide()
	var f := get_viewport().gui_get_focus_owner()
	if f != null and is_ancestor_of(f):
		f.release_focus()


## The good picked on the cards (the first when none was picked), or "".
func selected_good() -> String:
	if _picked != "":
		return _picked
	return "" if _rows.is_empty() else String(_rows[0]["good"])


## Leaves one of the picked good behind (X).
func leave_one() -> void:
	if selected_good() != "":
		chosen.emit(Interact.DROP_GOOD + selected_good())


## Puts the held item in the bag (P).
func stow() -> void:
	chosen.emit(Interact.STOW)


## Taps the card of row `i`: the good is picked, and its use runs.
func pick(i: int) -> void:
	_picked = _rows[i]["good"]
	var use: String = _rows[i]["use"]
	if use != "":
		chosen.emit(use)
	else:
		_paint()


## Taps "Leave 1" of row `i`.
func leave(i: int) -> void:
	_picked = _rows[i]["good"]
	leave_one()


## The cards, for tests and the render script: one use card per good.
func cards() -> Array[InteractMenu.CardButton]:
	return _cards


func _fill() -> void:
	for c: Node in _items.get_children():
		c.visible = false  # a card may still be inside its own signal: free it later
		c.queue_free()
	_cards.clear()
	if _rows.is_empty():
		return
	for i in _rows.size():
		var b := InteractMenu.CardButton.new()
		b.text = String(_rows[i]["text"])
		b.fired.connect(pick.bind(i))
		b.focus_entered.connect(_on_focus.bind(i))
		_items.add_child(b)
		_cards.append(b)
		var one := InteractMenu.CardButton.new()
		one.text = "Leave 1"
		one.size_flags_horizontal = Control.SIZE_FILL
		one.clip_text = false  # "Leave 1" is never cut short
		one.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		one.custom_minimum_size.x = InteractMenu.row_h() * 1.6
		one.fired.connect(leave.bind(i))
		_items.add_child(one)
	_paint()


func _on_focus(i: int) -> void:
	_picked = _rows[i]["good"]
	_paint()


## Colours the picked good's card.
func _paint() -> void:
	var want := selected_good()
	for i in _cards.size():
		for k: String in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
			if _rows[i]["good"] == want:
				_cards[i].add_theme_color_override(k, PICKED_COLOR)
			else:
				_cards[i].remove_theme_color_override(k)


## The fixed buttons at the height of a card (at least 48 dp on a phone).
func _size_buttons() -> void:
	var h := InteractMenu.row_h()
	for b: Control in [%Close, %LeaveOne, %Stow]:
		b.custom_minimum_size.y = h


## Sits the panel at the bottom middle like the action card (InteractMenu._fit).
func _fit() -> void:
	if not is_inside_tree():
		return
	var view := get_viewport_rect().size
	var w := maxf(minf(InteractMenu.MAX_W, view.x - InteractMenu.SIDE * 2.0), 160.0)
	offset_left = -w / 2.0  # the width first: the header label wraps by it
	offset_right = w / 2.0
	var rest := 0.0
	for c: Control in [%Top, _header, _buttons]:
		if c.visible:
			rest += c.get_combined_minimum_size().y + InteractMenu.GAP
	_scroll.custom_minimum_size.y = maxf(minf(_items.get_combined_minimum_size().y,
			view.y * InteractMenu.MAX_H - rest - 2.0 * InteractMenu.GAP - InteractMenu.BOTTOM), InteractMenu.row_h())
	var h := get_combined_minimum_size().y
	offset_bottom = -InteractMenu.BOTTOM
	offset_top = -InteractMenu.BOTTOM - h


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"back") or event.is_action_pressed(&"bag"):
		close()
	elif event.is_action_pressed(&"drop"):
		leave_one()
	elif event.is_action_pressed(&"stow"):
		stow()
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
## is the menu pick for a tap, or "" (a trade good: sell it at a shop).
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
				"" if verb == "" else "   (%s)" % verb]})
	return out
