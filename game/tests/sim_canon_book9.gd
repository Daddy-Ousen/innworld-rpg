extends GutTest
## Real Book 9 canon (game/data/canon/book9). With no player input, every
## b9. event in days FIRST_DAY-LAST_DAY happens as written: no drift. The
## game is slept to day FIRST_DAY - 1 once (before_all); each test starts
## from a copy of that save. M36: Book 9 is complete.

## First day with Book 9 canon (5.45: the morning after the Raskghar battle).
const FIRST_DAY := 164
## Last day with Book 9 canon (Interlude - Thereafter: Ryoka at Reizmelt).
const LAST_DAY := 180
## Fight stages (xp_window) and scene stages (talk hooks), in the order the canon files load.
const FIGHTS: Array[String] = [
	"b9.numbtongue_ambushes_the_door_thieves",
	"b9.the_halfseekers_charge_the_redfangs",
	"b9.the_trebuchets_fire_on_the_east_gate",
	"b9.the_east_gate_breaks_and_the_drakes_sortie",
]
const SCENES: Array[String] = [
	"b9.ilvriss_leads_the_victory_parade_in_the_rain",
	"b9.the_meadow_baseball_championship",
	"b9.the_hobs_share_out_the_raskghar_hoard",
	"b9.bevussa_tells_bird_about_birds",
	"b9.erin_is_still_in_her_cell",
	"b9.mrsha_throws_everdawns_radiance",
]
const KILLS := {
	"b9.gilam_kills_twofeather_at_a_creek": "twofeather",
	"b9.tremborag_kills_quietstab_at_the_latrines": "quietstab",
	"b9.tyrion_lances_tremborag": "tremborag",
	"b9.azkerash_kills_headscratcher": "headscratcher",
	"b9.yellow_splatters_dies_shielding_pawn": "yellow_splatters",
	"b9.spiderslicer_dies_shielding_garen": "spiderslicer",
	"b9.shorthilt_dies_fighting_the_riders": "shorthilt",
	"b9.relc_kills_garen_at_the_east_gate": "garen",
	"b9.tyrion_lances_reiss": "goblin_lord",
	"b9.eater_of_spears_falls_to_human_riders": "eater_of_spears",
	"b9.noears_destroys_the_inns_third_floor": "noears",
	"b9.pyrite_holds_the_slope_against_tyrion": "pyrite",
	"b9.redscar_kills_sir_vumat": "sir_vumat",
}
## Alive at the end of Book 9: no kill effect for them (plan conflicts 3 - 5; Calruz has no verdict).
const SURVIVORS := ["numbtongue", "purple_smile", "osthia_blackwing", "calruz", "rags", "redscar", "erin_solstice",
		"mrsha", "ceria_springwalker", "tyrion_veltras", "ilvriss", "relc", "klbkch", "zevara"]
## Book 8 dead stay dead through Book 9.
const BOOK8_DEAD := ["fess", "rebat", "cassa", "vakk"]

var _db: DataDb
var _base_json := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	var gs := GameState.new_game(1, _db)
	ToyCanon.sleep_through(gs, _db, FIRST_DAY - 1)
	_base_json = gs.to_json()


func _fresh() -> GameState:
	return GameState.from_json(_base_json)


static func _b9(id: String) -> bool:
	return id.begins_with("b9.")


func _b9_events() -> Array[String]:
	var out: Array[String] = []
	for id: String in _db.canon.events:
		var ev: Dictionary = _db.canon.events[id]
		if _b9(id) and int(ev["window"]["earliest"]) <= LAST_DAY and not _db.canon.alt_only.has(id):
			out.append(id)
	return out


func _sleep_to_last_day(gs: GameState) -> void:
	while gs.world.last_day < LAST_DAY:
		Commands.sleep(gs, _db, Rest.ANYWHERE)


func test_book9_loads() -> void:
	assert_eq(_db.canon.errors, [] as Array[String])
	assert_eq(_db.errors, [] as Array[String])
	assert_eq(_b9_events().size(), 206)
	for loc: String in _db.canon.locations:
		assert_true(_db.canon.locations[loc] is Dictionary, loc)


func test_book9_runs_as_canon() -> void:
	var gs := _fresh()
	assert_eq(gs.clock.day(), FIRST_DAY)
	_sleep_to_last_day(gs)
	var expected := _b9_events()
	for id: String in expected:
		assert_eq(gs.world.status(id), Director.DONE, id)
	var history := gs.world.history.filter(func(h: Dictionary) -> bool: return _b9(h["event"]))
	assert_eq(history.size(), expected.size(), "one history entry per event")
	assert_eq(gs.world.drift, 0.0)


func test_book9_dead_are_the_thirteen_named() -> void:
	var killers := {}
	for id: String in _b9_events():
		for who: String in _db.canon.events[id].get("effects", {}).get("kill", []):
			killers[id] = who
	assert_eq(killers, KILLS)
	var gs := _fresh()
	_sleep_to_last_day(gs)
	for who: String in KILLS.values():
		assert_false(gs.world.is_alive(_db.canon, who), who + " is dead")


func test_survivors_live_and_book8_dead_stay_dead() -> void:
	var gs := _fresh()
	_sleep_to_last_day(gs)
	for who: String in SURVIVORS:
		assert_true(_db.canon.npcs.has(who), who + " has a record")
		assert_true(gs.world.is_alive(_db.canon, who), who + " lives")
	for who: String in BOOK8_DEAD:
		assert_false(gs.world.is_alive(_db.canon, who), who + " stays dead")
	# No Book 9 event kills a survivor, a Book 8 name or the Book 8 dead again.
	var killed: Array = KILLS.values()
	for who: String in SURVIVORS + BOOK8_DEAD:
		assert_false(killed.has(who), who)


func test_stages_are_ten_fights_and_scenes() -> void:
	var staged: Array[String] = []
	var windows: Array[String] = []
	var hooked: Array[String] = []
	for id: String in _b9_events():
		var ev: Dictionary = _db.canon.events[id]
		if ev.has("stage"):
			staged.append(id)
			for n: Dictionary in ev["stage"].get("npcs", []):
				assert_true(_db.behaviour.npcs.has(n["npc"]), id + ": " + String(n["npc"]))
		if ev.has("xp_window"):
			windows.append(id)
		if ev.has("hooks"):
			hooked.append(id)
	var expected_staged: Array[String] = []
	expected_staged.assign(FIGHTS + SCENES)
	staged.sort()
	expected_staged.sort()
	assert_eq(staged, expected_staged)
	windows.sort()
	var fights := FIGHTS.duplicate()
	fights.sort()
	assert_eq(windows, fights, "each fight gives an XP window, scenes give none")
	hooked.sort()
	var scenes := SCENES.duplicate()
	scenes.sort()
	assert_eq(hooked, scenes, "only the scene stages carry talk hooks")


func test_the_rains_the_boycott_and_the_door_follow_the_book() -> void:
	var gs := _fresh()
	_sleep_to_last_day(gs)
	# Rain and flood end by event (days 172, 174); the boycott ends when Drakes eat at the inn (169).
	for f: String in ["izril.rains_ended", "izril.floodplains_muddy"]:
		assert_true(gs.flags.has(f), f)
	for f: String in ["izril.rains", "izril.flood", "wandering_inn.drake_boycott"]:
		assert_false(gs.flags.has(f), f)
	# The magic door ends at city hall; the thief's flags are cleared again.
	assert_true(gs.flags.has("albez_door.at_liscor_city_hall"))
	for f: String in ["albez_door.at_wandering_inn", "albez_door.stolen", "albez_door.anchor_at_pallass"]:
		assert_false(gs.flags.has(f), f)
	assert_true(gs.flags.has("albez_door.pallass_stone_shattered"))


func test_the_ending_follows_the_book() -> void:
	var gs := _fresh()
	_sleep_to_last_day(gs)
	for f: String in ["battle_of_liscor.goblin_lord_slain", "reiss.died_at_erins_table", "erin.refused_the_general_class",
			"rags.great_chieftain_title", "numbtongue.speared_in_the_battle", "numbtongue.reported_dead_by_badarrow",
			"purple_smile.missing_after_the_battle", "osthia.alive_after_the_battle", "wandering_inn.third_floor_destroyed",
			"wandering_inn.closed_and_barred", "calruz.accepts_any_punishment", "ryoka.is_a_city_runner"]:
		assert_true(gs.flags.has(f), f)
	# Calruz has no verdict in Book 9: he is still held.
	assert_true(gs.flags.has("calruz.in_watch_prison"))
	# Erin leaves the cells on day 173 and keeps no [General] class.
	assert_true(gs.flags.has("erin.freed_from_the_cells"))


func test_chapter_order_runs_the_book_in_order() -> void:
	var gs := _fresh()
	_sleep_to_last_day(gs)
	var seq := gs.world.history.filter(func(h: Dictionary) -> bool: return _b9(h["event"])) \
			.map(func(h: Dictionary) -> String: return h["event"])
	var beats: Array[String] = [
		"b9.the_army_comes_home_through_the_doors",
		"b9.gilam_kills_twofeather_at_a_creek",
		"b9.tremborag_kills_quietstab_at_the_latrines",
		"b9.numbtongue_ambushes_the_door_thieves",
		"b9.the_halfseekers_charge_the_redfangs",
		"b9.the_trebuchets_fire_on_the_east_gate",
		"b9.the_east_gate_breaks_and_the_drakes_sortie",
		"b9.reiss_dies_at_a_table_in_the_inn",
		"b9.erin_refuses_the_general_class",
		"b9.rags_is_hailed_great_chieftain",
		"b9.ryoka_runs_a_package_to_reizmelt",
	]
	var last := -1
	for id: String in beats:
		var at := seq.find(id)
		assert_gt(at, last, id + " comes after the one before it")
		last = at
