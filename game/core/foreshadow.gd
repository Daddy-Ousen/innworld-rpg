## Signposts (M31.0, ADR 0044 "M31.0"): talk of the town before a big day. A
## canon event's optional `foreshadow` {"days_before", "text", "where"?,
## "hours"?} shows from window.earliest - days_before to the event's last
## window day (with delays) while the event is pending and not staged yet,
## nothing makes it fail for good (Director.evaluate: no hard fail), and none
## of its stage's unless_flags is set. `where` and `hours` default to the
## stage's area and hours. The text never tells the outcome. Read only: the
## morning page (SystemMessages) and the journal ("Coming up") show it.
class_name Foreshadow
extends RefCounted


## The signposts that show today, soonest first: [{"event", "text", "where",
## "hours", "day" (canon day the window opens)}].
static func coming(gs: GameState, db: DataDb) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var w := gs.world
	var today := gs.clock.day()
	for id in db.canon.foreshadows:
		var ev: Dictionary = db.canon.events[id]
		var f: Dictionary = ev["foreshadow"]
		var from := int(ev["window"]["earliest"])
		if w.status(id) != WorldState.PENDING or w.staged.has(id) \
				or today < from - int(f["days_before"]) or today > w.latest(id, ev):
			continue
		var st: Dictionary = ev.get("stage", {})
		if (st.get("unless_flags", []) as Array).any(func(fl: String) -> bool: return gs.flags.get(fl, false)):
			continue
		var fails: Array = Director.evaluate(gs, db, id)["fails"]
		if fails.any(func(x: Dictionary) -> bool: return x["kind"] == Director.FAIL_HARD):
			continue
		out.append({"event": id, "text": String(f["text"]), "where": String(f.get("where", st.get("area", ""))),
			"hours": (f.get("hours", st.get("hours", [0, 24])) as Array).map(func(h: Variant) -> int: return int(h)),
			"day": from})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["day"] < b["day"] or (a["day"] == b["day"] and a["hours"][0] < b["hours"][0]))
	return out


## The map's name, or its id.
static func place(db: DataDb, area: String) -> String:
	return String(db.maps.areas.get(area, {}).get("name", area))


## "18:00 – 23:00"; hour 24 is "00:00".
static func hours_text(hours: Array) -> String:
	return "%02d:00 – %02d:00" % [int(hours[0]) % 24, int(hours[1]) % 24]


## When it comes, from today: "today", "tomorrow" or "in N days".
static func when_text(gs: GameState, e: Dictionary) -> String:
	var days := int(e["day"]) - gs.clock.day()
	if days <= 0:
		return "today"
	return "tomorrow" if days == 1 else "in %d days" % days


## The morning page's lines: "<text> (tomorrow, <place>, 18:00 – 23:00)".
static func morning_lines(gs: GameState, db: DataDb) -> Array[String]:
	var out: Array[String] = []
	for e in coming(gs, db):
		out.append("%s (%s, %s, %s)" % [e["text"], when_text(gs, e), place(db, e["where"]), hours_text(e["hours"])])
	return out
