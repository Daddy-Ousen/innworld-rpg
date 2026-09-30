## The player's mana (M17.5, ADR 0027). MP is kept between fights like HP: it
## comes back 1 per `tactical.mp.regen_minutes` of awake world time (Mana.tick)
## and a night's rest refills it (Mana.refill, Combat.night). The max comes
## from Stats.max_mp; PlayerState.mp stores -1 for full.
class_name Mana
extends RefCounted


static func rules(db: DataDb) -> Dictionary:
	return db.rules["combat"].get("tactical", {}).get("mp", {})


## Current MP.
static func current(gs: GameState, db: DataDb) -> int:
	var most := Stats.max_mp(gs, db)
	return most if gs.player.mp < 0 else mini(gs.player.mp, most)


## Sets MP, clamped to 0..max. Full is stored as -1 (and clears the regen clock).
static func set_mp(gs: GameState, db: DataDb, value: int) -> void:
	if value >= Stats.max_mp(gs, db):
		gs.player.mp = -1
		gs.player.mp_minutes = 0
	else:
		gs.player.mp = maxi(value, 0)


## Spends `amount` MP. False (nothing changes) if there is not enough.
static func spend(gs: GameState, db: DataDb, amount: int) -> bool:
	var cur := current(gs, db)
	if amount > cur:
		return false
	set_mp(gs, db, cur - amount)
	return true


## Awake time passes: 1 MP per regen_minutes. The rest of a step is kept in
## `mp_minutes`, so short trips still count. Does nothing when MP is full.
static func tick(gs: GameState, db: DataDb, minutes: int) -> void:
	if minutes <= 0:
		return
	var cur := current(gs, db)
	if cur >= Stats.max_mp(gs, db):
		gs.player.mp_minutes = 0
		return
	var per := maxi(int(rules(db).get("regen_minutes", 10)), 1)
	var total := gs.player.mp_minutes + minutes
	@warning_ignore("integer_division")
	var gain := total / per
	gs.player.mp_minutes = total % per
	if gain > 0:
		set_mp(gs, db, cur + gain)


## A rest: MP rises to `share` of the max (never lowers it).
static func refill(gs: GameState, db: DataDb, share: float) -> void:
	var target := ceili(Stats.max_mp(gs, db) * clampf(share, 0.0, 1.0))
	set_mp(gs, db, maxi(current(gs, db), target))
	gs.player.mp_minutes = 0
