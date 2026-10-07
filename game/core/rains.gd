## The spring rains (M19.0, ADR 0030; Book 7). Two world flags from
## rules.rains: season_flag (rain falls outdoors: look and sound) and
## flood_flag (the Floodplains are under water). The flood itself is map
## overlays that hold on the flood flag (MapDb, M8.W), so walking needs no
## code here. Events set and clear the flags; this class only reads them.
class_name Rains
extends RefCounted


static func rules(db: DataDb) -> Dictionary:
	return db.rules.get("rains", {})


## True while the rains fall (and the db has rains rules).
static func on(gs: GameState, db: DataDb) -> bool:
	var r := rules(db)
	return not r.is_empty() and gs.flags.has(r["season_flag"])


## True while the flood stands (and the db has rains rules).
static func flooded(gs: GameState, db: DataDb) -> bool:
	var r := rules(db)
	return not r.is_empty() and gs.flags.has(r["flood_flag"])
