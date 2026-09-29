## The player's inn work (M14.2, ADR 0021): reputation, the patrons in the
## common room and the day's takings. Part of GameState (save v15). See Guests.
class_name InnState
extends RefCounted

## 0..100; -1 = not set yet (Guests.reputation gives rules.inn.start_reputation).
var reputation: int = -1
## Patrons: [{"id": "p<N>", "area", "race", "look", "seat": [x, y], "order": dish good,
##  "arrive": minute, "until": minute, "paid": copper (0 = not served yet)}].
## A patron is in the room from "arrive"; it leaves at "until" (served: after
## eating; not served: out of patience).
var guests: Array[Dictionary] = []
## Copper earned by serving since the last night.
var income_today: int = 0
## Patrons who came since the last night (the "guests" action context).
var guests_today: int = 0
## Dishes served, ever.
var served_total: int = 0
## Meal key (Guests.meal_key) of the last meal whose patrons were rolled; -1 = none.
var meal: int = -1
## Canon NPC id → meal key when the player last served them.
var served_npcs: Dictionary = {}
## The next patron number.
var next_id: int = 1


## The patron with this id, or {}.
func guest(id: String) -> Dictionary:
	for g in guests:
		if g["id"] == id:
			return g
	return {}


func to_dict() -> Dictionary:
	return {"reputation": reputation, "guests": guests.duplicate(true), "income_today": income_today,
		"guests_today": guests_today, "served_total": served_total, "meal": meal,
		"served_npcs": served_npcs.duplicate(), "next_id": next_id}


## Accepts {} (a migrated v14 save): no patrons, reputation not set yet.
static func from_dict(d: Dictionary) -> InnState:
	var s := InnState.new()
	s.reputation = int(d.get("reputation", -1))
	for g: Dictionary in d.get("guests", []):
		var seat: Array = g["seat"]
		s.guests.append({"id": String(g["id"]), "area": String(g["area"]), "race": String(g["race"]), "look": String(g["look"]),
			"seat": [int(seat[0]), int(seat[1])], "order": String(g["order"]),
			"arrive": int(g["arrive"]), "until": int(g["until"]), "paid": int(g["paid"])})
	s.income_today = int(d.get("income_today", 0))
	s.guests_today = int(d.get("guests_today", 0))
	s.served_total = int(d.get("served_total", 0))
	s.meal = int(d.get("meal", -1))
	for n: String in (d.get("served_npcs", {}) as Dictionary):
		s.served_npcs[n] = int(d["served_npcs"][n])
	s.next_id = int(d.get("next_id", 1))
	return s
