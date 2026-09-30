extends GutTest
## M17.8 (ADR 0027): the hidden XP duress of a fight. The fight keeps the highest HP before a foe's blow
## ("peak") and the lowest after one ("low"), in per mille of max HP (-1 = no foe hit yet); Combat.end_fight
## turns the gap into a factor for every record of the fight (Xp.duress_mult). Traps do not count.
## Toy arena (ToyCombat) with the shipped duress curve put back (ToyData.with_duress).

var _db: DataDb


func before_each() -> void:
	_db = ToyData.with_duress(ToyCombat.db())
	ToyCombat.tactical(_db)
	_db.rules["combat"]["hp_base"] = 97  # max HP 100 with endurance 1 x 3 (toy base stats): see _most()


func _game() -> GameState:
	var gs := ToyCombat.new_game(_db, 1)
	ToyCombat.to_arena(gs, _db, Vector2i(2, 4))
	return gs


func _fight(gs: GameState) -> void:
	ToyCombat.spawn(gs, _db, "goblin", Vector2i(2, 9))  # far away: a fight with nobody hitting yet


func _hit(gs: GameState, amount: int, from_foe: bool = true) -> void:
	Combat.damage_player(gs, _db, amount, from_foe)


func _most(gs: GameState) -> int:
	return Stats.max_hp(gs, _db)


func test_a_new_fight_has_no_marks() -> void:
	var gs := _game()
	_fight(gs)
	assert_eq(int(gs.combat.fight["peak"]), -1)
	assert_eq(int(gs.combat.fight["low"]), -1)
	assert_eq(Combat.fight_lost(gs.combat.fight), 0.0)


func test_a_foe_blow_sets_both_marks() -> void:
	var gs := _game()
	_fight(gs)
	var most := _most(gs)
	_hit(gs, most / 4)
	assert_eq(int(gs.combat.fight["peak"]), 1000, "full before the blow")
	assert_almost_eq(float(gs.combat.fight["low"]), 750.0, 10.0)
	assert_almost_eq(Combat.fight_lost(gs.combat.fight), 0.25, 0.01)


func test_healing_never_raises_the_low_and_the_gap_is_the_worst_point() -> void:
	var gs := _game()
	_fight(gs)
	var most := _most(gs)
	_hit(gs, most / 2)  # 50%
	Combat.set_hp(gs, _db, most * 9 / 10)  # a heal to 90%
	_hit(gs, most * 3 / 10)  # 60%
	assert_almost_eq(float(gs.combat.fight["low"]), 500.0, 10.0, "the lowest stays 50%")
	assert_almost_eq(Combat.fight_lost(gs.combat.fight), 0.5, 0.01, "100% down to 50%")


func test_a_fight_started_hurt_counts_only_what_the_fight_took() -> void:
	var gs := _game()
	var most := _most(gs)
	Combat.set_hp(gs, _db, most * 4 / 10)  # 40% when it starts
	_fight(gs)
	_hit(gs, most * 3 / 10)  # to 10%
	assert_almost_eq(Combat.fight_lost(gs.combat.fight), 0.3, 0.01, "30% lost in this fight, not 90%")


func test_a_trap_does_not_count() -> void:
	var gs := _game()
	_fight(gs)
	_hit(gs, _most(gs) / 2, false)
	assert_eq(int(gs.combat.fight["low"]), -1)
	assert_eq(Combat.fight_lost(gs.combat.fight), 0.0)


func test_no_fight_no_marks_and_no_error() -> void:
	var gs := _game()
	_hit(gs, 3)
	assert_true(gs.combat.fight.is_empty())


func test_the_marks_survive_a_save_and_an_old_save_reads_minus_one() -> void:
	var gs := _game()
	_fight(gs)
	_hit(gs, _most(gs) / 5)
	var back := CombatState.from_dict(JSON.parse_string(JSON.stringify(gs.combat.to_dict())))
	assert_eq(int(back.fight["low"]), int(gs.combat.fight["low"]))
	assert_eq(int(back.fight["peak"]), 1000)
	var old := gs.combat.to_dict()
	(old["fight"] as Dictionary).erase("low")
	(old["fight"] as Dictionary).erase("peak")
	var loaded := CombatState.from_dict(old)
	assert_eq(int(loaded.fight["low"]), -1, "a save made before M17.8: no foe hit yet, not 0% HP")
	assert_eq(Combat.fight_lost(loaded.fight), 0.0)


func _records(gs: GameState, action_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for r: Dictionary in gs.action_log.records:
		if r["action_id"] == action_id:
			out.append(r)
	return out


func test_end_fight_gives_every_record_the_duress() -> void:
	var gs := _game()
	var g := ToyCombat.spawn(gs, _db, "goblin", Vector2i(2, 5))
	ToyCombat.always_hit(_db)
	ToyCombat.freeze(_db)  # the goblin does not swing back: only the blows the test makes count
	FightBot.attack(gs, _db, "s")
	_hit(gs, _most(gs) * 3 / 10)  # 30% lost
	Combat.end_fight(gs, _db, Combat.WON)
	var att := _records(gs, "attack_melee")
	assert_false(att.is_empty(), "the fight made an attack record")
	for r: Dictionary in att:
		assert_almost_eq(float(r["duress"]), 1.2, 0.02, "30% lost: x1.2")
	assert_true(g != "")


func test_a_fight_with_no_blow_pays_half() -> void:
	var gs := _game()
	ToyCombat.spawn(gs, _db, "goblin", Vector2i(2, 5))
	ToyCombat.always_hit(_db)
	ToyCombat.freeze(_db)  # the goblin does not swing back: only the blows the test makes count
	FightBot.attack(gs, _db, "s")
	Combat.end_fight(gs, _db, Combat.WON)
	for r: Dictionary in _records(gs, "attack_melee"):
		assert_eq(float(r["duress"]), 0.5)


func test_a_knock_out_pays_the_most() -> void:
	var gs := _game()
	ToyCombat.spawn(gs, _db, "goblin", Vector2i(2, 5))
	ToyCombat.always_hit(_db)
	ToyCombat.freeze(_db)  # the goblin does not swing back: only the blows the test makes count
	FightBot.attack(gs, _db, "s")
	_hit(gs, _most(gs) * 2)
	assert_true(Combat.is_down(gs))
	Combat.end_fight(gs, _db, Combat.KNOCKED_OUT)
	for r: Dictionary in _records(gs, "attack_melee"):
		assert_almost_eq(float(r["duress"]), 1.9, 0.001)
		assert_eq(r["outcome"], "fail", "the old outcome factor still applies")
