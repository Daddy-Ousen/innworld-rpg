extends GutTest
## M30.4 (ADR 0044): the Earther meeting with real data. Telling Erin you are from Earth
## works once, shows a text page with her face, sets erin.knows_player_is_earther, raises
## her regard and opens her Earth lines. It is player life, not canon: the canon days after
## it run exactly as without it (drift 0, same history).

const ERIN := "erin_solstice"
const FLAG := "erin.knows_player_is_earther"

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()


## Day 8, 10:00, the player in the inn next to `npc`.
func _game(npc: String = ERIN) -> GameState:
	var gs := GameState.new_game(20261019, _db)
	gs.clock.total_minutes = 1440 * 7 + 10 * 60
	gs.player.place("inn_interior", Vector2i(5, 5))
	gs.npcs.npcs[npc]["area"] = "inn_interior"
	gs.npcs.npcs[npc]["x"] = 6
	gs.npcs.npcs[npc]["y"] = 5
	return gs


## The NPC's own options open now (a command moves NPCs on, so not through Interact).
func _voice_ids(gs: GameState, npc: String) -> Array:
	return Voice.options(gs, _db, npc).map(func(v: Dictionary) -> String: return v["id"])


func test_tell_erin_once() -> void:
	var gs := _game()
	var row: Dictionary = Interact.options(gs, _db).filter(func(o: Dictionary) -> bool:
		return o["id"] == ERIN)[0]
	assert_true((row["voice"] as Array).any(func(v: Dictionary) -> bool: return v["id"] == "earth"),
			"a stranger can tell her on day 8")
	var regard := Standing.regard(gs, _db, ERIN)
	var r := Commands.interact(gs, _db, ERIN, Interact.VOICE + "earth")
	assert_eq(r["error"], "")
	assert_eq(r["page"]["title"], "From Earth")
	var lines: Array = r["page"]["lines"]
	assert_true(lines.size() >= 4 and lines.size() <= 6, str(lines))
	assert_true(gs.flags.get(FLAG, false))
	assert_gte(Standing.regard(gs, _db, ERIN) - regard, 3, "+3 and the talk")
	assert_false(_voice_ids(gs, ERIN).has("earth"), "only once")
	assert_true(_voice_ids(gs, ERIN).has("work"), "her work offer stays open")
	var p := SystemMessages.talk_page(ERIN, r["page"])
	assert_eq(p["kind"], SystemMessages.TALK)
	assert_eq(SystemMessages.portrait_npc(p), ERIN, "the page shows Erin's face")


func test_erin_talks_of_earth_after() -> void:
	var gs := _game()
	var earth := func(t: String) -> bool: return t.contains("pizza") or t.contains("songs") \
			or t.contains("video games") or t.contains("Earth thing")
	assert_false(Voice.lines_now(gs, _db, ERIN).any(earth), "no Earth talk before")
	Commands.interact(gs, _db, ERIN, Interact.VOICE + "earth")
	assert_eq(Voice.lines_now(gs, _db, ERIN).filter(earth).size(), 4)


func test_flag_survives_a_save() -> void:
	var gs := _game()
	Commands.interact(gs, _db, ERIN, Interact.VOICE + "earth")
	var loaded := GameState.from_json(gs.to_json())
	assert_true(loaded.flags.get(FLAG, false))


func test_ryoka_reacts_once() -> void:
	var gs := _game("ryoka_griffin")
	var r := Commands.interact(gs, _db, "ryoka_griffin", Interact.VOICE + "earth")
	assert_eq(r["error"], "")
	assert_true(gs.flags.get("ryoka.knows_player_is_earther", false))
	assert_false(gs.flags.get(FLAG, false), "Erin does not know from Ryoka's talk")
	assert_false(_voice_ids(gs, "ryoka_griffin").has("earth"))


func test_canon_runs_the_same_after_the_talk() -> void:
	var told := _game()
	var plain := _game()
	Commands.interact(told, _db, ERIN, Interact.VOICE + "earth")
	Commands.interact(plain, _db, ERIN, "talk_with_guest")
	for gs: GameState in [told, plain]:
		gs.player.place("liscor_gate", Vector2i(3, 12))  # where sim_canon_book1 sleeps
		var nights := 0
		while gs.world.last_day < 12 and nights < 12:
			var night := Commands.sleep(gs, _db, Rest.ANYWHERE)
			assert_false(night.is_empty(), "sleep refused: %s" % str(gs.combat.lines.slice(-1)))
			if night.is_empty():
				return
			nights += 1
	assert_eq(told.world.drift, 0.0)
	assert_eq(plain.world.drift, 0.0)
	assert_eq(told.world.history, plain.world.history, "the same canon history")
	assert_eq(told.rng.to_dict(), plain.rng.to_dict(), "the same RNG stream")
