extends GutTest
## Where the player may sleep (M8.6, ADR 0015): a bed heals fully, the
## floor indoors or on a campsite heals half, outdoors you cannot sleep;
## a paid room; a collapse happens anywhere.

const SEED := 20260925

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])


func _game(start: String, area: String, pos: Vector2i) -> GameState:
	var gs := GameState.new_game(SEED, _db, start)
	gs.player.place(area, pos)
	Commands.settle(gs, _db)
	return gs


func _next_to(gs: GameState, area: String, object_id: String) -> void:
	var o := Interact.object_of(_db, area, object_id)
	var pos := Vector2i(int(o["at"][0]), int(o["at"][1]))
	for d: Vector2i in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
		if _db.maps.is_walkable(area, pos + d) and gs.npcs.at(area, pos + d) == "":
			gs.player.place(area, pos + d)
			return
	fail_test("no free tile next to %s" % object_id)


func test_you_cannot_sleep_outdoors() -> void:
	var gs := _game("celum", "celum_gate", Vector2i(16, 8))
	var before := gs.clock.total_minutes
	assert_eq(Commands.sleep(gs, _db), {})
	assert_has(gs.combat.lines, String(_db.rules["economy"]["rest"]["refused_line"]))
	assert_eq(gs.clock.total_minutes, before)


func test_the_floor_indoors_heals_half() -> void:
	var gs := _game("celum", "celum_runners_guild", Vector2i(10, 8))
	Combat.set_hp(gs, _db, 1)
	assert_false(Commands.sleep(gs, _db).is_empty())
	assert_eq(Combat.hp(gs, _db), ceili(Stats.max_hp(gs, _db) * 0.5))


func test_a_bed_heals_fully_and_sleeping_next_to_a_free_bed_uses_it() -> void:
	var gs := _game("liscor", "inn_interior", Vector2i(12, 14))
	_next_to(gs, "inn_interior", "bed")
	Combat.set_hp(gs, _db, 1)
	var place := Rest.place(gs, _db)
	assert_eq(place["rest"], Rest.BED)
	assert_eq(place["bed"], "bed")
	Commands.sleep(gs, _db)
	assert_eq(Combat.hp(gs, _db), Stats.max_hp(gs, _db))


func test_the_camp_floor_heals_half_and_the_bedroll_fully() -> void:
	var gs := _game("liscor", "road_camp", Vector2i(16, 5))
	assert_eq(Rest.place(gs, _db)["rest"], Rest.FLOOR)
	Combat.set_hp(gs, _db, 1)
	Commands.sleep(gs, _db)
	assert_eq(Combat.hp(gs, _db), ceili(Stats.max_hp(gs, _db) * 0.5))
	_next_to(gs, "road_camp", "bedroll")
	Combat.set_hp(gs, _db, 1)
	Commands.sleep(gs, _db, "bedroll")
	assert_eq(Combat.hp(gs, _db), Stats.max_hp(gs, _db))


func test_a_room_at_the_rats_tail_costs_coins() -> void:
	var gs := _game("celum", "celum_square", Vector2i(16, 16))
	_next_to(gs, "celum_square", "rats_tail_door")
	assert_eq(Rest.place(gs, _db)["rest"], "", "no free bed here, outdoors")
	assert_eq(Commands.sleep(gs, _db, "rats_tail_door"), {})
	assert_string_contains(gs.combat.lines[-1], "cannot pay")
	Commands.give(gs, _db, 12)
	Combat.set_hp(gs, _db, 1)
	assert_false(Commands.sleep(gs, _db, "rats_tail_door").is_empty())
	assert_eq(gs.economy.coins, 2)
	assert_eq(Combat.hp(gs, _db), Stats.max_hp(gs, _db))


func test_a_bed_that_is_not_near_is_refused() -> void:
	var gs := _game("liscor", "inn_interior", Vector2i(2, 2))
	assert_eq(Commands.sleep(gs, _db, "bed"), {})
	assert_string_contains(gs.combat.lines[-1], "no bed")


func test_a_collapse_happens_outdoors_too() -> void:
	var gs := _game("celum", "celum_gate", Vector2i(16, 8))
	gs.clock.awake_minutes = int(_db.rules["clock"]["collapse_after_awake"])
	var night := Commands.sleep(gs, _db)
	assert_false(night.is_empty())
	assert_true(night["collapsed"])
