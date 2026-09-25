## Small hand-made content for System unit tests. Not a test script itself
## (GUT skips scripts that do not extend GutTest).
class_name ToyData
extends RefCounted


static func db() -> DataDb:
	var rules: Dictionary = DataDb.load_dir().rules.duplicate(true)
	rules["clock"]["start_minute"] = 360  # toy games start on day 1
	rules["levels"] = {"base_xp": 100, "growth": 2.0, "capstones": [3]}
	rules["offers"] = {"max_per_night": 2}
	rules["skills"] = {"on_accept": 1, "chance_per_level": 1.0, "base_weight": 0.1}
	rules.erase("winter")  # no winter in toy worlds (M8.W); ToyWinter adds it
	var tags := {"cooking": "", "cooking.stew": "", "combat": "", "hospitality": ""}
	var actions := {
		"cook": {"name": "Cook", "minutes": 60, "base_xp": 10, "risk": 0.0, "tags": {"cooking.stew": 1.0}},
		"fight": {"name": "Fight", "minutes": 10, "base_xp": 10, "risk": 0.0, "tags": {"combat": 1.0}},
	}
	var classes := {
		"cook": _class({"cooking": 1.0}, 20, {"loss": {"neglect_days": 3, "neglect_tags": ["cooking"]}}),
		"innkeeper": _class({"hospitality": 1.0, "cooking": 0.5}, 30),
		"warrior": _class({"combat": 1.0}, 20, {"excludes": ["pacifist"]}),
		"pacifist": _class({"hospitality": 1.0}, 10),
		"elf_guard": _class({"combat": 1.0}, 5, {"race_limits": {"allow": ["elf"]}}),
		"flag_class": _class({"combat": 1.0}, 5, {"prereqs": {"classes": [], "flags": ["met_relc"]}}),
		"battle_chef": _class({"combat": 1.0, "cooking": 1.0}, 10,
				{"consolidation": {"from": ["cook", "warrior"], "level_cost": 1}}),
	}
	var skills := {
		"stew_sense": _skill("common", [{"class": "cook", "min_level": 1, "max_level": 9, "weight": 1.0}],
				{"cooking.stew": 1.0}, [{"type": "xp_mult", "tags": ["cooking"], "value": 2.0}]),
		"knife_work": _skill("common", [{"class": "cook", "min_level": 1, "max_level": 9, "weight": 1.0}],
				{"combat": 1.0}, [{"type": "stat_mod", "stat": "dexterity", "value": 1}]),
		"grand_feast": _skill("rare", [{"class": "cook", "min_level": 3, "max_level": 9, "weight": 1.0}],
				{"cooking": 1.0}, [{"type": "action_unlock", "action": "cook"}]),
		"swing": _skill("common", [{"class": "warrior", "min_level": 1, "max_level": 9, "weight": 1.0}],
				{"combat": 1.0}, []),
	}
	return DataDb.from_dicts(tags, actions, rules, classes, skills)


static func _class(weights: Dictionary, threshold: float, extra: Dictionary = {}) -> Dictionary:
	var c := {
		"name": "[X]",
		"tag_weights": weights,
		"offer_threshold": threshold,
		"prereqs": {"classes": [], "flags": []},
		"excludes": [],
		"race_limits": null,
		"loss": null,
		"consolidation": null,
		"canon_ref": {"book": 1, "chapter": null, "confidence": "guess"},
	}
	c.merge(extra, true)
	return c


static func _skill(rarity: String, pools: Array, affinity: Dictionary, effects: Array) -> Dictionary:
	return {
		"name": "[S]",
		"rarity": rarity,
		"pools": pools,
		"tag_affinity": affinity,
		"effects": effects,
		"canon_ref": {"book": 1, "chapter": null, "confidence": "guess"},
	}


## A bare action record with fixed XP (skips the XP formula).
static func record(tags: Dictionary, xp: float, day: int = 1, time: int = 0) -> Dictionary:
	return {"time": time, "day": day, "minute": 0, "action_id": "toy", "tags": tags, "xp": xp}


## Holds `id` at `level` without an offer.
static func give_class(gs: GameState, id: String, level: int = 1, xp: float = 0.0) -> void:
	gs.progression.classes[id] = {"level": level, "xp": xp, "last_active_day": gs.clock.day()}
