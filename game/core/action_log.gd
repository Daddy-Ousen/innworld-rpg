## Records of what the player did. Keeps recent records (for novelty) and
## lifetime totals (for class pools and skill choice).
class_name ActionLog
extends RefCounted

## Recent action records, oldest first. See ADR 0002 for the record shape.
var records: Array[Dictionary] = []
## Lifetime count per action id. Survives pruning.
var action_counts: Dictionary = {}
## Lifetime XP per tag (xp × tag weight). Survives pruning.
var tag_totals: Dictionary = {}


func add(record: Dictionary) -> void:
	records.append(record)
	var id: String = record["action_id"]
	action_counts[id] = count(id) + 1
	var tags: Dictionary = record["tags"]
	for tag: String in tags:
		tag_totals[tag] = float(tag_totals.get(tag, 0.0)) + float(record["xp"]) * float(tags[tag])


func count(action_id: String) -> int:
	return int(action_counts.get(action_id, 0))


## Drops records older than `window_days` before `now` (total minutes).
func prune(now: int, window_days: int) -> void:
	var limit := now - window_days * Clock.MINUTES_PER_DAY
	records = records.filter(func(r: Dictionary) -> bool: return int(r["time"]) >= limit)


func to_dict() -> Dictionary:
	return {
		"records": records.duplicate(true),
		"action_counts": action_counts.duplicate(),
		"tag_totals": tag_totals.duplicate(),
	}


## JSON turns ints into floats; cast the int fields back.
static func from_dict(d: Dictionary) -> ActionLog:
	var log := ActionLog.new()
	for r: Dictionary in d.get("records", []):
		var rec := r.duplicate(true)
		for key: String in ["time", "day", "minute"]:
			if rec.has(key):
				rec[key] = int(rec[key])
		log.records.append(rec)
	var counts: Dictionary = d.get("action_counts", {})
	for id: String in counts:
		log.action_counts[id] = int(counts[id])
	log.tag_totals = (d.get("tag_totals", {}) as Dictionary).duplicate()
	return log
