## The player's stats (M5, ADR 0010): the race's base stats from
## rules.combat.base_stats (or "default"), plus the stat_mod effects of the
## skills the player holds. Nothing stores them; they are worked out when
## needed, so a new skill counts at once.
class_name Stats
extends RefCounted


## {stat name: int}. Has every base stat, and any other stat a skill names.
static func of(gs: GameState, db: DataDb) -> Dictionary:
	var bases: Dictionary = db.rules["combat"]["base_stats"]
	var base: Dictionary = bases.get(gs.race, bases["default"])
	var out := {}
	for stat: String in base:
		out[stat] = int(base[stat])
	for e: Dictionary in SkillSystem.stat_effects(gs.progression, db):
		out[e["stat"]] = int(out.get(e["stat"], 0)) + int(e["value"])
	return out


static func get_stat(gs: GameState, db: DataDb, stat: String) -> int:
	return int(of(gs, db).get(stat, 0))


## hp_base + hp_per_endurance × endurance, at least 1.
static func max_hp(gs: GameState, db: DataDb) -> int:
	var c: Dictionary = db.rules["combat"]
	return maxi(int(c["hp_base"]) + int(c["hp_per_endurance"]) * get_stat(gs, db, "endurance"), 1)
