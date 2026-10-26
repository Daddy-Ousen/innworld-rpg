extends GutTest
## M29.2 (ADR 0044): Liscor's Drakes are wary of a Human; Lism charges a stranger more.
## rules.standing.race_regard, real data.

const SEED := 20260929
const MARKET := "liscor_market"

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])


func _game() -> GameState:
	var gs := GameState.new_game(SEED, _db)
	gs.player.place(MARKET, Vector2i(5, 5))
	return gs


## Some Liscor Drake that is not an exception, and one that is.
func _drake(except: bool) -> String:
	var ex: Array = Standing.rules(_db)["race_regard"][0]["except"]
	var ids: Array = _db.canon.npcs.keys()
	ids.sort()
	for id: String in ids:
		var n: Dictionary = _db.canon.npcs[id]
		if n.get("race", "") == "Drake" and Standing.town_of_location(_db, String(n.get("home", ""))) == "liscor" \
				and ex.has(id) == except:
			return id
	return ""


func test_a_stranger_drake_starts_wary() -> void:
	var gs := _game()
	var id := _drake(false)
	assert_ne(id, "", "a Liscor Drake exists")
	assert_eq(Standing.race_start(gs, _db, id), -3)
	assert_eq(Standing.regard(gs, _db, id), -3 + gs.world.relationship(id, NpcSim.PLAYER))
	assert_eq(Standing.band(gs, _db, id)["label"], "wary")


func test_friends_of_erin_and_other_races_are_not_wary() -> void:
	var gs := _game()
	for id: String in ["relc", "olesm", "selys"]:
		assert_eq(Standing.race_start(gs, _db, id), 0, "%s is excepted" % id)
	assert_eq(Standing.race_start(gs, _db, "krshia"), 0, "a Gnoll")
	assert_eq(Standing.race_start(gs, _db, "no_such_npc"), 0)



## Zel's canon "home" is null (he has none). A null home or race must not break the
## String() call; such an NPC simply has no town, so no wariness.
func test_an_npc_with_a_null_home_or_race_starts_at_zero() -> void:
	var gs := _game()
	_db.canon.npcs["test_homeless_drake"] = {"race": "Drake", "home": null}
	_db.canon.npcs["test_no_race"] = {"race": null, "home": MARKET}
	var out := [Standing.race_start(gs, _db, "test_homeless_drake"), Standing.race_start(gs, _db, "test_no_race")]
	_db.canon.npcs.erase("test_homeless_drake")
	_db.canon.npcs.erase("test_no_race")
	assert_eq(out, [0, 0])
	assert_eq(Standing.race_start(gs, _db, "zel_shivertail"), 0, "a Drake with no home")

func test_reputation_wears_the_wariness_away() -> void:
	var gs := _game()
	var id := _drake(false)
	Standing.add_reputation(gs, _db, "liscor", 5)
	assert_eq(Standing.race_start(gs, _db, id), -2, "half way: -3 x 0.5 rounds to -2")
	Standing.add_reputation(gs, _db, "liscor", 5)
	assert_eq(Standing.race_start(gs, _db, id), 0, "reputation 10: gone")
	assert_eq(Standing.band(gs, _db, id)["label"], "" if gs.world.relationship(id, NpcSim.PLAYER) < 3 else "acquaintance")


func test_lism_charges_a_stranger_more_and_fairly_once_known() -> void:
	var gs := _game()
	var good := ""
	for g: String in _db.economy.shops["lism_stall"]["sells"]:
		good = g
		break
	var plain := Economy.price(gs, _db, "krshia_stall", good, Economy.BUY)
	var wary := Economy.price(gs, _db, "lism_stall", good, Economy.BUY)
	assert_gte(wary, plain, "never cheaper than the base price")
	assert_almost_eq(Standing.shop_markup(gs, _db, "lism_stall"), 0.15, 0.0001)
	assert_eq(Standing.shop_markup(gs, _db, "krshia_stall"), 0.0, "Krshia trades fairly")
	assert_eq(Economy.price(gs, _db, "lism_stall", good, Economy.SELL),
			Economy.price(gs, _db, "krshia_stall", good, Economy.SELL), "what he pays you is unchanged")
	Standing.add_reputation(gs, _db, "liscor", 10)
	assert_eq(Standing.shop_markup(gs, _db, "lism_stall"), 0.0, "known: no markup")


func test_a_db_without_race_regard_is_unchanged() -> void:
	var good: Dictionary = _db.rules["standing"]
	var plain := good.duplicate(true)
	plain.erase("race_regard")
	_db.rules["standing"] = plain
	var gs := _game()
	var out := [Standing.race_start(gs, _db, "olesm"), Standing.shop_markup(gs, _db, "lism_stall")]
	_db.rules["standing"] = good
	assert_eq(out, [0, 0.0])


func test_bad_race_regard_is_an_error_and_the_real_one_is_fine() -> void:
	assert_eq(Standing.validate(_db), [] as Array[String])
	var good: Dictionary = _db.rules["standing"]
	var bad := good.duplicate(true)
	bad["race_regard"] = [{"town": "moon", "race": "Drake", "start": -1, "fade": 5},
			{"town": "liscor", "race": "Drake", "start": -1, "fade": 0},
			{"town": "liscor", "race": "Drake", "start": -1, "fade": 5, "shops": ["no_such_shop"]}]
	_db.rules["standing"] = bad
	var errs := Standing.validate(_db)
	_db.rules["standing"] = good
	assert_eq(errs.size(), 3, str(errs))
