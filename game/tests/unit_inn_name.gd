extends GutTest
## M29.1 (ADR 0044): the inn is "The abandoned inn on the hill" until Erin names it (1.18,
## flag wandering_inn.named); the name sign and the No Killing Goblins board show from their flags.

const NAMED := "wandering_inn.named"
const BOARD := "wandering_inn.no_killing_goblins_sign"

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()


func after_each() -> void:
	_db.maps.sync_flags({})


func test_location_name_follows_the_flag() -> void:
	assert_eq(_db.canon.location_name({}, "wandering_inn"), "The abandoned inn on the hill")
	assert_eq(_db.canon.location_name({NAMED: true}, "wandering_inn"), "The Wandering Inn")
	assert_eq(_db.canon.location_name({}, "liscor"), _db.canon.locations["liscor"]["name"], "no names: the name")
	assert_eq(_db.canon.location_name({}, "no_such_place"), "no_such_place")


func test_the_last_set_name_wins() -> void:
	var c := CanonDb.from_dicts({}, {"p": {"name": "A", "names": [{"flag": "f1", "name": "B"},
			{"flag": "f2", "name": "C"}]}}, {})
	assert_eq(c.location_name({"f1": true}, "p"), "B")
	assert_eq(c.location_name({"f1": true, "f2": true}, "p"), "C")
	assert_eq(c.location_name({"f2": true}, "p"), "C")


func test_the_hud_shows_the_name_of_the_day() -> void:
	var hud: Hud = add_child_autofree(load("res://ui/hud.tscn").instantiate())
	var gs := GameState.new_game(1, _db)
	gs.player.place("inn_hill", Vector2i(16, 13))
	gs.flags.erase(NAMED)
	hud.refresh(gs, _db)
	var text: String = hud.get_node("%Status").text
	assert_string_contains(text, "The abandoned inn on the hill")
	gs.flags[NAMED] = true
	hud.refresh(gs, _db)
	assert_string_contains(hud.get_node("%Status").text, "The Wandering Inn")


func _ids(area: String) -> Array:
	return _db.maps.objects_on(area).map(func(o: Dictionary) -> String: return o["id"])


func test_signs_wait_for_their_flags() -> void:
	_db.maps.sync_flags({})
	assert_false(_ids("inn_hill").has("inn_name_sign"), "no name sign before 1.18")
	assert_false(_ids("inn_hill").has("inn_goblin_board"), "no board before 1.18")
	_db.maps.sync_flags({NAMED: true, BOARD: true})
	assert_true(_ids("inn_hill").has("inn_name_sign"))
	assert_true(_ids("inn_hill").has("inn_goblin_board"))


func test_the_naming_event_sets_both_flags() -> void:
	var flags: Array = _db.canon.events["b1.erin_names_the_inn"]["effects"]["set_flags"]
	assert_has(flags, NAMED)
	assert_has(flags, BOARD)
	assert_has(_db.canon.events["b1.inn_first_regulars"]["effects"]["set_flags"], "wandering_inn.has_regulars")
