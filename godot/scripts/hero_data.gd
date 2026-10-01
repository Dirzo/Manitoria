class_name HeroData
extends RefCounted

static var species: Dictionary = {}
const FRONT = ["Tank", "Bruiser", "Warden"]
const FLANK = ["Skirmisher", "Assassin", "Diver", "Trickster", "Duelist"]
const NAMES = ["Ash", "Briar", "Cinder", "Dusk", "Ember", "Fable", "Grit", "Halo", "Iris", "Jinx", "Knell", "Lumen", "Morrow", "Nyx", "Onyx", "Pike", "Quill", "Rook", "Sable", "Thorn", "Umber", "Vale", "Wisp", "Zephyr", "Aldric", "Bramble", "Corvin", "Dagny", "Elowen", "Fenwick", "Gorm", "Hollis", "Isolde", "Jareth", "Kestrel", "Lark", "Mabry", "Nettle", "Orrin", "Pyre", "Quarry", "Rune", "Saffron", "Talon", "Ulla", "Vesper", "Wren", "Yarrow", "Alder", "Barrow", "Cobalt", "Dagger", "Ebony", "Flint", "Gale", "Hawthorn", "Ingot", "Jasper", "Kindle", "Loam", "Mist", "North", "Oriel", "Pebble", "Quartz", "Riven", "Sorrel", "Tansy", "Urchin", "Vigil", "Whisper", "Yew", "Amber", "Bastion", "Cairn", "Drift", "Echo", "Frost", "Gloam", "Harrow", "Ivy", "Juniper", "Kairo", "Lyric", "Marrow", "Nimbus", "Opal", "Puck", "Rowan", "Shale", "Tempest", "Valor", "Warden", "Xylo", "Yonder", "Zinnia", "Brisket", "Clover", "Dandelion", "Fizz", "Gumbo", "Hiccup", "Noodle", "Pip", "Scruff", "Tumble", "Waffle", "Biscuit"]
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
  species.wendigo.ability_description = "Frenzies for 5s: +22% attack and speed, healing for 45% of damage dealt."
  species.nemean.ability_description = "Taunts nearby foes and rallies allies with +22% attack and speed. Its hide reduces incoming damage by 16%."
  species.harpy.ability_description = "Damages nearby foes and silences their abilities for 2.5 seconds."
  species.hydra.ability_description = "Below 72% health, restores 23% maximum health and rallies for 4s. Basic attacks cleave nearby foes."
  species.pegasus.ability_description = "Nearby allies gain 22% attack and movement speed for 5 seconds."
  species.direwolf.ability_description = "Summons two pups for 16 seconds. The pack pressures wounded foes."

static func line(sp: String) -> String:
 load_data()
 if species[sp].role in FRONT: return "Front"
 if species[sp].role in FLANK: return "Flank"
 return "Back"

static func make_hero(sp: String, id: String, nickname: String, level: int = 1) -> Dictionary:
 load_data()
 return {"id": id, "sp": sp, "name": nickname, "level": level, "xp": 0, "signature_rank": 1, "learned": {}, "vigor": 0, "force": 0, "slot": -1, "bouts": 0, "wins": 0, "kills": 0, "impact": 0.0, "pending": [], "history": [], "evolution": "", "rewards": [], "last_offers": [], "progression_version": 2, "trait": Traits.ORDER[abs(hash(id + "|temper")) % Traits.ORDER.size()]}

static func stats(hero: Dictionary, quality: float = 1.0) -> Dictionary:
 load_data()
 var d = species[hero.sp]
 var level = hero.level
 var tierf = League.stat_factor(hero.sp)   # draft tier (Legendary / Epic / Common) and per-species balance
 var result = {"hp": (450.0 + (level - 1) * 24.0) * d.hp * tierf * quality * (1.0 + hero.get("vigor", 0) * 0.10), "attack": (43.0 + (level - 1) * 2.6) * d.atk * tierf * quality * (1.0 + hero.get("force", 0) * 0.08), "armor": clampf(0.08 + d.def * 0.09, 0.10, 0.28), "speed": d.mv * 0.036, "range": maxf(0.7, d.range / 44.0), "interval": 1.0 / (d.as * 0.85), "cooldown": d.cd}
 for item in Campaign.EQUIPMENT:
  if item.id not in hero.get("equipment", {}).values(): continue
  result.hp *= 1.0 + item.get("hp", 0.0)
  result.attack *= 1.0 + item.get("attack", 0.0)
  result.speed *= 1.0 + item.get("speed", 0.0)
  result.interval /= 1.0 + item.get("haste", 0.0)
  result.armor += item.get("armor", 0.0)
 # Temperament, scaling curve and forged items.
 var curve = Traits.curve(hero)
 result.hp *= Traits.mod(hero, "hp") * curve
 result.attack *= Traits.mod(hero, "attack") * curve
 result.armor += Traits.mod(hero, "armor")
 result.speed *= Traits.mod(hero, "speed")
 result.interval /= Traits.mod(hero, "haste")
 var f = Forge.totals(hero)
 result.hp *= 1.0 + f.hp; result.attack *= 1.0 + f.attack; result.armor = clampf(result.armor + f.armor, 0.0, 0.45)
 result.interval /= 1.0 + f.haste; result.speed *= 1.0 + f.speed
 match hero.get("evolution", ""):
  "ravager": result.attack *= 1.20; result.hp *= 0.90; result.speed *= 1.15
  "guardian": result.hp *= 1.15; result.armor += 0.04; result.attack *= 0.90
  "arcanist": result.attack *= 0.85; result.interval *= 1.15
 result.hp*=1.0+hero.get("legacy_hp",0.0)
 result.attack*=1.0+hero.get("legacy_attack",0.0)
 if hero.get("evolution","")=="ascended":result.attack*=0.9
 return result

static func power(hero: Dictionary) -> int:
 var s = stats(hero)
 return roundi(s.hp / 5.0 + s.attack * 3.0 / s.interval + hero.learned.size() * 25 + hero.signature_rank * 10)

const ABILITY_SLOTS = 4
const DISCOVERY_CHOICES = 12 # Preserve indices 0–7; expand fresh discovery choices.
const EVOLUTIONS = {
 "ravager": {"name":"Ravager", "color":"ffb36b", "description":"Become a relentless hunter: +20% attack, +15% movement, 12% lifesteal on basic attacks, but -10% maximum health. Amber talons and spell trails."},
 "guardian": {"name":"Guardian", "color":"7de6bd", "description":"Become a protector: +15% health, +4% armor, but -10% attack. Every ability shields the most wounded nearby ally for 3% of your maximum health. Emerald ward rings."},
 "arcanist": {"name":"Arcanist", "color":"bba2ff", "description":"Become a spell specialist: +20% ability potency and 15% shorter ability cooldowns, but -15% attack and 15% slower basic attacks. Violet orbiting runes."}
}

static func ability_pool(sp: String) -> Array:
 # Keep legacy indices 0 and 1 stable so existing saves retain their actions.
 var pool = DISCOVERIES[sp].duplicate(true)
 var extras = ["beam", "storm", "wisps", "silence", "frost", "ward", "barrage", "renew"]
 if line(sp) == "Front": extras = ["whirl", "quake", "ward", "rally", "drain", "fear", "fissure", "renew"]
 elif line(sp) == "Flank": extras = ["ambush", "execute", "toxic", "whirl", "drain", "gust", "ward", "rally"]
 elif sp in ["unicorn", "treant", "naga", "pegasus"]: extras = ["renew", "ward", "rally", "roots", "gust", "beam", "silence", "wisps"]
 var titles = {"beam":"Lance", "storm":"Tempest", "wisps":"Spirit Volley", "silence":"Hush", "frost":"Binding", "ward":"Aegis", "barrage":"Barrage", "renew":"Restoration", "whirl":"Cyclone", "quake":"Earthshaker", "rally":"War Cry", "drain":"Siphon", "fear":"Dread", "fissure":"Rift", "ambush":"Pursuit", "execute":"Finisher", "toxic":"Blight", "gust":"Gale", "roots":"Entanglement"}
 for effect in extras:
  if pool.any(func(row): return row[1] == effect): continue
  pool.append([species[sp].n + " " + titles[effect], effect])
  if pool.size() == 8: break
 # Append without reordering any existing saved ability IDs.
 var reserves=["meteor","fire","roots","silence","renew","ward","rally","beam","storm","wisps","barrage","frost","gust","fear","drain","execute","ambush","toxic","fissure","quake","whirl"]
 titles.merge({"meteor":"Starfall","fire":"Wildfire"})
 for effect in reserves:
  if pool.size()>=DISCOVERY_CHOICES:break
  if not pool.any(func(row):return row[1]==effect):pool.append([species[sp].n+" "+titles[effect],effect])
 return pool

static func learned_ability(sp: String, index: int) -> Dictionary:
 if index==12:return ChampionEvolution.action(sp)
 var row = ability_pool(sp)[index]
 var spec = EFFECTS[row[1]]
 return {"key": str(index), "name": row[0], "effect": row[1], "description": spec[0], "cooldown": spec[1], "range": spec[2]}

static func evolution_info(hero: Dictionary) -> Dictionary:
 if hero.get("evolution","")=="ascended":return ChampionEvolution.info(hero)
 return EVOLUTIONS.get(hero.get("evolution",""),{})

static func evolution_color(hero: Dictionary) -> Color:
 return Color(evolution_info(hero).get("color","ffffff"))

static func cooldown_factor(hero: Dictionary) -> float:
 return (0.85 if hero.get("evolution", "") == "arcanist" else 1.0) * Traits.mod(hero, "cd") * Forge.totals(hero).cd

static func spell_factor(hero: Dictionary) -> float:
 return (1.20 if hero.get("evolution", "") == "arcanist" else 1.0) * Traits.mod(hero, "potency") * (1.0 + Forge.totals(hero).potency)

static func choices(hero: Dictionary, won: bool, rng: RandomNumberGenerator, reward_level: int = -1) -> Array:
 var out = []
 var level = int(hero.level) if reward_level < 0 else reward_level
 if level >= 10 and hero.get("evolution", "").is_empty():
  for key in EVOLUTIONS:
   var e = EVOLUTIONS[key]
   out.append({"type":"evolution", "key":key, "name":species[hero.sp].n + " · " + e.name, "description":e.description, "rarity":"Evolution", "bonus":1.0})
  return out
 if hero.learned.size() + 1 < ABILITY_SLOTS:
  for i in range(DISCOVERY_CHOICES):
   if hero.learned.has(str(i)): continue
   var a = learned_ability(hero.sp, i)
   out.append({"type":"ability", "key":str(i), "name":a.name + " · Rank 1", "description":a.description + " Adds an automatic action to an empty ability slot.", "rarity":"Uncommon", "bonus":1.0})
 else:
  for key in hero.learned:
   if int(hero.learned[key]) >= 2: continue
   var a = learned_ability(hero.sp, int(key))
   out.append({"type":"ability", "key":key, "name":a.name + " · Rank 2", "description":a.description + " Rank 2: +20% potency and 8% shorter cooldown.", "rarity":"Uncommon", "bonus":1.0})
  if hero.signature_rank < 2:
   out.append({"type":"signature", "key":"signature", "name":species[hero.sp].ability_name + " · Rank 2", "description":"Your signature gains 20% potency and an 8% shorter cooldown.", "rarity":"Uncommon", "bonus":1.0})
 # Fisher-Yates uses the saved reward seed, never global random state.
 for i in range(out.size()-1, 0, -1):
  var j = rng.randi_range(0, i); var temp = out[i]; out[i] = out[j]; out[j] = temp
 # Prefer previously unseen cards while there are enough alternatives.
 var recent = hero.get("last_offers", []).duplicate()
 if hero.learned.size()+1<ABILITY_SLOTS:recent.append_array(hero.get("offered_discoveries",[]))
 var fresh = out.filter(func(c): return c.key not in recent)
 var repeat = out.filter(func(c): return c.key in recent)
 out = (fresh + repeat).slice(0, 3)
 if out.is_empty():
  for t in [["vigor", "Iron Vitality", "+10% maximum health."], ["force", "Killing Instinct", "+8% attack."], ["focus", "Arcane Affinity", "+8% ability potency."]]:
   out.append({"type":t[0], "key":t[0], "name":t[1], "description":"All four abilities are ranked up. " + t[2], "rarity":"Common", "bonus":1.0})
 for card in out:
  if card.type in ["ability","signature"]:
   var roll=rng.randf()
   if level>=5 and roll<(0.09 if won else 0.05):
    card.rarity="Legendary";card.bonus=1.25;card.description+=" Legendary: +75% potency, a gilded spell effect and a moment in the spotlight. Recharges 12% slower."
   elif roll<(0.31 if won else 0.21):
    card.rarity="Rare";card.bonus=1.1;card.description+=" Rare: +30% potency and a luminous spell effect."
 return out

static func apply_choice(hero: Dictionary, card: Dictionary) -> void:
 if card.type in ["ability","signature"]:
  if card.type=="ability" and not hero.learned.has(card.key) and hero.learned.size()+1>=ABILITY_SLOTS:return
  if not hero.has("skill_rarity"):hero.skill_rarity={}
  var previous=RarityStyle.for_skill(hero,"signature" if card.type=="signature" else "ability:"+card.key)
  if previous!="Legendary" and (card.rarity=="Legendary" or previous!="Rare"):hero.skill_rarity[card.key]=card.rarity
 match card.type:
  "ability":
   if not hero.learned.has(card.key) and hero.learned.size()+1 >= ABILITY_SLOTS: return
   hero.learned[card.key] = mini(2, int(hero.learned.get(card.key, 0)) + 1)
   hero["ability_bonus_" + card.key] = maxf(hero.get("ability_bonus_" + card.key, 1.0), card.bonus)
  "signature":
   hero.signature_rank = mini(2, hero.signature_rank + 1)
   hero.signature_bonus=maxf(hero.get("signature_bonus",1.0),card.bonus)
  "evolution":
   if not hero.get("evolution", "").is_empty(): return
   hero.evolution = card.key
  "vigor", "force", "focus": hero[card.type] = int(hero.get(card.type, 0)) + 1
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

static func migrate_progression(hero: Dictionary) -> void:
 if hero.get("progression_version", 0) >= 2: return
 var count = hero.get("pending", []).size()
 hero.pending = []; hero.rewards = []; hero.last_offers = []
 hero.evolution = hero.get("evolution", "")
 hero.progression_version = 2
 # Existing high-level heroes receive their missed evolution once, without a reset.
 if hero.level >= 10 and hero.evolution.is_empty(): queue_reward(hero, 10, false, hash(hero.id + "evolution"))
 for i in range(count): queue_reward(hero, maxi(2, int(hero.level)-count+i+1), false, hash(hero.id + str(i)))

static func xp_needed(level: int) -> int:
 return 100 + (level - 1) * 30
