## Relationships and reputation (M14.3, ADR 0021; save v16). Rules in rules.standing.
##   Relationship: WorldState.relationships[npc]["player"], raised by talking (NpcSim.note_talk)
##   and by serving a canon guest. WorldState.contact[npc] is the last day the player had
##   contact. Night step 7 (Night.run): a relationship with no contact for decay_after_days
##   moves toward 0 by relationship_decay per night.
##   Reputation: WorldState.reputation[key], a town (the nearest settlement above a map's
##   location) or a faction (an NPC's canon faction). Talking gives the map's town talk_town
##   and the NPC's faction talk_faction, once per NPC per day; serving a patron gives inn_town
##   serve_town. Every reputation_decay_every days each one moves 1 toward 0. Kept within +-cap.
##   Readers: regard (relationship plus faction reputation / faction_div) picks the greeting
##   band and who fights beside the player (NpcReact); a shop's prices follow the town's
##   reputation (Economy.price); the inn's guest curve gets inn_share of the inn town's.
## A db without rules.standing (toy dbs) has none of this: every reader gives its old answer.
class_name Standing
extends RefCounted

const FIELDS := ["confidence", "cap", "decay_after_days", "relationship_decay", "reputation_decay_every",
	"talk_town", "talk_faction", "serve_town", "inn_town", "inn_share", "price_per_point",
	"price_max", "faction_div", "friend_fight", "bands"]


static func rules(db: DataDb) -> Dictionary:
	return db.rules.get("standing", {})


static func on(db: DataDb) -> bool:
	return not rules(db).is_empty()


## The town of `area`: the nearest settlement at or above the map's location. "" if none.
static func town_of(db: DataDb, area: String) -> String:
	var loc: String = db.maps.areas.get(area, {}).get("location", "")
	var guard := 0
	while loc != "" and db.canon.locations.has(loc) and guard < 16:
		var l: Dictionary = db.canon.locations[loc]
		if l.get("kind", "") == "settlement":
			return loc
		var up: Variant = l.get("parent", null)
		loc = "" if up == null else String(up)
		guard += 1
	return ""


static func reputation(gs: GameState, key: String) -> int:
	return int(gs.world.reputation.get(key, 0))


## Changes the reputation of `key` (a town or a faction) by `delta`, within +-cap.
static func add_reputation(gs: GameState, db: DataDb, key: String, delta: int) -> void:
	if not on(db) or key == "" or delta == 0:
		return
	var cap := int(rules(db)["cap"])
	var v := clampi(reputation(gs, key) + delta, -cap, cap)
	if v == 0:
		gs.world.reputation.erase(key)
	else:
		gs.world.reputation[key] = v


## The player had contact with canon NPC `npc` today (a talk, a served dish).
static func touch(gs: GameState, npc: String) -> void:
	gs.world.contact[npc] = gs.clock.day()


## What the NPC thinks of the player: their relationship plus their faction's reputation
## / faction_div (rounded toward 0).
static func regard(gs: GameState, db: DataDb, npc: String) -> int:
	var rel := gs.world.relationship(npc, NpcSim.PLAYER)
	if not on(db):
		return rel
	var faction: Variant = db.canon.npcs.get(npc, {}).get("faction", null)
	if faction == null:
		return rel
	@warning_ignore("integer_division")
	return rel + reputation(gs, String(faction)) / maxi(int(rules(db)["faction_div"]), 1)


## The greeting band for `npc`: {"label": String, "line": String} ("%s" in the line is the name).
static func band(gs: GameState, db: DataDb, npc: String) -> Dictionary:
	var out := {"label": "", "line": ""}
	if not on(db):
		return out
	var r := regard(gs, db, npc)
	for b: Array in rules(db)["bands"]:
		if r >= int(b[0]):
			out = {"label": String(b[1]), "line": String(b[2])}
	return out


## True if `npc` thinks so well of the player that they fight beside them.
static func is_friend(gs: GameState, db: DataDb, npc: String) -> bool:
	return on(db) and regard(gs, db, npc) >= int(rules(db)["friend_fight"])


## The first talk of the day with `npc` (NpcSim.note_talk): contact, town and faction reputation.
static func on_talk(gs: GameState, db: DataDb, npc: String) -> void:
	if not on(db):
		return
	touch(gs, npc)
	var r := rules(db)
	add_reputation(gs, db, town_of(db, gs.player.area), int(r["talk_town"]))
	var faction: Variant = db.canon.npcs.get(npc, {}).get("faction", null)
	if faction != null:
		add_reputation(gs, db, String(faction), int(r["talk_faction"]))


## A patron was served (Guests.serve): the inn town thinks a little better of the player.
static func on_serve(gs: GameState, db: DataDb) -> void:
	if on(db):
		add_reputation(gs, db, String(rules(db)["inn_town"]), int(rules(db)["serve_town"]))


## Fraction off what the player pays (and on top of what a shop pays) where they stand now;
## negative = dearer. 0.0 if the area is in no town or there is no standing.
static func price_shift(gs: GameState, db: DataDb) -> float:
	if not on(db) or not gs.player.is_placed():
		return 0.0
	var r := rules(db)
	var town := town_of(db, gs.player.area)
	if town == "":
		return 0.0
	var m := float(r["price_max"])
	return clampf(float(reputation(gs, town)) * float(r["price_per_point"]), -m, m)


## Reputation points the inn's guest curve adds to the inn's own reputation.
static func guest_bonus(gs: GameState, db: DataDb) -> int:
	if not on(db):
		return 0
	return int(float(reputation(gs, String(rules(db)["inn_town"]))) * float(rules(db)["inn_share"]))


## Night step 7 (Night.run): quiet relationships and reputations drift toward 0.
static func night(gs: GameState, db: DataDb) -> void:
	if not on(db):
		return
	var r := rules(db)
	var today := gs.clock.day()
	var w := gs.world
	for npc: String in w.relationships:
		var v := w.relationship(npc, NpcSim.PLAYER)
		if v == 0:
			continue
		if not w.contact.has(npc):
			w.contact[npc] = today  # an old save or an event gift: the clock starts now
			continue
		if today - int(w.contact[npc]) > int(r["decay_after_days"]):
			var step := mini(int(r["relationship_decay"]), absi(v))
			w.add_relationship(npc, NpcSim.PLAYER, -signi(v) * step)
	var every := maxi(int(r["reputation_decay_every"]), 1)
	if today % every == 0:
		for key: String in w.reputation.keys():
			add_reputation(gs, db, key, -signi(int(w.reputation[key])))


## The character sheet's standing lines: the inn's reputation and every town or faction with one.
static func lines(gs: GameState, db: DataDb) -> Array[String]:
	var out: Array[String] = []
	if not on(db):
		return out
	if Guests.on(db) and gs.inn.reputation >= 0:
		out.append("Inn reputation: %d." % Guests.reputation(gs, db))
	for key: String in gs.world.reputation:
		var name: String = db.canon.locations.get(key, {}).get("name", key.replace("_", " ").capitalize())
		out.append("%s: %+d." % [name, int(gs.world.reputation[key])])
	if not out.is_empty():
		out.push_front("Standing:")
	return out


## Checks rules.standing. Returns the errors.
static func validate(db: DataDb) -> Array[String]:
	var errs: Array[String] = []
	if not db.rules.has("standing"):
		return errs
	var r: Variant = db.rules["standing"]
	if not r is Dictionary:
		return ["rules.standing: must be an object."] as Array[String]
	for f: String in FIELDS:
		if not (r as Dictionary).has(f):
			errs.append("rules.standing: missing '%s'." % f)
	if not errs.is_empty():
		return errs
	if int(r["cap"]) < 1 or int(r["decay_after_days"]) < 0 or int(r["relationship_decay"]) < 0 \
			or int(r["reputation_decay_every"]) < 1 or int(r["faction_div"]) < 1:
		errs.append("rules.standing: cap >= 1, decay values >= 0, reputation_decay_every >= 1, faction_div >= 1.")
	if float(r["price_per_point"]) < 0.0 or float(r["price_max"]) < 0.0 or float(r["price_max"]) >= 1.0 \
			or float(r["inn_share"]) < 0.0:
		errs.append("rules.standing: price_per_point >= 0, price_max in 0..1, inn_share >= 0.")
	if not db.canon.locations.is_empty() and not db.canon.locations.has(r["inn_town"]):
		errs.append("rules.standing.inn_town: unknown location '%s'." % r["inn_town"])
	var last := -100000
	if not r["bands"] is Array or (r["bands"] as Array).is_empty():
		errs.append("rules.standing.bands: needs rows [min regard, label, line].")
	else:
		for b: Variant in r["bands"]:
			if not b is Array or (b as Array).size() != 3 or int(b[0]) <= last:
				errs.append("rules.standing.bands: rows are [min regard, label, line], min rising.")
				break
			last = int(b[0])
	return errs
