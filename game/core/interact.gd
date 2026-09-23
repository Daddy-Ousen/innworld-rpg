## Map objects (ADR 0006) and NPCs (ADR 0008): what the player can use or
## who they can talk to from where they stand, and doing it. The action
## context gets the map's canon location, the zone (if any) and the
## object's own context. Talking to an NPC adds {"npc": id}, makes them a
## witness and raises their relationship with the player once a day.
##
## Objects with "sleep": true (a bed) also offer SLEEP. It is not an
## action: the presentation ends the day with Commands.sleep.
## Objects with an "item" (M5.2) also offer TAKE: the presentation calls
## Commands.take, and the player holds that item.
class_name Interact
extends RefCounted

const SLEEP := "sleep"
const TAKE := "take"


## Objects on or next to the player, nearest first, then NPCs next to the
## player: [{"id", "name", "actions": [action ids], "npc": bool, "sleep": bool,
## "item": item id to take or ""}].
static func options(gs: GameState, db: DataDb) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not Movement.ensure_placed(gs, db):
		return out
	for o: Dictionary in db.maps.objects_near(gs.player.area, gs.player.pos()):
		out.append({"id": o["id"], "name": o["name"], "actions": (o["actions"] as Array).duplicate(),
			"npc": false, "sleep": o.get("sleep", false), "item": o.get("item", "")})
	for id in NpcSim.near_player(gs):
		out.append({"id": id, "name": db.canon.npcs[id]["name"], "npc": true,
			"actions": (db.rules["npc"]["talk_actions"] as Array).duplicate(), "sleep": false,
			"item": ""})
	return out


## True if the player stands on or next to `object_id` and can sleep there.
static func can_sleep(gs: GameState, db: DataDb, object_id: String) -> bool:
	return options(gs, db).any(func(o: Dictionary) -> bool:
		return o["id"] == object_id and o["sleep"])


## Does `action_id` on the nearby object `object_id`. `opts` go to
## Actions.perform; opts.context is merged last. Returns
## {"record": Dictionary, "error": String}; error is "" on success.
static func perform(gs: GameState, db: DataDb, object_id: String, action_id: String,
		opts: Dictionary = {}) -> Dictionary:
	if not Movement.ensure_placed(gs, db):
		return _fail("There is no world to act in.")
	var obj := {}
	for o: Dictionary in options(gs, db):
		if o["id"] == object_id:
			obj = o
			break
	if obj.is_empty():
		return _fail("There is no '%s' here." % object_id)
	if not (obj["actions"] as Array).has(action_id):
		return _fail(("You cannot %s with %s." if obj["npc"] else "You cannot %s at the %s.")
				% [action_id, obj["name"]])
	var p := gs.player
	var context := {"location": db.maps.areas[p.area]["location"]}
	var zone := db.maps.zone_at(p.area, p.pos())
	if zone != "":
		context["zone"] = zone
	var full := opts.duplicate()
	if obj["npc"]:
		context["npc"] = object_id
		var witnesses: Array = (opts.get("witnesses", []) as Array).duplicate()
		if not witnesses.has(object_id):
			witnesses.push_front(object_id)
		full["witnesses"] = witnesses
	else:
		context.merge(_object(db, p.area, object_id).get("context", {}), true)
	context.merge(opts.get("context", {}), true)
	full["context"] = context
	var rec := Actions.perform(gs, db, action_id, full)
	if rec.is_empty():
		return _fail("You are too tired." if gs.clock.is_collapse_due(db.rules["clock"])
				else "You cannot do that.")
	if obj["npc"]:
		NpcSim.note_talk(gs, db, object_id)
	return {"record": rec, "error": ""}


static func _object(db: DataDb, area: String, id: String) -> Dictionary:
	for o: Dictionary in db.maps.areas[area]["objects"]:
		if o["id"] == id:
			return o
	return {}


static func _fail(why: String) -> Dictionary:
	return {"record": {}, "error": why}
