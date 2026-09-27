## Which area bed (a looping sound on the Ambience bus) fits the game now,
## and which objects make a looping sound (M12.4, ADR 0019). Pure and
## headless (no nodes), so tests can check it. Presentation only: reads
## GameState, never changes it (CLAUDE.md rule 1).
## - The bed: the map's place from data/audio.json `ambience` (`by_map`,
##   else `indoor` / `outdoor`), then the place's variant for the time and
##   season, with the same fallback as the music (MusicPick.pick_variant).
## - Object loops: an object kind with "sound" in data/objects.json
##   ({"cue", "radius" in cells, default DEFAULT_RADIUS}) plays that cue
##   around the object; it fades out with distance.
class_name AmbiencePick
extends RefCounted

const DEFAULT_RADIUS := 5.0


## The bed cue for now ("" = silence).
static func bed(gs: GameState, db: DataDb, audio: AudioDb) -> String:
	var area := gs.player.area
	return bed_for(audio, audio.ambience_place(area, db.maps.is_indoor(area)),
			Atmosphere.darkness(gs.clock.minute()) >= MusicPick.NIGHT_FROM, Winter.on(gs, db))


static func bed_for(audio: AudioDb, place: String, night: bool, winter: bool) -> String:
	return MusicPick.pick_variant(audio.ambience_beds(place), night, winter)


## The loop of an object kind's art ({"cue": String, "radius": cells};
## {} = silent).
static func loop_of(art: Variant) -> Dictionary:
	if not art is Dictionary or not (art as Dictionary).get("sound") is Dictionary:
		return {}
	var s: Dictionary = art["sound"]
	var cue := String(s.get("cue", ""))
	if cue == "":
		return {}
	return {"cue": cue, "radius": float(s.get("radius", DEFAULT_RADIUS))}


## The loops of the objects on a map: [{"cue", "cell": Vector2i, "radius"}].
static func loops_on(maps: MapDb, area: String, object_art: Dictionary) -> Array:
	var out: Array = []
	for o: Dictionary in maps.objects_on(area):
		var l := loop_of(object_art.get(String(o.get("kind", "")), {}))
		if not l.is_empty():
			l["cell"] = Vector2i(int(o["at"][0]), int(o["at"][1]))
			out.append(l)
	return out
