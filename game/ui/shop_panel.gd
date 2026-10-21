## The shop screen (M34.1, ADR 0045): the trades of one shop object in two tabs,
## Buy and Sell, one big card per good (name, price, how many you carry). A
## pick on a card shows the count strip: - count +, Max, and one big Buy (or
## Sell) button with the total. Hold - or + to count fast. Each Sell card has a
## "Sell all" button too. A deal is sent as `chosen` with the trade pick the use
## menu always sent (Interact.trade_action(prefix, good, count), M27.2); the
## game screen runs it and opens the shop again with the new prices and counts.
## Back (the button, Escape) sends `went_back`: the game screen shows the card of
## the shop again. Cards fire on release and a drag scrolls (InteractMenu.CardButton).
## Presentation only.
class_name ShopPanel
extends PanelContainer

signal chosen(object_id: String, action_id: String)
signal went_back(object_id: String)

## The most the strip counts to in one deal.
const MAX_COUNT := 99
## Seconds a held - or + waits before it repeats, then the time between repeats.
const REPEAT_WAIT := 0.4
const REPEAT_EVERY := 0.08
const PICKED_COLOR := Color(1.0, 0.85, 0.4)

## The tab now: Economy.BUY or Economy.SELL.
var tab := Economy.BUY
## The good picked on the tab ("" = none: the strip is hidden).
var good := ""
var count := 1

var _object := ""
var _trades: Array[Dictionary] = []
var _gs: GameState
var _db: DataDb
var _rows: Array[Dictionary] = []
var _cards: Array[InteractMenu.CardButton] = []
var _minus: StepButton
var _plus: StepButton
var _max: Button
var _deal: Button
var _count: Label
var _note := ""

@onready var _title: Label = %Title
@onready var _sub: Label = %Sub
@onready var _close: Button = %Close
@onready var _buy_tab: Button = %BuyTab
@onready var _sell_tab: Button = %SellTab
@onready var _scroll: ScrollContainer = %Scroll
@onready var _list: VBoxContainer = %Items
@onready var _strip: HBoxContainer = %Strip


## - or +: one step when pressed, then a step each REPEAT_EVERY while held.
class StepButton extends Button:
	signal step

	var _held := false
	var _t := 0.0

	func _init() -> void:
		action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		custom_minimum_size = Vector2(InteractMenu.ROW_H * 1.5, InteractMenu.ROW_H)
		button_down.connect(func() -> void:
			_held = true
			_t = -REPEAT_WAIT
			step.emit())
		button_up.connect(func() -> void: _held = false)

	func _process(delta: float) -> void:
		if not _held:
			return
		_t += delta
		while _t >= REPEAT_EVERY:
			_t -= REPEAT_EVERY
			step.emit()


func _ready() -> void:
	hide()
	_close.pressed.connect(back)
	var tabs := ButtonGroup.new()
	for b: Button in [_buy_tab, _sell_tab]:
		b.toggle_mode = true
		b.button_group = tabs
		b.custom_minimum_size.y = InteractMenu.ROW_H
	_buy_tab.pressed.connect(show_tab.bind(Economy.BUY))
	_sell_tab.pressed.connect(show_tab.bind(Economy.SELL))
	_minus = StepButton.new()
	_minus.text = "-"
	_minus.step.connect(step_count.bind(-1))
	_count = Label.new()
	_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_count.custom_minimum_size.x = InteractMenu.ROW_H * 1.25
	_plus = StepButton.new()
	_plus.text = "+"
	_plus.step.connect(step_count.bind(1))
	_max = Button.new()
	_max.text = "Max"
	_max.custom_minimum_size = Vector2(InteractMenu.ROW_H * 2.0, InteractMenu.ROW_H)
	_max.pressed.connect(set_max)
	_deal = Button.new()
	_deal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_deal.custom_minimum_size.y = InteractMenu.ROW_H
	_deal.clip_text = true
	_deal.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_deal.pressed.connect(deal)
	for c: Control in [_minus, _count, _plus, _max, _deal]:
		_strip.add_child(c)
	get_viewport().size_changed.connect(_fit)
	Session.ui_scale_changed.connect(_fit)


func _exit_tree() -> void:
	# The viewport and Session outlive the panel.
	if get_viewport().size_changed.is_connected(_fit):
		get_viewport().size_changed.disconnect(_fit)
	if Session.ui_scale_changed.is_connected(_fit):
		Session.ui_scale_changed.disconnect(_fit)


## option: an Interact.options row of a shop object. Opened again on the same
## shop (after a deal), it keeps the tab, the good and the count (the count
## clamped to what you can now buy or sell). Returns false if it has no trades.
func open(option: Dictionary, db: DataDb, gs: GameState) -> bool:
	var trades: Array = option.get("trades", [])
	if trades.is_empty():
		return false
	var again := visible and _object == String(option["id"])
	_object = String(option["id"])
	_db = db
	_gs = gs
	_trades.assign(trades)
	_title.text = String(option["name"])
	if not again:
		note("")
		good = ""
		count = 1
		tab = Economy.BUY if not _of(Economy.BUY).is_empty() else Economy.SELL
	if picked().is_empty():
		good = ""
	show()
	_refresh()
	return true


## The object id of the shop on the screen.
func shop_id() -> String:
	return _object


## The cards of the tab now, in order: {"text", "good", "price", "have", "kind"}.
func rows() -> Array[Dictionary]:
	return _rows


func cards() -> Array[InteractMenu.CardButton]:
	return _cards


## What the last deal did, shown under the header with the coins left; "" for none.
func note(text: String) -> void:
	_note = text
	if _db != null:
		_show_coins()


## The line under the header.
func sub_text() -> String:
	return _sub.text


## The big button's text and whether it can be pressed now.
func deal_text() -> String:
	return _deal.text


func deal_enabled() -> bool:
	return _strip.visible and not _deal.disabled


func show_tab(kind: String) -> void:
	if kind != tab:
		tab = kind
		good = ""
		count = 1
	_refresh()


## Picks card `i` of the tab, as a tap or a click does.
func pick(i: int) -> void:
	_cards[i].pressed.emit()


## The trade of the picked good on the tab now, or {}.
func picked() -> Dictionary:
	for t: Dictionary in _of(tab):
		if t["good"] == good:
			return t
	return {}


func step_count(d: int) -> void:
	count = clampi(count + d, 1, maxi(max_count(picked(), _gs, _db), 1))
	_show_strip()


func set_max() -> void:
	count = maxi(max_count(picked(), _gs, _db), 1)
	_show_strip()


## The big Buy or Sell button: sends the trade pick for `count` of the good.
func deal() -> void:
	var t := picked()
	if t.is_empty() or max_count(t, _gs, _db) <= 0:
		return
	chosen.emit(_object, Interact.trade_action(_prefix(t), good, count))


## "Sell all" on card `i` of the Sell tab.
func sell_all(i: int) -> void:
	var r := _rows[i]
	chosen.emit(_object, Interact.trade_action(Interact.SELL, r["good"], int(r["have"])))


func back() -> void:
	var id := _object
	close()
	went_back.emit(id)


func close() -> void:
	hide()
	for c: Control in [_minus, _plus, _max, _deal, _buy_tab, _sell_tab]:
		c.release_focus()


## The cards of one tab (`kind` BUY or SELL) of a shop's trades (Economy.trades).
static func cards_of(trades: Array, kind: String, gs: GameState, db: DataDb) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for t: Dictionary in trades:
		if t["kind"] != kind:
			continue
		var have := gs.economy.count(t["good"]) if gs != null else int(t.get("have", 0))
		var text := "%s %s" % [t["name"], Economy.format(db, int(t["price"]))]
		if have > 0:
			text += " (have %d)" % have
		out.append({"text": text, "good": t["good"], "price": int(t["price"]), "have": have, "kind": kind})
	return out


## How many of a trade's good one deal can take: what the coins pay for (one for
## a meal eaten there or clothes, Economy.is_single), or what the bag holds;
## MAX_COUNT at most. 0 when you cannot pay for one.
static func max_count(t: Dictionary, gs: GameState, db: DataDb) -> int:
	if t.is_empty():
		return 0
	if t["kind"] == Economy.SELL:
		return mini(gs.economy.count(t["good"]), MAX_COUNT)
	var cap := 1 if Economy.is_single(db, t["good"]) else MAX_COUNT
	var price := int(t["price"])
	@warning_ignore("integer_division")
	return cap if price <= 0 else mini(gs.economy.coins / price, cap)


func _prefix(t: Dictionary) -> String:
	return Interact.BUY if t["kind"] == Economy.BUY else Interact.SELL


func _of(kind: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for t: Dictionary in _trades:
		if t["kind"] == kind:
			out.append(t)
	return out


## "You have 5s 7c", or after a deal "You buy 3 bread for 9c. 4s 8c left."
func _show_coins() -> void:
	var coins := Economy.format(_db, _gs.economy.coins)
	_sub.text = "You have %s" % coins if _note == "" else "%s %s left." % [_note, coins]


func _refresh() -> void:
	_show_coins()
	_buy_tab.set_pressed_no_signal(tab == Economy.BUY)
	_sell_tab.set_pressed_no_signal(tab == Economy.SELL)
	_fill()
	_show_strip()
	_fit()
	_fit.call_deferred()  # again once the new cards have their theme sizes
	if not is_visible_in_tree():
		return
	var owner_focus := get_viewport().gui_get_focus_owner()
	if owner_focus != null and owner_focus in [_minus, _plus, _max, _deal] and _strip.visible:
		return
	if _strip.visible and not _deal.disabled:
		_deal.grab_focus()
	elif not _cards.is_empty():
		_cards[maxi(_rows.map(func(r: Dictionary) -> String: return r["good"]).find(good), 0)].grab_focus()


## Puts the cards of the tab on the panel: two columns of goods to buy (one when
## a name is long), and on the Sell tab a "Sell all" button next to each good.
func _fill() -> void:
	for c: Node in _list.get_children():
		c.visible = false  # a card may still be inside its own signal: free it later
		c.queue_free()
	_rows = cards_of(_trades, tab, _gs, _db)
	_cards.clear()
	if _rows.is_empty():
		var none := Label.new()
		none.text = "Nothing for sale here." if tab == Economy.BUY else "You carry nothing this shop buys."
		none.modulate = Color(1, 1, 1, 0.7)
		_list.add_child(none)
		return
	var grid := GridContainer.new()
	var selling := tab == Economy.SELL
	grid.columns = 2 if selling or not _rows.any(func(r: Dictionary) -> bool:
			return String(r["text"]).length() > InteractMenu.LONG) else 1
	grid.add_theme_constant_override("h_separation", InteractMenu.GAP)
	grid.add_theme_constant_override("v_separation", InteractMenu.GAP)
	_list.add_child(grid)
	for i in _rows.size():
		var b := InteractMenu.CardButton.new()
		b.text = String(_rows[i]["text"])
		if _rows[i]["good"] == good:
			for k: String in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
				b.add_theme_color_override(k, PICKED_COLOR)
		b.fired.connect(_on_card.bind(i))
		grid.add_child(b)
		_cards.append(b)
		if selling:
			var all := InteractMenu.CardButton.new()
			all.text = "Sell all"
			all.size_flags_horizontal = Control.SIZE_FILL
			all.custom_minimum_size.x = InteractMenu.ROW_H * 3.0
			all.fired.connect(sell_all.bind(i))
			grid.add_child(all)


func _on_card(i: int) -> void:
	if _rows[i]["good"] != good:
		good = _rows[i]["good"]
		count = 1
	_refresh()


## The count strip of the picked good: hidden when none is picked.
func _show_strip() -> void:
	var t := picked()
	_strip.visible = not t.is_empty()
	if t.is_empty():
		return
	var most := max_count(t, _gs, _db)
	count = clampi(count, 1, maxi(most, 1))
	_count.text = str(count)
	_minus.disabled = count <= 1
	_plus.disabled = count >= most
	_max.disabled = count >= most
	_deal.disabled = most <= 0
	if most <= 0:
		_deal.text = "Not enough coins"
	else:
		_deal.text = "%s %d for %s" % ["Buy" if t["kind"] == Economy.BUY else "Sell", count,
				Economy.format(_db, int(t["price"]) * count)]


## Sits the panel at the bottom middle like the action card (InteractMenu._fit).
func _fit() -> void:
	if not is_inside_tree():
		return
	var view := get_viewport_rect().size
	var w := maxf(minf(InteractMenu.MAX_W, view.x - InteractMenu.SIDE * 2.0), 160.0)
	var rest := 0.0
	for c: Control in [%Header, _sub, _strip]:
		if c.visible:
			rest += c.get_combined_minimum_size().y + InteractMenu.GAP
	_scroll.custom_minimum_size.y = maxf(minf(_list.get_combined_minimum_size().y,
			view.y * InteractMenu.MAX_H - rest - 2.0 * InteractMenu.GAP - InteractMenu.BOTTOM), InteractMenu.ROW_H)
	var h := get_combined_minimum_size().y
	offset_left = -w / 2.0
	offset_right = w / 2.0
	offset_bottom = -InteractMenu.BOTTOM
	offset_top = -InteractMenu.BOTTOM - h


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"back"):
		back()
		get_viewport().set_input_as_handled()
