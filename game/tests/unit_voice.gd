extends GutTest
## NPC voices (M30.1, ADR 0044 "M30.0"): own greetings by band, lines by gate, own
## talk options through Interact, barks (pure pick and the view bubbles), the stable
## hash (no gs.rng), validation, and the real data. Test voices are put on the real db.

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()


func after_each() -> void:
	_db.voices = {}


func _voice() -> Dictionary:
	return {
		"confidence": "guess",
		"greet": {"stranger": ["Who are you?"], "acquaintance": ["You again. Good."]},
		"idle": ["Fresh fruit!", "Buy, buy!", "[Krshia sniffs the air.]"],
		"lines": [
			{"text": "The flag is up.", "flags": ["x.up"]},
			{"text": "Not while it is up.", "not_flags": ["x.up"], "days": [1, 3]},
			{"text": "Friends hear this.", "min_band": "friend", "days": [50, 60]},
		],
		"options": [
			{"id": "chess", "label": "Ask Krshia for a game", "action": "play_chess",
			 "context": {"opponent_skill": 0.9}},
			{"id": "secret", "label": "Ask about her past", "action": "talk_with_guest",
			 "min_band": "acquaintance"},
		],
	}


## Day 2, 9:00, the player in the market next to Krshia.
func _gs() -> GameState:
	_db.voices = {"krshia": _voice()}
	var gs := GameState.new_game(20261018, _db)
	gs.clock.total_minutes = 1440 + 9 * 60
	gs.player.place("liscor_market", Vector2i(5, 5))
	gs.npcs.npcs["krshia"]["area"] = "liscor_market"
	gs.npcs.npcs["krshia"]["x"] = 6
	gs.npcs.npcs["krshia"]["y"] = 5
	return gs


func test_hash_is_fnv1a_and_stable() -> void:
	assert_eq(Voice.hash32(""), 2166136261)
	assert_eq(Voice.hash32("a"), 0xe40c292c, "FNV-1a 32 of 'a'")
	assert_eq(Voice.pick(["x", "y", "z"], "2|krshia|line"), Voice.pick(["x", "y", "z"], "2|krshia|line"))


func test_greet_by_band() -> void:
	var gs := _gs()
	assert_eq(Voice.band_key(gs, _db, "krshia"), Voice.STRANGER)
	assert_eq(Voice.greet(gs, _db, "krshia"), "Krshia: \"Who are you?\"")
	gs.world.add_relationship("krshia", NpcSim.PLAYER, 4)
	assert_eq(Voice.greet(gs, _db, "krshia"), "Krshia: \"You again. Good.\"")
	gs.world.add_relationship("krshia", NpcSim.PLAYER, 3)
	assert_eq(Voice.band_key(gs, _db, "krshia"), "friend")
	assert_eq(Voice.greet(gs, _db, "krshia"), "", "no friend key: the generic band line is used")
	assert_eq(Voice.greet(gs, _db, "relc"), "", "no voice")


func test_line_gates() -> void:
	var gs := _gs()
	assert_eq(Voice.lines_now(gs, _db, "krshia"), ["Not while it is up."] as Array[String])
	gs.flags["x.up"] = true
	assert_eq(Voice.lines_now(gs, _db, "krshia"), ["The flag is up."] as Array[String])
	gs.clock.total_minutes = 54 * 1440
	assert_eq(Voice.lines_now(gs, _db, "krshia"), ["The flag is up."] as Array[String], "not a friend yet")
	gs.world.add_relationship("krshia", NpcSim.PLAYER, 7)
	assert_eq(Voice.lines_now(gs, _db, "krshia"), ["The flag is up.", "Friends hear this."] as Array[String])
	assert_true(Voice.line(gs, _db, "krshia").begins_with("Krshia: \""))


func test_bracket_text_is_an_action() -> void:
	assert_eq(Voice.say(_db, "krshia", "[Krshia sniffs the air.]"), "[Krshia sniffs the air.]")


func test_options_in_interact_and_perform() -> void:
	var gs := _gs()
	var row: Dictionary = Interact.options(gs, _db).filter(func(o: Dictionary) -> bool:
		return o["id"] == "krshia")[0]
	assert_eq(row["voice"], [{"id": "chess", "label": "Ask Krshia for a game", "action": "play_chess"}])
	assert_true((row["actions"] as Array).has("talk_with_guest"), "generic rows stay")
	var r := Interact.perform(gs, _db, "krshia", Interact.VOICE + "secret")
	assert_ne(r["error"], "", "gated option refused")
	r = Interact.perform(gs, _db, "krshia", Interact.VOICE + "chess")
	assert_eq(r["error"], "")
	assert_eq(r["record"]["action_id"], "play_chess")
	var tags: Dictionary = r["record"]["tags"]
	assert_almost_eq(float(tags["strategy"]), float(tags["games.chess"]), 0.001,
			"option context reached the action (strategy +0.5)")
	assert_eq(Interact.action_of(_db, "krshia", Interact.VOICE + "chess"), "play_chess")
	assert_eq(Interact.action_of(_db, "krshia", "persuade"), "persuade")


func test_first_talk_says_own_greet_and_line_not_rng() -> void:
	var gs := _gs()
	var before := gs.rng.to_dict()
	Interact.perform(gs, _db, "krshia", "talk_with_guest")
	assert_eq(gs.combat.lines.slice(-2), ["Krshia: \"Who are you?\"", "Krshia: \"Not while it is up.\""],
			str(gs.combat.lines))
	assert_eq(gs.rng.to_dict(), before, "an own line uses no gs.rng (no talk topic was picked)")
	var n := gs.combat.lines.size()
	Interact.perform(gs, _db, "krshia", "talk_with_guest")
	assert_eq(gs.combat.lines.size(), n, "once a day")


func test_no_voice_talks_as_before() -> void:
	var gs := _gs()
	_db.voices = {}
	Interact.perform(gs, _db, "krshia", "talk_with_guest")
	assert_false(gs.combat.lines.has("Krshia: \"Who are you?\""))
	var row: Dictionary = Interact.options(gs, _db).filter(func(o: Dictionary) -> bool:
		return o["id"] == "krshia")[0]
	assert_eq(row["voice"], [] as Array[Dictionary])


func test_bark_pick_is_pure() -> void:
	_db.voices = {"krshia": _voice()}
	var a := Voice.bark(_db, 3, "krshia", 9 * 60)
	assert_true(_voice()["idle"].has(a))
	assert_eq(Voice.bark(_db, 3, "krshia", 9 * 60 + 19), a, "same 20 min bucket")
	assert_eq(Voice.bark_bucket(_db, 9 * 60 + 19), 27)
	assert_eq(Voice.bark(_db, 3, "relc", 9 * 60), "", "no idle lines")


func test_view_bubble_near_player_only() -> void:
	var gs := _gs()
	var v: WorldView = add_child_autofree(load("res://world/world_view.tscn").instantiate())
	v.setup(_db.maps)
	v.refresh(gs, _db)
	var said := v.bubbles.text_of("krshia")
	assert_eq(said, Voice.bark(_db, gs.clock.day(), "krshia", gs.clock.minute()))
	v.bubbles.tick(ViewBubbles.HOLD + ViewBubbles.FADE + 0.1)
	await get_tree().process_frame
	assert_eq(v.bubbles.text_of("krshia"), "", "faded out")
	v.refresh(gs, _db)
	assert_eq(v.bubbles.text_of("krshia"), "", "one bark per bucket")
	gs.clock.total_minutes += 20
	gs.npcs.npcs["krshia"]["x"] = 5 + 9
	v.refresh(gs, _db)
	assert_eq(v.bubbles.text_of("krshia"), "", "out of range")


func test_validate() -> void:
	_db.voices = {
		"krshia": _voice(),
		"nobody_at_all": {"confidence": "guess"},
		"relc": {"confidence": "maybe", "greet": {"pal": ["Hi."]}, "idle": ["one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty twentyone"],
			"lines": [{"text": "Hi.", "days": [5, 2], "when": 1}],
			"options": [{"id": "a", "label": "A", "action": "no_such"}, {"id": "a", "label": "B", "action": "persuade",
				"min_band": "pal"}]},
	}
	var errs := Voice.validate(_db)
	var text := "\n".join(errs)
	for bit in ["nobody_at_all", "confidence", "greet key 'pal'", "more than 20 words", "days must be",
			"unknown field 'when'", "unknown action 'no_such'", "used twice", "min_band 'pal'"]:
		assert_true(text.contains(bit), "%s in %s" % [bit, text])
	assert_false(text.contains("voice 'krshia'"), "the good entry passes")


## M30.4: an option's set_flags, relationship and page; its own not_flags make it one-time.
func test_option_effects_once() -> void:
	var v := _voice()
	(v["options"] as Array).append({"id": "earth", "label": "Tell her", "action": "talk_with_guest",
		"not_flags": ["krshia.knows"], "set_flags": ["krshia.knows"], "relationship": 3,
		"page": {"title": "Home", "lines": ["One.", "Two."]}})
	var gs := _gs()
	_db.voices = {"krshia": v}
	var before := gs.rng.to_dict()
	var r := Interact.perform(gs, _db, "krshia", Interact.VOICE + "earth")
	assert_eq(r["error"], "")
	assert_eq(r["page"], {"title": "Home", "lines": ["One.", "Two."] as Array[String]})
	assert_true(gs.flags.get("krshia.knows", false))
	assert_eq(gs.world.relationship("krshia", NpcSim.PLAYER), 3 + int(_db.rules["npc"]["talk_relationship"]))
	assert_eq(gs.rng.to_dict(), before, "no gs.rng")
	var row: Dictionary = Interact.options(gs, _db).filter(func(o: Dictionary) -> bool:
		return o["id"] == "krshia")[0]
	assert_false((row["voice"] as Array).any(func(o: Dictionary) -> bool: return o["id"] == "earth"), "once")
	assert_ne(Interact.perform(gs, _db, "krshia", Interact.VOICE + "earth")["error"], "")
	r = Interact.perform(gs, _db, "krshia", Interact.VOICE + "chess")
	assert_false(r.has("page"), "an option with no page gives none")


func test_validate_option_effects() -> void:
	var v := _voice()
	(v["options"] as Array).append_array([
		{"id": "a", "label": "A", "action": "persuade", "set_flags": "x", "relationship": 1.5},
		{"id": "b", "label": "B", "action": "persuade", "page": {"title": "T", "lines": []}},
		{"id": "c", "label": "C", "action": "persuade", "page": {"title": "T", "lines": ["one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty twentyone"]}},
		{"id": "d", "label": "D", "action": "persuade", "set_flags": ["x.ok"], "relationship": 2,
		 "page": {"title": "T", "lines": ["Fine."]}}])
	_db.voices = {"krshia": v}
	var text := "\n".join(Voice.validate(_db))
	for bit in ["set_flags must be", "relationship must be", "page must be", "more than 20 words"]:
		assert_true(text.contains(bit), "%s in %s" % [bit, text])
	assert_false(text.contains("options[5]"), "the good option passes: " + text)


## M30.4: the Earthers the player can meet, each with a one-time Earth talk.
const EARTHERS := {"erin_solstice": "erin", "ryoka_griffin": "ryoka", "laken_godart": "laken",
		"rose": "rose", "imani": "imani", "joseph": "joseph"}


func test_earthers_have_an_earth_talk() -> void:
	var d := DataDb.load_dir()
	for id: String in EARTHERS:
		var o := Voice.option(d, id, "earth")
		var flag := "%s.knows_player_is_earther" % EARTHERS[id]
		assert_false(o.is_empty(), "%s has an earth talk" % id)
		assert_eq(o.get("set_flags", []), [flag], id)
		assert_eq(o.get("not_flags", []), [flag], "%s: once" % id)
		var n := (o.get("page", {}).get("lines", []) as Array).size()
		assert_true(n >= 4 and n <= 6, "%s: 4 - 6 lines, got %d" % [id, n])
		assert_gte(int(o.get("relationship", 0)), 2, id)
	assert_eq(int(Voice.option(d, "erin_solstice", "earth")["relationship"]), 3)


func test_no_rules_no_voices() -> void:
	var d := ToyData.db()
	assert_false(Voice.on(d))
	assert_eq(Voice.validate(d), [] as Array[String], str(Voice.validate(d)))
	d.voices = {"x": {}}
	assert_eq(Voice.validate(d).size(), 1, "voices without rules.voice")


func test_real_data_is_valid() -> void:
	var d := DataDb.load_dir()
	assert_eq(d.errors, [] as Array[String])
	assert_true(Voice.on(d))
	assert_eq(Voice.validate(d), [] as Array[String])


## M30.2: the Book 1 cast (ADR 0044 "M30.0" first cast).
const BOOK1_CAST := ["erin_solstice", "relc", "klbkch", "pisces", "olesm", "selys", "krshia", "zevara",
		"lism", "ryoka_griffin", "ceria_springwalker", "pawn", "rags", "toren", "beilmark"]


## Every flag the canon events (and their alt events and hooks) can set.
func _canon_flags(d: DataDb) -> Dictionary:
	var out := {}
	var walk := func(again: Callable, v: Variant) -> void:
		if v is Dictionary:
			for k: String in v:
				if k == "set_flags":
					for f: String in v[k]:
						out[f] = true
				else:
					again.call(again, v[k])
		elif v is Array:
			for x: Variant in v:
				again.call(again, x)
	walk.call(walk, d.canon.events)
	return out


## Every flag a voice entry's gates name.
func _voice_flags(v: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var gates: Array = (v.get("lines", []) as Array) + (v.get("options", []) as Array)
	for g: Dictionary in gates:
		for k in ["flags", "not_flags"]:
			for f: String in g.get(k, []):
				out.append(f)
	return out


func test_book1_cast_has_voices() -> void:
	var d := DataDb.load_dir()
	for id: String in BOOK1_CAST:
		assert_true(d.voices.has(id), "%s has a voice" % id)
		var v: Dictionary = d.voices.get(id, {})
		assert_true((v.get("greet", {}) as Dictionary).has(Voice.STRANGER), "%s greets a stranger" % id)
		assert_gte((v.get("idle", []) as Array).size(), 3, "%s has map barks" % id)
		assert_gt((v.get("lines", []) as Array).size(), 0, "%s has lines after events" % id)


func test_book1_voice_flags_are_real() -> void:
	var d := DataDb.load_dir()
	var known := _canon_flags(d)
	for id: String in d.voices:  # M30.4: a flag an own option sets is real too
		for o: Dictionary in d.voices[id].get("options", []):
			for f: String in o.get("set_flags", []):
				known[f] = true
	for id: String in d.voices:
		for f in _voice_flags(d.voices[id]):
			assert_true(known.has(f), "%s: flag '%s' is set by no canon event" % [id, f])


func test_book1_options() -> void:
	var d := DataDb.load_dir()
	var want := {"erin_solstice": ["work", "chess", "inn", "earth"], "relc": ["spar"], "pisces": ["magic"],
			"olesm": ["chess"], "krshia": ["haggle"], "toren": ["chess"], "ryoka_griffin": ["earth"]}
	for id: String in want:
		var ids: Array = (d.voices[id]["options"] as Array).map(func(o: Dictionary) -> String: return o["id"])
		assert_eq(ids, want[id], id)
	for id: String in ["klbkch", "zevara", "rags", "pawn"]:
		assert_false(d.voices[id].has("options"), "%s has lines only" % id)


func test_book1_speech_and_actions() -> void:
	var d := DataDb.load_dir()
	for id: String in BOOK1_CAST:
		for text in (d.voices[id].get("idle", []) as Array):
			if id == "toren":
				assert_true(String(text).begins_with("["), "Toren never speaks: %s" % text)
			assert_eq(Voice.say(d, id, String(text)).begins_with("["), String(text).begins_with("["))
	var l := Voice.say(d, "relc", "Hi.")
	assert_eq(l, "Relc Grasstongue: \"Hi.\"")


## A real first talk (a new game starts on day 8 with the inn open): Erin's own greeting and an own line, no gs.rng drawn.
func test_real_talk_with_erin() -> void:
	var d := DataDb.load_dir()
	var gs := GameState.new_game(20261018, d)
	gs.clock.total_minutes = 1440 * 5 + 10 * 60
	gs.player.place("inn_interior", Vector2i(5, 5))
	gs.npcs.npcs["erin_solstice"]["area"] = "inn_interior"
	gs.npcs.npcs["erin_solstice"]["x"] = 6
	gs.npcs.npcs["erin_solstice"]["y"] = 5
	var before := gs.rng.to_dict()
	var r := Interact.perform(gs, d, "erin_solstice", "talk_with_guest")
	assert_eq(r["error"], "")
	var lines: Array = gs.combat.lines.slice(-2)
	assert_true(String(lines[0]).begins_with("Erin Solstice: \""), str(lines))
	assert_eq(lines[1], "Erin Solstice: \"I cook too much pasta and eat it alone. Please eat some.\"")
	assert_eq(gs.rng.to_dict(), before, "own greeting and line draw no gs.rng")


## M30.3: the Books 2 - 8 cast.
const LATER_CAST := ["lyonette", "mrsha", "bird", "ksmvr", "yvlon_byres", "numbtongue", "headscratcher",
		"badarrow", "rabbiteater", "shorthilt", "zel_shivertail", "ilvriss", "jelaqua", "moore", "halrac",
		"wesle", "octavia", "magnolia_reinhart", "laken_godart", "calruz"]


func test_later_cast_has_voices() -> void:
	var d := DataDb.load_dir()
	for id: String in LATER_CAST:
		assert_true(d.voices.has(id), "%s has a voice" % id)
		var v: Dictionary = d.voices.get(id, {})
		for band in [Voice.STRANGER, "acquaintance", "friend", "close friend"]:
			assert_true((v.get("greet", {}) as Dictionary).has(band), "%s greets band %s" % [id, band])
		assert_gte((v.get("idle", []) as Array).size(), 3, "%s has map barks" % id)
		assert_gt((v.get("lines", []) as Array).size(), 0, "%s has lines after events" % id)
		assert_true(d.canon.npcs.has(id), id)


func test_later_cast_lines_follow_each_books_flags() -> void:
	var d := DataDb.load_dir()
	var keyed := 0
	for id: String in LATER_CAST:
		for l: Dictionary in d.voices[id]["lines"]:
			assert_true(l.has("flags"), "%s: every later line waits for a story flag" % id)
			keyed += 1
	assert_gte(keyed, 60)


func test_mrsha_acts_and_never_speaks() -> void:
	var d := DataDb.load_dir()
	var v: Dictionary = d.voices["mrsha"]
	var texts: Array = (v["idle"] as Array).duplicate()
	for band: String in v["greet"]:
		texts.append_array(v["greet"][band])
	for l: Dictionary in v["lines"]:
		texts.append(l["text"])
	for t in texts:
		assert_true(String(t).begins_with("[") and String(t).ends_with("]"), "Mrsha is mute: %s" % t)


func test_lines_depend_on_the_story() -> void:
	var d := DataDb.load_dir()
	var gs := GameState.new_game(20261018, d)
	assert_eq(Voice.lines_now(gs, d, "zel_shivertail"), [] as Array[String], "no Zel line before his flags")
	gs.flags["zel.drinks_milk_with_ashfire_bee_honey"] = true
	assert_eq(Voice.lines_now(gs, d, "zel_shivertail").size(), 1)
	gs.flags["zel.allied_with_magnolia"] = true
	assert_eq(Voice.lines_now(gs, d, "zel_shivertail").size(), 2)

