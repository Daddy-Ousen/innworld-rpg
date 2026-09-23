extends GutTest
## M4.5 System messages (ADR 0009): pages, the System dialog, the
## character sheet and sleeping in a bed.

var _db: DataDb


func before_all() -> void:
	_db = ToyMaps.db()


func _new_game() -> GameState:
	return ToyMaps.new_game(_db)


func _kinds(pages: Array[Dictionary]) -> Array:
	return pages.map(func(p: Dictionary) -> String: return p["kind"])


func _offer(gs: GameState, id: String, kind: String = ClassSystem.KIND_NEW) -> void:
	gs.progression.offers.append({"class": id, "kind": kind, "day": gs.clock.day()})


func _dialog() -> SystemDialog:
	return add_child_autofree(load("res://ui/system_dialog.tscn").instantiate())


# --- Pages ------------------------------------------------------------------

func test_empty_night_is_one_silent_morning_page() -> void:
	var gs := _new_game()
	gs.clock.advance(14 * 60)  # 20:00, not a nap
	var night := Night.run(gs, _db)
	var pages := SystemMessages.pages(night, gs, _db)
	assert_eq(_kinds(pages), [SystemMessages.MORNING])
	assert_eq(pages[0]["lines"], [SystemMessages.SILENT_LINE, "You wake on day 2 at 06:00."])
	assert_eq(pages[0]["choices"], [SystemMessages.NEXT])


func test_pages_come_in_a_fixed_order() -> void:
	var gs := _new_game()
	_offer(gs, "cook")
	_offer(gs, "warrior")
	var night := {"collapsed": true, "progress": ["Cook reached level 2."],
		"world": ["Rumor: a thing happened.", Director.UNRELIABLE_LINE]}
	var pages := SystemMessages.pages(night, gs, _db)
	assert_eq(_kinds(pages), [SystemMessages.COLLAPSE, SystemMessages.PROGRESS,
		SystemMessages.RUMORS, SystemMessages.DRIFT, SystemMessages.OFFER, SystemMessages.OFFER,
		SystemMessages.MORNING])
	assert_eq(pages[0]["lines"], [Night.COLLAPSE_LINE])
	assert_eq(pages[2]["lines"], ["Rumor: a thing happened."], "the drift line gets its own page")
	assert_eq(pages[4]["class"], "cook")
	assert_eq(pages[5]["class"], "warrior")
	assert_eq(pages[-1]["lines"].size(), 1, "not silent")


func test_a_real_night_offer_has_accept_and_decline() -> void:
	var gs := _new_game()
	for i in 3:
		Actions.perform(gs, _db, "cook")
	var night := Night.run(gs, _db)
	assert_true((night["offers"] as Array).has("cook"))
	var offers := SystemMessages.pages(night, gs, _db).filter(func(p: Dictionary) -> bool:
		return p["kind"] == SystemMessages.OFFER)
	assert_eq(offers.size(), (night["offers"] as Array).size())
	assert_eq(offers[0]["choices"], [SystemMessages.ACCEPT, SystemMessages.DECLINE])
	assert_string_contains("\n".join(offers[0]["lines"]), "never offered again")


func test_consolidation_offer_names_what_it_replaces() -> void:
	var gs := _new_game()
	ToyData.give_class(gs, "cook", 4)
	ToyData.give_class(gs, "warrior", 2)
	_offer(gs, "battle_chef", ClassSystem.KIND_CONSOLIDATION)
	var text := "\n".join(SystemMessages.offer_pages(gs, _db)[0]["lines"])
	assert_string_contains(text, "takes the place of")
	assert_string_contains(text, "level 3", "best from level 4 minus level_cost 1")


func test_confirm_and_open_checks() -> void:
	var gs := _new_game()
	_offer(gs, "cook")
	var p := SystemMessages.offer_pages(gs, _db)[0]
	assert_true(SystemMessages.is_open(p, gs))
	var confirm := SystemMessages.confirm_decline(_db, "cook")
	assert_eq(confirm["choices"], [SystemMessages.YES, SystemMessages.BACK])
	assert_string_contains("\n".join(confirm["lines"]), "permanent")
	gs.progression.offers.clear()
	assert_false(SystemMessages.is_open(p, gs), "the offer is gone")
	assert_true(SystemMessages.is_open(SystemMessages.result(["x"]), gs), "other pages stay")


func test_night_result_has_sections() -> void:
	var gs := _new_game()
	ToyData.give_class(gs, "cook", 1, 95.0)
	Actions.perform(gs, _db, "cook")
	gs.clock.awake_minutes = int(_db.rules["clock"]["collapse_after_awake"])
	var night := Night.run(gs, _db, true)
	assert_true(night["collapsed"])
	assert_string_contains("\n".join(night["progress"]), "level 2")
	assert_eq(night["lines"][0], Night.COLLAPSE_LINE)
	assert_eq(night["world"], [])


# --- Dialog -----------------------------------------------------------------

func test_dialog_accept_shows_the_answer_then_closes() -> void:
	var gs := _new_game()
	_offer(gs, "cook")
	var d := _dialog()
	watch_signals(d)
	d.open(SystemMessages.pages({}, gs, _db), gs, _db)
	assert_true(d.visible)
	assert_eq(d.current["kind"], SystemMessages.OFFER)
	assert_eq(d.get_node("%Buttons").get_child_count(), 2)
	d.choose(SystemMessages.ACCEPT)
	assert_true(gs.progression.has_class("cook"))
	assert_eq(d.current["kind"], SystemMessages.RESULT)
	assert_string_contains("\n".join(d.current["lines"]), "Class gained")
	d.choose(SystemMessages.NEXT)
	assert_eq(d.current["kind"], SystemMessages.MORNING)
	d.choose(SystemMessages.NEXT)
	assert_false(d.visible)
	assert_signal_emitted(d, "closed")


func test_dialog_decline_asks_once_more() -> void:
	var gs := _new_game()
	_offer(gs, "cook")
	var d := _dialog()
	d.open(SystemMessages.offer_pages(gs, _db), gs, _db)
	d.choose(SystemMessages.DECLINE)
	assert_eq(d.current["kind"], SystemMessages.CONFIRM)
	assert_true(gs.progression.has_offer("cook"), "nothing happens before the second answer")
	d.choose(SystemMessages.BACK)
	assert_eq(d.current["kind"], SystemMessages.OFFER)
	d.choose(SystemMessages.DECLINE)
	d.choose(SystemMessages.YES)
	assert_true(gs.progression.declined.has("cook"))
	assert_eq(d.current["kind"], SystemMessages.RESULT)
	d.choose(SystemMessages.NEXT)
	assert_false(d.visible)


func test_dialog_skips_offers_that_an_accept_withdrew() -> void:
	var gs := _new_game()
	_offer(gs, "warrior")
	_offer(gs, "pacifist")  # warrior excludes pacifist
	var d := _dialog()
	d.open(SystemMessages.pages({}, gs, _db), gs, _db)
	d.choose(SystemMessages.ACCEPT)
	assert_string_contains("\n".join(d.current["lines"]), "is gone")
	d.choose(SystemMessages.NEXT)
	assert_eq(d.current["kind"], SystemMessages.MORNING, "the pacifist page is skipped")


# --- Character sheet --------------------------------------------------------

func test_sheet_lists_classes_skills_and_offers() -> void:
	var gs := _new_game()
	var text := "\n".join(CharacterSheet.lines(gs, _db))
	assert_string_contains(text, "Classes:\n  None yet.")
	assert_string_contains(text, "Focus: none")
	ToyData.give_class(gs, "cook", 2, 10.0)
	gs.progression.skills.append({"id": "stew_sense", "class": "cook", "level": 2, "day": 1})
	_offer(gs, "warrior")
	gs.progression.declined.append("pacifist")
	text = "\n".join(CharacterSheet.lines(gs, _db))
	assert_string_contains(text, "[X] level 2   10 / 200 XP")
	assert_string_contains(text, "[S]   from [X] level 2")
	assert_string_contains(text, "Open offers:")
	assert_string_contains(text, "Declined:")
	assert_string_contains(text, "Total level: 2")


# --- Beds -------------------------------------------------------------------

func test_a_bed_offers_sleep() -> void:
	var gs := _new_game()
	gs.player.place("shop", Vector2i(1, 1))
	var cot: Dictionary = Interact.options(gs, _db)[0]
	assert_eq(cot["id"], "cot")
	assert_true(cot["sleep"])
	assert_true(Interact.can_sleep(gs, _db, "cot"))
	gs.player.place("town", Vector2i(1, 2))
	assert_false(Interact.can_sleep(gs, _db, "cot"), "too far")


func test_console_use_bed_sleep_ends_the_day() -> void:
	var c := ConsoleCommands.new(_db)
	c.gs = _new_game()
	c.gs.player.place("shop", Vector2i(1, 1))
	c.gs.clock.advance(14 * 60)
	assert_string_contains("\n".join(c.execute("look")), "Cot (cot): sleep")
	var out := "\n".join(c.execute("use cot sleep"))
	assert_string_contains(out, "You sleep")
	assert_eq(c.gs.clock.day(), 2)


func test_the_real_inn_bed_is_a_bed() -> void:
	var db := DataDb.load_dir()
	var gs := GameState.new_game(1, db)
	gs.npcs.npcs.clear()
	var bed := Vector2i(21, 13)
	var spot := Vector2i(-1, -1)
	for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if db.maps.is_walkable("inn_interior", bed + d):
			spot = bed + d
			break
	assert_ne(spot, Vector2i(-1, -1), "a free tile next to the bed")
	gs.player.place("inn_interior", spot)
	assert_true(Interact.can_sleep(gs, db, "bed"))


# --- Main scene -------------------------------------------------------------

func test_main_scene_sleep_opens_the_dialog() -> void:
	var session := get_node_or_null("/root/Session")
	if session == null:
		fail_test("no Session autoload")
		return
	session.set_state(GameState.new_game(1, session.db))
	var main: Node = add_child_autofree(load("res://world/main.tscn").instantiate())
	session.gs.progression.offers.append({"class": "innkeeper", "kind": "new", "day": 8})
	session.gs.player.place("inn_interior", Vector2i(20, 13))
	session.gs.npcs.npcs.clear()
	session.gs.clock.advance(14 * 60)
	main.use("bed", Interact.SLEEP)
	assert_eq(session.gs.clock.day(), 9)
	var dialog: SystemDialog = main.dialog
	assert_true(dialog.visible)
	assert_true(main.is_busy())
	assert_eq(dialog.current["kind"], SystemMessages.OFFER)
	dialog.choose(SystemMessages.ACCEPT)
	dialog.choose(SystemMessages.NEXT)
	dialog.choose(SystemMessages.NEXT)
	assert_false(main.is_busy())
	assert_true(session.gs.progression.has_class("innkeeper"))
	assert_string_contains(main.hud.get_node("%Log").text, "Day 9, 06:00.")


func test_a_knock_out_page_replaces_the_collapse_page() -> void:
	var gs := _new_game()
	gs.clock.advance(14 * 60)
	var night := Night.run(gs, _db, true, true)
	var pages := SystemMessages.pages(night, gs, _db)
	assert_eq(_kinds(pages), [SystemMessages.KNOCKOUT, SystemMessages.MORNING])
	assert_eq(pages[0]["title"], "Knocked Out")
	assert_eq(pages[0]["lines"][0], Night.KNOCKOUT_LINE)
	var place: String = _db.canon.locations[Movement.location_at(gs, _db)]["name"]
	assert_eq(pages[0]["lines"][1], "You wake at %s with %d HP." % [place, Combat.hp(gs, _db)])


func test_sheet_shows_hp_held_item_and_stats() -> void:
	var gs := _new_game()
	var text := "\n".join(CharacterSheet.lines(gs, _db))
	assert_string_contains(text, Hud.health(gs, _db))
	assert_string_contains(text, "Stats: Strength ")
	assert_string_contains(text, "Endurance ")
