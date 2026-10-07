extends GutTest
## M19.4 on the real Book 7 data (5.07, 5.08, Interlude - Flos, day 137): Pallass opens the
## door, the Face-Eater Moths attack (a fight stage on inn_hill with waves and an XP window x3),
## and that night a scene in the inn lets the player sit with the wounded. The game is slept
## to day 136 once (before_all); each test starts from a copy of that save.

const SEED := 20261009
const DAY := 137
const GOATS := "b7.face_eater_moths_attack_the_inn_and_liscor"
const FEAST := "b7.the_inn_after_the_moths"
const HILL_SPOT := Vector2i(16, 13)
const INN_SPOT := Vector2i(3, 3)

var _db: DataDb
var _base := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])
	assert_eq(_db.canon.errors, [] as Array[String])
	var gs := GameState.new_game(SEED, _db)
	ToyCanon.sleep_through(gs, _db, DAY - 1)
	_base = gs.to_json()


func _fresh() -> GameState:
	var gs := GameState.from_json(_base)
	assert_eq(gs.clock.day(), DAY)
	return gs


func _wait_for(gs: GameState, db: DataDb, event: String, area: String, pos: Vector2i) -> void:
	gs.player.place(area, pos)
	Commands.settle(gs, db)
	for i in 120:
		if gs.world.staged.has(event):
			break
		assert_true(Commands.wait(gs, db, 600) >= 0, "wait")
	assert_true(gs.world.staged.has(event), "%s is staged" % event)


func _area_of(gs: GameState, id: String) -> String:
	var n: Dictionary = gs.npcs.npcs.get(id, {})
	return "" if n.is_empty() else String(n["area"])


func _hook_of(gs: GameState, id: String) -> String:
	var entry: Dictionary = gs.world.history.filter(func(h: Dictionary) -> bool: return h["event"] == id)[0]
	return str(entry.get("hook", ""))


func _stage_foe(gs: GameState) -> String:
	var best := ""
	var best_d := 1 << 30
	for id: String in gs.combat.ids():
		var m: Dictionary = gs.combat.monsters[id]
		if m["state"] != CombatState.HOSTILE or m.get("stage", "") != GOATS:
			continue
		var d := CombatState.pos_of(m) - gs.player.pos()
		if absi(d.x) + absi(d.y) < best_d:
			best_d = absi(d.x) + absi(d.y)
			best = id
	return best


func _fight_turn(gs: GameState, db: DataDb) -> void:
	var id := _stage_foe(gs)
	if id == "":
		Commands.wait(gs, db, 6)
		return
	var at := CombatState.pos_of(gs.combat.monsters[id])
	var d := at - gs.player.pos()
	if absi(d.x) + absi(d.y) == 1:
		FightBot.attack(gs, db, "e" if d.x > 0 else "w" if d.x < 0 else "s" if d.y > 0 else "n")
		return
	var sides := {at + Vector2i(1, 0): true, at + Vector2i(-1, 0): true, at + Vector2i(0, 1): true, at + Vector2i(0, -1): true}
	var path := Pathfind.path(db.maps, gs.player.area, gs.player.pos(), sides, MonsterSim.taken(gs, ""))
	if path["found"] and not (path["steps"] as Array).is_empty():
		FightBot.move(gs, db, path["steps"][0])
	else:
		Commands.wait(gs, db, 6)


func _talk_to(gs: GameState, id: String) -> void:
	var n: Dictionary = gs.npcs.npcs[id]
	var at := Vector2i(int(n["x"]), int(n["y"]))
	var sides := {at + Vector2i(1, 0): true, at + Vector2i(-1, 0): true, at + Vector2i(0, 1): true, at + Vector2i(0, -1): true}
	assert_true(ToyMaps.walk_to(gs, _db, sides), "walk to " + id)
	var r := Commands.interact(gs, _db, id, "talk_with_guest")
	assert_eq(r["error"], "")


func test_the_data_is_loaded() -> void:
	for id: String in [GOATS, FEAST, "b7.pallass_opens_the_door_and_lifts_the_embargo", "b7.pisces_falene_and_moore_call_down_a_great_rain",
			"b7.flos_speaks_to_the_whole_world"]:
		assert_true(_db.canon.events.has(id), id)
	var ev: Dictionary = _db.canon.events[GOATS]
	assert_eq(ev["stage"]["area"], "inn_hill")
	assert_eq(ev["stage"]["kind"], "fight")
	assert_eq(ev["xp_window"]["boost"], 3)
	assert_true((ev["stage"]["waves"] as Array).size() >= 6)
	for w: Dictionary in ev["stage"]["waves"]:
		for a: String in w.get("allies", []):
			assert_true(_db.behaviour.npcs.has(a), a)
			assert_true(_db.behaviour.npcs[a].has("combat"), a + " has combat")


func test_the_moths_come_after_midday_with_the_allies() -> void:
	var db := DataDb.load_dir()
	ToyCombat.freeze(db)
	var gs := _fresh()
	_wait_for(gs, db, GOATS, "inn_hill", HILL_SPOT)
	@warning_ignore("integer_division")
	var h: int = gs.clock.minute() / 60
	assert_true(h >= 13 and h < 20, "afternoon")
	var moths := gs.combat.ids().filter(func(id: String) -> bool: return gs.combat.monsters[id].get("stage", "") == GOATS)
	assert_true(moths.size() >= 3, "moths on the map")
	assert_eq(gs.combat.monsters[moths[0]]["type"], "moth_swarm")
	FightBot.wait_seconds(gs, db, 6)
	for n: String in ["erin_solstice", "jelaqua", "headscratcher", "numbtongue"]:
		assert_eq(_area_of(gs, n), "inn_hill", n)


func test_fighting_the_moths_changes_the_event() -> void:
	var db := DataDb.load_dir()
	ToyCombat.freeze(db)
	ToyCombat.always_hit(db)
	var gs := _fresh()
	_wait_for(gs, db, GOATS, "inn_hill", HILL_SPOT)
	for i in 4000:
		if _stage_foe(gs) == "" and not gs.combat.has_fight():
			break
		_fight_turn(gs, db)
	assert_eq(_stage_foe(gs), "", "the moths are down")
	ToyCanon.sleep_through(gs, db, DAY)
	assert_eq(gs.world.status(GOATS), Director.CHANGED)
	assert_eq(_hook_of(gs, GOATS), "player_fought_the_face_eater_moths")
	assert_true(gs.flags.has("wandering_inn.earther_fought_the_moths"))
	assert_true(gs.flags.has("jelaqua.body_broken"), "the canon still happens")
	assert_true(gs.world.relationship("erin_solstice", NpcSim.PLAYER) >= 2)


func test_staying_away_still_breaks_the_inn_and_opens_the_pallass_door() -> void:
	var gs := _fresh()
	ToyCanon.sleep_through(gs, _db, DAY)
	assert_eq(gs.world.status(GOATS), Director.DONE)
	assert_false(gs.flags.has("wandering_inn.earther_fought_the_moths"))
	for f: String in ["wandering_inn.serves_wine", "pallass.embargo_lifted", "albez_door.anchor_at_pallass",
			"wandering_inn.windows_broken", "wandering_inn.watchtower_smashed", "jelaqua.body_broken",
			"jelaqua.body_cannot_be_saved", "liscor_dungeon.gold_rank", "pisces.hailed_as_a_hero",
			"hive.painted_soldiers_seen_by_the_world", "flos.watched_the_liscor_battle"]:
		assert_true(gs.flags.has(f), f)
	assert_false(gs.flags.has("pallass.embargo_of_liscor_begun"), "the embargo flag is cleared")
	assert_true(gs.flags.has("izril.rains"))
	assert_true(gs.world.is_alive(_db.canon, "jelaqua"))
	assert_true(gs.world.is_alive(_db.canon, "bird"))
	ToyCanon.sleep_through(gs, _db, DAY + 1)
	for f: String in ["flos.broadcast_to_the_world", "nawalishifra.swore_to_forge_a_blade"]:
		assert_true(gs.flags.has(f), f)


func test_the_wounded_sit_in_the_inn_that_night() -> void:
	var gs := _fresh()
	_wait_for(gs, _db, FEAST, "inn_interior", INN_SPOT)
	@warning_ignore("integer_division")
	var h: int = gs.clock.minute() / 60
	assert_true(h >= 20 and h < 24, "night")
	for n: String in ["bird", "jelaqua", "moore", "numbtongue"]:
		assert_eq(_area_of(gs, n), "inn_interior", n)


func test_talking_to_jelaqua_changes_the_scene() -> void:
	var gs := _fresh()
	_wait_for(gs, _db, FEAST, "inn_interior", INN_SPOT)
	_talk_to(gs, "jelaqua")
	ToyCanon.sleep_through(gs, _db, DAY)
	assert_eq(gs.world.status(FEAST), Director.CHANGED)
	assert_true(gs.flags.has("wandering_inn.earther_sat_with_the_wounded"))
	assert_true(gs.flags.has("wandering_inn.wounded_rest_after_the_moths"), "the scene happens either way")
