## On-screen controls for touch screens (M20.1, ADR 0032): a floating stick
## (a finger anywhere on the left half of the screen walks; user, 2026-10-08)
## and a Wait button (bottom left); More, Bag and the context button (bottom
## right, M34.2); Menu (top right); the More grid (Eat, Sleep, Character,
## Journal, Log, Help, Block, Throw, Drop); Back (top right) while a panel is
## open; Cancel while a Skill is armed or a walk runs.
## M34.2 (ADR 0045): the context button replaces Use. It names the nearest
## target's main action and the target ("Talk / Erin"); a tap opens that
## target's card (`context_pressed`). With 2+ targets near, chips left of it
## (a face or a short name) open the others' cards; with more than CHIPS + 1
## the last chip is "All" (the whole target list). The game screen sends the
## targets with set_targets (InteractMenu.targets).
## Each button sends the input action of its key (project.godot [input]) as
## an InputEventAction, so the game reads a tap and a key the same way. A held
## button, or the stick pushed one way, is a held key. The game screen calls sync() every frame.
## M20.3: under a UI scale factor the controls keep their size on the screen
## (user, 2026-10-05): they sit in a box scaled by 1 / factor (set_factor).
## Presentation only.
class_name TouchControls
extends Control

signal cancel_pressed
## M34.2: the context button or a chip: open the card of `object_id` ("" = the target list).
signal context_pressed(object_id: String)

const SIZE := 64.0
const WIDE := 104.0
const GAP := 6.0
const MARGIN := 12.0
## The context button's height: bigger than the others, in thumb reach.
const BIG := 96.0
## Chips beside the context button (the last one is "All" when more are near).
const CHIPS := 3
## A chip without a face shows this many letters of the name.
const CHIP_LETTERS := 5
## Room the Wait button takes from the left edge at factor 1: the HUD log moves right of it.
const PAD_WIDTH := MARGIN + SIZE + MARGIN
## The stick (pixels on the screen). A finger moved less than DEAD from where it
## touched sends nothing; past RADIUS the stick's centre follows the finger.
const DEAD := 18.0
const RADIUS := 56.0
## The other axis must beat the current one by this ratio before the walk turns.
const TURN := 1.3
## The stick starts on the left part of the screen only.
const STICK_ZONE := 0.5
const STICK_ACTIONS := {
	Vector2.UP: &"move_n", Vector2.DOWN: &"move_s", Vector2.RIGHT: &"move_e", Vector2.LEFT: &"move_w",
}
## Right column, top down: label, action ("" = opens the More grid). The
## context button comes last (M34.2).
const COLUMN := [["More", &""], ["Bag", &"bag"]]
const MORE := [
	["Eat", &"eat"], ["Sleep", &"sleep"], ["Character", &"sheet"],
	["Journal", &"journal"], ["Log", &"log"], ["Help", &"help"],
	["Block", &"block"], ["Throw", &"throw"], ["Drop", &"drop"],
]

var pad: GridContainer
var stick: StickView
var column: VBoxContainer
var more: GridContainer
var back: Button
var cancel: Button
## M34.2: the context button, its chips and Menu (top right).
var context: Button
var chips: HBoxContainer
var menu_button: Button
var _targets: Array[Dictionary] = []
## Action -> its button (the pad, the column and the More grid).
var buttons := {}
## Actions a button holds down now.
var _held := {}
## The stick: the finger (-1 = none) and the direction it holds now.
var _finger := -1
var _dir := Vector2.ZERO
## False while a fight turn or a panel has the screen: a touch is a tap then.
var stick_enabled := false
## M34.3: the finger down now (or the last one) walked with the stick, so its lift is no tap.
var stick_walked := false
## Tests set this: the right edge of the stick's zone in pixels (0 = by the screen).
var zone_override := 0.0
## The UI scale factor (M20.3) and the box that undoes it.
var factor := 1.0
var _box: Control


## Draws the stick under the finger. Presentation only.
class StickView extends Control:
	var origin := Vector2.ZERO
	var knob := Vector2.ZERO
	var active := false
	var factor := 1.0

	func _draw() -> void:
		if not active:
			return
		var k := 1.0 / factor
		draw_circle(origin, RADIUS * k, Color(1, 1, 1, 0.12))
		draw_arc(origin, RADIUS * k, 0.0, TAU, 48, Color(1, 1, 1, 0.45), 2.0 * k, true)
		draw_circle(knob, 22.0 * k, Color(1, 1, 1, 0.5))


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate.a = 0.8
	_box = Control.new()
	_box.name = "Box"
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_box)
	resized.connect(_layout_box)
	_layout_box()
	_build_pad()
	stick = StickView.new()
	stick.name = "Stick"
	stick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stick.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(stick)
	_build_column()
	_build_more()
	menu_button = _button("Menu", &"back", WIDE)
	_place_top_right(menu_button)
	back = _button("Back", &"back", WIDE)
	_place_top_right(back)
	set_targets([] as Array[Dictionary])
	visible = false


## Shows what fits the screen now. `shown`: the touch controls are on.
## `panel_open`: a panel (menu, bag, journal ...) has the screen; only Back
## shows. `blocked`: the System dialog or the console is up; nothing shows.
## `can_cancel`: a Skill is armed or a walk runs. `tapping`: a fight turn is
## on, so a touch on the map picks a cell and the stick stays off.
func sync(shown: bool, panel_open: bool, blocked: bool, can_cancel: bool, tapping := false) -> void:
	visible = shown and not blocked
	var play := visible and not panel_open
	pad.visible = play
	stick_enabled = play and not tapping
	column.visible = play
	menu_button.visible = play
	cancel.visible = play and can_cancel
	if not play:
		more.visible = false
	chips.visible = play and not more.visible and chips.get_child_count() > 0
	back.visible = visible and panel_open
	if not play:
		release_all()


## M34.2: Menu and Back sit `px` (this layer's pixels) from the top: under the HUD's status bar.
func set_top_room(px: float) -> void:
	var top := MARGIN + px * factor
	for c: Control in [menu_button, back]:
		if c.offset_top != top:  # called each frame: no relayout when unchanged
			c.offset_top = top
			c.offset_bottom = top


## M34.5: the bottom-right controls sit `px` (this layer's pixels) above the
## bottom edge: over the combat bar while a fight runs (0 = none). Cancel stays
## on top of the column, whose height changes when the context button hides.
func set_bottom_room(px: float) -> void:
	var bottom := -(MARGIN + px * factor)
	for c: Control in [column, chips, more]:
		if c.offset_bottom != bottom:  # called each frame: no relayout when unchanged
			c.offset_bottom = bottom
			c.offset_top = bottom
	var over := bottom - column.get_combined_minimum_size().y - GAP
	if cancel.offset_bottom != over:
		cancel.offset_bottom = over
		cancel.offset_top = over


## M34.2: the targets near, nearest first ({"id", "verb", "name", "look"},
## InteractMenu.targets). The first is on the context button; the others are chips.
func set_targets(targets: Array[Dictionary]) -> void:
	_targets = targets
	context.disabled = targets.is_empty()
	context.visible = not targets.is_empty()  # M34.5: no empty button (it hid End turn in a fight)
	context.text = "-" if targets.is_empty() else "%s\n%s" % [targets[0]["verb"], targets[0]["name"]]
	for c: Node in chips.get_children():
		chips.remove_child(c)
		c.queue_free()
	var others := _chip_targets()
	others.reverse()  # the row grows left: the nearest sits next to the button
	for t: Dictionary in others:
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(SIZE, SIZE)
		b.tooltip_text = ("%s %s" % [t["verb"], t["name"]]).strip_edges()
		var face := Portrait.texture(String(t["look"]))
		if face != null:
			b.icon = face
			b.expand_icon = true
		else:
			b.text = String(t["name"]).left(CHIP_LETTERS)
		b.pressed.connect(func() -> void: context_pressed.emit(String(t["id"])))
		chips.add_child(b)


## The targets on the context button and its chips now.
func targets() -> Array[Dictionary]:
	return _targets


## The ids the chips open, nearest first ("" = All).
func chip_ids() -> Array[String]:
	var out: Array[String] = []
	for t: Dictionary in _chip_targets():
		out.append(String(t["id"]))
	return out


## Presses chip `i` (nearest first), as a tap does.
func press_chip(i: int) -> void:
	var b: Button = chips.get_child(chips.get_child_count() - 1 - i)
	b.pressed.emit()


## The targets after the first, CHIPS at most; the last is "All" when more are near.
func _chip_targets() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	out.assign(_targets.slice(1))
	if out.size() > CHIPS:
		out.resize(CHIPS - 1)
		out.append({"id": "", "verb": "", "name": "All", "look": ""})
	return out


## The UI scale factor (M20.3): the controls keep their size on the screen.
func set_factor(f: float) -> void:
	factor = maxf(f, 0.1)
	stick.factor = factor
	_layout_box()


## Room the pad takes from the left edge, in this layer's pixels.
func pad_width() -> float:
	return PAD_WIDTH / factor


func _layout_box() -> void:
	_box.scale = Vector2.ONE / factor
	_box.size = size * factor


## Lets go of every held button (the pad hid while a finger was on it).
func release_all() -> void:
	stick_up(_finger)
	for action: StringName in _held.keys():
		_send(action, false)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			stick_down(event.index, event.position)
		else:
			stick_up(event.index)
	elif event is InputEventScreenDrag:
		stick_move(event.index, event.position)


## A finger touched the screen at `at` (this layer's pixels): the stick starts
## there, when it is on the left part of the screen and not on a button.
func stick_down(finger: int, at: Vector2) -> void:
	if _finger == -1:
		stick_walked = false
	if not stick_enabled or _finger != -1 or at.x > _zone_right():
		return
	if _on_button(at):
		return
	_finger = finger
	stick.active = true
	stick.origin = at
	stick.knob = at
	_set_dir(Vector2.ZERO)
	stick.queue_redraw()


func stick_move(finger: int, at: Vector2) -> void:
	if finger != _finger or _finger == -1:
		return
	var d := at - stick.origin
	var dist := d.length()
	if dist > RADIUS / factor:
		# Past the rim: the centre follows the finger, so a long swipe never runs out of room.
		stick.origin = at - d / dist * (RADIUS / factor)
		d = at - stick.origin
		dist = d.length()
	stick.knob = at
	if dist < DEAD / factor:
		_set_dir(Vector2.ZERO)
	else:
		_set_dir(_pick(d))
	stick.queue_redraw()


func stick_up(finger: int) -> void:
	if finger != _finger or _finger == -1:
		return
	_finger = -1
	stick.active = false
	_set_dir(Vector2.ZERO)
	stick.queue_redraw()


## The direction the stick holds now (Vector2.ZERO = none).
func stick_dir() -> Vector2:
	return _dir


## 4-way: the stronger axis wins, and the walk turns only when the other axis
## clearly beats it (so a finger near the diagonal does not zig-zag).
func _pick(d: Vector2) -> Vector2:
	var ax := absf(d.x)
	var ay := absf(d.y)
	var horizontal := ax >= ay
	if _dir != Vector2.ZERO:
		var was_h := _dir.x != 0.0
		horizontal = was_h
		if was_h and ay > ax * TURN:
			horizontal = false
		elif not was_h and ax > ay * TURN:
			horizontal = true
	if horizontal:
		return Vector2.RIGHT if d.x > 0.0 else Vector2.LEFT
	return Vector2.DOWN if d.y > 0.0 else Vector2.UP


func _set_dir(dir: Vector2) -> void:
	if dir == _dir:
		return
	if _dir != Vector2.ZERO:
		_send(STICK_ACTIONS[_dir], false)
	_dir = dir
	if _dir != Vector2.ZERO:
		stick_walked = true
		_send(STICK_ACTIONS[_dir], true)


func _zone_right() -> float:
	return zone_override if zone_override > 0.0 else size.x * STICK_ZONE


## True when `at` is over a visible button (the stick does not start on one).
func _on_button(at: Vector2) -> bool:
	for c: Control in [pad, column, more, back, cancel, chips, menu_button]:
		if c.is_visible_in_tree() and c.get_global_rect().has_point(at):
			return true
	return false


func is_held(action: StringName) -> bool:
	return _held.has(action)


## Presses and lets go of `action`'s button, as a tap does (tests use it).
func tap(action: StringName) -> void:
	_send(action, true)
	_send(action, false)


func _build_pad() -> void:
	pad = GridContainer.new()
	pad.name = "Pad"
	pad.columns = 1
	_box.add_child(pad)
	pad.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	pad.grow_vertical = Control.GROW_DIRECTION_BEGIN
	pad.offset_left = MARGIN
	pad.offset_bottom = -MARGIN
	pad.offset_top = -MARGIN
	pad.add_child(_button("Wait", &"wait", SIZE))


func _build_column() -> void:
	column = VBoxContainer.new()
	column.name = "Column"
	column.add_theme_constant_override("separation", int(GAP))
	for row: Array in COLUMN:
		if row[1] == &"":
			var b := Button.new()
			b.text = row[0]
			b.name = "More"
			b.focus_mode = Control.FOCUS_NONE
			b.custom_minimum_size = Vector2(WIDE, SIZE)
			b.pressed.connect(func() -> void: more.visible = not more.visible)
			column.add_child(b)
		else:
			column.add_child(_button(row[0], row[1], WIDE))
	context = Button.new()
	context.name = "Context"
	context.focus_mode = Control.FOCUS_NONE
	context.custom_minimum_size = Vector2(WIDE, BIG)
	context.clip_text = true
	context.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	context.pressed.connect(func() -> void:
		if not _targets.is_empty():
			context_pressed.emit(String(_targets[0]["id"])))
	buttons[&"use"] = context  # E opens the use menu; on touch this button does
	column.add_child(context)
	_place_bottom_right(column, MARGIN)
	chips = HBoxContainer.new()
	chips.name = "Chips"
	chips.add_theme_constant_override("separation", int(GAP))
	_place_bottom_right(chips, MARGIN + WIDE + GAP * 2)
	# Cancel sits above the column (not in it), so the column never moves.
	cancel = Button.new()
	cancel.text = "Cancel"
	cancel.name = "Cancel"
	cancel.focus_mode = Control.FOCUS_NONE
	cancel.custom_minimum_size = Vector2(WIDE, SIZE)
	cancel.pressed.connect(func() -> void: cancel_pressed.emit())
	_place_bottom_right(cancel, MARGIN)
	cancel.offset_bottom = -(MARGIN + column.get_combined_minimum_size().y + GAP)
	cancel.offset_top = cancel.offset_bottom


func _build_more() -> void:
	more = GridContainer.new()
	more.name = "MoreGrid"
	more.columns = 3
	more.add_theme_constant_override("h_separation", int(GAP))
	more.add_theme_constant_override("v_separation", int(GAP))
	for row: Array in MORE:
		var b := _button(row[0], row[1], WIDE)
		b.button_up.connect(func() -> void: more.visible = false)
		more.add_child(b)
	more.visible = false
	_place_bottom_right(more, MARGIN + WIDE + GAP * 2)


## Anchors `c` to the bottom right corner, `right` px in from the right edge (M34.2).
func _place_bottom_right(c: Control, right: float) -> void:
	if c.get_parent() == null:
		_box.add_child(c)
	c.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	c.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	c.grow_vertical = Control.GROW_DIRECTION_BEGIN
	c.offset_right = -right
	c.offset_left = -right
	c.offset_bottom = -MARGIN
	c.offset_top = -MARGIN


## Anchors `c` to the top right corner (Menu, Back; M34.2).
func _place_top_right(c: Control) -> void:
	if c.get_parent() == null:
		_box.add_child(c)
	c.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	c.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	c.grow_vertical = Control.GROW_DIRECTION_END
	c.offset_right = -MARGIN
	c.offset_left = -MARGIN
	c.offset_top = MARGIN
	c.offset_bottom = MARGIN


func _button(label: String, action: StringName, width: float) -> Button:
	var b := Button.new()
	b.text = label
	_wire(b, action, width)
	return b


## Makes `b` hold `action` while pressed. No focus: keys keep going to the game.
func _wire(b: Button, action: StringName, width: float) -> void:
	b.name = String(action)
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(width, SIZE)
	b.button_down.connect(_send.bind(action, true))
	b.button_up.connect(_send.bind(action, false))
	buttons[action] = b


func _send(action: StringName, pressed: bool) -> void:
	if pressed == _held.has(action):
		return
	if pressed:
		_held[action] = true
	else:
		_held.erase(action)
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	Input.parse_input_event(ev)


## On a touch screen a single tap picks an item in `list` (a mouse needs a
## double click, and a double tap is hard to find on a phone).
static func activate_on_tap(list: ItemList) -> void:
	list.item_clicked.connect(func(index: int, _at: Vector2, button: int) -> void:
		if button == MOUSE_BUTTON_LEFT and Session.touch_shown():
			list.item_activated.emit(index))
