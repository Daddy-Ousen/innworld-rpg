## The Voice of the World as pages (ADR 0009). Turns a night result
## (Night.run) and GameState into the pages the System dialog shows, in
## this order: collapse (or knock-out), levels and skills, local news (M6.4),
## rumors, drift warning, one page per open class offer, then the morning. Headless, so tests can check
## it. Reads state only; the dialog sends the answers as Commands.
##
## A page: {"kind", "title", "lines": Array[String], "choices": Array[String],
## "class": String}. `class` is set on offer and confirm pages only.
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

const NEXT := "next"
const ACCEPT := "accept"
const DECLINE := "decline"
const YES := "yes"
const BACK := "back"

const SILENT_LINE := "The System is silent."

## How to play: on the welcome page and in the journal (M6.1).
const HINTS: Array[String] = [
	"Walk with WASD or the arrow keys. E uses what is next to you.",
	"Every action gives XP. At night the System can offer you a class.",
	"J opens the journal. Choose a focus there: matching actions give more XP.",
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
		out.append(page(NEWS, "Local News", news))
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
	morning.append("You wake on day %d at %s." % [gs.clock.day(), gs.clock.time_string()])
	out.append(page(MORNING, "Morning", morning))
	return out


## The first page of a new game (M6.1): who the player is, then HINTS.
static func welcome_page() -> Dictionary:
	var lines: Array[String] = [
		"You are an Earther. The Great Ritual pulled you into this world last night.",
		"You stand outside the east gate of Liscor, a walled city of Drakes and Gnolls.",
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


static func page(kind: String, title: String, lines: Array, choices: Array = [NEXT]) -> Dictionary:
	var l: Array[String] = []
	l.assign(lines)
	var c: Array[String] = []
	c.assign(choices)
	return {"kind": kind, "title": title, "lines": l, "choices": c, "class": ""}
