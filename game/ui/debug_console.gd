## Debug text console: type actions, sleep, see System messages.
## Runs on its own, or as the overlay in world/main.tscn (backtick key).
## With the Session autoload it works on Session.gs, so the map follows.
extends Control

var _console: ConsoleCommands
var _session: Node
var _history: Array[String] = []
var _history_pos := 0

@onready var _output: RichTextLabel = %Output
@onready var _input: LineEdit = %Input


func _ready() -> void:
	_session = get_node_or_null("/root/Session")
	var db: DataDb = _session.db if _session != null else DataDb.load_dir()
	if not db.is_valid():
		_print(["Data errors:"] as Array[String])
		_print(db.errors)
	_console = ConsoleCommands.new(db)
	if _session != null:
		_console.gs = _session.gs
	_input.text_submitted.connect(_on_submitted)
	_input.gui_input.connect(_on_input_key)
	_input.grab_focus()
	_print(["Innworld RPG — debug console."] as Array[String])
	_print(_console.execute("help"))
	_print(_console.execute("status"))


func _on_submitted(text: String) -> void:
	_input.clear()
	if text.strip_edges().is_empty():
		return
	_history.append(text)
	_history_pos = _history.size()
	_output.push_color(Color(0.6, 0.6, 0.6))
	_output.add_text("> " + text + "\n")
	_output.pop()
	if _session != null:
		_console.gs = _session.gs
	_print(_console.execute(text))
	if _session != null:
		_session.set_state(_console.gs)


## Up/down arrows walk the command history.
func _on_input_key(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or _history.is_empty():
		return
	if event.keycode == KEY_UP:
		_history_pos = maxi(_history_pos - 1, 0)
	elif event.keycode == KEY_DOWN:
		_history_pos = mini(_history_pos + 1, _history.size())
	else:
		return
	_input.text = _history[_history_pos] if _history_pos < _history.size() else ""
	_input.caret_column = _input.text.length()
	_input.accept_event()


func _print(lines: Array[String]) -> void:
	for line in lines:
		_output.add_text(line + "\n")
