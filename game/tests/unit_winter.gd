extends GutTest
## Winter (M8.W, ADR 0014) on toy maps: the cold, warmth (indoors, fires,
## clothes), the night, the Frost Fairies (talk, snow, swat, iron), the
## snow-wall overlays, and the save.

const FLAG := "izril.winter"

var _db: DataDb


## ToyCombat's world plus a winter: a 10×7 open "yard" (outdoors) with a
## warm brazier at 7,1; the shop is indoors. The fairies always come (2),
## never annoyed unless a test says so.
func before_each() -> void:
	_db = ToyCombat.db()
	_db.tags["fae"] = ""
	_db.tags["social"] = ""
	_db.tags["social.conversation"] = ""
	_db.actions["talk_to_fairy"] = {"name": "Talk with a Frost Fairy", "minutes": 5, "base_xp": 6,
		"risk": 0.2, "tags": {"fae": 1.0, "social.conversation": 0.3}}
	var w: Dictionary = DataDb.load_dir().rules["winter"].duplicate(true)
	w["fairies"]["chance"] = 1.0
	w["fairies"]["count"] = [2, 2]
	w["fairies"]["annoy_chance"] = 0.0
	_db.rules["winter"] = w
	var tiles := ToyMaps.tiles()
	tiles["grass"]["winter_color"] = "#eeeeee"
	tiles["snow"] = {"name": "Snow wall", "walk": false, "color": "#ffffff"}
	var areas := _db.maps.areas.duplicate(true)
	(areas["shop"] as Dictionary)["indoor"] = true
	areas["yard"] = ToyMaps.area("yard", "toy_field", ["gggggggggg", "gggggggggg", "gggggggggg",
		"gggggggggg", "gggggggggg", "gggggggggg", "gggggggggg"], {}, [], [
		{"id": "brazier", "at": [7, 1], "name": "Brazier", "actions": [], "solid": true, "warm": true},
	])
	(areas["yard"] as Dictionary)["legend"]["s"] = "snow"
	(areas["yard"] as Dictionary)["overlays"] = [
		{"id": "wall", "tile": "snow", "when_flags": ["yard.walled"], "rects": [[2, 3, 3, 1]]},
	]
	_db.maps = MapDb.from_dicts(tiles, areas)
	_db.combat.items["horseshoe"] = {"name": "Horseshoe", "confidence": "guess", "melee": [1, 2],
		"throw": [1, 3], "throw_range": 4, "break_chance": 0.0, "tags": ["iron"]}
	_db.errors.clear()
	_db._validate_rules()
	assert_eq(_db.errors, [] as Array[String])
	assert_eq(_db.maps.validate(_db), [] as Array[String])


func _game(area: String = "yard", pos: Vector2i = Vector2i(1, 5), winter: bool = true) -> GameState:
	var gs := GameState.new_game(1, _db)
	if winter:
		gs.flags[FLAG] = true
	gs.player.place(area, pos)
	Commands.settle(gs, _db)
	return gs


func _max(gs: GameState) -> int:
	return Stats.max_hp(gs, _db)


func test_no_cold_before_winter() -> void:
	var gs := _game("yard", Vector2i(1, 5), false)
	Commands.wait(gs, _db, 3 * 3600)
	assert_eq(Combat.hp(gs, _db), _max(gs))
	assert_eq(Winter.status(gs, _db), "")
	assert_true(gs.winter.fairies.is_empty())


func test_the_cold_bites_every_half_hour_outdoors() -> void:
	var gs := _game()
	assert_eq(Winter.status(gs, _db), "cold")
	Commands.wait(gs, _db, 29 * 60)
	assert_eq(Combat.hp(gs, _db), _max(gs))
	Commands.wait(gs, _db, 60)
	assert_eq(Combat.hp(gs, _db), _max(gs) - 1)
	assert_has(gs.combat.lines, _db.rules["winter"]["cold"]["line"] % 1)
	Commands.wait(gs, _db, 60 * 60)
	assert_eq(Combat.hp(gs, _db), _max(gs) - 3)


func test_the_cold_never_knocks_you_out() -> void:
	var gs := _game()
	Combat.set_hp(gs, _db, 2)
	Commands.wait(gs, _db, 5 * 3600)
	assert_eq(Combat.hp(gs, _db), 1)
	assert_false(Combat.is_down(gs))


func test_a_fire_or_a_roof_keeps_you_warm() -> void:
	var gs := _game("yard", Vector2i(7, 3))  # two tiles from the brazier
	assert_eq(Winter.status(gs, _db), "warm")
	Commands.wait(gs, _db, 2 * 3600)
	assert_eq(Combat.hp(gs, _db), _max(gs))
	assert_true(_db.maps.is_indoor("shop"))
	assert_false(_db.maps.is_indoor("yard"))
	gs = _game("shop", Vector2i(1, 1))
	assert_eq(Winter.status(gs, _db), "warm")
	Commands.wait(gs, _db, 2 * 3600)
	assert_eq(Combat.hp(gs, _db), _max(gs))


func test_warmth_resets_the_chill() -> void:
	var gs := _game()
	Commands.wait(gs, _db, 20 * 60)
	gs.player.place("yard", Vector2i(7, 2))
	Commands.wait(gs, _db, 6)
	assert_eq(gs.winter.chill, 0)
	gs.player.place("yard", Vector2i(1, 5))
	Commands.wait(gs, _db, 20 * 60)
	assert_eq(Combat.hp(gs, _db), _max(gs), "20 + 20 minutes apart is no bite")


func test_winter_clothes_halve_the_cold() -> void:
	var gs := _game()
	gs.flags[_db.rules["winter"]["clothes_flag"]] = true
	Commands.wait(gs, _db, 59 * 60)
	assert_eq(Combat.hp(gs, _db), _max(gs))
	Commands.wait(gs, _db, 60)
	assert_eq(Combat.hp(gs, _db), _max(gs) - 1)


func test_the_night_does_not_chill_and_warns_once() -> void:
	var gs := _game()
	gs.clock.advance(14 * 60)  # 20:00
	Commands.wait(gs, _db, 6)
	var night := Commands.sleep(gs, _db)
	assert_has(night["lines"], _db.rules["winter"]["cold"]["morning_line"])
	assert_eq(gs.winter.chill, 0)
	assert_eq(Combat.hp(gs, _db), _max(gs))
	gs.clock.advance(14 * 60)
	Commands.wait(gs, _db, 6)
	night = Commands.sleep(gs, _db)
	assert_does_not_have(night["lines"], _db.rules["winter"]["cold"]["morning_line"])


func test_fairies_come_outdoors_and_never_indoors() -> void:
	var gs := _game()
	assert_eq(gs.winter.area, "yard")
	assert_eq(gs.winter.ids().size(), 2)
	for id in gs.winter.ids():
		var at := WinterState.pos_of(gs.winter.fairies[id])
		assert_gte(maxi(absi(at.x - 1), absi(at.y - 5)), 3, "not next to the player")
	for i in 30:
		Commands.wait(gs, _db, 6)
	for id in gs.winter.ids():
		assert_true(_db.maps.in_bounds("yard", WinterState.pos_of(gs.winter.fairies[id])))
	gs.player.place("shop", Vector2i(1, 1))
	Commands.wait(gs, _db, 6)
	assert_true(gs.winter.fairies.is_empty())


func _fairy_next_to(gs: GameState, off: Vector2i = Vector2i(1, 0)) -> String:
	var id := gs.winter.ids()[0]
	var at := gs.player.pos() + off
	gs.winter.fairies[id] = {"x": at.x, "y": at.y}
	return id


func test_talking_to_a_fairy_gives_fae_xp_and_a_rude_line() -> void:
	var gs := _game()
	ToyCombat.freeze(_db)
	_db.rules["winter"]["fairies"]["act_seconds"] = 100000
	var id := _fairy_next_to(gs)
	var opts := Interact.options(gs, _db)
	var fairy := opts.filter(func(o: Dictionary) -> bool: return o["id"] == Winter.FAIRY + id)
	assert_eq(fairy.size(), 1)
	assert_eq(fairy[0]["actions"], ["talk_to_fairy"])
	var r := Commands.interact(gs, _db, Winter.FAIRY + id, "talk_to_fairy")
	assert_eq(r["error"], "")
	assert_eq(r["record"]["action_id"], "talk_to_fairy")
	assert_true(r["record"]["tags"].has("fae"))
	assert_true(gs.combat.lines.any(func(l: String) -> bool: return l.begins_with("Frost Fairy: ")))
	assert_eq(Combat.hp(gs, _db), _max(gs), "the first talk of the day is safe")


func test_pestering_fairies_brings_down_snow() -> void:
	var gs := _game()
	_db.rules["winter"]["fairies"]["act_seconds"] = 100000
	_db.rules["winter"]["fairies"]["annoy_chance"] = 1.0
	var id := _fairy_next_to(gs)
	Commands.interact(gs, _db, Winter.FAIRY + id, "talk_to_fairy")
	assert_eq(gs.winter.slowed, 0)
	Commands.interact(gs, _db, Winter.FAIRY + id, "talk_to_fairy")
	assert_has(gs.combat.lines, _db.rules["winter"]["fairies"]["snow_line"])
	assert_eq(gs.winter.slowed, int(_db.rules["winter"]["fairies"]["slow_steps"]))
	assert_lt(Combat.hp(gs, _db), _max(gs))


func test_a_swat_misses_and_the_snow_slows_you() -> void:
	var gs := _game()
	_db.rules["winter"]["fairies"]["act_seconds"] = 100000
	_fairy_next_to(gs)
	var before := NpcSim.world_sec(gs)
	var r := Commands.move(gs, _db, "e")
	assert_false(r["moved"])
	assert_ne(r["fairy"], "")
	assert_has(gs.combat.lines, _db.rules["winter"]["fairies"]["swat_line"])
	assert_eq(NpcSim.world_sec(gs) - before, 6, "the swat takes a turn")
	var slow := gs.winter.slowed
	assert_gt(slow, 0)
	gs.winter.fairies.clear()
	before = NpcSim.world_sec(gs)
	assert_true(Commands.move(gs, _db, "n")["moved"])
	assert_eq(NpcSim.world_sec(gs) - before, 12, "a slowed step takes double time")
	assert_eq(gs.winter.slowed, slow - 1)


func test_iron_keeps_fairies_away() -> void:
	var gs := _game()
	gs.player.held = "horseshoe"
	_db.rules["winter"]["fairies"]["annoy_chance"] = 1.0
	_fairy_next_to(gs)
	for i in 10:
		Commands.wait(gs, _db, 6)
	for id in gs.winter.ids():
		var at := WinterState.pos_of(gs.winter.fairies[id])
		assert_gte(maxi(absi(at.x - 1), absi(at.y - 5)), 2, "they back off")
	var id := _fairy_next_to(gs)
	_db.rules["winter"]["fairies"]["act_seconds"] = 100000
	Commands.move(gs, _db, "e")
	assert_eq(gs.winter.slowed, 0, "no snow on someone holding iron")
	assert_true(gs.winter.fairies.has(id))


func test_an_overlay_blocks_while_its_flag_holds() -> void:
	var gs := _game()
	var at := Vector2i(3, 3)
	assert_true(_db.maps.is_walkable("yard", at))
	gs.flags["yard.walled"] = true
	Commands.wait(gs, _db, 6)
	assert_false(_db.maps.is_walkable("yard", at))
	assert_eq(_db.maps.tile_at("yard", at), "snow")
	assert_ne(_db.maps.overlay_key, "")
	gs.flags.erase("yard.walled")
	Commands.wait(gs, _db, 6)
	assert_true(_db.maps.is_walkable("yard", at))


func test_bad_overlays_and_winter_colors() -> void:
	var tiles := ToyMaps.tiles()
	tiles["grass"]["winter_color"] = "white-ish"
	var areas := ToyMaps.areas()
	areas["field"]["overlays"] = [
		{"id": "a", "tile": "lava", "when_flags": ["x"], "rects": [[0, 1, 1, 1]]},
		{"id": "a", "tile": "wall", "rects": [[0, 0, 1, 1]]},
		{"id": "b", "tile": "wall", "when_flags": [3], "rects": [[3, 0, 5, 1]]},
	]
	var maps := MapDb.from_dicts(tiles, areas)
	var errs := maps.validate(_db)
	areas["town"]["indoor"] = "yes"
	maps = MapDb.from_dicts(tiles, areas)
	errs = maps.validate(_db)
	var has := func(part: String) -> bool: return errs.any(func(e: String) -> bool: return e.contains(part))
	assert_true(has.call("winter_color must be"), "bad winter colour")
	assert_true(has.call("map 'town': indoor must be true or false"))
	assert_true(has.call("overlay 'a': unknown tile 'lava'"))
	assert_true(has.call("covers an exit"))
	assert_true(has.call("overlay: missing 'when_flags'"))
	assert_true(has.call("overlay 'b': when_flags must be a list of strings"))
	assert_true(has.call("overlay 'b': rects must be"))


func test_bad_winter_rules() -> void:
	var w: Dictionary = _db.rules["winter"]
	w["cold"]["every_minutes"] = 0
	w["fairies"]["count"] = [3, 1]
	w["fairies"]["talk_action"] = "sing"
	w["fairies"].erase("lines")
	_db.errors.clear()
	_db._validate_rules()
	assert_true(_db.errors.any(func(e: String) -> bool: return e.contains("rules.winter.fairies: missing 'lines'")))
	w["fairies"]["lines"] = []
	_db.errors.clear()
	_db._validate_rules()
	for part: String in ["every_minutes", "count must be", "unknown talk_action 'sing'", "lines must be"]:
		assert_true(_db.errors.any(func(e: String) -> bool: return e.contains(part)), part)


func test_winter_survives_a_save() -> void:
	var gs := _game()
	Commands.wait(gs, _db, 20 * 60)
	gs.winter.slowed = 3
	var copy := GameState.from_json(gs.to_json())
	assert_eq(copy.winter.to_dict(), gs.winter.to_dict())
	Commands.wait(gs, _db, 15 * 60)
	Commands.wait(copy, _db, 15 * 60)
	assert_eq(copy.to_json(), gs.to_json(), "plays on the same")


func test_a_v9_save_loads_without_winter() -> void:
	var d := _game().to_dict()
	d.erase("winter")
	d["save_version"] = 9
	var gs := GameState.from_dict(SaveMigrations.migrate(d))
	assert_eq(gs.save_version, GameState.SAVE_VERSION)
	assert_eq(gs.winter.sec, -1)
	assert_true(gs.winter.fairies.is_empty())
