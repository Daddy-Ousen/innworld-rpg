extends GutTest
## Winter on the real data (M8.W): the canon flag izril.winter comes with
## the night of day 42 (2.05); the first winter morning warns about the
## cold. Toren's snow wall rings the inn once b2.toren_walls_the_inn_with_snow
## has happened (day 43, so from the morning of day 44), with a gap on the
## road to the door. Outdoors the cold bites; the Market Street braziers
## and the inn keep you warm.

var _db: DataDb
var _base_json := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	var gs := GameState.new_game(1, _db)
	ToyCanon.sleep_through(gs, _db, 40)
	_base_json = gs.to_json()


func _fresh() -> GameState:
	var gs := GameState.from_json(_base_json)
	_db.maps.sync_flags(gs.flags)
	return gs


func _sleep_to(gs: GameState, day: int) -> Array[String]:
	var lines: Array[String] = []
	while gs.clock.day() < day:
		lines.append_array(Commands.sleep(gs, _db)["lines"])
	return lines


func test_winter_data_is_sound() -> void:
	assert_eq(_db.errors, [] as Array[String])
	var w: Dictionary = _db.rules["winter"]
	assert_eq(w["flag"], "izril.winter")
	assert_true(_db.actions.has(w["fairies"]["talk_action"]))
	assert_true(_db.tags.has("fae"))
	assert_true(_db.maps.is_indoor("inn_interior"))
	for area: String in ["liscor_gate", "liscor_market", "floodplains_south", "inn_hill", "ruins_entrance"]:
		assert_false(_db.maps.is_indoor(area), area)
	assert_true((_db.combat.items["horseshoe"]["tags"] as Array).has(w["fairies"]["iron_tag"]))
	# The snow wall covers no tile an NPC, a spawn home or a stage needs.
	var wall := {}
	for o: Dictionary in _db.maps.areas["inn_hill"]["overlays"]:
		for r: Array in o["rects"]:
			var rect := MapDb.rect_of(r)
			for y in range(rect.position.y, rect.end.y):
				for x in range(rect.position.x, rect.end.x):
					wall[Vector2i(x, y)] = true
	for id in _db.behaviour.ids():
		for g: Dictionary in _db.behaviour.npcs[id]["goals"]:
			var t: Dictionary = g["target"]
			if t.get("area", "") != "inn_hill":
				continue
			var spots: Array = [t["pos"]] if t.has("pos") else t.get("route", [])
			for p: Array in spots:
				assert_false(wall.has(Vector2i(int(p[0]), int(p[1]))), "%s goal %s" % [id, p])
	for id: String in _db.canon.stages:
		var st: Dictionary = _db.canon.events[id]["stage"]
		if st["area"] != "inn_hill":
			continue
		for f: Dictionary in st.get("foes", []):
			assert_false(wall.has(Vector2i(int(f["pos"][0]), int(f["pos"][1]))), id)
		for n: Dictionary in st.get("npcs", []):
			assert_false(wall.has(Vector2i(int(n["pos"][0]), int(n["pos"][1]))), id)
		for wave: Dictionary in st.get("waves", []):
			assert_false(wall.has(Vector2i(int(wave["from"][0]), int(wave["from"][1]))), id)


func test_no_cold_before_winter() -> void:
	var gs := _fresh()
	assert_false(gs.flags.has("izril.winter"))
	gs.player.place("liscor_gate", Vector2i(3, 12))
	Commands.wait(gs, _db, 2 * 3600)
	assert_eq(Combat.hp(gs, _db), Stats.max_hp(gs, _db))


func test_winter_comes_with_a_warning_and_the_cold_bites() -> void:
	var gs := _fresh()
	var lines := _sleep_to(gs, 43)
	assert_true(gs.flags.has("izril.winter"))
	assert_has(lines, _db.rules["winter"]["cold"]["morning_line"])
	gs.player.place("liscor_gate", Vector2i(3, 12))
	Commands.settle(gs, _db)
	var full := Combat.hp(gs, _db)
	Commands.wait(gs, _db, 60 * 60)
	assert_eq(Combat.hp(gs, _db), full - 2, "two bites in an hour at the gate")
	gs.player.place("liscor_market", Vector2i(6, 10))  # beside the west brazier
	Commands.wait(gs, _db, 6)
	assert_eq(Winter.status(gs, _db), "warm")
	Commands.wait(gs, _db, 60 * 60)
	assert_eq(Combat.hp(gs, _db), full - 2, "warm by the brazier")


func test_torens_snow_wall_rings_the_inn_from_day_44() -> void:
	var gs := _fresh()
	_sleep_to(gs, 43)
	_db.maps.sync_flags(gs.flags)
	assert_true(_db.maps.is_walkable("inn_hill", Vector2i(12, 3)), "no wall on day 43")
	_sleep_to(gs, 44)
	assert_true(gs.flags.has("wandering_inn.snow_wall"))
	gs.player.place("inn_hill", Vector2i(16, 15))
	Commands.settle(gs, _db)
	assert_false(_db.maps.is_walkable("inn_hill", Vector2i(12, 3)))
	assert_false(_db.maps.is_walkable("inn_hill", Vector2i(10, 8)))
	assert_eq(_db.maps.tile_at("inn_hill", Vector2i(12, 13)), "snow_wall")
	for dir: String in ["n", "n", "n", "n"]:
		Commands.move(gs, _db, dir)
		if gs.player.area == "inn_interior":
			break
	assert_eq(gs.player.area, "inn_interior", "the road through the gap reaches the door")
