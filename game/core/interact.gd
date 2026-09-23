## Map objects (ADR 0006): what the player can use from where they stand,
## and doing an object's action. The action context gets the map's canon
## location, the zone (if any) and the object's own context.
class_name Interact
extends RefCounted


## Objects on or next to the player, nearest first:
## [{"id", "name", "actions": [action ids]}].
static func options(gs: GameState, db: DataDb) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not Movement.ensure_placed(gs, db):
		return out
	for o: Dictionary in db.maps.objects_near(gs.player.area, gs.player.pos()):
		out.append({"id": o["id"], "name": o["name"], "actions": (o["actions"] as Array).duplicate()})
	return out


## Does `action_id` on the nearby object `object_id`. `opts` go to
## Actions.perform; opts.context is merged last. Returns
## {"record": Dictionary, "error": String}; error is "" on success.
static func perform(gs: GameState, db: DataDb, object_id: String, action_id: String,
		opts: Dictionary = {}) -> Dictionary:
	if not Movement.ensure_placed(gs, db):
		return _fail("There is no world to act in.")
	var obj := {}
	for o: Dictionary in db.maps.objects_near(gs.player.area, gs.player.pos()):
		if o["id"] == object_id:
			obj = o
			break
	if obj.is_empty():
		return _fail("There is no '%s' here." % object_id)
	if not (obj["actions"] as Array).has(action_id):
		return _fail("You cannot %s at the %s." % [action_id, obj["name"]])
	var p := gs.player
	var context := {"location": db.maps.areas[p.area]["location"]}
	var zone := db.maps.zone_at(p.area, p.pos())
	if zone != "":
		context["zone"] = zone
	context.merge(obj.get("context", {}), true)
	context.merge(opts.get("context", {}), true)
	var full := opts.duplicate()
	full["context"] = context
	var rec := Actions.perform(gs, db, action_id, full)
	if rec.is_empty():
		return _fail("You are too tired." if gs.clock.is_collapse_due(db.rules["clock"])
				else "You cannot do that.")
	return {"record": rec, "error": ""}


static func _fail(why: String) -> Dictionary:
	return {"record": {}, "error": why}
