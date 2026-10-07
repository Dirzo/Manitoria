extends SceneTree
func _init() -> void:
 HeroData.load_data()
 var rows=[]
 for sp in ["golem","minotaur","harpy","phoenix","cyclops","unicorn"]:
  var record={"champion":sp,"suggested_wins":0,"opposite_wins":0,"draws":0,"timeouts":0,"bouts":2}
  for side in range(2):
   var teams=[[],[]]
   for team in range(2):
    for i in range(5):
     var hero_sp=sp if i==2 else ["golem","minotaur",sp,"kirin","unicorn"][i]
     var hero=HeroData.make_hero(hero_sp,"probe-%d"%i,hero_sp,8)
     hero.slot=Campaign.FORMATION[i];hero.learned={"0":1,"1":1};hero.equipment={}
     if i==2:
      var correct=Forge.recommended(sp,hero)
      var weights=SkillScaling.build_weights(hero)
      var opposite=["bloodmaw","frenzy","executioner"] if weights.ap>weights.ad else ["archmage","crown","stormorb"]
      for slot in range(3):hero.equipment[str(slot)]=(correct if team==side else opposite)[slot]
     teams[team].append(hero)
   var sim=BattleSim.new();sim.silent=true;sim.setup(teams[0],teams[1],911)
   while not sim.finished:sim.step(1.0/30.0)
   if sim.winner==side:record.suggested_wins+=1
   elif sim.winner==-1:record.draws+=1
   else:record.opposite_wins+=1
   if sim.time>=CombatPacing.TIME_LIMIT:record.timeouts+=1
  rows.append(record)
 var out=FileAccess.open("res://../../build-balance-probe.json",FileAccess.WRITE);out.store_string(JSON.stringify(rows,"  "));out.close()
 print("Build comparison: 12 mirrored full-team fights completed")
 quit()
