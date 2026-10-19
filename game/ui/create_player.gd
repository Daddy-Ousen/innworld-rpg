## The "Who are you?" step of New game (M30.5, ADR 0044): a name field, the look
## presets (a front frame of each sheet) and the Earth backgrounds (PlayerIdentity).
## Built in code; buttons work with touch and the UI scale. Presentation only: `begun`
## hands the picks to the title menu, which starts the game.
class_name CreatePlayer
extends VBoxContainer

signal begun(identity: Dictionary)
signal cancelled

## Look preset ids and the shown one.
var looks: Array[String] = []
var look_i := 0
## The picked background id, "" = none.
var background := ""

var _db: DataDb
var name_edit: LineEdit
var _preview: TextureRect
var _look_label: Label
var _blurb: Label
var _bg_buttons := {}
var begin: Button


func _init() -> void:
	name = "Create"
	add_theme_constant_override("separation", 8)


## Fills the panel from `db` (data/backgrounds.json) and resets the picks.
func setup(db: DataDb) -> void:
	_db = db
	for c: Node in get_children():
		remove_child(c)
		c.queue_free()
	_bg_buttons.clear()
	looks = PlayerIdentity.looks(db)
	look_i = 0
	background = ""
	_label("Who are you?", Color(1, 0.82, 0.45))
	name_edit = LineEdit.new()
	name_edit.name = "Name"
	name_edit.placeholder_text = PlayerIdentity.DEFAULT_NAME
	name_edit.max_length = PlayerIdentity.MAX_NAME
	name_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(name_edit)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(row)
	row.add_child(_button("Prev", "<", func() -> void: show_look(look_i - 1)))
	_preview = TextureRect.new()
	_preview.custom_minimum_size = Vector2(96, 96)
	_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(_preview)
	row.add_child(_button("Next", ">", func() -> void: show_look(look_i + 1)))
	_look_label = _label("", Color(0.7, 0.7, 0.75))
	var bgs := PlayerIdentity.backgrounds(db)
	if not bgs.is_empty():
		_label("On Earth you were:", Color(0.7, 0.7, 0.75))
		var grid := GridContainer.new()
		grid.columns = 3
		add_child(grid)
		for id: String in bgs:
			var b := _button("Bg_" + id, String(bgs[id]["name"]), pick_background.bind(id))
			b.toggle_mode = true
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			grid.add_child(b)
			_bg_buttons[id] = b
		_blurb = _label("", Color(0.85, 0.85, 0.8))
		_blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_blurb.custom_minimum_size = Vector2(300, 0)
	var end := HBoxContainer.new()
	end.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(end)
	end.add_child(_button("Back", "Back", func() -> void: cancelled.emit()))
	begin = _button("Begin", "Begin", func() -> void: begun.emit(identity()))
	end.add_child(begin)
	for x: Button in [end.get_child(0), begin]:
		x.custom_minimum_size.x = 120
	show_look(0)
	pick_background("")


## Shows look preset `i` (wraps around).
func show_look(i: int) -> void:
	look_i = posmod(i, looks.size())
	var look := looks[look_i]
	_look_label.text = "Look %d of %d" % [look_i + 1, looks.size()]
	if CharacterSprite.has_sheet(look):
		var t := AtlasTexture.new()
		t.atlas = load(CharacterSprite.path_for(look))
		t.region = CharacterSprite.region_of("walk", "s", 0)
		_preview.texture = t
	else:
		_preview.texture = null


## Picks background `id`; the same id again (or "") picks none.
func pick_background(id: String) -> void:
	background = "" if id == background else id
	for k: String in _bg_buttons:
		(_bg_buttons[k] as Button).set_pressed_no_signal(k == background)
	if _blurb != null:
		_blurb.text = "Pick what you did before the Ritual, or none." if background == "" \
				else String(PlayerIdentity.backgrounds(_db)[background]["blurb"])


## The picks for PlayerIdentity.apply.
func identity() -> Dictionary:
	return {"name": PlayerIdentity.clean_name(name_edit.text), "look": looks[look_i], "background": background}


func _label(text: String, colour: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_color", colour)
	add_child(l)
	return l


func _button(id: String, text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.name = id
	b.text = text
	b.custom_minimum_size = Vector2(48, 40)  # a finger-sized target
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(on_press)
	return b
