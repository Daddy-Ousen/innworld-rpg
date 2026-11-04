extends GutTest
## M36.10 (ADR 0047): kill sims for Book 9. The 13 named dead die by their own canon events. A key NPC dies at the
## start of day 175 (the eve of the battle of Liscor) and the game sleeps through day 177: nothing crashes, every
## Book 9 event to day 176 resolves, and the dead stay dead. Garen, Reiss (the Goblin Lord) and Pyrite have events
## that need them alive: those events are cancelled and the rest of the battle goes on. The game is slept once
## (before_all); each test starts from a copy.
## Known gap (not tested, see handoff.md): the 5.60 - 5.62 events about Erin, Rags, Numbtongue, Tyrion and Redscar
## have optional roles and no requires.alive, so their deaths change nothing yet.

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
	assert_true(_happened(gs, LANCE_REISS), "Tyrion still lances Reiss")
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


func test_a_key_npc_dies_and_the_book_still_runs_to_the_end_of_the_battle() -> void:
	# Erin, Rags, Numbtongue, Tyrion, Redscar and the Drakes at the gate: no crash, everything resolves, the dead stay dead.
	for npc: String in ["erin_solstice", "rags", "numbtongue", "tyrion_veltras", "redscar", "relc", "zevara", "ilvriss"]:
		var gs := _run([npc])
		_all_resolved(gs)
		assert_false(gs.world.is_alive(_db.canon, npc), npc + " stays dead")
		assert_true(_happened(gs, GATE), npc + ": the gate event is resolved")
		for n: String in ["twofeather", "quietstab", "tremborag"]:
			assert_false(gs.world.is_alive(_db.canon, n), n + " (dead before day 175) stays dead")
