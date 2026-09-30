extends GutTest
## M17.8 probe (ADR 0027): how fast does a hard fighter level, next to the inn worker of
## `sim_balance_progress`? The fighter wins or loses two Goblin fights a day on the Floodplains
## (one Goblin while the total level is below 3, two after; full HP before each, like a day of
## rest and bandages between), waits out the day indoors, sleeps, and answers every class offer
## with "accept the first, decline the rest". It logs class, level and XP by night.
## The fight XP is the hidden duress of M17.8: x0.5 when no HP was lost, x1.0 at 10% lost, more
## after that. Loose asserts: the numbers are game balance, not canon.
## Set BALANCE_LOG to a file path to get the table.

const AREA := "floodplains_south"
const SPOT := Vector2i(10, 10)
const SEEDS := [1, 20260923, 14008]
const DAYS := 22
const MAX_TURNS := 300

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()


func _hit_adjacent(gs: GameState) -> bool:
	for dir: String in PlayerState.DIRS:
		var id := gs.combat.at(gs.player.area, gs.player.pos() + (PlayerState.DIRS[dir] as Vector2i))
		if id != "" and gs.combat.monsters[id]["state"] == CombatState.HOSTILE:
			FightBot.attack(gs, _db, dir)
			return true
	return false


## One fight: `count` Goblins next to the player, who blocks below a fifth of max HP.
func _fight(gs: GameState, count: int) -> void:
	Combat.set_hp(gs, _db, 9999)
	gs.player.place(AREA, SPOT)
	Commands.settle(gs, _db)
	var placed := 0
	for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if placed < count and _db.maps.is_walkable(AREA, SPOT + d):
			Combat.add_monster(gs, _db, "goblin_grunt", SPOT + d, CombatState.HOSTILE, "", "probe")
			placed += 1
	var turns := 0
	while gs.combat.has_fight() and turns < MAX_TURNS and not Combat.is_down(gs):
		if Combat.hp(gs, _db) * 5 <= Stats.max_hp(gs, _db):
			FightBot.block(gs, _db)
		elif not _hit_adjacent(gs):
			Commands.wait(gs, _db, 6)
		turns += 1
	if gs.combat.has_fight() and not Combat.is_down(gs):
		Combat.end_fight(gs, _db, Combat.FLED)  # the bot gave up: the last Goblin ran off


func _classes(gs: GameState) -> String:
	var out: Array[String] = []
	for id: String in gs.progression.classes:
		out.append("%s %d (%.0f xp)" % [id, gs.progression.level_of(id), float(gs.progression.classes[id]["xp"])])
	return ", ".join(out)


## Plays DAYS days. Returns {"first_class_night": int, "rows": Array[String], "gs": GameState}.
## `duress` false plays the same days with the duress factor switched off (x1.0), for the table.
func _run(seed_: int, duress: bool = true) -> Dictionary:
	var saved: Variant = _db.rules["xp"]["duress"]
	if not duress:
		_db.rules["xp"].erase("duress")
	var gs := GameState.new_game(seed_, _db)
	var first := -1
	var rows: Array[String] = []
	for day in range(1, DAYS + 1):
		var n := 1 if gs.progression.total_level() < 3 else 2
		_fight(gs, n)
		_fight(gs, n)
		Combat.set_hp(gs, _db, 9999)
		gs.player.place("inn_interior", Vector2i(20, 13))
		Commands.settle(gs, _db)
		Commands.wait(gs, _db, 10 * 3600)
		var night := Commands.sleep(gs, _db, Rest.ANYWHERE)
		for id: String in night["offers"]:
			if gs.progression.classes.is_empty():
				Commands.accept_class(gs, _db, id)
			else:
				Commands.decline_class(gs, _db, id)
		if first < 0 and not gs.progression.classes.is_empty():
			first = day
		rows.append("fighter seed %d%s night %2d  total level %2d  classes %s" % [seed_,
				"" if duress else " (no duress)", day, gs.progression.total_level(), _classes(gs)])
	_db.rules["xp"]["duress"] = saved
	return {"first_class_night": first, "rows": rows, "gs": gs}


func test_a_fighter_levels_at_a_fair_pace_on_every_seed() -> void:
	var lines: Array[String] = []
	for s: int in SEEDS:
		var r := _run(s)
		lines.append_array(r["rows"])
		lines.append_array(_run(s, false)["rows"])
		var gs: GameState = r["gs"]
		assert_gt(int(r["first_class_night"]), 0, "seed %d: a class was offered" % s)
		assert_lte(int(r["first_class_night"]), 8, "seed %d: the first class comes early" % s)
		assert_gte(gs.progression.total_level(), 3, "seed %d: level 3 by day %d" % [s, DAYS])
		assert_lte(gs.progression.total_level(), 14, "seed %d: not a runaway" % s)
	_write(lines)


func _write(lines: Array[String]) -> void:
	gut.p("\n".join(lines))
	var path := OS.get_environment("BALANCE_LOG")
	if path == "":
		return
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("\n".join(lines) + "\n")
