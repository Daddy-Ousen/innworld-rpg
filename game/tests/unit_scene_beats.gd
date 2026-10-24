extends GutTest
## Scene beats in the real canon (M31.2, ADR 0044 "M31.2"): every Books 1 – 4
## scene plays 3 – 6 short beats, spoken by NPCs the scene places (or no
## speaker), each short enough for a speech bubble, all inside the scene's hours.

const BOOKS := ["b1.", "b2.", "b3.", "b4."]
const MIN_BEATS := 3
const MAX_BEATS := 6

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()


## The scene stages of Books 1 – 4: event id → stage.
func _scenes() -> Dictionary:
	var out := {}
	for id: String in _db.canon.events:
		var st: Dictionary = _db.canon.events[id].get("stage", {})
		if st.get("kind", "fight") == "scene" and BOOKS.any(func(p: String) -> bool: return id.begins_with(p)):
			out[id] = st
	return out


func test_the_canon_loads_clean() -> void:
	assert_eq(_db.canon.errors, [] as Array[String])
	assert_eq(_db.combat.errors, [] as Array[String])


func test_every_scene_has_three_to_six_beats() -> void:
	var scenes := _scenes()
	assert_eq(scenes.size(), 17, "the 17 scenes of Books 1 – 4")
	for id: String in scenes:
		var n := (scenes[id].get("beats", []) as Array).size()
		assert_between(n, MIN_BEATS, MAX_BEATS, "%s has %d beats" % [id, n])


func test_a_speaker_is_placed_by_the_scene() -> void:
	for id: String in _scenes():
		var st: Dictionary = _scenes()[id]
		var placed: Array = (st["npcs"] as Array).map(func(n: Dictionary) -> String: return n["npc"])
		for b: Dictionary in st.get("beats", []):
			if b.has("npc"):
				assert_has(placed, b["npc"], "%s: beat speaker %s is placed" % [id, b["npc"]])


func test_a_beat_fits_a_bubble() -> void:
	var most := int(_db.rules["voice"]["max_words"])
	for id: String in _scenes():
		for b: Dictionary in _scenes()[id].get("beats", []):
			var words := String(b["line"]).split(" ", false).size()
			assert_true(words <= most, "%s: '%s' has %d words (max %d)" % [id, b["line"], words, most])


func test_the_beats_play_inside_the_scene_hours() -> void:
	for id: String in _scenes():
		var st: Dictionary = _scenes()[id]
		var span := (int(st["hours"][1]) - int(st["hours"][0]) + 24) % 24
		for b: Dictionary in st.get("beats", []):
			assert_lt(int(b["after_seconds"]), span * 3600, "%s: beat at %ds" % [id, b["after_seconds"]])
