extends GutTest
## M8.7 stages on the real Book 2 data: on day 69 the Snow Golems attack on
## the plain and Toren pulls a sledding crowd on the inn's hill (a scene);
## on day 71, in Celum, the muggers wait on the square and the Brilliant
## Swords start a bar fight in the Frenzied Hare. The game is slept to day
## 69 once (before_all); each test starts from a copy of that save.

const SEED := 20260926
const GOLEMS := "b2.snow_golems_attack_erins_sledge"
const SLEDS := "b2.toren_pulls_a_sledding_crowd"
const MUGGERS := "b2.erin_beats_the_celum_muggers"
const BAR_FIGHT := "b2.bar_fight_with_the_brilliant_swords"

var _db: DataDb
var _day69 := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])
	var gs := GameState.new_game(SEED, _db, "celum")
	ToyCanon.sleep_through(gs, _db, 68)
	_day69 = gs.to_json()


func _copy(day: int) -> GameState:
	var gs := GameState.from_json(_day69)
	ToyCanon.sleep_through(gs, _db, day - 1)
	assert_eq(gs.clock.day(), day)
	return gs


## Stands at `pos` in `area` and waits (10 minutes a step, up to 20 hours)
## until the event's stage starts.
func _wait_for(gs: GameState, event: String, area: String, pos: Vector2i) -> void:
	gs.player.place(area, pos)
	Commands.settle(gs, _db)
	for i in 120:
		if gs.world.staged.has(event):
			break
		assert_true(Commands.wait(gs, _db, 600) >= 0, "wait")
	assert_true(gs.world.staged.has(event), "%s is staged" % event)


func _foes(gs: GameState, enemy: String) -> int:
	return gs.combat.ids().filter(func(id: String) -> bool: return gs.combat.monsters[id]["type"] == enemy).size()


func _where(gs: GameState, id: String) -> String:
	var n: Dictionary = gs.npcs.npcs.get(id, {})
	return "" if n.is_empty() else String(n["area"])


func test_the_new_stages_are_loaded() -> void:
	for id: String in [GOLEMS, SLEDS, MUGGERS, BAR_FIGHT]:
		assert_has(_db.canon.stages, id)


func test_snow_golems_attack_on_the_plain() -> void:
	var gs := _copy(69)
	_wait_for(gs, GOLEMS, "floodplains_south", Vector2i(16, 4))
	assert_eq(_foes(gs, "snow_golem"), 3)


func test_toren_pulls_a_sledding_crowd() -> void:
	var gs := _copy(69)
	_wait_for(gs, SLEDS, "inn_hill", Vector2i(17, 12))
	assert_eq(gs.combat.ids().filter(func(id: String) -> bool: return gs.combat.monsters[id]["stage"] == SLEDS).size(), 0,
			"a scene, not a fight")
	for id: String in ["toren", "selys", "krshia"]:
		assert_eq(_where(gs, id), "inn_hill", id)


func test_muggers_on_the_celum_square() -> void:
	var gs := _copy(71)
	assert_true(gs.flags.has("erin.stranded_north"), "Toren left Erin")
	_wait_for(gs, MUGGERS, "celum_square", Vector2i(6, 10))
	assert_eq(_foes(gs, "celum_mugger"), 3)


func test_bar_fight_in_the_frenzied_hare() -> void:
	var gs := _copy(71)
	gs.player.place("celum_frenzied_hare", Vector2i(10, 10))
	Commands.settle(gs, _db)
	while gs.clock.minute() < 18 * 60:
		assert_true(Commands.wait(gs, _db, 3600) >= 0, "wait")
	_wait_for(gs, BAR_FIGHT, "celum_frenzied_hare", Vector2i(10, 10))
	assert_eq(_foes(gs, "brilliant_swords_adventurer"), 5)
	assert_eq(_where(gs, "erin_solstice"), "celum_frenzied_hare", "Erin is in the fight")
