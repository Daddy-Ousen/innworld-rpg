extends GutTest

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()


func after_each() -> void:
	var path := ProjectSettings.globalize_path(ConsoleCommands.SAVE_PATH)
	if FileAccess.file_exists(ConsoleCommands.SAVE_PATH):
		DirAccess.remove_absolute(path)


func _start() -> int:
	return int(_db.rules["clock"]["start_minute"])


func _text(lines: Array[String]) -> String:
	return "\n".join(lines)


func test_help_and_unknown_command() -> void:
	var c := ConsoleCommands.new(_db)
	assert_string_contains(_text(c.execute("help")), "sleep")
	assert_string_contains(_text(c.execute("dance")), "Unknown command")
	assert_eq(c.execute("   "), [] as Array[String])


func test_do_parses_repeat_options_and_context() -> void:
	var c := ConsoleCommands.new(_db)
	var out := c.execute("do cook_stew x2 guests=12 location=wandering_inn intensity=1.5 with=relc,klbkch")
	assert_eq(out.size(), 2)
	var rec: Dictionary = c.gs.action_log.records[0]
	assert_true((rec["tags"] as Dictionary).has("hospitality"), "context went to the action")
	assert_almost_eq(float(rec["intensity"]), 1.5, 0.000001)
	assert_eq(rec["witnesses"], ["relc", "klbkch"])
	assert_eq(c.gs.clock.total_minutes, _start() + 2 * 90)


func test_do_unknown_action() -> void:
	var c := ConsoleCommands.new(_db)
	assert_string_contains(_text(c.execute("do fly")), "Unknown action")
	assert_string_contains(_text(c.execute("do")), "Usage")


func test_sleep_status_and_offers() -> void:
	var c := ConsoleCommands.new(_db, 20260923)
	var status := ""
	for i in 15:
		var next := c.gs.clock.day() + 1
		c.execute("do cook_stew x2 guests=12 location=wandering_inn")
		c.execute("do serve_guests x2 guests=12")
		c.execute("do clean_room location=wandering_inn")
		c.execute("do talk_with_guest location=wandering_inn")
		assert_string_contains(_text(c.execute("sleep *")), "Day %d" % next)
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
	assert_eq(c.gs.clock.total_minutes, _start())
	assert_string_contains(_text(c.execute("load")), "Loaded")
	assert_eq(c.gs.to_json(), saved)


func test_where_look_go_and_use() -> void:
	var c := ConsoleCommands.new(_db)
	assert_string_contains(_text(c.execute("where")), "Liscor east gate")
	assert_string_contains(_text(c.execute("look")), "@")
	var out := _text(c.execute("go w x3"))
	assert_string_contains(out, "You travel to Liscor market")
	assert_eq(c.gs.player.area, "liscor_market")
	assert_string_contains(_text(c.execute("go up")), "n, s, e or w")
	assert_string_contains(_text(c.execute("use stove cook_stew")), "no 'stove' here")
	assert_string_contains(_text(c.execute("use stove")), "Usage")


func test_go_into_a_wall_stops() -> void:
	var c := ConsoleCommands.new(_db)
	c.gs.player.place("inn_interior", Vector2i(1, 1))
	var out := _text(c.execute("go n x5"))
	assert_string_contains(out, "You walk 0 steps.")
	assert_string_contains(out, "blocks the way")


func test_use_an_object() -> void:
	var c := ConsoleCommands.new(_db)
	c.gs.player.place("inn_interior", Vector2i(20, 2))
	assert_string_contains(_text(c.execute("look")), "Stove (stove)")
	assert_string_contains(_text(c.execute("use stove cook_stew")), "Cook a stew")
	assert_eq(c.gs.action_log.records[-1]["action_id"], "cook_stew")


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


func test_wait_npcs_and_talk() -> void:
	var c := ConsoleCommands.new(_db)
	assert_string_contains(_text(c.execute("npcs")), "beilmark         liscor_gate 2,13")
	assert_string_contains(_text(c.execute("look")), "Beilmark (beilmark): talk_with_guest")
	var out := _text(c.execute("use beilmark talk_with_guest"))
	assert_string_contains(out, "Talk with a guest")
	assert_eq(c.gs.world.relationship("beilmark", NpcSim.PLAYER), 1)
	var t := c.gs.clock.total_minutes
	assert_string_contains(_text(c.execute("wait 30")), "You wait.")
	assert_eq(c.gs.clock.total_minutes, t + 30)
	assert_string_contains(_text(c.execute("wait soon")), "whole number")


func test_combat_commands() -> void:
	var c := ConsoleCommands.new(_db)
	c.gs.player.place("floodplains_south", Vector2i(14, 9))
	Commands.settle(c.gs, _db)
	c.gs.combat.monsters.clear()
	c.gs.combat.fight = {}
	for s: Dictionary in _db.combat.spawns:
		c.gs.combat.spawn_last[s["id"]] = c.gs.clock.total_minutes
	assert_string_contains(_text(c.execute("look")), "Loose stones (loose_stones_1): take")
	assert_string_contains(_text(c.execute("use loose_stones_1 take")), "You take the stone.")
	assert_string_contains(_text(c.execute("status")), "HP 20/20 · Held: Stone")
	assert_string_contains(_text(c.execute("monsters")), "There are no monsters here.")
	assert_string_contains(_text(c.execute("throw")), "There is nothing to throw at.")
	assert_string_contains(_text(c.execute("spawn dragon")), "Unknown enemy")
	assert_string_contains(_text(c.execute("spawn goblin_grunt 1 0")), "Goblin (m")
	assert_string_contains(_text(c.execute("look")), "@M")
	var list := _text(c.execute("monsters"))
	assert_string_contains(list, "hostile")
	assert_string_contains(list, "In a fight (in danger).")
	assert_string_contains(_text(c.execute("do sweep_floor")), Combat.REFUSED_DANGER)
	assert_string_contains(_text(c.execute("attack e")), "Goblin")
	assert_string_contains(_text(c.execute("block")), "You raise your guard.")
	assert_string_contains(_text(c.execute("drop")), "You put the stone down.")
	assert_string_contains(_text(c.execute("drop")), "You hold nothing.")
	assert_string_contains(_text(c.execute("attack")), "Usage")
	assert_string_contains(_text(c.execute("knockout")), "--- You are knocked out. ---")
	assert_eq(c.gs.player.area, "inn_interior")
	assert_string_contains(_text(c.execute("monsters")), "There are no monsters here.")
