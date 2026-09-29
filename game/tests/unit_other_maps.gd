extends GutTest
## M16.6 (ADR 0026): the other maps. Gates with towers, the inn's board, Esthelm's shacks, the
## ruins' ditch, windows in room walls and cave decoration. All of it is map data: this test
## reads the real maps and checks that the pieces stand where the plan says and stay usable.

const ROOMS_WITH_WINDOWS: Array[String] = ["celum_frenzied_hare", "celum_runners_guild", "celum_stitchworks",
		"inn_interior", "inn_upper_floor", "liscor_adventurers_guild", "liscor_gnoll_tavern",
		"liscor_mages_guild", "liscor_tailless_thief", "liscor_watch_barracks", "liscor_watch_office"]
const CAVES: Array[String] = ["liscor_depths", "liscor_crypt", "bee_cave", "esthelm_creler_cave"]
const DECO: Array[String] = ["cobweb", "bones", "glow_mushrooms"]

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()


func _object(area: String, id: String) -> Dictionary:
	for o: Dictionary in _db.maps.areas[area]["objects"]:
		if o["id"] == id:
			return o
	return {}


func test_the_real_data_loads_clean() -> void:
	assert_eq(_db.maps.errors, [] as Array[String])


func test_gates_have_towers_and_signed_exits() -> void:
	var maps := _db.maps
	assert_eq(maps.tile_at("celum_gate", Vector2i(13, 1)), "building", "west tower")
	assert_eq(maps.tile_at("celum_gate", Vector2i(19, 1)), "building_b", "east tower")
	assert_false(maps.is_walkable("celum_gate", Vector2i(13, 1)), "a tower is solid")
	assert_true(maps.is_walkable("celum_gate", Vector2i(15, 2)), "the guard post beside the gate is free")
	assert_eq(_object("celum_gate", "celum_fee_stand")["sign"]["text"], "Gate fee")
	assert_eq(maps.tile_at("liscor_gate", Vector2i(0, 8)), "building", "gatehouse beside the gate")
	for pair: Array in [["celum_gate", "celum_square"], ["liscor_gate", "liscor_market"]]:
		for e: Dictionary in maps.areas[pair[0]]["exits"]:
			if e["to"] == pair[1]:
				assert_true(e.has("sign"), "%s exit to %s has a sign" % pair)
	for cell: Vector2i in [Vector2i(2, 10), Vector2i(2, 13), Vector2i(3, 12)]:
		assert_true(maps.is_walkable("liscor_gate", cell), "Liscor gate cell %s stays free (schedules, start)" % cell)


func test_the_inn_hill_has_the_goblin_board_and_no_invented_yard() -> void:
	var board := _object("inn_hill", "inn_goblin_board")
	assert_false(board.is_empty(), "the board by the door")
	assert_eq(board["sign"]["text"], "No Killing Goblins")
	for o: Dictionary in _db.maps.areas["inn_hill"]["objects"]:
		assert_false(["stable", "fence", "well"].has(o["kind"]), "%s: the text has no stable, fence or well" % o["id"])


func test_esthelm_has_four_refugee_shacks_and_no_green_square() -> void:
	for i in range(1, 5):
		var shack := _object("esthelm_ruins", "esthelm_shack_%d" % i)
		assert_false(shack.is_empty(), "shack %d" % i)
		assert_eq(shack["kind"], "plaque")
		var want := "plain_house" if i % 2 == 1 else "plain_house_b"
		assert_eq(_db.maps.tile_at("esthelm_ruins", Vector2i(shack["at"][0], shack["at"][1])), want)
	assert_eq(_db.maps.tile_at("esthelm_ruins", Vector2i(26, 16)), "cobble")


func test_the_ruins_entrance_has_a_ditch_and_watch_tents_but_an_open_fight_ground() -> void:
	var maps := _db.maps
	assert_eq(maps.tile_at("ruins_entrance", Vector2i(9, 6)), "chasm")
	assert_eq(maps.tile_at("ruins_entrance", Vector2i(22, 6)), "chasm")
	assert_false(_object("ruins_entrance", "watch_post_west").is_empty())
	assert_false(_object("ruins_entrance", "watch_post_east").is_empty())
	assert_true(maps.is_walkable("ruins_entrance", Vector2i(18, 9)), "Gazi's stage tile")
	assert_true(maps.is_walkable("ruins_entrance", Vector2i(15, 8)), "the palisade gap")


func test_the_road_camp_signs_its_three_roads() -> void:
	var texts := []
	for e: Dictionary in _db.maps.areas["road_camp"]["exits"]:
		assert_true(e.has("sign"), "%s exit is signed" % e["to"])
		texts.append(e["sign"]["text"])
	assert_eq(texts.size(), 3)


func test_room_walls_have_windows_that_are_walls() -> void:
	for id: String in ROOMS_WITH_WINDOWS:
		var n := 0
		var s := _db.maps.size(id)
		for x in s.x:
			var at := Vector2i(x, 0)
			if _db.maps.tile_at(id, at) == "wood_window":
				n += 1
				assert_false(_db.maps.is_walkable(id, at), "%s (%d,0): a window is a wall" % [id, x])
				assert_true(_db.maps.raw_exit_at(id, at).is_empty(), "%s (%d,0): no exit in a window" % [id, x])
		assert_gt(n, 0, "%s has a window" % id)


func test_caves_have_decoration_that_never_blocks() -> void:
	for id: String in CAVES:
		var n := 0
		for o: Dictionary in _db.maps.areas[id]["objects"]:
			if DECO.has(String(o["kind"])):
				n += 1
				assert_eq((o["actions"] as Array).size(), 0, "%s: decoration has no action" % o["id"])
				assert_false(o.get("solid", false), "%s: decoration is not solid" % o["id"])
		assert_gte(n, 2, "%s has decoration" % id)
