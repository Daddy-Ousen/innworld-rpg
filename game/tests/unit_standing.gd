extends GutTest
## Relationships and reputation (M14.3, ADR 0021): rules.standing, towns and factions,
## talk and serve gains, night step 7 decay, greeting bands, friends in fights, shop
## prices, the inn's guest curve, and the v16 save. Real data.

const SEED := 20260929
const MARKET := "liscor_market"

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])


func _game(area: String = MARKET, pos: Vector2i = Vector2i(5, 5)) -> GameState:
	var gs := GameState.new_game(SEED, _db)
	gs.player.place(area, pos)
	return gs


## Some canon NPC on the roster with a faction: [id, faction].
func _faction_npc(gs: GameState) -> Array:
	var ids: Array = gs.npcs.npcs.keys()
	ids.sort()
	for id: String in ids:
		var f: Variant = _db.canon.npcs.get(id, {}).get("faction", null)
		if f != null:
			return [id, String(f)]
	return []


func _set_day(gs: GameState, day: int) -> void:
	gs.clock.total_minutes = (day - 1) * 1440 + 8 * 60


func test_town_is_the_nearest_settlement() -> void:
	assert_eq(Standing.town_of(_db, "liscor_market"), "liscor")
	assert_eq(Standing.town_of(_db, "liscor_gate"), "liscor")
	assert_eq(Standing.town_of(_db, "celum_square"), "celum")
	assert_eq(Standing.town_of(_db, "celum_frenzied_hare"), "celum")
	assert_eq(Standing.town_of(_db, "esthelm_ruins"), "esthelm")
	assert_eq(Standing.town_of(_db, "inn_interior"), "", "the inn is in the Floodplains, no town")
	assert_eq(Standing.town_of(_db, "nowhere"), "")


func test_reputation_is_capped_and_zero_is_removed() -> void:
	var gs := _game()
	Standing.add_reputation(gs, _db, "liscor", 500)
	assert_eq(Standing.reputation(gs, "liscor"), 100)
	Standing.add_reputation(gs, _db, "liscor", -500)
	assert_eq(Standing.reputation(gs, "liscor"), -100)
	Standing.add_reputation(gs, _db, "liscor", 100)
	assert_false(gs.world.reputation.has("liscor"))
	Standing.add_reputation(gs, _db, "", 5)
	assert_true(gs.world.reputation.is_empty())


func test_a_db_without_standing_changes_nothing() -> void:
	var toy := DataDb.from_dicts({}, {}, {}, {}, {})
	var gs := GameState.new()
	assert_false(Standing.on(toy))
	Standing.add_reputation(gs, toy, "liscor", 5)
	assert_true(gs.world.reputation.is_empty())
	assert_eq(Standing.price_shift(gs, toy), 0.0)
	assert_eq(Standing.guest_bonus(gs, toy), 0)
	assert_eq(Standing.band(gs, toy, "x"), {"label": "", "line": ""})
	assert_false(Standing.is_friend(gs, toy, "x"))
	Standing.night(gs, toy)


func test_talking_gives_contact_town_and_faction_reputation() -> void:
	var gs := _game()
	var pick := _faction_npc(gs)
	assert_eq(pick.size(), 2, "a roster NPC with a faction")
	var id: String = pick[0]
	assert_true(NpcSim.note_talk(gs, _db, id))
	assert_eq(gs.world.contact[id], gs.clock.day())
	assert_eq(Standing.reputation(gs, "liscor"), 1, "the town of the map")
	assert_eq(Standing.reputation(gs, pick[1]), 1, "the NPC's faction")
	assert_false(NpcSim.note_talk(gs, _db, id), "once a day")
	assert_eq(Standing.reputation(gs, "liscor"), 1)


func test_serving_a_patron_raises_the_inn_town() -> void:
	var gs := _game("inn_interior", Vector2i(12, 11))
	Standing.on_serve(gs, _db)
	assert_eq(Standing.reputation(gs, "liscor"), 1)


func test_a_quiet_relationship_fades_toward_zero() -> void:
	var gs := _game()
	gs.world.add_relationship("krshia", NpcSim.PLAYER, 5)
	gs.world.contact["krshia"] = 1
	_set_day(gs, 20)
	Standing.night(gs, _db)
	assert_eq(gs.world.relationship("krshia", NpcSim.PLAYER), 4)
	Standing.night(gs, _db)
	Standing.night(gs, _db)
	assert_eq(gs.world.relationship("krshia", NpcSim.PLAYER), 2)
	gs.world.add_relationship("krshia", NpcSim.PLAYER, -10)
	Standing.night(gs, _db)
	assert_eq(gs.world.relationship("krshia", NpcSim.PLAYER), -7, "a grudge fades toward 0 too")


func test_a_recent_contact_keeps_the_relationship() -> void:
	var gs := _game()
	gs.world.add_relationship("krshia", NpcSim.PLAYER, 5)
	_set_day(gs, 20)
	gs.world.contact["krshia"] = 14
	Standing.night(gs, _db)
	assert_eq(gs.world.relationship("krshia", NpcSim.PLAYER), 5, "6 days: still within 7")
	gs.world.contact["krshia"] = 12
	Standing.night(gs, _db)
	assert_eq(gs.world.relationship("krshia", NpcSim.PLAYER), 4, "8 days: fading")


func test_no_contact_record_starts_the_clock_and_never_passes_zero() -> void:
	var gs := _game()
	gs.world.add_relationship("krshia", NpcSim.PLAYER, 1)
	_set_day(gs, 30)
	Standing.night(gs, _db)
	assert_eq(gs.world.relationship("krshia", NpcSim.PLAYER), 1)
	assert_eq(gs.world.contact["krshia"], 30)
	gs.world.contact["krshia"] = 1
	Standing.night(gs, _db)
	assert_eq(gs.world.relationship("krshia", NpcSim.PLAYER), 0)
	Standing.night(gs, _db)
	assert_eq(gs.world.relationship("krshia", NpcSim.PLAYER), 0)


func test_other_relationships_do_not_fade() -> void:
	var gs := _game()
	gs.world.add_relationship("krshia", "lism", 5)
	_set_day(gs, 30)
	Standing.night(gs, _db)
	assert_eq(gs.world.relationship("krshia", "lism"), 5)


func test_reputation_fades_every_third_day() -> void:
	var gs := _game()
	Standing.add_reputation(gs, _db, "liscor", 5)
	Standing.add_reputation(gs, _db, "celum", -2)
	_set_day(gs, 10)
	Standing.night(gs, _db)
	assert_eq(Standing.reputation(gs, "liscor"), 5, "day 10: no fade")
	_set_day(gs, 9)
	Standing.night(gs, _db)
	assert_eq(Standing.reputation(gs, "liscor"), 4)
	assert_eq(Standing.reputation(gs, "celum"), -1)
	_set_day(gs, 12)
	Standing.night(gs, _db)
	assert_false(gs.world.reputation.has("celum"), "faded to 0: removed")


func test_night_runs_the_decay() -> void:
	var gs := _game()
	gs.world.add_relationship("krshia", NpcSim.PLAYER, 5)
	gs.world.contact["krshia"] = -20
	Night.run(gs, _db)
	assert_eq(gs.world.relationship("krshia", NpcSim.PLAYER), 4)


func test_bands_follow_regard() -> void:
	var gs := _game()
	assert_eq(Standing.band(gs, _db, "krshia")["label"], "", "a stranger")
	gs.world.add_relationship("krshia", NpcSim.PLAYER, 3)
	assert_eq(Standing.band(gs, _db, "krshia")["label"], "acquaintance")
	gs.world.add_relationship("krshia", NpcSim.PLAYER, 3)
	assert_eq(Standing.band(gs, _db, "krshia")["label"], "friend")
	gs.world.add_relationship("krshia", NpcSim.PLAYER, 4)
	assert_eq(Standing.band(gs, _db, "krshia")["label"], "close friend")
	gs.world.add_relationship("lism", NpcSim.PLAYER, -3)
	assert_eq(Standing.band(gs, _db, "lism")["label"], "wary")
	gs.world.add_relationship("lism", NpcSim.PLAYER, -20)
	assert_eq(Standing.band(gs, _db, "lism")["label"], "hostile")


func test_faction_reputation_adds_to_regard() -> void:
	var gs := _game()
	var pick := _faction_npc(gs)
	Standing.add_reputation(gs, _db, pick[1], 30)
	assert_eq(Standing.regard(gs, _db, pick[0]), 3)
	Standing.add_reputation(gs, _db, pick[1], -60)
	assert_eq(Standing.regard(gs, _db, pick[0]), -3, "rounded toward 0")


func test_friends_fight_beside_the_player() -> void:
	var gs := _game()
	assert_false(NpcReact.is_fighter(gs, _db, "krshia"))
	gs.world.add_relationship("krshia", NpcSim.PLAYER, 9)
	assert_false(Standing.is_friend(gs, _db, "krshia"))
	assert_false(NpcReact.is_fighter(gs, _db, "krshia"))
	gs.world.add_relationship("krshia", NpcSim.PLAYER, 1)
	assert_true(Standing.is_friend(gs, _db, "krshia"))
	assert_true(NpcReact.is_fighter(gs, _db, "krshia"))


func test_shop_prices_follow_the_town() -> void:
	var gs := _game()
	var base := int(_db.economy.goods["healing_potion"]["buy"])
	var sell := int(_db.economy.goods["healing_potion"]["sell"])
	assert_gt(base, 10, "a good with a price that shows the shift")
	assert_eq(Economy.price(gs, _db, "krshia_stall", "healing_potion", Economy.BUY), base)
	Standing.add_reputation(gs, _db, "liscor", 25)
	assert_almost_eq(Standing.price_shift(gs, _db), 0.1, 0.0001)
	assert_eq(Economy.price(gs, _db, "krshia_stall", "healing_potion", Economy.BUY),
			roundi(base * 0.9))
	assert_eq(Economy.price(gs, _db, "krshia_stall", "healing_potion", Economy.SELL), sell, "0 stays 0")
	Standing.add_reputation(gs, _db, "liscor", 75)
	assert_almost_eq(Standing.price_shift(gs, _db), 0.2, 0.0001, "capped at price_max")
	Standing.add_reputation(gs, _db, "liscor", -300)
	assert_eq(Economy.price(gs, _db, "krshia_stall", "healing_potion", Economy.BUY),
			roundi(base * 1.2), "a bad name costs more")
	assert_true(Economy.price(gs, _db, "krshia_stall", "meat", Economy.BUY) >= 1)


func test_a_town_with_no_reputation_or_an_area_with_no_town_keeps_prices() -> void:
	var gs := _game("inn_interior", Vector2i(12, 11))
	Standing.add_reputation(gs, _db, "liscor", 50)
	assert_eq(Standing.price_shift(gs, _db), 0.0)
	gs.player.place("celum_square", Vector2i(5, 5))
	assert_eq(Standing.price_shift(gs, _db), 0.0, "Celum has none")


func test_the_inn_town_adds_guests() -> void:
	var gs := _game("inn_interior", Vector2i(12, 11))
	assert_eq(Standing.guest_bonus(gs, _db), 0)
	Standing.add_reputation(gs, _db, "liscor", 40)
	assert_eq(Standing.guest_bonus(gs, _db), 10)


func test_the_sheet_lists_standing() -> void:
	var gs := _game()
	assert_false(CharacterSheet.lines(gs, _db).has("Standing:"))
	Standing.add_reputation(gs, _db, "liscor", 4)
	var lines := CharacterSheet.lines(gs, _db)
	assert_true(lines.has("Standing:"))
	assert_true(lines.has("Liscor: +4."), str(lines))


func test_the_talk_menu_shows_the_band_and_a_greeting() -> void:
	var gs := _game()
	var id := "krshia"
	gs.npcs.npcs[id]["area"] = MARKET
	gs.npcs.npcs[id]["x"] = 6
	gs.npcs.npcs[id]["y"] = 5
	gs.world.add_relationship(id, NpcSim.PLAYER, 5)
	var opts := Interact.options(gs, _db)
	var o: Dictionary = {}
	for x in opts:
		if x["id"] == id:
			o = x
	assert_eq(o.get("standing", "?"), "acquaintance")
	var r := Interact.perform(gs, _db, id, "talk_with_guest")
	assert_eq(r["error"], "")
	assert_true(gs.combat.lines.any(func(l: String) -> bool: return l.contains("greets you warmly")),
			str(gs.combat.lines))


func test_standing_is_saved_and_a_v15_save_loads() -> void:
	var gs := _game()
	Standing.add_reputation(gs, _db, "liscor", 7)
	gs.world.contact["krshia"] = 4
	var back := GameState.from_json(gs.to_json())
	assert_eq(back.world.reputation, {"liscor": 7})
	assert_eq(back.world.contact, {"krshia": 4})
	var data := gs.to_dict()
	(data["world"] as Dictionary).erase("reputation")
	(data["world"] as Dictionary).erase("contact")
	data["save_version"] = 15
	var old := GameState.from_dict(SaveMigrations.migrate(data))
	assert_eq(old.save_version, GameState.SAVE_VERSION)
	assert_eq(old.world.reputation, {})
	assert_eq(old.world.contact, {})


func test_rules_are_checked() -> void:
	var bad := DataDb.load_dir()
	bad.rules["standing"] = (bad.rules["standing"] as Dictionary).duplicate(true)
	(bad.rules["standing"] as Dictionary).erase("cap")
	assert_true(Standing.validate(bad).any(func(e: String) -> bool: return e.contains("'cap'")))
	bad.rules["standing"] = (_db.rules["standing"] as Dictionary).duplicate(true)
	bad.rules["standing"]["bands"] = [[3, "a", ""], [1, "b", ""]]
	assert_gt(Standing.validate(bad).size(), 0)
	bad.rules["standing"]["bands"] = (_db.rules["standing"] as Dictionary)["bands"]
	bad.rules["standing"]["inn_town"] = "nowhere"
	assert_gt(Standing.validate(bad).size(), 0)
