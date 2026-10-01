class_name ItemEffects
extends RefCounted

static var catalog: Dictionary={}

static func definition(id: String) -> Dictionary:
 if Forge.valid(id): return Forge.info(id)
 if catalog.is_empty():
  for item in Campaign.EQUIPMENT:catalog[item.id]=item
 return catalog.get(id,{})

static func has(u: Dictionary, id: String) -> bool:
 return not u.summon and id in u.hero.get("equipment",{}).values()

static func ready(sim: BattleSim, u: Dictionary, id: String, cooldown: float) -> bool:
 if sim.time<float(u.items.get(id,-1.0)): return false
 u.items[id]=sim.time+cooldown
 return true

static func proc(sim: BattleSim, u: Dictionary, id: String, target: Dictionary) -> void:
 sim.track(u,"casts",1,"item:"+id)
 sim.emit({"type":"item_proc","uid":u.uid,"pos":u.pos,"target":target.pos,"credit":"item:"+id,"name":definition(id).name})

static func ward(sim: BattleSim, u: Dictionary, target: Dictionary, amount: float, id: String) -> void:
 var before=float(target.shield)
 sim.shield(target,amount)
 sim.track(u,"shielding",float(target.shield)-before,"item:"+id)
 proc(sim,u,id,target)

static func opening(sim: BattleSim, u: Dictionary) -> void:
 if u.items.get("opened",false): return
 u.items.opened=true
 if has(u,"barding"): ward(sim,u,u,u.max_hp*0.12,"barding")
 RoleItems.trigger(sim,u,"opening")

static func on_cast(sim: BattleSim, u: Dictionary) -> void:
 if str(u.credit).begins_with("ability:"):u.items.spell_primed_until=sim.time+5.0
 RoleItems.trigger(sim,u,"cast")
 if has(u,"totem"):
  var allies=sim.living(u.team,false).filter(func(a):return a.uid!=u.uid and a.pos.distance_to(u.pos)<=4.0)
  allies.sort_custom(func(a,b):return a.pos.distance_squared_to(u.pos)<b.pos.distance_squared_to(u.pos))
  if not allies.is_empty() and ready(sim,u,"totem",6.0): ward(sim,u,allies[0],u.max_hp*0.05,"totem")
 if has(u,"starheart") and str(u.credit).begins_with("ability:") and u.cd>0 and ready(sim,u,"starheart",4.0):
  sim.track(u,"cooldown_recovered",minf(u.cd,1.5),"item:starheart");u.cd=maxf(0,u.cd-1.5);proc(sim,u,"starheart",u)

static func on_heal(sim: BattleSim, u: Dictionary, target: Dictionary, actual: float, credit: String) -> void:
 if actual<=0 or u.team!=target.team or u.uid==target.uid or not u.alive or str(credit).begins_with("item:"): return
 RoleItems.trigger(sim,u,"heal",target,actual)
 if has(u,"tideheart") and ready(sim,u,"tideheart",2.0):
  ward(sim,u,target,minf(actual*0.25,target.max_hp*0.06),"tideheart")

static func on_hit(sim: BattleSim, u: Dictionary, target: Dictionary, actual: float, credit: String) -> void:
 if credit!="basic" or actual<=0: return
 RoleItems.trigger(sim,u,"basic",target,actual)
 if has(u,"emberfang") and target.hp>0:
  target.scorch_source=u.uid;sim.status(target,"scorch",3.0)
  if ready(sim,u,"emberfang",3.0): proc(sim,u,"emberfang",target)
 if target.hp>0 and u.hp>0 and has(u,"sunclaw") and target.hp/target.max_hp<0.35 and ready(sim,u,"sunclaw",2.0):
  proc(sim,u,"sunclaw",target);sim.hurt(u,target,u.attack*0.45,true,"item:sunclaw")
 if target.hp>0 and u.hp>0 and has(target,"thornmail") and ready(sim,target,"thornmail",2.0):
  proc(sim,target,"thornmail",u);sim.hurt(target,u,target.attack*0.30,true,"item:thornmail")

static func defend(sim: BattleSim, u: Dictionary) -> void:
 if u.hp<=0: return
 if has(u,"frostplate") and u.hp/u.max_hp<0.4 and ready(sim,u,"frostplate",10000.0):
  ward(sim,u,u,u.max_hp*0.12,"frostplate")
  for enemy in sim.near_foes(u,u.pos,3.0):sim.status(enemy,"slow",3.0)
 if has(u,"crownguard") and u.hp/u.max_hp<0.3 and ready(sim,u,"crownguard",10000.0):
  for key in ["stun","root","silence"]:u.status.erase(key)
  ward(sim,u,u,u.max_hp*0.22,"crownguard")
