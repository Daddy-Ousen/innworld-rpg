extends GutTest
## Mana (M17.5, ADR 0027): max MP from Intellect, total level and class; regen
## 1 MP per 10 awake minutes; a night refills; save v20.

var _db: DataDb


func before_each() -> void:
	_db = ToyCombat.db()


func _game() -> GameState:
	return ToyCombat.new_game(_db)


func _hold(gs: GameState, skill: String) -> void:
	gs.progression.skills.append({"id": skill, "class": "cook", "level": 1, "day": 1})


func test_a_new_player_has_full_mana() -> void:
	var gs := _game()
	assert_eq(Stats.max_mp(gs, _db), 6, "0 + 2 × Intellect 3 + 0 levels")
	assert_eq(Mana.current(gs, _db), 6)
	assert_eq(gs.player.mp, -1, "full is stored as -1")


func test_max_mp_follows_intellect_level_and_class() -> void:
	_db.skills["sharp"] = {"name": "[Sharp]", "rarity": "common", "pools": [], "tag_affinity": {},
		"effects": [{"type": "stat_mod", "stat": "intellect", "value": 2}], "canon_ref": {}}
	var gs := _game()
	_hold(gs, "sharp")
	assert_eq(Stats.max_mp(gs, _db), 10, "2 × (3 + 2)")
	gs.progression.classes["cook"] = {"level": 3}
	assert_eq(Stats.max_mp(gs, _db), 13, "+1 per total level")
	_db.classes["cook"]["combat"] = {"mp_bonus": 2}
	assert_eq(Stats.max_mp(gs, _db), 19, "+2 per level of a class with mp_bonus")


func test_a_hurt_mana_pool_keeps_its_value_when_the_max_grows() -> void:
	var gs := _game()
	Mana.set_mp(gs, _db, 4)
	gs.progression.classes["cook"] = {"level": 2}
	assert_eq(Mana.current(gs, _db), 4)
	assert_eq(Stats.max_mp(gs, _db), 8)


func test_spend_takes_mp_or_refuses() -> void:
	var gs := _game()
	assert_true(Mana.spend(gs, _db, 4))
	assert_eq(Mana.current(gs, _db), 2)
	assert_false(Mana.spend(gs, _db, 3), "not enough")
	assert_eq(Mana.current(gs, _db), 2, "a refused spend costs nothing")


func test_set_mp_clamps() -> void:
	var gs := _game()
	Mana.set_mp(gs, _db, -5)
	assert_eq(Mana.current(gs, _db), 0)
	Mana.set_mp(gs, _db, 99)
	assert_eq(gs.player.mp, -1)


func test_tick_gives_one_mp_per_ten_minutes_and_keeps_the_rest() -> void:
	var gs := _game()
	Mana.set_mp(gs, _db, 0)
	Mana.tick(gs, _db, 25)
	assert_eq(Mana.current(gs, _db), 2)
	assert_eq(gs.player.mp_minutes, 5)
	Mana.tick(gs, _db, 5)
	assert_eq(Mana.current(gs, _db), 3, "the kept 5 minutes count")
	assert_eq(gs.player.mp_minutes, 0)


func test_tick_stops_at_full() -> void:
	var gs := _game()
	Mana.set_mp(gs, _db, 5)
	Mana.tick(gs, _db, 500)
	assert_eq(gs.player.mp, -1)
	assert_eq(gs.player.mp_minutes, 0, "no regen clock at full MP")


func test_waiting_regenerates_mana() -> void:
	var gs := _game()
	Mana.set_mp(gs, _db, 0)
	Movement.wait(gs, _db, 600)
	assert_eq(Mana.current(gs, _db), 1, "10 minutes")


func test_short_steps_add_up() -> void:
	var gs := _game()
	Mana.set_mp(gs, _db, 0)
	for i in 10:
		Movement.wait(gs, _db, 60)
	assert_eq(Mana.current(gs, _db), 1, "ten one-minute waits")


func test_an_action_regenerates_mana() -> void:
	var gs := _game()
	Mana.set_mp(gs, _db, 0)
	Actions.perform(gs, _db, "fight", {"minutes": 30})
	assert_eq(Mana.current(gs, _db), 3)


func test_a_night_refills_mana() -> void:
	var gs := _game()
	Mana.set_mp(gs, _db, 1)
	Combat.night(gs, _db, false, false)
	assert_eq(gs.player.mp, -1, "a full sleep")


func test_a_collapse_and_a_knock_out_refill_only_part() -> void:
	var gs := _game()
	Mana.set_mp(gs, _db, 0)
	Combat.night(gs, _db, true, false)
	assert_eq(Mana.current(gs, _db), 3, "half of 6")
	Mana.set_mp(gs, _db, 0)
	Combat.night(gs, _db, false, true)
	assert_eq(Mana.current(gs, _db), 2, "a quarter of 6, rounded up")


func test_a_night_never_lowers_mana() -> void:
	var gs := _game()
	Mana.set_mp(gs, _db, 5)
	Combat.night(gs, _db, true, false)
	assert_eq(Mana.current(gs, _db), 5)


func test_mana_saves_and_loads() -> void:
	var gs := _game()
	Mana.set_mp(gs, _db, 3)
	gs.player.mp_minutes = 7
	gs.progression.spells.append("fireball")
	var back := GameState.from_json(gs.to_json())
	assert_eq(back.player.mp, 3)
	assert_eq(back.player.mp_minutes, 7)
	assert_eq(back.progression.spells, ["fireball"] as Array[String])


func test_v19_saves_load_with_full_mana_and_no_spells() -> void:
	var gs := _game()
	var data := gs.to_dict()
	(data["player"] as Dictionary).erase("mp")
	(data["player"] as Dictionary).erase("mp_minutes")
	(data["progression"] as Dictionary).erase("spells")
	data["save_version"] = 19
	var migrated := SaveMigrations.migrate(data)
	assert_eq(int(migrated["save_version"]), GameState.SAVE_VERSION)
	assert_eq(GameState.SAVE_VERSION, 20)
	var back := GameState.from_dict(migrated)
	assert_eq(back.player.mp, -1)
	assert_eq(back.progression.spells.size(), 0)


func test_a_v19_encounter_gets_an_empty_npc_mana_table() -> void:
	var gs := _game()
	var data := gs.to_dict()
	data["combat"]["encounter"] = {"round": 2, "order": ["player"]}
	data["save_version"] = 19
	var migrated := SaveMigrations.migrate(data)
	assert_eq(migrated["combat"]["encounter"]["npc_mp"], {})


func test_real_rules_have_the_mana_numbers() -> void:
	var real := DataDb.load_dir()
	assert_eq(real.errors.size(), 0)
	var m: Dictionary = real.rules["combat"]["tactical"]["mp"]
	assert_eq(int(m["per_intellect"]), 2)
	assert_eq(int(m["per_level"]), 1)
	assert_eq(int(real.rules["combat"]["base_stats"]["default"]["intellect"]), 3)
