## Small hand-made combat content (M5, ADR 0010) on the ToyMaps world.
##   enemies: goblin (pack, hp 8, hits for 2, ranged stones for 1),
##            crab (ambush, hp 30, armor 4, hits for 5, scared by "stink"),
##            bird (territorial, hp 6, hits for 1, 4 s turns, guards its home).
##   items: stick (melee 3, throw 2, range 3), vase (melee 2, breaks on a hit,
##          range 2), stink (no damage, tag "stink", range 5).
##   The toy knock-out wake spot: from the field, the shop at 1,1.
## The player starts in town at 1,2 (ToyMaps); 2,2 (east) and 1,1 (north) are free.
## M5.2 adds the "arena" (14×9 open grass, no border walls, a wall at
## x 6, y 3–5, zone toy_corner [10, 0, 4, 4], an exit at 0,8 to town, a
## stick pile at 1,1 and a stink bush at 2,1 to take items from). Spawns
## are empty; tests add them to d.combat.spawns. Put the player there with
## to_arena().
class_name ToyCombat
extends RefCounted

const ARENA := [
	"gggggggggggggg",
	"gggggggggggggg",
	"gggggggggggggg",
	"ggggggwggggggg",
	"ggggggwggggggg",
	"ggggggwggggggg",
	"gggggggggggggg",
	"gggggggggggggg",
	"gggggggggggggg",
]


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
	var areas := ToyMaps.areas()
	areas["arena"] = ToyMaps.area("arena", "toy_field", ARENA, {"toy_corner": [[10, 0, 4, 4]]}, [
		{"at": [0, 8], "to": "town", "arrive": [1, 1], "minutes": 0},
	], [
		{"id": "stick_pile", "at": [1, 1], "name": "Stick pile", "actions": [], "item": "stick"},
		{"id": "stink_bush", "at": [2, 1], "name": "Stink bush", "actions": [], "item": "stink"},
	])
	d.maps = MapDb.from_dicts(ToyMaps.tiles(), areas)
	d.maps.validate(d)
	d.combat.validate(d)
	return d


## Moves the player to `pos` in the arena and syncs (no time passes; the
## town's monsters are gone and the arena's spawns are checked).
static func to_arena(gs: GameState, d: DataDb, pos: Vector2i) -> void:
	gs.player.place("arena", pos)
	Combat.sync(gs, d)


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
		"bird": {"name": "Bird", "confidence": "guess", "tags": ["razorbeak"], "color": "#44aa44",
			"danger": 0.4, "behaviour": "territorial", "hp": 6, "armor": 0, "accuracy": 4, "evasion": 5,
			"damage": [1, 1], "act_seconds": 4, "aggro_radius": 3, "lose_radius": 5, "chase_turns": 99,
			"flee_below": 0.34, "scared_by": []},
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


## Monsters never get a turn (the M5.1 core tests drive them by hand).
static func freeze(d: DataDb) -> void:
	for e: Dictionary in d.combat.enemies.values():
		e["act_seconds"] = 1000000


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
