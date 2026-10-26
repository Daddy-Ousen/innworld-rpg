extends GutTest
## M23.6 (ADR 0036): a key Book 7 NPC dies on day 130 and the game sleeps
## through day 143. Threads that do not need the dead NPC go on; the dead
## NPC's own events cancel; alt events show in the history; drift stays in
## proportion. Key NPCs and events: docs/divergence/picks.md. The game is
## slept once (before_all); each test starts from a copy.

const FIRST_DAY := 130
const LAST_DAY := 143
## Book 7 canon events that did not happen (cancelled or mutated), and total
## drift (all books), at most. Before M23.6: Erin 38 / 38, Laken 26 / 13.5,
## Selys 18 / 15, Zevara 17 / 15, Rags 14 / 12.5, Magnolia 0 / 11.5, Kerrig 5 / 4.5.
## Erin and Selys lose more now: the Pallass door, the inn's moth fight and
## Selys's kidnapping no longer run without their cause (ADR 0036 "Book 7").
## M32.4: Magnolia 12 / 18 -> 31 / 30. Her death on day 130 stops the battle of Invrisil, so Zel lives:
## his mourning, casket, will and funeral (and the Pallass door after it) do not happen; he gives Selys
## the Heartflame himself.
## Laken 26 / 13 -> 26 / 49.5 (M28 Book 8 data): Book 7 alone still adds 13.0. The rest is Book 8 day 143:
## with no Laken there is no gathering, no night raid on the Goblin camp and no Lancrel war, so that whole
## chain (5.21 E - 5.32 G, Rags, Pyrite and Bethal too) cancels at once by real causes (ADR 0036 rule 1).
## Elia's mountain siege no longer waits on Tyrion saving Laken (story order only).
const CEILING := {
	"erin_solstice": [51, 49.0],
	"laken_godart": [26, 49.5],
	"selys": [25, 21.5],
	"zevara": [5, 6.0],
	"rags": [14, 11.5],
	"magnolia_reinhart": [31, 30.0],
	"kerrig_louis": [3, 3.0],
}
const ALTS := ["the_face_eater_moths_fall_on_liscor", "the_adventurers_haul_the_hobs_out_of_the_rift",
	"zels_will_sends_the_heartflame_to_magnolia", "selys_reads_of_the_heartflame_in_the_guild_archive",
	"durene_and_prost_keep_riverfarm_going", "tessia_fires_the_trebuchets_for_the_village",
	"riverfarm_feasts_its_own_people", "pyrite_moves_the_tribe_from_the_lake",
	"pyrite_leads_the_tribe_round_the_human_army", "pyrite_takes_the_tribe_south"]
## The door to Pallass, from Hawk's alley to the lifted embargo.
const PALLASS := ["hawk_opens_the_door_in_pallass", "erin_and_ilvriss_step_into_pallass",
	"pallass_watch_arrests_the_intruders", "pallass_raid_on_the_inn_fails", "erin_cuts_the_link_to_pallass",
	"zevara_brings_venim_to_the_inn", "erin_signs_the_pallass_lease", "pallass_opens_the_door_and_lifts_the_embargo",
	"pallass_crowd_mocks_liscor_at_the_door", "pallass_soldiers_cross_and_cut_down_fleeing_moths"]
## The moth battle at Liscor's wall, and after.
const WALL := ["zevara_and_olesm_feel_danger_and_the_first_moth_rises", "the_wall_holds_zevara_olesm_relc_ilvriss",
	"the_antinium_and_painted_soldiers_fight_in_the_open", "tekshia_declares_the_dungeon_gold_rank",
	"olesm_becomes_a_strategist", "pawn_blesses_the_fallen_on_the_walls", "fourth_company_decides_to_attack",
	"horns_open_the_victory_parade", "crowd_cheers_the_painted_soldiers"]
## The moth battle on the inn's hill.
const INN_MOTHS := ["face_eater_moths_attack_the_inn_and_liscor", "jelaqua_is_dropped_by_a_giant_moth",
	"pisces_falene_and_moore_call_down_a_great_rain", "the_inn_after_the_moths"]
## Zel's will and funeral.
const ZEL := ["zevara_asks_for_the_door_for_zel", "zels_casket_opened_in_city_hall", "zel_will_read_by_scrying_orb",
	"zel_funeral_in_the_plaza", "ilvriss_and_embria_vow_vengeance"]
## Selys and the Heartflame Breastplate.
const HEARTFLAME := ["zel_leaves_his_gear_to_selys", "selys_offered_breastplate_deals", "pisces_advises_on_the_armour",
	"selys_hisses_and_the_armour_burns", "selys_walks_burning_to_the_guild", "selys_leases_the_armour_to_halfseekers"]
## Selys is seized in Pallass after the Archive.
const KIDNAP := ["selys_reads_the_heartflame_in_pallass_archive", "selys_kidnapped_in_pallass", "pisces_saves_selys",
	"venim_arrests_the_kidnappers", "liscor_waits_for_selys_at_the_inn", "pisces_brings_selys_dinner"]
## The Redfang five in the dungeon.
const DUNGEON := ["redfang_decide_to_leave", "redfang_slip_away_to_the_dungeon", "hobs_loot_the_treasure_room",
	"cave_goblins_wound_badarrow", "hobs_report_the_face_collector", "treasure_argument_over_the_artifacts"]
## Magnolia's gathering at Riverfarm.
const NOBLES := ["magnolias_letter_invites_laken_to_a_gathering", "magnolia_sets_her_test_for_laken",
	"nobles_ride_to_riverfarm_with_sixty_guards", "laken_feasts_the_nobles_and_the_spring_court",
	"laken_tells_bevia_he_wants_no_lands", "a_poisoned_cup_is_found_at_the_banquet",
	"bethal_tells_magnolia_that_laken_passed"]
## The spring court at the feast.
const FAE := ["laken_calls_the_spring_court_to_his_feast", "the_fae_turn_wild_and_the_bells_ring",
	"the_fae_leave_and_bow_to_the_emperor_of_eyes"]
## The Flooded Waters tribe fights the army on the road.
const ROAD := ["kerrig_begs_rags_to_spare_the_army", "flooded_waters_rout_the_army_on_the_road",
	"welca_escapes_on_a_stolen_horse", "flooded_waters_burn_the_dead_and_salute_in_silence"]

var _db: DataDb
var _base_json := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	var gs := GameState.new_game(1, _db)
	ToyCanon.sleep_through(gs, _db, FIRST_DAY - 1)
	_base_json = gs.to_json()


## Kills `npcs` on day 130, sleeps through day 143.
func _run(npcs: Array) -> GameState:
	var gs := GameState.from_json(_base_json)
	for npc: String in npcs:
		assert_eq(Commands.kill_npc(gs, _db, npc), "")
	while gs.world.last_day < LAST_DAY:
		Commands.sleep(gs, _db, Rest.ANYWHERE)
	return gs


## Book 7 canon events (not alt events) that did not happen.
func _lost(gs: GameState) -> Array[String]:
	var out: Array[String] = []
	for id: String in _db.canon.events:
		if id.begins_with("b7.") and not _db.canon.alt_only.has(id) and not Director.happened(gs.world.status(id)):
			out.append(id)
	return out


func _check_ceiling(gs: GameState, npc: String) -> void:
	var lost := _lost(gs)
	assert_lte(lost.size(), int(CEILING[npc][0]), "%s: Book 7 events lost" % npc)
	assert_gt(gs.world.drift, 0.0)
	assert_lte(gs.world.drift, float(CEILING[npc][1]), "%s: drift" % npc)
	for id: String in _db.canon.events:
		if id.begins_with("b7.") and int(_db.canon.events[id]["window"]["latest"]) <= LAST_DAY \
				and not _db.canon.alt_only.has(id):
			assert_ne(gs.world.status(id), WorldState.PENDING, "%s is resolved" % id)


func _happened(gs: GameState, ids: Array) -> void:
	for id: String in ids:
		assert_true(Director.happened(gs.world.status("b7." + id)), id)


func _not_happened(gs: GameState, ids: Array) -> void:
	for id: String in ids:
		assert_false(Director.happened(gs.world.status("b7." + id)), id)


func _entry(gs: GameState, id: String) -> Dictionary:
	for h: Dictionary in gs.world.history:
		if h["event"] == id and h["outcome"] != Director.DELAYED:
			return h
	return {}


## The canon event mutated into `alt` on `day`, and the alt ran.
func _mutated(gs: GameState, id: String, alt: String, day: int) -> void:
	var e := _entry(gs, "b7." + id)
	assert_eq(e.get("outcome", ""), Director.MUTATED, id)
	assert_eq(e.get("via", ""), "b7." + alt, id)
	assert_eq(int(e.get("day", 0)), day, "%s mutates on its own day" % id)
	assert_eq(gs.world.status("b7." + alt), Director.DONE, alt)


## The canon event ran with `npc` in role `role` (a substitute).
func _stood_in(gs: GameState, id: String, role: String, npc: String) -> void:
	var e := _entry(gs, "b7." + id)
	assert_eq(e.get("outcome", ""), Director.SUBSTITUTED, id)
	assert_eq(e.get("roles", {}).get(role, ""), npc, id)


func test_every_day_with_on_map_canon_has_a_hook() -> void:
	var on_map := {}
	for area: String in _db.maps.areas:
		on_map[_db.maps.areas[area]["location"]] = true
	var days := {}
	var hooked := {}
	for id: String in _db.canon.events:
		var ev: Dictionary = _db.canon.events[id]
		if not id.begins_with("b7.") or _db.canon.alt_only.has(id) or not on_map.has(ev["location"]):
			continue
		var day := int(ev["window"]["earliest"])
		days[day] = true
		for h: Dictionary in ev.get("hooks", []):
			for d in range(int(h["days"][0]), int(h["days"][1]) + 1):
				hooked[d] = true
	assert_eq(days.size(), 14)
	for day: int in days:
		assert_true(hooked.has(day), "day %d has a hook" % day)


func test_sweeping_after_the_fire_changes_the_day() -> void:
	var gs := GameState.from_json(_base_json)
	ToyCanon.sleep_through(gs, _db, 135)
	assert_eq(gs.clock.day(), 136)
	gs.player.place("inn_interior", Vector2i(2, 2))
	Commands.settle(gs, _db)
	var r := Commands.interact(gs, _db, "broom", "sweep_floor")
	assert_eq(r["error"], "")
	ToyCanon.sleep_through(gs, _db, 136)
	var ev := _entry(gs, "b7.octavias_crate_sets_the_inn_floor_alight")
	assert_eq(ev["outcome"], Director.CHANGED)
	assert_eq(ev["hook"], "player_helped_smother_the_fire")
	assert_true(gs.flags.has("wandering_inn.earther_helped_smother_the_fire"))
	assert_true(gs.flags.has("wandering_inn.floor_scorched"), "the canon effects still happen")


func test_no_kill_never_runs_an_alt_event() -> void:
	var gs := _run([])
	assert_eq(_lost(gs), [] as Array[String])
	assert_eq(gs.world.drift, 0.0)
	assert_true(gs.flags.has("izril.rains"))
	assert_true(gs.flags.has("izril.flood"))
	for id: String in ALTS:
		assert_true(_db.canon.alt_only.has("b7." + id), id)
		assert_eq(gs.world.status("b7." + id), WorldState.PENDING, id)


func test_erin_dies_and_liscor_fights_the_moths_alone() -> void:
	var gs := _run(["erin_solstice"])
	_check_ceiling(gs, "erin_solstice")
	_mutated(gs, "face_eater_moths_attack_the_inn_and_liscor", "the_face_eater_moths_fall_on_liscor", 137)
	_mutated(gs, "erin_rescues_headscratcher_and_badarrow", "the_adventurers_haul_the_hobs_out_of_the_rift", 140)
	_mutated(gs, "selys_reads_the_heartflame_in_pallass_archive",
		"selys_reads_of_the_heartflame_in_the_guild_archive", 142)
	assert_true(gs.flags.has("izril.rains"), "the rain does not need Erin")
	assert_true(gs.flags.has("izril.flood"), "the flood does not need Erin")
	_happened(gs, ["izril_mourns_zel", "the_flood_reaches_the_inn_hill", "vuliel_drae_confess_the_eggs"])
	_happened(gs, WALL)
	_happened(gs, ZEL)
	_happened(gs, HEARTFLAME)
	_happened(gs, DUNGEON)
	_happened(gs, NOBLES)
	_happened(gs, ["rags_turns_south_toward_liscor", "flooded_waters_rout_the_army_on_the_road"])
	_not_happened(gs, PALLASS)
	_not_happened(gs, KIDNAP)
	_not_happened(gs, ["jelaqua_is_dropped_by_a_giant_moth", "pisces_falene_and_moore_call_down_a_great_rain",
		"the_inn_after_the_moths", "players_of_celum_perform_at_the_inn", "battle_of_liscor_play",
		"klbkch_and_relc_visit_the_rebuilt_inn"])


func test_laken_dies_and_riverfarm_holds_together() -> void:
	var gs := _run(["laken_godart"])
	_check_ceiling(gs, "laken_godart")
	_mutated(gs, "riverfarm_grows_toward_a_city", "durene_and_prost_keep_riverfarm_going", 130)
	_mutated(gs, "riverfarm_tests_trebuchets_and_a_ballista", "tessia_fires_the_trebuchets_for_the_village", 132)
	assert_true(gs.flags.has("riverfarm.has_working_trebuchets"))
	_happened(gs, PALLASS)
	_happened(gs, WALL)
	_happened(gs, INN_MOTHS)
	_happened(gs, HEARTFLAME)
	_happened(gs, KIDNAP)
	_not_happened(gs, NOBLES)
	_not_happened(gs, FAE)


func test_selys_dies_and_the_heartflame_goes_to_magnolia() -> void:
	var gs := _run(["selys"])
	_check_ceiling(gs, "selys")
	_mutated(gs, "zel_leaves_his_gear_to_selys", "zels_will_sends_the_heartflame_to_magnolia", 141)
	assert_true(gs.flags.has("heartflame.will_sends_it_to_magnolia"))
	_happened(gs, ZEL)
	_happened(gs, PALLASS)
	_happened(gs, INN_MOTHS)
	_happened(gs, ["erin_runs_the_door_after_the_funeral", "tekshia_approves_pisces_sewer_undead"])
	_not_happened(gs, HEARTFLAME)
	_not_happened(gs, KIDNAP)
	_not_happened(gs, ["ilvriss_confirms_the_law", "selys_buries_zels_ashes_by_sserys", "tekshia_signs_the_goblin_team"])


func test_zevara_dies_and_others_stand_in() -> void:
	var gs := _run(["zevara"])
	_check_ceiling(gs, "zevara")
	_stood_in(gs, "zevara_brings_venim_to_the_inn", "guard_captain", "relc")
	_stood_in(gs, "pallass_opens_the_door_and_lifts_the_embargo", "captain", "relc")
	_stood_in(gs, "zevara_and_olesm_stop_the_fight", "zevara", "ilvriss")
	_stood_in(gs, "zevara_asks_for_the_door_for_zel", "zevara", "tekshia")
	_happened(gs, PALLASS)
	_happened(gs, WALL)
	_happened(gs, ZEL)
	_happened(gs, HEARTFLAME)
	_happened(gs, KIDNAP)
	_not_happened(gs, ["zevara_learns_of_the_pallass_door", "zevara_has_the_walls_checked",
		"zevara_faces_embria_in_her_office", "zevara_hides_the_healer_death"])


func test_rags_dies_and_pyrite_leads_the_tribe() -> void:
	var gs := _run(["rags"])
	_check_ceiling(gs, "rags")
	_mutated(gs, "rags_breaks_camp_and_marches_west", "pyrite_moves_the_tribe_from_the_lake", 142)
	_mutated(gs, "redfang_scout_reports_a_human_army_hunting_goblins",
		"pyrite_leads_the_tribe_round_the_human_army", 142)
	_mutated(gs, "rags_turns_south_toward_liscor", "pyrite_takes_the_tribe_south", 142)
	_happened(gs, ["garen_feels_the_goblin_lord_coming", "garen_and_tremborag_agree_to_hold_the_mountain",
		"pyrite_beats_off_the_mountain_goblins_who_grab_welca", "pyrite_talks_with_the_knights_over_lunch"])
	_happened(gs, DUNGEON)
	_happened(gs, WALL)
	_not_happened(gs, ROAD)
	_not_happened(gs, ["rags_judges_the_goblins_who_attacked_welca", "rags_reaches_chieftain_level_20"])


func test_magnolia_dies_and_riverfarm_feasts_alone() -> void:
	var gs := _run(["magnolia_reinhart"])
	_check_ceiling(gs, "magnolia_reinhart")
	_mutated(gs, "nobles_ride_to_riverfarm_with_sixty_guards", "riverfarm_feasts_its_own_people", 142)
	_happened(gs, FAE)
	_happened(gs, ["laken_ends_the_builders_feud", "scaffold_collapse_sparks_a_feud_in_riverfarm"])
	_not_happened(gs, NOBLES)
	assert_true(gs.world.is_alive(_db.canon, "zel_shivertail"), "M32.4: no battle, so Zel lives")
	_not_happened(gs, ZEL)
	_mutated(gs, "zel_leaves_his_gear_to_selys", "zel_gives_selys_the_heartflame", 141)
	_happened(gs, HEARTFLAME.filter(func(id: String) -> bool: return id != "zel_leaves_his_gear_to_selys"))


func test_kerrig_dies_and_the_army_is_still_routed() -> void:
	var gs := _run(["kerrig_louis"])
	_check_ceiling(gs, "kerrig_louis")
	_happened(gs, ["redfang_scout_reports_a_human_army_hunting_goblins", "flooded_waters_rout_the_army_on_the_road",
		"flooded_waters_burn_the_dead_and_salute_in_silence", "rags_turns_south_toward_liscor"])
	_not_happened(gs, ["kerrig_begs_rags_to_spare_the_army", "welca_escapes_on_a_stolen_horse"])
