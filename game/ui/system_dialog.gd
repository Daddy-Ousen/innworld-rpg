## The "Voice of the World" panel (ADR 0009). Shows SystemMessages pages
## one at a time. Offers get Accept / Decline; Decline asks once more.
## Answers go to Commands.accept_class / decline_class. Enter presses the
## focused button. Presentation only: it changes state through Commands.
class_name SystemDialog
extends PanelContainer

signal closed
## The player confirmed a fate warning (SystemMessages.STRIKE): attack this NPC now.
signal struck(npc: String)

const LABELS := {
	SystemMessages.NEXT: "Continue",
	SystemMessages.ACCEPT: "Accept",
	SystemMessages.DECLINE: "Decline",
	SystemMessages.YES: "Yes, decline",
	SystemMessages.BACK: "Back",
	SystemMessages.STRIKE: "Strike them down",
	SystemMessages.SPARE: "Step back",
}

var _gs: GameState
var _db: DataDb
var _pages: Array[Dictionary] = []
var _index := 0
## The page on screen (a confirm page is shown in place of its offer).
var current: Dictionary = {}

@onready var _title: Label = %Title
@onready var _text: Label = %Text
@onready var _buttons: HBoxContainer = %Buttons


func _ready() -> void:
	hide()


func open(pages: Array[Dictionary], gs: GameState, db: DataDb) -> void:
	_gs = gs
	_db = db
	_pages = pages.duplicate()
	_index = -1
	_advance()


## Presses a choice on the current page (the buttons call this too).
func choose(choice: String) -> void:
	match choice:
		SystemMessages.ACCEPT:
			_answer(Commands.accept_class(_gs, _db, current["class"]))
		SystemMessages.DECLINE:
			_show(SystemMessages.confirm_decline(_db, current["class"]))
		SystemMessages.YES:
			_answer(Commands.decline_class(_gs, _db, current["class"]))
		SystemMessages.BACK:
			_show(_pages[_index])
		SystemMessages.STRIKE:
			var npc: String = current["npc"]
			_dismiss()
			struck.emit(npc)
		SystemMessages.SPARE:
			_dismiss()
		_:
			_advance()


## Shows the System's answer next, then moves on.
func _answer(lines: Array[String]) -> void:
	_pages.insert(_index + 1, SystemMessages.result(lines))
	_advance()


## Closes a fate warning: no night follows, so `closed` does not fire.
func _dismiss() -> void:
	_pages.clear()
	current = {}
	hide()


func _advance() -> void:
	_index += 1
	while _index < _pages.size() and not SystemMessages.is_open(_pages[_index], _gs):
		_index += 1
	if _index >= _pages.size():
		current = {}
		hide()
		closed.emit()
		return
	_show(_pages[_index])


func _show(page: Dictionary) -> void:
	current = page
	Audio.play_cues([SoundCues.page_sound(Audio.db, page)])
	_title.text = "[%s]" % page["title"]
	_text.text = "\n".join(page["lines"])
	for b in _buttons.get_children():
		_buttons.remove_child(b)
		b.queue_free()
	for choice: String in page["choices"]:
		var b := Button.new()
		b.text = LABELS.get(choice, choice.capitalize())
		b.pressed.connect(choose.bind(choice), CONNECT_DEFERRED)
		_buttons.add_child(b)
	show()
	if page["kind"] == SystemMessages.FATE:  # the safe answer has the focus; the other waits a moment
		var strike := _buttons.get_child(0) as Button
		strike.disabled = float(page.get("delay", 0.0)) > 0.0
		if is_inside_tree():
			(_buttons.get_child(1) as Button).grab_focus()
			if strike.disabled:
				var id := strike.get_instance_id()  # the page may be gone when the timer ends
				get_tree().create_timer(float(page["delay"])).timeout.connect(
						func() -> void:
							var b := instance_from_id(id) as Button
							if b != null:
								b.disabled = false)
		return
	if is_inside_tree():
		(_buttons.get_child(0) as Button).grab_focus()
