extends SceneTree
var checks=0
var failures=0
class TestGame extends Node:
 var campaign: Campaign
 var phase="test"
 func render() -> void:pass
 func toast(message: String) -> void:push_error(message)
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func _initialize() -> void:call_deferred("run")
func draft(seed_value: int) -> Campaign:
 var c=Campaign.new();c.new_run("Speedrun QA",98,seed_value,"Standard");c.state.speedrun_lab=true;c.state.speedrun_memory=true
 c.choose_starter(League.tiers().Legendary[0])
 var epic=c.state.market.filter(func(h):return League.tier(h.sp)=="Epic")[0];c.recruit(epic.id)
 for i in range(3):c.recruit(c.state.market.filter(func(h):return League.tier(h.sp)=="Common")[0].id)
 return c
func snapshot(c: Campaign) -> String:
 var data=c.state.duplicate(true);data.erase("speedrun_plan")
 return JSON.stringify(data)
func run() -> void:
 var host=TestGame.new();root.add_child(host);host.campaign=draft(73001)
 var c=host.campaign;var h=c.lineup()[0];var legacy=h.duplicate(true);legacy.copies=6
 check(HeroData.stats(h)==HeroData.stats(legacy),"Legacy copies produce no combat bonus")
 check(HeroData.power(h)==HeroData.power(legacy),"Legacy copies produce no power bonus")
 var gold=int(c.state.gold);check(not c.buy_champion_copy(h.id) and int(c.state.gold)==gold,"Copy purchase disabled without charging gold")
 var lab=SpeedrunLab.new();lab.game=host;root.add_child(lab);lab.reset_plan()
 check(SpeedrunLab.validate(c,lab.plan).is_empty(),"Normal budget draft and standard formation accepted")
 lab.plan.items.resize(21);check(not SpeedrunLab.validate(c,lab.plan).is_empty(),"Twenty-item cap enforced");lab.plan.items=[]
 lab.plan.cups=7;check(not SpeedrunLab.validate(c,lab.plan).is_empty(),"Only five or ten cups accepted");lab.plan.cups=5
 lab.plan.items=[{"id":"invalid","target":""}];check(not SpeedrunLab.validate(c,lab.plan).is_empty(),"Invalid item rejected");lab.plan.items=[]
 var oldslot=c.lineup()[1].slot;c.lineup()[1].slot=h.slot;check(not SpeedrunLab.validate(c,lab.plan).is_empty(),"Overlapping hexes rejected");c.lineup()[1].slot=oldslot
 for champion in c.lineup():
  lab.plan.evolutions[champion.id]=Evolutions.options(champion.sp)[2];lab.plan.apex[champion.id]="apex_slot"
  for id in Forge.recommended(champion.sp,champion):lab.plan.items.append({"id":id,"target":champion.id})
 check(lab.plan.items.size()==15,"Three item priorities for each of five champions")
 var source=snapshot(c)
 await lab.start()
 var five=lab.result.duplicate(true)
 check(five.complete and five.cups.size()==5,"Five-cup run completes using real combat")
 check(snapshot(c)==source,"Original draft is untouched by simulation")
 check(five.matches.size()>=10 and five.matches.size()<=35,"Player played a full legal bracket in every cup")
 check(five.gold_left>=0,"Player wallet never goes negative")
 var total=0
 for buy in five.purchases:total+=int(buy.cost);check(buy.gold_left>=0 and buy.cost==RivalEconomy.item_cost(buy.item),"Real component cost charged for priority purchase")
 var earned=0
 for m in five.matches:earned+=int(m.gold)
 check(int(five.initial_gold)+earned-total==int(five.gold_left),"Exact gold conservation")
 for cup in five.cups:
  check(cup.bracket.finished and cup.bracket.champion>=0,"CPU and player double-elimination bracket finished")
  for champ in cup.roster:check(champ.get("equipment",{}).size()<=HeroData.item_slots(champ),"Legal item slot limit")
 for champ in five.final_roster:
  if int(champ.level)>=8:check(champ.evolution==lab.plan.evolutions[champ.id],"Preferred species evolution chosen when earned")
 for decision in five.decisions:check(decision.key in decision.offered,"Skill policy chooses actual offered rewards")
 if "--five-only" in OS.get_cmdline_user_args():
  if FileAccess.file_exists("user://speedrun_reference_5.json"):
   var reference=JSON.parse_string(FileAccess.get_file_as_string("user://speedrun_reference_5.json"))
   for key in ["matches","purchases","decisions","gold_left","final_roster"]:
    check(load("res://tools/speedrun_saved_test.gd").equivalent(five[key],reference[key]),"Optimized full-run equivalence: "+key)
  print("SPEEDRUN FIVE-CUP: %d checks; %d failures; %d matches %.2fs"%[checks,failures,five.matches.size(),five.elapsed_seconds])
  lab.queue_free();host.queue_free();await process_frame;quit(1 if failures else 0);return
 lab.plan.cups=10
 await lab.start()
 var ten=lab.result.duplicate(true)
 check(ten.complete and ten.cups.size()==10,"Ten-cup run completes using real combat")
 check(snapshot(c)==source,"Ten-cup benchmark cannot mutate the draft")
 check(ten.cpu_matches.size()>50,"Full CPU battle rows recorded separately")
 for cup in ten.cups:
  for cl in cup.cpu_economy:check(cl.gold>=0 and cl.spent>=0,"CPU spends only available gold")
 for cup in ten.cups:
  for champ in cup.roster:check(int(champ.level)<=20,"Level cap enforced")
  check(cup.bracket.finished,"Every extended CPU bracket resolves")
 for cl in c.state.clubs:check(not cl.has("development_spent") or int(cl.development_spent)>=0,"CPU budget is valid")
 check(FileAccess.file_exists(SpeedrunLab.RESULTS_PATH),"Results database written")
 check(not lab.export_result().is_empty(),"Detailed JSON export written")
 lab.plan.cups=5
 await lab.start()
 check(lab.result.matches==five.matches and lab.result.purchases==five.purchases and lab.result.decisions==five.decisions,"Repeat seed, draft and priorities reproduce combat and decisions")
 print("SPEEDRUN TEST: %d checks; %d failures; 5 cups %d matches %.2fs; 10 cups %d matches %.2fs"%[checks,failures,five.matches.size(),five.elapsed_seconds,ten.matches.size(),ten.elapsed_seconds])
 lab.queue_free();host.queue_free();await process_frame;quit(1 if failures else 0)
