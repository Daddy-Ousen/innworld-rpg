extends GutTest
## NPCs near a fight (M6.5, ADR 0011) on the ToyNpcs world with toy combat:
## the guard (tag "guard") fights, the farmer steps away or stands still,
## a stage ally fights. Monsters are frozen: only the NPCs act.

var _db: DataDb


func before_each() -> void:
	_db = ToyNpcs.combat_db()
	ToyCombat.freeze(_db)


func _wait(gs: GameState, times: int = 1) -> Array[String]:
	var lines: Array[String] = []
	for i in times:
		Commands.wait(gs, _db, 6)
		lines.append_array(gs.combat.lines)
	return lines


func _dist(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


## A guard fight in town: the player at 6,1, a Goblin at 4,3, the guard on
## patrol at 1,1. Returns the lines seen until the Goblin is gone.
func _guard_fight(seed_value: int) -> Dictionary:
	var gs := ToyNpcs.new_game(_db, seed_value)
	gs.player.place("town", Vector2i(6, 1))
	Commands.settle(gs, _db)
	var gob := ToyCombat.spawn(gs, _db, "goblin", Vector2i(4, 3))
	var lines: Array[String] = []
	for i in 40:
		if not gs.combat.monsters.has(gob):
			break
		lines.append_array(_wait(gs))
	return {"gs": gs, "gob": gob, "lines": lines}


func test_react_rules_are_in_the_shipped_data() -> void:
	var real := DataDb.load_dir()
	assert_eq(real.errors, [] as Array[String])
	assert_true((real.rules["npc"]["react"]["fight_tags"] as Array).has("guard"))


func test_a_guard_walks_to_a_monster_and_fights_it() -> void:
	ToyCombat.always_hit(_db)
	var r := _guard_fight(1)
	var gs: GameState = r["gs"]
	assert_false(gs.combat.monsters.has(r["gob"]), "the guard killed the Goblin")
	assert_true((r["lines"] as Array).any(func(l: String) -> bool: return l.begins_with("Guard hits the Goblin for")),
			"guard hit lines: %s" % [r["lines"]])
	assert_has(r["lines"], "The Goblin dies.")
	assert_false(gs.combat.has_fight(), "the fight is over")
	assert_eq(Combat.hp(gs, _db), Stats.max_hp(gs, _db), "the player was never hit")


func test_npc_fights_are_the_same_with_the_same_seed() -> void:
	var a := _guard_fight(7)
	var b := _guard_fight(7)
	assert_eq(a["lines"], b["lines"])
	assert_eq((a["gs"] as GameState).to_json(), (b["gs"] as GameState).to_json())


func test_a_bystander_steps_away_from_a_monster() -> void:
	var gs := ToyNpcs.new_game(_db)
	gs.player.place("field", Vector2i(0, 2))
	Commands.settle(gs, _db)
	assert_eq(ToyNpcs.pos(gs, "farmer"), Vector2i(2, 1))
	var gob := ToyCombat.spawn(gs, _db, "goblin", Vector2i(3, 1))
	_wait(gs)
	var gob_at := CombatState.pos_of(gs.combat.monsters[gob])
	assert_gt(_dist(ToyNpcs.pos(gs, "farmer"), gob_at), 1, "the farmer stepped away")
	_wait(gs, 3)
	assert_gt(_dist(ToyNpcs.pos(gs, "farmer"), gob_at), 2, "and keeps away")
	Combat.damage_monster(gs, _db, gob, 99)
	_wait(gs, 10)
	assert_false(gs.combat.has_fight())
	assert_eq(ToyNpcs.pos(gs, "farmer"), Vector2i(2, 1), "back to work when it is over")


func test_a_far_bystander_stands_still() -> void:
	ToyCombat.never_hit(_db)
	var gs := ToyNpcs.new_game(_db)
	gs.player.place("town", Vector2i(6, 1))
	Commands.settle(gs, _db)
	var n: Dictionary = gs.npcs.npcs["farmer"]
	n["area"] = "town"
	n["x"] = 1
	n["y"] = 3
	ToyCombat.spawn(gs, _db, "goblin", Vector2i(6, 3))
	_wait(gs, 4)
	assert_eq(ToyNpcs.area(gs, "farmer"), "town")
	assert_eq(ToyNpcs.pos(gs, "farmer"), Vector2i(1, 3), "no walk to the field while in danger")


func test_a_stage_ally_fights_its_stage_foe_only() -> void:
	ToyCombat.always_hit(_db)
	var gs := ToyNpcs.new_game(_db)
	gs.player.place("field", Vector2i(0, 2))
	Commands.settle(gs, _db)
	var gob := ToyCombat.spawn(gs, _db, "goblin", Vector2i(3, 2))
	assert_false(NpcReact.is_fighter(gs, _db, "farmer"), "a plain Goblin: the farmer is no fighter")
	gs.combat.monsters[gob]["stage"] = "e.ambush"
	_db.canon = CanonDb.from_dicts(ToyNpcs.npcs(), ToyMaps.locations(), {"e.ambush": ToyCanon.event(1, 1,
			{"stage": {"area": "field", "hours": [6, 12], "foes": [{"enemy": "goblin", "pos": [3, 2]}],
				"allies": ["farmer"]}})})
	assert_true(NpcReact.is_fighter(gs, _db, "farmer"), "an ally of the Goblin's stage")
	assert_false(NpcReact.is_fighter(gs, _db, "baker"))
	assert_true(NpcReact.is_fighter(gs, _db, "guard"), "a guard always fights")
	var lines: Array[String] = []
	for i in 20:
		if not gs.combat.monsters.has(gob):
			break
		lines.append_array(_wait(gs))
	assert_false(gs.combat.monsters.has(gob), "the farmer beat the Goblin")
	assert_true(lines.any(func(l: String) -> bool: return l.begins_with("Farmer hits the Goblin")))


func test_a_fighter_with_no_monster_in_reach_keeps_its_goal() -> void:
	var gs := ToyNpcs.new_game(_db)
	gs.player.place("town", Vector2i(6, 1))
	Commands.settle(gs, _db)
	_db.rules["npc"]["react"]["help_radius"] = 1
	ToyCombat.spawn(gs, _db, "goblin", Vector2i(6, 3))
	_wait(gs, 3)
	assert_ne(ToyNpcs.pos(gs, "guard"), Vector2i(1, 1), "the guard walks its patrol")
	_db.rules["npc"]["react"]["help_radius"] = 8
