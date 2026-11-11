## M29.0: the System speaks like the books (ADR 0044).
extends GutTest


func test_bare_takes_off_the_brackets() -> void:
	assert_eq(SystemVoice.bare("[Innkeeper]"), "Innkeeper")
	assert_eq(SystemVoice.bare("Innkeeper"), "Innkeeper", "no brackets: unchanged")


func test_lines_in_book_style() -> void:
	assert_eq(SystemVoice.level_up("[Innkeeper]", 2), "[Innkeeper Level 2!]")
	assert_eq(SystemVoice.skill("[Basic Cooking]"), "[Skill – Basic Cooking obtained!]")
	assert_eq(SystemVoice.class_obtained("[Innkeeper]"), "[Innkeeper Class Obtained!]")
	assert_eq(SystemVoice.class_offered("[Innkeeper]"), "[Innkeeper Class Offered!]")
	assert_eq(SystemVoice.class_lost("[Cook]"), "[Cook Class Lost.]")
	assert_eq(SystemVoice.level_down("[Cook]", 3, 2), "[Cook Level 3 → Level 2.]")
	assert_eq(SystemVoice.conditions_met(["[Cook]", "[Warrior]"], "[Battle Chef]"),
			"[Conditions Met: Cook, Warrior → Battle Chef Class!]")
	assert_eq(SystemVoice.breakthrough("[Innkeeper]", 10), "[Breakthrough: Innkeeper can grow past Level 10!]")


func test_accept_says_class_then_level_then_skill() -> void:
	var db := ToyData.db()
	var gs := GameState.new()
	gs.progression.offers.append({"class": "cook", "kind": ClassSystem.KIND_NEW, "day": 1})
	var lines := ClassSystem.accept(gs, db, "cook")
	assert_eq(lines[0], "[X Class Obtained!]")
	assert_eq(lines[1], "[X Level 1!]")
	assert_eq(lines[2], "[Skill – S obtained!]")


func test_offer_page_title_and_first_line() -> void:
	var db := ToyMaps.db()
	var gs := ToyMaps.new_game(db)
	gs.progression.offers.append({"class": "cook", "kind": ClassSystem.KIND_NEW, "day": 1})
	var p: Dictionary = SystemMessages.offer_pages(gs, db)[0]
	assert_eq(p["title"], "Class Offered")
	assert_eq(p["lines"][0], SystemVoice.class_offered(db.classes["cook"]["name"]))
	assert_eq(p["choices"], [SystemMessages.ACCEPT, SystemMessages.DECLINE] as Array[String])


func test_talk_action_is_just_talk() -> void:
	var db := DataDb.load_dir()
	assert_eq(db.actions["talk_with_guest"]["name"], "Talk", "id unchanged, label short")
