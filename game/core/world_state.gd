## The world's emergent state (DESIGN §4.1): what really happened to canon
## events and NPCs. Stores only changes; the defaults come from CanonDb
## (npc alive_at_start, event pending, window.latest). Logic lives in Director.
class_name WorldState
extends RefCounted

const PENDING := "pending"

## NPC overrides: id → {"alive": bool}.
var npcs: Dictionary = {}
## from npc → {to npc → int}.
var relationships: Dictionary = {}
## Event runtime state: id → {"status", "day", "roles", "latest"}. Missing = pending.
## status: pending | done | substituted | mutated | cancelled.
var events: Dictionary = {}
## The emergent timeline, in order: {"day", "event", "outcome", "roles", "via"?, "reason"?,
## "by"?, "hook"?}. "by": "player" and "hook" mark a change the player made (M6.4).
var history: Array[Dictionary] = []
## What the player heard, in order (M6.4): {"day", "event", "kind", "text"}.
## kind: "news" (local, from event or hook `news`) or "rumor" (T1 `rumor`).
var news: Array[Dictionary] = []
## Canon fights the player met on the map (M6.5): event id → day it was staged.
## An event stages once.
var staged: Dictionary = {}
## Weighted count of changed canon events (rules "director.drift").
var drift: float = 0.0
## Last day the director has run for (0 = never).
var last_day: int = 0


func is_alive(canon: CanonDb, npc: String) -> bool:
	if npcs.has(npc):
		return bool(npcs[npc]["alive"])
	return canon.npcs.has(npc) and bool(canon.npcs[npc].get("alive_at_start", true))


func set_alive(npc: String, alive: bool) -> void:
	npcs[npc] = {"alive": alive}


func status(event_id: String) -> String:
	return events.get(event_id, {}).get("status", PENDING)


## The event's current last day: window.latest, plus any delays.
func latest(event_id: String, ev: Dictionary) -> int:
	return int(events.get(event_id, {}).get("latest", ev["window"]["latest"]))


func add_news(day: int, event_id: String, kind: String, text: String) -> void:
	news.append({"day": day, "event": event_id, "kind": kind, "text": text})


## News and rumors from day `from_day` on, newest first.
func news_since(from_day: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in range(news.size() - 1, -1, -1):
		if int(news[i]["day"]) >= from_day:
			out.append(news[i])
	return out


func relationship(from: String, to: String) -> int:
	return int(relationships.get(from, {}).get(to, 0))


func add_relationship(from: String, to: String, delta: int) -> void:
	if not relationships.has(from):
		relationships[from] = {}
	relationships[from][to] = relationship(from, to) + delta


func to_dict() -> Dictionary:
	return {
		"npcs": npcs.duplicate(true),
		"relationships": relationships.duplicate(true),
		"events": events.duplicate(true),
		"history": history.duplicate(true),
		"news": news.duplicate(true),
		"staged": staged.duplicate(),
		"drift": drift,
		"last_day": last_day,
	}


## Accepts {} (a migrated v2 save): a world where nothing has happened yet.
## JSON numbers load as floats; day/latest/delta values are made ints again.
static func from_dict(d: Dictionary) -> WorldState:
	var w := WorldState.new()
	w.npcs = (d.get("npcs", {}) as Dictionary).duplicate(true)
	for from: String in d.get("relationships", {}):
		for to: String in d["relationships"][from]:
			w.add_relationship(from, to, int(d["relationships"][from][to]))
	for id: String in d.get("events", {}):
		var e: Dictionary = (d["events"][id] as Dictionary).duplicate(true)
		for k: String in ["day", "latest"]:
			if e.has(k):
				e[k] = int(e[k])
		w.events[id] = e
	for h: Dictionary in d.get("history", []):
		var entry := h.duplicate(true)
		entry["day"] = int(entry["day"])
		w.history.append(entry)
	for n: Dictionary in d.get("news", []):
		var item := n.duplicate(true)
		item["day"] = int(item["day"])
		w.news.append(item)
	for id: String in d.get("staged", {}):
		w.staged[id] = int(d["staged"][id])
	w.drift = float(d.get("drift", 0.0))
	w.last_day = int(d.get("last_day", 0))
	return w
