class_name Evolutions
extends RefCounted
## Level-10 evolutions: three unique choices per species, each pushing the champion into a niche.
## An evolution can change stats, strengthen or speed up its signature, sharpen its learned skills,
## add a brand-new ability, and give combat perks. Keys are "<species>:<index>".
##
## mods  : hp / attack / speed / haste / potency (multipliers), armor (added), cd (skill cooldown multiplier)
## sig   : signature {power, cd}       skills: learned abilities {power, cd}
## grant : a new ability {effect, name, cd} (effect from HeroData.EFFECTS)
## perks : lifesteal (share of basic damage healed) · ward (shield the most wounded ally for this share of
##         max health on every cast) · on_hit [rider, chance] (basic attacks) · thorns (share of damage
##         taken reflected) · execute (bonus damage to foes under 35% health) · regen (share of max health per second)
## look  : arena aura style (ravager / guardian / arcanist)

const DATA := {
 "minotaur": [
  {"name": "Labyrinth Juggernaut", "niche": "Line breaker", "look": "guardian", "color": "e0a46b", "mods": {"hp": 1.12, "armor": 0.04}, "sig": {"power": 1.25, "cd": 0.85},
   "text": "Gore Charge hits 25% harder and returns 15% sooner. +12% health, +4 armor."},
  {"name": "Bloodhorn Berserker", "niche": "Frontline carry", "look": "ravager", "color": "ff6b4a", "mods": {"attack": 1.18, "haste": 1.10, "hp": 0.92}, "perks": {"lifesteal": 0.10},
   "text": "+18% damage, +10% attack speed, heals 10% of basic damage. -8% health."},
  {"name": "Maze Warden", "niche": "Area control", "look": "arcanist", "color": "c9a26b", "grant": {"effect": "quake", "name": "Labyrinth Quake", "cd": 14.0}, "perks": {"on_hit": ["stun", 0.08]},
   "text": "New ability Labyrinth Quake: slams and stuns everyone nearby. Basic attacks have an 8% stun chance."},
 ],
 "golem": [
  {"name": "Living Fortress", "niche": "Unbreakable wall", "look": "guardian", "color": "c8c0a8", "mods": {"hp": 1.18, "armor": 0.06, "speed": 0.9}, "sig": {"power": 1.2},
   "text": "+18% health, +6 armor, Bulwark shields 20% more. -10% move speed."},
  {"name": "Shardbound Sentinel", "niche": "Punishing tank", "look": "ravager", "color": "8fd8ff", "mods": {"hp": 1.06}, "perks": {"thorns": 0.18},
   "text": "Crystal skin reflects 18% of all damage taken back at the attacker. +6% health."},
  {"name": "Runebound Monolith", "niche": "Team protector", "look": "arcanist", "color": "ffe3a1", "grant": {"effect": "ward", "name": "Rune Ward", "cd": 15.0}, "perks": {"ward": 0.04},
   "text": "New ability Rune Ward shields the team. Every cast also shields the most wounded ally for 4% of its health."},
 ],
 "troll": [
  {"name": "Mossblood Colossus", "niche": "Attrition tank", "look": "guardian", "color": "7fbf6a", "mods": {"hp": 1.12}, "perks": {"regen": 0.008},
   "text": "Regenerates 0.8% of max health every second, on top of its troll regeneration. +12% health."},
  {"name": "Bonecrusher", "niche": "Slow-and-smash bruiser", "look": "ravager", "color": "d39a55", "mods": {"attack": 1.15}, "sig": {"power": 1.3, "cd": 0.9}, "perks": {"on_hit": ["chill", 0.2]},
   "text": "Club Smash hits 30% harder and comes back 10% faster. +15% damage; basic attacks often chill."},
  {"name": "Bog Shaman", "niche": "Frontline healer", "look": "arcanist", "color": "8fe0a0", "grant": {"effect": "renew", "name": "Bog Renewal", "cd": 13.0}, "mods": {"potency": 1.15},
   "text": "New ability Bog Renewal heals nearby allies. +15% ability power."},
 ],
 "wendigo": [
  {"name": "Winter Devourer", "niche": "Sustain duelist", "look": "ravager", "color": "a9e5ff", "mods": {"attack": 1.1}, "perks": {"lifesteal": 0.14}, "sig": {"cd": 0.85},
   "text": "Heals 14% of basic damage; Endless Hunger returns 15% sooner. +10% damage."},
  {"name": "Hollow Stalker", "niche": "Finisher", "look": "ravager", "color": "d591d8", "mods": {"speed": 1.12}, "perks": {"execute": 0.35},
   "text": "Deals 35% more damage to foes under 35% health. +12% move speed."},
  {"name": "Frostbitten Horror", "niche": "Fear controller", "look": "arcanist", "color": "9fc8ff", "grant": {"effect": "fear", "name": "Dread Howl", "cd": 15.0}, "perks": {"on_hit": ["chill", 0.25]},
   "text": "New ability Dread Howl terrifies nearby foes. Basic attacks often chill."},
 ],
 "direwolf": [
  {"name": "Moonfang Alpha", "niche": "Pack leader", "look": "guardian", "color": "c9d6ff", "sig": {"power": 1.3, "cd": 0.85}, "mods": {"hp": 1.08},
   "text": "Pack Howl pups hit 30% harder and are called 15% sooner. +8% health."},
  {"name": "Bloodtrail Hunter", "niche": "Back-line chaser", "look": "ravager", "color": "ff7a5c", "mods": {"speed": 1.15, "attack": 1.1}, "perks": {"on_hit": ["venom", 0.25]},
   "text": "+15% move speed, +10% damage; bites often leave a bleeding wound."},
  {"name": "Spirit Wolf", "niche": "Team booster", "look": "arcanist", "color": "8fb8ff", "grant": {"effect": "rally", "name": "Moon Rally", "cd": 14.0}, "mods": {"potency": 1.1},
   "text": "New ability Moon Rally boosts nearby allies' damage and speed. +10% ability power."},
 ],
 "manticore": [
  {"name": "Venom Sovereign", "niche": "Poison assassin", "look": "ravager", "color": "b7ed69", "sig": {"power": 1.35}, "perks": {"on_hit": ["venom", 0.35]},
   "text": "Tail Venom poisons 35% harder; basic attacks often poison too."},
  {"name": "Desert Reaper", "niche": "Executioner", "look": "ravager", "color": "ffb36b", "mods": {"attack": 1.12}, "perks": {"execute": 0.4},
   "text": "Deals 40% more damage to foes under 35% health. +12% damage."},
  {"name": "Spined Bulwark", "niche": "Spiked skirmisher", "look": "guardian", "color": "c8a070", "mods": {"hp": 1.15, "armor": 0.03}, "perks": {"thorns": 0.15},
   "text": "Spines reflect 15% of damage taken. +15% health, +3 armor."},
 ],
 "griffin": [
  {"name": "Crown of the Skies", "niche": "Back-line diver", "look": "ravager", "color": "ffd36e", "sig": {"power": 1.25, "cd": 0.8}, "mods": {"speed": 1.1},
   "text": "Skystrike hits 25% harder and returns 20% sooner. +10% move speed."},
  {"name": "Stormwing Raptor", "niche": "Attack-speed carry", "look": "ravager", "color": "8bdfff", "mods": {"haste": 1.18, "attack": 1.05}, "perks": {"on_hit": ["stun", 0.06]},
   "text": "+18% attack speed, +5% damage; talons can stun."},
  {"name": "Aerie Guardian", "niche": "Peel diver", "look": "guardian", "color": "f0e6c8", "grant": {"effect": "gust", "name": "Aerie Gust", "cd": 12.0}, "mods": {"hp": 1.12},
   "text": "New ability Aerie Gust blasts foes away from your back line. +12% health."},
 ],
 "kitsune": [
  {"name": "Ninefold Oracle", "niche": "Illusion caster", "look": "arcanist", "color": "cbb1ff", "mods": {"potency": 1.2, "cd": 0.9},
   "text": "+20% ability power and 10% faster skills."},
  {"name": "Foxfire Duelist", "niche": "Flame skirmisher", "look": "ravager", "color": "ff9a5c", "mods": {"attack": 1.12}, "perks": {"on_hit": ["burn", 0.3]},
   "text": "+12% damage; basic attacks often set foes alight."},
  {"name": "Shrine Keeper", "niche": "Spirit support", "look": "guardian", "color": "ffe9c0", "grant": {"effect": "wisps", "name": "Shrine Wisps", "cd": 12.0}, "perks": {"ward": 0.03},
   "text": "New ability Shrine Wisps. Every cast shields the most wounded ally for 3% of its health."},
 ],
 "wyvern": [
  {"name": "Plaguewing", "niche": "Area denial", "look": "arcanist", "color": "b7ed69", "sig": {"power": 1.3, "cd": 0.85}, "mods": {"potency": 1.1},
   "text": "Acid Pool burns 30% harder and returns 15% sooner. +10% ability power."},
  {"name": "Venomlance", "niche": "Ranged carry", "look": "ravager", "color": "9be05a", "mods": {"attack": 1.12, "haste": 1.08}, "perks": {"on_hit": ["venom", 0.25]},
   "text": "+12% damage, +8% attack speed; spit often poisons."},
  {"name": "Skyscale Drake", "niche": "Durable artillery", "look": "guardian", "color": "7fbf8a", "mods": {"hp": 1.2, "armor": 0.04},
   "text": "+20% health and +4 armor: a back-liner that survives dives."},
 ],
 "harpy": [
  {"name": "Storm Siren", "niche": "Silence controller", "look": "arcanist", "color": "cbb1ff", "sig": {"power": 1.2, "cd": 0.8}, "perks": {"on_hit": ["silence", 0.1]},
   "text": "Shriek returns 20% sooner and hits 20% harder; attacks can silence."},
  {"name": "Gale Huntress", "niche": "Ranged carry", "look": "ravager", "color": "cfe9f2", "mods": {"haste": 1.15, "attack": 1.08},
   "text": "+15% attack speed and +8% damage."},
  {"name": "Tempest Choir", "niche": "Team booster", "look": "guardian", "color": "a8e0ff", "grant": {"effect": "rally", "name": "War Song", "cd": 14.0}, "mods": {"hp": 1.08},
   "text": "New ability War Song rallies nearby allies. +8% health."},
 ],
 "phoenix": [
  {"name": "Dawn Eternal", "niche": "Burn caster", "look": "arcanist", "color": "ffa35b", "sig": {"power": 1.3}, "mods": {"potency": 1.12},
   "text": "Flame Wave burns 30% harder. +12% ability power."},
  {"name": "Cinder Hawk", "niche": "Fire skirmisher", "look": "ravager", "color": "ff6a1c", "mods": {"attack": 1.12, "speed": 1.1}, "perks": {"on_hit": ["burn", 0.35]},
   "text": "+12% damage, +10% move speed; attacks often burn."},
  {"name": "Ashen Saint", "niche": "Rebirth healer", "look": "guardian", "color": "ffd9a0", "grant": {"effect": "renew", "name": "Ember Renewal", "cd": 13.0}, "mods": {"hp": 1.1},
   "text": "New ability Ember Renewal heals nearby allies. +10% health."},
 ],
 "kirin": [
  {"name": "Heaven's Thunder", "niche": "Chain caster", "look": "arcanist", "color": "8bdfff", "sig": {"power": 1.3, "cd": 0.85},
   "text": "Chain Lightning hits 30% harder and returns 15% sooner."},
  {"name": "Jade Celestial", "niche": "Spell weaver", "look": "arcanist", "color": "7fe0b0", "skills": {"power": 1.2, "cd": 0.9}, "mods": {"potency": 1.08},
   "text": "Learned skills hit 20% harder and recharge 10% faster. +8% ability power."},
  {"name": "Storm Charger", "niche": "Lightning lancer", "look": "ravager", "color": "eef6ff", "mods": {"attack": 1.12, "speed": 1.1}, "perks": {"on_hit": ["stun", 0.07]},
   "text": "+12% damage, +10% move speed; hooves can stun."},
 ],
 "basilisk": [
  {"name": "Obsidian Monarch", "niche": "Lockdown controller", "look": "arcanist", "color": "a9e5ff", "sig": {"cd": 0.75, "power": 1.1},
   "text": "Petrifying Gaze returns 25% sooner."},
  {"name": "Venomfang Basilisk", "niche": "Poison bruiser", "look": "ravager", "color": "b7ed69", "mods": {"attack": 1.12}, "perks": {"on_hit": ["venom", 0.35]},
   "text": "+12% damage; bites often poison."},
  {"name": "Stoneskin Wyrm", "niche": "Petrify tank", "look": "guardian", "color": "c8c0a8", "mods": {"hp": 1.15, "armor": 0.05}, "perks": {"thorns": 0.1},
   "text": "+15% health, +5 armor, reflects 10% of damage taken."},
 ],
 "treant": [
  {"name": "Worldroot Ancient", "niche": "Main healer", "look": "guardian", "color": "78ce92", "sig": {"power": 1.3}, "mods": {"potency": 1.12},
   "text": "Rootbloom heals 30% more. +12% ability power."},
  {"name": "Thornwarden", "niche": "Root tank", "look": "guardian", "color": "5fa86a", "mods": {"hp": 1.18, "armor": 0.04}, "perks": {"thorns": 0.12, "on_hit": ["root", 0.1]},
   "text": "+18% health, +4 armor, reflects 12% of damage taken; branches can root."},
  {"name": "Grove Shepherd", "niche": "Area control", "look": "arcanist", "color": "9fe07a", "grant": {"effect": "roots", "name": "Grasping Grove", "cd": 13.0},
   "text": "New ability Grasping Grove roots a cluster of foes."},
 ],
 "naga": [
  {"name": "Pearl Empress", "niche": "Shield support", "look": "guardian", "color": "d8fbff", "sig": {"power": 1.3, "cd": 0.85},
   "text": "Tidal Ward shields 30% more and returns 15% sooner."},
  {"name": "Tide Caller", "niche": "Water caster", "look": "arcanist", "color": "3fc9e6", "grant": {"effect": "beam", "name": "Riptide Beam", "cd": 12.0}, "mods": {"potency": 1.12},
   "text": "New ability Riptide Beam. +12% ability power."},
  {"name": "Coral Sentinel", "niche": "Front-line support", "look": "guardian", "color": "ff9b8a", "mods": {"hp": 1.15, "armor": 0.04}, "perks": {"ward": 0.04},
   "text": "+15% health, +4 armor; every cast shields the most wounded ally for 4% of its health."},
 ],
 "unicorn": [
  {"name": "Astral Paragon", "niche": "Main healer", "look": "guardian", "color": "fffbe6", "sig": {"power": 1.3, "cd": 0.85},
   "text": "Radiant Horn heals 30% more and returns 15% sooner."},
  {"name": "Starlance Charger", "niche": "Holy bruiser", "look": "ravager", "color": "ffd36a", "mods": {"attack": 1.15, "hp": 1.08}, "perks": {"lifesteal": 0.08},
   "text": "+15% damage, +8% health, heals 8% of basic damage."},
  {"name": "Moonlit Seer", "niche": "Protective caster", "look": "arcanist", "color": "cbb1ff", "grant": {"effect": "ward", "name": "Moonveil", "cd": 14.0}, "mods": {"potency": 1.1},
   "text": "New ability Moonveil shields the team. +10% ability power."},
 ],
 "cerberus": [
  {"name": "Hellgate Warden", "niche": "Bleed tank", "look": "guardian", "color": "ff7a3a", "mods": {"hp": 1.12, "armor": 0.04}, "sig": {"power": 1.2},
   "text": "+12% health, +4 armor; Triple Bite hits 20% harder."},
  {"name": "Infernal Hound", "niche": "Fire bruiser", "look": "ravager", "color": "ff6a1c", "grant": {"effect": "fire", "name": "Hellfire Breath", "cd": 12.0}, "perks": {"on_hit": ["burn", 0.25]},
   "text": "New ability Hellfire Breath; bites often burn."},
  {"name": "Three-Headed Terror", "niche": "Fear warden", "look": "arcanist", "color": "b06aff", "grant": {"effect": "fear", "name": "Triple Howl", "cd": 15.0}, "mods": {"hp": 1.08},
   "text": "New ability Triple Howl terrifies nearby foes. +8% health."},
 ],
 "nemean": [
  {"name": "Sunmane Sovereign", "niche": "Rally leader", "look": "guardian", "color": "ffd36e", "sig": {"power": 1.3, "cd": 0.85}, "mods": {"hp": 1.06},
   "text": "Pride Roar rallies 30% harder and returns 15% sooner. +6% health."},
  {"name": "Golden Hide", "niche": "Immovable warden", "look": "guardian", "color": "e8c070", "mods": {"hp": 1.15, "armor": 0.06}, "perks": {"thorns": 0.1},
   "text": "+15% health, +6 armor, reflects 10% of damage taken."},
  {"name": "Pridebreaker", "niche": "Frontline carry", "look": "ravager", "color": "ff9a5c", "mods": {"attack": 1.18, "haste": 1.08}, "perks": {"execute": 0.25},
   "text": "+18% damage, +8% attack speed, +25% damage to foes under 35% health."},
 ],
 "yeti": [
  {"name": "Avalanche King", "niche": "Slow tank", "look": "guardian", "color": "f2fbff", "sig": {"power": 1.25, "cd": 0.85}, "mods": {"hp": 1.1},
   "text": "Frost Roar chills 25% harder and returns 15% sooner. +10% health."},
  {"name": "Glacier Breaker", "niche": "Freeze bruiser", "look": "ravager", "color": "8fd8ff", "mods": {"attack": 1.15}, "perks": {"on_hit": ["chill", 0.35]},
   "text": "+15% damage; fists often chill."},
  {"name": "Blizzard Caller", "niche": "Ice artillery", "look": "arcanist", "color": "a9e5ff", "grant": {"effect": "meteor", "name": "Hailstorm", "cd": 15.0}, "mods": {"potency": 1.1},
   "text": "New ability Hailstorm drops ice on a cluster. +10% ability power."},
 ],
 "zaratan": [
  {"name": "Wandering Continent", "niche": "Ultimate wall", "look": "guardian", "color": "c8b090", "mods": {"hp": 1.22, "armor": 0.05, "speed": 0.9},
   "text": "+22% health, +5 armor. -10% move speed."},
  {"name": "Reefback Bastion", "niche": "Shield tank", "look": "guardian", "color": "7fd0d0", "sig": {"cd": 0.8}, "perks": {"ward": 0.05},
   "text": "Shell Up returns 20% sooner; every cast shields the most wounded ally for 5% of its health."},
  {"name": "Tidequake Titan", "niche": "Area control", "look": "arcanist", "color": "3fc9e6", "grant": {"effect": "quake", "name": "Tidequake", "cd": 14.0}, "perks": {"thorns": 0.1},
   "text": "New ability Tidequake stuns nearby foes; reflects 10% of damage taken."},
 ],
 "owlbear": [
  {"name": "Ironfeather Apex", "niche": "Pin bruiser", "look": "guardian", "color": "c8a070", "sig": {"power": 1.25, "cd": 0.85}, "mods": {"hp": 1.1},
   "text": "Maul pins 25% harder and returns 15% sooner. +10% health."},
  {"name": "Frenzied Mauler", "niche": "Damage bruiser", "look": "ravager", "color": "ff7a5c", "mods": {"attack": 1.15, "haste": 1.12}, "perks": {"lifesteal": 0.08},
   "text": "+15% damage, +12% attack speed, heals 8% of basic damage."},
  {"name": "Elder Hooter", "niche": "Fear bruiser", "look": "arcanist", "color": "b8a0ff", "grant": {"effect": "fear", "name": "Night Screech", "cd": 15.0}, "mods": {"hp": 1.08},
   "text": "New ability Night Screech terrifies nearby foes. +8% health."},
 ],
 "hydra": [
  {"name": "Undying Crown", "niche": "Regenerating tank", "look": "guardian", "color": "97eda6", "perks": {"regen": 0.01}, "sig": {"power": 1.2},
   "text": "Regenerates 1% of max health every second; Regrowth heals 20% more."},
  {"name": "Venomous Heads", "niche": "Poison cleaver", "look": "ravager", "color": "b7ed69", "mods": {"attack": 1.12}, "perks": {"on_hit": ["venom", 0.4]},
   "text": "+12% damage; every head's bite often poisons."},
  {"name": "Marsh Leviathan", "niche": "Drain bruiser", "look": "arcanist", "color": "6fa86a", "grant": {"effect": "drain", "name": "Marsh Drain", "cd": 12.0}, "perks": {"lifesteal": 0.06},
   "text": "New ability Marsh Drain steals health; heals 6% of basic damage."},
 ],
 "chimera": [
  {"name": "Threefold Tyrant", "niche": "Burst duelist", "look": "ravager", "color": "ff6a1c", "sig": {"power": 1.3, "cd": 0.85},
   "text": "Threefold Strike hits 30% harder and returns 15% sooner."},
  {"name": "Goatheart Brawler", "niche": "Durable duelist", "look": "guardian", "color": "d8c09a", "mods": {"hp": 1.15, "armor": 0.04}, "perks": {"lifesteal": 0.08},
   "text": "+15% health, +4 armor, heals 8% of basic damage."},
  {"name": "Serpent Tail", "niche": "Venom duelist", "look": "arcanist", "color": "9be05a", "mods": {"haste": 1.12}, "perks": {"on_hit": ["venom", 0.3]},
   "text": "+12% attack speed; the serpent's bite often poisons."},
 ],
 "gargoyle": [
  {"name": "Cathedral Sentinel", "niche": "Dive tank", "look": "guardian", "color": "c8c0a8", "mods": {"hp": 1.15, "armor": 0.05}, "sig": {"power": 1.15},
   "text": "+15% health, +5 armor; Stone Dive hits 15% harder."},
  {"name": "Nightwing Hunter", "niche": "Back-line assassin", "look": "ravager", "color": "8f8fff", "mods": {"attack": 1.12, "speed": 1.1}, "perks": {"execute": 0.3},
   "text": "+12% damage, +10% move speed, +30% damage to foes under 35% health."},
  {"name": "Gloom Spire", "niche": "Fear diver", "look": "arcanist", "color": "b06aff", "grant": {"effect": "fear", "name": "Gloom Shriek", "cd": 15.0}, "sig": {"cd": 0.85},
   "text": "New ability Gloom Shriek terrifies nearby foes; Stone Dive returns 15% sooner."},
 ],
 "nekomata": [
  {"name": "Twilight Reaver", "niche": "Executioner", "look": "ravager", "color": "d591d8", "mods": {"attack": 1.1}, "perks": {"execute": 0.45},
   "text": "+45% damage to foes under 35% health. +10% damage."},
  {"name": "Shadow Twin-Tail", "niche": "Repeat ambusher", "look": "arcanist", "color": "a060ff", "sig": {"cd": 0.75, "power": 1.1},
   "text": "Vanish returns 25% sooner and ambushes 10% harder."},
  {"name": "Ghostfire Cat", "niche": "Spirit caster", "look": "arcanist", "color": "8fb8ff", "grant": {"effect": "wisps", "name": "Ghostfire", "cd": 11.0}, "mods": {"potency": 1.12},
   "text": "New ability Ghostfire wisps. +12% ability power."},
 ],
 "jackalope": [
  {"name": "Briarwild Trickster", "niche": "Hit-and-run", "look": "ravager", "color": "86d955", "sig": {"power": 1.25, "cd": 0.8}, "mods": {"speed": 1.1},
   "text": "Antler Rush hits 25% harder and returns 20% sooner. +10% move speed."},
  {"name": "Thornhorn Charger", "niche": "Bleeding skirmisher", "look": "ravager", "color": "c8803a", "mods": {"attack": 1.12, "haste": 1.1}, "perks": {"on_hit": ["venom", 0.3]},
   "text": "+12% damage, +10% attack speed; antlers often leave bleeding wounds."},
  {"name": "Lucky Hare", "niche": "Charm support", "look": "guardian", "color": "ffe08a", "grant": {"effect": "rally", "name": "Lucky Leap", "cd": 13.0}, "perks": {"ward": 0.03},
   "text": "New ability Lucky Leap rallies nearby allies; every cast shields the most wounded ally for 3% of its health."},
 ],
 "cyclops": [
  {"name": "Mountain's Eye", "niche": "Siege artillery", "look": "arcanist", "color": "ffcf5a", "sig": {"power": 1.3, "cd": 0.85},
   "text": "Boulder Toss hits 30% harder and returns 15% sooner."},
  {"name": "Gazing Titan", "niche": "Beam artillery", "look": "arcanist", "color": "ffe08a", "grant": {"effect": "beam", "name": "Titan's Gaze", "cd": 12.0}, "mods": {"potency": 1.1},
   "text": "New ability Titan's Gaze, a piercing beam. +10% ability power."},
  {"name": "Boulder Brute", "niche": "Front-line siege", "look": "guardian", "color": "c8a070", "mods": {"hp": 1.2, "armor": 0.05}, "perks": {"on_hit": ["stun", 0.06]},
   "text": "+20% health, +5 armor; blows can stun."},
 ],
 "thunderbird": [
  {"name": "Tempest Incarnate", "niche": "Storm artillery", "look": "arcanist", "color": "8bdfff", "sig": {"power": 1.3, "cd": 0.85},
   "text": "Storm Call strikes 30% harder and returns 15% sooner."},
  {"name": "Thunderhead", "niche": "Spell weaver", "look": "arcanist", "color": "c0e8ff", "skills": {"power": 1.2, "cd": 0.9}, "mods": {"potency": 1.08},
   "text": "Learned skills hit 20% harder and recharge 10% faster. +8% ability power."},
  {"name": "Skybreaker", "niche": "Shock carry", "look": "ravager", "color": "eef6ff", "mods": {"haste": 1.15, "attack": 1.08}, "perks": {"on_hit": ["stun", 0.06]},
   "text": "+15% attack speed, +8% damage; bolts can stun."},
 ],
 "sphinx": [
  {"name": "Oracle of Ages", "niche": "Confusion controller", "look": "arcanist", "color": "cbb1ff", "sig": {"cd": 0.75}, "mods": {"potency": 1.1},
   "text": "Riddle of Ruin returns 25% sooner. +10% ability power."},
  {"name": "Sun Guardian", "niche": "Protective controller", "look": "guardian", "color": "ffd36a", "mods": {"hp": 1.15, "armor": 0.04}, "perks": {"ward": 0.04},
   "text": "+15% health, +4 armor; every cast shields the most wounded ally for 4% of its health."},
  {"name": "Desert Silencer", "niche": "Anti-caster", "look": "arcanist", "color": "e8c070", "grant": {"effect": "silence", "name": "Sealing Riddle", "cd": 13.0}, "perks": {"on_hit": ["silence", 0.1]},
   "text": "New ability Sealing Riddle silences a cluster; attacks can silence."},
 ],
 "pegasus": [
  {"name": "Dawn Herald", "niche": "Speed support", "look": "guardian", "color": "ffe9b8", "sig": {"power": 1.3, "cd": 0.85},
   "text": "Tailwind grants 30% more and returns 15% sooner."},
  {"name": "Skylance Paladin", "niche": "Diving support", "look": "ravager", "color": "ffd36a", "mods": {"attack": 1.15, "hp": 1.1, "speed": 1.08},
   "text": "+15% damage, +10% health, +8% move speed."},
  {"name": "Cloud Shepherd", "niche": "Healer", "look": "arcanist", "color": "d8f0ff", "grant": {"effect": "renew", "name": "Cloudmend", "cd": 13.0}, "perks": {"ward": 0.03},
   "text": "New ability Cloudmend heals nearby allies; every cast shields the most wounded ally for 3% of its health."},
 ],
 "arachne": [
  {"name": "Widow Empress", "niche": "Swarm summoner", "look": "arcanist", "color": "c060ff", "sig": {"power": 1.3, "cd": 0.8},
   "text": "Brood spiderlings hit 30% harder and are summoned 20% sooner."},
  {"name": "Silk Weaver", "niche": "Root controller", "look": "arcanist", "color": "e0e0ff", "grant": {"effect": "roots", "name": "Web Snare", "cd": 12.0}, "perks": {"on_hit": ["root", 0.1]},
   "text": "New ability Web Snare roots a cluster; bites can root."},
  {"name": "Venom Matriarch", "niche": "Poison carry", "look": "ravager", "color": "b7ed69", "mods": {"attack": 1.12}, "perks": {"on_hit": ["venom", 0.4]},
   "text": "+12% damage; bites often poison."},
 ],
 "salamander": [
  {"name": "Molten Heart", "niche": "Lava caster", "look": "arcanist", "color": "ff5a14", "sig": {"power": 1.3, "cd": 0.85}, "mods": {"potency": 1.08},
   "text": "Magma Burst burns 30% harder and returns 15% sooner. +8% ability power."},
  {"name": "Ember Skink", "niche": "Burn skirmisher", "look": "ravager", "color": "ff9a5c", "mods": {"haste": 1.12, "speed": 1.1}, "perks": {"on_hit": ["burn", 0.35]},
   "text": "+12% attack speed, +10% move speed; attacks often burn."},
  {"name": "Obsidian Salamander", "niche": "Lava tank", "look": "guardian", "color": "5a4a5a", "mods": {"hp": 1.18, "armor": 0.05}, "perks": {"thorns": 0.12},
   "text": "+18% health, +5 armor; molten skin reflects 12% of damage taken."},
 ],
}

static func has(key: String) -> bool:
	return key.contains(":")

static func entry(key: String) -> Dictionary:
	if not has(key): return {}
	var parts = key.split(":")
	var list: Array = DATA.get(parts[0], [])
	var i = int(parts[1])
	return list[i] if i >= 0 and i < list.size() else {}

static func of(hero: Dictionary) -> Dictionary:
	return entry(str(hero.get("evolution", "")))

static func options(sp: String) -> Array:
	var out = []
	for i in range(DATA.get(sp, []).size()): out.append("%s:%d" % [sp, i])
	return out

static func mod(hero: Dictionary, stat: String, default := 1.0) -> float:
	return float(of(hero).get("mods", {}).get(stat, default))

static func perk(hero: Dictionary, name: String, default = 0.0):
	return of(hero).get("perks", {}).get(name, default)

static func sig(hero: Dictionary, field: String) -> float:
	return float(of(hero).get("sig", {}).get(field, 1.0))

static func skills(hero: Dictionary, field: String) -> float:
	return float(of(hero).get("skills", {}).get(field, 1.0))

## Learned-ability index used for an evolution's granted ability (13 + evolution index).
static func grant_index(key: String) -> int:
	return 13 + int(key.split(":")[1]) if has(key) and not entry(key).get("grant", {}).is_empty() else -1

static func grant_ability(sp: String, slot: int) -> Dictionary:
	var e = entry("%s:%d" % [sp, slot]); var g = e.get("grant", {})
	if g.is_empty(): return {}
	var spec = HeroData.EFFECTS[g.effect]
	return {"key": str(13 + slot), "name": g.name, "effect": g.effect, "rider": "none", "power": 1.0, "summary": HeroData.EFFECT_SUMMARY.get(g.effect, spec[0]), "description": spec[0] + "  Evolution ability · %.0fs cooldown." % g.cd, "cooldown": float(g.cd), "range": spec[2]}

static func info(key: String) -> Dictionary:
	var e = entry(key)
	if e.is_empty(): return {}
	return {"name": e.name, "niche": e.niche, "color": e.color, "description": e.text, "look": e.look}

## Art key for the level-up card: the granted ability's effect, else the signature's.
static func art(key: String) -> String:
	var e = entry(key)
	if e.is_empty(): return key
	if not e.get("grant", {}).is_empty(): return e.grant.effect
	if not e.get("sig", {}).is_empty(): return HeroData.species[key.split(":")[0]].ab
	return {"guardian": "ward", "ravager": "ambush"}.get(e.look, "wisps")

static func look(key: String) -> String:
	if key in ["ravager", "guardian", "arcanist", "ascended"]: return key
	return str(entry(key).get("look", "arcanist"))
