extends GutTest
## M36.2 on the real Book 9 data (5.45, 5.46, 5.47 G, days 164 - 167): the morning after the three-door battle,
## Ilvriss's victory parade, the Celum door in the meadow and Erin's baseball game, then Rags in the north: Pellmia's
## riders, Twofeather killed by Gilam, [Chieftain] 25, the burning forest and Gilam spared. Two scene stages with one
## talk hook each (user pick, 2026-11-01): the parade in the plaza and the baseball game north of Celum. No fight
## stage, no xp_window. One kill: Twofeather. Slept to day 163 once (before_all); each test starts from a copy.

const SEED := 20261101
const CHAPTERS := ["5.45", "5.46", "5.47G"]
const PARADE := "b9.ilvriss_leads_the_victory_parade_in_the_rain"
const PARADE_HOOK := "player_cheered_at_the_victory_parade"
const GAME := "b9.the_meadow_baseball_championship"
const GAME_HOOK := "player_played_baseball_in_the_meadow"
const TWOFEATHER := "b9.gilam_kills_twofeather_at_a_creek"

var _db: DataDb
var _base := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])
	assert_eq(_db.canon.errors, [] as Array[String])
	var gs := GameState.new_game(SEED, _db)
	ToyCanon.sleep_through(gs, _db, 163)
	_base = gs.to_json()


func _fresh() -> GameState:
	var gs := GameState.from_json(_base)
	assert_eq(gs.clock.day(), 164)
	return gs


func _batch_ids() -> Array[String]:
	var ids: Array[String] = []
	for id: String in _db.canon.events:
		var ref: Dictionary = _db.canon.events[id]["canon_ref"]
		if int(ref["book"]) == 9 and String(ref["chapter"]) in CHAPTERS and not _db.canon.alt_only.has(id):
			ids.append(id)
	return ids


func _has_all(gs: GameState, flags: Array) -> void:
	for f: String in flags:
		assert_true(gs.flags.has(f), f)


func _wait_for_stage(gs: GameState, id: String, area: String, spot: Vector2i) -> void:
	gs.player.place(area, spot)
	Commands.settle(gs, _db)
	for i in 120:
		if gs.world.staged.has(id):
			break
		assert_true(Commands.wait(gs, _db, 600) >= 0, "wait")
	assert_true(gs.world.staged.has(id), id + " is staged")


func _area_of(gs: GameState, id: String) -> String:
	var n: Dictionary = gs.npcs.npcs.get(id, {})
	return "" if n.is_empty() else String(n["area"])


func _talk_to(gs: GameState, id: String) -> void:
	var n: Dictionary = gs.npcs.npcs[id]
	var area := String(n["area"])
	var at := Vector2i(int(n["x"]), int(n["y"]))
	var taken := {}
	for other: String in gs.npcs.in_area(area):
		taken[NpcRoster.pos_of(gs.npcs.npcs[other])] = true
	var spot := Vector2i(-1, -1)
	for d: Vector2i in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
		if not taken.has(at + d) and _db.maps.is_walkable(area, at + d):
			spot = at + d
			break
	assert_ne(spot, Vector2i(-1, -1), "a free side of " + id)
	gs.player.place(area, spot)
	var r := Commands.interact(gs, _db, id, "talk_with_guest")
	assert_eq(r["error"], "")


func _hook_of(gs: GameState, id: String) -> String:
	var entry: Dictionary = gs.world.history.filter(func(h: Dictionary) -> bool: return h["event"] == id)[0]
	return str(entry.get("hook", ""))


func _system(chapter: String) -> Array:
	var f := FileAccess.open("res://data/canon/book9/chapters/%s.json" % chapter, FileAccess.READ)
	var doc: Dictionary = JSON.parse_string(f.get_as_text())
	return doc["system"]


func test_the_batch_has_two_scenes_two_hooks_and_one_kill() -> void:
	var ids := _batch_ids()
	assert_eq(ids.size(), 31)
	var stages: Array[String] = []
	var hooks: Array[String] = []
	var killed: Array[String] = []
	for id: String in ids:
		var ev: Dictionary = _db.canon.events[id]
		if ev.has("stage"):
			stages.append(id)
			assert_eq(ev["stage"]["kind"], "scene", id + " is a scene, not a fight")
		for h: Dictionary in ev.get("hooks", []):
			hooks.append(String(h["id"]))
		assert_false(ev.has("xp_window"), id)
		assert_eq(ev["window"]["confidence"], "guess", id)
		for n: String in ev["effects"].get("kill", []):
			killed.append(n)
		assert_true(int(ev["window"]["earliest"]) >= 164 and int(ev["window"]["latest"]) <= 167, id)
		for dep: String in ev["depends_on"]:
			assert_true(_db.canon.events.has(dep), dep)
	stages.sort()
	hooks.sort()
	assert_eq(stages, [PARADE, GAME] as Array[String])
	assert_eq(hooks, [PARADE_HOOK, GAME_HOOK] as Array[String])
	assert_eq(killed, ["twofeather"] as Array[String], "only Twofeather dies by name")
	assert_eq(_db.canon.events[TWOFEATHER]["window"]["earliest"], 166)
	assert_eq(_db.canon.events["b9.rags_spares_gilam"]["window"]["earliest"], 167)


func test_the_scene_data_is_sound() -> void:
	for id: String in [PARADE, GAME]:
		var ev: Dictionary = _db.canon.events[id]
		var st: Dictionary = ev["stage"]
		assert_true(_db.canon.foreshadows.has(id), id + " has a signpost")
		assert_eq(ev["hooks"].size(), 1, id)
		assert_eq(ev["hooks"][0]["then"], "change", id)
		assert_eq([int(ev["hooks"][0]["days"][0]), int(ev["hooks"][0]["days"][1])], [164, 164], id)
		assert_ne(String(ev["hooks"][0].get("news", "")), "", id)
		var seen := {}
		for n: Dictionary in st["npcs"]:
			assert_true(_db.behaviour.npcs.has(n["npc"]), n["npc"])
			var at := Vector2i(int(n["pos"][0]), int(n["pos"][1]))
			assert_true(_db.maps.is_walkable(String(st["area"]), at), "%s: %s stands on %s" % [id, n["npc"], at])
			assert_false(seen.has(at), id + " tile used twice " + str(at))
			seen[at] = true
	assert_eq(_db.canon.events[PARADE]["stage"]["area"], "liscor_plaza")
	assert_eq(_db.canon.events[GAME]["stage"]["area"], "celum_north_gate")
	assert_true(int(_db.canon.events[PARADE]["stage"]["hours"][1]) <= int(_db.canon.events[GAME]["stage"]["hours"][0]),
			"the parade ends before the game starts")


func test_staying_away_still_sets_the_day_164_canon() -> void:
	var gs := _fresh()
	ToyCanon.sleep_through(gs, _db, 164)
	_has_all(gs, ["liscor.army_home_from_the_raskghar_camp", "raskghar.other_camps_cleared_by_goblins",
			"drassi.spreads_the_victory_news", "mrsha.has_a_secret_skill", "lyonette.has_crimson_stinger",
			"liscor_gnolls.honour_mrsha_as_the_doombringer", "raskghar_loot.pooled_for_bids_and_a_lottery",
			"albez_door.celum_side_in_the_meadow", "liscor.raskghar_victory_parade_held", "mrsha.smiles_again",
			"erin.taught_baseball", "ceria.expects_calruz_to_be_executed", "cave_goblins.play_in_the_meadow",
			"players_of_celum.want_a_raskghar_play", "liscor.picnic_in_the_celum_meadow",
			"celum_meadow.baseball_championship_played"])
	assert_eq(gs.world.status(PARADE), Director.DONE)
	assert_eq(gs.world.status(GAME), Director.DONE)
	assert_false(gs.flags.has("liscor.earther_cheered_at_the_victory_parade"))
	assert_false(gs.flags.has("celum_meadow.earther_played_baseball"))
	assert_true(gs.flags.has("calruz.awaits_trial"), "no verdict for Calruz")
	assert_true(gs.flags.has("calruz.in_watch_prison"))


func test_talking_at_the_parade_changes_it() -> void:
	var gs := _fresh()
	_wait_for_stage(gs, PARADE, "liscor_plaza", Vector2i(15, 12))
	for id: String in ["ilvriss", "zevara", "embria_grasstongue", "relc"]:
		assert_eq(_area_of(gs, id), "liscor_plaza", id)
	_talk_to(gs, "zevara")
	ToyCanon.sleep_through(gs, _db, 164)
	assert_eq(gs.world.status(PARADE), Director.CHANGED)
	assert_eq(_hook_of(gs, PARADE), PARADE_HOOK)
	assert_true(gs.flags.has("liscor.earther_cheered_at_the_victory_parade"))
	assert_true(gs.flags.has("liscor.raskghar_victory_parade_held"), "the canon still happens")


func test_playing_baseball_changes_the_game() -> void:
	var gs := _fresh()
	_wait_for_stage(gs, GAME, "celum_north_gate", Vector2i(16, 10))
	for id: String in ["erin_solstice", "mrsha", "ceria_springwalker", "headscratcher", "relc"]:
		assert_eq(_area_of(gs, id), "celum_north_gate", id)
	var before := gs.world.relationship("erin_solstice", "player")
	_talk_to(gs, "erin_solstice")
	ToyCanon.sleep_through(gs, _db, 164)
	assert_eq(gs.world.status(GAME), Director.CHANGED)
	assert_eq(_hook_of(gs, GAME), GAME_HOOK)
	assert_true(gs.flags.has("celum_meadow.earther_played_baseball"))
	assert_true(gs.flags.has("celum_meadow.baseball_championship_played"), "the canon still happens")
	assert_gt(gs.world.relationship("erin_solstice", "player"), before)


func test_days_166_and_167_twofeather_dies_and_gilam_is_spared() -> void:
	var gs := _fresh()
	ToyCanon.sleep_through(gs, _db, 165)
	assert_true(gs.world.is_alive(_db.canon, "twofeather"), "alive before Day 3")
	ToyCanon.sleep_through(gs, _db, 166)
	assert_false(gs.world.is_alive(_db.canon, "twofeather"))
	_has_all(gs, ["rags.dreamed_of_velan", "flooded_waters.herded_south_by_pellmia", "gilam.broke_tyrions_order",
			"pyrite.named_twofeather", "rags.chieftain_level_25"])
	assert_false(gs.flags.has("rags.spared_gilam"))
	ToyCanon.sleep_through(gs, _db, 167)
	_has_all(gs, ["flooded_waters.rallied_by_rags", "flooded_waters.burned_a_forest_to_trap_the_riders",
			"quietstab.took_gilams_white_mare", "rags.spared_gilam", "pellmia.doubts_his_duty",
			"flooded_waters.has_a_bag_of_holding"])
	for id: String in ["rags", "pyrite", "redscar", "quietstab", "poisonbite", "noears", "gilam", "lord_pellmia", "kilmet",
			"erin_solstice", "mrsha", "calruz", "ceria_springwalker"]:
		assert_true(gs.world.is_alive(_db.canon, id), id)


func test_the_rains_and_the_boycott_do_not_change_yet() -> void:
	var gs := _fresh()
	var before := {}
	for f: String in ["izril.rains", "izril.flood", "wandering_inn.drake_boycott"]:
		before[f] = gs.flags.has(f)
	ToyCanon.sleep_through(gs, _db, 167)
	for f: String in before:
		assert_eq(gs.flags.has(f), before[f], f + " is not touched by this batch")


func test_level_records() -> void:
	var seen := {}
	for ch: String in CHAPTERS:
		for s: Dictionary in _system(ch):
			assert_ne(s["who"], "ryoka_griffin", "Ryoka never levels")
			seen["%s %s" % [s["who"], s["name"]]] = s["level"]
	assert_eq(int(seen.get("rags [Chieftain]", -1)), 25)
	assert_true(seen.has("lyonette [Crimson Stinger]"))
	assert_true(seen.has("wesle [Method Acting]"))
