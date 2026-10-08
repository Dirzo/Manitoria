extends SceneTree
## Dungeon mode routing: walk all three depths through every room type, forcing wins (and a few
## losses) so map movement, lives, loot and relics, events, outfitters, Wardens, endless depths,
## run traits, scores and saves are all exercised.
var checks=0
var failures=0
func check(ok: bool,msg: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(msg)
func _initialize() -> void:call_deferred("run")

func squad(c: Campaign) -> void:
 c.state.roster=[]
 for i in range(5):
  var h=HeroData.make_hero(["golem","minotaur","harpy","unicorn","phoenix"][i],"dg%d"%i,"Delver %d"%i,1);h.slot=Campaign.FORMATION[i];c.state.roster.append(h)
 c.state.headliner=c.state.roster[0].id;c.draft_rivals()

func fight(c: Campaign, win: bool) -> bool:
 var opponent=c.opponent();var sim=BattleSim.new();sim.silent=true;sim.team_mods=c.battle_mods();sim.setup(c.lineup(),opponent.roster,c.match_seed(),c.quality())
 for u in sim.units:
  if (u.team==0)==win:u.attack*=30;u.attack_basic*=30;u.ability_power*=30;u.max_hp*=20;u.hp=u.max_hp
 sim.run_to_end()
 check(sim.winner==(0 if win else 1),"Controlled fixture produces the forced result")
 return c.resolve(sim)

func settle(c: Campaign) -> void:
 while not c.pending_heroes().is_empty():
  var h=c.pending_heroes()[0];check(c.choose(h.id,0),"Level reward applies")
 var d=c.state.dungeon
 var guard=0
 while not d.loot.is_empty() and guard<5:check(Dungeon.take_loot(c,0),"Spoils are taken");guard+=1
 if not d.event.is_empty():
  var pick=-1
  for i in range(d.event.choices.size()):
   if not d.event.choices[i].get("disabled",false):pick=i;break
  check(pick>=0,"Every event has a valid choice")
  check(Dungeon.choose_event(c,pick)!="","Event choice resolves")
  while not d.loot.is_empty():check(Dungeon.take_loot(c,0),"Event spoils are taken")
 if c.state.tour.shop:check(WorldTour.leave_shop(c),"Leave the outfitter")
 if c.state.tour.get("intermission",false):check(WorldTour.end_intermission(c),"Descend to the next depth")

func walk_depth(c: Campaign, seen: Dictionary, lose_once: bool) -> void:
 var start_act=int(c.state.dungeon.act);var lost=false;var steps=0
 while int(c.state.dungeon.act)==start_act and not c.state.dungeon.awaiting_endless and not c.state.get("run_over",false) and steps<20:
  settle(c)
  if int(c.state.dungeon.act)!=start_act:break
  var options=Dungeon.reachable(c)
  check(not options.is_empty(),"There is always a room ahead")
  if options.is_empty():return
  var col=options[0]
  for o in options:
   if not seen.has(str(c.state.dungeon.map[int(c.state.dungeon.row)+1][o].type)):col=o;break
  for o in options:
   if str(c.state.dungeon.map[int(c.state.dungeon.row)+1][o].type)=="elite" and not seen.has("elite"):col=o
  var kind=Dungeon.enter(c,col);check(kind!="","Enter room "+str(col));seen[kind]=true
  if kind=="boss":check(c.opponent().roster.size()==3 and c.opponent().roster[0].has("monster"),"A Warden is a boss with two escorts")
  if kind=="battle":check(c.opponent().roster.all(func(h):return h.has("monster")),"Skirmishes are dungeon monsters")
  if kind in ["battle","elite","boss"]:
   if lose_once and not lost and kind=="battle" and c.state.dungeon.lives>1:
    var before=int(c.state.dungeon.lives)
    check(fight(c,false),"Lost fight resolves");lost=true
    check(int(c.state.dungeon.lives)==before-1,"A lost fight costs one life")
    check(not c.state.dungeon.fight,"A lost skirmish still lets the guild push past")
   else:
    var score=int(c.state.dungeon.score)
    check(fight(c,true),"Won fight resolves")
    check(int(c.state.dungeon.score)>score,"Winning earns points")
  steps+=1
  await process_frame

func run() -> void:
 for path in [Dungeon.SCORES_PATH]:
  if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
 # Map shape: every room reachable, a Warden at the bottom of every depth.
 var probe=Campaign.new();probe.new_run("Map probe",94,1234,"Standard");Dungeon.start(probe)
 for act in range(1,7):
  for s in range(12):
   probe.state.seed=1000+s*17
   var m=Dungeon.generate(probe,act)
   check(m.size()==Dungeon.ROWS and m[-1].size()==1 and m[-1][0].type=="boss","Every depth ends in a single Warden")
   check(m.any(func(row):return row.any(func(n):return n.type=="elite")),"Every depth holds an elite")
   for r in range(1,m.size()):
    for j in range(m[r].size()):check(m[r-1].any(func(n):return j in n.links),"Every room has a way in")
 # Run traits: eight of the pool, two per species, rolled differently per run.
 var a=RunTraits.roll("alpha");var b=RunTraits.roll("beta")
 check(a.active.size()==RunTraits.ACTIVE,"Eight run traits are active")
 check(a.species.values().all(func(t):return t.size()==2 and t[0]!=t[1]),"Every species carries two different traits")
 check(a.species.values().all(func(t):return t.all(func(x):return x in a.active)),"Species only carry active traits")
 check(a.active!=b.active or a.species!=b.species,"Traits re-roll between runs")
 var tally={}
 for t in a.species.values():
  for x in t:tally[x]=int(tally.get(x,0))+1
 check(tally.values().max()-tally.values().min()<=2,"Traits are dealt evenly across species")

 var c=Campaign.new();c.new_run("Dungeon flow",95,4242,"Standard");Dungeon.start(c);squad(c)
 check(Dungeon.active(c),"Dungeon mode is active")
 check(c.state.dungeon.lives==3,"Standard difficulty has three lives")
 check(WorldTour.opponent(c).roster.size()>=4,"Opponent preview works without a bracket")
 check(not c.state.tour.has("bracket"),"No cup bracket is drawn")
 # Relics and traits reach the fight.
 c.state.dungeon.relics=["giants_belt","trait_emblem:"+str(c.state.dungeon.traits.active[0])]
 var plain=BattleSim.new();plain.silent=true;plain.setup(c.lineup(),c.opponent().roster,1,1.0)
 var boosted=BattleSim.new();boosted.silent=true;boosted.team_mods=c.battle_mods();boosted.setup(c.lineup(),c.opponent().roster,1,1.0)
 check(boosted.units[0].max_hp>plain.units[0].max_hp*1.09,"Giant's Belt raises health in battle")
 check(RunTraits.counts(c,[]).get(c.state.dungeon.traits.active[0],0)==1,"Emblems count toward a trait")
 c.state.dungeon.relics=[]
 check(c.save(),"Fresh dungeon run saves")
 var reloaded=Campaign.new();check(reloaded.load_slot(95) and Dungeon.active(reloaded),"Dungeon run loads from its slot")
 var seen={}
 for depth in range(3):
  await walk_depth(c,seen,depth==0)
 settle(c)
 check(c.state.dungeon.awaiting_endless,"After three Wardens the guild chooses: bank or go endless")
 check(c.state.dungeon.relics.size()>=3,"Elites and Wardens grant relics")
 check(c.state.dungeon.history.size()==3,"Three Wardens recorded")
 check(c.state.get("chests",[]).size()==3,"Each Warden drops a medal chest")
 for k in ["battle","elite","boss","treasure","rest"]:check(seen.has(k),"Visited a %s room"%k)
 check(Dungeon.go_endless(c),"Descend into the endless depths")
 check(int(c.state.dungeon.act)==4 and c.state.dungeon.endless,"Endless depth 4 opens")
 settle(c)
 var quality_before=c.quality()
 await walk_depth(c,seen,false)
 check(int(c.state.dungeon.act)==5,"An endless Warden opens the next endless depth")
 check(int(c.state.tour.level)<=20,"Tour level stays within save limits")
 settle(c)
 var points=Dungeon.final_score(c)
 check(Dungeon.retire(c),"Retire from the endless depths")
 check(c.state.tour.complete and int(c.state.dungeon.final_score)==points,"Retiring banks the score")
 check(Dungeon.scores().size()==1 and Dungeon.rank_of(c)==1,"The banked run tops the high-score table")
 check(c.state.gold>=0,"Gold never goes negative")

 # Old saves that still say "flames" load as lives.
 var old=Campaign.new();old.new_run("Old save",97,55,"Standard");Dungeon.start(old)
 old.state.dungeon.flames=2;old.state.dungeon.max_flames=3;old.state.dungeon.erase("lives");old.state.dungeon.erase("max_lives");old.state.dungeon.erase("relics");old.state.dungeon.erase("traits")
 Dungeon.migrate(old)
 check(old.state.dungeon.lives==2 and old.state.dungeon.max_lives==3 and old.state.dungeon.has("traits"),"Flame saves migrate to lives")

 # Running out of lives ends the run and banks its score.
 var f=Campaign.new();f.new_run("Snuffed",96,777,"Champion");Dungeon.start(f);squad(f)
 check(f.state.dungeon.lives==2,"Champion difficulty has two lives")
 var guard=0
 while not f.state.get("run_over",false) and guard<10:
  settle(f)
  var opts=Dungeon.reachable(f);var pick=opts[0]
  for o in opts:
   if f.state.dungeon.map[int(f.state.dungeon.row)+1][o].type in ["battle","elite","boss"]:pick=o;break
  var kind=Dungeon.enter(f,pick)
  if kind in ["battle","elite","boss"]:check(fight(f,false),"Losing fight resolves")
  guard+=1
 check(f.state.get("run_over",false) and f.state.dungeon.lives==0,"The run ends when the last life is lost")
 check(f.state.dungeon.has("final_score") and Dungeon.scores().size()==2,"A fallen run banks its score")
 for slot in [95,96,97]:
  for suffix in ["",".backup",".tmp"]:
   if FileAccess.file_exists(Campaign.save_path(slot)+suffix):DirAccess.remove_absolute(Campaign.save_path(slot)+suffix)
 if FileAccess.file_exists(Dungeon.SCORES_PATH):DirAccess.remove_absolute(Dungeon.SCORES_PATH)
 print("Dungeon smoke: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
