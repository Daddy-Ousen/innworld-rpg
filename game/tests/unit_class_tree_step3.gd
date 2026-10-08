extends GutTest
## Wiki class tree, step 3: hunter, archer, alchemist, blacksmith, teacher, knight, assassin.

const NEW_CLASSES := ["hunter", "archer", "alchemist", "blacksmith", "teacher", "knight", "assassin"]
var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()


func test_each_new_class_uses_known_tags_and_has_a_skill() -> void:
	for id: String in NEW_CLASSES:
		assert_true(_db.classes.has(id), id)
		for tag: String in _db.classes[id]["tag_weights"]:
			assert_true(_db.tags.has(tag), "%s uses tag %s" % [id, tag])
		var has_skill := false
		for sk: Dictionary in _db.skills.values():
			for pool: Dictionary in sk["pools"]:
				if pool["class"] == id:
					has_skill = true
		assert_true(has_skill, "%s has a Skill" % id)


func test_advancements_need_their_base_class() -> void:
	assert_eq(_db.classes["knight"]["prereqs"]["classes"], ["exemplar_warrior"])
	assert_eq(_db.classes["assassin"]["prereqs"]["classes"], ["rogue"])
	assert_true((_db.classes["assassin"]["excludes"] as Array).has("guardsman"))


func test_knight_offer_needs_exemplar_warrior() -> void:
	var gs := GameState.new()
	gs.progression.pools["knight"] = 1000.0
	assert_false(ClassSystem.make_offers(gs, _db, ClassSystem.KIND_NEW, 2).has("knight"))
	ToyData.give_class(gs, "exemplar_warrior", 5)
	assert_true(ClassSystem.make_offers(gs, _db, ClassSystem.KIND_NEW, 2).has("knight"))
