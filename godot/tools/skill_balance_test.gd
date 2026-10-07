extends SceneTree
var failures=0
var checks=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(message)

func hit(sp: String,effect: String,equipment: Dictionary) -> float:
 var sim=BattleSim.new();sim.silent=true
 var hero=HeroData.make_hero(sp,"attacker","Attacker",5);hero.equipment=equipment
 var source=sim.add_unit(hero,0,Vector2.ZERO)
 var target=sim.add_unit(HeroData.make_hero("golem","target","Target",5),1,ArenaGrid.center(1,0))
 source.casting_resolution=true
 target.hp=target.max_hp*10.0;target.armor=0
 var before=target.hp
 var skill_key="test"
 for key in SkillScaling.audit_book.get(sp,{}):
  if key!="signature" and SkillScaling.audited(sp,key).effect==effect:skill_key=key;break
 sim.cast_learned(source,target,{"key":skill_key,"effect":effect,"name":"Test","range":30.0,"power":1.0},1)
 return before-target.hp

func _init() -> void:
 HeroData.load_data()
 var campaign=Campaign.new();campaign.new_run("Balance QA",98,8181)
 campaign.state.gold=10000
 check(campaign.recruit(campaign.state.market[0].id),"Founding recruitment succeeds")
 campaign.state.tour.cup_started=true
 var snapshot=campaign.state.duplicate(true)
 check(not campaign.recruit(campaign.state.market[0].id) and campaign.state==snapshot,"In-cup signing fails without mutating gold or roster")
 check(not campaign.sell(campaign.state.roster[0].id),"In-cup release is blocked")
 campaign.state.tour.intermission=true
 check(campaign.recruit(campaign.state.market[0].id),"Keeping team between cups permits recruitment")
 check(WorldTour.end_intermission(campaign) and not campaign.recruitment_open(),"Starting next cup closes recruitment")
 campaign.state.tour.erase("cup_started");campaign.state.tour.serial=2
 check(not campaign.recruitment_open(),"Existing in-cup saves also lock recruitment")
 var spell=hit("phoenix","fire",{})
 check(is_equal_approx(hit("phoenix","fire",{"0":"fang"}),spell),"Attack damage item does not amplify a pure spell")
 check(hit("phoenix","fire",{"0":"ember"})>spell,"Ability power item amplifies an actual spell cast")
 var strike=hit("manticore","execute",{})
 check(hit("manticore","execute",{"0":"fang"})>strike,"Attack damage item amplifies an AD champion skill")
 var quake=hit("golem","quake",{})
 check(hit("golem","quake",{"0":"plate"})>quake,"Armor item amplifies an actual defensive slam")
 var volley=hit("owlbear","whirl",{})
 check(hit("owlbear","whirl",{"0":"feather"})>volley,"Attack speed item amplifies a rapid strike")
 check(is_equal_approx(hit("phoenix","fire",{"0":"feather"}),spell),"Attack speed does not amplify ordinary spells")
 var grid_sim=BattleSim.new();grid_sim.silent=true
 var close=grid_sim.add_unit(HeroData.make_hero("golem","close","Close",5),0,Vector2.ZERO)
 var adjacent=grid_sim.add_unit(HeroData.make_hero("golem","adjacent","Adjacent",5),1,ArenaGrid.center(1,0))
 check(grid_sim.cast_learned(close,adjacent,{"key":"0","effect":"quake","name":"Quake","range":3.0,"power":1.0},1),"Short skills can cast onto an adjacent hex")
 check(grid_sim.near_foes(close,close.pos,2.5).has(adjacent),"One-hex area effects include adjacent cells")
 var clock=HeroData.make_hero("phoenix","clock","Clock",10)
 clock.equipment={"0":"crown","1":"hourglass","2":"crown","3":"hourglass","4":"crown"};clock.evolution="arcanist"
 check(HeroData.cooldown_factor(clock)>=0.60,"Cooldown stacking respects the 40% stat reduction cap")
 check(is_equal_approx(CombatPacing.sustain_factor(60.0),1.0) and CombatPacing.sustain_factor(110.0)<0.50 and is_equal_approx(CombatPacing.sustain_factor(150.0),0.05),"Overtime tapers sustain while preserving ordinary fights")
 var report=[]
 for sp in HeroData.species:
  var hero=HeroData.make_hero(sp,sp,sp,5);hero.learned={"0":1,"1":1}
  var recommendations=Forge.recommended(sp,hero)
  check(recommendations.size()==3 and recommendations[0]!=recommendations[1] and recommendations[1]!=recommendations[2] and recommendations[0]!=recommendations[2],"Three distinct suggested items for "+sp)
  check(recommendations.all(func(id):return Forge.ITEMS.has(id) and not Forge.ITEMS[id].get("wild",false)),"Reliable valid suggestions for "+sp)
  for i in range(12):
   var ability=HeroData.learned_ability(sp,i)
   var profile=SkillScaling.profile(sp,ability.effect)
   var sum=profile.get("ad",0.0)+profile.get("ap",0.0)+profile.get("armor",0.0)+profile.get("hp",0.0)
   check(is_equal_approx(sum,1.0) and ability.description.contains("Scaling:"),"Explicit scaling and readable description: "+ability.name)
  report.append({"champion":HeroData.species[sp].n,"signature":SkillScaling.description(sp,HeroData.species[sp].ab),"recommended":recommendations,"recommended_names":recommendations.map(func(id):return Forge.ITEMS[id].name)})
 var out=FileAccess.open("user://champion-builds.json",FileAccess.WRITE);out.store_string(JSON.stringify(report,"  "));out.close()
 print("Skill/item/recruitment: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
