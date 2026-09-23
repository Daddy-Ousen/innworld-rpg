extends GutTest
## M5 "Done when" (ROADMAP): from a new game the player walks to the
## Floodplains, takes a seed core, meets all 3 enemy types from the spawn
## tables, attacks with fists and an item, blocks, throws, scares a Rock
## Crab, flees a Razorbeak, is knocked out once and wakes at 06:00 in the
## inn with low HP. That night's records carry combat.melee, combat.block,
## combat.thrown, combat.improvise and running.escape. The same seed gives
## the same game, and a save/load in the middle of a fight plays on the same.
## Combat goes through the main scene (bump attacks, B, T, X, the use menu's
## Take), so the knock-out opens the System dialog.

const SEED := 2
const DAY := 8
const TAGS := ["combat.melee", "combat.block", "combat.thrown", "combat.improvise", "running.escape"]
const MAX_STEPS := 400
const MAX_TURNS := 300
const NEST := Vector2i(21, 16)
## Where the player waits for the Goblins' morning raid on the orchard.
const RAID_SPOT := Vector2i(7, 12)
const SAVE_AT := 3

var _session: Node
var _db: DataDb
var _main: Node
## Monster types met (from the spawn tables, out of hiding).
var _met := {}
## All combat text seen.
var _lines: Array[String] = []
## The game saved in the middle of the Goblin fight.
var _saved := ""
## The first System page after the knock-out.
var _first_page: Dictionary = {}


func before_each() -> void:
	_session = get_node_or_null("/root/Session")
	if _session != null:
		_db = _session.db


func _gs() -> GameState:
	return _session.gs


## True once the knock-out night has passed.
func _down() -> bool:
	return _gs().clock.day() > DAY


## After every command: note the monsters met and the combat text.
func _note() -> void:
	for m: Dictionary in _gs().combat.monsters.values():
		if m["spawn"] != "" and m["state"] != CombatState.HIDDEN:
			_met[m["type"]] = true
	_lines.append_array(_gs().combat.lines)
	if _main.dialog.visible and _first_page.is_empty():
		_first_page = _main.dialog.current


func _step(dir: String) -> void:
	_main.step(dir)
	_note()


func _obj(id: String) -> Vector2i:
	for o: Dictionary in _db.maps.areas[_gs().player.area]["objects"]:
		if o["id"] == id:
			return Vector2i(int(o["at"][0]), int(o["at"][1]))
	return Vector2i(-1, -1)


## Walks to any tile of `goals`, around NPCs and monsters. Stops (false)
## when enemies are near (unless `through_danger`), or after the knock-out.
func _walk(goals: Dictionary, through_danger: bool = false) -> bool:
	for i in MAX_STEPS:
		var gs := _gs()
		if goals.has(gs.player.pos()):
			return true
		if _down() or (Combat.in_danger(gs) and not through_danger):
			return false
		var avoid := {}
		for id in gs.npcs.in_area(gs.player.area):
			avoid[NpcRoster.pos_of(gs.npcs.npcs[id])] = true
		for m: Dictionary in gs.combat.monsters.values():
			avoid[CombatState.pos_of(m)] = true
		var found := Pathfind.path(_db.maps, gs.player.area, gs.player.pos(), goals, avoid)
		_step(found["steps"][0] if found["found"] and not (found["steps"] as Array).is_empty() else _main.WAIT)
	return false


## Walkable tiles within `most` king moves of `at` (not `at` itself).
func _near(at: Vector2i, most: int) -> Dictionary:
	var out := {}
	for dy in range(-most, most + 1):
		for dx in range(-most, most + 1):
			var p := at + Vector2i(dx, dy)
			if p != at and _db.maps.is_walkable(_gs().player.area, p):
				out[p] = true
	return out


## The direction of a hostile monster next to the player, or "".
func _hostile_dir() -> String:
	var gs := _gs()
	for dir: String in PlayerState.DIRS:
		var id := gs.combat.at(gs.player.area, gs.player.pos() + (PlayerState.DIRS[dir] as Vector2i))
		if id != "" and gs.combat.monsters[id]["state"] == CombatState.HOSTILE:
			return dir
	return ""


func _of_type(type: String) -> String:
	for id in _gs().combat.ids():
		if _gs().combat.monsters[id]["type"] == type:
			return id
	return ""


## Waits (6 s at a time) while a fight is on.
func _wait_out_fight() -> void:
	for i in MAX_TURNS:
		if not _gs().combat.has_fight() or _down():
			return
		_step(_main.WAIT)


## Bandages until full HP (no enemies near).
func _heal() -> void:
	var gs := _gs()
	for i in 5:
		if Combat.hp(gs, _db) >= Stats.max_hp(gs, _db):
			return
		Commands.perform(gs, _db, "bandage_wound")
	_session.changed()


## Takes a seed core, finds the hidden Rock Crab of the valley, and scares
## it off with the seed core (T). Returns "" or what went wrong.
func _scare_a_crab() -> String:
	var gs := _gs()
	if not _walk(Pathfind.around(_obj("blue_fruit_tree_1"))):
		return "walk to the blue fruit tree"
	_main.use("blue_fruit_tree_1", Interact.TAKE)
	_note()
	if gs.player.held != "seed_core":
		return "take a seed core"
	var crab := _of_type("rock_crab")
	for i in 14:
		if crab != "":
			break
		Commands.wait(gs, _db, 3600)
		crab = _of_type("rock_crab")
	if crab == "":
		return "no Rock Crab spawned"
	var goals := {}
	for dir: String in PlayerState.DIRS:
		goals[CombatState.pos_of(gs.combat.monsters[crab]) + (PlayerState.DIRS[dir] as Vector2i)] = true
	_walk(goals)
	for i in 5:
		if Combat.in_danger(gs):
			break
		_step(_main.WAIT)
	if not Combat.in_danger(gs) or not gs.combat.monsters.has(crab):
		return "the crab did not come out"
	_main.throw()
	_note()
	if not _lines.has("The Rock Crab panics and backs away."):
		return "the crab was not scared"
	_wait_out_fight()
	return "" if not gs.combat.has_fight() and not _down() else "the crab fight did not end"


## Takes a stone, goes near the Razorbeak's nest, hits the bird once with
## the stone and runs until it gives up. Returns "" or what went wrong.
func _flee_the_razorbeak() -> String:
	var gs := _gs()
	if not _walk(Pathfind.around(_obj("loose_stones_1"))):
		return "walk to the stones"
	_main.use("loose_stones_1", Interact.TAKE)
	_note()
	if gs.player.held != "stone":
		return "take a stone"
	_walk(_near(NEST, 3))
	var hit := false
	for i in 30:
		var dir := _hostile_dir()
		if dir != "":
			_step(dir)
			hit = true
			break
		_main.block()
		_note()
	if not hit or _of_type("razorbeak") == "":
		return "no swing at the Razorbeak"
	var fled := _count("flee_danger")
	if not _walk(Pathfind.around(_obj("loose_stones_1")), true):
		return "could not run"
	_wait_out_fight()
	if gs.combat.has_fight() or _down():
		return "the Razorbeak fight did not end"
	return "" if _count("flee_danger") > fled else "the Razorbeak fight was not a flight"


## Waits for the Goblins' morning raid, then fights them with fists and
## blocks. Saves the game SAVE_AT turns into the fight when `save`. The
## fight may end in the knock-out. Returns "" or what went wrong.
func _fight_goblins(save: bool = false) -> String:
	var gs := _gs()
	if gs.player.held != "":
		_main.drop()
		_note()
	if not Combat.in_danger(gs):
		_walk({RAID_SPOT: true})
	for i in 5 * 60:
		if Combat.in_danger(gs) or gs.clock.minute() >= 12 * 60:
			break
		Commands.wait(gs, _db, 60)
		_note()
	if not Combat.in_danger(gs) or _of_type("goblin_grunt") == "":
		return "no Goblin raid"
	for i in MAX_TURNS:
		if _down() or not gs.combat.has_fight():
			break
		if save and i == SAVE_AT:
			_saved = gs.to_json()
		var dir := _hostile_dir()
		if dir != "" and int(gs.combat.fight["blocks"]) > 0:
			_step(dir)
		else:
			_main.block()
			_note()
	return "" if _down() or not gs.combat.has_fight() else "the Goblin fight did not end"


## Stands by the Razorbeak's nest until it knocks the player out (unless
## the Goblins already did).
func _get_knocked_out() -> String:
	if _down():
		return ""
	_walk(_near(NEST, 2))
	for i in MAX_TURNS:
		if _down():
			return ""
		_step(_main.WAIT)
	return "not knocked out"


## Answers the System dialog (accepts the first offer, if any).
func _close_dialog() -> void:
	var dialog: SystemDialog = _main.dialog
	while dialog.visible:
		dialog.choose(SystemMessages.ACCEPT if dialog.current["kind"] == SystemMessages.OFFER
				else SystemMessages.NEXT)


## The whole day from a new game. Returns "" or what went wrong.
func _play(seed_value: int, save: bool = false) -> String:
	_met.clear()
	_lines.clear()
	_first_page = {}
	_session.set_state(GameState.new_game(seed_value, _db))
	if not ToyMaps.walk_to_area(_gs(), _db, "floodplains_south"):
		return "walk to the Floodplains"
	_session.changed()
	for phase: Callable in [_scare_a_crab, _flee_the_razorbeak]:
		var err: String = phase.call()
		if err != "":
			return err
		_heal()
	var why := _fight_goblins(save)
	if why == "":
		why = _get_knocked_out()
	_close_dialog()
	return why


func _count(action_id: String) -> int:
	return _gs().action_log.records.filter(func(r: Dictionary) -> bool:
		return r["action_id"] == action_id).size()


func _day_records() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for r: Dictionary in _gs().action_log.records:
		if int(r["day"]) == DAY:
			out.append(r)
	return out


func test_m5_done() -> void:
	if _session == null:
		fail_test("no Session autoload")
		return
	_main = add_child_autofree(load("res://world/main.tscn").instantiate())
	assert_eq(_play(SEED, true), "")
	var gs := _gs()
	assert_eq(_met.keys().size(), 3, "Rock Crab, Razorbeak and Goblins: %s" % [_met.keys()])
	assert_has(_lines, "The Rock Crab panics and backs away.")
	# Knocked out once; woke at 06:00 in the inn with low HP.
	assert_eq(_first_page.get("kind", ""), SystemMessages.KNOCKOUT)
	assert_eq(gs.clock.day(), DAY + 1)
	assert_eq(gs.clock.time_string(), "06:00")
	assert_eq(gs.player.area, "inn_interior")
	assert_true(Hud.is_low(gs, _db), "low HP: %s" % Hud.health(gs, _db))
	var inn: String = _db.canon.locations[Movement.location_at(gs, _db)]["name"]
	assert_eq(_first_page.get("lines", [""])[-1], "You wake at %s with %d HP." % [inn, Combat.hp(gs, _db)])
	# That night's records.
	var tags := {}
	var fists := false
	var improvised := false
	for r: Dictionary in _day_records():
		tags.merge(r["tags"])
		if r["action_id"] == "attack_melee":
			if (r["tags"] as Dictionary).has("combat.improvise"):
				improvised = true
			else:
				fists = true
	for tag: String in TAGS:
		assert_true(tags.has(tag), tag)
	assert_true(fists, "a punch")
	assert_true(improvised, "a swing with an item")
	assert_eq(_count("throw_object"), 1, "one throw: the seed core")
	# Same seed, same game; a save in the middle of the Goblin fight plays on the same.
	var done := gs.to_json()
	assert_ne(_saved, "", "saved in the middle of the fight")
	var saved := _saved
	assert_eq(_play(SEED), "")
	assert_eq(_gs().to_json(), done, "same seed, same game")
	_session.set_state(GameState.from_json(saved))
	assert_true(_gs().combat.has_fight(), "the loaded game is in the fight")
	assert_eq(_fight_goblins(), "")
	assert_eq(_get_knocked_out(), "")
	_close_dialog()
	assert_eq(_gs().to_json(), done, "a loaded game plays on the same")

