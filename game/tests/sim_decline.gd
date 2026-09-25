extends GutTest
## M1 acceptance: a declined class never returns, even when the player keeps
## doing exactly the work that earned it. Uses the shipped data.

const SEED := 99
var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()


func _fight_day(gs: GameState) -> void:
	for i in 4:
		Commands.perform(gs, _db, "attack_melee", {"risk": 0.7})
		Commands.perform(gs, _db, "block_attack", {"risk": 0.7})
	Commands.perform(gs, _db, "weapon_practice")
	Commands.perform(gs, _db, "keep_watch")


func test_declined_warrior_never_returns() -> void:
	var gs := GameState.new_game(SEED, _db)
	var declined_on := 0
	for day in range(1, 41):
		_fight_day(gs)
		var night := Commands.sleep(gs, _db, Rest.ANYWHERE)
		var offers: Array = night["offers"]
		if declined_on > 0:
			assert_false(offers.has("warrior"), "day %d: [Warrior] came back" % day)
		for id: String in offers:
			if id == "warrior":
				Commands.decline_class(gs, _db, id)
				declined_on = day
				gut.p("[Warrior] declined on day %d" % day)
			else:
				Commands.accept_class(gs, _db, id)
				gut.p("accepted %s on day %d" % [id, day])
	var p := gs.progression
	assert_gt(declined_on, 0, "[Warrior] was offered")
	assert_eq(p.declined, ["warrior"] as Array[String])
	assert_false(p.has_class("warrior"))
	assert_false(p.has_offer("warrior"))
	assert_true(p.has_class("guardsman"), "the fighting XP still found a related class")

	# The blacklist survives save/load.
	var loaded := GameState.from_json(gs.to_json())
	for day in 10:
		_fight_day(loaded)
		assert_false((Commands.sleep(loaded, _db, Rest.ANYWHERE)["offers"] as Array).has("warrior"))
