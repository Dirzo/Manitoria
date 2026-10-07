extends SceneTree
var rows=[]
var fixtures={}
func _initialize() -> void:call_deferred("run")
func hero(sp: String,id: String) -> Dictionary:
 var h=HeroData.make_hero(sp,id,HeroData.species[sp].n,8)
 h.learned={"0":1,"4":1,"8":1};h.signature_rank=2;h.equipment={};h.copies=1
 h.tactics=BattleTactics.for_hero(h)
 return h
func squad(subject: String,item: String="",single_item: bool=false) -> Array:
 var pool=["golem","minotaur","phoenix","unicorn","direwolf","gargoyle","harpy","naga"]
 var result=[];var c=Campaign.new()
 var h=hero(subject,"subject");h.slot=c.standard_slot(h,[])
 if single_item:
  if not item.is_empty():h.equipment={"0":item}
 else:
  var recommended=Forge.recommended(subject,h)
  for i in range(2):h.equipment[str(i)]=recommended[i]
 result.append(h)
 for sp in pool:
  if sp==subject:continue
  var ally=hero(sp,"ally-"+sp);ally.slot=c.standard_slot(ally,result.map(func(o):return o.slot))
  var rec=Forge.recommended(sp,ally)
  for i in range(2):ally.equipment[str(i)]=rec[i]
  result.append(ally)
  if result.size()==5:break
 return result
func foes(index: int) -> Array:
 var result=[];var c=Campaign.new()
 for sp in (["gargoyle","minotaur","harpy","direwolf","naga"] if index==0 else ["golem","arachne","phoenix","thunderbird","unicorn"]):
  var h=hero(sp,"foe-"+sp);h.slot=c.standard_slot(h,result.map(func(o):return o.slot))
  var rec=Forge.recommended(sp,h)
  for i in range(2):h.equipment[str(i)]=rec[i]
  result.append(h)
 return result
func fight(team: Array,enemy: Array,side: int,seed: int) -> Dictionary:
 var sim=BattleSim.new();sim.silent=true;sim.setup(team if side==0 else enemy,enemy if side==0 else team,seed);sim.run_to_end()
 var report=sim.report_rows();var subject=report.filter(func(r):return r.id=="subject")[0]
 var margin=0.0
 for u in sim.units:
  if not u.summon and u.alive:margin+=(1.0 if u.team==side else -1.0)*u.hp/u.max_hp
 return {"winner":sim.winner,"side":side,"won":sim.winner==side,"draw":sim.winner<0,"timeout":sim.time>=CombatPacing.TIME_LIMIT,"seconds":sim.time,"margin":margin,"subject":subject}
func item_carrier(id: String) -> String:
 var best="golem";var score_best=-INF;var info=ItemEffects.definition(id);var st=Forge.stats_of(id)
 if not Forge.valid(id):
  for stat in ["hp","attack","armor","haste","speed"]:st[stat]=float(info.get(stat,0.0))
 var text=info.get("description","").to_lower()
 for sp in HeroData.species:
  var h=hero(sp,"score");var w=SkillScaling.build_weights(h)
  var score=0.0
  score+=st.attack*w.get("ad",0.0)*5+st.potency*w.get("ap",0.0)*5+st.haste*w.get("as",0.0)*5
  score+=st.hp*w.get("hp",0.0)*3+st.armor*w.get("armor",0.0)*8+(1.0-st.cd)*w.get("cdr",0.0)*5
  if id in Forge.recommended(sp,h):score+=1.0
  if ("heal" in text or "ally" in text) and HeroData.species[sp].role=="Support":score+=.3
  if ("taking" in text or "hits you" in text or "below" in text) and HeroData.species[sp].role in ["Tank","Bruiser"]:score+=.3
  if score>score_best:score_best=score;best=sp
 return best
func run() -> void:
 HeroData.load_data();HeroData.run_salt="performance-069";League.run_tiers={};ItemFeedback.enabled=false
 var mode=OS.get_environment("SUMMARY_MODE");var output={"mode":mode,"version":"0.69","level":8,"copies":1,"evolution":"none","signature_rank":2,"learned":{"0":1,"4":1,"8":1},"rows":[]}
 if mode.begins_with("items"):
  var ids=ItemFeedback.ids()
  if mode=="items-legacy":ids=ids.filter(func(id):return not Forge.valid(id))
  for id in ids:
   var carrier=item_carrier(id);var info=ItemEffects.definition(id);var entry={"id":id,"info":info,"stats":Forge.stats_of(id),"cost":RivalEconomy.item_cost(id) if Forge.valid(id) else int(info.price),"carrier":carrier,"battles":[]}
   for side in range(2):
    var key=carrier+str(side)
    if not fixtures.has(key):fixtures[key]=fight(squad(carrier,"",true),foes(0),side,6201)
    var battle=fight(squad(carrier,id,true),foes(0),side,6201)
    battle.baseline=fixtures[key];entry.battles.append(battle)
   output.rows.append(entry);print("Item ",output.rows.size(),"/",ids.size()," ",id)
   await process_frame
 else:
  for sp in HeroData.species:
   var h=hero(sp,"subject");var entry={"sp":sp,"name":HeroData.species[sp].n,"role":HeroData.species[sp].role,"build":SkillScaling.build_weights(h),"items":Forge.recommended(sp,h),"battles":[]}
   for opponent in range(2):
    for side in range(2):entry.battles.append(fight(squad(sp),foes(opponent),side,6201+opponent))
   output.rows.append(entry);print("Champion ",output.rows.size(),"/",HeroData.species.size()," ",sp)
   await process_frame
 var file=FileAccess.open("user://performance-"+mode+".json",FileAccess.WRITE);file.store_string(JSON.stringify(output,"  "));file.close()
 print("Performance screening complete: ",mode," ",output.rows.size()," entries");quit()
