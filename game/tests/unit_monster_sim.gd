extends GutTest
## Monsters on the map (M5.2, ADR 0010) in ToyCombat's arena: spawn gates
## and placement, turn cadence, AI per behaviour (pack, ambush,
## territorial), flee, spot and ambush, scare, long gaps, the turn cap.

var _db: DataDb


func before_each() -> void:
	_db = ToyCombat.db()
	_db.combat.enemies["goblin"]["ranged"]["chance"] = 0.0  # no stones unless a test wants them


func _arena(pos: Vector2i, seed_value: int = 1) -> GameState:
	var gs := ToyCombat.new_game(_db, seed_value)
	ToyCombat.to_arena(gs, _db, pos)
	return gs


## A spawn in the arena: a goblin pair on the east side, open all day.
func _spawn(extra: Dictionary = {}) -> Dictionary:
	var s := {"id": "east", "area": "arena", "enemy": "goblin", "confidence": "guess",
		"count": [2, 2], "chance": 1.0, "cooldown_minutes": 120, "rects": [[10, 0, 4, 9]]}
	s.merge(extra, true)
	return s


func _add(gs: GameState, type: String, pos: Vector2i, state: String = CombatState.IDLE,
		group: String = "") -> String:
	return Combat.add_monster(gs, _db, type, pos, state, "", group)


## Waits one player turn (6 s) `times` times.
func _turn(gs: GameState, times: int = 1) -> void:
	for i in times:
		Commands.wait(gs, _db, 6)


func _pos(gs: GameState, id: String) -> Vector2i:
	return CombatState.pos_of(gs.combat.monsters[id])


func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


## One step towards `goal`, around monsters. False if there is no way.
func _step_to(gs: GameState, goal: Vector2i) -> bool:
	var avoid := {}
	for id in gs.combat.ids():
		avoid[_pos(gs, id)] = true
	var found := Pathfind.path(_db.maps, gs.player.area, gs.player.pos(), {goal: true}, avoid)
	if not found["found"] or (found["steps"] as Array).is_empty():
		return false
	return Commands.move(gs, _db, found["steps"][0])["moved"]


func _records(gs: GameState, action_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for r: Dictionary in gs.action_log.records:
		if r["action_id"] == action_id:
			out.append(r)
	return out


# --- spawns -----------------------------------------------------------------

func test_a_spawn_places_its_group_on_free_far_tiles() -> void:
	_db.combat.spawns = [_spawn()]
	assert_eq(_db.combat.validate(_db), [] as Array[String])
	var gs := _arena(Vector2i(1, 4))
	var ids := gs.combat.ids()
	assert_eq(ids.size(), 2, "entering the area checks the spawns")
	for id in ids:
		var m: Dictionary = gs.combat.monsters[id]
		assert_eq(m["spawn"], "east")
		assert_eq(m["state"], CombatState.IDLE)
		assert_eq(m["group"], ids[0], "one pack")
		assert_eq(m["pack"], 2)
		assert_true(Rect2i(10, 0, 4, 9).has_point(_pos(gs, id)))
		assert_gte(Combat._dist(_pos(gs, id), gs.player.pos()), 6, "spawn.min_distance")
		assert_eq(Vector2i(int(m["home_x"]), int(m["home_y"])), _pos(gs, id), "home = where it spawned")
	assert_ne(_pos(gs, ids[0]), _pos(gs, ids[1]))
	assert_eq(gs.combat.spawn_last["east"], gs.clock.total_minutes)
	assert_false(gs.combat.has_fight(), "idle monsters start no fight")


func test_an_ambusher_spawns_hidden_and_a_home_spawn_at_home() -> void:
	_db.combat.spawns = [_spawn({"id": "rocks", "enemy": "crab", "count": [1, 1]}),
		_spawn({"id": "nest", "enemy": "bird", "count": [1, 1], "home": [11, 4]})]
	_db.combat.spawns[1].erase("rects")
	assert_eq(_db.combat.validate(_db), [] as Array[String])
	var gs := _arena(Vector2i(1, 4))
	var ids := gs.combat.ids()
	assert_eq(ids.size(), 2)
	assert_eq(gs.combat.monsters[ids[0]]["state"], CombatState.HIDDEN)
	assert_eq(gs.combat.monsters[ids[1]]["state"], CombatState.IDLE)
	assert_eq(_pos(gs, ids[1]), Vector2i(11, 4))


func test_spawn_gates() -> void:
	var gs := _arena(Vector2i(1, 4))
	assert_true(MonsterSim.spawn_open(gs, _spawn()))
	assert_false(MonsterSim.spawn_open(gs, _spawn({"hours": [7, 11]})), "06:00 is before 07")
	assert_true(MonsterSim.spawn_open(gs, _spawn({"hours": [22, 7]})), "the hours wrap")
	assert_false(MonsterSim.spawn_open(gs, _spawn({"days": [2, 3]})))
	assert_false(MonsterSim.spawn_open(gs, _spawn({"when_flags": ["raid"]})))
	gs.flags["raid"] = true
	assert_true(MonsterSim.spawn_open(gs, _spawn({"when_flags": ["raid"]})))
	assert_false(MonsterSim.spawn_open(gs, _spawn({"unless_flags": ["raid"]})))
	gs.clock.advance(60)
	assert_true(MonsterSim.spawn_open(gs, _spawn({"hours": [7, 11]})))
	assert_false(MonsterSim.spawn_open(gs, _spawn({"hours": [22, 7]})))
	gs.combat.spawn_last["east"] = gs.clock.total_minutes - 60
	assert_false(MonsterSim.spawn_open(gs, _spawn()), "cooldown")
	gs.combat.spawn_last["east"] = gs.clock.total_minutes - 120
	assert_true(MonsterSim.spawn_open(gs, _spawn()))
	Combat.add_monster(gs, _db, "goblin", Vector2i(12, 8), CombatState.IDLE, "east")
	assert_false(MonsterSim.spawn_open(gs, _spawn()), "one of its monsters is still here")


func test_spawns_keep_their_distance_and_the_cap() -> void:
	_db.rules["combat"]["spawn"]["max_monsters"] = 3
	_db.combat.spawns = [_spawn({"count": [5, 5]})]
	var gs := _arena(Vector2i(9, 4))
	assert_true(gs.combat.monsters.is_empty(), "no tile in the rect is 6 away")
	assert_false(gs.combat.spawn_last.has("east"), "no cooldown when nothing was placed")
	gs.player.place("arena", Vector2i(1, 4))
	assert_eq(MonsterSim.spawn_check(gs, _db).size(), 3, "rules.combat.spawn.max_monsters")


func test_a_failed_chance_places_nothing() -> void:
	_db.combat.spawns = [_spawn({"chance": 0.0})]
	var gs := _arena(Vector2i(1, 4))
	assert_true(gs.combat.monsters.is_empty())


func test_spawns_are_checked_on_entering_and_every_hour() -> void:
	_db.combat.spawns = [_spawn({"hours": [7, 8]})]
	var gs := _arena(Vector2i(1, 4))
	assert_true(gs.combat.monsters.is_empty(), "closed at 06:00")
	assert_eq(gs.combat.checked, gs.clock.total_minutes)
	Commands.wait(gs, _db, 30 * 60)
	assert_true(gs.combat.monsters.is_empty(), "06:30: no check yet")
	Commands.wait(gs, _db, 30 * 60)
	assert_eq(gs.clock.time_string(), "07:00")
	assert_eq(gs.combat.monsters.size(), 2, "the hourly check")


# --- turns and AI ------------------------------------------------------------

func test_turns_follow_act_seconds() -> void:
	for type: String in ["goblin", "bird"]:
		_db.combat.enemies[type]["lose_radius"] = 20
	var gs := _arena(Vector2i(1, 1))
	var gob := _add(gs, "goblin", Vector2i(12, 1), CombatState.HOSTILE)
	var bird := _add(gs, "bird", Vector2i(12, 7), CombatState.HOSTILE)
	_turn(gs, 2)
	assert_eq(_pos(gs, gob), Vector2i(10, 1), "6 s turns: 2 steps in 12 s")
	assert_eq(_manhattan(_pos(gs, bird), gs.player.pos()), 17 - 3, "4 s turns: 3 steps in 12 s")
	assert_eq(gs.combat.monsters[gob]["carry"], 0)
	assert_eq(gs.combat.monsters[bird]["carry"], 0)


func test_a_pack_turns_hostile_together() -> void:
	var gs := _arena(Vector2i(1, 4))
	var ids: Array[String] = []
	for at: Vector2i in [Vector2i(4, 4), Vector2i(7, 1), Vector2i(7, 7)]:  # 6 away: lose_radius
		ids.append(_add(gs, "goblin", at, CombatState.IDLE, "pack"))
	_turn(gs)
	for id in ids:
		assert_eq(gs.combat.monsters[id]["state"], CombatState.HOSTILE, id)
	assert_eq((gs.combat.fight["foes"] as Dictionary).size(), 3)
	assert_has(gs.combat.lines, "3 Goblins come at you!")
	assert_true(Combat.in_danger(gs))


func test_an_idle_monster_waits_outside_its_aggro_radius() -> void:
	var gs := _arena(Vector2i(1, 4))
	var gob := _add(gs, "goblin", Vector2i(10, 4))
	_turn(gs, 3)
	assert_eq(gs.combat.monsters[gob]["state"], CombatState.IDLE)
	assert_eq(_pos(gs, gob), Vector2i(10, 4))


func test_a_monster_walks_round_a_wall() -> void:
	_db.combat.enemies["goblin"]["lose_radius"] = 20
	ToyCombat.never_hit(_db)
	var gs := _arena(Vector2i(8, 4))
	var gob := _add(gs, "goblin", Vector2i(4, 4), CombatState.HOSTILE)
	for i in 12:
		_turn(gs)
		assert_true(_db.maps.is_walkable("arena", _pos(gs, gob)))
		if _manhattan(_pos(gs, gob), gs.player.pos()) == 1:
			break
	assert_eq(_manhattan(_pos(gs, gob), gs.player.pos()), 1, "it got next to the player")


func test_monsters_walk_round_npcs() -> void:
	_db.combat.enemies["goblin"]["lose_radius"] = 20
	ToyCombat.never_hit(_db)
	var gs := _arena(Vector2i(1, 1))
	gs.npcs.npcs["guard"] = {"area": "arena", "x": 2, "y": 1, "facing": "s", "goal": "",
		"route_i": 0, "carry": 0, "talked_day": 0}
	var gob := _add(gs, "goblin", Vector2i(5, 1), CombatState.HOSTILE)
	for i in 8:
		_turn(gs)
		assert_ne(_pos(gs, gob), Vector2i(2, 1), "never on the NPC")
	assert_eq(_manhattan(_pos(gs, gob), gs.player.pos()), 1)


func test_a_monster_next_to_the_player_attacks() -> void:
	ToyCombat.always_hit(_db)
	var gs := _arena(Vector2i(1, 4))
	_add(gs, "goblin", Vector2i(2, 4), CombatState.HOSTILE)
	_turn(gs)
	assert_eq(Combat.hp(gs, _db), Stats.max_hp(gs, _db) - 2)
	assert_has(gs.combat.lines, "The Goblin attacks you: 2 damage.")


func test_a_goblin_throws_stones_from_range() -> void:
	ToyCombat.always_hit(_db)
	_db.combat.enemies["goblin"]["ranged"]["chance"] = 1.0
	var gs := _arena(Vector2i(1, 4))
	var gob := _add(gs, "goblin", Vector2i(4, 4), CombatState.HOSTILE)
	_turn(gs)
	assert_eq(Combat.hp(gs, _db), Stats.max_hp(gs, _db) - 1)
	assert_has(gs.combat.lines, "The Goblin throws a stone at you: 1 damage.")
	assert_eq(_pos(gs, gob), Vector2i(4, 4), "it threw instead of walking")


func test_a_hurt_monster_flees_and_is_gone_at_the_edge() -> void:
	var gs := _arena(Vector2i(5, 1))
	var gob := _add(gs, "goblin", Vector2i(8, 1), CombatState.HOSTILE)
	gs.combat.monsters[gob]["hp"] = 3
	_turn(gs)
	assert_eq(gs.combat.monsters[gob]["state"], CombatState.FLEE)
	assert_eq(gs.combat.fight["routed"], 1)
	assert_has(gs.combat.lines, "The Goblin runs away.")
	assert_false(Combat.in_danger(gs), "a fleeing monster is no danger")
	for i in 6:
		_turn(gs)
		if not gs.combat.monsters.has(gob):
			break
	assert_false(gs.combat.monsters.has(gob), "gone at the map edge")
	assert_false(gs.combat.has_fight(), "the fight is won")


func test_half_a_pack_gone_breaks_its_morale() -> void:
	var gs := _arena(Vector2i(1, 4))
	var a := _add(gs, "goblin", Vector2i(2, 4), CombatState.HOSTILE, "pack")
	var b := _add(gs, "goblin", Vector2i(4, 1), CombatState.HOSTILE, "pack")
	for id in [a, b]:
		gs.combat.monsters[id]["pack"] = 2
	Combat.damage_monster(gs, _db, a, 99)
	_turn(gs)
	assert_eq(gs.combat.monsters[b]["state"], CombatState.FLEE)


func test_a_lone_goblin_keeps_fighting() -> void:
	ToyCombat.never_hit(_db)
	var gs := _arena(Vector2i(1, 4))
	var gob := _add(gs, "goblin", Vector2i(2, 4), CombatState.HOSTILE)
	_turn(gs, 3)
	assert_eq(gs.combat.monsters[gob]["state"], CombatState.HOSTILE)


# --- ambush, spot, scare -----------------------------------------------------

func test_a_hidden_monster_gets_one_spot_roll() -> void:
	_db.rules["combat"]["spot"] = {"base": 1.0, "per_point": 0.0}
	var gs := _arena(Vector2i(1, 4))
	var crab := _add(gs, "crab", Vector2i(3, 4), CombatState.HIDDEN)
	Combat.sync(gs, _db)
	assert_eq(gs.combat.monsters[crab]["state"], CombatState.IDLE)
	assert_has(gs.combat.lines, "You spot a Crab among the rocks.")
	_db.rules["combat"]["spot"] = {"base": 0.0, "per_point": 0.0}
	var gs2 := _arena(Vector2i(1, 4))
	var crab2 := _add(gs2, "crab", Vector2i(3, 4), CombatState.HIDDEN)
	Combat.sync(gs2, _db)
	assert_eq(gs2.combat.monsters[crab2]["state"], CombatState.HIDDEN)
	assert_true(gs2.combat.monsters[crab2]["rolled_spot"])
	_db.rules["combat"]["spot"] = {"base": 1.0, "per_point": 0.0}
	Combat.sync(gs2, _db)
	assert_eq(gs2.combat.monsters[crab2]["state"], CombatState.HIDDEN, "only one roll")


func test_the_spot_chance_uses_perception() -> void:
	_db.rules["combat"]["spot"] = {"base": 0.0, "per_point": 1.0 / 3.0 + 0.001}
	var gs := _arena(Vector2i(1, 4))
	var crab := _add(gs, "crab", Vector2i(3, 5), CombatState.HIDDEN)
	Combat.sync(gs, _db)
	assert_eq(gs.combat.monsters[crab]["state"], CombatState.IDLE, "3 perception × 0.334 > 1")


func test_a_spotted_crab_only_attacks_up_close() -> void:
	ToyCombat.never_hit(_db)
	var gs := _arena(Vector2i(1, 4))
	var crab := _add(gs, "crab", Vector2i(3, 4))
	_turn(gs, 2)
	assert_eq(gs.combat.monsters[crab]["state"], CombatState.IDLE, "aggro_radius 1")
	Commands.move(gs, _db, "e")
	_turn(gs, 2)
	assert_eq(gs.combat.monsters[crab]["state"], CombatState.HOSTILE)


func test_a_hidden_crab_ambushes_next_to_the_player() -> void:
	ToyCombat.always_hit(_db)
	_db.rules["combat"]["spot"] = {"base": 0.0, "per_point": 0.0}
	var gs := _arena(Vector2i(1, 4))
	var crab := _add(gs, "crab", Vector2i(3, 4), CombatState.HIDDEN)
	assert_true(Commands.move(gs, _db, "e")["moved"])
	assert_eq(gs.combat.monsters[crab]["state"], CombatState.HIDDEN, "6 s < its 8 s turn")
	_turn(gs)
	assert_eq(gs.combat.monsters[crab]["state"], CombatState.HOSTILE)
	assert_has(gs.combat.lines, "A Crab bursts out of hiding!")
	assert_eq(Combat.hp(gs, _db), Stats.max_hp(gs, _db) - 5)
	assert_true(Combat.in_danger(gs))


func test_bumping_a_hidden_crab_springs_the_ambush() -> void:
	ToyCombat.always_hit(_db)
	_db.rules["combat"]["spot"] = {"base": 0.0, "per_point": 0.0}
	var gs := _arena(Vector2i(1, 4))
	var crab := _add(gs, "crab", Vector2i(2, 4), CombatState.HIDDEN)
	var before := NpcSim.world_sec(gs)
	var r := Commands.move(gs, _db, "e")
	assert_false(r["moved"])
	assert_eq(r["monster"], crab)
	assert_true(r.has("ambush"))
	assert_false(r.has("attack"), "the player does not get a swing")
	assert_true(r["ambush"]["hit"])
	assert_eq(gs.combat.monsters[crab]["hp"], 30)
	assert_eq(gs.combat.monsters[crab]["state"], CombatState.HOSTILE)
	assert_eq(Combat.hp(gs, _db), Stats.max_hp(gs, _db) - 5)
	assert_eq(NpcSim.world_sec(gs), before, "a blocked step takes no time")


func test_the_ambush_bonus_raises_the_hit_chance() -> void:
	# The crab's accuracy 2 vs dexterity 3 gives 0.65; with the 0.2 bonus 0.85.
	_db.rules["combat"]["spot"] = {"base": 0.0, "per_point": 0.0}
	var hits := 0
	for seed_value in 40:
		var gs := _arena(Vector2i(1, 4), seed_value)
		_add(gs, "crab", Vector2i(2, 4), CombatState.HIDDEN)
		if Commands.move(gs, _db, "e")["ambush"]["hit"]:
			hits += 1
	assert_gt(hits, 26, "about 34 of 40 hit")


func test_a_crab_gives_up_and_hides_again() -> void:
	ToyCombat.never_hit(_db)
	var gs := _arena(Vector2i(1, 4))
	var crab := _add(gs, "crab", Vector2i(2, 4), CombatState.HOSTILE)
	for i in 20:
		if gs.combat.monsters[crab]["state"] == CombatState.HIDDEN:
			break
		assert_true(_step_to(gs, Vector2i(13, 8)) or Commands.wait(gs, _db, 6) >= 0)
	assert_eq(gs.combat.monsters[crab]["state"], CombatState.HIDDEN)
	assert_false(gs.combat.monsters[crab]["rolled_spot"], "a new spot roll")
	assert_false(gs.combat.has_fight(), "it gave up: the player got away")
	assert_eq(_records(gs, "flee_danger").size(), 1)


func test_a_scare_item_scares_a_crab_but_not_a_bird() -> void:
	ToyCombat.always_hit(_db)
	var gs := _arena(Vector2i(1, 4))
	var crab := _add(gs, "crab", Vector2i(3, 4), CombatState.HOSTILE)
	var bird := _add(gs, "bird", Vector2i(1, 7), CombatState.HOSTILE)
	gs.player.held = "stink"
	Commands.throw(gs, _db, crab)
	assert_eq(gs.combat.monsters[crab]["state"], CombatState.FLEE)
	assert_eq(gs.combat.monsters[crab]["scared"], 12)
	assert_eq(gs.combat.fight["routed"], 1, "a scared foe counts as routed")
	gs.player.held = "stink"
	Commands.throw(gs, _db, bird)
	assert_eq(gs.combat.monsters[bird]["state"], CombatState.HOSTILE)


func test_a_scared_crab_calms_down_and_hides() -> void:
	var gs := _arena(Vector2i(1, 1))
	var crab := _add(gs, "crab", Vector2i(10, 7), CombatState.FLEE)
	gs.combat.monsters[crab]["scared"] = 2
	_turn(gs, 3)  # 18 s: two 8 s turns
	assert_eq(gs.combat.monsters[crab]["scared"], 0)
	assert_eq(gs.combat.monsters[crab]["state"], CombatState.HIDDEN)


# --- territorial -------------------------------------------------------------

func test_a_territorial_bird_guards_its_home_on_a_leash() -> void:
	ToyCombat.never_hit(_db)
	var gs := _arena(Vector2i(1, 1))
	var bird := _add(gs, "bird", Vector2i(11, 4))
	_turn(gs)
	assert_eq(gs.combat.monsters[bird]["state"], CombatState.IDLE)
	gs.player.place("arena", Vector2i(8, 1))  # 3 from the nest
	_turn(gs)
	assert_eq(gs.combat.monsters[bird]["state"], CombatState.HOSTILE)
	for i in 10:
		if gs.combat.monsters[bird]["state"] != CombatState.HOSTILE:
			break
		assert_true(_step_to(gs, Vector2i(0, 1)) or Commands.wait(gs, _db, 6) >= 0)
	assert_eq(gs.combat.monsters[bird]["state"], CombatState.HOME)
	assert_gt(Combat._dist(gs.player.pos(), Vector2i(11, 4)), 5, "past its leash")
	assert_false(gs.combat.has_fight())
	assert_eq(_records(gs, "flee_danger").size(), 1, "the player fled")
	_turn(gs, 20)
	assert_eq(_pos(gs, bird), Vector2i(11, 4), "back home")
	assert_eq(gs.combat.monsters[bird]["state"], CombatState.IDLE)


# --- time --------------------------------------------------------------------

func test_a_long_quiet_gap_gives_no_turns() -> void:
	var gs := _arena(Vector2i(1, 1))
	var gob := _add(gs, "goblin", Vector2i(12, 7), CombatState.HOME)
	gs.combat.monsters[gob]["home_y"] = 1
	Commands.wait(gs, _db, 400)
	assert_eq(_pos(gs, gob), Vector2i(12, 7), "over jump_seconds: no turns")
	assert_eq(gs.combat.monsters[gob]["carry"], 0)
	_turn(gs, 2)
	assert_eq(_pos(gs, gob), Vector2i(12, 5), "two steps home")


func test_a_long_wait_in_danger_still_gives_turns_up_to_the_cap() -> void:
	ToyCombat.never_hit(_db)
	_db.rules["combat"]["max_turns_per_sync"] = 3
	var gs := _arena(Vector2i(1, 1))
	var gob := _add(gs, "goblin", Vector2i(2, 1), CombatState.HOSTILE)
	Commands.wait(gs, _db, 600)
	var misses := gs.combat.lines.filter(func(l: String) -> bool: return l.contains("misses"))
	assert_eq(misses.size(), 3)
	assert_eq(gs.combat.monsters[gob]["carry"], 0)


func test_no_turns_once_the_player_is_down() -> void:
	ToyCombat.always_hit(_db)
	var gs := _arena(Vector2i(1, 1))
	_add(gs, "goblin", Vector2i(2, 1), CombatState.HOSTILE)
	_add(gs, "goblin", Vector2i(1, 2), CombatState.HOSTILE)
	Combat.set_hp(gs, _db, 2)
	_turn(gs)
	assert_true(Combat.is_down(gs))
	var hits := gs.combat.lines.filter(func(l: String) -> bool: return l.contains("attacks you"))
	assert_eq(hits.size(), 1, "the second goblin does not hit a knocked-out player")


func test_leaving_and_the_night_clear_the_arena() -> void:
	var gs := _arena(Vector2i(1, 1))
	_add(gs, "goblin", Vector2i(12, 7))
	gs.player.place("town", Vector2i(1, 2))
	Combat.sync(gs, _db)
	assert_true(gs.combat.monsters.is_empty())


func test_same_seed_same_monsters_and_save_load() -> void:
	_db.combat.spawns = [_spawn({"count": [2, 3]})]
	_db.combat.enemies["goblin"]["ranged"]["chance"] = 0.5
	var a := _arena(Vector2i(1, 4), 5)
	var b := _arena(Vector2i(1, 4), 5)
	var c := GameState.from_json(a.to_json())
	for gs: GameState in [a, b, c]:
		gs.player.place("arena", Vector2i(7, 4))
		for i in 10:
			Commands.wait(gs, _db, 6)
	assert_eq(a.to_json(), b.to_json())
	assert_eq(a.to_json(), c.to_json(), "a loaded game plays on the same")
	assert_eq(typeof(c.combat.monsters.values()[0]["pack"]), TYPE_INT)
