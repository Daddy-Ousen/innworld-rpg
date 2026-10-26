## The use menu as an action card (M34.0, ADR 0045). With two or more things
## near, the first page asks who or what (one big button each, with a face);
## then the card of that target shows its actions as big buttons. One target
## opens its card at once. The rows come from Interact.options and the picks are
## the same as before: "Sleep" for a bed (Interact.SLEEP; "Rent a room" for a
## paid one), "Take <item>" (Interact.TAKE), one Shop button for a shop's trades
## (M34.1: `shop_opened`, the game screen shows ShopPanel), a wagon's ride
## (Interact.RIDE), a magic door's trips
## (Interact.PORTAL), the dishes a guest can get (Interact.SERVE, M14.2), an
## NPC's own talk options (Interact.VOICE, M30.1), "Ask about" a task (Interact.QUEST,
## M33.2), spells (Interact.LEARN,
## M17.5), Appraise (M25.3) and Attack last, in red (Interact.ATTACK, M14.5).
## An NPC or a patron shows their face and standing on the card (M14.3, M14.7).
## open_bag lists the goods to eat, drink or read (Interact.USE_GOOD).
## A button fires on release, and only when the finger moved less than DRAG: a
## drag scrolls the card. Attack needs a HOLD on touch and a Yes / No with keys
## or a mouse. Arrows move between buttons, Enter picks, Escape goes back a page.
## Presentation only.
class_name InteractMenu
extends PanelContainer

signal chosen(object_id: String, action_id: String)
## M34.1: the Shop button of a shop object: the game screen opens ShopPanel on it.
signal shop_opened(option: Dictionary)

## The pick of the Shop button (a menu pick only, not a command).
const SHOP := "menu:shop"
const TARGETS := "targets"
const ACTIONS := "actions"
const CONFIRM := "confirm"
## Button height (UI pixels). M34.4: on a phone row_h() makes it at least 48 dp.
const ROW_H := 32.0
const GAP := 8
## A finger that moves more than this (UI pixels) scrolls the card instead of picking.
const DRAG := 12.0
## Seconds a finger holds Attack on touch.
const HOLD := 0.6
## The card's widest size, the room kept at its sides and under it, and its
## greatest part of the screen height.
const MAX_W := 560.0
const SIDE := 56.0
const BOTTOM := 8.0
const MAX_H := 0.85
## A row longer than this puts the card in one column.
const LONG := 22
const ATTACK_GROUP := "attack"
## The order of the button groups on a card (M34.2: Shop before a stall's Haggle).
const GROUPS := ["talk", "serve", "trade", "work", "travel", "learn", "other", ATTACK_GROUP]
const ATTACK_COLOR := Color(0.9, 0.35, 0.3)

## The page now: TARGETS, ACTIONS or CONFIRM.
var page := ""
## -1 = ask Session (touch controls shown), 0 = keys and mouse, 1 = touch. Tests set it.
var touch_override := -1

var _options: Array[Dictionary] = []
var _db: DataDb
## The option on the card ({} on the target page).
var _target := {}
var _bag := false
var _rows: Array[Dictionary] = []
var _buttons: Array[CardButton] = []

@onready var _face: TextureRect = %Face
@onready var _title: Label = %Title
@onready var _sub: Label = %Sub
@onready var _close: Button = %Close
@onready var _scroll: ScrollContainer = %Scroll
@onready var _list: VBoxContainer = %Rows


## A big card button: fires on release, and not after a drag (the drag scrolls
## the card instead).
class CardButton extends Button:
	signal fired

	var dragged := false
	var _down := false
	var _from := Vector2.ZERO

	func _init() -> void:
		action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
		clip_text = true
		text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		custom_minimum_size = Vector2(0, InteractMenu.row_h())
		pressed.connect(_on_pressed)

	# Runs before the button's own input (which sends `pressed` on release).
	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				press_at(event.position)
			else:
				_down = false
				_end_drag.call_deferred()
		elif event is InputEventMouseMotion and _down:
			move_to(event.position, event.relative)

	## A finger or the mouse went down at `at` (the button's pixels).
	func press_at(at: Vector2) -> void:
		_down = true
		dragged = false
		_from = at

	## It moved to `at`; past DRAG it scrolls the card by `step`.
	func move_to(at: Vector2, step: Vector2) -> void:
		if not dragged and at.distance_to(_from) > DRAG:
			dragged = true
		if not dragged:
			return
		var n := get_parent()
		while n != null and not n is ScrollContainer:
			n = n.get_parent()
		if n != null:
			(n as ScrollContainer).scroll_vertical -= int(step.y)

	func _end_drag() -> void:
		dragged = false

	func _on_pressed() -> void:
		if dragged:
			dragged = false
			return
		fired.emit()


## Attack on touch: it fires after the finger held it for HOLD seconds; a ring
## fills while it is held. A tap alone does nothing.
class HoldButton extends CardButton:
	var held := 0.0
	var _holding := false

	func _init() -> void:
		super()
		button_down.connect(func() -> void:
			_holding = true
			held = 0.0)
		button_up.connect(func() -> void:
			_holding = false
			held = 0.0
			queue_redraw())

	func _process(delta: float) -> void:
		if not _holding:
			return
		if dragged:
			_holding = false
			held = 0.0
		else:
			held += delta
			if held >= HOLD:
				_holding = false
				held = 0.0
				fired.emit()
		queue_redraw()

	func _on_pressed() -> void:
		dragged = false

	func _draw() -> void:
		if not _holding or held <= 0.0:
			return
		var r := minf(size.y * 0.35, 14.0)
		draw_arc(Vector2(size.x - r - 8.0, size.y / 2.0), r, -PI / 2.0, -PI / 2.0 + TAU * held / HOLD, 32,
				ATTACK_COLOR, 3.0, true)


func _ready() -> void:
	hide()
	_close.pressed.connect(back)
	get_viewport().size_changed.connect(_fit)
	Session.ui_scale_changed.connect(_fit)


func _exit_tree() -> void:
	# The viewport and Session outlive the card.
	if get_viewport().size_changed.is_connected(_fit):
		get_viewport().size_changed.disconnect(_fit)
	if Session.ui_scale_changed.is_connected(_fit):
		Session.ui_scale_changed.disconnect(_fit)


## options: Interact.options(). Shows nothing and returns false if no option has a row.
func open(options: Array[Dictionary], db: DataDb) -> bool:
	_db = db
	_bag = false
	_options.assign(options.filter(func(o: Dictionary) -> bool:
		return not action_rows(o, db, Session.gs).is_empty()))
	if _options.is_empty():
		return false
	if _options.size() == 1:
		_show_card(_options[0])
	else:
		_show_targets()
	_open()
	return true


## Opens on the card of the option with id `object_id` (Back from the shop
## screen, M34.1; the context button and its chips, M34.2); with no such option
## it opens as `open` does.
func open_on(options: Array[Dictionary], db: DataDb, object_id: String) -> bool:
	if not open(options, db):
		return false
	for o: Dictionary in _options:
		if o["id"] == object_id and page != ACTIONS:
			_show_card(o)
			_after_page()
	return true


## The bag: one button per good you can eat, drink or read. Returns false if none.
func open_bag(gs: GameState, db: DataDb) -> bool:
	_db = db
	_bag = true
	_options.clear()
	Portrait.show_in(_face, "")
	var rows: Array[Dictionary] = []
	for g in gs.economy.goods():
		var use := db.economy.use_of(g)
		if use not in ["food", "heal", "teaches"]:
			continue
		rows.append({"text": "%s %s (%d left)" % [{"food": "Eat", "heal": "Drink", "teaches": "Read"}[use],
				db.economy.goods[g]["name"], gs.economy.count(g)], "object": "bag",
				"action": Interact.USE_GOOD + g, "group": "other"})
	if rows.is_empty():
		return false
	page = ACTIONS
	_target = {"id": "bag", "name": "Bag"}
	_head("Bag", "Eat, drink or read", "")
	_fill(rows, _on_action)
	_close.text = "Close"
	_open()
	return true


## The buttons of the page now, in order: {"text", "object", "action", "group"}.
func rows() -> Array[Dictionary]:
	return _rows


func buttons() -> Array[CardButton]:
	return _buttons


## The card's title and the line under it.
func title_text() -> String:
	return ("%s %s" % [_title.text, _sub.text]).strip_edges()


## Picks button `i` of the page, as a tap or a click does.
func pick(i: int) -> void:
	_buttons[i].pressed.emit()


## The answer on the Attack page.
func confirm(yes: bool) -> void:
	if page == CONFIRM:
		pick(0 if yes else 1)


## Back one page: the confirm page to the card, a card to the target list, else close.
func back() -> void:
	if page == CONFIRM:
		_show_card(_target)
	elif page == ACTIONS and _options.size() > 1:
		_show_targets()
	else:
		close()
		return
	_after_page()


func close() -> void:
	hide()
	for b in _buttons:
		b.release_focus()


## The rows of one Interact option, in group order (GROUPS), with the text a
## button shows (no name prefix: the card's title names the target).
static func action_rows(o: Dictionary, db: DataDb, gs: GameState) -> Array[Dictionary]:
	var by := {}
	for g: String in GROUPS:
		by[g] = [] as Array[Dictionary]
	var id := String(o["id"])
	var add := func(group: String, text: String, action: String) -> void:
		(by[group] as Array[Dictionary]).append({"text": text, "object": id, "action": action, "group": group})
	var trades: Array = o.get("trades", [])
	if not trades.is_empty():  # M34.1: the trades are on the shop screen (ShopPanel)
		var sells := trades.filter(func(t: Dictionary) -> bool: return t["kind"] == Economy.SELL).size()
		add.call("trade", "Shop" if sells == 0 else "Shop (%d to sell)" % sells, SHOP)
	if not (o.get("ride", {}) as Dictionary).is_empty():
		var r: Dictionary = o["ride"]
		@warning_ignore("integer_division")
		add.call("travel", "Ride to %s (%s, %d h)" % [db.maps.areas[r["to"]]["name"],
				Economy.format(db, int(r["price"])), int(r["minutes"]) / 60], Interact.RIDE)
	if not (o.get("portal", {}) as Dictionary).is_empty() and gs != null:
		for l: Dictionary in Portal.open_links(gs, o["portal"]):
			add.call("travel", "To %s (%d left today)" % [Portal.link_name(db, l), Portal.trips_left(gs, db)],
					Interact.portal_action(l))
	for c: Dictionary in o.get("serve", []):
		add.call("serve", "Serve %s (%s%s)" % [String(c["name"]).to_lower(), "ordered, " if c["ordered"] else "",
				Economy.format(db, int(c["pay"]))], Interact.SERVE + String(c["good"]))
	if o.get("guest", false) and not (o["serve"] as Array).any(func(c: Dictionary) -> bool: return c["ordered"]):
		var want := String(db.economy.goods[o["order"]]["name"]).to_lower()
		add.call("serve", "Wants %s (you have none)" % want, Interact.SERVE + String(o["order"]))
	for v: Dictionary in o.get("voice", []):  # M30.1: the NPC's own talk options first
		add.call("talk", "%s (%d min)" % [v["label"], int(db.actions[v["action"]]["minutes"])],
				Interact.VOICE + String(v["id"]))
	for q: Dictionary in o.get("quests", []):  # M33.2: ask about a task
		add.call("talk", "%s (%d min)" % [q["label"], int(db.actions[Interact.action_of(db, id, Interact.QUEST)]["minutes"])],
				Interact.QUEST + String(q["id"]))
	var person: bool = o.get("npc", false) or o.get("fairy", false)
	for action_id: String in o["actions"]:
		if not trades.is_empty() and action_id in [Economy.BUY_ACTION, Economy.SELL_ACTION]:
			continue
		var hint := "" if gs == null else Cooking.hint(gs, db, action_id,
				String(Interact.object_of(db, gs.player.area, id).get("kind", "")))
		add.call("talk" if person else "work", "%s (%d min%s)" % [db.actions[action_id]["name"],
				int(db.actions[action_id]["minutes"]), "" if hint == "" else "; " + hint], action_id)
	if o.get("sleep", false):
		add.call("other", "Sleep (end the day)" if int(o.get("price", 0)) == 0
				else "Rent a room and sleep (%s)" % Economy.format(db, int(o["price"])), Interact.SLEEP)
	if String(o.get("item", "")) != "":
		add.call("other", "Take %s" % db.combat.items.get(o["item"], {}).get("name", o["item"]), Interact.TAKE)
	for sid: String in o.get("teach", []):  # M17.5: a teacher's spells
		add.call("learn", "Learn %s (%s)" % [Spells.name_of(db, sid),
				_hours(int(Spells.spell(db, sid).get("learn", {}).get("minutes", 60)))], Interact.LEARN + sid)
	if o.get("appraise", false):  # M25.3: [Appraisal] reads an NPC's sheet
		add.call("other", "Appraise", Interact.APPRAISE)
	if o.get("attack", false):  # the last row of an NPC, in red (M14.5)
		add.call(ATTACK_GROUP, "Attack", Interact.ATTACK)
	var out: Array[Dictionary] = []
	for g: String in GROUPS:
		out.append_array(by[g])
	return out


## M34.2: the targets near for the context button, nearest first (the order of
## Interact.options), only those with a button: [{"id", "verb", "name", "look"}].
static func targets(options: Array[Dictionary], db: DataDb, gs: GameState) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for o: Dictionary in options:
		if action_rows(o, db, gs).is_empty():
			continue
		out.append({"id": String(o["id"]), "verb": verb_of(o), "name": String(o["name"]),
				"look": look_of(o, db, gs)})
	return out


## The one word the context button shows for a target: "Serve" (a patron, or a
## dish ordered), "Talk", "Shop", "Sleep", "Door", "Ride", "Use", "Take".
static func verb_of(o: Dictionary) -> String:
	if o.get("guest", false) or (o.get("serve", []) as Array).any(func(c: Dictionary) -> bool: return c["ordered"]):
		return "Serve"
	if o.get("npc", false) or o.get("fairy", false):
		return "Talk"
	if not (o.get("trades", []) as Array).is_empty():
		return "Shop"
	if o.get("sleep", false):
		return "Sleep"
	if not (o.get("portal", {}) as Dictionary).is_empty():
		return "Door"
	if not (o.get("ride", {}) as Dictionary).is_empty():
		return "Ride"
	if (o.get("actions", []) as Array).is_empty() and String(o.get("item", "")) != "":
		return "Take"
	return "Use"


## M34.4: the height of a card button now: ROW_H, and at least UiScale.TOUCH_DP on a
## phone (the UI factor alone gave about 30 dp at 250 %).
static func row_h() -> float:
	var tree := Engine.get_main_loop() as SceneTree
	var f := tree.root.content_scale_factor if tree != null else 1.0
	return maxf(ROW_H, UiScale.touch_ui_px(f))


## A target's button text: "Erin (friend)", "Stove".
static func target_label(o: Dictionary) -> String:
	var label := String(o["name"])
	if String(o.get("standing", "")) != "":
		label += " (%s)" % o["standing"]
	return label


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


func _touch() -> bool:
	return touch_override == 1 if touch_override >= 0 else Session.touch_shown()


func _open() -> void:
	show()
	_after_page()


func _after_page() -> void:
	_close.custom_minimum_size.y = row_h()
	_fit()
	_fit.call_deferred()  # again once the new buttons have their theme sizes
	if is_visible_in_tree() and not _buttons.is_empty():
		_buttons[0].grab_focus()


func _show_targets() -> void:
	page = TARGETS
	_target = {}
	_head("Who or what?", "%d near you" % _options.size(), "")
	var rows: Array[Dictionary] = []
	for o: Dictionary in _options:
		rows.append({"text": target_label(o), "object": String(o["id"]), "action": "", "group": "target",
				"look": look_of(o, _db, Session.gs)})
	_fill(rows, func(i: int) -> void:
		_show_card(_options[i])
		_after_page())
	_close.text = "Close"


func _show_card(o: Dictionary) -> void:
	page = ACTIONS
	_target = o
	_head(String(o["name"]), String(o.get("standing", "")), look_of(o, _db, Session.gs))
	_fill(action_rows(o, _db, Session.gs), _on_action)
	_close.text = "Back" if _options.size() > 1 else "Close"


func _on_action(i: int) -> void:
	var r := _rows[i]
	if r["action"] == SHOP:
		close()
		shop_opened.emit(_target)
		return
	if r["action"] == Interact.ATTACK and not _touch():
		_show_confirm(r)
		_after_page()
		return
	_choose(r)


func _show_confirm(attack: Dictionary) -> void:
	page = CONFIRM
	_head("Attack %s?" % _target["name"], "", look_of(_target, _db, Session.gs))
	var rows: Array[Dictionary] = [
		{"text": "Yes, attack", "object": attack["object"], "action": Interact.ATTACK, "group": "confirm"},
		{"text": "No", "object": attack["object"], "action": "", "group": "confirm"}]
	_fill(rows, func(i: int) -> void:
		if i == 0:
			_choose(attack)
		else:
			_show_card(_target)
			_after_page())
	_close.text = "Back"


func _choose(r: Dictionary) -> void:
	close()
	chosen.emit(String(r["object"]), String(r["action"]))


func _head(title: String, sub: String, look: String) -> void:
	_title.text = title
	_sub.text = sub
	_sub.visible = sub != ""
	Portrait.show_in(_face, look)


## Puts `rows` on the card as buttons; a pick calls `on_pick` with the row index.
func _fill(rows: Array[Dictionary], on_pick: Callable) -> void:
	for c: Node in _list.get_children():
		c.visible = false  # a button may still be inside its own signal: free it later
		c.queue_free()
	_rows = rows
	_buttons.clear()
	var grid := GridContainer.new()
	grid.columns = 1 if rows.any(func(r: Dictionary) -> bool: return String(r["text"]).length() > LONG) else 2
	grid.add_theme_constant_override("h_separation", GAP)
	grid.add_theme_constant_override("v_separation", GAP)
	_list.add_child(grid)
	var touch := _touch()
	for i in rows.size():
		var r := rows[i]
		var attack: bool = r["group"] == ATTACK_GROUP
		var b: CardButton = HoldButton.new() if attack and touch else CardButton.new()
		b.text = "Hold to attack" if attack and touch else String(r["text"])
		if attack or r["group"] == "confirm" and i == 0:
			for k: String in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
				b.add_theme_color_override(k, ATTACK_COLOR)
		if attack:
			_list.add_child(HSeparator.new())
			_list.add_child(b)
		else:
			grid.add_child(b)
		var face := Portrait.texture(String(r.get("look", "")))
		if face != null:
			b.icon = face
			b.add_theme_constant_override("icon_max_width", int(row_h()) - 8)
		b.fired.connect(on_pick.bind(i))
		_buttons.append(b)


## Sits the card at the bottom middle, as wide as fits (MAX_W at most), and as
## high as its buttons need (MAX_H of the screen at most; then it scrolls).
func _fit() -> void:
	if not is_inside_tree():
		return
	var view := get_viewport_rect().size
	var w := maxf(minf(MAX_W, view.x - SIDE * 2.0), 160.0)
	var head := (%Header as Control).get_combined_minimum_size().y
	_scroll.custom_minimum_size.y = maxf(minf(_list.get_combined_minimum_size().y,
			view.y * MAX_H - head - 3.0 * GAP - BOTTOM), row_h())
	var h := get_combined_minimum_size().y
	offset_left = -w / 2.0
	offset_right = w / 2.0
	offset_bottom = -BOTTOM
	offset_top = -BOTTOM - h


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"back"):
		back()
		get_viewport().set_input_as_handled()
