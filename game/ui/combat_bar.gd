## The combat bar (M17.3, ADR 0027), bottom right while a fight runs: the
## round, the turn order as faces (Portrait; a letter when there is no sheet)
## framed by side (blue: you and your side, red: foes, yellow: fleeing), the
## fighter whose turn it is in gold, the player's AP as pips (each pip is one
## AP, filled by quarters), the tiles left to move, and the End turn button.
## M17.4: a row of Skill buttons under it (SkillBar; `skill` is emitted with the
## id of the one pressed). M17.5: spells are in that row too ("spell:<id>"), and
## the player's MP shows beside the AP once they know a spell.
## Hidden when there is no fight. Presentation only (CLAUDE.md rule 1).
class_name CombatBar
extends PanelContainer

signal end_turn
signal skill(skill_id: String)

const FACE := Vector2(64, 64)
const FRAME := 2
const ACTIVE_FRAME := 4
const ACTIVE := Color("#f0c850")
const FACE_BACK := Color(0.1, 0.1, 0.12, 0.9)

var _round: Label
var _ap: Label
var _mp: Label
var _move: Label
var _pips: ApPips
var _button: Button
var _faces: HBoxContainer
var _skills: SkillBar
var _ids: Array[String] = []
var _active := ""


## One pip per AP; `ap_q` fills them by quarters.
class ApPips extends Control:
	const PIP := 12.0
	const GAP := 4.0
	const FULL := Color("#5cc8f0")
	const EMPTY := Color(0.15, 0.15, 0.18, 0.9)
	const EDGE := Color(0.8, 0.85, 0.9, 0.8)
	var ap_q := 0
	var max_q := 0

	func set_ap(ap: int, most: int) -> void:
		ap_q = ap
		max_q = most
		@warning_ignore("integer_division")
		var n := (most + Encounter.Q_PER_AP - 1) / Encounter.Q_PER_AP
		custom_minimum_size = Vector2(n * (PIP + GAP), PIP)
		queue_redraw()

	func _draw() -> void:
		@warning_ignore("integer_division")
		var n := (max_q + Encounter.Q_PER_AP - 1) / Encounter.Q_PER_AP
		var y := (size.y - PIP) / 2.0
		for i in n:
			var r := Rect2(i * (PIP + GAP), y, PIP, PIP)
			draw_rect(r, EMPTY)
			var fill := clampi(ap_q - i * Encounter.Q_PER_AP, 0, Encounter.Q_PER_AP)
			if fill > 0:
				draw_rect(Rect2(r.position, Vector2(PIP * fill / float(Encounter.Q_PER_AP), PIP)), FULL)
			draw_rect(r, EDGE, false, 1.0)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var box := VBoxContainer.new()
	add_child(box)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	box.add_child(top)
	_round = Label.new()
	top.add_child(_round)
	_ap = Label.new()
	top.add_child(_ap)
	_mp = Label.new()  # M17.5: shown once the player knows a spell
	_mp.visible = false
	top.add_child(_mp)
	_pips = ApPips.new()
	_pips.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(_pips)
	_move = Label.new()
	top.add_child(_move)
	_button = Button.new()
	_button.text = "End turn"
	_button.focus_mode = Control.FOCUS_NONE  # Space must not press it twice
	_button.pressed.connect(func() -> void: end_turn.emit())
	top.add_child(_button)
	_faces = HBoxContainer.new()
	_faces.add_theme_constant_override("separation", 4)
	box.add_child(_faces)
	_skills = SkillBar.new()
	_skills.picked.connect(func(id: String) -> void: skill.emit(id))
	box.add_child(_skills)
	visible = false


func refresh(gs: GameState, db: DataDb) -> void:
	visible = Encounter.active(gs)
	if not visible:
		return
	var e := gs.combat.encounter
	var t := Encounter.rules(db)
	var mine := Encounter.is_player_turn(gs)
	_round.text = "Round %d" % int(e["round"])
	var ap := int(e["ap_q"]) if mine else 0
	_ap.text = "AP %s" % _ap_string(ap)
	_mp.visible = not gs.progression.spells.is_empty()
	_mp.text = "MP %d/%d" % [Mana.current(gs, db), Stats.max_mp(gs, db)]
	_pips.set_ap(ap, Encounter.player_ap(gs, db))
	@warning_ignore("integer_division")
	var steps := mini(ap, CombatSkills.move_cap_q(gs, db) - int(e["moved_q"])) / int(t["move_cost_q"]) \
			if mine else 0
	_move.text = "Move %d" % steps
	_button.disabled = not mine
	_skills.refresh(gs, db)
	var order: Array = e["order"]
	var turn := int(e["turn"])
	_active = String(order[turn]) if turn < order.size() else ""
	for c in _faces.get_children():
		_faces.remove_child(c)
		c.queue_free()
	_ids.clear()
	for id: String in order:
		var face := _face(gs, db, id)
		if face != null:
			_ids.append(id)
			_faces.add_child(face)


## The fighters shown, in turn order.
func face_ids() -> Array[String]:
	return _ids.duplicate()


func active_id() -> String:
	return _active


func ap_text() -> String:
	return _ap.text


func mp_text() -> String:
	return _mp.text if _mp.visible else ""


func move_text() -> String:
	return _move.text


func button() -> Button:
	return _button


func skills() -> SkillBar:
	return _skills


## "4.5" for 18 q, "6" for 24 q.
static func _ap_string(q: int) -> String:
	if q % Encounter.Q_PER_AP == 0:
		@warning_ignore("integer_division")
		return str(q / Encounter.Q_PER_AP)
	return ("%.2f" % (q / float(Encounter.Q_PER_AP))).trim_suffix("0")


## A monster's whole front standing frame (a crab has no head to crop), or
## null when it has no sheet.
static func _whole(look: String) -> AtlasTexture:
	if not CharacterSprite.has_sheet(look):
		return null
	var t := AtlasTexture.new()
	t.atlas = load(CharacterSprite.path_for(look))
	t.region = CharacterSprite.region_of("walk", "s", 0)
	return t


## During a replay (M17.3): fighter `id` is acting, so its face is framed in
## gold, the AP pips are empty and End turn waits.
func show_acting(id: String) -> void:
	_active = id
	_ap.text = "AP -"
	_move.text = "Move -"
	_pips.set_ap(0, _pips.max_q)
	_button.disabled = true
	for i in _ids.size():
		var style: StyleBoxFlat = _faces.get_child(i).get_theme_stylebox("panel")
		var on := _ids[i] == id
		style.set_border_width_all(ACTIVE_FRAME if on else FRAME)
		style.border_color = ACTIVE if on else style.get_meta("side")


## A framed face for fighter `id`, or null when it is gone.
func _face(gs: GameState, db: DataDb, id: String) -> Control:
	var look := ""
	var who := ""
	var side := WorldView.ALLY_EDGE
	if id == Encounter.PLAYER:
		look = "player"
		who = "You"
	elif id.begins_with(Encounter.NPC):
		var npc := id.substr(Encounter.NPC.length())
		if not gs.npcs.npcs.has(npc):
			return null
		look = Portrait.look_of_npc(db, npc)
		who = Combat.npc_name(db, npc)
		if Brawl.on(db) and Brawl.is_hostile(gs, gs.npcs.npcs[npc]):
			side = WorldView.HOSTILE_EDGE
	else:
		if not gs.combat.monsters.has(id):
			return null
		var m: Dictionary = gs.combat.monsters[id]
		look = String(db.combat.enemies[m["type"]].get("look", m["type"]))
		who = Combat.name_of(db, m)
		side = WorldView.state_edge(String(m["state"]))
	var frame := PanelContainer.new()
	frame.name = id.replace(":", "_")
	frame.tooltip_text = who
	var style := StyleBoxFlat.new()
	style.bg_color = FACE_BACK
	var width := ACTIVE_FRAME if id == _active else FRAME
	style.set_border_width_all(width)
	style.border_color = ACTIVE if id == _active else side
	style.set_meta("side", side)
	frame.add_theme_stylebox_override("panel", style)
	var tex := Portrait.texture(look) if not gs.combat.monsters.has(id) else _whole(look)
	if tex != null:
		var r := TextureRect.new()
		r.texture = tex
		r.custom_minimum_size = FACE
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		frame.add_child(r)
	else:
		var l := Label.new()
		l.text = who.substr(0, 1).to_upper()
		l.custom_minimum_size = FACE
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.add_theme_color_override("font_color", side)
		frame.add_child(l)
	return frame
