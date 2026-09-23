extends GutTest
## M4 "Done when" (ROADMAP): from a new game the player walks from the Liscor
## gate to the market and the inn, does actions through map objects, meets
## NPCs on their schedules, sleeps in the inn bed through the main scene and
## answers a class offer in the System dialog. M6.1 pacing (ADR 0011): a plain
## inn workday gets the first offer by the third night.

const SEED := 20260923
const MAX_DAYS := 3

var _session: Node


func before_each() -> void:
	_session = get_node_or_null("/root/Session")


func _use(gs: GameState, db: DataDb, object_id: String, action_id: String) -> void:
	assert_true(ToyMaps.walk_next_to(gs, db, object_id), "walk to %s" % object_id)
	assert_eq(Commands.interact(gs, db, object_id, action_id)["error"], "",
			"%s at %s" % [action_id, object_id])


func test_first_days_end_with_an_answered_offer() -> void:
	if _session == null:
		fail_test("no Session autoload")
		return
	var db: DataDb = _session.db
	_session.set_state(GameState.new_game(SEED, db))
	var gs: GameState = _session.gs
	var main: Node = add_child_autofree(load("res://world/main.tscn").instantiate())
	var dialog: SystemDialog = main.dialog

	assert_eq(gs.player.area, "liscor_gate")
	assert_false(gs.npcs.in_area("liscor_gate").is_empty(), "guards at the gate")
	assert_true(ToyMaps.walk_to_area(gs, db, "liscor_market"))
	# The traders open their stalls at 07:00 and 08:00 (npc_behaviour.json).
	for i in 180:
		if not gs.npcs.in_area("liscor_market").is_empty():
			break
		Commands.wait(gs, db, 60)
	assert_false(gs.npcs.in_area("liscor_market").is_empty(), "traders at the market")
	_use(gs, db, "krshia_counter", "buy_supplies")
	assert_true(ToyMaps.walk_to_area(gs, db, "liscor_gate"))
	assert_true(ToyMaps.walk_to_area(gs, db, "floodplains_south"))
	assert_true(ToyMaps.walk_to_area(gs, db, "inn_hill"))
	assert_true(ToyMaps.walk_to_area(gs, db, "inn_interior"))

	var answered := ""
	for day in MAX_DAYS:
		for action: String in ["cook_stew", "cook_stew", "cook_stew"]:
			_use(gs, db, "stove", action)
		_use(gs, db, "broom", "sweep_floor")
		_use(gs, db, "bed", "clean_room")
		assert_true(ToyMaps.walk_next_to(gs, db, "bed"), "walk to the bed")
		var today := gs.clock.day()
		main.use("bed", Interact.SLEEP)
		assert_eq(gs.clock.day(), today + 1, "slept through the night")
		assert_true(dialog.visible, "the System speaks every morning")
		while dialog.visible:
			if dialog.current["kind"] == SystemMessages.OFFER and answered == "":
				answered = dialog.current["class"]
				dialog.choose(SystemMessages.ACCEPT)
			elif dialog.current["kind"] == SystemMessages.OFFER:
				dialog.choose(SystemMessages.DECLINE)
				dialog.choose(SystemMessages.YES)
			else:
				dialog.choose(SystemMessages.NEXT)
		if answered != "":
			gut.p("offer on day %d: %s" % [gs.clock.day(), answered])
			break
	assert_ne(answered, "", "a class offer within %d days" % MAX_DAYS)
	assert_true(gs.progression.has_class(answered))
	assert_false(main.is_busy())
