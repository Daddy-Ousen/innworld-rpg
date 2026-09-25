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
class_name Rest
extends RefCounted

const BED := "bed"
const FLOOR := "floor"
const ANYWHERE := "*"


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
