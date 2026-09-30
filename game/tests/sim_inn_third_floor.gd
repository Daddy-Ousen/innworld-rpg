extends GutTest
## M13.0 (ADR 0020) on the real data: the inn's new upper floor and Bird's
## tower. The stairs open only after wandering_inn.third_floor_built; the
## building site stands on the hill between the two build flags; Bird keeps
## watch on the tower; a save upstairs loads upstairs.

const SEED := 20260928
const BEGUN := "wandering_inn.expansion_begun"
const BUILT := "wandering_inn.third_floor_built"
const BELOW_STAIRS := Vector2i(15, 13)

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])


func _at_the_stairs(flags: Array = []) -> GameState:
	var gs := GameState.new_game(SEED, _db)
	for f: String in flags:
		gs.flags[f] = true
	gs.player.place("inn_interior", BELOW_STAIRS)
	Commands.settle(gs, _db)
	return gs


func _ids_on(area: String) -> Array:
	return _db.maps.objects_on(area).map(func(o: Dictionary) -> String: return o["id"])


func test_the_stairs_are_plain_floor_before_the_build() -> void:
	var gs := _at_the_stairs()
	assert_true(FightBot.move(gs, _db, "s")["moved"])
	assert_eq(gs.player.area, "inn_interior")
	assert_eq(gs.player.pos(), BELOW_STAIRS + Vector2i.DOWN)
	assert_false(_ids_on("inn_interior").has("stairs_up"), "no stairs drawn")


func test_the_stairs_lead_up_after_the_build() -> void:
	var gs := _at_the_stairs([BEGUN, BUILT])
	assert_true(_ids_on("inn_interior").has("stairs_up"))
	FightBot.move(gs, _db, "s")
	assert_eq(gs.player.area, "inn_upper_floor")
	assert_eq(gs.player.pos(), Vector2i(17, 6))
	assert_true(ToyMaps.walk_to_area(gs, _db, "inn_watchtower"), "the ladder to the tower")
	assert_false(_db.maps.is_indoor("inn_watchtower"), "the tower is open to the sky")
	assert_true(ToyMaps.walk_next_to(gs, _db, "watch_post"))
	var r := Commands.interact(gs, _db, "watch_post", "keep_watch")
	assert_eq(r["error"], "")
	assert_true(ToyMaps.walk_to_area(gs, _db, "inn_upper_floor"))
	assert_true(ToyMaps.walk_to_area(gs, _db, "inn_interior"), "and back down")


func test_the_building_site_stands_between_the_flags() -> void:
	var gs := _at_the_stairs()
	var site := ["building_lumber", "building_stone"]
	var outhouses := ["outhouse_1", "outhouse_2"]
	for id: String in site + outhouses:
		assert_false(_ids_on("inn_hill").has(id), "%s: not yet" % id)
	gs.flags[BEGUN] = true
	Commands.settle(gs, _db)
	for id: String in site:
		assert_true(_ids_on("inn_hill").has(id), "%s: while they build" % id)
	for id: String in outhouses:
		assert_false(_ids_on("inn_hill").has(id), id)
	gs.flags[BUILT] = true
	Commands.settle(gs, _db)
	for id: String in site:
		assert_false(_ids_on("inn_hill").has(id), "%s: gone when it is done" % id)
	for id: String in outhouses:
		assert_true(_ids_on("inn_hill").has(id), "%s: built" % id)


func test_bird_keeps_watch_on_the_tower() -> void:
	var gs := _at_the_stairs()
	Commands.wait(gs, _db, 600)
	assert_ne(String(gs.npcs.npcs.get("bird", {}).get("area", "")), "inn_watchtower", "no tower yet")
	gs.flags[BUILT] = true
	Commands.wait(gs, _db, 600)
	var bird: Dictionary = gs.npcs.npcs["bird"]
	assert_eq(bird["area"], "inn_watchtower")
	assert_eq(NpcRoster.pos_of(bird), Vector2i(3, 2))


func test_a_save_upstairs_loads_upstairs() -> void:
	var gs := _at_the_stairs([BEGUN, BUILT])
	FightBot.move(gs, _db, "s")
	assert_eq(gs.player.area, "inn_upper_floor")
	var back := GameState.from_json(gs.to_json())
	Commands.settle(back, _db)
	assert_eq(back.player.area, "inn_upper_floor")
	assert_eq(back.player.pos(), Vector2i(17, 6))
	assert_true(ToyMaps.walk_to_area(back, _db, "inn_interior"), "the way down is still there")
