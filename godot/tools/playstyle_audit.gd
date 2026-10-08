extends SceneTree
const STYLES={"Attack tempo":["jackalope","minotaur","harpy","direwolf","naga"],"Spell control":["phoenix","arachne","wyvern","naga","gargoyle"],"Sustain support":["unicorn","treant","gargoyle","manticore","direwolf"],"Tank carry":["zaratan","golem","gargoyle","owlbear","troll"]}
func _initialize() -> void:call_deferred("run")
func team(style: String,difficulty: String,cup: int,seed: int) -> Array:
 var c=Campaign.new();var heroes=[];var rng=RandomNumberGenerator.new();rng.seed=891+seed
 var budget=0
 for prior in range(1,cup):budget+=4*TourBalance.match_gold(prior,difficulty,true)+150+[1,6,11,15,20][prior-1]*15
 for sp in STYLES[style]:
  var h=HeroData.make_hero(sp,style+sp,sp,1);h.slot=c.standard_slot(h,heroes.map(func(o):return o.slot))
  var xp=(cup-1)*800
  while xp>=HeroData.xp_needed(h.level):
   xp-=HeroData.xp_needed(h.level);h.level+=1
   var cards=HeroData.choices(h,true,rng);var best=cards[0];var best_score=-INF
   for card in cards:
    var score=0.0
    if card.type=="evolution":
     var e=Evolutions.entry(card.key);score=e.get("mods",{}).get("potency",1.0) if style=="Spell control" else e.get("mods",{}).get("hp",1.0) if style in ["Tank carry","Sustain support"] else e.get("mods",{}).get("haste",1.0)
    elif card.type in ["ability","signature"]:
     var effect=HeroData.species[h.sp].ab if card.type=="signature" else HeroData.learned_ability(h.sp,int(card.key)).effect
     var weights=SkillScaling.profile(h.sp,effect,"signature" if card.type=="signature" else str(card.key))
     score=weights.get("ap",0.0) if style=="Spell control" else weights.get("hp",0.0)+weights.get("armor",0.0) if style=="Tank carry" else weights.get("ad",0.0)+weights.get("as",0.0)
     if style=="Sustain support" or HeroData.species[h.sp].role=="Support":score=1.5 if effect in ["renew","radiance","rootbloom","regrowth","ward","tidal"] else .5
     score+=.2 if card.get("upgrade",false) else .3
    if score>best_score:best_score=score;best=card
   HeroData.apply_choice(h,best)
  if style=="Attack tempo" and OS.get_environment("STYLE_COUNTER")=="1":
   h.tactics={"target":"healers","teamwork":"assist","opening":"flank" if HeroData.line(h.sp)=="Flank" else "advance"}
  if HeroData.species[h.sp].role=="Support":h.tactics=BattleTactics.PRESETS.Support.duplicate(true)
  h.equipment={};heroes.append(h)
 for slot in range(3):
  for h in heroes:
   var item=(["frenzy","tusk","grievous"][slot] if style=="Attack tempo" and OS.get_environment("STYLE_COUNTER")=="1" and h.sp in ["jackalope","direwolf"] else Forge.recommended(h.sp,h)[slot]);
   if style=="Spell control" and OS.get_environment("STYLE_COUNTER")=="1" and slot==2 and h.sp=="phoenix":item="grievous"
   var cost=RivalEconomy.item_cost(item)
   if budget>=cost:h.equipment[str(slot)]=item;budget-=cost
 return heroes
func run() -> void:
 HeroData.load_data();HeroData.run_salt="playstyle-audit";League.run_tiers={};ItemFeedback.enabled=false
 var output=[];var names=STYLES.keys();var cup=int(OS.get_environment("STYLE_CUP")) if OS.get_environment("STYLE_CUP")!="" else 4
 for difficulty in ["Keeper","Standard","Champion"]:
  for a in range(names.size()):
   for b in range(a+1,names.size()):
    if OS.get_environment("STYLE_VS")!="" and names[b]!=OS.get_environment("STYLE_VS"):continue
    if OS.get_environment("STYLE_A")!="" and names[a]!=OS.get_environment("STYLE_A"):continue
    if OS.get_environment("STYLE_DIFFICULTY")!="" and difficulty!=OS.get_environment("STYLE_DIFFICULTY"):continue
    var row={"difficulty":difficulty,"cup":cup,"a":names[a],"b":names[b],"wins_a":0,"wins_b":0,"draws":0,"timeouts":0,"seconds":0.0,"fights":0}
    for seed in range(int(OS.get_environment("STYLE_SEEDS")) if OS.get_environment("STYLE_SEEDS")!="" else 2):
     var players=team(names[a],difficulty,cup,seed);var foes=team(names[b],difficulty,cup,seed)
     if players.size()!=5 or foes.size()!=5:push_error("Invalid playstyle fixture");quit(1);return
     for side in range(2):
      var sim=BattleSim.new();sim.silent=true;sim.setup(players if side==0 else foes,foes if side==0 else players,841+seed)
      sim.run_to_end();row.fights+=1
      row.wins_a+=1 if sim.winner==side else 0;row.wins_b+=1 if sim.winner==1-side else 0;row.draws+=1 if sim.winner==-1 else 0
      row.timeouts+=1 if sim.time>=CombatPacing.TIME_LIMIT else 0;row.seconds+=sim.time
    row.seconds/=row.fights;output.append(row);print(difficulty," ",names[a]," vs ",names[b]," ",row.wins_a,"-",row.wins_b," timeouts ",row.timeouts)
    await process_frame
 var file=FileAccess.open("user://playstyle-audit"+OS.get_environment("STYLE_LABEL")+".json",FileAccess.WRITE);file.store_string(JSON.stringify(output,"  "));file.close()
 print("Playstyles: ",output.reduce(func(total,row):return total+row.fights,0)," mirrored fights");quit()
