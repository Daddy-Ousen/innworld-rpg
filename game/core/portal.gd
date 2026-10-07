## Magic doors (M10.0, ADR 0017): the Albez door that links Erin's inn near
## Liscor to Octavia's shop in Celum (Book 4). A map object with "portal"
## takes the player to a tile of another map in rules.portal.minutes, with
## no cold on the way. It works only while its power_flags hold (the door
## has mana), and at most rules.portal.trips_per_day times a day for the
## player (PlayerState portal_day / portal_trips). Each trip is a travel
## action with context.portal. The object itself is on the map only while
## its own when_flags hold (MapDb).
## M19.0 (ADR 0030): a portal is either the old single form
## {"to", "pos", "power_flags"} or {"links": [{"id", "name"?, "to", "pos",
## "power_flags"?, "when_flags"?, "unless_flags"?, "hours"?}]}: one door,
## several far ends (Celum, Pallass). The player picks the link. A link is
## open while its flags hold and the clock is in its hours [from, to). The
## trips are one shared count a day.
class_name Portal
extends RefCounted


## Trips through a magic door the player has left today.
static func trips_left(gs: GameState, db: DataDb) -> int:
	var per_day := int(db.rules["portal"]["trips_per_day"])
	if gs.player.portal_day != gs.clock.day():
		return per_day
	return maxi(0, per_day - gs.player.portal_trips)


## The links of a portal ({} entries have "id" "" for the old single form).
static func links_of(p: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if p.has("links"):
		for l: Dictionary in p["links"]:
			out.append(l)
	else:
		out.append({"id": "", "to": p["to"], "pos": p["pos"], "power_flags": p.get("power_flags", [])})
	return out


## True while every power flag of link `l` holds.
static func link_powered(gs: GameState, l: Dictionary) -> bool:
	for f: String in l.get("power_flags", []):
		if not gs.flags.get(f, false):
			return false
	return true


## True while every power flag of portal object `o` holds (the first open
## link of a door with several).
static func is_powered(gs: GameState, o: Dictionary) -> bool:
	var open := open_links(gs, o["portal"])
	return not open.is_empty() and link_powered(gs, open[0])


## True while link `l` is on offer: its flags hold and the hour is in its hours.
static func link_open(gs: GameState, l: Dictionary) -> bool:
	if not MapDb.flags_hold(l, gs.flags):
		return false
	return not l.has("hours") or MonsterSim.in_hours(gs, l["hours"])


## The links of portal `p` that are on offer now.
static func open_links(gs: GameState, p: Dictionary) -> Array[Dictionary]:
	return links_of(p).filter(func(l: Dictionary) -> bool: return link_open(gs, l))


## The name of a link in the menu: its own "name", else the far map's name.
static func link_name(db: DataDb, l: Dictionary) -> String:
	return String(l.get("name", db.maps.areas[l["to"]]["name"]))


## Steps through the nearby magic door `object_id` by link `link_id` ("" =
## the only or first open link). Returns "" or why not.
static func use(gs: GameState, db: DataDb, object_id: String, link_id: String = "") -> String:
	if not Movement.ensure_placed(gs, db):
		return "There is no world to walk in."
	var obj := {}
	for o: Dictionary in db.maps.objects_near(gs.player.area, gs.player.pos()):
		if o["id"] == object_id and o.has("portal"):
			obj = o
	if obj.is_empty():
		return "There is no magic door '%s' here." % object_id
	var rules: Dictionary = db.rules["portal"]
	var p: Dictionary = obj["portal"]
	var link := {}
	for l: Dictionary in links_of(p):
		if link_id == "" or l["id"] == link_id:
			if link_open(gs, l):
				link = l
				break
			if link_id != "":
				return String(rules.get("shut_line", rules["dry_line"]))
	if link.is_empty():
		if link_id != "":
			return "The door has no link '%s'." % link_id
		return String(rules.get("shut_line", rules["dry_line"]))
	if not link_powered(gs, link):
		return rules["dry_line"]
	if trips_left(gs, db) <= 0:
		return rules["spent_line"]
	var minutes := int(rules["minutes"])
	var rec := Actions.perform(gs, db, "travel", {
		"minutes": minutes,
		"intensity": float(minutes) / float(db.actions["travel"]["minutes"]),
		"context": {"from": gs.player.area, "to": link["to"], "portal": true},
	})
	if rec.is_empty():
		return "You are too tired."
	if gs.player.portal_day != gs.clock.day():
		gs.player.portal_day = gs.clock.day()
		gs.player.portal_trips = 0
	gs.player.portal_trips += 1
	gs.player.place(link["to"], Vector2i(int(link["pos"][0]), int(link["pos"][1])))
	gs.winter.sec = NpcSim.world_sec(gs)  # an instant step: no cold on the way
	gs.combat.lines.append(String(rules["line"]) % db.maps.areas[link["to"]]["name"])
	return ""
