## The unit markers of the world view (M26.1, ADR 0041): NPCs (name, HP bar,
## "(down)"), inn patrons (M14.2), monsters (sprite with a foot ring or
## squares, label, HP bar; a hidden one is a rock), Frost Fairies (bobbing
## diamonds) and found traps (M13.T). Big battles (M7.B, ADR 0013): see
## `labelled`. WorldView makes and owns one; `_v` is the view (untyped: no
## script cycle).
class_name ViewMarkers
extends RefCounted

const TILE := ViewArt.TILE
const U := ViewArt.U
const NPC_COLOR := Color("#3b6fd1")
## A hidden monster is drawn as this tile.
const HIDDEN_TILE := "rock"
## Monster marker edge by state: hostile, fleeing, else calm.
const HOSTILE_EDGE := Color("#e03a3a")
const FLEE_EDGE := Color("#f0d040")
const ALLY_EDGE := Color("#4a90e2")
## HP bar under a marker: back, fill, and fill at or below BAR_LOW of max.
const BAR_BACK := Color(0.1, 0.1, 0.1, 0.85)
const BAR_FILL := Color("#5cc85c")
const BAR_LOW_FILL := Color("#e05050")
const BAR_LOW := 0.34
## Up to this many monsters on screen: all keep their labels.
const LABEL_ALL_UP_TO := 4
const LABEL_NEAREST := 3
## Two labels on the same row closer than this many tiles would overlap.
const LABEL_GAP := 3
const DOWN_ALPHA := 0.35
const CALM_EDGE := Color(0, 0, 0, 0.6)
## A dark ring between the edge and the body, so a green Goblin stands out on grass.
const RING := Color(0.08, 0.08, 0.08, 1)
const FAIRY_BODY := Color("#bfe8ff")
const FAIRY_EDGE := Color("#ffffff")
## Frost Fairies float up and down this many px, this fast (radians/s).
const FAIRY_BOB := 1.5 * U
const FAIRY_BOB_SPEED := 4.0
## A found trap (M13.T): armed, or spent / disarmed.
const TRAP_ARMED := Color("#e03a3a")
const TRAP_SAFE := Color(0.55, 0.55, 0.55, 0.8)
const TRAP_EDGE := Color(0.08, 0.08, 0.08, 0.9)
## The ring under a monster sprite's feet: half-size, px below the cell
## centre, points, and how strong its state colour shows.
const FOOT_RING := Vector2(11, 4)
const FOOT_RING_Y := 11.0
const FOOT_RING_POINTS := 16
const FOOT_RING_ALPHA := 0.7

var _v
var _bob_time := 0.0


func _init(view) -> void:
	_v = view


## Redraws every marker of the player's area.
func show_all(gs: GameState) -> void:
	_show_npcs(gs)
	_show_guests(gs)
	_show_monsters(gs)
	_show_fairies(gs)
	_show_traps(gs)


## Frost Fairies bob up and down (real time).
func bob(delta: float) -> void:
	var fairies: Node2D = _v.fairies
	if fairies.get_child_count() == 0:
		return
	_bob_time += delta
	for f in fairies.get_children():
		var base: Vector2 = f.get_meta("base")
		f.position = base + Vector2(0, sin(_bob_time * FAIRY_BOB_SPEED + float(f.get_meta("phase"))) * FAIRY_BOB)


static func _clear(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()


## One marker per NPC in the area (named after the NPC id), with its
## name above it; a hurt NPC has an HP bar, a fallen one is faded.
func _show_npcs(gs: GameState) -> void:
	var npcs: Node2D = _v.npcs
	_clear(npcs)
	for id in gs.npcs.in_area(_v.area):
		var n: Dictionary = gs.npcs.npcs[id]
		var down := bool(n.get("down", false))
		var marker := Node2D.new()
		marker.name = id
		marker.position = ViewArt.cell_center(NpcRoster.pos_of(n))
		var sprite := CharacterSprite.make(CharacterSprite.look_for(id, String(_v.npc_races.get(id, ""))))
		if sprite != null:
			sprite.pose(String(n.get("facing", "s")), down)
			marker.add_child(sprite)
		else:
			var square := ColorRect.new()
			square.position = Vector2(-5, -5) * U
			square.size = Vector2(10, 10) * U
			square.color = NPC_COLOR
			if down:
				square.color.a = DOWN_ALPHA
			square.mouse_filter = Control.MOUSE_FILTER_IGNORE
			marker.add_child(square)
		var name_text := String(_v.npc_names.get(id, id))
		ViewArt.add_label(marker, name_text + " (down)" if down else name_text,
				sprite.head() if sprite != null else 5.0 * U)
		var most := int(_v.npc_max_hp.get(id, 0))
		var now := int(n.get("hp", -1))
		if most > 0 and now >= 0:
			_bar(marker, float(now) / most)
		npcs.add_child(marker)


## M14.2: one marker per patron in the area (named "guest_<id>"), facing its
## table, "Drake patron (wants stew)" or "(eating)" above it. Drawn like an
## NPC with the race look (CharacterSprite), or a square with no sheet.
func _show_guests(gs: GameState) -> void:
	for g in Guests.present(gs):
		if g["area"] != _v.area:
			continue
		var seat := Vector2i(int(g["seat"][0]), int(g["seat"][1]))
		var marker := Node2D.new()
		marker.name = "guest_" + String(g["id"])
		marker.position = ViewArt.cell_center(seat)
		var sprite := CharacterSprite.make(String(g["look"]))
		if sprite != null:
			sprite.pose(_facing_table(seat))
			marker.add_child(sprite)
		else:
			var square := ColorRect.new()
			square.position = Vector2(-5, -5) * U
			square.size = Vector2(10, 10) * U
			square.color = NPC_COLOR
			square.mouse_filter = Control.MOUSE_FILTER_IGNORE
			marker.add_child(square)
		var state := "eating" if int(g["paid"]) > 0 \
				else "wants " + String(g["order"]).replace("_", " ")
		ViewArt.add_label(marker, "%s (%s)" % [Guests.patron_name(g), state],
				CharacterSprite.HEAD if sprite != null else 5.0 * U)
		(_v.npcs as Node2D).add_child(marker)


## The way from a seat to its table ("s" if none is found).
func _facing_table(seat: Vector2i) -> String:
	for o: Dictionary in (_v._maps as MapDb).objects_on(_v.area):
		for s: Array in o.get("seats", []):
			if Vector2i(int(s[0]), int(s[1])) == seat:
				var d := Vector2i(int(o["at"][0]), int(o["at"][1])) - seat
				for dir: String in PlayerState.DIRS:
					if PlayerState.DIRS[dir] == Vector2i(signi(d.x), signi(d.y)):
						return dir
	return "s"


## One marker per monster in the area (named after the monster id). With a
## sheet for its type (M11.4): a foot ring in the state colour, the sprite
## (facing its last step or swing), "Goblin 5/8" above the head (see
## labelled) and an HP bar below. With no sheet: an edge by state, a dark
## ring, a body in the enemy colour, the label and the bar. A hidden monster
## is the rock tile's prop (or a rock-coloured square) with no label.
func _show_monsters(gs: GameState) -> void:
	var monsters: Node2D = _v.monsters
	var enemies: Dictionary = _v.enemies
	var maps: MapDb = _v._maps
	_clear(monsters)
	var named := labelled(gs, enemies)
	for id in gs.combat.ids():
		var m: Dictionary = gs.combat.monsters[id]
		if m["area"] != _v.area:
			continue
		var e: Dictionary = enemies.get(m["type"], {})
		var marker := Node2D.new()
		marker.name = id
		marker.position = ViewArt.cell_center(CombatState.pos_of(m))
		if m["state"] == CombatState.HIDDEN:
			var prop := ViewArt.tile_prop(maps.tiles, HIDDEN_TILE, _v._winter)
			if prop != null:
				marker.add_child(prop)
			else:
				var rock := Color.html(maps.tiles.get(HIDDEN_TILE, e).get("color", "#7a7468"))
				ViewArt.square(marker, TILE / 2.0, rock.darkened(0.35))
				ViewArt.square(marker, TILE / 2.0 - 2 * U, rock)
			monsters.add_child(marker)
			continue
		var edge := state_edge(String(m["state"]))
		var sprite := CharacterSprite.make(_v.monster_look(String(m["type"])))
		if sprite != null:
			_foot_ring(marker, edge)
			sprite.pose(String(_v.monster_facing.get(id, "s")))
			marker.add_child(sprite)
		else:
			ViewArt.square(marker, 6 * U, edge)
			ViewArt.square(marker, 5 * U, RING)
			ViewArt.square(marker, 4 * U, Color.html(e.get("color", "#ff00ff")))
		if named.has(id):
			ViewArt.add_label(marker, monster_label(m, e), CharacterSprite.HEAD if sprite != null else 5.0 * U)
		_bar(marker, float(m["hp"]) / maxi(int(e.get("hp", m["hp"])), 1))
		monsters.add_child(marker)


## The marker edge colour of a monster state: hostile, fleeing, ally, else calm.
static func state_edge(state: String) -> Color:
	match state:
		CombatState.HOSTILE:
			return HOSTILE_EDGE
		CombatState.FLEE:
			return FLEE_EDGE
		CombatState.ALLY:
			return ALLY_EDGE
	return CALM_EDGE


## A flat ring under a monster sprite's feet in its state colour.
func _foot_ring(marker: Node2D, color: Color) -> void:
	var ring := Polygon2D.new()
	ring.name = "Ring"
	var pts := PackedVector2Array()
	for i in FOOT_RING_POINTS:
		var a := TAU * i / FOOT_RING_POINTS
		pts.append(Vector2(cos(a) * FOOT_RING.x, sin(a) * FOOT_RING.y))
	ring.polygon = pts
	ring.color = Color(color, maxf(color.a, 0.35) * FOOT_RING_ALPHA)
	ring.position = Vector2(0, FOOT_RING_Y)
	marker.add_child(ring)


## A small pale diamond per Frost Fairy in the player's area (no label).
func _show_fairies(gs: GameState) -> void:
	var fairies: Node2D = _v.fairies
	_clear(fairies)
	if gs.winter.area != _v.area:
		return
	for id in gs.winter.ids():
		var marker := Node2D.new()
		marker.name = id
		marker.position = ViewArt.cell_center(WinterState.pos_of(gs.winter.fairies[id]))
		marker.set_meta("base", marker.position)
		marker.set_meta("phase", float(id.hash() % 628) / 100.0)
		marker.rotation = PI / 4.0
		ViewArt.square(marker, 3 * U, FAIRY_EDGE)
		ViewArt.square(marker, 2 * U, FAIRY_BODY)
		fairies.add_child(marker)


## One diamond per found trap on the player's map (named after the trap
## id): red while armed, grey once spent or disarmed.
func _show_traps(gs: GameState) -> void:
	var traps: Node2D = _v.traps
	var area: String = _v.area
	_clear(traps)
	for t: Dictionary in (_v._maps as MapDb).areas[area].get("traps", []):
		if not MapDb.flags_hold(t, gs.flags) or not Traps.state(gs, area, t)["found"]:
			continue
		var marker := Node2D.new()
		marker.name = String(t["id"])
		marker.position = ViewArt.cell_center(Vector2i(int(t["at"][0]), int(t["at"][1])))
		marker.rotation = PI / 4.0
		ViewArt.square(marker, 5 * U, TRAP_EDGE)
		ViewArt.square(marker, 4 * U, TRAP_ARMED if Traps.is_armed(gs, area, t) else TRAP_SAFE)
		traps.add_child(marker)


## Ids of the monsters in the player's area that keep their label. In
## order: the most dangerous foe (lowest id on a tie), the helpers, then the
## foes nearest the player (king moves, then id; with more than
## LABEL_ALL_UP_TO seen monsters, at most LABEL_NEAREST of them). A label is
## left out if it would overlap one already shown: an NPC's name or an
## earlier monster label on the same row within LABEL_GAP tiles.
static func labelled(gs: GameState, enemy_defs: Dictionary) -> Dictionary:
	var seen: Array[String] = []
	for id in gs.combat.ids():
		var m: Dictionary = gs.combat.monsters[id]
		if m["area"] == gs.player.area and m["state"] != CombatState.HIDDEN:
			seen.append(id)
	var foes: Array[String] = []
	var helpers: Array[String] = []
	var top := ""
	var top_danger := 0.0
	for id in seen:
		var m: Dictionary = gs.combat.monsters[id]
		if m["state"] == CombatState.ALLY:
			helpers.append(id)
			continue
		var d := float(enemy_defs.get(m["type"], {}).get("danger", 0.0))
		if top == "" or d > top_danger:
			top = id
			top_danger = d
		foes.append(id)
	var you := gs.player.pos()
	foes.erase(top)
	foes.sort_custom(func(a: String, b: String) -> bool:
		var da := _king(you, CombatState.pos_of(gs.combat.monsters[a]))
		var dbb := _king(you, CombatState.pos_of(gs.combat.monsters[b]))
		return da < dbb or (da == dbb and a.substr(1).to_int() < b.substr(1).to_int()))
	var shown: Array[Vector2i] = []
	for nid in gs.npcs.in_area(gs.player.area):
		shown.append(NpcRoster.pos_of(gs.npcs.npcs[nid]))
	var out := {}
	var order: Array[String] = []
	if top != "":
		order.append(top)
	order.append_array(helpers)
	var cap := foes.size() if seen.size() <= LABEL_ALL_UP_TO else LABEL_NEAREST
	var plain := 0
	for id in order + foes:
		var is_plain := id != top and not helpers.has(id)
		if is_plain and plain >= cap:
			break
		var at := CombatState.pos_of(gs.combat.monsters[id])
		if shown.any(func(p: Vector2i) -> bool: return p.y == at.y and absi(p.x - at.x) <= LABEL_GAP):
			continue
		shown.append(at)
		out[id] = true
		if is_plain:
			plain += 1
	return out


static func _king(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


## A small HP bar (share 0..1) under a marker.
func _bar(marker: Node2D, share: float) -> void:
	share = clampf(share, 0.0, 1.0)
	var back := ColorRect.new()
	back.position = Vector2(-6, 6) * U
	back.size = Vector2(12, 2) * U
	back.color = BAR_BACK
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.add_child(back)
	var fill := ColorRect.new()
	fill.position = Vector2(-6, 6) * U
	fill.size = Vector2(12 * share, 2) * U
	fill.color = BAR_LOW_FILL if share <= BAR_LOW else BAR_FILL
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.add_child(fill)


## "Goblin 5/8": name, HP now / max HP.
static func monster_label(m: Dictionary, e: Dictionary) -> String:
	return "%s %d/%d" % [e.get("name", m["type"]), int(m["hp"]), int(e.get("hp", m["hp"]))]
