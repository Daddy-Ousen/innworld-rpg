extends GutTest
## M11.4 monster art (ADR 0018): every enemy has a sheet; a monster whose type
## has one is a sprite with a state ring, faces its last step or swing, falls
## and fades when gone; a hidden Rock Crab is the rock prop.

const ART_GOBLIN := "goblin_grunt"


## A frozen toy arena with the player at 3,7 and a toy enemy that has a real
## sheet (a copy of the toy goblin named after the real Goblin grunt look).
func _arena() -> Array:
	var d := ToyCombat.db()
	ToyCombat.freeze(d)
	ToyCombat.always_hit(d)
	d.combat.enemies[ART_GOBLIN] = (d.combat.enemies["goblin"] as Dictionary).duplicate(true)
	var gs := ToyCombat.new_game(d)
	ToyCombat.to_arena(gs, d, Vector2i(3, 7))
	return [d, gs]


func _view(d: DataDb) -> WorldView:
	var v: WorldView = add_child_autofree(load("res://world/world_view.tscn").instantiate())
	v.setup(d.maps, {}, d.combat.enemies)
	return v


func _sprite(v: WorldView, id: String) -> CharacterSprite:
	for c in v.monsters.get_node(id).get_children():
		if c is CharacterSprite:
			return c
	return null


func test_every_enemy_has_a_sheet() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/enemies.json"))
	assert_eq(data["enemies"].size(), 47)  # M19.1: face_eater_moth, moth_swarm; M18.1: eater_goat
	for type: String in data["enemies"]:
		var look := String(data["enemies"][type].get("look", type))
		assert_true(CharacterSprite.has_sheet(look), "no sheet for %s (tools/build_sprites.py or build_creatures.py)" % type)


## M13.0: an enemy with a "look" is drawn with that enemy's sheet.
func test_an_enemy_look_borrows_another_sheet() -> void:
	var a := _arena()
	var d: DataDb = a[0]
	var gs: GameState = a[1]
	d.combat.enemies["pale_goblin"] = (d.combat.enemies["goblin"] as Dictionary).duplicate(true)
	d.combat.enemies["pale_goblin"]["look"] = ART_GOBLIN
	var v := _view(d)
	var id := ToyCombat.spawn(gs, d, "pale_goblin", Vector2i(4, 7))
	v.refresh(gs, d)
	assert_eq(v.monster_look("pale_goblin"), ART_GOBLIN)
	assert_eq(v.monster_look("goblin"), "goblin", "no look: its own type")
	assert_eq((v.monsters.get_node(id).get_child(1) as CharacterSprite).texture.resource_path,
			CharacterSprite.path_for(ART_GOBLIN))


func test_a_monster_with_a_sheet_is_a_sprite_with_a_state_ring() -> void:
	var a := _arena()
	var d: DataDb = a[0]
	var gs: GameState = a[1]
	var v := _view(d)
	var art := ToyCombat.spawn(gs, d, ART_GOBLIN, Vector2i(4, 7))
	var plain := ToyCombat.spawn(gs, d, "goblin", Vector2i(6, 7))
	var helper := ToyCombat.spawn(gs, d, ART_GOBLIN, Vector2i(2, 7), CombatState.ALLY)
	v.refresh(gs, d)
	var m := v.monsters.get_node(art)
	assert_eq(m.get_child_count(), 5, "ring, sprite, label, bar back and fill")
	assert_true(m.get_child(0) is Polygon2D, "the ring under the feet")
	assert_eq((m.get_child(0) as Polygon2D).color.to_html(false), WorldView.HOSTILE_EDGE.to_html(false))
	assert_true(m.get_child(1) is CharacterSprite)
	assert_eq((m.get_child(1) as CharacterSprite).texture.resource_path, CharacterSprite.path_for(ART_GOBLIN))
	assert_eq((m.get_child(1) as CharacterSprite).shown, ["walk", "s", 0], "faces down before it has moved")
	assert_eq((m.get_child(2) as Label).text, "Goblin 8/8")
	assert_true(m.get_child(3) is ColorRect, "the HP bar")
	var h := v.monsters.get_node(helper)
	assert_eq((h.get_child(0) as Polygon2D).color.to_html(false), WorldView.ALLY_EDGE.to_html(false))
	var p := v.monsters.get_node(plain)
	assert_true(p.get_child(0) is ColorRect, "a type with no sheet stays a square")
	assert_eq((p.get_child(0) as ColorRect).color, WorldView.HOSTILE_EDGE)


func test_a_monster_sprite_faces_its_swing_and_its_step() -> void:
	var a := _arena()
	var d: DataDb = a[0]
	var gs: GameState = a[1]
	var v := _view(d)
	var gob := ToyCombat.spawn(gs, d, ART_GOBLIN, Vector2i(3, 6))
	v.refresh(gs, d)
	Combat.set_hp(gs, d, Combat.hp(gs, d) - 2)
	v.refresh(gs, d)
	var s := _sprite(v, gob)
	assert_eq(s.shown[0], "attack", "it swings at you")
	assert_eq(s.shown[1], "s", "down, toward you")
	v.refresh(gs, d)
	assert_eq(_sprite(v, gob).shown, ["walk", "s", 0], "a new marker still faces its last swing")
	gs.combat.monsters[gob]["x"] = 4
	v.refresh(gs, d)
	s = _sprite(v, gob)
	assert_true(s.is_walking(), "one step glides")
	assert_eq(s.facing, "e")
	assert_eq(s.position, Vector2(-WorldView.TILE, 0), "from the old cell")
	s.finish()
	assert_eq(s.shown, ["walk", "e", 0])


func test_a_killed_sprite_monster_falls_and_fades() -> void:
	var a := _arena()
	var d: DataDb = a[0]
	var gs: GameState = a[1]
	var v := _view(d)
	var gob := ToyCombat.spawn(gs, d, ART_GOBLIN, Vector2i(4, 7))
	gs.combat.monsters[gob]["hp"] = 1
	v.refresh(gs, d)
	Commands.attack(gs, d, "e")
	v.refresh(gs, d)
	assert_false(gs.combat.monsters.has(gob))
	assert_eq(v.fx.get_child_count(), 1, "the ghost")
	var ghost := v.fx.get_child(0)
	assert_true(ghost.get_child(0) is CharacterSprite)
	var s: CharacterSprite = ghost.get_child(0)
	assert_true(s.down, "it falls")
	assert_eq(s.shown[0], "hurt")
	await wait_seconds(CharacterSprite.FALL_TIME + WorldView.GONE_TIME + 0.15)
	assert_eq(v.fx.get_child_count(), 0, "then it is gone")


func test_a_hidden_monster_is_the_rock_prop() -> void:
	var a := _arena()
	var d: DataDb = a[0]
	var gs: GameState = a[1]
	d.maps.tiles[WorldView.HIDDEN_TILE] = {"name": "Rock", "walk": false, "color": "#7a7468",
		"prop": {"sheet": "lpc_atlas", "region": [28, 26, 1, 1]}}
	var v := _view(d)
	var crab := ToyCombat.spawn(gs, d, "crab", Vector2i(10, 1), CombatState.HIDDEN)
	v.refresh(gs, d)
	var c := v.monsters.get_node(crab)
	assert_eq(c.get_child_count(), 1, "the rock, no label, no bar")
	assert_true(c.get_child(0) is Sprite2D)
	assert_eq((c.get_child(0) as Sprite2D).texture.resource_path, WorldView.sheet_path("lpc_atlas"))
	assert_eq((c.get_child(0) as Sprite2D).region_rect, Rect2(28 * 32, 26 * 32, 32, 32))
