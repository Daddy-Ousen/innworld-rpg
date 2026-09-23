## Night resolution pipeline (DESIGN §2). Fixed order; each step works on
## GameState only. Step 7 (relationship decay) comes later.
class_name Night
extends RefCounted


## Runs one night: the player sleeps, or collapses (`collapsed` = true,
## also for being knocked out). Returns
## {"days_passed": int, "records": int, "offers": Array[String], "lines": Array[String],
##  "events": Array[Dictionary]} (history entries the director added tonight).
## The lines are also stored in gs.morning for the morning summary.
static func run(gs: GameState, db: DataDb, collapsed: bool = false) -> Dictionary:
	var lines: Array[String] = []
	if collapsed:
		lines.append("You collapsed. The System still works while you sleep.")
	# 1. Close the day's action log.
	var records := close_day(gs)
	# 2. XP resolution → level-ups → skills.
	lines.append_array(resolve_xp(gs, db, records))
	# 3. Class offers.
	var budget := int(db.rules["offers"]["max_per_night"])
	var offered := ClassSystem.make_offers(gs, db, ClassSystem.KIND_NEW, budget)
	# 4. Class loss and consolidation.
	lines.append_array(ClassSystem.check_loss(gs, db, gs.clock.day()))
	offered.append_array(ClassSystem.make_offers(gs, db, ClassSystem.KIND_CONSOLIDATION,
			budget - offered.size()))
	for id in offered:
		lines.append("Class offered: %s. Accept or decline." % db.classes[id]["name"])
	# 5. World director: canon events up to the day before the wake day.
	var history_before := gs.world.history.size()
	lines.append_array(Director.run(gs, db, gs.clock.wake_day(db.rules["clock"], collapsed) - 1))
	var events := gs.world.history.slice(history_before)
	# 6. Off-screen sim: NPCs go where their goals put them at wake time
	#    (the dead are gone).
	var wake := gs.clock.total_minutes + gs.clock.sleep_length(db.rules["clock"], collapsed)
	NpcSim.advance_to(gs, db, wake * 60 + gs.player.sub_seconds)
	# 8. Advance to the next day and keep the morning summary.
	var days := gs.clock.sleep(db.rules["clock"], collapsed)
	gs.morning = lines.duplicate()
	return {"days_passed": days, "records": records.size(), "offers": offered, "lines": lines,
			"events": events}


## Step 1: returns the records made since the last night, and starts a new day.
static func close_day(gs: GameState) -> Array[Dictionary]:
	var start := gs.progression.day_start
	var out: Array[Dictionary] = []
	for r: Dictionary in gs.action_log.records:
		if int(r["time"]) >= start:
			out.append(r)
	gs.progression.day_start = gs.clock.total_minutes
	return out


## Step 2: feeds the records into classes and pools, then levels up held
## classes (in the order gained) and rolls a skill for each new level.
static func resolve_xp(gs: GameState, db: DataDb, records: Array[Dictionary]) -> Array[String]:
	var p := gs.progression
	var level_rules: Dictionary = db.rules["levels"]
	var blocked_before := {}
	for id: String in p.classes:
		blocked_before[id] = Levels.is_blocked(p, id, level_rules)
	for r in records:
		ClassSystem.feed(gs, db, r)
	var lines: Array[String] = []
	for id: String in p.classes:
		var name: String = db.classes[id]["name"]
		for level in Levels.level_up(p, id, level_rules):
			lines.append("%s reached level %d." % [name, level])
			var skill := SkillSystem.on_level(gs, db, id, level)
			if skill != "":
				lines.append("Skill gained: %s." % db.skills[skill]["name"])
		if Levels.is_blocked(p, id, level_rules) and not blocked_before[id]:
			lines.append("%s needs a breakthrough to reach level %d." % [name, p.level_of(id) + 1])
	return lines
