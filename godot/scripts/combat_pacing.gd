class_name CombatPacing
extends RefCounted
## Combat rhythm. Each class has its own cadence so a fight reads as a sequence of decisions:
## the front line opens, supports answer, casters pick their moment, flankers strike last.

# Fighters are tougher so a fight lasts long enough to read and plan around.
const HP_SCALE := 1.75
const BASIC_SCALE := 0.92
const TIME_LIMIT := 150.0
# Skills are rarer but each one matters more.
const SKILL_POWER := 1.12
# A team never starts two skills within this many seconds (except emergency heals and Legendaries).
const TEAM_SPACING := 0.9
# A four-creature squad fights harder (tuned by simulation so an elite four and a full five are even).
const ELITE_SQUAD := {"hp": 1.23, "attack": 1.20}

# Cooldown multiplier and the opening window (seconds) before the first skill, per role.
const ROLE := {
	"Tank":       {"cd": 1.4, "open": [2.0, 3.5]},
	"Warden":     {"cd": 1.45, "open": [2.5, 4.0]},
	"Bruiser":    {"cd": 1.55, "open": [3.0, 5.0]},
	"Support":    {"cd": 1.65, "open": [4.5, 6.5]},
	"Controller": {"cd": 1.8, "open": [5.0, 7.0]},
	"Summoner":   {"cd": 1.55, "open": [3.5, 5.0]},
	"Caster":     {"cd": 1.95, "open": [5.5, 8.0]},
	"Ranged":     {"cd": 1.8, "open": [5.0, 7.5]},
	"Artillery":  {"cd": 2.0, "open": [6.0, 8.5]},
	"Skirmisher": {"cd": 1.55, "open": [4.0, 6.0]},
	"Duelist":    {"cd": 1.55, "open": [4.0, 6.0]},
	"Trickster":  {"cd": 1.70, "open": [6.0, 8.0]},
	"Assassin":   {"cd": 1.85, "open": [6.5, 9.0]},
	"Diver":      {"cd": 1.80, "open": [6.0, 8.5]},
}

# Rarity: rarer skills hit much harder, and recharge a little slower so they stay an event.
const RARITY := {"Uncommon": {"power": 1.0, "cd": 1.0}, "Rare": {"power": 1.3, "cd": 1.05}, "Legendary": {"power": 1.75, "cd": 1.12}}

static func role(hero: Dictionary) -> Dictionary:
	HeroData.load_data()
	return ROLE.get(HeroData.species[hero.sp].role, {"cd": 1.5, "open": [4.0, 6.0]})

static func rarity_of(hero: Dictionary, key: String) -> String:
	return RarityStyle.for_skill(hero, "signature" if key == "signature" else "ability:" + key)

static func signature_cd(hero: Dictionary) -> float:
	return Evolutions.sig(hero, "cd") * HeroData.species[hero.sp].cd * pow(0.92, hero.signature_rank - 1) * HeroData.cooldown_factor(hero) * role(hero).cd * RARITY[rarity_of(hero, "signature")].cd

static func ability_cd(hero: Dictionary, key: String) -> float:
	var a = HeroData.learned_ability(hero.sp, int(key))
	return (1.0 if int(key) >= 12 else Evolutions.skills(hero, "cd")) * a.cooldown * pow(0.92, int(hero.learned.get(key, 1)) - 1) * HeroData.cooldown_factor(hero) * role(hero).cd * RARITY[rarity_of(hero, key)].cd

static func power(hero: Dictionary, key: String) -> float:
	var evo = Evolutions.sig(hero, "power") if key == "signature" else (Evolutions.skills(hero, "power") if key.is_valid_int() and int(key) < 12 else 1.0)
	return SKILL_POWER * RARITY[rarity_of(hero, key)].power * evo

## First-use timers: the signature comes first for front-liners; learned skills follow in a staggered order.
static func opening(hero: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var w = role(hero).open
	var first = rng.randf_range(w[0], w[1])
	var out = {"signature": first}
	var k = 0
	for key in hero.learned:
		out[key] = first + 2.2 + k * 2.6 + rng.randf_range(0.0, 1.2)
		k += 1
	return out
