## Which sounds a change on screen makes (M12, ADR 0019). The cues come from
## data/audio.json (AudioDb). Pure and headless (no nodes), so tests can
## check it. Presentation only: never changes GameState (CLAUDE.md rule 1).
class_name SoundCues
extends RefCounted


## The footstep cue for a step onto a tile ("" = no sound). In winter a
## tile that turns white (it has a "winter_color") and has a footstep of
## its own sounds like snow; indoor maps never get snow.
static func footstep(audio: AudioDb, tile: String, tile_def: Dictionary = {},
		winter: bool = false) -> String:
	var step := audio.cue("footsteps", tile)
	if step != "" and winter and tile_def.has("winter_color"):
		var snow := audio.cue("footsteps", AudioDb.WINTER_STEP)
		if snow != "":
			return snow
	return step


## The cues of AnimDiff events, in order.
static func from_events(audio: AudioDb, events: Array) -> Array[String]:
	var out: Array[String] = []
	for e: Dictionary in events:
		var c := ""
		if e["type"] == AnimDiff.HIT:
			c = audio.cue("combat", "hit")
		if c != "":
			out.append(c)
	return out
