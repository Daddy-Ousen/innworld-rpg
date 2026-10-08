## The long-road prompt and its short walking scene. A road of
## LONG_MINUTES or more (Celum <-> camp <-> Liscor, 10 h) is not a normal
## step: the player confirms first, then a small animation shows a walker
## on a track from one place to the other while the screen is covered. The
## real move happens at the end of the walk (`arrived`), then the screen
## fades back. Presentation only (CLAUDE.md rule 1): it changes no state.
class_name TravelPrompt
extends Control

## Exits at least this long (minutes) ask first.
const LONG_MINUTES := 300
const WALK_SECONDS := 1.8
const FADE_SECONDS := 0.25
const FOCUS_ASK := "Stay"

## The player said yes; the walking scene starts.
signal confirmed
## The player said no.
signal cancelled
## The walk is over and the screen is covered: make the move now.
signal arrived

var _panel: PanelContainer
var _ask_label: Label
var _go: Button
var _stay: Button
var _scene: ColorRect
var _from_label: Label
var _to_label: Label
var _time_label: Label
var _track: ColorRect
var _fill: ColorRect
var _walker: Control
var _tween: Tween
var _walking := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	hide()


## True when an exit of `minutes` needs the prompt.
static func is_long(minutes: int) -> bool:
	return minutes >= LONG_MINUTES


## "10 hours", "1 hour 30 min".
static func duration_text(minutes: int) -> String:
	var h := minutes / 60
	var m := minutes % 60
	var parts: Array[String] = []
	if h > 0:
		parts.append("%d hour%s" % [h, "" if h == 1 else "s"])
	if m > 0:
		parts.append("%d min" % m)
	return " ".join(parts) if not parts.is_empty() else "no time"


## Shows the question for a trip from `from_name` to `to_name`.
func ask(from_name: String, to_name: String, minutes: int) -> void:
	_from_label.text = from_name
	_to_label.text = to_name
	_time_label.text = "%s on the road..." % duration_text(minutes)
	_ask_label.text = "Travel to %s?\nThe journey takes about %s." % [to_name, duration_text(minutes)]
	_walking = false
	_scene.hide()
	$Dim.show()
	_panel.show()
	show()
	_stay.grab_focus.call_deferred()


## True while the question or the walk is on screen.
func is_open() -> bool:
	return visible


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.name = "Dim"
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_panel = PanelContainer.new()
	center.add_child(_panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	_panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	_ask_label = Label.new()
	_ask_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_ask_label)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)
	_go = Button.new()
	_go.text = "Travel"
	_go.pressed.connect(_on_go)
	row.add_child(_go)
	_stay = Button.new()
	_stay.text = FOCUS_ASK
	_stay.pressed.connect(_on_stay)
	row.add_child(_stay)

	_scene = ColorRect.new()
	_scene.color = Color(0.05, 0.06, 0.09, 1.0)
	_scene.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scene.mouse_filter = Control.MOUSE_FILTER_STOP
	_scene.name = "WalkScene"
	add_child(_scene)
	_track = ColorRect.new()
	_track.color = Color(0.32, 0.27, 0.2)
	_scene.add_child(_track)
	_fill = ColorRect.new()
	_fill.color = Color(0.78, 0.66, 0.4)
	_scene.add_child(_fill)
	for end in [0, 1]:
		var post := ColorRect.new()
		post.color = Color(0.78, 0.66, 0.4)
		post.size = Vector2(10, 26)
		post.name = "Post%d" % end
		_scene.add_child(post)
	_from_label = _scene_label()
	_to_label = _scene_label()
	_time_label = _scene_label()
	_walker = Control.new()
	var body := ColorRect.new()
	body.color = Color(0.85, 0.85, 0.9)
	body.position = Vector2(-5, -6)
	body.size = Vector2(10, 16)
	_walker.add_child(body)
	var head := ColorRect.new()
	head.color = Color(0.95, 0.8, 0.65)
	head.position = Vector2(-4, -14)
	head.size = Vector2(8, 8)
	_walker.add_child(head)
	_scene.add_child(_walker)


func _scene_label() -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_scene.add_child(l)
	return l


func _on_stay() -> void:
	hide()
	cancelled.emit()


func _on_go() -> void:
	_panel.hide()
	confirmed.emit()
	_play()


func _play() -> void:
	_walking = true
	$Dim.hide()
	_scene.modulate.a = 0.0
	_scene.show()
	_layout()
	_set_progress(0.0)
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(_scene, "modulate:a", 1.0, FADE_SECONDS)
	_tween.tween_method(_set_progress, 0.0, 1.0, WALK_SECONDS)
	_tween.tween_callback(_arrive)


func _arrive() -> void:
	_walking = false
	arrived.emit()
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(_scene, "modulate:a", 0.0, FADE_SECONDS)
	_tween.tween_callback(_done)


func _done() -> void:
	_scene.hide()
	hide()


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()


func _left() -> float:
	return get_viewport_rect().size.x * 0.18


func _right() -> float:
	return get_viewport_rect().size.x * 0.82


func _mid_y() -> float:
	return get_viewport_rect().size.y * 0.5


func _layout() -> void:
	var left := _left()
	var right := _right()
	var y := _mid_y()
	_track.position = Vector2(left, y)
	_track.size = Vector2(right - left, 4)
	_fill.position = Vector2(left, y)
	_fill.size = Vector2(0, 4)
	(_scene.get_node("Post0") as ColorRect).position = Vector2(left - 5, y - 22)
	(_scene.get_node("Post1") as ColorRect).position = Vector2(right - 5, y - 22)
	var w := 260.0
	_from_label.size = Vector2(w, 30)
	_from_label.position = Vector2(left - w / 2.0, y + 18)
	_to_label.size = Vector2(w, 30)
	_to_label.position = Vector2(right - w / 2.0, y + 18)
	_time_label.size = Vector2(w * 2.0, 30)
	_time_label.position = Vector2((left + right) / 2.0 - w, y - 90)


func _set_progress(p: float) -> void:
	var left := _left()
	var x := lerpf(left, _right(), p)
	var y := _mid_y()
	_fill.size.x = x - left
	_walker.position = Vector2(x, y - 12 - absf(sin(p * 26.0)) * 4.0)


## Esc or a key on the question says no; a key or a click during the walk
## skips to the end. Everything else is swallowed while the prompt is up.
func _input(event: InputEvent) -> void:
	if not visible:
		return
	var pressed := false
	if event is InputEventKey:
		pressed = event.pressed and not event.echo
	elif event is InputEventMouseButton or event is InputEventScreenTouch:
		pressed = event.pressed
	if _walking:
		if pressed:
			skip()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel"):
		_on_stay()
		get_viewport().set_input_as_handled()


## Jumps the walk to its end (the move and the fade-out follow at once).
func skip() -> void:
	if not _walking:
		return
	_kill_tween()
	_set_progress(1.0)
	_scene.modulate.a = 1.0
	_arrive()
