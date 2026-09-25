extends GutTest
## The three M6.4 divergence cases on the real Book 1 canon, played with
## real commands: a fight (bump attacks) and cooking at the inn stove.
## Monsters are frozen and every hit lands, so the fights are sure.

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()
	ToyCombat.freeze(_db)
	ToyCombat.always_hit(_db)


## A new game (day 8) that has slept until the morning of `day`.
func _game_on_day(day: int) -> GameState:
	var gs := GameState.new_game(1, _db)
	ToyCanon.sleep_through(gs, _db, day - 1)
	assert_eq(gs.clock.day(), day)
	return gs


## Fights a monster of `type` on the Floodplains with bump attacks until it dies.
func _beat(gs: GameState, type: String) -> void:
	gs.player.place("floodplains_south", Vector2i(4, 4))
	Commands.settle(gs, _db)
	var id := Combat.add_monster(gs, _db, type, Vector2i(5, 4))
	assert_ne(id, "")
	for i in 100:
		if not gs.combat.monsters.has(id):
			break
		Commands.move(gs, _db, "e")
	assert_false(gs.combat.monsters.has(id), "the %s is dead" % type)
	assert_false(gs.combat.has_fight(), "the fight is over")
	var won := gs.action_log.records.filter(func(r: Dictionary) -> bool:
		return r["action_id"] == "attack_melee" and r["context"].get("enemy", "") == type)
	assert_eq(won.size(), 1, "one melee record for the fight")
	assert_eq(won[0]["outcome"], "success")


## Cooks a stew at the inn's stove.
func _cook_at_the_inn(gs: GameState) -> void:
	gs.player.place("inn_interior", Vector2i(20, 2))
	Commands.settle(gs, _db)
	var r := Commands.interact(gs, _db, "stove", "cook_stew")
	assert_eq(r["error"], "")
	assert_eq(r["record"]["context"]["location"], "wandering_inn")


func _texts(gs: GameState) -> Array:
	return gs.world.news.map(func(n: Dictionary) -> String: return n["text"])


func _hook_news(event_id: String) -> String:
	return _db.canon.events[event_id]["hooks"][0]["news"]


func test_hook_data_is_sound() -> void:
	var hooks := 0
	for id: String in _db.canon.events:
		for hook: Dictionary in _db.canon.events[id].get("hooks", []):
			hooks += 1
			for m: Dictionary in hook["did"]:
				for a: String in m["action"]:
					assert_true(_db.actions.has(a), "%s: action %s" % [id, a])
	assert_eq(hooks, 11)
	assert_true(_db.canon.alt_only.has("b1.player_beat_rock_crab_first"))


func test_beating_a_rock_crab_spares_erin_the_scare() -> void:
	var gs := _game_on_day(11)
	_beat(gs, "rock_crab")
	ToyCanon.sleep_through(gs, _db, 11)
	assert_eq(gs.world.status("b1.erin_screams_off_rock_crab"), Director.MUTATED)
	assert_eq(gs.world.status("b1.player_beat_rock_crab_first"), Director.DONE)
	assert_false(gs.flags.has("erin.scared_off_rock_crab"))
	assert_true(gs.flags.has("floodplains.rock_crab_beaten_by_earther"))
	assert_true(_texts(gs).has(_hook_news("b1.erin_screams_off_rock_crab")))
	assert_eq(gs.world.drift, 0.5)
	ToyCanon.sleep_through(gs, _db, 13)
	assert_eq(gs.world.status("b1.erin_names_the_inn"), Director.DONE, "Erin's week goes on")


func test_fighting_goblins_keeps_the_tribe_from_the_inn() -> void:
	var gs := _game_on_day(14)
	_beat(gs, "goblin_grunt")
	ToyCanon.sleep_through(gs, _db, 19)
	assert_eq(gs.world.status("b1.rags_brings_goblins_to_eat"), Director.CANCELLED)
	assert_false(gs.flags.has("goblin_tribe.paying_guests"))
	assert_eq(gs.world.status("b1.workers_learn_chess"), Director.DONE, "the Workers still come")
	assert_true(_texts(gs).has(_hook_news("b1.rags_brings_goblins_to_eat")))
	assert_false(_texts(gs).has(_db.canon.events["b1.rags_brings_goblins_to_eat"]["news"]))
	assert_eq(gs.world.drift, 1.0)


func test_cooking_for_the_first_regulars_changes_their_day() -> void:
	var canon := _game_on_day(15)
	ToyCanon.sleep_through(canon, _db, 15)
	var gs := _game_on_day(15)
	_cook_at_the_inn(gs)
	ToyCanon.sleep_through(gs, _db, 15)
	assert_eq(gs.world.status("b1.inn_first_regulars"), Director.CHANGED)
	assert_true(gs.flags.has("wandering_inn.earther_cooks"))
	assert_true(gs.flags.has("erin.knows_antinium_diet"), "the canon effects still happen")
	assert_eq(gs.world.relationship("klbkch", "erin_solstice"),
			canon.world.relationship("klbkch", "erin_solstice") + 1)
	assert_true(_texts(gs).has(_hook_news("b1.inn_first_regulars")))
	assert_eq(gs.world.drift, 0.25)
	ToyCanon.sleep_through(gs, _db, 19)
	assert_eq(gs.world.status("b1.workers_learn_chess"), Director.DONE, "later canon still runs")


func test_a_saved_deed_still_changes_the_story_after_a_load() -> void:
	var gs := _game_on_day(11)
	_beat(gs, "rock_crab")
	var loaded := GameState.from_json(gs.to_json())
	Commands.settle(loaded, _db)
	ToyCanon.sleep_through(loaded, _db, 11)
	assert_eq(loaded.world.status("b1.erin_screams_off_rock_crab"), Director.MUTATED)


func test_the_journal_shows_the_news_and_the_change() -> void:
	var gs := _game_on_day(11)
	_beat(gs, "rock_crab")
	ToyCanon.sleep_through(gs, _db, 11)
	var text := "\n".join(Journal.lines(gs, _db))
	assert_string_contains(text, "Day 11: " + _hook_news("b1.erin_screams_off_rock_crab"))
	assert_string_contains(text, "Drift: 0.50. The story has started to change.")
	assert_eq(Journal.changes(gs, _db), ["Day 11: " + _hook_news("b1.erin_screams_off_rock_crab")] as Array[String])
