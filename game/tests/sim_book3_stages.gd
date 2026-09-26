extends GutTest
## M9.1 stages on the real Book 3 data: on day 75 Persua and her Runners
## fight Ryoka in Celum's Runners' Guild (3.04); on the evening of day 76
## Lyonette reopens the Wandering Inn and Pawn comes to eat (3.05 L, a
## scene). Persua cannot die: beaten, she runs (enemy escape). A player who
## fights beside Ryoka, or keeps Lyonette's inn going, changes the event.
## M9.2: on the morning of day 76 Ryoka and Fals talk at the Frenzied Hare
## (3.09, a scene); a player who serves or sits with them changes it. The
## same day Erin's Corusdeer soup goes on sale at Stitchworks, and that
## night Ryoka leaves Celum for Magnolia.
## The game is slept to day 74 once (before_all); each test starts from a
## copy of that save.

const SEED := 20260926
const GUILD_FIGHT := "b3.ryoka_beats_persua_in_the_runners_guild"
const REOPENING := "b3.lyonette_reopens_the_inn"
const HARE_TALK := "b3.ryoka_and_fals_talk_at_the_frenzied_hare"
const HARE_SPOT := Vector2i(10, 10)
const GUILD_SPOT := Vector2i(6, 8)
const INN_SPOT := Vector2i(4, 10)

var _db: DataDb
var _day74 := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])
	var gs := GameState.new_game(SEED, _db)
	ToyCanon.sleep_through(gs, _db, 73)
	_day74 = gs.to_json()


func _copy(day: int, db: DataDb = null) -> GameState:
	var d := _db if db == null else db
	var gs := GameState.from_json(_day74)
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


func _foes(gs: GameState, enemy: String) -> int:
	return gs.combat.ids().filter(func(id: String) -> bool: return gs.combat.monsters[id]["type"] == enemy).size()


func _area_of(gs: GameState, id: String) -> String:
	var n: Dictionary = gs.npcs.npcs.get(id, {})
	return "" if n.is_empty() else String(n["area"])


func _hook_of(gs: GameState, id: String) -> String:
	var entry: Dictionary = gs.world.history.filter(func(h: Dictionary) -> bool: return h["event"] == id)[0]
	return str(entry.get("hook", ""))


func _texts(gs: GameState) -> Array:
	return gs.world.news.map(func(n: Dictionary) -> String: return n["text"])


## The nearest hostile monster of the guild fight, or "".
func _nearest_foe(gs: GameState) -> String:
	var best := ""
	var best_d := 1 << 30
	for id: String in gs.combat.ids():
		var m: Dictionary = gs.combat.monsters[id]
		if m["state"] != CombatState.HOSTILE or m.get("stage", "") != GUILD_FIGHT:
			continue
		var d := CombatState.pos_of(m) - gs.player.pos()
		if absi(d.x) + absi(d.y) < best_d:
			best_d = absi(d.x) + absi(d.y)
			best = id
	return best


## One turn: hit the nearest foe when it is next to the player, else step toward it.
func _fight_turn(gs: GameState, db: DataDb) -> void:
	var id := _nearest_foe(gs)
	if id == "":
		Commands.wait(gs, db, 6)
		return
	var at := CombatState.pos_of(gs.combat.monsters[id])
	var d := at - gs.player.pos()
	if absi(d.x) + absi(d.y) == 1:
		Commands.attack(gs, db, "e" if d.x > 0 else "w" if d.x < 0 else "s" if d.y > 0 else "n")
		return
	var path := Pathfind.path(db.maps, gs.player.area, gs.player.pos(), Pathfind.around(at), MonsterSim.taken(gs, ""))
	if path["found"] and not (path["steps"] as Array).is_empty():
		Commands.move(gs, db, path["steps"][0])
	else:
		Commands.wait(gs, db, 6)


func test_the_new_stages_are_loaded() -> void:
	for id: String in [GUILD_FIGHT, REOPENING]:
		assert_has(_db.canon.stages, id)
	assert_eq(_db.canon.events[GUILD_FIGHT]["stage"]["area"], "celum_runners_guild")
	assert_eq(_db.canon.events[REOPENING]["stage"]["kind"], "scene")
	assert_true(_db.combat.enemies["persua_courier"].has("escape"), "Persua cannot die")
	for npc: String in ["ryoka_griffin", "lyonette", "pawn"]:
		assert_true(_db.behaviour.npcs.has(npc), npc + " can be placed by a stage")
	for s: Dictionary in _db.combat.spawns:
		assert_false(["persua_courier", "celum_runner"].has(s["enemy"]), "only a stage brings " + str(s["enemy"]))


func test_persua_and_her_runners_wait_in_the_guild() -> void:
	var gs := _copy(75)
	assert_true(gs.flags.has("ryoka.in_celum"), "Ryoka is in Celum")
	_wait_for(gs, _db, GUILD_FIGHT, "celum_runners_guild", GUILD_SPOT)
	var hour := gs.clock.minute() / 60
	assert_true(hour >= 10 and hour < 14, "between 10 and 14")
	assert_eq(_foes(gs, "persua_courier"), 1)
	assert_eq(_foes(gs, "celum_runner"), 3)
	Commands.wait(gs, _db, 6)
	assert_eq(_area_of(gs, "ryoka_griffin"), "celum_runners_guild", "Ryoka is in the fight")


func test_no_guild_fight_the_day_before() -> void:
	var gs := _copy(74)
	gs.clock.advance(5 * 60)  # 11:00 on day 74
	gs.player.place("celum_runners_guild", GUILD_SPOT)
	Commands.settle(gs, _db)
	Commands.wait(gs, _db, 60)
	assert_false(gs.world.staged.has(GUILD_FIGHT))


func test_an_escaping_persua_never_dies() -> void:
	var gs := GameState.new_game(1, _db)
	gs.player.place("celum_runners_guild", GUILD_SPOT)
	var id := Combat.add_monster(gs, _db, "persua_courier", GUILD_SPOT + Vector2i(1, 0))
	Combat.join(gs, id)
	assert_false(Combat.damage_monster(gs, _db, id, 5), "hurt, not gone")
	assert_true(gs.combat.monsters.has(id))
	assert_false(Combat.damage_monster(gs, _db, id, 999), "no kill")
	assert_false(gs.combat.monsters.has(id), "she ran out of the guild")
	assert_has(gs.combat.lines, _db.combat.enemies["persua_courier"]["escape"]["line"])
	assert_eq(int(gs.combat.fight["routed"]), 1)
	assert_eq(int(gs.combat.fight["kills"]), 0)


func test_standing_with_ryoka_changes_the_event() -> void:
	var db := DataDb.load_dir()
	ToyCombat.freeze(db)
	ToyCombat.always_hit(db)
	var gs := _copy(75, db)
	_wait_for(gs, db, GUILD_FIGHT, "celum_runners_guild", GUILD_SPOT)
	for i in 3000:
		if _nearest_foe(gs) == "" and not gs.combat.has_fight():
			break
		_fight_turn(gs, db)
	assert_eq(_nearest_foe(gs), "", "no foe is left")
	assert_false(gs.combat.has_fight(), "the fight ends")
	var melee := gs.action_log.records.filter(func(r: Dictionary) -> bool: return r["action_id"] == "attack_melee")
	assert_eq(melee.size(), 1)
	assert_eq(melee[0]["outcome"], "success")
	assert_eq(melee[0]["context"]["enemy"], "persua_courier", "the fight's records name Persua")
	assert_eq(melee[0]["context"]["location"], "celum_runners_guild")

	ToyCanon.sleep_through(gs, db, 75)
	assert_eq(gs.world.status(GUILD_FIGHT), Director.CHANGED)
	assert_eq(_hook_of(gs, GUILD_FIGHT), "player_stood_with_ryoka")
	assert_true(gs.flags.has("celum.earther_stood_with_ryoka"))
	assert_true(gs.flags.has("persua.swore_to_kill_ryoka"), "the canon still happens")
	assert_true(gs.world.is_alive(db.canon, "persua"))
	assert_eq(gs.world.relationship("ryoka_griffin", NpcSim.PLAYER), 3)
	assert_eq(gs.world.relationship("persua", NpcSim.PLAYER), -2)
	assert_true(_texts(gs).has(db.canon.events[GUILD_FIGHT]["hooks"][0]["news"]))


func test_lyonette_reopens_with_pawn_as_her_guest() -> void:
	var gs := _copy(76)
	_wait_for(gs, _db, REOPENING, "inn_interior", INN_SPOT)
	var hour := gs.clock.minute() / 60
	assert_true(hour >= 18 and hour < 22, "in the evening")
	assert_eq(gs.combat.ids().filter(func(id: String) -> bool: return gs.combat.monsters[id].get("stage", "") == REOPENING).size(), 0,
			"a scene, not a fight")
	for npc: String in ["lyonette", "pawn"]:
		assert_eq(_area_of(gs, npc), "inn_interior", npc)
	Commands.wait(gs, _db, 1800)
	assert_eq(_area_of(gs, "pawn"), "inn_interior", "Pawn stays while the scene is live")


func test_keeping_lyonette_going_changes_the_event() -> void:
	var gs := _copy(76)
	assert_eq(Commands.give(gs, _db, 200), "")
	gs.player.place("inn_interior", INN_SPOT)
	Commands.settle(gs, _db)
	assert_true(ToyMaps.walk_next_to(gs, _db, "inn_counter"), "walk to the counter")
	var r := Commands.interact(gs, _db, "inn_counter", "buy_supplies")
	assert_eq(r["error"], "")
	assert_eq(r["record"]["context"]["location"], "wandering_inn")
	ToyCanon.sleep_through(gs, _db, 76)
	assert_eq(gs.world.status(REOPENING), Director.CHANGED)
	assert_eq(_hook_of(gs, REOPENING), "player_ate_at_lyonettes_inn")
	assert_true(gs.flags.has("wandering_inn.earther_kept_lyonette_going"))
	assert_true(gs.flags.has("wandering_inn.reopened_by_lyonette"), "the canon still happens")
	assert_eq(gs.world.relationship("lyonette", NpcSim.PLAYER), 3)
	assert_true(_texts(gs).has(_db.canon.events[REOPENING]["hooks"][0]["news"]))


func test_ryoka_and_fals_talk_at_the_hare_in_the_morning() -> void:
	assert_eq(_db.canon.events[HARE_TALK]["stage"]["kind"], "scene")
	assert_true(_db.behaviour.npcs.has("fals"), "fals can be placed by a stage")
	var gs := _copy(76)
	_wait_for(gs, _db, HARE_TALK, "celum_frenzied_hare", HARE_SPOT)
	var hour := gs.clock.minute() / 60
	assert_true(hour >= 9 and hour < 12, "in the morning")
	for npc: String in ["ryoka_griffin", "fals"]:
		assert_eq(_area_of(gs, npc), "celum_frenzied_hare", npc)
	Commands.wait(gs, _db, 1800)
	assert_eq(_area_of(gs, "fals"), "celum_frenzied_hare", "Fals stays while the scene is live")


func test_sitting_with_ryoka_and_fals_changes_the_event() -> void:
	var gs := _copy(76)
	gs.player.place("celum_frenzied_hare", HARE_SPOT)
	Commands.settle(gs, _db)
	assert_true(ToyMaps.walk_next_to(gs, _db, "hare_table_east"), "walk to a table")
	var r := Commands.interact(gs, _db, "hare_table_east", "talk_with_guest")
	assert_eq(r["error"], "")
	assert_eq(r["record"]["context"]["location"], "frenzied_hare")
	ToyCanon.sleep_through(gs, _db, 76)
	assert_eq(gs.world.status(HARE_TALK), Director.CHANGED)
	assert_eq(_hook_of(gs, HARE_TALK), "player_sat_with_ryoka_and_fals")
	assert_true(gs.flags.has("frenzied_hare.earther_sat_with_ryoka"))
	assert_true(gs.flags.has("ryoka.heard_the_horns_are_in_ocre"), "the canon still happens")
	assert_eq(gs.world.relationship("ryoka_griffin", NpcSim.PLAYER), 2)
	assert_eq(gs.world.relationship("fals", NpcSim.PLAYER), 2)
	assert_true(_texts(gs).has(_db.canon.events[HARE_TALK]["hooks"][0]["news"]))


func test_corusdeer_soup_goes_on_sale_and_ryoka_leaves_celum() -> void:
	var gs := _copy(76)
	var obj := Interact.object_of(_db, "celum_square", "stitchworks_door")
	var goods := func() -> Array: return Economy.trades(gs, _db, obj).map(func(t: Dictionary) -> String: return t["good"])
	assert_false(goods.call().has("corusdeer_soup"), "not before Erin makes it")
	ToyCanon.sleep_through(gs, _db, 76)
	assert_eq(gs.world.status("b3.erin_and_octavia_brew_corusdeer_soup"), Director.DONE)
	assert_true(goods.call().has("corusdeer_soup"), "on sale from day 77")
	assert_true(gs.flags.has("ryoka.gone_to_magnolia"))
	for i in 24:
		if gs.clock.minute() >= 19 * 60:
			break
		Commands.wait(gs, _db, 3600)
	assert_true(BehaviourDb.is_off_map(_area_of(gs, "ryoka_griffin")), "Ryoka has left Celum")

