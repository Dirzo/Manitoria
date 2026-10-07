extends SceneTree
var checks=0
var failures=0
func check(ok: bool,msg: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(msg)
func _initialize() -> void:
 HeroData.load_data()
 var xp=0;var player_levels=[]
 for cup in range(1,6):
  var experience=xp;var level=1
  while experience>=HeroData.xp_needed(level):experience-=HeroData.xp_needed(level);level+=1
  player_levels.append(level)
  check(abs(TourBalance.level(cup,"Champion")-level)<=1,"Champion floors follow earned player XP, cup %d"%cup)
  xp+=4*roundi(80*WorldTour.PLAYER_XP)+TourBalance.TRAINING_XP
 check(player_levels==[1,6,8,11,13],"Four-bout wins plus camps reach the expected levels")
 var rare=0
 for i in range(100):
  if TourBalance.rarity(11,"Champion","tier-%d"%i)=="Rare":rare+=1
 check(rare>10 and rare<70,"Cup-three Rare upgrades are staggered, not team-wide")
 for cup in range(1,6):
  check(TourBalance.level(cup,"Keeper")<=TourBalance.level(cup,"Standard") and TourBalance.level(cup,"Standard")<=TourBalance.level(cup,"Champion"),"Ordered levels in cup %d"%cup)
  for difficulty in TourBalance.LEVELS:
   var current=TourBalance.level(cup,difficulty)
   if cup>1:
    check(current>TourBalance.level(cup-1,difficulty) and current-TourBalance.level(cup-1,difficulty)<=5,"Bounded level step: "+difficulty)
   check(TourBalance.quality(cup,3,difficulty)-TourBalance.quality(cup,0,difficulty)<.025,"Small within-cup quality rise")
 for sp in HeroData.species:
  for difficulty in TourBalance.LEVELS:
   var last_budget=0.0
   for stage in range(1,21):
    var hero=HeroData.make_hero(sp,"balance-"+sp,sp,1+stage/2);hero.learned={"0":1,"1":1}
    if hero.level>=8:hero.evolution=Evolutions.options(sp)[0]
    var gear=Forge.rival_loadout(hero,stage,difficulty)
    var ids=gear.values()
    check(ids.size()<=HeroData.item_slots(hero),"Legal slots: "+sp)
    var unique={};var wild=0
    for id in ids:
     check(Forge.valid(id),"Valid equipped item: "+str(id));unique[id]=true
     if Forge.ITEMS.get(id,{}).get("wild",false):wild+=1
    check(unique.size()==ids.size(),"No duplicate rival items: "+sp)
    check(wild<=1 and (stage>=15 or wild==0),"Wild effects limited and late: "+sp)
    var budget=TourBalance.gear_budget(stage,difficulty)
    check(budget>=last_budget and budget-last_budget<.17,"Continuous gear budget: "+difficulty);last_budget=budget
    if stage<15:
     var rec=Forge.recommended(sp,hero)
     for id in ids:
      if Forge.is_item(id):check(id in rec,"Finished gear fits current skills: "+sp)
 print("Tour balance: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
