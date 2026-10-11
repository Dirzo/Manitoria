class_name Evolutions
extends RefCounted
## v0.76: three species-unique evolutions per champion, chosen at HeroData.EVOLVE_LEVEL.
## An evolution only changes the signature, the six stats, or adds movement. The data lives in
## Signatures.DATA[sp].evos; this class keeps the old lookup API. Keys are "<species>:<index>".

static func has(key: String) -> bool:
	return key.contains(":")

static func entry(key: String) -> Dictionary:
	if not has(key): return {}
	var sp = key.get_slice(":", 0); var i = int(key.get_slice(":", 1))
	if not Signatures.DATA.has(sp): return {}
	var list: Array = Signatures.DATA[sp].evos
	if i < 0 or i >= list.size(): return {}
	var e: Dictionary = list[i].duplicate(true)
	e.niche = e.tag
	return e

static func of(hero: Dictionary) -> Dictionary:
	return entry(str(hero.get("evolution", "")))

static func options(sp: String) -> Array:
	var out = []
	for i in range(Signatures.of(sp).evos.size()): out.append("%s:%d" % [sp, i])
	return out

## Stat modifiers. Multipliers (hp, as, ad_pct, speed) default to 1; flat ones (hp_flat, ad, res, ap, mana) to 0.
static func mod(hero: Dictionary, stat: String, default := 1.0) -> float:
	return float(of(hero).get("mods", {}).get(stat, default))

static func flat(hero: Dictionary, stat: String) -> float:
	return float(of(hero).get("mods", {}).get(stat, 0.0))

## Old perk hooks: evolutions no longer carry perks.
static func perk(_hero: Dictionary, _name: String, default = 0.0):
	return default

static func sig(_hero: Dictionary, _field: String) -> float:
	return 1.0

static func skills(_hero: Dictionary, _field: String) -> float:
	return 1.0

## Evolutions never grant a second ability.
static func grant_index(_key: String) -> int:
	return -1

static func grant_ability(_sp: String, _slot: int) -> Dictionary:
	return {}

static func text(key: String, hero: Dictionary = {}) -> String:
	var e = entry(key)
	if e.is_empty(): return ""
	if hero.is_empty(): return Signatures.fill(str(e.text), {}, {})
	var h = hero.duplicate(true); h.evolution = key
	return Signatures.fill(str(e.text), h, HeroData.stats(h))

static func info(key: String) -> Dictionary:
	var e = entry(key)
	if e.is_empty(): return {}
	return {"name": e.name, "niche": e.tag, "color": e.color, "description": text(key), "look": e.look}

## Art key for the level-up card: the signature's effect.
static func art(key: String) -> String:
	var sp = key.get_slice(":", 0)
	return str(Signatures.of(sp).fx) if Signatures.DATA.has(sp) else key

static func look(key: String) -> String:
	if key in ["ravager", "guardian", "arcanist", "ascended"]: return key
	return str(entry(key).get("look", "arcanist"))
