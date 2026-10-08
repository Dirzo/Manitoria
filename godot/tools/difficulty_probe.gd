extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 HeroData.load_data();HeroData.run_salt="difficulty-audit";League.run_tiers={};ItemFeedback.enabled=false
 var output=[];var fights=0
 for difficulty in ["Keeper","Standard","Champion"]:
  for cup in range(1,6):
   if OS.get_environment("PROBE_DIFFICULTY")!="" and difficulty!=OS.get_environment("PROBE_DIFFICULTY"):continue
   if OS.get_environment("PROBE_CUP")!="" and cup!=int(OS.get_environment("PROBE_CUP")):continue
   var row={"copy_gold":0,"star_champions":0,"difficulty":difficulty,"cup":cup,"wins":0,"draws":0,"fights":0,"survival":0.0,"duration":0.0,"player_level":0,"rival_level":0,"timeouts":0}
   for cohort in range(8):
    for seed in range(int(OS.get_environment("PROBE_SEEDS")) if OS.get_environment("PROBE_SEEDS")!="" else 2):
     var c=Campaign.new();c.state={"difficulty":difficulty,"seed":891,"tour":{"level":cup,"bout":0}}
     var rng=RandomNumberGenerator.new();rng.seed=791+seed
     var players=[];var rivals=[];var species=HeroData.species.keys()
     for i in range(5):
      var sp=species[(cohort*4+i)%species.size()]
      var h=HeroData.make_hero(sp,"probe-%d-%d"%[cohort,i],sp,1);h.slot=Campaign.FORMATION[i]
      # Four winning bouts per previous cup, with ordinary unfocused XP.
      var xp=(cup-1)*(4*roundi(80*WorldTour.PLAYER_XP)+TourBalance.TRAINING_XP)
      while h.level<20 and xp>=HeroData.xp_needed(h.level):
       xp-=HeroData.xp_needed(h.level);h.level+=1
       var cards=HeroData.choices(h,true,rng);HeroData.apply_choice(h,cards[0])
      h.equipment={}
      var rec=Forge.recommended(sp,h)
      var count=[0,1,2,2,3][cup-1]
      for slot in range(count):h.equipment[str(slot)]=rec[slot%rec.size()]
      if cup==1 or cup==4:h.equipment[str(count)]=["fang","plate","ember","moon","seed"][i]
      players.append(h)
      var enemy=HeroData.make_hero(sp,"rival-%d-%d"%[cohort,i],sp,1);enemy.slot=h.slot
      var lev=TourBalance.level(cup,difficulty,enemy.id)
      while enemy.level<lev:
       enemy.level+=1;var cards=HeroData.choices(enemy,true,rng);HeroData.apply_choice(enemy,cards[rng.randi_range(0,cards.size()-1)])
      enemy.equipment=Forge.rival_loadout(enemy,WorldTour.stage(c),difficulty)
      var club={"roster":[enemy]};c.state.clubs=[club];WorldTour.outfit_clubs(c)
      rivals.append(enemy)
     for side in range(2):
      var sim=BattleSim.new();sim.silent=true
      sim.setup(players if side==0 else rivals,rivals if side==0 else players,901+seed,c.quality() if side==0 else 1.0)
      # BattleSim only applies quality to team one; adjust mirrored player's opponent manually.
      if side==1:
       for u in sim.units:
        if u.team==0:
         u.hp*=c.quality();u.max_hp*=c.quality();u.attack*=c.quality();u.attack_basic*=c.quality();u.ability_power*=c.quality();u.skill_base*=c.quality()
      sim.run_to_end();row.fights+=1;fights+=1
      row.wins+=1 if sim.winner==side else 0;row.draws+=1 if sim.winner==-1 else 0
      row.survival+=float(sim.living(side,false).size())/5;row.duration+=sim.time
      row.timeouts+=1 if sim.time>=CombatPacing.TIME_LIMIT else 0
     row.player_level=players[0].level;row.rival_level=rivals[0].level
   row.win_rate=float(row.wins)/row.fights;row.survival/=row.fights;row.duration/=row.fights
   output.append(row);print(difficulty," cup ",cup,": ",row.wins,"/",row.fights," player L",row.player_level," rival L",row.rival_level)
   await process_frame
 var label=OS.get_environment("BALANCE_LABEL")
 var out=FileAccess.open("res://../../difficulty-"+label+".json",FileAccess.WRITE);out.store_string(JSON.stringify({"fights":fights,"rows":output},"  "));out.close()
 print("Difficulty probe: ",fights," mirrored fights");quit()
