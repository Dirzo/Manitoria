class_name HeroData
extends RefCounted

static var species: Dictionary = {}
const FRONT = ["Tank", "Bruiser", "Warden"]
const FLANK = ["Skirmisher", "Assassin", "Diver", "Trickster", "Duelist"]
const NAMES = ["Ash", "Briar", "Cinder", "Dusk", "Ember", "Fable", "Grit", "Halo", "Iris", "Jinx", "Knell", "Lumen", "Morrow", "Nyx", "Onyx", "Pike", "Quill", "Rook", "Sable", "Thorn", "Umber", "Vale", "Wisp", "Zephyr", "Aldric", "Bramble", "Corvin", "Dagny", "Elowen", "Fenwick", "Gorm", "Hollis", "Isolde", "Jareth", "Kestrel", "Lark", "Mabry", "Nettle", "Orrin", "Pyre", "Quarry", "Rune", "Saffron", "Talon", "Ulla", "Vesper", "Wren", "Yarrow", "Alder", "Barrow", "Cobalt", "Dagger", "Ebony", "Flint", "Gale", "Hawthorn", "Ingot", "Jasper", "Kindle", "Loam", "Mist", "North", "Oriel", "Pebble", "Quartz", "Riven", "Sorrel", "Tansy", "Urchin", "Vigil", "Whisper", "Yew", "Amber", "Bastion", "Cairn", "Drift", "Echo", "Frost", "Gloam", "Harrow", "Ivy", "Juniper", "Kairo", "Lyric", "Marrow", "Nimbus", "Opal", "Puck", "Rowan", "Shale", "Tempest", "Valor", "Warden", "Xylo", "Yonder", "Zinnia", "Brisket", "Clover", "Dandelion", "Fizz", "Gumbo", "Hiccup", "Noodle", "Pip", "Scruff", "Tumble", "Waffle", "Biscuit"]
## Creature-flavoured names: a yeti is a Frezi or a Snorri, a phoenix a Solara or a Pyra.
const SPECIES_NAMES := {
 "yeti": ["Frezi", "Nuki", "Snorri", "Brrok", "Yumi", "Ploof", "Glacio", "Tundra", "Mumbo", "Krisp", "Shiver", "Bjork", "Flurry", "Pemmi", "Hoarfrost", "Sleetbeard"],
 "wendigo": ["Hollowmaw", "Skraeth", "Gaunt", "Wither", "Antlerghast", "Nethic", "Starvel", "Rimeclaw", "Mourne", "Ichor", "Pale", "Cadaver", "Vesk", "Chillgrip", "Ghast", "Ebbis"],
 "golem": ["Bouldur", "Granitor", "Pebbleton", "Slab", "Cairn", "Rubble", "Basalt", "Monolith", "Gravlok", "Obbo", "Flint", "Tor", "Quarrion", "Stonebrow", "Marbo", "Kollos"],
 "troll": ["Grubnak", "Moss", "Gorrk", "Bogwart", "Snaggle", "Mudbelly", "Thokk", "Hagrim", "Lumpo", "Brakka", "Gristle", "Ogg", "Bridgewort", "Stumpf", "Grunda"],
 "owlbear": ["Hoot", "Bramble", "Fuzzclaw", "Hootsworth", "Ruffle", "Barkhoo", "Tuftbear", "Mauler", "Owlric", "Pinecone", "Grizhoot", "Feathermaw", "Nibbs", "Bruin", "Talonpaw", "Hootch"],
 "direwolf": ["Fang", "Howl", "Grimtooth", "Ashpelt", "Lupa", "Varg", "Shadowmane", "Rend", "Skoll", "Moonbay", "Fenra", "Ghostpaw", "Ripper", "Wulfric", "Snarl", "Hati"],
 "nekomata": ["Mikan", "Kuro", "Twintail", "Nyako", "Yoru", "Shiori", "Tama", "Kage", "Suzu", "Mochi", "Hanabi", "Nekoyo", "Rin", "Yami", "Kitsuko", "Soot"],
 "gargoyle": ["Grotesk", "Cornice", "Spire", "Gargle", "Crag", "Belfry", "Stonewing", "Vigil", "Rookstone", "Gable", "Chimney", "Grimbald", "Parapet", "Rainspout", "Sculk", "Ledge"],
 "chimera": ["Trice", "Hydrix", "Manewing", "Tripla", "Gorgo", "Flamevine", "Brimbeast", "Tryx", "Chimerra", "Tarsk", "Splice", "Kimber", "Threefold", "Gnasha", "Volka", "Tangle"],
 "manticore": ["Stingrah", "Venox", "Scorpra", "Barbtail", "Mantix", "Spinejaw", "Vex", "Toxira", "Quillmaw", "Raptor", "Dread", "Skorr", "Thornlash", "Venomane", "Sabra", "Kesh"],
 "wyvern": ["Wyrmlet", "Acidra", "Gloomwing", "Skorch", "Vorrax", "Venomwyrm", "Blight", "Sludge", "Corrode", "Drakka", "Wyrrin", "Fizzle", "Tarnish", "Sizzle", "Viridax", "Bile"],
 "harpy": ["Screech", "Shrilla", "Talona", "Aello", "Celaena", "Gale", "Scrawk", "Plume", "Keening", "Shrike", "Ravena", "Ocypa", "Squall", "Kyra", "Cackle", "Swoop"],
 "salamander": ["Ember", "Sizzle", "Magmo", "Pyrrik", "Scorchy", "Cinderling", "Blaze", "Flicker", "Molten", "Ignis", "Charr", "Smoulder", "Kindle", "Slagtail", "Lavalle", "Sparky"],
 "basilisk": ["Glare", "Stonegaze", "Serpis", "Hiss", "Petra", "Medusine", "Gorgal", "Coilfang", "Sslith", "Basil", "Graveeye", "Venomgaze", "Sloth", "Marbleye", "Ssark"],
 "cyclops": ["Oculus", "Monoclus", "Boulderhurl", "Polyph", "Glaucus", "Thunderbrow", "Ogle", "Brontes", "Squint", "Arges", "Rockeye", "Lidless", "Peeper", "Steropes"],
 "naga": ["Nerissa", "Tidecoil", "Serpentina", "Mira", "Coralyn", "Ripple", "Pearl", "Marisol", "Undina", "Sirena", "Lagoon", "Kaimana", "Wavelet", "Shelly", "Thalassa"],
 "pegasus": ["Skydancer", "Zephyrine", "Cloudmane", "Aurora", "Pegs", "Starhoof", "Gust", "Nimbus", "Featherfoot", "Celeste", "Breeze", "Halcyon", "Wingbeat", "Stratus", "Glory", "Swiftwind"],
 "jackalope": ["Otis", "Hoppsworth", "Antlers", "Jackie", "Thumper", "Bramblehop", "Lopsy", "Twitch", "Bounder", "Nibbler", "Fernhop", "Dash", "Clover", "Skippit", "Juniper", "Bunbun"],
 "zaratan": ["Shellbrook", "Isleback", "Barnacle", "Terrapin", "Atollus", "Moss", "Archelon", "Leviaturt", "Driftshell", "Reefus", "Slowtide", "Kelp", "Islard", "Brineback", "Tortuga"],
 "hydra": ["Lernia", "Manyhead", "Hydrina", "Hisslings", "Venomcoil", "Regrow", "Septis", "Hydrax", "Seven", "Coilmaw", "Serpentrix", "Ladon", "Splitfang", "Murkmaw", "Twinsy", "Hissy"],
 "cerberus": ["Threeheads", "Garmr", "Blazeguard", "Hellhound", "Orthrus", "Ashmaw", "Gatewarden", "Brimstone", "Spot", "Pyrodog", "Underbark", "Grimmy", "Kerb", "Fangtrio", "Molossus"],
 "phoenix": ["Solara", "Pyra", "Ashborn", "Rekindle", "Cinderwing", "Ignatia", "Aurelia", "Flarewing", "Sunfire", "Embra", "Rebirth", "Phoebe", "Firebird", "Helia", "Kindra"],
 "thunderbird": ["Thunderclap", "Voltwing", "Stormcaller", "Skyroar", "Kaboom", "Zap", "Fulgor", "Tempest", "Boom", "Thundra", "Bolt", "Squallwing", "Crackle", "Arcwing"],
 "unicorn": ["Starlight", "Moonbeam", "Glimmer", "Sparkle", "Pearlhorn", "Twinkle", "Lumina", "Dreamer", "Prism", "Silverhorn", "Opaline", "Seraphine", "Dazzle", "Halo", "Glitter"],
 "sphinx": ["Riddleus", "Sphinxa", "Nefer", "Sandmind", "Amunet", "Enigma", "Ankh", "Sekhmet", "Ponder", "Pharos", "Akhet", "Oracle", "Riddler", "Dune", "Khafra", "Mystery"],
 "minotaur": ["Bullrog", "Asterion", "Hornbreaker", "Taurus", "Maze", "Bovric", "Goremane", "Brawn", "Stampede", "Hoofrage", "Labyrinth", "Bullock", "Minos", "Rampage", "Charger", "Moogar"],
 "nemean": ["Leo", "Goldmane", "Nemea", "Pride", "Aurex", "Lionheart", "Regal", "Sunclaw", "Rex", "Valor", "Majesty", "Kingsley", "Ironhide", "Roar"],
 "griffin": ["Talonis", "Skyclaw", "Gryphis", "Aquila", "Featherking", "Swoopclaw", "Stormbeak", "Griff", "Altair", "Beakmaw", "Highwing", "Eyrie", "Regalis", "Clawdia", "Aero", "Gryffo"],
 "kitsune": ["Kitsu", "Ninetails", "Inari", "Yuki", "Kohaku", "Foxfire", "Tamamo", "Akari", "Hoshi", "Fubuki", "Momiji", "Sora", "Kitsuko", "Hikari"],
 "kirin": ["Qilin", "Jade", "Celestine", "Lumos", "Kai", "Ryuu", "Tenshi", "Kirra", "Lanshan", "Thunderhoof", "Meiling", "Sorin", "Yushan", "Tianma"],
 "treant": ["Oakheart", "Barkley", "Rootwise", "Elderbough", "Sylvan", "Grovewarden", "Thornwood", "Mossbeard", "Timber", "Willowmere", "Ashgrove", "Fernroot", "Birchy", "Burl", "Hollowoak"],
 "arachne": ["Silkweaver", "Webba", "Spindle", "Arachna", "Weavira", "Loom", "Venomsilk", "Tarantia", "Skitter", "Widow", "Gossamer", "Threadra", "Lacey", "Spinnie"],
}

## A fitting name for this creature, stable for a given key (hero id) within a run.
static func themed_name(sp: String, key: String) -> String:
 var pool: Array = SPECIES_NAMES.get(sp, NAMES)
 return str(pool[abs(hash(key + "|" + run_salt + "|" + sp)) % pool.size()])
# Two legacy discovery IDs per species; ability_pool extends each to eight options.
# Mechanics are shared primitives; names, targeting, and combinations belong to that hero.
const DISCOVERIES = {
 "minotaur": [["Labyrinth Quake", "quake"], ["Blood of the Labyrinth", "rally"]],
 "golem": [["Fault Line", "fissure"], ["Granite Covenant", "ward"]],
 "troll": [["Boulder Barrage", "meteor"], ["Second Wind", "renew"]],
 "wendigo": [["Winter Hunger", "drain"], ["Dread of the Forest", "fear"]],
 "direwolf": [["Pack Ambush", "ambush"], ["Alpha's Challenge", "rally"]],
 "manticore": [["Venom Volley", "toxic"], ["Predator's Mark", "execute"]],
 "griffin": [["Razorwind", "gust"], ["Royal Descent", "quake"]],
 "kitsune": [["Spirit Lanterns", "wisps"], ["Moonlit Veil", "ward"]],
 "wyvern": [["Corrosive Rain", "toxic"], ["Wing Buffet", "gust"]],
 "harpy": [["Featherstorm", "barrage"], ["Siren's Lament", "silence"]],
 "phoenix": [["Solar Lance", "beam"], ["Cinder Sanctuary", "renew"]],
 "kirin": [["Thunderhead", "storm"], ["Static Prison", "frost"]],
 "basilisk": [["Obsidian Prison", "frost"], ["Venomous Wake", "toxic"]],
 "treant": [["Bramble Prison", "roots"], ["Heartwood Covenant", "ward"]],
 "naga": [["Undertow", "gust"], ["Moonwell", "renew"]],
 "unicorn": [["Astral Lance", "beam"], ["Dawn's Embrace", "ward"]],
 "cerberus": [["Gates of Hades", "fire"], ["Hellhound Pursuit", "ambush"]],
 "nemean": [["Lionheart Covenant", "ward"], ["Sovereign Challenge", "rally"]],
 "yeti": [["Avalanche", "meteor"], ["Permafrost", "frost"]],
 "zaratan": [["Tidal Quake", "quake"], ["Island Sanctuary", "renew"]],
 "owlbear": [["Rending Cyclone", "whirl"], ["Hunter's Instinct", "execute"]],
 "hydra": [["Venom of Five Heads", "toxic"], ["Undying Vigor", "renew"]],
 "chimera": [["Dragon's Breath", "fire"], ["Serpent's Coil", "roots"]],
 "gargoyle": [["Cathedral Collapse", "meteor"], ["Stonewatch", "ward"]],
 "nekomata": [["Nightfall Ambush", "ambush"], ["Soul Reaver", "drain"]],
 "jackalope": [["Briar Stampede", "fissure"], ["Lucky Foot", "rally"]],
 "cyclops": [["Mountain Breaker", "quake"], ["Unerring Eye", "beam"]],
 "thunderbird": [["Tempest Crown", "storm"], ["Skybreaker", "gust"]],
 "sphinx": [["Silence of Ages", "silence"], ["Judgment of Stars", "meteor"]],
 "pegasus": [["Dawnflight", "renew"], ["Celestial Wake", "gust"]],
 "arachne": [["Widow's Prison", "roots"], ["Venomweb", "toxic"]],
 "salamander": [["Cinder Spit", "fire"], ["Molten Lance", "beam"]]
}
const EFFECTS = {
 "brood": ["Hatch two spiderlings, up to three active, lasting 16s. AP strengthens their bites and health.", 16.0, 5.0],
 "magma": ["Erupt a molten pool for 60% skill power on impact and 35% per second for 4s, slowing foes.", 14.0, 7.0],
 "quake": ["Slam nearby enemies for 150% attack and stun for 0.8s.", 10.0, 3.0],
 "rally": ["Rally allies: +22% attack and speed for 4s, with a small shield.", 14.0, 5.5],
 "fissure": ["Crack a line through foes for 150% attack and root for 1s.", 11.0, 7.0],
 "ward": ["Shield allies in range for 22% of your maximum health for 5s.", 13.0, 5.0],
 "meteor": ["A falling projectile strikes a cluster for 180% attack and stuns.", 12.0, 7.0],
 "renew": ["Heal the three most wounded allies for 130% attack plus 8% health.", 12.0, 6.5],
 "drain": ["Strike a wounded foe for 170% attack; heal for damage dealt.", 11.0, 4.5],
 "fear": ["Dread weakens nearby enemies' damage by 25% for 4s.", 12.0, 5.0],
 "ambush": ["Leap to a wounded foe for 190% attack; gain a brief shield.", 12.0, 7.0],
 "toxic": ["Poison a cluster for 40% attack each second for 4s.", 11.0, 7.0],
 "execute": ["Strike for 140% attack, doubled against foes below 35% health.", 11.0, 4.5],
 "gust": ["A gust hits a cluster for 130% attack, pushing and slowing it.", 10.0, 6.0],
 "wisps": ["Three spirit bolts seek separate enemies for 85% attack each.", 10.0, 7.0],
 "barrage": ["Fire five bolts at the current target, each for 45% attack.", 11.0, 7.0],
 "silence": ["Deal 90% attack and silence a cluster's abilities for 2.5s.", 12.0, 7.0],
 "beam": ["A piercing lance hits every foe along its line for 180% attack.", 12.0, 9.0],
 "storm": ["Lightning strikes three different foes for 110% attack each.", 12.0, 8.0],
 "frost": ["Freeze a cluster for 0.8s and deal 110% attack.", 12.0, 7.0],
 "roots": ["Root a cluster for 1.8s and deal 100% attack.", 12.0, 7.0],
 "fire": ["Burn a cluster for 120% attack plus 30% per second for 3s.", 10.0, 6.5],
 "whirl": ["Spin through nearby foes for 200% attack and gain a shield.", 11.0, 3.0]
}

static func load_data() -> void:
 if species.is_empty():
  species = JSON.parse_string(FileAccess.get_file_as_string("res://data/species.json"))
  # v0.76: names and text come from the signature data.
  for sp in species:
   var sig = Signatures.of(sp)
   species[sp].ability_name = sig.name
   species[sp].ability_description = Signatures.fill(str(sig.text), {}, {})

static func line(sp: String) -> String:
 load_data()
 if species[sp].role in FRONT: return "Front"
 if species[sp].role in FLANK: return "Flank"
 return "Back"

static func make_hero(sp: String, id: String, nickname: String, level: int = 1) -> Dictionary:
 load_data()
 var h = {"id": id, "sp": sp, "name": nickname, "level": level, "xp": 0, "signature_rank": 1, "learned": {}, "vigor": 0, "force": 0, "slot": -1, "bouts": 0, "wins": 0, "kills": 0, "impact": 0.0, "pending": [], "history": [], "evolution": "", "rewards": [], "last_offers": [], "progression_version": PROGRESSION_VERSION, "cards": {}}
 # Every champion is rolled fresh each run: a random temperament and random stat genes.
 var rng = RandomNumberGenerator.new(); rng.seed = hash(id + "|identity|" + run_salt)
 h.trait = Traits.roll(rng)
 h.rolls = roll_stats(rng, roll_floor(sp))
 return h

# ---------------------------------------------------------------- stat genes
## Set once per run (from the campaign seed) so every new game deals different traits and rolls.
static var run_salt := ""
const ROLL_KEYS = ["hp", "attack", "armor", "haste", "speed", "potency"]
## Roll keys kept from older saves; v0.76 shows them as the six stats (armor -> Resistance, speed -> Mana).
const ROLL_NAMES = {"hp": "HP", "attack": "AD", "armor": "Resistance", "haste": "AS", "speed": "Mana", "potency": "AP"}
const ROLL_MAX = 31
## How much each stat matters to a role. Power level only rewards the rolls a role actually uses,
## so a tank with great damage rolls but poor health and armor is still a poor tank.
const ROLE_WEIGHTS = {
 "Tank": {"hp": 0.4, "armor": 0.4, "speed": 0.1, "potency": 0.1},
 "Warden": {"hp": 0.35, "armor": 0.35, "potency": 0.2, "speed": 0.1},
 "Bruiser": {"hp": 0.3, "attack": 0.3, "armor": 0.2, "haste": 0.1, "speed": 0.1},
 "Support": {"potency": 0.5, "hp": 0.2, "speed": 0.15, "armor": 0.15},
 "Caster": {"potency": 0.5, "attack": 0.2, "haste": 0.1, "hp": 0.1, "speed": 0.1},
 "Controller": {"potency": 0.45, "hp": 0.2, "attack": 0.15, "speed": 0.1, "armor": 0.1},
 "Summoner": {"potency": 0.5, "hp": 0.2, "attack": 0.15, "speed": 0.15},
 "Artillery": {"attack": 0.4, "haste": 0.3, "potency": 0.15, "hp": 0.15},
 "Ranged": {"attack": 0.4, "haste": 0.35, "speed": 0.1, "hp": 0.15},
 "Assassin": {"attack": 0.4, "haste": 0.2, "speed": 0.3, "hp": 0.1},
 "Diver": {"attack": 0.3, "speed": 0.3, "hp": 0.2, "haste": 0.2},
 "Skirmisher": {"attack": 0.3, "haste": 0.3, "speed": 0.25, "hp": 0.15},
 "Duelist": {"attack": 0.35, "haste": 0.3, "hp": 0.2, "armor": 0.15},
 "Trickster": {"potency": 0.3, "speed": 0.3, "attack": 0.25, "haste": 0.15},
}

## Rarity sets the lowest a stat can roll: headliners are never hopeless at anything.
const ROLL_FLOOR := {"Legendary": 12, "Epic": 8, "Common": 4}
## Rolls also grow as a champion levels: its role's key stats faster, the rest slower.
const GROWTH_KEY := 0.6
const GROWTH_OTHER := 0.35

## Bell-shaped rolls between the floor and 31 (two dice averaged, so extremes are rare).
static func roll_stats(rng: RandomNumberGenerator, floor_value: int = 0) -> Dictionary:
 var r = {}
 for k in ROLL_KEYS:
  var u = (rng.randf() + rng.randf()) * 0.5
  r[k] = clampi(floor_value + roundi(u * float(ROLL_MAX - floor_value)), floor_value, ROLL_MAX)
 return r

static func roll_floor(sp: String) -> int:
 return int(ROLL_FLOOR.get(League.tier(sp), 0))

## Base rolls (what the champion was born with), never below its rarity's floor.
static func rolls(hero: Dictionary) -> Dictionary:
 var r = hero.get("rolls", {})
 if not (r is Dictionary and r.size() == ROLL_KEYS.size()):
  # Older saves and generated stand-ins: stable rolls from the champion's id.
  var rng = RandomNumberGenerator.new(); rng.seed = hash(str(hero.get("id", "")) + "|rolls|" + run_salt)
  r = roll_stats(rng, roll_floor(str(hero.get("sp", ""))))
 var f = roll_floor(str(hero.get("sp", "")))
 if f > 0 and r.values().any(func(v): return int(v) < f):
  r = r.duplicate()
  for k in r: r[k] = maxi(int(r[k]), f)
 return r

## How much a stat has grown from levelling.
## v0.76: rolls no longer grow; level-up cards replace roll growth.
static func roll_growth(_hero: Dictionary, _key: String) -> int:
 return 0

## The roll as it stands now (base + growth). This is what the stats actually use.
static func roll_now(hero: Dictionary, key: String) -> int:
 return int(rolls(hero).get(key, 15)) + roll_growth(hero, key)

static func roll_norm_now(hero: Dictionary, key: String) -> float:
 return (float(roll_now(hero, key)) - 15.5) / 15.5

## -1 (worst roll) .. +1 (perfect roll)
static func roll_norm(hero: Dictionary, key: String) -> float:
 return (float(rolls(hero).get(key, 15.5)) - 15.5) / 15.5

static func roll_mult(hero: Dictionary, key: String) -> float:
 var spread = {"hp": 0.18, "attack": 0.18, "haste": 0.12, "speed": 0.10, "potency": 0.18}.get(key, 0.15)
 return 1.0 + roll_norm_now(hero, key) * spread

static func roll_total(hero: Dictionary) -> int:
 var t = 0
 for k in ROLL_KEYS: t += int(rolls(hero).get(k, 0))
 return t

static func role_weights(sp: String) -> Dictionary:
 load_data()
 var build=SkillScaling.build_weights({"sp":sp,"learned":{}})
 var weights={"hp":build.hp,"attack":build.ad,"armor":build.armor,"haste":build["as"],"speed":build.cd,"potency":build.ap}
 var total=0.0
 for value in weights.values():total+=value
 for key in weights:weights[key]/=total
 return weights

## Role fit of the rolls: -1 .. +1, only counting the stats this creature's role relies on.
## Overall fit for the role: stat rolls (70%) and temperament (30%) together.
static func fit_score(hero: Dictionary) -> float:
 var rf = roll_fit(hero)
 var f = rf * 0.7 + Traits.temper_fit(hero) * 0.3
 # GREAT needs good rolls too: temperament alone can lift a champion to GOOD, not past it.
 return minf(f, 0.34) if rf < 0.15 else f

static func roll_fit(hero: Dictionary) -> float:
 var w = role_weights(hero.sp); var t = 0.0
 for k in w: t += roll_norm(hero, k) * w[k]
 return t

## Colour for a single roll (0..31): red, orange, yellow, green, gold for perfect.
static func roll_color(v: int) -> Color:
 if v >= 30: return Color("ffd36e")
 if v >= 24: return Color("6fe08a")
 if v >= 16: return Color("d6e86a")
 if v >= 8: return Color("ffa451")
 return Color("ff5e5e")

static func roll_grade(v: int) -> String:
 if v >= 30: return "S"
 if v >= 24: return "A"
 if v >= 16: return "B"
 if v >= 8: return "C"
 return "D"

static func stats(hero: Dictionary, quality: float = 1.0) -> Dictionary:
 load_data()
 var d = species[hero.sp]
 var level = int(hero.level); var lv = float(level - 1)
 var tierf = League.stat_factor(hero.sp)   # draft tier (Legendary / Epic / Common) and per-species balance
 var curve = Traits.curve(hero)
 # v0.76: six stats. Level adds +3% base HP and +2% base AD; level-up cards add the rest.
 var base_hp = 520.0 * d.hp * tierf * quality * curve
 var base_ad = 39.6 * d.atk * tierf * quality * curve
 var base_res = clampf(0.08 + d.def * 0.09, 0.10, 0.28)
 base_res = base_res / (1.0 - base_res) * 100.0
 var hp = base_hp * (1.0 + 0.03 * lv)
 var ad = base_ad * (1.0 + 0.02 * lv)
 var aspd = d["as"] * 0.85 * (0.8 if d.role == "Artillery" else 1.0)
 var res = base_res; var ap = 100.0; var mana = 1.0
 # Birth rolls: armor roll -> Resistance, move-speed roll -> Mana, potency roll -> AP.
 hp *= roll_mult(hero, "hp"); ad *= roll_mult(hero, "attack"); aspd *= roll_mult(hero, "haste")
 res += roll_norm_now(hero, "armor") * 5.0; mana += roll_norm_now(hero, "speed") * 0.10; ap += roll_norm_now(hero, "potency") * 12.0
 # Temperament.
 hp *= Traits.mod(hero, "hp"); ad *= Traits.mod(hero, "attack"); aspd *= Traits.mod(hero, "haste")
 res += Traits.mod(hero, "armor") * ARMOR_TO_RES; ap *= Traits.mod(hero, "potency")
 mana *= Traits.mod(hero, "speed") / Traits.mod(hero, "cd")
 # Items (old fractions convert: armor -> Resistance, move speed and cooldowns -> Mana).
 var f = Forge.totals(hero)
 hp *= 1.0 + f.hp; ad *= 1.0 + f.attack; aspd *= 1.0 + f.haste; res += f.armor * ARMOR_TO_RES
 ap += f.potency * 100.0; mana += f.speed + (1.0 / maxf(0.3, f.cd) - 1.0)
 for item in Campaign.EQUIPMENT:
  if item.id not in hero.get("equipment", {}).values(): continue
  hp *= 1.0 + item.get("hp", 0.0); ad *= 1.0 + item.get("attack", 0.0); aspd *= 1.0 + item.get("haste", 0.0)
  res += item.get("armor", 0.0) * ARMOR_TO_RES; mana += item.get("speed", 0.0)
 # Evolution stat changes.
 if Evolutions.has(str(hero.get("evolution", ""))):
  hp = hp * Evolutions.mod(hero, "hp") + Evolutions.flat(hero, "hp_flat")
  ad = (ad + Evolutions.flat(hero, "ad")) * Evolutions.mod(hero, "ad_pct"); aspd *= Evolutions.mod(hero, "as")
  res += Evolutions.flat(hero, "res"); ap += Evolutions.flat(hero, "ap"); mana += Evolutions.flat(hero, "mana")
 # Level-up cards.
 hp += StatCards.total(hero, "hp"); ad += StatCards.total(hero, "ad"); aspd *= 1.0 + StatCards.total(hero, "as")
 ap += StatCards.total(hero, "ap"); mana += StatCards.total(hero, "mana"); res += StatCards.total(hero, "res")
 # Legacy growth fields from older saves.
 hp *= 1.0 + hero.get("vigor", 0) * 0.10 + hero.get("legacy_hp", 0.0)
 ad *= 1.0 + hero.get("force", 0) * 0.08 + hero.get("legacy_attack", 0.0)
 aspd *= 1.0 + hero.get("agility", 0) * 0.08; ap += hero.get("focus", 0) * 8.0
 if is_awakened(hero): hp *= 1.10; ad *= 1.10; ap += 10.0
 match str(hero.get("apex", "")):
  "apex_body": hp *= 1.0 + APEX_STAT; ad *= 1.0 + APEX_STAT; ap *= 1.0 + APEX_STAT
  "apex_instinct": aspd *= 1.15; mana += 0.15
 res = maxf(0.0, res); aspd = clampf(aspd, 0.2, 5.0); mana = maxf(0.2, mana)
 var result = {"hp": hp, "attack": ad, "ad": ad, "as": aspd, "ap": ap, "mana": mana, "res": res,
  "armor": res / (100.0 + res), "speed": d.mv * 0.036 * Evolutions.mod(hero, "speed"),
  "range": maxf(0.7, d.range / 44.0), "interval": 1.0 / aspd, "cooldown": 0.0,
  "base_hp": base_hp, "base_armor": base_res / (100.0 + base_res), "base_interval": 1.0 / (d["as"] * 0.85), "base_as": d["as"] * 0.85 * (0.8 if d.role == "Artillery" else 1.0)}
 if result.range > 2.0:
  result.range *= 1.55 if d.role == "Artillery" else 1.35
 # Old-scale spell magnitude, still used by item and relic procs.
 result.skill_base = base_ad * (1.0 + 0.026 * lv) * 1.09
 result.ability_power = result.skill_base * ap / 100.0
 var m = Signatures.mana(hero)
 result.start_mana = m[0]; result.max_mana = m[1]
 if str(hero.get("apex", "")) == "apex_instinct": result.start_mana = m[1]
 return result

## Old item/relic armor fractions become Resistance points (+0.05 armor = +8 Resistance).
const ARMOR_TO_RES := 160.0

## Second evolution (Apex) at level 16: one permanent choice.
const APEX_LEVEL := 16
const APEX_STAT := 0.15
const APEX := {
 "apex_body": {"name": "Apex Body", "summary": "+15% HP, AD and AP", "description": "A permanent +15% to HP, AD and AP."},
 "apex_sig": {"name": "Apex Signature", "summary": "Signature +25%, max mana −10", "description": "Every number in the signature is 25% stronger and it costs 10 less mana."},
 "apex_instinct": {"name": "Apex Instinct", "summary": "+15% AS and Mana, first cast instant", "description": "+15% AS and +15% Mana, and the first cast of every fight starts at full mana."},
}
const APEX_LEGACY := {"apex_stats": "apex_body", "apex_skill": "apex_sig", "apex_slot": "apex_body"}

## Item slots: 3, a 4th after the first evolution (or an awakening), a 5th from Apex Arsenal.
static func item_slots(hero: Dictionary) -> int:
 var n = 3
 if not str(hero.get("evolution", "")).is_empty() or bool(hero.get("awakened", false)): n += 1
 if hero.get("apex", "") == "apex_slot": n += 1
 return n

## Power on a 1-100 scale that grows through the run: level-1 champions sit in the teens to high 30s,
## and only the best champions near level 20 approach 100. The colour of a Power number shows
## quality (rarity, rolls, temperament) instead, via power_quality(), so a strong roll reads green early.
static func power(hero: Dictionary) -> int:
 var lvl = int(hero.get("level", 1))
 return clampi(roundi((power_quality(hero) - 40.0) * 0.8 + (lvl - 1) * 3.15), 1, 100)

## Level-neutral quality on the old 40-99 rating scale (what the Power colour is based on).
static func power_quality(hero: Dictionary) -> float:
 return League.ovr_raw(hero) - (int(hero.get("level", 1)) - 1) * 0.84

const ABILITY_SLOTS = 4
const EVOLVE_LEVEL = 8   # first (and only) evolution choice
const MAX_RANK = 3
const DISCOVERY_CHOICES = 12 # 2 originals + 10 unique skills per species (data/skills.json)
const EVOLUTIONS = {
 "ravager": {"name":"Ravager", "color":"ffb36b", "description":"Become a relentless hunter: +20% attack, +15% movement, 12% lifesteal on basic attacks, but -10% maximum health. Amber talons and spell trails."},
 "guardian": {"name":"Guardian", "color":"7de6bd", "description":"Become a protector: +15% health, +4% armor, but -10% attack. Every ability shields the most wounded nearby ally for 3% of your maximum health. Emerald ward rings."},
 "arcanist": {"name":"Arcanist", "color":"bba2ff", "description":"Become a spell specialist: +20% ability potency and 15% shorter ability cooldowns, but -15% attack and 15% slower basic attacks. Violet orbiting runes."}
}

## Twelve skills per species, all unique: two originals plus ten from data/skills.json.
## Each row: [name, effect, rider]. Riders add a signature twist (burn, chill, leech…).
static var skill_book := {}
static func ability_pool(sp: String) -> Array:
 if skill_book.is_empty():
  skill_book = JSON.parse_string(FileAccess.get_file_as_string("res://data/skills.json"))
 var pool = []
 for row in DISCOVERIES[sp]: pool.append([row[0], row[1], "none"])
 for row in skill_book.get(sp, []): pool.append([row[0], row[1], row[2]])
 return pool

const EFFECT_SUMMARY = {"quake":"Stun slam around you", "rally":"Team rally: +attack & speed", "fissure":"Rooting line strike", "ward":"Shield nearby allies",
 "meteor":"Stunning meteor on a cluster", "renew":"Heal the 3 most wounded", "drain":"Life-draining strike", "fear":"Weaken nearby foes",
 "ambush":"Leap onto a wounded foe", "toxic":"Poison cloud", "execute":"Finisher vs low-health foes", "gust":"Knockback gust that slows",
 "wisps":"3 seeking spirit bolts", "barrage":"5-bolt barrage on target", "silence":"Silence a cluster", "beam":"Piercing line lance",
 "storm":"Lightning on 3 foes", "frost":"Freeze a cluster", "roots":"Root a cluster", "fire":"Burning blast", "whirl":"Spin attack + shield"}
const RIDERS = {
 "none": ["", ""], "burn": ["+ Burn", "Sets the main target ablaze for 3s."], "chill": ["+ Chill", "Slows the main target for 2s."],
 "stun": ["+ Stun", "Stuns the main target for 0.5s."], "root": ["+ Root", "Roots the main target for 0.8s."],
 "weaken": ["+ Weaken", "Weakens the main target's damage for 3s."], "silence": ["+ Silence", "Silences the main target for 1.5s."],
 "leech": ["+ Siphon heal", "Heals you for 35% of this skill's power."], "guard": ["+ Self shield", "Shields you for 10% of your max health."],
 "haste": ["+ Haste", "Rallies you (+attack & speed) for 3s."], "mend": ["+ Mend", "Also heals the most wounded ally."],
 "echo": ["+ Echo", "Strikes the main target again for 40% skill power."], "venom": ["+ Venom", "Poisons the main target for 4s at 20% skill power per second."]}

static func learned_ability(sp: String, index: int) -> Dictionary:
 load_data()
 if index==12:return audit_ability(sp,index,ChampionEvolution.action(sp))
 if index>=13:return audit_ability(sp,index,Evolutions.grant_ability(sp,index-13))
 var pool = ability_pool(sp)
 var row = pool[clampi(index, 0, pool.size() - 1)]
 var spec = EFFECTS[row[1]]
 # Each skill gets its own tuning: stronger skills recharge slower.
 var h = float(abs(hash(sp + "|" + row[0])) % 1000) / 999.0
 var power = 0.92 + 0.22 * h if row[2] != "none" else 1.0
 var cd = spec[1] * (0.9 + 0.22 * h) if row[2] != "none" else spec[1]
 var rider = RIDERS.get(row[2], ["", ""])
 var summary = EFFECT_SUMMARY[row[1]]
 if rider[0] != "" and rider[0].trim_prefix("+ ").to_lower() not in summary.to_lower(): summary += " " + rider[0]
 var detail = spec[0].replace("% attack","% skill power") + ((" " + rider[1]) if rider[1] != "" else "") + "  Skill multiplier ×%.2f · %.1fs base cooldown. " % [power, cd] + SkillScaling.description(sp,row[1])
 var reach = float(spec[2])
 if species[sp].range / 44.0 > 2.0 and reach >= 6.0:
  reach *= 1.40 if species[sp].role == "Artillery" else 1.25
 return audit_ability(sp,index,{"key": str(index), "name": row[0], "effect": row[1], "rider": row[2], "power": power, "summary": summary, "description": detail, "cooldown": cd, "range": reach})

static func audit_ability(sp: String,index: int,a: Dictionary) -> Dictionary:
 if a.is_empty():return a
 var data=SkillScaling.audited(sp,str(index))
 if data.is_empty():return a
 a=a.duplicate(true)
 for key in ["name","effect","rider","power","cooldown"]:a[key]=data[key]
 var spec=EFFECTS[a.effect]
 a.range=float(spec[2])
 if species[sp].range/44.0>2.0 and a.range>=6.0:a.range*=1.40 if species[sp].role=="Artillery" else 1.25
 a.summary=EFFECT_SUMMARY.get(a.effect,"Summon slowing spiderlings")
 if a.effect=="magma":a.summary="Molten pool: burn + slow"
 if data.has("range"):a.range=float(data.range)
 var rider=RIDERS.get(a.rider,["",""])
 a.summary+=" "+rider[0] if not rider[0].is_empty() else ""
 var reach_note=""
 if a.effect in ["quake","whirl","fear"]:reach_note="Area: 1 hex around you. "
 elif a.effect not in ["ward","rally","renew","brood"]:
  var hexes=ArenaGrid.attack_hexes(a.range)
  reach_note="Primary reach: %d hexes. "%hexes
  a.summary+=" · %d hexes"%hexes
 a.description=data.description+" "+rider[1]+" "+reach_note+"%.1fs base cooldown. "%a.cooldown+SkillScaling.description(sp,a.effect,str(index))
 return a

const SIGNATURE_SUMMARY = {"gore":"Charge + stun", "bulwark":"Taunt + stone shield", "smash":"Slam & slow, regenerates", "hunger":"Frenzy: attack + lifesteal",
 "howl":"Summon 2 wolf pups", "venom":"Leap + poison weakest", "skystrike":"Dive backline + stun", "foxfire":"Decoys + blink",
 "acid":"Acid pool", "shriek":"Silence + slow nearby", "flamewave":"Fire wave, rises once", "chain":"Lightning chains 4 foes",
 "gaze":"Petrify one foe", "rootbloom":"Heal ally + root foe", "tidal":"Shield nearby allies", "radiance":"Heal + cleanse allies",
 "triplebite":"Bite 3 foes + bleed", "prideroar":"Taunt + rally, tough hide", "frostroar":"Chill nearby + ice shield", "shellup":"Taunt + shell (−80% dmg)",
 "maul":"Pounce + pin", "regrowth":"Regrow health, cleave", "threefold":"3 rapid hits + burn", "stonedive":"Dive backline, turn to stone",
 "vanish":"Vanish, then ambush", "antlerrush":"Charge through the line", "boulder":"Boulder: crush + stun", "stormcall":"Lightning on 3 foes",
 "riddle":"Confuse a foe", "tailwind":"Allies +30% attack & speed", "brood":"Summon 3 spiderlings", "magma":"Lava pool: burn + slow"}

static func signature_summary(sp: String) -> String:
 load_data()
 return "%s · %s" % [Signatures.of(sp).name, Signatures.of(sp).builds]

## Awakening (from Gold-chest unlocks) is separate from the level-10 evolution, so a champion keeps both.
static func is_awakened(hero: Dictionary) -> bool:
 return bool(hero.get("awakened", false)) or str(hero.get("evolution", "")) == "ascended"

static func evolution_info(hero: Dictionary) -> Dictionary:
 if hero.get("evolution","")=="ascended":return ChampionEvolution.info(hero)
 if Evolutions.has(str(hero.get("evolution",""))):return Evolutions.info(hero.evolution)
 return EVOLUTIONS.get(hero.get("evolution",""),{})

static func evolution_color(hero: Dictionary) -> Color:
 return Color(evolution_info(hero).get("color","ffffff"))

## v0.76: no cooldowns; kept as the inverse of Mana gain for older callers.
static func cooldown_factor(hero: Dictionary) -> float:
 return clampf(1.0 / float(stats(hero).mana), 0.40, 2.0)

static func spell_factor(hero: Dictionary) -> float:
 return stats(hero).ap / 100.0

static func choices(hero: Dictionary, won: bool, rng: RandomNumberGenerator, reward_level: int = -1) -> Array:
 var out = []
 var level = int(hero.level) if reward_level < 0 else reward_level
 if level >= EVOLVE_LEVEL and str(hero.get("evolution", "")).is_empty():
  # Three evolutions unique to this species, each pointing at a different build.
  for key in Evolutions.options(hero.sp):
   var e = Evolutions.entry(key)
   var t = Evolutions.text(key, hero)
   out.append({"type":"evolution", "key":key, "name":e.name, "summary":str(e.tag).to_upper() + " · " + t, "description":e.tag + ". " + t, "rarity":"Evolution", "bonus":1.0})
  if not out.is_empty(): return out
 if level >= APEX_LEVEL and str(hero.get("apex", "")).is_empty() and not str(hero.get("evolution", "")).is_empty():
  for key in APEX:
   out.append({"type":"apex", "key":key, "name":APEX[key].name, "summary":"APEX · " + APEX[key].summary, "description":"Second evolution. " + APEX[key].description, "rarity":"Evolution", "bonus":1.0})
  return out
 # v0.76: every other level-up deals three stat cards at random rarities.
 return StatCards.draw(rng, level)

static func apply_choice(hero: Dictionary, card: Dictionary) -> void:
 match card.type:
  "stat": StatCards.apply(hero, card)
  "evolution":
   if not str(hero.get("evolution", "")).is_empty(): return
   hero.evolution = card.key
  "apex":
   if not str(hero.get("apex", "")).is_empty(): return
   hero.apex = card.key
  "vigor", "force", "focus", "agility": hero[card.type] = int(hero.get(card.type, 0)) + 1
  _: return
 if not hero.has("history"): hero.history = []
 hero.history.append(card.name)

static func queue_reward(hero: Dictionary, level: int, won: bool, seed_value: int) -> void:
 if not hero.has("rewards"): hero.rewards = []
 hero.rewards.append({"level":level, "won":won, "seed":seed_value})
 hero.pending.append([])
 materialize_reward(hero)

static func materialize_reward(hero: Dictionary) -> void:
 if hero.pending.is_empty() or not hero.pending[0].is_empty(): return
 var reward = hero.rewards[0]
 var rng = RandomNumberGenerator.new(); rng.seed = int(reward.seed)
 hero.pending[0] = choices(hero, reward.won, rng, int(reward.level))

const PROGRESSION_VERSION := 3

static func migrate_progression(hero: Dictionary) -> void:
 if int(hero.get("progression_version", 0)) >= PROGRESSION_VERSION: return
 # v0.76: skills, ranks and discoveries are gone. Past level-ups become auto-picked stat cards,
 # which the player may reset once for free. Level, rolls, evolution and items stay.
 var pending_count = hero.get("pending", []).size()
 hero.learned = {}; hero.signature_rank = 1; hero.erase("skill_rarity"); hero.erase("signature_bonus")
 for k in hero.keys().duplicate():
  if str(k).begins_with("ability_bonus_"): hero.erase(k)
 hero.apex = APEX_LEGACY.get(str(hero.get("apex", "")), str(hero.get("apex", "")))
 if str(hero.get("evolution", "")) in ["ravager", "guardian", "arcanist", "ascended"]:
  if str(hero.evolution) == "ascended": hero.awakened = true
  hero.evolution = ""
 hero.cards = {}; hero.pending = []; hero.rewards = []; hero.last_offers = []
 hero.progression_version = PROGRESSION_VERSION
 var lvl = int(hero.get("level", 1))
 var rng = RandomNumberGenerator.new(); rng.seed = hash(str(hero.get("id", "")) + "|v076")
 for l in range(2, lvl - pending_count + 1):
  if (l == EVOLVE_LEVEL) or (l == APEX_LEVEL): continue
  var cards = StatCards.draw(rng, l)
  StatCards.apply(hero, cards[StatCards.auto_pick(hero, cards)])
 hero.card_reset = true
 if lvl >= EVOLVE_LEVEL and str(hero.evolution).is_empty(): queue_reward(hero, EVOLVE_LEVEL, false, hash(str(hero.id) + "evolution"))
 if lvl >= APEX_LEVEL and str(hero.get("apex", "")).is_empty(): queue_reward(hero, APEX_LEVEL, false, hash(str(hero.id) + "apex"))
 for i in range(pending_count): queue_reward(hero, maxi(2, lvl - pending_count + i + 1), false, hash(str(hero.id) + str(i)))

## Undo every stat card and redraw them as fresh picks (the one-time free reset for migrated saves).
static func reset_cards(hero: Dictionary) -> bool:
 if not bool(hero.get("card_reset", false)): return false
 hero.card_reset = false; hero.cards = {}
 var lvl = int(hero.get("level", 1))
 for l in range(2, lvl + 1):
  if l == EVOLVE_LEVEL or l == APEX_LEVEL: continue
  queue_reward(hero, l, false, hash(str(hero.id) + "|reset|" + str(l)))
 return true

static func xp_needed(level: int) -> int:
 return 100 + (level - 1) * 30

## Rivals, recruits and monsters arrive with their level-ups already picked (signature-focused).
static func auto_cards(h: Dictionary, seed_text: String) -> void:
 h.learned = {}; h.signature_rank = 1; h.cards = {}
 var rng = RandomNumberGenerator.new(); rng.seed = hash(seed_text + "|cards|" + run_salt)
 for l in range(2, int(h.level) + 1):
  if l == EVOLVE_LEVEL or l == APEX_LEVEL: continue
  var cards = StatCards.draw(rng, l)
  StatCards.apply(h, cards[StatCards.auto_pick(h, cards)])
 if int(h.level) >= APEX_LEVEL and str(h.get("apex", "")).is_empty(): h.apex = APEX.keys()[rng.randi_range(0, APEX.size() - 1)]
