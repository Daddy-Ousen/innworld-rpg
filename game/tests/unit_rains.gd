extends GutTest
## M19.0 (ADR 0030): the spring rains. Two flags (rules.rains): rain falls
## outdoors (look and sound), and the flood stands (map overlays that block
## walking). Toy maps for the mechanics; the real db for the data.

const SEASON := "izril.rains"
const FLOOD := "izril.flood"
const NOON := 720

var _db: DataDb


func before_each() -> void:
	_db = ToyMaps.db()
	_db.rules["rains"] = {"season_flag": SEASON, "flood_flag": FLOOD}
	_db.maps.areas["field"]["overlays"] = [
		{"id": "flood", "tile": "water", "when_flags": [FLOOD], "rects": [[2, 0, 1, 3]]}]
	_db.errors.clear()
	_db._validate_rules()


func _view(rain_flag: String = SEASON) -> WorldView:
	var v: WorldView = add_child_autofree(load("res://world/world_view.tscn").instantiate())
	v.setup(_db.maps, {}, {}, {}, "", {}, rain_flag)
	return v


func _at(gs: GameState, minute: int) -> void:
	gs.clock.total_minutes = gs.clock.total_minutes - gs.clock.minute() + minute


func test_the_flags_are_read_from_the_rules() -> void:
	var gs := ToyMaps.new_game(_db)
	assert_false(Rains.on(gs, _db))
	assert_false(Rains.flooded(gs, _db))
	gs.flags[SEASON] = true
	assert_true(Rains.on(gs, _db))
	assert_false(Rains.flooded(gs, _db), "rain alone is no flood")
	gs.flags[FLOOD] = true
	assert_true(Rains.flooded(gs, _db))


func test_a_db_without_rains_rules_has_no_rain() -> void:
	var d := ToyMaps.db()
	d.rules.erase("rains")
	var gs := ToyMaps.new_game(d)
	gs.flags[SEASON] = true
	assert_false(Rains.on(gs, d))
	assert_false(Rains.flooded(gs, d))
	assert_eq(Rains.rules(d), {})


func test_the_real_rules_have_two_different_flags() -> void:
	var real := DataDb.load_dir()
	assert_eq(real.errors, [] as Array[String])
	var r := Rains.rules(real)
	assert_ne(r["season_flag"], "")
	assert_ne(r["flood_flag"], "")
	assert_ne(r["season_flag"], r["flood_flag"])


func test_bad_rains_rules_are_reported() -> void:
	var rules: Dictionary = _db.rules.duplicate(true)
	(rules["rains"] as Dictionary).erase("flood_flag")
	assert_true(DataDb.from_dicts(_db.tags, _db.actions, rules).errors.has("rules.rains: missing 'flood_flag'."))
	rules["rains"] = {"season_flag": "", "flood_flag": "x"}
	assert_true(DataDb.from_dicts(_db.tags, _db.actions, rules).errors.has(
			"rules.rains: season_flag must be a non-empty flag name."))
	rules["rains"] = {"season_flag": "x", "flood_flag": "x"}
	assert_true(DataDb.from_dicts(_db.tags, _db.actions, rules).errors.has(
			"rules.rains: season_flag and flood_flag must differ."))
	rules["rains"] = 3
	assert_true(DataDb.from_dicts(_db.tags, _db.actions, rules).errors.has("rules.rains: must be an object."))


func test_rain_falls_outdoors_while_the_season_flag_holds() -> void:
	var v := _view()
	var gs := ToyMaps.new_game(_db)
	_at(gs, NOON)
	v.refresh(gs)
	assert_false(v.atmosphere.rain.emitting, "dry before the rains")
	gs.flags[SEASON] = true
	v.refresh(gs)
	assert_true(v.atmosphere.rain.emitting, "rain outdoors")
	assert_true(v.atmosphere.rain.visible)
	assert_false(v.atmosphere.snow.emitting, "no snow in the rains")
	gs.flags.erase(SEASON)
	v.refresh(gs)
	assert_false(v.atmosphere.rain.emitting, "the rains end")


func test_no_rain_indoors() -> void:
	var v := _view()
	var gs := ToyMaps.new_game(_db)
	gs.flags[SEASON] = true
	_db.maps._indoor["shop"] = true
	gs.player.place("shop", Vector2i(1, 1))
	v.refresh(gs)
	assert_false(v.atmosphere.rain.emitting)


func test_a_view_with_no_rain_flag_never_rains() -> void:
	var v := _view("")
	var gs := ToyMaps.new_game(_db)
	gs.flags[SEASON] = true
	v.refresh(gs)
	assert_false(v.atmosphere.rain.emitting)


func test_the_flood_blocks_walking_until_it_goes() -> void:
	var gs := ToyMaps.new_game(_db)
	gs.player.place("field", Vector2i(1, 1))
	Commands.settle(gs, _db)
	assert_true(Commands.move(gs, _db, "e")["moved"], "dry: the tile is walkable")
	gs.player.place("field", Vector2i(1, 1))
	gs.flags[FLOOD] = true
	var r: Dictionary = Commands.move(gs, _db, "e")
	assert_true(r["blocked"], "the flood water blocks")
	assert_eq(gs.player.pos(), Vector2i(1, 1))
	assert_eq(_db.maps.tile_at("field", Vector2i(2, 1)), "water")
	gs.flags.erase(FLOOD)
	assert_true(Commands.move(gs, _db, "e")["moved"], "the flood is gone")


func test_the_rain_bed_replaces_the_outdoor_bed_only_in_rain() -> void:
	var a := AudioDb.load_file()
	assert_eq(AmbiencePick.bed_for(a, "outdoor", false, false, true), "amb_rain")
	assert_eq(AmbiencePick.bed_for(a, "outdoor", true, false, true), "amb_rain", "at night too")
	assert_eq(AmbiencePick.bed_for(a, "outdoor", false, false), "amb_birds", "dry as before")
	assert_eq(AmbiencePick.bed_for(a, "market", false, false, true), "amb_rain")
	assert_eq(AmbiencePick.bed_for(a, "cave", false, false, true), "amb_cave", "a cave keeps its bed")
	assert_eq(AmbiencePick.bed_for(a, "tavern", false, false, true), "amb_crowd")
	assert_eq(AmbiencePick.bed_for(a, "", false, false, true), "", "no place: silence")
	assert_false(a.sound("amb_rain").is_empty(), "the cue is defined")


func test_the_rain_bed_follows_the_game() -> void:
	var real := DataDb.load_dir()
	var a := AudioDb.load_file()
	var gs := GameState.new_game(1, real)
	gs.player.place("liscor_gate", Vector2i(3, 12))
	_at(gs, NOON)
	assert_eq(AmbiencePick.bed(gs, real, a), "amb_birds")
	gs.flags[Rains.rules(real)["season_flag"]] = true
	assert_eq(AmbiencePick.bed(gs, real, a), "amb_rain")
