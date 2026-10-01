class_name RoleItems
extends RefCounted

# Rules are evaluated only for equipped items. Proc credits never re-enter these hooks.
static func trigger(sim: BattleSim, u: Dictionary, event: String, other: Dictionary={}, amount: float=0.0) -> void:
 if u.summon or not u.alive or u.hp<=0: return
 for id in u.hero.get("equipment",{}).values():
  var item=ItemEffects.definition(id)
  if item.get("trigger","")!=event: continue
  var target=other
  if event=="cast":target=sim.find_unit(int(u.target))
  var allies=sim.living(u.team,false).filter(func(a):return a.uid!=u.uid and a.pos.distance_to(u.pos)<=5.0)
  allies.sort_custom(func(a,b):return a.hp/a.max_hp<b.hp/b.max_hp)
  var nearby=allies.filter(func(a):return a.pos.distance_to(u.pos)<=4.0)
  nearby.sort_custom(func(a,b):return a.pos.distance_squared_to(u.pos)<b.pos.distance_squared_to(u.pos))
  var condition=str(item.get("condition","always"))
  var ratio=float(u.hp)/u.max_hp
  match condition:
   "low30":
    if ratio>=0.30:continue
   "low35", "low35_ally":
    if ratio>=0.35:continue
   "low40":
    if ratio>=0.40:continue
   "burst":
    if amount<u.max_hp*.12:continue
   "outnumbered":
    if sim.near_foes(u,u.pos,3.0).size()<2:continue
   "snared":
    if not sim.active(u,"slow") and not sim.active(u,"root"):continue
   "third", "third_same":
    if target.is_empty():continue
    var counter=str(id)+"_count";var previous=str(id)+"_target"
    if condition=="third_same" and u.items.get(previous,-1)!=target.uid:u.items[counter]=0
    u.items[previous]=target.uid;u.items[counter]=int(u.items.get(counter,0))+1
    if int(u.items[counter])<3:continue
    u.items[counter]=0
   "spell_primed":
    if sim.time>float(u.items.get("spell_primed_until",-1)):continue
   "wounded_ally", "critical_ally":
    if allies.is_empty() or allies[0].hp>=allies[0].max_hp:continue
    if condition=="critical_ally" and allies[0].hp/allies[0].max_hp>=.5:continue
    target=allies[0]
   "near_ally":
    if nearby.is_empty():continue
    target=nearby[0]
  if condition=="low35_ally":
   if allies.is_empty() or allies[0].hp>=allies[0].max_hp:continue
   target=allies[0]
  if item.effect=="escort":
   if nearby.is_empty():continue
   target=nearby[0]
  if item.effect not in ["self_ward","self_heal","self_cleanse","escape"]:
   if target.is_empty() or not target.alive or target.hp<=0:continue
  if not target.is_empty():
   match condition:
    "close":
     if u.pos.distance_to(target.pos)>3.0:continue
    "within4":
     if u.pos.distance_to(target.pos)>4.0:continue
    "within5":
     if u.pos.distance_to(target.pos)>5.0:continue
    "distant":
     if u.pos.distance_to(target.pos)<=3.0:continue
    "long_range":
     if u.pos.distance_to(target.pos)<4.0:continue
    "ranged_target":
     if target.range<=2:continue
    "healthy_target":
     if target.hp/target.max_hp<=.75:continue
    "isolated":
     var friends=sim.living(target.team).filter(func(a):return a.uid!=target.uid and a.pos.distance_to(target.pos)<=3.0)
     if not friends.is_empty():continue
    "giant":
     if target.max_hp<u.max_hp*1.25:continue
    "controlled":
     if not sim.active(target,"root") and not sim.active(target,"stun") and not sim.active(target,"silence"):continue
    "cooling":
     if target.cd<=0:continue
    "secondary":
     var enemies=sim.foes(u).filter(func(e):return e.uid!=target.uid and e.pos.distance_to(target.pos)<=3.0)
     enemies.sort_custom(func(a,b):return a.pos.distance_squared_to(target.pos)<b.pos.distance_squared_to(target.pos))
     if enemies.is_empty():continue
     target=enemies[0]
    "echo_target":
     var echoes=sim.living(u.team,false).filter(func(a):return a.uid!=target.uid and a.uid!=u.uid and a.hp<a.max_hp and a.pos.distance_to(target.pos)<=3.0)
     echoes.sort_custom(func(a,b):return a.hp/a.max_hp<b.hp/b.max_hp)
     if echoes.is_empty():continue
     target=echoes[0]
  if item.effect=="self_cooldown" and u.cd<=0:continue
  if not ItemEffects.ready(sim,u,id,float(item.proc_cd)):continue
  if condition=="spell_primed":u.items.erase("spell_primed_until")
  apply(sim,u,target,item,amount,nearby)

static func apply(sim: BattleSim,u: Dictionary,target: Dictionary,item: Dictionary,amount: float,nearby: Array) -> void:
 var id=str(item.id);var value=float(item.value);var credit="item:"+id
 match item.effect:
  "self_ward", "escape":
   if item.effect=="escape":sim.status(u,"stealth",1.2)
   ItemEffects.ward(sim,u,u,u.max_hp*value,id);return
  "ally_ward":ItemEffects.ward(sim,u,target,u.max_hp*value,id);return
  "paired_ward":
   ItemEffects.ward(sim,u,u,u.max_hp*value,id)
   var before=float(target.shield);sim.shield(target,u.max_hp*value)
   sim.track(u,"shielding",float(target.shield)-before,credit);return
  "escort":
   var total=0.0
   for ally in nearby.slice(0,2):
    var before=float(ally.shield);sim.shield(ally,u.max_hp*value);total+=float(ally.shield)-before
   sim.track(u,"shielding",total,credit)
  "damage", "chain":sim.hurt(u,target,u.attack*value,true,credit)
  "giant_damage":sim.hurt(u,target,minf(target.max_hp*value,u.attack*.70),true,credit)
  "self_heal":sim.heal(u,u,u.max_hp*value,credit)
  "damage_heal":sim.heal(u,u,amount*value,credit)
  "ally_heal":sim.heal(u,target,u.max_hp*value,credit)
  "echo_heal":sim.heal(u,target,minf(amount*value,target.max_hp*.04),credit)
  "self_cleanse":
   u.status.erase("slow");u.status.erase("root")
  "ally_cleanse":
   for key in ["stun","root","silence"]:target.status.erase(key)
  "self_rally":sim.status(u,"rally",value)
  "ally_rally", "opening_rally":sim.status(target,"rally",value)
  "self_cooldown":
   sim.track(u,"cooldown_recovered",minf(value,u.cd),credit);u.cd=maxf(0,u.cd-value)
  "ally_cooldown":
   sim.track(u,"cooldown_recovered",minf(value,target.cd),credit);target.cd=maxf(0,target.cd-value)
  "root", "slow", "silence", "weaken":sim.status(target,item.effect,value)
 ItemEffects.proc(sim,u,id,target if not target.is_empty() else u)
