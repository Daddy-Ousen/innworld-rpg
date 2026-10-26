## Quests (M33.2, ADR 0044 "M33.2"): the tasks the player took on. Part of
## GameState (save v24). The quests themselves are data (data/quests.json, Quests).
class_name QuestState
extends RefCounted

const ACTIVE := "active"
const DONE := "done"
const FAILED := "failed"

## Quest id → {"status": ACTIVE | DONE | FAILED, "step": index of the current step,
## "count": matching records for the current step, "day": the day it started,
## "end_day": the day it was done or failed (-1 = still open)}. Start order.
var entries: Dictionary = {}


func to_dict() -> Dictionary:
	return {"entries": entries.duplicate(true)}


## Accepts {} (a migrated v23 save): no tasks yet.
static func from_dict(d: Dictionary) -> QuestState:
	var q := QuestState.new()
	var src: Dictionary = d.get("entries", {})
	for id: String in src:
		var e: Dictionary = src[id]
		q.entries[id] = {"status": String(e["status"]), "step": int(e["step"]), "count": int(e["count"]),
			"day": int(e["day"]), "end_day": int(e.get("end_day", -1))}
	return q
