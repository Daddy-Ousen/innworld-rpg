extends GutTest
## M36.3 on the real Book 9 data (5.48 G, 5.49, 5.50 G, Interlude – Bird, days 168 - 171): the Goblin horde driven
## south by Tyrion, Tremborag on Pyrite's pikes, Garen's key, the sit-about and Reiss's dream, Quietstab killed by
## Tremborag; in Liscor Ilvriss pays Erin but not the Redfangs, Calruz's axe goes to Headscratcher, the Hobs share
## out the Raskghar hoard, Rabbiteater becomes a [Champion], the Drake boycott ends (guess), and Bevussa tells Bird
## about birds. Two scene stages with one talk hook each (user pick, 2026-11-01): the hoard upstairs (day 169) and
## the bird stories (day 170). No fight stage, no xp_window. One kill: Quietstab. Slept to day 168 once (before_all).

const SEED := 20261101
const CHAPTERS := ["5.48G", "5.49", "5.50G", "interlude_bird"]
const HOARD := "b9.the_hobs_share_out_the_raskghar_hoard"
const HOARD_HOOK := "player_saw_the_raskghar_hoard_shared"
const BIRD := "b9.bevussa_tells_bird_about_birds"
const BIRD_HOOK := "player_heard_bevussas_bird_stories"
const QUIETSTAB := "b9.tremborag_kills_quietstab_at_the_latrines"

var _db: DataDb
var _base := ""


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])
	assert_eq(_db.canon.errors, [] as Array[String])
	var gs := GameState.new_game(SEED, _db)
	ToyCanon.sleep_through(gs, _db, 168)
	_base = gs.to_json()


func _fresh() -> GameState:
	var gs := GameState.from_json(_base)
	assert_eq(gs.clock.day(), 169)
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
	for i in 160:
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
		assert_true(int(ev["window"]["earliest"]) >= 168 and int(ev["window"]["latest"]) <= 171, id)
		for dep: String in ev["depends_on"]:
			assert_true(_db.canon.events.has(dep), dep)
	stages.sort()
	hooks.sort()
	assert_eq(stages, [BIRD, HOARD] as Array[String])
	assert_eq(hooks, [BIRD_HOOK, HOARD_HOOK] as Array[String])
	assert_eq(killed, ["quietstab"] as Array[String], "only Quietstab dies by name")
	assert_eq(_db.canon.events[QUIETSTAB]["window"]["earliest"], 171)
	assert_eq(_db.canon.events[HOARD]["window"]["earliest"], 169, "5.49 is day 169 (user pick)")
	assert_eq(_db.canon.events[BIRD]["window"]["earliest"], 170, "the Bird interlude is day 170 (user pick)")


func test_the_scene_data_is_sound() -> void:
	for id: String in [HOARD, BIRD]:
		var ev: Dictionary = _db.canon.events[id]
		var st: Dictionary = ev["stage"]
		var day := int(ev["window"]["earliest"])
		assert_true(_db.canon.foreshadows.has(id), id + " has a signpost")
		assert_eq(ev["hooks"].size(), 1, id)
		assert_eq(ev["hooks"][0]["then"], "change", id)
		assert_eq([int(ev["hooks"][0]["days"][0]), int(ev["hooks"][0]["days"][1])], [day, day], id)
		assert_ne(String(ev["hooks"][0].get("news", "")), "", id)
		var seen := {}
		for n: Dictionary in st["npcs"]:
			assert_true(_db.behaviour.npcs.has(n["npc"]), n["npc"])
			var at := Vector2i(int(n["pos"][0]), int(n["pos"][1]))
			assert_true(_db.maps.is_walkable(String(st["area"]), at), "%s: %s stands on %s" % [id, n["npc"], at])
			assert_false(seen.has(at), id + " tile used twice " + str(at))
			seen[at] = true
	assert_eq(_db.canon.events[HOARD]["stage"]["area"], "inn_upper_floor")
	assert_eq(_db.canon.events[BIRD]["stage"]["area"], "inn_interior")


func test_staying_away_still_sets_the_canon_to_day_171() -> void:
	var gs := _fresh()
	assert_true(gs.flags.has("wandering_inn.drake_boycott"), "the boycott is on before 5.49")
	ToyCanon.sleep_through(gs, _db, 171)
	_has_all(gs, ["rags.runs_at_the_head_of_the_tribe", "goblin_horde.driven_south_by_tyrion",
			"tremborag.stopped_by_pyrites_pikes", "redscar.chose_rags", "velan_keys.garen_holds_one",
			"olesm.sent_the_raskghar_report", "redfang.denied_the_gnoll_rescue_bounty",
			"calruz_axe.given_to_erin_for_the_goblins", "headscratcher.carries_calruzs_axe",
			"raskghar_hoard.given_to_three_teams", "horns_of_hammerad.done_with_the_dungeon",
			"rabbiteater.is_a_champion", "redfang.bronze_team_certified", "wandering_inn.drakes_eat_there_again",
			"goblin_chieftains.held_a_sit_about", "tremborag.swore_to_kill_reiss_and_rags",
			"pyrite.known_as_greydaths_companion", "osthia.captive_of_reiss", "redfangs.chose_rags_over_garen",
			"flooded_waters.lost_quietstab", "reiss.allied_with_rags", "bird.has_bevussas_feather",
			"relc.flirted_with_bevussa", "bird.sleeps_on_bevussas_feather"])
	assert_false(gs.flags.has("wandering_inn.drake_boycott"), "the boycott is over (guess)")
	assert_eq(gs.world.status(HOARD), Director.DONE)
	assert_eq(gs.world.status(BIRD), Director.DONE)
	assert_false(gs.flags.has("wandering_inn.earther_saw_the_hoard_shared"))
	assert_false(gs.flags.has("wandering_inn.earther_heard_the_bird_stories"))
	assert_true(gs.flags.has("calruz.awaits_trial"), "no verdict for Calruz")
	assert_true(gs.world.is_alive(_db.canon, "osthia_blackwing"), "Osthia is a prisoner, not dead")


func test_standing_with_the_teams_changes_the_hoard() -> void:
	var gs := _fresh()
	_wait_for_stage(gs, HOARD, "inn_upper_floor", Vector2i(16, 5))
	for id: String in ["erin_solstice", "headscratcher", "ceria_springwalker", "jelaqua", "halrac"]:
		assert_eq(_area_of(gs, id), "inn_upper_floor", id)
	var before := gs.world.relationship("headscratcher", "player")
	_talk_to(gs, "headscratcher")
	ToyCanon.sleep_through(gs, _db, 169)
	assert_eq(gs.world.status(HOARD), Director.CHANGED)
	assert_eq(_hook_of(gs, HOARD), HOARD_HOOK)
	assert_true(gs.flags.has("wandering_inn.earther_saw_the_hoard_shared"))
	assert_true(gs.flags.has("raskghar_hoard.given_to_three_teams"), "the canon still happens")
	assert_gt(gs.world.relationship("headscratcher", "player"), before)


func test_sitting_with_bird_changes_the_stories() -> void:
	var gs := _fresh()
	ToyCanon.sleep_through(gs, _db, 169)
	_wait_for_stage(gs, BIRD, "inn_interior", Vector2i(4, 4))
	for id: String in ["bird", "erin_solstice", "relc"]:
		assert_eq(_area_of(gs, id), "inn_interior", id)
	var before := gs.world.relationship("bird", "player")
	_talk_to(gs, "bird")
	ToyCanon.sleep_through(gs, _db, 170)
	assert_eq(gs.world.status(BIRD), Director.CHANGED)
	assert_eq(_hook_of(gs, BIRD), BIRD_HOOK)
	assert_true(gs.flags.has("wandering_inn.earther_heard_the_bird_stories"))
	assert_true(gs.flags.has("bird.has_bevussas_feather"), "the canon still happens")
	assert_gt(gs.world.relationship("bird", "player"), before)


func test_quietstab_dies_on_day_171_and_the_book_9_dead_stay_dead() -> void:
	var gs := _fresh()
	assert_false(gs.world.is_alive(_db.canon, "twofeather"), "Twofeather died on day 166 (M36.2)")
	ToyCanon.sleep_through(gs, _db, 170)
	assert_true(gs.world.is_alive(_db.canon, "quietstab"), "alive before Day 8")
	assert_true(gs.world.is_alive(_db.canon, "tremborag"))
	ToyCanon.sleep_through(gs, _db, 171)
	assert_false(gs.world.is_alive(_db.canon, "quietstab"))
	assert_true(gs.world.is_alive(_db.canon, "tremborag"), "Tremborag dies later (5.51 G, M36.4)")
	assert_true(gs.world.is_alive(_db.canon, "goblin_lord"))
	assert_true(gs.world.is_alive(_db.canon, "garen"))


func test_the_system_records_rabbiteater_and_olesm() -> void:
	var names := {}
	for s: Dictionary in _system("5.49"):
		names[String(s["who"]) + " " + String(s["name"])] = s
	for key: String in ["rabbiteater [Champion]", "rabbiteater [Champion's Gear]", "rabbiteater [Grand Slash]",
			"rabbiteater [Valor of Champions]", "olesm [Strategist]"]:
		assert_true(names.has(key), key)
	assert_eq(int(names["rabbiteater [Warrior]"]["level"]), 20)
	for s: Dictionary in _system("5.48G") + _system("5.49") + _system("5.50G") + _system("interlude_bird"):
		assert_ne(String(s["who"]), "ryoka_griffin", "no records for Ryoka")
