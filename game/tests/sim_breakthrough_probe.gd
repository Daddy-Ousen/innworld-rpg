extends GutTest
## M22.4 probe (ADR 0035): does a busy player pass a capstone in play? Plays the scripted inn day
## of `sim_balance_progress` from day 1 to the end of Book 3 (day 87), answers every offer with
## "accept the first, decline the rest", and logs when the first class reaches level 9, earns its
## key, and passes level 10. Loose asserts only: the bar numbers are balance, not canon.
## Set BALANCE_LOG to a file path to get the table.

const SEEDS := [1, 20260923, 14008]
const LAST_DAY := 87
const CAPSTONE := 10
const AREA := "floodplains_south"
const SPOT := Vector2i(10, 10)
const MAX_TURNS := 300

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()


## `busy` plays a crowded inn (up to 20 guests); otherwise a quiet one (up to 4: no duress).
func _play_day(gs: GameState, day: int, busy: bool = true) -> void:
	var inn := {"guests": mini(2 + day, 20) if busy else mini(2 + day, 4), "location": "wandering_inn"}
	var plan: Array = [
		["cook_stew", {"context": inn}], ["serve_guests", {"context": inn}],
		["clean_room", {"context": inn}], ["sweep_floor", {"context": inn}], ["wash_dishes", {"context": inn}],
		["talk_with_guest", {"context": inn}], ["carry_water", {}],
	]
	plan.append_array([["bake_bread", {"context": inn}], ["chop_wood", {}]] if day % 2 == 0 else [["cook_pasta", {"context": inn}]])
	for step: Array in plan:
		Commands.perform(gs, _db, step[0], step[1])


## Returns {"level9_night", "key_night", "level10_night", "class", "rows", "gs"}.
func _run(seed_: int, style: String = "busy") -> Dictionary:
	var gs := GameState.new_game(seed_, _db)
	var out := {"level9_night": -1, "key_night": -1, "level10_night": -1, "class": "", "rows": [] as Array[String]}
	for day in range(1, LAST_DAY + 1):
		if style == "fighter":
			_fighter_day(gs)
		else:
			_play_day(gs, day, style == "busy")
		var night := Commands.sleep(gs, _db, Rest.ANYWHERE)
		for id: String in night["offers"]:
			if gs.progression.classes.is_empty():
				Commands.accept_class(gs, _db, id)
			else:
				Commands.decline_class(gs, _db, id)
		var best := _best(gs)
		var bid: String = best["id"]
		var lvl := int(best["level"])
		if out["level9_night"] < 0 and lvl >= CAPSTONE - 1:
			out["level9_night"] = day
			out["class"] = bid
		if out["key_night"] < 0 and out["class"] != "" and (gs.progression.breakthroughs.has(out["class"]) or lvl >= CAPSTONE):
			out["key_night"] = day
		if out["level10_night"] < 0 and lvl >= CAPSTONE:
			out["level10_night"] = day
		(out["rows"] as Array[String]).append("%s seed %d night %2d  total %2d  best %s %d  keys %s" % [style, seed_, day,
				gs.progression.total_level(), bid, lvl, ",".join(gs.progression.breakthroughs)])
	out["gs"] = gs
	return out


func _hit_adjacent(gs: GameState) -> bool:
	for dir: String in PlayerState.DIRS:
		var id := gs.combat.at(gs.player.area, gs.player.pos() + (PlayerState.DIRS[dir] as Vector2i))
		if id != "" and gs.combat.monsters[id]["state"] == CombatState.HOSTILE:
			FightBot.attack(gs, _db, dir)
			return true
	return false


## One fight, like `sim_balance_fighter`: Goblins next to the player, who blocks below a fifth of max HP.
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
		Combat.end_fight(gs, _db, Combat.FLED)


func _fighter_day(gs: GameState) -> void:
	var n := 1 if gs.progression.total_level() < 3 else 2
	_fight(gs, n)
	_fight(gs, n)
	Combat.set_hp(gs, _db, 9999)
	gs.player.place("inn_interior", Vector2i(20, 13))
	Commands.settle(gs, _db)
	Commands.wait(gs, _db, 10 * 3600)


func _best(gs: GameState) -> Dictionary:
	var best := {"id": "", "level": 0}
	for id: String in gs.progression.classes:
		var l := gs.progression.level_of(id)
		if l > int(best["level"]):
			best = {"id": id, "level": l}
	return best


func _describe(style: String, s: int, r: Dictionary) -> String:
	return "%s seed %d: level 9 on night %d, key on night %d, level 10 on night %d (%s)" % [style, s,
			r["level9_night"], r["key_night"], r["level10_night"], r["class"]]


func _log_lines(lines: Array[String]) -> void:
	gut.p("
".join(lines.filter(func(l: String) -> bool: return " night " not in l)))
	var path := OS.get_environment("BALANCE_LOG")
	if path != "":
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_string("
".join(lines) + "
")


func test_a_busy_inn_worker_passes_level_10_within_books_1_to_3() -> void:
	var lines: Array[String] = []
	for s: int in SEEDS:
		var r := _run(s)
		lines.append_array(r["rows"])
		lines.append(_describe("busy", s, r))
		assert_gt(int(r["level9_night"]), 0, "seed %d reaches level 9" % s)
		assert_gt(int(r["level10_night"]), 0, "seed %d passes level 10 by day %d" % [s, LAST_DAY])
	_log_lines(lines)


## A quiet inn gives no duress, so the gate holds: the key waits for a Book 3 moment, long after
## level 9. A fighter (fast, see `sim_balance_fighter`) still needs its own key.
func test_a_quiet_inn_waits_for_its_key_and_a_fighter_passes() -> void:
	var lines: Array[String] = []
	for s: int in SEEDS:
		var q := _run(s, "quiet")
		lines.append_array(q["rows"])
		lines.append(_describe("quiet", s, q))
		assert_gt(int(q["level9_night"]), 0, "quiet seed %d reaches level 9" % s)
		assert_gt(int(q["key_night"]), int(q["level9_night"]) + 10, "quiet seed %d: the gate really holds" % s)
		assert_gt(int(q["level10_night"]), 0, "quiet seed %d is not stuck for good (day %d)" % [s, LAST_DAY])
		var f := _run(s, "fighter")
		lines.append_array(f["rows"])
		lines.append(_describe("fighter", s, f))
		assert_gt(int(f["level10_night"]), 0, "fighter seed %d passes level 10 by day %d" % [s, LAST_DAY])
	_log_lines(lines)
