## The Skill bar (M17.4, ADR 0027): a row in the combat bar with one button
## per combat Skill the player holds (up to nine, keys 1-9): the key, the
## name and the AP cost; a cooling Skill shows its rounds left. A button is
## off when it is not the player's turn, the Skill cools down or the AP left
## is too little. The armed Skill (a strike waiting for its target) stays
## pressed. Hidden when the player has no combat Skill.
## Presentation only (CLAUDE.md rule 1).
class_name SkillBar
extends HBoxContainer

signal picked(skill_id: String)

const KEYS := 9

var _ids: Array[String] = []
var _armed := ""


func _ready() -> void:
	add_theme_constant_override("separation", 4)


func refresh(gs: GameState, db: DataDb) -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_ids = CombatSkills.actions(gs, db).slice(0, KEYS)
	visible = not _ids.is_empty()
	var mine := Encounter.is_player_turn(gs)
	var ap := int(gs.combat.encounter.get("ap_q", 0)) if mine else 0
	for i in _ids.size():
		var id := _ids[i]
		var a := CombatSkills.action_of(db, id)
		var left := CombatSkills.rounds_left(gs, Encounter.PLAYER, id)
		var b := Button.new()
		b.name = id
		b.focus_mode = Control.FOCUS_NONE  # keys must not press it
		b.toggle_mode = true
		b.button_pressed = id == _armed
		b.text = "%d %s %s AP" % [i + 1, String(db.skills[id]["name"]), CombatBar._ap_string(int(a["ap_q"]))]
		if left > 0:
			b.text += " (%d)" % left
		b.disabled = not mine or left > 0 or ap < int(a["ap_q"])
		b.tooltip_text = _tip(a)
		b.pressed.connect(func() -> void:
			b.button_pressed = id == _armed
			picked.emit(id))
		add_child(b)


## The Skill ids shown, in key order (key 1 is the first).
func ids() -> Array[String]:
	return _ids.duplicate()


func button_of(id: String) -> Button:
	return get_node_or_null(NodePath(id)) as Button


## Marks `id` as armed ("" = none).
func set_armed(id: String) -> void:
	_armed = id
	for c in get_children():
		(c as Button).set_pressed_no_signal(String(c.name) == id)


func armed() -> String:
	return _armed


## What the Skill does, in words.
static func _tip(a: Dictionary) -> String:
	var parts: Array[String] = []
	match String(a["kind"]):
		CombatSkills.STRIKE:
			parts.append("A throw of what you hold." if bool(a.get("thrown", false)) else "A blow at a foe next to you.")
		CombatSkills.AREA:
			parts.append("Hits every foe around you.")
		CombatSkills.SELF:
			if float(a.get("heal", 0.0)) > 0.0:
				parts.append("Heals %d%% of your HP." % roundi(float(a["heal"]) * 100.0))
			if int(a.get("move_q", 0)) > 0:
				parts.append("You can move %d more tiles this turn." % int(a["move_q"]))
	if int(a.get("hits", 1)) > 1:
		parts.append("%d blows." % int(a["hits"]))
	if float(a.get("damage_mult", 1.0)) != 1.0:
		parts.append("x%s damage." % str(a["damage_mult"]).trim_suffix(".0"))
	if bool(a.get("sure_hit", false)):
		parts.append("Never misses.")
	elif float(a.get("hit_bonus", 0.0)) > 0.0:
		parts.append("Hits more often.")
	if int(a.get("cooldown", 0)) > 0:
		parts.append("Ready again after %d round%s." % [int(a["cooldown"]), "" if int(a["cooldown"]) == 1 else "s"])
	return " ".join(parts)
