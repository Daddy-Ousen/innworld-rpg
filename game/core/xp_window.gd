## XP windows (M17.8, ADR 0027): hidden boosts for the big moments of the books. A canon
## event may carry `"xp_window": {"boost": 1|2|3, "hours"?: [from, to]}` next to its `stage`.
## The window is open while the event is still PENDING (it has not resolved yet: events
## resolve in the night), today lies inside its day window (with delays), and the hour
## lies inside `hours` (may wrap past midnight; none = all day). While it is open every
## action pays more XP: Xp.boost_mult(boost) from rules.xp.boosts (1 = x1.5, 2 = x2, 3 = x3).
## Two windows at once do not multiply: the highest boost counts. The player never sees
## this. It is a pure function of GameState and the canon data, so it needs no save data.
class_name XpWindow
extends RefCounted


## The highest boost tier open now (0 = no window).
static func boost(gs: GameState, db: DataDb) -> int:
	var best := 0
	var day := gs.clock.day()
	for id: String in db.canon.windows:
		var ev: Dictionary = db.canon.events[id]
		var w: Dictionary = ev["xp_window"]
		if int(w["boost"]) <= best or gs.world.status(id) != WorldState.PENDING:
			continue
		if day < int(ev["window"]["earliest"]) or day > gs.world.latest(id, ev):
			continue
		if w.has("hours") and not MonsterSim.in_hours(gs, w["hours"]):
			continue
		best = int(w["boost"])
	return best


## The XP factor of the open window (1.0 = none).
static func mult(gs: GameState, db: DataDb) -> float:
	return Xp.boost_mult(boost(gs, db), db.rules["xp"])


## Every window's boost tier must exist in rules.xp.boosts. Returns the problems.
static func validate(db: DataDb) -> Array[String]:
	var out: Array[String] = []
	var tiers: Dictionary = db.rules.get("xp", {}).get("boosts", {})
	for id: String in db.canon.windows:
		var b := int(db.canon.events[id]["xp_window"]["boost"])
		if not tiers.has(str(b)):
			out.append("event '%s' xp_window: rules.xp.boosts has no tier %d." % [id, b])
	return out
