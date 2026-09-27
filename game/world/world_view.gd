## Draws the player's map from MapDb, the NPCs in it (with names), the
## monsters (with name and HP) and the player. Placeholder art: one
## coloured 16×16 tile per tiles.json entry, made in code. A hidden monster
## (a Rock Crab) looks like a rock tile and has no label.
## Big battles (M7.B, ADR 0013): every monster and every hurt NPC has a small
## HP bar; with more than LABEL_ALL_UP_TO monsters, only the most dangerous
## foe, the helpers and the LABEL_NEAREST foes nearest the player keep their
## label, and a label that would overlap another is left out (see
## labelled). A helper has a blue edge; a fallen NPC is faded, "(down)".
## Winter (M8.W): once the winter flag is set, tiles with a "winter_color"
## are drawn in it (the snow look); map overlays (the snow wall) redraw
## when they switch; Frost Fairies are small pale diamonds.
## Art (M11, ADR 0018): cells are 32 px. A tile with a "sprite" is drawn from
## game/assets/tiles/<sheet>.png (one of its cells, picked by position), and
## a "prop" (a tree, a rock) is drawn over it, y-sorted with the characters.
## The player and NPCs with a baked sheet are CharacterSprites; the player's
## sprite glides one cell per step. Anything with no art is drawn as before.
## Presentation only: reads GameState, never changes it (CLAUDE.md rule 1).
class_name WorldView
extends Node2D

const TILE := 32
## Old 16 px sizes are scaled by this.
const U := TILE / 16
const SHEET_PATH := "res://assets/tiles/%s.png"
## One step glide, the same as the held-key repeat in main.gd.
const STEP_TIME := 0.14
const OBJECT_COLOR := Color("#e8c547")
const EXIT_COLOR := Color(1.0, 1.0, 0.7, 0.3)
const NOSE := 4 * U
const NPC_COLOR := Color("#3b6fd1")
const NPC_NAME_SIZE := 10
## Names are drawn this many times larger, then scaled down, so they stay
## sharp under the camera zoom.
const TEXT_SCALE := 3
## A hidden monster is drawn as this tile.
const HIDDEN_TILE := "rock"
## Monster marker edge by state: hostile, fleeing, else calm.
const HOSTILE_EDGE := Color("#e03a3a")
const FLEE_EDGE := Color("#f0d040")
const ALLY_EDGE := Color("#4a90e2")
## HP bar under a marker: back, fill, and fill at or below BAR_LOW of max.
const BAR_BACK := Color(0.1, 0.1, 0.1, 0.85)
const BAR_FILL := Color("#5cc85c")
const BAR_LOW_FILL := Color("#e05050")
const BAR_LOW := 0.34
## Up to this many monsters on screen: all keep their labels.
const LABEL_ALL_UP_TO := 4
const LABEL_NEAREST := 3
## Two labels on the same row closer than this many tiles would overlap.
const LABEL_GAP := 3
const DOWN_ALPHA := 0.35
const CALM_EDGE := Color(0, 0, 0, 0.6)
## A dark ring between the edge and the body, so a green Goblin stands out on grass.
const RING := Color(0.08, 0.08, 0.08, 1)
const FAIRY_BODY := Color("#bfe8ff")
const FAIRY_EDGE := Color("#ffffff")

## Map id on screen now ("" = none).
var area := ""
## tile id → atlas coords.
var atlas: Dictionary = {}
## tile id → {"source": id, "cells": Array[Vector2i]} for tiles with art.
var sprites: Dictionary = {}
## The player's sprite (null = the red square).
var look: CharacterSprite
## NPC id → name shown over its marker.
var npc_names: Dictionary = {}
## Enemy type → enemies.json entry (name, color, hp).
var enemies: Dictionary = {}
## NPC id → max HP (NpcReact.stats), for the HP bars of hurt NPCs.
var npc_max_hp: Dictionary = {}
var _maps: MapDb
## The world flag that turns on the snow look ("" = never), and whether
## the tiles are drawn in winter colours now.
var _winter_flag := ""
var _winter := false
var _overlay_key := ""

@onready var tiles: TileMapLayer = $Tiles
@onready var marks: Node2D = $Marks
@onready var npcs: Node2D = $Npcs
@onready var monsters: Node2D = $Monsters
@onready var fairies: Node2D = $Fairies
@onready var props: Node2D = $Props
@onready var player: Node2D = $Player
@onready var body: ColorRect = $Player/Body
@onready var nose: ColorRect = $Player/Nose
@onready var camera: Camera2D = $Player/Camera


func setup(maps: MapDb, names: Dictionary = {}, enemy_defs: Dictionary = {},
		max_hp: Dictionary = {}, winter_flag: String = "") -> void:
	_maps = maps
	npc_names = names
	enemies = enemy_defs
	npc_max_hp = max_hp
	_winter_flag = winter_flag
	_winter = false
	atlas.clear()
	sprites.clear()
	tiles.tile_set = make_tile_set(maps.tiles, atlas, false, sprites)
	area = ""
	if look != null:
		player.remove_child(look)
		look.queue_free()
	look = CharacterSprite.make("player")
	if look != null:
		player.add_child(look)
	body.visible = look == null
	nose.visible = look == null


## Redraws the map if the player changed area, then moves the marker.
func refresh(gs: GameState) -> void:
	if _maps == null or not gs.player.is_placed():
		return
	_maps.sync_flags(gs.flags)  # the overlays are a cache shared by every game on this db
	var winter := _winter_flag != "" and gs.flags.has(_winter_flag)
	if winter != _winter:
		_winter = winter
		atlas.clear()
		sprites.clear()
		tiles.tile_set = make_tile_set(_maps.tiles, atlas, winter, sprites)
		area = ""
	if _maps.overlay_key != _overlay_key:
		_overlay_key = _maps.overlay_key
		area = ""
	var new_area := gs.player.area != area
	if new_area:
		_show_area(gs.player.area)
	_show_npcs(gs)
	_show_monsters(gs)
	_show_fairies(gs)
	var old := player.position
	player.position = cell_center(gs.player.pos())
	nose.position = Vector2(PlayerState.DIRS[gs.player.facing]) * NOSE - nose.size / 2.0
	if look != null:
		if not new_area and old.distance_to(player.position) == TILE:
			look.walk(gs.player.facing, old - player.position, STEP_TIME)
		elif new_area or old != player.position or not look.is_walking():
			look.finish()
			look.pose(gs.player.facing)
	if new_area:  # jump, do not glide across the new map
		camera.reset_smoothing()


static func cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell * TILE) + Vector2(TILE, TILE) / 2.0


## The art cell of a tile with more than one look, picked by map position
## (the same cell every time; no randomness).
static func pick_cell(cells: Array, cell: Vector2i) -> Vector2i:
	var h := absi((cell.x * 73856093) ^ (cell.y * 19349663))
	return cells[h % cells.size()]


## The sprite (or winter sprite) entry of a tile def, {} when none.
static func sprite_def(def: Dictionary, winter: bool, key: String = "sprite") -> Dictionary:
	if winter and def.has("winter_" + key):
		return def["winter_" + key]
	return def.get(key, {})


## One atlas row, one tile per tiles.json entry (file order). Tiles you
## cannot walk on get a darker edge. Fills `atlas_out` with id → coords.
## With `winter`, a tile's "winter_color" is used where it has one.
## Tiles with a sprite whose sheet exists also get an atlas source per sheet;
## `sprites_out` gets id → {"source", "cells"} for them.
static func make_tile_set(tile_defs: Dictionary, atlas_out: Dictionary, winter: bool = false,
		sprites_out: Dictionary = {}) -> TileSet:
	var ids := tile_defs.keys()
	var img := Image.create(TILE * maxi(ids.size(), 1), TILE, false, Image.FORMAT_RGBA8)
	for i in ids.size():
		var def: Dictionary = tile_defs[ids[i]]
		var color := Color.html(def["winter_color"] if winter and def.has("winter_color") else def["color"])
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
	var sheets := {}
	for id in ids:
		var sp := sprite_def(tile_defs[id], winter)
		if sp.is_empty() or not ResourceLoader.exists(SHEET_PATH % sp["sheet"]):
			continue
		if not sheets.has(sp["sheet"]):
			var s := TileSetAtlasSource.new()
			s.texture = load(SHEET_PATH % sp["sheet"])
			s.texture_region_size = Vector2i(TILE, TILE)
			sheets[sp["sheet"]] = ts.add_source(s)
		var src: TileSetAtlasSource = ts.get_source(sheets[sp["sheet"]])
		var cells: Array[Vector2i] = []
		for c: Array in sp["cells"]:
			var v := Vector2i(int(c[0]), int(c[1]))
			if not src.has_tile(v):
				src.create_tile(v)
			cells.append(v)
		sprites_out[id] = {"source": sheets[sp["sheet"]], "cells": cells}
	return ts


func _show_area(id: String) -> void:
	area = id
	tiles.clear()
	for child in props.get_children():
		props.remove_child(child)
		child.queue_free()
	var size := _maps.size(id)
	for y in size.y:
		for x in size.x:
			var cell := Vector2i(x, y)
			var t := _maps.tile_at(id, cell)
			if sprites.has(t):
				tiles.set_cell(cell, sprites[t]["source"], pick_cell(sprites[t]["cells"], cell))
			else:
				tiles.set_cell(cell, 0, atlas[t])
			_add_prop(t, cell)
	for child in marks.get_children():
		marks.remove_child(child)
		child.queue_free()
	var m: Dictionary = _maps.areas[id]
	for e: Dictionary in m["exits"]:
		var r := MapDb.rect_of(e["at"])
		_rect(Vector2(r.position * TILE), Vector2(r.size * TILE), EXIT_COLOR)
	for o: Dictionary in _maps.objects_on(id):
		var at := Vector2(int(o["at"][0]), int(o["at"][1])) * TILE
		_rect(at + Vector2(2, 2) * U, Vector2(TILE - 4 * U, TILE - 4 * U), OBJECT_COLOR)
		var label := Label.new()
		label.text = String(o["name"]).left(1)
		label.add_theme_font_size_override("font_size", 10 * U)
		label.add_theme_color_override("font_color", Color.BLACK)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marks.add_child(label)
		label.position = at + (Vector2(TILE, TILE) - label.get_minimum_size()) / 2.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = size.x * TILE
	camera.limit_bottom = size.y * TILE


## One marker per NPC in the area (named after the NPC id), with its
## name above it; a hurt NPC has an HP bar, a fallen one is faded.
func _show_npcs(gs: GameState) -> void:
	for child in npcs.get_children():
		npcs.remove_child(child)
		child.queue_free()
	for id in gs.npcs.in_area(area):
		var n: Dictionary = gs.npcs.npcs[id]
		var down := bool(n.get("down", false))
		var marker := Node2D.new()
		marker.name = id
		marker.position = cell_center(NpcRoster.pos_of(n))
		var sprite := CharacterSprite.make(id)
		if sprite != null:
			sprite.pose(String(n.get("facing", "s")), down)
			marker.add_child(sprite)
		else:
			var square := ColorRect.new()
			square.position = Vector2(-5, -5) * U
			square.size = Vector2(10, 10) * U
			square.color = NPC_COLOR
			if down:
				square.color.a = DOWN_ALPHA
			square.mouse_filter = Control.MOUSE_FILTER_IGNORE
			marker.add_child(square)
		var name_text := String(npc_names.get(id, id))
		_add_label(marker, name_text + " (down)" if down else name_text,
				CharacterSprite.HEAD if sprite != null else 5.0 * U)
		var most := int(npc_max_hp.get(id, 0))
		var now := int(n.get("hp", -1))
		if most > 0 and now >= 0:
			_bar(marker, float(now) / most)
		npcs.add_child(marker)


## One marker per monster in the area (named after the monster id): an
## edge by state, a dark ring, a body in the enemy colour, "Goblin 5/8"
## above it (see labelled) and an HP bar below. A hidden monster is a rock
## tile with no label.
func _show_monsters(gs: GameState) -> void:
	for child in monsters.get_children():
		monsters.remove_child(child)
		child.queue_free()
	var named := labelled(gs, enemies)
	for id in gs.combat.ids():
		var m: Dictionary = gs.combat.monsters[id]
		if m["area"] != area:
			continue
		var e: Dictionary = enemies.get(m["type"], {})
		var marker := Node2D.new()
		marker.name = id
		marker.position = cell_center(CombatState.pos_of(m))
		if m["state"] == CombatState.HIDDEN:
			var rock := Color.html(_maps.tiles.get(HIDDEN_TILE, e).get("color", "#7a7468"))
			_square(marker, TILE / 2.0, rock.darkened(0.35))
			_square(marker, TILE / 2.0 - 2 * U, rock)
		else:
			var edge := CALM_EDGE
			if m["state"] == CombatState.HOSTILE:
				edge = HOSTILE_EDGE
			elif m["state"] == CombatState.FLEE:
				edge = FLEE_EDGE
			elif m["state"] == CombatState.ALLY:
				edge = ALLY_EDGE
			_square(marker, 6 * U, edge)
			_square(marker, 5 * U, RING)
			_square(marker, 4 * U, Color.html(e.get("color", "#ff00ff")))
			if named.has(id):
				_add_label(marker, monster_label(m, e))
			_bar(marker, float(m["hp"]) / maxi(int(e.get("hp", m["hp"])), 1))
		monsters.add_child(marker)


## A small pale diamond per Frost Fairy in the player's area (no label).
func _show_fairies(gs: GameState) -> void:
	for child in fairies.get_children():
		fairies.remove_child(child)
		child.queue_free()
	if gs.winter.area != area:
		return
	for id in gs.winter.ids():
		var marker := Node2D.new()
		marker.name = id
		marker.position = cell_center(WinterState.pos_of(gs.winter.fairies[id]))
		marker.rotation = PI / 4.0
		_square(marker, 3 * U, FAIRY_EDGE)
		_square(marker, 2 * U, FAIRY_BODY)
		fairies.add_child(marker)


## Ids of the monsters in the player's area that keep their label. In
## order: the most dangerous foe (lowest id on a tie), the helpers, then the
## foes nearest the player (king moves, then id; with more than
## LABEL_ALL_UP_TO seen monsters, at most LABEL_NEAREST of them). A label is
## left out if it would overlap one already shown: an NPC's name or an
## earlier monster label on the same row within LABEL_GAP tiles.
static func labelled(gs: GameState, enemy_defs: Dictionary) -> Dictionary:
	var seen: Array[String] = []
	for id in gs.combat.ids():
		var m: Dictionary = gs.combat.monsters[id]
		if m["area"] == gs.player.area and m["state"] != CombatState.HIDDEN:
			seen.append(id)
	var foes: Array[String] = []
	var helpers: Array[String] = []
	var top := ""
	var top_danger := 0.0
	for id in seen:
		var m: Dictionary = gs.combat.monsters[id]
		if m["state"] == CombatState.ALLY:
			helpers.append(id)
			continue
		var d := float(enemy_defs.get(m["type"], {}).get("danger", 0.0))
		if top == "" or d > top_danger:
			top = id
			top_danger = d
		foes.append(id)
	var you := gs.player.pos()
	foes.erase(top)
	foes.sort_custom(func(a: String, b: String) -> bool:
		var da := _king(you, CombatState.pos_of(gs.combat.monsters[a]))
		var dbb := _king(you, CombatState.pos_of(gs.combat.monsters[b]))
		return da < dbb or (da == dbb and a.substr(1).to_int() < b.substr(1).to_int()))
	var shown: Array[Vector2i] = []
	for nid in gs.npcs.in_area(gs.player.area):
		shown.append(NpcRoster.pos_of(gs.npcs.npcs[nid]))
	var out := {}
	var order: Array[String] = []
	if top != "":
		order.append(top)
	order.append_array(helpers)
	var cap := foes.size() if seen.size() <= LABEL_ALL_UP_TO else LABEL_NEAREST
	var plain := 0
	for id in order + foes:
		var is_plain := id != top and not helpers.has(id)
		if is_plain and plain >= cap:
			break
		var at := CombatState.pos_of(gs.combat.monsters[id])
		if shown.any(func(p: Vector2i) -> bool: return p.y == at.y and absi(p.x - at.x) <= LABEL_GAP):
			continue
		shown.append(at)
		out[id] = true
		if is_plain:
			plain += 1
	return out


static func _king(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


## A small HP bar (share 0..1) under a marker.
func _bar(marker: Node2D, share: float) -> void:
	share = clampf(share, 0.0, 1.0)
	var back := ColorRect.new()
	back.position = Vector2(-6, 6) * U
	back.size = Vector2(12, 2) * U
	back.color = BAR_BACK
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.add_child(back)
	var fill := ColorRect.new()
	fill.position = Vector2(-6, 6) * U
	fill.size = Vector2(12 * share, 2) * U
	fill.color = BAR_LOW_FILL if share <= BAR_LOW else BAR_FILL
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.add_child(fill)


## "Goblin 5/8": name, HP now / max HP.
static func monster_label(m: Dictionary, e: Dictionary) -> String:
	return "%s %d/%d" % [e.get("name", m["type"]), int(m["hp"]), int(e.get("hp", m["hp"]))]


## A square of half-width `half` centred on the marker.
func _square(marker: Node2D, half: float, color: Color) -> void:
	var r := ColorRect.new()
	r.position = Vector2(-half, -half)
	r.size = Vector2(half, half) * 2.0
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.add_child(r)


## A small sharp name label centred above a marker, its bottom `top` px
## above the marker's centre.
func _add_label(marker: Node2D, text: String, top: float = 5.0 * U) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", NPC_NAME_SIZE * TEXT_SCALE)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("outline_size", 6)
	label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	label.scale = Vector2.ONE / TEXT_SCALE
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.add_child(label)
	var size := label.get_minimum_size() / TEXT_SCALE
	label.position = Vector2(-size.x / 2.0, -top - size.y)


## A tile's prop (a tree, a rock) on `cell`: a region of its sheet,
## bottom-centred on the cell, in the y-sorted Props layer.
func _add_prop(tile: String, cell: Vector2i) -> void:
	var def: Dictionary = _maps.tiles.get(tile, {})
	var p := sprite_def(def, _winter, "prop")
	if p.is_empty() or not ResourceLoader.exists(SHEET_PATH % p["sheet"]):
		return
	var r: Array = p["region"]
	var size := Vector2(int(r[2]), int(r[3])) * TILE
	var s := Sprite2D.new()
	s.texture = load(SHEET_PATH % p["sheet"])
	s.region_enabled = true
	s.region_rect = Rect2(Vector2(int(r[0]), int(r[1])) * TILE, size)
	s.centered = false
	s.offset = Vector2(-size.x / 2.0, TILE / 2.0 - size.y)
	s.position = cell_center(cell)
	props.add_child(s)


func _rect(pos: Vector2, size: Vector2, color: Color) -> void:
	var r := ColorRect.new()
	r.position = pos
	r.size = size
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marks.add_child(r)
