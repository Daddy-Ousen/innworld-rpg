extends GutTest
## M18.1 (ADR 0028) on the real data: the Book 6 world. Wirclaw's village west
## of the inn hill; the inn basement under a trapdoor that opens with the
## Antinium build; inside the Ruins of Liscor the hall with the illusion
## doorway, the one-way chute to the ossuary and its corridor down to the
## crypt level; the Eater Goat; the new looks and NPC records.

const SEED := 20261001
const BUILD := "wandering_inn.expansion_begun"
const LOOTED := "ruins.vault_found_looted"
const FOUND := "liscor_ruins.hidden_chute_found"
const NEW_MAPS := ["wirclaw_village", "inn_basement", "liscor_ruins_hall", "liscor_ruins_ossuary"]

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])


func _at(area: String, pos: Vector2i, flags: Array = []) -> GameState:
	var gs := GameState.new_game(SEED, _db)
	for f: String in flags:
		gs.flags[f] = true
	gs.player.place(area, pos)
	Commands.settle(gs, _db)
	return gs


func test_wirclaws_village_is_a_walk_west_of_the_inn_hill() -> void:
	var gs := _at("inn_hill", Vector2i(1, 11))
	var before := gs.clock.total_minutes
	assert_true(FightBot.move(gs, _db, "w")["moved"])
	assert_eq(gs.player.area, "wirclaw_village")
	assert_eq(gs.player.pos(), Vector2i(30, 11))
	assert_eq(gs.clock.total_minutes - before, 30, "a 30-minute walk")
	FightBot.move(gs, _db, "e")
	assert_eq(gs.player.area, "inn_hill", "and back")
	assert_eq(gs.player.pos(), Vector2i(1, 11))


func test_the_trapdoor_opens_with_the_inn_build() -> void:
	var gs := _at("inn_interior", Vector2i(14, 10))
	assert_false(_db.maps.objects_on("inn_interior").any(
			func(o: Dictionary) -> bool: return o["id"] == "trapdoor"), "no trapdoor before the build")
	FightBot.move(gs, _db, "s")
	assert_eq(gs.player.area, "inn_interior", "plain floor before the build")
	gs = _at("inn_interior", Vector2i(14, 10), [BUILD])
	assert_true(_db.maps.objects_on("inn_interior").any(
			func(o: Dictionary) -> bool: return o["id"] == "trapdoor"))
	FightBot.move(gs, _db, "s")
	assert_eq(gs.player.area, "inn_basement")
	assert_eq(gs.player.pos(), Vector2i(3, 1))
	FightBot.move(gs, _db, "w")
	assert_eq(gs.player.area, "inn_interior", "up the ladder")
	assert_eq(gs.player.pos(), Vector2i(14, 10))


func test_the_ruins_doors_open_once_the_vault_was_found_looted() -> void:
	var gs := _at("ruins_entrance", Vector2i(16, 4))
	FightBot.move(gs, _db, "n")
	assert_eq(gs.player.area, "ruins_entrance", "shut before 2.02")
	gs = _at("ruins_entrance", Vector2i(16, 4), [LOOTED])
	FightBot.move(gs, _db, "n")
	assert_eq(gs.player.area, "liscor_ruins_hall")
	assert_eq(gs.player.pos(), Vector2i(15, 16))
	FightBot.move(gs, _db, "s")
	assert_eq(gs.player.area, "ruins_entrance", "out through the doors")


func test_the_illusion_wall_hides_the_chute_until_it_is_found() -> void:
	var gs := _at("liscor_ruins_hall", Vector2i(20, 7), [LOOTED])
	assert_false(FightBot.move(gs, _db, "e")["moved"], "solid stone to everyone without the ring")
	gs = _at("liscor_ruins_hall", Vector2i(20, 7), [LOOTED, FOUND])
	for i in 4:
		assert_true(FightBot.move(gs, _db, "e")["moved"], "step %d" % i)
	assert_eq(gs.player.pos(), Vector2i(24, 7), "in the round room")
	var before := gs.clock.total_minutes
	FightBot.move(gs, _db, "e")
	assert_eq(gs.player.area, "liscor_ruins_ossuary", "the hexagon drops you down the chute")
	assert_eq(gs.player.pos(), Vector2i(8, 4))
	assert_eq(gs.clock.total_minutes - before, 1)
	for e: Dictionary in _db.maps.areas["liscor_ruins_ossuary"]["exits"]:
		assert_ne(e["to"], "liscor_ruins_hall", "the chute is one way")


func test_the_ossuary_corridor_leads_down_to_the_crypt_level() -> void:
	var gs := _at("liscor_ruins_ossuary", Vector2i(27, 21), [FOUND])
	FightBot.move(gs, _db, "s")
	assert_eq(gs.player.area, "liscor_crypt")
	assert_eq(gs.player.pos(), Vector2i(15, 19))
	gs = _at("liscor_crypt", Vector2i(14, 19))
	FightBot.move(gs, _db, "s")
	assert_eq(gs.player.area, "liscor_crypt", "no way up before the chute is found")
	gs = _at("liscor_crypt", Vector2i(14, 19), [FOUND])
	FightBot.move(gs, _db, "s")
	assert_eq(gs.player.area, "liscor_ruins_ossuary")
	assert_eq(gs.player.pos(), Vector2i(27, 21))


func test_the_corridor_has_a_trap() -> void:
	var gs := _at("liscor_ruins_ossuary", Vector2i(28, 13), [FOUND])
	var r := FightBot.move(gs, _db, "s")
	assert_eq(r["sprung"].get("id", ""), "corridor_tile")
	assert_true(Combat.hp(gs, _db) < Stats.max_hp(gs, _db))


func test_a_knock_out_on_the_new_maps_wakes_you_nearby() -> void:
	var wake := {"wirclaw_village": ["inn_interior", Vector2i(20, 13), Vector2i(3, 2)],
		"inn_basement": ["inn_interior", Vector2i(20, 13), Vector2i(3, 2)],
		"liscor_ruins_hall": ["liscor_gate", Vector2i(3, 12), Vector2i(15, 15)],
		"liscor_ruins_ossuary": ["liscor_gate", Vector2i(3, 12), Vector2i(5, 4)]}
	var audio: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/audio.json"))
	for area: String in NEW_MAPS:
		assert_true(audio["moods"]["by_map"].has(area), "%s has a mood" % area)
		var gs := _at(area, wake[area][2], [BUILD, LOOTED, FOUND])
		Combat.night(gs, _db, false, true)
		assert_eq(gs.player.area, wake[area][0], area)
		assert_eq(gs.player.pos(), wake[area][1], area)


func test_the_eater_goat_leaps_and_fears_nothing() -> void:
	var goat: Dictionary = _db.combat.enemies["eater_goat"]
	assert_eq(goat["abilities"][0]["kind"], "leap")
	assert_eq(float(goat["flee_below"]), 0.0)
	assert_eq(goat["scared_by"], [])
	assert_true(CharacterSprite.has_sheet("eater_goat"), "drawn by tools/build_creatures.py")
	for s: Dictionary in _db.combat.spawns:
		assert_ne(s["enemy"], "eater_goat", "the 4.34 stage brings them (M18.3), not a spawn")


func test_book6_records_and_looks() -> void:
	var c := _db.canon
	for id: String in ["goblin_lord", "snapjaw", "eater_of_spears", "eggsnatcher", "wirclaw", "purple_smile",
			"falene_skystrall", "dawil", "the_fool", "erille"]:
		assert_true(c.npcs.has(id), id)
	assert_eq(c.npcs["wirclaw"]["home"], "wirclaw_village")
	assert_true(c.locations.has("wirclaw_village"))
	for id: String in c.events:
		assert_false(id.begins_with("b6."), "no Book 6 events yet (M18.2 on)")
	for id: String in ["headscratcher", "numbtongue", "badarrow", "shorthilt", "rabbiteater", "wirclaw",
			"falene_skystrall", "dawil", "purple_smile"]:
		assert_eq(CharacterSprite.look_for(id, String(c.npcs[id]["race"])), id, "own look for %s" % id)
	assert_eq(CharacterSprite.look_for("dasha", "Dwarf"), "race_dwarf", "Dwarves get a generic look")
