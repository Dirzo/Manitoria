class_name Forge
extends RefCounted
## v0.77 itemisation. Eight components (one per stat path) plus Trickster's Coin. Two components
## forge one of 36 finished items; Coin + a component forges one of 9 Wild items (big upside,
## obvious downside). A Mythic Anvil turns a finished item into its Legendary ("leg_<id>").
## Every item has one fantasy, a visible change on the champion and a felt moment in combat.
##
## Stat keys (components and "x"): ad (flat), as (fraction), ap (flat), mana (fraction), hp (flat),
## res (flat), crit (chance), critdmg (added multiplier), size (added Size), hp_pct / ad_pct / as_pct
## (multipliers, -0.4 = 40% less).

const SLOTS := 3
const COMPONENT_PRICE := 70
const ITEM_PRICE := 190
const LEGEND := "leg_"

const COMPONENTS := {
	"fang":    {"name": "Sharpened Fang", "art": "comp:fang", "ad": 10.0, "short": "+10 AD"},
	"feather": {"name": "Roc Feather", "art": "comp:feather", "as": 0.12, "short": "+12% AS"},
	"ember":   {"name": "Ember Shard", "art": "comp:ember", "ap": 15.0, "short": "+15 AP"},
	"moon":    {"name": "Moonstone", "art": "comp:moon", "mana": 0.12, "short": "+12% Mana"},
	"hide":    {"name": "Troll Hide", "art": "comp:hide", "hp": 150.0, "short": "+150 HP"},
	"plate":   {"name": "Bronze Plate", "art": "comp:plate", "res": 15.0, "short": "+15 Resistance"},
	"storm":   {"name": "Storm Glass", "art": "comp:storm", "crit": 0.15, "short": "+15% Crit"},
	"marrow":  {"name": "Titan Marrow", "art": "comp:marrow", "size": 0.10, "hp": 60.0, "short": "+10% Size, +60 HP"},
	"coin":    {"name": "Trickster's Coin", "art": "comp:coin", "short": "Forges a Wild item: a huge upside with a real downside"},
}
const COMPONENT_ORDER := ["fang", "feather", "ember", "moon", "hide", "plate", "storm", "marrow", "coin"]
const PATHS := {"giant": "Giant", "tempo": "Tempo", "crit": "Crit", "spell": "Spell", "tank": "Tank", "sustain": "Sustain", "wild": "Wild"}
const PATH_COLOR := {"giant": "ffb347", "tempo": "5fe3ff", "crit": "ff6a3d", "spell": "b07bff", "tank": "b8c4d0", "sustain": "e0344f", "wild": "ffd04a"}

# icon = an existing item portrait (assets/items/i_<icon>.png).
const ITEMS := {
	# ---------------------------------------------------------------- Giant
	"titanheart":  {"recipe": ["marrow", "marrow"], "name": "Titan's Heart", "path": "giant", "icon": "colossus", "x": {"size": 0.30},
		"text": "+30% Size. Size bonuses to HP and AD are doubled. Above 1.5× Size, can't be stunned, knocked back or pulled.",
		"leg": ["Heart of the World", "+60% Size (cap 2.4×). Size bonuses to HP and AD are tripled. Always unstoppable."]},
	"club":        {"recipe": ["marrow", "fang"], "name": "Colossus Club", "path": "giant", "icon": "titan",
		"text": "Basic attacks become stomps that also hit every adjacent enemy for 60% AD. The radius grows with Size.",
		"leg": ["Worldbreaker", "Stomps hit everything within 2 hexes; every 3rd stomp stuns them for 1s."]},
	"belt":        {"recipe": ["marrow", "hide"], "name": "Titan's Belt", "path": "giant", "icon": "giant",
		"text": "Start at +10% Size, then gain +5% Size every 2s in combat, up to +60%.",
		"leg": ["The Living Mountain", "Keeps growing to 2.4×. At full size, takes 40% less damage and taunts everyone within 3 hexes."]},
	"wrath":       {"recipe": ["hide", "fang"], "name": "Titan's Wrath", "path": "giant", "icon": "crusader",
		"text": "When hit, gain +1% Size and +2% AD, up to 40 stacks.",
		"leg": ["Wrath of Ages", "No stack cap. From 40 stacks, attacks hit every adjacent enemy."]},
	"hooves":      {"recipe": ["marrow", "feather"], "name": "Thunderhoof Greaves", "path": "giant", "icon": "pilgrim",
		"text": "Every 10% Size also gives +8% AS. Arriving on a hex tramples adjacent enemies a hex aside.",
		"leg": ["Stampede Engine", "Every 10% Size gives +15% AS, and trampled enemies are stunned for 0.5s."]},
	"patience":    {"recipe": ["marrow", "moon"], "name": "Mountain's Patience", "path": "giant", "icon": "stoneskin",
		"text": "Each signature cast gives +10% Size and +150 max HP for the fight (up to 6 casts).",
		"leg": ["Mountain King", "Each cast gives +20% Size and +300 max HP, with no cast limit."]},
	"granite":     {"recipe": ["marrow", "plate"], "name": "Granite Hide", "path": "giant", "icon": "ironbark",
		"text": "+1 Resistance for every 1% Size above its natural size.",
		"leg": ["Living Granite", "+2 Resistance per 1% Size, and reflects 20% of basic-attack damage."]},
	"draught":     {"recipe": ["marrow", "ember"], "name": "Titan's Draught", "path": "giant", "icon": "witherbloom", "x": {"size": 0.20},
		"text": "+20% Size. Signature areas and projectiles grow with Size too.",
		"leg": ["Titanic Elixir", "+40% Size; signature areas grow twice as fast with Size."]},
	"maul":        {"recipe": ["marrow", "storm"], "name": "Earthshaker Maul", "path": "giant", "icon": "thundercleaver",
		"text": "Crits send a shockwave that hits adjacent enemies for 50% of the crit. The radius grows with Size.",
		"leg": ["Thunderstrike Maul", "Every crit is a stomp hitting all enemies within 2 hexes and stunning them for 0.5s."]},
	# ---------------------------------------------------------------- Tempo
	"frenzy":      {"recipe": ["feather", "fang"], "name": "Frenzy Horn", "path": "tempo", "icon": "frenzy",
		"text": "Each attack gives +5% AS for the fight, with no cap. A stun removes half the stacks.",
		"leg": ["Hurricane Horn", "+8% AS per attack; stuns no longer remove stacks. Above 4 AS, attacks hit every adjacent enemy."]},
	"tempest":     {"recipe": ["feather", "feather"], "name": "Tempest Talons", "path": "tempo", "icon": "tempest",
		"text": "Attacks bounce to 2 more enemies for 60% damage.",
		"leg": ["Chain Tempest", "Attacks bounce to 4 more enemies for 70%."]},
	"quicksilver": {"recipe": ["feather", "moon"], "name": "Quicksilver", "path": "tempo", "icon": "quicksilver",
		"text": "Basic attacks give double mana.",
		"leg": ["Quickening", "Attacks give triple mana, and each cast gives +30% AS for 3s."]},
	"quiver":      {"recipe": ["feather", "ember"], "name": "Arcane Quiver", "path": "tempo", "icon": "quiver",
		"text": "Every 3rd attack also fires a spell bolt for 60 AP.",
		"leg": ["Echoing Quiver", "Every 4th attack also casts the signature at 30% strength."]},
	"drum":        {"recipe": ["feather", "hide"], "name": "War Drum", "path": "tempo", "icon": "drum",
		"text": "Every 5th attack beats the drum: allies within 2 hexes gain +25% AS for 3s.",
		"leg": ["Warlord's Drum", "Every 3rd attack gives the whole team +40% AS for 3s."]},
	"spikes":      {"recipe": ["feather", "plate"], "name": "Spiked Gauntlet", "path": "tempo", "icon": "spikes",
		"text": "When hit by a basic attack, 30% chance to counterattack instantly.",
		"leg": ["Thornstorm", "60% counterattack chance, and counters always crit."]},
	"talons":      {"recipe": ["feather", "storm"], "name": "Storm Talons", "path": "tempo", "icon": "galetalons",
		"text": "Each crit gives +8% AS for 5s, stacking.",
		"leg": ["Cyclone Talons", "Each crit gives +12% AS for the rest of the fight."]},
	# ---------------------------------------------------------------- Crit
	"tempestcrown":{"recipe": ["storm", "storm"], "name": "Tempest Crown", "path": "crit", "icon": "tempestcrown", "x": {"crit": 0.30, "critdmg": 0.5},
		"text": "+30% Crit and +0.5× crit damage.",
		"leg": ["Crown of Storms", "+60% Crit and +1.0× crit damage. MEGA CRITS chain lightning to 2 enemies."]},
	"dragonedge":  {"recipe": ["storm", "fang"], "name": "Dragon's Edge", "path": "crit", "icon": "executioner", "x": {"critdmg": 1.0},
		"text": "+1.0× crit damage (crits for 3×). Crits on enemies below 40% HP deal double again.",
		"leg": ["Godslayer", "Crits deal 5×. A MEGA CRIT executes an enemy below 15% HP outright."]},
	"deathblade":  {"recipe": ["fang", "fang"], "name": "Deathblade", "path": "crit", "icon": "bloodmaw",
		"text": "Each takedown gives +15 AD for the fight.",
		"leg": ["Reaper's Blade", "+30 AD per takedown, and each takedown fills the mana bar."]},
	"gauntlet":    {"recipe": ["storm", "ember"], "name": "Jeweled Gauntlet", "path": "crit", "icon": "stormorb", "x": {"crit": 0.10},
		"text": "+10% Crit. The signature can crit.",
		"leg": ["Starfall Gauntlet", "The signature always crits its first target; spell crits rain stars on 3 enemies for 30% of the crit."]},
	"overcharge":  {"recipe": ["storm", "moon"], "name": "Overcharge Crown", "path": "crit", "icon": "overcharge",
		"x": {"crit": 0.10}, "text": "+10% Crit. Each crit gives 10 mana.",
		"leg": ["Overload Crown", "Crits give 15 mana; each cast gives +25% Crit for 4s."]},
	# ---------------------------------------------------------------- Spell
	"archmage":    {"recipe": ["ember", "ember"], "name": "Archmage Orb", "path": "spell", "icon": "archmage", "x": {"ap": 30.0},
		"text": "+30 AP. Signature areas are 25% bigger.",
		"leg": ["Archmage's Eye", "+60 AP; signature areas are 50% bigger."]},
	"crown":       {"recipe": ["ember", "moon"], "name": "Blue Crown", "path": "spell", "icon": "crown",
		"text": "After casting, refund 20 mana.",
		"leg": ["Eternity Crown", "Refunds 40 mana after casting, and each cast has a 25% chance to cast again immediately."]},
	"spellblade":  {"recipe": ["ember", "fang"], "name": "Spellblade", "path": "spell", "icon": "spellblade",
		"text": "After casting, the next 3 attacks deal +100% AD + 40 AP.",
		"leg": ["Arcblade", "After casting, the next 3 attacks deal +200% AD + 80 AP and arc to a second enemy."]},
	"phoenix":     {"recipe": ["ember", "hide"], "name": "Phoenix Ember", "path": "spell", "icon": "phoenixember",
		"text": "The first time it would die, it rises at 30% HP and explodes for 150 AP.",
		"leg": ["Undying Phoenix", "Rises up to 3 times at 35% HP; each explosion is bigger (150 / 250 / 400 AP)."]},
	"hourglass":   {"recipe": ["moon", "moon"], "name": "Hourglass Crest", "path": "spell", "icon": "hourglass",
		"text": "Start with full mana. The first cast is 50% stronger.",
		"leg": ["Hourglass of Ages", "Starts full; the first two casts are twice as strong."]},
	# ---------------------------------------------------------------- Tank
	"colossus":    {"recipe": ["hide", "hide"], "name": "Colossus Heart", "path": "tank", "icon": "worldtree", "x": {"hp_pct": 0.25},
		"text": "+25% HP. Below 50% HP, regenerate 3% max HP per second.",
		"leg": ["Heart of the Colossus", "+50% HP; regenerates 3% max HP per second whenever below 70%."]},
	"bastion":     {"recipe": ["hide", "plate"], "name": "Bastion Shell", "path": "tank", "icon": "bastion",
		"text": "At 50% HP, gain a shield of 35% max HP for 5s.",
		"leg": ["Immortal Bastion", "Every 8s, a shield of 25% max HP; while shielded, reflects 50% of damage taken."]},
	"mirror":      {"recipe": ["plate", "plate"], "name": "Mirror Carapace", "path": "tank", "icon": "mirror",
		"text": "Reflect 30% of signature damage taken.",
		"leg": ["Mirror of Ages", "Reflects 100% of signature damage, and fully negates the first enemy signature each fight."]},
	"tusk":        {"recipe": ["fang", "plate"], "name": "Shieldbreaker Tusk", "path": "tank", "icon": "tusk",
		"text": "Attacks shred 4 Resistance (stacking to 40) and cut healing by 40%.",
		"leg": ["Ruin", "Shreds 8 Resistance per hit (to 80) and cuts healing by 70%."]},
	"runeward":    {"recipe": ["ember", "plate"], "name": "Runeward", "path": "tank", "icon": "runeward",
		"text": "Negate the first enemy signature every 8s.",
		"leg": ["Runic Bulwark", "Negates a signature every 5s; each negate shields all allies for 150 AP."]},
	"thunderhide": {"recipe": ["hide", "storm"], "name": "Thunder Hide", "path": "tank", "icon": "stormmantle",
		"text": "When hit by a crit or a signature, zap all adjacent enemies for 80 AP.",
		"leg": ["Storm Colossus", "Zaps within 2 hexes for 120 AP when hit by a crit or signature, and from basic attacks once every 2s."]},
	"dragonscale": {"recipe": ["plate", "storm"], "name": "Dragonscale", "path": "tank", "icon": "lightningrod",
		"text": "Crits against it deal normal damage, and each blocked crit gives +5 Resistance.",
		"leg": ["Dragon's Hoard", "Immune to crits; each crit attempt against it gives +8 Resistance."]},
	"bell":        {"recipe": ["moon", "hide"], "name": "Warding Bell", "path": "tank", "icon": "bell",
		"text": "Each cast shields it and the nearest ally for 15% of its max HP.",
		"leg": ["Sanctuary Bell", "Each cast shields every ally for 15% of its max HP."]},
	"aegis":       {"recipe": ["moon", "plate"], "name": "Sanctified Aegis", "path": "tank", "icon": "aegis",
		"text": "At the start of each fight, shield all allies for 200 + 5% of its max HP.",
		"leg": ["Aegis of Dawn", "Opening shield of 300 + 8% max HP on all allies, refreshed once when the team falls below 50% total HP."]},
	# ---------------------------------------------------------------- Sustain
	"bloodmoon":   {"recipe": ["fang", "moon"], "name": "Bloodmoon Fang", "path": "sustain", "icon": "leechhide",
		"text": "20% of all damage dealt heals it. Overhealing becomes a shield, up to 30% max HP.",
		"leg": ["Crimson Moon", "40% of all damage heals it; the overheal shield goes up to 60% max HP, and kills heal 30%."]},
	# ---------------------------------------------------------------- Wild (Trickster's Coin)
	"bloodfeast":  {"recipe": ["coin", "fang"], "name": "Bloodfeast", "path": "wild", "wild": true, "icon": "bloodfeast",
		"text": "Kills heal 40% max HP.", "down": "Heals from allies are 50% weaker.",
		"leg": ["Feast of Ruin", "Kills heal 100% max HP and give +10% Size."]},
	"spurs":       {"recipe": ["coin", "feather"], "name": "Reckless Spurs", "path": "wild", "wild": true, "icon": "sugarrush", "x": {"as_pct": 0.80},
		"text": "+80% AS.", "down": "Takes 25% more damage.",
		"leg": ["Blur", "+150% AS; takes 35% more damage."]},
	"wildfire":    {"recipe": ["coin", "ember"], "name": "Wildfire Tome", "path": "wild", "wild": true, "icon": "plaguetome",
		"text": "The signature costs 40% less mana.", "down": "Each cast burns 5% of its own max HP.",
		"leg": ["Inferno Tome", "The signature costs 60% less mana; each cast burns 8% of its max HP."]},
	"bottle":      {"recipe": ["coin", "moon"], "name": "Lightning in a Bottle", "path": "wild", "wild": true, "icon": "bottle",
		"text": "Every 5s, a 200 AP bolt strikes a random unit.", "down": "1 in 4 bolts hits an ally.",
		"leg": ["Storm in a Bottle", "Every 3s, a 300 AP bolt strikes a random unit (1 in 4 hits an ally)."]},
	"giant":       {"recipe": ["coin", "hide"], "name": "Giant's Draught", "path": "wild", "wild": true, "icon": "giant", "x": {"size": 0.80, "as_pct": -0.40},
		"text": "+80% Size.", "down": "−40% AS.",
		"leg": ["Elixir of Titans", "Grows straight to 2.4× Size; −50% AS."]},
	"turtle":      {"recipe": ["coin", "plate"], "name": "Turtle Shell", "path": "wild", "wild": true, "icon": "turtle",
		"text": "Below 40% HP, hides for 3s: invulnerable, heals 25%, then +30% AS for 6s.", "down": "Can't act while hidden.",
		"leg": ["Ancient Shell", "Hides twice (at 40% and 20% HP) and heals 40% each time."]},
	"gambler":     {"recipe": ["coin", "storm"], "name": "Gambler's Edge", "path": "wild", "wild": true, "icon": "chaos",
		"text": "Crits deal 8×.", "down": "Crit chance is halved, and non-crits deal 30% less.",
		"leg": ["Loaded Dice", "Crits deal 12×."]},
	"glasstitan":  {"recipe": ["coin", "marrow"], "name": "Glass Titan", "path": "wild", "wild": true, "icon": "doppel", "x": {"size": 0.60, "ad_pct": 1.0, "hp_pct": -0.50},
		"text": "+100% AD and +60% Size.", "down": "−50% max HP.",
		"leg": ["Shattered Titan", "+150% AD at 2× Size; −60% max HP."]},
	"swap":        {"recipe": ["coin", "coin"], "name": "Swap Charm", "path": "wild", "wild": true, "icon": "swap",
		"text": "When an ally drops below 25%, swaps places and shields them for 25% of its own HP (10s cooldown).", "down": "It takes the hits meant for them.",
		"leg": ["Soul Swap", "The swapped ally is also invulnerable for 2s."]},
}
## Legendary stat overrides (on top of the base item's "x").
const LEG_X := {
	"titanheart": {"size": 0.60}, "draught": {"size": 0.40}, "tempestcrown": {"crit": 0.60, "critdmg": 1.0},
	"dragonedge": {"critdmg": 3.0}, "archmage": {"ap": 60.0}, "colossus": {"hp_pct": 0.50},
	"spurs": {"as_pct": 1.50}, "giant": {"size": 1.40, "as_pct": -0.50}, "glasstitan": {"size": 0.90, "ad_pct": 1.5, "hp_pct": -0.60},
	"overcharge": {"crit": 0.10}, "gauntlet": {"crit": 0.10},
}
## Old (v0.76 and earlier) ids convert to their closest v0.77 item when a save loads.
const RETIRED := {
	"silk": "feather", "venom": "fang", "relic": "plate", "seed": "hide",
	"bloodmaw": "bloodmoon", "titan": "wrath", "frenzy": "frenzy", "spellblade": "spellblade", "executioner": "dragonedge",
	"thornlash": "club", "berserker": "bloodfeast", "colossus": "colossus", "bastion": "bastion", "drum": "drum",
	"phoenixember": "phoenix", "bell": "bell", "lifebloom": "bell", "mirror": "mirror", "spikes": "spikes", "runeward": "runeward",
	"stoneskin": "granite", "ironbark": "granite", "tempest": "tempest", "quiver": "quiver", "quicksilver": "quicksilver",
	"hunter": "tusk", "sugarrush": "spurs", "archmage": "archmage", "crown": "crown", "scepter": "bell", "chaos": "wildfire",
	"hourglass": "hourglass", "spiritbell": "bell", "puppet": "bottle", "worldtree": "colossus", "thundercleaver": "maul",
	"stormmantle": "thunderhide", "lightningrod": "dragonscale", "galetalons": "talons", "stormorb": "gauntlet", "overcharge": "overcharge",
	"rainbringer": "overcharge", "tempestcrown": "tempestcrown", "flicker": "dragonedge", "galvanic": "dragonedge", "judgement": "gauntlet",
	"shadowblade": "deathblade", "phantomcloak": "bloodmoon", "smokeplate": "bastion", "windwalker": "talons", "illusion": "crown",
	"eclipse": "quicksilver", "wispshroud": "bell", "doppel": "glasstitan", "nightshroud": "deathblade", "assassinkit": "dragonedge",
	"wardshroud": "runeward", "viperfang": "deathblade", "leechhide": "bloodmoon", "acidshell": "tusk", "needles": "tempest",
	"plaguetome": "archmage", "witherbloom": "crown", "grievous": "tusk", "hydravenom": "frenzy", "antidote": "colossus",
	"crusader": "deathblade", "martyr": "aegis", "aegis": "aegis", "pilgrim": "hooves", "halo": "runeward", "rosary": "aegis",
	"chalice": "bell", "divine": "swap", "grail": "colossus", "idol": "swap", "turtle": "turtle", "giant": "giant",
	"bloodfeast": "bloodfeast", "bottle": "bottle", "swap": "swap", "tusk": "tusk",
}

static var _recipes: Dictionary = {}

static func base_id(id: String) -> String: return id.trim_prefix(LEGEND)
static func is_legend(id: String) -> bool: return id.begins_with(LEGEND) and ITEMS.has(base_id(id))
static func is_component(id: String) -> bool: return COMPONENTS.has(id)
static func is_item(id: String) -> bool: return ITEMS.has(base_id(id))
static func is_wild(id: String) -> bool: return bool(ITEMS.get(base_id(id), {}).get("wild", false))
static func valid(id: String) -> bool: return COMPONENTS.has(id) or ITEMS.has(base_id(id))

static func combine(a: String, b: String) -> String:
	if _recipes.is_empty():
		for id in ITEMS:
			var r = ITEMS[id].recipe; _recipes[_key(r[0], r[1])] = id
	return str(_recipes.get(_key(a, b), ""))

static func _key(a: String, b: String) -> String:
	return a + "+" + b if a < b else b + "+" + a

static func path_color(id: String) -> Color:
	return Color(PATH_COLOR.get(str(ITEMS.get(base_id(id), {}).get("path", "")), "ffffff"))

static func info(id: String) -> Dictionary:
	if COMPONENTS.has(id):
		var c = COMPONENTS[id].duplicate(); c.id = id; c.kind = "component"; c.rarity = "Common"; c.price = COMPONENT_PRICE
		c.description = c.short + ("\nCombine with another component to forge a Wild item." if id == "coin" else "\nCombine with another component to forge a finished item.")
		return c
	var b = base_id(id)
	if ITEMS.has(b):
		var src = ITEMS[b]; var it = src.duplicate(); it.id = id; it.kind = "item"; it.sfx = str(src.icon); it.art = "item:" + id; it.price = ITEM_PRICE
		var legend = is_legend(id)
		it.legendary = legend
		if legend: it.name = src.leg[0]; it.text = src.leg[1]
		it.rarity = "Legendary" if legend else ("Wild" if src.get("wild", false) else "Rare")
		it.path_name = PATHS.get(str(src.path), "")
		it.description = it.text + ("\nDownside: " + str(src.down) if src.has("down") else "") + "\n" + stat_line(id)
		if legend: it.description += "\nLegendary of " + str(src.name) + "."
		elif not src.get("wild", false): it.description += "\nMythic Anvil: becomes " + str(src.leg[0]) + " — " + str(src.leg[1])
		else: it.description += "\nMythic Anvil (50% to destroy): becomes " + str(src.leg[0]) + " — " + str(src.leg[1])
		return it
	return {}

const STAT_KEYS := ["ad", "as", "ap", "mana", "hp", "res", "crit", "critdmg", "size", "hp_pct", "ad_pct", "as_pct"]

## Stat contributions of one component, item or Legendary.
static func stats_of(id: String) -> Dictionary:
	var out = {}
	for k in STAT_KEYS: out[k] = 0.0
	var b = base_id(id)
	var parts = [id] if COMPONENTS.has(id) else (ITEMS[b].recipe if ITEMS.has(b) else [])
	for p in parts:
		for k in COMPONENTS[p]:
			if out.has(k): out[k] += float(COMPONENTS[p][k])
	if ITEMS.has(b):
		var x = LEG_X.get(b, ITEMS[b].get("x", {})) if is_legend(id) else ITEMS[b].get("x", {})
		for k in x: out[k] += float(x[k])
	return out

static func stat_line(id: String) -> String:
	var s = stats_of(id); var parts = []
	if s.ad != 0: parts.append("%+d AD" % roundi(s.ad))
	if s.ad_pct != 0: parts.append("%+d%% AD" % roundi(s.ad_pct * 100))
	if s["as"] != 0: parts.append("%+d%% AS" % roundi(s["as"] * 100))
	if s.as_pct != 0: parts.append("%+d%% AS" % roundi(s.as_pct * 100))
	if s.ap != 0: parts.append("%+d AP" % roundi(s.ap))
	if s.mana != 0: parts.append("%+d%% Mana" % roundi(s.mana * 100))
	if s.hp != 0: parts.append("%+d HP" % roundi(s.hp))
	if s.hp_pct != 0: parts.append("%+d%% HP" % roundi(s.hp_pct * 100))
	if s.res != 0: parts.append("%+d Resistance" % roundi(s.res))
	if s.crit != 0: parts.append("%+d%% Crit" % roundi(s.crit * 100))
	if s.critdmg != 0: parts.append("%+.1f× crit damage" % s.critdmg)
	if s.size != 0: parts.append("%+d%% Size" % roundi(s.size * 100))
	return " · ".join(parts)

static func carried(hero: Dictionary) -> Array:
	var out = []
	for v in hero.get("equipment", {}).values():
		if valid(str(v)): out.append(str(v))
	return out

static func holds(hero: Dictionary, id: String) -> bool:
	for v in carried(hero):
		if base_id(v) == id: return true
	return false

static func holds_legend(hero: Dictionary, id: String) -> bool:
	return (LEGEND + id) in carried(hero)

## Totals as HeroData.stats() reads them.
static func totals(hero: Dictionary) -> Dictionary:
	var t = {"ad": 0.0, "as": 0.0, "ap": 0.0, "mana": 0.0, "hp": 0.0, "res": 0.0, "crit": 0.0, "critdmg": 0.0, "size": 0.0,
		"hp_mult": 1.0, "ad_mult": 1.0, "as_mult": 1.0, "size_k": 1.0, "size_cap": HeroData.SIZE_CAP, "critdmg_cap": 0.0}
	for id in carried(hero):
		var s = stats_of(id)
		for k in ["ad", "as", "ap", "mana", "hp", "res", "crit", "critdmg", "size"]: t[k] += s[k]
		t.hp_mult *= 1.0 + s.hp_pct; t.ad_mult *= 1.0 + s.ad_pct; t.as_mult *= maxf(0.2, 1.0 + s.as_pct)
		if is_legend(id) and ITEMS[base_id(id)].path in ["giant"] or id in [LEGEND + "giant", LEGEND + "glasstitan"]: t.size_cap = HeroData.SIZE_CAP_LEGEND
	if holds(hero, "titanheart"): t.size_k = 3.0 if holds_legend(hero, "titanheart") else 2.0
	if holds(hero, "gambler"):
		t.crit *= 0.5; t.critdmg += 10.0 if holds_legend(hero, "gambler") else 6.0; t.critdmg_cap = 12.0
	if holds_legend(hero, "giant"): t.size = maxf(t.size, 3.0)
	return t

## Is this item carried in a fight (normal or Legendary)?
static func has(u: Dictionary, id: String) -> bool:
	return not u.get("summon", false) and id in u.get("forge", [])

static func leg(u: Dictionary, id: String) -> bool:
	return not u.get("summon", false) and id in u.get("legends", [])

## An AP-scaled item number (AP and level, but not signature bonuses).
static func ap(u: Dictionary, base: float) -> float:
	return base * float(u.get("ap", 100.0)) / 100.0 * Signatures.level_factor(int(u.hero.get("level", 1)))

# ---------------------------------------------------------------- Size in combat
## The size factor that multiplies HP and AD for a champion at a given Size.
static func size_factor(u: Dictionary, size: float) -> float:
	return 1.0 + maxf(0.0, size - float(u.get("born_size", 1.0))) * 0.5 * float(u.get("size_k", 1.0))

## Grow (or shrink) a champion mid-fight: HP, AD, Resistance and area follow, the model rescales.
static func set_size(sim: BattleSim, u: Dictionary, size: float) -> void:
	var cap = HeroData.SIZE_CAP_LEGEND if u.get("size_cap", 2.0) > 2.0 else HeroData.SIZE_CAP
	size = clampf(size, 0.7, cap)
	var old = float(u.get("size", 1.0))
	if is_equal_approx(old, size): return
	var r = size_factor(u, size) / size_factor(u, old)
	var hp_ratio = u.hp / u.max_hp
	u.max_hp *= r; u.hp = u.max_hp * hp_ratio
	u.attack *= r; u.attack_basic = u.get("attack_basic", u.attack) * r
	u.size = size
	refresh_size(u)
	if size > old + 0.04 and not sim.silent: sim.emit({"type": "grow", "uid": u.uid, "pos": u.pos, "size": size})

static func refresh_size(u: Dictionary) -> void:
	var over = maxf(0.0, u.size - float(u.get("born_size", 1.0)))
	var area = 1.0 + over * 0.5
	if has(u, "draught"): area += over * (1.0 if leg(u, "draught") else 0.5)
	if has(u, "archmage"): area += 0.5 if leg(u, "archmage") else 0.25
	u.area = area
	if has(u, "granite"): u.res = float(u.base_res) + over * 100.0 * (2.0 if leg(u, "granite") else 1.0)
	if has(u, "hooves"): u.buffs["hooves"] = {"as": over * (1.5 if leg(u, "hooves") else 0.8), "t": 9999.0}

# ---------------------------------------------------------------- setup and ticking
static func setup_unit(sim: BattleSim, u: Dictionary) -> void:
	u.forge = []; u.legends = []
	u.fx = {"last_hit": -10.0, "hits": 0, "base_interval": u.interval, "struck": {}, "crit": 0.0, "dodge": 0.0, "lifesteal": 0.0, "tenacity": 0.0,
		"stacks": {}, "casts": 0, "cast_n": 0, "banners": {}}
	if u.summon: return
	for id in carried(u.hero):
		if ITEMS.has(base_id(id)):
			u.forge.append(base_id(id))
			if is_legend(id): u.legends.append(base_id(id))
	var t = totals(u.hero)
	u.size_cap = t.size_cap
	refresh_size(u)
	if has(u, "hourglass"): u.mana = u.max_mana
	if has(u, "wildfire"): u.max_mana *= 0.4 if leg(u, "wildfire") else 0.6; u.mana = minf(u.mana, u.max_mana)
	if has(u, "belt"): set_size(sim, u, u.size + 0.10)

static func stack(u: Dictionary, key: String, n: int = 1, cap: int = 9999) -> int:
	var v = mini(cap, int(u.fx.stacks.get(key, 0)) + n)
	u.fx.stacks[key] = v
	return v

static func tick(sim: BattleSim, u: Dictionary, dt: float) -> void:
	if u.summon or not u.alive: return
	if float(u.get("drain", 0.0)) > 0.0 and u.hp > u.max_hp * 0.10: u.hp = maxf(u.max_hp * 0.10, u.hp - u.max_hp * float(u.drain) * dt)
	if u.get("doppel", false) and not u.fx.get("doppel_done", false) and sim.time > 0.1:
		u.fx.doppel_done = true
		var copy = sim.add_unit(u.hero, u.team, u.pos + Vector2(0.8, 0), 1.0, u.uid)
		copy.max_hp = u.max_hp * 0.5; copy.hp = copy.max_hp; copy.attack = u.attack * 0.5; copy.attack_basic = copy.attack
		copy.interval = u.interval; copy.range = u.range; copy.radius = u.radius; copy.ttl = 999.0; copy.size = u.size * 0.9
		copy.doppel_copy = true
		sim.emit({"type": "cast", "uid": u.uid, "effect": "vanish", "name": "Doppelganger", "pos": u.pos, "target": copy.pos})
	if u.forge.is_empty(): return
	var t = sim.time
	if not u.fx.get("opened", false) and t > 0.2:
		u.fx.opened = true
		if has(u, "aegis"):
			var big = leg(u, "aegis")
			for a in sim.living(u.team, false): sim.shield(a, (300.0 if big else 200.0) + u.max_hp * (0.08 if big else 0.05), 8.0)
			proc(sim, u, "aegis", u)
	if has(u, "aegis") and leg(u, "aegis") and not u.fx.get("aegis_refresh", false):
		var mates = sim.living(u.team, false); var hp = 0.0; var mx = 0.0
		for a in mates: hp += a.hp; mx += a.max_hp
		if mx > 0 and hp / mx < 0.5:
			u.fx.aegis_refresh = true
			for a in mates: sim.shield(a, 300.0 + u.max_hp * 0.08, 8.0)
			proc(sim, u, "aegis", u)
	if has(u, "belt") and ready(sim, u, "belt", 2.0):
		var cap = 2.4 if leg(u, "belt") else float(u.born_size) + 0.60 + float(u.get("belt_base", 0.0))
		if not u.has("belt_base"): u.belt_base = u.size - float(u.born_size) - 0.10
		if u.size < cap - 0.001:
			set_size(sim, u, minf(cap, u.size + 0.05))
			if not u.fx.banners.get("belt", false): proc(sim, u, "belt", u)
			if u.size >= cap - 0.001: banner(sim, u, "belt", "TITAN!")
	if has(u, "belt") and leg(u, "belt") and u.size >= 2.39 and ready(sim, u, "mountain_taunt", 3.0):
		for e in SignatureCast.within(sim, u, u.pos, 3): e.taunt_by = u.uid; sim.status(e, "taunt", 2.0)
	if has(u, "titanheart") and (leg(u, "titanheart") or u.size >= 1.5): sim.status(u, "unstoppable", 0.25)
	if has(u, "colossus"):
		var below = 0.70 if leg(u, "colossus") else 0.50
		if u.hp < u.max_hp * below: sim.heal(u, u, u.max_hp * 0.03 * dt, "item:colossus")
	if has(u, "bastion"):
		if leg(u, "bastion"):
			if ready(sim, u, "bastion", 8.0): sim.shield(u, u.max_hp * 0.25, 8.0); proc(sim, u, "bastion", u)
		elif not u.fx.get("bastion", false) and u.hp < u.max_hp * 0.5:
			u.fx.bastion = true; sim.shield(u, u.max_hp * 0.35, 5.0); proc(sim, u, "bastion", u)
	if has(u, "bottle") and t > 1.0 and ready(sim, u, "bottle", 3.0 if leg(u, "bottle") else 5.0):
		var pool = sim.foes(u)
		if sim.rng.randf() < 0.25: pool = sim.living(u.team, false).filter(func(a): return a.uid != u.uid)
		if not pool.is_empty():
			var v = pool[sim.rng.randi_range(0, pool.size() - 1)]
			sim.true_hit = false
			sim.hurt(u, v, SignatureCast.ap(u, 300.0 if leg(u, "bottle") else 200.0) / float(u.get("sig_mult", 1.0)), true, "item:bottle")
			sim.emit({"type": "bolt", "uid": u.uid, "pos": v.pos + Vector2(0, -0.1), "target": v.pos, "effect": "stormcall"})
			proc(sim, u, "bottle", v)
	if has(u, "turtle"):
		var hide_end = float(u.fx.get("turtle_end", -1.0))
		if hide_end > 0.0 and t >= hide_end:
			u.fx.turtle_end = -1.0; u.buffs["turtle"] = {"as": 0.30, "t": 6.0}
		var marks = [0.40, 0.20] if leg(u, "turtle") else [0.40]
		var used = int(u.fx.get("turtle_used", 0))
		if hide_end < 0.0 and used < marks.size() and u.hp < u.max_hp * float(marks[used]):
			u.fx.turtle_used = used + 1; u.fx.turtle_end = t + 3.0
			u.status["stun"] = 3.0; u.status["shell"] = 3.0
			sim.heal(u, u, u.max_hp * (0.40 if leg(u, "turtle") else 0.25), "item:turtle")
			proc(sim, u, "turtle", u)
	if has(u, "swap") and float(u.items.get("swap", -1.0)) <= t:
		for a in sim.living(u.team, false):
			if a.uid != u.uid and a.hp / a.max_hp < 0.25 and a.pos.distance_to(u.pos) < 12.0 and u.hp / u.max_hp > 0.4:
				ready(sim, u, "swap", 10.0)
				sim.swap_hexes(u, a)
				sim.shield(a, u.max_hp * 0.25)
				if leg(u, "swap"): a.status["divine"] = 2.0
				sim.emit({"type": "cast", "uid": u.uid, "effect": "vanish", "name": "Swap Charm", "pos": u.pos, "target": a.pos})
				proc(sim, u, "swap", a)
				break

static func ready(sim: BattleSim, u: Dictionary, id: String, cooldown: float) -> bool:
	if sim.time < float(u.items.get(id, -1.0)): return false
	u.items[id] = sim.time + cooldown
	return true

static func proc(sim: BattleSim, u: Dictionary, id: String, target: Dictionary) -> void:
	sim.track(u, "casts", 1, "item:" + id)
	if sim.silent: return
	if not u.fx.banners.has(id):
		u.fx.banners[id] = true
		var name = str(ITEMS[id].leg[0]) if leg(u, id) else str(ITEMS[id].name)
		sim.emit({"type": "item_banner", "uid": u.uid, "pos": u.pos, "item_id": id, "name": name.to_upper() + "!", "color": PATH_COLOR.get(str(ITEMS[id].path), "ffffff"), "legend": leg(u, id)})
	ItemFeedback.signal_effect(sim, u, id, target)

static func banner(sim: BattleSim, u: Dictionary, id: String, text: String) -> void:
	if sim.silent: return
	sim.emit({"type": "item_banner", "uid": u.uid, "pos": u.pos, "item_id": id, "name": text, "color": PATH_COLOR.get(str(ITEMS[id].path), "ffffff"), "legend": leg(u, id)})

# ---------------------------------------------------------------- damage
## Crit roll, crit-based and conditional multipliers, negation. Runs inside BattleSim.hurt before Resistance.
static func damage_mod(sim: BattleSim, source: Dictionary, target: Dictionary, amount: float, magical: bool, credit: String) -> float:
	sim.crit_mult = 0.0
	if float(target.get("fx", {}).get("turtle_end", -1.0)) > sim.time: return 0.0
	if target.get("status", {}).get("divine", 0.0) > 0.0: return 0.0
	var basic = credit == "basic"
	var item_hit = credit.begins_with("item:")
	# Signature negation (Runeward, Mirror of Ages).
	if credit == "signature" and not target.get("summon", true) and not target.forge.is_empty():
		var key = "%d:%d" % [source.uid, int(source.get("fx", {}).get("cast_n", 0))]
		if str(target.fx.get("negating", "")) == key: return 0.0
		var negate = false
		if has(target, "mirror") and leg(target, "mirror") and not target.fx.get("mirror_used", false): target.fx.mirror_used = true; negate = true
		elif has(target, "runeward") and ready(sim, target, "runeward", 5.0 if leg(target, "runeward") else 8.0): negate = true
		if negate:
			target.fx.negating = key
			sim.emit({"type": "blocked", "uid": target.uid, "source": source.uid, "pos": target.pos, "amount": amount, "credit": "item:runeward"})
			proc(sim, target, "runeward" if has(target, "runeward") else "mirror", source)
			if has(target, "runeward") and leg(target, "runeward"):
				for a in sim.living(target.team, false): sim.shield(a, ap(target, 150.0), 5.0)
			return 0.0
	if source.get("summon", true) or item_hit: return amount
	# Crits: basic attacks always can; the signature only with Jeweled Gauntlet.
	var can_crit = basic or (credit == "signature" and has(source, "gauntlet")) or credit == "counter"
	if can_crit:
		var chance = float(source.get("crit", 0.0)) + (0.25 if float(source.fx.get("overload_until", -1.0)) > sim.time else 0.0)
		var forced = credit == "counter" and leg(source, "spikes")
		if credit == "signature" and leg(source, "gauntlet") and not source.fx.get("starfall_done", true):
			source.fx.starfall_done = true; forced = true
		if forced or sim.rng.randf() < chance:
			var mult = float(source.get("crit_damage", 2.0))
			if has(source, "dragonedge") and not leg(source, "dragonedge") and target.hp / target.max_hp < 0.40: mult *= 2.0
			if has(target, "dragonscale"):
				target.res = float(target.res) + (8.0 if leg(target, "dragonscale") else 5.0)
				proc(sim, target, "dragonscale", source)
				mult = 1.0
			if mult > 1.0:
				sim.crit_mult = mult
				amount *= mult
				ItemFeedback.augment(sim, source, "crit", target)
		elif has(source, "gambler"):
			amount *= 0.70
	# Spellblade empowered attacks.
	if basic and int(source.fx.get("spellblade", 0)) > 0:
		source.fx.spellblade -= 1
		var big = leg(source, "spellblade")
		amount += source.attack * (2.0 if big else 1.0) + ap(source, 80.0 if big else 40.0)
		proc(sim, source, "spellblade", target)
	# Incoming modifiers.
	amount *= float(target.get("taken_mult", 1.0))
	if not target.get("summon", true):
		if has(target, "spurs"): amount *= 1.35 if leg(target, "spurs") else 1.25
		if has(target, "belt") and leg(target, "belt") and target.size >= 2.39: amount *= 0.60
		if has(target, "mirror") and credit == "signature" and not sim.reflecting:
			sim.reflecting = true; sim.hurt(target, source, amount * (1.0 if leg(target, "mirror") else 0.30), true, "item:mirror"); sim.reflecting = false
			if ready(sim, target, "mirror_fx", 1.0): proc(sim, target, "mirror", source)
		if has(target, "bastion") and leg(target, "bastion") and target.shield > 0 and not sim.reflecting:
			sim.reflecting = true; sim.hurt(target, source, amount * 0.50, true, "item:bastion"); sim.reflecting = false
		if has(target, "granite") and leg(target, "granite") and basic and not sim.reflecting:
			sim.reflecting = true; sim.hurt(target, source, amount * 0.20, true, "item:granite"); sim.reflecting = false
	return amount

## After damage lands (actual = HP lost). Most on-hit and when-hit items live here.
static func after_hit(sim: BattleSim, source: Dictionary, target: Dictionary, actual: float, magical: bool, credit: String) -> void:
	var crit = sim.last_crit
	var basic = credit == "basic"
	var item_hit = credit.begins_with("item:")
	# Bearer was hit.
	if not target.get("summon", true) and target.alive and not target.forge.is_empty() and actual > 0.0 and not item_hit:
		target.fx.last_hit = sim.time
		if has(target, "wrath") and ready(sim, target, "wrath", 0.25):
			var n = stack(target, "wrath", 1, 99999 if leg(target, "wrath") else 40)
			if n <= 40 or leg(target, "wrath"):
				target.attack *= 1.02; target.attack_basic *= 1.02
				if n <= 40: set_size(sim, target, target.size + 0.01)
				if n == 1: proc(sim, target, "wrath", target)
		if has(target, "thunderhide") and not sim.reflecting:
			var big = leg(target, "thunderhide")
			if (crit > 0.0 or credit == "signature" or (big and basic)) and ready(sim, target, "thunderhide", 2.0 if (basic and crit <= 0.0) else 0.5):
				sim.reflecting = true
				for e in SignatureCast.within(sim, target, target.pos, 2 if big else 1):
					sim.hurt(target, e, ap(target, 120.0 if big else 80.0), true, "item:thunderhide")
				sim.reflecting = false
				sim.emit({"type": "cast", "uid": target.uid, "effect": "stormcall", "name": "", "pos": target.pos, "target": target.pos})
				proc(sim, target, "thunderhide", target)
		if has(target, "spikes") and basic and source.alive and not sim.countering and source.uid != target.uid:
			if sim.rng.randf() < (0.60 if leg(target, "spikes") else 0.30) and sim.in_attack_range(target, source):
				sim.countering = true
				sim.hurt(target, source, target.get("attack_basic", target.attack), false, "counter")
				sim.countering = false
				proc(sim, target, "spikes", source)
	if source.get("summon", true) or item_hit: return
	if float(source.fx.get("lifesteal", 0.0)) > 0.0 and actual > 0.0: sim.heal(source, source, actual * float(source.fx.lifesteal), "item:lifesteal")
	if source.forge.is_empty(): return
	# Lifesteal (Bloodmoon Fang / Crimson Moon) on all damage.
	if has(source, "bloodmoon") and actual > 0.0:
		var big = leg(source, "bloodmoon")
		var heal_amount = actual * (0.40 if big else 0.20)
		var room = source.max_hp - source.hp
		if heal_amount > room:
			var over = heal_amount - room
			source.shield = minf(source.max_hp * (0.60 if big else 0.30), source.shield + over); source.shield_time = maxf(source.shield_time, 4.0)
		sim.heal(source, source, minf(heal_amount, room), "item:bloodmoon")
		if ready(sim, source, "bloodmoon_fx", 2.5): proc(sim, source, "bloodmoon", source)
	if crit > 0.0:
		if has(source, "talons"):
			if leg(source, "talons"): source.buffs["talons"] = {"as": float(source.buffs.get("talons", {}).get("as", 0.0)) + 0.12, "t": 9999.0}
			else: source.buffs["talons_%d" % stack(source, "talons_n")] = {"as": 0.08, "t": 5.0}
			proc(sim, source, "talons", source)
		if has(source, "overcharge"):
			source.mana = minf(source.max_mana, source.mana + (15.0 if leg(source, "overcharge") else 10.0))
			proc(sim, source, "overcharge", source)
		if has(source, "maul") and actual > 0.0:
			var big = leg(source, "maul")
			var radius = 2 if big else 1
			for e in SignatureCast.within(sim, source, target.pos, radius):
				if e.uid == target.uid: continue
				sim.hurt(source, e, actual * 0.5, true, "item:maul")
				if big: sim.status(e, "stun", 0.5)
			sim.emit({"type": "stomp", "uid": source.uid, "pos": target.pos, "radius": radius, "color": PATH_COLOR.giant})
			proc(sim, source, "maul", target)
		if crit >= 3.0:
			if has(source, "tempestcrown") and leg(source, "tempestcrown"):
				var near = sim.foes(source).filter(func(e): return e.uid != target.uid)
				near.sort_custom(func(a, b): return a.pos.distance_squared_to(target.pos) < b.pos.distance_squared_to(target.pos))
				for e in near.slice(0, 2):
					sim.hurt(source, e, actual * 0.5, true, "item:tempestcrown")
					sim.emit({"type": "bolt", "uid": source.uid, "pos": target.pos, "target": e.pos, "effect": "chain"})
			if has(source, "dragonedge") and leg(source, "dragonedge") and target.alive and target.hp < target.max_hp * 0.15:
				sim.true_hit = true; sim.hurt(source, target, target.hp + 1.0, true, "item:dragonedge"); sim.true_hit = false
				banner(sim, source, "dragonedge", "EXECUTED!")
		if credit == "signature" and has(source, "gauntlet") and ready(sim, source, "gauntlet_fx", 2.0): proc(sim, source, "gauntlet", target)
		if credit == "signature" and has(source, "gauntlet") and leg(source, "gauntlet") and actual > 0.0 and ready(sim, source, "starfall", 0.3):
			var pool = sim.foes(source)
			for i in range(mini(3, pool.size())):
				var e = pool[sim.rng.randi_range(0, pool.size() - 1)]
				sim.hurt(source, e, actual * 0.30, true, "item:gauntlet")
				sim.emit({"type": "bolt", "uid": source.uid, "pos": e.pos + Vector2(0.2, -0.2), "target": e.pos, "effect": "stormcall"})
	if not (basic or credit == "counter"): return
	# On basic attack.
	source.fx.hits = int(source.fx.hits) + 1
	var hits = int(source.fx.hits)
	if has(source, "quicksilver") and hits == 1: proc(sim, source, "quicksilver", source)
	if has(source, "quicksilver"): source.mana = minf(source.max_mana, source.mana + sim.MANA_PER_ATTACK * float(source.mana_gain) * (2.0 if leg(source, "quicksilver") else 1.0))
	if has(source, "frenzy"):
		var n = stack(source, "frenzy")
		source.buffs["frenzy"] = {"as": n * (0.08 if leg(source, "frenzy") else 0.05), "t": 9999.0}
		if n == 1 or n % 10 == 0: proc(sim, source, "frenzy", source)
	if has(source, "tusk") and target.alive:
		var big = leg(source, "tusk")
		var n = mini(int(target.fx.get("tusk_stacks", 0)) + 1, 10)
		target.fx["tusk_stacks"] = n
		target.buffs["tusk"] = {"res": -n * (8.0 if big else 4.0), "t": 6.0}
		sim.status(target, "scorch", 3.0); target.scorch_source = source.uid; target.scorch_factor = 0.30 if big else 0.60
		if n == 1: proc(sim, source, "tusk", target)
	if has(source, "tempest"):
		var big = leg(source, "tempest")
		var near = sim.foes(source).filter(func(e): return e.uid != target.uid and ArenaGrid.distance(e.cell, target.cell) <= 3)
		near.sort_custom(func(a, b): return a.pos.distance_squared_to(target.pos) < b.pos.distance_squared_to(target.pos))
		var from = target.pos
		for e in near.slice(0, 4 if big else 2):
			sim.hurt(source, e, source.get("attack_basic", source.attack) * (0.70 if big else 0.60), false, "item:tempest")
			sim.emit({"type": "bolt", "uid": source.uid, "pos": from, "target": e.pos, "effect": "chain"})
			from = e.pos
		if not near.is_empty() and ready(sim, source, "tempest_fx", 3.0): proc(sim, source, "tempest", target)
	if has(source, "club"):
		var big = leg(source, "club")
		var radius = 2 if big else 1
		var n = stack(source, "club")
		for e in SignatureCast.within(sim, source, target.pos, radius):
			if e.uid == target.uid: continue
			sim.hurt(source, e, source.attack * 0.60, false, "item:club")
			if big and n % 3 == 0: sim.status(e, "stun", 1.0)
		if big and n % 3 == 0: sim.status(target, "stun", 1.0)
		sim.emit({"type": "stomp", "uid": source.uid, "pos": target.pos, "radius": radius, "color": PATH_COLOR.giant, "quake": big and n % 3 == 0})
		if n == 1: proc(sim, source, "club", target)
	var wide = (has(source, "frenzy") and leg(source, "frenzy") and sim.attack_rate(source) >= 4.0) or (has(source, "wrath") and leg(source, "wrath") and int(source.fx.stacks.get("wrath", 0)) >= 40)
	if wide:
		for e in SignatureCast.within(sim, source, source.pos, 1):
			if e.uid != target.uid: sim.hurt(source, e, source.get("attack_basic", source.attack), false, "item:frenzy" if has(source, "frenzy") else "item:wrath")
	if has(source, "quiver"):
		if leg(source, "quiver"):
			if hits % 4 == 0: sim.echo_cast(source, target, 0.30); proc(sim, source, "quiver", target)
		elif hits % 3 == 0:
			sim.launch(source, target, ap(source, 60.0), 0.35, true, "wisps")
			sim.projectiles.back().credit = "item:quiver"
			proc(sim, source, "quiver", target)
	if has(source, "drum"):
		var big = leg(source, "drum")
		if hits % (3 if big else 5) == 0:
			var mates = sim.living(source.team, false) if big else SignatureCast.allies_within(sim, source, 2)
			for a in mates: a.buffs["drum"] = {"as": 0.40 if big else 0.25, "t": 3.0}
			sim.emit({"type": "stomp", "uid": source.uid, "pos": source.pos, "radius": 2, "color": PATH_COLOR.tempo, "soft": true})
			proc(sim, source, "drum", source)

static func on_cast(sim: BattleSim, u: Dictionary, target: Dictionary) -> void:
	if u.get("summon", false) or u.get("forge", []).is_empty(): return
	u.fx.cast_n = int(u.fx.get("cast_n", 0)) + 1
	u.fx.starfall_done = false
	var n = int(u.fx.cast_n)
	u.sig_scale = 1.0 * (1.20 if u.get("elite", false) else 1.0)
	if has(u, "hourglass"):
		var big = leg(u, "hourglass")
		if n <= (2 if big else 1): u.sig_scale *= 2.0 if big else 1.5; proc(sim, u, "hourglass", u)
	if has(u, "spellblade"): u.fx.spellblade = 3
	if has(u, "crown"):
		var big = leg(u, "crown")
		u.fx.crown_refund = 40.0 if big else 20.0
		if big and sim.rng.randf() < 0.25: u.fx.echo_pending = true; banner(sim, u, "crown", "ECHO!")
	if has(u, "patience"):
		var big = leg(u, "patience")
		if big or n <= 6:
			set_size(sim, u, u.size + (0.20 if big else 0.10))
			var add = 300.0 if big else 150.0
			u.max_hp += add; u.hp += add
			proc(sim, u, "patience", u)
	if has(u, "bell"):
		var amount = u.max_hp * 0.15
		var mates = sim.living(u.team, false) if leg(u, "bell") else [u]
		if not leg(u, "bell"):
			var others = sim.living(u.team, false).filter(func(a): return a.uid != u.uid)
			others.sort_custom(func(a, b): return a.pos.distance_squared_to(u.pos) < b.pos.distance_squared_to(u.pos))
			if not others.is_empty(): mates.append(others[0])
		for a in mates: sim.shield(a, amount, 5.0)
		proc(sim, u, "bell", u)
	if has(u, "quicksilver") and leg(u, "quicksilver"): u.buffs["quickening"] = {"as": 0.30, "t": 3.0}
	if has(u, "overcharge") and leg(u, "overcharge"): u.fx.overload_until = sim.time + 4.0
	if has(u, "wildfire"):
		var burn = u.max_hp * (0.08 if leg(u, "wildfire") else 0.05)
		u.hp = maxf(1.0, u.hp - burn)
		proc(sim, u, "wildfire", u)

## After the signature resolves: refunds and echoes.
static func after_cast(sim: BattleSim, u: Dictionary, target: Dictionary) -> void:
	if u.get("summon", false) or u.get("forge", []).is_empty(): return
	if float(u.fx.get("crown_refund", 0.0)) > 0.0:
		u.mana = minf(u.max_mana, u.mana + float(u.fx.crown_refund)); u.fx.crown_refund = 0.0
		proc(sim, u, "crown", u)
	if u.fx.get("echo_pending", false):
		u.fx.echo_pending = false
		sim.echo_cast(u, target, 1.0)

## Return true to cancel the death.
static func on_death(sim: BattleSim, u: Dictionary) -> bool:
	if has(u, "phoenix"):
		var big = leg(u, "phoenix")
		var used = int(u.fx.get("revived", 0))
		if used < (3 if big else 1):
			u.fx.revived = used + 1
			u.hp = u.max_hp * (0.35 if big else 0.30); u.status.clear(); u.dots.clear()
			var power = [150.0, 250.0, 400.0][mini(used, 2)]
			for e in SignatureCast.within(sim, u, u.pos, 1 + used):
				sim.hurt(u, e, ap(u, power), true, "item:phoenix")
			sim.emit({"type": "cast", "uid": u.uid, "effect": "rebirth", "name": "Phoenix Ember", "pos": u.pos, "target": u.pos})
			sim.emit({"type": "stomp", "uid": u.uid, "pos": u.pos, "radius": 1 + used, "color": "ff8a3a"})
			proc(sim, u, "phoenix", u)
			return true
	return false

static func on_kill(sim: BattleSim, killer: Dictionary, victim: Dictionary) -> void:
	if victim.summon: return
	if killer.get("puppets", false) and not killer.get("summon", false):
		var puppet = sim.add_unit(victim.hero, killer.team, victim.pos, 1.0, killer.uid)
		puppet.max_hp = victim.max_hp * 0.25; puppet.hp = puppet.max_hp; puppet.attack = victim.attack * 0.25; puppet.attack_basic = puppet.attack
		puppet.interval = victim.interval; puppet.range = victim.range; puppet.ttl = 999.0
		sim.emit({"type": "cast", "uid": killer.uid, "effect": "summons", "name": "Puppet Strings", "pos": victim.pos, "target": victim.pos})
	if killer.get("summon", false) or killer.get("forge", []).is_empty(): return
	if has(killer, "deathblade"):
		var big = leg(killer, "deathblade")
		var add = 30.0 if big else 15.0
		killer.attack += add; killer.attack_basic = killer.get("attack_basic", killer.attack) + add
		stack(killer, "deathblade")
		if big: killer.mana = killer.max_mana
		proc(sim, killer, "deathblade", killer)
	if not killer.alive: return
	if has(killer, "bloodfeast"):
		sim.heal(killer, killer, killer.max_hp * (1.0 if leg(killer, "bloodfeast") else 0.40), "item:bloodfeast")
		if leg(killer, "bloodfeast"): set_size(sim, killer, killer.size + 0.10)
		proc(sim, killer, "bloodfeast", killer)
	if has(killer, "bloodmoon") and leg(killer, "bloodmoon"):
		sim.heal(killer, killer, killer.max_hp * 0.30, "item:bloodmoon")

static func on_ally_death(_sim: BattleSim, _victim: Dictionary) -> void:
	pass

## Arriving on a new hex (Thunderhoof Greaves tramples).
static func on_move(sim: BattleSim, u: Dictionary) -> void:
	if u.get("summon", false) or not has(u, "hooves") or not ready(sim, u, "hooves_trample", 1.2): return
	var near = SignatureCast.within(sim, u, u.pos, 1)
	for e in near:
		SignatureCast.push(sim, e, u.pos, 1)
		if leg(u, "hooves"): sim.status(e, "stun", 0.5)
	if not near.is_empty():
		sim.emit({"type": "stomp", "uid": u.uid, "pos": u.pos, "radius": 1, "color": PATH_COLOR.giant})
		proc(sim, u, "hooves", u)

## A stun cuts Frenzy Horn's ramp in half (not for Hurricane Horn).
static func on_stunned(_sim: BattleSim, u: Dictionary) -> void:
	if u.get("summon", false) or not has(u, "frenzy") or leg(u, "frenzy"): return
	var n = int(u.fx.stacks.get("frenzy", 0)) / 2
	u.fx.stacks["frenzy"] = n
	u.buffs["frenzy"] = {"as": n * 0.05, "t": 9999.0}

static func status_mod(u: Dictionary, key: String, seconds: float) -> float:
	if key in ["stun", "root", "silence", "slow"]: seconds *= 1.0 - float(u.get("fx", {}).get("tenacity", 0.0))
	return seconds

static func heal_mod(target: Dictionary, amount: float, source: Dictionary = {}) -> float:
	if has(target, "bloodfeast") and source.get("uid", -1) != target.get("uid", -2): amount *= 0.50
	if target.get("relic_heal_cut", 0.0) > 0.0: amount *= 1.0 - float(target.relic_heal_cut)
	return amount

static func shield_mod(_target: Dictionary, amount: float) -> float:
	return amount

## Berserker's Totem (relic) overrides target choice: always the nearest enemy.
static func forced_target(_sim: BattleSim, u: Dictionary, all: Array) -> Dictionary:
	if not u.get("berserk", false) or all.is_empty(): return {}
	var best = all[0]
	for e in all:
		if u.pos.distance_squared_to(e.pos) < u.pos.distance_squared_to(best.pos): best = e
	return best

## Anvil: turn a finished item into its Legendary. Wild items: 50% Legendary, 50% destroyed.
## Returns "legendary", "destroyed" or "" when not allowed.
static func anvil(hero: Dictionary, slot: String, rng: RandomNumberGenerator) -> String:
	var id = str(hero.get("equipment", {}).get(slot, ""))
	if not ITEMS.has(id): return ""
	for v in carried(hero):
		if is_legend(v): return ""
	if is_wild(id) and rng.randf() < 0.5:
		hero.equipment.erase(slot)
		return "destroyed"
	hero.equipment[slot] = LEGEND + id
	return "legendary"

static func legend_held(hero: Dictionary) -> String:
	for v in carried(hero):
		if is_legend(v): return v
	return ""

## Old item ids (v0.76 and earlier) convert to v0.77 items.
static func migrate_id(id: String) -> String:
	if valid(id) and not RETIRED.has(id): return id
	if COMPONENTS.has(id): return id
	return str(RETIRED.get(id, id if valid(id) else ""))

# ---------------------------------------------------------------- rival gear
## Rival clubs: deterministic loadouts that grow with the tour level.
static func rival_loadout(hero: Dictionary, level: int, difficulty: String = "Standard") -> Dictionary:
	var budget = TourBalance.gear_budget(level, difficulty)
	var roll = abs(hash(str(hero.get("id", "")) + "|gear")) % 100
	var n = int(floor(budget)) + (1 if roll < float(fposmod(budget, 1)) * 100 else 0)
	n = mini(n, mini(3, HeroData.item_slots(hero)))
	var out = {}; var core = recommended(hero.sp, hero)
	for i in range(n): out[str(i)] = core[i]
	if n < mini(3, HeroData.item_slots(hero)):
		var next = core[n]; out[str(n)] = ITEMS[next].recipe[roll % 2]
	if difficulty == "Champion" and level >= 15 and roll < 25 and n > 0:
		var wilds = ["spurs", "bloodfeast", "gambler"] if Signatures.primary(hero.sp) in ["ad", "as"] else ["wildfire", "bottle", "giant"]
		out[str(n - 1)] = wilds[roll % wilds.size()]
	# Legendaries arrive from cup 4 (tour level 13+).
	if level >= 13 and n > 0 and roll < (15 + (level - 13) * 6):
		out["0"] = LEGEND + str(out["0"]) if ITEMS.has(str(out["0"])) else out["0"]
	return out

# ---------------------------------------------------------------- recommended builds
## Which path suits each species best (first is the core build).
const SPECIES_PATHS := {
	"minotaur": ["giant", "crit"], "golem": ["tank", "giant"], "troll": ["giant", "tank"], "wendigo": ["tempo", "sustain"],
	"direwolf": ["tempo", "spell"], "manticore": ["crit", "tempo"], "griffin": ["crit", "giant"], "kitsune": ["spell", "crit"],
	"wyvern": ["crit", "tempo"], "harpy": ["tempo", "crit"], "phoenix": ["spell", "tank"], "kirin": ["spell", "tempo"],
	"basilisk": ["spell", "tank"], "treant": ["spell", "tank"], "naga": ["spell", "tank"], "unicorn": ["spell", "tank"],
	"cerberus": ["tempo", "sustain"], "nemean": ["tank", "giant"], "yeti": ["tank", "giant"], "zaratan": ["giant", "tank"],
	"owlbear": ["tempo", "crit"], "hydra": ["tempo", "giant"], "chimera": ["crit", "spell"], "gargoyle": ["giant", "crit"],
	"nekomata": ["crit", "sustain"], "jackalope": ["tempo", "crit"], "cyclops": ["crit", "giant"], "thunderbird": ["spell", "tempo"],
	"sphinx": ["spell", "tank"], "pegasus": ["spell", "tank"], "arachne": ["spell", "tempo"], "salamander": ["spell", "giant"],
}
const RECOMMENDED := {
	"minotaur": ["club", "titanheart", "dragonedge"], "golem": ["bastion", "granite", "aegis"], "troll": ["belt", "club", "colossus"],
	"wendigo": ["frenzy", "bloodmoon", "tempest"], "direwolf": ["frenzy", "quiver", "drum"], "manticore": ["dragonedge", "tempestcrown", "talons"],
	"griffin": ["dragonedge", "deathblade", "tempestcrown"], "kitsune": ["archmage", "gauntlet", "crown"], "wyvern": ["dragonedge", "tempestcrown", "quicksilver"],
	"harpy": ["frenzy", "tempest", "talons"], "phoenix": ["archmage", "crown", "phoenix"], "kirin": ["archmage", "gauntlet", "crown"],
	"basilisk": ["crown", "hourglass", "runeward"], "treant": ["archmage", "bell", "crown"], "naga": ["archmage", "aegis", "crown"],
	"unicorn": ["archmage", "bell", "hourglass"], "cerberus": ["frenzy", "bloodmoon", "tusk"], "nemean": ["aegis", "bastion", "titanheart"],
	"yeti": ["granite", "bastion", "thunderhide"], "zaratan": ["belt", "colossus", "granite"], "owlbear": ["frenzy", "tempestcrown", "talons"],
	"hydra": ["frenzy", "belt", "bloodmoon"], "chimera": ["dragonedge", "spellblade", "tempestcrown"], "gargoyle": ["club", "titanheart", "maul"],
	"nekomata": ["dragonedge", "deathblade", "bloodmoon"], "jackalope": ["frenzy", "tempestcrown", "talons"], "cyclops": ["dragonedge", "tempestcrown", "maul"],
	"thunderbird": ["archmage", "quiver", "gauntlet"], "sphinx": ["crown", "hourglass", "archmage"], "pegasus": ["hourglass", "aegis", "crown"],
	"arachne": ["archmage", "crown", "quiver"], "salamander": ["archmage", "draught", "crown"],
}

static func recommended(sp: String, _hero: Dictionary = {}) -> Array:
	return RECOMMENDED.get(sp, ["archmage", "crown", "colossus"]).duplicate()

## Is this offer part of the champion's recommended build? "core" = the finished item itself,
## "part" = a component of one, "" = neither. Returns [kind, item_id].
static func rec_match(sp: String, id: String, hero: Dictionary = {}) -> Array:
	for r in recommended(sp, hero):
		if r == base_id(id): return ["core", r]
	for r in recommended(sp, hero):
		if ITEMS.has(r) and id in ITEMS[r].recipe: return ["part", r]
	return ["", ""]
