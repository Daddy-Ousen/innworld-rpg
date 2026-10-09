## Night resolution pipeline (DESIGN §2). Fixed order; each step works on
## GameState only. Step 7 is Standing.night (M14.3).
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
		knocked_out: bool = false, rest: String = Rest.BED) -> Dictionary:
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
	# 2b. Hunger (M8.6): fed today, or one more hungry night (lower max HP).
	var long_sleep_hunger := collapsed and not knocked_out
	var hunger := Economy.night(gs, db, records,
			gs.clock.wake_day(db.rules["clock"], long_sleep_hunger) > gs.clock.day())
	# 3. Class offers.
	var budget := int(db.rules["offers"]["max_per_night"])
	var offered := ClassSystem.make_offers(gs, db, ClassSystem.KIND_NEW, budget)
	# 4. Class loss and consolidation.
	progress.append_array(ClassSystem.check_loss(gs, db, gs.clock.day()))
	offered.append_array(ClassSystem.make_offers(gs, db, ClassSystem.KIND_CONSOLIDATION,
			budget - offered.size()))
	lines.append_array(progress)
	var progress_end := lines.size()
	lines.append_array(hunger)
	# 2c. The inn (M14.2): the day's takings; the guests go home.
	lines.append_array(Guests.night(gs, db))
	for id in offered:
		lines.append("Class offered: %s. Accept or decline." % db.classes[id]["name"])
	# 5. World director: canon events up to the day before the wake day.
	var history_before := gs.world.history.size()
	var news_before := gs.world.news.size()
	var keys_before := gs.progression.breakthroughs.duplicate()
	var world := Director.run(gs, db, gs.clock.wake_day(db.rules["clock"], long_sleep) - 1)
	# 5b. Canon moments (M22): a class given its key in step 5 levels up now.
	var canon_keys := resolve_canon_keys(gs, db, keys_before)
	progress.append_array(canon_keys)
	for i in canon_keys.size():
		lines.insert(progress_end + i, canon_keys[i])
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
	Combat.night(gs, db, collapsed, knocked_out, Rest.share(db, rest))
	var wake := gs.clock.total_minutes + gs.clock.sleep_length(db.rules["clock"], long_sleep)
	NpcSim.advance_to(gs, db, wake * 60 + gs.player.sub_seconds)
	Winter.night(gs, wake * 60 + gs.player.sub_seconds)
	# 7. Standing (M14.3): quiet relationships and reputations drift toward 0.
	Standing.night(gs, db)
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
## classes (in the order gained) and rolls a skill for each new level. A class
## that waits for a capstone first checks today's records for its
## breakthrough (M22, ADR 0035), so a class that reaches 9 tonight is not
## checked with today's records.
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
		var key := Breakthrough.check_records(gs, db, id, records)
		if key != "":
			lines.append(key)
		lines.append_array(level_lines(gs, db, id))
		if Levels.is_blocked(p, id, level_rules) and not blocked_before[id]:
			lines.append("%s needs a breakthrough to reach level %d." % [db.classes[id]["name"], p.level_of(id) + 1])
	return lines


## Levels the class up as far as its XP goes. Returns a line per level, the
## Skill it gained, and the breakthrough hint when it reaches the level under
## a capstone without a key.
static func level_lines(gs: GameState, db: DataDb, id: String) -> Array[String]:
	var p := gs.progression
	var level_rules: Dictionary = db.rules["levels"]
	var name: String = db.classes[id]["name"]
	var lines: Array[String] = []
	for level in Levels.level_up(p, id, level_rules):
		lines.append("%s reached level %d." % [name, level])
		var skill := SkillSystem.on_level(gs, db, id, level)
		if skill != "":
			lines.append("Skill gained: %s." % db.skills[skill]["name"])
		if level == p.level_of(id) and Breakthrough.waiting_for(p, id, level_rules) != 0:
			var hint := Breakthrough.hint(db, id)
			if hint != "":
				lines.append(hint)
	return lines


## Step 5b: classes that got a key from a canon moment in step 5 level up the
## same night. `keys_before` = Progression.breakthroughs before step 5.
static func resolve_canon_keys(gs: GameState, db: DataDb, keys_before: Array[String]) -> Array[String]:
	var p := gs.progression
	var lines: Array[String] = []
	for id: String in p.classes:
		if p.breakthroughs.has(id) and not keys_before.has(id):
			lines.append(Breakthrough.key_line(db, id, p.level_of(id)))
			lines.append_array(level_lines(gs, db, id))
	return lines
