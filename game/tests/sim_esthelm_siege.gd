extends GutTest
## M9.3 on the real Book 3 data. Day 80 (3.20T): the Goblin Lord's vanguard
## storms the ruins of Esthelm. The player holds Ylawes' barricade with the
## townsfolk; the dead come first, then the black-armoured assault, then the
## Redfang band charges in on the player's side, and last the Silver-rank
## adventurers break the Goblin rear. A player who fights there changes the
## event. Day 78 (3.16): Erin's play at the Frenzied Hare is a scene; a
## player who sits in on it changes that event.
## The game is slept to day 77 once (before_all); each test starts from a
## copy of that save.

const SEED := 20260926
const SIEGE := "b3.the_last_battle_of_esthelm"
const PLAY := "b3.erin_stages_romeo_and_juliet"
const RUINS_SPOT := Vector2i(8, 6)
const HARE_SPOT := Vector2i(10, 10)
const ARMY := ["goblin_lord_soldier", "goblin_lord_archer", "goblin_lord_shaman", "goblin_lord_hob", "goblin_lord_commander"]
const HELPERS := ["redfang_warrior", "redfang_hob", "esthelm_defender", "silver_rank_adventurer"]

var _db: DataDb
var _day77 := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])
	var gs := GameState.new_game(SEED, _db)
	ToyCanon.sleep_through(gs, _db, 76)
	_day77 = gs.to_json()


func _copy(day: int, db: DataDb = null) -> GameState:
	var d := _db if db == null else db
	var gs := GameState.from_json(_day77)
	ToyCanon.sleep_through(gs, d, day - 1)
	assert_eq(gs.clock.day(), day)
	return gs


## Stands at `pos` in `area` and waits (10 minutes a step, up to 20 hours)
## until the event's stage starts. Returns the combat lines seen.
func _wait_for(gs: GameState, db: DataDb, event: String, area: String, pos: Vector2i) -> Array[String]:
	gs.player.place(area, pos)
	Commands.settle(gs, db)
	var lines: Array[String] = gs.combat.lines.duplicate()
	for i in 120:
		if gs.world.staged.has(event):
			break
		assert_true(Commands.wait(gs, db, 600) >= 0, "wait")
		lines.append_array(gs.combat.lines)
	assert_true(gs.world.staged.has(event), "%s is staged" % event)
	return lines


func _count(gs: GameState, types: Array, state: String) -> int:
	return gs.combat.ids().filter(func(id: String) -> bool:
		var m: Dictionary = gs.combat.monsters[id]
		return types.has(m["type"]) and m["state"] == state).size()


func _area_of(gs: GameState, id: String) -> String:
	var n: Dictionary = gs.npcs.npcs.get(id, {})
	return "" if n.is_empty() else String(n["area"])


func _hook_of(gs: GameState, id: String) -> String:
	var entry: Dictionary = gs.world.history.filter(func(h: Dictionary) -> bool: return h["event"] == id)[0]
	return str(entry.get("hook", ""))


func _texts(gs: GameState) -> Array:
	return gs.world.news.map(func(n: Dictionary) -> String: return n["text"])


## One turn: hit a hostile monster next to the player, or step toward the
## closest one, or wait.
func _step_toward_a_foe(gs: GameState, db: DataDb) -> void:
	var area := gs.player.area
	var best: Array = []
	for id in gs.combat.ids():
		var m: Dictionary = gs.combat.monsters[id]
		if m["area"] != area or m["state"] != CombatState.HOSTILE:
			continue
		var at := CombatState.pos_of(m)
		var d := at - gs.player.pos()
		if absi(d.x) + absi(d.y) == 1:
			Commands.attack(gs, db, "e" if d.x > 0 else "w" if d.x < 0 else "s" if d.y > 0 else "n")
			return
		var path := Pathfind.path(db.maps, area, gs.player.pos(), Pathfind.around(at), MonsterSim.taken(gs, ""))
		if path["found"] and not (path["steps"] as Array).is_empty() \
				and (best.is_empty() or (path["steps"] as Array).size() < best.size()):
			best = path["steps"]
	if best.is_empty():
		Commands.wait(gs, db, 6)
	else:
		Commands.move(gs, db, best[0])


func test_the_ruins_and_the_stages_are_loaded() -> void:
	assert_true(_db.maps.areas.has("esthelm_ruins"), "the ruins map")
	var exits: Array = _db.maps.areas["road_camp"]["exits"]
	assert_eq(exits.filter(func(e: Dictionary) -> bool: return e["to"] == "esthelm_ruins").size(), 1, "a road from the camp")
	assert_has(_db.canon.stages, SIEGE)
	assert_has(_db.canon.stages, PLAY)
	assert_eq(_db.canon.events[SIEGE]["stage"]["area"], "esthelm_ruins")
	assert_eq(_db.canon.events[PLAY]["stage"]["kind"], "scene")
	for npc: String in ["ylawes_byres", "erin_solstice", "wesle"]:
		assert_true(_db.behaviour.npcs.has(npc), npc + " can be placed by a stage")
	assert_true(_db.behaviour.npcs["ylawes_byres"].has("combat"), "Ylawes fights")
	for s: Dictionary in _db.combat.spawns:
		assert_false(ARMY.has(s["enemy"]) or HELPERS.has(s["enemy"]), "only a stage brings " + str(s["enemy"]))


func test_the_siege_waves_come_in_order() -> void:
	var db := DataDb.load_dir()
	ToyCombat.freeze(db)
	var gs := _copy(80, db)
	assert_true(gs.flags.has("ylawes.at_esthelm"), "Ylawes holds the ruins")
	var lines := _wait_for(gs, db, SIEGE, "esthelm_ruins", RUINS_SPOT)
	var st: Dictionary = db.canon.events[SIEGE]["stage"]
	assert_has(lines, st["line"])
	Commands.wait(gs, db, 6)
	assert_eq(_area_of(gs, "ylawes_byres"), "esthelm_ruins", "Ylawes is at the barricade")
	assert_eq(_count(gs, ["esthelm_defender"], CombatState.ALLY), 4, "the townsfolk hold the line")
	assert_true(_count(gs, ARMY, CombatState.HOSTILE) > 0, "the kill team is in the ruins")
	# Clear each wave by hand so the next one can come (max_on_map). The
	# helpers leave when the fight ends, so count the most seen at once.
	var seen := {}
	for i in 200:
		for type: String in HELPERS:
			seen[type] = maxi(int(seen.get(type, 0)), _count(gs, [type], CombatState.ALLY))
		if not Stage.waves_left(gs, db):
			break
		# Once the commander is in, leave his wave to Ylawes and the Redfang
		# band, who are on the map by then.
		for id in gs.combat.ids() if _count(gs, ["goblin_lord_commander"], CombatState.HOSTILE) == 0 else []:
			if gs.combat.monsters.has(id) and gs.combat.monsters[id]["state"] == CombatState.HOSTILE:
				Combat.damage_monster(gs, db, id, 999)
		Commands.wait(gs, db, 30)
		lines.append_array(gs.combat.lines)
		for type: String in HELPERS:
			seen[type] = maxi(int(seen.get(type, 0)), _count(gs, [type], CombatState.ALLY))
	assert_false(Stage.waves_left(gs, db), "every wave came")
	for w: Dictionary in st["waves"]:
		assert_has(lines, w["line"])
	assert_eq(seen["redfang_hob"], 1, "the Redfang Hob fights on the player's side")
	assert_eq(seen["redfang_warrior"], 5, "and five Redfang Goblins")
	# The relief comes as the last foes fall (left_at_most 1); the fight may
	# end on that same turn, so only its line is checked (above).
	assert_eq(_count(gs, HELPERS, CombatState.HOSTILE), 0, "helpers never turn on the player")


func test_holding_the_barricade_changes_the_battle() -> void:
	var db := DataDb.load_dir()
	ToyCombat.freeze(db)
	ToyCombat.always_hit(db)
	var gs := _copy(80, db)
	_wait_for(gs, db, SIEGE, "esthelm_ruins", RUINS_SPOT)
	for i in 6000:
		if not gs.combat.has_fight():
			break
		_step_toward_a_foe(gs, db)
	assert_false(gs.combat.has_fight(), "the vanguard is beaten")
	var melee := gs.action_log.records.filter(func(r: Dictionary) -> bool: return r["action_id"] == "attack_melee")
	assert_eq(melee.size(), 1)
	assert_eq(melee[0]["outcome"], "success")
	assert_eq(melee[0]["context"]["enemy"], "goblin_lord_commander", "the records name the commander")
	assert_eq(melee[0]["context"]["location"], "esthelm")

	ToyCanon.sleep_through(gs, db, 80)
	assert_eq(gs.world.status(SIEGE), Director.CHANGED)
	assert_eq(_hook_of(gs, SIEGE), "player_held_the_esthelm_barricade")
	assert_true(gs.flags.has("esthelm.earther_held_the_barricade"))
	assert_true(gs.flags.has("esthelm.saved"), "the canon still happens")
	assert_eq(gs.world.relationship("ylawes_byres", NpcSim.PLAYER), 3)
	assert_true(_texts(gs).has(db.canon.events[SIEGE]["hooks"][0]["news"]))


func test_no_siege_the_day_before() -> void:
	var gs := _copy(79)
	gs.clock.advance(4 * 60)  # 10:00 on day 79
	gs.player.place("esthelm_ruins", RUINS_SPOT)
	Commands.settle(gs, _db)
	Commands.wait(gs, _db, 60)
	assert_false(gs.world.staged.has(SIEGE))


func test_erin_and_wesle_put_on_the_play() -> void:
	var gs := _copy(78)
	_wait_for(gs, _db, PLAY, "celum_frenzied_hare", HARE_SPOT)
	var hour := gs.clock.minute() / 60
	assert_true(hour >= 19 and hour < 23, "in the evening")
	for npc: String in ["erin_solstice", "wesle"]:
		assert_eq(_area_of(gs, npc), "celum_frenzied_hare", npc)
	Commands.wait(gs, _db, 1800)
	assert_eq(_area_of(gs, "wesle"), "celum_frenzied_hare", "Wesle stays while the scene is live")


func test_watching_the_play_changes_the_event() -> void:
	var gs := _copy(78)
	assert_eq(Commands.give(gs, _db, 50), "")
	gs.player.place("celum_frenzied_hare", HARE_SPOT)
	Commands.settle(gs, _db)
	assert_true(ToyMaps.walk_next_to(gs, _db, "hare_table_east"), "walk to a table")
	var r := Commands.interact(gs, _db, "hare_table_east", "talk_with_guest")
	assert_eq(r["error"], "")
	ToyCanon.sleep_through(gs, _db, 78)
	assert_eq(gs.world.status(PLAY), Director.CHANGED)
	assert_eq(_hook_of(gs, PLAY), "player_watched_erins_play")
	assert_true(gs.flags.has("frenzied_hare.earther_saw_the_play"))
	assert_true(gs.flags.has("erin.staged_a_play"), "the canon still happens")
	assert_eq(gs.world.relationship("erin_solstice", NpcSim.PLAYER), 2)
	assert_true(_texts(gs).has(_db.canon.events[PLAY]["hooks"][0]["news"]))
