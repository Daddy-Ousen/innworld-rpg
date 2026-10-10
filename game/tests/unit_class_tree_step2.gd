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


func test_dragoon_needs_warrior_and_rider_and_a_level_10() -> void:
	var gs := GameState.new()
	ToyData.give_class(gs, "warrior", 1)
	gs.progression.pools["dragoon"] = 1000.0
	assert_eq(ClassSystem.consolidate_ready(gs, _db), [] as Array[String], "no rider")
	ToyData.give_class(gs, "rider", 1)
	assert_eq(ClassSystem.consolidate_ready(gs, _db), [] as Array[String], "both at level 1")
	gs.progression.classes["warrior"]["level"] = 10
	var lines := ClassSystem.consolidate_ready(gs, _db)
	assert_string_contains(lines[0], "[Warrior] and [Rider] became [Dragoon]")
	assert_false(gs.progression.has_class("rider"))
	assert_eq(gs.progression.level_of("dragoon"), 8, "level 10 minus cost 2")


func test_consolidation_waits_for_the_source_breakthrough() -> void:
	var gs := GameState.new()
	var levels: Dictionary = _db.rules["levels"]
	ToyData.give_class(gs, "warrior", 9)
	ToyData.give_class(gs, "rider", 1)
	gs.progression.pools["dragoon"] = 1000.0
	assert_eq(Breakthrough.waiting_for(gs.progression, "warrior", levels), 10)
	assert_eq(ClassSystem.consolidate_ready(gs, _db), [] as Array[String], "level 9 waits for its key")
	ClassSystem.grant_breakthrough(gs, "warrior")
	gs.progression.classes["warrior"]["level"] = 10
	ClassSystem.consolidate_ready(gs, _db)
	assert_true(gs.progression.has_class("dragoon"))
	assert_false(gs.progression.breakthroughs.has("warrior"), "the old key goes with the class")
	assert_false(gs.progression.breakthroughs.has("dragoon"), "no key carried over")
	gs.progression.classes["dragoon"]["level"] = 9
	assert_eq(Breakthrough.waiting_for(gs.progression, "dragoon", levels), 10,
			"the new class needs its own breakthrough")


func test_druid_needs_three_classes_and_a_level_10() -> void:
	var gs := GameState.new()
	ToyData.give_class(gs, "gardener", 10)
	ToyData.give_class(gs, "beast_tamer", 2)
	gs.progression.pools["druid"] = 1000.0
	assert_eq(ClassSystem.consolidate_ready(gs, _db), [] as Array[String], "mage missing")
	ToyData.give_class(gs, "mage", 1)
	ClassSystem.consolidate_ready(gs, _db)
	assert_true(gs.progression.has_class("druid"))
	assert_eq(gs.progression.level_of("druid"), 7, "level 10 minus cost 3")
