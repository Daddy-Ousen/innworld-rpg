extends GutTest
## M6 "Done when" (ROADMAP): a new player plays two weeks, gets a class and
## changes one canon event. Through the main scene: walk from the Liscor
## gate to the inn, work there every day and sleep in the inn bed, answer
## the System (accept the first offer). On day 9 the Goblin Chieftain comes
## into the inn (a canon stage); the player fights him with a chair next to
## Erin and wins, so b1.erin_kills_chieftain changes. A save in the middle
## of that fight plays on the same after a load, and a save slot written on
## day 15 loads back the same game. The game ends on the morning of day 22
## (days 8–21 played).

const SEED := 1
const FIRST_DAY := 8
const LAST_DAY := 21
const CHIEFTAIN_EVENT := "b1.erin_kills_chieftain"
const WORK := [["stove", "cook_stew"], ["wash_basin", "wash_dishes"], ["stove", "cook_pasta"],
	["broom", "sweep_floor"], ["stove", "bake_bread"], ["bed", "clean_room"]]
const END_HOUR := 20
const LOW_HP := 5
const MAX_STEPS := 400
const MAX_TURNS := 300
const SAVE_AT := 3
const SLOT := "1"
const SLOT_DAY := 15

var _session: Node
var _db: DataDb
var _main: Node
## The game saved SAVE_AT turns into the Chieftain fight, and the game
## right after that fight.
var _saved := ""
var _after_fight := ""
## Combat text seen.
var _lines: Array[String] = []
## Offers answered, in order.
var _offers: Array[String] = []


func before_each() -> void:
	_session = get_node_or_null("/root/Session")
	if _session != null:
		_db = _session.db
		for slot: String in SaveSlots.all():
			SaveSlots.delete(_session.save_dir, slot)


func _gs() -> GameState:
	return _session.gs


func _step(dir: String) -> void:
	_main.step(dir)
	_lines.append_array(_gs().combat.lines)


func _obj(id: String) -> Vector2i:
	for o: Dictionary in _db.maps.areas[_gs().player.area]["objects"]:
		if o["id"] == id:
			return Vector2i(int(o["at"][0]), int(o["at"][1]))
	return Vector2i(-1, -1)


## Walks to any tile of `goals` around NPCs and monsters. False when a
## fight starts or after MAX_STEPS.
func _walk(goals: Dictionary) -> bool:
	for i in MAX_STEPS:
		var gs := _gs()
		if goals.has(gs.player.pos()):
			return true
		if Combat.in_danger(gs):
			return false
		var found := Pathfind.path(_db.maps, gs.player.area, gs.player.pos(), goals,
				MonsterSim.taken(gs, ""))
		_step(found["steps"][0] if found["found"] and not (found["steps"] as Array).is_empty() else _main.WAIT)
	return false


## The direction of a hostile monster next to the player, or "".
func _hostile_dir() -> String:
	var gs := _gs()
	for dir: String in PlayerState.DIRS:
		var id := gs.combat.at(gs.player.area, gs.player.pos() + (PlayerState.DIRS[dir] as Vector2i))
		if id != "" and gs.combat.monsters[id]["state"] == CombatState.HOSTILE:
			return dir
	return ""


## Fights until the fight is over: attacks a hostile monster next to the
## player (blocks when HP is low), else steps towards the nearest one.
## Saves the game SAVE_AT turns in when `save`. Returns "" or what went wrong.
func _fight(save: bool) -> String:
	for i in MAX_TURNS:
		var gs := _gs()
		if Combat.is_down(gs) or not gs.combat.has_fight():
			break
		if save and i == SAVE_AT:
			_saved = gs.to_json()
		var dir := _hostile_dir()
		if dir != "":
			if Combat.hp(gs, _db) <= LOW_HP:
				_main.block()
				_lines.append_array(gs.combat.lines)
			else:
				_step(dir)
			continue
		var foe := Combat.nearest_foe(gs)
		if foe == "" or gs.combat.monsters[foe]["state"] != CombatState.HOSTILE:
			_step(_main.WAIT)
			continue
		var found := Pathfind.path(_db.maps, gs.player.area, gs.player.pos(),
				Pathfind.around(CombatState.pos_of(gs.combat.monsters[foe])), MonsterSim.taken(gs, ""))
		_step(found["steps"][0] if found["found"] and not (found["steps"] as Array).is_empty() else _main.WAIT)
	var gs := _gs()
	if gs.clock.day() > FIRST_DAY + 1 or Combat.is_down(gs):
		return "knocked out in the fight"
	return "" if not gs.combat.has_fight() else "the fight did not end"


## Answers the System dialog: accepts the first offer, declines the rest.
func _close_dialog() -> void:
	var dialog: SystemDialog = _main.dialog
	while dialog.visible:
		if dialog.current["kind"] == SystemMessages.OFFER:
			_offers.append(dialog.current["class"])
			if _gs().progression.classes.is_empty():
				dialog.choose(SystemMessages.ACCEPT)
			else:
				dialog.choose(SystemMessages.DECLINE)
				dialog.choose(SystemMessages.YES)
		else:
			dialog.choose(SystemMessages.NEXT)


## One day at the inn: takes a chair, then works until END_HOUR (fighting
## whatever comes in), then sleeps in the bed. Returns "" or what went wrong.
func _day() -> String:
	var gs := _gs()
	var day := gs.clock.day()
	var i := 0
	while _gs().clock.minute() < END_HOUR * 60:
		gs = _gs()
		if gs.combat.has_fight():
			var err := _fight(day == FIRST_DAY + 1 and _saved == "")
			if err != "":
				return err
			if _after_fight == "":
				_after_fight = _gs().to_json()
			continue
		if gs.player.held == "":
			if _walk(Pathfind.around(_obj("table"))):
				_main.use("table", Interact.TAKE)
			continue
		var w: Array = WORK[i % WORK.size()]
		i += 1
		if _walk(Pathfind.around(_obj(w[0]))):
			_main.use(w[0], w[1])
	if not _walk(Pathfind.around(_obj("bed"))):
		return "walk to the bed on day %d" % day
	_main.use("bed", Interact.SLEEP)
	if _gs().clock.day() != day + 1:
		return "slept through day %d" % day
	_close_dialog()
	return ""


func test_m6_done() -> void:
	if _session == null:
		fail_test("no Session autoload")
		return
	_session.set_state(GameState.new_game(SEED, _db))
	_main = add_child_autofree(load("res://world/main.tscn").instantiate())
	var gs := _gs()
	assert_eq(gs.clock.day(), FIRST_DAY)
	assert_eq(gs.player.area, "liscor_gate")
	for area: String in ["floodplains_south", "inn_hill", "inn_interior"]:
		assert_true(ToyMaps.walk_to_area(_gs(), _db, area), "walk to %s" % area)
	_session.changed()

	while _gs().clock.day() <= LAST_DAY:
		if _gs().clock.day() == SLOT_DAY and not SaveSlots.exists(_session.save_dir, SLOT):
			var before := _gs().to_json()
			assert_eq(_session.save_slot(SLOT), OK)
			_main.use("broom", "sweep_floor")  # something to undo
			assert_true(_session.load_slot(SLOT))
			assert_eq(_gs().to_json(), before, "the slot loads back the same game")
		var err := _day()
		if err != "":
			fail_test(err)
			return
	gs = _gs()
	assert_eq(gs.clock.day(), LAST_DAY + 1, "two weeks played")

	# The Chieftain came on day 9 and the player won next to Erin.
	assert_eq(gs.world.staged, {CHIEFTAIN_EVENT: FIRST_DAY + 1})
	assert_true(_lines.any(func(l: String) -> bool: return l.begins_with("Erin Solstice hits the Goblin Chieftain")))
	assert_has(_lines, "The Goblin Chieftain dies.")
	assert_eq(gs.world.status(CHIEFTAIN_EVENT), Director.CHANGED, "one canon event changed")
	assert_gt(gs.world.drift, 0.0)
	var hook_news: String = _db.canon.events[CHIEFTAIN_EVENT]["hooks"][0]["news"]
	assert_has(Journal.changes(gs, _db), "Day %d: %s" % [FIRST_DAY + 1, hook_news], "the journal shows it")

	# A class, and some levels.
	assert_false(gs.progression.classes.is_empty(), "a class: offers %s" % [_offers])
	var cls: String = gs.progression.classes.keys()[0]
	gut.p("class %s level %d; offers %s" % [cls, gs.progression.level_of(cls), _offers])
	assert_gte(gs.progression.level_of(cls), 4, "levels come at a fair pace")

	# A save in the middle of the Chieftain fight plays on the same.
	assert_ne(_saved, "")
	assert_ne(_after_fight, "")
	_session.set_state(GameState.from_json(_saved))
	assert_true(_gs().combat.has_fight(), "the loaded game is in the fight")
	assert_eq(_fight(false), "")
	assert_eq(_gs().to_json(), _after_fight, "a loaded fight plays on the same")
