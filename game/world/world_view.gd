## Draws the player's map from MapDb, the NPCs in it (with names) and
## the player. Placeholder art: one coloured 16×16 tile per tiles.json
## entry, made in code.
## Presentation only: reads GameState, never changes it (CLAUDE.md rule 1).
class_name WorldView
extends Node2D

const TILE := 16
const OBJECT_COLOR := Color("#e8c547")
const EXIT_COLOR := Color(1.0, 1.0, 0.7, 0.3)
const NOSE := 4
const NPC_COLOR := Color("#3b6fd1")
const NPC_NAME_SIZE := 7
## Names are drawn this many times larger, then scaled down, so they stay
## sharp under the camera zoom.
const TEXT_SCALE := 3

## Map id on screen now ("" = none).
var area := ""
## tile id → atlas coords.
var atlas: Dictionary = {}
## NPC id → name shown over its marker.
var npc_names: Dictionary = {}
var _maps: MapDb

@onready var tiles: TileMapLayer = $Tiles
@onready var marks: Node2D = $Marks
@onready var npcs: Node2D = $Npcs
@onready var player: Node2D = $Player
@onready var nose: ColorRect = $Player/Nose
@onready var camera: Camera2D = $Player/Camera


func setup(maps: MapDb, names: Dictionary = {}) -> void:
	_maps = maps
	npc_names = names
	atlas.clear()
	tiles.tile_set = make_tile_set(maps.tiles, atlas)
	area = ""


## Redraws the map if the player changed area, then moves the marker.
func refresh(gs: GameState) -> void:
	if _maps == null or not gs.player.is_placed():
		return
	var new_area := gs.player.area != area
	if new_area:
		_show_area(gs.player.area)
	_show_npcs(gs)
	player.position = cell_center(gs.player.pos())
	nose.position = Vector2(PlayerState.DIRS[gs.player.facing]) * NOSE - nose.size / 2.0
	if new_area:  # jump, do not glide across the new map
		camera.reset_smoothing()


static func cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell * TILE) + Vector2(TILE, TILE) / 2.0


## One atlas row, one tile per tiles.json entry (file order). Tiles you
## cannot walk on get a darker edge. Fills `atlas_out` with id → coords.
static func make_tile_set(tile_defs: Dictionary, atlas_out: Dictionary) -> TileSet:
	var ids := tile_defs.keys()
	var img := Image.create(TILE * maxi(ids.size(), 1), TILE, false, Image.FORMAT_RGBA8)
	for i in ids.size():
		var def: Dictionary = tile_defs[ids[i]]
		var color := Color.html(def["color"])
		var cell := Rect2i(i * TILE, 0, TILE, TILE)
		if def["walk"]:
			img.fill_rect(cell, color)
		else:
			img.fill_rect(cell, color.darkened(0.35))
			img.fill_rect(cell.grow(-2), color)
		atlas_out[ids[i]] = Vector2i(i, 0)
	var source := TileSetAtlasSource.new()
	source.texture = ImageTexture.create_from_image(img)
	source.texture_region_size = Vector2i(TILE, TILE)
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	ts.add_source(source, 0)
	for i in ids.size():
		source.create_tile(Vector2i(i, 0))
	return ts


func _show_area(id: String) -> void:
	area = id
	tiles.clear()
	var size := _maps.size(id)
	for y in size.y:
		for x in size.x:
			var cell := Vector2i(x, y)
			tiles.set_cell(cell, 0, atlas[_maps.tile_at(id, cell)])
	for child in marks.get_children():
		marks.remove_child(child)
		child.queue_free()
	var m: Dictionary = _maps.areas[id]
	for e: Dictionary in m["exits"]:
		var r := MapDb.rect_of(e["at"])
		_rect(Vector2(r.position * TILE), Vector2(r.size * TILE), EXIT_COLOR)
	for o: Dictionary in m["objects"]:
		var at := Vector2(int(o["at"][0]), int(o["at"][1])) * TILE
		_rect(at + Vector2(2, 2), Vector2(TILE - 4, TILE - 4), OBJECT_COLOR)
		var label := Label.new()
		label.text = String(o["name"]).left(1)
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_color", Color.BLACK)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marks.add_child(label)
		label.position = at + (Vector2(TILE, TILE) - label.get_minimum_size()) / 2.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = size.x * TILE
	camera.limit_bottom = size.y * TILE


## One marker per NPC in the area (named after the NPC id), with its
## name above it.
func _show_npcs(gs: GameState) -> void:
	for child in npcs.get_children():
		npcs.remove_child(child)
		child.queue_free()
	for id in gs.npcs.in_area(area):
		var marker := Node2D.new()
		marker.name = id
		marker.position = cell_center(NpcRoster.pos_of(gs.npcs.npcs[id]))
		var body := ColorRect.new()
		body.position = Vector2(-5, -5)
		body.size = Vector2(10, 10)
		body.color = NPC_COLOR
		body.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker.add_child(body)
		var label := Label.new()
		label.text = npc_names.get(id, id)
		label.add_theme_font_size_override("font_size", NPC_NAME_SIZE * TEXT_SCALE)
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
		label.add_theme_constant_override("outline_size", 6)
		label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		label.scale = Vector2.ONE / TEXT_SCALE
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker.add_child(label)
		var size := label.get_minimum_size() / TEXT_SCALE
		label.position = Vector2(-size.x / 2.0, -5 - size.y)
		npcs.add_child(marker)


func _rect(pos: Vector2, size: Vector2, color: Color) -> void:
	var r := ColorRect.new()
	r.position = pos
	r.size = size
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marks.add_child(r)
