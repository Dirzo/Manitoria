extends SceneTree
const STRATEGIES=["Balanced","Attack tempo","Spell power","Tank carry"]
var catalog={}
var output:FileAccess
var games=0
func _initialize() -> void:call_deferred("run")
func choose(cards: Array,h: Dictionary,strategy: String,rng: RandomNumberGenerator) -> Dictionary:
 if strategy=="Balanced":return cards[rng.randi_range(0,cards.size()-1)]
 var best=cards[0];var score_best=-INF
 for card in cards:
  var score=rng.randf()*.15
  if card.type=="evolution":
   var mods=Evolutions.entry(card.key).get("mods",{})
   score+=float(mods.get("potency",1.0)) if strategy=="Spell power" else float(mods.get("hp",1.0)) if strategy=="Tank carry" else float(mods.get("haste",1.0))
  elif card.type in ["ability","signature"]:
   var effect=HeroData.species[h.sp].ab if card.type=="signature" else HeroData.learned_ability(h.sp,int(card.key)).effect
   var p=SkillScaling.profile(h.sp,effect,"signature" if card.type=="signature" else str(card.key))
   score+=float(p.get("ap",0.0)) if strategy=="Spell power" else float(p.get("hp",0.0))+float(p.get("armor",0.0)) if strategy=="Tank carry" else float(p.get("ad",0.0))+float(p.get("as",0.0))
   if HeroData.species[h.sp].role=="Support":score+=1.3 if effect in ["renew","radiance","rootbloom","regrowth","ward","tidal"] else .1
   score+=.2 if card.get("upgrade",false) else .3
  if score>score_best:score_best=score;best=card
 return best
func develop(club: Dictionary,cup: int,difficulty: String,strategy: String,rng: RandomNumberGenerator) -> Dictionary:
 var funds=League.START_GOLD
 for h in club.roster:funds-=League.cost(h.sp)
 assert(funds>=0)
 for prior in range(1,cup):funds+=2*TourBalance.match_gold(prior,difficulty,true)+2*TourBalance.match_gold(prior,difficulty,false)+60
 var earned=funds;var spent=0;var c=Campaign.new()
 for h in club.roster:
  var goal=TourBalance.level(cup,difficulty,h.id)
  while h.level<goal:
   h.level+=1;HeroData.apply_choice(h,choose(HeroData.choices(h,true,rng),h,strategy,rng))
  h.equipment={};h.tactics=BattleTactics.for_hero(h)
 for slot in range(3):
  for h in club.roster:
   var rec=Forge.recommended(h.sp,h);var id=rec[slot];var cost=RivalEconomy.item_cost(id)
   if funds>=cost:h.equipment[str(slot)]=id;funds-=cost;spent+=cost
 assert(funds>=0 and spent+funds==earned)
 return {"roster":club.roster,"strategy":strategy,"spent":spent,"remaining":funds,"elite":club.elite}
func draft(rng: RandomNumberGenerator,id: String,anchor: String="") -> Dictionary:
 var legs=League.tiers().Legendary;var head=anchor if anchor in legs else legs[rng.randi_range(0,legs.size()-1)]
 var club=League.draft_club(id,head,rng,id)
 for attempt in range(200):
  if anchor.is_empty() or club.roster.any(func(h):return h.sp==anchor):return club
  head=legs[rng.randi_range(0,legs.size()-1)];club=League.draft_club(id,head,rng,id)
 push_error("Unable to draft anchor "+anchor);quit(1);return club
func simulate(a: Dictionary,b: Dictionary,side: int,seed: int,meta: Dictionary) -> Dictionary:
 var sim=BattleSim.new();sim.silent=true;sim.setup(a.roster if side==0 else b.roster,b.roster if side==0 else a.roster,seed);sim.run_to_end()
 var rows=[];var margin=0.0
 for u in sim.units:
  if u.summon:continue
  var h=u.hero
  var r={"sp":h.sp,"team":u.team,"won":sim.winner==u.team,"alive":u.alive,"damage":u.damage,"healing":u.healing,"blocked":u.blocked,"taken":u.damage_taken,"cc":u.get("cc",0.0),"ais":League.ais(sim,u),"skills":u.ability_stats,"level":h.level,"stars":ChampionStars.tier(h),"evolution":h.get("evolution",""),"learned":h.learned,"signature_rank":h.signature_rank,"items":h.equipment.values(),"rarity":h.get("skill_rarity",{}),"strategy":a.strategy if u.team==side else b.strategy}
  rows.append(r)
  if u.alive:margin+=(1.0 if u.team==side else -1.0)*u.hp/u.max_hp
 var row=meta.duplicate(true);row.side=side;row.seed=seed;row.winner=sim.winner;row.seconds=sim.time;row.timeout=sim.time>=CombatPacing.TIME_LIMIT;row.margin=margin;row.units=rows
 output.store_line(JSON.stringify(row));games+=1
 return row
func carrier(id: String,scenario: int) -> String:
 var list=[];var info=ItemEffects.definition(id);var stats=Forge.stats_of(id)
 if not Forge.valid(id):
  for stat in ["hp","attack","armor","haste","speed"]:stats[stat]=float(info.get(stat,0.0))
 for sp in HeroData.species:
  var h=HeroData.make_hero(sp,"score",sp,8);h.learned={"0":1,"4":1,"8":1};var w=SkillScaling.build_weights(h)
  var score=stats.attack*w.ad*5+stats.potency*w.ap*5+stats.haste*w["as"]*5+stats.hp*w.hp*3+stats.armor*w.armor*8+(1-stats.cd)*w.cd*5
  if id in Forge.recommended(sp,h):score+=1
  if "heal" in info.get("description","").to_lower() and HeroData.species[sp].role=="Support":score+=.4
  list.append({"sp":sp,"score":score})
 list.sort_custom(func(a,b):return a.score>b.score)
 return list[scenario%2].sp
func run() -> void:
 HeroData.load_data();ItemFeedback.enabled=false
 var mode=OS.get_environment("AUDIT_MODE");var start=int(OS.get_environment("AUDIT_START"));var count=int(OS.get_environment("AUDIT_COUNT"));var label=OS.get_environment("AUDIT_LABEL")
 output=FileAccess.open("user://analytics-"+label+".jsonl",FileAccess.WRITE)
 var defs={"species":HeroData.species,"items":{},"skill_audit":SkillScaling.audited("arachne","signature")}
 for id in ItemFeedback.ids():defs.items[id]=ItemEffects.definition(id)
 var cat=FileAccess.open("user://analytics-catalog-"+label+".json",FileAccess.WRITE);cat.store_string(JSON.stringify(defs));cat.close()
 if mode=="champions":
  var all=HeroData.species.keys()
  for i in range(start,start+count):
   var seed=93000+i;var rng=RandomNumberGenerator.new();rng.seed=seed;HeroData.run_salt="analytics|"+str(seed);League.run_tiers=League.roll_tiers(str(seed))
   var cup=1+(i/32)%5;var difficulty=["Keeper","Standard","Champion"][(i/160)%3]
   var a=develop(draft(rng,"a"+str(i),all[i%32]),cup,difficulty,STRATEGIES[(i/32)%4],rng)
   var b=develop(draft(rng,"b"+str(i)),cup,difficulty,STRATEGIES[rng.randi_range(0,3)],rng)
   for side in range(2):simulate(a,b,side,seed,{"kind":"champions","pair":i,"cup":cup,"difficulty":difficulty,"anchor":all[i%32],"wallets":[a.remaining,b.remaining],"spent":[a.spent,b.spent]})
   if (i-start+1)%8==0:print(label," pairs ",i-start+1,"/",count," games ",games)
   await process_frame
 else:
  var ids=ItemFeedback.ids()
  var selected=OS.get_environment("AUDIT_ITEM_IDS")
  if not selected.is_empty():ids=Array(selected.split(","))
  var scenarios=maxi(8,int(OS.get_environment("AUDIT_SCENARIOS")))
  for index in range(start,start+count):
   var id=ids[index]
   for scenario in range(scenarios):
    var seed=170000+index*scenarios+scenario;var rng=RandomNumberGenerator.new();rng.seed=seed;HeroData.run_salt="item-audit|"+str(seed);League.run_tiers=League.roll_tiers(str(seed));var sp=carrier(id,scenario)
    var cup=3+scenario%3;var difficulty=["Keeper","Standard","Champion"][scenario%3]
    var a=develop(draft(rng,"ia"+str(seed),sp),cup,difficulty,STRATEGIES[scenario%4],rng)
    var b=develop(draft(rng,"ib"+str(seed)),cup,difficulty,STRATEGIES[(scenario+1)%4],rng)
    var subject=a.roster.filter(func(h):return h.sp==sp)[0];subject.equipment.erase("2")
    for slot in subject.equipment.keys():
     if subject.equipment[slot]==id:subject.equipment.erase(slot)
    var before=a.duplicate(true)
    subject.equipment["2"]=id
    for side in range(2):
     var meta={"kind":"items","pair":index*scenarios+scenario,"item":id,"carrier":sp,"cup":cup,"difficulty":difficulty,"scenario":scenario}
     meta.condition="baseline";simulate(before,b,side,seed,meta)
     meta.condition="item";simulate(a,b,side,seed,meta)
   print(label," items ",index-start+1,"/",count," games ",games)
   await process_frame
 output.close();print("Audit complete ",label," games ",games);quit()
