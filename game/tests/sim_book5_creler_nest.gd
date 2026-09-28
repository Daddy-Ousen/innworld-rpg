extends GutTest
## M13.6 on the real Book 5 data (4.24 – 4.27 H, days 110–111). Two fights
## and two scenes: a Razorbeak goes for Mrsha on the inn hill (day 110
## morning), Brunkr trains Lyonette and she knights him (day 110 afternoon),
## Hawk brings word that the Drake armies fell (day 110 night), and the Horns
## burn a Creler nest in a cave past Esthelm (day 111). A player who joins in
## changes each event.
## The game is slept to the morning of day 110 once (before_all); each test
## starts from a copy of that save.

const SEED := 20260928
const DAY := 110
const RAZORBEAK := "b5.zzzc_a_razorbeak_tries_to_carry_off_mrsha"
const LESSON := "b5.zzzg_brunkr_trains_lyonette_and_she_knights_him"
const NEWS := "b5.zzzk_hawk_brings_word_the_drake_armies_fell"
const NEST := "b5.zzzzc_the_horns_burn_a_creler_nest"
const INN_SPOT := Vector2i(10, 10)
const HILL_SPOT := Vector2i(15, 13)
const CAVE_SPOT := Vector2i(8, 11)

var _db: DataDb
var _day110 := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])
	var gs := GameState.new_game(SEED, _db)
	ToyCanon.sleep_through(gs, _db, DAY - 1)
	_day110 = gs.to_json()


func _copy(day: int, db: DataDb = null) -> GameState:
	var d := _db if db == null else db
	var gs := GameState.from_json(_day110)
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


## Waits in the inn (out of the cold and away from the morning Razorbeak)
## until `hour`.
func _wait_indoors_until(gs: GameState, hour: int) -> void:
	gs.player.place("inn_interior", INN_SPOT)
	Commands.settle(gs, _db)
	for i in 48:
		if _hour(gs) >= hour:
			break
		assert_true(Commands.wait(gs, _db, 1800) >= 0, "wait")
	assert_true(_hour(gs) >= hour, "it is %d:00" % hour)


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


func _stage_foes(gs: GameState, event: String) -> Array:
	return gs.combat.ids().filter(func(id: String) -> bool:
		var m: Dictionary = gs.combat.monsters[id]
		return m["state"] == CombatState.HOSTILE and m.get("stage", "") == event)


func _stage_foe(gs: GameState, event: String) -> String:
	var best := ""
	var best_d := 1 << 30
	for id: String in _stage_foes(gs, event):
		var d := CombatState.pos_of(gs.combat.monsters[id]) - gs.player.pos()
		if absi(d.x) + absi(d.y) < best_d:
			best_d = absi(d.x) + absi(d.y)
			best = id
	return best


## One step toward the nearest stage foe, or a blow when next to it. Walks to
## the four side squares only (a diagonal square never attacks).
func _fight_turn(gs: GameState, db: DataDb, event: String) -> void:
	var id := _stage_foe(gs, event)
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


func _fight_out(gs: GameState, db: DataDb, event: String) -> void:
	for i in 4000:
		if _stage_foe(gs, event) == "" and not gs.combat.has_fight():
			break
		_fight_turn(gs, db, event)
	assert_eq(_stage_foe(gs, event), "", "the foes are down")


func _frozen_db() -> DataDb:
	var db := DataDb.load_dir()
	ToyCombat.freeze(db)
	ToyCombat.always_hit(db)
	return db


func test_the_stages_are_loaded() -> void:
	assert_eq(_db.canon.events[RAZORBEAK]["stage"]["area"], "inn_hill")
	assert_eq(_db.canon.events[LESSON]["stage"]["area"], "inn_hill")
	assert_eq(_db.canon.events[NEWS]["stage"]["area"], "inn_interior")
	assert_eq(_db.canon.events[NEST]["stage"]["area"], "esthelm_creler_cave")
	for id: String in [RAZORBEAK, LESSON, NEWS, NEST]:
		assert_has(_db.canon.stages, id)
	for id: String in [LESSON, NEWS]:
		var st: Dictionary = _db.canon.events[id]["stage"]
		assert_eq(st["kind"], "scene", id)
		for n: Dictionary in st["npcs"]:
			assert_true(_db.behaviour.npcs.has(n["npc"]), "%s can be placed by %s" % [n["npc"], id])
	for id: String in [RAZORBEAK, NEST]:
		for w: Dictionary in _db.canon.events[id]["stage"]["waves"]:
			for npc: String in w.get("allies", []):
				assert_true(_db.behaviour.npcs.has(npc), npc + " can be placed")
				assert_true(_db.behaviour.npcs[npc].has("combat"), npc + " can fight")
			for foe: String in w.get("foes", []):
				assert_true(_db.combat.enemies.has(foe), foe)


func test_the_razorbeak_comes_on_the_morning_of_day_110() -> void:
	var gs := _copy(110)
	_wait_for(gs, _db, RAZORBEAK, "inn_hill", HILL_SPOT)
	var h := _hour(gs)
	assert_true(h >= 7 and h < 11, "morning")
	assert_eq(_stage_foes(gs, RAZORBEAK).size(), 1)


func test_fighting_the_razorbeak_changes_the_event() -> void:
	var db := _frozen_db()
	var gs := _copy(110, db)
	_wait_for(gs, db, RAZORBEAK, "inn_hill", HILL_SPOT)
	_fight_out(gs, db, RAZORBEAK)
	ToyCanon.sleep_through(gs, db, 110)
	assert_eq(gs.world.status(RAZORBEAK), Director.CHANGED)
	assert_eq(_hook_of(gs, RAZORBEAK), "player_drove_off_the_razorbeak")
	assert_true(gs.flags.has("wandering_inn.earther_saved_mrsha_from_a_razorbeak"))
	assert_true(gs.flags.has("mrsha.snatched_at_by_a_razorbeak"), "the canon still happens")
	assert_true(gs.world.relationship("mrsha", NpcSim.PLAYER) >= 2)


func test_brunkr_trains_lyonette_on_the_hill_on_day_110() -> void:
	var gs := _copy(110)
	_wait_indoors_until(gs, 13)
	_wait_for(gs, _db, LESSON, "inn_hill", HILL_SPOT)
	var h := _hour(gs)
	assert_true(h >= 13 and h < 17, "afternoon")
	for npc: String in ["brunkr", "lyonette", "ishkr", "mrsha"]:
		assert_eq(_area_of(gs, npc), "inn_hill", npc)


func test_talking_with_brunkr_changes_the_lesson_and_he_wakes_a_knight() -> void:
	var gs := _copy(110)
	_wait_indoors_until(gs, 13)
	_wait_for(gs, _db, LESSON, "inn_hill", HILL_SPOT)
	_do_with(gs, "brunkr", "talk_with_guest", "wandering_inn")
	ToyCanon.sleep_through(gs, _db, 111)
	_assert_changed(gs, LESSON, "player_watched_brunkr_train_lyonette",
			"wandering_inn.earther_watched_brunkr_train_lyonette", "lyonette.swore_brunkr_as_a_knight")
	assert_true(gs.world.relationship("brunkr", NpcSim.PLAYER) >= 1)
	for f: String in ["brunkr.class_knight", "brunkr.arm_healed"]:
		assert_true(gs.flags.has(f), f)
	assert_false(gs.flags.has("brunkr.hand_infected"))


func test_hawk_brings_the_news_on_the_night_of_day_110() -> void:
	var gs := _copy(110)
	_wait_indoors_until(gs, 19)
	_wait_for(gs, _db, NEWS, "inn_interior", INN_SPOT)
	assert_true(_hour(gs) >= 19, "night")
	for npc: String in ["hawk", "zel_shivertail", "erin_solstice", "ryoka_griffin"]:
		assert_eq(_area_of(gs, npc), "inn_interior", npc)
	_do_with(gs, "hawk", "comfort_someone", "wandering_inn")
	ToyCanon.sleep_through(gs, _db, 110)
	_assert_changed(gs, NEWS, "player_heard_the_news_from_the_south",
			"wandering_inn.earther_heard_the_armies_fell", "liscor.knows_the_drake_armies_fell")
	for f: String in ["liscor.prepares_for_a_siege", "drake_cities.warned_of_the_goblin_lord", "venitra.disguised_as_regrika_blackpaw"]:
		assert_true(gs.flags.has(f), f)


func test_the_cave_track_opens_once_the_horns_take_work_near_esthelm() -> void:
	var track: Array = _db.maps.areas["esthelm_ruins"]["exits"].filter(
			func(e: Dictionary) -> bool: return e["to"] == "esthelm_creler_cave")
	assert_eq(track.size(), 1)
	var flag: String = track[0]["when_flags"][0]
	var gs := _copy(110)
	assert_false(gs.flags.has(flag), "closed on day 110")
	ToyCanon.sleep_through(gs, _db, 110)
	assert_true(gs.flags.has(flag), "open on day 111")


func test_the_horns_fight_the_crelers_on_day_111() -> void:
	var gs := _copy(111)
	_wait_for(gs, _db, NEST, "esthelm_creler_cave", CAVE_SPOT)
	assert_true(_hour(gs) >= 13, "afternoon")
	assert_eq(_stage_foes(gs, NEST).size(), 6)
	Commands.wait(gs, _db, 6)
	for npc: String in ["ceria_springwalker", "pisces", "yvlon_byres", "ksmvr"]:
		assert_eq(_area_of(gs, npc), "esthelm_creler_cave", npc)


func test_fighting_the_crelers_changes_the_event() -> void:
	var db := _frozen_db()
	var gs := _copy(111, db)
	_wait_for(gs, db, NEST, "esthelm_creler_cave", CAVE_SPOT)
	_fight_out(gs, db, NEST)
	ToyCanon.sleep_through(gs, db, 111)
	assert_eq(gs.world.status(NEST), Director.CHANGED)
	assert_eq(_hook_of(gs, NEST), "player_fought_the_creler_nest")
	assert_true(gs.flags.has("esthelm.earther_fought_the_creler_nest"))
	assert_true(gs.flags.has("horns_of_hammerad.burned_a_creler_nest"), "the canon still happens")
	assert_true(gs.world.relationship("yvlon_byres", NpcSim.PLAYER) >= 2)


func test_no_creler_fight_on_day_110() -> void:
	var gs := _copy(110)
	gs.player.place("esthelm_creler_cave", CAVE_SPOT)
	Commands.settle(gs, _db)
	for i in 14:
		Commands.wait(gs, _db, 3600)
		assert_false(gs.world.staged.has(NEST))
