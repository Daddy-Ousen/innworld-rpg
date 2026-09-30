## The combat screen's marks on the map (M17.3, ADR 0027): the tiles the
## player can walk to this turn (exit tiles, where a step flees, in yellow),
## the path a click would walk, a red frame on the foe it would hit with the
## hit chance over it, and a ring under the fighter whose turn is shown.
## M17.4: gold frames on the foes an armed Skill can hit.
## M17.5: orange tiles for what an armed spell would hit (preview), and the tiles a
## cast spell just hit, while its replay plays (burst).
## Draws only; WorldView owns it and main.gd feeds it.
## Presentation only: never changes GameState (CLAUDE.md rule 1).
class_name CombatOverlay
extends Node2D

const REACH := Color(0.35, 0.6, 1.0, 0.22)
const REACH_EDGE := Color(0.55, 0.75, 1.0, 0.45)
const EXIT := Color(1.0, 0.85, 0.3, 0.35)
const PATH := Color(1.0, 1.0, 1.0, 0.85)
const TARGET := Color("#e03a3a")
const ACTIVE := Color(1.0, 0.95, 0.5, 0.9)
const SKILL := Color("#f0c850")
const SPELL := Color(1.0, 0.55, 0.15, 0.30)
const SPELL_EDGE := Color(1.0, 0.7, 0.3, 0.8)
const BURST := Color(1.0, 0.75, 0.25, 0.55)
const COVER_HALF := Color(0.95, 0.8, 0.3, 0.95)
const COVER_FULL := Color(0.4, 0.75, 1.0, 0.95)
const DOT := 3.0
const FRAME := 2.0

## Cells in reach ({Vector2i: steps}); exit cells among them ({Vector2i: true}).
var reach: Dictionary = {}
var exits: Dictionary = {}
## The cells a click would walk through, in order.
var path: Array[Vector2i] = []
## The foe a click would hit (has_target false = none), and the text over it.
var target := Vector2i.ZERO
var has_target := false
var text := ""
## The fighter whose turn the screen shows (has_active false = none).
var active := Vector2i.ZERO
var has_active := false
## The cells of the foes an armed Skill can hit (M17.4).
var marks: Array[Vector2i] = []
## The tiles an armed spell would hit at the hovered tile, and the tiles of a spell
## being replayed (M17.5).
var preview: Array[Vector2i] = []
var burst: Array[Vector2i] = []
## M17.6: cover beside the tiles you can stand on: {cell: {unit step: level}}.
var covers: Dictionary = {}

var _label: Label


func _ready() -> void:
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", WorldView.NAME_FONT_SIZE)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_label.add_theme_constant_override("outline_size", 8)
	_label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_label.scale = Vector2.ONE / WorldView.TEXT_SCALE
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.z_index = 5
	_label.visible = false
	add_child(_label)


func show_reach(cells: Dictionary, exit_cells: Dictionary) -> void:
	reach = cells
	exits = exit_cells
	queue_redraw()


## Shows a click's path, and when `foe` is true its target at `at` with `label`.
func show_plan(cells: Array[Vector2i], foe: bool, at: Vector2i = Vector2i.ZERO, label: String = "") -> void:
	path = cells
	has_target = foe
	target = at
	text = label if foe else ""
	_label.text = text
	_label.visible = text != ""
	if _label.visible:
		var size := _label.get_minimum_size() / WorldView.TEXT_SCALE
		var c := WorldView.cell_center(at)
		_label.position = c + Vector2(-size.x / 2.0, WorldView.TILE / 2.0)  # under the foe
	queue_redraw()


func clear_plan() -> void:
	show_plan([] as Array[Vector2i], false)


func show_covers(cells: Dictionary) -> void:
	covers = cells
	queue_redraw()


func show_marks(cells: Array[Vector2i]) -> void:
	marks = cells
	queue_redraw()


func show_preview(cells: Array[Vector2i]) -> void:
	preview = cells
	queue_redraw()


func show_burst(cells: Array[Vector2i]) -> void:
	burst = cells
	queue_redraw()


func mark_active(cell: Vector2i) -> void:
	active = cell
	has_active = true
	queue_redraw()


func clear_active() -> void:
	has_active = false
	queue_redraw()


## Clears everything (no fight, or not the player's turn).
func clear() -> void:
	reach = {}
	exits = {}
	has_active = false
	marks = []
	preview = []
	burst = []
	covers = {}
	clear_plan()


func label_text() -> String:
	return _label.text if _label.visible else ""


func _draw() -> void:
	var t := float(WorldView.TILE)
	for cell: Vector2i in reach:
		var r := Rect2(Vector2(cell) * t + Vector2.ONE, Vector2(t - 2, t - 2))
		draw_rect(r, EXIT if exits.has(cell) else REACH)
		draw_rect(r, REACH_EDGE, false, 1.0)
	for cell in preview:
		var r := Rect2(Vector2(cell) * t + Vector2.ONE, Vector2(t - 2, t - 2))
		draw_rect(r, SPELL)
		draw_rect(r, SPELL_EDGE, false, 1.0)
	for cell in burst:
		draw_rect(Rect2(Vector2(cell) * t + Vector2.ONE, Vector2(t - 2, t - 2)), BURST)
	for cell: Vector2i in covers:
		for side: Vector2i in covers[cell]:
			_draw_cover(cell, side, String(covers[cell][side]) == Cover.HALF)
	for cell in path:
		draw_circle(WorldView.cell_center(cell), DOT, PATH)
	for cell in marks:
		draw_rect(Rect2(Vector2(cell) * t + Vector2.ONE * 2.0, Vector2(t - 4, t - 4)), SKILL, false, FRAME)
	if has_target:
		draw_rect(Rect2(Vector2(target) * t, Vector2(t, t)), TARGET, false, FRAME)
	if has_active:
		var c := WorldView.cell_center(active) + Vector2(0, t / 2.0 - 5.0)
		draw_arc(c, t / 2.5, 0.0, TAU, 24, ACTIVE, FRAME)


## A bar on the edge of `cell` that faces its cover: short and gold for half cover, the
## whole edge and blue for full cover (M17.6).
func _draw_cover(cell: Vector2i, side: Vector2i, half: bool) -> void:
	var t := float(WorldView.TILE)
	var centre := WorldView.cell_center(cell) + Vector2(side) * (t / 2.0 - 2.0)
	var along := Vector2(side.y, side.x).abs() * (t * (0.25 if half else 0.5) - 2.0)
	draw_line(centre - along, centre + along, COVER_HALF if half else COVER_FULL, 3.0 if not half else 2.0)
