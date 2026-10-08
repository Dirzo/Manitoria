extends SceneTree
## Dungeon mode routing: walk all three depths through every room type, forcing wins (and a few
## losses) so map movement, flames, loot, events, outfitters, Wardens and saves are all exercised.
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
 var opponent=c.opponent();var sim=BattleSim.new();sim.silent=true;sim.setup(c.lineup(),opponent.roster,c.match_seed(),c.quality())
 for u in sim.units:
  if (u.team==0)==win:u.attack*=30;u.attack_basic*=30;u.ability_power*=30;u.max_hp*=20;u.hp=u.max_hp
 sim.run_to_end()
 check(sim.winner==(0 if win else 1),"Controlled fixture produces the forced result")
 return c.resolve(sim)

func settle(c: Campaign) -> void:
 while not c.pending_heroes().is_empty():
  var h=c.pending_heroes()[0];check(c.choose(h.id,0),"Level reward applies")
 var d=c.state.dungeon
 if not d.loot.is_empty():check(Dungeon.take_loot(c,0),"Spoils go into the bag")
 if not d.event.is_empty():
  var pick=-1
  for i in range(d.event.choices.size()):
   if not d.event.choices[i].get("disabled",false):pick=i;break
  check(pick>=0,"Every event has a valid choice")
  check(Dungeon.choose_event(c,pick)!="","Event choice resolves")
  if not d.loot.is_empty():check(Dungeon.take_loot(c,0),"Event spoils go into the bag")
 if c.state.tour.shop:check(WorldTour.leave_shop(c),"Leave the outfitter")
 if c.state.tour.get("intermission",false):check(WorldTour.end_intermission(c),"Descend to the next depth")

func run() -> void:
 # Map shape: every room reachable, a Warden at the bottom of every depth.
 var probe=Campaign.new();probe.new_run("Map probe",94,1234,"Standard");Dungeon.start(probe)
 for act in range(1,Dungeon.ACTS+1):
  for s in range(20):
   probe.state.seed=1000+s*17
   var m=Dungeon.generate(probe,act)
   check(m.size()==Dungeon.ROWS and m[-1].size()==1 and m[-1][0].type=="boss","Every depth ends in a single Warden")
   for r in range(1,m.size()):
    for j in range(m[r].size()):check(m[r-1].any(func(n):return j in n.links),"Every room has a way in")
   for r in range(m.size()-1):
    for n in m[r]:check(not n.links.is_empty(),"Every room has a way out")
   check(m.any(func(row):return row.any(func(n):return n.type=="elite")),"Every depth holds an elite")

 var c=Campaign.new();c.new_run("Dungeon flow",95,4242,"Standard");Dungeon.start(c);squad(c)
 check(Dungeon.active(c),"Dungeon mode is active")
 check(c.state.dungeon.flames==3,"Standard difficulty carries three flames")
 check(WorldTour.opponent(c).roster.size()>=4,"Opponent preview works without a bracket")
 check(not c.state.tour.has("bracket"),"No cup bracket is drawn")
 check(c.save(),"Fresh dungeon run saves")
 var reloaded=Campaign.new();check(reloaded.load_slot(95) and Dungeon.active(reloaded),"Dungeon run loads from its slot")
 var seen={};var steps=0;var losses=0
 while not c.state.tour.complete and not c.state.get("run_over",false) and steps<60:
  settle(c)
  var options=Dungeon.reachable(c)
  check(not options.is_empty(),"There is always a room ahead")
  if options.is_empty():break
  # Prefer room types not yet visited so the walk covers everything.
  var col=options[0]
  for o in options:
   if not seen.has(str(c.state.dungeon.map[int(c.state.dungeon.row)+1][o].type)):col=o;break
  for o in options:
   if str(c.state.dungeon.map[int(c.state.dungeon.row)+1][o].type)=="elite" and not seen.has("elite"):col=o
  var kind=Dungeon.enter(c,col);check(kind!="","Enter room "+str(col))
  seen[kind]=true
  if kind in ["battle","elite","boss"]:
   var lose=kind=="battle" and losses<1 and c.state.dungeon.flames>1
   if lose:
    var before=int(c.state.dungeon.flames)
    check(fight(c,false),"Lost fight resolves");losses+=1
    check(int(c.state.dungeon.flames)==before-1,"A lost fight snuffs out one flame")
    check(not c.state.dungeon.fight,"A lost skirmish still lets the guild push past")
   else:
    var depth=int(c.state.dungeon.act)
    check(fight(c,true),"Won fight resolves")
    if kind=="boss":check(c.state.tour.complete or int(c.state.dungeon.act)==depth+1,"A Warden opens the next depth")
  steps+=1
  print("Dungeon: depth ",c.state.dungeon.act," room ",c.state.dungeon.row+1," ",kind," flames ",c.state.dungeon.flames," gold ",c.state.gold)
  await process_frame
 settle(c)
 check(c.state.tour.complete,"All three depths are conquered")
 check(c.state.dungeon.history.size()==3,"Three Wardens recorded")
 check(c.state.get("chests",[]).size()==3,"Each Warden drops a medal chest")
 for k in ["battle","elite","boss","treasure","rest"]:check(seen.has(k),"Visited a %s room"%k)
 check(c.state.gold>=0,"Gold never goes negative")

 # Running out of flames ends the run.
 var f=Campaign.new();f.new_run("Snuffed",96,777,"Champion");Dungeon.start(f);squad(f)
 check(f.state.dungeon.flames==2,"Champion difficulty carries two flames")
 var guard=0
 while not f.state.get("run_over",false) and guard<10:
  settle(f)
  var opts=Dungeon.reachable(f);var pick=opts[0]
  for o in opts:
   if f.state.dungeon.map[int(f.state.dungeon.row)+1][o].type in ["battle","elite","boss"]:pick=o;break
  var kind=Dungeon.enter(f,pick)
  if kind in ["battle","elite","boss"]:check(fight(f,false),"Losing fight resolves")
  guard+=1
 check(f.state.get("run_over",false) and f.state.dungeon.flames==0,"The run ends when the last flame goes out")
 for slot in [95,96]:
  for suffix in ["",".backup",".tmp"]:
   if FileAccess.file_exists(Campaign.save_path(slot)+suffix):DirAccess.remove_absolute(Campaign.save_path(slot)+suffix)
 print("Dungeon smoke: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
