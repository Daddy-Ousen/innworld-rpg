extends GutTest
## M6.1 journal (J): focus choices from class data, and the focus it sets.

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()


func _choice(choices: Array[Dictionary], name: String) -> Dictionary:
	for c: Dictionary in choices:
		if c["name"] == name:
			return c
	return {}


func test_choices_start_with_no_focus_and_skip_consolidations() -> void:
	var gs := GameState.new_game(1, _db)
	var choices := Journal.focus_choices(gs, _db)
	assert_eq(choices[0]["name"], "No focus")
	assert_eq(choices[0]["tags"], [])
	var inn := _choice(choices, "Become [Innkeeper]")
	assert_eq(inn["tags"], ["hospitality", "cooking", "cleaning"] as Array[String], "main tags, strongest first")
	assert_true(_choice(choices, "Become [Commander]").is_empty(), "a consolidation is not a focus")


func test_declined_class_is_no_focus_choice() -> void:
	var gs := GameState.new_game(1, _db)
	gs.progression.declined.append("cook")
	assert_true(_choice(Journal.focus_choices(gs, _db), "Become [Cook]").is_empty())


func test_focus_name() -> void:
	var gs := GameState.new_game(1, _db)
	assert_eq(Journal.focus_name(gs, _db), "none")
	Commands.set_focus(gs, _db, ["cleaning", "hospitality", "cooking"])
	assert_eq(Journal.focus_name(gs, _db), "Become [Innkeeper]", "order does not matter")
	Commands.set_focus(gs, _db, ["cooking", "commerce"])
	assert_eq(Journal.focus_name(gs, _db), "cooking, commerce", "a focus set in the console")


func test_lines_show_the_day_the_focus_and_the_hints() -> void:
	var gs := GameState.new_game(1, _db)
	var text := "\n".join(Journal.lines(gs, _db))
	assert_string_contains(text, "Day 8, 06:00.")
	assert_string_contains(text, "Focus: none")
	assert_string_contains(text, SystemMessages.HINTS[0])


func test_choose_sets_the_focus() -> void:
	var gs := GameState.new_game(1, _db)
	var journal: Journal = add_child_autofree(load("res://ui/journal.tscn").instantiate())
	journal.open(gs, _db)
	assert_true(journal.visible)
	var items: ItemList = journal.get_node("%Focus")
	var index := -1
	for i in items.item_count:
		if items.get_item_text(i) == "Become [Innkeeper]":
			index = i
	assert_eq(journal.choose(index), "")
	assert_eq(gs.focus_tags, ["hospitality", "cooking", "cleaning"] as Array[String])
	assert_string_contains(journal.get_node("%Text").text, "Focus: Become [Innkeeper]")
	assert_eq(journal.choose(0), "")
	assert_eq(gs.focus_tags, [] as Array[String])


func test_focus_speeds_the_first_offer() -> void:
	# Conviction (DESIGN §3.2): the same inn work fills [Innkeeper] faster with the focus.
	var plain := GameState.new_game(3, _db)
	var focused := GameState.new_game(3, _db)
	Commands.set_focus(focused, _db, Journal.main_tags(_db.classes["innkeeper"]))
	for gs: GameState in [plain, focused]:
		gs.player.place("inn_interior", Vector2i(20, 13))
		gs.npcs.npcs.clear()
		for work: Array in [["stove", "cook_stew"], ["broom", "sweep_floor"], ["bed", "clean_room"]]:
			ToyMaps.walk_next_to(gs, _db, work[0])
			assert_eq(Commands.interact(gs, _db, work[0], work[1])["error"], "")
		gs.clock.advance(14 * 60)
		ToyMaps.walk_next_to(gs, _db, "bed")
		Commands.sleep(gs, _db)
	assert_gt(float(focused.progression.pools["innkeeper"]), float(plain.progression.pools["innkeeper"]))
