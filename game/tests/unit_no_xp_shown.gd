extends GutTest
## M15.3: the player never sees XP numbers or the total level (DESIGN §1, ADR 0022).
## The debug console (`) is a developer tool and keeps its numbers.

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()


func _assert_clean(text: String, where: String) -> void:
	assert_false(text.contains("XP"), "%s shows XP" % where)
	assert_false(text.to_lower().contains("total level"), "%s shows the total level" % where)


func _game_with_classes() -> GameState:
	var gs := GameState.new_game(1, _db)
	gs.progression.classes["cook"] = {"level": 4, "xp": 37.0, "last_active_day": 1}
	gs.progression.classes["warrior"] = {"level": 3, "xp": 5.0, "last_active_day": 1}
	return gs


func test_the_character_sheet_shows_class_levels_only() -> void:
	var gs := _game_with_classes()
	var text := "\n".join(CharacterSheet.lines(gs, _db))
	_assert_clean(text, "the character sheet")
	assert_string_contains(text, "level 4")
	assert_string_contains(text, "level 3")
	assert_false(text.contains("37"), "no XP amount")


func test_the_journal_and_the_hints_show_no_xp() -> void:
	var gs := _game_with_classes()
	_assert_clean("\n".join(Journal.lines(gs, _db)), "the journal")
	_assert_clean("\n".join(SystemMessages.HINTS), "the hints")
	_assert_clean("\n".join(SystemMessages.KEYS), "the help page")
	_assert_clean("\n".join(SystemMessages.welcome_page()["lines"]), "the welcome page")


func test_an_action_line_shows_no_xp() -> void:
	var session := get_node_or_null("/root/Session")
	if session == null:
		return
	session.set_state(GameState.new_game(1, session.db))
	var main: Node = add_child_autofree(load("res://world/main.tscn").instantiate())
	main.switch_scene = false
	session.gs.player.place("inn_interior", Vector2i(20, 2))
	main.use("stove", "cook_stew")
	var log_text: String = main.hud.get_node("%Log").text
	assert_string_contains(log_text, "Cook a stew.")
	_assert_clean(log_text, "the action line")


func test_the_console_keeps_its_numbers() -> void:
	var c := ConsoleCommands.new(_db)
	assert_string_contains("\n".join(c.execute("do cook_stew")), "XP")
