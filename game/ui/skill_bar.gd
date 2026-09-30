## The Skill bar (M17.4, ADR 0027): a row in the combat bar with one button
## per combat Skill the player holds, then one per spell they know (nine in all,
## keys 1-9): the key, the name and the AP cost (a spell also its MP cost); a
## cooling Skill or spell shows its rounds left. A button is off when it is not
## the player's turn, it cools down, or the AP (or MP) left is too little. The
## armed one (a strike or spell waiting for its target) stays pressed. A spell's
## id here is "spell:<id>" (Spells.KEY). Hidden when there is nothing to use.
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
	var all: Array[String] = CombatSkills.actions(gs, db)
	for sid in Spells.known(gs, db):
		all.append(Spells.KEY + sid)
	_ids = all.slice(0, KEYS)
	visible = not _ids.is_empty()
	var mine := Encounter.is_player_turn(gs)
	var ap := int(gs.combat.encounter.get("ap_q", 0)) if mine else 0
	for i in _ids.size():
		var id := _ids[i]
		var is_spell := id.begins_with(Spells.KEY)
		var a := Spells.spell(db, id.substr(Spells.KEY.length())) if is_spell else CombatSkills.action_of(db, id)
		var left := CombatSkills.rounds_left(gs, Encounter.PLAYER, id)
		var b := Button.new()
		b.name = node_name(id)
		b.focus_mode = Control.FOCUS_NONE  # keys must not press it
		b.toggle_mode = true
		b.button_pressed = id == _armed
		var label := String(a["name"]) if is_spell else String(db.skills[id]["name"])
		b.text = "%d %s %s AP" % [i + 1, label, CombatBar._ap_string(int(a["ap_q"]))]
		if is_spell:
			b.text += " %d MP" % int(a["mp"])
		if left > 0:
			b.text += " (%d)" % left
		b.disabled = not mine or left > 0 or ap < int(a["ap_q"]) 				or (is_spell and Mana.current(gs, db) < int(a["mp"]))
		b.tooltip_text = spell_tip(a) if is_spell else _tip(a)
		b.pressed.connect(func() -> void:
			b.button_pressed = id == _armed
			picked.emit(id))
		add_child(b)


## The Skill ids shown, in key order (key 1 is the first).
func ids() -> Array[String]:
	return _ids.duplicate()


## A button's node name for id `id` (a node name cannot hold ":").
static func node_name(id: String) -> String:
	return id.replace(":", "_")


func button_of(id: String) -> Button:
	return get_node_or_null(NodePath(node_name(id))) as Button


## Marks `id` as armed ("" = none).
func set_armed(id: String) -> void:
	_armed = id
	for c in get_children():
		(c as Button).set_pressed_no_signal(String(c.name) == node_name(id))


func armed() -> String:
	return _armed


## What a spell does, in words.
static func spell_tip(s: Dictionary) -> String:
	var parts: Array[String] = []
	match String(s["shape"]):
		"one":
			parts.append("One foe up to %d tiles away." % int(s["range"]))
		"line":
			parts.append("Every foe on a line of %d tiles; a wall stops it." % int(s["length"]))
		"blast":
			parts.append("Every foe within %d tile%s of a spot up to %d tiles away." % [
				int(s["radius"]), "" if int(s["radius"]) == 1 else "s", int(s["range"])])
		"around":
			parts.append("Hits every foe around you.")
	parts.append("%d-%d damage." % [int(s["damage"][0]), int(s["damage"][1])])
	parts.append("Never misses." if String(s["hit"]) == "auto" else "Your Intellect decides if it hits.")
	if int(s.get("cooldown", 0)) > 0:
		parts.append("Ready again after %d round%s." % [int(s["cooldown"]), "" if int(s["cooldown"]) == 1 else "s"])
	return " ".join(parts)


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
