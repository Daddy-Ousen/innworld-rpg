extends GutTest
## M10.0 (ADR 0017): the Albez door. Door objects show on the map only while
## their flags hold; a door works only while its power flags hold, and the
## player has rules.portal.trips_per_day trips a day. Save v13 keeps the
## count.

const INN_DOOR := "albez_door"
const CELUM_DOOR := "albez_door_celum"
const NEXT_TO_INN_DOOR := Vector2i(3, 12)
const NEXT_TO_CELUM_DOOR := Vector2i(9, 3)

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()


func _game() -> GameState:
	var gs := GameState.new_game(7, _db)
	gs.player.place("inn_interior", NEXT_TO_INN_DOOR)
	Commands.settle(gs, _db)
	return gs


func _open_both_ends(gs: GameState, powered: bool = true) -> void:
	Commands.set_flag(gs, "albez_door.at_wandering_inn")
	Commands.set_flag(gs, "albez_door.anchor_at_stitchworks")
	if powered:
		Commands.set_flag(gs, "erin.magical_grounds")
	Commands.settle(gs, _db)


func _has_option(gs: GameState, id: String) -> bool:
	return Interact.options(gs, _db).any(func(o: Dictionary) -> bool: return o["id"] == id)


func test_the_door_data_loads() -> void:
	assert_eq(_db.errors, [] as Array[String])
	assert_true(_db.maps.areas.has("celum_stitchworks"), "Octavia's shop")
	assert_true(_db.maps.is_indoor("celum_stitchworks"))
	var exits: Array = _db.maps.areas["celum_square"]["exits"]
	assert_eq(exits.filter(func(e: Dictionary) -> bool: return e["to"] == "celum_stitchworks").size(), 1,
			"a door from the square")
	assert_eq(Interact.object_of(_db, "inn_interior", INN_DOOR)["portal"]["to"], "celum_stitchworks")
	assert_eq(int(_db.rules["portal"]["trips_per_day"]), 4)


func test_no_door_before_its_flags() -> void:
	var gs := _game()
	assert_false(_has_option(gs, INN_DOOR), "no magic door at the inn yet")
	assert_ne(Commands.portal(gs, _db, INN_DOOR), "")
	assert_eq(gs.player.area, "inn_interior")
	_open_both_ends(gs, false)
	assert_true(_has_option(gs, INN_DOOR), "the door stands in the inn")


func test_a_dry_door_does_not_open() -> void:
	var gs := _game()
	_open_both_ends(gs, false)
	assert_eq(Commands.portal(gs, _db, INN_DOOR), _db.rules["portal"]["dry_line"])
	assert_eq(gs.player.area, "inn_interior")
	assert_eq(gs.player.portal_trips, 0)


func test_stepping_through_and_back() -> void:
	var gs := _game()
	_open_both_ends(gs)
	var before := gs.clock.total_minutes
	assert_eq(Commands.portal(gs, _db, INN_DOOR), "")
	assert_eq(gs.player.area, "celum_stitchworks")
	assert_eq(gs.player.pos(), NEXT_TO_CELUM_DOOR)
	assert_eq(gs.clock.total_minutes - before, int(_db.rules["portal"]["minutes"]))
	var rec: Dictionary = gs.action_log.records[-1]
	assert_eq(rec["action_id"], "travel")
	assert_true(rec["context"].get("portal", false), "a portal trip")
	assert_eq(Portal.trips_left(gs, _db), 3)
	assert_eq(Commands.portal(gs, _db, CELUM_DOOR), "")
	assert_eq(gs.player.area, "inn_interior")
	assert_eq(gs.player.pos(), NEXT_TO_INN_DOOR)
	assert_eq(Portal.trips_left(gs, _db), 2)


func test_four_trips_a_day_then_the_next_day() -> void:
	var gs := _game()
	_open_both_ends(gs)
	for i in 4:
		assert_eq(Commands.portal(gs, _db, INN_DOOR if i % 2 == 0 else CELUM_DOOR), "", "trip %d" % i)
	assert_eq(gs.player.area, "inn_interior")
	assert_eq(Commands.portal(gs, _db, INN_DOOR), _db.rules["portal"]["spent_line"])
	assert_eq(gs.player.area, "inn_interior")
	Commands.sleep(gs, _db, Rest.ANYWHERE)
	gs.player.place("inn_interior", NEXT_TO_INN_DOOR)
	Commands.settle(gs, _db)
	assert_eq(Portal.trips_left(gs, _db), 4, "the door has mana again")
	assert_eq(Commands.portal(gs, _db, INN_DOOR), "")


func test_the_celum_end_needs_its_own_flag() -> void:
	var gs := _game()
	Commands.set_flag(gs, "albez_door.at_wandering_inn")
	Commands.set_flag(gs, "erin.magical_grounds")
	Commands.settle(gs, _db)
	assert_eq(Commands.portal(gs, _db, INN_DOOR), "")
	assert_false(_has_option(gs, CELUM_DOOR), "no anchor door at Octavia's")


func test_the_shop_door_leads_in_and_sells() -> void:
	var gs := _game()
	gs.player.place("celum_square", Vector2i(2, 13))
	Commands.settle(gs, _db)
	Commands.move(gs, _db, "w")
	assert_eq(gs.player.area, "celum_stitchworks")
	assert_eq(Commands.give(gs, _db, 100), "")
	assert_true(ToyMaps.walk_next_to(gs, _db, "octavia_counter"))
	assert_eq(Commands.buy(gs, _db, "octavia_counter", "healing_potion")["error"], "")


func test_the_trip_count_is_saved() -> void:
	var gs := _game()
	_open_both_ends(gs)
	assert_eq(Commands.portal(gs, _db, INN_DOOR), "")
	var copy := GameState.from_json(gs.to_json())
	assert_eq(copy.player.portal_day, gs.clock.day())
	assert_eq(copy.player.portal_trips, 1)


func test_a_v12_save_loads_with_no_trips() -> void:
	var d := _game().to_dict()
	(d["player"] as Dictionary).erase("portal_day")
	(d["player"] as Dictionary).erase("portal_trips")
	d["save_version"] = 12
	var gs := GameState.from_dict(SaveMigrations.migrate(d))
	assert_eq(gs.save_version, GameState.SAVE_VERSION)
	assert_eq(gs.player.portal_day, -1)
	assert_eq(gs.player.portal_trips, 0)


func test_bad_portal_data_is_reported() -> void:
	var tiles := {"floor": {"name": "Floor", "walk": true, "color": "#888888"},
		"wall": {"name": "Wall", "walk": false, "color": "#444444"}}
	var rows := ["....", "....", "...."]
	var base := {"schema_version": 1, "name": "A", "location": "stitchworks", "confidence": "guess",
		"legend": {".": "floor", "#": "wall"}, "rows": rows, "zones": {}, "exits": []}
	var a := base.duplicate(true)
	a["id"] = "a"
	a["objects"] = [
		{"id": "no_power", "at": [0, 0], "name": "Door", "actions": [], "portal": {"to": "a", "pos": [1, 1]}},
		{"id": "bad_to", "at": [1, 0], "name": "Door", "actions": [],
			"portal": {"to": "nowhere", "pos": [1, 1], "power_flags": []}},
		{"id": "solid_hidden", "at": [2, 0], "name": "Door", "actions": [], "solid": true, "when_flags": ["x"]},
		{"id": "bad_flags", "at": [3, 0], "name": "Door", "actions": [], "unless_flags": "x"}]
	var maps := MapDb.from_dicts(tiles, {"a": a})
	var errs := maps.validate(_db)
	for part: String in ["portal must be {to, pos, power_flags}", "portal to unknown map 'nowhere'",
			"an object with flags must not be solid", "unless_flags must be a list of strings"]:
		assert_true(errs.any(func(e: String) -> bool: return e.contains(part)), part)


func test_bad_portal_rules_are_reported() -> void:
	var rules: Dictionary = _db.rules.duplicate(true)
	(rules["portal"] as Dictionary).erase("spent_line")
	var db := DataDb.from_dicts(_db.tags, _db.actions, rules)
	assert_true(db.errors.has("rules.portal: missing 'spent_line'."))
