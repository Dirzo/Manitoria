class_name StatCards
extends RefCounted
## v0.76 level-ups: three cards, each a different random stat at a random rarity. Keep one.

const KEYS := ["ad", "as", "ap", "mana", "hp", "res", "size", "crit"]
const NAMES := {"ad": "AD", "as": "AS", "ap": "AP", "mana": "Mana", "hp": "HP", "res": "Resistance", "size": "Size", "crit": "Crit"}
const LONG := {"ad": "Attack damage", "as": "Attack speed", "ap": "Ability power", "mana": "Mana gain", "hp": "Health", "res": "Resistance", "size": "Size", "crit": "Crit chance"}
const RARITIES := ["Common", "Rare", "Epic", "Legendary"]
## Value per rarity. AS and Mana are fractions (+0.05 = +5%); the rest are flat points.
const VALUES := {
	"ad": [4, 7, 11, 16], "as": [0.05, 0.09, 0.14, 0.20], "ap": [8, 14, 22, 32],
	"mana": [0.05, 0.09, 0.14, 0.20], "hp": [60, 110, 170, 250], "res": [5, 9, 14, 20],
	"size": [0.03, 0.05, 0.08, 0.12], "crit": [0.03, 0.05, 0.08, 0.12],
}
const ODDS := [0.55, 0.28, 0.13, 0.04]
const ODDS_LATE := [0.45, 0.30, 0.20, 0.05]   # level 15+
const COLORS := {"Common": "c8c8c8", "Rare": "5aa8ff", "Epic": "b77bff", "Legendary": "ffc34a"}
const REROLLS_START := 3

static func rarity(rng: RandomNumberGenerator, level: int) -> int:
	var odds = ODDS_LATE if level >= 15 else ODDS
	var r = rng.randf(); var acc = 0.0
	for i in range(odds.size()):
		acc += odds[i]
		if r < acc: return i
	return 0

static func value_text(key: String, v: float) -> String:
	return "+%d%% %s" % [roundi(v * 100), NAMES[key]] if key in ["as", "mana", "size", "crit"] else "+%d %s" % [roundi(v), NAMES[key]]

static func card(key: String, tier: int) -> Dictionary:
	var v = float(VALUES[key][tier]); var r = RARITIES[tier]
	return {"type": "stat", "key": key, "value": v, "rarity": r, "tier": tier, "name": value_text(key, v),
		"summary": r.to_upper() + " · " + value_text(key, v), "description": "%s %s: %s." % [r, LONG[key], value_text(key, v)], "bonus": 1.0}

## Three distinct stats, each at its own random rarity.
static func draw(rng: RandomNumberGenerator, level: int) -> Array:
	var pool: Array = KEYS.duplicate()
	for i in range(pool.size() - 1, 0, -1):
		var j = rng.randi_range(0, i); var t = pool[i]; pool[i] = pool[j]; pool[j] = t
	var out = []
	for k in pool.slice(0, 3): out.append(card(k, rarity(rng, level)))
	return out

static func apply(hero: Dictionary, c: Dictionary) -> void:
	if not hero.has("cards") or not (hero.cards is Dictionary): hero.cards = {}
	hero.cards[c.key] = float(hero.cards.get(c.key, 0.0)) + float(c.value)

static func total(hero: Dictionary, key: String) -> float:
	var c = hero.get("cards", {})
	return float(c.get(key, 0.0)) if c is Dictionary else 0.0

## Rivals and mobs: favour what the signature scales with, weighted by rarity.
static func auto_pick(hero: Dictionary, cards: Array) -> int:
	var keys = Signatures.build_keys(str(hero.sp))
	var best = 0; var best_score = -1.0
	for i in range(cards.size()):
		var c = cards[i]
		var score = (1.0 + c.tier) * (2.0 if c.key in keys else 1.0)
		if c.key == "hp": score *= 1.3
		if score > best_score: best_score = score; best = i
	return best

## One line with the six stats, as shown on cards and the champion view.
static func stat_line(s: Dictionary) -> String:
	return "AD %d  ·  AS %.2f  ·  AP %d  ·  Mana %d%%  ·  HP %d  ·  Resistance %d  ·  Size %.2f×  ·  Crit %d%% (%.1f×)" % [roundi(s.attack), float(s["as"]), roundi(s.ap), roundi(float(s.mana) * 100.0), roundi(s.hp), roundi(s.res), float(s.size), roundi(float(s.crit) * 100.0), float(s.crit_damage)]

## What this champion's level-up cards have added so far ("" when none).
static func picks_line(hero: Dictionary) -> String:
	var parts = []
	for k in KEYS:
		var v = total(hero, k)
		if v > 0.0: parts.append(value_text(k, v))
	return "  ·  ".join(parts)
