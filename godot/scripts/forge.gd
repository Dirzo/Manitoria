class_name Forge
extends RefCounted
## Auto-battler itemisation: eight components, and every pair of components forges one of
## 36 finished items. Components carry stats; finished items add an effect, and the wild ones
## change how the champion behaves. Each champion carries up to three items. Dropping a second
## component onto a champion who holds a loose component forges them together.

const SLOTS := 3
const COMPONENT_PRICE := 70
const ITEM_PRICE := 190

const COMPONENTS := {
	"fang":     {"name": "Sharpened Fang", "art": "comp:fang", "attack": 0.12, "short": "+12% attack damage"},
	"hide":     {"name": "Troll Hide", "art": "comp:hide", "hp": 0.10, "short": "+10% health"},
	"plate":    {"name": "Bronze Plate", "art": "comp:plate", "armor": 0.05, "short": "+5 armor"},
	"feather":  {"name": "Roc Feather", "art": "comp:feather", "haste": 0.09, "short": "+9% attack speed"},
	"ember":    {"name": "Ember Shard", "art": "comp:ember", "potency": 0.12, "short": "+12% ability power"},
	"moon":     {"name": "Moonstone", "art": "comp:moon", "cd": 0.92, "short": "8% shorter skill cooldowns"},
	"seed":     {"name": "Sapling Heart", "art": "comp:seed", "hp": 0.05, "potency": 0.06, "short": "+5% health, +6% ability power"},
	"storm":    {"name": "Storm Glass", "art": "comp:storm", "crit": 0.12, "short": "+12% critical strike chance"},
	"silk":     {"name": "Shadow Silk", "art": "comp:silk", "dodge": 0.10, "short": "+10% chance to dodge basic attacks"},
	"venom":    {"name": "Venom Gland", "art": "comp:venom", "lifesteal": 0.06, "short": "+6% lifesteal on all damage"},
	"relic":    {"name": "Holy Relic", "art": "comp:relic", "tenacity": 0.30, "hp": 0.07, "short": "+30% crowd-control resistance, +7% health"},
	"coin":     {"name": "Trickster's Coin", "art": "comp:coin", "attack": 0.04, "hp": 0.04, "short": "+4% attack damage and health · forges wild items"},
}
const COMPONENT_ORDER := ["fang", "hide", "plate", "feather", "ember", "moon", "seed", "storm", "silk", "venom", "relic", "coin"]

# Finished items. "x" holds extra stats on top of the two components. "wild" items rewrite behaviour.
const ITEMS := {
	"bloodmaw":    {"recipe": ["fang", "fang"], "name": "Bloodmaw", "art": "drain", "text": "Basic attacks heal for 18% of the damage dealt."},
	"titan":       {"recipe": ["fang", "hide"], "name": "Titan's Wrath", "art": "prideroar", "text": "When hit, gain 1.5% attack damage (max 16 stacks)."},
	"tusk":        {"recipe": ["fang", "plate"], "name": "Shieldbreaker Tusk", "art": "gore", "text": "Basic attacks ignore 30% armor and deal +60% to shields."},
	"frenzy":      {"recipe": ["fang", "feather"], "name": "Frenzy Horn", "art": "howl", "text": "Each basic attack grants 3% attack speed for the rest of the fight (max 8 stacks)."},
	"spellblade":  {"recipe": ["fang", "ember"], "name": "Spellblade", "art": "beam", "text": "After casting a skill, your next basic attack deals 120% bonus damage."},
	"executioner": {"recipe": ["fang", "moon"], "name": "Executioner's Edge", "art": "execute", "text": "+50% basic damage to enemies under 30% health. Kills instantly ready your signature."},
	"thornlash":   {"recipe": ["fang", "seed"], "name": "Thornroot Lash", "art": "roots", "text": "Every fourth basic attack roots the target for 0.8s."},
	"berserker":   {"recipe": ["fang", "coin"], "name": "Berserker's Totem", "art": "maul", "wild": true, "x": {"attack": 0.20, "speed": 0.20}, "text": "WILD: ignores tactics and always charges the nearest enemy. +20% attack damage, +20% move speed, but heals on you are 30% weaker."},
	"colossus":    {"recipe": ["hide", "hide"], "name": "Colossus Heart", "art": "vigor", "x": {"hp": 0.15}, "text": "+15% more health. Regenerate 1.2% health per second after 3s without being hit."},
	"bastion":     {"recipe": ["hide", "plate"], "name": "Bastion Shell", "art": "shellup", "text": "The first time you fall below 50% health, gain a shield of 24% max health."},
	"drum":        {"recipe": ["hide", "feather"], "name": "Rhythm Drum", "art": "rally", "text": "Every 7s, nearby allies gain Rally (+22% damage and speed) for 2.5s."},
	"phoenixember":{"recipe": ["hide", "ember"], "name": "Phoenix Ember", "art": "rebirth", "wild": true, "text": "WILD: the first time you would die, burst back to life at 25% health."},
	"bell":        {"recipe": ["hide", "moon"], "name": "Taunting Bell", "art": "shriek", "text": "Every 8s, enemies within 3.5m must attack you for 2s, and you gain an 8% shield."},
	"lifebloom":   {"recipe": ["hide", "seed"], "name": "Lifebloom", "art": "regrowth", "text": "Every 5s, heal the most wounded nearby ally for 1.6% of your max health."},
	"giant":       {"recipe": ["hide", "coin"], "name": "Giant's Draught", "art": "boulder", "wild": true, "x": {"hp": 0.25, "attack": 0.10, "speed": -0.15}, "text": "WILD: grow huge. +25% health and +10% attack damage, but 15% slower."},
	"mirror":      {"recipe": ["plate", "plate"], "name": "Mirror Carapace", "art": "ward", "x": {"hp": 0.08}, "text": "+8% more health. Reflect 25% of ability damage taken back at the caster."},
	"spikes":      {"recipe": ["plate", "feather"], "name": "Spiked Gauntlet", "art": "whirl", "text": "When hit by a basic attack, 45% chance to stun the attacker for 0.8s (3s cooldown)."},
	"runeward":    {"recipe": ["plate", "ember"], "name": "Runeward", "art": "radiance", "text": "Negate the first enemy ability that hits you every 12 seconds."},
	"stoneskin":   {"recipe": ["plate", "moon"], "name": "Stoneskin", "art": "stonedive", "x": {"hp": 0.10}, "text": "+10% health. Immune to stun, root and silence while above 50% health."},
	"ironbark":    {"recipe": ["plate", "seed"], "name": "Ironbark", "art": "guardian", "text": "Take 12% less damage from every source."},
	"turtle":      {"recipe": ["plate", "coin"], "name": "Turtle Shell", "art": "shellup", "wild": true, "text": "WILD: below 40% health, hide in your shell for 3s (invulnerable, can't act, heal 18%), then burst out with Rally for 7s."},
	"tempest":     {"recipe": ["feather", "feather"], "name": "Tempest Talons", "art": "skystrike", "text": "Basic attacks bounce to a second enemy for 40% damage."},
	"quiver":      {"recipe": ["feather", "ember"], "name": "Arcane Quiver", "art": "barrage", "text": "Every third basic attack explodes for 60% ability power around the target."},
	"quicksilver": {"recipe": ["feather", "moon"], "name": "Quicksilver", "art": "gust", "text": "Each basic attack shortens all your skill cooldowns by 0.25s."},
	"hunter":      {"recipe": ["feather", "seed"], "name": "Hunter's Mark", "art": "ambush", "text": "Basic attacks Weaken the target (-25% damage) for 2s."},
	"sugarrush":   {"recipe": ["feather", "coin"], "name": "Sugar Rush", "art": "tailwind", "wild": true, "x": {"haste": 0.40, "speed": 0.30}, "text": "WILD: +40% attack speed and +30% move speed, but lose 0.6% max health every second (stops at 15%)."},
	"archmage":    {"recipe": ["ember", "ember"], "name": "Archmage Orb", "art": "arcanist", "x": {"potency": 0.20}, "text": "+20% extra ability power."},
	"crown":       {"recipe": ["ember", "moon"], "name": "Blue Crown", "art": "stormcall", "x": {"cd": 0.88}, "text": "Skills recharge 12% faster (plus the Moonstone)."},
	"scepter":     {"recipe": ["ember", "seed"], "name": "Verdant Scepter", "art": "renew", "text": "Ability damage also heals your most wounded ally for 25% of it."},
	"chaos":       {"recipe": ["ember", "coin"], "name": "Chaos Die", "art": "riddle", "wild": true, "text": "WILD: every skill rolls the die: a free extra blast, a team-wide heal, or a fizzle that stuns you."},
	"hourglass":   {"recipe": ["moon", "moon"], "name": "Hourglass Crest", "art": "tidal", "x": {"cd": 0.90}, "text": "Start the fight with your signature ready. Skills recharge 10% faster (plus both Moonstones)."},
	"spiritbell":  {"recipe": ["moon", "seed"], "name": "Spirit Bell", "art": "wisps", "text": "When an ally falls, gain a 14% shield and Rally for 4s."},
	"puppet":      {"recipe": ["moon", "coin"], "name": "Puppet Strings", "art": "summons", "wild": true, "text": "WILD: enemies you finish rise as small puppets that fight for you."},
	"worldtree":   {"recipe": ["seed", "seed"], "name": "World Tree Seed", "art": "rootbloom", "text": "Heals and shields on you are 30% stronger. Regenerate 0.8% health per second."},
	"swap":        {"recipe": ["seed", "coin"], "name": "Swap Charm", "art": "vanish", "wild": true, "text": "WILD: when an ally drops below 25% health, teleport to swap places with them and shield them (10s cooldown)."},
	# ---- Storm Glass
	"thundercleaver": {"recipe": ["storm", "fang"], "name": "Thundercleaver", "art": "chain", "text": "Critical strikes arc lightning to 2 nearby enemies for 50% of the hit."},
	"stormmantle":    {"recipe": ["storm", "hide"], "name": "Stormhide Mantle", "art": "stormcall", "text": "Every 5s, zap the nearest enemy for 60% ability power."},
	"lightningrod":   {"recipe": ["storm", "plate"], "name": "Lightning Rod", "art": "storm", "text": "When an enemy ability hits you, zap the caster for 80% attack (2s cooldown)."},
	"galetalons":     {"recipe": ["storm", "feather"], "name": "Gale Talons", "art": "skystrike", "x": {"crit": 0.10}, "text": "+10% more crit chance. Critical strikes grant Rally for 3s."},
	"stormorb":       {"recipe": ["storm", "ember"], "name": "Stormcaller Orb", "art": "storm", "text": "Your abilities can critically strike."},
	"overcharge":     {"recipe": ["storm", "moon"], "name": "Overcharge Crown", "art": "beam", "x": {"crit": 0.08}, "text": "+8% more crit chance. Critical strikes shorten your skill cooldowns by 0.65s (1s cooldown)."},
	"rainbringer":    {"recipe": ["storm", "seed"], "name": "Rainbringer", "art": "tidal", "text": "Critical strikes heal your most wounded ally for 30% of the damage."},
	"bottle":         {"recipe": ["storm", "coin"], "name": "Lightning in a Bottle", "art": "stormcall", "wild": true, "text": "WILD: every 7s a bolt strikes a random enemy for 120% attack... and sometimes an ally."},
	"tempestcrown":   {"recipe": ["storm", "storm"], "name": "Tempest Crown", "art": "stormcall", "x": {"crit": 0.18}, "text": "+18% more crit chance. Your critical strikes deal 180% damage."},
	"flicker":        {"recipe": ["storm", "silk"], "name": "Flicker Strike", "art": "ambush", "x": {"crit": 0.12, "attack": 0.08}, "text": "+12% more crit chance, +8% attack damage. Critical strikes blink you behind your target."},
	"galvanic":       {"recipe": ["storm", "venom"], "name": "Galvanic Venom", "art": "acid", "x": {"crit": 0.10}, "text": "+10% more crit chance. Critical strikes on poisoned enemies deal +70% damage."},
	"judgement":      {"recipe": ["storm", "relic"], "name": "Judgement Bolt", "art": "radiance", "text": "Every 7s, smite the weakest enemy for 75% ability power."},
	# ---- Shadow Silk
	"shadowblade":    {"recipe": ["silk", "fang"], "name": "Shadowblade", "art": "vanish", "text": "After dodging, your next basic attack deals +100% damage."},
	"phantomcloak":   {"recipe": ["silk", "hide"], "name": "Phantom Cloak", "art": "wisps", "text": "Dodging an attack heals you for 3% max health."},
	"smokeplate":     {"recipe": ["silk", "plate"], "name": "Smoke Bomb Plate", "art": "fear", "text": "The first time you fall below 50% health, vanish for 2s and shake off stuns and roots."},
	"windwalker":     {"recipe": ["silk", "feather"], "name": "Windwalker Sash", "art": "gust", "x": {"speed": 0.20, "dodge": 0.05}, "text": "+20% move speed, +5% dodge. Dodging grants Rally for 2s."},
	"illusion":       {"recipe": ["silk", "ember"], "name": "Illusionist's Veil", "art": "foxfire", "text": "Casting a skill turns you invisible for 1s."},
	"eclipse":        {"recipe": ["silk", "moon"], "name": "Eclipse Mask", "art": "silence", "text": "Dodging shortens your skill cooldowns by 0.5s."},
	"wispshroud":     {"recipe": ["silk", "seed"], "name": "Will-o'-Wisp Shroud", "art": "wisps", "text": "Dodging heals your most wounded ally for 2% of your max health."},
	"doppel":         {"recipe": ["silk", "coin"], "name": "Doppelganger Cloak", "art": "vanish", "wild": true, "text": "WILD: at 50% health, a shadow copy of you tears free and fights for 10s."},
	"nightshroud":    {"recipe": ["silk", "silk"], "name": "Nightshroud", "art": "vanish", "x": {"dodge": 0.15}, "text": "+15% more dodge. Begin every fight invisible for 3s."},
	"assassinkit":    {"recipe": ["silk", "venom"], "name": "Assassin's Kit", "art": "ambush", "text": "Your first hit on each enemy deals +80% damage."},
	"wardshroud":     {"recipe": ["silk", "relic"], "name": "Ward Shroud", "art": "ward", "text": "Your dodge chance also works against abilities."},
	# ---- Venom Gland
	"viperfang":      {"recipe": ["venom", "fang"], "name": "Viper Fang", "art": "venom", "text": "Basic attacks poison the target for 18% attack over 3s."},
	"leechhide":      {"recipe": ["venom", "hide"], "name": "Leech Hide", "art": "drain", "text": "Your lifesteal is doubled below 40% health."},
	"acidshell":      {"recipe": ["venom", "plate"], "name": "Acid Shell", "art": "acid", "text": "Enemies who hit you with basic attacks are poisoned."},
	"needles":        {"recipe": ["venom", "feather"], "name": "Needle Storm", "art": "barrage", "text": "Every fourth basic attack fires 3 venom darts at random enemies (40% each)."},
	"plaguetome":     {"recipe": ["venom", "ember"], "name": "Plague Tome", "art": "toxic", "text": "Your abilities also poison for 40% of their damage over 4s."},
	"witherbloom":    {"recipe": ["venom", "moon"], "name": "Witherbloom", "art": "brood", "x": {"potency": 0.06, "cd": 0.95}, "text": "+6% ability power, 5% faster skills. Your abilities Weaken their targets (-25% damage) for 4s."},
	"grievous":       {"recipe": ["venom", "seed"], "name": "Grievous Thorns", "art": "roots", "text": "Your hits cut enemy healing by 50% for 3s."},
	"bloodfeast":     {"recipe": ["venom", "coin"], "name": "Bloodfeast", "art": "hunger", "wild": true, "text": "WILD: kills heal 30% max health. Heals from allies are 25% weaker."},
	"hydravenom":     {"recipe": ["venom", "venom"], "name": "Hydra Venom", "art": "venom", "text": "All of your hits poison for 27% attack over 3s."},
	"antidote":       {"recipe": ["venom", "relic"], "name": "Antidote Charm", "art": "renew", "x": {"hp": 0.12}, "text": "+12% health. Poisons and burns on you wear off three times as fast; regenerate 2% health per second while afflicted."},
	# ---- Holy Relic
	"crusader":       {"recipe": ["relic", "fang"], "name": "Crusader's Edge", "art": "execute", "text": "+25% damage while you are above 70% health."},
	"martyr":         {"recipe": ["relic", "hide"], "name": "Martyr's Heart", "art": "renew", "text": "While above 50% health, heal allies within 4m for 1% of your max health each second."},
	"aegis":          {"recipe": ["relic", "plate"], "name": "Sanctified Aegis", "art": "bulwark", "text": "Start every fight by shielding all allies for 8% of your max health."},
	"pilgrim":        {"recipe": ["relic", "feather"], "name": "Pilgrim's Boots", "art": "tailwind", "x": {"speed": 0.12}, "text": "+12% move speed. Immune to slows."},
	"halo":           {"recipe": ["relic", "ember"], "name": "Halo of Dawn", "art": "radiance", "x": {"potency": 0.10, "hp": 0.05}, "text": "+10% ability power, +5% health. Your skills cleanse stuns, roots and silences from the nearest ally."},
	"rosary":         {"recipe": ["relic", "moon"], "name": "Saint's Rosary", "art": "rally", "text": "Your first skill of the fight heals the whole team for 5%."},
	"chalice":        {"recipe": ["relic", "seed"], "name": "Chalice of Renewal", "art": "regrowth", "x": {"potency": 0.08}, "text": "+8% more ability power. Heals you give are 25% stronger."},
	"divine":         {"recipe": ["relic", "coin"], "name": "Divine Intervention", "art": "guardian", "wild": true, "text": "WILD: once per fight, the first ally to fall below 15% becomes invulnerable for 2.5s."},
	"grail":          {"recipe": ["relic", "relic"], "name": "Holy Grail", "art": "radiance", "x": {"tenacity": 0.35}, "text": "+35% more crowd-control resistance. Regenerate 0.9% health per second."},
	"idol":        {"recipe": ["coin", "coin"], "name": "Golden Idol", "art": "victory", "wild": true, "text": "WILD: +60 gold after every match you win, but the bearer takes 10% more damage."},
}

static var _recipes: Dictionary = {}

static func is_component(id: String) -> bool: return COMPONENTS.has(id)
static func is_item(id: String) -> bool: return ITEMS.has(id)
static func valid(id: String) -> bool: return COMPONENTS.has(id) or ITEMS.has(id)

static func combine(a: String, b: String) -> String:
	if _recipes.is_empty():
		for id in ITEMS:
			var r = ITEMS[id].recipe; _recipes[_key(r[0], r[1])] = id
	return str(_recipes.get(_key(a, b), ""))

static func _key(a: String, b: String) -> String:
	return a + "+" + b if a < b else b + "+" + a

static func info(id: String) -> Dictionary:
	if COMPONENTS.has(id):
		var c = COMPONENTS[id].duplicate(); c.id = id; c.kind = "component"; c.rarity = "Common"; c.price = COMPONENT_PRICE
		c.description = c.short + "\nCombine with another component to forge a finished item."
		return c
	if ITEMS.has(id):
		var it = ITEMS[id].duplicate(); it.id = id; it.kind = "item"; it.sfx = it.art; it.art = "item:" + id; it.rarity = "Legendary" if it.get("wild", false) else "Rare"; it.price = ITEM_PRICE
		it.description = it.text + "\n" + stat_line(id)
		return it
	return {}

## Stat contributions of one item or component.
static func stats_of(id: String) -> Dictionary:
	var out = {"hp": 0.0, "attack": 0.0, "armor": 0.0, "haste": 0.0, "speed": 0.0, "potency": 0.0, "cd": 1.0, "crit": 0.0, "dodge": 0.0, "lifesteal": 0.0, "tenacity": 0.0}
	var parts = [id] if COMPONENTS.has(id) else (ITEMS[id].recipe if ITEMS.has(id) else [])
	for p in parts:
		var c = COMPONENTS[p]
		for k in c:
			if k == "cd": out.cd *= float(c.cd)
			elif out.has(k) and k != "cd": out[k] += float(c[k])
	if ITEMS.has(id):
		for k in ITEMS[id].get("x", {}):
			if k == "cd": out.cd *= float(ITEMS[id].x.cd)
			else: out[k] += float(ITEMS[id].x[k])
	return out

static func stat_line(id: String) -> String:
	var s = stats_of(id); var parts = []
	if s.attack != 0: parts.append("%+d%% attack damage" % roundi(s.attack * 100))
	if s.hp != 0: parts.append("%+d%% health" % roundi(s.hp * 100))
	if s.armor != 0: parts.append("%+d armor" % roundi(s.armor * 100))
	if s.haste != 0: parts.append("%+d%% attack speed" % roundi(s.haste * 100))
	if s.speed != 0: parts.append("%+d%% move" % roundi(s.speed * 100))
	if s.potency != 0: parts.append("%+d%% ability power" % roundi(s.potency * 100))
	if s.cd != 1.0: parts.append("%d%% faster skills" % roundi((1.0 - s.cd) * 100))
	if s.crit != 0: parts.append("%+d%% crit" % roundi(s.crit * 100))
	if s.dodge != 0: parts.append("%+d%% dodge" % roundi(s.dodge * 100))
	if s.lifesteal != 0: parts.append("%+d%% lifesteal" % roundi(s.lifesteal * 100))
	if s.tenacity != 0: parts.append("%+d%% CC resistance" % roundi(s.tenacity * 100))
	return " · ".join(parts)

static func carried(hero: Dictionary) -> Array:
	var out = []
	for v in hero.get("equipment", {}).values():
		if valid(str(v)): out.append(str(v))
	return out

static func totals(hero: Dictionary) -> Dictionary:
	var t = {"hp": 0.0, "attack": 0.0, "armor": 0.0, "haste": 0.0, "speed": 0.0, "potency": 0.0, "cd": 1.0, "crit": 0.0, "dodge": 0.0, "lifesteal": 0.0, "tenacity": 0.0}
	for id in carried(hero):
		var s = stats_of(id)
		for k in t:
			if k == "cd": t.cd *= s.cd
			else: t[k] += s[k]
	return t

static func has(u: Dictionary, id: String) -> bool:
	return not u.get("summon", false) and id in u.get("forge", [])

# ---------------------------------------------------------------- combat hooks
static func setup_unit(sim: BattleSim, u: Dictionary) -> void:
	u.forge = [] if u.summon else carried(u.hero).filter(func(i): return ITEMS.has(i))
	u.fx = {"last_hit": -10.0, "titan": 0, "frenzy": 0, "hits": 0, "base_interval": u.interval, "struck": {}}
	if not u.summon:
		var t = totals(u.hero)
		u.fx.crit = minf(0.60,t.crit); u.fx.dodge = minf(0.45, t.dodge); u.fx.lifesteal = t.lifesteal; u.fx.tenacity = minf(0.65, t.tenacity)
	if has(u, "hourglass"): u.cd = 0.4
	if has(u, "giant"): u.radius *= 1.2

static func tick(sim: BattleSim, u: Dictionary, dt: float) -> void:
	if u.forge.is_empty() or not u.alive: return
	var t = sim.time
	if has(u, "colossus") and t - u.fx.last_hit > 3.0 and u.hp < u.max_hp: sim.heal(u, u, u.max_hp * 0.012 * dt, "item:colossus")
	if has(u, "worldtree") and u.hp < u.max_hp: sim.heal(u, u, u.max_hp * 0.008 * dt, "item:worldtree")
	if has(u, "sugarrush") and u.hp > u.max_hp * 0.15: u.hp = maxf(u.max_hp * 0.15, u.hp - u.max_hp * 0.006 * dt)
	if has(u, "drum") and ready(sim, u, "drum", 7.0):
		for a in sim.living(u.team, false):
			if a.pos.distance_to(u.pos) <= 5.0: sim.status(a, "rally", 2.5)
		proc(sim, u, "drum", u)
	if has(u, "bell") and t > 2.0:
		var near = sim.near_foes(u, u.pos, 3.5)
		if not near.is_empty() and ready(sim, u, "bell", 8.0):
			for e in near: e.taunt_by = u.uid; sim.status(e, "taunt", 2.0)
			sim.shield(u, u.max_hp * 0.08)
			proc(sim, u, "bell", u)
	if has(u, "lifebloom"):
		var hurt = sim.living(u.team, false).filter(func(a): return a.hp < a.max_hp and a.pos.distance_to(u.pos) <= 6.0)
		if not hurt.is_empty() and ready(sim, u, "lifebloom", 5.0):
			hurt.sort_custom(func(a, b): return a.hp / a.max_hp < b.hp / b.max_hp)
			sim.heal(u, hurt[0], u.max_hp * 0.016, "item:lifebloom"); proc(sim, u, "lifebloom", hurt[0])
	if has(u, "swap") and float(u.items.get("swap", -1.0)) <= t:
		for a in sim.living(u.team, false):
			if a.uid != u.uid and a.hp / a.max_hp < 0.25 and a.pos.distance_to(u.pos) < 12.0 and u.hp / u.max_hp > 0.4:
				ready(sim, u, "swap", 10.0)
				sim.swap_hexes(u, a)
				sim.shield(a, u.max_hp * 0.15)
				sim.emit({"type": "cast", "uid": u.uid, "effect": "vanish", "name": "Swap Charm", "pos": u.pos, "target": a.pos})
				proc(sim, u, "swap", a)
				break
	if not u.fx.get("opened", false):
		u.fx.opened = true
		if has(u, "nightshroud"): sim.status(u, "stealth", 3.0); proc(sim,u,"nightshroud",u)
		if has(u, "aegis"):
			for a in sim.living(u.team, false): sim.shield(a, u.max_hp * 0.08)
			proc(sim, u, "aegis", u)
	if has(u, "stormmantle") and t > 1.0:
		var near = sim.foes(u); near.sort_custom(func(a, b): return u.pos.distance_squared_to(a.pos) < u.pos.distance_squared_to(b.pos))
		if not near.is_empty() and u.pos.distance_to(near[0].pos) < 8.0 and ready(sim, u, "stormmantle", 5.0):
			sim.hurt(u, near[0], u.ability_power * 0.6, true, "item:stormmantle"); proc(sim, u, "stormmantle", near[0])
	if has(u, "judgement") and t > 1.0:
		var foes = sim.foes(u)
		if not foes.is_empty() and ready(sim, u, "judgement", 7.0):
			foes.sort_custom(func(a, b): return a.hp / a.max_hp < b.hp / b.max_hp)
			sim.hurt(u, foes[0], u.ability_power * 0.75, true, "item:judgement"); proc(sim, u, "judgement", foes[0])
	if has(u, "bottle") and t > 1.0 and ready(sim, u, "bottle", 7.0):
		var pool = sim.foes(u) if sim.rng.randf() > 0.12 else sim.living(u.team, false)
		if not pool.is_empty():
			var victim = pool[sim.rng.randi_range(0, pool.size() - 1)]
			sim.hurt(u, victim, u.attack * 1.2, true, "item:bottle"); proc(sim, u, "bottle", victim)
	if has(u, "grail") and u.hp < u.max_hp: sim.heal(u, u, u.max_hp * 0.009 * dt, "item:grail")
	if has(u, "martyr") and u.hp / u.max_hp > 0.5:
		for a in sim.living(u.team, false):
			if a.uid != u.uid and a.hp < a.max_hp and a.pos.distance_to(u.pos) <= 4.0: sim.heal(u, a, u.max_hp * 0.01 * dt, "item:martyr")
	if has(u, "antidote") and not u.dots.is_empty():
		for d in u.dots: d.remaining -= dt * 2.0
		sim.heal(u, u, u.max_hp * 0.02 * dt, "item:antidote")
	if has(u, "divine") and not u.fx.get("divine_used", false):
		for a in sim.living(u.team, false):
			if a.hp / a.max_hp < 0.15:
				u.fx.divine_used = true; a.status["divine"] = 2.5; proc(sim, u, "divine", a); break
	if has(u, "turtle") and u.fx.get("turtle_end", -1.0) > 0 and t >= u.fx.turtle_end:
		u.fx.turtle_end = -1.0; sim.status(u, "rally", 7.0)

static func ready(sim: BattleSim, u: Dictionary, id: String, cooldown: float) -> bool:
	if sim.time < float(u.items.get(id, -1.0)): return false
	u.items[id] = sim.time + cooldown
	return true

static func proc(sim: BattleSim, u: Dictionary, id: String, target: Dictionary) -> void:
	sim.track(u, "casts", 1, "item:" + id)
	ItemFeedback.signal_effect(sim,u,id,target)

## Damage shaping, before armor and shields.
static func damage_mod(sim: BattleSim, source: Dictionary, target: Dictionary, amount: float, magical: bool, credit: String) -> float:
	if target.get("fx", {}).get("turtle_end", -1.0) > sim.time: return 0.0
	if target.get("status", {}).get("divine", 0.0) > 0.0: return 0.0
	var basic = credit == "basic"
	var item_hit = credit.begins_with("item:")
	# Dodge.
	var dodge = float(target.get("fx", {}).get("dodge", 0.0))
	if dodge > 0.0 and not item_hit and (basic or has(target, "wardshroud")) and sim.rng.randf() < dodge:
		target.fx.dodged = true
		if has(target, "shadowblade"): target.fx.shadow_primed = true
		if has(target, "phantomcloak"): sim.heal(target, target, target.max_hp * 0.03, "item:phantomcloak")
		if has(target, "windwalker"): sim.status(target, "rally", 2.0)
		if has(target, "eclipse"):
			target.cd = maxf(0.0, target.cd - 0.5)
			for k in target.ability_cds: target.ability_cds[k] = maxf(0.0, float(target.ability_cds[k]) - 0.5)
		if has(target, "wispshroud"):
			var hurt = sim.living(target.team, false).filter(func(a): return a.hp < a.max_hp)
			if not hurt.is_empty():
				hurt.sort_custom(func(a, b): return a.hp / a.max_hp < b.hp / b.max_hp); sim.heal(target, hurt[0], target.max_hp * 0.02, "item:wispshroud")
		ItemFeedback.augment(sim,target,"dodge",target)
		for id in ["shadowblade","windwalker","eclipse","wardshroud"]:
			if has(target,id):proc(sim,target,id,target)
		sim.emit({"type": "dodge", "uid": target.uid, "pos": target.pos})
		return 0.0
	if source.get("fx", {}).has("crit") and not item_hit:
		source.fx.last_crit = false
		if (basic or has(source, "stormorb")) and sim.rng.randf() < float(source.fx.crit):
			source.fx.last_crit = true
			ItemFeedback.augment(sim,source,"crit",target)
			amount *= 1.8 if has(source, "tempestcrown") else 1.5
			if has(source, "galvanic") and target.get("status", {}).get("poison", 0.0) > 0.0: amount *= 1.7
	if not source.get("forge", []).is_empty() and not item_hit:
		if has(source, "crusader") and source.hp / source.max_hp > 0.7: amount *= 1.25; proc(sim,source,"crusader",target)
		if has(source, "assassinkit") and not source.fx.struck.has(target.uid): source.fx.struck[target.uid] = true; amount *= 1.8; proc(sim,source,"assassinkit",target)
		if basic and has(source, "shadowblade") and source.fx.get("shadow_primed", false): source.fx.shadow_primed = false; amount += source.attack * 1.0; proc(sim, source, "shadowblade", target)
	if not source.get("forge", []).is_empty():
		if basic and has(source, "executioner") and target.hp / target.max_hp < 0.3: amount *= 1.5; proc(sim,source,"executioner",target)
		if basic and has(source, "spellblade") and source.fx.get("primed", false):
			source.fx.primed = false; amount += source.attack * 1.2; proc(sim, source, "spellblade", target)
		if basic and has(source, "tusk"):
			amount *= 1.0 + target.armor * 0.3
			if target.shield > 0: amount *= 1.6
			proc(sim,source,"tusk",target)
	if not target.get("forge", []).is_empty():
		if has(target, "ironbark"): amount *= 0.88; proc(sim,target,"ironbark",target)
		if has(target, "idol"): amount *= 1.10; proc(sim,target,"idol",target)
		if not basic and not credit.begins_with("item:") and has(target, "runeward") and ready(sim, target, "runeward", 12.0):
			proc(sim, target, "runeward", source); return 0.0
	return amount

## After damage lands.
static func after_hit(sim: BattleSim, source: Dictionary, target: Dictionary, actual: float, magical: bool, credit: String) -> void:
	var basic = credit == "basic"
	if not target.get("forge", []).is_empty() and target.alive and actual > 0:
		target.fx.last_hit = sim.time
		if has(target, "titan") and target.fx.titan < 16 and ready(sim, target, "titan", 0.4):
			target.fx.titan += 1; target.attack *= 1.015; target.attack_basic = target.get("attack_basic", target.attack) * 1.015; proc(sim,target,"titan",target)
		if has(target, "bastion") and target.hp / target.max_hp < 0.5 and not target.fx.get("bastion", false):
			target.fx.bastion = true; sim.shield(target, target.max_hp * 0.24); proc(sim, target, "bastion", target)
		if basic and has(target, "spikes") and source.alive and sim.rng.randf() < 0.45 and ready(sim, target, "spikes", 3.0):
			sim.status(source, "stun", 0.8); proc(sim, target, "spikes", source)
		if not basic and not credit.begins_with("item:") and has(target, "mirror") and source.alive and not source.summon:
			sim.hurt(target, source, actual * 0.25, true, "item:mirror")
		if not basic and not credit.begins_with("item:") and has(target, "lightningrod") and source.alive and ready(sim, target, "lightningrod", 2.0):
			sim.hurt(target, source, target.attack * 0.8, true, "item:lightningrod"); proc(sim, target, "lightningrod", source)
		if basic and has(target, "acidshell") and source.alive: sim.poison(target, source, 3.0, target.attack * 0.08, "poison"); proc(sim,target,"acidshell",source)
		if has(target, "smokeplate") and target.hp / target.max_hp < 0.5 and not target.fx.get("smoked", false):
			target.fx.smoked = true
			for k in ["stun", "root", "slow"]: target.status.erase(k)
			sim.status(target, "stealth", 2.0); proc(sim, target, "smokeplate", target)
		if has(target, "doppel") and target.hp / target.max_hp < 0.5 and not target.fx.get("doppel", false):
			target.fx.doppel = true
			var copy = sim.add_unit(target.hero, target.team, target.pos + Vector2(0.8, 0.0), 1.0, target.uid)
			copy.ttl = 10.0; copy.max_hp *= 1.6; copy.hp = copy.max_hp; copy.attack *= 1.6; copy.attack_basic = copy.attack
			sim.emit({"type": "summon", "uid": target.uid, "pos": target.pos}); proc(sim, target, "doppel", target)
		if has(target, "turtle") and target.hp / target.max_hp < 0.4 and not target.fx.get("turtled", false) and target.hp > 0:
			target.fx.turtled = true; target.fx.turtle_end = sim.time + 3.0; sim.status(target, "stun", 3.0); sim.heal(target, target, target.max_hp * 0.18, "item:turtle"); proc(sim, target, "turtle", target)
	if not source.alive or actual <= 0: return
	var item_hit = credit.begins_with("item:")
	var ls = float(source.get("fx", {}).get("lifesteal", 0.0))
	if ls > 0.0 and not item_hit:
		if has(source, "leechhide") and source.hp / source.max_hp < 0.4: ls *= 2.0
		sim.heal(source, source, actual * ls, "item:lifesteal")
	if source.get("forge", []).is_empty(): return
	if not item_hit:
		if source.fx.get("last_crit", false):
			source.fx.last_crit = false
			if has(source, "thundercleaver"):
				var arcs = sim.foes(source).filter(func(e): return e.uid != target.uid and e.pos.distance_to(target.pos) <= 3.5)
				for e in arcs.slice(0, 2): sim.hurt(source, e, actual * 0.5, true, "item:thundercleaver")
			if has(source, "galetalons"): sim.status(source, "rally", 3.0); proc(sim,source,"galetalons",source)
			if has(source, "overcharge") and ready(sim,source,"overcharge",1.0):
				source.cd = maxf(0.0, source.cd - 0.65)
				for k in source.ability_cds: source.ability_cds[k] = maxf(0.0, float(source.ability_cds[k]) - 0.65)
				proc(sim,source,"overcharge",source)
			if has(source, "rainbringer"):
				var hurt = sim.living(source.team, false).filter(func(a): return a.hp < a.max_hp)
				if not hurt.is_empty():
					hurt.sort_custom(func(a, b): return a.hp / a.max_hp < b.hp / b.max_hp); sim.heal(source, hurt[0], actual * 0.3, "item:rainbringer")
			if has(source, "flicker") and target.alive:
				var dir = (target.pos - source.pos).normalized()
				sim.relocate_hex(source, target.pos + dir * ArenaGrid.ROW_GAP); proc(sim,source,"flicker",target)
		if has(source, "grievous") and target.alive: target.scorch_source = source.uid; sim.status(target, "scorch", 3.0); proc(sim,source,"grievous",target)
		if has(source, "hydravenom") and target.alive: sim.poison(source, target, 3.0, source.attack * 0.09, "poison"); proc(sim,source,"hydravenom",target)
		if not basic:
			if has(source, "plaguetome") and target.alive: sim.poison(source, target, 4.0, actual * 0.1, "poison"); proc(sim,source,"plaguetome",target)
			if has(source, "witherbloom") and target.alive: sim.status(target, "weaken", 4.0); proc(sim,source,"witherbloom",target)
	if basic:
		if has(source, "viperfang") and target.alive: sim.poison(source, target, 3.0, source.attack * 0.06, "poison"); proc(sim,source,"viperfang",target)
		if has(source, "needles") and (source.fx.hits + 1) % 4 == 0:
			var pool = sim.foes(source)
			for i in range(mini(3, pool.size())): sim.hurt(source, pool[sim.rng.randi_range(0, pool.size() - 1)], source.attack * 0.4, false, "item:needles")
			proc(sim, source, "needles", target)
		source.fx.hits += 1
		if has(source, "bloodmaw"): sim.heal(source, source, actual * 0.18, "item:bloodmaw")
		if has(source, "frenzy") and source.fx.frenzy < 8:
			source.fx.frenzy += 1; source.interval = source.fx.base_interval / (1.0 + 0.03 * source.fx.frenzy); proc(sim,source,"frenzy",source)
		if has(source, "thornlash") and source.fx.hits % 4 == 0 and target.alive: sim.status(target, "root", 0.8); proc(sim, source, "thornlash", target)
		if has(source, "hunter") and target.alive: sim.status(target, "weaken", 2.0); proc(sim,source,"hunter",target)
		if has(source, "quicksilver"):
			source.cd = maxf(0.0, source.cd - 0.25)
			for k in source.ability_cds: source.ability_cds[k] = maxf(0.0, float(source.ability_cds[k]) - 0.25)
			proc(sim,source,"quicksilver",source)
		if has(source, "tempest"):
			var others = sim.foes(source).filter(func(e): return e.uid != target.uid and e.pos.distance_to(target.pos) <= 3.0)
			if not others.is_empty(): sim.hurt(source, others[0], actual * 0.4, false, "item:tempest")
		if has(source, "quiver") and source.fx.hits % 3 == 0:
			for e in sim.near_foes(source, target.pos, 1.6): sim.hurt(source, e, source.ability_power * 0.6, true, "item:quiver")
			proc(sim, source, "quiver", target)
	elif not credit.begins_with("item:") and has(source, "scepter"):
		var hurt = sim.living(source.team, false).filter(func(a): return a.hp < a.max_hp)
		if not hurt.is_empty():
			hurt.sort_custom(func(a, b): return a.hp / a.max_hp < b.hp / b.max_hp)
			sim.heal(source, hurt[0], actual * 0.25, "item:scepter")

static func on_cast(sim: BattleSim, u: Dictionary, target: Dictionary) -> void:
	if u.get("forge", []).is_empty() or u.get("casting_chaos", false): return
	if has(u, "spellblade"): u.fx.primed = true
	if has(u, "illusion"): sim.status(u, "stealth", 1.0); proc(sim,u,"illusion",u)
	if has(u, "halo"):
		var allies = sim.living(u.team, false).filter(func(a): return a.uid != u.uid and (sim.active(a, "stun") or sim.active(a, "root") or sim.active(a, "silence")))
		if not allies.is_empty():
			allies.sort_custom(func(a, b): return u.pos.distance_squared_to(a.pos) < u.pos.distance_squared_to(b.pos))
			for k in ["stun", "root", "silence"]: allies[0].status.erase(k)
			proc(sim, u, "halo", allies[0])
	if has(u, "rosary") and not u.fx.get("rosary", false):
		u.fx.rosary = true
		for a in sim.living(u.team, false): sim.heal(u, a, a.max_hp * 0.05, "item:rosary")
		proc(sim, u, "rosary", u)
	if has(u, "chaos") and not target.is_empty():
		var roll = sim.rng.randi_range(0, 2)
		if roll == 0:
			u.casting_chaos = true
			for e in sim.near_foes(u, target.pos, 2.2): sim.hurt(u, e, u.ability_power * 0.8, true, "item:chaos")
			u.erase("casting_chaos")
		elif roll == 1:
			for a in sim.living(u.team, false): sim.heal(u, a, a.max_hp * 0.03, "item:chaos")
		else:
			sim.status(u, "stun", 0.8)
		proc(sim, u, "chaos", target)

## Return true to cancel the death.
static func on_death(sim: BattleSim, u: Dictionary) -> bool:
	if has(u, "phoenixember") and not u.fx.get("revived", false):
		u.fx.revived = true; u.hp = u.max_hp * 0.25; u.status.clear(); u.dots.clear()
		sim.emit({"type": "cast", "uid": u.uid, "effect": "rebirth", "name": "Phoenix Ember", "pos": u.pos, "target": u.pos})
		proc(sim, u, "phoenixember", u)
		return true
	return false

static func on_kill(sim: BattleSim, killer: Dictionary, victim: Dictionary) -> void:
	if killer.get("forge", []).is_empty() or victim.summon: return
	if has(killer, "executioner"): killer.cd = 0.0
	if has(killer, "bloodfeast") and killer.alive: sim.heal(killer, killer, killer.max_hp * 0.30, "item:bloodfeast"); proc(sim, killer, "bloodfeast", killer)
	if has(killer, "puppet") and killer.alive:
		var puppet = sim.add_unit(victim.hero, killer.team, victim.pos, 1.0, killer.uid)
		puppet.ttl = 12.0
		sim.emit({"type": "summon", "uid": killer.uid, "pos": victim.pos})
		proc(sim, killer, "puppet", victim)

static func on_ally_death(sim: BattleSim, victim: Dictionary) -> void:
	for a in sim.living(victim.team, false):
		if has(a, "spiritbell"):
			sim.shield(a, a.max_hp * 0.14); sim.status(a, "rally", 4.0); proc(sim, a, "spiritbell", a)

static func status_mod(u: Dictionary, key: String, seconds: float) -> float:
	if key == "slow" and has(u, "pilgrim"): return 0.0
	if key in ["stun", "root", "silence", "slow"]: seconds *= 1.0 - float(u.get("fx", {}).get("tenacity", 0.0))
	if key in ["stun", "root", "silence"] and has(u, "stoneskin") and u.hp / u.max_hp > 0.5 and not u.get("fx", {}).get("turtle_end", -1.0) > 0: return 0.0
	return seconds

static func heal_mod(target: Dictionary, amount: float, source: Dictionary = {}) -> float:
	if has(source, "chalice"): amount *= 1.25
	if has(target, "bloodfeast") and source.get("uid", -1) != target.get("uid", -2): amount *= 0.75
	if has(target, "worldtree"): amount *= 1.3
	if has(target, "berserker"): amount *= 0.7
	return amount

static func shield_mod(target: Dictionary, amount: float) -> float:
	return amount * (1.3 if has(target, "worldtree") else 1.0)

## Berserker's Totem overrides target choice.
static func forced_target(sim: BattleSim, u: Dictionary, all: Array) -> Dictionary:
	if not has(u, "berserker") or all.is_empty(): return {}
	var best = all[0]
	for e in all:
		if u.pos.distance_squared_to(e.pos) < u.pos.distance_squared_to(best.pos): best = e
	return best

## Rival clubs: deterministic loadouts that grow with the tour level.
## `level` is the tour stage (1-20 across five cups). A fractional item budget staggers
## finished items across bearers; a component bridges milestones. One compatible wild item at most.
static func rival_loadout(hero: Dictionary, level: int, difficulty: String = "Standard") -> Dictionary:
	var budget=TourBalance.gear_budget(level,difficulty)
	var roll=abs(hash(str(hero.get("id",""))+"|gear"))%100
	var n=int(floor(budget))+(1 if roll<float(fposmod(budget,1))*100 else 0)
	n=mini(n,mini(3,HeroData.item_slots(hero)))
	var out={};var core=recommended(hero.sp,hero)
	for i in range(n):out[str(i)]=core[i]
	# A loose component bridges finished-item milestones at player-accessible cost.
	if n<mini(3,HeroData.item_slots(hero)):
		var next=core[n];out[str(n)]=ITEMS[next].recipe[roll%2]
	# Wild effects arrive late, at most one per bearer, with stat-compatible choices.
	if difficulty=="Champion" and level>=15 and roll<25 and n>0:
		var ad=SkillScaling.audited(hero.sp,"signature").get("build_path","ap")=="ad"
		var wild=["berserker","bloodfeast","bottle"] if ad else ["chaos","phoenixember","doppel"]
		out[str(n-1)]=wild[roll%wild.size()]
	if difficulty=="Champion" and level>=20 and roll<20 and HeroData.item_slots(hero)>=4:
		out["3"]=COMPONENT_ORDER[roll%COMPONENT_ORDER.size()]
	return out

# ------------------------------------------------------------------ recommended builds
## A core build per species: three finished items that suit its kit and role.
const RECOMMENDED := {
	"minotaur": ["titan", "bloodmaw", "stoneskin"], "golem": ["bastion", "bell", "mirror"], "troll": ["colossus", "worldtree", "titan"],
	"wendigo": ["bloodmaw", "leechhide", "frenzy"], "direwolf": ["frenzy", "tempest", "executioner"], "manticore": ["viperfang", "assassinkit", "galvanic"],
	"griffin": ["shadowblade", "crusader", "executioner"], "kitsune": ["illusion", "eclipse", "archmage"], "wyvern": ["plaguetome", "archmage", "crown"],
	"harpy": ["tempest", "frenzy", "galetalons"], "phoenix": ["archmage", "stormorb", "crown"], "kirin": ["archmage", "stormorb", "crown"],
	"basilisk": ["witherbloom", "crown", "plaguetome"], "treant": ["chalice", "scepter", "lifebloom"], "naga": ["rosary", "aegis", "chalice"],
	"unicorn": ["halo", "rosary", "martyr"], "cerberus": ["frenzy", "bloodmaw", "spellblade"], "nemean": ["titan", "ironbark", "aegis"],
	"yeti": ["ironbark", "stoneskin", "spikes"], "zaratan": ["bell", "colossus", "runeward"], "owlbear": ["crusader", "titan", "thornlash"],
	"hydra": ["worldtree", "hydravenom", "grievous"], "chimera": ["spellblade", "crusader", "quicksilver"], "gargoyle": ["runeward", "stormmantle", "archmage"],
	"nekomata": ["assassinkit", "shadowblade", "nightshroud"], "jackalope": ["frenzy", "pilgrim", "executioner"], "cyclops": ["tusk", "executioner", "spellblade"],
	"thunderbird": ["archmage", "stormorb", "crown"], "sphinx": ["crown", "hourglass", "witherbloom"], "pegasus": ["drum", "rosary", "pilgrim"],
	"arachne": ["archmage", "crown", "plaguetome"], "salamander": ["plaguetome", "archmage", "grievous"],
}

static func recommended(sp: String,hero: Dictionary={}) -> Array:
	HeroData.load_data()
	var champion=hero if not hero.is_empty() else {"sp":sp,"learned":{}}
	var weights=SkillScaling.build_weights(champion)
	var effects=[HeroData.species[sp].ab]
	for key in champion.get("learned",{}):effects.append(HeroData.learned_ability(sp,int(key)).effect)
	var evolution_skill=Evolutions.grant_index(str(champion.get("evolution","")))
	if evolution_skill>=0:effects.append(HeroData.learned_ability(sp,evolution_skill).effect)
	var healing=effects.any(func(effect):return effect in ["renew","radiance","rootbloom","regrowth"])
	var ranked=[]
	for id in ITEMS:
		if ITEMS[id].get("wild",false):continue
		var stats=stats_of(id)
		var score=stats.attack/0.12*weights.ad+stats.potency/0.12*weights.ap+stats.haste/0.09*weights["as"]+stats.armor/0.05*weights.armor+stats.hp/0.10*weights.hp+(1.0-stats.cd)/0.08*weights.cd
		if id in ["bloodmaw","tusk","frenzy","executioner","tempest","thornlash","crusader","shadowblade","assassinkit","thundercleaver","galetalons"]:score+=1.2*(weights.ad+weights["as"])
		if id in ["archmage","stormorb","plaguetome","witherbloom","quiver","stormmantle"]:score+=1.2*weights.ap
		if id in ["bell","bastion","ironbark","mirror","spikes","stoneskin","aegis","runeward"]:score+=weights.armor+weights.hp
		if id in ["colossus","worldtree","lifebloom","grail"]:score+=weights.hp
		if id in ["crown","hourglass","quicksilver","overcharge"]:score+=weights.cd
		if id=="spellblade":score+=minf(weights.ad,weights.ap)*2.0+weights.cd*0.5
		if healing and id=="chalice":score+=2.3*weights.ap
		if HeroData.species[sp].role=="Support" and id in ["halo","rosary","scepter","lifebloom"]:score+=1.3
		if id in RECOMMENDED.get(sp,[]):score+=1.0
		ranked.append({"id":id,"score":score})
	# Stable ties keep offers and item hints consistent across redraws.
	ranked.sort_custom(func(a,b):return a.score>b.score if not is_equal_approx(a.score,b.score) else a.id<b.id)
	return ranked.slice(0,3).map(func(row):return row.id)

## Is this offer part of the champion's recommended build? "core" = the finished item itself,
## "part" = a component of one, "" = neither. Returns [kind, item_id].
static func rec_match(sp: String, id: String,hero: Dictionary={}) -> Array:
	for r in recommended(sp,hero):
		if r == id: return ["core", r]
	for r in recommended(sp,hero):
		if ITEMS.has(r) and id in ITEMS[r].recipe: return ["part", r]
	return ["", ""]
