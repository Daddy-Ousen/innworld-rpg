extends GutTest
## M11.3 animation (ADR 0018): AnimDiff finds what changed between two
## refreshes; WorldView plays it (glides, flashes, damage numbers, falls,
## fades, swings) without changing GameState.


func _unit(kind: String, cell: Vector2i, hp: int = 10, side: String = "us", down: bool = false) -> Dictionary:
	var u := {"kind": kind, "cell": cell, "hp": hp, "down": down, "side": side}
	if kind == "monster":
		u["type"] = "goblin"
	return u


func _snap(units: Dictionary, attacks: int = -1, facing: String = "e", area: String = "arena") -> Dictionary:
	return {"area": area, "attacks": attacks, "units": units, "facing": facing}


func _you(cell: Vector2i, hp: int = 10) -> Dictionary:
	return _unit("player", cell, hp)


func _names(events: Array) -> Array:
	return events.map(func(e: Dictionary) -> String: return "%s:%s" % [e["type"], e["id"]])


func _arena() -> Array:
	var d := ToyCombat.db()
	ToyCombat.freeze(d)
	ToyCombat.always_hit(d)
	var gs := ToyCombat.new_game(d)
	ToyCombat.to_arena(gs, d, Vector2i(3, 7))
	return [d, gs]


func _view(d: DataDb, names: Dictionary = {}) -> WorldView:
	var v: WorldView = add_child_autofree(load("res://world/world_view.tscn").instantiate())
	v.setup(d.maps, names, d.combat.enemies)
	return v


func test_snapshot_lists_who_is_in_the_area() -> void:
	var a := _arena()
	var d: DataDb = a[0]
	var gs: GameState = a[1]
	var goblin := ToyCombat.spawn(gs, d, "goblin", Vector2i(4, 7))
	var crab := ToyCombat.spawn(gs, d, "crab", Vector2i(10, 1), CombatState.HIDDEN)
	var helper := ToyCombat.spawn(gs, d, "bird", Vector2i(1, 1), CombatState.ALLY)
	var s := AnimDiff.snapshot(gs, 20)
	var u: Dictionary = s["units"]
	assert_eq(s["area"], "arena")
	assert_eq(s["attacks"], 0, "a hostile monster begins a fight; no blow yet")
	assert_eq(u[AnimDiff.PLAYER]["cell"], Vector2i(3, 7))
	assert_eq(u[AnimDiff.PLAYER]["hp"], 20, "full HP is the max")
	assert_eq(AnimDiff.snapshot(gs)["units"][AnimDiff.PLAYER]["hp"], -1, "no max given: not known")
	assert_eq(u[goblin]["side"], "them")
	assert_eq(u[goblin]["type"], "goblin")
	assert_eq(u[helper]["side"], "us")
	assert_false(u.has(crab), "a hidden monster looks like a rock")


func test_steps_one_cell_glide_and_jumps_do_not() -> void:
	var before := _snap({AnimDiff.PLAYER: _you(Vector2i(2, 2)),
		"m1": _unit("monster", Vector2i(4, 7), 8, "them"), "m2": _unit("monster", Vector2i(1, 1), 8, "them")})
	var after := _snap({AnimDiff.PLAYER: _you(Vector2i(2, 1)),
		"m1": _unit("monster", Vector2i(5, 8), 8, "them"), "m2": _unit("monster", Vector2i(3, 1), 8, "them")})
	var ev := AnimDiff.events(before, after)
	assert_eq(_names(ev), ["move:@player", "move:m1"])
	assert_eq(ev[0]["dir"], "n")
	assert_eq(ev[1]["dir"], "e", "a diagonal step faces sideways")
	assert_eq(ev[1]["from"], Vector2i(4, 7))
	assert_eq(ev[1]["to"], Vector2i(5, 8))
	assert_eq(AnimDiff.dir_of(Vector2i(0, 1)), "s")
	assert_eq(AnimDiff.dir_of(Vector2i(-1, 0)), "w")


func test_hits_falls_and_gone_monsters() -> void:
	var before := _snap({AnimDiff.PLAYER: _you(Vector2i(2, 2), -1),
		"guard": _unit("npc", Vector2i(5, 5), 10), "m1": _unit("monster", Vector2i(9, 9), 8, "calm")})
	var after := _snap({AnimDiff.PLAYER: _you(Vector2i(2, 2), 6),
		"guard": _unit("npc", Vector2i(5, 5), 0, "us", true)})
	var ev := AnimDiff.events(before, after)
	assert_eq(_names(ev), ["hit:guard", "fall:guard", "gone:m1"], "the player's HP was not known: no number")
	assert_eq(ev[0]["amount"], 10)
	assert_eq(ev[2]["cell"], Vector2i(9, 9))
	assert_eq(ev[2]["monster_type"], "goblin")


func test_no_events_on_the_first_refresh_or_a_new_area() -> void:
	var s := _snap({AnimDiff.PLAYER: _you(Vector2i(2, 2))})
	var moved := _snap({AnimDiff.PLAYER: _you(Vector2i(2, 3))}, -1, "s", "town")
	assert_eq(AnimDiff.events({}, s).size(), 0)
	assert_eq(AnimDiff.events(s, moved).size(), 0)


func test_the_player_swings_when_their_attack_count_grows() -> void:
	var units := {AnimDiff.PLAYER: _you(Vector2i(3, 7)), "m1": _unit("monster", Vector2i(4, 7), 8, "them")}
	assert_eq(_names(AnimDiff.events(_snap(units, 0), _snap(units, 1))), ["swing:@player"], "a miss still swings")
	assert_eq(_names(AnimDiff.events(_snap(units), _snap(units, 1))), ["swing:@player"], "the first blow")
	assert_eq(_names(AnimDiff.events(_snap(units), _snap(units, 0))), [], "a foe began the fight")
	# The blow that ends the fight: the count is gone, but the foe in front is too.
	var alone := {AnimDiff.PLAYER: _you(Vector2i(3, 7))}
	var ev := AnimDiff.events(_snap(units, 2), _snap(alone))
	assert_eq(_names(ev), ["gone:m1", "swing:@player"])
	assert_eq(ev[1]["dir"], "e")
	assert_eq(_names(AnimDiff.events(_snap(units), _snap(alone))), ["gone:m1", "swing:@player"],
			"one blow began and ended the fight")
	var walked := {AnimDiff.PLAYER: _you(Vector2i(3, 8))}
	assert_eq(_names(AnimDiff.events(_snap(units, 2), _snap(walked, -1, "s"))), ["move:@player", "gone:m1"],
			"it fled while you walked away")


func test_monsters_swing_at_a_hit_neighbour_of_the_other_side() -> void:
	var before := _snap({AnimDiff.PLAYER: _you(Vector2i(3, 7), 10),
		"m1": _unit("monster", Vector2i(4, 6), 8, "them"), "m2": _unit("monster", Vector2i(9, 9), 8, "them"),
		"m3": _unit("monster", Vector2i(3, 5), 8, "them"), "m4": _unit("monster", Vector2i(2, 7), 8, "calm"),
		"m5": _unit("monster", Vector2i(12, 1), 8, "them"), "m6": _unit("monster", Vector2i(12, 2), 5, "us")})
	var after := before.duplicate(true)
	var u: Dictionary = after["units"]
	u[AnimDiff.PLAYER]["hp"] = 8
	u["m3"]["cell"] = Vector2i(3, 6)  # stepped next to you: no blow this turn
	u["m5"]["hp"] = 4
	var ev := AnimDiff.events(before, after)
	assert_eq(_names(ev), ["hit:@player", "move:m3", "hit:m5", "swing:m1", "swing:m6"])
	assert_eq(ev[3]["dir"], "w", "m1 is up-right of you: it faces left")
	assert_eq(ev[4]["dir"], "n", "the helper hits the goblin above it")


func test_a_real_attack_gives_a_hit_and_a_swing() -> void:
	var a := _arena()
	var d: DataDb = a[0]
	var gs: GameState = a[1]
	var goblin := ToyCombat.spawn(gs, d, "goblin", Vector2i(4, 7))
	var before := AnimDiff.snapshot(gs)
	Commands.attack(gs, d, "e")
	var ev := AnimDiff.events(before, AnimDiff.snapshot(gs))
	assert_has(_names(ev), "hit:" + goblin)
	assert_has(_names(ev), "swing:@player")


func test_the_view_plays_a_hit_a_number_and_the_player_swing() -> void:
	var a := _arena()
	var d: DataDb = a[0]
	var gs: GameState = a[1]
	var v := _view(d)
	var goblin := ToyCombat.spawn(gs, d, "goblin", Vector2i(4, 7))
	v.refresh(gs, d)
	Commands.attack(gs, d, "e")
	v.refresh(gs, d)
	var hp := int(gs.combat.monsters[goblin]["hp"])
	assert_eq(v.monsters.get_node(goblin).modulate, WorldView.HIT_TINT, "the flash")
	assert_eq(v.fx.get_child_count(), 1)
	assert_eq((v.fx.get_child(0) as Label).text, "-%d" % (8 - hp))
	assert_eq(v.look.shown[0], "attack", "the player swings")
	assert_eq(v.look.shown[1], "e")
	assert_eq(v.look.region_rect.size, Vector2(128, 128))
	assert_eq(v.monster_facing, {}, "the goblin did nothing")
	Combat.set_hp(gs, d, Combat.hp(gs, d) - 2)
	v.refresh(gs, d)
	var number := v.fx.get_child(v.fx.get_child_count() - 1) as Label
	assert_eq(number.text, "-2")
	assert_eq(number.get_theme_color("font_color"), WorldView.HURT_YOU_COLOR)
	assert_eq(v.monster_facing[goblin], "w", "the goblin swung at you")
	assert_eq(v.look.modulate, WorldView.HIT_TINT)


func test_a_killed_monster_fades_out() -> void:
	var a := _arena()
	var d: DataDb = a[0]
	var gs: GameState = a[1]
	var v := _view(d)
	var goblin := ToyCombat.spawn(gs, d, "goblin", Vector2i(4, 7))
	gs.combat.monsters[goblin]["hp"] = 1
	v.refresh(gs, d)
	Commands.attack(gs, d, "e")
	v.refresh(gs, d)
	assert_false(gs.combat.monsters.has(goblin))
	assert_eq(v.monsters.get_child_count(), 0)
	assert_eq(v.fx.get_child_count(), 1, "a fading ghost, no number")
	assert_eq(v.look.shown[0], "attack", "the last blow still swings")
	gs.player.place("town", Vector2i(1, 2))
	v.refresh(gs, d)
	assert_eq(v.fx.get_child_count(), 0, "a new map clears the effects")


func test_a_square_monster_lunges_when_it_hits() -> void:
	var a := _arena()
	var d: DataDb = a[0]
	var gs: GameState = a[1]
	var v := _view(d)
	var goblin := ToyCombat.spawn(gs, d, "goblin", Vector2i(3, 6))
	v.refresh(gs, d)
	var edge := v.monsters.get_node(goblin).get_child(0) as ColorRect
	var base := edge.position
	Combat.set_hp(gs, d, Combat.hp(gs, d) - 2)
	v.refresh(gs, d)
	edge = v.monsters.get_node(goblin).get_child(0) as ColorRect
	await wait_seconds(WorldView.LUNGE_TIME / 2.0)
	assert_gt(edge.position.y, base.y, "it moves down, toward you")
	await wait_seconds(WorldView.LUNGE_TIME)
	assert_almost_eq(edge.position, base, Vector2(0.01, 0.01), "and back")


func test_an_npc_step_glides_and_a_fall_lies_down() -> void:
	var d := ToyNpcs.db()
	var v: WorldView = add_child_autofree(load("res://world/world_view.tscn").instantiate())
	v.setup(d.maps, {"relc": "Relc"})
	var gs := ToyNpcs.new_game(d)
	var relc: Dictionary = (gs.npcs.npcs["guard"] as Dictionary).duplicate(true)
	gs.npcs.npcs.erase("guard")
	gs.npcs.npcs["relc"] = relc
	v.refresh(gs)
	var label_at := (v.npcs.get_node("relc").get_child(1) as Label).position
	relc["x"] = int(relc["x"]) + 1
	relc["facing"] = "e"
	v.refresh(gs)
	var marker := v.npcs.get_node("relc")
	var s := marker.get_child(0) as CharacterSprite
	assert_eq(marker.position, WorldView.cell_center(NpcRoster.pos_of(relc)), "the marker is on the cell at once")
	assert_eq(s.position, Vector2(-WorldView.TILE, 0), "the sprite starts on the old cell")
	assert_true(s.is_walking())
	assert_eq((marker.get_child(1) as Label).position, label_at + Vector2(-WorldView.TILE, 0), "the name follows")
	relc["x"] = int(relc["x"]) + 1
	v.refresh(gs)
	s = v.npcs.get_node("relc").get_child(0) as CharacterSprite
	assert_eq(s.half, 0, "the next step plays the other half of the cycle")
	relc["hp"] = 0
	relc["down"] = true
	v.refresh(gs)
	s = v.npcs.get_node("relc").get_child(0) as CharacterSprite
	assert_eq(s.shown, ["hurt", "s", 0], "falling")
	s.finish()
	assert_eq(s.shown, ["hurt", "s", 5], "lying down")


func test_sprite_swing_and_fall_end_in_a_pose() -> void:
	var s := CharacterSprite.make("relc")
	add_child_autofree(s)
	s.attack("w")
	assert_eq(s.shown, ["attack", "w", 0])
	assert_eq(s.region_rect, CharacterSprite.region_of("attack", "w", 0))
	s.walk("n", Vector2(0, 32), 0.14)
	assert_eq(s.shown[0], "walk", "a new step ends the swing at once")
	s.finish()
	assert_eq(s.shown, ["walk", "n", 0])
	s.fall()
	s.finish()
	assert_true(s.down)
	assert_eq(s.shown, ["hurt", "s", 5])
	s.pose("e")
	assert_false(s.down)


func test_frost_fairies_bob() -> void:
	var d := ToyMaps.db()
	var v: WorldView = add_child_autofree(load("res://world/world_view.tscn").instantiate())
	v.setup(d.maps)
	var gs := ToyMaps.new_game(d)
	gs.winter.area = gs.player.area
	gs.winter.fairies["f1"] = {"x": 3, "y": 3}
	v.refresh(gs)
	var f := v.fairies.get_child(0) as Node2D
	var ys := {}
	for i in 6:
		v._process(0.1)
		ys[snappedf(f.position.y, 0.01)] = true
		assert_almost_eq(absf(f.position.y - WorldView.cell_center(Vector2i(3, 3)).y), 0.0, WorldView.FAIRY_BOB + 0.01)
	assert_gt(ys.size(), 3, "it moves")
