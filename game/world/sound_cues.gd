## Which sounds a change on screen makes (M12, ADR 0019). The cues come from
## data/audio.json (AudioDb). Pure and headless (no nodes), so tests can
## check it. Presentation only: never changes GameState (CLAUDE.md rule 1).
class_name SoundCues
extends RefCounted

## A cue sounds at most this often per change.
const MAX_SAME := 2
const DOOR := "door"
const OPEN_PAGE := "open"
const DEATH_PAGE := "death"


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


## The cues of AnimDiff events, in order: a hit (or "hurt" when the player
## is hit) plus the voice of a hit monster, a fall, a gone monster's voice
## (else "gone"), a swing. `units` is the AnimDiff snapshot after the change
## (it holds each monster's type). One cue sounds at most MAX_SAME times per
## change, so a big battle is not a wall of noise.
static func from_events(audio: AudioDb, events: Array, units: Dictionary = {}) -> Array[String]:
	var out: Array[String] = []
	var count := {}
	for e: Dictionary in events:
		var id := String(e["id"])
		var cues: Array[String] = []
		match e["type"]:
			AnimDiff.HIT:
				cues.append(audio.cue("combat", "hurt" if id == AnimDiff.PLAYER else "hit"))
				cues.append(audio.enemy_cue(String(units.get(id, {}).get("type", "")), "hurt"))
			AnimDiff.FALL:
				cues.append(audio.cue("combat", "fall"))
			AnimDiff.GONE:
				var voice := audio.enemy_cue(String(e["monster_type"]), "gone")
				cues.append(voice if voice != "" else audio.cue("combat", "gone"))
			AnimDiff.SWING:
				cues.append(audio.cue("combat", "swing"))
		for c in cues:
			if c != "" and int(count.get(c, 0)) < MAX_SAME:
				count[c] = int(count.get(c, 0)) + 1
				out.append(c)
	return out


## The cue of a use-menu action: an action id, or a use-menu id (sleep, take,
## ride, portal; buy:x, sell:x and use:x go to buy, sell and use).
static func action_cue(audio: AudioDb, action_id: String) -> String:
	for prefix: String in [Interact.BUY, Interact.SELL, Interact.USE_GOOD]:
		if action_id.begins_with(prefix):
			return audio.cue("actions", prefix.trim_suffix(":"))
	return audio.cue("actions", action_id)


## A door sounds when a step goes between indoors and outdoors.
static func door_cue(audio: AudioDb, from_indoor: bool, to_indoor: bool) -> String:
	return audio.cue("actions", DOOR) if from_indoor != to_indoor else ""


## The cue of a System page kind; a kind not in the data plays "open".
static func page_cue(audio: AudioDb, kind: String) -> String:
	return audio.cue("pages", kind if audio.has_key("pages", kind) else OPEN_PAGE)


## The cue of a System page: a page that tells of a death (its "deaths",
## M12.5) plays the "death" cue when the data has one, else its kind's cue.
static func page_sound(audio: AudioDb, page: Dictionary) -> String:
	if not (page.get("deaths", []) as Array).is_empty() and audio.has_key("pages", DEATH_PAGE):
		return audio.cue("pages", DEATH_PAGE)
	return page_cue(audio, String(page.get("kind", "")))
