extends GutTest
## Combat on the real maps and data (M5.2, ADR 0010): the real spawn tables
## make all 3 enemy types, a seed core sends a Rock Crab running, and a
## Goblin pack fight is deterministic: the same seed gives the same game, and
## a save/load in the middle of the fight plays on the same.

const SEED := 5252
const MAX_TURNS := 300

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()


## A new game (day 8, 06:00) with the player placed on `pos` in `area`.
func _game_at(seed_value: int, area: String, pos: Vector2i) -> GameState:
	var gs := GameState.new_game(seed_value, _db)
	gs.player.place(area, pos)
	Commands.settle(gs, _db)
	return gs


## No monsters, and every spawn on its cooldown: the test places its own.
func _calm(gs: GameState) -> void:
	gs.combat.monsters.clear()
	gs.combat.fight = {}
	for s: Dictionary in _db.combat.spawns:
		gs.combat.spawn_last[s["id"]] = gs.clock.total_minutes


func _records(gs: GameState, action_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for r: Dictionary in gs.action_log.records:
		if r["action_id"] == action_id:
			out.append(r)
	return out


## One command of a simple fighter: hit a hostile monster next to you,
## else throw the held item at the nearest one in range, else raise your
## guard. Returns false when the fight is over (a knock-out ends it).
func _bot_turn(gs: GameState) -> bool:
	if Combat.is_down(gs):
		Commands.knock_out(gs, _db)
		return false
	if not gs.combat.has_fight():
		return false
	var you := gs.player.pos()
	for dir: String in PlayerState.DIRS:
		var id := gs.combat.at(gs.player.area, you + (PlayerState.DIRS[dir] as Vector2i))
		if id != "" and gs.combat.monsters[id]["state"] == CombatState.HOSTILE:
			Commands.attack(gs, _db, dir)
			return true
	if gs.player.held != "":
		for id in gs.combat.in_state(CombatState.HOSTILE):
			if Combat._dist(you, CombatState.pos_of(gs.combat.monsters[id])) \
					<= int(_db.combat.items[gs.player.held]["throw_range"]):
				Commands.throw(gs, _db, id)
				return true
	Commands.block(gs, _db)
	return true


## A stone in hand at the loose stones, and a pack of 3 Goblins 6 tiles south.
func _pack_fight_start() -> GameState:
	var gs := _game_at(SEED, "floodplains_south", Vector2i(14, 9))
	_calm(gs)
	assert_eq(Commands.take(gs, _db, "loose_stones_1"), "")
	var group := ""
	for x in [13, 14, 15]:
		var id := Combat.add_monster(gs, _db, "goblin_grunt", Vector2i(x, 15), CombatState.IDLE,
				"", group)
		group = gs.combat.monsters[id]["group"]
	for m: Dictionary in gs.combat.monsters.values():
		m["pack"] = 3
	return gs


## One command: wait for the pack to see you, or a bot turn. False when
## the bot is done (knocked out).
func _step(gs: GameState) -> bool:
	if not gs.combat.has_fight():
		Commands.wait(gs, _db, 6)
		return true
	return _bot_turn(gs)


## Plays until the fight has started and ended. Returns the number of commands.
func _fight(gs: GameState) -> int:
	var started := false
	for i in MAX_TURNS:
		if gs.combat.has_fight():
			started = true
		elif started:
			return i
		if not _step(gs):
			return i
	return MAX_TURNS


func test_the_real_spawn_tables_make_all_three_enemy_types() -> void:
	var types := {}
	for seed_value in 20:
		var gs := _game_at(seed_value, "floodplains_south", Vector2i(16, 1))
		for m: Dictionary in gs.combat.monsters.values():
			assert_ne(m["spawn"], "")
			types[m["type"]] = true
		# 08:00: the goblins come for the fruit.
		gs.combat.spawn_last.clear()
		gs.combat.monsters.clear()
		gs.clock.advance(120)
		MonsterSim.spawn_check(gs, _db)
		for m: Dictionary in gs.combat.monsters.values():
			types[m["type"]] = true
	assert_eq(types.keys().size(), 3, "Rock Crab, Goblins and Razorbeak: %s" % [types.keys()])


func test_goblins_raid_the_hill_only_while_their_chieftain_lives() -> void:
	var raids := 0
	for seed_value in 20:
		var gs := GameState.new_game(seed_value, _db)
		gs.clock.advance(14 * 60)  # day 8, 20:00
		gs.player.place("inn_hill", Vector2i(16, 12))
		Commands.settle(gs, _db)
		if not gs.combat.monsters.is_empty():
			raids += 1
			for m: Dictionary in gs.combat.monsters.values():
				assert_eq(m["type"], "goblin_grunt")
		gs.flags["goblin_tribe.leaderless"] = true
		gs.combat.spawn_last.clear()
		gs.combat.monsters.clear()
		assert_true(MonsterSim.spawn_check(gs, _db).is_empty(), "no raids once the tribe is leaderless")
	assert_gt(raids, 0)


func test_the_razorbeak_is_always_at_its_nest() -> void:
	var gs := _game_at(SEED, "floodplains_south", Vector2i(1, 11))
	var birds := gs.combat.ids().filter(func(id: String) -> bool:
		return gs.combat.monsters[id]["type"] == "razorbeak")
	assert_eq(birds.size(), 1)
	assert_eq(CombatState.pos_of(gs.combat.monsters[birds[0]]), Vector2i(21, 16))


func test_a_seed_core_sends_a_rock_crab_running() -> void:
	var gs := _game_at(SEED, "floodplains_south", Vector2i(5, 19))
	_calm(gs)
	assert_eq(Commands.take(gs, _db, "blue_fruit_tree_1"), "")
	assert_eq(gs.player.held, "seed_core")
	var crab := Combat.add_monster(gs, _db, "rock_crab", Vector2i(7, 19), CombatState.HIDDEN)
	assert_true(Commands.move(gs, _db, "e")["moved"])
	for i in 6:
		if Combat.in_danger(gs):
			break
		Commands.wait(gs, _db, 6)
	assert_true(Combat.in_danger(gs), "the crab came out")
	assert_eq(Commands.throw(gs, _db, crab)["error"], "")
	assert_eq(gs.combat.monsters[crab]["state"], CombatState.FLEE)
	assert_has(gs.combat.lines, "The Rock Crab panics and backs away.")
	for i in 60:
		if not gs.combat.has_fight():
			break
		Commands.wait(gs, _db, 6)
	assert_false(gs.combat.has_fight())
	var throws := _records(gs, "throw_object")
	assert_eq(throws.size(), 1)
	assert_eq(throws[0]["outcome"], "success", "the crab ran: a win")
	assert_true((throws[0]["tags"] as Dictionary).has("combat.thrown"))
	assert_true((throws[0]["tags"] as Dictionary).has("combat.improvise"))


func test_a_goblin_pack_fight_ends_and_leaves_records() -> void:
	var gs := _pack_fight_start()
	var turns := _fight(gs)
	assert_lt(turns, MAX_TURNS, "the fight ended")
	assert_false(gs.combat.has_fight())
	assert_gt(_records(gs, "attack_melee").size(), 0)
	assert_eq(_records(gs, "throw_object").size(), 1, "the stone")
	assert_true(gs.clock.day() == 8 or gs.player.area == "inn_interior",
			"won on the spot, or knocked out and carried to the inn")


func test_the_same_seed_gives_the_same_fight_and_save_load_plays_on_the_same() -> void:
	var a := _pack_fight_start()
	for i in 6:
		_step(a)
	assert_true(a.combat.has_fight(), "saved in the middle of the fight")
	var saved := a.to_json()
	_fight(a)
	var b := _pack_fight_start()
	for i in 6:
		_step(b)
	_fight(b)
	assert_eq(a.to_json(), b.to_json(), "same seed, same game")
	var c := GameState.from_json(saved)
	_fight(c)
	assert_eq(c.to_json(), a.to_json(), "a loaded game plays on the same")
