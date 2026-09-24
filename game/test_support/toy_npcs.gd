## Toy NPCs on the ToyMaps world, for NPC tests (ADR 0008). Toy games
## start on day 1 at 06:00 with the player at town 1,2.
##   guard:  patrols town (1,1) ↔ (3,1) from 06 to 22, else off-map in "city".
##   baker:  works in the shop (1,1) from 08 to 12, else in "city".
##   farmer: works in the field (2,1) from 06 to 18, else in "city".
## "city" comes in and goes out at town 1,3. The talk action is "chat".
class_name ToyNpcs
extends RefCounted


static func db() -> DataDb:
	var d := ToyMaps.db()
	d.tags["social"] = ""
	d.actions["chat"] = {"name": "Chat", "minutes": 20, "base_xp": 2, "risk": 0.0,
		"tags": {"social": 1.0}}
	d.rules["npc"] = {"step_seconds": 8, "jump_seconds": 300, "talk_actions": ["chat"],
		"talk_relationship": 1, "react": d.rules["npc"]["react"]}
	d.canon = CanonDb.from_dicts(npcs(), ToyMaps.locations(), {})
	d.behaviour = BehaviourDb.from_dicts(entries(), behaviour())
	d.behaviour.validate(d)
	return d


static func npcs() -> Dictionary:
	return {
		"guard": {"name": "Guard", "tags": ["guard"]},
		"baker": {"name": "Baker", "tags": ["baker"]},
		"farmer": {"name": "Farmer", "tags": ["farmer"]},
	}


static func entries() -> Dictionary:
	return {"city": {"town": [1, 3]}}


static func behaviour() -> Dictionary:
	return {
		"guard": npc([
			goal("patrol", 2, {"hours": [[6, 22, 1]],
				"target": {"area": "town", "route": [[1, 1], [3, 1]]}}),
			goal("off_map", 1, {"target": {"off_map": "city"}}),
		]),
		"baker": npc([
			goal("work", 2, {"hours": [[8, 12, 1]], "target": {"area": "shop", "pos": [1, 1]}}),
			goal("off_map", 1, {"target": {"off_map": "city"}}),
		]),
		"farmer": npc([
			goal("work", 2, {"hours": [[6, 18, 1]], "target": {"area": "field", "pos": [2, 1]}}),
			goal("sleep", 1, {"target": {"off_map": "city"}}),
		]),
	}


static func npc(goals: Array) -> Dictionary:
	return {"confidence": "guess", "goals": goals}


static func goal(name: String, base: float, extra: Dictionary) -> Dictionary:
	var g := {"goal": name, "base": base}
	g.merge(extra)
	return g


## ToyNpcs + the ToyCombat enemies, items and fight actions (M6.5: NPCs
## near a fight), with canon `events` for the toy NPCs (e.g. a stage).
## Knock-outs in the field wake in the shop at 1,1. Check d.combat.errors.
static func combat_db(events: Dictionary = {}) -> DataDb:
	var d := db()
	var c := ToyCombat.db()
	d.tags.merge(c.tags)
	d.actions.merge(c.actions)
	d.rules["combat"]["knockout"]["wake"] = {"field": {"area": "shop", "pos": [1, 1]}}
	d.canon = CanonDb.from_dicts(npcs(), ToyMaps.locations(), events)
	d.combat = CombatDb.from_dicts(ToyCombat.enemies(), ToyCombat.items())
	d.combat.validate(d)
	return d


## A toy game (day 1, 06:00) with the NPCs placed.
static func new_game(d: DataDb, seed_value: int = 1) -> GameState:
	return GameState.new_game(seed_value, d)


static func pos(gs: GameState, id: String) -> Vector2i:
	return NpcRoster.pos_of(gs.npcs.npcs[id])


static func area(gs: GameState, id: String) -> String:
	return gs.npcs.npcs[id]["area"]
