extends GutTest
## Quests (M33.2, ADR 0044 "M33.2"): a giver offers a task when its gate passes, "Ask about"
## starts it, steps count action records (the hook matcher) or wait for a flag, rewards are
## paid once, a task fails when its giver dies, a fail flag is set or its last day passes.
## The state survives a save; a v23 save loads with no tasks. Test quests are put on the real db.

const GIVER := "krshia"
const ID := "help_krshia"

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()


func after_each() -> void:
	_db.quests = {}


func _quest() -> Dictionary:
	return {
		"title": "Krshia's stall",
		"giver": GIVER,
		"offer": "Help me, yes? Play chess with the market.",
		"gate": {"flags": ["x.open"], "min_band": "acquaintance"},
		"fail": {"flags": ["x.closed"], "after_day": 30},
		"steps": [
			{"text": "Play chess twice.", "did": {"action": ["play_chess"]}, "count": 2},
			{"text": "Wait for the sign.", "flag": "x.sign"},
			{"text": "Go back to Krshia.", "did": {"action": ["talk_with_guest"], "context": {"npc": GIVER}}},
		],
		"rewards": {"relationship": 3, "coins": 150, "goods": {"bread": 2}, "flags": ["x.rewarded"]},
		"done": "Good work. Here, take this.",
		"confidence": "guess",
	}


## Day 2, 9:00, the player in the market next to Krshia, the gate open.
func _gs(open: bool = true) -> GameState:
	_db.quests = {ID: _quest()}
	var gs := GameState.new_game(20261026, _db)
	gs.clock.total_minutes = 1440 + 9 * 60
	gs.player.place("liscor_market", Vector2i(5, 5))
	gs.npcs.npcs[GIVER]["area"] = "liscor_market"
	gs.npcs.npcs[GIVER]["x"] = 6
	gs.npcs.npcs[GIVER]["y"] = 5
	if open:
		gs.flags["x.open"] = true
		gs.world.add_relationship(GIVER, NpcSim.PLAYER, 4)
	return gs


func _started() -> GameState:
	var gs := _gs()
	var r := Commands.interact(gs, _db, GIVER, Interact.QUEST + ID)
	assert_eq(r["error"], "")
	return gs


func _has_line(gs: GameState, bit: String) -> bool:
	return gs.combat.lines.any(func(l: String) -> bool: return l.contains(bit))


func test_the_offer_waits_for_the_gate() -> void:
	var gs := _gs(false)
	assert_eq(Quests.offers(gs, _db, GIVER), [] as Array[Dictionary], "no flag, no band")
	gs.flags["x.open"] = true
	assert_eq(Quests.offers(gs, _db, GIVER), [] as Array[Dictionary], "still a stranger")
	gs.world.add_relationship(GIVER, NpcSim.PLAYER, 4)
	assert_eq(Quests.offers(gs, _db, GIVER), [{"id": ID, "label": "Ask about: Krshia's stall"}] as Array[Dictionary])
	assert_eq(Quests.offers(gs, _db, "relc"), [] as Array[Dictionary], "only the giver offers it")


func test_the_offer_is_a_talk_row_of_the_giver() -> void:
	var gs := _gs()
	var row := {}
	for o: Dictionary in Interact.options(gs, _db):
		if o["id"] == GIVER:
			row = o
	assert_eq(row.get("quests", []), [{"id": ID, "label": "Ask about: Krshia's stall"}])
	assert_eq(Interact.action_of(_db, GIVER, Interact.QUEST + ID), "talk_with_guest")


func test_ask_about_starts_the_task() -> void:
	var gs := _started()
	assert_eq(Quests.status(gs, ID), QuestState.ACTIVE)
	assert_true(_has_line(gs, "New task: Krshia's stall."))
	assert_true(_has_line(gs, "Krshia: \"Help me, yes?"), "the giver says the offer")
	assert_eq(Quests.offers(gs, _db, GIVER), [] as Array[Dictionary], "offered once")
	var again := Commands.interact(gs, _db, GIVER, Interact.QUEST + ID)
	assert_ne(again["error"], "", "a started task cannot be asked about again")


func test_a_closed_gate_cannot_start_a_task() -> void:
	var gs := _gs(false)
	var r := Commands.interact(gs, _db, GIVER, Interact.QUEST + ID)
	assert_ne(r["error"], "")
	assert_eq(Quests.status(gs, ID), "")
	assert_ne(Quests.start(gs, _db, ID), "", "start checks the gate too")


func test_a_did_step_counts_only_new_records() -> void:
	var gs := _gs()
	Actions.perform(gs, _db, "play_chess")
	Commands.interact(gs, _db, GIVER, Interact.QUEST + ID)
	assert_eq(Quests.entry(gs, ID)["count"], 0, "chess before the task does not count")
	Actions.perform(gs, _db, "play_chess")
	assert_eq(Quests.entry(gs, ID)["step"], 0)
	assert_eq(Quests.entry(gs, ID)["count"], 1)
	Actions.perform(gs, _db, "talk_with_guest", {"context": {"npc": GIVER}})
	assert_eq(Quests.entry(gs, ID)["count"], 1, "another action does not count")
	Actions.perform(gs, _db, "play_chess")
	assert_eq(Quests.entry(gs, ID)["step"], 1, "two games: the next step")
	assert_eq(Quests.entry(gs, ID)["count"], 0)
	assert_true(_has_line(gs, "Task: Wait for the sign."))


func test_a_flag_step_waits_for_the_flag() -> void:
	var gs := _started()
	Actions.perform(gs, _db, "play_chess")
	Actions.perform(gs, _db, "play_chess")
	assert_eq(Quests.update(gs, _db), [] as Array[String], "no flag yet")
	assert_eq(Quests.entry(gs, ID)["step"], 1)
	gs.flags["x.sign"] = true
	var lines := Quests.update(gs, _db)
	assert_eq(Quests.entry(gs, ID)["step"], 2)
	assert_eq(lines, ["Task: Go back to Krshia."] as Array[String])


func test_a_flag_set_before_the_step_passes_it_at_once() -> void:
	var gs := _gs()
	gs.flags["x.sign"] = true
	Commands.interact(gs, _db, GIVER, Interact.QUEST + ID)
	Actions.perform(gs, _db, "play_chess")
	Actions.perform(gs, _db, "play_chess")
	assert_eq(Quests.entry(gs, ID)["step"], 2, "the flag step is skipped at once")


func test_the_last_step_pays_the_rewards_once() -> void:
	var gs := _started()
	gs.flags["x.sign"] = true
	Actions.perform(gs, _db, "play_chess")
	Actions.perform(gs, _db, "play_chess")
	var coins := gs.economy.coins
	var bread := gs.economy.count("bread")
	var rel := gs.world.relationship(GIVER, NpcSim.PLAYER)
	var r := Commands.interact(gs, _db, GIVER, "talk_with_guest")
	assert_eq(r["error"], "")
	assert_eq(Quests.status(gs, ID), QuestState.DONE)
	assert_eq(gs.economy.coins, coins + 150)
	assert_eq(gs.economy.count("bread"), bread + 2)
	assert_true(gs.flags.get("x.rewarded", false))
	assert_true(gs.world.relationship(GIVER, NpcSim.PLAYER) >= rel + 3, "the reward (and the talk)")
	assert_true(_has_line(gs, "Task done: Krshia's stall."))
	assert_true(_has_line(gs, "Krshia: \"Good work."))
	coins = gs.economy.coins
	Commands.interact(gs, _db, GIVER, "talk_with_guest")
	Quests.update(gs, _db)
	assert_eq(gs.economy.coins, coins, "paid once")
	assert_eq(Quests.offers(gs, _db, GIVER), [] as Array[Dictionary], "a done task is not offered again")


func test_a_fail_flag_fails_the_task() -> void:
	var gs := _started()
	gs.flags["x.closed"] = true
	assert_eq(Quests.update(gs, _db), ["Task failed: Krshia's stall."] as Array[String])
	assert_eq(Quests.status(gs, ID), QuestState.FAILED)
	Actions.perform(gs, _db, "play_chess")
	assert_eq(Quests.entry(gs, ID)["count"], 0, "a failed task counts nothing")


func test_the_last_day_fails_the_task() -> void:
	var gs := _started()
	gs.clock.total_minutes = 29 * 1440 + 9 * 60
	Quests.update(gs, _db)
	assert_eq(Quests.status(gs, ID), QuestState.ACTIVE, "day 30 is still open")
	gs.clock.total_minutes = 30 * 1440 + 9 * 60
	Quests.update(gs, _db)
	assert_eq(Quests.status(gs, ID), QuestState.FAILED)


func test_the_givers_death_fails_the_task_and_ends_the_offer() -> void:
	var gs := _gs()
	gs.world.set_alive(GIVER, false)
	assert_eq(Quests.offers(gs, _db, GIVER), [] as Array[Dictionary])
	gs.world.set_alive(GIVER, true)
	Commands.interact(gs, _db, GIVER, Interact.QUEST + ID)
	gs.world.set_alive(GIVER, false)
	Quests.update(gs, _db)
	assert_eq(Quests.status(gs, ID), QuestState.FAILED)


func test_the_night_checks_the_tasks() -> void:
	var gs := _started()
	gs.flags["x.closed"] = true
	var night := Night.run(gs, _db)
	assert_eq(Quests.status(gs, ID), QuestState.FAILED)
	assert_true(gs.morning.has("Task failed: Krshia's stall."), str(night))


func test_the_journal_lists_the_tasks() -> void:
	var gs := _gs()
	assert_true(Journal.lines(gs, _db).has("  No tasks yet."))
	Commands.interact(gs, _db, GIVER, Interact.QUEST + ID)
	Actions.perform(gs, _db, "play_chess")
	var lines := Journal.lines(gs, _db)
	assert_true(lines.has("Tasks:"))
	assert_true(lines.has("  Krshia's stall: Play chess twice. (1/2)"), str(lines))
	gs.flags["x.closed"] = true
	Quests.update(gs, _db)
	assert_true(Journal.lines(gs, _db).has("  Failed: Krshia's stall."))


func test_the_tasks_survive_a_save() -> void:
	var gs := _started()
	Actions.perform(gs, _db, "play_chess")
	var loaded := GameState.from_json(gs.to_json())
	assert_eq(loaded.quests.to_dict(), gs.quests.to_dict())
	assert_eq(Quests.entry(loaded, ID)["count"], 1)


func test_a_v23_save_loads_with_no_tasks() -> void:
	var d := _gs().to_dict()
	d["save_version"] = 23
	d.erase("quests")
	var gs := GameState.from_json(JSON.stringify(d))
	assert_not_null(gs)
	assert_eq(gs.save_version, GameState.SAVE_VERSION)
	assert_eq(gs.quests.entries, {})


func test_bad_quest_data_is_reported() -> void:
	_db.quests = {
		"Bad Id": {"title": "", "giver": "nobody", "offer": "x", "steps": [], "more": 1},
		"bad_steps": {"title": "T", "giver": GIVER, "offer": "x", "confidence": "guess",
			"steps": [{"text": "a"}, {"text": "b", "flag": "x.y", "did": {"action": ["play_chess"]}},
				{"text": "c", "did": {"action": ["fly"]}, "count": 0}],
			"rewards": {"goods": {"gold_bar": 1}, "coins": -1, "spells": ["x"]},
			"gate": {"min_band": "best pal"}, "fail": {"after_day": "soon"}},
	}
	var text := "\n".join(Quests.validate(_db))
	for bit in ["'Bad Id'", "title must be", "unknown giver 'nobody'", "at least one step", "unknown field 'more'",
			"confidence", "step 0 needs a flag or a did", "step 1 has both", "unknown action 'fly'",
			"count must be", "unknown good 'gold_bar'", "coins must be", "unknown reward 'spells'",
			"min_band 'best pal'", "after_day must be"]:
		assert_true(text.contains(bit), "%s in %s" % [bit, text])


func test_the_real_quests_are_valid() -> void:
	_db = DataDb.load_dir()
	assert_eq(Quests.validate(_db), [] as Array[String])
	assert_eq(_db.errors, [] as Array[String])
