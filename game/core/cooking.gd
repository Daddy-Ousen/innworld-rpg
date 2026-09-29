## Cooking (M14.1, ADR 0021). Recipes are in data/recipes.json (EconomyDb).
## After a cook action is done at a station (a map object whose kind is in
## the recipe's stations), a recipe whose inputs are all in the bag uses them
## up and puts its outputs in the bag. With no inputs, or at no station, the
## action is only practice: XP as before, no dish, and a line says why.
## An action with no recipe is left alone.
class_name Cooking
extends RefCounted


## After a done action (Commands.perform / Commands.interact). `object_id` is
## the object the action was done at ("" = none: no station).
static func after_action(gs: GameState, db: DataDb, rec: Dictionary, object_id: String = "") -> void:
	if rec.is_empty():
		return
	var ids := db.economy.recipes_for(rec["action_id"])
	if ids.is_empty():
		return
	var kind := _station_kind(gs, db, object_id)
	var here: Array[String] = []
	for id in ids:
		if (db.economy.recipes[id]["stations"] as Array).has(kind):
			here.append(id)
	var lines := gs.combat.lines
	if here.is_empty():
		lines.append("You have no place to cook that here, so it is only practice.")
		return
	for id in here:
		if can_cook(gs, db, id):
			cook(gs, db, id)
			return
	lines.append("You lack the ingredients (%s), so it is only practice." % _amounts(db, db.economy.recipes[here[0]]["inputs"]))


## True if the bag holds every input of recipe `id`.
static func can_cook(gs: GameState, db: DataDb, id: String) -> bool:
	var inputs: Dictionary = db.economy.recipes[id]["inputs"]
	for g: String in inputs:
		if gs.economy.count(g) < int(inputs[g]):
			return false
	return true


## Uses up the inputs of recipe `id` and adds its outputs. The caller has checked can_cook.
static func cook(gs: GameState, db: DataDb, id: String) -> void:
	var r: Dictionary = db.economy.recipes[id]
	for g: String in r["inputs"]:
		gs.economy.add(g, -int(r["inputs"][g]))
	for g: String in r["outputs"]:
		gs.economy.add(g, int(r["outputs"][g]))
	gs.combat.lines.append("You make %s." % _amounts(db, r["outputs"]))


## For a menu: what `action_id` does at a station of `kind` with today's bag.
## "" if the action has no recipe, else "makes 3 stew" or "needs 1 meat, 2 vegetables".
static func hint(gs: GameState, db: DataDb, action_id: String, kind: String) -> String:
	var first := ""
	for id in db.economy.recipes_for(action_id):
		var r: Dictionary = db.economy.recipes[id]
		if not (r["stations"] as Array).has(kind):
			continue
		if can_cook(gs, db, id):
			return "makes " + _amounts(db, r["outputs"])
		if first == "":
			first = "needs " + _amounts(db, r["inputs"])
	return first


## "3 stew", "1 meat, 2 vegetables".
static func _amounts(db: DataDb, m: Dictionary) -> String:
	var parts: Array[String] = []
	for g: String in m:
		parts.append("%d %s" % [int(m[g]), String(db.economy.goods[g]["name"]).to_lower()])
	return ", ".join(parts)


static func _station_kind(gs: GameState, db: DataDb, object_id: String) -> String:
	if object_id == "" or not gs.player.is_placed():
		return ""
	return String(Interact.object_of(db, gs.player.area, object_id).get("kind", ""))
