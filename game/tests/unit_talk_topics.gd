extends GutTest
## Talk topics (M25.1, ADR 0039): the topic pool (own, town and rumour news, talk.json
## topics and request hints with their gates), the weighted pick, the regard floor,
## validation, and the real data through Interact. Toy data first, then real data.

const RULES := {"news_days": 3, "min_regard": 0, "line": "%s: \"%s\"",
	"weights": {"own": 4, "town": 3, "rumor": 2, "topic": 2, "request": 1}}


func _npc(home: Variant, tags: Array = ["human"]) -> Dictionary:
	var n := ToyCanon.npc(tags)
	n["home"] = home
	return n


func _db(talk: Dictionary = {}) -> DataDb:
	var d := ToyData.db()
	d.rules["talk"] = RULES.duplicate(true)
	var locs := {
		"town_a": {"name": "A", "kind": "settlement", "parent": null},
		"market_a": {"name": "A market", "kind": "district", "parent": "town_a"},
		"town_b": {"name": "B", "kind": "settlement", "parent": null},
	}
	var events := {
		"e.fight": ToyCanon.event(1, 1, {"location": "market_a"}),
		"e.far": ToyCanon.event(1, 1, {"location": "town_b"}),
		"e.old": ToyCanon.event(1, 1, {"location": "town_a"}),
		"e.t1": ToyCanon.event(1, 1, {"location": "town_b", "tier": 1}),
	}
	d.canon = CanonDb.from_dicts({"guard": _npc("market_a", ["human", "guard"]), "baker": _npc("town_a"),
			"drifter": _npc(null)}, locs, events)
	assert_eq(d.canon.errors, [] as Array[String])
	d.talk = talk
	return d


## Day 5; news: e.old (day 1, too old), e.fight (cast guard), e.far, e.t1 rumour.
func _gs(d: DataDb) -> GameState:
	var gs := GameState.new_game(7, d)
	gs.clock.total_minutes = 4 * 1440 + 9 * 60
	gs.world.add_news(1, "e.old", Director.NEWS, "Old news.")
	gs.world.add_news(4, "e.fight", Director.NEWS, "A fight in the market.")
	gs.world.add_news(4, "e.far", Director.NEWS, "Far news.")
	gs.world.add_news(5, "e.t1", Director.RUMOR, "A rumour.")
	gs.world.events["e.fight"] = {"status": "done", "day": 4, "roles": {"hero": "guard", "crowd": "*crowd"}}
	return gs


func _texts(p: Array[Dictionary]) -> Dictionary:
	var out := {}
	for t in p:
		out[t["text"]] = t["source"]
	return out


func test_news_sources_by_cast_town_and_rumour() -> void:
	var d := _db()
	var gs := _gs(d)
	assert_eq(_texts(TalkTopics.pool(gs, d, "guard")),
			{"A rumour.": "rumor", "A fight in the market.": "own"}, "old and far news left out")
	assert_eq(_texts(TalkTopics.pool(gs, d, "baker")),
			{"A rumour.": "rumor", "A fight in the market.": "town"})
	assert_eq(_texts(TalkTopics.pool(gs, d, "drifter")), {"A rumour.": "rumor"}, "no home: rumours only")
	assert_eq(TalkTopics.npc_town(d, "guard"), "town_a")
	assert_eq(TalkTopics.event_town(d, "e.far"), "town_b")


func test_topic_gates() -> void:
	var d := _db({
		"t.any": {"kind": "news", "text": "Any.", "confidence": "guess"},
		"t.npc": {"kind": "rumor", "text": "Npc.", "confidence": "guess", "who": {"npcs": ["baker"]}},
		"t.tag": {"kind": "request", "text": "Tag.", "confidence": "guess", "who": {"tags": ["guard"]}},
		"t.town": {"kind": "news", "text": "Town.", "confidence": "guess", "who": {"towns": ["town_a"]}},
		"t.flag": {"kind": "news", "text": "Flag.", "confidence": "guess", "flags": ["x.on"]},
		"t.not": {"kind": "news", "text": "Not.", "confidence": "guess", "not_flags": ["x.on"]},
		"t.days": {"kind": "news", "text": "Days.", "confidence": "guess", "days": [6, 9]},
	})
	var gs := _gs(d)
	gs.world.news.clear()
	assert_eq(_texts(TalkTopics.pool(gs, d, "guard")),
			{"Any.": "topic", "Not.": "topic", "Tag.": "request", "Town.": "topic"})
	assert_eq(_texts(TalkTopics.pool(gs, d, "drifter")), {"Any.": "topic", "Not.": "topic"})
	gs.flags["x.on"] = true
	gs.clock.total_minutes = 6 * 1440
	assert_eq(_texts(TalkTopics.pool(gs, d, "baker")),
			{"Any.": "topic", "Npc.": "topic", "Town.": "topic", "Flag.": "topic", "Days.": "topic"})


func test_line_is_seeded_and_formatted() -> void:
	var d := _db()
	var a := TalkTopics.line(_gs(d), d, "guard")
	assert_true(a == "NPC: \"A fight in the market.\"" or a == "NPC: \"A rumour.\"", a)
	assert_eq(TalkTopics.line(_gs(d), d, "guard"), a, "same seed, same line")
	var seen := {}
	var gs := _gs(d)
	for i in 40:
		seen[TalkTopics.line(gs, d, "guard")] = true
	assert_eq(seen.size(), 2, "both topics come up")


func test_no_line_without_rules_topics_or_regard() -> void:
	var d := _db()
	var gs := _gs(d)
	gs.world.add_relationship("guard", NpcSim.PLAYER, -1)
	assert_eq(TalkTopics.line(gs, d, "guard"), "", "below min_regard")
	gs.world.news.clear()
	assert_eq(TalkTopics.line(gs, d, "baker"), "", "empty pool")
	var toy := ToyData.db()
	assert_false(TalkTopics.on(toy))
	assert_eq(TalkTopics.line(gs, toy, "baker"), "", "no rules.talk")


func test_validate() -> void:
	var d := _db({
		"ok": {"kind": "request", "text": "Fine.", "confidence": "guess", "who": {"npcs": ["guard"]}},
		"bad_kind": {"kind": "gossip", "text": "x", "confidence": "guess"},
		"no_text": {"kind": "news", "text": " ", "confidence": "guess"},
		"bad_who": {"kind": "news", "text": "x", "confidence": "guess", "who": {"npcs": ["ghost"], "towns": ["nowhere"], "race": []}},
		"bad_days": {"kind": "news", "text": "x", "confidence": "guess", "days": [5, 2]},
		"bad_conf": {"kind": "news", "text": "x", "confidence": "maybe"},
		"missing": {"kind": "news"},
	})
	var errs := " ".join(TalkTopics.validate(d))
	for want in ["'bad_kind': kind", "'no_text': text", "unknown npc 'ghost'", "unknown town 'nowhere'",
			"who.race", "'bad_days': days", "'bad_conf': confidence", "'missing': missing 'text'"]:
		assert_true(errs.contains(want), want)
	assert_false(errs.contains("'ok'"), errs)
	d.rules["talk"].erase("weights")
	assert_eq(TalkTopics.validate(d), ["rules.talk: missing 'weights'."] as Array[String])


func test_real_data_loads_and_npcs_talk_once_a_day() -> void:
	var d := DataDb.load_dir()
	assert_eq(d.errors, [] as Array[String])
	assert_gte(d.talk.size(), 15)
	for id: String in d.talk:
		if d.talk[id]["kind"] == "request":
			assert_eq(d.talk[id]["confidence"], "guess", "request hints are game hints: %s" % id)
	var gs := GameState.new_game(20261012, d)
	gs.player.place("liscor_market", Vector2i(5, 5))
	gs.npcs.npcs["krshia"]["area"] = "liscor_market"
	gs.npcs.npcs["krshia"]["x"] = 6
	gs.npcs.npcs["krshia"]["y"] = 5
	assert_false(TalkTopics.pool(gs, d, "krshia").is_empty(), "Krshia always has her stall hint")
	var r := Interact.perform(gs, d, "krshia", "talk_with_guest")
	assert_eq(r["error"], "")
	var said := func() -> int:
		return gs.combat.lines.filter(func(l: String) -> bool: return l.begins_with("Krshia: \"")).size()
	assert_eq(said.call(), 2, "her own greeting and one line: " + str(gs.combat.lines))
	Interact.perform(gs, d, "krshia", "talk_with_guest")
	assert_eq(said.call(), 2, "one talk a day")
