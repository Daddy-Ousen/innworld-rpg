## One character drawn from a baked LPC sheet (tools/build_sprites.py,
## ADR 0018): game/assets/characters/<id>.png, 768×1088 px.
## 64×64 frames from the top: walk rows 0-3 (9 frames), hurt row 4 (6),
## idle rows 5-8 (2). Under them (y ATTACK_Y) the attack block: 128×128
## frames, rows 0-3, 6 frames; the character is in the middle of each frame,
## so a weapon swing has room. A 4-row animation has one row per facing
## (LPC order: up, left, down, right).
## The node sits on the cell centre; the feet are drawn near the cell's
## bottom edge. A step glides the sprite from the old cell to the node and
## plays half a walk cycle (the other half on the next step). M11.3: an
## attack swing, and a fall that ends lying down.
## Presentation only: never changes GameState (CLAUDE.md rule 1).
class_name CharacterSprite
extends Sprite2D

const FRAME := 64
const BIG := 128
## Animation → [first row, frames, rows] in the 64 px part of the sheet.
const ANIMS := {"walk": [0, 9, 4], "hurt": [4, 6, 1], "idle": [5, 2, 4]}
const ATTACK_Y := 9 * FRAME
const ATTACK_FRAMES := 6
## Facing → row inside a 4-row animation.
const DIR_ROW := {"n": 0, "w": 1, "s": 2, "e": 3}
const PATH := "res://assets/characters/%s.png"
## The frame centre is this far above the cell centre, so the feet are
## a little above the cell's bottom edge.
const LIFT := 18.0
## The top of the head, above the node (for labels).
const HEAD := 38.0
const WALK_FRAMES := 4
const ATTACK_TIME := 0.3
const FALL_TIME := 0.45

var facing := "s"
## Lying down (the last hurt frame) when standing still.
var down := false
## The frame on show: [animation ("walk", "hurt", "idle" or "attack"), facing, frame].
var shown: Array = ["walk", "s", 0]
## Which half of the walk cycle the next step plays (0 or 1).
var half := 0
var _tween: Tween


static func path_for(id: String) -> String:
	return PATH % id


## True when a baked sheet exists for `id` (an NPC id, an enemy type or "player").
static func has_sheet(id: String) -> bool:
	return id != "" and ResourceLoader.exists(path_for(id))


## The sheet region (pixels) of frame `i` of `anim` facing `dir` (n, s, e, w).
## Frames wrap.
static func region_of(anim: String, dir: String, i: int) -> Rect2:
	var d := int(DIR_ROW.get(dir, 2))
	if anim == "attack":
		return Rect2(posmod(i, ATTACK_FRAMES) * BIG, ATTACK_Y + d * BIG, BIG, BIG)
	var a: Array = ANIMS[anim]
	var row := int(a[0]) + (d if int(a[2]) == 4 else 0)
	return Rect2(posmod(i, int(a[1])) * FRAME, row * FRAME, FRAME, FRAME)


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
	s.region_enabled = true
	s.offset = Vector2(0, -LIFT)
	s.show_frame("walk", "s", 0)
	return s


## Shows one frame. Both frame sizes share a centre, so the feet stay put.
func show_frame(anim: String, dir: String, i: int) -> void:
	shown = [anim, dir, i]
	region_rect = region_of(anim, dir, i)


## Standing still facing `dir`, or lying down (the last hurt frame).
func pose(dir: String, lying: bool = false) -> void:
	facing = dir
	down = lying
	if lying:
		show_frame("hurt", "s", 5)
	else:
		show_frame("walk", dir, 0)


## Glide from `from` (an offset, the old cell minus the new one) to the node
## in `time` seconds, playing half a walk cycle; ends standing.
func walk(dir: String, from: Vector2, time: float) -> void:
	finish()
	facing = dir
	position = from
	var first := 1 + half * WALK_FRAMES
	half = 1 - half
	_play("walk", dir, first, WALK_FRAMES, time, true)


## One attack swing facing `dir`; ends standing that way.
func attack(dir: String, time: float = ATTACK_TIME) -> void:
	finish()
	facing = dir
	_play("attack", dir, 0, ATTACK_FRAMES, time)


## Falls over (the hurt frames) and stays lying down.
func fall(time: float = FALL_TIME) -> void:
	finish()
	down = true
	_play("hurt", "s", 0, 6, time)


func is_walking() -> bool:
	return _tween != null and _tween.is_running()


## Ends a running glide, swing or fall at once (a new command came in).
func finish() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	position = Vector2.ZERO
	pose(facing, down)


## Plays `count` frames of `anim` from frame `first` in `time` seconds (and
## glides to the node with `glide`), then the standing (or lying) pose.
func _play(anim: String, dir: String, first: int, count: int, time: float, glide: bool = false) -> void:
	show_frame(anim, dir, first)
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_method(func(t: float) -> void:
		show_frame(anim, dir, first + mini(int(t * count), count - 1)), 0.0, 1.0, time)
	if glide:
		_tween.tween_property(self, "position", Vector2.ZERO, time)
	_tween.chain().tween_callback(func() -> void: pose(facing, down))
