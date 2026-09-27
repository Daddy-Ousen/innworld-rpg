## One character drawn from a baked LPC sheet (tools/build_sprites.py,
## ADR 0018): game/assets/characters/<id>.png, 64×64 frames, 9 columns.
## Rows: walk 0-3, slash 4-7, hurt 8, idle 9-12; a 4-row animation has one
## row per facing (LPC order: up, left, down, right).
## The node sits on the cell centre; the feet are drawn near the cell's
## bottom edge. A step glides the sprite from the old cell to the node and
## plays half a walk cycle (the other half on the next step).
## Presentation only: never changes GameState (CLAUDE.md rule 1).
class_name CharacterSprite
extends Sprite2D

const FRAME := 64
const COLUMNS := 9
const ROWS := 13
## Animation → [first row, frames, rows].
const ANIMS := {"walk": [0, 9, 4], "slash": [4, 6, 4], "hurt": [8, 6, 1], "idle": [9, 2, 4]}
## Facing → row inside a 4-row animation.
const DIR_ROW := {"n": 0, "w": 1, "s": 2, "e": 3}
const PATH := "res://assets/characters/%s.png"
## The frame centre is this far above the cell centre, so the feet are
## a little above the cell's bottom edge.
const LIFT := 18.0
## The top of the head, above the node (for labels).
const HEAD := 38.0
const WALK_FRAMES := 4

var facing := "s"
var _half := 0
var _tween: Tween


static func path_for(id: String) -> String:
	return PATH % id


## True when a baked sheet exists for `id` (an NPC id, an enemy type or "player").
static func has_sheet(id: String) -> bool:
	return id != "" and ResourceLoader.exists(path_for(id))


## Frame index of frame `i` of `anim` facing `dir` (n, s, e, w).
static func frame_of(anim: String, dir: String, i: int) -> int:
	var a: Array = ANIMS[anim]
	var row := int(a[0]) + (int(DIR_ROW.get(dir, 2)) if int(a[2]) == 4 else 0)
	return row * COLUMNS + posmod(i, int(a[1]))


## The look of a character: its own sheet `id`, else the generic look of
## its race ("race_" + race, e.g. race_drake, race_half_elf), else "".
static func look_for(id: String, race: String = "") -> String:
	if has_sheet(id):
		return id
	var generic := "race_" + race.to_lower().replace("-", "_").replace(" ", "_")
	return generic if race != "" and has_sheet(generic) else ""


## A new sprite for `id`, or null when there is no sheet.
static func make(id: String) -> CharacterSprite:
	if not has_sheet(id):
		return null
	var s := CharacterSprite.new()
	s.texture = load(path_for(id))
	s.hframes = COLUMNS
	s.vframes = ROWS
	s.offset = Vector2(0, -LIFT)
	s.frame = frame_of("walk", "s", 0)
	return s


## Standing still facing `dir`, or lying down (the last hurt frame).
func pose(dir: String, down: bool = false) -> void:
	facing = dir
	frame = frame_of("hurt", "s", 5) if down else frame_of("walk", dir, 0)


## Glide from `from` (an offset, the old cell minus the new one) to the node
## in `time` seconds, playing half a walk cycle; ends standing.
func walk(dir: String, from: Vector2, time: float) -> void:
	finish()
	facing = dir
	position = from
	var first := 1 + _half * WALK_FRAMES
	_half = 1 - _half
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "position", Vector2.ZERO, time)
	_tween.tween_method(func(t: float) -> void:
		frame = frame_of("walk", dir, first + mini(int(t * WALK_FRAMES), WALK_FRAMES - 1)), 0.0, 1.0, time)
	_tween.chain().tween_callback(func() -> void: pose(dir))


func is_walking() -> bool:
	return _tween != null and _tween.is_running()


## Ends a running glide at once (a new command came in).
func finish() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	position = Vector2.ZERO
	pose(facing)
