extends GutTest
## M32.2 (ADR 0044 "M32.2") on the real Book 6 data: Zel's last stand (4.48 - 4.49, day 130) is a fight stage on
## the new map invrisil_battlefield. Goblins, the undead, a lieutenant, then the Chosen: Bea, Ijvani and Oom, and last
## Venitra and Kerash. None of the Chosen can die on the map (escape). Two hooks: fighting beside Zel, and driving off
## Bea and Ijvani before the last wave while Zel stands (sets zel.saved_by_the_player). In M32.2 nothing reads that
## flag yet: Zel still dies. The game is slept to day 129 once (before_all); each test starts from a copy.

const SEED := 20261004
const DAY := 130
const FIELD := "invrisil_battlefield"
const BATTLE := "b6.the_battle_of_invrisil_opens"
const BREAK := "b6.zel_breaks_the_chosen_and_azkerash_comes"
const DEATH := "b6.zel_names_the_goblin_lord_reiss_and_dies"
const FIGHT_HOOK := "player_fought_beside_zel"
const SAVE_HOOK := "player_broke_bea_and_ijvani"
const SAVED := "zel.saved_by_the_player"
const ZEL := "zel_shivertail"
const CHOSEN := ["bea", "ijvani", "oom", "venitra", "kerash"]
const CHOSEN_WAVE := 4
const START := Vector2i(2, 11)

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


func _frozen() -> DataDb:
	var db := DataDb.load_dir()
	ToyCombat.freeze(db)
	return db


func _area_of(gs: GameState, id: String) -> String:
	var n: Dictionary = gs.npcs.npcs.get(id, {})
	return "" if n.is_empty() else String(n["area"])


func _hook_of(gs: GameState, id: String) -> String:
	var entry: Dictionary = gs.world.history.filter(func(h: Dictionary) -> bool: return h["event"] == id)[0]
	return str(entry.get("hook", ""))


func _wait_for_battle(gs: GameState, db: DataDb) -> void:
	gs.player.place(FIELD, START)
	Commands.settle(gs, db)
	for i in 120:
		if gs.world.staged.has(BATTLE):
			break
		assert_true(Commands.wait(gs, db, 600) >= 0, "wait")
	assert_true(gs.world.staged.has(BATTLE), "the battle is staged")


## Hostile stage foes on the map: type → monster id (the last one of each type).
func _foes(gs: GameState) -> Dictionary:
	var out := {}
	for id: String in gs.combat.ids():
		var m: Dictionary = gs.combat.monsters[id]
		if m["state"] == CombatState.HOSTILE and m.get("stage", "") == BATTLE:
			out[m["type"]] = id
	return out


## Every hostile stage foe on the map.
func _foe_ids(gs: GameState) -> Array[String]:
	var out: Array[String] = []
	for id: String in gs.combat.ids():
		var m: Dictionary = gs.combat.monsters[id]
		if m["state"] == CombatState.HOSTILE and m.get("stage", "") == BATTLE:
			out.append(id)
	return out


func _stage_foe(gs: GameState) -> String:
	var best := ""
	var best_d := 1 << 30
	for id: String in gs.combat.ids():
		var m: Dictionary = gs.combat.monsters[id]
		if m["state"] != CombatState.HOSTILE or m.get("stage", "") != BATTLE:
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


## Stages the battle, lets Zel's wave come, then skips the waves before the Chosen: the foes on the map are taken
## off and the next wave is the Chosen's. Returns the Chosen on the map (type → id).
func _to_the_chosen(gs: GameState, db: DataDb) -> Dictionary:
	_wait_for_battle(gs, db)
	FightBot.wait_seconds(gs, db, 20)
	assert_eq(_area_of(gs, ZEL), FIELD, "Zel is on the field")
	gs.combat.stage_run["next"] = CHOSEN_WAVE
	for id: String in _foe_ids(gs):
		gs.combat.monsters.erase(id)
	Stage.tick(gs, db)
	var foes := _foes(gs)
	for t: String in ["bea", "ijvani", "oom"]:
		assert_true(foes.has(t), t + " came")
	return foes


## Drives off every foe on the map, wave after wave, until the fight is over.
func _drive_off_the_rest(gs: GameState, db: DataDb) -> void:
	for i in 10:
		for id: String in _foe_ids(gs):
			if gs.combat.monsters.has(id):
				Combat.damage_monster(gs, db, id, 9999)
		Stage.tick(gs, db)
		Combat.settle_if_over(gs, db)
		if not gs.combat.has_fight():
			break
	assert_false(gs.combat.has_fight(), "the fight is over")


func test_the_stage_data_is_sound() -> void:
	var ev: Dictionary = _db.canon.events[BATTLE]
	var st: Dictionary = ev["stage"]
	assert_eq(st["area"], FIELD)
	assert_eq(st["kind"], "fight")
	assert_eq(st["protect"], ZEL)
	assert_true(int(st["hours"][0]) >= 6 and int(st["hours"][1]) <= 18, "daytime")
	assert_eq(int(ev["xp_window"]["boost"]), 3)
	assert_eq(ev["xp_window"]["hours"], st["hours"])
	assert_eq(int(ev["foreshadow"]["days_before"]), 3, "news of the march on days 127 - 129")
	var waves: Array = st["waves"]
	assert_eq(waves[CHOSEN_WAVE]["foes"], ["bea", "ijvani", "oom"])
	assert_eq(waves[-1]["foes"], ["venitra", "kerash"], "Venitra and Kerash come last")
	assert_true((waves[0]["allies"] as Array).has(ZEL), "Zel comes first")
	for w: Dictionary in waves:
		for a: String in w.get("allies", []):
			if a != ZEL:
				assert_ne(String(_db.canon.npcs[a].get("race", "")), "Drake", a + ": no Drakes fight beside Zel")
	var walk := func(p: Array) -> bool: return _db.maps.is_walkable(FIELD, Vector2i(int(p[0]), int(p[1])))
	for f: Dictionary in st["foes"]:
		assert_true(walk.call(f["pos"]), "foe tile %s" % [f["pos"]])
	for w: Dictionary in waves:
		assert_true(walk.call(w["from"]), "wave tile %s" % [w["from"]])
	for t: String in CHOSEN:
		assert_true(_db.combat.enemies[t].has("escape"), t + " cannot die on the map")
	assert_true(_db.canon.events[DEATH]["depends_on"].has(BREAK), "the save hook runs before Zel's death")


func test_the_field_links_to_the_invrisil_gate() -> void:
	var there := false
	for e: Dictionary in _db.maps.areas["invrisil_gate"]["exits"]:
		there = there or e["to"] == FIELD
	assert_true(there, "the gate road leads to the field")
	var back := false
	for e: Dictionary in _db.maps.areas[FIELD]["exits"]:
		back = back or e["to"] == "invrisil_gate"
	assert_true(back, "the field leads back")
	assert_eq(String(_db.maps.areas[FIELD]["location"]), "invrisil")
	var wake: Dictionary = _db.rules["combat"]["knockout"]["wake"]
	assert_eq(String(wake.get(FIELD, {}).get("area", "")), "invrisil_gate", "a knock-out wakes you at the gate")


func test_the_battle_opens_by_day_with_zel() -> void:
	var db := _frozen()
	var gs := _fresh()
	_wait_for_battle(gs, db)
	@warning_ignore("integer_division")
	var h: int = gs.clock.minute() / 60
	assert_true(h >= 9 and h < 15, "daytime")
	assert_eq(XpWindow.boost(gs, db), 3)
	FightBot.wait_seconds(gs, db, 20)
	for n: String in [ZEL, "thomast", "bethal"]:
		assert_eq(_area_of(gs, n), FIELD, n)


func test_the_battle_can_be_fought_through() -> void:
	var db := _frozen()
	ToyCombat.always_hit(db)
	var gs := _fresh()
	_wait_for_battle(gs, db)
	var seen := {}
	for i in 6000:
		if _stage_foe(gs) == "" and not gs.combat.has_fight():
			break
		_fight_turn(gs, db)
		for t: String in _foes(gs):
			seen[t] = true
	assert_eq(_stage_foe(gs), "", "the field is clear")
	for t: String in CHOSEN:
		assert_true(seen.has(t), t + " came")
	ToyCanon.sleep_through(gs, db, DAY)
	assert_eq(gs.world.status(BATTLE), Director.CHANGED)
	assert_eq(_hook_of(gs, BATTLE), FIGHT_HOOK)
	assert_true(gs.flags.has("invrisil.earther_fought_beside_zel"))
	assert_false(gs.world.is_alive(db.canon, ZEL), "M32.2: Zel still dies")
	for n: String in ["venitra", "ijvani", "bea", "kerash"]:
		assert_true(gs.world.is_alive(db.canon, n), n + " is not killed on the map")


func test_driving_off_bea_and_ijvani_with_zel_standing_saves_him_in_the_record() -> void:
	var db := _frozen()
	var gs := _fresh()
	var foes := _to_the_chosen(gs, db)
	Combat.damage_monster(gs, db, foes["bea"], 9999)
	Combat.damage_monster(gs, db, foes["ijvani"], 9999)
	var notes: Array = gs.combat.fight["driven_off"]
	assert_eq(notes.size(), 2)
	for n: Dictionary in notes:
		assert_true(n["protect_standing"], "Zel stands")
		assert_true(n["waves_left"], "Venitra and Kerash have not come")
	_drive_off_the_rest(gs, db)
	ToyCanon.sleep_through(gs, db, DAY)
	assert_eq(gs.world.status(BREAK), Director.CHANGED)
	assert_eq(_hook_of(gs, BREAK), SAVE_HOOK)
	assert_true(gs.flags.has(SAVED))
	assert_false(gs.world.is_alive(db.canon, ZEL), "nothing reads the flag yet (M32.4 does)")
	assert_eq(gs.world.status(DEATH), Director.DONE)


func test_with_zel_down_the_flag_is_not_set() -> void:
	var db := _frozen()
	var gs := _fresh()
	var foes := _to_the_chosen(gs, db)
	gs.npcs.npcs[ZEL]["down"] = true
	Combat.damage_monster(gs, db, foes["bea"], 9999)
	Combat.damage_monster(gs, db, foes["ijvani"], 9999)
	_drive_off_the_rest(gs, db)
	ToyCanon.sleep_through(gs, db, DAY)
	assert_eq(gs.world.status(BREAK), Director.DONE)
	assert_false(gs.flags.has(SAVED))


func test_after_the_last_wave_it_is_too_late() -> void:
	var db := _frozen()
	var gs := _fresh()
	var foes := _to_the_chosen(gs, db)
	gs.combat.stage_run["next"] = (_db.canon.events[BATTLE]["stage"]["waves"] as Array).size()
	Combat.damage_monster(gs, db, foes["bea"], 9999)
	Combat.damage_monster(gs, db, foes["ijvani"], 9999)
	_drive_off_the_rest(gs, db)
	ToyCanon.sleep_through(gs, db, DAY)
	assert_false(gs.flags.has(SAVED), "no waves were left")


func test_driving_off_only_bea_is_not_enough() -> void:
	var db := _frozen()
	var gs := _fresh()
	var foes := _to_the_chosen(gs, db)
	Combat.damage_monster(gs, db, foes["bea"], 9999)
	gs.combat.stage_run["next"] = (_db.canon.events[BATTLE]["stage"]["waves"] as Array).size()
	_drive_off_the_rest(gs, db)
	ToyCanon.sleep_through(gs, db, DAY)
	assert_false(gs.flags.has(SAVED), "Ijvani went after the last wave")


func test_staying_away_keeps_the_canon() -> void:
	var gs := _fresh()
	ToyCanon.sleep_through(gs, _db, DAY)
	assert_eq(gs.world.status(BATTLE), Director.DONE)
	assert_eq(gs.world.status(BREAK), Director.DONE)
	assert_false(gs.flags.has(SAVED))
	assert_false(gs.flags.has("invrisil.earther_fought_beside_zel"))
	assert_false(gs.world.is_alive(_db.canon, ZEL))
