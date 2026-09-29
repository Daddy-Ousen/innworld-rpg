extends GutTest
## Attacking NPCs (M14.5, ADR 0021): the fate warning for a major NPC, blows and kills, what
## witnesses and towns think, guards and hostile NPCs, the danger they are, the fate page and its
## dialog, and the v17 save. Real data.

const SEED := 20260930
const MARKET := "liscor_market"
const PLAYER_AT := Vector2i(5, 5)

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])


func _game() -> GameState:
	var gs := GameState.new_game(SEED, _db)
	gs.player.place(MARKET, PLAYER_AT)
	return gs


func _put(gs: GameState, id: String, x: int, y: int) -> void:
	gs.npcs.npcs[id]["area"] = MARKET
	gs.npcs.npcs[id]["x"] = x
	gs.npcs.npcs[id]["y"] = y


## An NPC with no pending canon event that needs them and no guard tag.
func _minor(gs: GameState) -> String:
	var ids: Array = gs.npcs.npcs.keys()
	ids.sort()
	for id: String in ids:
		if not Brawl.is_major(gs, _db, id) and not NpcReact.has_fight_tag(_db, id):
			return id
	return ""


## Steps from roster entry `n` to the player, ignoring walls.
func _walk_distance(n: Dictionary) -> int:
	var d := NpcRoster.pos_of(n) - PLAYER_AT
	return absi(d.x) + absi(d.y)


## Attacks `id` until it dies (at most `most` blows). Returns the last result.
func _kill(gs: GameState, id: String, most: int = 300) -> Dictionary:
	var r := {}
	for i in most:
		r = Brawl.attack(gs, _db, id, true)
		if r["killed"] or r["error"] != "":
			break
	return r


func test_the_rules_are_valid_and_a_toy_db_has_none() -> void:
	assert_true(Brawl.on(_db))
	assert_eq(Brawl.validate(_db), [] as Array[String])
	var toy := DataDb.from_dicts({}, {}, {}, {}, {})
	assert_false(Brawl.on(toy))
	assert_eq(Brawl.validate(toy), [] as Array[String])
	assert_false(Brawl.hostile_near(GameState.new()))


func test_a_major_npc_is_one_a_pending_event_needs() -> void:
	var gs := _game()
	assert_true(Brawl.is_major(gs, _db, "erin_solstice"))
	assert_false(Brawl.is_major(gs, _db, "nobody"))
	assert_ne(_minor(gs), "", "the real roster has a minor NPC")


func test_the_first_attack_on_a_major_npc_warns_and_nothing_happens() -> void:
	var gs := _game()
	_put(gs, "erin_solstice", 6, 5)
	var minutes := gs.clock.total_minutes
	var sub := gs.player.sub_seconds
	var r := Brawl.attack(gs, _db, "erin_solstice")
	assert_true(r["warn"])
	assert_eq(r["error"], "")
	assert_eq(gs.clock.total_minutes, minutes)
	assert_eq(gs.player.sub_seconds, sub, "the warning takes no time")
	assert_false(gs.flags.has("fate_warned.erin_solstice"))
	assert_eq(int(gs.npcs.npcs["erin_solstice"]["hostile_day"]), 0)
	assert_false(Brawl.hostile_near(gs))


func test_a_confirmed_attack_goes_ahead_and_the_warning_comes_once() -> void:
	var gs := _game()
	_put(gs, "erin_solstice", 6, 5)
	var r := Brawl.attack(gs, _db, "erin_solstice", true)
	assert_false(r["warn"])
	assert_eq(r["error"], "")
	assert_true(gs.flags.has("fate_warned.erin_solstice"))
	assert_true(Brawl.hostile_near(gs))
	assert_false(Brawl.attack(gs, _db, "erin_solstice")["warn"], "not warned twice")
	var back := GameState.from_json(gs.to_json())
	assert_true(back.flags.has("fate_warned.erin_solstice"), "the warning is saved")


func test_a_minor_npc_needs_no_warning() -> void:
	var gs := _game()
	var id := _minor(gs)
	_put(gs, id, 6, 5)
	assert_false(Brawl.needs_warning(gs, _db, id))
	var r := Brawl.attack(gs, _db, id)
	assert_false(r["warn"])
	assert_false(gs.flags.has("fate_warned." + id))
	assert_true(gs.player.sub_seconds != 0 or gs.clock.total_minutes > 0, "a blow takes a turn")
	assert_eq(gs.player.facing, "e")


func test_a_blow_hurts_and_enough_of_them_kill() -> void:
	var gs := _game()
	var id := _minor(gs)
	_put(gs, id, 6, 5)
	var full := Combat.npc_hp(gs, _db, id)
	var hurt := false
	for i in 100:
		var r := Brawl.attack(gs, _db, id, true)
		if r["hit"]:
			assert_gt(int(r["damage"]), 0)
			if not r["killed"]:
				assert_lt(Combat.npc_hp(gs, _db, id), full)
			hurt = true
			break
	assert_true(hurt, "a blow lands within 100 tries")
	var last := _kill(gs, id)
	assert_true(last["killed"], "the NPC dies")
	assert_false(gs.world.is_alive(_db.canon, id))
	assert_true(gs.combat.lines.any(func(l: String) -> bool: return l.ends_with(" dies.")), str(gs.combat.lines))
	var kills: Array = gs.world.history.filter(func(h: Dictionary) -> bool: return h["event"] == "player.kill")
	assert_eq(kills.size(), 1)
	assert_eq(kills[0]["roles"]["victim"], id)


func test_a_dead_npc_leaves_the_roster_on_the_next_command() -> void:
	var gs := _game()
	var id := _minor(gs)
	_put(gs, id, 6, 5)
	for i in 300:
		Combat.set_hp(gs, _db, 9999)  # the NPC hits back; keep the player up
		if Commands.attack_npc(gs, _db, id, true)["killed"]:
			break
	assert_false(gs.npcs.npcs.has(id))


func test_the_first_blow_costs_standing_once_and_a_kill_costs_more() -> void:
	var gs := _game()
	var id := _minor(gs)
	var witness := "krshia"
	_put(gs, id, 6, 5)
	_put(gs, witness, 8, 6)
	var faction: Variant = _db.canon.npcs[id].get("faction", null)
	var r := Brawl.attack(gs, _db, id, true)
	assert_false(r["killed"])
	assert_eq(gs.world.relationship(id, NpcSim.PLAYER), -5)
	assert_eq(gs.world.relationship(witness, NpcSim.PLAYER), -2)
	assert_eq(Standing.reputation(gs, "liscor"), -3)
	if faction != null and String(faction) != "liscor":
		assert_eq(Standing.reputation(gs, String(faction)), -3)
	Brawl.attack(gs, _db, id, true)
	assert_eq(gs.world.relationship(id, NpcSim.PLAYER), -5, "a second blow the same day costs nothing")
	assert_eq(gs.world.relationship(witness, NpcSim.PLAYER), -2)
	assert_true(_kill(gs, id)["killed"])
	assert_eq(gs.world.relationship(witness, NpcSim.PLAYER), -7)
	assert_eq(Standing.reputation(gs, "liscor"), -8)


func test_only_the_area_sees_it() -> void:
	var gs := _game()
	var id := _minor(gs)
	_put(gs, id, 6, 5)
	gs.npcs.npcs["krshia"]["area"] = "liscor_gate"
	Brawl.attack(gs, _db, id, true)
	assert_eq(gs.world.relationship("krshia", NpcSim.PLAYER), 0)


func test_a_guard_who_sees_it_turns_hostile_and_it_is_danger() -> void:
	var gs := _game()
	var id := _minor(gs)
	_put(gs, id, 6, 5)
	_put(gs, "tkrn", 12, 8)
	Brawl.attack(gs, _db, id, true)
	assert_eq(int(gs.npcs.npcs["tkrn"]["hostile_day"]), gs.clock.day())
	assert_true(Brawl.is_hostile(gs, gs.npcs.npcs["tkrn"]))
	assert_true(Combat.in_danger(gs))
	assert_eq(Combat.refusal(gs), Combat.REFUSED_DANGER)
	var night := Commands.sleep(gs, _db, Rest.ANYWHERE)
	assert_true(night.is_empty(), "no sleeping with a hostile NPC near")
	assert_eq(gs.combat.lines, [Combat.REFUSED_DANGER] as Array[String])


func test_a_hostile_npc_walks_up_and_hits_the_player() -> void:
	var gs := _game()
	var id := _minor(gs)
	_put(gs, id, 12, 8)
	gs.npcs.npcs[id]["hostile_day"] = gs.clock.day()
	var n: Dictionary = gs.npcs.npcs[id]
	var start := _walk_distance(n)
	assert_true(Brawl.act(gs, _db, id, n, 6))
	assert_lt(_walk_distance(n), start, "one turn, one step closer")
	for i in 12:
		Brawl.act(gs, _db, id, n, 6)
	assert_eq(Brawl._dist(NpcRoster.pos_of(n), PLAYER_AT), 1, "next to the player")
	Combat.set_hp(gs, _db, 9999)
	var hp := Combat.hp(gs, _db)
	for i in 40:
		Brawl.act(gs, _db, id, n, 6)
	assert_lt(Combat.hp(gs, _db), hp, "and it hits")
	assert_true(gs.combat.lines.any(func(l: String) -> bool: return l.contains("hits you")), str(gs.combat.lines))


func test_a_calm_or_fallen_npc_does_not_act() -> void:
	var gs := _game()
	var id := _minor(gs)
	_put(gs, id, 6, 5)
	var n: Dictionary = gs.npcs.npcs[id]
	assert_false(Brawl.act(gs, _db, id, n, 6), "not hostile")
	n["hostile_day"] = gs.clock.day()
	n["down"] = true
	assert_false(Brawl.act(gs, _db, id, n, 6), "down")
	assert_false(Brawl.hostile_near(gs))


func test_hostility_ends_with_the_day() -> void:
	var gs := _game()
	var id := _minor(gs)
	_put(gs, id, 6, 5)
	Brawl.attack(gs, _db, id, true)
	assert_true(Brawl.hostile_near(gs))
	gs.clock.total_minutes += 24 * 60
	assert_false(Brawl.hostile_near(gs))


func test_a_command_runs_the_npcs_answer() -> void:
	var gs := _game()
	var id := _minor(gs)
	_put(gs, id, 6, 5)
	var r := Commands.attack_npc(gs, _db, id, true)
	assert_eq(r["error"], "")
	assert_true(Brawl.is_hostile(gs, gs.npcs.npcs[id]) or r["killed"])
	assert_gt(gs.combat.lines.size(), 0)


func test_errors() -> void:
	var gs := _game()
	assert_string_contains(Brawl.attack(gs, _db, "erin_solstice", true)["error"], "no 'erin_solstice' here")
	var id := _minor(gs)
	_put(gs, id, 20, 9)
	assert_ne(Brawl.attack(gs, _db, id, true)["error"], "", "too far")
	_put(gs, id, 6, 5)
	Combat.set_hp(gs, _db, 0)
	assert_eq(Brawl.attack(gs, _db, id, true)["error"], Combat.REFUSED_DOWN)


func test_the_use_menu_has_an_attack_row_for_npcs_only() -> void:
	var gs := _game()
	var id := _minor(gs)
	_put(gs, id, 6, 5)
	var seen := false
	for o: Dictionary in Interact.options(gs, _db):
		if o["id"] == id:
			assert_true(o["attack"])
			seen = true
		else:
			assert_false(o.get("attack", false))
	assert_true(seen)
	var menu: InteractMenu = add_child_autofree(load("res://ui/interact_menu.tscn").instantiate())
	assert_true(menu.open(Interact.options(gs, _db), _db))
	var items: ItemList = menu.get_node("%Items")
	var last := items.item_count - 1
	assert_eq(items.get_item_metadata(last)[1], Interact.ATTACK, "the Attack row is last")
	assert_string_contains(items.get_item_text(last), "Attack")


func test_the_fate_page_and_dialog() -> void:
	var page := SystemMessages.fate_page(_db, "erin_solstice")
	assert_eq(page["kind"], SystemMessages.FATE)
	assert_eq(page["npc"], "erin_solstice")
	assert_eq(page["choices"], [SystemMessages.STRIKE, SystemMessages.SPARE] as Array[String])
	assert_string_contains(page["lines"][0], "Erin Solstice")
	assert_gt(float(page["delay"]), 0.0)
	var gs := _game()
	var d: SystemDialog = add_child_autofree(load("res://ui/system_dialog.tscn").instantiate())
	watch_signals(d)
	d.open([page] as Array[Dictionary], gs, _db)
	assert_true(d.visible)
	d.choose(SystemMessages.SPARE)
	assert_false(d.visible)
	assert_signal_not_emitted(d, "struck")
	assert_signal_not_emitted(d, "closed")
	d.open([page] as Array[Dictionary], gs, _db)
	d.choose(SystemMessages.STRIKE)
	assert_false(d.visible)
	assert_signal_emitted_with_parameters(d, "struck", ["erin_solstice"])
	assert_signal_not_emitted(d, "closed")


func test_v17_save_round_trip_and_a_v16_save_loads() -> void:
	var gs := _game()
	var id := _minor(gs)
	gs.npcs.npcs[id]["hostile_day"] = 3
	var back := GameState.from_json(gs.to_json())
	assert_eq(int(back.npcs.npcs[id]["hostile_day"]), 3)
	var data := gs.to_dict()
	for n: Dictionary in (data["npcs"]["npcs"] as Dictionary).values():
		n.erase("hostile_day")
	data["save_version"] = 16
	var old := GameState.from_dict(SaveMigrations.migrate(data))
	assert_eq(old.save_version, GameState.SAVE_VERSION)
	assert_eq(int(old.npcs.npcs[id]["hostile_day"]), 0)
	assert_false(Brawl.hostile_near(old))


func test_the_game_screen_shows_the_fate_page_and_strikes_on_confirm() -> void:
	var session := get_node("/root/Session")
	var gs := _game()
	_put(gs, "erin_solstice", 6, 5)
	session.set_state(gs)
	var main: Node = add_child_autofree(load("res://world/main.tscn").instantiate())
	main.switch_scene = false
	main.menu.chosen.emit("erin_solstice", Interact.ATTACK)
	assert_true(main.dialog.visible, "a major NPC: the fate page")
	assert_eq(main.dialog.current["kind"], SystemMessages.FATE)
	assert_false(session.gs.flags.has("fate_warned.erin_solstice"))
	main.dialog.choose(SystemMessages.STRIKE)
	assert_false(main.dialog.visible)
	assert_true(session.gs.flags.has("fate_warned.erin_solstice"), "the attack went ahead")
	var id := _minor(session.gs)
	_put(session.gs, id, 4, 5)
	main.menu.chosen.emit(id, Interact.ATTACK)
	assert_false(main.dialog.visible, "a minor NPC: no page")
	assert_eq(int(session.gs.npcs.npcs[id]["hostile_day"]), session.gs.clock.day())
