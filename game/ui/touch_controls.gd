## On-screen controls for touch screens (M20.1, ADR 0032): a 4-way pad with
## Wait in the middle (bottom left); Use, Bag, More and Menu (right); the More
## grid (Eat, Sleep, Character, Journal, Log, Help, Block, Throw, Drop); Back
## while a panel is open; Cancel while a Skill is armed or a walk runs.
## Each button sends the input action of its key (project.godot [input]) as
## an InputEventAction, so the game reads a tap and a key the same way. A held
## pad button is a held key. The game screen calls sync() every frame.
## Presentation only.
class_name TouchControls
extends Control

signal cancel_pressed

const SIZE := 64.0
const WIDE := 104.0
const GAP := 6.0
const MARGIN := 12.0
## Room the pad takes from the left edge: the HUD log moves right of it.
const PAD_WIDTH := MARGIN + SIZE * 3 + GAP * 2 + MARGIN
## Pad cells, row by row: a direction action or WAIT ("" = empty cell).
const PAD := [
	"", &"move_n", "",
	&"move_w", &"wait", &"move_e",
	"", &"move_s", "",
]
const ARROWS := {
	&"move_n": Vector2.UP, &"move_s": Vector2.DOWN, &"move_e": Vector2.RIGHT, &"move_w": Vector2.LEFT,
}
## Right column: label, action ("" = opens the More grid).
const COLUMN := [["Use", &"use"], ["Bag", &"bag"], ["More", &""], ["Menu", &"back"]]
const MORE := [
	["Eat", &"eat"], ["Sleep", &"sleep"], ["Character", &"sheet"],
	["Journal", &"journal"], ["Log", &"log"], ["Help", &"help"],
	["Block", &"block"], ["Throw", &"throw"], ["Drop", &"drop"],
]

var pad: GridContainer
var column: VBoxContainer
var more: GridContainer
var back: Button
var cancel: Button
## Action -> its button (the pad, the column and the More grid).
var buttons := {}
## Actions a button holds down now.
var _held := {}


## An arrow drawn as a triangle, so the pad does not depend on font glyphs.
class Arrow extends Button:
	var dir := Vector2.ZERO

	func _draw() -> void:
		var c := size / 2.0
		var r := minf(size.x, size.y) * 0.24
		var side := Vector2(-dir.y, dir.x) * r
		var base := c - dir * r * 0.6
		draw_colored_polygon(PackedVector2Array([c + dir * r, base + side, base - side]),
				get_theme_color("font_color"))


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate.a = 0.8
	_build_pad()
	_build_column()
	_build_more()
	back = _button("Back", &"back", WIDE)
	_place_right(back, MARGIN)
	visible = false


## Shows what fits the screen now. `shown`: the touch controls are on.
## `panel_open`: a panel (menu, bag, journal ...) has the screen; only Back
## shows. `blocked`: the System dialog or the console is up; nothing shows.
## `can_cancel`: a Skill is armed or a walk runs.
func sync(shown: bool, panel_open: bool, blocked: bool, can_cancel: bool) -> void:
	visible = shown and not blocked
	var play := visible and not panel_open
	pad.visible = play
	column.visible = play
	cancel.visible = play and can_cancel
	if not play:
		more.visible = false
	back.visible = visible and panel_open
	if not play:
		release_all()


## Lets go of every held button (the pad hid while a finger was on it).
func release_all() -> void:
	for action: StringName in _held.keys():
		_send(action, false)


func is_held(action: StringName) -> bool:
	return _held.has(action)


## Presses and lets go of `action`'s button, as a tap does (tests use it).
func tap(action: StringName) -> void:
	_send(action, true)
	_send(action, false)


func _build_pad() -> void:
	pad = GridContainer.new()
	pad.name = "Pad"
	pad.columns = 3
	pad.add_theme_constant_override("h_separation", int(GAP))
	pad.add_theme_constant_override("v_separation", int(GAP))
	add_child(pad)
	pad.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	pad.grow_vertical = Control.GROW_DIRECTION_BEGIN
	pad.offset_left = MARGIN
	pad.offset_bottom = -MARGIN
	pad.offset_top = -MARGIN
	for cell: StringName in PAD:
		if cell == &"":
			var blank := Control.new()
			blank.custom_minimum_size = Vector2(SIZE, SIZE)
			blank.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pad.add_child(blank)
		elif ARROWS.has(cell):
			var a := Arrow.new()
			a.dir = ARROWS[cell]
			_wire(a, cell, SIZE)
			pad.add_child(a)
		else:
			pad.add_child(_button("Wait", cell, SIZE))


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
	_place_right(column, MARGIN)
	# Cancel sits above the column (not in it), so the column never moves.
	cancel = Button.new()
	cancel.text = "Cancel"
	cancel.name = "Cancel"
	cancel.focus_mode = Control.FOCUS_NONE
	cancel.custom_minimum_size = Vector2(WIDE, SIZE)
	cancel.pressed.connect(func() -> void: cancel_pressed.emit())
	_place_right(cancel, MARGIN)
	cancel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	cancel.offset_bottom = -(column.get_combined_minimum_size().y / 2.0 + GAP)
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
	_place_right(more, MARGIN + WIDE + GAP * 2)


## Anchors `c` to the middle of the right edge, `right` px in.
func _place_right(c: Control, right: float) -> void:
	if c.get_parent() == null:
		add_child(c)
	c.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	c.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	c.grow_vertical = Control.GROW_DIRECTION_BOTH
	c.offset_right = -right
	c.offset_left = -right
	c.offset_top = 0.0
	c.offset_bottom = 0.0


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
