## Text commands for the debug console. Parses one line, sends Commands to
## the core and returns output lines. Presentation only: it reads GameState
## and never changes it directly. Headless, so tests can drive it.
class_name ConsoleCommands
extends RefCounted

const SAVE_PATH := "user://debug_save.json"
## "do" options that go to Actions.perform; every other key=value goes to context.
const OPTION_KEYS := ["intensity", "risk", "outcome"]
const HELP := [
	"Commands:",
	"  do <action> [xN] [key=value ...]   do an action (N times). Keys: intensity, risk,",
	"                                     outcome, with=a,b (witnesses); others are context,",
	"                                     e.g. do cook_stew guests=12 location=wandering_inn",
	"  actions                            list actions",
	"  where                              area, tile, place, day and time",
	"  look                               map around you and objects you can use",
	"  go <n|s|e|w> [xN]                  walk N steps",
	"  use <object|npc> <action>          do an action with a nearby object or person",
	"                                     (use bed sleep: sleep in a bed;",
	"                                     use <object> take: hold its item)",
	"  attack <n|s|e|w>                   attack the monster next to you (go does too)",
	"  block                              raise your guard for one turn",
	"  throw [monster]                    throw the held item (default: the nearest monster)",
	"  drop                               put the held item down",
	"  monsters                           the monsters here (debug)",
	"  spawn <enemy> [dx dy]              put a hostile monster near you (debug; default 2 0)",
	"  knockout                           be knocked out now: the night, then the safe place (debug)",
	"  wait <minutes>                     stand still while the world goes on",
	"  npcs                               where every NPC is and what they do (debug)",
	"  sleep [bed | *]                    end the day where you stand (indoors or a camp),",
	"                                     in a bed next to you, or anywhere (*, debug)",
	"  bag                                coins, goods, hunger",
	"  buy <object> <good> / sell <object> <good>   trade at a nearby shop",
	"  eat <good>                         eat or drink a good from the bag",
	"  ride <object>                      take a nearby paid ride (a wagon)",
	"  portal <object>                    step through a nearby magic door",
	"  give <copper> [good] [n]           add coins and goods (debug)",
	"  status                             day, time, classes, skills, offers",
	"  accept <class> / decline <class>   answer a class offer",
	"  focus <tag ...> / focus clear      journal focus (conviction bonus)",
	"  pools                              hidden class pools (debug)",
	"  breakthrough <class>               allow the next capstone level (debug)",
	"  kill <npc>                         kill a canon NPC (debug)",
	"  flag <key> [value] / flag <key> off   set or clear a world flag (debug)",
	"  history                            what happened to canon events (debug)",
	"  drift                              how far the world left canon",
	"  news                               all news and rumors the player heard",
	"  save / load                        " + SAVE_PATH,
	"  new [seed] [start]                 start a new game (start: a rules.world.starts id)",
]

var db: DataDb
var gs: GameState


func _init(data: DataDb, seed_value: int = 1) -> void:
	db = data
	gs = GameState.new_game(seed_value, db)


func execute(line: String) -> Array[String]:
	var parts := line.strip_edges().split(" ", false)
	var out: Array[String] = []
	if parts.is_empty():
		return out
	var args := Array(parts.slice(1))
	match parts[0].to_lower():
		"help", "?":
			out.assign(HELP)
		"actions":
			for id: String in db.actions:
				out.append("  %-18s %3d min  %s" % [id, int(db.actions[id]["minutes"]), db.actions[id]["name"]])
		"do":
			out = _do(args)
		"sleep":
			out = _night(Commands.sleep(gs, db, args[0] if not args.is_empty() else ""))
		"bag":
			out = _bag()
		"buy", "sell":
			if args.size() < 2:
				out.append("Usage: %s <object> <good>." % parts[0])
			else:
				var r := Commands.buy(gs, db, args[0], args[1]) if parts[0] == "buy" \
						else Commands.sell(gs, db, args[0], args[1])
				out = _combat(r["error"])
		"eat":
			out = _need_arg(args, "eat <good>")
			if out.is_empty():
				out = _combat(Commands.use_good(gs, db, args[0]))
		"ride":
			out = _need_arg(args, "ride <object>")
			if out.is_empty():
				out = _combat(Commands.ride(gs, db, args[0]))
				out.append_array(_where())
		"portal":
			out = _need_arg(args, "portal <object>")
			if out.is_empty():
				out = _combat(Commands.portal(gs, db, args[0]))
				out.append_array(_where())
		"give":
			out = _need_arg(args, "give <copper> [good] [n]")
			if out.is_empty():
				var n := int(args[2]) if args.size() > 2 else 1
				var err := Commands.give(gs, db, int(args[0]), args[1] if args.size() > 1 else "", n)
				out.append(err if err != "" else "Coins %s." % Economy.format(db, gs.economy.coins))
		"where":
			out = _where()
		"look":
			out = _look()
		"go":
			out = _go(args)
		"use":
			out = _use(args)
		"wait":
			out = _wait(args)
		"npcs":
			out = _npcs()
		"attack":
			out = _need_arg(args, "attack <n|s|e|w>")
			if out.is_empty():
				out = _combat(Commands.attack(gs, db, (args[0] as String).to_lower().left(1))["error"])
		"block":
			out = _combat(Commands.block(gs, db))
		"throw":
			out = _throw(args)
		"drop":
			out = _combat(Commands.drop(gs, db))
		"monsters":
			out = _monsters()
		"spawn":
			out = _spawn(args)
		"knockout":
			out = _night(Commands.knock_out(gs, db))
		"status":
			out = _status()
		"accept":
			out = _need_arg(args, "accept <class>")
			if out.is_empty():
				out = Commands.accept_class(gs, db, args[0])
		"decline":
			out = _need_arg(args, "decline <class>")
			if out.is_empty():
				out = Commands.decline_class(gs, db, args[0])
		"focus":
			out = _focus(args)
		"pools":
			out = _pools()
		"breakthrough":
			out = _need_arg(args, "breakthrough <class>")
			if out.is_empty():
				var ok := Commands.grant_breakthrough(gs, args[0])
				out.append("Breakthrough granted." if ok else "You do not have the class '%s'." % args[0])
		"kill":
			out = _need_arg(args, "kill <npc>")
			if out.is_empty():
				var err := Commands.kill_npc(gs, db, args[0])
				out.append(err if err != "" else "%s is dead." % db.canon.npcs[args[0]]["name"])
		"flag":
			out = _flag(args)
		"history":
			out = _history()
		"drift":
			out.append("Drift %.2f." % gs.world.drift)
		"news":
			for n: Dictionary in gs.world.news:
				out.append("D%d  %-6s %s" % [int(n["day"]), n["kind"], n["text"]])
			if out.is_empty():
				out.append("No news yet.")
		"save":
			var err := gs.save_to_file(SAVE_PATH)
			out.append("Saved." if err == OK else "Save failed (error %d)." % err)
		"load":
			var loaded := GameState.load_from_file(SAVE_PATH)
			if loaded == null:
				out.append("Load failed.")
			else:
				gs = loaded
				Commands.settle(gs, db)
				out.append("Loaded. Day %d, %s." % [gs.clock.day(), gs.clock.time_string()])
		"new":
			var seed_value := int(args[0]) if not args.is_empty() and (args[0] as String).is_valid_int() else 1
			var start: String = args[1] if args.size() > 1 else ""
			if Movement.start_of(db, start).is_empty():
				out.append("Unknown start '%s'." % start)
			else:
				gs = GameState.new_game(seed_value, db, start)
				out.append("New game, seed %d. Day %d, %s, %s." % [seed_value, gs.clock.day(),
						gs.clock.time_string(), gs.player.area])
		_:
			out.append("Unknown command '%s'. Type help." % parts[0])
	return out


func _do(args: Array) -> Array[String]:
	var out := _need_arg(args, "do <action> [xN] [key=value ...]")
	if not out.is_empty():
		return out
	var action_id: String = args[0]
	if not db.actions.has(action_id):
		out.append("Unknown action '%s'. Type actions." % action_id)
		return out
	var times := 1
	var opts := {}
	var context := {}
	for arg: String in args.slice(1):
		if arg.begins_with("x") and arg.substr(1).is_valid_int():
			times = clampi(int(arg.substr(1)), 1, 100)
			continue
		var kv := arg.split("=", true, 1)
		if kv.size() != 2:
			out.append("Ignored '%s' (use key=value)." % arg)
			continue
		if kv[0] == "with":
			opts["witnesses"] = Array(kv[1].split(",", false))
		elif OPTION_KEYS.has(kv[0]):
			opts[kv[0]] = _value(kv[1])
		else:
			context[kv[0]] = _value(kv[1])
	if not context.is_empty():
		opts["context"] = context
	for i in times:
		var rec := Commands.perform(gs, db, action_id, opts)
		if rec.is_empty():
			if gs.clock.is_collapse_due(db.rules["clock"]):
				out.append("You are too tired. You collapse.")
				out.append_array(_night(Commands.sleep(gs, db)))
			elif not gs.combat.lines.is_empty():
				out.append_array(gs.combat.lines)
			else:
				out.append("You cannot do that.")
			break
		out.append("%s  %s: %.1f XP  (novelty %.2f)" % [
			_time_of(rec), db.actions[action_id]["name"], float(rec["xp"]), float(rec["novelty"])])
	return out


func _where() -> Array[String]:
	var out: Array[String] = []
	if not Movement.ensure_placed(gs, db):
		out.append("There is no world map.")
		return out
	var p := gs.player
	var place := Movement.location_at(gs, db)
	var place_name: String = db.canon.locations.get(place, {}).get("name", place)
	out.append("%s (%s) at %d,%d, facing %s. %s." % [db.maps.areas[p.area]["name"], p.area,
			p.x, p.y, p.facing, place_name])
	out.append("Day %d, %s." % [gs.clock.day(), gs.clock.time_string()])
	return out


## A small window of the map: @ is you, & a person, M a monster you can
## see, o an object, > an exit.
func _look() -> Array[String]:
	var out := _where()
	if not gs.player.is_placed():
		return out
	var p := gs.player
	var marks := {}
	for o: Dictionary in db.maps.objects_on(p.area):
		marks[Vector2i(int(o["at"][0]), int(o["at"][1]))] = "o"
	for id in gs.npcs.in_area(p.area):
		marks[NpcRoster.pos_of(gs.npcs.npcs[id])] = "&"
	for id in gs.combat.ids():
		var m: Dictionary = gs.combat.monsters[id]
		if m["area"] == p.area and m["state"] != CombatState.HIDDEN:
			marks[CombatState.pos_of(m)] = "M"
	var legend: Dictionary = db.maps.areas[p.area]["legend"]
	var char_of := {}
	for ch: String in legend:
		char_of[legend[ch]] = ch
	for y in range(p.y - 4, p.y + 5):
		var line := "  "
		for x in range(p.x - 8, p.x + 9):
			var at := Vector2i(x, y)
			var tile := db.maps.tile_at(p.area, at)
			if at == p.pos():
				line += "@"
			elif marks.has(at):
				line += marks[at]
			elif tile != "" and not db.maps.exit_at(p.area, at).is_empty():
				line += ">"
			else:
				line += char_of.get(tile, " ")
		out.append(line)
	var options := Interact.options(gs, db)
	for o: Dictionary in options:
		var actions: Array = (o["actions"] as Array) + ([Interact.SLEEP] if o["sleep"] else []) \
				+ ([Interact.TAKE] if o["item"] != "" else [])
		if int(o.get("price", 0)) > 0:
			actions.append("(room %s)" % Economy.format(db, int(o["price"])))
		for t: Dictionary in o.get("trades", []):
			actions.append("%s %s %s" % [t["kind"], t["good"], Economy.format(db, int(t["price"]))])
		if not (o.get("ride", {}) as Dictionary).is_empty():
			actions.append("ride to %s %s" % [o["ride"]["to"], Economy.format(db, int(o["ride"]["price"]))])
		if not (o.get("portal", {}) as Dictionary).is_empty():
			actions.append("portal to %s (%d left today)" % [o["portal"]["to"], Portal.trips_left(gs, db)])
		out.append("  %s (%s): %s" % [o["name"], o["id"], ", ".join(actions)])
	if options.is_empty():
		out.append("  Nothing to use here.")
	return out


func _go(args: Array) -> Array[String]:
	var out := _need_arg(args, "go <n|s|e|w> [xN]")
	if not out.is_empty():
		return out
	var dir: String = (args[0] as String).to_lower().left(1)
	if not PlayerState.DIRS.has(dir):
		out.append("Direction must be n, s, e or w.")
		return out
	var times := 1
	if args.size() > 1 and (args[1] as String).begins_with("x") and (args[1] as String).substr(1).is_valid_int():
		times = clampi(int((args[1] as String).substr(1)), 1, 100)
	var steps := 0
	for i in times:
		var r := Commands.move(gs, db, dir)
		if r.has("attack") and r["attack"]["error"] != "":
			out.append(r["attack"]["error"])
		var down := Combat.is_down(gs)
		out.append_array(_after_lines())
		if down or r.has("attack") or r.has("ambush"):
			break
		if r["refused"]:
			if gs.clock.is_collapse_due(db.rules["clock"]):
				out.append("You are too tired. You collapse.")
				out.append_array(_night(Commands.sleep(gs, db)))
			else:
				out.append("You cannot move.")
			break
		if r["blocked"]:
			out.append("%s is in the way." % db.canon.npcs[r["npc"]]["name"] if r["npc"] != ""
					else "Something blocks the way.")
			break
		steps += 1
		if r["exit_to"] != "":
			out.append("You travel to %s (%d min)." % [db.maps.areas[r["exit_to"]]["name"], int(r["minutes"])])
			break
	out.push_front("You walk %d step%s." % [steps, "" if steps == 1 else "s"])
	out.append_array(_where())
	return out


func _use(args: Array) -> Array[String]:
	var out: Array[String] = []
	if args.size() < 2:
		out.append("Usage: use <object> <action>. Type look.")
		return out
	if args[1] == Interact.SLEEP and Interact.can_sleep(gs, db, args[0]):
		return _night(Commands.sleep(gs, db, args[0]))
	if args[1] == Interact.TAKE:
		return _combat(Commands.take(gs, db, args[0]))
	var r := Commands.interact(gs, db, args[0], args[1])
	if r["error"] != "":
		out.append(r["error"])
		if gs.clock.is_collapse_due(db.rules["clock"]):
			out.append_array(_night(Commands.sleep(gs, db)))
		return out
	var rec: Dictionary = r["record"]
	out.append("%s  %s: %.1f XP  (novelty %.2f)" % [
		_time_of(rec), db.actions[args[1]]["name"], float(rec["xp"]), float(rec["novelty"])])
	return out


func _wait(args: Array) -> Array[String]:
	var out := _need_arg(args, "wait <minutes>")
	if not out.is_empty():
		return out
	if not (args[0] as String).is_valid_int() or int(args[0]) < 1:
		out.append("Minutes must be a whole number above 0.")
		return out
	if Commands.wait(gs, db, int(args[0]) * 60) < 0 and not Combat.is_down(gs):
		out.append("You are too tired. You collapse.")
		out.append_array(_night(Commands.sleep(gs, db)))
		return out
	out.append("You wait.")
	out.append_array(_after_lines())
	out.append_array(_where())
	return out


func _npcs() -> Array[String]:
	var out: Array[String] = []
	for id: String in gs.npcs.npcs:
		var n: Dictionary = gs.npcs.npcs[id]
		var place: String = n["area"]
		if not BehaviourDb.is_off_map(place):
			place += " %d,%d" % [int(n["x"]), int(n["y"])]
		out.append("  %-16s %-22s %-10s rel %d" % [id, place, n["goal"],
				gs.world.relationship(id, NpcSim.PLAYER)])
	if out.is_empty():
		out.append("There are no NPCs.")
	return out


## Combat text of the last command, then the night if it knocked the
## player out.
func _after_lines() -> Array[String]:
	var out: Array[String] = gs.combat.lines.duplicate()
	if Combat.is_down(gs):
		out.append_array(_night(Commands.knock_out(gs, db)))
	return out


## After a combat command: its error, or its combat text (and a knock-out).
func _bag() -> Array[String]:
	var out: Array[String] = ["Coins %s.%s" % [Economy.format(db, gs.economy.coins),
			"" if Economy.is_fed(gs) else " Not fed today."]]
	if gs.economy.hunger > 0:
		out.append("Hungry nights: %d (max HP x%.1f)." % [gs.economy.hunger, Economy.hp_mult(gs, db)])
	for g in gs.economy.goods():
		out.append("  %-16s x%d" % [g, gs.economy.count(g)])
	if gs.economy.bag.is_empty():
		out.append("  The bag is empty.")
	return out


func _combat(err: String) -> Array[String]:
	if err != "":
		var out: Array[String] = [err]
		return out
	return _after_lines()


func _throw(args: Array) -> Array[String]:
	var target: String = args[0] if not args.is_empty() else Combat.nearest_foe(gs)
	if target == "":
		var out: Array[String] = ["There is nothing to throw at."]
		return out
	return _combat(Commands.throw(gs, db, target)["error"])


func _monsters() -> Array[String]:
	var out: Array[String] = []
	for id in gs.combat.ids():
		var m: Dictionary = gs.combat.monsters[id]
		var e: Dictionary = db.combat.enemies[m["type"]]
		out.append("  %-4s %-10s %2d/%-2d %-8s %s %d,%d  %s" % [id, e["name"], int(m["hp"]), int(e["hp"]),
				m["state"], m["area"], int(m["x"]), int(m["y"]), m["spawn"] if m["spawn"] != "" else "debug"])
	if out.is_empty():
		out.append("There are no monsters here.")
	if gs.combat.has_fight():
		out.append("In a fight%s." % (" (in danger)" if Combat.in_danger(gs) else ""))
	return out


func _spawn(args: Array) -> Array[String]:
	var out := _need_arg(args, "spawn <enemy> [dx dy]")
	if not out.is_empty():
		return out
	var offset := Vector2i(2, 0)
	if args.size() >= 3 and (args[1] as String).is_valid_int() and (args[2] as String).is_valid_int():
		offset = Vector2i(int(args[1]), int(args[2]))
	var r := Commands.spawn_monster(gs, db, args[0], gs.player.pos() + offset)
	out.append(r["error"] if r["error"] != "" else "%s (%s) appears." % [
		db.combat.enemies[args[0]]["name"], r["id"]])
	return out


func _night(night: Dictionary) -> Array[String]:
	if night.is_empty():  # refused: enemies near
		return gs.combat.lines.duplicate()
	var out: Array[String] = ["--- You are knocked out. ---" if night.get("knocked_out", false)
			else "--- You sleep. ---"]
	out.append_array(night["lines"])
	if (night["lines"] as Array).is_empty():
		out.append("The System is silent.")
	out.append("--- Day %d, %s. ---" % [gs.clock.day(), gs.clock.time_string()])
	return out


@warning_ignore("integer_division")
func _status() -> Array[String]:
	var p := gs.progression
	var awake := gs.clock.awake_minutes
	var out: Array[String] = ["Day %d, %s. Awake %dh %02dm." % [
		gs.clock.day(), gs.clock.time_string(), awake / 60, awake % 60], Hud.health(gs, db)]
	if p.classes.is_empty():
		out.append("No class. Level 0.")
	for id: String in p.classes:
		var level := p.level_of(id)
		var need := Levels.xp_to_next(level, db.rules["levels"])
		var note := "  (needs a breakthrough)" if Levels.is_blocked(p, id, db.rules["levels"]) else ""
		out.append("%s level %d  %.0f/%.0f XP%s" % [db.classes[id]["name"], level,
				float(p.classes[id]["xp"]), need, note])
	if not p.skills.is_empty():
		out.append("Skills: " + ", ".join(p.skills.map(func(s: Dictionary) -> String:
			return db.skills[s["id"]]["name"])))
	for o: Dictionary in p.offers:
		out.append("Offer: %s (%s). accept %s / decline %s" % [
			db.classes[o["class"]]["name"], o["kind"], o["class"], o["class"]])
	if not p.declined.is_empty():
		out.append("Declined: " + ", ".join(p.declined))
	if not gs.focus_tags.is_empty():
		out.append("Focus: " + ", ".join(gs.focus_tags))
	return out


func _focus(args: Array) -> Array[String]:
	var tags := [] if args == ["clear"] else args
	var err := Commands.set_focus(gs, db, tags)
	var out: Array[String] = []
	if err != "":
		out.append(err)
	elif gs.focus_tags.is_empty():
		out.append("Focus cleared.")
	else:
		out.append("Focus: " + ", ".join(gs.focus_tags))
	return out


func _pools() -> Array[String]:
	var ids: Array = gs.progression.pools.keys()
	ids.sort_custom(func(a: String, b: String) -> bool:
		return ClassSystem.readiness(gs, db, a) > ClassSystem.readiness(gs, db, b))
	var out: Array[String] = []
	for id: String in ids:
		out.append("  %-12s %7.1f / %-5.0f %s" % [id, float(gs.progression.pools[id]),
				float(db.classes[id]["offer_threshold"]),
				"declined" if gs.progression.declined.has(id) else ""])
	if out.is_empty():
		out.append("All pools are empty. Pools fill at night.")
	return out


func _flag(args: Array) -> Array[String]:
	var out := _need_arg(args, "flag <key> [value] / flag <key> off")
	if not out.is_empty():
		return out
	var value: Variant = true
	if args.size() > 1:
		value = false if args[1] == "off" else _value(args[1])
	Commands.set_flag(gs, args[0], value)
	out.append("%s = %s" % [args[0], gs.flags[args[0]]] if gs.flags.has(args[0]) else "%s cleared." % args[0])
	return out


func _history() -> Array[String]:
	var out: Array[String] = []
	for h: Dictionary in gs.world.history:
		var roles: Dictionary = h["roles"]
		var who := ", ".join(roles.keys().map(func(r: String) -> String: return "%s=%s" % [r, roles[r]]))
		var line := "D%d  %-11s %s" % [int(h["day"]), h["outcome"], h["event"]]
		if h.has("via"):
			line += " → " + h["via"]
		if who != "":
			line += "  (%s)" % who
		if h.has("reason"):
			line += "  [%s]" % h["reason"]
		out.append(line)
	if out.is_empty():
		out.append("Nothing has happened yet.")
	out.append("Drift %.2f." % gs.world.drift)
	return out


func _need_arg(args: Array, usage: String) -> Array[String]:
	var out: Array[String] = []
	if args.is_empty():
		out.append("Usage: " + usage)
	return out


static func _value(text: String) -> Variant:
	if text.is_valid_int():
		return int(text)
	if text.is_valid_float():
		return float(text)
	return text


@warning_ignore("integer_division")
static func _time_of(rec: Dictionary) -> String:
	var m := int(rec["minute"])
	return "D%d %02d:%02d" % [int(rec["day"]), m / 60, m % 60]
