extends GutTest
## M19.0 (ADR 0030): a magic door with several links. The inn's Albez door is
## given two links in memory (Celum, and a test far end on the Liscor gate
## road that opens only by flag and hours); the old single form still works.

const INN_DOOR := "albez_door"
const NEXT_TO_INN_DOOR := Vector2i(3, 12)
const GATE_POS := [3, 12]

var _db: DataDb
var _saved: Dictionary


func before_all() -> void:
	_db = DataDb.load_dir()


func before_each() -> void:
	_saved = _door()["portal"].duplicate(true)
	_door()["portal"] = {"links": [
		{"id": "celum", "to": "celum_stitchworks", "pos": [9, 3], "power_flags": ["erin.magical_grounds"]},
		{"id": "gate", "name": "the Liscor gate", "to": "liscor_gate", "pos": GATE_POS, "power_flags": [],
			"when_flags": ["test.gate_open"], "unless_flags": ["test.gate_closed"], "hours": [6, 12]}]}


func after_each() -> void:
	_door()["portal"] = _saved


func _door() -> Dictionary:
	for o: Dictionary in _db.maps.areas["inn_interior"]["objects"]:  # not objects_on: that hides flagged objects
		if o["id"] == INN_DOOR:
			return o
	return {}


func _game(hour: int = 9) -> GameState:
	var gs := GameState.new_game(7, _db)
	gs.player.place("inn_interior", NEXT_TO_INN_DOOR)
	Commands.set_flag(gs, "albez_door.at_wandering_inn")
	Commands.set_flag(gs, "erin.magical_grounds")
	Commands.set_flag(gs, "test.gate_open")
	gs.clock.total_minutes += posmod(hour * 60 - gs.clock.minute(), Clock.MINUTES_PER_DAY)
	Commands.settle(gs, _db)
	return gs


func _ids(links: Array[Dictionary]) -> Array:
	return links.map(func(l: Dictionary) -> String: return l["id"])


func test_the_old_single_form_is_one_link() -> void:
	# M19.1: the real door has links now; the old form is written out here.
	var old_form := {"to": "celum_stitchworks", "pos": [9, 3], "power_flags": ["erin.magical_grounds"]}
	var links := Portal.links_of(old_form)
	assert_eq(links.size(), 1)
	assert_eq(links[0]["id"], "")
	assert_eq(links[0]["to"], "celum_stitchworks")
	assert_eq(Interact.portal_action(links[0]), Interact.PORTAL)
	assert_eq(Interact.portal_action({"id": "gate"}), "portal:gate")
	assert_true(Interact.is_portal_action("portal"))
	assert_true(Interact.is_portal_action("portal:gate"))
	assert_false(Interact.is_portal_action("buy:bread"))
	assert_eq(Interact.portal_link_of("portal:gate"), "gate")
	assert_eq(Interact.portal_link_of("portal"), "")


func test_a_link_is_on_offer_by_flags_and_hours() -> void:
	var gs := _game(9)
	var p: Dictionary = _door()["portal"]
	assert_eq(_ids(Portal.open_links(gs, p)), ["celum", "gate"])
	Commands.set_flag(gs, "test.gate_closed")
	assert_eq(_ids(Portal.open_links(gs, p)), ["celum"], "unless_flags")
	var late := _game(14)
	assert_eq(_ids(Portal.open_links(late, p)), ["celum"], "hours [6, 12)")
	var early := _game(5)
	assert_eq(_ids(Portal.open_links(early, p)), ["celum"])
	var none := GameState.new_game(7, _db)
	assert_eq(_ids(Portal.open_links(none, p)), ["celum"], "no gate_open flag")


func test_the_link_the_player_picks_is_the_one_used() -> void:
	var gs := _game(9)
	assert_eq(Commands.portal(gs, _db, INN_DOOR, "gate"), "")
	assert_eq(gs.player.area, "liscor_gate")
	assert_eq(gs.player.pos(), Vector2i(GATE_POS[0], GATE_POS[1]))
	var gs2 := _game(9)
	assert_eq(Commands.portal(gs2, _db, INN_DOOR, "celum"), "")
	assert_eq(gs2.player.area, "celum_stitchworks")
	var rec: Dictionary = gs2.action_log.records[-1]
	assert_eq(rec["context"]["to"], "celum_stitchworks")


func test_no_link_named_takes_the_first_open_one() -> void:
	var gs := _game(9)
	assert_eq(Commands.portal(gs, _db, INN_DOOR), "")
	assert_eq(gs.player.area, "celum_stitchworks")


func test_a_shut_link_refuses_and_costs_nothing() -> void:
	var gs := _game(14)
	assert_eq(Commands.portal(gs, _db, INN_DOOR, "gate"), _db.rules["portal"]["shut_line"])
	assert_eq(gs.player.area, "inn_interior")
	assert_eq(gs.player.portal_trips, 0)
	assert_eq(Commands.portal(gs, _db, INN_DOOR, "nowhere"), "The door has no link 'nowhere'.")


func test_every_link_has_its_own_power() -> void:
	var gs := _game(9)
	gs.flags.erase("erin.magical_grounds")
	assert_eq(Commands.portal(gs, _db, INN_DOOR, "celum"), _db.rules["portal"]["dry_line"])
	assert_eq(Commands.portal(gs, _db, INN_DOOR, "gate"), "", "the gate link needs no power flag")


func test_the_trips_are_one_shared_count() -> void:
	var gs := _game(9)
	assert_eq(Commands.portal(gs, _db, INN_DOOR, "gate"), "")
	assert_eq(Portal.trips_left(gs, _db), 3)
	gs.player.place("inn_interior", NEXT_TO_INN_DOOR)
	assert_eq(Commands.portal(gs, _db, INN_DOOR, "celum"), "")
	assert_eq(Portal.trips_left(gs, _db), 2, "both links draw from the same four trips")
	gs.player.portal_trips = 4
	gs.player.place("inn_interior", NEXT_TO_INN_DOOR)
	assert_eq(Commands.portal(gs, _db, INN_DOOR, "gate"), _db.rules["portal"]["spent_line"])


func test_the_menu_name_of_a_link() -> void:
	var p: Dictionary = _door()["portal"]
	assert_eq(Portal.link_name(_db, p["links"][0]), _db.maps.areas["celum_stitchworks"]["name"], "the far map's name")
	assert_eq(Portal.link_name(_db, p["links"][1]), "the Liscor gate", "its own name")


func test_the_real_data_has_no_errors_with_links() -> void:
	assert_eq(_db.maps.validate(_db).filter(func(e: String) -> bool: return e.contains("portal")), [])


func _bad(portal: Dictionary) -> Array:
	var tiles := {"floor": {"name": "Floor", "walk": true, "color": "#888888"},
		"wall": {"name": "Wall", "walk": false, "color": "#444444"}}
	var a := {"schema_version": 1, "id": "a", "name": "A", "location": "stitchworks", "confidence": "guess",
		"legend": {".": "floor", "#": "wall"}, "rows": ["....", "....", "...."], "zones": {}, "exits": [],
		"objects": [{"id": "d", "at": [0, 0], "name": "Door", "actions": [], "portal": portal}]}
	return MapDb.from_dicts(tiles, {"a": a}).validate(_db).filter(
			func(e: String) -> bool: return e.contains("object 'd'"))


func _has(errs: Array, part: String) -> bool:
	return errs.any(func(e: String) -> bool: return e.contains(part))


func test_bad_links_are_reported() -> void:
	var ok := {"id": "x", "to": "a", "pos": [1, 1]}
	assert_eq(_bad({"links": [ok]}), [], "a good link")
	assert_true(_has(_bad({"links": []}), "non-empty list"))
	assert_true(_has(_bad({"links": [ok], "to": "a"}), "replace to / pos"))
	assert_true(_has(_bad({"links": [{"to": "a", "pos": [1, 1]}]}), "needs an id"))
	assert_true(_has(_bad({"links": [{"id": "a:b", "to": "a", "pos": [1, 1]}]}), "needs an id"))
	assert_true(_has(_bad({"links": [ok, ok]}), "duplicate portal link id"))
	assert_true(_has(_bad({"links": [{"id": "x", "to": "nowhere", "pos": [1, 1]}]}), "unknown map"))
	assert_true(_has(_bad({"links": [{"id": "x", "to": "a", "pos": [9, 9]}]}), "walkable tile"))
	assert_true(_has(_bad({"links": [{"id": "x", "to": "a", "pos": [1, 1], "when_flags": "f"}]}),
			"when_flags must be a list"))
	assert_true(_has(_bad({"links": [{"id": "x", "to": "a", "pos": [1, 1], "hours": [6]}]}), "portal hours"))
	assert_true(_has(_bad({"links": [{"id": "x", "to": "a", "pos": [1, 1], "hours": [6, 25]}]}), "portal hours"))
	assert_true(_has(_bad({"links": [{"id": "x", "to": "a", "pos": [1, 1], "name": 3}]}), "name must be a string"))
