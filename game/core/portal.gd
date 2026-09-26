## Magic doors (M10.0, ADR 0017): the Albez door that links Erin's inn near
## Liscor to Octavia's shop in Celum (Book 4). A map object with "portal"
## ({"to", "pos", "power_flags"}) takes the player to a tile of another map
## in rules.portal.minutes, with no cold on the way. It works only while its
## power_flags hold (the door has mana), and at most
## rules.portal.trips_per_day times a day for the player (PlayerState
## portal_day / portal_trips). Each trip is a travel action with
## context.portal. The object itself is on the map only while its own
## when_flags hold (MapDb).
class_name Portal
extends RefCounted


## Trips through a magic door the player has left today.
static func trips_left(gs: GameState, db: DataDb) -> int:
	var per_day := int(db.rules["portal"]["trips_per_day"])
	if gs.player.portal_day != gs.clock.day():
		return per_day
	return maxi(0, per_day - gs.player.portal_trips)


## True while every power flag of portal object `o` holds.
static func is_powered(gs: GameState, o: Dictionary) -> bool:
	for f: String in o["portal"].get("power_flags", []):
		if not gs.flags.get(f, false):
			return false
	return true


## Steps through the nearby magic door `object_id`. Returns "" or why not.
static func use(gs: GameState, db: DataDb, object_id: String) -> String:
	if not Movement.ensure_placed(gs, db):
		return "There is no world to walk in."
	var obj := {}
	for o: Dictionary in db.maps.objects_near(gs.player.area, gs.player.pos()):
		if o["id"] == object_id and o.has("portal"):
			obj = o
	if obj.is_empty():
		return "There is no magic door '%s' here." % object_id
	var rules: Dictionary = db.rules["portal"]
	if not is_powered(gs, obj):
		return rules["dry_line"]
	if trips_left(gs, db) <= 0:
		return rules["spent_line"]
	var p: Dictionary = obj["portal"]
	var minutes := int(rules["minutes"])
	var rec := Actions.perform(gs, db, "travel", {
		"minutes": minutes,
		"intensity": float(minutes) / float(db.actions["travel"]["minutes"]),
		"context": {"from": gs.player.area, "to": p["to"], "portal": true},
	})
	if rec.is_empty():
		return "You are too tired."
	if gs.player.portal_day != gs.clock.day():
		gs.player.portal_day = gs.clock.day()
		gs.player.portal_trips = 0
	gs.player.portal_trips += 1
	gs.player.place(p["to"], Vector2i(int(p["pos"][0]), int(p["pos"][1])))
	gs.winter.sec = NpcSim.world_sec(gs)  # an instant step: no cold on the way
	gs.combat.lines.append(String(rules["line"]) % db.maps.areas[p["to"]]["name"])
	return ""
