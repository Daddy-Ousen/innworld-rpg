extends GutTest

const EPS := 0.000001
var _db: DataDb


func before_all() -> void:
	_db = ToyData.db()


func _ids(list: Array[Dictionary]) -> Array:
	return list.map(func(c: Dictionary) -> String: return c["id"])


func test_affinity_is_share_of_matching_tag_xp() -> void:
	var totals := {"cooking.stew": 30.0, "combat": 10.0}
	assert_almost_eq(SkillSystem.affinity({"cooking": 1.0}, totals), 0.75, EPS)
	assert_almost_eq(SkillSystem.affinity({"cooking": 1.0}, {}), 0.0, EPS)


func test_candidates_follow_class_and_level_band() -> void:
	var gs := GameState.new()
	assert_eq(_ids(SkillSystem.candidates(gs, _db, "cook", 1)), ["stew_sense", "knife_work"])
	assert_eq(_ids(SkillSystem.candidates(gs, _db, "cook", 3)), ["stew_sense", "knife_work", "grand_feast"])
	assert_eq(_ids(SkillSystem.candidates(gs, _db, "cook", 3, true)), ["grand_feast"])
	assert_eq(_ids(SkillSystem.candidates(gs, _db, "warrior", 1)), ["swing"])


func test_held_skills_are_not_candidates() -> void:
	var gs := GameState.new()
	gs.progression.skills.append({"id": "stew_sense", "class": "cook", "level": 1, "day": 1})
	assert_eq(_ids(SkillSystem.candidates(gs, _db, "cook", 1)), ["knife_work"])


func test_tag_history_weights_the_pick() -> void:
	var gs := GameState.new()
	gs.action_log.tag_totals = {"cooking.stew": 90.0, "combat": 10.0}
	var list := SkillSystem.candidates(gs, _db, "cook", 1)
	assert_almost_eq(float(list[0]["weight"]), 0.1 + 0.9, EPS)
	assert_almost_eq(float(list[1]["weight"]), 0.1 + 0.1, EPS)


func test_capstone_prefers_rare() -> void:
	var gs := GameState.new(5)
	assert_eq(SkillSystem.on_level(gs, _db, "cook", 3), "grand_feast")
	assert_eq(gs.progression.skills[0]["level"], 3)


func test_empty_pool_gives_nothing() -> void:
	var gs := GameState.new()
	assert_eq(SkillSystem.grant_random(gs, _db, "innkeeper", 1), "")
	assert_true(gs.progression.skills.is_empty())


func test_same_seed_same_pick() -> void:
	var picks := []
	for i in 2:
		var gs := GameState.new(42)
		picks.append(SkillSystem.grant_random(gs, _db, "cook", 1))
	assert_eq(picks[0], picks[1])


func test_xp_effects_only_collects_xp_mult() -> void:
	var gs := GameState.new()
	for id: String in ["stew_sense", "knife_work", "grand_feast"]:
		gs.progression.skills.append({"id": id, "class": "cook", "level": 1, "day": 1})
	var effects := SkillSystem.xp_effects(gs.progression, _db)
	assert_eq(effects.size(), 1)
	assert_eq(effects[0]["value"], 2.0)


func test_xp_mult_skill_raises_action_xp() -> void:
	var gs := GameState.new()
	var plain := float(Actions.perform(gs, _db, "cook")["xp"])
	var gs2 := GameState.new()
	gs2.progression.skills.append({"id": "stew_sense", "class": "cook", "level": 1, "day": 1})
	var rec := Actions.perform(gs2, _db, "cook")
	assert_almost_eq(float(rec["xp"]), plain * 2.0, EPS)
	assert_almost_eq(float(rec["skill_mult"]), 2.0, EPS)
