class_name ItemFeedback
extends RefCounted
static var enabled=true
## Presentation-only hooks: never roll RNG, modify combat stats, or trigger another item.
const THEMES={
 "fang":["ed6b50","shard"],"hide":["ce955a","glow"],"plate":["d4b67c","shard"],
 "feather":["63d8ee","feather"],"ember":["9b79ff","star"],"moon":["79baff","star"],
 "seed":["8edd63","leaf"],"storm":["62bfff","spark"],"silk":["bd79ee","glow"],
 "venom":["a6dc41","droplet"],"relic":["ffe29b","star"],"coin":["ffc859","star"]}
const GROUPS={
 "lightning":["thundercleaver","stormmantle","lightningrod","galetalons","stormorb","overcharge","bottle","tempestcrown","galvanic","judgement"],
 "poison":["viperfang","acidshell","needles","plaguetome","hydravenom","grievous","witherbloom"],
 "heal":["bloodmaw","colossus","lifebloom","scepter","rainbringer","phantomcloak","wispshroud","leechhide","bloodfeast","worldtree","antidote","martyr","rosary","chalice","grail"],
 "guard":["tusk","bastion","mirror","spikes","runeward","stoneskin","ironbark","turtle","aegis","wardshroud","divine"],
 "shadow":["shadowblade","smokeplate","illusion","eclipse","doppel","nightshroud","assassinkit","flicker","swap","puppet"],
 "tempo":["frenzy","quicksilver","crown","hourglass","drum","bell","spiritbell","sugarrush","windwalker","pilgrim"],
 "fire":["phoenixember","emberfang"],"growth":["giant","thornlash","hunter"],
 "arcane":["archmage","spellblade","quiver","halo","chaos"]}
static func ids() -> Array:
 var out=Forge.COMPONENT_ORDER.duplicate();out.append_array(Forge.ITEMS.keys())
 for row in Campaign.EQUIPMENT:
  if row.id not in out:out.append(row.id)
 return out

static func profile(id: String) -> Dictionary:
 var item=ItemEffects.definition(id);var parts=item.get("recipe",[id])
 var base=str(parts[0]);var theme=THEMES.get(base,["c8adff","star"])
 var family="arcane"
 for group in GROUPS:
  if id in GROUPS[group]:family=group;break
 if Forge.is_component(id):
  family={"fang":"strike","hide":"guard","plate":"guard","feather":"tempo","ember":"arcane","moon":"tempo","seed":"heal","storm":"lightning","silk":"shadow","venom":"heal","relic":"guard","coin":"strike"}.get(id,"arcane")
 elif not Forge.is_item(id):
  var effect=str(item.get("effect",item.get("art","")))
  if "heal" in effect or "renew" in effect:family="heal"
  elif "ward" in effect or "guard" in effect or "shield" in effect:family="guard"
  elif "burn" in effect or id=="emberfang":family="fire"
  elif "poison" in effect:family="poison"
  elif "escape" in effect or "blink" in effect:family="shadow"
  elif float(item.get("armor",0))>0:family="guard"
  elif float(item.get("attack",0))>0:family="strike"
 var color=Color(theme[0]);var motif=str(theme[1])
 match family:
  "lightning":color=Color("6dbfff");motif="spark"
  "poison":color=Color("98d945");motif="droplet"
  "heal","growth":color=Color("97db6b");motif="leaf"
  "shadow":color=Color("b881f2");motif="glow"
  "fire":color=Color("ff9a3f");motif="ember"
 if base=="relic" or id in ["judgement","halo","divine","rosary","grail","chalice","aegis"]:color=Color("ffe4a4");motif="star"
 return {"id":id,"name":item.get("name",id),"family":family,"color":color,"motif":motif,"variant":abs(hash(id))%6}

static func signal_effect(sim: BattleSim,u: Dictionary,id: String,target: Dictionary,stage: String="proc",amount: float=0) -> void:
 if sim.silent or not enabled or u.summon or ItemEffects.definition(id).is_empty():return
 if not u.has("item_feedback"):u.item_feedback={}
 var key=id+":"+stage
 if sim.time<float(u.item_feedback.get(key,-1)):return
 u.item_feedback[key]=sim.time+(1.8 if stage=="augment" else 1.0)
 sim.emit({"type":"item_feedback","uid":u.uid,"pos":u.pos,"target":target.get("pos",u.pos),"target_uid":target.get("uid",u.uid),"credit":"item:"+id,"item_id":id,"stage":stage,"amount":amount,"name":ItemEffects.definition(id).name})

static func opening(sim: BattleSim,u: Dictionary) -> void:
 if u.summon:return
 for id in u.hero.get("equipment",{}).values():signal_effect(sim,u,id,u,"equip")

static func stats(id: String) -> Dictionary:
 return Forge.stats_of(id) if Forge.valid(id) else ItemEffects.definition(id)

static func augment(sim: BattleSim,u: Dictionary,event: String,target: Dictionary={}) -> void:
 if sim.silent or not enabled or u.summon:return
 for id in u.hero.get("equipment",{}).values():
  var s=stats(id);var applies=false
  match event:
   "basic":applies=float(s.get("attack",0))>0 or float(s.get("haste",0))>0
   "cast":applies=float(s.get("potency",0))>0 or float(s.get("cd",1))<1
   "guard":applies=float(s.get("armor",0))>0 or float(s.get("hp",0))>0
   "move":applies=float(s.get("speed",0))>0
   "dodge":applies=float(s.get("dodge",0))>0
   "crit":applies=float(s.get("crit",0))>0
   "resist":applies=float(s.get("tenacity",0))>0
  if applies:signal_effect(sim,u,id,target,"augment")

static func credited(sim: BattleSim,u: Dictionary,target: Dictionary,credit: String,amount: float) -> void:
 if sim.silent or not enabled:return
 if amount<=0 or not credit.begins_with("item:"):return
 var id=credit.trim_prefix("item:")
 if id=="lifesteal":
  for equipped in u.hero.get("equipment",{}).values():
   if float(stats(equipped).get("lifesteal",0))>0:signal_effect(sim,u,equipped,target,"proc",amount)
 else:signal_effect(sim,u,id,target,"proc",amount)

static func play(vfx: VFX,e: Dictionary,from: Vector3,to: Vector3) -> void:
 var p=profile(e.item_id);var color: Color=p.color;var strong=e.stage=="proc"
 var life=.8 if strong else .45
 if strong:
  var badge=Sprite3D.new();badge.texture=AbilityArt.texture(ItemEffects.definition(e.item_id).get("art","ward"))
  badge.billboard=BaseMaterial3D.BILLBOARD_ENABLED;badge.no_depth_test=false
  badge.pixel_size=.65/maxf(1,badge.texture.get_width());badge.position=to+Vector3.UP*2.8
  vfx._track(badge,life,[],func(node,age):
   node.position.y=to.y+2.8+age*.45;node.modulate.a=1.0-clampf(age/life,0,1))
 if e.stage=="equip":
  vfx.rune(from,.65+float(p.variant)*.055,color,int(p.variant)%4,.9,0,1.1)
  vfx.spray(from+Vector3.UP*.7,5,p.motif,color,Vector2(.5,1.2),Vector2(.4,.8),.06,Vector3.UP,1,0,1)
  return
 var at=to+Vector3.UP
 match p.family:
  "lightning":vfx.bolt(from+Vector3.UP,at,color,.10 if strong else .045,life,2 if strong else 0)
  "heal":
   if from.distance_to(to)>.2:vfx.bolt(from+Vector3.UP*.8,at,color,.055,life,0,0,0)
   vfx.rune(to,.8,color,2,life);vfx.spray(at,9 if strong else 4,p.motif,color,Vector2(.5,1.4),Vector2(.3,.7),.075,Vector3.UP,1,0,1)
  "guard":
   vfx.shield(at,1.05 if strong else .8,color,life,.12)
   if strong:vfx.spray(at,8,"shard",color,Vector2(1,2),Vector2(.2,.5),.08,Vector3.UP,1,2,1)
  "poison":
   vfx.bolt(from+Vector3.UP,at,color,.08,life,0,0,.1)
   vfx.rune(to,.65,color,3,life);vfx.spray(at,8,p.motif,color,Vector2(.6,1.5),Vector2(.3,.6),.09,Vector3.UP,1,2,1)
  "shadow":
   vfx.rune(from,.85,color,1,life);vfx.rune(to,.85,color,1,life)
   vfx.spray(at,7,"glow",color,Vector2(.5,1.8),Vector2(.3,.6),.10,Vector3.UP,1,0,1)
  "tempo":
   vfx.rune(from,.9,color,1,life)
   for i in range(3):
    var a=i*TAU/3+float(p.variant)*.3
    vfx.glow(from+Vector3(cos(a)*.7,.6,sin(a)*.7),.22,color,life)
  "growth":
   var points=PackedVector3Array()
   for i in range(18):
    var t=i/17.0;points.append(to+Vector3(cos(t*TAU*1.5)*.7,t*1.5,sin(t*TAU*1.5)*.7))
   vfx.vine(points,.04,color.darkened(.4),color,life,0,true)
  "fire":
   vfx.glow(at,1.3 if strong else .5,color,life)
   vfx.spray(at,12 if strong else 5,"ember",color,Vector2(1,2.5),Vector2(.2,.6),.09,Vector3.UP,1,0,1)
  _:
   if from.distance_to(to)>.2:vfx.bolt(from+Vector3.UP,at,color,.075,life,0,0,0)
   vfx.glow(at,.7 if strong else .3,color,life)
   vfx.spray(at,8 if strong else 4,p.motif,color,Vector2(.7,2),Vector2(.2,.55),.085,Vector3.UP,1,1,1)
