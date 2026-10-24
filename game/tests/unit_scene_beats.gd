extends GutTest
## Stage beats in the real canon (M31.2 – M31.3, ADR 0044): every scene plays
## 3 – 6 short beats and every fight 1 – 3 ally shouts, spoken by NPCs the stage
## places (scene npcs, stage or wave allies) or by no one, each short enough
## for a speech bubble, all inside the stage's hours.

const SCENE_BEATS := [3, 6]
const FIGHT_BEATS := [1, 3]

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()


## The stages of one kind ("scene" or "fight"): event id → stage.
func _stages(kind: String) -> Dictionary:
	var out := {}
	for id: String in _db.canon.events:
		var st: Dictionary = _db.canon.events[id].get("stage", {})
		if not st.is_empty() and st.get("kind", "fight") == kind:
			out[id] = st
	return out


## Everyone the stage puts on the map who may speak a beat.
func _placed(st: Dictionary) -> Array:
	var out: Array = (st.get("npcs", []) as Array).map(func(n: Dictionary) -> String: return n["npc"])
	out.append_array(st.get("allies", []))
	for w: Dictionary in st.get("waves", []):
		out.append_array(w.get("allies", []))
	return out


func _all() -> Dictionary:
	var out := _stages("scene")
	out.merge(_stages("fight"))
	return out


func test_the_canon_loads_clean() -> void:
	assert_eq(_db.canon.errors, [] as Array[String])
	assert_eq(_db.combat.errors, [] as Array[String])


func test_every_scene_has_three_to_six_beats() -> void:
	var scenes := _stages("scene")
	assert_eq(scenes.size(), 47, "the 47 scenes of Books 1 – 8")
	for id: String in scenes:
		var n := (scenes[id].get("beats", []) as Array).size()
		assert_between(n, SCENE_BEATS[0], SCENE_BEATS[1], "%s has %d beats" % [id, n])


func test_every_fight_has_one_to_three_shouts() -> void:
	var fights := _stages("fight")
	assert_eq(fights.size(), 25, "the 25 fight stages of Books 1 – 8")
	for id: String in fights:
		var n := (fights[id].get("beats", []) as Array).size()
		assert_between(n, FIGHT_BEATS[0], FIGHT_BEATS[1], "%s has %d beats" % [id, n])


func test_a_speaker_is_placed_by_the_stage() -> void:
	var all := _all()
	for id: String in all:
		var placed := _placed(all[id])
		for b: Dictionary in all[id].get("beats", []):
			if b.has("npc"):
				assert_has(placed, b["npc"], "%s: beat speaker %s is placed" % [id, b["npc"]])


func test_a_beat_fits_a_bubble() -> void:
	var most := int(_db.rules["voice"]["max_words"])
	var all := _all()
	for id: String in all:
		for b: Dictionary in all[id].get("beats", []):
			var words := String(b["line"]).split(" ", false).size()
			assert_true(words <= most, "%s: '%s' has %d words (max %d)" % [id, b["line"], words, most])


func test_the_beats_play_inside_the_stage_hours() -> void:
	var all := _all()
	for id: String in all:
		var st: Dictionary = all[id]
		var span := (int(st["hours"][1]) - int(st["hours"][0]) + 24) % 24
		for b: Dictionary in st.get("beats", []):
			assert_lt(int(b["after_seconds"]), span * 3600, "%s: beat at %ds" % [id, b["after_seconds"]])
