extends GutTest
## Breakthroughs (M22, ADR 0035) on toy data. Toy capstone is level 3, so a
## class waits for its key at level 2. Level 2 → 3 costs 200 XP (total level 2).

const HINT := "Something must still test you as %s."


func _db(events: Dictionary = {}, class_extra: Dictionary = {}) -> DataDb:
	var d := ToyData.db()
	d.rules["levels"]["breakthrough"] = {"min_match": 0.5, "bars": {"risk": 0.6, "duress": 1.8, "window": 2.0},
			"need": {"3": 1}, "hint": HINT}
	d.classes["cook"].merge(class_extra, true)
	d.canon = CanonDb.from_dicts(ToyCanon.npcs(), {}, events)
	assert_eq(d.canon.errors, [] as Array[String])
	return d


func _gs(d: DataDb) -> GameState:
	return GameState.new_game(3, d)


func _rec(action: String = "cook", bars: Dictionary = {}, outcome: String = "success") -> Dictionary:
	var r := {"action_id": action, "tags": {"cooking.stew": 1.0} if action == "cook" else {"combat": 1.0},
		"outcome": outcome, "context": {}, "risk": 0.0, "duress": 1.0, "window": 1.0}
	r.merge(bars, true)
	return r


## A boon hook on cooking on days 1-2.
func _boon(fx: Dictionary = {"breakthrough": {"tags": {"cooking": 1.0}}}) -> Dictionary:
	return {"id": "cooked_well", "then": "boon", "days": [1, 2], "did": [{"action": ["cook"]}],
		"effects": fx, "news": "The soup was the talk of the town."}


func test_waiting_for_only_one_level_under_a_capstone_without_a_key() -> void:
	var d := _db()
	var gs := _gs(d)
	var rules: Dictionary = d.rules["levels"]
	assert_eq(Breakthrough.waiting_for(gs.progression, "cook", rules), 0, "not held")
	ToyData.give_class(gs, "cook", 1)
	assert_eq(Breakthrough.waiting_for(gs.progression, "cook", rules), 0, "two levels under")
	ToyData.give_class(gs, "cook", 2)
	assert_eq(Breakthrough.waiting_for(gs.progression, "cook", rules), 3)
	gs.progression.breakthroughs.append("cook")
	assert_eq(Breakthrough.waiting_for(gs.progression, "cook", rules), 0, "has its key")


func test_hard_moment_needs_fit_no_fail_and_enough_bars() -> void:
	var d := _db()
	var bt := Breakthrough.rules_of(d)
	var cook: Dictionary = d.classes["cook"]
	assert_true(Breakthrough.is_hard_moment(_rec("cook", {"duress": 1.8}), cook, bt, 3))
	assert_true(Breakthrough.is_hard_moment(_rec("cook", {"risk": 0.6}), cook, bt, 3))
	assert_true(Breakthrough.is_hard_moment(_rec("cook", {"window": 2.0}), cook, bt, 3))
	assert_false(Breakthrough.is_hard_moment(_rec("cook"), cook, bt, 3), "no bar passed")
	assert_false(Breakthrough.is_hard_moment(_rec("fight", {"duress": 2.0}), cook, bt, 3), "does not fit")
	assert_false(Breakthrough.is_hard_moment(_rec("cook", {"duress": 2.0}, "fail"), cook, bt, 3), "failed")
	assert_true(Breakthrough.is_hard_moment(_rec("cook", {"duress": 2.0}, "partial"), cook, bt, 3))
	bt["need"]["3"] = 2
	assert_false(Breakthrough.is_hard_moment(_rec("cook", {"duress": 2.0}), cook, bt, 3), "need 2 bars")
	assert_true(Breakthrough.is_hard_moment(_rec("cook", {"duress": 2.0, "risk": 0.7}), cook, bt, 3))
	assert_false(Breakthrough.is_hard_moment(_rec("cook", {"duress": 2.0}), cook, {}, 3), "no rules: off")


func test_old_records_without_bars_use_plain_values() -> void:
	var d := _db()
	var old := {"action_id": "cook", "tags": {"cooking": 1.0}, "outcome": "success"}
	assert_false(Breakthrough.is_hard_moment(old, d.classes["cook"], Breakthrough.rules_of(d), 3))


func test_trial_matches_action_outcome_min_and_capstone() -> void:
	var trial := {"action": ["cook"], "outcome": ["success"], "min": {"duress": 1.5}, "at": [3]}
	assert_true(Breakthrough.passes_trial(_rec("cook", {"duress": 1.5}), trial, 3))
	assert_false(Breakthrough.passes_trial(_rec("cook", {"duress": 1.4}), trial, 3), "below min")
	assert_false(Breakthrough.passes_trial(_rec("fight", {"duress": 2.0}), trial, 3), "other action")
	assert_false(Breakthrough.passes_trial(_rec("cook", {"duress": 2.0}, "partial"), trial, 3), "outcome")
	assert_false(Breakthrough.passes_trial(_rec("cook", {"duress": 2.0}), trial, 20), "not at this capstone")
	assert_true(Breakthrough.passes_trial(_rec("fight"), {"action": ["fight"]}, 20), "no at = all capstones")


func test_default_false_means_only_trials_count() -> void:
	var d := _db({}, {"breakthrough": {"default": false, "trials": [{"action": ["fight"]}]}})
	var records: Array[Dictionary] = [_rec("cook", {"duress": 2.0})]
	assert_false(Breakthrough.earned(d, "cook", records, 3), "the hard moment is off")
	records.append(_rec("fight"))
	assert_true(Breakthrough.earned(d, "cook", records, 3), "the trial counts")


func test_night_hard_moment_gives_the_key_and_the_capstone() -> void:
	var d := _db()
	var gs := _gs(d)
	ToyData.give_class(gs, "cook", 2, 250.0)
	Actions.perform(gs, d, "cook", {"duress": 2.0})
	var night := Night.run(gs, d)
	assert_eq(gs.progression.level_of("cook"), 3)
	assert_false(gs.progression.breakthroughs.has("cook"), "the key is used up")
	var lines: Array = night["lines"]
	var key_i := lines.find("Breakthrough: [X] can grow past level 2.")
	assert_ne(key_i, -1, "the key line")
	assert_lt(key_i, lines.find("[X] reached level 3."), "the key line comes first")
	assert_false("\n".join(lines).contains("needs a breakthrough"))


func test_key_waits_until_the_xp_fills() -> void:
	var d := _db()
	var gs := _gs(d)
	ToyData.give_class(gs, "cook", 2, 0.0)
	Actions.perform(gs, d, "cook", {"duress": 2.0})
	Night.run(gs, d)
	assert_eq(gs.progression.level_of("cook"), 2)
	assert_true(gs.progression.breakthroughs.has("cook"), "kept for later")
	gs.progression.classes["cook"]["xp"] = 250.0
	Night.run(gs, d)
	assert_eq(gs.progression.level_of("cook"), 3)


func test_a_moment_below_the_level_is_lost() -> void:
	var d := _db()
	var gs := _gs(d)
	ToyData.give_class(gs, "cook", 1, 0.0)
	Actions.perform(gs, d, "cook", {"duress": 2.0, "risk": 1.0, "window": 3.0})
	Night.run(gs, d)
	assert_false(gs.progression.breakthroughs.has("cook"))


func test_a_class_reaching_the_level_tonight_is_not_checked_and_gets_the_hint() -> void:
	var d := _db()
	var gs := _gs(d)
	ToyData.give_class(gs, "cook", 1, 99.0)
	Actions.perform(gs, d, "cook", {"duress": 2.0})
	var night := Night.run(gs, d)
	assert_eq(gs.progression.level_of("cook"), 2)
	assert_false(gs.progression.breakthroughs.has("cook"), "today's records came too early")
	var lines: Array = night["lines"]
	var hint := HINT % "[X]"
	assert_gt(lines.find(hint), lines.find("[X] reached level 2."), "after the level line")
	assert_eq(lines.count(hint), 1)


func test_class_hint_replaces_the_rules_hint() -> void:
	var d := _db({}, {"breakthrough": {"hint": "Feed a crowd."}})
	assert_eq(Breakthrough.hint(d, "cook"), "Feed a crowd.")
	assert_eq(Breakthrough.hint(d, "warrior"), HINT % "[X]")


func test_boon_hook_runs_as_canon_and_gives_the_key() -> void:
	var d := _db({"e.feast": ToyCanon.event(1, 1, {"hooks": [_boon()], "news": "A feast.",
			"effects": {"set_flags": ["feast.done"]}})})
	var gs := _gs(d)
	ToyData.give_class(gs, "warrior", 2)
	ToyData.give_class(gs, "cook", 2)
	Actions.perform(gs, d, "cook")
	Director.run(gs, d, 1)
	assert_eq(ToyCanon.timeline(gs), ["D1 done e.feast"] as Array[String])
	var h: Dictionary = gs.world.history[0]
	assert_false(h.has("by"), "not a change the player made")
	assert_eq(h["boons"], ["cooked_well"])
	assert_eq(gs.world.drift, 0.0, "no drift")
	assert_true(gs.flags.has("feast.done"), "the event's own effects")
	assert_eq(gs.progression.breakthroughs, ["cook"] as Array[String], "the best-fitting class")
	assert_eq(gs.world.news[0]["text"], "The soup was the talk of the town.")


func test_boon_without_the_deed_or_a_waiting_class_gives_nothing() -> void:
	var d := _db({"e.feast": ToyCanon.event(1, 1, {"hooks": [_boon()]}),
			"e.late": ToyCanon.event(2, 2, {"hooks": [_boon({"breakthrough": {"class": "cook"}})]})})
	var gs := _gs(d)
	ToyData.give_class(gs, "cook", 1)
	Director.run(gs, d, 1)
	assert_true(gs.progression.breakthroughs.is_empty(), "no deed")
	Actions.perform(gs, d, "cook")
	Director.run(gs, d, 2)
	assert_eq(gs.world.status("e.late"), Director.DONE)
	assert_true(gs.progression.breakthroughs.is_empty(), "level 1 is not waiting")


func test_night_step_5b_levels_a_class_given_a_canon_key() -> void:
	var d := _db({"e.feast": ToyCanon.event(1, 1, {"hooks": [_boon({"breakthrough": {"class": "cook"}})]})})
	var gs := _gs(d)
	ToyData.give_class(gs, "cook", 2, 250.0)
	Actions.perform(gs, d, "cook")
	var night := Night.run(gs, d)
	assert_eq(gs.progression.level_of("cook"), 3, "the same night")
	var progress: Array = night["progress"]
	var key_i := progress.find("Breakthrough: [X] can grow past level 2.")
	assert_ne(key_i, -1)
	assert_eq(progress[key_i + 1], "[X] reached level 3.")
	var lines: Array = night["lines"]
	assert_lt(lines.find("[X] reached level 3."), lines.find("News: The soup was the talk of the town."),
			"progress lines come before the news")


func test_canon_db_checks_boon_and_event_effects() -> void:
	var bad := func(ev: Dictionary) -> String:
		return ", ".join(CanonDb.from_dicts(ToyCanon.npcs(), {}, {"e.x": ev}).errors)
	var no_fx := _boon()
	no_fx.erase("effects")
	assert_string_contains(bad.call(ToyCanon.event(1, 1, {"hooks": [no_fx]})), "'boon' needs effects")
	assert_string_contains(bad.call(ToyCanon.event(1, 1, {"effects": {"breakthrough": {"class": "cook"}}})),
			"only allowed in hook effects")


func test_validate_catches_bad_rules_trials_and_effects() -> void:
	var d := _db({"e.x": ToyCanon.event(1, 1, {"hooks": [_boon({"breakthrough": {"class": "ghost"}}),
			_boon({"breakthrough": {"tags": {"nope": 1.0}}}).merged({"id": "b2"}, true)]})},
			{"breakthrough": {"default": false, "trials": [{"action": ["juggle"], "min": {"luck": 1}, "at": [7]}]}})
	d.rules["levels"]["breakthrough"]["need"] = {"3": 5}
	d.rules["levels"]["breakthrough"]["bars"]["luck"] = 1.0
	var errs := ", ".join(Breakthrough.validate(d))
	for part: String in ["need for 3", "unknown bar 'luck'", "unknown action 'juggle'", "unknown min 'luck'",
			"at 7 is not a capstone", "unknown class 'ghost'", "unknown tag 'nope'"]:
		assert_string_contains(errs, part)
	assert_eq(Breakthrough.validate(_db()), [] as Array[String], "a clean toy db")


func test_real_data_has_breakthrough_rules_and_no_errors() -> void:
	var d := DataDb.load_dir()
	assert_false(Breakthrough.rules_of(d).is_empty())
	assert_eq(Breakthrough.validate(d), [] as Array[String])


func test_real_main_classes_have_trials_and_boon_hooks_exist() -> void:
	var d := DataDb.load_dir()
	for id: String in ["innkeeper", "cook", "warrior", "runner", "mage", "scout", "priest", "carpenter"]:
		var block: Dictionary = d.classes[id].get("breakthrough", {})
		assert_false(block.get("trials", []).is_empty(), "%s has a trial" % id)
		assert_ne(block.get("hint", ""), "", "%s has a hint" % id)
	var boons := 0
	for eid: String in d.canon.events:
		for h: Dictionary in d.canon.events[eid].get("hooks", []):
			if h["then"] == CanonDb.HOOK_BOON:
				boons += 1
	assert_eq(boons, 6)
