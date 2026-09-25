## Money, goods and hunger (M8.6, ADR 0015). Part of GameState (save v11).
class_name EconomyState
extends RefCounted

## Coins, counted in copper (Economy.format shows silver and copper).
var coins: int = 0
## Goods the player carries: good id (data/economy.json) → count > 0.
var bag: Dictionary = {}
## The last day the player ate (or was fed at Erin's inn). -1 = never.
var fed_day: int = -1
## Hungry nights in a row (each one lowers max HP until the player eats).
var hunger: int = 0
## Shop id → the day the player last haggled there (better prices that day).
var haggled: Dictionary = {}


func count(good: String) -> int:
	return int(bag.get(good, 0))


func add(good: String, n: int) -> void:
	var left := count(good) + n
	if left > 0:
		bag[good] = left
	else:
		bag.erase(good)


## Bag goods, sorted by id.
func goods() -> Array[String]:
	var out: Array[String] = []
	out.assign(bag.keys())
	out.sort()
	return out


func to_dict() -> Dictionary:
	return {"coins": coins, "bag": bag.duplicate(), "fed_day": fed_day, "hunger": hunger,
		"haggled": haggled.duplicate()}


## Accepts {} (a migrated v10 save): no coins, an empty bag, never fed.
static func from_dict(d: Dictionary) -> EconomyState:
	var e := EconomyState.new()
	e.coins = int(d.get("coins", 0))
	for g: String in (d.get("bag", {}) as Dictionary):
		e.add(g, int(d["bag"][g]))
	e.fed_day = int(d.get("fed_day", -1))
	e.hunger = int(d.get("hunger", 0))
	for s: String in (d.get("haggled", {}) as Dictionary):
		e.haggled[s] = int(d["haggled"][s])
	return e
