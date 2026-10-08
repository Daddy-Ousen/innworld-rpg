## The Voice of the World as pages (ADR 0009). Turns a night result
## (Night.run) and GameState into the pages the System dialog shows, in
## this order: collapse (or knock-out), levels and skills, local news (M6.4),
## rumors, drift warning, one page per open class offer, then the morning. Headless, so tests can check
## it. Reads state only; the dialog sends the answers as Commands.
##
## A page: {"kind", "title", "lines": Array[String], "choices": Array[String],
## "class": String}. `class` is set on offer and confirm pages only. The
## news page also has "deaths": the NPCs whose death tonight's news tells
## of (M12.5: the dialog plays a sad sting for them). A fate page has "npc". The dialog shows the
## face of `portrait_npc` beside the text (M14.7).
class_name SystemMessages
extends RefCounted

const COLLAPSE := "collapse"
const KNOCKOUT := "knockout"
const PROGRESS := "progress"
const NEWS := "news"
const RUMORS := "rumors"
const DRIFT := "drift"
const OFFER := "offer"
const CONFIRM := "confirm"
const RESULT := "result"
const MORNING := "morning"
const WELCOME := "welcome"
const FATE := "fate"

const NEXT := "next"
const ACCEPT := "accept"
const DECLINE := "decline"
const YES := "yes"
const BACK := "back"
const STRIKE := "strike"
const SPARE := "spare"

const SILENT_LINE := "The System is silent."

## The key list: the help page (H, M15.2).
const KEYS: Array[String] = [
	"WASD / arrows: walk (into a monster: attack)",
	"Space: wait (in a fight: end your turn)",
	"In a fight: click a blue tile to walk, a foe to attack",
	"Cover: a bar on a tile's edge means cover beside it (gold half, blue full). It lowers ranged hits from that side; walls block throws and spells",
	"1-9: use a Skill or spell in a fight (then click a gold foe, or a tile; Esc: cancel)",
	"B: block",
	"T: throw the held item",
	"X: drop the held item",
	"E: use or take what is next to you",
	"F: eat",
	"I: bag",
	"Z: sleep",
	"C: character",
	"J: journal",
	"L: message history",
	"H: this help",
	"Esc: menu (save, load, quit)",
	"`: debug console",
	"Touch screen: hold a finger anywhere on the left half and drag to walk (Wait is bottom left); Use, Bag, More and Menu are on the right; Back closes a panel",
	"Touch, in a fight: tap a tile to see the plan, tap it again to act; Cancel stops a walk or a Skill",
	"Options: Touch controls Auto (on a touch screen), On or Off",
]

## How to play: on the welcome page and in the journal (M6.1).
const HINTS: Array[String] = [
	"Walk with WASD or the arrow keys. E uses what is next to you.",
	"What you do all day shapes you. At night the System can offer you a class.",
	"J opens the journal. Choose a focus there: work that matches it brings that class closer.",
	"Sleep in a bed (Z). C shows your character. Esc opens the menu (save, load).",
	"The game saves itself each morning.",
]


## All pages for one night, in order. Offers come from the open offers in
## gs (tonight's and any older unanswered ones), not from the night result.
static func pages(night: Dictionary, gs: GameState, db: DataDb) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if night.get("knocked_out", false):
		out.append(knockout_page(gs, db))
	elif night.get("collapsed", false):
		out.append(page(COLLAPSE, "Collapse", [Night.COLLAPSE_LINE]))
	var progress: Array = night.get("progress", [])
	if not progress.is_empty():
		out.append(page(PROGRESS, "Levels and Skills", progress))
	var news: Array = night.get("news", [])
	if not news.is_empty():
		var p := page(NEWS, "Local News", news)
		p["deaths"] = news_deaths(night, gs, db)
		out.append(p)
	var rumors: Array = (night.get("world", []) as Array).filter(func(l: String) -> bool:
		return l != Director.UNRELIABLE_LINE)
	if not rumors.is_empty():
		out.append(page(RUMORS, "Rumors", rumors))
	if (night.get("world", []) as Array).has(Director.UNRELIABLE_LINE):
		out.append(page(DRIFT, "A Warning", [Director.UNRELIABLE_LINE]))
	out.append_array(offer_pages(gs, db))
	var morning: Array[String] = []
	if out.is_empty():
		morning.append(SILENT_LINE)
	morning.append("You wake on day %d at %s." % [Clock.player_day(gs.clock.day(), db.rules["clock"]), gs.clock.time_string()])
	out.append(page(MORNING, "Morning", morning))
	return out


## The first page of a new game (M6.1): who the player is, where they
## stand (the start's intro, M8.5), then HINTS.
static func welcome_page(start: Dictionary = {}) -> Dictionary:
	var lines: Array[String] = [
		"You are an Earther. The Great Ritual pulled you into this world last night.",
		start.get("intro", "You stand outside the east gate of Liscor, a walled city of Drakes and Gnolls."),
		"You have no class and no level.",
		"",
	]
	lines.append_array(HINTS)
	return page(WELCOME, "Welcome", lines)


## The knock-out page (M5.3): where the player woke and with how much HP.
static func knockout_page(gs: GameState, db: DataDb) -> Dictionary:
	var place := gs.player.area
	if db.maps.areas.has(place):
		var loc := Movement.location_at(gs, db)
		place = db.canon.locations.get(loc, {}).get("name", db.maps.areas[place]["name"])
	return page(KNOCKOUT, "Knocked Out", [Night.KNOCKOUT_LINE,
		"You wake at %s with %d HP." % [place, Combat.hp(gs, db)]])


## One page per open offer, in offer order.
static func offer_pages(gs: GameState, db: DataDb) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for o: Dictionary in gs.progression.offers:
		var id: String = o["class"]
		var c: Dictionary = db.classes[id]
		var lines: Array[String] = []
		if o["kind"] == ClassSystem.KIND_CONSOLIDATION:
			var from: Array = c["consolidation"]["from"]
			var best := 0
			for old: String in from:
				best = maxi(best, gs.progression.level_of(old))
			lines.append("%s can join your classes into one." % c["name"])
			lines.append("It takes the place of: %s." % ", ".join(from.map(
					func(old: String) -> String: return db.classes[old]["name"])))
			lines.append("You start it at level %d." %
					maxi(1, best - int(c["consolidation"]["level_cost"])))
		else:
			lines.append("You can gain the class %s." % c["name"])
		lines.append("If you decline, it is never offered again.")
		var p := page(OFFER, "Class Offer", lines, [ACCEPT, DECLINE])
		p["class"] = id
		out.append(p)
	return out


## The fate warning (M14.5): shown before the first attack on a major NPC. It has "npc" and
## "delay" (seconds the STRIKE choice stays off).
static func fate_page(db: DataDb, npc: String) -> Dictionary:
	var r := Brawl.rules(db)
	var p := page(FATE, String(r["fate_title"]), Brawl.fate_lines(db, npc), [STRIKE, SPARE])
	p["npc"] = npc
	p["delay"] = float(r["fate_delay"])
	return p


## The NPC whose face a page shows: its "npc" (a fate warning), else the first NPC the page's news
## tells the death of, else "".
static func portrait_npc(p: Dictionary) -> String:
	if String(p.get("npc", "")) != "":
		return p["npc"]
	var deaths: Array = p.get("deaths", [])
	return "" if deaths.is_empty() else String(deaths[0])


## The "are you sure?" page shown after Decline.
static func confirm_decline(db: DataDb, class_id: String) -> Dictionary:
	var name: String = db.classes[class_id]["name"]
	var p := page(CONFIRM, "Decline?", [
		"Decline %s?" % name,
		"This is permanent. %s will never be offered again." % name,
	], [YES, BACK])
	p["class"] = class_id
	return p


## What the System said after an accept or decline.
static func result(lines: Array) -> Dictionary:
	return page(RESULT, "The System", lines)


## False for an offer page whose offer is gone (accepting a class can
## withdraw other offers). The dialog skips such pages.
static func is_open(p: Dictionary, gs: GameState) -> bool:
	return p["kind"] != OFFER or gs.progression.has_offer(p["class"])


## The NPCs killed tonight by canon events that made local news: an
## event that ran (done, substituted or changed) with news (its own or its
## hook's) and a `kill` effect whose NPC is dead now. A role filled by
## another NPC means that NPC (as Director._apply_effects does).
static func news_deaths(night: Dictionary, gs: GameState, db: DataDb) -> Array[String]:
	var out: Array[String] = []
	for entry: Dictionary in night.get("events", []):
		if not [Director.DONE, Director.SUBSTITUTED, Director.CHANGED].has(entry.get("outcome", "")):
			continue
		var ev: Dictionary = db.canon.events.get(String(entry.get("event", "")), {})
		if String(ev.get("news", "")) == "" and not entry.has("hook"):
			continue
		var roles: Dictionary = entry.get("roles", {})
		for npc: String in ev.get("effects", {}).get("kill", []):
			var who := npc
			for name: String in roles:
				var prefer: Array = ev.get("roles", {}).get(name, {}).get("prefer", [])
				if prefer.has(npc) and roles[name] != npc and not roles.values().has(npc):
					who = roles[name]
			if not gs.world.is_alive(db.canon, who) and not out.has(who):
				out.append(who)
	return out


static func page(kind: String, title: String, lines: Array, choices: Array = [NEXT]) -> Dictionary:
	var l: Array[String] = []
	l.assign(lines)
	var c: Array[String] = []
	c.assign(choices)
	return {"kind": kind, "title": title, "lines": l, "choices": c, "class": ""}
