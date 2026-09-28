extends GutTest
## M13.T (ADR 0020): map traps. A step springs an armed trap (seeded damage);
## a found, armed trap blocks; search and disarm are actions; a pit drops
## the player to another map; traps are saved (v14).
##   vault (9×5, exit west at 0,2 to town):
##     rune 3,2 (always armed, spot 1, disarm 1, 2–4 damage)
##     book 5,1 (once, spot 0, disarm 0, 3 damage)
##     spikes 5,3 (rearms after 30 min, 1 damage)
##     pit 7,2 (drops to the shop, 1 damage)
##     gated 2,3 (only with FLAG, once, 1 damage)

const FLAG := "vault.armed"


func _areas() -> Dictionary:
	var a := ToyMaps.areas()
	a["vault"] = ToyMaps.area("vault", "toy_shop", [
		"wwwwwwwww",
		"wgggggggw",
		"ggggggggw",
		"wgggggggw",
		"wwwwwwwww",
	], {}, [{"at": [0, 2], "to": "town", "arrive": [5, 2], "minutes": 0}], [
		{"id": "chest", "at": [1, 1], "name": "Chest", "actions": []},
	])
	a["vault"]["traps"] = [
		_trap("rune", [3, 2], [2, 4], 1.0, 1.0, false),
		_trap("book", [5, 1], [3, 3], 0.0, 0.0, true),
		_trap("spikes", [5, 3], [1, 1], 0.0, 0.0, false, {"rearm_minutes": 30}),
		_trap("pit", [7, 2], [1, 1], 0.0, 0.0, false, {"drop_to": {"to": "shop", "pos": [1, 1]}}),
		_trap("gated", [2, 3], [1, 1], 1.0, 0.0, true, {"when_flags": [FLAG]}),
	]
	return a


func _trap(id: String, at: Array, damage: Array, spot: float, disarm: float, once: bool,
		extra: Dictionary = {}) -> Dictionary:
	var t := {"id": id, "at": at, "name": id.capitalize(), "damage": damage, "hidden": true,
		"spot": spot, "disarm": disarm, "once": once}
	t.merge(extra)
	return t


func _db(areas: Dictionary = _areas()) -> DataDb:
	var d := ToyMaps.db()
	for tag: String in ["vigilance", "vigilance.traps", "crafting", "crafting.traps"]:
		d.tags[tag] = ""
	d.actions["search_for_traps"] = {"name": "Search", "minutes": 10, "base_xp": 5, "risk": 0.2,
		"tags": {"vigilance.traps": 1.0}}
	d.actions["disarm_trap"] = {"name": "Disarm", "minutes": 15, "base_xp": 8, "risk": 0.5,
		"tags": {"crafting.traps": 1.0}}
	var r: Dictionary = (d.rules["traps"] as Dictionary).duplicate()
	r["search_radius"] = 2
	r["spot_per_point"] = 0.0
	r["disarm_per_point"] = 0.0
	d.rules["traps"] = r
	d.rules["combat"]["knockout"]["wake"] = {"vault": {"area": "shop", "pos": [1, 1]}}
	d.maps = MapDb.from_dicts(ToyMaps.tiles(), areas)
	d.maps.validate(d)
	return d


func _game(d: DataDb, at: Vector2i, seed_value: int = 1) -> GameState:
	var gs := ToyMaps.new_game(d, seed_value)
	gs.player.place("vault", at)
	Commands.settle(gs, d)
	return gs


func _hp(gs: GameState, d: DataDb) -> int:
	return Combat.hp(gs, d)


func _errors_with(change: Callable) -> String:
	var a := _areas()
	change.call(a)
	return "\n".join(_db(a).maps.errors)


func test_the_data_is_valid() -> void:
	assert_eq(_db().maps.errors, [] as Array[String])
	assert_eq(DataDb.load_dir().errors, [] as Array[String], "the real data")


func test_a_step_springs_a_hidden_trap() -> void:
	var d := _db()
	var gs := _game(d, Vector2i(2, 2))
	var full := _hp(gs, d)
	var r := Commands.move(gs, d, "e")
	assert_true(r["moved"])
	assert_eq(r["sprung"]["id"], "rune")
	var dmg := int(r["sprung"]["damage"])
	assert_between(dmg, 2, 4)
	assert_eq(_hp(gs, d), full - dmg)
	assert_true(Traps.state(gs, "vault", Traps.trap_of(gs, d, "vault", "rune"))["found"])
	assert_true(gs.combat.lines.has("Trap! Rune."), "the rules' sprung line")


func test_the_same_seed_gives_the_same_damage() -> void:
	var d := _db()
	var hps: Array[int] = []
	for i in 2:
		var gs := _game(d, Vector2i(2, 2), 7)
		Commands.move(gs, d, "e")
		hps.append(_hp(gs, d))
	assert_eq(hps[0], hps[1])


func test_a_found_armed_trap_blocks() -> void:
	var d := _db()
	var gs := _game(d, Vector2i(2, 2))
	Commands.move(gs, d, "e")
	Commands.move(gs, d, "w")
	var hp := _hp(gs, d)
	var r := Commands.move(gs, d, "e")
	assert_false(r["moved"])
	assert_true(r["blocked"])
	assert_eq(r["trap"], "rune")
	assert_eq(_hp(gs, d), hp, "no second hit")
	assert_eq(gs.player.pos(), Vector2i(2, 2))


func test_a_once_trap_is_spent() -> void:
	var d := _db()
	var gs := _game(d, Vector2i(4, 1))
	assert_eq(Commands.move(gs, d, "e")["sprung"]["damage"], 3)
	Commands.move(gs, d, "w")
	var r := Commands.move(gs, d, "e")
	assert_true(r["moved"], "a spent trap does not block")
	assert_eq(r["sprung"], {})


func test_a_trap_rearms_after_its_minutes() -> void:
	var d := _db()
	var gs := _game(d, Vector2i(4, 3))
	var t := Traps.trap_of(gs, d, "vault", "spikes")
	Commands.move(gs, d, "e")
	assert_false(Traps.is_armed(gs, "vault", t))
	Commands.move(gs, d, "w")
	assert_eq(Commands.move(gs, d, "e")["sprung"], {}, "still spent")
	Commands.move(gs, d, "w")
	Commands.wait(gs, d, 30 * 60)
	assert_true(Traps.is_armed(gs, "vault", t))
	assert_true(Commands.move(gs, d, "e")["blocked"], "armed again, and found")


func test_search_finds_traps_near_you() -> void:
	var d := _db()
	var gs := _game(d, Vector2i(2, 1))
	var ids: Array = Interact.options(gs, d).map(func(o: Dictionary) -> String: return o["id"])
	assert_true(ids.has(Traps.SEARCH))
	var r := Commands.interact(gs, d, Traps.SEARCH, "search_for_traps")
	assert_eq(r["error"], "")
	assert_eq(r["record"]["action_id"], "search_for_traps")
	assert_eq(r["record"]["context"]["location"], "toy_shop")
	var rune := Traps.trap_of(gs, d, "vault", "rune")
	assert_true(Traps.state(gs, "vault", rune)["found"], "spot 1.0, 1 tile away")
	assert_false(Traps.state(gs, "vault", Traps.trap_of(gs, d, "vault", "book"))["found"], "spot 0")
	assert_false(Traps.state(gs, "vault", Traps.trap_of(gs, d, "vault", "pit"))["found"], "too far")
	assert_true(gs.combat.lines.has("You spot a trap: Rune."))


func test_no_search_where_there_are_no_traps() -> void:
	var d := _db()
	var gs := ToyMaps.new_game(d)
	assert_false(Interact.options(gs, d).any(func(o: Dictionary) -> bool: return o["id"] == Traps.SEARCH))


func test_disarm_a_found_trap() -> void:
	var d := _db()
	var gs := _game(d, Vector2i(2, 2))
	assert_false(Interact.options(gs, d).any(func(o: Dictionary) -> bool: return o["id"] == "trap:rune"),
			"not found yet")
	Commands.interact(gs, d, Traps.SEARCH, "search_for_traps")
	var r := Commands.interact(gs, d, "trap:rune", "disarm_trap")
	assert_eq(r["error"], "")
	assert_eq(r["record"]["outcome"], "success")
	assert_eq(r["record"]["context"]["trap"], "rune")
	var rune := Traps.trap_of(gs, d, "vault", "rune")
	assert_true(Traps.state(gs, "vault", rune)["disarmed"])
	var hp := _hp(gs, d)
	var m := Commands.move(gs, d, "e")
	assert_true(m["moved"])
	assert_eq(m["sprung"], {})
	assert_eq(_hp(gs, d), hp)


func test_a_failed_disarm_springs_the_trap() -> void:
	var d := _db()
	var gs := _game(d, Vector2i(4, 1))
	gs.combat.traps[Traps.key("vault", "book")] = {"found": true}
	var hp := _hp(gs, d)
	var r := Commands.interact(gs, d, "trap:book", "disarm_trap")
	assert_eq(r["error"], "")
	assert_eq(r["record"]["outcome"], "fail")
	assert_eq(_hp(gs, d), hp - 3)
	var book := Traps.trap_of(gs, d, "vault", "book")
	assert_false(Traps.state(gs, "vault", book)["disarmed"])
	assert_false(Traps.is_armed(gs, "vault", book), "a once trap is spent")


func test_a_pit_drops_you_to_another_map() -> void:
	var d := _db()
	var gs := _game(d, Vector2i(6, 2))
	var r := Commands.move(gs, d, "e")
	assert_eq(r["sprung"]["drop_to"], "shop")
	assert_eq(gs.player.area, "shop")
	assert_eq(gs.player.pos(), Vector2i(1, 1))


func test_a_flag_gated_trap_is_off_until_its_flag() -> void:
	var d := _db()
	var gs := _game(d, Vector2i(2, 2))
	assert_eq(Commands.move(gs, d, "s")["sprung"], {}, "off")
	Commands.move(gs, d, "n")
	gs.flags[FLAG] = true
	assert_eq(Commands.move(gs, d, "s")["sprung"]["id"], "gated")


func test_a_trap_can_knock_you_out() -> void:
	var d := _db()
	var gs := _game(d, Vector2i(4, 1))
	Combat.set_hp(gs, d, 2)
	Commands.move(gs, d, "e")
	assert_true(Combat.is_down(gs))
	Commands.knock_out(gs, d)
	assert_eq(gs.player.area, "shop", "woke at the map's wake spot")


func test_traps_are_saved() -> void:
	var d := _db()
	var gs := _game(d, Vector2i(4, 3))
	Commands.move(gs, d, "e")
	var copy := GameState.from_json(gs.to_json())
	assert_eq(copy.combat.traps, gs.combat.traps)
	var t := Traps.trap_of(copy, d, "vault", "spikes")
	assert_true(Traps.state(copy, "vault", t)["spent"])
	assert_eq(Traps.state(copy, "vault", t)["sprung"], gs.clock.total_minutes)


func test_a_v13_save_loads_with_no_trap_state() -> void:
	var d := _db()
	var data := _game(d, Vector2i(2, 2)).to_dict()
	(data["combat"] as Dictionary).erase("traps")
	data["save_version"] = 13
	var gs := GameState.from_dict(SaveMigrations.migrate(data))
	assert_eq(gs.save_version, GameState.SAVE_VERSION)
	assert_eq(gs.combat.traps, {})


func test_the_view_draws_found_traps_only() -> void:
	var d := _db()
	var gs := _game(d, Vector2i(2, 2))
	var v: WorldView = preload("res://world/world_view.tscn").instantiate()
	add_child_autofree(v)
	v.setup(d.maps)
	v.refresh(gs)
	assert_eq(v.traps.get_child_count(), 0, "all hidden")
	Commands.move(gs, d, "e")
	v.refresh(gs)
	assert_eq(v.traps.get_child_count(), 1)
	var marker := v.traps.get_child(0)
	assert_eq(String(marker.name), "rune")
	assert_eq((marker.get_child(1) as ColorRect).color, WorldView.TRAP_ARMED)


func test_bad_traps_are_reported() -> void:
	assert_string_contains(_errors_with(func(a: Dictionary) -> void:
		a["vault"]["traps"][0]["damage"] = [5, 2]), "damage must be")
	assert_string_contains(_errors_with(func(a: Dictionary) -> void:
		a["vault"]["traps"][0]["spot"] = 1.5), "spot must be 0..1")
	assert_string_contains(_errors_with(func(a: Dictionary) -> void:
		a["vault"]["traps"][1]["id"] = "rune"), "duplicate id")
	assert_string_contains(_errors_with(func(a: Dictionary) -> void:
		a["vault"]["traps"][0]["at"] = [0, 2]), "not an exit")
	assert_string_contains(_errors_with(func(a: Dictionary) -> void:
		a["vault"]["traps"][0]["at"] = [0, 0]), "not an exit")
	assert_string_contains(_errors_with(func(a: Dictionary) -> void:
		a["vault"]["traps"][0]["at"] = [1, 1]), "is on the object 'chest'")
	assert_string_contains(_errors_with(func(a: Dictionary) -> void:
		a["vault"]["traps"][1]["rearm_minutes"] = 10), "rearm_minutes")
	assert_string_contains(_errors_with(func(a: Dictionary) -> void:
		a["vault"]["traps"][3]["drop_to"] = {"to": "nowhere", "pos": [1, 1]}), "drop_to must be")
	assert_string_contains(_errors_with(func(a: Dictionary) -> void:
		(a["vault"]["traps"][0] as Dictionary).erase("once")), "missing 'once'")
	assert_string_contains(_errors_with(func(a: Dictionary) -> void:
		a["town"]["exits"].append({"at": [1, 3], "to": "vault", "arrive": [3, 2], "minutes": 0})),
		"arrive tile of an exit from 'town'")
	var d := _db()
	d.rules.erase("traps")
	d.maps = MapDb.from_dicts(ToyMaps.tiles(), _areas())
	d.maps.validate(d)
	assert_string_contains("\n".join(d.maps.errors), "a trap needs rules.traps")
