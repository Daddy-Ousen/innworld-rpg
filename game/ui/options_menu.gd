## The Options panel (M12.1, ADR 0019): a volume slider per audio bus and
## a mute box; a large text box (M15.0, Session.set_large_text); the touch
## controls Auto / On / Off (M20.1, Session.set_touch_mode). Opened from the title menu and the pause menu. Each change
## goes to Audio at once (it applies and saves user://settings.cfg).
## Esc or Back closes it. Presentation only.
class_name OptionsMenu
extends PanelContainer

signal closed

## Bus -> slider label, in slider order.
const LABELS := {"Master": "Volume", "Music": "Music", "Ambience": "Ambience", "SFX": "Effects",
		"UI": "Menu sounds"}
const STEP := 0.05
const SLIDER_WIDTH := 180.0
## Touch mode -> its label, in list order.
const TOUCH_LABELS := {TouchSettings.AUTO: "Auto", TouchSettings.ON: "On", TouchSettings.OFF: "Off"}

## Bus -> HSlider.
var sliders := {}

@onready var _rows: GridContainer = %Rows
@onready var _mute: CheckBox = %Mute
@onready var _large_text: CheckBox = %LargeText
@onready var _touch: OptionButton = %Touch
@onready var _back: Button = %Back


func _ready() -> void:
	hide()
	for bus: String in LABELS:
		var label := Label.new()
		label.text = LABELS[bus]
		_rows.add_child(label)
		var s := HSlider.new()
		s.name = bus
		s.min_value = 0.0
		s.max_value = 1.0
		s.step = STEP
		s.custom_minimum_size.x = SLIDER_WIDTH
		s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		s.value_changed.connect(func(v: float) -> void: Audio.set_volume(bus, v))
		_rows.add_child(s)
		sliders[bus] = s
	_mute.toggled.connect(Audio.set_muted)
	_large_text.toggled.connect(Session.set_large_text)
	for mode: String in TOUCH_LABELS:
		_touch.add_item(TOUCH_LABELS[mode])
	_touch.item_selected.connect(func(i: int) -> void:
		Session.set_touch_mode(TOUCH_LABELS.keys()[i]))
	_back.pressed.connect(close)


## Shows the panel with the current settings.
func open() -> void:
	for bus: String in sliders:
		(sliders[bus] as HSlider).set_value_no_signal(Audio.settings.volume(bus))
	_mute.set_pressed_no_signal(Audio.settings.muted)
	_large_text.set_pressed_no_signal(Session.text.large)
	_touch.select(TOUCH_LABELS.keys().find(Session.touch.mode))
	show()
	(sliders["Master"] as HSlider).grab_focus()


func close() -> void:
	if not visible:
		return
	hide()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"back"):
		close()
		get_viewport().set_input_as_handled()
