extends GutTest
## M13.5 on the real Book 5 data (4.18 – 4.19, days 106–109). Two scenes and
## a fight: Erin plays the unseen chess opponent into the night (day 107),
## Halrac teaches Bird his new bow on the hill while the building starts
## (day 108), and the undead climb out of the rift onto the Floodplains
## (day 109, Griffon Hunt helps). A player who joins in changes each event.
## Ryoka and Mrsha are home again from day 107.
## The game is slept to the morning of day 106 once (before_all); each test
## starts from a copy of that save.

const SEED := 20260928
const DAY := 106
const CHESS := "b5.zzd_erin_plays_the_unseen_chess_opponent_all_night"
const BOW := "b5.zzf_erin_buys_bird_a_bow_and_halrac_teaches_him"
const UNDEAD := "b5.zzl_undead_climb_out_of_the_rift"
const INN_SPOT := Vector2i(10, 10)
const HILL_SPOT := Vector2i(15, 13)
const PLAIN_SPOT := Vector2i(16, 8)

var _db: DataDb
var _day106 := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])
	var gs := GameState.new_game(SEED, _db)
	ToyCanon.sleep_through(gs, _db, DAY - 1)
	_day106 = gs.to_json()


func _copy(day: int, db: DataDb = null) -> GameState:
	var d := _db if db == null else db
	var gs := GameState.from_json(_day106)
	ToyCanon.sleep_through(gs, d, day - 1)
	assert_eq(gs.clock.day(), day)
	return gs


## Stands at `pos` in `area` and waits (10 minutes a step, up to 20 hours)
## until the event's stage starts.
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


func _hour(gs: GameState) -> int:
	@warning_ignore("integer_division")
	return gs.clock.minute() / 60


func _hook_of(gs: GameState, id: String) -> String:
	var entry: Dictionary = gs.world.history.filter(func(h: Dictionary) -> bool: return h["event"] == id)[0]
	return str(entry.get("hook", ""))


func _assert_changed(gs: GameState, id: String, hook: String, flag: String, canon_flag: String) -> void:
	assert_eq(gs.world.status(id), Director.CHANGED, id)
	assert_eq(_hook_of(gs, id), hook)
	assert_true(gs.flags.has(flag), flag)
	assert_true(gs.flags.has(canon_flag), "the canon still happens: " + canon_flag)
	var texts := gs.world.news.map(func(n: Dictionary) -> String: return n["text"])
	assert_true(texts.has(_db.canon.events[id]["hooks"][0]["news"]), "the hook's news")


## Walks next to `npc` and runs `action` with them.
func _do_with(gs: GameState, npc: String, action: String, location: String) -> void:
	var n: Dictionary = gs.npcs.npcs[npc]
	var at := Vector2i(int(n["x"]), int(n["y"]))
	var sides := {at + Vector2i(1, 0): true, at + Vector2i(-1, 0): true, at + Vector2i(0, 1): true, at + Vector2i(0, -1): true}
	if not sides.has(gs.player.pos()):
		assert_true(ToyMaps.walk_to(gs, _db, sides), "walk to " + npc)
	var r := Commands.interact(gs, _db, npc, action)
	assert_eq(r["error"], "")
	assert_eq(r["record"]["context"]["location"], location)


func _stage_foe(gs: GameState) -> String:
	var best := ""
	var best_d := 1 << 30
	for id: String in gs.combat.ids():
		var m: Dictionary = gs.combat.monsters[id]
		if m["state"] != CombatState.HOSTILE or m.get("stage", "") != UNDEAD:
			continue
		var d := CombatState.pos_of(m) - gs.player.pos()
		if absi(d.x) + absi(d.y) < best_d:
			best_d = absi(d.x) + absi(d.y)
			best = id
	return best


## One step toward the nearest undead, or a blow when next to it. Walks to
## the four side squares only (a diagonal square never attacks).
func _fight_turn(gs: GameState, db: DataDb) -> void:
	var id := _stage_foe(gs)
	if id == "":
		Commands.wait(gs, db, 6)
		return
	var at := CombatState.pos_of(gs.combat.monsters[id])
	var d := at - gs.player.pos()
	if absi(d.x) + absi(d.y) == 1:
		Commands.attack(gs, db, "e" if d.x > 0 else "w" if d.x < 0 else "s" if d.y > 0 else "n")
		return
	var sides := {at + Vector2i(1, 0): true, at + Vector2i(-1, 0): true, at + Vector2i(0, 1): true, at + Vector2i(0, -1): true}
	var path := Pathfind.path(db.maps, gs.player.area, gs.player.pos(), sides, MonsterSim.taken(gs, ""))
	if path["found"] and not (path["steps"] as Array).is_empty():
		Commands.move(gs, db, path["steps"][0])
	else:
		Commands.wait(gs, db, 6)


func test_the_stages_are_loaded() -> void:
	assert_eq(_db.canon.events[CHESS]["stage"]["area"], "inn_interior")
	assert_eq(_db.canon.events[BOW]["stage"]["area"], "inn_hill")
	assert_eq(_db.canon.events[UNDEAD]["stage"]["area"], "floodplains_south")
	for id: String in [CHESS, BOW, UNDEAD]:
		assert_has(_db.canon.stages, id)
	for id: String in [CHESS, BOW]:
		var st: Dictionary = _db.canon.events[id]["stage"]
		assert_eq(st["kind"], "scene", id)
		for n: Dictionary in st["npcs"]:
			assert_true(_db.behaviour.npcs.has(n["npc"]), "%s can be placed by %s" % [n["npc"], id])
	for w: Dictionary in _db.canon.events[UNDEAD]["stage"]["waves"]:
		for npc: String in w.get("allies", []):
			assert_true(_db.behaviour.npcs.has(npc), npc + " can be placed")
			assert_true(_db.behaviour.npcs[npc].has("combat"), npc + " can fight")
		for foe: String in w.get("foes", []):
			assert_true(_db.combat.enemies.has(foe), foe)


func test_ryoka_and_mrsha_are_home_from_day_107() -> void:
	var gs := _copy(106)
	assert_true(gs.flags.has("ryoka.away_at_the_strongheart_farm"), "still away on day 106")
	ToyCanon.sleep_through(gs, _db, 106)
	for f: String in ["ryoka.away_at_the_strongheart_farm", "mrsha.away_at_the_strongheart_farm"]:
		assert_false(gs.flags.has(f), f)
	assert_true(gs.flags.has("ryoka.home_at_the_wandering_inn"))
	gs.player.place("inn_interior", INN_SPOT)
	Commands.settle(gs, _db)
	while _hour(gs) < 19:
		assert_true(Commands.wait(gs, _db, 1800) >= 0, "wait")
	for npc: String in ["ryoka_griffin", "mrsha"]:
		assert_eq(_area_of(gs, npc), "inn_interior", npc + " is back at the inn")


func test_the_chess_marathon_is_on_the_evening_of_day_107() -> void:
	var gs := _copy(107)
	_wait_for(gs, _db, CHESS, "inn_interior", INN_SPOT)
	assert_true(_hour(gs) >= 17, "evening")
	for npc: String in ["erin_solstice", "pawn", "olesm", "anand"]:
		assert_eq(_area_of(gs, npc), "inn_interior", npc)


func test_watching_the_chess_changes_the_night() -> void:
	var gs := _copy(107)
	_wait_for(gs, _db, CHESS, "inn_interior", INN_SPOT)
	_do_with(gs, "olesm", "talk_with_guest", "wandering_inn")
	ToyCanon.sleep_through(gs, _db, 107)
	_assert_changed(gs, CHESS, "player_watched_erins_chess_marathon",
			"wandering_inn.earther_watched_the_chess_marathon", "erin.played_the_unseen_opponent_all_night")
	assert_true(gs.world.relationship("olesm", NpcSim.PLAYER) >= 1)


func test_halrac_teaches_bird_on_the_hill_on_day_108() -> void:
	var gs := _copy(108)
	_wait_for(gs, _db, BOW, "inn_hill", HILL_SPOT)
	var h := _hour(gs)
	assert_true(h >= 14 and h < 17, "afternoon")
	for npc: String in ["bird", "halrac", "pawn"]:
		assert_eq(_area_of(gs, npc), "inn_hill", npc)
	ToyCanon.sleep_through(gs, _db, 108)
	for f: String in ["wandering_inn.expansion_begun", "bird.has_a_yew_bow", "erin.asked_brunkr_to_train_lyonette"]:
		assert_true(gs.flags.has(f), f)


func test_talking_with_halrac_changes_the_lesson() -> void:
	var gs := _copy(108)
	_wait_for(gs, _db, BOW, "inn_hill", HILL_SPOT)
	_do_with(gs, "halrac", "talk_with_guest", "wandering_inn")
	ToyCanon.sleep_through(gs, _db, 108)
	_assert_changed(gs, BOW, "player_watched_bird_learn_the_bow",
			"wandering_inn.earther_watched_bird_learn_the_bow", "bird.has_a_yew_bow")
	assert_true(gs.world.relationship("halrac", NpcSim.PLAYER) >= 1)


func test_the_undead_climb_out_on_day_109_and_griffon_hunt_comes() -> void:
	var gs := _copy(109)
	_wait_for(gs, _db, UNDEAD, "floodplains_south", PLAIN_SPOT)
	var h := _hour(gs)
	assert_true(h >= 15 and h < 19, "late afternoon")
	var foes := gs.combat.ids().filter(func(id: String) -> bool: return gs.combat.monsters[id].get("stage", "") == UNDEAD)
	assert_eq(foes.size(), 4)
	Commands.wait(gs, _db, 6)
	for npc: String in ["halrac", "revi", "typhenous"]:
		assert_eq(_area_of(gs, npc), "floodplains_south", npc)


func test_fighting_the_undead_changes_the_event() -> void:
	var db := DataDb.load_dir()
	ToyCombat.freeze(db)
	ToyCombat.always_hit(db)
	var gs := _copy(109, db)
	_wait_for(gs, db, UNDEAD, "floodplains_south", PLAIN_SPOT)
	for i in 4000:
		if _stage_foe(gs) == "" and not gs.combat.has_fight():
			break
		_fight_turn(gs, db)
	assert_eq(_stage_foe(gs), "", "the undead are down")
	ToyCanon.sleep_through(gs, db, 109)
	assert_eq(gs.world.status(UNDEAD), Director.CHANGED)
	assert_eq(_hook_of(gs, UNDEAD), "player_fought_the_rift_undead")
	assert_true(gs.flags.has("floodplains.earther_fought_the_rift_undead"))
	assert_true(gs.flags.has("liscor_dungeon.undead_climbed_out_of_the_rift"), "the canon still happens")
	assert_true(gs.world.relationship("halrac", NpcSim.PLAYER) >= 2)


func test_no_undead_fight_on_day_108() -> void:
	var gs := _copy(108)
	gs.player.place("floodplains_south", PLAIN_SPOT)
	Commands.settle(gs, _db)
	for i in 14:
		Commands.wait(gs, _db, 3600)
		assert_false(gs.world.staged.has(UNDEAD))
