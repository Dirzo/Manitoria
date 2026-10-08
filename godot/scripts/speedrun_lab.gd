class_name SpeedrunLab
extends Node
## A repeatable benchmark on a cloned normal draft, never a progression shortcut.
const RESULTS_PATH="user://speedrun_results.json"
var game: Node
var plan: Dictionary={}
var result: Dictionary={}
var running=false
var cancelled=false
var status="Draft your squad, then choose your priorities."
var item_filter=""
var selected_item=""
var selected_target=""

func reset_plan() -> void:
 plan={"cups":5,"difficulty":"Standard","items":[],"evolutions":{},"apex":{},"goals":{}}
 result={};status="Your normal draft is the starting point for every simulation."

static func validate(c: Campaign,p: Dictionary) -> String:
 if not c.lineup_ready():return "Field four or five champions."
 if int(p.get("cups",0)) not in [5,10]:return "Choose five or ten cups."
 if p.get("difficulty","") not in ["Keeper","Standard","Champion"]:return "Choose a difficulty."
 if not p.get("items") is Array or p.items.size()>20:return "Choose at most twenty item priorities."
 var taken=[]
 for h in c.lineup():
  if int(h.slot)<0 or int(h.slot)>14 or int(h.slot) in taken:return "Each champion needs its own deployment hex."
  taken.append(int(h.slot))
 for item in p.items:
  if not item is Dictionary or not Forge.is_item(str(item.get("id",""))):return "Choose a finished Forge item."
  var target=str(item.get("target",""))
  if not target.is_empty() and not c.lineup().any(func(h):return h.id==target):return "An item target is outside your formation."
 for h in c.lineup():
  var ev=str(p.get("evolutions",{}).get(h.id,""))
  if not ev.is_empty() and ev not in Evolutions.options(h.sp):return "Choose a valid species evolution."
  var apex=str(p.get("apex",{}).get(h.id,"apex_skill"))
  if apex not in HeroData.APEX:return "Choose a valid Apex evolution."
  if str(p.get("goals",{}).get(h.id,"Adaptive")) not in DecisionMatrix.GOALS:return "Choose a valid build path."
 return ""

static func item_score(h: Dictionary,id: String) -> float:
 var w=SkillScaling.build_weights(h);var s=Forge.stats_of(id)
 var score=s.attack/.12*w.ad+s.potency/.12*w.ap+s.haste/.09*w["as"]+s.armor/.05*w.armor+s.hp/.10*w.hp+(1.0-s.cd)/.08*w.cd
 if id in Forge.recommended(h.sp,h):score+=2.0
 return score

static func buy_priorities(c: Campaign,p: Dictionary,purchases: Array,done: Dictionary) -> void:
 # Each row is one purchase, in order. Full/duplicate recipients are skipped until
 # evolution opens a slot. An affordable valid row never jumps an unaffordable row.
 for index in range(p.items.size()):
  if done.has(str(index)):continue
  var choice=p.items[index];var id=str(choice.id);var target=str(choice.get("target",""))
  var candidates=c.lineup().filter(func(h):return (target.is_empty() or h.id==target) and id not in h.get("equipment",{}).values() and h.get("equipment",{}).size()<HeroData.item_slots(h))
  if candidates.is_empty():continue
  var cost=RivalEconomy.item_cost(id)
  if int(c.state.gold)<cost:break
  candidates.sort_custom(func(a,b):return item_score(a,id)>item_score(b,id) if not is_equal_approx(item_score(a,id),item_score(b,id)) else str(a.id)<str(b.id))
  var h=candidates[0];h.equipment=h.get("equipment",{})
  for slot in GearUI.slot_keys(h):
   if not h.equipment.has(slot):h.equipment[slot]=id;break
  c.state.gold-=cost;done[str(index)]=true
  purchases.append({"priority":index+1,"cup":int(c.state.tour.level),"match":int(c.state.tour.serial),"hero":h.name,"hero_id":h.id,"item":id,"cost":cost,"gold_left":int(c.state.gold)})

static func skill_score(h: Dictionary,card: Dictionary,p: Dictionary) -> float:
 if card.type=="evolution":return 10000.0 if card.key==p.get("evolutions",{}).get(h.id,"") else 100.0
 if card.type=="apex":return 10000.0 if card.key==p.get("apex",{}).get(h.id,"apex_skill") else 100.0
 if card.type in ["ability","signature"]:
  var key="signature" if card.type=="signature" else str(card.key)
  var a=HeroData.species[h.sp] if card.type=="signature" else HeroData.learned_ability(h.sp,int(card.key))
  var effect=str(a.ab) if card.type=="signature" else str(a.effect)
  var scaling=SkillScaling.profile(h.sp,effect,key);var weights=SkillScaling.build_weights(h);var score=1.0
  for stat in ["ad","ap","as","armor","hp"]:score+=float(scaling.get(stat,0.0))*float(weights.get(stat,0.0))*3.0
  if card.type=="signature" or h.learned.has(card.key):score+=.5
  return score+{"Common":0.0,"Uncommon":.1,"Rare":.6,"Legendary":1.5}.get(str(card.rarity),0.0)
 return {"vigor":1.0,"force":SkillScaling.build_weights(h).ad,"focus":SkillScaling.build_weights(h).ap,"agility":SkillScaling.build_weights(h)["as"]}.get(str(card.type),0.0)

static func choose_rewards(c: Campaign,p: Dictionary,decisions: Array) -> void:
 for h in c.state.roster:
  h.build_goal=str(p.get("goals",{}).get(h.id,"Adaptive"))
  while not h.pending.is_empty():
   HeroData.materialize_reward(h)
   var cards=h.pending[0];var best=0
   for i in range(1,cards.size()):
    if skill_score(h,cards[i],p)>skill_score(h,cards[best],p):best=i
   decisions.append({"cup":int(c.state.tour.level),"hero":h.name,"type":cards[best].type,"key":cards[best].key,"name":cards[best].name,"offered":cards.map(func(card):return card.key)})
   c.choose(h.id,best)

func start() -> void:
 if running:return
 var error=validate(game.campaign,plan)
 if not error.is_empty():game.toast(error);return
 game.campaign.state.speedrun_plan=plan.duplicate(true);game.campaign.save()
 running=true;cancelled=false;result={};status="Preparing the opening bracket…";game.render()
 var c=Campaign.new();c.state=game.campaign.state.duplicate(true)
 c.state.speedrun_memory=true;c.state.speedrun_lab=true;c.state.speedrun_cups=int(plan.cups);c.state.difficulty=plan.difficulty
 c.state.run_id="speedrun_"+str(c.state.seed);c.state.challenge_rank=0;c.state.speedrun_cpu=[]
 var frozen_plan=plan.duplicate(true);var started=Time.get_ticks_msec();var purchases=[];var decisions=[];var done={};var matches=[];var cups=[];var first_failure=0
 var initial=c.state.duplicate(true)
 while not c.state.tour.complete and not cancelled:
  var cup=int(c.state.tour.level)
  choose_rewards(c,frozen_plan,decisions);buy_priorities(c,frozen_plan,purchases,done)
  if c.state.tour.get("intermission",false):WorldTour.end_intermission(c)
  if c.state.tour.shop:WorldTour.leave_shop(c)
  var rival=c.opponent()
  status="Cup %d / %d · Match %d · %s · %d gold"%[cup,int(frozen_plan.cups),int(c.state.tour.serial)+1,rival.name,int(c.state.gold)]
  if game.phase=="speedrun":game.render()
  await get_tree().process_frame
  if cancelled:break
  var sim=BattleSim.new();sim.silent=true;sim.setup(c.lineup(),rival.roster,c.match_seed(),c.quality())
  var work_started=Time.get_ticks_msec()
  while not sim.finished and not cancelled:
   sim.step(1.0/30.0)
   if Time.get_ticks_msec()-work_started>=12:
    await get_tree().process_frame;work_started=Time.get_ticks_msec()
  if cancelled:break
  var match_stage=WorldTour.stage_label(c)
  if not WorldTour.resolve(c,sim):status="Simulation stopped: "+c.last_error;break
  matches.append({"cup":cup,"stage":match_stage,"opponent":rival.name,"winner":sim.winner,"duration":sim.time,"rows":sim.report_rows(),"gold":int(c.state.report.gold),"seed":sim.battle_seed})
  if c.state.tour.bracket.finished:
   var history=c.state.tour.history[-1].duplicate(true);history.gold=int(c.state.gold);history.roster=c.lineup().duplicate(true);history.team_names=[c.state.name]+c.state.clubs.map(func(cl):return cl.name)
   history.cpu_economy=c.state.clubs.map(func(cl):return {"name":cl.name,"gold":int(cl.get("development_gold",0)),"earned":int(cl.get("development_earned",0)),"spent":int(cl.get("development_spent",0)),"roster":cl.roster.duplicate(true)})
   history.survived=int(history.place)<=WorldTour.survival_place(c)
   if not history.survived and first_failure==0:first_failure=cup
   cups.append(history)
  await get_tree().process_frame
 choose_rewards(c,frozen_plan,decisions)
 var complete=not cancelled and c.state.tour.complete and cups.size()==int(frozen_plan.cups)
 result={"version":"0.73","mode":"speedrun_stat_check","complete":complete,"cancelled":cancelled,"seed":int(initial.seed),"difficulty":frozen_plan.difficulty,"requested_cups":int(frozen_plan.cups),"elapsed_seconds":float(Time.get_ticks_msec()-started)/1000.0,"first_survival_failure":first_failure,"initial_gold":int(initial.gold),"gold_left":int(c.state.gold),"initial_roster":initial.roster,"final_roster":c.lineup().duplicate(true),"plan":frozen_plan,"cups":cups,"matches":matches,"purchases":purchases,"decisions":decisions,"rules":"Benchmark continues after elimination, with normal training and gold. Regular survival failure is reported separately. Priority items are forged at component cost without shop RNG. No trophies, Ascension unlocks or personal Atlas records."}
 result.cpu_matches=c.state.get("speedrun_cpu",[])
 result.unfulfilled=[]
 for index in range(frozen_plan.items.size()):
  if not done.has(str(index)):
   var choice=frozen_plan.items[index];var target=str(choice.get("target",""))
   var eligible=c.lineup().any(func(h):return (target.is_empty() or h.id==target) and choice.id not in h.get("equipment",{}).values() and h.get("equipment",{}).size()<HeroData.item_slots(h))
   result.unfulfilled.append({"priority":index+1,"item":choice.id,"target":target,"reason":"No legal recipient or free unlocked slot" if not eligible else "Waiting for gold or the next purchasing opportunity"})
 running=false
 status="Cancelled · partial results kept." if cancelled else "Completed %d cups · %d player matches in %.1fs"%[cups.size(),matches.size(),result.elapsed_seconds] if complete else "Stopped · partial results kept."
 if not save_result():status+=" · Could not write results to disk."
 if game.phase=="speedrun":game.render()

func save_result() -> bool:
 var records=[]
 if FileAccess.file_exists(RESULTS_PATH):
  var saved=JSON.parse_string(FileAccess.get_file_as_string(RESULTS_PATH))
  if saved is Array:records=saved
 records.push_front(result);records=records.slice(0,20)
 var file=FileAccess.open(RESULTS_PATH+".tmp",FileAccess.WRITE)
 if file==null:return false
 file.store_string(JSON.stringify(records));file.close()
 return DirAccess.rename_absolute(RESULTS_PATH+".tmp",RESULTS_PATH)==OK

func export_result() -> String:
 if result.is_empty():return ""
 var path="user://speedrun-%d-%dcups.json"%[int(result.seed),int(result.requested_cups)]
 var file=FileAccess.open(path,FileAccess.WRITE)
 if file==null:return ""
 file.store_string(JSON.stringify(result,"  "));file.close()
 return ProjectSettings.globalize_path(path)
