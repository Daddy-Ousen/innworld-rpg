extends GutTest

const EPS := 0.000001
const STEW := {"cooking.stew": 1.0}
const FIGHT := {"combat": 1.0}
var _db: DataDb


func before_all() -> void:
	_db = ToyData.db()


func _feed(gs: GameState, tags: Dictionary, xp: float, day: int = 1) -> void:
	ClassSystem.feed(gs, _db, ToyData.record(tags, xp, day))


func _offer_new(gs: GameState, budget: int = 2) -> Array[String]:
	return ClassSystem.make_offers(gs, _db, ClassSystem.KIND_NEW, budget)


func test_feed_fills_pools_by_tag_match() -> void:
	var gs := GameState.new()
	_feed(gs, STEW, 10.0)
	var pools := gs.progression.pools
	assert_almost_eq(float(pools["cook"]), 10.0, EPS)
	assert_almost_eq(float(pools["innkeeper"]), 5.0, EPS)
	assert_almost_eq(float(pools["battle_chef"]), 10.0, EPS)
	assert_false(pools.has("warrior"))


func test_held_class_gets_xp_not_pool() -> void:
	var gs := GameState.new()
	ToyData.give_class(gs, "cook")
	_feed(gs, STEW, 10.0)
	assert_false(gs.progression.pools.has("cook"))
	assert_almost_eq(float(gs.progression.classes["cook"]["xp"]), 10.0, EPS)


func test_offer_needs_full_pool() -> void:
	var gs := GameState.new()
	_feed(gs, STEW, 19.0)
	assert_eq(_offer_new(gs), [] as Array[String])
	_feed(gs, STEW, 1.0)
	assert_eq(_offer_new(gs), ["cook"] as Array[String])
	assert_eq(gs.progression.offers[0]["kind"], "new")


func test_offers_are_capped_and_best_filled_first() -> void:
	var gs := GameState.new()
	_feed(gs, STEW, 100.0)   # cook 5.0×, innkeeper 50/30
	_feed(gs, FIGHT, 30.0)   # warrior 1.5×
	gs.progression.pools["pacifist"] = 100.0  # 10×
	assert_eq(_offer_new(gs), ["pacifist", "cook"] as Array[String])
	assert_eq(_offer_new(gs, 5), ["innkeeper", "warrior"] as Array[String],
			"the rest come on later nights; open offers are not repeated")


func test_consolidation_class_is_not_a_normal_offer() -> void:
	var gs := GameState.new()
	gs.progression.pools["battle_chef"] = 1000.0
	assert_false(_offer_new(gs, 9).has("battle_chef"))
	assert_eq(ClassSystem.make_offers(gs, _db, ClassSystem.KIND_CONSOLIDATION, 2), [] as Array[String],
			"needs both source classes")


func test_excluded_class_is_not_offered() -> void:
	var gs := GameState.new()
	ToyData.give_class(gs, "warrior")
	gs.progression.pools["pacifist"] = 100.0
	assert_false(ClassSystem.can_offer(gs, _db, "pacifist"), "warrior excludes pacifist")


func test_race_limit() -> void:
	var gs := GameState.new()
	gs.progression.pools["elf_guard"] = 100.0
	assert_false(ClassSystem.can_offer(gs, _db, "elf_guard"), "Earthers are human")
	gs.race = "elf"
	assert_true(ClassSystem.can_offer(gs, _db, "elf_guard"))


func test_flag_prereq() -> void:
	var gs := GameState.new()
	assert_false(ClassSystem.can_offer(gs, _db, "flag_class"))
	gs.flags["met_relc"] = true
	assert_true(ClassSystem.can_offer(gs, _db, "flag_class"))


func test_accept_gives_level_1_and_a_skill() -> void:
	var gs := GameState.new(3)
	_feed(gs, STEW, 20.0)
	_offer_new(gs)
	var lines := ClassSystem.accept(gs, _db, "cook")
	var p := gs.progression
	assert_eq(p.level_of("cook"), 1)
	assert_false(p.has_offer("cook"))
	assert_eq(p.skills.size(), 1, "rules.skills.on_accept = 1")
	assert_eq(p.skills[0]["class"], "cook")
	assert_string_contains(lines[0], "Class gained")


func test_accept_withdraws_excluded_offers() -> void:
	var gs := GameState.new()
	gs.progression.pools["pacifist"] = 100.0
	gs.progression.pools["warrior"] = 100.0
	_offer_new(gs)
	ClassSystem.accept(gs, _db, "warrior")
	assert_false(gs.progression.has_offer("pacifist"))
	assert_false(gs.progression.declined.has("pacifist"), "withdrawn, not blacklisted")


func test_answer_without_offer_changes_nothing() -> void:
	var gs := GameState.new()
	var before := gs.to_json()
	assert_string_contains(ClassSystem.accept(gs, _db, "cook")[0], "no offer")
	assert_string_contains(ClassSystem.decline(gs, _db, "cook")[0], "no offer")
	assert_eq(gs.to_json(), before)


func test_declined_class_never_returns() -> void:
	var gs := GameState.new()
	_feed(gs, STEW, 20.0)
	_offer_new(gs)
	ClassSystem.decline(gs, _db, "cook")
	var p := gs.progression
	assert_eq(p.declined, ["cook"] as Array[String])
	var frozen := float(p.pools["cook"])
	for i in 20:
		_feed(gs, STEW, 100.0)
		assert_false(_offer_new(gs, 9).has("cook"))
	assert_almost_eq(float(p.pools["cook"]), frozen, EPS, "the pool stops growing")
	assert_true(p.has_offer("innkeeper"), "the XP still flows to related classes")


func test_consolidation_offer_and_accept() -> void:
	var gs := GameState.new()
	ToyData.give_class(gs, "cook", 4)
	ToyData.give_class(gs, "warrior", 2)
	gs.progression.skills.append({"id": "swing", "class": "warrior", "level": 1, "day": 1})
	gs.progression.pools["battle_chef"] = 10.0
	assert_eq(ClassSystem.make_offers(gs, _db, ClassSystem.KIND_CONSOLIDATION, 2),
			["battle_chef"] as Array[String])
	assert_eq(gs.progression.offers[0]["kind"], "consolidation")
	ClassSystem.accept(gs, _db, "battle_chef")
	var p := gs.progression
	assert_false(p.has_class("cook"))
	assert_false(p.has_class("warrior"))
	assert_eq(p.level_of("battle_chef"), 3, "best source level 4 − level_cost 1")
	assert_true(p.has_skill("swing"), "skills stay")


func test_neglect_drains_then_loses_the_class() -> void:
	var gs := GameState.new()
	ToyData.give_class(gs, "cook", 2, 40.0)
	var p := gs.progression
	assert_eq(ClassSystem.check_loss(gs, _db, 3), [] as Array[String], "2 days: fine")
	ClassSystem.check_loss(gs, _db, 4)
	assert_eq(p.level_of("cook"), 1)
	assert_almost_eq(float(p.classes["cook"]["xp"]), 0.0, EPS)
	var lines := ClassSystem.check_loss(gs, _db, 5)
	assert_false(p.has_class("cook"))
	assert_eq(p.lost, ["cook"] as Array[String])
	assert_string_contains(lines[0], "lost")
	_feed(gs, STEW, 20.0)
	assert_eq(_offer_new(gs), ["cook"] as Array[String], "a lost class can come back")


func test_matching_work_keeps_the_class_active() -> void:
	var gs := GameState.new()
	ToyData.give_class(gs, "cook", 2)
	_feed(gs, STEW, 5.0, 4)
	assert_eq(gs.progression.classes["cook"]["last_active_day"], 4)
	assert_eq(ClassSystem.check_loss(gs, _db, 6), [] as Array[String])
