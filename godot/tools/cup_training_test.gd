extends SceneTree
var checks=0
var failures=0
func check(ok: bool,msg: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(msg)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var c=Campaign.new();c.new_run("Training QA",96,921,"Standard")
 c.state.roster=[]
 for i in range(5):
  var h=HeroData.make_hero(["golem","minotaur","harpy","unicorn","phoenix"][i],"training%d"%i,"Training",1)
  h.slot=Campaign.FORMATION[i];c.state.roster.append(h)
 var bench=HeroData.make_hero("treant","bench","Bench",1);c.state.roster.append(bench)
 c.state.headliner=c.state.roster[0].id;c.draft_rivals();WorldTour.ensure_bracket(c)
 var matches=0
 while int(c.state.tour.level)==1 and matches<8:
  c.state.tour.shop=false
  var foe=WorldTour.opponent(c)
  var sim=BattleSim.new();sim.silent=true;sim.setup(c.lineup(),foe.roster,c.match_seed(),.01)
  for u in sim.units:
   if u.team==0:u.attack*=20;u.attack_basic*=20;u.ability_power*=20;u.max_hp*=10;u.hp=u.max_hp
  sim.run_to_end();check(sim.winner==0,"QA fixture wins the cup match")
  check(WorldTour.resolve(c,sim),"Cup result and training save successfully")
  matches+=1
 check(matches==4 and c.state.tour.level==2,"Four wins complete a cup")
 for h in c.lineup():
  check(h.level==6 and h.xp==0,"Actual cup XP plus camp reaches level six")
  check(h.get("last_xp",0)==320,"Final result includes match and training XP")
  check(not h.pending.is_empty(),"Training preserves player upgrade choices")
 check(bench.level==1 and bench.xp==0,"Unused reserves do not receive cup training")
 var xp=c.lineup().map(func(h):return [h.level,h.xp])
 WorldTour.ensure_bracket(c)
 check(xp==c.lineup().map(func(h):return [h.level,h.xp]),"Viewing completed bracket cannot grant training twice")
 print("Cup training/save: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
