## Winter (M8.W, ADR 0014; user choices 2026-09-25). From the canon flag
## rules.winter.flag (izril.winter, day 42):
##   Cold: outdoors and not warm, every cold.every_minutes the player loses
##   cold.damage HP, never below cold.floor_hp. Warm = an indoor map
##   (MapDb.is_indoor) or within cold.warm_radius of an object with
##   "warm": true. Winter clothes (flag winter.clothes_flag) make each tick
##   cold.clothes_mult times longer. Warmth resets the chill; a night does
##   not count (Night.run calls night()). A warm meal (M9.2: a good with
##   warm_minutes, e.g. Corusdeer soup) keeps you warm anywhere until
##   winter.warm_until.
##   Frost Fairies: on entering an outdoor map, a chance of a few fairies
##   that flit about (one step per fairies.act_seconds). Talking to one is
##   the action fairies.talk_action (a rude line); after the day's
##   safe_talks, each talk may annoy them. Walking into one swats at it.
##   An annoyed fairy drops snow: snow_damage HP (never below the cold
##   floor) and slow_steps steps at double time. Holding an item with
##   fairies.iron_tag makes them keep away and never drop snow.
## Everything random goes through gs.rng (CLAUDE.md rule 3).
class_name Winter
extends RefCounted

const FAIRY := "fairy:"
const ORTHO: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
## Gaps longer than this re-scatter the fairies instead of moving them.
const SCATTER_SECONDS := 300


static func rules(db: DataDb) -> Dictionary:
	return db.rules.get("winter", {})


## True once the winter flag is set (and the db has winter rules).
static func on(gs: GameState, db: DataDb) -> bool:
	var r := rules(db)
	return not r.is_empty() and gs.flags.has(r["flag"])


static func has_clothes(gs: GameState, db: DataDb) -> bool:
	return gs.flags.has(rules(db)["clothes_flag"])


## Indoors, near a warm object (a fire, a brazier), or warmed by a meal.
static func is_warm(gs: GameState, db: DataDb) -> bool:
	if gs.winter.warm_until > NpcSim.world_sec(gs):
		return true
	var area := gs.player.area
	if db.maps.is_indoor(area):
		return true
	var radius := int(rules(db)["cold"]["warm_radius"])
	for o: Dictionary in db.maps.areas[area]["objects"]:
		if bool(o.get("warm", false)):
			var d := Vector2i(int(o["at"][0]), int(o["at"][1])) - gs.player.pos()
			if maxi(absi(d.x), absi(d.y)) <= radius:
				return true
	return false


## "cold" (winter, outdoors, not warm), "warm" (winter, warm) or "" (no winter).
static func status(gs: GameState, db: DataDb) -> String:
	if not on(gs, db) or not gs.player.is_placed():
		return ""
	return "warm" if is_warm(gs, db) else "cold"


## Commands._after: the cold since the last sync, then the fairies.
static func sync(gs: GameState, db: DataDb) -> void:
	var w := gs.winter
	var now := NpcSim.world_sec(gs)
	var dt := 0 if w.sec < 0 else maxi(now - w.sec, 0)
	w.sec = now
	if not on(gs, db) or not gs.player.is_placed() or db.maps.is_empty():
		w.chill = 0
		w.fairies.clear()
		w.area = ""
		return
	_cold(gs, db, dt)
	_fairies(gs, db, dt)


## Night.run: the night does not chill; the fairies are rolled again on
## waking. `wake_sec` is the world second the player wakes at.
static func night(gs: GameState, wake_sec: int) -> void:
	var w := gs.winter
	w.sec = wake_sec
	w.chill = 0
	w.slowed = 0
	w.fairies.clear()
	w.area = ""


## The morning line on the first night of winter (once), or "".
static func warning(gs: GameState, db: DataDb) -> String:
	var r := rules(db)
	if r.is_empty() or not gs.flags.has(r["flag"]) or gs.flags.has(r["warned_flag"]):
		return ""
	gs.flags[r["warned_flag"]] = true
	return String(r["cold"]["morning_line"])


static func _cold(gs: GameState, db: DataDb, dt: int) -> void:
	var w := gs.winter
	if Combat.is_down(gs) or is_warm(gs, db):
		w.chill = 0
		return
	# The part of dt that a warm meal still covered does not chill.
	dt = mini(dt, maxi(NpcSim.world_sec(gs) - w.warm_until, 0)) if w.warm_until >= 0 else dt
	var cold: Dictionary = rules(db)["cold"]
	var tick := int(cold["every_minutes"]) * 60
	if has_clothes(gs, db):
		tick = int(round(tick * float(cold["clothes_mult"])))
	w.chill += dt
	var lost := 0
	while w.chill >= tick:
		w.chill -= tick
		lost += _hurt(gs, db, int(cold["damage"]))
	if lost > 0:
		gs.combat.lines.append(String(cold["line"]) % lost)


## A warm meal: no cold for `minutes` from now (or longer, if one still warms).
static func warm_for(gs: GameState, minutes: int) -> void:
	gs.winter.warm_until = maxi(gs.winter.warm_until, NpcSim.world_sec(gs) + minutes * 60)


## Takes up to `amount` HP, never below the cold floor. Returns the HP lost.
static func _hurt(gs: GameState, db: DataDb, amount: int) -> int:
	var hp := Combat.hp(gs, db)
	var floor_hp := int(rules(db)["cold"]["floor_hp"])
	var left := maxi(hp - amount, mini(floor_hp, hp))
	if left < hp:
		Combat.set_hp(gs, db, left)
	return hp - left


static func holds_iron(gs: GameState, db: DataDb) -> bool:
	var item: Dictionary = db.combat.items.get(gs.player.held, {})
	return (item.get("tags", []) as Array).has(rules(db)["fairies"]["iron_tag"])


static func _fairies(gs: GameState, db: DataDb, dt: int) -> void:
	var w := gs.winter
	var area := gs.player.area
	if db.maps.is_indoor(area):
		w.fairies.clear()
		w.area = area
		return
	var fr: Dictionary = rules(db)["fairies"]
	if w.area != area:
		w.area = area
		w.fairies.clear()
		if gs.rng.randf() < float(fr["chance"]):
			var n := gs.rng.randi_range(int(fr["count"][0]), int(fr["count"][1]))
			for i in n:
				_place(gs, db, "f%d" % w.next_id)
				w.next_id += 1
		return
	if w.fairies.is_empty():
		return
	if dt > SCATTER_SECONDS:
		for id in w.ids():
			w.fairies.erase(id)
			_place(gs, db, id)
		return
	@warning_ignore("integer_division")
	var turns := dt / int(fr["act_seconds"])
	for t in turns:
		for id in w.ids():
			_flit(gs, db, id)


## Puts fairy `id` on a random tile at least fairies.min_distance from the
## player, not on another fairy (20 tries; gives up quietly).
static func _place(gs: GameState, db: DataDb, id: String) -> void:
	var size := db.maps.size(gs.player.area)
	var min_d := int(rules(db)["fairies"]["min_distance"])
	for i in 20:
		var at := Vector2i(gs.rng.randi_range(0, size.x - 1), gs.rng.randi_range(0, size.y - 1))
		var d := at - gs.player.pos()
		if maxi(absi(d.x), absi(d.y)) >= min_d and gs.winter.at(at) == "":
			gs.winter.fairies[id] = {"x": at.x, "y": at.y}
			return


## One step for a fairy: away from the player when they hold iron (to at
## least fairies.iron_radius), else a random step or none. They fly: any
## tile in the map, but not the player's or another fairy's.
static func _flit(gs: GameState, db: DataDb, id: String) -> void:
	var w := gs.winter
	var pos := WinterState.pos_of(w.fairies[id])
	var you := gs.player.pos()
	var size := db.maps.size(gs.player.area)
	var choice := Vector2i.ZERO
	if holds_iron(gs, db):
		var best := _far(pos, you)
		if best >= int(rules(db)["fairies"]["iron_radius"]):
			return
		for off in ORTHO:
			if _far(pos + off, you) > best:
				best = _far(pos + off, you)
				choice = off
	else:
		var r := gs.rng.randi_range(0, 4)
		choice = ORTHO[r] if r < 4 else Vector2i.ZERO
	var to := pos + choice
	if choice == Vector2i.ZERO or to.x < 0 or to.y < 0 or to.x >= size.x or to.y >= size.y \
			or to == you or w.at(to) != "":
		return
	w.fairies[id] = {"x": to.x, "y": to.y}


static func _far(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


## Fairies on or next to the player: [fairy id].
static func near(gs: GameState) -> Array[String]:
	var out: Array[String] = []
	if gs.winter.area != gs.player.area:
		return out
	for id in gs.winter.ids():
		if _far(WinterState.pos_of(gs.winter.fairies[id]), gs.player.pos()) <= 1:
			out.append(id)
	return out


## Talks to fairy `id` (Interact, object id "fairy:<id>"): the talk action
## with context {"location", "fairy": true}, a rude line, and past the
## day's safe talks a chance they drop snow. Returns {"record", "error"}.
static func talk(gs: GameState, db: DataDb, id: String) -> Dictionary:
	if not near(gs).has(id):
		return {"record": {}, "error": "There is no fairy here."}
	var fr: Dictionary = rules(db)["fairies"]
	var rec := Actions.perform(gs, db, fr["talk_action"], {"context": {
		"location": db.maps.areas[gs.player.area]["location"], "fairy": true}})
	if rec.is_empty():
		return {"record": {}, "error": "You are too tired."}
	var lines: Array = fr["lines"]
	gs.combat.lines.append("%s: \"%s\"" % [fr["name"], lines[gs.rng.randi_range(0, lines.size() - 1)]])
	if _talks_today(gs, db) > int(fr["safe_talks_per_day"]) and not holds_iron(gs, db) \
			and gs.rng.randf() < float(fr["annoy_chance"]):
		drop_snow(gs, db)
	return {"record": rec, "error": ""}


## Walking into fairy `id`: a swat. It dodges and drops snow (unless the
## player holds iron). Costs one turn.
static func swat(gs: GameState, db: DataDb, id: String) -> void:
	var fr: Dictionary = rules(db)["fairies"]
	gs.combat.lines.append(String(fr["swat_line"]))
	Movement.spend_turn(gs, db)
	if not holds_iron(gs, db):
		drop_snow(gs, db)


static func drop_snow(gs: GameState, db: DataDb) -> void:
	var fr: Dictionary = rules(db)["fairies"]
	_hurt(gs, db, int(fr["snow_damage"]))
	gs.winter.slowed = int(fr["slow_steps"])
	gs.combat.lines.append(String(fr["snow_line"]))


static func _talks_today(gs: GameState, db: DataDb) -> int:
	var action: String = rules(db)["fairies"]["talk_action"]
	var n := 0
	for r: Dictionary in gs.action_log.records:
		if int(r["time"]) >= gs.progression.day_start and r["action_id"] == action:
			n += 1
	return n


## Step time while slowed: double, and one slow step is used up.
static func step_seconds(gs: GameState, base: int) -> int:
	if gs.winter.slowed <= 0:
		return base
	gs.winter.slowed -= 1
	return base * 2
