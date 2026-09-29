## Guests and serving (M14.2, ADR 0021). Rules in rules.inn; the inn state
## in GameState.inn (InnState, save v15).
##   Patrons: unnamed guests who sit on the "seats" of the tables in
##   rules.inn.area. The first command in a meal (rules.inn.meals) while the
##   player is in that area rolls how many come: guest_curve by reputation,
##   plus flag_bonus for canon flags; never more than the free seats. The
##   inn must be open (open_flags; not closed_flags unless reopen_flags).
##   They come over the first half of what is left of the meal, each with an
##   order (a dish) and patience. A patron nobody serves leaves when its
##   patience runs out; with the player in the area, reputation drops.
##   A fight in the room (Combat.in_danger) sends them all away.
##   Canon guests: an NPC in the area whose goal is in guest_goals (eating,
##   visiting the inn) is a guest too, once per meal slot.
##   Serve: a dish from the bag to a guest next to the player. It is the
##   action serve_guests for serve_minutes. Pay = the dish's sell price x
##   pay_factor (x other_dish_share for a patron who ordered something else);
##   reputation + serve_reputation; a canon guest's relationship goes up by
##   npc_relationship. A served patron eats for eat_minutes, then leaves.
##   Night: the day's takings go in the morning lines; everyone leaves.
## Patron rolls use their own Rng, seeded from the game seed and the meal,
## so they never change the main random stream (CLAUDE.md rule 3).
## A db without rules.inn (toy dbs) has no guests.
class_name Guests
extends RefCounted

## Interact option ids of patrons: "guest:<id>".
const GUEST := "guest:"
const SERVE_ACTION := "serve_guests"
const FIELDS := ["confidence", "area", "location", "start_reputation", "open_flags", "closed_flags",
	"reopen_flags", "meals", "guest_curve", "flag_bonus", "patron_races", "dishes",
	"patience_minutes", "pay_factor", "other_dish_share", "serve_minutes", "eat_minutes",
	"serve_reputation", "leave_reputation", "npc_relationship", "guest_goals",
	"meal_line", "left_line", "flee_line", "served_line", "income_line"]


static func rules(db: DataDb) -> Dictionary:
	return db.rules.get("inn", {})


static func on(db: DataDb) -> bool:
	return not rules(db).is_empty() and db.maps.areas.has(rules(db)["area"])


static func reputation(gs: GameState, db: DataDb) -> int:
	return gs.inn.reputation if gs.inn.reputation >= 0 else int(rules(db).get("start_reputation", 0))


static func add_reputation(gs: GameState, db: DataDb, delta: int) -> void:
	gs.inn.reputation = clampi(reputation(gs, db) + delta, 0, 100)


## Open for guests: every open flag set, and not closed (a closed flag with no reopen flag).
static func is_open(gs: GameState, db: DataDb) -> bool:
	var r := rules(db)
	for f: String in r["open_flags"]:
		if not gs.flags.has(f):
			return false
	var closed := (r["closed_flags"] as Array).any(func(f: String) -> bool: return gs.flags.has(f))
	return not closed or (r["reopen_flags"] as Array).any(func(f: String) -> bool: return gs.flags.has(f))


## The meal (index in rules.inn.meals) at this time of day, or -1.
static func meal_index(gs: GameState, db: DataDb) -> int:
	var hour := float(gs.clock.minute()) / 60.0
	var meals: Array = rules(db)["meals"]
	for i in meals.size():
		var h: Array = meals[i]["hours"]
		if hour >= float(h[0]) and hour < float(h[1]):
			return i
	return -1


## One key per meal per day.
static func meal_key(gs: GameState, i: int) -> int:
	return gs.clock.day() * 10 + i


## Canon guests are served once per slot: the last meal that has begun today (0 before breakfast).
static func slot_key(gs: GameState, db: DataDb) -> int:
	var hour := float(gs.clock.minute()) / 60.0
	var meals: Array = rules(db)["meals"]
	var slot := 0
	for i in meals.size():
		if hour >= float(meals[i]["hours"][0]):
			slot = i
	return meal_key(gs, slot)


## After every command (Commands._after): patrons leave, flee a fight, or
## come for a new meal.
static func sync(gs: GameState, db: DataDb) -> void:
	if not on(db):
		return
	var r := rules(db)
	var here: bool = gs.player.is_placed() and gs.player.area == r["area"]
	_leave(gs, db, here)
	if not here:
		return
	if Combat.in_danger(gs):
		if not gs.inn.guests.is_empty():
			gs.inn.guests.clear()
			gs.combat.lines.append(String(r["flee_line"]))
		return
	var i := meal_index(gs, db)
	if i < 0 or not is_open(gs, db) or gs.inn.meal == meal_key(gs, i):
		return
	gs.inn.meal = meal_key(gs, i)
	_arrive(gs, db, i)


## Patrons in the room now (they have arrived).
static func present(gs: GameState) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for g in gs.inn.guests:
		if int(g["arrive"]) <= gs.clock.total_minutes:
			out.append(g)
	return out


## The id of the patron seated on `pos` of `area`, or "".
static func at(gs: GameState, area: String, pos: Vector2i) -> String:
	for g in present(gs):
		if g["area"] == area and _seat(g) == pos:
			return g["id"]
	return ""


## Canon NPCs who are guests now: in the inn area, up, alive and with a guest goal.
static func npc_guests(gs: GameState, db: DataDb) -> Array[String]:
	var out: Array[String] = []
	if not on(db) or not is_open(gs, db):
		return out
	var r := rules(db)
	for id in gs.npcs.in_area(r["area"]):
		var n: Dictionary = gs.npcs.npcs[id]
		if (r["guest_goals"] as Array).has(n.get("goal", "")) and not bool(n.get("down", false)) \
				and gs.world.is_alive(db.canon, id):
			out.append(id)
	return out


## Unserved patrons on or next to the player, by id.
static func near(gs: GameState) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not gs.player.is_placed():
		return out
	for g in present(gs):
		var d := _seat(g) - gs.player.pos()
		if g["area"] == gs.player.area and int(g["paid"]) == 0 and maxi(absi(d.x), absi(d.y)) <= 1:
			out.append(g)
	return out


## The "guests" action context at the inn: patrons today plus canon guests now.
static func count(gs: GameState, db: DataDb) -> int:
	return gs.inn.guests_today + npc_guests(gs, db).size()


## "Drake patron".
static func patron_name(g: Dictionary) -> String:
	return "%s patron" % String(g["race"]).capitalize()


## What the player can serve `target` ("guest:<id>" or a canon NPC id) from
## the bag: [{"good", "name", "ordered": bool, "pay"}], the order first.
## [] if `target` is not a guest waiting for food.
static func serve_choices(gs: GameState, db: DataDb, target: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var order: Variant = _order_of(gs, db, target)
	if order == null:
		return out
	for good: String in rules(db)["dishes"]:
		if gs.economy.count(good) <= 0:
			continue
		var c := {"good": good, "name": db.economy.goods[good]["name"], "ordered": good == order,
			"pay": pay_for(db, order, good)}
		if c["ordered"]:
			out.push_front(c)
		else:
			out.append(c)
	return out


## Copper for serving `good` to a guest who ordered `order` ("" = a canon guest: anything will do).
static func pay_for(db: DataDb, order: String, good: String) -> int:
	var r := rules(db)
	var share := 1.0 if order == "" or order == good else float(r["other_dish_share"])
	return maxi(roundi(float(db.economy.goods[good]["sell"]) * float(r["pay_factor"]) * share), 1)


## Serves `good` from the bag to `target` next to the player. Returns
## {"record", "error"} (see Interact.perform); what happened is in gs.combat.lines.
static func serve(gs: GameState, db: DataDb, target: String, good: String) -> Dictionary:
	var order: Variant = _order_of(gs, db, target) if on(db) else null
	if order == null:
		return _fail("There is no guest waiting for food there.")
	if not (rules(db)["dishes"] as Array).has(good):
		return _fail("You cannot serve that.")
	if gs.economy.count(good) <= 0:
		return _fail("You have no %s." % String(db.economy.goods[good]["name"]).to_lower())
	var r := rules(db)
	var minutes := int(r["serve_minutes"])
	var npc := "" if target.begins_with(GUEST) else target
	var context := {"location": db.maps.areas[gs.player.area]["location"], "guests": count(gs, db),
		"good": good}
	var opts := {"minutes": minutes, "intensity": float(minutes) / float(db.actions[SERVE_ACTION]["minutes"]),
		"context": context}
	if npc != "":
		context["npc"] = npc
		opts["witnesses"] = [npc]
	var rec := Actions.perform(gs, db, SERVE_ACTION, opts)
	if rec.is_empty():
		return _fail("You are too tired.")
	var pay := pay_for(db, String(order), good)
	gs.economy.add(good, -1)
	gs.economy.coins += pay
	gs.inn.income_today += pay
	gs.inn.served_total += 1
	add_reputation(gs, db, int(r["serve_reputation"]))
	var who := ""
	if npc == "":
		var g := gs.inn.guest(target.substr(GUEST.length()))
		g["paid"] = pay
		g["until"] = gs.clock.total_minutes + int(r["eat_minutes"])
		who = "the " + patron_name(g).to_lower()
	else:
		gs.inn.served_npcs[npc] = slot_key(gs, db)
		gs.world.add_relationship(npc, NpcSim.PLAYER, int(r["npc_relationship"]))
		who = db.canon.npcs[npc]["name"]
	gs.combat.lines.append(String(r["served_line"]) % [String(db.economy.goods[good]["name"]).to_lower(),
			who, Economy.format(db, pay)])
	return {"record": rec, "error": ""}


## Night step (Night.run): the day's takings for the morning, then everyone leaves.
static func night(gs: GameState, db: DataDb) -> Array[String]:
	var lines: Array[String] = []
	if not on(db):
		return lines
	if gs.inn.income_today > 0:
		lines.append(String(rules(db)["income_line"]) % Economy.format(db, gs.inn.income_today))
	gs.inn.guests.clear()
	gs.inn.income_today = 0
	gs.inn.guests_today = 0
	gs.inn.served_npcs.clear()
	return lines


## Checks rules.inn against the maps, goods and actions. Returns the errors.
static func validate(db: DataDb) -> Array[String]:
	var errs: Array[String] = []
	if not db.rules.has("inn"):
		return errs
	var r: Variant = db.rules["inn"]
	if not r is Dictionary:
		return ["rules.inn: must be an object."] as Array[String]
	for f: String in FIELDS:
		if not (r as Dictionary).has(f):
			errs.append("rules.inn: missing '%s'." % f)
	if not errs.is_empty():
		return errs
	if not db.maps.areas.has(r["area"]):
		errs.append("rules.inn: unknown area '%s'." % r["area"])
	elif _seats(db, r["area"]).is_empty():
		errs.append("rules.inn: area '%s' has no table seats." % r["area"])
	if not db.actions.has(SERVE_ACTION):
		errs.append("rules.inn: needs the action '%s'." % SERVE_ACTION)
	for m: Variant in r["meals"]:
		var h: Variant = (m as Dictionary).get("hours", []) if m is Dictionary else []
		if not m is Dictionary or not (m as Dictionary).has("name") or not h is Array or (h as Array).size() != 2 \
				or float(h[0]) < 0.0 or float(h[0]) >= float(h[1]) or float(h[1]) > 24.0:
			errs.append("rules.inn.meals: each needs a name and hours [from, to] in 0..24, from < to.")
	for row: Variant in r["guest_curve"]:
		if not row is Array or (row as Array).size() != 3 or int(row[1]) < 0 or int(row[1]) > int(row[2]):
			errs.append("rules.inn.guest_curve: rows are [reputation, min, max] with 0 <= min <= max.")
	for race: String in r["patron_races"]:
		if float(r["patron_races"][race]) <= 0.0:
			errs.append("rules.inn.patron_races: weight of '%s' must be > 0." % race)
	for good: Variant in r["dishes"]:
		if not db.economy.goods.has(good) or int(db.economy.goods[good].get("sell", 0)) < 1:
			errs.append("rules.inn.dishes: '%s' must be a good with a sell price >= 1." % good)
	var p: Array = r["patience_minutes"]
	if p.size() != 2 or int(p[0]) < 1 or int(p[0]) > int(p[1]):
		errs.append("rules.inn.patience_minutes: [min, max] with 1 <= min <= max.")
	if float(r["pay_factor"]) <= 0.0 or float(r["other_dish_share"]) < 0.0 or float(r["other_dish_share"]) > 1.0 \
			or int(r["serve_minutes"]) < 1 or int(r["eat_minutes"]) < 1:
		errs.append("rules.inn: pay_factor > 0, other_dish_share 0..1, serve_minutes and eat_minutes >= 1.")
	return errs


static func _arrive(gs: GameState, db: DataDb, i: int) -> void:
	var r := rules(db)
	var rng := Rng.new(gs.rng.get_seed() ^ (meal_key(gs, i) * 2654435761))
	var bonus := 0
	for f: String in r["flag_bonus"]:
		if gs.flags.has(f):
			bonus += int(r["flag_bonus"][f])
	var row: Array = r["guest_curve"][0]
	for c: Array in r["guest_curve"]:
		if reputation(gs, db) >= int(c[0]):
			row = c
	var free := _free_seats(gs, db)
	var n := mini(rng.randi_range(int(row[1]), int(row[2])) + bonus, free.size())
	var now := gs.clock.total_minutes
	var meal: Dictionary = r["meals"][i]
	var end := gs.clock.total_minutes - gs.clock.minute() + roundi(float(meal["hours"][1]) * 60.0)
	@warning_ignore("integer_division")
	var spread := maxi((end - now) / 2, 0)
	var races: Array = (r["patron_races"] as Dictionary).keys()
	var weights: Array = (r["patron_races"] as Dictionary).values()
	var patience: Array = r["patience_minutes"]
	for k in n:
		var seat: Vector2i = free.pop_at(rng.randi_range(0, free.size() - 1))
		var race: String = races[rng.weighted_index(weights)]
		var arrive := now + rng.randi_range(0, spread)
		gs.inn.guests.append({"id": "p%d" % gs.inn.next_id, "area": r["area"], "race": race,
			"look": "race_" + race, "seat": [seat.x, seat.y], "order": String(rng.pick(r["dishes"])),
			"arrive": arrive, "until": arrive + rng.randi_range(int(patience[0]), int(patience[1])),
			"paid": 0})
		gs.inn.next_id += 1
	gs.inn.guests_today += n
	if n > 0:
		gs.combat.lines.append(String(r["meal_line"]) % [meal["name"], n])


## Patrons whose time is up leave. An unserved one costs reputation if the player is there to see it.
static func _leave(gs: GameState, db: DataDb, here: bool) -> void:
	var r := rules(db)
	var stay: Array[Dictionary] = []
	for g in gs.inn.guests:
		if int(g["until"]) > gs.clock.total_minutes:
			stay.append(g)
		elif int(g["paid"]) == 0 and here:
			add_reputation(gs, db, int(r["leave_reputation"]))
			gs.combat.lines.append(String(r["left_line"]) % patron_name(g).to_lower())
	gs.inn.guests = stay


## The order of a guest waiting for food: a dish for a patron, "" for a
## canon guest; null if `target` is not such a guest next to the player.
static func _order_of(gs: GameState, db: DataDb, target: String) -> Variant:
	if target.begins_with(GUEST):
		for g in near(gs):
			if g["id"] == target.substr(GUEST.length()):
				return String(g["order"])
		return null
	if not NpcSim.near_player(gs).has(target) or not npc_guests(gs, db).has(target) \
			or int(gs.inn.served_npcs.get(target, -1)) == slot_key(gs, db):
		return null
	return ""


## The seats of the tables in `area`, in map order.
static func _seats(db: DataDb, area: String) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for o: Dictionary in db.maps.objects_on(area):
		for s: Array in o.get("seats", []):
			out.append(Vector2i(int(s[0]), int(s[1])))
	return out


## Seats with no patron, player, NPC or monster on them.
static func _free_seats(gs: GameState, db: DataDb) -> Array[Vector2i]:
	var area: String = rules(db)["area"]
	var out: Array[Vector2i] = []
	for s in _seats(db, area):
		var taken := gs.inn.guests.any(func(g: Dictionary) -> bool: return _seat(g) == s)
		if not taken and s != gs.player.pos() and gs.npcs.at(area, s) == "" and gs.combat.at(area, s) == "":
			out.append(s)
	return out


static func _seat(g: Dictionary) -> Vector2i:
	return Vector2i(int(g["seat"][0]), int(g["seat"][1]))


static func _fail(why: String) -> Dictionary:
	return {"record": {}, "error": why}
