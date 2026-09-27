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
## M11.1: the ground comes from GroundArt (soft edges between terrains in the
## Edges layer), and a map object with a "kind" is drawn from
## data/objects.json (a "frames" object is animated).
## M11.3: after each refresh the view compares the new state with the last
## one (AnimDiff) and plays the changes: NPCs and monsters glide one step
## (NPC sprites walk), a hit flashes red and shows a damage number (Fx
## layer), a fallen NPC falls over, a gone monster fades out, the player and
## monsters swing (a sprite attack, a square lunges). Frost Fairies bob.
## Nothing waits for these: a new command draws the new state at once.
## M11.4: a monster whose type has a sheet is a CharacterSprite with a ring
## in its state colour under its feet (a gone one falls and fades); a
## hidden Rock Crab is the rock prop. Types with no sheet stay squares.
## M11.5: an Atmosphere child tints the map by the clock (a warm room light
## indoors), lights objects whose kind has "light" in objects.json and lets
## snow fall outdoors in winter.
## M12 (ADR 0019): each refresh emits `sounds` with the sound cues of the
## change (SoundCues): the player's footstep and the AnimDiff hits, falls,
## swings and gone monsters (with monster voices, M12.2). main.gd
## sends them to the Audio autoload, so the view needs no audio nodes.
## Presentation only: reads GameState, never changes it (CLAUDE.md rule 1).
class_name WorldView
extends Node2D

## The sound cues of one refresh, in order (M12).
signal sounds(cues: Array[String])

const TILE := 32
## Old 16 px sizes are scaled by this.
const U := TILE / 16
const SHEET_PATH := "res://assets/tiles/%s.png"
const OBJECT_SHEET_PATH := "res://assets/objects/%s.png"
const OBJECT_ART_PATH := "res://data/objects.json"
## Frames per second of animated objects (a fire).
const ANIM_FPS := 6.0
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
## Frost Fairies float up and down this many px, this fast (radians/s).
const FAIRY_BOB := 1.5 * U
const FAIRY_BOB_SPEED := 4.0
## A hit: the unit is tinted this colour, back to normal in FLASH_TIME.
const HIT_TINT := Color(1.0, 0.25, 0.25)
const FLASH_TIME := 0.25
## Damage numbers rise NUMBER_RISE px and fade in NUMBER_TIME seconds.
const NUMBER_TIME := 0.8
const NUMBER_RISE := 8.0 * U
const HURT_YOU_COLOR := Color("#ff5a5a")
const HURT_OTHER_COLOR := Color("#fff2a8")
## A square's swing: it lunges this far toward the target and back.
const LUNGE := 3.0 * U
const LUNGE_TIME := 0.2
## A gone monster fades out in this time.
const GONE_TIME := 0.35
## The ring under a monster sprite's feet: half-size, px below the cell
## centre, points, and how strong its state colour shows.
const FOOT_RING := Vector2(11, 4)
const FOOT_RING_Y := 11.0
const FOOT_RING_POINTS := 16
const FOOT_RING_ALPHA := 0.7

## Map id on screen now ("" = none).
var area := ""
## tile id → atlas coords.
var atlas: Dictionary = {}
## tile id → {"source": id, "cells": Array[Vector2i]} for tiles with art.
var sprites: Dictionary = {}
## Object kind → objects.json entry (see object_look).
var object_art: Dictionary = {}
## The player's sprite (null = the red square).
var look: CharacterSprite
## NPC id → name shown over its marker.
var npc_names: Dictionary = {}
## NPC id → race (canon npcs.json), for the generic look of an NPC with
## no own sheet (CharacterSprite.look_for).
var npc_races: Dictionary = {}
## Enemy type → enemies.json entry (name, color, hp).
var enemies: Dictionary = {}
## NPC id → max HP (NpcReact.stats), for the HP bars of hurt NPCs.
var npc_max_hp: Dictionary = {}
## Monster id → facing (n, s, e, w) from its last step or swing (the
## monster sprites stand this way).
var monster_facing: Dictionary = {}
## The state last drawn (AnimDiff.snapshot), and the walk-cycle half of each
## NPC (their markers are made anew each refresh).
var _last: Dictionary = {}
var _halves: Dictionary = {}
var _maps: MapDb
## The sound data (M12.1); setup loads data/audio.json when it is not set.
var audio: AudioDb
## The world flag that turns on the snow look ("" = never), and whether
## the tiles are drawn in winter colours now.
var _winter_flag := ""
var _winter := false
var _overlay_key := ""
## Animated object sprites on the map now, and the animation clock.
var _animated: Array[Sprite2D] = []
var _anim_time := 0.0
## Day/night tint, fire light and snow (M11.5).
var atmosphere: Atmosphere

@onready var tiles: TileMapLayer = $Tiles
@onready var edges: TileMapLayer = $Edges
@onready var marks: Node2D = $Marks
@onready var npcs: Node2D = $Npcs
@onready var monsters: Node2D = $Monsters
@onready var fairies: Node2D = $Fairies
@onready var props: Node2D = $Props
@onready var fx: Node2D = $Fx
@onready var player: Node2D = $Player
@onready var body: ColorRect = $Player/Body
@onready var nose: ColorRect = $Player/Nose
@onready var camera: Camera2D = $Player/Camera


func setup(maps: MapDb, names: Dictionary = {}, enemy_defs: Dictionary = {},
		max_hp: Dictionary = {}, winter_flag: String = "", races: Dictionary = {}) -> void:
	_maps = maps
	npc_names = names
	npc_races = races
	enemies = enemy_defs
	npc_max_hp = max_hp
	_winter_flag = winter_flag
	_winter = false
	object_art = load_object_art()
	if audio == null:
		audio = AudioDb.load_file()
	if atmosphere == null:
		atmosphere = Atmosphere.new()
		atmosphere.tile = TILE
		add_child(atmosphere)
	atlas.clear()
	sprites.clear()
	tiles.tile_set = make_tile_set(maps.tiles, atlas, false, sprites)
	edges.tile_set = tiles.tile_set
	area = ""
	if look != null:
		player.remove_child(look)
		look.queue_free()
	look = CharacterSprite.make("player")
	if look != null:
		player.add_child(look)
	body.visible = look == null
	nose.visible = look == null


## Redraws the map if the player changed area, then moves the marker and
## plays what changed since the last refresh. `db` (optional) gives the
## player's max HP, for a damage number when they were at full HP.
func refresh(gs: GameState, db: DataDb = null) -> void:
	if _maps == null or not gs.player.is_placed():
		return
	_maps.sync_flags(gs.flags)  # the overlays are a cache shared by every game on this db
	var winter := _winter_flag != "" and gs.flags.has(_winter_flag)
	if winter != _winter:
		_winter = winter
		atlas.clear()
		sprites.clear()
		tiles.tile_set = make_tile_set(_maps.tiles, atlas, winter, sprites)
		edges.tile_set = tiles.tile_set
		area = ""
	if _maps.overlay_key != _overlay_key:
		_overlay_key = _maps.overlay_key
		area = ""
	var new_area := gs.player.area != area
	if new_area:
		_show_area(gs.player.area)
	atmosphere.set_time(gs.clock.minute(), winter)
	_show_npcs(gs)
	_show_monsters(gs)
	_show_fairies(gs)
	var old := player.position
	player.position = cell_center(gs.player.pos())
	var cues: Array[String] = []
	if not new_area and old.distance_to(player.position) == TILE:
		var tile := _maps.tile_at(area, gs.player.pos())
		var step := SoundCues.footstep(audio, tile, _maps.tiles.get(tile, {}),
				winter and not _maps.is_indoor(area))
		if step != "":
			cues.append(step)
	nose.position = Vector2(PlayerState.DIRS[gs.player.facing]) * NOSE - nose.size / 2.0
	if look != null:
		if not new_area and old.distance_to(player.position) == TILE:
			look.walk(gs.player.facing, old - player.position, STEP_TIME)
		elif new_area or old != player.position or not look.is_walking():
			look.finish()
			look.pose(gs.player.facing)
	if new_area:  # jump, do not glide across the new map
		camera.reset_smoothing()
	var snap := AnimDiff.snapshot(gs, Stats.max_hp(gs, db) if db != null else 0)
	var changes: Array = [] if new_area else AnimDiff.events(_last, snap)
	_last = snap
	play(changes)
	cues.append_array(SoundCues.from_events(audio, changes, snap["units"]))
	if not cues.is_empty():
		sounds.emit(cues)


func _process(delta: float) -> void:
	if _animated.is_empty() and fairies.get_child_count() == 0:
		return
	_anim_time += delta
	var step := int(_anim_time * ANIM_FPS)
	for s in _animated:
		var n := int(s.get_meta("frames"))
		s.region_rect.position.x = float(s.get_meta("x0")) + (step % n) * s.region_rect.size.x
	for f in fairies.get_children():
		var base: Vector2 = f.get_meta("base")
		f.position = base + Vector2(0, sin(_anim_time * FAIRY_BOB_SPEED + float(f.get_meta("phase"))) * FAIRY_BOB)


## Plays AnimDiff events on the markers drawn now. The player's own step is
## played by refresh (the sprite glide).
func play(changes: Array) -> void:
	for e: Dictionary in changes:
		var id := String(e["id"])
		var node := _unit_node(id)
		match e["type"]:
			AnimDiff.MOVE:
				if node != null and id != AnimDiff.PLAYER:
					_glide(node, id, Vector2(e["from"] - e["to"]) * TILE, e["dir"])
				if _is_monster(id):
					monster_facing[id] = e["dir"]
			AnimDiff.HIT:
				if node != null:
					_flash(node)
					_number(node.position, int(e["amount"]), id == AnimDiff.PLAYER)
			AnimDiff.FALL:
				var lying := _sprite_of(node)
				if lying != null:
					lying.fall()
			AnimDiff.GONE:
				_fade_out(e["cell"], String(e["monster_type"]), String(monster_facing.get(id, "s")))
			AnimDiff.SWING:
				if id != AnimDiff.PLAYER:
					monster_facing[id] = e["dir"]
				var swinging := _sprite_of(node)
				if swinging != null:
					swinging.attack(e["dir"])
				elif node != null:
					_lunge(node, e["dir"])


## The marker of a unit: the player, an NPC or a monster (null = none).
func _unit_node(id: String) -> Node2D:
	if id == AnimDiff.PLAYER:
		return player
	var n := npcs.get_node_or_null(NodePath(id)) as Node2D
	return n if n != null else monsters.get_node_or_null(NodePath(id)) as Node2D


static func _is_monster(id: String) -> bool:
	return id.begins_with("m") and id.substr(1).is_valid_int()


## The CharacterSprite of a marker, or null (a square).
func _sprite_of(node: Node2D) -> CharacterSprite:
	if node == player:
		return look
	if node == null:
		return null
	for c in node.get_children():
		if c is CharacterSprite:
			return c
	return null


## A marker glides one step: its sprite walks from `from` (old cell minus new
## cell, px); its squares, label and bar slide.
func _glide(node: Node2D, id: String, from: Vector2, dir: String) -> void:
	var t: Tween = null
	for c in node.get_children():
		if c is CharacterSprite:
			var s: CharacterSprite = c
			s.half = int(_halves.get(id, 0))
			s.walk(dir, from, STEP_TIME)
			_halves[id] = s.half
		elif c is Control or c is Node2D:
			if t == null:
				t = node.create_tween().set_parallel(true)
			var base: Vector2 = c.position
			c.position = base + from
			t.tween_property(c, "position", base, STEP_TIME)


## A square marker lunges toward `dir` and back.
func _lunge(node: Node2D, dir: String) -> void:
	var to := Vector2(PlayerState.DIRS.get(dir, Vector2i.ZERO)) * LUNGE
	var t := node.create_tween().set_parallel(true)
	for c in node.get_children():
		if (c is Control or c is Node2D) and not c is Camera2D:
			var base: Vector2 = c.position
			t.tween_property(c, "position", base + to, LUNGE_TIME / 2.0)
			t.tween_property(c, "position", base, LUNGE_TIME / 2.0).set_delay(LUNGE_TIME / 2.0)


## A red flash on a hit unit (its sprite, else the whole marker).
func _flash(node: Node2D) -> void:
	var item: CanvasItem = _sprite_of(node)
	if item == null:
		item = node if node != player else body
	item.modulate = HIT_TINT
	item.create_tween().tween_property(item, "modulate", Color.WHITE, FLASH_TIME)


## "-3" over a unit at `at`; it rises and fades (red when you are hurt).
func _number(at: Vector2, amount: int, you: bool) -> void:
	var label := Label.new()
	label.text = "-%d" % amount
	label.add_theme_font_size_override("font_size", NPC_NAME_SIZE * TEXT_SCALE)
	label.add_theme_color_override("font_color", HURT_YOU_COLOR if you else HURT_OTHER_COLOR)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 8)
	label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	label.scale = Vector2.ONE / TEXT_SCALE
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx.add_child(label)
	var size := label.get_minimum_size() / TEXT_SCALE
	label.position = at + Vector2(-size.x / 2.0, -CharacterSprite.HEAD - size.y)
	var t := label.create_tween().set_parallel(true)
	t.tween_property(label, "position:y", label.position.y - NUMBER_RISE, NUMBER_TIME)
	t.tween_property(label, "modulate:a", 0.0, NUMBER_TIME).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(label.queue_free)


## A gone monster on its old cell: its sprite falls (the hurt frames) and
## fades; with no sheet, a copy of its square shrinks and fades.
func _fade_out(cell: Vector2i, type: String, dir: String = "s") -> void:
	var ghost := Node2D.new()
	ghost.name = "gone"
	ghost.position = cell_center(cell)
	var sprite := CharacterSprite.make(type)
	if sprite != null:
		sprite.pose(dir)
		ghost.add_child(sprite)
	else:
		_square(ghost, 5 * U, RING)
		_square(ghost, 4 * U, Color.html(enemies.get(type, {}).get("color", "#ff00ff")))
	fx.add_child(ghost)
	var t := ghost.create_tween()
	if sprite != null:
		sprite.fall(CharacterSprite.FALL_TIME)
		t.tween_interval(CharacterSprite.FALL_TIME)
		t.tween_property(ghost, "modulate:a", 0.0, GONE_TIME)
	else:
		t.set_parallel(true)
		t.tween_property(ghost, "scale", Vector2(0.3, 0.3), GONE_TIME)
		t.tween_property(ghost, "modulate:a", 0.0, GONE_TIME)
		t = t.chain()
	t.tween_callback(ghost.queue_free)


## The file of an art sheet: game/assets/tiles/<name>.png, else
## game/assets/objects/<name>.png; "" when neither exists.
static func sheet_path(sheet_name: String) -> String:
	if sheet_name == "":
		return ""
	for f: String in [SHEET_PATH, OBJECT_SHEET_PATH]:
		if ResourceLoader.exists(f % sheet_name):
			return f % sheet_name
	return ""


## data/objects.json "kinds" ({} when the file is missing or broken).
static func load_object_art(path: String = OBJECT_ART_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not d is Dictionary or not (d as Dictionary).get("kinds", {}) is Dictionary:
		return {}
	return d["kinds"]


## The art of a map object: {"sheet", "region": Rect2 (pixels, frame 0),
## "frames"}, or {} when its kind has no art (it is drawn as a square).
static func object_look(o: Dictionary, kinds: Dictionary, winter: bool = false) -> Dictionary:
	var art: Variant = kinds.get(String(o.get("kind", "")), {})
	if not art is Dictionary or sheet_path(String(art.get("sheet", ""))) == "":
		return {}
	var r: Variant = art["winter_region"] if winter and art.has("winter_region") else art.get("region")
	if not r is Array or (r as Array).size() != 4:
		return {}
	return {"sheet": String(art["sheet"]), "region": Rect2(r[0], r[1], r[2], r[3]),
		"frames": maxi(int(art.get("frames", 1)), 1)}


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
		if sp.is_empty() or sheet_path(String(sp["sheet"])) == "":
			continue
		if not sheets.has(sp["sheet"]):
			var s := TileSetAtlasSource.new()
			s.texture = load(sheet_path(String(sp["sheet"])))
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
	edges.clear()
	_animated.clear()
	monster_facing.clear()
	_halves.clear()
	for child in fx.get_children():
		fx.remove_child(child)
		child.queue_free()
	for child in props.get_children():
		props.remove_child(child)
		child.queue_free()
	var size := _maps.size(id)
	var ground := GroundArt.plan(_maps, id, _winter)
	for y in size.y:
		for x in size.x:
			var cell := Vector2i(x, y)
			var t := _maps.tile_at(id, cell)
			var art: Dictionary = ground.get(cell, {})
			if art.is_empty() or not _set_art(tiles, cell, art["base"]):
				tiles.set_cell(cell, 0, atlas[t])
			if art.has("over"):
				_set_art(edges, cell, art["over"])
			_add_prop(t, cell)
	for child in marks.get_children():
		marks.remove_child(child)
		child.queue_free()
	var m: Dictionary = _maps.areas[id]
	for e: Dictionary in m["exits"]:
		var r := MapDb.rect_of(e["at"])
		_rect(Vector2(r.position * TILE), Vector2(r.size * TILE), EXIT_COLOR)
	var light_sources: Array = []
	for o: Dictionary in _maps.objects_on(id):
		var cell := Vector2i(int(o["at"][0]), int(o["at"][1]))
		var light := Atmosphere.light_of(object_art.get(String(o.get("kind", "")), {}))
		if not light.is_empty():
			light_sources.append({"cell": cell, "light": light})
		var look_art := object_look(o, object_art, _winter)
		if not look_art.is_empty():
			_add_sprite(look_art["sheet"], look_art["region"], cell, look_art["frames"])
			continue
		var at := Vector2(cell * TILE)
		_rect(at + Vector2(2, 2) * U, Vector2(TILE - 4 * U, TILE - 4 * U), OBJECT_COLOR)
		var label := Label.new()
		label.text = String(o["name"]).left(1)
		label.add_theme_font_size_override("font_size", 10 * U)
		label.add_theme_color_override("font_color", Color.BLACK)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marks.add_child(label)
		label.position = at + (Vector2(TILE, TILE) - label.get_minimum_size()) / 2.0
	atmosphere.show_area(_maps.is_indoor(id), light_sources)
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
		var sprite := CharacterSprite.make(CharacterSprite.look_for(id, String(npc_races.get(id, ""))))
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


## One marker per monster in the area (named after the monster id). With a
## sheet for its type (M11.4): a foot ring in the state colour, the sprite
## (facing its last step or swing), "Goblin 5/8" above the head (see
## labelled) and an HP bar below. With no sheet: an edge by state, a dark
## ring, a body in the enemy colour, the label and the bar. A hidden monster
## is the rock tile's prop (or a rock-coloured square) with no label.
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
			var prop := _tile_prop(HIDDEN_TILE)
			if prop != null:
				marker.add_child(prop)
			else:
				var rock := Color.html(_maps.tiles.get(HIDDEN_TILE, e).get("color", "#7a7468"))
				_square(marker, TILE / 2.0, rock.darkened(0.35))
				_square(marker, TILE / 2.0 - 2 * U, rock)
			monsters.add_child(marker)
			continue
		var edge := state_edge(String(m["state"]))
		var sprite := CharacterSprite.make(String(m["type"]))
		if sprite != null:
			_foot_ring(marker, edge)
			sprite.pose(String(monster_facing.get(id, "s")))
			marker.add_child(sprite)
		else:
			_square(marker, 6 * U, edge)
			_square(marker, 5 * U, RING)
			_square(marker, 4 * U, Color.html(e.get("color", "#ff00ff")))
		if named.has(id):
			_add_label(marker, monster_label(m, e), CharacterSprite.HEAD if sprite != null else 5.0 * U)
		_bar(marker, float(m["hp"]) / maxi(int(e.get("hp", m["hp"])), 1))
		monsters.add_child(marker)


## The marker edge colour of a monster state: hostile, fleeing, ally, else calm.
static func state_edge(state: String) -> Color:
	match state:
		CombatState.HOSTILE:
			return HOSTILE_EDGE
		CombatState.FLEE:
			return FLEE_EDGE
		CombatState.ALLY:
			return ALLY_EDGE
	return CALM_EDGE


## A flat ring under a monster sprite's feet in its state colour.
func _foot_ring(marker: Node2D, color: Color) -> void:
	var ring := Polygon2D.new()
	ring.name = "Ring"
	var pts := PackedVector2Array()
	for i in FOOT_RING_POINTS:
		var a := TAU * i / FOOT_RING_POINTS
		pts.append(Vector2(cos(a) * FOOT_RING.x, sin(a) * FOOT_RING.y))
	ring.polygon = pts
	ring.color = Color(color, maxf(color.a, 0.35) * FOOT_RING_ALPHA)
	ring.position = Vector2(0, FOOT_RING_Y)
	marker.add_child(ring)


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
		marker.set_meta("base", marker.position)
		marker.set_meta("phase", float(id.hash() % 628) / 100.0)
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


## A tile's prop (a tree, a rock) on `cell`: a region of its sheet (in
## cells), bottom-centred on the cell, in the y-sorted Props layer.
func _add_prop(tile: String, cell: Vector2i) -> void:
	var s := _tile_prop(tile)
	if s != null:
		s.position = cell_center(cell)
		props.add_child(s)


## A new sprite of a tile's prop, bottom-centred on (0, 0); null when the
## tile has no prop art.
func _tile_prop(tile: String) -> Sprite2D:
	var def: Dictionary = _maps.tiles.get(tile, {})
	var p := sprite_def(def, _winter, "prop")
	if p.is_empty() or sheet_path(String(p["sheet"])) == "":
		return null
	var r: Array = p["region"]
	return _region_sprite(p["sheet"], Rect2(Vector2(int(r[0]), int(r[1])) * TILE,
			Vector2(int(r[2]), int(r[3])) * TILE))


## A region (pixels) of a sheet, bottom-centred on `cell`, in the y-sorted
## Props layer. With `frames` > 1 it is animated (the frames follow to the right).
func _add_sprite(sheet: String, region: Rect2, cell: Vector2i, frames: int = 1) -> Sprite2D:
	var s := _region_sprite(sheet, region)
	s.position = cell_center(cell)
	props.add_child(s)
	if frames > 1:
		s.set_meta("frames", frames)
		s.set_meta("x0", region.position.x)
		_animated.append(s)
	return s


## A sprite of a region (pixels) of a sheet, bottom-centred on a cell whose
## centre is the sprite's position.
static func _region_sprite(sheet: String, region: Rect2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load(sheet_path(sheet))
	s.region_enabled = true
	s.region_rect = region
	s.centered = false
	s.offset = Vector2(-region.size.x / 2.0, TILE / 2.0 - region.size.y)
	return s


## Draws `art` ([sheet, cell of the sheet]) on `cell` of `layer`; false when
## the sheet or its cell is missing (the caller draws the colour square).
func _set_art(layer: TileMapLayer, cell: Vector2i, art: Array) -> bool:
	var path := sheet_path(String(art[0]))
	if path == "":
		return false
	var ts := tiles.tile_set
	var id := -1
	for i in ts.get_source_count():
		var sid := ts.get_source_id(i)
		var src := ts.get_source(sid) as TileSetAtlasSource
		if src != null and src.texture != null and src.texture.resource_path == path:
			id = sid
			break
	if id < 0:
		var s := TileSetAtlasSource.new()
		s.texture = load(path)
		s.texture_region_size = Vector2i(TILE, TILE)
		id = ts.add_source(s)
	var atlas_src: TileSetAtlasSource = ts.get_source(id)
	var c: Vector2i = art[1]
	var cells := atlas_src.texture.get_size() / TILE
	if c.x < 0 or c.y < 0 or c.x >= int(cells.x) or c.y >= int(cells.y):
		return false
	if not atlas_src.has_tile(c):
		atlas_src.create_tile(c)
	layer.set_cell(cell, id, c)
	return true


func _rect(pos: Vector2, size: Vector2, color: Color) -> void:
	var r := ColorRect.new()
	r.position = pos
	r.size = size
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marks.add_child(r)
