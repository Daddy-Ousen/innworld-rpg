extends GutTest
## Friend perks (M33.4, ADR 0044 "M33.4"): rules.standing.perks. A perk is on while regard with
## its NPC reaches its band. Kinds: discount (BUY price at the shops), talk_xp (XP of an action done
## with that NPC), fight_help (fights beside the player from "friend"). Night.run says each perk once.
## Real data, plus bad-data checks.

const SEED := 20261026

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String], "real data loads clean")


func _gs() -> GameState:
	return GameState.new_game(SEED, _db)


## Set regard with `npc` to exactly `to` (the start regard of a fresh game is not always 0).
func _regard(gs: GameState, npc: String, to: int) -> void:
	gs.world.add_relationship(npc, NpcSim.PLAYER, to - Standing.regard(gs, _db, npc))


func test_the_real_perks_are_valid() -> void:
	assert_eq(Standing.validate(_db), [] as Array[String])
	assert_true(Standing.rules(_db)["perks"].size() >= 30)


func test_every_perk_npc_has_a_perk_at_each_band() -> void:
	var seen := {}
	for p: Dictionary in Standing.rules(_db)["perks"]:
		seen["%s|%s" % [p["npc"], p["band"]]] = true
	for p: Dictionary in Standing.rules(_db)["perks"]:
		assert_true(seen.has("%s|friend" % p["npc"]), "%s has a friend perk" % p["npc"])
		assert_true(seen.has("%s|close friend" % p["npc"]), "%s has a close friend perk" % p["npc"])


func test_a_friend_gives_a_discount_that_grows() -> void:
	var gs := _gs()
	var base := Economy.price(gs, _db, "krshia_stall", "bread", Economy.BUY)
	_regard(gs, "krshia", 7)
	assert_almost_eq(Standing.perk_discount(gs, _db, "krshia_stall"), 0.05, 0.0001)
	assert_almost_eq(Standing.perk_discount(gs, _db, "lism_stall"), 0.0, 0.0001, "another shop is not cheaper")
	_regard(gs, "krshia", 12)
	assert_almost_eq(Standing.perk_discount(gs, _db, "krshia_stall"), 0.1, 0.0001)
	assert_true(Economy.price(gs, _db, "krshia_stall", "bread", Economy.BUY) <= base)
	var dear := Economy.price(gs, _db, "krshia_stall", "healing_potion", Economy.BUY)
	_regard(gs, "krshia", 0)
	assert_true(Economy.price(gs, _db, "krshia_stall", "healing_potion", Economy.BUY) >= dear, "no perk, no discount")


func test_a_discount_never_changes_what_the_shop_pays() -> void:
	var gs := _gs()
	var before := Economy.price(gs, _db, "krshia_stall", "bread", Economy.SELL)
	_regard(gs, "krshia", 12)
	assert_eq(Economy.price(gs, _db, "krshia_stall", "bread", Economy.SELL), before)


func test_time_with_a_friend_teaches_more() -> void:
	var gs := _gs()
	_regard(gs, "erin_solstice", 0)
	var plain: float = Actions.perform(gs, _db, "talk_with_guest", {"context": {"npc": "erin_solstice"}})["xp"]
	var other := _gs()
	_regard(other, "erin_solstice", 7)
	var friend: float = Actions.perform(other, _db, "talk_with_guest", {"context": {"npc": "erin_solstice"}})["xp"]
	assert_almost_eq(friend, plain * 1.25, plain * 0.001)
	var close := _gs()
	_regard(close, "erin_solstice", 12)
	var best: float = Actions.perform(close, _db, "talk_with_guest", {"context": {"npc": "erin_solstice"}})["xp"]
	assert_almost_eq(best, plain * 1.5, plain * 0.001)


func test_an_action_with_nobody_gets_no_bonus() -> void:
	var gs := _gs()
	var a: float = Actions.perform(gs, _db, "sweep_floor")["xp"]
	var other := _gs()
	_regard(other, "erin_solstice", 12)
	var b: float = Actions.perform(other, _db, "sweep_floor")["xp"]
	assert_almost_eq(a, b, 0.0001)


func test_a_friend_fights_beside_you_from_friend() -> void:
	var gs := _gs()
	_regard(gs, "relc", 5)
	assert_false(Standing.is_friend(gs, _db, "relc"))
	_regard(gs, "relc", 6)
	assert_true(Standing.is_friend(gs, _db, "relc"), "a fight_help perk at friend")
	_regard(gs, "erin_solstice", 6)
	assert_false(Standing.is_friend(gs, _db, "erin_solstice"), "no fight_help perk: still needs friend_fight")
	_regard(gs, "erin_solstice", 10)
	assert_true(Standing.is_friend(gs, _db, "erin_solstice"))


func test_each_perk_is_told_once() -> void:
	var gs := _gs()
	Standing.perk_news(gs, _db)  # perks a fresh game already has
	_regard(gs, "krshia", 7)
	var lines := Standing.perk_news(gs, _db)
	assert_eq(lines.size(), 1)
	assert_true(lines[0].contains("Krshia"))
	assert_eq(Standing.perk_news(gs, _db), [] as Array[String], "told once")
	_regard(gs, "krshia", 12)
	assert_eq(Standing.perk_news(gs, _db).size(), 1, "the close friend perk is new")


func test_the_perk_flag_names_the_band_with_an_underscore() -> void:
	var gs := _gs()
	Standing.perk_news(gs, _db)
	_regard(gs, "lism", 7)
	var lines := Standing.perk_news(gs, _db)
	assert_eq(lines.size(), 1)
	assert_true(gs.flags.get("perk.lism.friend", false))
	_regard(gs, "lism", 12)
	Standing.perk_news(gs, _db)
	assert_true(gs.flags.get("perk.lism.close_friend", false))


func test_bad_perks_are_reported() -> void:
	var db := DataDb.load_dir()
	db.rules["standing"]["perks"] = [
		{"npc": "nobody_here", "band": "friend", "kind": "talk_xp", "value": 1.2, "text": "x"},
		{"npc": "krshia", "band": "best pal", "kind": "talk_xp", "value": 1.2, "text": "x"},
		{"npc": "krshia", "band": "friend", "kind": "magic", "text": "x"},
		{"npc": "krshia", "band": "friend", "kind": "discount", "value": 0.9, "shops": ["krshia_stall"], "text": "x"},
		{"npc": "krshia", "band": "friend", "kind": "discount", "value": 0.1, "shops": ["no_shop"], "text": "x"},
		{"npc": "krshia", "band": "friend", "kind": "talk_xp", "value": 0.5, "text": "x"},
		{"npc": "krshia", "band": "friend", "kind": "fight_help", "value": 2, "text": "x"},
		{"npc": "krshia", "band": "friend", "kind": "fight_help", "text": ""},
		{"npc": "krshia", "band": "friend", "kind": "fight_help", "text": "again"},
		{"npc": "krshia", "band": "friend", "kind": "fight_help", "text": "twice", "colour": "red"},
	]
	var text := "\n".join(Standing.validate(db))
	for bit in ["unknown npc 'nobody_here'", "band 'best pal'", "kind must be one of", "value in 0..0.5",
			"unknown shop", "talk_xp needs a value", "takes no value", "text must be a non-empty",
			"a second 'fight_help'", "unknown field 'colour'"]:
		assert_true(text.contains(bit), "%s in %s" % [bit, text])


func test_a_db_without_perks_answers_as_before() -> void:
	var db := DataDb.load_dir()
	db.rules["standing"].erase("perks")
	var gs := GameState.new_game(SEED, db)
	assert_eq(Standing.validate(db), [] as Array[String])
	assert_eq(Standing.perk_discount(gs, db, "krshia_stall"), 0.0)
	assert_eq(Standing.talk_xp_mult(gs, db, {"npc": "erin_solstice"}), 1.0)
	assert_eq(Standing.perk_news(gs, db), [] as Array[String])
