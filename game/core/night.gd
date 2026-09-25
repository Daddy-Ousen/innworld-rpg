## Night resolution pipeline (DESIGN §2). Fixed order; each step works on
## GameState only. Step 7 (relationship decay) comes later.
class_name Night
extends RefCounted


const COLLAPSE_LINE := "You collapsed. The System still works while you sleep."
const KNOCKOUT_LINE := "You were knocked out. The System still works while you sleep."


## Runs one night: the player sleeps, or collapses (`collapsed` = true).
## Being knocked out (`knocked_out` = true, with `collapsed`) counts as a
## collapse for the System, but the player wakes at the normal wake time
## (ADR 0010). Returns
## {"days_passed": int, "records": int, "offers": Array[String], "lines": Array[String],
##  "events": Array[Dictionary], "collapsed": bool, "knocked_out": bool,
##  "progress": Array[String], "news": Array[String], "world": Array[String]}.
## `events` are the history entries the director added tonight; `news` the
## local news texts it added (M6.4). `lines` is everything in order: the
## collapse (or knock-out) line, then
## `progress` (levels, skills, class loss), one line per offer, one
## "News: ..." line per news, then
## `world` (the director's rumors and drift warning). The lines are also
## stored in gs.morning for the morning summary.
static func run(gs: GameState, db: DataDb, collapsed: bool = false,
		knocked_out: bool = false) -> Dictionary:
	collapsed = collapsed or knocked_out
	var long_sleep := collapsed and not knocked_out
	var lines: Array[String] = []
	if knocked_out:
		lines.append(KNOCKOUT_LINE)
	elif collapsed:
		lines.append(COLLAPSE_LINE)
	# 1. Close the day's action log.
	var records := close_day(gs)
	# 2. XP resolution → level-ups → skills.
	var progress := resolve_xp(gs, db, records)
	# 3. Class offers.
	var budget := int(db.rules["offers"]["max_per_night"])
	var offered := ClassSystem.make_offers(gs, db, ClassSystem.KIND_NEW, budget)
	# 4. Class loss and consolidation.
	progress.append_array(ClassSystem.check_loss(gs, db, gs.clock.day()))
	offered.append_array(ClassSystem.make_offers(gs, db, ClassSystem.KIND_CONSOLIDATION,
			budget - offered.size()))
	lines.append_array(progress)
	for id in offered:
		lines.append("Class offered: %s. Accept or decline." % db.classes[id]["name"])
	# 5. World director: canon events up to the day before the wake day.
	var history_before := gs.world.history.size()
	var news_before := gs.world.news.size()
	var world := Director.run(gs, db, gs.clock.wake_day(db.rules["clock"], long_sleep) - 1)
	var news: Array[String] = []
	for n: Dictionary in gs.world.news.slice(news_before):
		if n["kind"] == Director.NEWS:
			news.append(n["text"])
			lines.append("News: %s" % n["text"])
	var warn := Winter.warning(gs, db)
	if warn != "":
		world.append(warn)
	lines.append_array(world)
	var events := gs.world.history.slice(history_before)
	# 6. Off-screen sim. Monsters are gone and the player heals (a knocked-out
	#    player wakes at a safe place); NPCs go where their goals put them
	#    at wake time (the dead are gone).
	Combat.night(gs, db, collapsed, knocked_out)
	var wake := gs.clock.total_minutes + gs.clock.sleep_length(db.rules["clock"], long_sleep)
	NpcSim.advance_to(gs, db, wake * 60 + gs.player.sub_seconds)
	Winter.night(gs, wake * 60 + gs.player.sub_seconds)
	# 8. Advance to the next day and keep the morning summary.
	var days := gs.clock.sleep(db.rules["clock"], long_sleep)
	gs.clock.last_sleep_collapsed = collapsed
	gs.morning = lines.duplicate()
	return {"days_passed": days, "records": records.size(), "offers": offered, "lines": lines,
			"events": events, "collapsed": collapsed, "knocked_out": knocked_out,
			"progress": progress, "news": news, "world": world}


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
