extends GutTest
## M11.0 art (ADR 0018): character sheets, art tiles and props, the player's
## step glide, and the fallback to squares when there is no art.


func _art_tiles() -> Dictionary:
	var t := ToyMaps.tiles()
	t["grass"]["sprite"] = {"sheet": "lpc_terrains", "cells": [[1, 10], [0, 12], [1, 12], [2, 12]]}
	t["grass"]["winter_sprite"] = {"sheet": "lpc_terrains", "cells": [[22, 10]]}
	t["wall"]["sprite"] = {"sheet": "no_such_sheet", "cells": [[0, 0]]}
	t["water"]["sprite"] = {"sheet": "lpc_terrains", "cells": [[1, 17]]}
	t["water"]["prop"] = {"sheet": "lpc_atlas", "region": [30, 0, 2, 5]}
	return t


func _art_view() -> WorldView:
	var v: WorldView = add_child_autofree(load("res://world/world_view.tscn").instantiate())
	v.setup(MapDb.from_dicts(_art_tiles(), ToyMaps.areas()))
	return v


func test_frames_follow_the_sheet_layout() -> void:
	assert_eq(CharacterSprite.frame_of("walk", "s", 0), 2 * 9, "walk row 2 faces down")
	assert_eq(CharacterSprite.frame_of("walk", "n", 3), 3)
	assert_eq(CharacterSprite.frame_of("walk", "s", 10), 2 * 9 + 1, "frames wrap")
	assert_eq(CharacterSprite.frame_of("slash", "e", 3), 7 * 9 + 3)
	assert_eq(CharacterSprite.frame_of("hurt", "w", 5), 8 * 9 + 5, "hurt has one row")
	assert_eq(CharacterSprite.frame_of("idle", "w", 1), 10 * 9 + 1)


func test_sheets_exist_only_for_built_looks() -> void:
	assert_true(CharacterSprite.has_sheet("player"))
	assert_false(CharacterSprite.has_sheet("no_such_look"))
	assert_false(CharacterSprite.has_sheet(""))
	assert_null(CharacterSprite.make("no_such_look"))
	var s := CharacterSprite.make("player")
	assert_not_null(s)
	assert_eq(s.hframes, CharacterSprite.COLUMNS)
	assert_eq(s.vframes, CharacterSprite.ROWS)
	s.pose("w", true)
	assert_eq(s.frame, CharacterSprite.frame_of("hurt", "s", 5), "down = lying")
	s.free()


func test_every_look_in_appearance_json_has_a_sheet() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/appearance.json"))
	assert_gt(data["looks"].size(), 0)
	for id: String in data["looks"]:
		assert_true(CharacterSprite.has_sheet(id), "run tools/build_sprites.py for %s" % id)


func test_pick_cell_is_fixed_by_position() -> void:
	var cells := [Vector2i(1, 10), Vector2i(0, 12), Vector2i(1, 12)]
	var seen := {}
	for y in 8:
		for x in 8:
			var c := WorldView.pick_cell(cells, Vector2i(x, y))
			assert_true(cells.has(c))
			assert_eq(c, WorldView.pick_cell(cells, Vector2i(x, y)))
			seen[c] = true
	assert_gt(seen.size(), 1, "the look varies over the map")


func test_tile_set_adds_sheets_and_skips_missing_art() -> void:
	var atlas := {}
	var sprites := {}
	var ts := WorldView.make_tile_set(_art_tiles(), atlas, false, sprites)
	assert_eq(atlas.size(), 3, "every tile keeps its colour cell")
	assert_eq(sprites.keys().size(), 2, "grass and water; the wall's sheet is missing")
	assert_false(sprites.has("wall"))
	assert_eq(sprites["grass"]["source"], sprites["water"]["source"], "one source per sheet")
	var src: TileSetAtlasSource = ts.get_source(sprites["grass"]["source"])
	assert_eq(src.texture_region_size, Vector2i(WorldView.TILE, WorldView.TILE))
	for c: Vector2i in sprites["grass"]["cells"]:
		assert_true(src.has_tile(c))
	var winter := {}
	WorldView.make_tile_set(_art_tiles(), {}, true, winter)
	assert_eq(winter["grass"]["cells"], [Vector2i(22, 10)] as Array[Vector2i], "winter art")
	assert_eq(winter["water"]["cells"], [Vector2i(1, 17)] as Array[Vector2i], "no winter art: summer art")


func test_map_cells_use_art_and_props_stand_on_their_cells() -> void:
	var v := _art_view()
	var gs := ToyMaps.new_game(ToyMaps.db())
	v.refresh(gs)
	var water := 0
	for y in 5:
		for x in 8:
			var cell := Vector2i(x, y)
			var t := v._maps.tile_at("town", cell)
			if t == "wall":
				assert_eq(v.tiles.get_cell_source_id(cell), 0, "no art: the colour square")
				assert_eq(v.tiles.get_cell_atlas_coords(cell), v.atlas["wall"])
			else:
				assert_eq(v.tiles.get_cell_source_id(cell), v.sprites[t]["source"])
				assert_eq(v.tiles.get_cell_atlas_coords(cell), WorldView.pick_cell(v.sprites[t]["cells"], cell))
			if t == "water":
				water += 1
	assert_gt(water, 0)
	assert_eq(v.props.get_child_count(), water, "one prop per water cell")
	var p: Sprite2D = v.props.get_child(0)
	assert_eq(p.region_rect.size, Vector2(2, 5) * WorldView.TILE)
	assert_eq(p.offset.y + p.region_rect.size.y, WorldView.TILE / 2.0, "bottom edge on the cell's bottom")


func test_player_sprite_glides_one_step_and_jumps_on_area_change() -> void:
	var d := ToyMaps.db()
	var v: WorldView = add_child_autofree(load("res://world/world_view.tscn").instantiate())
	v.setup(d.maps)
	assert_not_null(v.look)
	assert_false(v.body.visible, "the square is hidden under the sprite")
	var gs := ToyMaps.new_game(d)
	v.refresh(gs)
	assert_eq(v.look.position, Vector2.ZERO)
	Commands.move(gs, d, "e")
	v.refresh(gs)
	assert_eq(v.player.position, WorldView.cell_center(Vector2i(2, 2)), "the marker is on the cell at once")
	assert_eq(v.look.position, Vector2(-WorldView.TILE, 0), "the sprite starts on the old cell")
	assert_true(v.look.is_walking())
	v.look.finish()
	assert_eq(v.look.position, Vector2.ZERO)
	assert_eq(v.look.frame, CharacterSprite.frame_of("walk", "e", 0), "standing, facing east")
	gs.player.place("town", Vector2i(6, 2))
	Commands.move(gs, d, "s")  # the shop door
	v.refresh(gs)
	assert_eq(v.area, "shop")
	assert_eq(v.look.position, Vector2.ZERO, "no glide across maps")


func test_npc_with_a_sheet_is_a_sprite_and_others_stay_squares() -> void:
	var d := ToyNpcs.db()
	var v: WorldView = add_child_autofree(load("res://world/world_view.tscn").instantiate())
	v.setup(d.maps, {"guard": "Guard", "relc": "Relc"})
	var gs := ToyNpcs.new_game(d)
	var guard: Dictionary = gs.npcs.npcs["guard"]
	var relc := guard.duplicate(true)
	relc["x"] = int(guard["x"]) + 2
	gs.npcs.npcs["relc"] = relc
	v.refresh(gs)
	assert_eq(v.npcs.get_child_count(), 2)
	var r: Node2D = v.npcs.get_node("relc")
	assert_true(r.get_child(0) is CharacterSprite)
	assert_eq((r.get_child(1) as Label).text, "Relc")
	assert_lt((r.get_child(1) as Label).position.y, -CharacterSprite.HEAD, "name above the head")
	assert_true(v.npcs.get_node("guard").get_child(0) is ColorRect)


func test_look_for_uses_own_sheet_then_race_then_none() -> void:
	assert_eq(CharacterSprite.look_for("relc", "Drake"), "relc", "own look first")
	assert_eq(CharacterSprite.look_for("olesm", "Drake"), "race_drake")
	assert_eq(CharacterSprite.look_for("someone", "Half-Elf"), "race_half_elf")
	assert_eq(CharacterSprite.look_for("someone", "half-Elf"), "race_half_elf", "case does not matter")
	assert_eq(CharacterSprite.look_for("someone", "String People"), "", "no generic look: a square")
	assert_eq(CharacterSprite.look_for("someone"), "")


func test_every_npc_with_a_schedule_has_a_look() -> void:
	var canon := CanonDb.load_root()
	var beh := BehaviourDb.load_dir()
	assert_gt(beh.ids().size(), 30)
	for id: String in beh.ids():
		assert_true(canon.npcs.has(id), id)
		var race := String(canon.npcs.get(id, {}).get("race", ""))
		assert_eq(CharacterSprite.look_for(id, race), id, "own look for %s" % id)


func test_npc_with_no_own_sheet_takes_its_race_look() -> void:
	var d := ToyNpcs.db()
	var v: WorldView = add_child_autofree(load("res://world/world_view.tscn").instantiate())
	v.setup(d.maps, {"guard": "Guard"}, {}, {}, "", {"guard": "Gnoll"})
	var gs := ToyNpcs.new_game(d)
	v.refresh(gs)
	var s: Node = v.npcs.get_node("guard").get_child(0)
	assert_true(s is CharacterSprite, "the generic Gnoll look")
	assert_eq((s as CharacterSprite).texture.resource_path, CharacterSprite.path_for("race_gnoll"))
