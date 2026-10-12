class_name WardenMechanics
extends RefCounted
## Simulation-only mechanics. Sound and presentation consume the same events in watched fights.
const KITS := {
 "rootmother": {"name":"Bramble Cage", "effect":"roots", "every":14.0, "radius":4.0, "damage":0.55, "status":"root", "seconds":1.4, "counter":"Spread out; interrupt the cage before it closes."},
 "prismatic_archon": {"name":"Mana Fracture", "effect":"beam", "every":13.0, "radius":1.6, "damage":0.75, "status":"silence", "seconds":1.8, "counter":"Protect your strongest caster; silence interrupts the fracture."},
 "forge_tyrant": {"name":"Crucible Brand", "effect":"magma", "every":15.0, "radius":4.0, "damage":0.35, "counter":"Keep the backline mobile; the marked floor burns for four seconds."},
 "frost_matriarch": {"name":"Icebound Prison", "effect":"frost", "every":14.0, "radius":3.5, "damage":0.55, "status":"root", "seconds":1.8, "counter":"Separate your damage dealers; control interrupts the prison."},
 "leviathan": {"name":"Undertow", "effect":"tidal", "every":15.0, "radius":4.0, "damage":0.50, "status":"slow", "seconds":2.0, "counter":"The distant backline is pulled toward the Leviathan; interrupt Undertow."},
 "spore_queen": {"name":"Virulent Bloom", "effect":"toxic", "every":14.0, "radius":4.2, "damage":0.25, "counter":"Spread out and bring sustain; poison lasts four seconds."},
 "bone_king": {"name":"Soul Tithe", "effect":"drain", "every":14.0, "radius":1.5, "damage":0.70, "counter":"Guard wounded allies; the King heals from damage actually dealt."},
 "tempest_roc": {"name":"Storm Conductor", "effect":"chain", "every":13.0, "radius":4.0, "damage":0.65, "counter":"Spread out: lightning jumps to at most three nearby champions."},
 "sun_pharaoh": {"name":"Solar Judgment", "effect":"fire", "every":15.0, "radius":4.0, "damage":0.45, "counter":"Move the backline away from the marked sunfire; interrupt its charge."},
 "abyssal_keeper": {"name":"Rift Collapse", "effect":"vanish", "every":14.0, "radius":4.2, "damage":0.65, "status":"weaken", "seconds":2.0, "counter":"Avoid clustering: the rift pulls victims together and weakens them."}
}
const WINDUP := 1.25

static func event(sim: BattleSim, u: Dictionary, action: String, effect: String, title: String, target: Vector2, kind: String = "cast", extra: Dictionary = {}) -> void:
 var e = {"type":kind, "uid":u.uid, "pos":u.pos, "target":target, "effect":effect, "name":title, "credit":"boss:" + action, "boss_key":u.boss.key, "boss_action":action}
 e.merge(extra, true); sim.emit(e)

static func begin(sim: BattleSim, u: Dictionary, kind: String, spec: Dictionary, target: Vector2) -> void:
 u.boss_pending = {"kind":kind, "spec":spec.duplicate(true), "target":target, "delay":WINDUP, "total":WINDUP}
 u.velocity = Vector2.ZERO
 event(sim, u, "warning", str(spec.effect), str(spec.name), target, "telegraph", {"duration":WINDUP, "radius":spec.get("radius", 0.0)})

static func tick(sim: BattleSim, u: Dictionary, dt: float) -> void:
 var b = u.boss; var m = Bestiary.BOSSES[b.key]
 if not u.alive:
  u.erase("boss_pending"); return
 if u.has("boss_pending"):
  var p = u.boss_pending
  if sim.active(u, "stun") or sim.active(u, "silence"):
   u.erase("boss_pending")
   event(sim, u, "interrupt", str(p.spec.effect), str(p.spec.name), p.target, "interrupt")
   return
  p.delay -= dt
  if p.delay <= 0.0:
   u.erase("boss_pending"); resolve(sim, u, p)
   u.recovery = maxf(u.recovery, 0.22); u.recovery_clip = "cast"
  return
 # Boss timers stop under control. No spells or summons while stunned/silenced.
 if sim.active(u, "stun") or sim.active(u, "silence"): return
 for kind in ["summon", "slam", "pulse"]:
  if m.has(kind): b[kind + "_t"] -= dt
 b.special_t -= dt
 # Existing champion attacks finish first; only one Warden warning can be active.
 if u.windup > 0.0 or u.has("pending_cast") or u.has("next_cell") or u.recovery > 0.0: return
 if m.has("summon") and b.summon_t <= 0.0:
  b.summon_t = float(m.summon.every)
  begin(sim, u, "summon", {"name":"Call the Brood", "effect":"brood", "mob":m.summon.mob, "count":m.summon.count}, u.pos); return
 if m.has("slam") and b.slam_t <= 0.0 and not sim.near_foes(u, u.pos, float(m.slam.radius)).is_empty():
  b.slam_t = float(m.slam.every)
  var spec = m.slam.duplicate(true); spec.name = "Warden Slam"; spec.effect = "quake"
  spec.radius = maxf(float(spec.radius), ArenaGrid.ROW_GAP + 0.15)
  begin(sim, u, "slam", spec, u.pos); return
 if m.has("pulse") and b.pulse_t <= 0.0:
  b.pulse_t = float(m.pulse.every)
  var spec = m.pulse.duplicate(true); spec.name = "Warden Pulse"; spec.effect = {"silence":"radiance", "slow":"frost", "stun":"storm"}.get(str(spec.status), "shriek")
  begin(sim, u, "pulse", spec, u.pos); return
 if b.special_t <= 0.0:
  var targets = sim.foes(u).filter(func(v): return not v.summon)
  if targets.is_empty(): targets = sim.foes(u)
  if targets.is_empty(): return
  targets.sort_custom(func(a, c):
   var av = a.hp / a.max_hp if b.key == "bone_king" else -a.ability_power if b.key == "prismatic_archon" else -a.attack if b.key == "frost_matriarch" else -u.pos.distance_squared_to(a.pos)
   var cv = c.hp / c.max_hp if b.key == "bone_king" else -c.ability_power if b.key == "prismatic_archon" else -c.attack if b.key == "frost_matriarch" else -u.pos.distance_squared_to(c.pos)
   return a.uid < c.uid if is_equal_approx(av, cv) else av < cv)
  var spec = KITS[b.key]
  b.special_t = float(spec.every)
  begin(sim, u, "special", spec, targets[0].pos)

static func area_foes(sim: BattleSim, u: Dictionary, center: Vector2, radius: float) -> Array:
 return sim.foes(u).filter(func(v): return v.pos.distance_squared_to(center) <= radius * radius)

static func resolve(sim: BattleSim, u: Dictionary, p: Dictionary) -> void:
 var spec = p.spec; var old_credit = u.credit
 u.credit = "boss:" + str(p.kind); sim.cc_source = u
 sim.track(u, "casts", 1.0, u.credit)
 event(sim, u, str(p.kind), str(spec.effect), str(spec.name), p.target)
 if p.kind == "summon":
  Bestiary.call_adds(sim, u, str(spec.mob), int(spec.count))
 else:
  var targets = sim.foes(u) if p.kind == "pulse" else area_foes(sim, u, p.target, float(spec.radius))
  if p.kind == "special" and u.boss.key == "tempest_roc":
   # Chain starts at the marked floor, then jumps only to a nearby, unhit opponent.
   targets.sort_custom(func(a, c): return a.pos.distance_squared_to(p.target) < c.pos.distance_squared_to(p.target))
   var chain: Array = []
   if not targets.is_empty():
    chain.append(targets[0])
    while chain.size() < 3:
     var last = chain[-1]; var next = area_foes(sim, u, last.pos, float(spec.radius)).filter(func(v): return v not in chain)
     if next.is_empty(): break
     next.sort_custom(func(a, c): return a.pos.distance_squared_to(last.pos) < c.pos.distance_squared_to(last.pos))
     chain.append(next[0])
   targets = chain
  var drained = 0.0
  for e in targets:
   if not u.alive: break
   var before = e.hp
   sim.hurt(u, e, u.attack * float(spec.damage), p.kind != "slam", u.credit)
   drained += maxf(0.0, before - e.hp)
   if spec.has("status"): sim.status(e, str(spec.status), float(spec.seconds))
   if p.kind == "slam": sim.status(e, "stun", float(spec.stun))
   if p.kind == "special" and e.alive:
    match u.boss.key:
     "spore_queen": sim.poison(u, e, 4.0, u.attack * 0.10)
     "sun_pharaoh": sim.poison(u, e, 3.0, u.attack * 0.08, "burn")
     "leviathan": sim.relocate_hex(e, e.pos.lerp(u.pos, 0.35))
     "abyssal_keeper": sim.relocate_hex(e, e.pos.lerp(p.target, 0.55))
  if p.kind == "special" and u.alive:
   if u.boss.key == "bone_king": sim.heal(u, u, drained * 0.65, u.credit)
   if u.boss.key == "forge_tyrant":
    sim.zones.append({"source":u.uid, "pos":p.target, "radius":float(spec.radius), "damage":u.attack * 0.12, "remaining":4.0, "effect":"magma", "credit":u.credit})
    sim.emit({"type":"zone", "uid":u.uid, "pos":p.target, "radius":float(spec.radius), "duration":4.0, "effect":"magma", "credit":u.credit})
 u.credit = old_credit
