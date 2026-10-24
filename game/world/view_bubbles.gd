## Speech bubbles over NPCs on the map (M30.1, ADR 0044 "M30.0"): barks. An NPC
## with idle lines within rules.voice.bark_tiles of the player says one line per
## bark bucket (Voice.bark: a stable pick, never gs.rng). The bubble fades after a
## few real seconds. M31.0: a stage beat with a speaker (Stage.last_beat) shows
## over that NPC once, in place of a bark. View only: nothing here reads or writes
## game state beyond looking at it. No bubbles in a fight. WorldView makes and owns
## one; `_v` is the view (untyped: no script cycle).
class_name ViewBubbles
extends RefCounted

const TILE := ViewArt.TILE
const U := ViewArt.U
## Real seconds a bubble shows at full strength, then fades out over FADE.
const HOLD := 3.5
const FADE := 1.0
## Px above the NPC's cell centre (over the name label).
const TOP := 14.0 * U
const BACK := Color(1, 1, 1, 0.9)
const TEXT := Color(0.1, 0.1, 0.12)

var _v
## NPC id → the "day|bucket" key of the last bark shown (one per bucket).
var _said: Dictionary = {}
## The key of the last stage beat shown (Stage.last_beat), "" = none yet.
var _beat := ""
var layer: Node2D


func _init(view) -> void:
	_v = view


## Adds bubbles for NPCs in range whose bark bucket changed since their last bark.
## Bubbles of NPCs that left the area go away. `db` null = no barks.
func update(gs: GameState, db: DataDb) -> void:
	_ensure_layer()
	if db == null or gs.combat.has_fight():
		_clear_all()
		return
	var here := {}
	var barks := Voice.on(db)
	var reach := int(Voice.rules(db)["bark_tiles"]) if barks else 0
	var day := gs.clock.day()
	var minute := gs.clock.minute()
	for id in gs.npcs.in_area(_v.area):
		var n: Dictionary = gs.npcs.npcs[id]
		var at := NpcRoster.pos_of(n)
		here[id] = true
		if not barks:
			continue
		var d := at - gs.player.pos()
		if bool(n.get("down", false)) or maxi(absi(d.x), absi(d.y)) > reach:
			continue
		var key := "%d|%d" % [day, Voice.bark_bucket(db, minute)]
		if _said.get(id, "") == key:
			_move(id, at)
			continue
		var text := Voice.bark(db, day, id, minute)
		if text == "":
			continue
		_said[id] = key
		_show(id, at, text)
	for b in layer.get_children():
		if not here.has(String(b.name)):
			layer.remove_child(b)
			b.queue_free()
	_beat_bubble(gs, db, here)


## Shows the stage's newest beat over its speaker, once (if the speaker is here).
func _beat_bubble(gs: GameState, db: DataDb, here: Dictionary) -> void:
	var beat := Stage.last_beat(gs, db)
	if beat.is_empty() or beat["key"] == _beat:
		return
	_beat = beat["key"]
	var npc: String = beat["npc"]
	if npc != "" and here.has(npc):
		_show(npc, NpcRoster.pos_of(gs.npcs.npcs[npc]), beat["line"])


## Ages and fades the bubbles (real time).
func tick(delta: float) -> void:
	if layer == null:
		return
	for b in layer.get_children():
		var age := float(b.get_meta("age", 0.0)) + delta
		b.set_meta("age", age)
		if age >= HOLD + FADE:
			layer.remove_child(b)
			b.queue_free()
		elif age > HOLD:
			b.modulate.a = 1.0 - (age - HOLD) / FADE


## The text of the bubble over `npc` now, or "".
func text_of(npc: String) -> String:
	if layer == null or not layer.has_node(npc):
		return ""
	return (layer.get_node(npc).get_node("Text") as Label).text


func _ensure_layer() -> void:
	if layer != null:
		return
	layer = Node2D.new()
	layer.name = "Bubbles"
	layer.z_index = 5
	_v.add_child(layer)


func _clear_all() -> void:
	for b in layer.get_children():
		layer.remove_child(b)
		b.queue_free()


func _move(id: String, at: Vector2i) -> void:
	if layer.has_node(id):
		(layer.get_node(id) as Node2D).position = ViewArt.cell_center(at)


func _show(id: String, at: Vector2i, text: String) -> void:
	if layer.has_node(id):
		var old := layer.get_node(id)
		layer.remove_child(old)
		old.queue_free()
	var bubble := Node2D.new()
	bubble.name = id
	bubble.position = ViewArt.cell_center(at)
	bubble.set_meta("age", 0.0)
	var label := Label.new()
	label.name = "Text"
	label.text = text
	label.add_theme_font_size_override("font_size", ViewArt.NAME_FONT_SIZE)
	label.add_theme_color_override("font_color", TEXT)
	var box := StyleBoxFlat.new()
	box.bg_color = BACK
	box.set_corner_radius_all(6)
	box.set_content_margin_all(4)
	label.add_theme_stylebox_override("normal", box)
	label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	label.scale = Vector2.ONE / ViewArt.TEXT_SCALE
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.add_child(label)
	var size := label.get_minimum_size() / ViewArt.TEXT_SCALE
	label.position = Vector2(-size.x / 2.0, -TOP - size.y)
	layer.add_child(bubble)
