## Read-only character sheet (C key): HP, held item, coins and bag (M8.6), stats, classes,
## levels, skills, focus, open offers. `lines` is static and headless, so tests can check it.
## Presentation only.
class_name CharacterSheet
extends PanelContainer

@onready var _text: Label = %Text


func _ready() -> void:
	hide()


func open(gs: GameState, db: DataDb) -> void:
	_text.text = "\n".join(lines(gs, db))
	show()


func close() -> void:
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode in [KEY_ESCAPE, KEY_C]:
		close()
		get_viewport().set_input_as_handled()


@warning_ignore("integer_division")
static func lines(gs: GameState, db: DataDb) -> Array[String]:
	var p := gs.progression
	var awake := gs.clock.awake_minutes
	var out: Array[String] = [
		"Day %d, %s. Awake %dh %02dm." % [gs.clock.day(), gs.clock.time_string(), awake / 60, awake % 60],
		"Race: %s. Total level: %d." % [gs.race.capitalize(), p.total_level()],
		Hud.health(gs, db),
	]
	if Economy.on(db):
		out.append(Hud.purse(gs, db))
		var bag := gs.economy.goods().map(func(g: String) -> String:
			return "%s x%d" % [db.economy.goods[g]["name"], gs.economy.count(g)])
		out.append("Bag: %s" % (", ".join(bag) if not bag.is_empty() else "empty"))
		if not Economy.is_fed(gs):
			out.append("You have not eaten today.")
	var stats := Stats.of(gs, db)
	out.append("Stats: %s" % ", ".join(stats.keys().map(func(s: String) -> String:
		return "%s %d" % [s.capitalize(), int(stats[s])])))
	out.append("")
	out.append("Classes:")
	if p.classes.is_empty():
		out.append("  None yet.")
	for id: String in p.classes:
		var level := p.level_of(id)
		var need := Levels.xp_to_next(level, db.rules["levels"])
		var note := "  (needs a breakthrough)" if Levels.is_blocked(p, id, db.rules["levels"]) else ""
		out.append("  %s level %d   %.0f / %.0f XP%s" % [db.classes[id]["name"], level,
				float(p.classes[id]["xp"]), need, note])
	out.append("")
	out.append("Skills:")
	if p.skills.is_empty():
		out.append("  None yet.")
	for s: Dictionary in p.skills:
		out.append("  %s   from %s level %d" % [db.skills[s["id"]]["name"],
				db.classes[s["class"]]["name"], int(s["level"])])
	out.append("")
	out.append("Focus: %s" % Journal.focus_name(gs, db))
	if not p.offers.is_empty():
		out.append("Open offers: %s (answer them after you sleep)" % ", ".join(p.offers.map(
				func(o: Dictionary) -> String: return db.classes[o["class"]]["name"])))
	if not p.declined.is_empty():
		out.append("Declined: %s" % ", ".join(p.declined.map(
				func(id: String) -> String: return db.classes[id]["name"])))
	return out
