class_name Relics
extends RefCounted
## Relics: passive bonuses that last the whole dungeon run. Elites, treasure, events and Wardens
## offer one of three. Most apply combat modifiers to the player's squad at the start of every
## fight; a few change the run itself (gold, XP, lives, campfires). Modifier keys (all optional):
##   hp / attack / power / haste / speed   +fraction (0.10 = +10%)
##   armor   +flat armor            crit / dodge / lifesteal / tenacity   +fraction
##   shield  opening shield as a fraction of max health      regen  health per second (fraction)
##   cd      multiplies the first signature cast's wait     grant  item behaviours to borrow
##   filter  {"line": "Front"} / {"species": [...]} / {"headliner": true}

const RELICS := {
 # Common
 "whetstone":     {"name": "Whetstone", "rarity": "Common", "art": "maul", "text": "+8% damage.", "mods": [{"attack": 0.08}]},
 "giants_belt":   {"name": "Giant's Belt", "rarity": "Common", "art": "vigor", "text": "+10% health.", "mods": [{"hp": 0.10}]},
 "war_drum":      {"name": "War Drum", "rarity": "Common", "art": "rally", "text": "+8% attack speed.", "mods": [{"haste": 0.08}]},
 "sage_lantern":  {"name": "Sage's Lantern", "rarity": "Common", "art": "radiance", "text": "+12% ability power.", "mods": [{"power": 0.12}]},
 "feather_charm": {"name": "Feather Charm", "rarity": "Common", "art": "tailwind", "text": "8% dodge.", "mods": [{"dodge": 0.08}]},
 "iron_banner":   {"name": "Iron Banner", "rarity": "Common", "art": "bulwark", "text": "Front line: +5 armor and +8% health.", "mods": [{"armor": 0.05, "hp": 0.08, "filter": {"line": "Front"}}]},
 "hunters_eye":   {"name": "Hunter's Eye", "rarity": "Common", "art": "focus", "text": "Back line: +14% damage.", "mods": [{"attack": 0.14, "filter": {"line": "Back"}}]},
 "shadow_dagger": {"name": "Shadow Dagger", "rarity": "Common", "art": "ambush", "text": "Flankers: 15% critical chance.", "mods": [{"crit": 0.15, "filter": {"line": "Flank"}}]},
 "aegis_sigil":   {"name": "Aegis Sigil", "rarity": "Common", "art": "ward", "text": "Start every fight with a shield worth 12% of max health.", "mods": [{"shield": 0.12}]},
 "swift_boots":   {"name": "Swift Boots", "rarity": "Common", "art": "gust", "text": "+12% move speed and +4% attack speed.", "mods": [{"speed": 0.12, "haste": 0.04}]},
 "lucky_coin":    {"name": "Lucky Coin", "rarity": "Common", "art": "riddle", "text": "+40 gold after every win.", "gold_win": 40},
 "scholars_tome": {"name": "Scholar's Tome", "rarity": "Common", "art": "arcanist", "text": "+30% XP from fights.", "xp": 0.30},
 # Rare
 "vampiric_chalice": {"name": "Vampiric Chalice", "rarity": "Rare", "art": "drain", "text": "8% lifesteal.", "mods": [{"lifesteal": 0.08}]},
 "hourglass_shard":  {"name": "Hourglass Shard", "rarity": "Rare", "art": "chain", "text": "Signatures are ready twice as fast at the start of a fight.", "mods": [{"cd": 0.5}]},
 "headliner_crown":  {"name": "Headliner's Crown", "rarity": "Rare", "art": "prideroar", "text": "Your headliner gains +22% health and damage.", "mods": [{"hp": 0.22, "attack": 0.22, "filter": {"headliner": true}}]},
 "stoneskin_idol":   {"name": "Stoneskin Idol", "rarity": "Rare", "art": "shellup", "text": "30% tenacity and +3 armor.", "mods": [{"tenacity": 0.30, "armor": 0.03}]},
 "blood_pact":       {"name": "Blood Pact", "rarity": "Rare", "art": "hunger", "text": "+18% damage, but -8% health.", "mods": [{"attack": 0.18, "hp": -0.08}]},
 "glass_lens":       {"name": "Glass Lens", "rarity": "Rare", "art": "beam", "text": "+22% ability power, but -8% health.", "mods": [{"power": 0.22, "hp": -0.08}]},
 "bulwark_charm":    {"name": "Bulwark Charm", "rarity": "Rare", "art": "guardian", "text": "Front line: shield of 24% max health the first time they drop below half.", "mods": [{"grant": ["bastion"], "filter": {"line": "Front"}}]},
 "heartstone":       {"name": "Heartstone", "rarity": "Rare", "art": "renew", "text": "+1 maximum life (and one restored).", "max_lives": 1},
 "trait_emblem":     {"name": "Trait Emblem", "rarity": "Rare", "art": "summons", "text": "Counts as one extra champion for a run trait."},
 # Warden relics
 "ember_heart":    {"name": "Ember Heart", "rarity": "Boss", "art": "rebirth", "text": "Your headliner rises once per fight at 25% health.", "mods": [{"grant": ["phoenixember"], "filter": {"headliner": true}}]},
 "warlords_horn":  {"name": "Warlord's Horn", "rarity": "Boss", "art": "howl", "text": "+14% damage and attack speed. Campfires can no longer restore lives.", "mods": [{"attack": 0.14, "haste": 0.14}], "no_rest": true},
 "titan_core":     {"name": "Titan Core", "rarity": "Boss", "art": "boulder", "text": "+25% health and +4 armor, but -8% move speed.", "mods": [{"hp": 0.25, "armor": 0.04, "speed": -0.08}]},
 "abyssal_eye":    {"name": "Abyssal Eye", "rarity": "Boss", "art": "gaze", "text": "15% critical chance and 15% dodge.", "mods": [{"crit": 0.15, "dodge": 0.15}]},
 "golden_idol":    {"name": "Golden Idol", "rarity": "Boss", "art": "victory", "text": "+90 gold after every win, but -1 maximum life.", "gold_win": 90, "max_lives": -1},
 "everflame":      {"name": "Everflame Brazier", "rarity": "Boss", "art": "fire", "text": "Your team regenerates 1% health per second.", "mods": [{"regen": 0.01}]},
}

static func owned(c: Campaign) -> Array:
 return c.state.get("dungeon", {}).get("relics", [])

## "trait_emblem:wildheart" style ids carry the emblem's trait.
static func base(id: String) -> String:
 return id.split(":")[0]

static func info(id: String) -> Dictionary:
 var r = RELICS.get(base(id), {"name": id, "rarity": "Common", "art": "ward", "text": ""}).duplicate(true)
 if base(id) == "trait_emblem" and ":" in id:
  var t = RunTraits.info(id.split(":")[1])
  r.name = "%s Emblem" % t.name; r.text = "Counts as one extra champion for %s." % t.name
 return r

static func has(c: Campaign, id: String) -> bool:
 return owned(c).any(func(r): return base(r) == id)

static func total(c: Campaign, key: String) -> float:
 var s = 0.0
 for id in owned(c): s += float(info(id).get(key, 0.0))
 return s

static func emblems(c: Campaign) -> Array:
 return owned(c).filter(func(r): return base(r) == "trait_emblem" and ":" in r).map(func(r): return r.split(":")[1])

static func mods(c: Campaign) -> Array:
 var out = []
 for id in owned(c):
  for m in info(id).get("mods", []):
   var copy = m.duplicate(true); copy.source = "relic:" + base(id)
   if copy.get("filter", {}).get("headliner", false): copy.filter = {"id": c.state.get("headliner", "")}
   out.append(copy)
 return out

## Three different relics the guild does not own yet. Wardens offer their own pool.
static func offer(c: Campaign, rng: RandomNumberGenerator, rarity_pool: Array) -> Array:
 var mine = owned(c).map(func(r): return base(r))
 var pool = RELICS.keys().filter(func(id): return RELICS[id].rarity in rarity_pool and id not in mine)
 pool.sort()
 var picks = []
 while picks.size() < 3 and not pool.is_empty():
  var id = pool[rng.randi_range(0, pool.size() - 1)]; pool.erase(id)
  if id == "trait_emblem":
   var active = RunTraits.data(c).get("active", [])
   if active.is_empty(): continue
   id += ":" + str(active[rng.randi_range(0, active.size() - 1)])
  picks.append(id)
 return picks

# ------------------------------------------------------------------ Combat
static func matches(u: Dictionary, filter: Dictionary) -> bool:
 if filter.has("line") and HeroData.line(u.hero.sp) != filter.line: return false
 if filter.has("species") and u.hero.sp not in filter.species: return false
 if filter.has("id") and str(u.hero.id) != str(filter.id): return false
 return true

## Applies a list of modifiers to one fighter, right after the fight is set up.
static func apply(sim: BattleSim, u: Dictionary, list: Array) -> void:
 for m in list:
  if not matches(u, m.get("filter", {})): continue
  if m.has("hp"): u.max_hp *= 1.0 + float(m.hp); u.hp = u.max_hp
  if m.has("attack"): u.attack *= 1.0 + float(m.attack); u.attack_basic = u.get("attack_basic", u.attack) * (1.0 + float(m.attack))
  if m.has("power"): u.ability_power *= 1.0 + float(m.power); u.skill_base *= 1.0 + float(m.power)
  if m.has("haste"): u.interval /= 1.0 + float(m.haste); u.fx.base_interval = u.interval
  if m.has("speed"): u.speed *= 1.0 + float(m.speed)
  if m.has("armor"): u.armor = clampf(u.armor + float(m.armor), 0.0, 0.6)
  for k in ["crit", "dodge", "lifesteal", "tenacity"]:
   if m.has(k): u.fx[k] = minf({"crit": 0.75, "dodge": 0.5, "lifesteal": 0.4, "tenacity": 0.7}[k], float(u.fx.get(k, 0.0)) + float(m[k]))
  if m.has("cd"): u.cd *= float(m.cd)
  if m.has("regen"): u.run_regen = float(u.get("run_regen", 0.0)) + float(m.regen)
  if m.has("shield"): u.shield = minf(u.max_hp * 0.55, u.shield + u.max_hp * float(m.shield)); u.shield_time = 6.0
  for item in m.get("grant", []):
   if item not in u.forge: u.forge.append(item)
