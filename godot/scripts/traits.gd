class_name Traits
extends RefCounted
## Every champion is an individual: a temperament trait (one strength, one weakness, like a
## Pokémon nature) on top of its species' scaling curve. Early scalers hit hard at low levels and
## fade; late scalers start soft and take over in the later cups.

# Multipliers: hp, attack (basic + ability damage), potency (ability strength incl. heals/shields),
# cd (ability cooldowns, <1 = faster), haste (attack speed), speed (movement), armor (flat), scale (curve shift).
const TRAITS := {
	"Courageous": {"hp": 1.14, "potency": 0.90, "cd": 1.06, "up": "+14% health", "down": "-10% ability strength, slower skills"},
	"Shy":        {"potency": 1.14, "cd": 0.92, "attack": 0.88, "up": "+14% ability strength, faster skills", "down": "-12% damage"},
	"Ferocious":  {"attack": 1.12, "hp": 0.90, "up": "+12% damage", "down": "-10% health"},
	"Stoic":      {"armor": 0.05, "hp": 1.05, "speed": 0.88, "up": "+5 armor, +5% health", "down": "-12% move speed"},
	"Swift":      {"speed": 1.15, "haste": 1.08, "hp": 0.92, "up": "+15% move, +8% attack speed", "down": "-8% health"},
	"Cunning":    {"cd": 0.86, "attack": 0.92, "up": "14% faster skills", "down": "-8% damage"},
	"Reckless":   {"attack": 1.10, "haste": 1.06, "armor": -0.05, "up": "+10% damage, +6% attack speed", "down": "-5 armor"},
	"Gentle":     {"potency": 1.16, "attack": 0.90, "up": "+16% ability strength", "down": "-10% damage"},
	"Proud":      {"hp": 1.08, "attack": 1.08, "cd": 1.12, "up": "+8% health and damage", "down": "12% slower skills"},
	"Patient":    {"scale": 2.0, "up": "Scales much harder late", "down": "Weaker in the early cups"},
	"Eager":      {"scale": -2.0, "up": "Strong from the first cup", "down": "Falls off late"},
	"Steadfast":  {"hp": 1.07, "armor": 0.03, "haste": 0.94, "up": "+7% health, +3 armor", "down": "-6% attack speed"},
}
const ORDER := ["Courageous", "Shy", "Ferocious", "Stoic", "Swift", "Cunning", "Reckless", "Gentle", "Proud", "Patient", "Eager", "Steadfast"]

# Species identity: scaling score (1 = explosive early, 10 = hyper late), the role it is perfect for,
# and the two temperaments that suit it best.
const SPECIES := {
	"jackalope":   {"score": 3, "calling": "Early-game skirmish carry", "ideal": ["Swift", "Ferocious"]},
	"zaratan":     {"score": 5, "calling": "Unbreakable anchor", "ideal": ["Courageous", "Stoic"]},
	"hydra":       {"score": 8, "calling": "Late-game regenerating bruiser", "ideal": ["Patient", "Proud"]},
	"cerberus":    {"score": 4, "calling": "Early lockdown warden", "ideal": ["Courageous", "Eager"]},
	"phoenix":     {"score": 9, "calling": "Hyper-scaling fire caster", "ideal": ["Patient", "Shy"]},
	"thunderbird": {"score": 7, "calling": "Late storm artillery", "ideal": ["Cunning", "Shy"]},
	"unicorn":     {"score": 6, "calling": "Team-sustain support", "ideal": ["Gentle", "Steadfast"]},
	"sphinx":      {"score": 8, "calling": "Late-game control engine", "ideal": ["Cunning", "Patient"]},
	"golem":       {"score": 5, "calling": "Shield-wall tank", "ideal": ["Stoic", "Courageous"]},
	"minotaur":    {"score": 2, "calling": "Opening-cup bully", "ideal": ["Ferocious", "Eager"]},
	"nemean":      {"score": 3, "calling": "Early frontline rallier", "ideal": ["Courageous", "Proud"]},
	"griffin":     {"score": 5, "calling": "Backline diver", "ideal": ["Swift", "Reckless"]},
	"kitsune":     {"score": 8, "calling": "Late trickster carry", "ideal": ["Cunning", "Patient"]},
	"kirin":       {"score": 7, "calling": "Chain-lightning caster", "ideal": ["Shy", "Cunning"]},
	"treant":      {"score": 7, "calling": "Growing healer", "ideal": ["Gentle", "Patient"]},
	"arachne":     {"score": 6, "calling": "Swarm summoner", "ideal": ["Cunning", "Proud"]},
	"troll":       {"score": 3, "calling": "Early brawler", "ideal": ["Ferocious", "Courageous"]},
	"wendigo":     {"score": 7, "calling": "Late hunger bruiser", "ideal": ["Reckless", "Patient"]},
	"owlbear":     {"score": 2, "calling": "Early mauler", "ideal": ["Ferocious", "Eager"]},
	"yeti":        {"score": 5, "calling": "Frost tank", "ideal": ["Stoic", "Steadfast"]},
	"direwolf":    {"score": 2, "calling": "Early pack skirmisher", "ideal": ["Swift", "Eager"]},
	"nekomata":    {"score": 7, "calling": "Late shadow assassin", "ideal": ["Reckless", "Cunning"]},
	"gargoyle":    {"score": 4, "calling": "Stone diver", "ideal": ["Steadfast", "Swift"]},
	"chimera":     {"score": 6, "calling": "Three-headed duelist", "ideal": ["Ferocious", "Proud"]},
	"manticore":   {"score": 8, "calling": "Late venom assassin", "ideal": ["Reckless", "Patient"]},
	"wyvern":      {"score": 5, "calling": "Venom marksman", "ideal": ["Reckless", "Swift"]},
	"harpy":       {"score": 3, "calling": "Early harrier", "ideal": ["Swift", "Eager"]},
	"salamander":  {"score": 7, "calling": "Late fire caster", "ideal": ["Shy", "Patient"]},
	"basilisk":    {"score": 6, "calling": "Petrifying controller", "ideal": ["Cunning", "Stoic"]},
	"cyclops":     {"score": 3, "calling": "Early siege artillery", "ideal": ["Proud", "Eager"]},
	"naga":        {"score": 6, "calling": "Tidal healer", "ideal": ["Gentle", "Shy"]},
	"pegasus":     {"score": 4, "calling": "Early tempo support", "ideal": ["Gentle", "Swift"]},
}

const PIVOT_LEVEL := 7.0   # curves cross here: every species is at par at level 7
const SLOPE := 0.0065

static func trait_of(hero: Dictionary) -> String:
	var t = str(hero.get("trait", ""))
	if TRAITS.has(t): return t
	# Older saves and rival rosters: a stable temperament from the champion's id.
	return ORDER[abs(hash(str(hero.get("id", "")) + "|temper")) % ORDER.size()]

static func roll(rng: RandomNumberGenerator) -> String:
	return ORDER[rng.randi_range(0, ORDER.size() - 1)]

static func info(sp: String) -> Dictionary:
	return SPECIES.get(sp, {"score": 5, "calling": "Versatile fighter", "ideal": ["Steadfast", "Proud"]})

static func score(hero: Dictionary) -> float:
	return clampf(float(info(hero.sp).score) + float(TRAITS[trait_of(hero)].get("scale", 0.0)), 1.0, 10.0)

static func scaling_type(s: float) -> String:
	return "Early" if s <= 3.5 else ("Late" if s >= 6.5 else "Steady")

## Level curve: late scalers start below par and finish above it; early scalers the reverse.
static func curve(hero: Dictionary) -> float:
	var lv = float(hero.get("level", 1))
	var d = (score(hero) - 5.5) * (lv - PIVOT_LEVEL) * SLOPE
	# Early scalers fade late, but gently: they still gain raw stats every level.
	if d < 0.0 and lv > PIVOT_LEVEL: d *= 0.6
	return clampf(1.0 + d, 0.80, 1.32)

static func mod(hero: Dictionary, key: String) -> float:
	return float(TRAITS[trait_of(hero)].get(key, 0.0 if key == "armor" else 1.0))

static func is_ideal(hero: Dictionary) -> bool:
	return trait_of(hero) in info(hero.sp).ideal

static func describe(hero: Dictionary) -> String:
	var t = TRAITS[trait_of(hero)]
	return "%s: %s · %s" % [trait_of(hero), t.up, t.down]

static func scaling_text(sp: String) -> String:
	var s = float(info(sp).score)
	return "%s scaler · %d/10" % [scaling_type(s), int(s)]
