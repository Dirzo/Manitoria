class_name Bestiary
extends RefCounted
## The dungeon's own monsters. Each mob reuses a creature model with its own skin tint, size, name,
## stat profile and (sometimes) a borrowed item behaviour. Bosses add fight mechanics on top:
## summoned adds, ground slams, enrage and shielded phases.
##   stats: hp / attack / power / haste / speed (+fraction), armor (+flat), crit / dodge (+chance)

const MOBS := {
 # Depth 1 · The Rootbound Halls
 "gloomfang":    {"name": "Gloomfang", "sp": "direwolf", "tint": "5b3d8a", "scale": 1.0, "depth": [1, 4], "stats": {"haste": 0.15, "hp": -0.10}, "text": "Fast pack hunter."},
 "thornback":    {"name": "Thornback Troll", "sp": "troll", "tint": "4f7a32", "scale": 1.12, "depth": [1, 4], "stats": {"hp": 0.20, "attack": -0.08}, "grant": ["spikes"], "text": "Thorny hide stuns attackers."},
 "sporeling":    {"name": "Sporeling", "sp": "treant", "tint": "a8c95a", "scale": 0.82, "depth": [1, 4], "stats": {"hp": -0.15, "power": 0.15}, "text": "Small healer that spreads spores."},
 "briar_harpy":  {"name": "Briar Harpy", "sp": "harpy", "tint": "6d8f3a", "scale": 0.95, "depth": [1, 4], "stats": {"crit": 0.15}, "text": "Diving harrier with barbed talons."},
 "moss_golem":   {"name": "Moss Golem", "sp": "golem", "tint": "567a4a", "scale": 1.05, "depth": [1, 4], "stats": {"armor": 0.05, "speed": -0.10}, "text": "Slow wall of stone and moss."},
 # Depth 2 · The Cinder Vaults
 "ember_imp":    {"name": "Ember Imp", "sp": "salamander", "tint": "ff5a2a", "scale": 0.78, "depth": [2, 5], "stats": {"power": 0.20, "hp": -0.18}, "text": "Fragile, explosive caster."},
 "magma_hound":  {"name": "Magma Hound", "sp": "cerberus", "tint": "ff7a30", "scale": 1.0, "depth": [2, 5], "stats": {"attack": 0.08, "hp": -0.06}, "text": "Molten jaws."},
 "slagbrute":    {"name": "Slagbrute", "sp": "minotaur", "tint": "5a2a22", "scale": 1.15, "depth": [2, 5], "stats": {"hp": 0.12, "attack": 0.03, "speed": -0.10}, "text": "Hulking forge guard."},
 "cinder_wyrm":  {"name": "Cinder Wyrm", "sp": "wyvern", "tint": "d0471f", "scale": 1.0, "depth": [2, 5], "stats": {"attack": 0.12, "hp": -0.08}, "text": "Spits burning venom."},
 "ash_golem":    {"name": "Ash Golem", "sp": "golem", "tint": "6b6460", "scale": 1.08, "depth": [2, 5], "stats": {"armor": 0.05, "haste": -0.12}, "grant": ["bastion"], "text": "Shields itself when cracked."},
 # Depth 3 · The Starless Deep
 "shade_stalker": {"name": "Shade Stalker", "sp": "nekomata", "tint": "2a1a44", "scale": 1.0, "depth": [3, 6], "stats": {"dodge": 0.15, "crit": 0.12}, "text": "Strikes from the dark."},
 "void_weaver":  {"name": "Void Weaver", "sp": "arachne", "tint": "4a2a7a", "scale": 1.0, "depth": [3, 6], "stats": {"power": 0.12, "hp": 0.05}, "text": "Spins webs of nothing."},
 "star_wraith":  {"name": "Star Wraith", "sp": "wendigo", "tint": "7fc8ff", "scale": 1.05, "depth": [3, 6], "stats": {"attack": 0.10, "speed": 0.10, "hp": -0.05}, "text": "Cold and hungry."},
 "bone_gargoyle": {"name": "Bone Gargoyle", "sp": "gargoyle", "tint": "e8dcc0", "scale": 1.0, "depth": [3, 6], "stats": {"armor": 0.05, "attack": 0.05}, "text": "Carved from old bones."},
 "mind_eater":   {"name": "Mind Eater", "sp": "basilisk", "tint": "8a3a9a", "scale": 1.05, "depth": [3, 6], "stats": {"power": 0.15}, "text": "Its stare turns thought to stone."},
}

const BOSSES := {
 "rootmother": {"name": "The Rootmother", "sp": "treant", "tint": "2f6a2a", "glow": "8fe08a", "scale": 1.75, "depth": 1, "title": "Warden of Roots",
  "stats": {"hp": 1.6, "attack": 0.18, "power": 0.18, "armor": 0.02}, "summon": {"mob": "sporeling", "every": 13.0, "count": 2}, "regen": 0.004,
  "text": "Summons Sporelings every 13 seconds and slowly regrows."},
 "forge_tyrant": {"name": "Magmaw, the Forge Tyrant", "sp": "minotaur", "tint": "b33a12", "glow": "ff9a4a", "scale": 1.7, "depth": 2, "title": "Warden of Embers",
  "stats": {"hp": 1.1, "attack": 0.12, "armor": 0.02}, "slam": {"every": 11.0, "radius": 2.6, "damage": 0.6, "stun": 0.5}, "enrage": {"below": 0.4, "haste": 0.30, "attack": 0.15},
  "text": "Slams the ground every 11 seconds, stunning everyone close. Enrages below 40% health."},
 "abyssal_keeper": {"name": "The Abyssal Keeper", "sp": "hydra", "tint": "1e1240", "glow": "b9a2ff", "scale": 1.8, "depth": 3, "title": "Keeper of the Deep",
  "stats": {"hp": 2.9, "attack": 0.45, "power": 0.35, "armor": 0.04}, "phases": {"at": [0.66, 0.33], "shield": 0.22, "mob": "shade_stalker", "count": 2}, "slam": {"every": 11.0, "radius": 2.6, "damage": 1.0, "stun": 0.6},
  "text": "At two-thirds and one-third health it shields itself and calls Shade Stalkers. Slams the ground."},
}
const BOSS_ORDER := ["rootmother", "forge_tyrant", "abyssal_keeper"]

static func info(key: String) -> Dictionary:
 return MOBS.get(key, BOSSES.get(key, {}))

static func pool(act: int) -> Array:
 var a = act if act <= 3 else ((act - 1) % 3) + 1
 var keys = MOBS.keys().filter(func(k): return a in MOBS[k].depth)
 keys.sort()
 return keys

static func boss_for(act: int) -> String:
 return BOSS_ORDER[(act - 1) % BOSS_ORDER.size()]

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
 var m = info(str(u.hero.monster))
 if m.is_empty(): return
 # Monsters ignore the run's random draft tiers: a Warden is as strong whichever tier its model rolled.
 var tf = League.stat_factor(str(u.hero.sp)) / float(League.BALANCE.get(str(u.hero.sp), 1.0))
 u.max_hp /= tf; u.hp = u.max_hp; u.attack /= tf; u.attack_basic = u.get("attack_basic", u.attack) / tf; u.ability_power /= tf; u.skill_base /= tf
 var mod = m.get("stats", {}).duplicate()
 var boost = float(u.hero.get("empower", 0.0))
 if boost > 0.0:
  for k in ["hp", "attack", "power"]: mod[k] = (1.0 + float(mod.get(k, 0.0))) * (1.0 + boost) - 1.0
 if m.has("grant"): mod.grant = m.grant
 Relics.apply(sim, u, [mod])
 u.radius *= minf(1.35, float(m.get("scale", 1.0)))
 if BOSSES.has(str(u.hero.monster)):
  u.boss = {"key": str(u.hero.monster), "summon_t": float(m.get("summon", {}).get("every", 0.0)), "slam_t": float(m.get("slam", {}).get("every", 0.0)) * 0.7, "phase": 0, "enraged": false}
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
 if m.has("enrage") and not b.enraged and u.hp / u.max_hp < float(m.enrage.below):
  b.enraged = true
  u.interval /= 1.0 + float(m.enrage.haste); u.fx.base_interval = u.interval
  u.attack *= 1.0 + float(m.enrage.attack); u.attack_basic = u.get("attack_basic", u.attack) * (1.0 + float(m.enrage.attack))
  sim.emit({"type": "cast", "uid": u.uid, "effect": "prideroar", "name": "Enrage", "pos": u.pos, "target": u.pos})
 if m.has("phases") and int(b.phase) < m.phases.at.size() and u.hp / u.max_hp < float(m.phases.at[int(b.phase)]):
  b.phase = int(b.phase) + 1
  sim.shield(u, u.max_hp * float(m.phases.shield)); u.shield_time = 8.0
  sim.emit({"type": "cast", "uid": u.uid, "effect": "vanish", "name": "Abyssal Ward", "pos": u.pos, "target": u.pos})
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
## Recolour the creature's skin, resize it and give bosses a glowing rim.
static func dress(model: Node3D, flash_mat: ShaderMaterial, hero: Dictionary, summon: bool) -> void:
 var m = info(str(hero.get("monster", "")))
 if m.is_empty(): return
 if not summon: model.scale *= float(m.get("scale", 1.0))
 var skin = ShaderMaterial.new(); skin.shader = load("res://shaders/vfx/monster_skin.gdshader")
 skin.set_shader_parameter("tint", Color(m.tint)); skin.set_shader_parameter("strength", 0.6 if BOSSES.has(str(hero.monster)) else 0.5)
 skin.set_shader_parameter("rim", Color(m.get("glow", m.tint))); skin.set_shader_parameter("rim_amount", 1.2 if BOSSES.has(str(hero.monster)) else 0.35)
 flash_mat.next_pass = skin
