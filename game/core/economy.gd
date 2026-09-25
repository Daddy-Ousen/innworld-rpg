## The economy (M8.6, ADR 0015; user choices 2026-09-25). Rules in
## rules.economy, goods and shops in data/economy.json (EconomyDb).
##   Coins: counted in copper, shown as silver and copper (format).
##   Trade: a map object with "shop" sells and buys goods. A trade is the
##   action buy_supplies / sell_goods for trade_minutes. Haggling at a shop
##   gives haggle_share better prices there for the rest of the day.
##   Yields and jobs: some actions put goods in the bag or pay coins.
##   Goods: food is eaten from the bag (fed today), a potion heals, clothes
##   are worn at once (wear_flag), a meal (eat_now) is eaten where bought.
##   Hunger: at night, a player who was not fed today gets one more hungry
##   night; each lowers max HP by hunger.step (never below hunger.floor)
##   until they eat. Working at Erin's inn (an inn work action at
##   hunger.inn_location while hunger.inn_npc lives) feeds you that day.
##   Ride: a map object with "ride" takes you to another map for a price;
##   it is a covered ride, so its minutes do not chill (Winter).
## A db without rules.economy (toy dbs) has no hunger and no money rules.
## Randomness (job pay) goes through gs.rng (CLAUDE.md rule 3).
class_name Economy
extends RefCounted

const BUY := "buy"
const SELL := "sell"
const BUY_ACTION := "buy_supplies"
const SELL_ACTION := "sell_goods"
const HAGGLE_ACTION := "haggle"


static func rules(db: DataDb) -> Dictionary:
	return db.rules.get("economy", {})


static func on(db: DataDb) -> bool:
	return not rules(db).is_empty()


## "1s 4c", "4c" or "0c".
static func format(db: DataDb, copper: int) -> String:
	var per := int(rules(db).get("copper_per_silver", 0))
	if per <= 0 or copper < per:
		return "%dc" % copper
	@warning_ignore("integer_division")
	var silver := copper / per
	return "%ds" % silver if copper % per == 0 else "%ds %dc" % [silver, copper % per]


## The price of `good` at `shop` today: kind BUY (what the player pays) or
## SELL (what the shop pays). Haggled today: buy lower (at least 1), sell higher.
static func price(gs: GameState, db: DataDb, shop: String, good: String, kind: String) -> int:
	var base := int(db.economy.goods[good][kind])
	if int(gs.economy.haggled.get(shop, -1)) != gs.clock.day():
		return base
	var share := float(rules(db).get("haggle_share", 0.0))
	if kind == BUY:
		return maxi(floori(base * (1.0 - share)), 1)
	return ceili(base * (1.0 + share))


## The trades at a shop object: [{"kind": BUY | SELL, "good", "name", "price"}],
## buys first; sells only goods in the bag. [] for an object with no shop.
static func trades(gs: GameState, db: DataDb, obj: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var shop: String = obj.get("shop", "")
	if shop == "" or not db.economy.shops.has(shop):
		return out
	var s: Dictionary = db.economy.shops[shop]
	for g: String in s["sells"]:
		out.append({"kind": BUY, "good": g, "name": db.economy.goods[g]["name"],
			"price": price(gs, db, shop, g, BUY)})
	for g: String in s["buys"]:
		if gs.economy.count(g) > 0:
			out.append({"kind": SELL, "good": g, "name": db.economy.goods[g]["name"],
				"price": price(gs, db, shop, g, SELL)})
	return out


## Buys one `good` at the nearby shop object `object_id`. Returns
## {"record", "error"} (see Interact.perform). What happened is in gs.combat.lines.
static func buy(gs: GameState, db: DataDb, object_id: String, good: String) -> Dictionary:
	var obj := _shop_object(gs, db, object_id)
	if obj.is_empty():
		return _fail("There is no shop '%s' here." % object_id)
	var shop: String = obj["shop"]
	if not (db.economy.shops[shop]["sells"] as Array).has(good):
		return _fail("%s does not sell that." % obj["name"])
	var cost := price(gs, db, shop, good, BUY)
	if gs.economy.coins < cost:
		return _fail("You cannot afford it (%s; you have %s)." % [format(db, cost),
				format(db, gs.economy.coins)])
	var r := _trade(gs, db, object_id, BUY_ACTION, good)
	if r["error"] != "":
		return r
	gs.economy.coins -= cost
	var g: Dictionary = db.economy.goods[good]
	var lines := gs.combat.lines
	lines.append("You buy %s for %s." % [String(g["name"]).to_lower(), format(db, cost)])
	match db.economy.use_of(good):
		"eat_now":
			_eat(gs, db)
			lines.append("You eat it there and then.")
		"wear_flag":
			gs.flags[g["wear_flag"]] = true
			lines.append("You put it on.")
		_:
			gs.economy.add(good, 1)
	return r


## Sells one `good` from the bag at the nearby shop object `object_id`.
## Returns {"record", "error"}.
static func sell(gs: GameState, db: DataDb, object_id: String, good: String) -> Dictionary:
	var obj := _shop_object(gs, db, object_id)
	if obj.is_empty():
		return _fail("There is no shop '%s' here." % object_id)
	var shop: String = obj["shop"]
	if not (db.economy.shops[shop]["buys"] as Array).has(good):
		return _fail("%s does not buy that." % obj["name"])
	if gs.economy.count(good) <= 0:
		return _fail("You have none to sell.")
	var paid := price(gs, db, shop, good, SELL)
	var r := _trade(gs, db, object_id, SELL_ACTION, good)
	if r["error"] != "":
		return r
	gs.economy.add(good, -1)
	gs.economy.coins += paid
	gs.combat.lines.append("You sell %s for %s." % [String(db.economy.goods[good]["name"]).to_lower(),
			format(db, paid)])
	return r


## After a done action (Commands.perform / Commands.interact): its yields go
## in the bag, a job pays, a haggle at a shop object marks the shop for today.
static func after_action(gs: GameState, db: DataDb, rec: Dictionary, object_id: String = "") -> void:
	if rec.is_empty():
		return
	var action: String = rec["action_id"]
	var lines := gs.combat.lines
	var got: Dictionary = db.economy.yields.get(action, {})
	for g: String in got:
		gs.economy.add(g, int(got[g]))
		lines.append("You get %d %s." % [int(got[g]), String(db.economy.goods[g]["name"]).to_lower()])
	if db.economy.jobs.has(action):
		var pay: Array = db.economy.jobs[action]["pay"]
		var coins := gs.rng.randi_range(int(pay[0]), int(pay[1]))
		gs.economy.coins += coins
		lines.append("You are paid %s." % format(db, coins))
	if action == HAGGLE_ACTION and object_id != "" and gs.player.is_placed():
		var shop: String = Interact.object_of(db, gs.player.area, object_id).get("shop", "")
		if shop != "":
			gs.economy.haggled[shop] = gs.clock.day()
			lines.append("Prices here are a little better for you today.")


## Uses a good from the bag: eats food (fed today, hunger gone) or drinks a
## potion (heals). Takes rules.economy.eat_minutes. Returns "" or an error.
static func use_good(gs: GameState, db: DataDb, good: String) -> String:
	if gs.economy.count(good) <= 0:
		return "You have no %s." % String(db.economy.goods.get(good, {}).get("name", good)).to_lower()
	var name := String(db.economy.goods[good]["name"]).to_lower()
	match db.economy.use_of(good):
		"food":
			_eat(gs, db)
			gs.combat.lines.append("You eat the %s." % name)
		"heal":
			var before := Combat.hp(gs, db)
			Combat.set_hp(gs, db, before + int(db.economy.goods[good]["heal"]))
			gs.combat.lines.append("You drink the %s. (+%d HP)" % [name, Combat.hp(gs, db) - before])
		_:
			return "You cannot use the %s." % name
	gs.economy.add(good, -1)
	Movement.wait(gs, db, int(rules(db).get("eat_minutes", 0)) * 60)
	return ""


## Fed today (ate, or worked at Erin's inn and it is night).
static func is_fed(gs: GameState) -> bool:
	return gs.economy.fed_day == gs.clock.day()


## Share of max HP left by hunger: 1.0, or less for each hungry night.
static func hp_mult(gs: GameState, db: DataDb) -> float:
	var h: Dictionary = rules(db).get("hunger", {})
	if h.is_empty() or gs.economy.hunger <= 0:
		return 1.0
	return maxf(float(h["floor"]), 1.0 - float(h["step"]) * gs.economy.hunger)


## Night step (Night.run), with the records since the last sleep: work at
## Erin's inn feeds you today. A sleep into a new day (`new_day`; a nap in
## the same day counts no hunger) then clears hunger if you were fed today,
## else adds one hungry night. Returns the morning lines.
static func night(gs: GameState, db: DataDb, records: Array[Dictionary],
		new_day: bool = true) -> Array[String]:
	var lines: Array[String] = []
	var h: Dictionary = rules(db).get("hunger", {})
	if h.is_empty():
		return lines
	var e := gs.economy
	if not is_fed(gs) and _worked_at_inn(gs, db, records, h):
		e.fed_day = gs.clock.day()
		lines.append(String(h["fed_line"]))
	if not new_day:
		return lines
	if is_fed(gs):
		e.hunger = 0
		return lines
	e.hunger += 1
	lines.append(String(h["hungry_line"]) % roundi(100.0 * (1.0 - hp_mult(gs, db))))
	return lines


## Takes the ride of the nearby map object `object_id`: pays, travels for
## its minutes (a travel action) and arrives at its pos. Returns "" or an error.
static func ride(gs: GameState, db: DataDb, object_id: String) -> String:
	if not Movement.ensure_placed(gs, db):
		return "There is no world to ride in."
	var obj := {}
	for o: Dictionary in db.maps.objects_near(gs.player.area, gs.player.pos()):
		if o["id"] == object_id and o.has("ride"):
			obj = o
	if obj.is_empty():
		return "There is no ride '%s' here." % object_id
	var r: Dictionary = obj["ride"]
	var cost := int(r["price"])
	if gs.economy.coins < cost:
		return "You cannot afford the ride (%s; you have %s)." % [format(db, cost),
				format(db, gs.economy.coins)]
	var minutes := int(r["minutes"])
	var rec := Actions.perform(gs, db, "travel", {
		"minutes": minutes,
		"intensity": float(minutes) / float(db.actions["travel"]["minutes"]),
		"context": {"from": gs.player.area, "to": r["to"], "ride": true},
	})
	if rec.is_empty():
		return "You are too tired."
	gs.economy.coins -= cost
	gs.player.place(r["to"], Vector2i(int(r["pos"][0]), int(r["pos"][1])))
	gs.winter.sec = NpcSim.world_sec(gs)  # a covered ride: no cold on the way
	gs.combat.lines.append("You pay %s and ride to %s." % [format(db, cost), db.maps.areas[r["to"]]["name"]])
	return ""


static func _worked_at_inn(gs: GameState, db: DataDb, records: Array[Dictionary], h: Dictionary) -> bool:
	if db.canon.npcs.has(h["inn_npc"]) and not gs.world.is_alive(db.canon, h["inn_npc"]):
		return false
	var work: Array = h["inn_work_actions"]
	return records.any(func(r: Dictionary) -> bool:
		return work.has(r["action_id"]) \
				and (r.get("context", {}) as Dictionary).get("location", "") == h["inn_location"])


static func _eat(gs: GameState, db: DataDb) -> void:
	gs.economy.fed_day = gs.clock.day()
	gs.economy.hunger = 0
	if gs.player.hp > 0:
		Combat.set_hp(gs, db, gs.player.hp)  # keeps HP; max HP is back


## A nearby object with a known shop, or {}.
static func _shop_object(gs: GameState, db: DataDb, object_id: String) -> Dictionary:
	if not Movement.ensure_placed(gs, db):
		return {}
	for o: Dictionary in db.maps.objects_near(gs.player.area, gs.player.pos()):
		if o["id"] == object_id and db.economy.shops.has(o.get("shop", "")):
			return o
	return {}


## The trade action for trade_minutes, with the good in the context.
static func _trade(gs: GameState, db: DataDb, object_id: String, action: String, good: String) -> Dictionary:
	var minutes := int(rules(db).get("trade_minutes", db.actions[action]["minutes"]))
	return Interact.perform(gs, db, object_id, action, {
		"minutes": minutes,
		"intensity": float(minutes) / float(db.actions[action]["minutes"]),
		"context": {"good": good},
	})


static func _fail(why: String) -> Dictionary:
	return {"record": {}, "error": why}
