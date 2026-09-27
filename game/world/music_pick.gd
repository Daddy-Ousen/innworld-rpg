## Which music track fits the game now (M12.3, ADR 0019). Pure and headless
## (no nodes), so tests can check it. Presentation only: reads GameState,
## never changes it (CLAUDE.md rule 1). The tracks come from data/audio.json.
## Priority, first match wins:
## 1. a canon moment (`moments`, in data order),
## 2. a staged battle with foes left, while the player is in its area (`battle`),
## 3. any fight (`fight`),
## 4. a live scene stage (`scene`),
## 5. the mood of the place (`moods`: by map id, else by the map's location,
##    else `default`) with its day / night / winter variant (`mood_tracks`).
## "" = silence.
class_name MusicPick
extends RefCounted

## The sky counts as night from this darkness (Atmosphere.darkness).
const NIGHT_FROM := 0.5


static func track(gs: GameState, db: DataDb, audio: AudioDb) -> String:
	var t := moment(gs, db, audio)
	if t != "":
		return t
	for state: String in states(gs, db):
		t = audio.state_track(state)
		if t != "":
			return t
	return place_track(audio, mood_of(audio, db.maps, gs.player.area),
			Atmosphere.darkness(gs.clock.minute()) >= NIGHT_FROM, Winter.on(gs, db))


## The states that hold now, most urgent first (battle, fight, scene).
static func states(gs: GameState, db: DataDb) -> Array[String]:
	var out: Array[String] = []
	var run := gs.combat.stage_run
	if not run.is_empty() and Stage.foes_left(gs, db) > 0 \
			and db.canon.events.get(run["event"], {}).get("stage", {}).get("area", "") == gs.player.area:
		out.append("battle")
	if gs.combat.has_fight():
		out.append("fight")
	if scene_live(gs, db):
		out.append("scene")
	return out


static func scene_live(gs: GameState, db: DataDb) -> bool:
	for id: String in db.canon.stages:
		if Stage.is_scene_live(gs, db, id):
			return true
	return false


## The track of the first canon moment that holds now ("" = none). A moment
## holds when all its `when_flags` are set, none of its `unless_flags` is,
## the player is in one of its `areas` (none = anywhere) and one of its
## `stages` is live (none = no stage needed): a scene stage live now, or the
## staged fight in progress.
static func moment(gs: GameState, db: DataDb, audio: AudioDb) -> String:
	var moments: Variant = audio.data.get("moments", [])
	if not moments is Array:
		return ""
	for mo: Variant in moments:
		if mo is Dictionary and _holds(gs, db, mo):
			return String(mo.get("track", ""))
	return ""


static func _holds(gs: GameState, db: DataDb, mo: Dictionary) -> bool:
	for f: String in mo.get("when_flags", []):
		if not gs.flags.has(f):
			return false
	for f: String in mo.get("unless_flags", []):
		if gs.flags.has(f):
			return false
	var areas: Array = mo.get("areas", [])
	if not areas.is_empty() and not areas.has(gs.player.area):
		return false
	var stages: Array = mo.get("stages", [])
	if stages.is_empty():
		return true
	for id: String in stages:
		if Stage.is_scene_live(gs, db, id) or String(gs.combat.stage_run.get("event", "")) == id:
			return true
	return false


## The mood of a map: by its id, else by its location, else the default.
static func mood_of(audio: AudioDb, maps: MapDb, area: String) -> String:
	var moods: Dictionary = audio.data.get("moods", {})
	var by_map: Dictionary = moods.get("by_map", {})
	if by_map.has(area):
		return String(by_map[area])
	var location := String(maps.areas.get(area, {}).get("location", ""))
	var by_location: Dictionary = moods.get("by_location", {})
	if by_location.has(location):
		return String(by_location[location])
	return String(moods.get("default", ""))


## A mood's track for the time and season. A missing variant falls back:
## winter_night -> night -> winter_day -> day; winter_day -> day;
## night -> day.
static func place_track(audio: AudioDb, mood: String, night: bool, winter: bool) -> String:
	var variants: Dictionary = audio.data.get("mood_tracks", {}).get(mood, {})
	var order: Array[String] = []
	if winter and night:
		order = ["winter_night", "night", "winter_day", "day"]
	elif winter:
		order = ["winter_day", "day"]
	elif night:
		order = ["night", "day"]
	else:
		order = ["day"]
	for v in order:
		if String(variants.get(v, "")) != "":
			return String(variants[v])
	return ""
