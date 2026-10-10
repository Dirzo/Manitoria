class_name BattleSim
extends RefCounted

signal action(event: Dictionary)
var units: Array = []
var projectiles: Array = []
var zones: Array = []
var time = 0.0
var finished = false
var winner = -1
var rng = RandomNumberGenerator.new()
var uid = 0
var shot_id = 0
var ticks = 0
var silent = false
var battle_seed = 0
var team_cast := [-10.0, -10.0]   # when each team's latest skill lands (CombatPacing.TEAM_SPACING)
## Run-wide modifiers per team (dungeon relics and run traits), applied once the fighters are placed.
var team_mods: Array = [[], []]
## The guild run's four-champion "elite squad" bonus; the dungeon sizes fights to the squad instead.
var elite_squads := true
const BOUNDS = ArenaGrid.BOUNDS
# Body radius per species (sim units), measured from each model's footprint.
const BODY = {"arachne":0.83,"basilisk":0.68,"cerberus":0.68,"chimera":0.68,"cyclops":0.68,"direwolf":0.68,"gargoyle":0.68,"golem":0.68,"griffin":0.68,"harpy":0.68,"hydra":0.68,"jackalope":0.68,"kirin":0.68,"kitsune":0.68,"manticore":0.68,"minotaur":0.68,"naga":0.68,"nekomata":0.68,"nemean":0.71,"owlbear":0.68,"pegasus":0.68,"phoenix":0.68,"salamander":0.69,"sphinx":0.68,"thunderbird":0.68,"treant":0.68,"troll":0.68,"unicorn":0.68,"wendigo":0.68,"wyvern":0.68,"yeti":0.68,"zaratan":0.68}

const FORMATION_COLUMNS = ArenaGrid.FORMATION_COLUMNS
const FORMATION_ROW_GAP = ArenaGrid.ROW_GAP

func setup(left: Array, right: Array, seed_value: int, rival_quality: float = 1.0) -> void:
 units.clear(); projectiles.clear(); zones.clear()
 shot_id = 0
 time = 0.0; finished = false; winner = -1; uid = 0; ticks = 0
 team_cast = [-10.0, -10.0]
 rng.seed = seed_value
 battle_seed = seed_value
 for team in range(2):
  var list = left if team == 0 else right
  var elite = elite_squads and list.size() == Campaign.MIN_SQUAD
  for i in range(list.size()):
   var hero = list[i]
   var slot = int(hero.get("slot", i))
   if slot < 0: slot = i
   var pos = ArenaGrid.formation_position(slot, team)
   var unit = add_unit(hero, team, pos, rival_quality if team else 1.0)
   if elite:
    unit.max_hp *= CombatPacing.ELITE_SQUAD.hp; unit.hp = unit.max_hp
    unit.attack *= CombatPacing.ELITE_SQUAD.attack; unit.attack_basic = unit.get("attack_basic", unit.attack) * CombatPacing.ELITE_SQUAD.attack
    unit.elite = true
    unit.skill_base *= 1.20;unit.ability_power *= 1.20
 for u in units:
  if not u.summon and not team_mods[u.team].is_empty(): Relics.apply(self, u, team_mods[u.team])

func add_unit(hero: Dictionary, team: int, pos: Vector2, quality: float = 1.0, owner: int = -1) -> Dictionary:
 hero=hero.duplicate(true)
 if owner<0 and HeroData.is_awakened(hero):hero.learned["12"]=1
 # A species evolution may bring its own ability (learned slot 13-15 inside the fight only).
 if owner<0 and Evolutions.grant_index(str(hero.get("evolution","")))>=0:hero.learned[str(Evolutions.grant_index(hero.evolution))]=1
 var s = HeroData.stats(hero, quality)
 var u = {"uid": uid, "hero": hero.duplicate(true), "team": team, "pos": pos, "heading": PI / 2 if team == 0 else -PI / 2, "hp": s.hp, "max_hp": s.hp, "attack": s.attack, "armor": s.armor, "speed": s.speed, "range": s.range, "interval": s.interval, "cd": rng.randf_range(1.3, 2.8), "attack_timer": rng.randf_range(0.0, 0.4), "windup": 0.0, "target": -1, "pending_target": -1, "status": {}, "shield": 0.0, "shield_time": 0.0, "cast_time": 0.0, "alive": true, "moving": false, "reborn": false, "summon": owner >= 0, "owner": owner, "ttl": 16.0, "damage": 0.0, "healing": 0.0, "blocked": 0.0, "kills": 0, "kill_chain": 0, "last_kill": -20.0, "ability_cds": {}, "radius": BODY.get(hero.sp, 0.72)}
 u.items = {}; u.tactics = BattleTactics.for_hero(hero)
 for key in ["ability_power","skill_base","base_hp","base_armor","base_interval"]:u[key]=s[key]
 if owner < 0 and float(Evolutions.perk(hero, "regen", 0.0)) > 0.0: u.evo_regen = float(Evolutions.perk(hero, "regen", 0.0))
 u.velocity = Vector2.ZERO
 u.start_pos = pos; u.area_wait = {}; u.recovery = 0.0; u.windup_total = 0.0
 u.dots = []; u.credit = "basic"; u.ability_stats = {}; u.timeline = {}; u.damage_taken = 0.0; u.healing_received = 0.0
 # Staggered openers per class (CombatPacing): front line first, flankers and artillery last.
 var opener = CombatPacing.opening(hero, rng)
 if owner < 0: u.cd = opener.signature
 for k in hero.learned: u.ability_cds[k] = opener.get(k, 6.0)
 if owner < 0:
  u.max_hp *= CombatPacing.HP_SCALE; u.hp = u.max_hp; u.attack_basic = u.attack * CombatPacing.BASIC_SCALE
 else:
  u.attack_basic = u.attack
 if owner < 0 and HeroData.species[hero.sp].role == "Artillery": u.attack_basic *= 1.30
 if owner >= 0:
  u.max_hp *= 0.21; u.hp = u.max_hp; u.attack *= 0.36; u.radius = 0.3
  u.range = 0.7; u.speed *= 1.2
 uid += 1
 units.append(u)
 Forge.setup_unit(self, u)
 if owner < 0 and hero.has("monster"): Bestiary.apply(self, u)
 u.attack_hexes = ArenaGrid.attack_hexes(u.range)
 relocate_hex(u, pos)
 u.start_pos = u.pos
 emit({"type": "spawn", "uid": u.uid, "pos": u.pos})
 return u

func emit(e: Dictionary) -> void:
 if e.has("uid"):
  var source = find_unit(int(e.get("source", e.uid)))
  if not source.is_empty():
   e.evolution = source.hero.get("evolution", "")
   e.species = source.hero.sp
   e.credit = e.get("credit", source.credit)
   e.rarity = RarityStyle.for_skill(source.hero,e.credit)
   e.rank = source.hero.signature_rank if e.credit=="signature" else int(source.hero.learned.get(e.credit.trim_prefix("ability:"),1))
   if e.credit.begins_with("ability:"):
    var skill = HeroData.learned_ability(source.hero.sp, int(e.credit.trim_prefix("ability:")))
    e.skill_name = skill.name
    if not e.has("effect"): e.effect = skill.effect
   elif e.credit == "signature":
    e.skill_name = HeroData.species[source.hero.sp].ability_name
    if not e.has("effect"): e.effect = HeroData.species[source.hero.sp].ab
 if not silent: action.emit(e)

func find_unit(id: int) -> Dictionary:
 for u in units:
  if u.uid == id: return u
 return {}

func occupied_cells(except_uid: int = -1) -> Dictionary:
 var occupied = {}
 for unit in units:
  if not unit.alive or unit.uid == except_uid or not unit.has("cell"): continue
  occupied[unit.cell] = true
  if unit.has("next_cell"): occupied[unit.next_cell] = true
 return occupied

func relocate_hex(unit: Dictionary, destination: Vector2) -> void:
 var blocked_cells = occupied_cells(unit.uid)
 var best = unit.get("cell",ArenaGrid.nearest(destination))
 var closest_distance = INF
 for cell in ArenaGrid.cells():
  if blocked_cells.has(cell): continue
  var d = ArenaGrid.point(cell).distance_squared_to(destination)
  if d < closest_distance: closest_distance = d; best = cell
 unit.cell = best; unit.pos = ArenaGrid.point(best)
 unit.erase("next_cell"); unit.velocity = Vector2.ZERO; unit.moving = false

func swap_hexes(a: Dictionary, b: Dictionary) -> void:
 var cell = a.cell; a.cell = b.cell; b.cell = cell
 for unit in [a,b]:
  unit.erase("next_cell"); unit.pos = ArenaGrid.point(unit.cell); unit.velocity = Vector2.ZERO; unit.moving = false

func in_attack_range(a: Dictionary, b: Dictionary) -> bool:
 return CombatRange.contains(a, b, a.attack_hexes)

func begin_hex_step(unit: Dictionary, target: Dictionary, lurking: bool=false, retreat: bool=false) -> void:
 var occupied = occupied_cells(unit.uid)
 var start: Vector2i = unit.cell
 var goal: Vector2i = target.cell
 if lurking:
  goal = ArenaGrid.nearest(Vector2(lerpf(unit.start_pos.x,0.0,0.5),signf(unit.start_pos.y)*6.6))
 elif unit.tactics.opening == "flank" and time < 4.0:
  goal = ArenaGrid.nearest(Vector2(target.pos.x,signf(unit.start_pos.y)*6.8))
 if retreat:
  var best = start; var best_distance = ArenaGrid.distance(start,target.cell)
  for cell in ArenaGrid.neighbors(start):
   if not occupied.has(cell) and ArenaGrid.distance(cell,target.cell)>best_distance:
    best=cell;best_distance=ArenaGrid.distance(cell,target.cell)
  if best!=start: unit.next_cell=best
  return
 # Breadth-first search finds the shortest open route to a firing hex.
 var frontier: Array[Vector2i] = [start]
 var previous = {start:start}
 var found = start
 var index = 0
 while index < frontier.size():
  var cell = frontier[index]; index += 1
  if cell!=start and (ArenaGrid.distance(cell,goal)<=unit.attack_hexes if goal==target.cell else cell==goal):
   found=cell;break
  for neighbor in ArenaGrid.neighbors(cell):
   if occupied.has(neighbor) or previous.has(neighbor): continue
   previous[neighbor]=cell;frontier.append(neighbor)
 if found==start:return
 while previous[found]!=start:found=previous[found]
 unit.next_cell=found

func advance_hex_step(unit: Dictionary, dt: float) -> void:
 var destination = ArenaGrid.point(unit.next_cell)
 var direction = destination-unit.pos
 var speed = unit.speed*(0.55 if active(unit,"slow") else 1.0)*(1.22 if active(unit,"rally") else 1.0)
 unit.velocity=direction.normalized()*speed
 unit.heading=atan2(direction.x,direction.y);unit.moving=true
 unit.pos=unit.pos.move_toward(destination,speed*dt)
 if unit.pos.is_equal_approx(destination):
  unit.cell=unit.next_cell;unit.erase("next_cell")
  unit.pos=destination;unit.velocity=Vector2.ZERO;unit.moving=false
  ItemFeedback.augment(self,unit,"move",unit)

func living(team: int, include_summons: bool = true) -> Array:
 return units.filter(func(u): return u.alive and u.team == team and (include_summons or not u.summon))

func foes(u: Dictionary) -> Array:
 var team = u.team if active(u, "confuse") else 1 - u.team
 return living(team).filter(func(e): return e.uid != u.uid and not active(e, "stealth"))

func active(u: Dictionary, key: String) -> bool:
 return u.status.get(key, 0.0) > 0

func closest(u: Dictionary) -> Dictionary:
 var all = foes(u)
 if all.is_empty(): return {}
 var taunter = find_unit(int(u.get("taunt_by", -1)))
 if active(u, "taunt") and not taunter.is_empty() and taunter.alive: return taunter
 var forced = Forge.forced_target(self, u, all)
 if not forced.is_empty(): return forced
 all.sort_custom(func(a, b): return u.pos.distance_squared_to(a.pos) < u.pos.distance_squared_to(b.pos))
 if u.summon:
  var prey = all.filter(func(e): return e.hp / e.max_hp < 0.4 and u.pos.distance_to(e.pos) < 5)
  if not prey.is_empty(): return prey[0]
 var previous = find_unit(u.target)
 if u.tactics.persistence == "committed" and not previous.is_empty() and previous in all and u.pos.distance_to(previous.pos) < 10.0:
  return previous
 all.sort_custom(func(a, b): return target_score(u, a) < target_score(u, b))
 return all[0]

func target_score(u: Dictionary, enemy: Dictionary) -> float:
 var distance = u.pos.distance_to(enemy.pos)
 var score = distance
 if distance > 10: return score + 20.0
 match u.tactics.target:
  "weakest": score += enemy.hp / enemy.max_hp * 6.0
  "backline": score -= 5.0 if enemy.range > 2 and not enemy.summon else 0.0
  "healers": score -= 6.0 if can_heal(enemy) else 0.0
  "threat": score -= minf(6.0, enemy.attack / enemy.interval / 18.0)
  "tanks": score -= 5.0 if HeroData.species[enemy.hero.sp].role in HeroData.FRONT else 0.0
 if u.tactics.posture == "guard":
  for ally in living(u.team, false):
   if ally.uid != u.uid and ally.range > 2 and ally.pos.distance_to(u.pos) < 7 and enemy.pos.distance_to(ally.pos) < 3.5:
    score -= 6.0; break
 if u.tactics.teamwork == "assist":
  for ally in living(u.team, false):
   if ally.uid != u.uid and ally.target == enemy.uid and ally.pos.distance_to(u.pos) < 7: score -= 1.8
 if u.tactics.teamwork == "independent" and u.tactics.target == "natural":
  # Independent fighters prefer an open engagement over piling onto one foe.
  for ally in living(u.team, false):
   if ally.uid != u.uid and ally.target == enemy.uid and ally.pos.distance_to(enemy.pos) < 4.0: score += 0.65
 if enemy.uid == u.target: score -= 1.2
 return score

func can_heal(u: Dictionary) -> bool:
 if HeroData.species[u.hero.sp].ab in ["rootbloom", "radiance"]: return true
 for key in u.hero.learned:
  if HeroData.learned_ability(u.hero.sp, int(key)).effect == "renew": return true
 return false

func wounded_allies(u: Dictionary) -> Array:
 var list = living(u.team)
 list.sort_custom(func(a, b): return healing_score(u, a) < healing_score(u, b))
 return list

func healing_score(u: Dictionary, ally: Dictionary) -> float:
 var ratio = ally.hp / ally.max_hp
 if ratio >= 0.86: return 10.0 + ratio
 if u.tactics.healing == "self" and ally.uid == u.uid: return ratio - 2.0
 if u.tactics.healing == "front" and HeroData.species[ally.hero.sp].role in HeroData.FRONT: return ratio - 1.0
 return ratio

func area_ready(u: Dictionary, effect: String, center: Vector2, radius: float) -> bool:
 if u.tactics.area != "cluster" or u.get("casting_resolution", false): return true
 if near_foes(u, center, radius).size() >= 2:
  u.area_wait.erase(effect); return true
 if not u.area_wait.has(effect): u.area_wait[effect] = time
 if time - u.area_wait[effect] >= 2.0:
  u.area_wait.erase(effect); return true
 return false

func near_foes(u: Dictionary, center: Vector2, radius: float) -> Array:
 var center_cell=ArenaGrid.nearest(center)
 var hex_radius=maxi(1,roundi(radius/ArenaGrid.ROW_GAP))
 return foes(u).filter(func(e): return ArenaGrid.distance(e.cell,center_cell)<=hex_radius)

## Crowd control credit: whoever acted last is credited with the control time they apply to foes.
var cc_source: Dictionary = {}
const CC_WEIGHT := {"stun": 1.0, "root": 1.0, "silence": 1.0, "fear": 1.0, "slow": 0.5, "chill": 0.5}

func status(u: Dictionary, key: String, seconds: float) -> void:
 if not u.alive: return
 var original_seconds=seconds
 seconds = Forge.status_mod(u, key, seconds)
 if seconds<original_seconds:
  ItemFeedback.augment(self,u,"resist",u)
  if key=="slow" and Forge.has(u,"pilgrim"):ItemFeedback.signal_effect(self,u,"pilgrim",u)
  if key in ["stun","root","silence"] and Forge.has(u,"stoneskin") and u.hp/u.max_hp>.5:ItemFeedback.signal_effect(self,u,"stoneskin",u)
 if seconds <= 0.0: return
 if ItemEffects.has(u,"windstep") and key in ["stun","root","slow"]:
  seconds*=0.7
  if seconds>0:ItemFeedback.signal_effect(self,u,"windstep",u)
 if CC_WEIGHT.has(key) and not cc_source.is_empty() and cc_source.team != u.team:
  cc_source.cc = cc_source.get("cc", 0.0) + seconds * CC_WEIGHT[key]
 u.status[key] = maxf(u.status.get(key, 0.0), seconds)
 if key == "stun" or (key == "silence" and u.has("pending_cast")):
  if u.windup > 0 or u.has("pending_cast"):
   emit({"type": "interrupt", "uid": u.uid, "pos": u.pos})
  if key == "stun": u.windup = 0.0; u.attack_timer = maxf(u.attack_timer, 0.25)
  u.erase("pending_cast"); u.cast_time = 0.0

func shield(u: Dictionary, value: float) -> void:
 var original_value=value
 value = Forge.shield_mod(u, value)
 if value>original_value:ItemFeedback.signal_effect(self,u,"worldtree",u)
 value *= CombatPacing.sustain_factor(time)
 u.shield = minf(u.max_hp * 0.55, u.shield + value)
 u.shield_time = 5.0

func heal(source: Dictionary, target: Dictionary, amount: float, credit: String = "") -> void:
 if not target.alive: return
 amount = Forge.heal_mod(target, amount, source)
 if HeroData.species.get(source.hero.sp,{}).get("role","")=="Support":
  var support_count=living(source.team,false).filter(func(u):return HeroData.species.get(u.hero.sp,{}).get("role","")=="Support").size()
  amount*=CombatPacing.support_heal_factor(support_count)
 amount *= CombatPacing.sustain_factor(time)
 if active(target,"scorch"):
  var owner_unit=find_unit(int(target.get("scorch_source",-1)))
  var healing_factor=.50 if not owner_unit.is_empty() and Forge.has(owner_unit,"grievous") else .65
  if not owner_unit.is_empty():track(owner_unit,"healing_denied",minf(amount,target.max_hp-target.hp)-minf(amount*healing_factor,target.max_hp-target.hp),"item:grievous" if healing_factor==.50 else "item:emberfang")
  amount*=healing_factor
 var actual = minf(amount, target.max_hp - target.hp)
 target.hp += actual; source.healing += actual; target.healing_received += actual
 if target.summon:
  var owner_unit = find_unit(target.owner)
  if not owner_unit.is_empty(): owner_unit.healing_received += actual
 track(source,"healing",actual,credit)
 track(source,"overheal",maxf(0,amount-actual),credit)
 if source.summon:
  var owner_unit = find_unit(source.owner)
  if not owner_unit.is_empty(): owner_unit.healing += actual
 if actual>0:
  ItemFeedback.credited(self,source,target,credit,actual)
  if Forge.has(source,"chalice"):ItemFeedback.signal_effect(self,source,"chalice",target,"proc",actual)
  if Forge.has(target,"worldtree"):ItemFeedback.signal_effect(self,target,"worldtree",target,"proc",actual)
 if actual > 0: emit({"type": "heal", "uid": target.uid, "source": source.uid, "amount": actual, "pos": target.pos, "credit": credit if not credit.is_empty() else source.credit})

 ItemEffects.on_heal(self,source,target,actual,credit)

var reflecting := false

func hurt(source: Dictionary, target: Dictionary, amount: float, magical: bool = true, credit: String = "") -> void:
 if not target.alive: return
 var hit_credit=credit if not credit.is_empty() else str(source.credit)
 if hit_credit=="signature":magical=SkillScaling.magical(source.hero.sp,HeroData.species[source.hero.sp].ab)
 elif hit_credit.begins_with("ability:"):
  var skill_key=hit_credit.trim_prefix("ability:")
  magical=SkillScaling.magical(source.hero.sp,HeroData.learned_ability(source.hero.sp,int(skill_key)).effect,skill_key)
 if magical and ItemEffects.has(target,"spellguard"):
  track(target,"mitigated",amount*.12,"item:spellguard");amount*=.88
 if hit_credit=="basic" and target.shield>0:RoleItems.trigger(self,source,"shield_hit",target)
 if hit_credit=="basic" and ItemEffects.has(target,"scale"):
  amount*=0.88
 if hit_credit=="basic" and ItemEffects.has(source,"claw") and target.shield>0:
  var broken=minf(target.shield,source.attack*0.35)
  target.shield-=broken;target.blocked+=broken;track(target,"blocked",broken,"incoming");track(source,"shield_break",broken,"item:claw");ItemEffects.proc(self,source,"claw",target)
 amount = Forge.damage_mod(self, source, target, amount, magical, hit_credit)
 if not source.summon and target.hp < target.max_hp * 0.35: amount *= 1.0 + float(Evolutions.perk(source.hero, "execute", 0.0))
 amount *= 1.22 if active(source, "rally") else 1.0
 amount *= 0.75 if active(source, "weaken") else 1.0
 amount *= 0.35 if active(target, "shell") else 1.0
 amount *= 0.84 if target.hero.sp == "nemean" else 1.0
 amount *= 1.0 - target.armor * (0.55 if magical else 1.0)
 var absorbed = minf(target.shield, amount)
 target.shield -= absorbed; target.blocked += absorbed; amount -= absorbed
 track(target,"blocked",absorbed,"incoming")
 if absorbed > 0: emit({"type":"blocked", "uid":target.uid, "source":source.uid, "pos":target.pos, "amount":absorbed, "credit":credit if not credit.is_empty() else source.credit})
 var actual = minf(target.hp, amount)
 target.hp = maxf(0, target.hp - amount); source.damage += actual
 target.damage_taken += actual; track(target,"taken",actual,"incoming")
 if target.summon:
  var owner_unit = find_unit(target.owner)
  if not owner_unit.is_empty(): owner_unit.damage_taken += actual; owner_unit.blocked += absorbed
 track(source,"damage",actual,credit)
 if source.summon:
  var owner_unit = find_unit(source.owner)
  if not owner_unit.is_empty(): owner_unit.damage += actual
 if active(source, "hunger"): heal(source, source, actual * 0.45,"signature")
 if not magical and not source.summon and source.hero.get("evolution", "") == "ravager": heal(source, source, actual * 0.12,"lifesteal")
 # Evolution perks: lifesteal on basics, on-hit riders, thorns.
 if not source.summon and hit_credit == "basic" and actual > 0:
  var ls = float(Evolutions.perk(source.hero, "lifesteal", 0.0))
  if ls > 0.0: heal(source, source, actual * ls, "lifesteal")
  var oh = Evolutions.perk(source.hero, "on_hit", [])
  if oh is Array and oh.size() == 2 and target.alive and rng.randf() < float(oh[1]):
   var rider_power=source.attack if SkillScaling.audited(source.hero.sp,"signature").get("build_path","ap")=="ad" else source.ability_power
   var previous_credit=source.credit;source.credit="evolution"
   apply_rider(source,target,str(oh[0]),rider_power)
   source.credit=previous_credit
 var th = float(Evolutions.perk(target.hero, "thorns", 0.0)) if not target.summon else 0.0
 if th > 0.0 and actual > 0 and source.alive and not reflecting and source.uid != target.uid:
  reflecting = true; hurt(target, source, actual * th, true, "thorns"); reflecting = false
 if actual > 0: emit({"type": "hit", "uid": target.uid, "source": source.uid, "amount": actual, "pos": target.pos, "credit": credit if not credit.is_empty() else source.credit})
 if actual>0:
  ItemFeedback.credited(self,source,target,hit_credit,actual)
  ItemFeedback.augment(self,target,"guard",target)
  if hit_credit=="basic":ItemFeedback.augment(self,source,"basic",target)
 ItemEffects.on_hit(self,source,target,actual,hit_credit)
 Forge.after_hit(self, source, target, actual, magical, hit_credit)
 if not target.alive: return
 ItemEffects.defend(self,target)
 if not hit_credit.begins_with("item:") and actual>0:
  RoleItems.trigger(self,target,"hurt",source,actual)
  if hit_credit=="basic":RoleItems.trigger(self,target,"hurt_basic",source,actual)
 if target.hp > 0: return
 if Forge.on_death(self, target): return
 if target.hero.sp == "phoenix" and not target.reborn and not target.summon:
  target.reborn = true; target.hp = target.max_hp * 0.35
  target.healing += target.hp; target.healing_received += target.hp
  track(target,"healing",target.hp,"rebirth"); track(target,"casts",1,"rebirth")
  target.status.clear(); target.dots.clear(); shield(target, target.max_hp * 0.15)
  emit({"type": "cast", "uid": target.uid, "effect": "rebirth", "name": "Ashen Rebirth", "pos": target.pos, "target": target.pos})
  return
 target.alive = false; target.moving = false; target.windup = 0.0
 emit({"type": "death", "uid": target.uid, "pos": target.pos})
 if not target.summon:
  var killer = find_unit(source.owner) if source.summon else source
  if killer.is_empty(): killer = source
  killer.kills += 1
  # A streak counts last hits by the same champion, each within 15 s of the previous one.
  killer.kill_chain = killer.kill_chain + 1 if time - killer.last_kill < 15.0 else 1
  killer.last_kill = time
  if killer.kill_chain >= 2: emit({"type": "multikill", "uid": killer.uid, "count": killer.kill_chain, "name": killer.hero.name, "team": killer.team})
  Forge.on_kill(self, killer, target)
  Forge.on_ally_death(self, target)

func attack(u: Dictionary, target: Dictionary) -> void:
 if not u.alive or not target.alive or not in_attack_range(u, target): return
 cc_source = u
 u.credit = "basic"; track(u,"casts",1)
 emit({"type": "release", "uid": u.uid, "pos": u.pos, "target": target.pos, "ranged": u.range > 2})
 var amount = u.get("attack_basic", u.attack)
 if u.range > 2:
  var duration = clampf(u.pos.distance_to(target.pos) / (8.0 if is_artillery(u) else 10.0), 0.28, 1.35)
  launch(u, target, amount, duration, false, HeroData.species[u.hero.sp].ab)
 else:
  hurt(u, target, amount, false)
  if u.summon and u.hero.sp == "arachne": status(target, "slow", 0.8)
  if u.hero.sp == "hydra" and not u.summon:
   for e in near_foes(u, target.pos, 1.5):
    if e.uid != target.uid: hurt(u, e, amount * 0.3, false)

func step(dt: float) -> void:
 if finished: return
 time += dt; ticks += 1
 for p in projectiles.duplicate():
  p.remaining -= dt
  if p.remaining <= 0:
   var source = find_unit(p.source); var target = find_unit(p.target)
   if not source.is_empty() and not target.is_empty():
    cc_source = source
    if p.get("area", false):
     for e in near_foes(source, target.pos, 2.4):
      hurt(source, e, p.amount,true,p.get("credit","basic")); status(e, "stun", 0.6)
     emit({"type": "impact", "pos": target.pos, "effect": p.effect, "credit": p.credit, "uid": source.uid, "heavy": p.get("heavy", false)})
    else:
     if target.alive:
      hurt(source, target, p.amount, p.magical,p.get("credit","basic"))
      emit({"type": "impact", "pos": target.pos, "effect": p.effect, "credit": p.credit, "uid": source.uid, "small": true, "heavy": p.get("heavy", false)})
   projectiles.erase(p)
 for zone in zones.duplicate():
  zone.remaining -= dt
  var source = find_unit(zone.source)
  if not source.is_empty():
   for e in near_foes(source, zone.pos, zone.radius):
    hurt(source, e, zone.damage * dt,true,zone.get("credit","signature"))
    if zone.effect == "magma": status(e, "slow", 0.3)
  if zone.remaining <= 0: zones.erase(zone)
 var order = units.duplicate()
 # Seeded initiative avoids a permanent left/right advantage at simultaneous contact.
 for i in range(order.size() - 1, 0, -1):
  var j = rng.randi_range(0, i)
  var swap = order[i]; order[i] = order[j]; order[j] = swap
 for u in order:
  if not u.alive: continue
  ItemEffects.opening(self,u)
  u.moving = false
  if u.windup > 0 or u.has("pending_cast") or u.recovery > 0 or active(u,"stun") or active(u,"root"): u.velocity = Vector2.ZERO
  for key in u.status: u.status[key] = maxf(0, u.status[key] - dt)
  u.shield_time -= dt
  if u.shield_time <= 0: u.shield = 0.0
  for dot in u.dots.duplicate():
   var source = find_unit(int(dot.source))
   var tick_time = minf(dt, dot.remaining)
   dot.remaining -= dt
   if not source.is_empty() and u.alive: hurt(source, u, dot.damage * tick_time,true,dot.get("credit","signature"))
   if dot.remaining <= 0: u.dots.erase(dot)
  if not u.alive: continue
  Forge.tick(self, u, dt)
  if u.summon:
   u.ttl -= dt
   if u.ttl <= 0:
    u.alive = false; emit({"type": "death", "uid": u.uid, "pos": u.pos}); continue
  if u.hero.sp == "troll": heal(u, u, u.max_hp * 0.007 * dt,"regeneration")
  if not u.summon and u.has("evo_regen"): heal(u, u, u.max_hp * u.evo_regen * dt, "regeneration")
  if not u.summon and u.has("run_regen"): heal(u, u, u.max_hp * u.run_regen * dt, "regeneration")
  if u.has("boss"): Bestiary.tick(self, u, dt)
  u.cd = maxf(0, u.cd - dt)
  u.cast_time = maxf(0, u.cast_time - dt)
  u.recovery = maxf(0, u.recovery - dt)
  u.attack_timer = maxf(0, u.attack_timer - dt * (1.22 if active(u, "rally") else 1.0))
  for key in u.ability_cds: u.ability_cds[key] = maxf(0, u.ability_cds[key] - dt)
  if u.has("boss_pending"): continue
  if active(u, "stun"):
   u.windup = 0.0; u.erase("pending_cast"); continue
  if u.has("next_cell"):
   if not active(u,"root"): advance_hex_step(u,dt)
   continue
  if u.has("pending_cast"):
   var pending = u.pending_cast
   if active(u, "silence"):
    u.erase("pending_cast"); continue
   var tracked = find_unit(pending.target)
   if not tracked.is_empty() and tracked.alive:
    var aim = tracked.pos - u.pos; u.heading = atan2(aim.x, aim.y)
   pending.delay -= dt
   if pending.delay <= 0:
    var victim = find_unit(pending.target)
    if victim.is_empty() or not victim.alive: victim = closest(u)
    u.casting_resolution = true
    if not victim.is_empty():
     if pending.kind == "signature": cast_signature(u, victim)
     else: cast_learned(u, victim, pending.ability, pending.rank)
    u.erase("casting_resolution"); u.erase("pending_cast"); u.cast_time = 0.22
    u.recovery = 0.22; u.recovery_clip = "cast"
   continue
  if u.windup > 0:
   u.windup -= dt
   if u.windup <= 0:
    var target = find_unit(u.pending_target)
    if not target.is_empty() and target.alive and in_attack_range(u, target): attack(u, target)
    u.attack_timer = u.interval
    u.recovery = 0.36 if is_artillery(u) else 0.22; u.recovery_clip = "attack"
   continue
  var lurking = u.tactics.opening == "lurk" and not u.get("dove", false) and not u.summon
  if lurking and lurk_trigger(u):
   # The dive: switch to the back line and open with the signature right away.
   u.dove = true; lurking = false
   u.tactics = u.tactics.duplicate(); u.tactics.target = "backline"; u.tactics.persistence = "committed"
   u.cd = minf(u.cd, 0.15); team_cast[u.team] = -10.0
  var target = closest(u)
  if target.is_empty(): continue
  u.target = target.uid
  var direction = target.pos - u.pos
  u.heading = atan2(direction.x, direction.y)
  if u.cast_time > 0 or u.recovery > 0: continue
  # Teams take turns: a fighter waits for its team's previous skill to start landing before
  # beginning its own, so skills arrive as a readable sequence instead of a pile-up.
  var lane_free = time >= team_cast[u.team] + CombatPacing.TEAM_SPACING * 0.35 or (can_heal(u) and wounded_allies(u)[0].hp / wounded_allies(u)[0].max_hp < 0.3)
  if not u.summon and not active(u, "silence") and lane_free and not lurking:
   var casted = false
   if u.tactics.abilities == "learned": casted = try_learned(u, target)
   if not casted and u.cd <= 0 and cast_signature(u, target):
    u.cd = CombatPacing.signature_cd(u.hero)
    u.cast_time = 0.6; casted = true
   if not casted and u.tactics.abilities != "learned": casted = try_learned(u, target)
   if casted: continue
  var engaged = in_attack_range(u, target)
  if engaged and u.attack_timer <= 0:
   u.velocity = Vector2.ZERO
   u.windup = 0.62 if is_artillery(u) else (0.32 if u.range < 2 else 0.44); u.windup_total = u.windup; u.pending_target = target.uid
   emit({"type": "attack", "uid": u.uid, "pos": u.pos, "target": target.pos, "duration": u.windup})
  elif not active(u, "root"):
   var hold = u.tactics.opening == "hold" and time < 3.0
   if not engaged and not hold: begin_hex_step(u, target, lurking)
   elif engaged and u.tactics.distance == "kite" and u.attack_hexes > 1 and ArenaGrid.distance(u.cell,target.cell) < u.attack_hexes - 1:
    begin_hex_step(u,target,false,true)
 var a = living(0, false); var b = living(1, false)
 if a.is_empty() or b.is_empty():
  finished = true; winner = 0 if b.is_empty() and not a.is_empty() else 1 if a.is_empty() and not b.is_empty() else -1
 elif time >= CombatPacing.TIME_LIMIT:
  var health = [0.0, 0.0]
  for u in units:
   if not u.summon: health[u.team] += u.hp / u.max_hp
  finished = true; winner = 0 if health[0] > health[1] + 0.01 else 1 if health[1] > health[0] + 0.01 else -1

# A lurker dives once the front lines are trading blows (after 4 s), when it is threatened, or after 8 s.
func lurk_trigger(u: Dictionary) -> bool:
 if time >= 8.0: return true
 for e in foes(u):
  if e.pos.distance_to(u.pos) < u.range + 1.2: return true
 if time < 4.0: return false
 for ally in living(u.team, false):
  if ally.uid == u.uid or HeroData.species[ally.hero.sp].role not in HeroData.FRONT: continue
  for e in foes(u):
   if e.pos.distance_to(ally.pos) < 2.8: return true
 return false

func try_learned(u: Dictionary, target: Dictionary) -> bool:
 for key in u.ability_cds:
  var ability = HeroData.learned_ability(u.hero.sp, int(key))
  if u.ability_cds[key] <= 0 and cast_learned(u, target, ability, int(u.hero.learned[key])):
   u.ability_cds[key] = CombatPacing.ability_cd(u.hero, key); u.cast_time = 0.65; return true
 return false

func is_artillery(u: Dictionary) -> bool:
 return not u.summon and HeroData.species[u.hero.sp].role == "Artillery"

func launch(u: Dictionary, target: Dictionary, amount: float, duration: float, magical: bool, effect: String, area: bool = false) -> void:
 shot_id += 1
 var heavy = is_artillery(u) or effect in ["meteor", "boulder"]
 projectiles.append({"id": shot_id, "source": u.uid, "target": target.uid, "amount": amount, "remaining": duration, "duration": duration, "credit":u.credit, "origin": u.pos, "last_pos": target.pos, "magical": magical, "effect": effect, "area": area, "heavy": heavy})
 emit({"type": "projectile", "uid": u.uid, "target_uid": target.uid, "pos": u.pos, "target": target.pos, "duration": duration, "effect": effect, "heavy": heavy})

func cast_visual(u: Dictionary, effect: String, label_text: String, target: Vector2) -> void:
 ItemFeedback.augment(self,u,"cast",u)
 ItemEffects.on_cast(self,u)
 Forge.on_cast(self, u, find_unit(int(u.target)))
 var ward_share = float(Evolutions.perk(u.hero, "ward", 0.0)) if not u.summon else 0.0
 if ward_share > 0.0:
  var mates = living(u.team, false).filter(func(v): return v.pos.distance_to(u.pos) <= 5.0)
  mates.sort_custom(func(a, b): return a.hp/a.max_hp < b.hp/b.max_hp)
  if not mates.is_empty(): shield(mates[0], u.max_hp * ward_share)
 if u.hero.get("evolution", "") == "guardian" and not u.summon:
  var allies = living(u.team, false).filter(func(v): return v.pos.distance_to(u.pos) <= 5.0)
  allies.sort_custom(func(a, b): return a.hp/a.max_hp < b.hp/b.max_hp)
  if not allies.is_empty(): shield(allies[0], u.max_hp * 0.03)
 if effect in ["quake", "whirl", "fear", "shriek", "triplebite", "bulwark", "prideroar", "shellup", "frostroar"]: target = u.pos
 emit({"type": "cast", "uid": u.uid, "effect": effect, "name": label_text, "pos": u.pos, "target": target})

func leap(u: Dictionary, target: Dictionary) -> void:
 relocate_hex(u, target.pos + (u.pos - target.pos).normalized() * ArenaGrid.ROW_GAP)

func poison(u: Dictionary, target: Dictionary, seconds: float, power: float, kind: String = "poison") -> void:
 var dot_credit="on_hit" if u.credit=="basic" else u.credit
 for dot in target.dots:
  if dot.source == u.uid and dot.kind == kind:
   # A weak on-hit rider must not erase a stronger spell or steal its damage credit.
   if power>=dot.damage:
    dot.remaining=seconds;dot.damage=power;dot.credit=dot_credit;status(target,kind,seconds)
   return
 status(target,kind,seconds)
 target.dots.append({"source": u.uid, "kind": kind, "credit":dot_credit, "remaining": seconds, "damage": power})

func cast_signature(u: Dictionary, target: Dictionary) -> bool:
 cc_source = u
 var key = HeroData.species[u.hero.sp].ab
 if key in ["howl","brood"] and living(u.team).filter(func(v):return v.summon and v.owner==u.uid).size()>=3:return false
 if not u.get("casting_resolution", false) and u.tactics.target == "natural":
  var candidates = foes(u).filter(func(e): return u.pos.distance_to(e.pos) <= 8.5)
  if key in ["venom", "vanish"]:
   candidates.sort_custom(func(a, b): return a.hp / a.max_hp < b.hp / b.max_hp)
   if not candidates.is_empty(): target = candidates[0]
  if key in ["skystrike", "stonedive", "foxfire"]:
   var backline = candidates.filter(func(e): return e.range > 2 and not e.summon)
   backline.sort_custom(func(a, b): return u.pos.distance_to(a.pos) < u.pos.distance_to(b.pos))
   if not backline.is_empty(): target = backline[0]
 var range_limit = CombatRange.signature_world(u)
 var friendly = key in ["rootbloom", "radiance", "tidal", "tailwind", "regrowth", "shellup", "bulwark", "hunger", "howl", "brood", "prideroar", "frostroar"]
 if not friendly and not CombatRange.contains(u, target, ArenaGrid.attack_hexes(range_limit)): return false
 var allies = wounded_allies(u)
 if key in ["rootbloom", "radiance"] and allies[0].hp / allies[0].max_hp > 0.86: return false
 if key == "regrowth" and u.hp / u.max_hp > 0.72: return false
 if key in ["shellup", "bulwark", "hunger", "prideroar", "frostroar"] and u.pos.distance_to(target.pos) > 4.5: return false
 if not u.get("casting_resolution", false):
  if key in ["smash", "acid", "flamewave", "magma", "boulder", "shriek", "triplebite"]:
   if not area_ready(u, key, u.pos if key in ["shriek", "triplebite"] else target.pos, 2.5): return false
  team_cast[u.team] = time + SkillCombat.windup(key)
  u.pending_cast = {"kind": "signature", "target": target.uid, "delay": SkillCombat.windup(key), "total": SkillCombat.windup(key), "effect": key, "name": HeroData.species[u.hero.sp].ability_name, "credit": "signature"}
  emit({"type": "telegraph", "credit": u.pending_cast.credit, "uid": u.uid, "pos": u.pos, "target": u.pos if friendly or key in ["shriek", "triplebite"] else target.pos, "effect": key, "name": HeroData.species[u.hero.sp].ability_name})
  return true
 u.credit = "signature"; track(u,"casts",1)
 var strength = (1.0 + (u.hero.signature_rank - 1) * 0.20)
 var power = SkillScaling.power(u,key) * strength * CombatPacing.power(u.hero, "signature")
 var utility=clampf(SkillScaling.power(u,key)/u.skill_base,0.65,1.60)
 cast_visual(u, key, HeroData.species[u.hero.sp].ability_name, target.pos)
 match key:
  "gore", "venom", "skystrike", "maul", "stonedive", "vanish", "antlerrush":
   var start = u.pos
   leap(u, target)
   hurt(u, target, power * (2.1 if key == "vanish" else 1.55 if key == "maul" else 1.7))
   if key in ["gore", "skystrike", "stonedive"]: status(target, "stun", 0.8)
   if key == "maul": status(target, "root", 1.5)
   if key == "venom": poison(u, target, 4, power * 0.3)
   if key == "stonedive":
    shield(u, u.max_hp * 0.18)
    for e in near_foes(u, target.pos, ArenaGrid.ROW_GAP * 1.05):
     if e.uid != target.uid: hurt(u, e, power * 0.55)
   if key == "vanish": status(u, "stealth", 0.9)
   if key == "antlerrush":
    for e in foes(u):
     if e.uid != target.uid and Geometry2D.get_closest_point_to_segment(e.pos, start, u.pos).distance_to(e.pos) < 1.7: hurt(u, e, power * 1.4)
  "bulwark", "prideroar", "shellup", "frostroar":
   shield(u, u.base_hp * CombatPacing.HP_SCALE * 0.24 * strength * utility)
   for e in near_foes(u, u.pos, 3.4):
    e.taunt_by = u.uid; status(e, "taunt", 2.5 * strength)
    if key == "frostroar": status(e, "slow", 3); hurt(u, e, power * 0.6)
   if key == "shellup": status(u, "shell", minf(4.5,3 * strength * utility))
   if key == "prideroar":
    for a in allies:
     if a.pos.distance_to(u.pos) < 5: status(a, "rally", minf(6.0,4 * strength * utility))
  "smash", "shriek", "triplebite":
   var victims = near_foes(u, target.pos if key == "smash" else u.pos, 3.0)
   if key == "triplebite": victims = victims.slice(0, 3)
   for e in victims:
    hurt(u, e, power * (1.55 if key == "smash" else 1.05))
    if key == "shriek": status(e, "silence", 2.5)
    elif key == "triplebite": poison(u, e, 3, power * 0.20, "bleed")
    else: status(e, "slow", 2.5)
  "hunger": status(u, "hunger", minf(7.0,5 * strength * utility)); status(u, "rally", minf(7.0,5 * strength * utility))
  "howl", "brood", "foxfire":
   var pets = living(u.team).filter(func(a): return a.summon and a.owner == u.uid)
   if pets.size() < 3:
    for i in range(mini(3 if key == "brood" else 2,3-pets.size())):
     var pet = HeroData.make_hero("arachne" if key == "brood" else "direwolf" if key == "howl" else "kitsune", "pet", "Broodling" if key == "brood" else "Spirit", int(u.hero.level))
     add_unit(pet, u.team, u.pos + Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)), strength * utility, u.uid)
   if key == "foxfire": leap(u, target); shield(u, u.max_hp * 0.12)
  "acid", "flamewave", "magma":
   zones.append({"source": u.uid, "pos": target.pos, "credit":u.credit, "radius": ArenaGrid.ROW_GAP, "damage": power * 0.43, "remaining": 4.0, "effect": key})
   for e in near_foes(u, target.pos, 2.5): hurt(u, e, power * 0.65)
  "chain":
   var struck = []; var current = target; var origin = u.pos
   for jump in range(4):
    hurt(u, current, power * 1.15 * pow(0.90, jump)); struck.append(current.uid)
    emit({"type": "bolt", "uid": u.uid, "pos": origin, "target": current.pos, "effect": key})
    origin = current.pos
    var options = foes(u).filter(func(e): return not struck.has(e.uid) and e.pos.distance_to(origin) < 4.8)
    options.sort_custom(func(a, b): return a.pos.distance_to(origin) < b.pos.distance_to(origin))
    if options.is_empty(): break
    current = options[0]
  "stormcall":
   var victims = foes(u)
   for i in range(mini(3, victims.size())):
    var index = rng.randi_range(0, victims.size() - 1); var e = victims[index]; victims.remove_at(index)
    hurt(u, e, power * 1.05)
    emit({"type": "bolt", "uid": u.uid, "pos": u.pos, "target": e.pos, "effect": key})
  "gaze": hurt(u, target, power * 1.3); status(target, "stun", 1.6)
  "rootbloom": heal(u, allies[0], power * 2.3); status(target, "root", 1.3)
  "tidal":
   for a in allies:
    if a.pos.distance_to(u.pos) < 6.0: shield(a, power * 2.0)
  "radiance":
   for a in allies:
    if a.pos.distance_to(u.pos) < 5.2:
     heal(u, a, power * 1.6)
     for k in ["stun", "root", "poison", "slow"]: a.status.erase(k)
     a.dots = a.dots.filter(func(dot): return dot.kind != "poison")
  "regrowth": heal(u, u, u.base_hp * CombatPacing.HP_SCALE * 0.23 * strength * utility); status(u, "rally", 4)
  "threefold":
   for i in range(3): hurt(u, target, power * 0.72)
   poison(u, target, 3, power * 0.22, "burn")
  "boulder": projectile_ability(u, target, power * 2.0)
  "riddle": hurt(u, target, power * 0.8); status(target, "confuse", 2.5)
  "tailwind":
   for a in allies:
    if a.pos.distance_to(u.pos) < 6: status(a, "rally", minf(7.0,5 * strength * utility))
 return true

func projectile_ability(u: Dictionary, target: Dictionary, power: float) -> void:
 launch(u, target, power, clampf(u.pos.distance_to(target.pos) / 8.0, 0.7, 1.5), true, "meteor", true)

func cast_learned(u: Dictionary, target: Dictionary, a: Dictionary, rank: int) -> bool:
 cc_source = u
 var effect = a.effect
 var support = effect in ["renew", "ward", "rally", "brood"]
 if effect=="brood" and living(u.team).filter(func(v):return v.summon and v.owner==u.uid).size()>=3:return false
 if not support and not CombatRange.contains(u, target, ArenaGrid.attack_hexes(a.range)): return false
 var allies = wounded_allies(u)
 if effect == "renew" and allies[0].hp / allies[0].max_hp > 0.82: return false
 if support and effect!="brood" and u.pos.distance_to(target.pos) > 8: return false
 if not u.get("casting_resolution", false):
  if effect in ["meteor", "quake", "whirl", "fear", "toxic", "fire", "gust", "silence", "frost", "roots", "magma"]:
   if not area_ready(u, effect, u.pos if effect in ["quake", "whirl", "fear"] else target.pos, 2.5): return false
  team_cast[u.team] = time + SkillCombat.windup(effect)
  u.pending_cast = {"kind": "learned", "target": target.uid, "delay": SkillCombat.windup(effect), "total": SkillCombat.windup(effect), "effect": effect, "name": a.name, "credit": "ability:" + a.key, "ability": a, "rank": rank}
  emit({"type": "telegraph", "credit": u.pending_cast.credit, "uid": u.uid, "pos": u.pos, "target": u.pos if support or effect in ["quake", "whirl", "fear"] else target.pos, "effect": effect, "name": a.name})
  return true
 u.credit = "ability:" + a.key; track(u,"casts",1)
 var strength = (1.0 + (rank - 1) * 0.2) * CombatPacing.power(u.hero, a.key)
 var power = SkillScaling.power(u,effect,str(a.key)) * strength * float(a.get("power", 1.0))
 var utility=clampf(SkillScaling.power(u,effect,str(a.key))/u.skill_base,0.65,1.60)
 cast_visual(u, effect, a.name, target.pos)
 apply_rider(u, target, str(a.get("rider", "none")), power)
 match effect:
  "magma":
   zones.append({"source":u.uid,"pos":target.pos,"credit":u.credit,"radius":ArenaGrid.ROW_GAP,"damage":power*0.35,"remaining":4.0,"effect":"magma"})
   for v in near_foes(u,target.pos,2.5):hurt(u,v,power*0.6)
  "brood":
   var count=living(u.team).filter(func(v):return v.summon and v.owner==u.uid).size()
   for i in range(mini(2,3-count)):
    var pet=HeroData.make_hero("arachne","pet","Spiderling",int(u.hero.level))
    add_unit(pet,u.team,u.pos+Vector2(rng.randf_range(-1,1),rng.randf_range(-1,1)),strength*utility,u.uid)
  "renew":
   for v in allies.slice(0, 3): heal(u, v, power * 1.3 + v.max_hp * 0.08)
  "ward", "rally":
   for v in allies:
    if v.pos.distance_to(u.pos) <= a.range:
     shield(v, u.base_hp * CombatPacing.HP_SCALE * (0.22 if effect == "ward" else 0.08) * strength * utility)
     if effect == "rally": status(v, "rally", minf(6.0,4 * strength * utility))
  "meteor": projectile_ability(u, target, power * 1.8)
  "storm", "wisps":
   for v in foes(u).slice(0, 3):
    if effect == "wisps": launch(u, v, power * 0.85, 0.55, true, effect)
    else:
     hurt(u, v, power * 1.1)
     emit({"type": "bolt", "uid": u.uid, "pos": u.pos, "target": v.pos, "effect": effect})
  "barrage":
   for i in range(5):
    launch(u, target, power * 0.45, 0.28 + i * 0.12, true, effect)
  "drain", "execute", "ambush":
   if effect == "ambush": leap(u, target); shield(u, u.max_hp * 0.12)
   var damage = power * (1.9 if effect == "ambush" else 1.7 if effect == "drain" else 2.8 if target.hp / target.max_hp < 0.35 else 1.4)
   var before = target.hp; hurt(u, target, damage)
   if effect == "drain": heal(u, u, before - target.hp)
  "beam", "fissure":
   var endpoint = u.pos + (target.pos - u.pos).normalized() * a.range
   for v in foes(u):
    if Geometry2D.get_closest_point_to_segment(v.pos, u.pos, endpoint).distance_to(v.pos) < 1.4:
     hurt(u, v, power * (1.8 if effect == "beam" else 1.5))
     if effect == "fissure": status(v, "root", 1)
   emit({"type": "bolt", "uid": u.uid, "pos": u.pos, "target": endpoint, "effect": effect})
  _:
   var center = u.pos if effect in ["quake", "whirl", "fear"] else target.pos
   for v in near_foes(u, center, 3.0 if effect in ["quake", "whirl", "fear"] else 2.5):
    match effect:
     "quake": hurt(u, v, power * 1.5); status(v, "stun", 0.8)
     "whirl": hurt(u, v, power * 2.0)
     "fear": status(v, "weaken", minf(6.0,4 * strength * utility))
     "toxic": poison(u, v, 4, power * 0.4)
     "fire": hurt(u, v, power * 1.2); poison(u, v, 3, power * 0.3, "burn")
     "gust": hurt(u, v, power * 1.3); relocate_hex(v, v.pos + (v.pos - u.pos).normalized() * ArenaGrid.ROW_GAP); status(v, "slow", 2)
     "silence": hurt(u, v, power * 0.9); status(v, "silence", 2.5)
     "frost": hurt(u, v, power * 1.1); status(v, "stun", 0.8)
     "roots": hurt(u, v, power); status(v, "root", 1.8)
   if effect == "whirl": shield(u, u.max_hp * 0.12)
 return true

## The twist that makes each learned skill unique.
func apply_rider(u: Dictionary, target: Dictionary, rider: String, power: float) -> void:
 cc_source = u
 if rider == "none" or rider == "": return
 var foe_ok = not target.is_empty() and target.get("alive", false) and target.team != u.team
 if rider in ["burn", "venom", "chill", "stun", "root", "weaken", "silence", "echo"] and not foe_ok: return
 match rider:
  "burn": poison(u, target, 3, power * 0.25, "burn")
  "venom": poison(u, target, 4, power * 0.2)
  "chill": status(target, "slow", 2)
  "stun": status(target, "stun", 0.5)
  "root": status(target, "root", 0.8)
  "weaken": status(target, "weaken", 3)
  "silence": status(target, "silence", 1.5)
  "echo": hurt(u, target, power * 0.4)
  "leech": heal(u, u, power * 0.35)
  "guard": shield(u, u.max_hp * 0.10)
  "haste": status(u, "rally", 3)
  "mend":
   var w = wounded_allies(u)
   if not w.is_empty(): heal(u, w[0], power * 0.6)

func run_to_end() -> int:
 silent = true
 while not finished: step(1.0 / 30.0)
 return winner

func track(unit: Dictionary, metric: String, amount: float, key: String = "") -> void:
 var recipient = unit
 if unit.summon:
  var owner_unit = find_unit(unit.owner)
  if not owner_unit.is_empty(): recipient = owner_unit; key = "incoming" if metric == "taken" else "summons"
 if key.is_empty(): key = unit.get("credit","basic")
 if not recipient.ability_stats.has(key): recipient.ability_stats[key] = {"damage":0.0,"healing":0.0,"overheal":0.0,"casts":0.0}
 recipient.ability_stats[key][metric] = recipient.ability_stats[key].get(metric,0.0)+amount
 if metric not in ["damage","healing","taken","blocked"]: return
 var second = str(int(time))
 if not recipient.timeline.has(second): recipient.timeline[second] = {"damage":0.0,"healing":0.0,"taken":0.0,"blocked":0.0}
 recipient.timeline[second][metric] += amount

func report_rows() -> Array:
 var rows = []
 for u in units:
  if u.summon: continue
  rows.append({"id":u.hero.id,"name":u.hero.name,"sp":u.hero.sp,"team":u.team,"damage":u.damage,"healing":u.healing,"taken":u.damage_taken,"healing_received":u.healing_received,"blocked":u.blocked,"kills":u.kills,"cc":u.get("cc",0.0),"alive":u.alive,"hp":u.hp,"max_hp":u.max_hp,"ability_stats":u.ability_stats.duplicate(true),"timeline":u.timeline.duplicate(true)})
 return rows
