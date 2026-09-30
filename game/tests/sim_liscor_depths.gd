extends GutTest
## M13.0 (ADR 0020) on the real data: Liscor's dungeon under the rift. The
## ropes down are plain ground until liscor_dungeon.new_section_found; then
## the climb takes 10 minutes. Monsters spawn in the trapped rooms and the
## crypt level, a knock-out down there wakes you at the inn, and Toren walks
## the rune hall once he is in the dungeon.

const SEED := 20260928
const FOUND := "liscor_dungeon.new_section_found"
const BY_THE_ROPES := Vector2i(11, 12)

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])


func _at_the_rift(flags: Array = []) -> GameState:
	var gs := GameState.new_game(SEED, _db)
	for f: String in flags:
		gs.flags[f] = true
	gs.player.place("dungeon_rift", BY_THE_ROPES)
	Commands.settle(gs, _db)
	return gs


func test_the_ropes_are_hidden_until_the_new_section_is_found() -> void:
	var gs := _at_the_rift()
	assert_true(FightBot.move(gs, _db, "e")["moved"])
	assert_eq(gs.player.area, "dungeon_rift", "no ropes yet")
	gs.flags[FOUND] = true
	FightBot.move(gs, _db, "w")
	var before := gs.clock.total_minutes
	FightBot.move(gs, _db, "e")
	assert_eq(gs.player.area, "liscor_depths")
	assert_eq(gs.player.pos(), Vector2i(3, 2))
	assert_eq(gs.clock.total_minutes - before, 10, "a 10-minute climb")
	for t: Dictionary in _db.maps.areas["liscor_depths"]["traps"]:  # walking only here (M13.T)
		gs.combat.traps[Traps.key("liscor_depths", t["id"])] = {"disarmed": true}
	assert_true(ToyMaps.walk_to_area(gs, _db, "liscor_crypt"), "the stairs down to the crypt level")
	assert_true(ToyMaps.walk_to_area(gs, _db, "liscor_depths"))
	assert_true(ToyMaps.walk_to_area(gs, _db, "dungeon_rift"), "and up the ropes again")


## Rolls the spawns of `area` until the cap; returns the types that came.
func _spawned(area: String, at: Vector2i) -> Dictionary:
	var gs := _at_the_rift([FOUND])
	gs.player.place(area, at)
	Commands.settle(gs, _db)
	var types := {}
	for i in 30:
		for id: String in MonsterSim.spawn_check(gs, _db):
			types[gs.combat.monsters[id]["type"]] = true
	return types


func test_monsters_spawn_in_the_depths_and_the_crypt() -> void:
	var depths := _spawned("liscor_depths", Vector2i(3, 2))
	assert_false(depths.is_empty(), "the trapped rooms")
	for t: String in depths:
		assert_has(["shield_spider", "cave_goblin"], t)
	var crypt := _spawned("liscor_crypt", Vector2i(2, 2))
	assert_false(crypt.is_empty(), "the crypt level")
	for t: String in crypt:
		assert_has(["skeleton", "zombie", "crypt_worm", "giant_leech", "cave_goblin", "not_gnoll"], t)


func test_a_knock_out_in_the_dungeon_wakes_you_at_the_inn() -> void:
	for area: String in ["liscor_depths", "liscor_crypt", "inn_upper_floor", "inn_watchtower"]:
		var gs := _at_the_rift([FOUND])
		gs.player.place(area, Vector2i(2, 2) if area != "inn_watchtower" else Vector2i(4, 4))
		Combat.night(gs, _db, false, true)
		assert_eq(gs.player.area, "inn_interior", area)
		assert_eq(gs.player.pos(), Vector2i(20, 13), area)


func test_toren_walks_the_rune_hall() -> void:
	var gs := _at_the_rift([FOUND])
	gs.flags["toren.in_liscor_dungeon"] = true
	Commands.wait(gs, _db, 600)
	var toren: Dictionary = gs.npcs.npcs["toren"]
	assert_eq(toren["area"], "liscor_depths")
	assert_eq(toren["goal"], "patrol")


## Every map has a music mood, and every map where monsters spawn has a
## knock-out wake spot (a guard for new maps).
func test_every_map_has_a_mood_and_every_spawn_map_a_wake_spot() -> void:
	var audio: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/audio.json"))
	var by_map: Dictionary = audio["moods"]["by_map"]
	var by_location: Dictionary = audio["moods"]["by_location"]
	for area: String in _db.maps.areas:
		var loc := String(_db.maps.areas[area]["location"])
		assert_true(by_map.has(area) or by_location.has(loc), "%s has a mood" % area)
	var wake: Dictionary = _db.rules["combat"]["knockout"]["wake"]
	for s: Dictionary in _db.combat.spawns:
		assert_true(wake.has(s["area"]), "%s has a wake spot" % s["area"])


## M13.T: the real traps. A rune in the rune hall springs; the covered pit
## drops you to the crypt level; a search next to a rune can find it.
func test_the_trapped_rooms_have_traps() -> void:
	var gs := _at_the_rift([FOUND])
	gs.player.place("liscor_depths", Vector2i(14, 3))
	Commands.settle(gs, _db)
	var r := FightBot.move(gs, _db, "e")
	assert_eq(r["sprung"].get("id", ""), "rune_hall_glyph_1")
	assert_true(Combat.hp(gs, _db) < Stats.max_hp(gs, _db))
	gs.player.place("liscor_depths", Vector2i(17, 9))
	Commands.settle(gs, _db)
	r = FightBot.move(gs, _db, "s")
	assert_eq(r["sprung"].get("drop_to", ""), "liscor_crypt")
	assert_eq(gs.player.area, "liscor_crypt")
	var found := false
	for i in 20:
		var g := GameState.new_game(SEED + i, _db)
		g.flags[FOUND] = true
		g.player.place("liscor_depths", Vector2i(20, 4))
		Commands.settle(g, _db)
		g.combat.monsters.clear()  # no spawned foes in the way of the search
		g.combat.fight = {}
		assert_eq(Commands.interact(g, _db, Traps.SEARCH, "search_for_traps")["error"], "")
		var t := Traps.trap_of(g, _db, "liscor_depths", "rune_hall_glyph_2")
		if Traps.state(g, "liscor_depths", t)["found"]:
			found = true
			break
	assert_true(found, "a search finds the rune sooner or later")
