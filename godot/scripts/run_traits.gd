class_name RunTraits
extends RefCounted
## Run traits: auto-chess style synergies built from what each creature actually is.
## Every species has tags on three axes: its KIN (Avian, Ursine, Feline…), its ELEMENT (Fire,
## Frost, Storm…) and its CLASS (Bruiser, Guardian, Hunter…, from its combat role). The Owlbear
## is Avian, Ursine and a Bruiser; the Phoenix is Avian, Fire, Spirit and a Mystic.
##
## Each dungeon run is fresh in two ways:
##   * only some traits are awakened (every species keeps at least two, at most three);
##   * every awakened trait rolls one of two flavours (Avian is Skyborne one run, Raptors the next).
## Field different champions that share a trait to reach its thresholds. Each species counts
## once, and Trait Emblem relics add one.

const AWAKEN := 14            # traits awakened per run (of 25)
const MIN_TAGS := 2
const MAX_TAGS := 3
const KIND_COLOR := {"kin": "e8c27a", "element": "8fd7ff", "class": "c8ff9d"}

## Each flavour: [name, [[scope, bonus, text], [scope, bonus, text]]] for its two thresholds.
## scope "holders" boosts champions with the trait; "team" boosts the whole squad.
const TRAITS := {
 # ---------------------------------------------------------------- Kin
 "avian": {"name": "Avian", "kind": "kin", "color": "9fd8ff", "text": "Creatures of the open sky.",
  "members": ["griffin", "harpy", "phoenix", "thunderbird", "owlbear", "pegasus", "sphinx", "gargoyle"],
  "flavours": [["Skyborne", [["holders", {"dodge": 0.10, "speed": 0.08}, "Avians gain 10% dodge and +8% Mana"], ["holders", {"dodge": 0.20, "speed": 0.15}, "Avians gain 20% dodge and +15% Mana"]]],
               ["Raptors", [["holders", {"crit": 0.12}, "Avians gain 12% critical chance"], ["holders", {"crit": 0.24, "attack": 0.08}, "Avians gain 24% critical chance and +8% AD"]]]]},
 "ursine": {"name": "Ursine", "kind": "kin", "color": "c89a6a", "text": "Bears and great shaggy brutes.",
  "members": ["owlbear", "yeti", "troll", "wendigo"],
  "flavours": [["Thick Hide", [["holders", {"hp": 0.15}, "Ursines gain +15% HP"], ["holders", {"hp": 0.32, "armor": 0.03}, "Ursines gain +32% HP and +5 Resistance"]]],
               ["Mauling", [["holders", {"attack": 0.12}, "Ursines gain +12% AD"], ["holders", {"attack": 0.24, "lifesteal": 0.06}, "Ursines gain +24% AD and 6% lifesteal"]]]]},
 "canine": {"name": "Canine", "kind": "kin", "color": "d8c0a0", "text": "Wolves, hounds and foxes. They hunt together.",
  "members": ["direwolf", "cerberus", "kitsune"],
  "flavours": [["Pack", [["team", {"haste": 0.06}, "Your team gains +6% AS"], ["team", {"haste": 0.14}, "Your team gains +14% AS"]]],
               ["Howl", [["holders", {"attack": 0.12}, "Canines gain +12% AD"], ["holders", {"attack": 0.25, "speed": 0.08}, "Canines gain +25% AD and +8% Mana"]]]]},
 "feline": {"name": "Feline", "kind": "kin", "color": "ffcf7a", "text": "Lions, cats and things with too many lives.",
  "members": ["nemean", "manticore", "nekomata", "sphinx", "chimera"],
  "flavours": [["Pounce", [["holders", {"crit": 0.15}, "Felines gain 15% critical chance"], ["holders", {"crit": 0.28, "haste": 0.08}, "Felines gain 28% critical chance and +8% AS"]]],
               ["Nine Lives", [["holders", {"hp": 0.10}, "Felines gain +10% HP"], ["holders", {"hp": 0.10, "grant": ["phoenixember"]}, "Felines rise once per fight at 25% HP"]]]]},
 "scaled": {"name": "Scaled", "kind": "kin", "color": "7fc8a0", "text": "Serpents, lizards and shelled things.",
  "members": ["hydra", "naga", "basilisk", "salamander", "wyvern", "zaratan"],
  "flavours": [["Scales", [["holders", {"armor": 0.04}, "Scaled gain +6 Resistance"], ["holders", {"armor": 0.08, "hp": 0.08}, "Scaled gain +13 Resistance and +8% HP"]]],
               ["Coldblood", [["holders", {"regen": 0.008}, "Scaled regenerate 0.8% HP per second"], ["holders", {"regen": 0.016}, "Scaled regenerate 1.6% HP per second"]]]]},
 "draconic": {"name": "Draconic", "kind": "kin", "color": "ff8a6a", "text": "Dragon blood runs in them.",
  "members": ["wyvern", "hydra", "chimera", "salamander"],
  "flavours": [["Dragonblood", [["holders", {"power": 0.15}, "Draconics gain +15% AP"], ["holders", {"power": 0.30}, "Draconics gain +30% AP"]]],
               ["Wyrmscale", [["holders", {"hp": 0.12, "armor": 0.03}, "Draconics gain +12% HP and +5 Resistance"], ["holders", {"hp": 0.24, "armor": 0.06}, "Draconics gain +24% HP and +10 Resistance"]]]]},
 "hoofed": {"name": "Hoofed", "kind": "kin", "color": "e0d0b0", "text": "Horns, hooves and antlers.",
  "members": ["unicorn", "pegasus", "kirin", "minotaur", "jackalope"],
  "flavours": [["Stampede", [["holders", {"speed": 0.10, "attack": 0.06}, "Hoofed gain +10% Mana and +6% AD"], ["holders", {"speed": 0.15, "attack": 0.16}, "Hoofed gain +15% Mana and +16% AD"]]],
               ["Gore", [["holders", {"crit": 0.10}, "Hoofed gain 10% critical chance"], ["holders", {"crit": 0.20, "attack": 0.10}, "Hoofed gain 20% critical chance and +10% AD"]]]]},
 "stoneborn": {"name": "Stoneborn", "kind": "kin", "color": "b0b0c0", "text": "Hewn, not born.",
  "members": ["golem", "gargoyle", "zaratan"],
  "flavours": [["Bedrock", [["holders", {"armor": 0.05}, "Stoneborn gain +8 Resistance"], ["holders", {"armor": 0.10, "tenacity": 0.25}, "Stoneborn gain +16 Resistance and 25% tenacity"]]],
               ["Unbreakable", [["holders", {"shield": 0.15}, "Stoneborn start each fight with a 15% HP shield"], ["holders", {"shield": 0.28}, "Stoneborn start each fight with a 28% HP shield"]]]]},
 "giant": {"name": "Giant", "kind": "kin", "color": "c8a888", "text": "Big enough to shake the floor.",
  "members": ["cyclops", "troll", "yeti", "minotaur"],
  "flavours": [["Colossal", [["holders", {"hp": 0.18}, "Giants gain +18% HP"], ["holders", {"hp": 0.35}, "Giants gain +35% HP"]]],
               ["Earthshaker", [["holders", {"attack": 0.12}, "Giants gain +12% AD"], ["holders", {"attack": 0.25, "armor": 0.03}, "Giants gain +25% AD and +5 Resistance"]]]]},
 "sylvan": {"name": "Sylvan", "kind": "kin", "color": "8fe08a", "text": "Children of the old forests.",
  "members": ["treant", "unicorn", "jackalope", "kitsune", "pegasus"],
  "flavours": [["Bloom", [["team", {"regen": 0.006}, "Your team regenerates 0.6% HP per second"], ["team", {"regen": 0.012}, "Your team regenerates 1.2% HP per second"]]],
               ["Fae Luck", [["holders", {"dodge": 0.10}, "Sylvans gain 10% dodge"], ["holders", {"dodge": 0.18, "crit": 0.10}, "Sylvans gain 18% dodge and 10% critical chance"]]]]},
 "venomous": {"name": "Venomous", "kind": "kin", "color": "a6e05a", "text": "Stingers, fangs and poison glands.",
  "members": ["arachne", "manticore", "basilisk", "wyvern", "naga"],
  "flavours": [["Toxins", [["holders", {"crit": 0.12}, "Venomous gain 12% critical chance"], ["holders", {"crit": 0.22, "attack": 0.10}, "Venomous gain 22% critical chance and +10% AD"]]],
               ["Paralytic", [["holders", {"power": 0.12}, "Venomous gain +12% AP"], ["holders", {"power": 0.24, "haste": 0.08}, "Venomous gain +24% AP and +8% AS"]]]]},
 "spirit": {"name": "Spirit", "kind": "kin", "color": "e0c8ff", "text": "Half here, half somewhere else.",
  "members": ["wendigo", "nekomata", "kitsune", "phoenix"],
  "flavours": [["Ethereal", [["holders", {"dodge": 0.12}, "Spirits gain 12% dodge"], ["holders", {"dodge": 0.22}, "Spirits gain 22% dodge"]]],
               ["Undying", [["holders", {"hp": 0.08}, "Spirits gain +8% HP"], ["holders", {"hp": 0.08, "grant": ["phoenixember"]}, "Spirits rise once per fight at 25% HP"]]]]},
 # ---------------------------------------------------------------- Element
 "fire": {"name": "Fire", "kind": "element", "color": "ff8a4a", "text": "They burn.",
  "members": ["phoenix", "salamander", "cerberus", "chimera"],
  "flavours": [["Inferno", [["holders", {"power": 0.15}, "Fire champions gain +15% AP"], ["holders", {"power": 0.30}, "Fire champions gain +30% AP"]]],
               ["Kindled", [["holders", {"attack": 0.10}, "Fire champions gain +10% AD"], ["team", {"attack": 0.12}, "Your team gains +12% AD"]]]]},
 "frost": {"name": "Frost", "kind": "element", "color": "bfe8ff", "text": "Cold to the bone.",
  "members": ["yeti", "wendigo", "kirin"],
  "flavours": [["Permafrost", [["holders", {"armor": 0.05, "tenacity": 0.15}, "Frost champions gain +8 Resistance and 15% tenacity"], ["holders", {"armor": 0.10, "tenacity": 0.30}, "Frost champions gain +16 Resistance and 30% tenacity"]]],
               ["Icebound", [["holders", {"hp": 0.12}, "Frost champions gain +12% HP"], ["holders", {"hp": 0.25}, "Frost champions gain +25% HP"]]]]},
 "storm": {"name": "Storm", "kind": "element", "color": "fff08a", "text": "Wind and lightning.",
  "members": ["thunderbird", "kirin", "griffin", "harpy"],
  "flavours": [["Thunderstruck", [["holders", {"haste": 0.10}, "Storm champions gain +10% AS"], ["holders", {"haste": 0.22}, "Storm champions gain +22% AS"]]],
               ["Static", [["holders", {"power": 0.12}, "Storm champions gain +12% AP"], ["holders", {"power": 0.24, "cd": 0.7}, "Storm champions gain +24% AP and cast their signature 30% sooner"]]]]},
 "tide": {"name": "Tide", "kind": "element", "color": "6ac8e8", "text": "Salt water and deep currents.",
  "members": ["naga", "zaratan", "hydra"],
  "flavours": [["Tidal", [["holders", {"regen": 0.008}, "Tide champions regenerate 0.8% HP per second"], ["holders", {"regen": 0.016}, "Tide champions regenerate 1.6% HP per second"]]],
               ["Undertow", [["holders", {"shield": 0.12}, "Tide champions start each fight with a 12% HP shield"], ["team", {"shield": 0.15}, "Your team starts each fight with a 15% HP shield"]]]]},
 "earth": {"name": "Earth", "kind": "element", "color": "c8b088", "text": "Stone, sand and the deep earth.",
  "members": ["golem", "gargoyle", "cyclops", "basilisk", "zaratan"],
  "flavours": [["Quake", [["holders", {"attack": 0.10}, "Earth champions gain +10% AD"], ["holders", {"attack": 0.20, "armor": 0.03}, "Earth champions gain +20% AD and +5 Resistance"]]],
               ["Bulwark", [["holders", {"armor": 0.04}, "Earth champions gain +6 Resistance"], ["team", {"armor": 0.04}, "Your team gains +6 Resistance"]]]]},
 "radiant": {"name": "Radiant", "kind": "element", "color": "ffe8a0", "text": "Touched by old light.",
  "members": ["unicorn", "pegasus", "sphinx", "kirin", "nemean"],
  "flavours": [["Halo", [["team", {"shield": 0.08}, "Your team starts each fight with an 8% HP shield"], ["team", {"shield": 0.16}, "Your team starts each fight with a 16% HP shield"]]],
               ["Sunlit", [["holders", {"power": 0.12}, "Radiant champions gain +12% AP"], ["holders", {"power": 0.25}, "Radiant champions gain +25% AP"]]]]},
 "shadow": {"name": "Shadow", "kind": "element", "color": "b9a2ff", "text": "Darkness given teeth.",
  "members": ["nekomata", "manticore", "arachne", "kitsune", "gargoyle"],
  "flavours": [["Umbral", [["holders", {"crit": 0.15}, "Shadow champions gain 15% critical chance"], ["holders", {"crit": 0.28}, "Shadow champions gain 28% critical chance"]]],
               ["Veil", [["holders", {"dodge": 0.12}, "Shadow champions gain 12% dodge"], ["holders", {"dodge": 0.24}, "Shadow champions gain 24% dodge"]]]]},
 # ---------------------------------------------------------------- Class (from combat role)
 "bruiser": {"name": "Bruiser", "kind": "class", "color": "ff9a7a", "text": "Front-line fighters who trade blows.",
  "members": ["minotaur", "troll", "wendigo", "owlbear", "hydra", "chimera"],
  "flavours": [["Brawlers", [["holders", {"hp": 0.12, "attack": 0.06}, "Bruisers gain +12% HP and +6% AD"], ["holders", {"hp": 0.25, "attack": 0.12}, "Bruisers gain +25% HP and +12% AD"]]],
               ["Bloodlust", [["holders", {"lifesteal": 0.06}, "Bruisers gain 6% lifesteal"], ["holders", {"lifesteal": 0.12, "attack": 0.08}, "Bruisers gain 12% lifesteal and +8% AD"]]]]},
 "guardian": {"name": "Guardian", "kind": "class", "color": "a8c8e8", "text": "Tanks and wardens who hold the line.",
  "members": ["golem", "yeti", "zaratan", "cerberus", "nemean"],
  "flavours": [["Bulwark", [["holders", {"armor": 0.05}, "Guardians gain +8 Resistance"], ["holders", {"armor": 0.10, "hp": 0.10}, "Guardians gain +16 Resistance and +10% HP"]]],
               ["Protectors", [["team", {"shield": 0.08}, "Your team starts each fight with an 8% HP shield"], ["team", {"shield": 0.15, "armor": 0.02}, "Your team starts with a 15% HP shield and +3 Resistance"]]]]},
 "hunter": {"name": "Hunter", "kind": "class", "color": "ffd36e", "text": "Skirmishers, assassins and divers.",
  "members": ["direwolf", "jackalope", "manticore", "nekomata", "griffin", "gargoyle"],
  "flavours": [["Ambush", [["holders", {"crit": 0.12}, "Hunters gain 12% critical chance"], ["holders", {"crit": 0.24, "attack": 0.08}, "Hunters gain 24% critical chance and +8% AD"]]],
               ["Swift Strikes", [["holders", {"haste": 0.10}, "Hunters gain +10% AS"], ["holders", {"haste": 0.20, "speed": 0.08}, "Hunters gain +20% AS and +8% Mana"]]]]},
 "marksman": {"name": "Marksman", "kind": "class", "color": "c8ff9d", "text": "They hit from a distance.",
  "members": ["wyvern", "harpy", "cyclops", "thunderbird"],
  "flavours": [["Deadeye", [["holders", {"attack": 0.12}, "Marksmen gain +12% AD"], ["holders", {"attack": 0.25}, "Marksmen gain +25% AD"]]],
               ["Volley", [["holders", {"haste": 0.10}, "Marksmen gain +10% AS"], ["holders", {"haste": 0.22}, "Marksmen gain +22% AS"]]]]},
 "mystic": {"name": "Mystic", "kind": "class", "color": "c8a8ff", "text": "Casters, controllers and tricksters.",
  "members": ["phoenix", "kirin", "salamander", "basilisk", "sphinx", "kitsune", "arachne"],
  "flavours": [["Arcana", [["holders", {"power": 0.15}, "Mystics gain +15% AP"], ["holders", {"power": 0.30}, "Mystics gain +30% AP"]]],
               ["Focus", [["holders", {"cd": 0.75}, "Mystics cast their signature 25% sooner"], ["holders", {"cd": 0.5, "power": 0.10}, "Mystics cast their signature twice as soon and gain +10% AP"]]]]},
 "mender": {"name": "Mender", "kind": "class", "color": "8fe0c0", "text": "Healers and supports.",
  "members": ["treant", "naga", "unicorn", "pegasus"],
  "flavours": [["Sanctuary", [["team", {"regen": 0.006}, "Your team regenerates 0.6% HP per second"], ["team", {"regen": 0.012}, "Your team regenerates 1.2% HP per second"]]],
               ["Blessed", [["team", {"hp": 0.06}, "Your team gains +6% HP"], ["team", {"hp": 0.12}, "Your team gains +12% HP"]]]]},
}

## The flavour picks of the run being shown (set whenever a run's traits are read).
static var flavour_of := {}

static func tags_of(sp: String) -> Array:
 return TRAITS.keys().filter(func(id): return sp in TRAITS[id].members)

static func roll(salt: String) -> Dictionary:
 HeroData.load_data()
 var rng = RandomNumberGenerator.new(); rng.seed = hash(salt + "|run-traits-v2")
 var ids = TRAITS.keys(); ids.sort(); shuffle(ids, rng)
 var active = ids.slice(0, AWAKEN)
 var all_species = HeroData.species.keys(); all_species.sort()
 # Every species keeps at least two awakened traits: wake one of its own if it is short.
 for sp in all_species:
  var own = tags_of(sp); own.sort(); shuffle(own, rng)
  for id in own:
   if own.filter(func(t): return t in active).size() >= MIN_TAGS: break
   if id not in active: active.append(id)
 var species = {}
 for sp in all_species:
  var mine = tags_of(sp).filter(func(t): return t in active)
  mine.sort(); shuffle(mine, rng)
  species[sp] = mine.slice(0, MAX_TAGS)
 # Traits nobody ended up holding go back to sleep.
 active = active.filter(func(id): return species.values().any(func(list): return id in list))
 active.sort_custom(func(a, b): return ["kin", "element", "class"].find(TRAITS[a].kind) < ["kin", "element", "class"].find(TRAITS[b].kind) or (TRAITS[a].kind == TRAITS[b].kind and a < b))
 var flavours = {}
 for id in active: flavours[id] = rng.randi_range(0, TRAITS[id].flavours.size() - 1)
 flavour_of = flavours
 return {"version": 2, "active": active, "species": species, "flavour": flavours}

static func shuffle(list: Array, rng: RandomNumberGenerator) -> void:
 for i in range(list.size() - 1, 0, -1):
  var j = rng.randi_range(0, i); var tmp = list[i]; list[i] = list[j]; list[j] = tmp

static func data(c: Campaign) -> Dictionary:
 var t = c.state.get("dungeon", {}).get("traits", {})
 flavour_of = t.get("flavour", {})
 return t

static func of(c: Campaign, sp: String) -> Array:
 return data(c).get("species", {}).get(sp, [])

## A trait as this run has it: name, flavour, colour and tiers.
static func info(id: String) -> Dictionary:
 if not TRAITS.has(id): return {"name": id.capitalize(), "flavour": "", "kind": "kin", "color": "ffffff", "text": "", "tiers": [], "members": []}
 var t = TRAITS[id]; var f = t.flavours[clampi(int(flavour_of.get(id, 0)), 0, t.flavours.size() - 1)]
 return {"name": t.name, "flavour": f[0], "kind": t.kind, "color": t.color, "text": t.text, "tiers": f[1], "members": t.members}

## Small families light up at 2 and 3; larger ones at 2 and 4.
static func thresholds(id: String) -> Array:
 return [2, 3] if TRAITS.get(id, {}).get("members", []).size() <= 4 else [2, 4]

static func tier_of(id: String, n: int) -> int:
 var reached = -1; var th = thresholds(id)
 for i in range(th.size()):
  if n >= th[i]: reached = i
 return reached

## Species-distinct count for each trait, plus emblem relics.
static func counts(c: Campaign, heroes: Array) -> Dictionary:
 var seen = {}; var out = {}
 for h in heroes:
  if seen.has(h.sp): continue
  seen[h.sp] = true
  for t in of(c, h.sp): out[t] = int(out.get(t, 0)) + 1
 for t in Relics.emblems(c): out[t] = int(out.get(t, 0)) + 1
 return out

## Combat modifiers the fielded squad has earned.
static func mods(c: Campaign, heroes: Array) -> Array:
 var out = []; var n = counts(c, heroes)
 for id in n:
  var info = info(id)
  var k = tier_of(id, int(n[id]))
  if k < 0 or info.tiers.size() <= k: continue
  var t = info.tiers[k]
  var m = t[1].duplicate(true)
  if t[0] == "holders": m.filter = {"species": heroes.filter(func(h): return id in of(c, h.sp)).map(func(h): return h.sp)}
  m.source = "trait:" + id
  out.append(m)
 return out

static func summary(c: Campaign, heroes: Array) -> Array:
 var n = counts(c, heroes); var rows = []
 for id in data(c).get("active", []):
  rows.append({"id": id, "count": int(n.get(id, 0)), "tier": tier_of(id, int(n.get(id, 0)))})
 rows.sort_custom(func(a, b): return a.tier > b.tier or (a.tier == b.tier and a.count > b.count))
 return rows

static func next_threshold(id: String, n: int) -> int:
 for th in thresholds(id):
  if n < th: return th
 return thresholds(id)[-1]

static func tag_text(c: Campaign, sp: String) -> String:
 return " · ".join(of(c, sp).map(func(t): return info(t).name))

static func tooltip(id: String) -> String:
 var t = info(id)
 var lines = ["%s · %s" % [t.name, t.flavour], t.text]
 var th = thresholds(id)
 for i in range(t.tiers.size()): lines.append("(%d) %s" % [th[i], t.tiers[i][2]])
 return "\n".join(lines)
