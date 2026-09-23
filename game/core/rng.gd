## Seeded random number generator. The only source of randomness in the game.
## Never call the global randi()/randf(); use an Rng owned by GameState.
class_name Rng
extends RefCounted

var _rng := RandomNumberGenerator.new()


func _init(seed_value: int = 0) -> void:
	_rng.seed = seed_value


func get_seed() -> int:
	return _rng.seed


func randi() -> int:
	return _rng.randi()


func randi_range(from: int, to: int) -> int:
	return _rng.randi_range(from, to)


func randf() -> float:
	return _rng.randf()


func randf_range(from: float, to: float) -> float:
	return _rng.randf_range(from, to)


## Returns a random element, or null for an empty array.
func pick(items: Array) -> Variant:
	if items.is_empty():
		return null
	return items[_rng.randi_range(0, items.size() - 1)]


## Picks an index with chance proportional to its weight. Weights <= 0 are
## never picked. Returns -1 if no weight is > 0. Uses one randf() call.
func weighted_index(weights: Array) -> int:
	var total := 0.0
	for w: Variant in weights:
		total += maxf(float(w), 0.0)
	if total <= 0.0:
		return -1
	var roll := _rng.randf() * total
	var last := -1
	for i in weights.size():
		var w := maxf(float(weights[i]), 0.0)
		if w <= 0.0:
			continue
		last = i
		if roll < w:
			return i
		roll -= w
	return last


## Seed and state are 64-bit ints. JSON parses numbers as floats and would lose
## precision, so we store them as strings.
func to_dict() -> Dictionary:
	return {"seed": str(_rng.seed), "state": str(_rng.state)}


static func from_dict(d: Dictionary) -> Rng:
	var r := Rng.new()
	r._rng.seed = String(d["seed"]).to_int()
	r._rng.state = String(d["state"]).to_int()
	return r
