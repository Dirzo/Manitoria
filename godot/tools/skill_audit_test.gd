extends SceneTree
var checks=0
var failures=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func _init() -> void:
 HeroData.load_data()
 var count=0
 for sp in HeroData.species:
  var signature=SkillScaling.audited(sp,"signature")
  check(signature.effect==HeroData.species[sp].ab,"Signature matches actual mechanic: "+sp)
  for i in range(16):
   var a=HeroData.learned_ability(sp,i)
   if a.is_empty():continue
   var entry=SkillScaling.audited(sp,str(i));count+=1
   check(not entry.is_empty(),"Every learned/ascended action audited: %s:%d"%[sp,i])
   var p=SkillScaling.profile(sp,a.effect,str(i))
   var sum=p.get("ad",0.0)+p.get("ap",0.0)+p.get("hp",0.0)+p.get("armor",0.0)
   check(is_equal_approx(sum,1.0),"Normalized channels: "+a.name)
   check(a.description.contains("Scaling:") and a.description.contains(a.name),"Truthful scaling tooltip: "+a.name)
   check(HeroData.EFFECTS.has(a.effect) and a.cooldown>0 and a.range>0,"Supported action: "+a.name)
   if sp=="arachne":check(p.get("ad",0.0)==0.0,"Arachne skill retains AP identity: "+a.name)
 check(count==441,"Full audit covers 384 discoveries and 57 ascended/granted actions")
 var sim=BattleSim.new();sim.silent=true
 var h=HeroData.make_hero("arachne","a","Arachne",5)
 var u=sim.add_unit(h,0,Vector2.ZERO)
 var target=sim.add_unit(HeroData.make_hero("golem","g","Golem",5),1,ArenaGrid.center(1,0))
 u.casting_resolution=true
 var a=HeroData.learned_ability("arachne",3)
 check(sim.cast_learned(u,target,a,1),"Spider Swarm summons instead of spirit bolts")
 check(sim.living(0).filter(func(v):return v.summon).size()==2,"Spider Swarm hatches two")
 check(sim.cast_signature(u,target),"Signature fills a partially occupied brood")
 check(sim.living(0).filter(func(v):return v.summon).size()==3 and not sim.cast_signature(u,target),"Signature obeys the shared three-pet limit")
 for pet in sim.living(0).filter(func(v):return v.summon):pet.alive=false
 check(sim.cast_learned(u,target,a,1),"Learned brood repopulates after pets die")
 check(sim.cast_learned(u,target,a,1),"Second brood fills final slot")
 check(sim.living(0).filter(func(v):return v.summon).size()==3 and not sim.cast_learned(u,target,a,1),"Shared summon cap prevents swarm flooding")
 var distant_sim=BattleSim.new();distant_sim.silent=true
 var backline=distant_sim.add_unit(h,0,Vector2.ZERO);backline.casting_resolution=true
 var distant=distant_sim.add_unit(HeroData.make_hero("golem","far","Far",5),1,ArenaGrid.center(4,0))
 check(distant_sim.cast_learned(backline,distant,a,1),"Backline summoner can hatch brood before enemies close")
 var fang=HeroData.learned_ability("arachne",5)
 var base=SkillScaling.power(u,fang.effect,fang.key)
 u.attack*=2
 check(is_equal_approx(base,SkillScaling.power(u,fang.effect,fang.key)),"Venomfang ignores attack damage gear")
 u.ability_power*=1.5
 check(SkillScaling.power(u,fang.effect,fang.key)>base,"Venomfang responds to AP")
 var bird=sim.add_unit(HeroData.make_hero("thunderbird","b","Bird",5),0,ArenaGrid.center(-1,0))
 var volley=HeroData.learned_ability("thunderbird",6)
 var lightning=HeroData.learned_ability("thunderbird",4)
 var v0=SkillScaling.power(bird,volley.effect,volley.key)
 var l0=SkillScaling.power(bird,lightning.effect,lightning.key)
 bird.interval*=0.75
 check(SkillScaling.power(bird,volley.effect,volley.key)>v0 and is_equal_approx(l0,SkillScaling.power(bird,lightning.effect,lightning.key)),"Thunderbird AS rewards volleys independently from lightning")
 check(not SkillScaling.magical("thunderbird",volley.effect,volley.key) and SkillScaling.magical("thunderbird",lightning.effect,lightning.key),"Physical feather volleys and magical lightning have distinct defenses")
 var atk=HeroData.make_hero("thunderbird","atk","Attack",5);atk.learned={"2":1,"6":1,"10":1}
 var ap=atk.duplicate(true);ap.learned={"0":1,"4":1,"11":1}
 check(SkillScaling.build_weights(atk)["as"]>SkillScaling.build_weights(ap)["as"] and SkillScaling.build_weights(atk).ap>SkillScaling.build_weights(atk).ad,"Thunderbird rapid kit values AS while retaining its AP path")
 for sp in HeroData.species:
  check(Evolutions.options(sp).size()==3,"Three valid evolution paths: "+sp)
 var matriarch=h.duplicate(true);matriarch.evolution="arachne:2"
 check(Evolutions.mod(matriarch,"potency")>1.0 and Evolutions.mod(matriarch,"haste")>1.0 and Evolutions.mod(matriarch,"hp")<1.0,"Venom Matriarch trades health for AP/on-hit tempo")
 check(SkillScaling.build_weights(matriarch)["as"]>SkillScaling.build_weights(h)["as"],"Item suggestions value tempo for AP on-hit evolutions")
 var poison_unit=sim.add_unit(matriarch,0,ArenaGrid.center(-2,0))
 target.hp=target.max_hp*100.0;target.armor=0.0;sim.rng.seed=42
 for i in range(30):sim.hurt(poison_unit,target,1.0,false,"basic")
 check(target.dots.any(func(dot):return dot.source==poison_unit.uid and is_equal_approx(dot.damage,poison_unit.ability_power*0.2)),"Evolution venom on-hit uses real AP damage")
 poison_unit.credit="ability:11";sim.poison(poison_unit,target,4.0,poison_unit.ability_power*0.4)
 poison_unit.credit="basic";sim.poison(poison_unit,target,4.0,poison_unit.ability_power*0.2)
 check(target.dots.any(func(dot):return dot.source==poison_unit.uid and is_equal_approx(dot.damage,poison_unit.ability_power*0.4) and dot.credit=="ability:11"),"Weak poison proc preserves the stronger spell and its damage credit")
 var dot_sim=BattleSim.new();dot_sim.silent=true;dot_sim.rng.seed=42
 var dot_source=dot_sim.add_unit(matriarch,0,Vector2.ZERO)
 var dot_target=dot_sim.add_unit(HeroData.make_hero("golem","dot","Dot",5),1,ArenaGrid.center(1,0))
 for unit in [dot_source,dot_target]:unit.cd=100.0;unit.attack_timer=100.0
 dot_source.credit="basic";dot_sim.poison(dot_source,dot_target,4.0,dot_source.ability_power*0.2)
 for frame in range(90):dot_sim.step(1.0/30.0)
 check(dot_target.dots.size()==1 and dot_target.dots[0].remaining<1.1 and dot_target.dots[0].credit=="on_hit","Damage-over-time cannot recursively trigger basic attack riders")
 var ward_hero=HeroData.make_hero("golem","ward","Ward",5);ward_hero.equipment={"0":"runeward"}
 var defended=sim.add_unit(ward_hero,1,ArenaGrid.center(2,0))
 check(Forge.damage_mod(sim,u,defended,100.0,false,"ability:5")==0.0,"Runeward blocks physical skill hits")
 check(Forge.damage_mod(sim,u,defended,100.0,false,"ability:5")>0.0,"Runeward cooldown prevents permanent blocking")
 print("Full skill audit: %d checks, %d failures; %d actions"%[checks,failures,count+32])
 quit(1 if failures else 0)

