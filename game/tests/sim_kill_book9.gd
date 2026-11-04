extends GutTest
## M36.10 (ADR 0047): kill sims for Book 9. The 13 named dead die by their own canon events. A key NPC dies at the
## start of day 175 (the eve of the battle of Liscor) and the game sleeps through day 177: nothing crashes, every
## Book 9 event to day 176 resolves, and the dead stay dead. Garen, Reiss (the Goblin Lord) and Pyrite have events
## that need them alive: those events are cancelled and the rest of the battle goes on. The game is slept once
## (before_all); each test starts from a copy.
## Events about one person list that person in requires.alive (follow-up to M36.10): a dead Erin does not walk out
## under a white flag, and the events that depend on it are cancelled too.

const KILL_DAY := 175
const LAST_DAY := 177
const NAMED_DEAD := ["twofeather", "quietstab", "tremborag", "headscratcher", "yellow_splatters", "spiderslicer",
		"shorthilt", "garen", "goblin_lord", "eater_of_spears", "noears", "pyrite", "sir_vumat"]
## Alive at the end of Book 9: canon never kills them (plan conflicts 3 - 5; Calruz has no verdict).
const NOT_KILLED := ["numbtongue", "purple_smile", "osthia_blackwing", "calruz", "rags", "redscar", "erin_solstice"]
const GATE := "b9.the_east_gate_breaks_and_the_drakes_sortie"
const RELC_KILLS_GAREN := "b9.relc_kills_garen_at_the_east_gate"
const LANCE_REISS := "b9.tyrion_lances_reiss"
const REISS_AT_TABLE := "b9.reiss_dies_at_a_table_in_the_inn"
const PYRITE_HOLDS := "b9.pyrite_holds_the_slope_against_tyrion"
const GREAT_CHIEFTAIN := "b9.rags_is_hailed_great_chieftain"

var _db: DataDb
var _base_json := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])
	var gs := GameState.new_game(1, _db)
	ToyCanon.sleep_through(gs, _db, KILL_DAY - 1)
	_base_json = gs.to_json()


## Kills `npcs` at the start of day 175, sleeps through day 177.
func _run(npcs: Array) -> GameState:
	var gs := GameState.from_json(_base_json)
	assert_eq(gs.clock.day(), KILL_DAY)
	for npc: String in npcs:
		assert_eq(Commands.kill_npc(gs, _db, npc), "", npc + " can be killed")
		assert_false(gs.world.is_alive(_db.canon, npc), npc + " is dead")
	while gs.world.last_day < LAST_DAY:
		Commands.sleep(gs, _db, Rest.ANYWHERE)
	return gs


## Book 9 canon events (not alt events) up to day 176 that did not happen.
func _lost(gs: GameState) -> Array[String]:
	var out: Array[String] = []
	for id: String in _db.canon.events:
		if id.begins_with("b9.") and not _db.canon.alt_only.has(id) \
				and int(_db.canon.events[id]["window"]["earliest"]) <= LAST_DAY - 1 \
				and not Director.happened(gs.world.status(id)):
			out.append(id)
	return out


func _all_resolved(gs: GameState) -> void:
	for id: String in _db.canon.events:
		if id.begins_with("b9.") and not _db.canon.alt_only.has(id) \
				and int(_db.canon.events[id]["window"]["latest"]) <= LAST_DAY - 1:
			assert_ne(gs.world.status(id), WorldState.PENDING, "%s is resolved" % id)


func _happened(gs: GameState, id: String) -> bool:
	return Director.happened(gs.world.status(id))


func test_each_named_dead_dies_by_one_book9_event() -> void:
	var by := {}
	for id: String in _db.canon.events:
		if not id.begins_with("b9.") or _db.canon.alt_only.has(id):
			continue
		for n: String in _db.canon.events[id]["effects"].get("kill", []):
			by[n] = int(by.get(n, 0)) + 1
	assert_eq(by.size(), NAMED_DEAD.size())
	for n: String in NAMED_DEAD:
		assert_true(_db.canon.npcs.has(n), n + " has a record")
		assert_eq(int(by.get(n, 0)), 1, n)
	for n: String in NOT_KILLED:
		assert_false(by.has(n), n + " is not killed by canon")


func test_no_kill_ends_the_battle_of_liscor_in_canon() -> void:
	var gs := _run([])
	assert_eq(_lost(gs), [] as Array[String])
	assert_eq(gs.world.drift, 0.0)
	_all_resolved(gs)
	for n: String in NAMED_DEAD:
		assert_false(gs.world.is_alive(_db.canon, n), n)
	for n: String in NOT_KILLED:
		assert_true(gs.world.is_alive(_db.canon, n), n)
	for f: String in ["battle_of_liscor.goblin_lord_slain", "rags.great_chieftain_title", "erin.refused_the_general_class"]:
		assert_true(gs.flags.has(f), f)


func test_garen_dies_early_and_relc_has_no_one_to_kill() -> void:
	var gs := _run(["garen"])
	_all_resolved(gs)
	assert_gt(gs.world.drift, 0.0)
	assert_false(_happened(gs, RELC_KILLS_GAREN), "Garen is already dead")
	assert_false(gs.flags.has("garen.killed_by_relc_at_the_gate"))
	assert_false(gs.world.is_alive(_db.canon, "garen"), "he stays dead")
	assert_true(_happened(gs, GATE), "the gate still breaks")
	assert_false(_happened(gs, "b9.garen_cuts_azkerash_and_reiss_wakes"), "he cannot cut Azkerash")
	assert_false(_happened(gs, LANCE_REISS), "the lance follows Garen's cut")
	assert_false(_happened(gs, "b9.halfseekers_burn_garens_body"), "no body to burn")


func test_reiss_dies_early_and_the_lance_and_the_table_do_not_happen() -> void:
	var gs := _run(["goblin_lord"])
	_all_resolved(gs)
	assert_gt(gs.world.drift, 0.0)
	assert_false(_happened(gs, LANCE_REISS), "Reiss is already dead")
	assert_false(_happened(gs, REISS_AT_TABLE))
	assert_false(gs.flags.has("battle_of_liscor.goblin_lord_slain"))
	assert_false(gs.world.is_alive(_db.canon, "goblin_lord"), "he stays dead")
	assert_true(_happened(gs, GATE), "the gate still breaks")
	assert_true(_happened(gs, RELC_KILLS_GAREN), "Garen still falls to Relc")


func test_pyrite_dies_early_and_rags_is_not_hailed() -> void:
	var gs := _run(["pyrite"])
	_all_resolved(gs)
	assert_gt(gs.world.drift, 0.0)
	assert_false(_happened(gs, PYRITE_HOLDS), "Pyrite is already dead")
	assert_false(_happened(gs, GREAT_CHIEFTAIN), "the survivors have no one to follow")
	assert_false(gs.flags.has("rags.great_chieftain_title"))
	assert_false(gs.world.is_alive(_db.canon, "pyrite"), "he stays dead")
	assert_true(_happened(gs, GATE))
	assert_true(_happened(gs, LANCE_REISS))


func test_erin_dies_and_there_is_no_white_flag_and_no_battle() -> void:
	var gs := _run(["erin_solstice"])
	_all_resolved(gs)
	assert_gt(gs.world.drift, 0.0)
	for id: String in ["b9.erin_sews_a_white_flag", "b9.erin_walks_out_under_a_white_flag",
			"b9.erin_leads_the_cave_goblins_into_reisss_host", GATE, RELC_KILLS_GAREN, LANCE_REISS]:
		assert_false(_happened(gs, id), id)
	assert_false(gs.flags.has("erin.walked_out_under_a_white_flag"))
	assert_false(gs.flags.has("erin.refused_the_general_class"))
	assert_false(gs.world.is_alive(_db.canon, "erin_solstice"), "she stays dead")
	# Nobody else is killed by the cancelled battle.
	for n: String in ["garen", "goblin_lord", "pyrite", "sir_vumat", "headscratcher", "noears"]:
		assert_true(gs.world.is_alive(_db.canon, n), n + " is spared")


func test_tyrion_dies_and_the_barrage_and_the_battle_do_not_happen() -> void:
	var gs := _run(["tyrion_veltras"])
	_all_resolved(gs)
	assert_gt(gs.world.drift, 0.0)
	for id: String in ["b9.tyrion_orders_the_barrage", "b9.the_trebuchets_fire_on_the_east_gate", GATE, LANCE_REISS]:
		assert_false(_happened(gs, id), id)
	assert_true(gs.world.is_alive(_db.canon, "goblin_lord"), "no lance, no death in the battle")


func test_rags_dies_and_the_flank_attack_is_gone_but_the_gate_still_breaks() -> void:
	var gs := _run(["rags"])
	_all_resolved(gs)
	assert_gt(gs.world.drift, 0.0)
	for id: String in ["b9.rags_walks_south_behind_the_human_army", "b9.rags_breaks_the_dungeon_wall_on_the_human_rear"]:
		assert_false(_happened(gs, id), id)
	assert_true(_happened(gs, GATE))
	assert_false(gs.world.is_alive(_db.canon, "rags"), "she stays dead")


func test_numbtongue_dies_and_is_not_speared_twice() -> void:
	var gs := _run(["numbtongue"])
	_all_resolved(gs)
	assert_gt(gs.world.drift, 0.0)
	assert_false(_happened(gs, "b9.numbtongue_is_speared_and_plays_a_last_chord"))
	assert_false(gs.flags.has("numbtongue.speared_in_the_battle"))
	assert_true(_happened(gs, GATE), "the battle goes on")
	assert_false(gs.world.is_alive(_db.canon, "numbtongue"), "he stays dead")


func test_redscar_dies_and_sir_vumat_lives() -> void:
	var gs := _run(["redscar"])
	_all_resolved(gs)
	assert_false(_happened(gs, "b9.redscar_kills_sir_vumat"))
	assert_true(gs.world.is_alive(_db.canon, "sir_vumat"), "no one is left to kill him")
	assert_true(_happened(gs, GATE))


func test_relc_dies_and_garen_is_not_killed_at_the_gate() -> void:
	var gs := _run(["relc"])
	_all_resolved(gs)
	assert_false(_happened(gs, RELC_KILLS_GAREN))
	assert_true(gs.world.is_alive(_db.canon, "garen"), "Relc cannot kill him")
	assert_true(_happened(gs, GATE))
	assert_true(_happened(gs, LANCE_REISS))


func test_noears_and_ilvriss_die_and_the_book_still_resolves() -> void:
	# Noears (the roof) and Ilvriss (the door, the war room): big chains are cancelled, nothing is left pending.
	var gs := _run(["noears"])
	_all_resolved(gs)
	assert_gt(gs.world.drift, 0.0)
	assert_false(_happened(gs, "b9.noears_calls_the_inns_mana_for_lightning"))
	assert_false(_happened(gs, "b9.noears_destroys_the_inns_third_floor"))
	assert_false(gs.world.is_alive(_db.canon, "noears"), "he stays dead")
	gs = _run(["ilvriss"])
	_all_resolved(gs)
	assert_gt(gs.world.drift, 0.0)
	assert_false(_happened(gs, "b9.ilvriss_moves_the_door_to_city_hall"))
	assert_false(gs.flags.has("albez_door.at_liscor_city_hall"))
	assert_false(gs.world.is_alive(_db.canon, "ilvriss"), "he stays dead")
