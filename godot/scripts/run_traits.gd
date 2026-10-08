class_name RunTraits
extends RefCounted
## Run traits: auto-chess style team synergies, rolled fresh for every dungeon run. Each run draws
## eight traits from a larger pool and deals every species two of them, so the same champion can be
## a Wildheart bruiser one run and a Stormcaller the next. Field champions that share a trait to
## reach its thresholds (2 and 4). Each species counts once, and relic emblems add one.

const ACTIVE := 8
const PER_SPECIES := 2
const THRESHOLDS := [2, 4]
## Each tier: [bonus for "holders" or the whole "team", modifier, description].
const POOL := {
 "wildheart":  {"name": "Wildheart", "color": "8fe08a", "text": "Thick hides and stubborn hearts.", "tiers": [["holders", {"hp": 0.12}, "Wildhearts gain +12% health"], ["holders", {"hp": 0.28}, "Wildhearts gain +28% health"]]},
 "bloodfang":  {"name": "Bloodfang", "color": "ff7a7a", "text": "Every wound feeds them.", "tiers": [["holders", {"attack": 0.10}, "Bloodfangs gain +10% damage"], ["holders", {"attack": 0.22, "lifesteal": 0.08}, "Bloodfangs gain +22% damage and 8% lifesteal"]]},
 "stormcaller": {"name": "Stormcaller", "color": "9fd8ff", "text": "They speak and the sky answers.", "tiers": [["team", {"power": 0.08}, "Your team gains +8% ability power"], ["holders", {"power": 0.25, "cd": 0.7}, "Stormcallers gain +25% ability power and cast their signature 30% sooner"]]},
 "ironhide":   {"name": "Ironhide", "color": "c2c4d6", "text": "Scales like forged plate.", "tiers": [["holders", {"armor": 0.04}, "Ironhides gain +4 armor"], ["holders", {"armor": 0.09, "tenacity": 0.20}, "Ironhides gain +9 armor and 20% tenacity"]]},
 "swiftwing":  {"name": "Swiftwing", "color": "c8ff9d", "text": "Gone before the blow lands.", "tiers": [["holders", {"haste": 0.10}, "Swiftwings gain +10% attack speed"], ["holders", {"haste": 0.22, "speed": 0.10}, "Swiftwings gain +22% attack speed and +10% move speed"]]},
 "moonshadow": {"name": "Moonshadow", "color": "b9a2ff", "text": "Hard to see, harder to hit.", "tiers": [["holders", {"dodge": 0.12}, "Moonshadows gain 12% dodge"], ["holders", {"dodge": 0.22, "crit": 0.12}, "Moonshadows gain 22% dodge and 12% critical chance"]]},
 "sunforged":  {"name": "Sunforged", "color": "ffd36e", "text": "Warded by old light.", "tiers": [["holders", {"shield": 0.15}, "Sunforged start each fight with a 15% health shield"], ["team", {"shield": 0.18}, "Your whole team starts with an 18% health shield"]]},
 "venomkin":   {"name": "Venomkin", "color": "a6e05a", "text": "Every bite finds a weak spot.", "tiers": [["holders", {"crit": 0.12}, "Venomkin gain 12% critical chance"], ["holders", {"crit": 0.25, "attack": 0.10}, "Venomkin gain 25% critical chance and +10% damage"]]},
 "everbloom":  {"name": "Everbloom", "color": "7fe0c0", "text": "Roots that never stop mending.", "tiers": [["holders", {"regen": 0.010}, "Everblooms regenerate 1% health per second"], ["team", {"regen": 0.012}, "Your team regenerates 1.2% health per second"]]},
 "ancient":    {"name": "Ancient", "color": "e8c27a", "text": "Older than the dungeon itself.", "tiers": [["holders", {"hp": 0.08, "attack": 0.08}, "Ancients gain +8% health and damage"], ["holders", {"hp": 0.18, "attack": 0.18}, "Ancients gain +18% health and damage"]]},
 "packhunter": {"name": "Packhunter", "color": "ffb35c", "text": "Stronger together.", "tiers": [["team", {"haste": 0.06}, "Your team gains +6% attack speed"], ["holders", {"attack": 0.15, "speed": 0.10}, "Packhunters gain +15% damage and +10% move speed"]]},
 "runebound":  {"name": "Runebound", "color": "8fd7ff", "text": "Carved with forgotten glyphs.", "tiers": [["holders", {"power": 0.15}, "Runebound gain +15% ability power"], ["holders", {"power": 0.30, "hp": 0.10}, "Runebound gain +30% ability power and +10% health"]]},
 "gravebound": {"name": "Gravebound", "color": "efe6d2", "text": "Death is only a door.", "tiers": [["holders", {"hp": 0.10}, "Gravebound gain +10% health"], ["holders", {"hp": 0.10, "grant": ["phoenixember"]}, "Gravebound rise once per fight at 25% health"]]},
}

static func roll(salt: String) -> Dictionary:
 HeroData.load_data()
 var rng = RandomNumberGenerator.new(); rng.seed = hash(salt + "|run-traits")
 var ids = POOL.keys(); ids.sort()
 shuffle(ids, rng)
 var active = ids.slice(0, ACTIVE)
 var all_species = HeroData.species.keys(); all_species.sort()
 # Deal from a deck so every active trait lands on roughly the same number of species.
 var deck = []
 while deck.size() < all_species.size() * PER_SPECIES:
  var batch = active.duplicate(); shuffle(batch, rng); deck.append_array(batch)
 var species = {}
 for sp in all_species:
  var mine = []
  for i in range(deck.size()):
   if mine.size() >= PER_SPECIES: break
   if deck[i] != "" and deck[i] not in mine: mine.append(deck[i]); deck[i] = ""
  deck = deck.filter(func(v): return v != "")
  species[sp] = mine
 return {"active": active, "species": species}

static func shuffle(list: Array, rng: RandomNumberGenerator) -> void:
 for i in range(list.size() - 1, 0, -1):
  var j = rng.randi_range(0, i); var tmp = list[i]; list[i] = list[j]; list[j] = tmp

static func data(c: Campaign) -> Dictionary:
 return c.state.get("dungeon", {}).get("traits", {})

static func of(c: Campaign, sp: String) -> Array:
 return data(c).get("species", {}).get(sp, [])

static func info(id: String) -> Dictionary:
 return POOL.get(id, {"name": id.capitalize(), "color": "ffffff", "text": "", "tiers": []})

## Species-distinct count for each trait, plus emblem relics.
static func counts(c: Campaign, heroes: Array) -> Dictionary:
 var seen = {}; var out = {}
 for h in heroes:
  if seen.has(h.sp): continue
  seen[h.sp] = true
  for t in of(c, h.sp): out[t] = int(out.get(t, 0)) + 1
 for t in Relics.emblems(c): out[t] = int(out.get(t, 0)) + 1
 return out

static func tier(n: int) -> int:
 var reached = -1
 for i in range(THRESHOLDS.size()):
  if n >= THRESHOLDS[i]: reached = i
 return reached

## Combat modifiers the fielded squad has earned.
static func mods(c: Campaign, heroes: Array) -> Array:
 var out = []; var n = counts(c, heroes)
 for id in n:
  var k = tier(int(n[id]))
  if k < 0: continue
  var t = info(id).tiers[k]
  var m = t[1].duplicate(true)
  if t[0] == "holders": m.filter = {"species": heroes.filter(func(h): return id in of(c, h.sp)).map(func(h): return h.sp)}
  m.source = "trait:" + id
  out.append(m)
 return out

static func summary(c: Campaign, heroes: Array) -> Array:
 var n = counts(c, heroes); var rows = []
 for id in data(c).get("active", []):
  rows.append({"id": id, "count": int(n.get(id, 0)), "tier": tier(int(n.get(id, 0)))})
 rows.sort_custom(func(a, b): return a.tier > b.tier or (a.tier == b.tier and a.count > b.count))
 return rows

static func tag_text(c: Campaign, sp: String) -> String:
 return " · ".join(of(c, sp).map(func(t): return info(t).name))
