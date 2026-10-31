extends GutTest
## The three quest lines (M33.3, ADR 0044 "M33.3"): Erin's inn, Pawn's Soldiers, Pisces's mana
## lesson. Real data. Each line is valid, uses flags that canon (or a reward) sets, can be taken
## on and finished, and the Pisces reward opens [Flash Step]. Quests never change canon.

const SEED := 20261026
const MARKET := "liscor_market"
const LINES := {
	"erin_gets_the_inn_going": "erin_solstice",
	"pawn_and_the_painted_soldiers": "pawn",
	"pisces_teaches_mana": "pisces",
}

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String], "real data loads clean")


## Every flag that canon events or quest rewards can set.
func _settable() -> Dictionary:
	var out := {}
	for id: String in _db.canon.events:
		for f: String in _db.canon.events[id].get("effects", {}).get("set_flags", []):
			out[f] = true
	for q: Dictionary in _db.quests.values():
		for f: String in q.get("rewards", {}).get("flags", []):
			out[f] = true
	return out


## The player next to the giver in the market, the gate open, the giver a friend.
func _gs(id: String) -> GameState:
	var gs := GameState.new_game(SEED, _db)
	var giver: String = LINES[id]
	gs.player.place(MARKET, Vector2i(5, 5))
	gs.npcs.npcs[giver]["area"] = MARKET
	gs.npcs.npcs[giver]["x"] = 6
	gs.npcs.npcs[giver]["y"] = 5
	for f: String in _db.quests[id].get("gate", {}).get("flags", []):
		gs.flags[f] = true
	gs.world.add_relationship(giver, NpcSim.PLAYER, Voice.band_min(_db, "friend"))
	return gs


func test_the_three_lines_are_there() -> void:
	for id: String in LINES:
		assert_true(_db.quests.has(id), id)
		assert_eq(String(_db.quests[id]["giver"]), LINES[id], id)
		var n: int = (_db.quests[id]["steps"] as Array).size()
		assert_true(n >= 3 and n <= 5, "%s has %d steps" % [id, n])
	assert_eq(Quests.validate(_db), [] as Array[String])


func test_every_flag_is_set_by_canon_or_a_reward() -> void:
	var known := _settable()
	for id: String in LINES:
		var q: Dictionary = _db.quests[id]
		var flags: Array = []
		flags.append_array(q.get("gate", {}).get("flags", []))
		flags.append_array(q.get("fail", {}).get("flags", []))
		for s: Dictionary in q["steps"]:
			if s.has("flag"):
				flags.append(s["flag"])
		for f: String in flags:
			assert_true(known.has(f), "%s: nothing sets '%s'" % [id, f])


func test_no_line_gives_a_book_or_a_spell_directly() -> void:
	for id: String in LINES:
		var r: Dictionary = _db.quests[id].get("rewards", {})
		for good: String in r.get("goods", {}):
			assert_false(good.begins_with("spellbook_"), "%s hands out %s" % [id, good])


func test_each_line_can_be_taken_on_and_finished() -> void:
	for id: String in LINES:
		var gs := _gs(id)
		var giver: String = LINES[id]
		assert_eq(Quests.offers(gs, _db, giver).size(), 1, "%s is offered" % id)
		var r := Commands.interact(gs, _db, giver, Interact.QUEST + id)
		assert_eq(r["error"], "", id)
		assert_eq(Quests.status(gs, id), QuestState.ACTIVE, id)
		for s: Dictionary in _db.quests[id]["steps"]:
			if s.has("flag"):
				gs.flags[s["flag"]] = true
				Quests.update(gs, _db)
				continue
			var did: Dictionary = s["did"]
			for i in int(s.get("count", 1)):
				Actions.perform(gs, _db, String(did["action"][0]), {"context": did.get("context", {})})
		assert_eq(Quests.status(gs, id), QuestState.DONE, "%s is finished" % id)
		for f: String in _db.quests[id].get("rewards", {}).get("flags", []):
			assert_true(gs.flags.get(f, false), "%s sets %s" % [id, f])


func test_a_flag_step_does_not_pass_early() -> void:
	for id: String in LINES:
		var gs := _gs(id)
		Commands.interact(gs, _db, LINES[id], Interact.QUEST + id)
		var steps: Array = _db.quests[id]["steps"]
		for i in steps.size():
			var s: Dictionary = steps[i]
			if s.has("flag"):
				assert_eq(int(Quests.entry(gs, id)["step"]), i, "%s waits at step %d" % [id, i])
				break
			var did: Dictionary = s["did"]
			for k in int(s.get("count", 1)):
				Actions.perform(gs, _db, String(did["action"][0]), {"context": did.get("context", {})})
		assert_eq(Quests.status(gs, id), QuestState.ACTIVE, id)


func test_the_pisces_reward_opens_flash_step() -> void:
	var gs := _gs("pisces_teaches_mana")
	gs.world.events["b1.pisces_saves_erin_from_flies"] = {"status": Spells.DONE}
	assert_eq(Spells.teach_error(gs, _db, "pisces", "gust"), "", "Gust needs no task")
	assert_ne(Spells.teach_error(gs, _db, "pisces", "flash_step"), "", "Flash Step waits for the task")
	gs.flags["quest.pisces_mana_lesson"] = true
	assert_eq(Spells.teach_error(gs, _db, "pisces", "flash_step"), "")


func test_a_new_game_offers_erins_line() -> void:
	var gs := GameState.new_game(SEED, _db)
	var ids := Quests.offers(gs, _db, "erin_solstice").map(func(o: Dictionary) -> String: return o["id"])
	assert_true(ids.has("erin_gets_the_inn_going"), "offered on the first day: %s" % [ids])
	assert_true(Quests.offers(gs, _db, "pawn").is_empty(), "Pawn waits for his Soldiers (day 82)")
	assert_true(Quests.offers(gs, _db, "pisces").is_empty(), "Pisces waits for the flies (day 17)")
