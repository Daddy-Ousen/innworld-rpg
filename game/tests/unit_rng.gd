extends GutTest


func _sequence(r: Rng, n: int) -> Array:
	var out := []
	for i in n:
		out.append(r.randi())
	return out


func test_same_seed_gives_same_sequence() -> void:
	assert_eq(_sequence(Rng.new(42), 20), _sequence(Rng.new(42), 20))


func test_different_seed_gives_different_sequence() -> void:
	assert_ne(_sequence(Rng.new(1), 20), _sequence(Rng.new(2), 20))


func test_state_survives_json_round_trip() -> void:
	var a := Rng.new(123456789)
	_sequence(a, 7)
	var text := JSON.stringify(a.to_dict())
	var b := Rng.from_dict(JSON.parse_string(text))
	assert_eq(b.get_seed(), 123456789)
	assert_eq(_sequence(b, 20), _sequence(a, 20))


func test_pick_empty_returns_null() -> void:
	assert_null(Rng.new(1).pick([]))


func test_weighted_index_follows_weights() -> void:
	var rng := Rng.new(1)
	assert_eq(rng.weighted_index([]), -1)
	assert_eq(rng.weighted_index([0.0, -1.0]), -1)
	assert_eq(rng.weighted_index([0.0, 2.0, 0.0]), 1)
	var hits := [0, 0]
	for i in 1000:
		hits[rng.weighted_index([1.0, 3.0])] += 1
	assert_between(hits[1], 700, 800)
