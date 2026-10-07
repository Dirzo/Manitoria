extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 HeroData.load_data();ItemFeedback.enabled=false
 var saved=JSON.parse_string(FileAccess.get_file_as_string("res://../../soggy-run-original.json"))
 HeroData.run_salt=str(saved.salt);League.run_tiers=saved.tiers
 var players=saved.roster.filter(func(h):return h.slot>=0).duplicate(true)
 for h in players:h.level=saved.tour.start_levels.get(h.id,h.level)
 var rows=[]
 var cup=int(OS.get_environment("SOGGY_CUP")) if OS.get_environment("SOGGY_CUP")!="" else 3
 var stages=[1,6,11,15,20]
 # Keep the saved build; spend reachable level rewards on its existing skills.
 var campaign=Campaign.new();var growth_rng=RandomNumberGenerator.new();growth_rng.seed=811
 for h in players:
  h.pending=[];h.rewards=[]
  campaign.gain_xp(h,(cup-3)*800,true,true,growth_rng)
  while not h.pending.is_empty():
   HeroData.materialize_reward(h)
   var cards=h.pending[0];var chosen=cards[0]
   for card in cards:
    if card.type=="focus":chosen=card
   HeroData.apply_choice(h,chosen)
   h.pending.pop_front();h.rewards.pop_front()
 for revised in ([true] if OS.get_environment("SOGGY_REVISED_ONLY")=="1" else [false,true]):
  for club in saved.clubs:
   var rivals=club.roster.filter(func(h):return h.slot>=0).duplicate(true)
   if revised:
    for h in rivals:
     h.level=TourBalance.level(3,"Champion",h.id)
     var growth_level=TourBalance.level(cup,"Champion",h.id)
     while h.level<growth_level:campaign.gain_xp(h,HeroData.xp_needed(h.level)-int(h.xp),true,false,growth_rng)
     if h.level<8:h.evolution=""
     for k in h.learned.keys():
      if int(k)>=13:h.learned.erase(k)
     h.equipment=Forge.rival_loadout(h,stages[cup-1],"Champion")
     h.skill_rarity=h.get("skill_rarity",{});h.skill_rarity["0"]=TourBalance.rarity(stages[cup-1],"Champion",h.id)
   var row={"cup":cup,"revised":revised,"opponent":club.name,"wins":0,"draws":0,"fights":0,"remaining":0.0}
   for seed in range(2):
    for side in range(2):
     var quality=TourBalance.quality(cup,2,"Champion") if revised else 1.13
     var sim=BattleSim.new();sim.silent=true
     sim.setup(players if side==0 else rivals,rivals if side==0 else players,517+seed,quality if side==0 else 1.0)
     if side==1:
      for u in sim.units:
       if u.team==0:
        u.hp*=quality;u.max_hp*=quality;u.attack*=quality;u.attack_basic*=quality;u.ability_power*=quality;u.skill_base*=quality
     sim.run_to_end();row.fights+=1;row.wins+=1 if sim.winner==side else 0;row.draws+=1 if sim.winner==-1 else 0
     row.remaining+=sim.living(side,false).size()/5.0
   row.remaining/=row.fights;rows.append(row);print("Revised ",revised," ",club.name," ",row.wins,"/",row.fights)
   await process_frame
 var suffix=OS.get_environment("SOGGY_LABEL")
 var out=FileAccess.open("res://../../soggy-balance-"+(suffix if suffix!="" else "replays")+".json",FileAccess.WRITE);out.store_string(JSON.stringify(rows,"  "));out.close()
 print("Soggy save comparison: ",rows.size()*4," mirrored replays; original save untouched");quit()
