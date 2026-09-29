extends GutTest
## M14.8 probe (ADR 0021): how fast does a hard inn worker level, over several
## seeds? Plays the scripted inn day of `sim_30_days` for 22 days, answers every
## offer with "accept the first, decline the rest", and logs class, level and max
## HP by day. Loose asserts only: the numbers are game balance, not canon.
## Set BALANCE_LOG to a file path to get the table.

const SEEDS := [1, 20260923, 14008]
const DAYS := 22

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()


func _play_day(gs: GameState, day: int) -> void:
	var inn := {"guests": mini(2 + day, 20), "location": "wandering_inn"}
	var plan: Array = [
		["cook_stew", {"context": inn}], ["serve_guests", {"context": inn}],
		["clean_room", {"context": inn}], ["sweep_floor", {}], ["wash_dishes", {}],
		["talk_with_guest", {"context": inn}], ["carry_water", {}],
	]
	plan.append_array([["bake_bread", {}], ["chop_wood", {}]] if day % 2 == 0 else [["cook_pasta", {"context": inn}]])
	for step: Array in plan:
		Commands.perform(gs, _db, step[0], step[1])


## Plays DAYS days. Returns {"first_class_night": int, "rows": Array[String], "gs": GameState}.
func _run(seed_: int) -> Dictionary:
	var gs := GameState.new_game(seed_, _db)
	var first := -1
	var rows: Array[String] = []
	for day in range(1, DAYS + 1):
		_play_day(gs, day)
		var night := Commands.sleep(gs, _db, Rest.ANYWHERE)
		for id: String in night["offers"]:
			if gs.progression.classes.is_empty():
				Commands.accept_class(gs, _db, id)
			else:
				Commands.decline_class(gs, _db, id)
		if first < 0 and not gs.progression.classes.is_empty():
			first = day
		rows.append("seed %d night %2d  total level %2d  max hp %3d  classes %s" % [seed_, day,
				gs.progression.total_level(), Stats.max_hp(gs, _db), _classes(gs)])
	return {"first_class_night": first, "rows": rows, "gs": gs}


func _classes(gs: GameState) -> String:
	var out: Array[String] = []
	for id: String in gs.progression.classes:
		out.append("%s %d" % [id, gs.progression.level_of(id)])
	return ", ".join(out)


func test_levels_come_at_a_fair_pace_on_every_seed() -> void:
	var lines: Array[String] = []
	for s: int in SEEDS:
		var r := _run(s)
		lines.append_array(r["rows"])
		var gs: GameState = r["gs"]
		assert_gte(int(r["first_class_night"]), 1, "seed %d gets a class" % s)
		assert_lte(int(r["first_class_night"]), 3, "seed %d: first class by night 3" % s)
		assert_gte(gs.progression.total_level(), 5, "seed %d: level 5 by day 22" % s)
		assert_lte(gs.progression.total_level(), 14, "seed %d: not a runaway" % s)
	var path := OS.get_environment("BALANCE_LOG")
	if path != "":
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_string("\n".join(lines) + "\n")
