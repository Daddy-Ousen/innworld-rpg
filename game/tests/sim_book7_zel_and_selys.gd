extends GutTest
## M19.7 on the real Book 7 data (5.16 S - 5.18 S, days 140 - 143): Zel's will and funeral, Selys and
## the Heartflame Breastplate. Two scene stages with one talk hook each: Zel's funeral in the plaza
## (day 142) and the lease haggle in the inn (day 143). No xp_window. Slept to day 140 once (before_all).

const SEED := 20261010
const FUNERAL := "b7.zel_funeral_in_the_plaza"
const HAGGLE := "b7.selys_haggles_with_jelaqua_at_the_inn"

var _db: DataDb
var _base := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])
	var gs := GameState.new_game(SEED, _db)
	ToyCanon.sleep_through(gs, _db, 139)
	_base = gs.to_json()


func _at_day(day: int) -> GameState:
	var gs := GameState.from_json(_base)
	if day > 140:
		ToyCanon.sleep_through(gs, _db, day - 1)
	assert_eq(gs.clock.day(), day)
	return gs


func _wait_for_stage(gs: GameState, id: String, area: String, spot: Vector2i) -> void:
	gs.player.place(area, spot)
	Commands.settle(gs, _db)
	for i in 120:
		if gs.world.staged.has(id):
			break
		assert_true(Commands.wait(gs, _db, 600) >= 0, "wait")
	assert_true(gs.world.staged.has(id), id + " is staged")


func _area_of(gs: GameState, id: String) -> String:
	var n: Dictionary = gs.npcs.npcs.get(id, {})
	return "" if n.is_empty() else String(n["area"])


func _talk_to(gs: GameState, id: String) -> void:
	var n: Dictionary = gs.npcs.npcs[id]
	var area := String(n["area"])
	var at := Vector2i(int(n["x"]), int(n["y"]))
	var taken := {}
	for other: String in gs.npcs.in_area(area):
		taken[NpcRoster.pos_of(gs.npcs.npcs[other])] = true
	var spot := Vector2i(-1, -1)
	for d: Vector2i in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
		if not taken.has(at + d):
			spot = at + d
			break
	assert_ne(spot, Vector2i(-1, -1), "a free side of " + id)
	gs.player.place(area, spot)
	var r := Commands.interact(gs, _db, id, "talk_with_guest")
	assert_eq(r["error"], "")


func test_the_two_stages_are_scenes_without_windows() -> void:
	for id: String in [FUNERAL, HAGGLE]:
		var ev: Dictionary = _db.canon.events[id]
		assert_eq(ev["stage"]["kind"], "scene", id)
		assert_false(ev.has("xp_window"), id)
		assert_eq(ev["hooks"].size(), 1, id)
		var seen := {}
		for n: Dictionary in ev["stage"]["npcs"]:
			assert_true(_db.behaviour.npcs.has(n["npc"]), n["npc"])
			var key := str(n["pos"])
			assert_false(seen.has(key), id + " tile used twice " + key)
			seen[key] = true
	assert_eq(_db.canon.events[FUNERAL]["stage"]["area"], "liscor_plaza")
	assert_eq(_db.canon.events[HAGGLE]["stage"]["area"], "inn_interior")


func test_the_will_and_the_armour_days_140_to_141() -> void:
	var gs := _at_day(140)
	ToyCanon.sleep_through(gs, _db, 141)
	for f: String in ["redfang.reported_face_collector", "liscor.door_reserved_for_zels_body", "liscor.pisces_sewer_undead_approved",
			"zel.body_in_liscor", "heartflame.armour_found_on_zel", "zel.will_read", "heartflame.selys_inherits",
			"heartflame.claim_secure_by_osthia_law"]:
		assert_true(gs.flags.has(f), f)


func test_the_funeral_has_a_zevara_hook() -> void:
	var gs := _at_day(142)
	_wait_for_stage(gs, FUNERAL, "liscor_plaza", Vector2i(15, 5))
	for id: String in ["zevara", "tekshia", "selys", "ilvriss", "embria_grasstongue", "relc"]:
		assert_eq(_area_of(gs, id), "liscor_plaza", id)
	_talk_to(gs, "zevara")
	ToyCanon.sleep_through(gs, _db, 142)
	assert_eq(gs.world.status(FUNERAL), Director.CHANGED)
	assert_true(gs.flags.has("liscor.earther_stood_at_zels_funeral"))
	assert_true(gs.flags.has("zel.cremated"))
	assert_true(gs.flags.has("pallass.selys_kidnapped"))
	assert_true(gs.flags.has("pisces.killed_selys_kidnappers"))
	assert_true(gs.world.is_alive(_db.canon, "selys"))
	assert_true(gs.world.is_alive(_db.canon, "pisces"))


func test_the_lease_haggle_has_a_selys_hook_and_the_day_ends_in_the_graveyard() -> void:
	var gs := _at_day(143)
	_wait_for_stage(gs, HAGGLE, "inn_interior", Vector2i(3, 3))
	for id: String in ["selys", "jelaqua", "moore", "seborn", "erin_solstice"]:
		assert_eq(_area_of(gs, id), "inn_interior", id)
	_talk_to(gs, "selys")
	ToyCanon.sleep_through(gs, _db, 143)
	assert_eq(gs.world.status(HAGGLE), Director.CHANGED)
	assert_true(gs.flags.has("halfseekers.earther_heard_the_lease_haggle"))
	for f: String in ["heartflame.hiss_activates", "heartflame.leased_to_halfseekers", "redfang.bronze_team_registered",
			"zel.buried_by_sserys_secretly", "heartflame.helm_riddle_known"]:
		assert_true(gs.flags.has(f), f)
