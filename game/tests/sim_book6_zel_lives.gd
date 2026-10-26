extends GutTest
## M32.4 on the real Book 6 - 7 data (ADR 0044 "M32.4"): the "Zel lives" bend. With
## zel.saved_by_the_player (the M32.2 hook on Zel's stage), Zel's death mutates into
## b6.zel_spares_reiss_and_lives. The Goblin Lord, Magnolia and Az'kerash threads go on
## by alt events; the Book 6 - 7 mourning, the casket, the will and the funeral cancel;
## Zel gives Selys the Heartflame himself, so her Book 7 thread runs. The game is slept
## to day 129 once (before_all); each test starts from a copy and sets the flag on day 130.

const SEED := 20261026
const DAY := 130
const LAST_DAY := 143
const ZEL := "zel_shivertail"
const SAVED := "zel.saved_by_the_player"
const DEATH := "b6.zel_names_the_goblin_lord_reiss_and_dies"
const LIVES := "b6.zel_spares_reiss_and_lives"
const FUNERAL := "b7.zel_funeral_in_the_plaza"
## Canon event -> its alt when Zel lives (day 130 unless noted).
const BENDS := {
	DEATH: LIVES,
	"b6.magnolia_offers_a_bounty_on_the_necromancer": "b6.magnolia_offers_a_bounty_for_the_trap",
	"b6.azkerash_tells_his_chosen_the_next_will_be_better": "b6.azkerash_rages_that_zel_lived",
	"b6.liscor_mourns_zel": "b6.liscor_hears_zel_lived",
}
## Scenes about Zel's death that do not happen when he lives.
const MOURNING := ["b6.reiss_orders_zels_body_untouched_and_withdraws",
	"b6.klbkch_speaks_to_the_grand_queen_through_the_mirror",
	"b7.izril_mourns_zel", "b7.pallass_military_parade", "b7.laken_hears_zel_shivertail_is_dead",
	"b7.selys_remembers_zels_last_visit", "b7.zevara_asks_for_the_door_for_zel", "b7.zels_casket_opened_in_city_hall",
	"b7.zel_will_read_by_scrying_orb", "b7.zevara_hides_the_healer_death", FUNERAL,
	"b7.ilvriss_and_embria_vow_vengeance", "b7.selys_buries_zels_ashes_by_sserys"]
## Selys and the Heartflame Breastplate (heartflame.selys_inherits).
const HEARTFLAME := ["b7.selys_becomes_an_heiress", "b7.ilvriss_confirms_the_law", "b7.selys_offered_breastplate_deals",
	"b7.pisces_advises_on_the_armour", "b7.selys_and_pisces_visit_the_armour", "b7.selys_gets_the_dignitaries",
	"b7.selys_hisses_and_the_armour_burns", "b7.selys_walks_burning_to_the_guild",
	"b7.selys_leases_the_armour_to_halfseekers", "b7.selys_haggles_with_jelaqua_at_the_inn",
	"b7.heartflame_riddle_reaches_selys"]
## Book 6 - 7 canon events lost and total drift, at most (measured 2026-10-26: 25 / 15.0). Besides the
## death, its 5 dependents and the 11 Book 7 Zel scenes, no funeral means no door to Pallass after it:
## Selys reads in the guild archive (alt) and is never kidnapped (6 scenes).
const MAX_LOST := 25
const MAX_DRIFT := 15.0

var _db: DataDb
var _base := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])
	var gs := GameState.new_game(SEED, _db)
	ToyCanon.sleep_through(gs, _db, DAY - 1)
	_base = gs.to_json()


## Day 130 with Zel saved on the field, slept through `day`.
func _saved(day: int) -> GameState:
	var gs := GameState.from_json(_base)
	assert_eq(gs.clock.day(), DAY)
	gs.flags[SAVED] = true
	ToyCanon.sleep_through(gs, _db, day)
	return gs


func _entry(gs: GameState, id: String) -> Dictionary:
	for h: Dictionary in gs.world.history:
		if h["event"] == id and h["outcome"] != Director.DELAYED:
			return h
	return {}


## Book 6 - 7 canon events (not alt events) that did not happen.
func _lost(gs: GameState) -> Array[String]:
	var out: Array[String] = []
	for id: String in _db.canon.events:
		if (id.begins_with("b6.") or id.begins_with("b7.")) and not _db.canon.alt_only.has(id) \
				and not Director.happened(gs.world.status(id)):
			out.append(id)
	return out


func test_the_bend_data_is_sound() -> void:
	var death: Dictionary = _db.canon.events[DEATH]
	assert_eq(death["requires"]["not_flags"], [SAVED])
	assert_eq(death["on_fail"][0], "mutate:" + LIVES)
	for alt: String in BENDS.values() + ["b7.zel_gives_selys_the_heartflame"]:
		assert_true(_db.canon.alt_only.has(alt), alt + " is an alt")
		var ev: Dictionary = _db.canon.events[alt]
		assert_eq(ev["canon_ref"]["confidence"], "guess", alt)
		assert_true(String(ev["canon_ref"]["note"]).begins_with("Not in the book (M32.4"), alt)
		assert_false((ev["effects"] as Dictionary).has("kill"), alt + " kills no one")
	assert_eq(_db.canon.events[FUNERAL]["stage"]["when_flags"], ["zel.body_in_liscor"])


func test_zel_lives_and_the_goblin_lord_is_still_named_reiss() -> void:
	var gs := _saved(DAY)
	assert_true(gs.world.is_alive(_db.canon, ZEL), "Zel lives")
	var e := _entry(gs, DEATH)
	assert_eq(e.get("outcome", ""), Director.MUTATED)
	assert_eq(e.get("via", ""), LIVES)
	assert_eq(int(e.get("day", 0)), DAY)
	for f: String in ["zel.survived_invrisil", "goblin_lord.named_reiss", "goblin_lord.swore_to_kill_the_necromancer",
			"goblin_army.withdrew_from_invrisil"]:
		assert_true(gs.flags.has(f), f)
	for f: String in ["zel.dead_at_invrisil", "world.believes_the_goblin_lord_killed_zel", "azkerash.and_the_chosen_killed_zel"]:
		assert_false(gs.flags.has(f), f)
	assert_true(gs.world.is_alive(_db.canon, "goblin_lord"), "the Goblin Lord lives as in canon")
	assert_false(gs.world.is_alive(_db.canon, "oom"), "Oom still falls in the dome")


func test_the_threads_after_the_death_hand_off_to_alts() -> void:
	var gs := _saved(DAY)
	for id: String in BENDS:
		var e := _entry(gs, id)
		assert_eq(e.get("outcome", ""), Director.MUTATED, id)
		assert_eq(e.get("via", ""), BENDS[id], id)
		assert_eq(gs.world.status(BENDS[id]), Director.DONE, BENDS[id])
	assert_true(gs.flags.has("magnolia.offered_a_bounty_on_the_necromancer"))
	assert_false(gs.flags.has("magnolia.weeps_for_zel"))
	assert_true(gs.flags.has("azkerash.failed_to_kill_zel"))
	assert_true(gs.flags.has("liscor.hears_zel_lived"))
	assert_false(gs.flags.has("liscor.mourns_zel"))


func test_the_mourning_cancels_through_book_7() -> void:
	var gs := _saved(LAST_DAY)
	for id: String in MOURNING:
		assert_false(Director.happened(gs.world.status(id)), id)
		assert_ne(gs.world.status(id), WorldState.PENDING, id + " is resolved")
	assert_false(Director.happened(gs.world.status("b6.the_inn_mourns_zel")), "the Erin-dead alt does not run")
	for f: String in ["izril.mourns_zel", "pallass.vengeance_parade_held", "laken.heard_that_zel_shivertail_is_dead",
			"zel.body_in_liscor", "zel.will_read", "zel.cremated"]:
		assert_false(gs.flags.has(f), f)
	assert_true(gs.world.is_alive(_db.canon, ZEL), "still alive at the end of Book 7")


func test_zel_gives_selys_the_heartflame_and_her_thread_runs() -> void:
	var gs := _saved(LAST_DAY)
	var e := _entry(gs, "b7.zel_leaves_his_gear_to_selys")
	assert_eq(e.get("outcome", ""), Director.MUTATED)
	assert_eq(e.get("via", ""), "b7.zel_gives_selys_the_heartflame")
	assert_eq(int(e.get("day", 0)), 141, "the gift comes on the will's day")
	assert_true(gs.flags.has("heartflame.selys_inherits"))
	assert_true(gs.flags.has("heartflame.given_by_zel"))
	assert_false(gs.flags.has("heartflame.bound_for_magnolia"))
	for id: String in HEARTFLAME:
		assert_true(Director.happened(gs.world.status(id)), id)


func test_the_funeral_scene_does_not_stage() -> void:
	var gs := _saved(141)
	gs.player.place("liscor_plaza", Vector2i(15, 5))
	Commands.settle(gs, _db)
	while gs.clock.day() == 142:
		assert_false(gs.world.staged.has(FUNERAL), "no body, no funeral")
		assert_true(Commands.wait(gs, _db, 1800) >= 0, "wait")
	assert_false(gs.world.staged.has(FUNERAL))


func test_zel_goes_back_to_liscor() -> void:
	var gs := _saved(DAY + 1)
	Commands.settle(gs, _db)
	assert_true(gs.npcs.npcs.has(ZEL), "Zel is in the roster")
	assert_eq(String(gs.npcs.npcs[ZEL]["area"]), BehaviourDb.OFF_MAP_PREFIX + "liscor")


func test_the_drift_is_counted() -> void:
	var gs := _saved(LAST_DAY)
	var lost := _lost(gs)
	print("M32.4 lost %d, drift %.2f: %s" % [lost.size(), gs.world.drift, lost])
	assert_gt(gs.world.drift, 0.0)
	assert_lte(lost.size(), MAX_LOST, "Book 6 - 7 events lost")
	assert_lte(gs.world.drift, MAX_DRIFT, "drift")
	for id: String in _db.canon.events:
		if (id.begins_with("b6.") or id.begins_with("b7.")) and not _db.canon.alt_only.has(id) \
				and int(_db.canon.events[id]["window"]["latest"]) <= LAST_DAY:
			assert_ne(gs.world.status(id), WorldState.PENDING, "%s is resolved" % id)
