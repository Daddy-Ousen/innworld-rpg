## Where the player may sleep (M8.6, ADR 0015; user choice 2026-09-25).
##   A bed (a map object with "sleep": true) heals fully (rest.bed); a bed
##   with a "price" is a paid room. Sleeping where you stand next to a free
##   bed uses that bed.
##   Without a bed, indoors (MapDb.is_indoor) or on a campsite
##   (MapDb.is_camp) you sleep on the floor: rest.floor of the heal.
##   Anywhere else (outdoors) you cannot sleep. A collapse or a knock-out
##   still happens anywhere (Commands.sleep).
## A db without rules.economy (toy dbs) lets you sleep anywhere, as a bed.
## Debug and tests: the bed id ANYWHERE sleeps where you stand as in a bed.
## Audit D1 / D2 (ADR 0051): `sleep_plan` says whether a sleep the player
## starts asks first; `options` and `next_meal` feed the Rest panel; the
## command is Commands.rest (pure time, chunks of CHUNK minutes).
class_name Rest
extends RefCounted

const BED := "bed"
const FLOOR := "floor"
const ANYWHERE := "*"
## A rest runs in chunks of this many minutes and stops early when the player is needed.
const CHUNK := 10
## The fixed Rest panel options, in minutes.
const HOURS: Array[int] = [60, 180]
## sleep_plan modes.
const ASK := "ask"
const NOW := "now"
const REFUSED := "refused"


## Where the player would sleep: {"rest": BED | FLOOR | "", "bed": object id
## or "", "price": copper, "error": ""}. `bed_id` "" = where you stand.
## rest "" = refused (the reason is in error).
static func place(gs: GameState, db: DataDb, bed_id: String = "") -> Dictionary:
	var out := {"rest": BED, "bed": bed_id, "price": 0, "error": ""}
	var r: Dictionary = Economy.rules(db).get("rest", {})
	if bed_id == ANYWHERE:
		out["bed"] = ""
		return out
	if r.is_empty() or not Movement.ensure_placed(gs, db):
		return out
	var beds := db.maps.objects_near(gs.player.area, gs.player.pos()).filter(
			func(o: Dictionary) -> bool: return bool(o.get("sleep", false)))
	if bed_id != "":
		var found := beds.filter(func(o: Dictionary) -> bool: return o["id"] == bed_id)
		if found.is_empty():
			out["rest"] = ""
			out["error"] = "There is no bed '%s' here." % bed_id
			return out
		out["price"] = int(found[0].get("price", 0))
		if gs.economy.coins < int(out["price"]):
			out["rest"] = ""
			out["error"] = String(r["poor_line"]) % Economy.format(db, int(out["price"]))
		return out
	for o: Dictionary in beds:
		if int(o.get("price", 0)) == 0:
			out["bed"] = o["id"]
			return out
	if db.maps.is_indoor(gs.player.area) or db.maps.is_camp(gs.player.area):
		out["rest"] = FLOOR
		return out
	out["rest"] = ""
	out["error"] = String(r["refused_line"])
	return out


## Share of the night heal for `rest` (1.0 for a bed or with no rules).
static func share(db: DataDb, rest: String) -> float:
	var r: Dictionary = Economy.rules(db).get("rest", {})
	if r.is_empty():
		return 1.0
	return float(r.get(rest, 1.0))


## The next meal start after now (today or tomorrow): {"name", "minutes", "hour"} or {} when
## the db has no rules.inn meals. A meal that starts right now counts as tomorrow's.
@warning_ignore("integer_division")
static func next_meal(gs: GameState, db: DataDb) -> Dictionary:
	var meals: Array = db.rules.get("inn", {}).get("meals", [])
	var best := {}
	for m: Dictionary in meals:
		var start := roundi(float(m["hours"][0]) * 60.0)
		var wait := posmod(start - gs.clock.minute(), Clock.MINUTES_PER_DAY)
		if wait == 0:
			wait = Clock.MINUTES_PER_DAY
		if best.is_empty() or wait < int(best["minutes"]):
			best = {"name": String(m["name"]), "minutes": wait, "hour": "%02d:%02d" % [start / 60, start % 60]}
	return best


## The rows of the Rest panel: [{"text", "minutes"}]. Rest 1 hour, Rest 3 hours, and Rest until the next meal.
static func options(gs: GameState, db: DataDb) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for h in HOURS:
		out.append({"text": "Rest %s" % duration_text(h), "minutes": h})
	var meal := next_meal(gs, db)
	if not meal.is_empty():
		out.append({"text": "Rest until %s (%s)" % [meal["hour"], meal["name"]], "minutes": int(meal["minutes"])})
	return out


## "1 hour", "3 hours", "40 min", "1 hour 30 min".
@warning_ignore("integer_division")
static func duration_text(minutes: int) -> String:
	var h := minutes / 60
	var m := minutes % 60
	var parts: Array[String] = []
	if h > 0:
		parts.append("%d hour%s" % [h, "" if h == 1 else "s"])
	if m > 0:
		parts.append("%d min" % m)
	return " ".join(parts) if not parts.is_empty() else "no time"


## What a sleep the player starts now would do, without changing anything:
## {"mode": ASK | NOW | REFUSED, "title", "sub"}. NOW: a collapse or a knock-out (no question).
## REFUSED: enemies near, outdoors, or no coins (Commands.sleep shows the line). ASK: title
## "Sleep until 06:00?", sub "9 h" (and "Room: <price>" for a paid room).
@warning_ignore("integer_division")
static func sleep_plan(gs: GameState, db: DataDb, bed: String = "") -> Dictionary:
	var rules: Dictionary = db.rules["clock"]
	if Combat.is_down(gs) or gs.clock.is_collapse_due(rules):
		return {"mode": NOW}
	if Combat.in_danger(gs):
		return {"mode": REFUSED}
	var place := place(gs, db, bed)
	if place["rest"] == "":
		return {"mode": REFUSED}
	var length := gs.clock.sleep_length(rules)
	var wake := (gs.clock.minute() + length) % Clock.MINUTES_PER_DAY
	var hours := "%d h" % (length / 60) if length % 60 == 0 else "%d h %d min" % [length / 60, length % 60]
	var sub := hours
	if int(place["price"]) > 0:
		sub += ". Room: %s" % Economy.format(db, int(place["price"]))
	return {"mode": ASK, "title": "Sleep until %02d:%02d?" % [wake / 60, wake % 60], "sub": sub}
