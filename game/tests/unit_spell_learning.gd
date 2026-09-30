extends GutTest
## Spell data and learning (M17.5, ADR 0027): spells.json is valid, a teacher teaches
## only after their canon event and only when next to the player, a spellbook is read
## once, nothing comes from nothing, [Mage] needs a known spell. Real data.

const SEED := 20260930
const MARKET := "liscor_market"
const PLAYER_AT := Vector2i(5, 5)
const TEACHER_EVENT := "b1.ceria_teaches_ryoka_light"

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String], "real data loads clean")


func _game() -> GameState:
	var gs := GameState.new_game(SEED, _db)
	gs.player.place(MARKET, PLAYER_AT)
	return gs


func _put(gs: GameState, id: String, at: Vector2i) -> void:
	gs.npcs.npcs[id]["area"] = MARKET
	gs.npcs.npcs[id]["x"] = at.x
	gs.npcs.npcs[id]["y"] = at.y


func _done(gs: GameState, event: String) -> void:
	gs.world.events[event] = {"status": Spells.DONE}


func test_the_shipped_spells_are_all_guesses_with_a_canon_ref() -> void:
	assert_gt(_db.spells.ids().size(), 3)
	for id in _db.spells.ids():
		var s: Dictionary = _db.spells.spells[id]
		assert_true(s["canon_ref"].has("book"), id)
		assert_true(s["name"].begins_with("["), id)


func test_a_new_player_knows_no_spell() -> void:
	var gs := _game()
	assert_eq(Spells.known(gs, _db), [] as Array[String])
	assert_false(gs.flags.has(Spells.KNOWS_FLAG))


func test_a_teacher_teaches_only_after_their_event() -> void:
	var gs := _game()
	assert_eq(Spells.teach_error(gs, _db, "ceria_springwalker", "ice_spike"),
			Spells.NOT_YET % "Ceria Springwalker")
	assert_eq(Spells.teachable(gs, _db, "ceria_springwalker"), [] as Array[String])
	_done(gs, TEACHER_EVENT)
	assert_eq(Spells.teach_error(gs, _db, "ceria_springwalker", "ice_spike"), "")
	assert_eq(Spells.teachable(gs, _db, "ceria_springwalker"), ["flashfire", "ice_spike"] as Array[String])


func test_a_teacher_teaches_only_their_own_spells() -> void:
	var gs := _game()
	_done(gs, TEACHER_EVENT)
	assert_eq(Spells.teach_error(gs, _db, "ceria_springwalker", "frozen_wind"),
			Spells.CANNOT_TEACH % "Ceria Springwalker")
	assert_eq(Spells.teach_error(gs, _db, "ceria_springwalker", "no_such_spell"), Spells.UNKNOWN)
	assert_eq(Spells.teach_error(gs, _db, "ceria_springwalker", "fireball"),
			Spells.CANNOT_TEACH % "Ceria Springwalker", "a book spell has no teacher")


func test_learning_from_a_teacher_takes_time_and_sets_the_mage_flag() -> void:
	var gs := _game()
	_done(gs, TEACHER_EVENT)
	_put(gs, "ceria_springwalker", PLAYER_AT + Vector2i(1, 0))
	var before := gs.clock.total_minutes
	assert_eq(Commands.learn_spell(gs, _db, "ceria_springwalker", "ice_spike"), "")
	assert_eq(Spells.known(gs, _db), ["ice_spike"] as Array[String])
	assert_true(gs.flags.get(Spells.KNOWS_FLAG, false))
	assert_gte(gs.clock.total_minutes - before, 120, "the study time passes")
	assert_true("You learn [Ice Spike]." in gs.combat.lines)


func test_a_teacher_must_be_next_to_the_player() -> void:
	var gs := _game()
	_done(gs, TEACHER_EVENT)
	_put(gs, "ceria_springwalker", PLAYER_AT + Vector2i(6, 0))
	assert_eq(Commands.learn_spell(gs, _db, "ceria_springwalker", "ice_spike"),
			Spells.NOT_HERE % "Ceria Springwalker")
	assert_eq(Spells.known(gs, _db).size(), 0)


func test_a_known_spell_is_not_learned_twice() -> void:
	var gs := _game()
	_done(gs, TEACHER_EVENT)
	_put(gs, "ceria_springwalker", PLAYER_AT + Vector2i(1, 0))
	Commands.learn_spell(gs, _db, "ceria_springwalker", "ice_spike")
	assert_eq(Commands.learn_spell(gs, _db, "ceria_springwalker", "ice_spike"), Spells.KNOWN % "[Ice Spike]")
	assert_eq(gs.progression.spells.size(), 1)


func test_the_teach_list_shows_in_the_npc_option() -> void:
	var gs := _game()
	_done(gs, TEACHER_EVENT)
	_put(gs, "ceria_springwalker", PLAYER_AT + Vector2i(1, 0))
	var mine := Interact.options(gs, _db).filter(func(o: Dictionary) -> bool:
		return o["id"] == "ceria_springwalker")
	assert_eq(mine.size(), 1)
	assert_eq(mine[0]["teach"], ["flashfire", "ice_spike"] as Array[String])


func test_learning_feeds_the_magic_pool() -> void:
	var gs := _game()
	_done(gs, TEACHER_EVENT)
	_put(gs, "ceria_springwalker", PLAYER_AT + Vector2i(1, 0))
	Commands.learn_spell(gs, _db, "ceria_springwalker", "ice_spike")
	var rec: Dictionary = gs.action_log.records[-1]
	assert_eq(rec["action_id"], Spells.STUDY_ACTION)
	assert_gt(float(rec["xp"]), 0.0)
	ClassSystem.feed(gs, _db, rec)  # the night does this
	assert_gt(float(gs.progression.pools.get("mage", 0.0)), 0.0, "[Study a spell] is magic XP")


func test_mage_needs_a_known_spell() -> void:
	var gs := _game()
	assert_false(ClassSystem.can_offer(gs, _db, "mage"))
	assert_eq(Commands.grant_spell(gs, _db, "ice_spike"), "")
	assert_true(ClassSystem.can_offer(gs, _db, "mage"))


func test_a_mage_level_adds_mp() -> void:
	var gs := _game()
	var plain := Stats.max_mp(gs, _db)
	gs.progression.classes["mage"] = {"level": 2, "xp": 0.0, "last_active_day": 1}
	assert_eq(Stats.max_mp(gs, _db), plain + 2 + 2, "+1 per total level, +1 per [Mage] level")


func test_a_spellbook_teaches_once_and_is_used_up() -> void:
	var gs := _game()
	assert_eq(Commands.give(gs, _db, 0, "spellbook_fireball", 1), "")
	assert_eq(Commands.use_good(gs, _db, "spellbook_fireball"), "")
	assert_eq(Spells.known(gs, _db), ["fireball"] as Array[String])
	assert_eq(gs.economy.count("spellbook_fireball"), 0, "the book is used up")
	Commands.give(gs, _db, 0, "spellbook_fireball", 1)
	assert_eq(Commands.use_good(gs, _db, "spellbook_fireball"), Spells.KNOWN % "[Fireball]")
	assert_eq(gs.economy.count("spellbook_fireball"), 1, "a refused book is kept")


func test_a_spellbook_takes_its_study_time() -> void:
	var gs := _game()
	Commands.give(gs, _db, 0, "spellbook_fireball", 1)
	var before := gs.clock.total_minutes
	Commands.use_good(gs, _db, "spellbook_fireball")
	assert_gte(gs.clock.total_minutes - before, 240)


func test_grant_spell_refuses_unknown_and_known() -> void:
	var gs := _game()
	assert_eq(Commands.grant_spell(gs, _db, "nope"), "Unknown spell 'nope'.")
	assert_eq(Commands.grant_spell(gs, _db, "fireball"), "")
	assert_eq(Commands.grant_spell(gs, _db, "fireball"), Spells.KNOWN % "[Fireball]")


func test_learning_needs_the_player_up_and_safe() -> void:
	var gs := _game()
	_done(gs, TEACHER_EVENT)
	_put(gs, "ceria_springwalker", PLAYER_AT + Vector2i(1, 0))
	Combat.set_hp(gs, _db, 0)
	assert_eq(Commands.learn_spell(gs, _db, "ceria_springwalker", "ice_spike"), Combat.REFUSED_DOWN)


func test_bad_spell_data_is_reported() -> void:
	var bad := {
		"no_shape": {"name": "[X]"},
		"bad_mp": {"name": "[Y]", "shape": "one", "ap_q": 8, "mp": 0, "range": 3, "damage": [1, 2],
			"hit": "roll", "cooldown": 0, "canon_ref": {"book": 1, "confidence": "guess"}},
		"bad_line": {"name": "[Z]", "shape": "line", "ap_q": 8, "mp": 1, "damage": [1, 2],
			"hit": "maybe", "cooldown": 0, "canon_ref": {"book": 1, "confidence": "guess"}},
		"bad_teacher": {"name": "[W]", "shape": "around", "ap_q": 8, "mp": 1, "damage": [1, 2],
			"hit": "auto", "cooldown": 0, "canon_ref": {"book": 1, "confidence": "guess"},
			"learn": {"teacher": "nobody", "minutes": 10}},
		"bad_book": {"name": "[V]", "shape": "around", "ap_q": 8, "mp": 1, "damage": [1, 2],
			"hit": "auto", "cooldown": 0, "canon_ref": {"book": 1, "confidence": "guess"},
			"learn": {"book": "healing_potion", "minutes": 10}},
	}
	var sdb := SpellDb.from_dicts(bad)
	var errs := sdb.validate(_db)
	assert_true(errs.any(func(e: String) -> bool: return e.contains("no_shape") and e.contains("missing")))
	assert_true(errs.any(func(e: String) -> bool: return e.contains("bad_mp") and e.contains("mp must")))
	assert_true(errs.any(func(e: String) -> bool: return e.contains("bad_line") and e.contains("length")))
	assert_true(errs.any(func(e: String) -> bool: return e.contains("bad_line") and e.contains("hit must")))
	assert_true(errs.any(func(e: String) -> bool: return e.contains("bad_teacher") and e.contains("unknown teacher")))
	assert_true(errs.any(func(e: String) -> bool: return e.contains("bad_book") and e.contains("teaches")))
