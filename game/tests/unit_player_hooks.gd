extends GutTest
## Player hooks and local news (M6.4, ADR 0011) on toy canon. The toy game
## starts on day 1 at 06:00; ToyData has the actions "cook" and "fight".


func _db(events: Dictionary) -> DataDb:
	var d := ToyData.db()
	d.canon = CanonDb.from_dicts(ToyCanon.npcs(), {}, events)
	assert_eq(d.canon.errors, [] as Array[String])
	return d


func _gs(d: DataDb) -> GameState:
	return GameState.new_game(3, d)


## The player does `action` now, with this context and outcome.
func _do(gs: GameState, d: DataDb, action: String = "fight", context: Dictionary = {"enemy": "crab"},
		outcome: String = "success") -> void:
	var rec := Actions.perform(gs, d, action, {"context": context, "outcome": outcome})
	assert_false(rec.is_empty(), "the deed is logged")


## A hook that matches a won fight against a crab on days 1–2.
func _hook(then: String, extra: Dictionary = {}) -> Dictionary:
	var h := {"id": "beat_crab", "then": then, "days": [1, 2],
		"did": [{"action": ["fight"], "outcome": ["success"], "context": {"enemy": "crab"}}]}
	h.merge(extra, true)
	return h


func test_record_keeps_its_context() -> void:
	var d := ToyData.db()
	var gs := _gs(d)
	var rec := Actions.perform(gs, d, "fight", {"context": {"enemy": "crab", "location": "toy"}})
	assert_eq(rec["context"], {"enemy": "crab", "location": "toy"})


func test_cancel_hook_cancels_the_event_and_its_dependents() -> void:
	var d := _db({
		"e.x": ToyCanon.event(2, 2, {"hooks": [_hook("cancel", {"news": "No crab came."})],
				"news": "A crab came.", "effects": {"set_flags": ["x.done"]}}),
		"e.after": ToyCanon.event(3, 3, {"depends_on": ["e.x"]}),
	})
	var gs := _gs(d)
	_do(gs, d)
	Director.run(gs, d, 3)
	assert_eq(ToyCanon.timeline(gs), ["D2 cancelled e.x", "D2 cancelled e.after"] as Array[String])
	var h: Dictionary = gs.world.history[0]
	assert_eq(h["by"], Director.BY_PLAYER)
	assert_eq(h["hook"], "beat_crab")
	assert_false(gs.world.history[1].has("by"), "the dependent was not the player's own change")
	assert_false(gs.flags.has("x.done"))
	assert_eq(gs.world.drift, 2.0)
	assert_eq(gs.world.news, [{"day": 2, "event": "e.x", "kind": "news", "text": "No crab came."}])


func test_without_the_deed_the_event_runs_as_canon() -> void:
	var d := _db({"e.x": ToyCanon.event(2, 2, {"hooks": [_hook("cancel")]})})
	var cases := [
		["cook", {"enemy": "crab"}, "success"],
		["fight", {"enemy": "rat"}, "success"],
		["fight", {"enemy": "crab"}, "fail"],
		["fight", {}, "success"],
	]
	for c: Array in cases:
		var gs := _gs(d)
		_do(gs, d, c[0], c[1], c[2])
		Director.run(gs, d, 2)
		assert_eq(gs.world.status("e.x"), Director.DONE, str(c))
		assert_eq(gs.world.drift, 0.0)


func test_context_may_list_several_values() -> void:
	var hook := _hook("cancel")
	hook["did"][0]["context"]["enemy"] = ["rat", "crab"]
	var d := _db({"e.x": ToyCanon.event(2, 2, {"hooks": [hook]})})
	var gs := _gs(d)
	_do(gs, d)
	Director.run(gs, d, 2)
	assert_eq(gs.world.status("e.x"), Director.CANCELLED)


func test_deed_outside_the_hook_days_does_not_count() -> void:
	var d := _db({"e.x": ToyCanon.event(2, 2, {"hooks": [_hook("cancel", {"days": [2, 2]})]})})
	var gs := _gs(d)
	_do(gs, d)
	Director.run(gs, d, 2)
	assert_eq(gs.world.status("e.x"), Director.DONE, "the fight was on day 1")


func test_deed_after_the_event_day_does_not_count() -> void:
	var d := _db({"e.x": ToyCanon.event(1, 1, {"hooks": [_hook("cancel", {"days": [1, 5]})]})})
	var gs := _gs(d)
	gs.clock.advance(Clock.MINUTES_PER_DAY)
	_do(gs, d)
	Director.run(gs, d, 1)
	assert_eq(gs.world.status("e.x"), Director.DONE, "day 1 was over before the fight on day 2")


func test_mutate_hook_runs_the_alternative() -> void:
	var d := _db({
		"e.x": ToyCanon.event(2, 2, {"hooks": [_hook("mutate:e.alt")], "effects": {"set_flags": ["x.done"]}}),
		"e.alt": ToyCanon.event(2, 2, {"effects": {"set_flags": ["alt.done"]}, "news": "Something else."}),
	})
	assert_true(d.canon.alt_only.has("e.alt"), "a hook target only runs in place of its event")
	var gs := _gs(d)
	_do(gs, d)
	Director.run(gs, d, 2)
	assert_eq(ToyCanon.timeline(gs), ["D2 mutated e.x", "D2 done e.alt"] as Array[String])
	assert_eq(gs.world.history[0]["via"], "e.alt")
	assert_eq(gs.world.history[0]["by"], Director.BY_PLAYER)
	assert_true(gs.flags.has("alt.done"))
	assert_false(gs.flags.has("x.done"))
	assert_eq(gs.world.drift, 0.5)
	assert_eq(gs.world.news.size(), 1)
	assert_eq(gs.world.news[0]["text"], "Something else.")


func test_mutate_hook_is_skipped_when_the_alternative_cannot_run() -> void:
	var d := _db({
		"e.x": ToyCanon.event(2, 2, {"hooks": [_hook("mutate:e.alt")]}),
		"e.alt": ToyCanon.event(2, 2, {"requires": ToyCanon.req([], ["never"])}),
	})
	var gs := _gs(d)
	_do(gs, d)
	Director.run(gs, d, 2)
	assert_eq(ToyCanon.timeline(gs), ["D2 done e.x"] as Array[String])


func test_first_matching_hook_wins() -> void:
	var miss := _hook("cancel", {"id": "miss"})
	miss["did"][0]["context"]["enemy"] = "rat"
	var d := _db({
		"e.x": ToyCanon.event(2, 2, {"hooks": [miss, _hook("mutate:e.alt")]}),
		"e.alt": ToyCanon.event(2, 2),
	})
	var gs := _gs(d)
	_do(gs, d)
	Director.run(gs, d, 2)
	assert_eq(gs.world.history[0]["hook"], "beat_crab")
	assert_eq(gs.world.status("e.x"), Director.MUTATED)


func test_change_hook_adds_effects_and_the_event_still_counts() -> void:
	var d := _db({
		"e.x": ToyCanon.event(2, 2, {"news": "Canon news.", "effects": {"set_flags": ["x.done"]},
			"hooks": [_hook("change", {"effects": {"set_flags": ["x.better"],
				"relationship": [{"from": "hero", "to": "mentor", "delta": 2}]}, "news": "Better news."})]}),
		"e.after": ToyCanon.event(3, 3, {"depends_on": ["e.x"]}),
	})
	var gs := _gs(d)
	_do(gs, d)
	Director.run(gs, d, 3)
	assert_eq(ToyCanon.timeline(gs), ["D2 changed e.x", "D3 done e.after"] as Array[String])
	assert_eq(gs.world.history[0]["by"], Director.BY_PLAYER)
	assert_true(gs.flags.has("x.done"), "the canon effects still happen")
	assert_true(gs.flags.has("x.better"))
	assert_eq(gs.world.relationship("hero", "mentor"), 2)
	assert_eq(gs.world.drift, 0.25)
	assert_eq(gs.world.news.map(func(n: Dictionary) -> String: return n["text"]), ["Better news."])


func test_change_hook_without_news_keeps_the_event_news() -> void:
	var d := _db({"e.x": ToyCanon.event(2, 2, {"news": "Canon news.",
			"hooks": [_hook("change", {"effects": {"set_flags": ["x.better"]}})]})})
	var gs := _gs(d)
	_do(gs, d)
	Director.run(gs, d, 2)
	assert_eq(gs.world.news[0]["text"], "Canon news.")


func test_news_and_rumors_are_kept() -> void:
	var d := _db({
		"e.local": ToyCanon.event(1, 1, {"news": "Local talk."}),
		"e.far": ToyCanon.event(1, 1, {"tier": 1, "rumor": "Far talk."}),
		"e.quiet": ToyCanon.event(1, 1),
	})
	var gs := _gs(d)
	Director.run(gs, d, 1)
	assert_eq(gs.world.news, [
		{"day": 1, "event": "e.far", "kind": "rumor", "text": "Far talk."},
		{"day": 1, "event": "e.local", "kind": "news", "text": "Local talk."},
	])
	assert_eq(gs.world.news_since(2), [] as Array[Dictionary])


func test_night_result_has_the_news() -> void:
	var d := _db({"e.local": ToyCanon.event(1, 1, {"news": "Local talk."}),
			"e.far": ToyCanon.event(1, 1, {"tier": 1, "rumor": "Far talk."})})
	var gs := _gs(d)
	gs.clock.advance(14 * 60)
	var night := Commands.sleep(gs, d)
	assert_eq(night["news"], ["Local talk."] as Array[String], "rumors stay in the world section")
	assert_true((night["lines"] as Array).has("News: Local talk."))
	var news_i := (night["lines"] as Array).find("News: Local talk.")
	var rumor_i := (night["lines"] as Array).find("Rumor: Far talk.")
	assert_lt(news_i, rumor_i, "news come before the world lines")


func test_canon_db_checks_hooks() -> void:
	var bad := func(hook: Dictionary) -> Array[String]:
		return CanonDb.from_dicts(ToyCanon.npcs(), {},
				{"e.x": ToyCanon.event(1, 1, {"hooks": [hook]})}).errors
	var no_then := _hook("cancel")
	no_then.erase("then")
	assert_string_contains(", ".join(bad.call(no_then)), "missing 'then'")
	assert_string_contains(", ".join(bad.call(_hook("explode"))), "'then' must be")
	assert_string_contains(", ".join(bad.call(_hook("change"))), "'change' needs effects")
	assert_string_contains(", ".join(bad.call(_hook("mutate:e.ghost"))), "mutate target 'e.ghost' is unknown")
	assert_string_contains(", ".join(bad.call(_hook("cancel", {"days": [3, 1]}))), "'days'")
	assert_string_contains(", ".join(bad.call(_hook("cancel", {"did": []}))), "'did' is empty")
	assert_string_contains(", ".join(bad.call(_hook("change", {"effects": {"kill": ["ghost"]}}))),
			"unknown npc 'ghost'")
	var twice := CanonDb.from_dicts(ToyCanon.npcs(), {},
			{"e.x": ToyCanon.event(1, 1, {"hooks": [_hook("cancel"), _hook("cancel")]})}).errors
	assert_string_contains(", ".join(twice), "duplicate hook id")


func test_news_and_record_context_survive_save_and_load() -> void:
	var d := _db({"e.local": ToyCanon.event(1, 1, {"news": "Local talk."})})
	var gs := _gs(d)
	_do(gs, d)
	Director.run(gs, d, 1)
	var loaded := GameState.from_json(gs.to_json())
	assert_eq(loaded.to_json(), gs.to_json())
	assert_eq(typeof(loaded.world.news[0]["day"]), TYPE_INT)
	assert_eq(loaded.action_log.records[-1]["context"], {"enemy": "crab"})


func test_v6_save_migrates_to_v7() -> void:
	var d := _db({"e.local": ToyCanon.event(1, 1, {"news": "Local talk."})})
	var gs := _gs(d)
	_do(gs, d)
	var old := gs.to_dict()
	old["save_version"] = 6
	(old["world"] as Dictionary).erase("news")
	for r: Dictionary in old["action_log"]["records"]:
		r.erase("context")
	var loaded := GameState.from_json(JSON.stringify(SaveCodec.encode(old)))
	assert_not_null(loaded)
	assert_eq(loaded.save_version, GameState.SAVE_VERSION)
	assert_eq(loaded.world.news, [] as Array[Dictionary])
	assert_eq(loaded.action_log.records[-1]["context"], {})
	Director.run(loaded, d, 1)
	assert_eq(loaded.world.news.size(), 1, "a migrated game hears news from now on")
