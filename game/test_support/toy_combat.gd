## Small hand-made combat content (M5, ADR 0010) on the ToyMaps world.
##   enemies: goblin (pack, hp 8, hits for 2, ranged stones for 1),
##            crab (ambush, hp 30, armor 4, hits for 5, scared by "stink").
##   items: stick (melee 3, throw 2, range 3), vase (melee 2, breaks on a hit,
##          range 2), stink (no damage, tag "stink", range 5).
##   The toy knock-out wake spot: from the field, the shop at 1,1.
## The player starts in town at 1,2 (ToyMaps); 2,2 (east) and 1,1 (north) are free.
class_name ToyCombat
extends RefCounted


static func db() -> DataDb:
	var d := ToyMaps.db()
	for tag: String in ["combat.melee", "combat.block", "combat.thrown", "combat.improvise",
			"running", "running.escape", "medicine", "medicine.first_aid"]:
		d.tags[tag] = ""
	d.actions["attack_melee"] = {"name": "Attack", "minutes": 5, "base_xp": 8, "risk": 0.5,
		"tags": {"combat.melee": 1.0},
		"context": [{"key": "weapon", "equals": "improvised", "add_tags": {"combat.improvise": 1.0}}]}
	d.actions["block_attack"] = {"name": "Block", "minutes": 5, "base_xp": 7, "risk": 0.5,
		"tags": {"combat.block": 1.0}}
	d.actions["throw_object"] = {"name": "Throw", "minutes": 5, "base_xp": 7, "risk": 0.4,
		"tags": {"combat.thrown": 1.0},
		"context": [{"key": "weapon", "equals": "improvised", "add_tags": {"combat.improvise": 1.0}}]}
	d.actions["flee_danger"] = {"name": "Flee", "minutes": 10, "base_xp": 8, "risk": 0.6,
		"tags": {"running.escape": 1.0}}
	d.actions["bandage_wound"] = {"name": "Bandage", "minutes": 20, "base_xp": 6, "risk": 0.0,
		"tags": {"medicine.first_aid": 1.0}}
	d.rules["combat"]["knockout"]["wake"] = {"field": {"area": "shop", "pos": [1, 1]}}
	d.combat = CombatDb.from_dicts(enemies(), items())
	d.combat.validate(d)
	return d


static func enemies() -> Dictionary:
	return {
		"goblin": {"name": "Goblin", "confidence": "guess", "tags": ["goblin"], "color": "#00aa00",
			"danger": 0.5, "behaviour": "pack", "hp": 8, "armor": 0, "accuracy": 3, "evasion": 3,
			"damage": [2, 2], "act_seconds": 6, "aggro_radius": 4, "lose_radius": 6, "chase_turns": 10,
			"flee_below": 0.5, "scared_by": [], "ranged": {"range": 3, "damage": [1, 1], "chance": 0.25}},
		"crab": {"name": "Crab", "confidence": "guess", "tags": ["rock_crab"], "color": "#888888",
			"danger": 0.8, "behaviour": "ambush", "hp": 30, "armor": 4, "accuracy": 2, "evasion": 1,
			"damage": [5, 5], "act_seconds": 8, "aggro_radius": 1, "lose_radius": 3, "chase_turns": 5,
			"flee_below": 0.2, "scared_by": ["stink"], "scare_turns": 12,
			"ambush": {"spot_radius": 2, "hit_bonus": 0.2}},
	}


static func items() -> Dictionary:
	return {
		"stick": {"name": "Stick", "confidence": "guess", "melee": [3, 3], "throw": [2, 2],
			"throw_range": 3, "break_chance": 0.0, "tags": []},
		"vase": {"name": "Vase", "confidence": "guess", "melee": [2, 2], "throw": [2, 2],
			"throw_range": 2, "break_chance": 1.0, "tags": []},
		"stink": {"name": "Stink bomb", "confidence": "guess", "melee": [0, 0], "throw": [0, 0],
			"throw_range": 5, "break_chance": 1.0, "tags": ["stink"]},
	}


## Every hit lands (hit chance clamped to 1.0).
static func always_hit(d: DataDb) -> void:
	d.rules["combat"]["hit"]["min"] = 1.0
	d.rules["combat"]["hit"]["max"] = 1.0


## Every attack misses.
static func never_hit(d: DataDb) -> void:
	d.rules["combat"]["hit"]["min"] = 0.0
	d.rules["combat"]["hit"]["max"] = 0.0


## A toy game (day 1, 06:00) with the player in town at 1,2.
static func new_game(d: DataDb, seed_value: int = 1) -> GameState:
	return GameState.new_game(seed_value, d)


## Adds a monster at `pos` in the player's area (hostile by default).
static func spawn(gs: GameState, d: DataDb, type: String, pos: Vector2i,
		state: String = CombatState.HOSTILE) -> String:
	return Combat.add_monster(gs, d, type, pos, state)
