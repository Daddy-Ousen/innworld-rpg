extends GutTest
## Wiki class tree, step 2: riding, animals, gardening and faith lines.

const ACTIONS := {
	"ride_horse": "riding", "tend_animals": "animals", "tend_garden": "gardening", "pray": "faith",
}
var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()


func test_each_new_action_trains_its_tag_and_has_a_map_object_and_sound() -> void:
	var audio := AudioDb.load_file()
	for id: String in ACTIONS:
		assert_true(_db.actions.has(id), id)
		assert_true((_db.actions[id]["tags"] as Dictionary).has(ACTIONS[id]), id)
		assert_true(audio.data["actions"].has(id), "%s has a sound" % id)
		var found := false
		for area: String in _db.maps.areas:
			for o: Dictionary in _db.maps.objects_on(area):
				if (o["actions"] as Array).has(id):
					found = true
		assert_true(found, "%s is on a map object" % id)


func test_priest_line_chain() -> void:
	assert_eq(_db.classes["priest"]["prereqs"]["classes"], ["acolyte"])
	assert_eq(_db.classes["bishop"]["prereqs"]["classes"], ["priest"])


func test_dragoon_needs_warrior_and_rider() -> void:
	var gs := GameState.new()
	ToyData.give_class(gs, "warrior", 4)
	gs.progression.pools["dragoon"] = 1000.0
	assert_eq(ClassSystem.make_offers(gs, _db, ClassSystem.KIND_CONSOLIDATION, 2), [] as Array[String])
	ToyData.give_class(gs, "rider", 3)
	assert_eq(ClassSystem.make_offers(gs, _db, ClassSystem.KIND_CONSOLIDATION, 2), ["dragoon"] as Array[String])
	ClassSystem.accept(gs, _db, "dragoon")
	assert_false(gs.progression.has_class("rider"))
	assert_eq(gs.progression.level_of("dragoon"), 2, "level 4 minus cost 2")


func test_druid_needs_three_classes() -> void:
	var gs := GameState.new()
	ToyData.give_class(gs, "gardener", 5)
	ToyData.give_class(gs, "beast_tamer", 2)
	gs.progression.pools["druid"] = 1000.0
	assert_eq(ClassSystem.make_offers(gs, _db, ClassSystem.KIND_CONSOLIDATION, 2), [] as Array[String])
	ToyData.give_class(gs, "mage", 1)
	assert_eq(ClassSystem.make_offers(gs, _db, ClassSystem.KIND_CONSOLIDATION, 2), ["druid"] as Array[String])
