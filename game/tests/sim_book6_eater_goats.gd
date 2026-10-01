extends GutTest
## M18.3 on the real Book 6 data (4.33 – 4.34, day 115): the Eater Goats attack
## Wirclaw's village. A fight stage with waves puts the Redfang Hobgoblins, Erin and
## Wirclaw beside the player. Bugear dies as the event's effect. In the evening a scene
## in the inn feeds the Redfang; a player who talks with them changes that event. The
## game is slept to day 114 once (before_all); each test starts from a copy of that save.

const SEED := 20261001
const DAY := 115
const GOATS := "b6.eater_goats_attack_wirclaws_village"
const FEAST := "b6.erin_bows_to_the_redfang_and_feeds_them"
const VILLAGE_SPOT := Vector2i(30, 11)
const INN_SPOT := Vector2i(14, 13)
const RED5: Array[String] = ["badarrow", "headscratcher", "shorthilt", "rabbiteater", "numbtongue"]

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


func test_the_data_is_loaded() -> void:
	for id: String in [GOATS, FEAST, "b6.bird_loses_an_archery_duel_to_badarrow", "b6.zevara_backs_down_on_zels_order",
			"b6.redfang_sleep_in_the_inn_basement", "b6.lyonette_wakes_in_the_quiet_inn"]:
		assert_true(_db.canon.events.has(id), id)
	var st: Dictionary = _db.canon.events[GOATS]["stage"]
	assert_eq(st["area"], "wirclaw_village")
	assert_false(_db.canon.events[GOATS].has("xp_window"))
	for n: String in RED5 + ["wirclaw", "erin_solstice", "bird"]:
		assert_true(_db.behaviour.npcs.has(n), n)
	assert_true(_db.canon.npcs["bugear"]["tags"].has("sword"))
	assert_false(_db.canon.npcs["bugear"]["tags"].has("spear"))


func test_the_goats_come_to_the_village_by_day_with_the_redfang() -> void:
	var db := DataDb.load_dir()
	ToyCombat.freeze(db)
	var gs := _fresh()
	_wait_for(gs, db, GOATS, "wirclaw_village", VILLAGE_SPOT)
	@warning_ignore("integer_division")
	var h: int = gs.clock.minute() / 60
	assert_true(h >= 12 and h < 17, "daytime")
	var goats := gs.combat.ids().filter(func(id: String) -> bool: return gs.combat.monsters[id].get("stage", "") == GOATS)
	# Four goats are placed; an ally may have downed one before the first look.
	assert_true(goats.size() >= 3 and goats.size() <= 4, "goats on the map")
	assert_eq(gs.combat.monsters[goats[0]]["type"], "eater_goat")
	FightBot.wait_seconds(gs, db, 6)
	for n: String in RED5 + ["erin_solstice", "wirclaw"]:
		assert_eq(_area_of(gs, n), "wirclaw_village", n)
	assert_true(gs.world.is_alive(db.canon, "bugear"), "Bugear dies at the end of the day, not in the stage")


func test_fighting_the_goats_changes_the_event() -> void:
	var db := DataDb.load_dir()
	ToyCombat.freeze(db)
	ToyCombat.always_hit(db)
	var gs := _fresh()
	_wait_for(gs, db, GOATS, "wirclaw_village", VILLAGE_SPOT)
	for i in 3000:
		if _stage_foe(gs) == "" and not gs.combat.has_fight():
			break
		_fight_turn(gs, db)
	assert_eq(_stage_foe(gs), "", "the goats are down")
	ToyCanon.sleep_through(gs, db, DAY)
	assert_eq(gs.world.status(GOATS), Director.CHANGED)
	assert_eq(_hook_of(gs, GOATS), "player_fought_the_eater_goats")
	assert_true(gs.flags.has("wirclaw_village.earther_fought_the_eater_goats"))
	assert_true(gs.flags.has("wirclaw_village.eater_goats_killed"), "the canon still happens")
	assert_false(gs.world.is_alive(db.canon, "bugear"), "Bugear dies either way")
	for n: String in ["headscratcher", "badarrow", "shorthilt", "rabbiteater", "numbtongue"]:
		assert_true(gs.world.is_alive(db.canon, n), n)
	assert_true(gs.world.relationship("erin_solstice", NpcSim.PLAYER) >= 2)
	assert_true(gs.world.relationship("headscratcher", NpcSim.PLAYER) >= 2)


func test_staying_away_still_kills_bugear_and_brings_the_redfang_to_the_inn() -> void:
	var gs := _fresh()
	ToyCanon.sleep_through(gs, _db, DAY)
	assert_eq(gs.world.status(GOATS), Director.DONE)
	assert_false(gs.world.is_alive(_db.canon, "bugear"))
	assert_false(gs.flags.has("wirclaw_village.earther_fought_the_eater_goats"))
	for f: String in ["eater_goats.ambushed_the_goblin_army", "redfang.survivors_became_hobgoblins", "bird.lost_the_duel_with_badarrow",
			"erin.bowed_to_the_goblins", "redfang.in_the_inn", "halfseekers.fought_the_redfang_in_the_inn",
			"zevara.stood_down_on_zels_order", "redfang.lodge_in_the_inn_basement", "zel.moved_out_of_the_inn",
			"lyonette.back_at_the_inn", "mrsha.back_at_the_inn", "jelaqua.needs_a_new_body"]:
		assert_true(gs.flags.has(f), f)
	for f: String in ["lyonette.sheltering_in_celum", "mrsha.sheltering_in_celum", "wandering_inn.boarded_up_for_the_goblin_lord",
			"zel.at_wandering_inn"]:
		assert_false(gs.flags.has(f), f)


func test_the_feast_scene_puts_the_redfang_in_the_inn() -> void:
	var db := DataDb.load_dir()
	ToyCombat.freeze(db)
	var gs := _fresh()
	_wait_for(gs, db, FEAST, "inn_interior", INN_SPOT)
	@warning_ignore("integer_division")
	var h: int = gs.clock.minute() / 60
	assert_true(h >= 16 and h < 20, "late afternoon")
	for n: String in RED5 + ["erin_solstice"]:
		assert_eq(_area_of(gs, n), "inn_interior", n)


func test_talking_with_the_redfang_changes_the_feast() -> void:
	var db := DataDb.load_dir()
	ToyCombat.freeze(db)
	var gs := _fresh()
	_wait_for(gs, db, FEAST, "inn_interior", INN_SPOT)
	var n: Dictionary = gs.npcs.npcs["headscratcher"]
	var at := Vector2i(int(n["x"]), int(n["y"]))
	var sides := {at + Vector2i(1, 0): true, at + Vector2i(-1, 0): true, at + Vector2i(0, 1): true, at + Vector2i(0, -1): true}
	assert_true(ToyMaps.walk_to(gs, db, sides), "walk to Headscratcher")
	var r := Commands.interact(gs, db, "headscratcher", "talk_with_guest")
	assert_eq(r["error"], "")
	ToyCanon.sleep_through(gs, db, DAY)
	assert_eq(gs.world.status(FEAST), Director.CHANGED)
	assert_eq(_hook_of(gs, FEAST), "player_ate_with_the_redfang")
	assert_true(gs.flags.has("wandering_inn.earther_sat_with_the_redfang"))
	assert_true(gs.flags.has("redfang.in_the_inn"), "the canon still happens")
	assert_true(gs.world.relationship("headscratcher", NpcSim.PLAYER) >= 1)


func test_the_redfang_sleep_in_the_basement_from_the_next_night() -> void:
	var gs := _fresh()
	ToyCanon.sleep_through(gs, _db, DAY)
	assert_eq(gs.clock.day(), DAY + 1)
	assert_true(Commands.wait(gs, _db, 17 * 3600) >= 0, "wait until the evening")
	Commands.wait(gs, _db, 3600)
	for n: String in RED5:
		assert_eq(_area_of(gs, n), "inn_basement", n)
