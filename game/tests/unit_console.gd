extends GutTest

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()


func after_each() -> void:
	var path := ProjectSettings.globalize_path(ConsoleCommands.SAVE_PATH)
	if FileAccess.file_exists(ConsoleCommands.SAVE_PATH):
		DirAccess.remove_absolute(path)


func _text(lines: Array[String]) -> String:
	return "\n".join(lines)


func test_help_and_unknown_command() -> void:
	var c := ConsoleCommands.new(_db)
	assert_string_contains(_text(c.execute("help")), "sleep")
	assert_string_contains(_text(c.execute("dance")), "Unknown command")
	assert_eq(c.execute("   "), [] as Array[String])


func test_do_parses_repeat_options_and_context() -> void:
	var c := ConsoleCommands.new(_db)
	var out := c.execute("do cook_stew x2 guests=12 location=inn intensity=1.5 with=relc,klbkch")
	assert_eq(out.size(), 2)
	var rec: Dictionary = c.gs.action_log.records[0]
	assert_true((rec["tags"] as Dictionary).has("hospitality"), "context went to the action")
	assert_almost_eq(float(rec["intensity"]), 1.5, 0.000001)
	assert_eq(rec["witnesses"], ["relc", "klbkch"])
	assert_eq(c.gs.clock.total_minutes, 360 + 2 * 90)


func test_do_unknown_action() -> void:
	var c := ConsoleCommands.new(_db)
	assert_string_contains(_text(c.execute("do fly")), "Unknown action")
	assert_string_contains(_text(c.execute("do")), "Usage")


func test_sleep_status_and_offers() -> void:
	var c := ConsoleCommands.new(_db, 20260923)
	var status := ""
	for day in range(1, 16):
		c.execute("do cook_stew x2 guests=12 location=inn")
		c.execute("do serve_guests x2 guests=12")
		c.execute("do clean_room location=inn")
		c.execute("do talk_with_guest location=inn")
		assert_string_contains(_text(c.execute("sleep")), "Day %d" % (day + 1))
		status = _text(c.execute("status"))
		if status.contains("Offer: [Innkeeper]"):
			break
	assert_string_contains(status, "Offer: [Innkeeper]")
	assert_string_contains(_text(c.execute("accept innkeeper")), "Class gained")
	assert_string_contains(_text(c.execute("status")), "[Innkeeper] level 1")
	assert_string_contains(_text(c.execute("pools")), "cook")


func test_collapse_from_the_console() -> void:
	var c := ConsoleCommands.new(_db)
	var out := _text(c.execute("do keep_watch x20"))
	assert_string_contains(out, "collapse")
	assert_true(c.gs.clock.last_sleep_collapsed)


func test_focus_command() -> void:
	var c := ConsoleCommands.new(_db)
	assert_string_contains(_text(c.execute("focus hospitality cooking")), "hospitality, cooking")
	assert_string_contains(_text(c.execute("focus nothing")), "Unknown tag")
	assert_string_contains(_text(c.execute("focus clear")), "cleared")


func test_save_load_and_new() -> void:
	var c := ConsoleCommands.new(_db)
	c.execute("do chop_wood")
	var saved := c.gs.to_json()
	assert_eq(_text(c.execute("save")), "Saved.")
	c.execute("new 5")
	assert_eq(c.gs.clock.total_minutes, 360)
	assert_string_contains(_text(c.execute("load")), "Loaded")
	assert_eq(c.gs.to_json(), saved)


func test_console_scene_runs_a_command() -> void:
	var scene: Control = add_child_autofree(load("res://ui/debug_console.tscn").instantiate())
	var input: LineEdit = scene.get_node("%Input")
	var output: RichTextLabel = scene.get_node("%Output")
	assert_string_contains(output.get_parsed_text(), "Commands:")
	input.text_submitted.emit("do sweep_floor")
	assert_string_contains(output.get_parsed_text(), "> do sweep_floor")
	assert_string_contains(output.get_parsed_text(), "Sweep the floor")


func test_kill_flag_history_and_drift() -> void:
	var c := ConsoleCommands.new(_db)
	assert_string_contains(_text(c.execute("kill relc")), "is dead")
	assert_string_contains(_text(c.execute("kill relc")), "already dead")
	assert_string_contains(_text(c.execute("kill")), "Usage")
	assert_string_contains(_text(c.execute("flag village.walls")), "village.walls = true")
	assert_eq(c.gs.flags["village.walls"], true)
	assert_string_contains(_text(c.execute("flag village.walls off")), "cleared")
	assert_false(c.gs.flags.has("village.walls"))
	c.execute("flag gold 5")
	assert_eq(c.gs.flags["gold"], 5)
	assert_string_contains(_text(c.execute("history")), "killed")
	assert_string_contains(_text(c.execute("drift")), "Drift 0.00")
