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
## M13.T: a found trap is a small diamond on its tile (red while armed,
## grey once spent or disarmed); hidden traps are not drawn.
## M17.3 (ADR 0027): a CombatOverlay child draws the move range, a click's
## path and the hit chance. `replay` plays a command's turn log
## (CombatState.turns) one fighter at a time: the camera goes to the fighter,
## its marker walks its path and swings at each foe it struck (a flash and a
## number on a hit). main.gd then refreshes with `replayed`, so only falls
## and gone monsters play. `skip_replay` ends it at once.
## M26.1 (ADR 0041): the work is split into helpers this view makes and owns:
## ViewMap (ground, objects, signs, crowd), ViewMarkers (units, fairies,
## traps), ViewEffects (AnimDiff effects and the replay). ViewArt holds the
## static art helpers. The public names stay here and pass on.
## Presentation only: reads GameState, never changes it (CLAUDE.md rule 1).
class_name WorldView
extends Node2D

## The sound cues of one refresh, in order (M12).
signal sounds(cues: Array[String])
## A new map: the object loops on it (AmbiencePick.loops_on, M12.4). The
## Audio autoload places their players under `loop_spots`.
signal area_loops(loops: Array)
## A replay reached entry `index` of the turn log (main.gd shows its lines).
signal replay_step(index: int)
## A replay ended by itself (not by skip_replay).
signal replay_done

const TILE := ViewArt.TILE
const U := ViewArt.U
const OBJECT_ART_PATH := ViewArt.OBJECT_ART_PATH
const NAME_FONT_SIZE := ViewArt.NAME_FONT_SIZE
const TEXT_SCALE := ViewArt.TEXT_SCALE
const ANIM_FPS := ViewMap.ANIM_FPS
const STEP_TIME := ViewEffects.STEP_TIME
const NOSE := 4 * U
## M29.5: in a fight the camera sits this many screen pixels lower on the map.
const FIGHT_LIFT := 60.0
const HIDDEN_TILE := ViewMarkers.HIDDEN_TILE
const HOSTILE_EDGE := ViewMarkers.HOSTILE_EDGE
const FLEE_EDGE := ViewMarkers.FLEE_EDGE
const ALLY_EDGE := ViewMarkers.ALLY_EDGE
const BAR_LOW_FILL := ViewMarkers.BAR_LOW_FILL
const DOWN_ALPHA := ViewMarkers.DOWN_ALPHA
const FAIRY_BOB := ViewMarkers.FAIRY_BOB
const TRAP_ARMED := ViewMarkers.TRAP_ARMED
const HIT_TINT := ViewEffects.HIT_TINT
const HURT_YOU_COLOR := ViewEffects.HURT_YOU_COLOR
const LUNGE_TIME := ViewEffects.LUNGE_TIME
const GONE_TIME := ViewEffects.GONE_TIME

## Map id on screen now ("" = none).
var area := ""
## tile id → atlas coords.
var atlas: Dictionary = {}
## tile id → {"source": id, "cells": Array[Vector2i]} for tiles with art.
var sprites: Dictionary = {}
## Object kind → objects.json entry (see object_look).
var object_art: Dictionary = {}
## data/objects.json "signs" (M16.3): icon id -> region on the signs sheet.
var sign_table: Dictionary = {}
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
## The state last drawn (AnimDiff.snapshot).
var _last: Dictionary = {}
var _maps: MapDb
## The sound data (M12.1); setup loads data/audio.json when it is not set.
var audio: AudioDb
## The world flag that turns on the snow look ("" = never), and whether
## the tiles are drawn in winter colours now.
var _winter_flag := ""
var _winter := false
## The world flag that makes it rain ("" = never; M19.0, Rains).
var _rain_flag := ""
var _overlay_key := ""
## Day/night tint, fire light and snow (M11.5).
var atmosphere: Atmosphere
## Holds the object loop players (M12.4), in map pixels.
var loop_spots: Node2D
## Tiles that mix several edge pieces (thin water, one-cell strips), over the Edges layer.
var mixes: Node2D

@onready var tiles: TileMapLayer = $Tiles
@onready var edges: TileMapLayer = $Edges
@onready var marks: Node2D = $Marks
@onready var traps: Node2D = $Traps
@onready var npcs: Node2D = $Npcs
@onready var monsters: Node2D = $Monsters
@onready var fairies: Node2D = $Fairies
@onready var props: Node2D = $Props
@onready var fx: Node2D = $Fx
@onready var player: Node2D = $Player
@onready var body: ColorRect = $Player/Body
@onready var nose: ColorRect = $Player/Nose
@onready var camera: Camera2D = $Player/Camera
@onready var overlay: CombatOverlay = $CombatOverlay

var _map := ViewMap.new(self)
var _markers := ViewMarkers.new(self)
var _effects := ViewEffects.new(self)


func setup(maps: MapDb, names: Dictionary = {}, enemy_defs: Dictionary = {},
		max_hp: Dictionary = {}, winter_flag: String = "", races: Dictionary = {},
		rain_flag: String = "") -> void:
	_maps = maps
	npc_names = names
	npc_races = races
	enemies = enemy_defs
	npc_max_hp = max_hp
	_winter_flag = winter_flag
	_rain_flag = rain_flag
	_winter = false
	object_art = load_object_art()
	sign_table = SignArt.load_table()
	if audio == null:
		audio = AudioDb.load_file()
	if atmosphere == null:
		atmosphere = Atmosphere.new()
		atmosphere.tile = TILE
		add_child(atmosphere)
	if mixes == null:
		mixes = Node2D.new()
		mixes.name = "EdgeMixes"
		add_child(mixes)
		move_child(mixes, edges.get_index() + 1)
	if loop_spots == null:
		loop_spots = Node2D.new()
		loop_spots.name = "LoopSpots"
		add_child(loop_spots)
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
## `replayed` (M17.3): the command's turns were just replayed, so only the
## falls and gone monsters of AnimDiff still play.
func refresh(gs: GameState, db: DataDb = null, replayed: bool = false) -> void:
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
	atmosphere.set_time(gs.clock.minute(), winter, _rain_flag != "" and gs.flags.has(_rain_flag))
	_map.set_hour(gs.clock.minute() / 60)
	_map.update_sign_labels(gs.player.pos())
	_markers.show_all(gs)
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
	# M29.5: in a fight the view sits lower on the map, so the fighters stay
	# above the log strip at the bottom of the screen.
	var lift := FIGHT_LIFT / camera.zoom.y if gs.combat.has_fight() else 0.0
	if not is_equal_approx(camera.offset.y, lift):
		camera.offset = Vector2(0.0, lift)
	if new_area:  # jump, do not glide across the new map
		camera.reset_smoothing()
	var snap := AnimDiff.snapshot(gs, Stats.max_hp(gs, db) if db != null else 0)
	var changes: Array = [] if new_area else AnimDiff.events(_last, snap)
	if replayed:
		changes = changes.filter(func(e: Dictionary) -> bool:
			return e["type"] == AnimDiff.FALL or e["type"] == AnimDiff.GONE)
	_last = snap
	play(changes)
	cues.append_array(SoundCues.from_events(audio, changes, snap["units"]))
	if not cues.is_empty():
		sounds.emit(cues)


func _process(delta: float) -> void:
	_map.tick(delta)
	_markers.bob(delta)


func _show_area(id: String) -> void:
	area = id
	monster_facing.clear()
	_effects.clear()
	_map.show_area(id)


## Plays AnimDiff events on the markers drawn now (ViewEffects.play). The
## player's own step is played by refresh (the sprite glide).
func play(changes: Array) -> void:
	_effects.play(changes)


## The map cell under a point in world space (M17.3: the mouse).
func cell_at(global: Vector2) -> Vector2i:
	return Vector2i((to_local(global) / TILE).floor())


func is_replaying() -> bool:
	return _effects.replaying


## Plays the turn log `turns` (CombatState.turns) on the markers drawn now
## (M17.3, ViewEffects.replay). Emits replay_step(i) and replay_done.
func replay(turns: Array) -> void:
	await _effects.replay(turns)


## Ends a replay at once (a key or a click during it). No replay_done.
func skip_replay() -> void:
	_effects.skip_replay()


## The sheet id of enemy `type`: its "look" (M13.0: art borrowed from
## another enemy) or the type itself.
func monster_look(type: String) -> String:
	return String(enemies.get(type, {}).get("look", type))


# Static names other scripts and tests use. The code is in the helpers.

static func unit_of(fighter: String) -> String:
	return ViewEffects.unit_of(fighter)


static func sheet_path(sheet_name: String) -> String:
	return ViewArt.sheet_path(sheet_name)


static func load_object_art(path: String = OBJECT_ART_PATH) -> Dictionary:
	return ViewArt.load_object_art(path)


static func object_look(o: Dictionary, kinds: Dictionary, winter: bool = false) -> Dictionary:
	return ViewArt.object_look(o, kinds, winter)


static func cell_center(cell: Vector2i) -> Vector2:
	return ViewArt.cell_center(cell)


static func pick_cell(cells: Array, cell: Vector2i) -> Vector2i:
	return ViewArt.pick_cell(cells, cell)


static func sprite_def(def: Dictionary, winter: bool, key: String = "sprite") -> Dictionary:
	return ViewArt.sprite_def(def, winter, key)


static func make_tile_set(tile_defs: Dictionary, atlas_out: Dictionary, winter: bool = false,
		sprites_out: Dictionary = {}) -> TileSet:
	return ViewArt.make_tile_set(tile_defs, atlas_out, winter, sprites_out)


static func state_edge(state: String) -> Color:
	return ViewMarkers.state_edge(state)


static func labelled(gs: GameState, enemy_defs: Dictionary) -> Dictionary:
	return ViewMarkers.labelled(gs, enemy_defs)


static func monster_label(m: Dictionary, e: Dictionary) -> String:
	return ViewMarkers.monster_label(m, e)
