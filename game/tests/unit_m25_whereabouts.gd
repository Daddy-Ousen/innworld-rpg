extends GutTest
## Magnolia's whereabouts by canon flags (M25.4): Celum in Book 1, the road
## north, the estate, away from 3.14 to 4.38B. Ressa goes with her. The
## Earthers Rose, Imani and Joseph stay at the estate from 2.23. Real data;
## the director runs the canon with no player.

const HOUR := 3600

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()


func _area(gs: GameState, npc: String, day: int, hour: int) -> String:
	var sec := (day - 1) * UtilityAi.SECONDS_PER_DAY + hour * HOUR
	return BehaviourDb.target_area(UtilityAi.pick(gs, _db, npc, sec)["target"])


func test_the_behaviour_data_loads_clean() -> void:
	assert_eq(_db.behaviour.errors, [] as Array[String])


func test_every_whereabouts_flag_is_set_by_a_canon_event() -> void:
	var set_by := {}
	for id: String in _db.canon.events:
		for f: String in _db.canon.events[id].get("effects", {}).get("set_flags", []):
			set_by[f] = true
	for npc: String in ["magnolia_reinhart", "ressa", "rose", "imani", "joseph"]:
		for g: Dictionary in _db.behaviour.npcs[npc]["goals"]:
			for f: String in g.get("when_flags", []) + g.get("unless_flags", []):
				assert_true(set_by.has(f), "%s: %s" % [npc, f])


func test_the_earthers_have_posts_on_the_estate_maps() -> void:
	for npc: String in ["rose", "imani", "joseph"]:
		assert_true(_db.canon.npcs.has(npc), npc)
		for g: Dictionary in _db.behaviour.npcs[npc]["goals"]:
			var t: Dictionary = g["target"]
			if t.has("area"):
				assert_true(str(t["area"]).begins_with("magnolia_estate_"), npc)
				var at := Vector2i(int(t["pos"][0]), int(t["pos"][1]))
				assert_true(_db.maps.is_walkable(t["area"], at), "%s post %s" % [npc, at])


func test_magnolia_and_ressa_follow_the_canon() -> void:
	var gs := GameState.new(11)
	# Book 1: her Celum house.
	Director.run(gs, _db, 20)
	for npc: String in ["magnolia_reinhart", "ressa"]:
		assert_eq(_area(gs, npc, 20, 12), "@celum", npc + " day 20")
	# After 1.63 and before 2.06: on the road north.
	gs.flags["magnolia.gone_north"] = true
	for npc: String in ["magnolia_reinhart", "ressa"]:
		assert_eq(_area(gs, npc, 42, 12), "@north_izril", npc + " on the road")
	gs.flags.erase("magnolia.gone_north")
	# Book 2 on: the estate (hall by day, inside at night).
	Director.run(gs, _db, 70)
	assert_true(gs.flags.has("magnolia.watches_the_inn"))
	for npc: String in ["magnolia_reinhart", "ressa"]:
		assert_eq(_area(gs, npc, 70, 12), "magnolia_estate_hall", npc + " day 70")
		assert_eq(_area(gs, npc, 70, 2), "@magnolia_estate", npc + " night 70")
	# 3.14: gone to First Landing, away in the north.
	Director.run(gs, _db, 90)
	assert_true(gs.flags.has("magnolia.gone_to_first_landing"))
	for npc: String in ["magnolia_reinhart", "ressa"]:
		assert_eq(_area(gs, npc, 90, 12), "@north_izril", npc + " day 90")
	# 4.38B: back at the estate.
	Director.run(gs, _db, 127)
	assert_true(gs.flags.has("magnolia.sends_gold_to_esthelm"))
	assert_eq(_area(gs, "magnolia_reinhart", 127, 12), "magnolia_estate_hall")


func test_the_earthers_show_once_magnolia_hides_them() -> void:
	var gs := GameState.new(11)
	for npc: String in ["rose", "imani", "joseph"]:
		assert_eq(_area(gs, npc, 45, 12), "@magnolia_estate", npc + " hidden")
	Director.run(gs, _db, 67)
	assert_true(gs.flags.has("magnolia.hides_other_earthers"))
	assert_eq(_area(gs, "rose", 67, 12), "magnolia_estate_hall")
	assert_eq(_area(gs, "imani", 67, 12), "magnolia_estate_hall")
	assert_eq(_area(gs, "joseph", 67, 12), "magnolia_estate_grounds")
	assert_eq(_area(gs, "rose", 67, 23), "@magnolia_estate")


## M35.3: Book 6 camp days, the battle of Invrisil and the walls after it.
func test_magnolia_and_ressa_at_invrisil_in_book_6() -> void:
	var gs := GameState.new(11)
	for f: String in ["magnolia.gone_north", "magnolia.watches_the_inn", "magnolia.sends_gold_to_esthelm"]:
		gs.flags[f] = true
	gs.flags["magnolia.levy_waits_at_invrisil"] = true
	for npc: String in ["magnolia_reinhart", "ressa"]:
		assert_eq(_area(gs, npc, 129, 12), "@invrisil", npc + " camp by day")
		assert_eq(_area(gs, npc, 129, 23), "@magnolia_estate", npc + " estate at night")
	gs.flags["invrisil.battle_begun"] = true
	for npc: String in ["magnolia_reinhart", "ressa"]:
		assert_eq(_area(gs, npc, 130, 12), "invrisil_battlefield", npc + " battle")
		assert_eq(_area(gs, npc, 130, 23), "invrisil_battlefield", npc + " battle at night")
	gs.flags["magnolia.offered_a_bounty_on_the_necromancer"] = true
	for npc: String in ["magnolia_reinhart", "ressa"]:
		assert_eq(_area(gs, npc, 132, 12), "invrisil_gate", npc + " walls by day")
		assert_eq(_area(gs, npc, 132, 2), "@magnolia_estate", npc + " estate at night")
	gs.flags["magnolia.defends_invrisil"] = true
	for npc: String in ["magnolia_reinhart", "ressa"]:
		assert_eq(_area(gs, npc, 140, 12), "magnolia_estate_hall", npc + " Book 7 estate")


## M35.3: if the battle never starts, the camp stay still ends at 5.02.
func test_the_camp_stay_ends_when_reiss_marches_past() -> void:
	var gs := GameState.new(11)
	for f: String in ["magnolia.gone_north", "magnolia.watches_the_inn", "magnolia.sends_gold_to_esthelm"]:
		gs.flags[f] = true
	gs.flags["magnolia.levy_waits_at_invrisil"] = true
	gs.flags["magnolia.defends_invrisil"] = true
	assert_eq(_area(gs, "magnolia_reinhart", 135, 12), "magnolia_estate_hall")


## M35.3: the real canon sets the flags in order. The events need Magnolia
## alive, so this starts a full new game and sleeps (no player choices).
func test_the_canon_runs_magnolia_through_invrisil() -> void:
	var gs := GameState.new_game(1, _db)
	ToyCanon.sleep_through(gs, _db, 129)
	assert_true(gs.flags.has("magnolia.recorded_the_speech"))
	assert_false(gs.flags.has("invrisil.battle_begun"))
	assert_eq(_area(gs, "magnolia_reinhart", 129, 12), "@invrisil")
	ToyCanon.sleep_through(gs, _db, 133)
	assert_true(gs.flags.has("magnolia.offered_a_bounty_on_the_necromancer"))
	assert_false(gs.flags.has("magnolia.defends_invrisil"))
	assert_eq(_area(gs, "magnolia_reinhart", 133, 12), "invrisil_gate")
	ToyCanon.sleep_through(gs, _db, 135)
	assert_true(gs.flags.has("magnolia.defends_invrisil"))
	assert_eq(_area(gs, "magnolia_reinhart", 135, 12), "magnolia_estate_hall")


## M35.3: every map post of Magnolia and Ressa is on a walkable tile.
func test_magnolia_and_ressa_posts_are_walkable() -> void:
	for npc: String in ["magnolia_reinhart", "ressa"]:
		for g: Dictionary in _db.behaviour.npcs[npc]["goals"]:
			var t: Dictionary = g["target"]
			if t.has("area"):
				var at := Vector2i(int(t["pos"][0]), int(t["pos"][1]))
				assert_true(_db.maps.is_walkable(t["area"], at), "%s post %s %s" % [npc, t["area"], at])
