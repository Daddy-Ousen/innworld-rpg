## Which sounds a change on screen makes (M12, ADR 0019). Pure and headless
## (no nodes), so tests can check it. Presentation only: never changes
## GameState (CLAUDE.md rule 1).
## M12.0 spike: the tables below are temporary. M12.1 moves them to
## data/audio.json (rule 4).
class_name SoundCues
extends RefCounted

## Ground tile -> footstep cue. Snow covers the outdoor ground in winter.
const STEPS := {
	"grass": "step_grass", "tall_grass": "step_grass", "dirt_road": "step_grass",
	"cobble": "step_stone", "cave_floor": "step_stone",
	"wood_floor": "step_wood", "door": "step_wood",
}
const SNOW_COVERED := ["grass", "tall_grass", "dirt_road", "cobble"]
const SNOW_STEP := "step_snow"
const HIT := "hit"


## The footstep cue for a step onto `tile` ("" = no sound).
static func footstep(tile: String, winter: bool = false) -> String:
	if winter and SNOW_COVERED.has(tile):
		return SNOW_STEP
	return String(STEPS.get(tile, ""))


## The cues of AnimDiff events, in order.
static func from_events(events: Array) -> Array[String]:
	var out: Array[String] = []
	for e: Dictionary in events:
		if e["type"] == AnimDiff.HIT:
			out.append(HIT)
	return out
