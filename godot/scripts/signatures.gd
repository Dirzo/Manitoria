class_name Signatures
extends RefCounted
## v0.76: one signature ability per champion, cast when the mana bar fills (TFT-style).
## Text tokens are filled with live numbers on the champion card:
##   {ad:300}  -> 300% of the champion's AD          {ap:150} -> 150 at 100 AP, grows with AP and level
##   {hp:12}   -> 12% of the champion's max HP       {res:2}  -> 2x the champion's Resistance
## Evolution "mods" change stats:  hp (x), hp_flat (+), ad (+), ad_pct (x), as (x), res (+),
##   mana (+fraction), ap (+), speed (x).  Everything else an evolution does lives in SignatureCast.

## AP numbers also grow with level so spell champions keep pace with AD growth and level-up cards.
const AP_LEVEL := 0.045

const DATA := {
	# ---------------------------------------------------------------- Frontline
	"minotaur": {"name": "Gore Charge", "fx": "gore", "mana": [30, 80], "builds": "AD", "true": false,
		"text": "Charges the farthest enemy in reach, hitting everyone in its path for {ad:100}, then gores the target for {ad:340} and stuns it for 1.5s.",
		"evos": [
			{"name": "Labyrinth Juggernaut", "tag": "Tank", "look": "guardian", "color": "e0a46b", "mods": {"res": 20}, "text": "Unstoppable while charging. Gains a {ap:150} shield on impact. +20 Resistance."},
			{"name": "Bloodhorn Berserker", "tag": "AD", "look": "ravager", "color": "ff6b4a", "mods": {"hp": 0.9}, "text": "Gore deals {ad:400}, and each charge grants +20% AS for the rest of the fight. −10% HP."},
			{"name": "Maze Breaker", "tag": "Movement", "look": "arcanist", "color": "c9a26b", "mods": {}, "text": "The charge carries the target 2 hexes back into Minotaur's team. Stun lasts 2.5s."},
		]},
	"golem": {"name": "Bulwark", "fx": "bulwark", "mana": [30, 80], "builds": "HP, Resistance",
		"text": "Taunts enemies within 2 hexes for 2s and raises a shield of {ap:150} + {hp:12} for 4s.",
		"evos": [
			{"name": "Living Fortress", "tag": "Tank", "look": "guardian", "color": "c8c0a8", "mods": {"hp": 1.3, "as": 0.85}, "text": "Shield is {ap:150} + {hp:20}. +30% HP, −15% AS."},
			{"name": "Shardbound Sentinel", "tag": "AP", "look": "ravager", "color": "8fd8ff", "mods": {}, "text": "When the shield ends, it shatters for 60% of the damage it absorbed to enemies within 2 hexes."},
			{"name": "Runebound Monolith", "tag": "Support", "look": "arcanist", "color": "ffe3a1", "mods": {"mana": 0.15}, "text": "The two nearest allies also get the shield at half strength. +15% Mana."},
		]},
	"troll": {"name": "Club Smash", "fx": "smash", "mana": [25, 65], "builds": "AD, HP",
		"text": "Smashes the target and everyone next to it for {ad:230}, cutting their AS by 30% for 3s.",
		"passive": "Regenerates 1.5% max HP per second.",
		"evos": [
			{"name": "Mossblood Colossus", "tag": "Tank", "look": "guardian", "color": "7fbf6a", "mods": {"hp_flat": 200}, "text": "Regeneration is 3% max HP per second. +200 HP."},
			{"name": "Bonecrusher", "tag": "AD", "look": "ravager", "color": "d39a55", "mods": {}, "text": "Smash deals {ad:300} and removes 20 Resistance from enemies hit for 4s."},
			{"name": "Boulder Hurler", "tag": "Movement", "look": "arcanist", "color": "8fe0a0", "mods": {}, "text": "Throws the smash at the enemy with the most HP up to 4 hexes away, then leaps after it."},
		]},
	"wendigo": {"name": "Endless Hunger", "fx": "hunger", "mana": [0, 55], "builds": "AS, AP",
		"text": "Frenzies for 5s: +100% AS (grows with AP) and basic attacks heal for 60% of damage dealt.",
		"evos": [
			{"name": "Winter Devourer", "tag": "Sustain", "look": "ravager", "color": "a9e5ff", "mods": {}, "text": "Heals 80% of damage, and each kill extends the frenzy by 1s."},
			{"name": "Hollow Stalker", "tag": "Movement", "look": "ravager", "color": "d591d8", "mods": {}, "text": "On cast and after each kill, dashes to the lowest-HP enemy. +30% damage to enemies below 40% HP."},
			{"name": "Frostbitten Horror", "tag": "AP", "look": "arcanist", "color": "9fc8ff", "mods": {}, "text": "The frenzy chills enemies within 2 hexes: −30% AS and {ap:25} damage per second."},
		]},
	"cerberus": {"name": "Three-Headed Bite", "fx": "triplebite", "mana": [30, 70], "builds": "AD, AP",
		"text": "Bites the three closest enemies for {ad:130} each and makes them bleed for {ap:45} over 3s. Heals for 25% of damage dealt.",
		"evos": [
			{"name": "Gatewarden", "tag": "Tank", "look": "guardian", "color": "ff9a5c", "mods": {"res": 20}, "text": "Bitten enemies are taunted for 1.5s. +20 Resistance."},
			{"name": "Hellfire Hound", "tag": "AP", "look": "arcanist", "color": "ff5a2a", "mods": {}, "text": "The bleed becomes a {ap:130} burn that cuts enemy healing by 33%."},
			{"name": "Hound of the Hunt", "tag": "Movement", "look": "ravager", "color": "d06a3a", "mods": {}, "text": "Leaps into the largest enemy cluster before biting."},
		]},
	"nemean": {"name": "Lionheart Roar", "fx": "prideroar", "mana": [40, 90], "builds": "HP, AP",
		"text": "Taunts enemies within 2 hexes for 1.5s. Allies within 2 hexes gain +30% AD and AS for 4s (grows with AP).",
		"passive": "Takes 15% less damage.",
		"evos": [
			{"name": "Pride King", "tag": "Support", "look": "arcanist", "color": "ffd36e", "mods": {}, "text": "The roar reaches 3 hexes and also shields allies for {ap:90}."},
			{"name": "Invulnerable Hide", "tag": "Tank", "look": "guardian", "color": "e8c070", "mods": {}, "text": "Takes 25% less damage, and ignores stuns for 3s after each cast."},
			{"name": "Sovereign's Pounce", "tag": "Movement", "look": "ravager", "color": "ffb36b", "mods": {}, "text": "Pounces onto the enemy with the highest AD and taunts only it, for 3s."},
		]},
	"yeti": {"name": "Avalanche Hide", "fx": "frostroar", "mana": [30, 80], "builds": "Resistance, AP",
		"text": "Chills enemies within 2 hexes for {ap:80} and −40% AS for 3s, and grows an ice shield of {ap:120} + {res:2}.",
		"evos": [
			{"name": "Permafrost", "tag": "AP", "look": "arcanist", "color": "a9e5ff", "mods": {}, "text": "The chill becomes a 1.25s freeze."},
			{"name": "Glacier Body", "tag": "Tank", "look": "guardian", "color": "d6f2ff", "mods": {"res": 30}, "text": "+30 Resistance, and the shield grows with 5× Resistance instead."},
			{"name": "Avalanche", "tag": "Movement", "look": "ravager", "color": "bfe8ff", "mods": {}, "text": "Rolls 3 hexes forward first, knocking enemies aside and into the air for 1s."},
		]},
	"zaratan": {"name": "Shellback", "fx": "shellup", "mana": [40, 80], "builds": "HP",
		"text": "Taunts adjacent enemies and withdraws into its shell for 3s, taking 80% less damage and restoring {ap:140} HP.",
		"evos": [
			{"name": "Island Fortress", "tag": "Support", "look": "guardian", "color": "4a8a7a", "mods": {}, "text": "Allies within 1 hex also take 30% less damage while the shell is up."},
			{"name": "Tidal Shell", "tag": "AP", "look": "arcanist", "color": "5ac8d8", "mods": {}, "text": "When the shell opens, a wave hits enemies within 2 hexes for 25% of the damage absorbed and pushes them back 1 hex."},
			{"name": "Ancient Isle", "tag": "Tank", "look": "guardian", "color": "7fbf6a", "mods": {"hp_flat": 400, "as": 0.85}, "text": "The shell lasts 4s. +400 HP, −15% AS."},
		]},
	"owlbear": {"name": "Rending Pounce", "fx": "maul", "mana": [25, 55], "builds": "AS, AD",
		"text": "Pounces on its target and pins it for 1.5s, clawing 4 times for {ad:80} each. +1 claw for every 25% bonus AS.",
		"evos": [
			{"name": "Ironfeather Mauler", "tag": "Tank", "look": "guardian", "color": "c8a070", "mods": {}, "text": "The pin lasts 2.5s, and Owlbear gains a {ap:120} shield during it."},
			{"name": "Rending Cyclone", "tag": "AD", "look": "ravager", "color": "ff8a5a", "mods": {}, "text": "The claws hit every adjacent enemy."},
			{"name": "Night Hunter", "tag": "Movement", "look": "arcanist", "color": "9a8ac8", "mods": {}, "text": "Pounces on the lowest-HP enemy anywhere on the board. +30% damage to pinned enemies."},
		]},
	"hydra": {"name": "Regrowth", "fx": "regrowth", "mana": [50, 95], "builds": "AS, HP",
		"text": "Heals {hp:15} + {ap:100} and grows a new head: +10% AS per head for the rest of the fight.",
		"passive": "Basic attacks cleave adjacent enemies for 40% AD.",
		"evos": [
			{"name": "Hydra Crown", "tag": "AD", "look": "ravager", "color": "6fe08a", "mods": {}, "text": "Each head also gives +10% AD."},
			{"name": "Venom Heads", "tag": "AP", "look": "arcanist", "color": "b7ed69", "mods": {}, "text": "Every attack poisons for {ap:12} per second, stacking."},
			{"name": "Coiling Lunge", "tag": "Movement", "look": "guardian", "color": "4aa88a", "mods": {}, "text": "Each cast lunges 2 hexes into the largest enemy cluster."},
		]},
	# ---------------------------------------------------------------- Flank
	"direwolf": {"name": "Pack Howl", "fx": "howl", "mana": [40, 80], "builds": "AP, AS",
		"text": "Summons two wolf pups for the rest of the fight, up to four. Each pup has {ap:320} HP and 70% of Direwolf's AD, and copies its AS.",
		"evos": [
			{"name": "Moonfang Alpha", "tag": "AP", "look": "guardian", "color": "c9d6ff", "mods": {}, "text": "Three pups per howl, up to six, and each pup gives the others +10% AS."},
			{"name": "Bloodtrail Hunter", "tag": "Movement", "look": "ravager", "color": "ff7a5c", "mods": {}, "text": "On each howl, Direwolf and its pups leap to the lowest-HP enemy. Their bites cause a {ap:30} bleed."},
			{"name": "Lone Wolf", "tag": "AD", "look": "arcanist", "color": "8fb8ff", "mods": {"hp": 1.2}, "text": "No pups. Each howl permanently grants +15% AD and AS for the fight instead. +20% HP."},
		]},
	"manticore": {"name": "Tail Venom", "fx": "venom", "mana": [15, 50], "builds": "AD, AP", "true": true,
		"text": "Leaps onto the most wounded enemy within 3 hexes, stings for {ad:200} and poisons for {ap:90} true damage over 3s. Poisoned enemies take 15% more damage from Manticore.",
		"evos": [
			{"name": "Venom Sovereign", "tag": "AP", "look": "ravager", "color": "b7ed69", "mods": {}, "text": "The poison stacks up to three times."},
			{"name": "Desert Reaper", "tag": "AD", "look": "ravager", "color": "ffb36b", "mods": {}, "text": "The sting deals double damage to enemies below 40% HP, and a kill refunds 40 mana."},
			{"name": "Sand Phantom", "tag": "Movement", "look": "arcanist", "color": "e8c890", "mods": {}, "text": "After stinging, dashes 3 hexes back and is untargetable for 1s."},
		]},
	"griffin": {"name": "Royal Descent", "fx": "skystrike", "mana": [30, 70], "builds": "AD",
		"text": "Swoops onto the enemy farthest away, dealing {ad:220} and stunning it for 1.5s.",
		"evos": [
			{"name": "Storm Talon", "tag": "AD", "look": "ravager", "color": "ffd36e", "mods": {}, "text": "The landing also hits adjacent enemies for {ad:120}."},
			{"name": "Sky Sovereign", "tag": "Movement", "look": "arcanist", "color": "a8c8ff", "mods": {"as": 1.2}, "text": "Carries the target into the air for 2s; it can't act or be helped. +20% AS."},
			{"name": "Wind Rider", "tag": "Tank", "look": "guardian", "color": "e0d8b0", "mods": {}, "text": "Flies back to its own side after the swoop and gains a {ap:150} shield."},
		]},
	"kitsune": {"name": "Foxfire Veil", "fx": "foxfire", "mana": [30, 65], "builds": "AP",
		"text": "Leaves two decoys that draw attacks, blinks behind the enemy with the most AP, then fires three foxfire bolts at it for {ap:60} each.",
		"evos": [
			{"name": "Nine Tails", "tag": "AP", "look": "arcanist", "color": "ff9ad5", "mods": {}, "text": "Fires nine bolts, split across the nearest enemies."},
			{"name": "Moon Veil", "tag": "Utility", "look": "guardian", "color": "c8b8ff", "mods": {}, "text": "Decoys explode for {ap:100} when they die."},
			{"name": "Spirit Step", "tag": "Movement", "look": "ravager", "color": "ffb36b", "mods": {}, "text": "Blinks again after the bolts and is untargetable for 1s."},
		]},
	"gargoyle": {"name": "Cathedral Drop", "fx": "stonedive", "mana": [50, 95], "builds": "AD, Resistance",
		"text": "Crashes onto the largest enemy cluster in the back line for {ad:230} to everyone within 1 hex, then turns to stone for 2s: it takes no damage and taunts adjacent enemies.",
		"evos": [
			{"name": "Stonewatch", "tag": "Tank", "look": "guardian", "color": "c8c0a8", "mods": {}, "text": "Stone lasts 3s and restores 15% max HP."},
			{"name": "Gargoyle Lord", "tag": "AD", "look": "ravager", "color": "9a8070", "mods": {}, "text": "The crash hits within 2 hexes and stuns for 1s."},
			{"name": "Belfry Hunter", "tag": "Movement", "look": "arcanist", "color": "a0a8c8", "mods": {}, "text": "After the stone form, leaps to the next cluster and crashes again for half damage."},
		]},
	"nekomata": {"name": "Twin-Tail Ambush", "fx": "vanish", "mana": [30, 65], "builds": "AD", "true": true,
		"text": "Slips into shadow for 1.5s (untargetable), reappears behind the lowest-HP enemy and strikes twice for {ad:145}. The second strike is true damage.",
		"evos": [
			{"name": "Soul Reaver", "tag": "Sustain", "look": "ravager", "color": "d591d8", "mods": {}, "text": "Heals for all damage dealt, and a kill sends it straight back into shadow."},
			{"name": "Nightfall", "tag": "AP", "look": "arcanist", "color": "8a6aff", "mods": {}, "text": "Both strikes become {ap:110} true damage."},
			{"name": "Twin Shadow", "tag": "Movement", "look": "guardian", "color": "5a5a8a", "mods": {}, "text": "The two strikes land on two different enemies, blinking between them."},
		]},
	"jackalope": {"name": "Briar Stampede", "fx": "antlerrush", "mana": [25, 55], "builds": "AD, AS",
		"text": "Charges straight through the enemy line to the far side, dealing {ad:150} to everyone it passes and knocking them up for 0.5s.",
		"evos": [
			{"name": "Lucky Foot", "tag": "AS", "look": "guardian", "color": "a8e08a", "mods": {"mana": 0.2}, "text": "After each stampede, the next three attacks deal double damage. +20% Mana."},
			{"name": "Wild Hare", "tag": "Movement", "look": "ravager", "color": "e0b080", "mods": {}, "text": "Charges through, then back again."},
			{"name": "Thorn Rabbit", "tag": "AP", "look": "arcanist", "color": "6fbf6a", "mods": {}, "text": "Leaves a briar trail that deals {ap:35} per second for 4s."},
		]},
	"chimera": {"name": "Threefold Strike", "fx": "threefold", "mana": [25, 55], "builds": "AD, AP",
		"text": "Three heads strike the target at once: the lion for {ad:180}, the goat stuns for 0.75s, and the serpent burns for {ap:100} over 3s.",
		"evos": [
			{"name": "Lion Ascendant", "tag": "AD", "look": "ravager", "color": "ffb36b", "mods": {"ad": 10}, "text": "The lion strikes for {ad:300}. +10 AD."},
			{"name": "Serpent Ascendant", "tag": "AP", "look": "arcanist", "color": "b7ed69", "mods": {}, "text": "The burn deals {ap:200} and spreads to adjacent enemies if the target dies."},
			{"name": "Goat Ascendant", "tag": "Movement", "look": "guardian", "color": "e0d0b0", "mods": {"hp_flat": 200}, "text": "The goat's stun lasts 1.5s and knocks the target back 2 hexes. +200 HP."},
		]},
	# ---------------------------------------------------------------- Back line
	"wyvern": {"name": "Corrosive Spit", "fx": "acid", "mana": [20, 60], "builds": "AD",
		"text": "Spits an acid glob at its target for {ad:320} and strips 25 Resistance for 5s. The glob leaves a pool that deals {ad:60} per second for 3s.",
		"evos": [
			{"name": "Corrosive Rain", "tag": "AD", "look": "arcanist", "color": "b7ed69", "mods": {}, "text": "Spits at three enemies for {ad:140} each, all shredded."},
			{"name": "Acid Wyrm", "tag": "AS", "look": "ravager", "color": "8fe05a", "mods": {}, "text": "Basic attacks on shredded enemies splash to adjacent enemies for 50% AD."},
			{"name": "Wing Buffet", "tag": "Movement", "look": "guardian", "color": "a0c890", "mods": {}, "text": "Whenever an enemy reaches it, flaps 2 hexes back and pushes that enemy away (once every 6s)."},
		]},
	"harpy": {"name": "Featherstorm", "fx": "shriek", "mana": [25, 65], "builds": "AD, AS", "true": true,
		"text": "Fires five feathers at its target for {ad:80} each, +1 feather for every 25% bonus AS. The last feather deals true damage and silences the target for 1.5s.",
		"evos": [
			{"name": "Siren's Lament", "tag": "Control", "look": "arcanist", "color": "cbb1ff", "mods": {}, "text": "Also shrieks, silencing and slowing enemies within 2 hexes for 2s."},
			{"name": "Razor Plumes", "tag": "AD", "look": "ravager", "color": "ffb36b", "mods": {}, "text": "Feathers pierce and hit the enemy behind for 50% damage."},
			{"name": "Swoop", "tag": "Movement", "look": "guardian", "color": "a8c8ff", "mods": {}, "text": "Flies into the enemy back line to fire, then flies back."},
		]},
	"phoenix": {"name": "Sunfire", "fx": "flamewave", "mana": [50, 95], "builds": "AP",
		"text": "Engulfs a cluster for {ap:120} and burns it for {ap:20} per second for 4s.",
		"passive": "Once per fight, rises from its ashes at 40% HP and casts immediately.",
		"evos": [
			{"name": "Eternal Flame", "tag": "Tank", "look": "guardian", "color": "ffd36e", "mods": {}, "text": "Rises at 70% HP and explodes for {ap:180} when it does."},
			{"name": "Solar Lance", "tag": "AP", "look": "arcanist", "color": "ffa35b", "mods": {}, "text": "Sunfire becomes a line of fire hitting every enemy in it for {ap:240}."},
			{"name": "Cinder Sanctuary", "tag": "Support", "look": "arcanist", "color": "97eda6", "mods": {}, "text": "Sunfire also heals allies in the area for {ap:120}."},
		]},
	"kirin": {"name": "Thunderhead", "fx": "chain", "mana": [30, 60], "builds": "AP",
		"text": "Lightning hits the target for {ap:170} and jumps to three more enemies, losing 12% per jump.",
		"evos": [
			{"name": "Storm Herald", "tag": "AP", "look": "arcanist", "color": "8bdfff", "mods": {}, "text": "Jumps twice more, and can hit the same enemy again."},
			{"name": "Static Prison", "tag": "Control", "look": "guardian", "color": "c8e8ff", "mods": {}, "text": "Every hit stuns for 0.5s."},
			{"name": "Thunderhoof", "tag": "Movement", "look": "ravager", "color": "ffe38a", "mods": {}, "text": "Every third basic attack chains to two enemies for 60% AD. After each cast, dashes 2 hexes away from the nearest enemy."},
		]},
	"basilisk": {"name": "Petrifying Gaze", "fx": "gaze", "mana": [50, 95], "builds": "Mana, AP",
		"text": "Turns the enemy with the most HP to stone for 2.5s and deals {ap:100}. Petrified enemies take 30% more damage.",
		"evos": [
			{"name": "Gorgon's Gaze", "tag": "Control", "look": "arcanist", "color": "9ad0a0", "mods": {}, "text": "Petrifies every enemy in a cone for 1.5s."},
			{"name": "Venomous Wake", "tag": "AP", "look": "ravager", "color": "b7ed69", "mods": {}, "text": "The petrified enemy is poisoned for {ap:180}."},
			{"name": "Coil Strike", "tag": "Movement", "look": "guardian", "color": "6a9a7a", "mods": {}, "text": "Pulls the petrified enemy 2 hexes toward Basilisk's team."},
		]},
	"treant": {"name": "Heartwood", "fx": "rootbloom", "mana": [40, 80], "builds": "AP, HP",
		"text": "Heals the most wounded ally for {ap:150}, and roots the nearest enemy for 1.5s for {ap:60}.",
		"evos": [
			{"name": "Elder Grove", "tag": "Support", "look": "arcanist", "color": "97eda6", "mods": {}, "text": "Heals the three most wounded allies."},
			{"name": "Bramble Prison", "tag": "Control", "look": "ravager", "color": "78ce92", "mods": {}, "text": "Roots every enemy within 1 hex of the nearest one for 2s."},
			{"name": "Walking Wood", "tag": "Tank", "look": "guardian", "color": "a08a5a", "mods": {"hp_flat": 300, "res": 20}, "text": "Pulls the rooted enemy to Treant. +300 HP, +20 Resistance."},
		]},
	"naga": {"name": "Tidal Ward", "fx": "tidal", "mana": [30, 70], "builds": "AP, Mana",
		"text": "Shields allies within 2 hexes for {ap:110} for 4s.",
		"evos": [
			{"name": "Undertow", "tag": "Movement", "look": "ravager", "color": "3a8ac8", "mods": {}, "text": "Also pulls enemies within 2 hexes 1 hex inward and slows them."},
			{"name": "Moonwell", "tag": "Support", "look": "arcanist", "color": "c8e8ff", "mods": {}, "text": "Any shield left when it ends becomes healing."},
			{"name": "Siren Coil", "tag": "AS", "look": "guardian", "color": "5ac8d8", "mods": {}, "text": "Shielded allies gain +20% AS while the shield holds."},
		]},
	"unicorn": {"name": "Dawn's Embrace", "fx": "radiance", "mana": [50, 90], "builds": "AP",
		"text": "Heals allies within 2 hexes for {ap:120}, removes stuns, roots, slows and poison, and makes them immune to them for 1.5s.",
		"evos": [
			{"name": "Astral Lance", "tag": "AP", "look": "arcanist", "color": "e8d8ff", "mods": {}, "text": "Also fires a lance through its target's line for {ap:150}."},
			{"name": "Radiant Horn", "tag": "Support", "look": "guardian", "color": "fff2c8", "mods": {}, "text": "Heals the whole team at 60% strength."},
			{"name": "Moonlit Gallop", "tag": "Movement", "look": "ravager", "color": "c8d8ff", "mods": {}, "text": "Dashes to the most wounded ally before casting."},
		]},
	"cyclops": {"name": "Boulder Hurl", "fx": "boulder", "mana": [40, 90], "builds": "AD", "true": true,
		"text": "Hurls a boulder at the largest enemy cluster for {ad:300} within 1 hex and stuns for 1.5s.",
		"evos": [
			{"name": "Mountain Breaker", "tag": "AD", "look": "guardian", "color": "c8a070", "mods": {}, "text": "The impact covers 2 hexes and knocks enemies back."},
			{"name": "Unerring Eye", "tag": "AD", "look": "ravager", "color": "ffd36e", "mods": {}, "text": "Throws at the farthest enemy for {ad:600} as true damage."},
			{"name": "Rolling Stone", "tag": "Movement", "look": "arcanist", "color": "a0a0a0", "mods": {}, "text": "The boulder rolls 3 more hexes, pushing everyone in its path."},
		]},
	"thunderbird": {"name": "Tempest Call", "fx": "stormcall", "mana": [40, 80], "builds": "AP, AS",
		"text": "Lightning strikes three random enemies for {ap:100} each. +1 strike for every 40% bonus AS.",
		"evos": [
			{"name": "Tempest Crown", "tag": "AP", "look": "arcanist", "color": "e8d84a", "mods": {}, "text": "Five base strikes, each stunning for 0.25s."},
			{"name": "Skybreaker", "tag": "AP", "look": "ravager", "color": "8bdfff", "mods": {}, "text": "Strikes land on the largest cluster and splash 1 hex."},
			{"name": "Storm Glide", "tag": "Movement", "look": "guardian", "color": "c8d8ff", "mods": {}, "text": "After each cast, glides to the safest hex on the board."},
		]},
	"sphinx": {"name": "Riddle of Ages", "fx": "riddle", "mana": [50, 95], "builds": "Mana, AP",
		"text": "Confounds the enemy with the most AD for 1.5s so it attacks its own allies, and deals {ap:70}.",
		"evos": [
			{"name": "Judgment of Stars", "tag": "AP", "look": "arcanist", "color": "ffd36e", "mods": {}, "text": "When the confusion ends, the target explodes for {ap:180} to its allies around it."},
			{"name": "Silence of Ages", "tag": "Control", "look": "guardian", "color": "cbb1ff", "mods": {}, "text": "Confounds the two strongest enemies."},
			{"name": "Ancient Mind", "tag": "Mana", "look": "ravager", "color": "e8c890", "mods": {"mana": 0.3}, "text": "+30% Mana and max mana −20."},
		]},
	"pegasus": {"name": "Dawnflight", "fx": "tailwind", "mana": [40, 80], "builds": "AP, Mana",
		"text": "Allies within 3 hexes gain +30% AS and run faster for 5s (grows with AP) and a {ap:60} shield.",
		"evos": [
			{"name": "Celestial Wake", "tag": "Movement", "look": "arcanist", "color": "c8d8ff", "mods": {}, "text": "Buffed allies dash 1 hex toward their targets."},
			{"name": "Skydancer", "tag": "AS", "look": "ravager", "color": "ffd36e", "mods": {}, "text": "Pegasus also gains +60% AS for itself while the buff lasts."},
			{"name": "Glory's Wing", "tag": "Support", "look": "guardian", "color": "fff2c8", "mods": {}, "text": "The buff also grants +20% AD."},
		]},
	"arachne": {"name": "Brood Mother", "fx": "brood", "mana": [30, 70], "builds": "AP",
		"text": "Summons three spiderlings, up to six. Each has {ap:90} HP and bites for {ap:20}, cutting AS by 20%.",
		"evos": [
			{"name": "Widow Queen", "tag": "AP", "look": "ravager", "color": "8a2a4a", "mods": {}, "text": "Spiderlings explode for {ap:60} when they die."},
			{"name": "Venomweb", "tag": "Control", "look": "arcanist", "color": "b7ed69", "mods": {}, "text": "Also webs the target's area, rooting enemies for 1.5s."},
			{"name": "Silk Lurker", "tag": "Movement", "look": "guardian", "color": "c8c8d8", "mods": {}, "text": "Pulls the farthest enemy into the middle of the brood."},
		]},
	"salamander": {"name": "Magma Pool", "fx": "magma", "mana": [30, 70], "builds": "AP",
		"text": "Erupts a lava pool on the target for {ap:120}, then {ap:30} per second for 4s, slowing everyone in it.",
		"evos": [
			{"name": "Molten Lance", "tag": "AP", "look": "arcanist", "color": "ff5a2a", "mods": {}, "text": "The eruption becomes a line of lava."},
			{"name": "Cinder Spit", "tag": "AD", "look": "ravager", "color": "ffa35b", "mods": {}, "text": "Basic attacks ignite for 30% AD over 3s, and the cast spits three small pools."},
			{"name": "Lava Swim", "tag": "Movement", "look": "guardian", "color": "ff8a3a", "mods": {}, "text": "Dives into its pool and resurfaces 2 hexes away, untargetable for 1s."},
		]},
}

static func of(sp: String) -> Dictionary:
	return DATA.get(sp, DATA.minotaur)

static func mana(hero: Dictionary) -> Array:
	var m: Array = of(str(hero.sp)).mana.duplicate()
	if evo_index(hero) == 2 and str(hero.sp) == "sphinx": m[1] -= 20
	if str(hero.get("apex", "")) == "apex_sig": m[1] -= 10
	return [mini(int(m[0]), int(m[1])), int(m[1])]

## Which of its species' three evolutions this champion took (0-2), or -1.
static func evo_index(hero: Dictionary) -> int:
	var key = str(hero.get("evolution", ""))
	if not key.begins_with(str(hero.get("sp", "")) + ":"): return -1
	return clampi(int(key.get_slice(":", 1)), 0, 2)

static func evo_entry(hero: Dictionary) -> Dictionary:
	var i = evo_index(hero)
	return {} if i < 0 else of(str(hero.sp)).evos[i]

## Signature strength from Apex Signature (+25%).
static func power_mult(hero: Dictionary) -> float:
	return 1.25 if str(hero.get("apex", "")) == "apex_sig" else 1.0

static func level_factor(level: int) -> float:
	return 1.0 + AP_LEVEL * float(maxi(0, level - 1))

## The AP-scaled number on the card for a base value (live unit or hero stats).
static func ap_value(base: float, ap: float, level: int, hero: Dictionary) -> float:
	return base * ap / 100.0 * level_factor(level) * power_mult(hero)

## Fill tokens with live numbers. stats = HeroData.stats(hero) (or {} for the generic text).
static func fill(text: String, hero: Dictionary, s: Dictionary) -> String:
	var rx = RegEx.new(); rx.compile("\\{(ad|ap|hp|res):([0-9.]+)\\}")
	var out = text
	for m in rx.search_all(text):
		var kind = m.get_string(1); var v = float(m.get_string(2)); var rep = ""
		if s.is_empty():
			rep = {"ad": "%d%% AD" % roundi(v), "ap": "%d AP" % roundi(v), "hp": "%d%% max HP" % roundi(v), "res": "%s× Resistance" % str(v)}[kind]
		else:
			match kind:
				"ad": rep = "%d (%d%% AD)" % [roundi(s.attack * v / 100.0 * power_mult(hero)), roundi(v)]
				"ap": rep = "%d" % roundi(ap_value(v, float(s.ap), int(hero.get("level", 1)), hero))
				"hp": rep = "%d (%d%% max HP)" % [roundi(s.hp * v / 100.0 * power_mult(hero)), roundi(v)]
				"res": rep = "%d" % roundi(s.res * v * power_mult(hero))
		out = out.replace(m.get_string(0), rep)
	return out

static func description(hero: Dictionary, live := true) -> String:
	var d = of(str(hero.sp)); var s = HeroData.stats(hero) if live else {}
	var text = fill(str(d.text), hero, s)
	if d.has("passive"): text += " Passive: " + str(d.passive)
	var e = evo_entry(hero)
	if not e.is_empty(): text += "\n" + str(e.name) + ": " + fill(str(e.text), hero, s)
	return text

static func mana_text(hero: Dictionary) -> String:
	var m = mana(hero)
	return "Mana %d / %d" % [m[0], m[1]]

## Which stats this signature scales with (for rivals' level-up picks and item advice).
static func build_keys(sp: String) -> Array:
	var out = []
	for part in str(of(sp).builds).split(","):
		out.append({"AD": "ad", "AS": "as", "AP": "ap", "Mana": "mana", "HP": "hp", "Resistance": "res"}.get(part.strip_edges(), "hp"))
	return out

static func primary(sp: String) -> String:
	return build_keys(sp)[0]
