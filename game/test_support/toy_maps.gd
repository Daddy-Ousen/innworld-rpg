## Small hand-made maps for world grid tests (ADR 0006), and walking helpers.
##   town (8×5, start 1,2): wall border, water at 5,1, a solid stove at 2,3,
##       a training dummy at 4,1 (zone toy_corner), an exit east to the
##       field (30 min) and a door at 6,3 into the shop (0 min).
##   field (4×3): exit west back to town (30 min).
##   shop (3×3): door at 1,2 back to town.
class_name ToyMaps
extends RefCounted


## ToyData + a travel action, a "spar" action with context rules, toy
## canon locations and the three maps. Validated; check d.maps.errors.
static func db() -> DataDb:
	var d := ToyData.db()
	d.tags["travel"] = ""
	d.actions["travel"] = {"name": "Travel", "minutes": 120, "base_xp": 5, "risk": 0.0,
		"tags": {"travel": 1.0}}
	d.actions["spar"] = {"name": "Spar", "minutes": 10, "base_xp": 5, "risk": 0.0,
		"tags": {"combat": 1.0}, "context": [
			{"key": "weapon", "equals": "stick", "add_tags": {"hospitality": 1.0}},
			{"key": "zone", "equals": "toy_corner", "add_tags": {"cooking": 1.0}},
		]}
	d.canon = CanonDb.from_dicts({}, locations(), {})
	d.rules["world"] = {"start": {"area": "town", "pos": [1, 2]}, "step_seconds": 6}
	d.maps = MapDb.from_dicts(tiles(), areas())
	d.maps.validate(d)
	return d


static func locations() -> Dictionary:
	return {
		"toy_town": {"name": "Toy town"},
		"toy_corner": {"name": "Toy corner"},
		"toy_field": {"name": "Toy field"},
		"toy_shop": {"name": "Toy shop"},
	}


static func tiles() -> Dictionary:
	return {
		"grass": {"name": "Grass", "walk": true, "color": "#00ff00"},
		"wall": {"name": "Wall", "walk": false, "color": "#444444"},
		"water": {"name": "Water", "walk": false, "color": "#0000ff"},
	}


static func areas() -> Dictionary:
	return {
		"town": area("town", "toy_town", [
			"wwwwwwww",
			"wgggg~gw",
			"wggggggg",
			"wggggggw",
			"wwwwwwww",
		], {"toy_corner": [[3, 1, 3, 1]]}, [
			{"at": [7, 2], "to": "field", "arrive": [1, 1], "minutes": 30},
			{"at": [6, 3], "to": "shop", "arrive": [1, 1], "minutes": 0},
		], [
			{"id": "stove", "at": [2, 3], "name": "Stove", "actions": ["cook"], "solid": true},
			{"id": "dummy", "at": [4, 1], "name": "Dummy", "actions": ["fight", "spar"],
				"context": {"weapon": "stick"}},
		]),
		"field": area("field", "toy_field", ["gggg", "gggg", "gggg"], {}, [
			{"at": [0, 1], "to": "town", "arrive": [6, 2], "minutes": 30},
		], []),
		"shop": area("shop", "toy_shop", ["www", "wgw", "wgw"], {}, [
			{"at": [1, 2], "to": "town", "arrive": [5, 2], "minutes": 0},
		], []),
	}


static func area(id: String, location: String, rows: Array, zones: Dictionary, exits: Array,
		objects: Array) -> Dictionary:
	return {
		"id": id, "name": id.capitalize(), "location": location, "confidence": "guess",
		"legend": {"g": "grass", "w": "wall", "~": "water"},
		"rows": rows, "zones": zones, "exits": exits, "objects": objects,
	}


## A toy game (day 1) with the player at the start.
static func new_game(d: DataDb, seed_value: int = 1) -> GameState:
	return GameState.new_game(seed_value, d)


## Walks the given steps. Returns false at the first step that does not move.
static func walk(gs: GameState, d: DataDb, steps: Array) -> bool:
	for dir: String in steps:
		if not Commands.move(gs, d, dir)["moved"]:
			return false
	return true


## Walks to the exit of the current map that leads to `to_area` and takes it.
static func walk_to_area(gs: GameState, d: DataDb, to_area: String) -> bool:
	var goals := {}
	for e: Dictionary in d.maps.areas[gs.player.area]["exits"]:
		if e["to"] == to_area:
			var r := MapDb.rect_of(e["at"])
			for y in range(r.position.y, r.end.y):
				for x in range(r.position.x, r.end.x):
					goals[Vector2i(x, y)] = true
	var found := Pathfind.path(d.maps, gs.player.area, gs.player.pos(), goals)
	return found["found"] and walk(gs, d, found["steps"]) and gs.player.area == to_area


## Walks until `object_id` (in the current map) is next to the player.
static func walk_next_to(gs: GameState, d: DataDb, object_id: String) -> bool:
	for o: Dictionary in d.maps.areas[gs.player.area]["objects"]:
		if o["id"] == object_id:
			var goals := Pathfind.around(Vector2i(int(o["at"][0]), int(o["at"][1])))
			var found := Pathfind.path(d.maps, gs.player.area, gs.player.pos(), goals)
			return found["found"] and walk(gs, d, found["steps"])
	return false
