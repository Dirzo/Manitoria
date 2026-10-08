extends SceneTree
var checks=0
var failures=0
func check(ok: bool,msg: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(msg)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var c=Campaign.new();c.new_run("Five cup flow",93,691,"Standard")
 c.state.roster=[]
 for i in range(5):
  var h=HeroData.make_hero(["golem","minotaur","harpy","unicorn","phoenix"][i],"flow%d"%i,"Flow %d"%i,1);h.slot=Campaign.FORMATION[i];c.state.roster.append(h)
 c.state.gold=0;c.state.headliner=c.state.roster[0].id;c.draft_rivals()
 var fights=0
 while not c.state.tour.complete and fights<25:
  while not c.pending_heroes().is_empty():
   var h=c.pending_heroes()[0];check(c.choose(h.id,0),"Actual level reward applies and saves")
  if c.state.tour.get("intermission",false):check(WorldTour.end_intermission(c),"Start the next cup")
  if c.state.tour.shop:
   var h=c.state.roster[2]
   # 0.73 retired champion copies: buying one must be refused without charging gold.
   var before_gold=int(c.state.gold);check(not c.buy_champion_copy(h.id) and int(c.state.gold)==before_gold,"Copy purchases stay retired during the shop")
   check(WorldTour.leave_shop(c),"Leave shop and retain team")
  var opponent=WorldTour.opponent(c);var sim=BattleSim.new();sim.silent=true;sim.setup(c.lineup(),opponent.roster,c.match_seed(),c.quality())
  # Forced wins isolate full tournament/save routing; this is not a balance win-rate sample.
  for u in sim.units:
   if u.team==0:u.attack*=30;u.attack_basic*=30;u.ability_power*=30;u.max_hp*=20;u.hp=u.max_hp
  sim.run_to_end();check(sim.winner==0,"Controlled flow fixture wins")
  check(WorldTour.resolve(c,sim),"Match, rewards, rival wallets and bracket save")
  check(c.state.gold>=0,"Player wallet stays nonnegative")
  for cl in c.state.clubs:check(cl.development_gold>=0,"Rival wallet stays nonnegative through actual brackets")
  fights+=1;print("Tour flow: match ",fights," cup ",c.state.tour.level)
  await process_frame
 check(c.state.tour.complete and fights==20,"Twenty winning matches complete all five cups")
 check(c.state.tour.history.size()==5,"All five cup histories are retained")
 check(c.state.roster.all(func(h):return ChampionStars.tier(h)==ChampionStars.tier({})),"No champion gains a copy/star tier after retirement")
 check(c.state.roster.all(func(h):return not str(h.evolution).is_empty()),"Earned rewards include named evolutions")
 print("Full five-cup save flow: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
