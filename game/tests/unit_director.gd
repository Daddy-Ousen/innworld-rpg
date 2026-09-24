extends GutTest

const EPS := 0.000001


## A toy db with these events and ToyCanon's NPCs.
func _db(events: Dictionary, rules_patch: Dictionary = {}) -> DataDb:
	var d := ToyData.db()
	d.rules["director"].merge(rules_patch, true)
	d.canon = CanonDb.from_dicts(ToyCanon.npcs(), {}, events)
	assert_eq(d.canon.errors, [] as Array[String])
	return d


func _gs(d: DataDb) -> GameState:
	return GameState.new_game(3, d)


func test_event_fires_on_the_first_day_it_can() -> void:
	var d := _db({"e.x": ToyCanon.event(2, 4, {"requires": ToyCanon.req([], ["ready"]),
			"effects": {"set_flags": ["x.done"], "clear_flags": ["ready"]}})})
	var gs := _gs(d)
	Director.run(gs, d, 2)
	assert_eq(gs.world.status("e.x"), WorldState.PENDING, "waits inside its window")
	assert_true(gs.world.history.is_empty())
	Commands.set_flag(gs, "ready")
	Director.run(gs, d, 3)
	assert_eq(ToyCanon.timeline(gs), ["D3 done e.x"] as Array[String])
	assert_true(gs.flags.has("x.done"))
	assert_false(gs.flags.has("ready"), "clear_flags")


func test_event_before_its_window_does_not_run() -> void:
	var d := _db({"e.x": ToyCanon.event(5, 5)})
	var gs := _gs(d)
	Director.run(gs, d, 4)
	assert_eq(gs.world.status("e.x"), WorldState.PENDING)
	assert_eq(gs.world.last_day, 4)


func test_same_day_flag_chain_without_depends_on() -> void:
	var d := _db({
		"e.a_second": ToyCanon.event(2, 2, {"requires": ToyCanon.req([], ["f"])}),
		"e.z_first": ToyCanon.event(2, 2, {"effects": {"set_flags": ["f"]}}),
	})
	var gs := _gs(d)
	Director.run(gs, d, 2)
	assert_eq(ToyCanon.timeline(gs), ["D2 done e.z_first", "D2 done e.a_second"] as Array[String])


func test_delay_uses_the_default_limit_then_cancels() -> void:
	var d := _db({"e.x": ToyCanon.event(1, 1, {"requires": ToyCanon.req([], ["never"]),
			"on_fail": ["delay", "cancel"]})}, {"default_delay_limit": 2})
	var gs := _gs(d)
	Director.run(gs, d, 5)
	assert_eq(ToyCanon.timeline(gs), ["D1 delayed e.x", "D2 delayed e.x", "D3 cancelled e.x"] as Array[String])
	assert_string_contains(gs.world.history[2]["reason"], "needs never")


func test_delay_cannot_fix_a_dead_npc() -> void:
	var d := _db({"e.x": ToyCanon.event(1, 3, {"requires": ToyCanon.req(["mentor"]), "on_fail": ["delay", "cancel"]})})
	var gs := _gs(d)
	Commands.kill_npc(gs, d, "mentor")
	Director.run(gs, d, 1)
	assert_eq(gs.world.status("e.x"), Director.CANCELLED, "no waiting for a hard failure")


func test_substitute_takes_most_matching_tags_then_lowest_id() -> void:
	var d := _db({
		"e.most": ToyCanon.event(1, 1, {"roles": {"r": ToyCanon.role(["guard_a"], ["human", "guard"])},
				"on_fail": ["substitute", "cancel"]}),
		"e.tie": ToyCanon.event(1, 1, {"roles": {"r": ToyCanon.role(["guard_a"], ["guard"])},
				"on_fail": ["substitute", "cancel"]}),
	})
	var gs := _gs(d)
	Commands.kill_npc(gs, d, "guard_a")
	Director.run(gs, d, 1)
	assert_eq(gs.world.events["e.most"]["roles"], {"r": "guard_c"}, "human+guard beats guard")
	assert_eq(gs.world.events["e.tie"]["roles"], {"r": "guard_b"}, "tie → lowest id")
	assert_eq(gs.world.status("e.tie"), Director.SUBSTITUTED)


func test_substitute_with_no_match_cancels() -> void:
	var d := _db({"e.x": ToyCanon.event(1, 1, {"roles": {"r": ToyCanon.role(["far_king"], ["royal"])},
			"on_fail": ["substitute", "cancel"]})})
	var gs := _gs(d)
	Commands.kill_npc(gs, d, "far_king")
	Director.run(gs, d, 1)
	assert_eq(gs.world.status("e.x"), Director.CANCELLED)


func test_later_prefer_npc_fills_the_role_without_drift() -> void:
	var d := _db({"e.x": ToyCanon.event(1, 1, {"roles": {"r": ToyCanon.role(["guard_a", "guard_c"], [])},
			"effects": {"kill": ["guard_a"]}})})
	var gs := _gs(d)
	Commands.kill_npc(gs, d, "guard_a")
	Director.run(gs, d, 1)
	assert_eq(gs.world.status("e.x"), Director.DONE)
	assert_false(gs.world.is_alive(d.canon, "guard_c"), "kill follows the role")
	assert_almost_eq(gs.world.drift, 0.0, EPS)


func test_revive_brings_a_dead_npc_back() -> void:
	var d := _db({
		"e.kill": ToyCanon.event(1, 1, {"effects": {"kill": ["mentor"]}}),
		"e.back": ToyCanon.event(2, 2, {"effects": {"revive": ["mentor"], "set_flags": ["mentor.back"]}}),
		"e.needs": ToyCanon.event(3, 3, {"requires": ToyCanon.req(["mentor"])}),
	})
	var gs := _gs(d)
	Director.run(gs, d, 1)
	assert_false(gs.world.is_alive(d.canon, "mentor"))
	Director.run(gs, d, 3)
	assert_true(gs.world.is_alive(d.canon, "mentor"), "revive")
	assert_eq(gs.world.status("e.needs"), Director.DONE, "alive again for later events")
	var back := GameState.from_dict(gs.to_dict())
	assert_true(back.world.is_alive(d.canon, "mentor"), "survives a save")


func test_revive_runs_after_kill_in_one_event() -> void:
	var d := _db({"e.x": ToyCanon.event(1, 1, {"effects": {"kill": ["guard_a"], "revive": ["mentor"]}})})
	var gs := _gs(d)
	Commands.kill_npc(gs, d, "mentor")
	Director.run(gs, d, 1)
	assert_false(gs.world.is_alive(d.canon, "guard_a"))
	assert_true(gs.world.is_alive(d.canon, "mentor"))


func test_revive_unknown_npc_is_a_data_error() -> void:
	var c := CanonDb.from_dicts(ToyCanon.npcs(), {}, {"e.x": ToyCanon.event(1, 1, {"effects": {"revive": ["zed"]}})})
	assert_eq(c.errors.size(), 1)
	assert_string_contains(c.errors[0], "effects.revive")


func test_substitute_then_delay_for_a_missing_flag() -> void:
	var d := _db({"e.x": ToyCanon.event(1, 1, {"roles": {"r": ToyCanon.role(["guard_a"], ["guard"])},
			"requires": ToyCanon.req([], ["late"]), "on_fail": ["substitute", "delay", "cancel"]})})
	var gs := _gs(d)
	Commands.kill_npc(gs, d, "guard_a")
	Director.run(gs, d, 1)
	assert_eq(gs.world.status("e.x"), WorldState.PENDING)
	Commands.set_flag(gs, "late")
	Director.run(gs, d, 2)
	assert_eq(gs.world.status("e.x"), Director.SUBSTITUTED)


func test_anonymous_role_never_takes_a_named_npc() -> void:
	var d := _db({"e.x": ToyCanon.event(1, 1, {"roles": {"crowd": ToyCanon.role([], ["guard"])}})})
	var gs := _gs(d)
	Director.run(gs, d, 1)
	assert_eq(gs.world.events["e.x"]["roles"], {"crowd": "*guard"})


func test_optional_role_may_stay_empty() -> void:
	var d := _db({"e.x": ToyCanon.event(1, 1, {"roles": {"watcher": ToyCanon.role(["mentor"], [], true)}})})
	var gs := _gs(d)
	Commands.kill_npc(gs, d, "mentor")
	Director.run(gs, d, 1)
	assert_eq(gs.world.status("e.x"), Director.DONE)
	assert_eq(gs.world.events["e.x"]["roles"], {})


func test_one_npc_fills_only_one_role() -> void:
	var d := _db({"e.x": ToyCanon.event(1, 1, {"roles": {
		"a": ToyCanon.role(["hero"], []), "b": ToyCanon.role(["hero"], ["human"])},
		"on_fail": ["substitute", "cancel"]})})
	var gs := _gs(d)
	Director.run(gs, d, 1)
	assert_eq(gs.world.events["e.x"]["roles"], {"a": "hero", "b": "guard_c"})


func test_evaluate_reports_failure_kinds() -> void:
	var d := _db({
		"e.dep": ToyCanon.event(9, 9),
		"e.x": ToyCanon.event(1, 1, {"requires": ToyCanon.req(["mentor"], ["f"], ["g"]),
				"depends_on": ["e.dep"], "roles": {"r": ToyCanon.role(["villain"], [])}}),
	})
	var gs := _gs(d)
	Commands.kill_npc(gs, d, "mentor")
	Commands.kill_npc(gs, d, "villain")
	Commands.set_flag(gs, "g")
	var fails: Array = Director.evaluate(gs, d, "e.x")["fails"]
	assert_eq(fails.map(func(f: Dictionary) -> String: return f["kind"]),
			["hard", "wait", "wait", "wait", "role"])


func test_cancel_propagates_down_the_chain() -> void:
	var d := _db({
		"e.a": ToyCanon.event(1, 1, {"requires": ToyCanon.req(["mentor"])}),
		"e.b": ToyCanon.event(5, 5, {"depends_on": ["e.a"], "on_fail": ["substitute", "delay", "cancel"]}),
		"e.c": ToyCanon.event(9, 9, {"depends_on": ["e.b"], "on_fail": ["mutate:e.c_alt", "cancel"]}),
		"e.c_alt": ToyCanon.event(9, 9, {"effects": {"set_flags": ["c.alt"]}}),
		"e.d": ToyCanon.event(2, 2),
	})
	var gs := _gs(d)
	Commands.kill_npc(gs, d, "mentor")
	Director.run(gs, d, 1)
	assert_eq(ToyCanon.timeline(gs), ["D1 killed player.kill", "D1 cancelled e.a", "D1 cancelled e.b",
			"D1 mutated e.c", "D1 done e.c_alt"] as Array[String])
	assert_true(gs.flags.has("c.alt"), "a dependent may still mutate")
	assert_eq(gs.world.status("e.d"), WorldState.PENDING, "unrelated events untouched")
	assert_almost_eq(gs.world.drift, 1.0 + 1.0 + 0.5, EPS)


func test_mutate_skips_an_alt_that_cannot_run() -> void:
	var d := _db({
		"e.x": ToyCanon.event(1, 1, {"requires": ToyCanon.req(["mentor"]), "on_fail": ["mutate:e.alt", "cancel"]}),
		"e.alt": ToyCanon.event(1, 1, {"requires": ToyCanon.req(["mentor"])}),
	})
	var gs := _gs(d)
	Commands.kill_npc(gs, d, "mentor")
	Director.run(gs, d, 1)
	assert_eq(gs.world.status("e.x"), Director.CANCELLED)
	assert_eq(gs.world.status("e.alt"), WorldState.PENDING)


func test_tier1_rumor_and_drift_weight() -> void:
	var d := _db({
		"e.news": ToyCanon.event(1, 1, {"tier": 1, "rumor": "Big news."}),
		"e.lost": ToyCanon.event(1, 1, {"tier": 1, "rumor": "Never heard.", "requires": ToyCanon.req(["far_king"])}),
	})
	var gs := _gs(d)
	Commands.kill_npc(gs, d, "far_king")
	var lines := Director.run(gs, d, 1)
	assert_eq(lines, ["Rumor: Big news."] as Array[String])
	assert_almost_eq(gs.world.drift, 1.0 * 0.5, EPS, "cancelled × tier 1 weight")


func test_unreliable_line_once_when_drift_crosses_the_limit() -> void:
	var d := _db({
		"e.a": ToyCanon.event(1, 1, {"requires": ToyCanon.req(["mentor"])}),
		"e.b": ToyCanon.event(2, 2, {"requires": ToyCanon.req(["mentor"])}),
	}, {"unreliable_at": 1.0})
	var gs := _gs(d)
	Commands.kill_npc(gs, d, "mentor")
	assert_eq(Director.run(gs, d, 1), [Director.UNRELIABLE_LINE] as Array[String])
	assert_eq(Director.run(gs, d, 2), [] as Array[String])


func test_player_kill_errors() -> void:
	var d := _db({})
	var gs := _gs(d)
	assert_string_contains(Commands.kill_npc(gs, d, "nobody"), "Unknown NPC")
	assert_eq(Commands.kill_npc(gs, d, "hero"), "")
	assert_string_contains(Commands.kill_npc(gs, d, "hero"), "already dead")
	assert_eq(gs.world.history.size(), 1)


func test_catch_up_over_many_days_equals_night_by_night() -> void:
	var d := ToyCanon.db()
	var a := _gs(d)
	Director.run(a, d, 7)
	var b := _gs(d)
	for day in range(1, 8):
		Director.run(b, d, day)
	assert_eq(a.world.to_dict(), b.world.to_dict())


func test_collapse_runs_the_skipped_day() -> void:
	var d := ToyCanon.db()
	var gs := _gs(d)
	gs.clock.advance(int(d.rules["clock"]["collapse_after_awake"]))  # day 2, 18:00
	var night := Commands.sleep(gs, d)
	assert_eq(gs.clock.day(), 3)
	assert_eq(gs.world.last_day, 2)
	assert_eq(night["lines"], ["You collapsed. The System still works while you sleep.",
			"Rumor: A new king was crowned far away."] as Array[String])
	assert_eq((night["events"] as Array).size(), 1)


func test_save_and_load_mid_game_gives_the_same_history() -> void:
	var d := ToyCanon.db()
	var straight := _gs(d)
	Commands.set_flag(straight, "village.walls_built")
	ToyCanon.sleep_through(straight, d, 3)
	var loaded := GameState.from_json(straight.to_json())
	assert_eq(loaded.to_json(), straight.to_json())
	ToyCanon.sleep_through(straight, d, 7)
	ToyCanon.sleep_through(loaded, d, 7)
	assert_eq(loaded.world.to_dict(), straight.world.to_dict())
