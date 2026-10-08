class_name Bestiary
extends RefCounted
## The dungeon's own monsters. Each mob reuses a creature model with its own skin tint, size, name,
## stat profile and (sometimes) a borrowed item behaviour. Wardens add fight mechanics on top:
## summoned adds, ground slams, enrage, shielded phases and pulses that hit the whole squad.
##   stats: hp / attack / power / haste / speed (+fraction), armor (+flat), crit / dodge (+chance)
## Mobs are grouped by the dungeon instance they live in (see DungeonInstances).

const MOBS := {
 # The Blight Forest
 "gloomfang":     {"name": "Gloomfang", "sp": "direwolf", "tint": "5b4a2a", "scale": 1.0, "stats": {"haste": 0.15, "hp": -0.10}, "text": "Fast pack hunter."},
 "thornback":     {"name": "Thornback Troll", "sp": "troll", "tint": "4f7a32", "scale": 1.12, "stats": {"hp": 0.20, "attack": -0.08}, "grant": ["spikes"], "text": "Thorny hide stuns attackers."},
 "sporeling":     {"name": "Sporeling", "sp": "treant", "tint": "a8c95a", "scale": 0.82, "stats": {"hp": -0.15, "power": 0.15}, "text": "Small healer that spreads spores."},
 "rotwing":       {"name": "Rotwing", "sp": "wyvern", "tint": "7a8a2a", "scale": 0.95, "stats": {"crit": 0.15}, "text": "Spits blighted venom."},
 # The Mana Caverns
 "mana_wisp":     {"name": "Mana Wisp", "sp": "kirin", "tint": "5ad8ff", "scale": 0.8, "stats": {"power": 0.20, "hp": -0.18}, "text": "Crackling arcane caster."},
 "crystal_golem": {"name": "Crystal Golem", "sp": "golem", "tint": "7fe8ff", "scale": 1.05, "stats": {"armor": 0.05, "speed": -0.10}, "text": "Slow, hard and glittering."},
 "glimmerfox":    {"name": "Glimmerfox", "sp": "kitsune", "tint": "8aa8ff", "scale": 0.95, "stats": {"dodge": 0.15, "hp": -0.05}, "text": "Hard to pin down."},
 "shardscale":    {"name": "Shardscale", "sp": "basilisk", "tint": "3ac0c8", "scale": 1.0, "stats": {"power": 0.12, "armor": 0.02}, "text": "Its gaze crystallises."},
 # The Magma Depths
 "ember_imp":     {"name": "Ember Imp", "sp": "salamander", "tint": "ff5a2a", "scale": 0.78, "stats": {"power": 0.20, "hp": -0.18}, "text": "Fragile, explosive caster."},
 "magma_hound":   {"name": "Magma Hound", "sp": "cerberus", "tint": "ff7a30", "scale": 1.0, "stats": {"attack": 0.08, "hp": -0.06}, "text": "Molten jaws."},
 "slagbrute":     {"name": "Slagbrute", "sp": "minotaur", "tint": "5a2a22", "scale": 1.15, "stats": {"hp": 0.12, "attack": 0.03, "speed": -0.10}, "text": "Hulking forge guard."},
 "ash_golem":     {"name": "Ash Golem", "sp": "golem", "tint": "6b6460", "scale": 1.08, "stats": {"armor": 0.05, "haste": -0.12}, "grant": ["bastion"], "text": "Shields itself when cracked."},
 # The Frostbound Crypt
 "rimefang":      {"name": "Rimefang", "sp": "direwolf", "tint": "bfe8ff", "scale": 1.0, "stats": {"haste": 0.10, "armor": 0.02}, "text": "Its bite numbs."},
 "frost_wraith":  {"name": "Frost Wraith", "sp": "wendigo", "tint": "7fc8ff", "scale": 1.05, "stats": {"attack": 0.10, "speed": 0.10, "hp": -0.05}, "text": "Cold and hungry."},
 "glacier_yeti":  {"name": "Glacier Yeti", "sp": "yeti", "tint": "e8f6ff", "scale": 1.1, "stats": {"hp": 0.15, "speed": -0.08}, "text": "A walking snowdrift."},
 "rime_harpy":    {"name": "Rime Harpy", "sp": "harpy", "tint": "a8d8f0", "scale": 0.95, "stats": {"crit": 0.12}, "text": "Dives on frozen wings."},
 # The Drowned Sanctum
 "tide_naga":     {"name": "Tide Naga", "sp": "naga", "tint": "2a8ab0", "scale": 1.0, "stats": {"power": 0.12}, "text": "Sings the sea back in."},
 "brine_serpent": {"name": "Brine Serpent", "sp": "basilisk", "tint": "2a6a8a", "scale": 1.05, "stats": {"hp": 0.08, "attack": 0.04}, "text": "Coils from the flooded halls."},
 "shellback":     {"name": "Shellback", "sp": "zaratan", "tint": "4a8a7a", "scale": 0.85, "stats": {"armor": 0.06, "haste": -0.10}, "text": "A small fortress."},
 "siren":         {"name": "Siren", "sp": "harpy", "tint": "4ab0d8", "scale": 0.95, "stats": {"power": 0.10, "dodge": 0.08}, "text": "Lures the careless in."},
 # The Fungal Hollows
 "mycelid":       {"name": "Mycelid", "sp": "treant", "tint": "b07ad8", "scale": 0.9, "stats": {"hp": 0.08, "power": 0.08}, "text": "A walking mushroom grove."},
 "spore_spider":  {"name": "Spore Spider", "sp": "arachne", "tint": "c08aff", "scale": 0.85, "stats": {"haste": 0.10, "hp": -0.08}, "text": "Leaves glowing spores behind."},
 "capbear":       {"name": "Capbear", "sp": "owlbear", "tint": "a85ab0", "scale": 1.05, "stats": {"hp": 0.12, "attack": 0.04}, "text": "Covered in fungal plates."},
 "glowmoth":      {"name": "Glowmoth", "sp": "pegasus", "tint": "e0a8ff", "scale": 0.85, "stats": {"power": 0.10, "speed": 0.08}, "text": "Its dust heals its kin."},
 # The Ossuary of Kings
 "bone_gargoyle": {"name": "Bone Gargoyle", "sp": "gargoyle", "tint": "e8dcc0", "scale": 1.0, "stats": {"armor": 0.05, "attack": 0.05}, "text": "Carved from old bones."},
 "grave_hound":   {"name": "Grave Hound", "sp": "cerberus", "tint": "d8d0b8", "scale": 1.0, "stats": {"attack": 0.08, "hp": -0.04}, "text": "Three heads, no flesh."},
 "crypt_knight":  {"name": "Crypt Knight", "sp": "minotaur", "tint": "c8c0a8", "scale": 1.1, "stats": {"armor": 0.04, "hp": 0.06}, "text": "Still guards a king long dead."},
 "wight":         {"name": "Wight", "sp": "nekomata", "tint": "e0e0d0", "scale": 1.0, "stats": {"crit": 0.12, "dodge": 0.05}, "text": "A pale, quick killer."},
 # The Storm Spire
 "storm_harpy":   {"name": "Storm Harpy", "sp": "harpy", "tint": "ffe85a", "scale": 0.95, "stats": {"haste": 0.12}, "text": "Rides the lightning."},
 "thunderhawk":   {"name": "Thunderhawk", "sp": "griffin", "tint": "d8c84a", "scale": 1.0, "stats": {"attack": 0.10, "hp": -0.05}, "text": "Strikes like thunder."},
 "spark_kirin":   {"name": "Spark Kirin", "sp": "kirin", "tint": "fff08a", "scale": 0.9, "stats": {"power": 0.15, "hp": -0.08}, "text": "Arcs between its foes."},
 "galvanic_golem": {"name": "Galvanic Golem", "sp": "golem", "tint": "8a9aa8", "scale": 1.05, "stats": {"armor": 0.05, "attack": 0.03}, "grant": ["lightningrod"], "text": "Answers spells with lightning."},
 # The Gilded Tomb
 "sand_manticore": {"name": "Sand Manticore", "sp": "manticore", "tint": "e0b860", "scale": 1.0, "stats": {"crit": 0.12}, "text": "A sting from under the dunes."},
 "tomb_jackal":   {"name": "Tomb Jackal", "sp": "jackalope", "tint": "d8a83a", "scale": 1.0, "stats": {"haste": 0.12, "hp": -0.06}, "text": "Gilded guardian of the dead."},
 "mummified_lion": {"name": "Mummified Lion", "sp": "nemean", "tint": "d8c8a0", "scale": 1.05, "stats": {"hp": 0.12, "speed": -0.06}, "text": "Wrapped and still roaring."},
 "scarab_golem":  {"name": "Scarab Golem", "sp": "golem", "tint": "3a8a6a", "scale": 1.0, "stats": {"armor": 0.06, "haste": -0.08}, "text": "Beetle-shell plates."},
 # The Void Rift
 "shade_stalker": {"name": "Shade Stalker", "sp": "nekomata", "tint": "2a1a44", "scale": 1.0, "stats": {"dodge": 0.15, "crit": 0.12}, "text": "Strikes from the dark."},
 "void_weaver":   {"name": "Void Weaver", "sp": "arachne", "tint": "4a2a7a", "scale": 1.0, "stats": {"power": 0.12, "hp": 0.05}, "text": "Spins webs of nothing."},
 "star_wraith":   {"name": "Star Wraith", "sp": "wendigo", "tint": "8a7aff", "scale": 1.05, "stats": {"attack": 0.10, "speed": 0.10, "hp": -0.05}, "text": "Cold and hungry."},
 "mind_eater":    {"name": "Mind Eater", "sp": "basilisk", "tint": "8a3a9a", "scale": 1.05, "stats": {"power": 0.15}, "text": "Its stare turns thought to stone."},
}

## Wardens. Their strength comes from the depth they guard (see strength()); "weight" scales that
## for how dangerous their mechanics already are, so any Warden can guard any depth fairly.
##   summon  {mob, every, count}       slam   {every, radius, damage, stun}
##   enrage  {below, haste, attack}    phases {at: [...], shield, mob, count}
##   pulse   {every, damage, status, seconds}: hits the whole squad
##   regen   health per second (fraction)
const BOSSES := {
 "rootmother": {"name": "The Rootmother", "sp": "treant", "tint": "2f6a2a", "glow": "8fe08a", "scale": 1.75, "weight": [1.0, 1.3, 1.4],
  "summon": {"mob": "sporeling", "every": 13.0, "count": 2}, "regen": 0.004,
  "text": "Summons Sporelings every 13 seconds and slowly regrows."},
 "prismatic_archon": {"name": "The Prismatic Archon", "sp": "sphinx", "tint": "4ae0ff", "glow": "b8f4ff", "scale": 1.7, "weight": [1.0, 0.95, 0.8],
  "pulse": {"every": 9.0, "damage": 0.45, "status": "silence", "seconds": 1.2}, "phases": {"at": [0.5], "shield": 0.25, "mob": "mana_wisp", "count": 2},
  "text": "Every 9 seconds a mana surge hits your whole squad and silences it. At half health it shields itself and calls Mana Wisps."},
 "forge_tyrant": {"name": "Magmaw, the Forge Tyrant", "sp": "minotaur", "tint": "b33a12", "glow": "ff9a4a", "scale": 1.7, "weight": [0.35, 0.42, 0.5],
  "slam": {"every": 11.0, "radius": 2.6, "damage": 0.6, "stun": 0.5}, "enrage": {"below": 0.4, "haste": 0.30, "attack": 0.15},
  "text": "Slams the ground every 11 seconds, stunning everyone close. Enrages below 40% health."},
 "frost_matriarch": {"name": "The Frost Matriarch", "sp": "yeti", "tint": "cfeeff", "glow": "e8faff", "scale": 1.75, "weight": [0.9, 1.2, 1.3],
  "pulse": {"every": 8.0, "damage": 0.3, "status": "slow", "seconds": 2.5}, "enrage": {"below": 0.35, "haste": 0.25, "attack": 0.10},
  "text": "Blizzard: every 8 seconds the whole squad takes cold damage and slows. Enrages below 35% health."},
 "leviathan": {"name": "The Drowned Leviathan", "sp": "hydra", "tint": "1a5a8a", "glow": "7fd8ff", "scale": 1.75, "weight": [0.6, 0.57, 0.62],
  "summon": {"mob": "siren", "every": 15.0, "count": 1}, "regen": 0.005, "slam": {"every": 13.0, "radius": 2.8, "damage": 0.5, "stun": 0.4},
  "text": "Tidal slams, Sirens from the deep every 15 seconds, and steady regeneration."},
 "spore_queen": {"name": "The Spore Queen", "sp": "arachne", "tint": "8a3ac8", "glow": "e0a8ff", "scale": 1.7, "weight": [1.1, 1.8, 1.8],
  "summon": {"mob": "spore_spider", "every": 11.0, "count": 2}, "pulse": {"every": 12.0, "damage": 0.25, "status": "slow", "seconds": 1.5},
  "text": "Hatches Spore Spiders every 11 seconds and releases choking spore clouds."},
 "bone_king": {"name": "The Bone King", "sp": "chimera", "tint": "e8dcc0", "glow": "fff2c8", "scale": 1.7, "weight": [0.5, 0.7, 0.6],
  "phases": {"at": [0.66, 0.33], "shield": 0.2, "mob": "bone_gargoyle", "count": 1}, "enrage": {"below": 0.25, "haste": 0.25, "attack": 0.15},
  "text": "Raises Bone Gargoyles and shields itself at two-thirds and one-third health, then enrages near death."},
 "tempest_roc": {"name": "The Tempest Roc", "sp": "thunderbird", "tint": "e8d84a", "glow": "fff6a8", "scale": 1.75, "weight": [0.95, 1.4, 1.25],
  "pulse": {"every": 7.0, "damage": 0.35, "status": "stun", "seconds": 0.35}, "enrage": {"below": 0.5, "haste": 0.20, "attack": 0.0},
  "text": "Chain lightning every 7 seconds strikes and briefly stuns the whole squad. Faster below half health."},
 "sun_pharaoh": {"name": "The Sun-Eater Pharaoh", "sp": "sphinx", "tint": "e8b83a", "glow": "ffe8a0", "scale": 1.7, "weight": [0.5, 0.75, 0.6],
  "phases": {"at": [0.6, 0.3], "shield": 0.25, "mob": "tomb_jackal", "count": 2}, "slam": {"every": 12.0, "radius": 2.6, "damage": 0.6, "stun": 0.5},
  "text": "Sunfire slams and, at 60% and 30% health, a golden ward and two Tomb Jackals."},
 "abyssal_keeper": {"name": "The Abyssal Keeper", "sp": "hydra", "tint": "1e1240", "glow": "b9a2ff", "scale": 1.8, "weight": [0.65, 0.8, 1.0],
  "phases": {"at": [0.66, 0.33], "shield": 0.22, "mob": "shade_stalker", "count": 2}, "slam": {"every": 11.0, "radius": 2.6, "damage": 1.0, "stun": 0.6},
  "text": "At two-thirds and one-third health it shields itself and calls Shade Stalkers. Slams the ground."},
}

static func info(key: String) -> Dictionary:
 return MOBS.get(key, BOSSES.get(key, {}))

## How strong a Warden's stats are at a depth, given its mechanics. A list holds one value per depth
## (summoners need more at depth 2-3, where their adds fall behind the squad), a number all depths.
static func weight(key: String, depth: int) -> float:
 var w = BOSSES[key].get("weight", 1.0)
 return float(w[clampi(depth, 1, 3) - 1]) if w is Array else float(w)

## A Warden's health / damage bonus at a depth (1-3; endless adds its own empowerment).
static func strength(key: String, depth: int) -> Dictionary:
 var d = clampi(depth, 1, 3) - 1
 var w = weight(key, depth)
 return {"hp": (1.6 + 0.65 * d) * w, "attack": (0.18 + 0.135 * d) * w, "power": (0.18 + 0.085 * d) * w, "armor": 0.02 + 0.01 * d}

## A monster as a hero dictionary the battle sim understands. Rival levels, rarity and gear follow
## the same TourBalance curve as the guild run's rivals.
static func make(key: String, id: String, level: int, stage: int, difficulty: String, slot: int) -> Dictionary:
 var m = info(key)
 var h = HeroData.make_hero(m.sp, id, m.name, level)
 h.name = m.name; h.monster = key; h.slot = slot
 for k in range(mini(3, maxi(0, level - 1))): h.learned[str(k)] = 2 if level >= 8 else 1
 if level >= 5: h.signature_rank = 2
 var tier = TourBalance.rarity(stage, difficulty, id)
 h.skill_rarity = {"0": tier}; h.ability_bonus_0 = 1.25 if tier == "Legendary" else 1.1 if tier == "Rare" else 1.0
 h.equipment = Forge.rival_loadout(h, stage, difficulty)
 if level >= HeroData.EVOLVE_LEVEL: h.evolution = "%s:%d" % [m.sp, abs(hash(id)) % 3]
 return h

# ------------------------------------------------------------------ Combat
static func apply(sim: BattleSim, u: Dictionary) -> void:
 var key = str(u.hero.monster); var m = info(key)
 if m.is_empty(): return
 # Monsters ignore the run's random draft tiers: a Warden is as strong whichever tier its model rolled.
 var tf = League.stat_factor(str(u.hero.sp)) / float(League.BALANCE.get(str(u.hero.sp), 1.0))
 u.max_hp /= tf; u.hp = u.max_hp; u.attack /= tf; u.attack_basic = u.get("attack_basic", u.attack) / tf; u.ability_power /= tf; u.skill_base /= tf
 var mod = (strength(key, int(u.hero.get("depth", 1))) if BOSSES.has(key) else m.get("stats", {})).duplicate()
 var boost = float(u.hero.get("empower", 0.0))
 # Wardens were tuned against five champions; a smaller guild meets a smaller Warden.
 if BOSSES.has(key) and u.hero.has("party"):
  var p = clampi(int(u.hero.party), 1, 5)
  mod.hp = (1.0 + float(mod.get("hp", 0.0))) * (0.25 + 0.15 * p) - 1.0
  mod.attack = (1.0 + float(mod.get("attack", 0.0))) * (0.5 + 0.1 * p) - 1.0
  mod.power = (1.0 + float(mod.get("power", 0.0))) * (0.5 + 0.1 * p) - 1.0
 if boost > 0.0:
  for k in ["hp", "attack", "power"]: mod[k] = (1.0 + float(mod.get(k, 0.0))) * (1.0 + boost) - 1.0
 if m.has("grant"): mod.grant = m.grant
 Relics.apply(sim, u, [mod])
 u.radius *= minf(1.35, float(m.get("scale", 1.0)))
 if BOSSES.has(key):
  u.boss = {"key": key, "summon_t": float(m.get("summon", {}).get("every", 0.0)), "slam_t": float(m.get("slam", {}).get("every", 0.0)) * 0.7, "pulse_t": float(m.get("pulse", {}).get("every", 0.0)), "phase": 0, "enraged": false}
  u.fx.tenacity = maxf(float(u.fx.get("tenacity", 0.0)), 0.5)

static func tick(sim: BattleSim, u: Dictionary, dt: float) -> void:
 var b = u.boss; var m = BOSSES[b.key]
 if m.has("regen"): sim.heal(u, u, u.max_hp * float(m.regen) * dt, "regeneration")
 if m.has("summon"):
  b.summon_t -= dt
  if b.summon_t <= 0.0:
   b.summon_t = float(m.summon.every); call_adds(sim, u, str(m.summon.mob), int(m.summon.count))
 if m.has("slam"):
  b.slam_t -= dt
  var close = sim.near_foes(u, u.pos, float(m.slam.radius))
  if b.slam_t <= 0.0 and not close.is_empty():
   b.slam_t = float(m.slam.every)
   sim.emit({"type": "cast", "uid": u.uid, "effect": "quake", "name": "Seismic Slam", "pos": u.pos, "target": u.pos})
   sim.cc_source = u
   for e in close:
    sim.hurt(u, e, u.attack * float(m.slam.damage), false, "signature"); sim.status(e, "stun", float(m.slam.stun))
 if m.has("pulse"):
  b.pulse_t -= dt
  if b.pulse_t <= 0.0:
   b.pulse_t = float(m.pulse.every)
   var effect = {"silence": "radiance", "slow": "frost", "stun": "storm"}.get(str(m.pulse.status), "shriek")
   sim.emit({"type": "cast", "uid": u.uid, "effect": effect, "name": "Warden's Pulse", "pos": u.pos, "target": u.pos})
   sim.cc_source = u
   for e in sim.foes(u):
    if not e.alive: continue
    sim.hurt(u, e, u.attack * float(m.pulse.damage), true, "signature"); sim.status(e, str(m.pulse.status), float(m.pulse.seconds))
 if m.has("enrage") and not b.enraged and u.hp / u.max_hp < float(m.enrage.below):
  b.enraged = true
  u.interval /= 1.0 + float(m.enrage.haste); u.fx.base_interval = u.interval
  u.attack *= 1.0 + float(m.enrage.attack); u.attack_basic = u.get("attack_basic", u.attack) * (1.0 + float(m.enrage.attack))
  sim.emit({"type": "cast", "uid": u.uid, "effect": "prideroar", "name": "Enrage", "pos": u.pos, "target": u.pos})
 if m.has("phases") and int(b.phase) < m.phases.at.size() and u.hp / u.max_hp < float(m.phases.at[int(b.phase)]):
  b.phase = int(b.phase) + 1
  sim.shield(u, u.max_hp * float(m.phases.shield)); u.shield_time = 8.0
  sim.emit({"type": "cast", "uid": u.uid, "effect": "vanish", "name": "Warden's Ward", "pos": u.pos, "target": u.pos})
  call_adds(sim, u, str(m.phases.mob), int(m.phases.count))

static func call_adds(sim: BattleSim, u: Dictionary, mob: String, count: int) -> void:
 var m = info(mob)
 for i in range(count):
  var h = HeroData.make_hero(m.sp, "%s_add_%d" % [u.hero.id, sim.uid], m.name, int(u.hero.level))
  h.monster = mob
  var a = TAU * (float(i) / maxf(1, count)) + sim.time
  var add = sim.add_unit(h, u.team, u.pos + Vector2(cos(a), sin(a)) * 1.6, 1.0, u.uid)
  add.ttl = 14.0; add.max_hp *= 1.6; add.hp = add.max_hp
 sim.emit({"type": "summon", "uid": u.uid, "pos": u.pos})

# ------------------------------------------------------------------ Looks
## Recolour the creature's skin, resize it and give Wardens a glowing rim.
static func dress(model: Node3D, flash_mat: ShaderMaterial, hero: Dictionary, summon: bool) -> void:
 var m = info(str(hero.get("monster", "")))
 if m.is_empty(): return
 if not summon: model.scale *= float(m.get("scale", 1.0))
 var skin = ShaderMaterial.new(); skin.shader = load("res://shaders/vfx/monster_skin.gdshader")
 skin.set_shader_parameter("tint", Color(m.tint)); skin.set_shader_parameter("strength", 0.6 if BOSSES.has(str(hero.monster)) else 0.5)
 skin.set_shader_parameter("rim", Color(m.get("glow", m.tint))); skin.set_shader_parameter("rim_amount", 1.2 if BOSSES.has(str(hero.monster)) else 0.35)
 flash_mat.next_pass = skin
