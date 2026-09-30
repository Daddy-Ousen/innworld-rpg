extends GutTest
## M17.6 (ADR 0027) cover on the combat screen: Cover.sides and Cover.note (core, toy arena), the overlay's
## cover bars, and the main scene feeding them with the real data (a player next to a tree).

const AREA := "ruins_entrance"

var _db: DataDb
var _session: Node


func before_each() -> void:
	_session = get_node_or_null("/root/Session")
	_db = ToyCombat.db()
	ToyCombat.tactical(_db)
	_db.maps.tiles["wall"]["cover"] = Cover.WALL
	var areas := _db.maps.areas
	(areas["arena"]["objects"] as Array).append(
			{"id": "table", "at": [9, 1], "name": "Table", "actions": [], "solid": true, "kind": "table"})
	_db.maps = MapDb.from_dicts(_db.maps.tiles, areas)
	_db.maps.validate(_db)


func _game(at: Vector2i) -> GameState:
	var gs := ToyCombat.new_game(_db)
	ToyCombat.to_arena(gs, _db, at)
	return gs


func test_sides_lists_the_cover_beside_a_tile() -> void:
	assert_eq(Cover.sides(_db, "arena", Vector2i(8, 1)), {Vector2i(1, 0): Cover.HALF})
	assert_eq(Cover.sides(_db, "arena", Vector2i(7, 4)), {Vector2i(-1, 0): Cover.WALL})
	assert_eq(Cover.sides(_db, "arena", Vector2i(0, 0)), {})


func test_note_words() -> void:
	var gs := _game(Vector2i(12, 1))
	var p := gs.player.pos()
	assert_eq(Cover.note(gs, _db, "arena", p, Vector2i(8, 1), true, Cover.FRIEND), "half cover")
	assert_eq(Cover.note(gs, _db, "arena", p, Vector2i(8, 1), false, Cover.FRIEND), "", "melee: no cover")
	assert_eq(Cover.note(gs, _db, "arena", Vector2i(4, 4), Vector2i(8, 4), true, Cover.FRIEND), "no sight")
	ToyCombat.spawn(gs, _db, "goblin", Vector2i(11, 3))
	ToyCombat.spawn(gs, _db, "goblin", Vector2i(13, 3))
	assert_eq(Cover.note(gs, _db, "arena", Vector2i(12, 4), Vector2i(12, 3), false, Cover.FOE), "pincer",
			"two goblins beside 12,3 bracket whoever stands there")
	assert_eq(Cover.note(gs, _db, "arena", Vector2i(11, 3), Vector2i(12, 3), false, Cover.FRIEND), "", "the goblins are not the player's side")
	gs.player.place("arena", Vector2i(12, 3))
	assert_eq(Cover.note(gs, _db, "arena", Vector2i(11, 3), gs.player.pos(), false, Cover.FOE), "pincer")


func test_the_overlay_keeps_and_clears_the_cover_bars() -> void:
	var o := CombatOverlay.new()
	add_child_autofree(o)
	var cells := {Vector2i(3, 3): {Vector2i(1, 0): Cover.HALF}}
	o.show_covers(cells)
	assert_eq(o.covers, cells)
	o.clear()
	assert_eq(o.covers, {})


## A walkable tile next to a tree tile on the real map, with a free walkable tile 4+ steps from it for a foe.
func _tree_spot(gs: GameState, db: DataDb) -> Array[Vector2i]:
	var size := db.maps.size(AREA)
	for y in range(2, size.y - 2):
		for x in range(2, size.x - 2):
			var c := Vector2i(x, y)
			if not Movement.can_enter(gs, db, AREA, c) or not db.maps.exit_at(AREA, c).is_empty():
				continue
			var has_tree := false
			for d: Vector2i in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
				if db.maps.tile_at(AREA, c + d) == "tree":
					has_tree = true
			if not has_tree:
				continue
			for dx in [5, -5]:
				var f := c + Vector2i(dx, 0)
				if Movement.can_enter(gs, db, AREA, f) and db.maps.exit_at(AREA, f).is_empty():
					return [c, f] as Array[Vector2i]
	return [] as Array[Vector2i]


func test_the_main_scene_marks_cover_beside_the_player() -> void:
	var db: DataDb = _session.db
	var gs := GameState.new_game(4, db)
	_session.set_state(gs)
	var m: Node = load("res://world/main.tscn").instantiate()
	m.switch_scene = false
	add_child_autofree(m)
	var spot := _tree_spot(gs, db)
	assert_eq(spot.size(), 2, "a tree spot on %s" % AREA)
	gs.player.place(AREA, spot[0])
	Combat.sync(gs, db)
	Combat.add_monster(gs, db, "rock_crab", spot[1], CombatState.HOSTILE)
	Commands.wait(gs, db, 0)
	_session.changed()
	assert_true(Encounter.is_player_turn(gs))
	var covers: Dictionary = m.view.overlay.covers
	assert_true(covers.has(spot[0]), "the player's own tile has cover beside it")
	assert_true((covers[spot[0]] as Dictionary).values().has(Cover.FULL), "a tree is full cover")
	for cell: Vector2i in covers:
		assert_true(cell == spot[0] or Encounter.reach(gs, db).has(cell), "only tiles you can stand on")
