class_name AbilityDemo
extends RefCounted
# Isolated, disposable combat state. Never references a campaign dictionary.
var sim: BattleSim
var caster: Dictionary
var target: Dictionary
var hero: Dictionary
var card: Dictionary
var effect=""
var elapsed=0.0
var cast_started=false
var shield_peak=0.0
var control_seen: Dictionary={}
var starting_health: Dictionary={}
var affected_ids: Dictionary={}

func setup(source: Dictionary,offer: Dictionary,layout: String="Clustered") -> void:
 hero=source.duplicate(true);card=offer.duplicate(true)
 HeroData.apply_choice(hero,card)
 # Gear procs would obscure which changes came from the previewed skill.
 hero.equipment={}
 sim=BattleSim.new();sim.rng.seed=9917
 caster=sim.add_unit(hero,0,Vector2(-1.4,0));caster.hp*=.45
 for i in range(3):
  var ally=HeroData.make_hero(["golem","unicorn","minotaur"][i],"ally%d"%i,"Ally %d"%(i+1),hero.level)
  var pos=Vector2(-3.4,-1.9+i*1.9) if layout!="Spread" else [Vector2(-3,0),Vector2(-7,-4),Vector2(-7,4)][i]
  var unit=sim.add_unit(ally,0,pos);unit.hp*=.28+.05*i
 var positions=[Vector2(.8,0),Vector2(1.3,-1.6),Vector2(1.3,1.6)]
 if layout=="Line":positions=[Vector2(.8,0),Vector2(2.8,0),Vector2(4.8,0)]
 elif layout=="Spread":positions=[Vector2(.8,0),Vector2(4.2,-3.6),Vector2(4.2,3.6)]
 for i in range(3):
  var enemy=HeroData.make_hero("golem","target%d"%i,"Enemy %d"%(i+1),hero.level)
  var unit=sim.add_unit(enemy,1,positions[i]);unit.hp*=.7 if i else .32
 target=sim.units[4]
 effect=HeroData.learned_ability(hero.sp,int(card.key)).effect if card.type=="ability" else HeroData.species[hero.sp].ab
 caster.tactics.area="immediate"
 for u in sim.units:starting_health[u.uid]=u.hp
 freeze_actions()

func freeze_actions() -> void:
 for u in sim.units:
  if u.summon:continue
  u.speed=0;u.velocity=Vector2.ZERO;u.attack_timer=1000;u.cd=1000
  for key in u.ability_cds:u.ability_cds[key]=1000

func advance(dt: float) -> void:
 if sim==null:return
 elapsed+=dt
 freeze_actions()
 if not cast_started and sim.time>=.65:
  if card.type=="ability":cast_started=sim.cast_learned(caster,target,HeroData.learned_ability(hero.sp,int(card.key)),int(hero.learned[card.key]))
  else:cast_started=sim.cast_signature(caster,target)
 sim.step(dt)
 for u in sim.units:
  shield_peak=maxf(shield_peak,u.shield)
  if u.damage_taken>0 or u.healing_received>0 or u.shield>0 or u.status.values().any(func(v):return v>0):affected_ids[u.uid]=true
  for status in u.status:
   if u.status[status]>0:control_seen[status]=true

func totals() -> Dictionary:
 var damage=0.0;var healing=0.0;var affected=0
 for u in sim.units:
  if u.team==1:damage+=u.damage_taken
  else:healing+=u.healing_received
  if u.damage_taken>0 or u.healing_received>0 or u.shield>0 or u.status.values().any(func(v):return v>0):affected+=1
 return {"damage":damage,"healing":healing,"shield":shield_peak,"affected":affected_ids.size()}
