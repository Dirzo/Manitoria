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
 if not c.state.dungeon.get("draft", {}).is_empty():
  var before = c.state.roster.size()
  if before < Dungeon.MAX_CHAMPIONS: check(Dungeon.take_champion(c, 0) and c.state.roster.size() == before + 1, "A drafted champion joins")
  else: check(Dungeon.skip_draft(c), "A full guild passes on a draft")
 if not c.state.dungeon.get("instance_choices", []).is_empty():
  var pick = c.state.dungeon.instance_choices[0]
  check(Dungeon.choose_instance(c, pick), "Choose an instance")
  check(c.state.dungeon.instance == pick and not c.state.dungeon.map.is_empty(), "The chosen instance gets its own map")
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
  if kind=="boss":check(c.opponent().roster.size()==1+clampi(Dungeon.party(c)-3,0,2) and c.opponent().roster[0].has("monster"),"A Warden brings escorts sized to the guild")
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
 var kept_progress=FileAccess.get_file_as_string(DungeonAscension.PROGRESS_PATH) if FileAccess.file_exists(DungeonAscension.PROGRESS_PATH) else ""
 for path in [Dungeon.SCORES_PATH,DungeonAscension.PROGRESS_PATH]:
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
 # Ten instances, each with four monsters and a Warden that exist in the bestiary.
 check(DungeonInstances.ORDER.size() == 10, "Ten dungeon instances")
 for id in DungeonInstances.ORDER:
  var info = DungeonInstances.info(id)
  check(info.mobs.size() == 4 and info.mobs.all(func(k): return Bestiary.MOBS.has(k)), "%s monsters exist" % id)
  check(Bestiary.BOSSES.has(info.boss), "%s Warden exists" % id)
  for k in info.mobs: check(HeroData.species.has(Bestiary.MOBS[k].sp), "%s uses a real creature model" % k)
 var visited = []
 for i in range(10):
  var offer = DungeonInstances.offer(visited, "cycle")
  check(offer.size() == 2 and offer[0] != offer[1] and (i == 9 or not offer.any(func(id): return id in visited)), "Offers never repeat an instance within a cycle")
  check(offer.any(func(id): return id not in visited), "Every offer includes an unvisited instance")
  visited.append(offer[0])
 check(DungeonInstances.offer(visited, "cycle").size() == 2, "Offers continue after every instance is visited")
 # Every instance dresses the arena without errors.
 var arena = ArenaView.new(); root.add_child(arena); await process_frame
 for id in DungeonInstances.ORDER:
  var i = DungeonInstances.info(id)
  arena.set_region({"name": i.name, "place": i.name, "theme": DungeonInstances.theme_name(id), "color": i.accent, "floor": i.floor, "sky": i.sky, "dungeon": id})
  check(arena.world_props.get_child_count() > 40, "%s arena is dressed" % id)
 arena.set_region({}); check(not arena.has_meta("dungeon_saved"), "Leaving the dungeon restores the colosseum")
 arena.queue_free()
 # Run traits: eight of the pool, two per species, rolled differently per run.
 var a=RunTraits.roll("alpha");var b=RunTraits.roll("beta")
 check(a.active.size()>=RunTraits.AWAKEN-2,"About fourteen traits awaken each run")
 check(a.species.values().all(func(t):return t.size()>=2 and t.size()<=3),"Every species carries two or three traits")
 for sp in a.species:check(a.species[sp].all(func(x):return x in RunTraits.tags_of(sp)),"%s only carries its own traits"%sp)
 check(a.species.values().all(func(t):return t.all(func(x):return x in a.active)),"Species only carry awakened traits")
 check(a.active!=b.active or a.species!=b.species or a.flavour!=b.flavour,"Traits re-roll between runs")
 check(RunTraits.tags_of("owlbear").has("avian") and RunTraits.tags_of("owlbear").has("ursine") and RunTraits.tags_of("owlbear").has("bruiser"),"The Owlbear is Avian, Ursine and a Bruiser")
 var flavours={}
 for s in range(40):
  var r=RunTraits.roll("f%d"%s)
  for id in r.flavour:flavours[id+str(r.flavour[id])]=true
 check(flavours.size()>=40,"Trait flavours vary between runs")

 var c=Campaign.new();c.new_run("Dungeon flow",95,4242,"Standard");Dungeon.start(c);squad(c)
 check(Dungeon.active(c),"Dungeon mode is active")
 check(c.state.dungeon.lives==3,"Standard difficulty has three lives")
 check(c.state.dungeon.instance_choices.size()==2 and c.state.dungeon.map.is_empty(),"A run opens on a choice of two instances")
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
 for k in ["battle","elite","boss","checkpoint","rest"]:check(seen.has(k),"Visited a %s room"%k)
 check(c.state.dungeon.visited.size()==3 and c.state.dungeon.visited.duplicate().all(func(id):return c.state.dungeon.visited.count(id)==1),"Three different instances on the way down")
 check(Dungeon.go_endless(c),"Descend into the endless depths")
 check(int(c.state.dungeon.act)==4 and c.state.dungeon.endless and c.state.dungeon.instance_choices.size()==2,"Endless depth 4 opens with a new choice")
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

 # The dungeon draft: headliner, a partner from five, then unlocks up to six.
 var g=Campaign.new();g.new_run("Draft flow",91,8080,"Standard");Dungeon.start(g)
 check(g.choose_starter(League.tiers().Legendary[0]),"Sign the headliner")
 check(g.state.roster.size()==1 and g.state.dungeon.draft.kind=="partner" and g.state.dungeon.draft.offers.size()==Dungeon.DRAFT_SIZE,"A partner draft of five follows the headliner")
 check(not g.recruitment_open(),"No recruit market in the dungeon")
 check(not Dungeon.skip_draft(g),"The partner draft cannot be skipped")
 var offered=g.state.dungeon.draft.offers.map(func(h):return h.sp)
 check(offered.all(func(sp):return League.tier(sp)!="Legendary") and offered.size()==offered.duplicate().filter(func(x):return true).size(),"Partners are Epic or Common champions")
 check(g.state.dungeon.draft.offers.all(func(h):return h.has("rolls")) and g.state.dungeon.draft.offers[0].rolls!=g.state.dungeon.draft.offers[1].rolls,"Every offer has its own stat rolls")
 check(Dungeon.take_champion(g,2) and g.state.roster.size()==2 and g.lineup().size()==2,"The partner joins the formation")
 check(g.lineup_ready(),"Two champions can fight")
 check(Dungeon.choose_instance(g,g.state.dungeon.instance_choices[0]),"Enter the first instance")
 check(Dungeon.opponent(g).roster.size()==2,"Fights are sized to the guild")
 var hits=0
 for s in range(30):
  var probe_c=Campaign.new();probe_c.new_run("Bias %d"%s,91,9000+s,"Standard");Dungeon.start(probe_c);probe_c.choose_starter(League.tiers().Legendary[s%8])
  hits+=probe_c.state.dungeon.draft.offers.filter(func(h):return not Dungeon.shared_traits(probe_c,h.sp).is_empty()).size()
 check(hits>30*1.2,"Drafts lean toward champions that share traits (%d synergy offers in 30 drafts)"%hits)
 while g.state.roster.size()<Dungeon.MAX_CHAMPIONS:
  Dungeon.offer_draft(g,"checkpoint",0);check(Dungeon.take_champion(g,0),"Unlock a champion")
 check(g.lineup().size()==6 and g.lineup_ready(),"Six champions take the field")
 Dungeon.offer_draft(g,"checkpoint",0);check(not Dungeon.take_champion(g,0),"No seventh champion")
 check(Dungeon.opponent(g).roster.size()==5,"Six champions meet a pack of five")
 # Old saves that still say "flames" load as lives.
 var old=Campaign.new();old.new_run("Old save",97,55,"Standard");Dungeon.start(old)
 old.state.dungeon.flames=2;old.state.dungeon.max_flames=3;old.state.dungeon.erase("lives");old.state.dungeon.erase("max_lives");old.state.dungeon.erase("relics");old.state.dungeon.erase("traits")
 Dungeon.migrate(old)
 check(old.state.dungeon.lives==2 and old.state.dungeon.max_lives==3 and old.state.dungeon.has("traits"),"Flame saves migrate to lives")
 var pre=Campaign.new();pre.new_run("Pre-instance save",98,56,"Standard");Dungeon.start(pre)
 for k in ["instance","visited","instance_choices"]:pre.state.dungeon.erase(k)
 pre.state.dungeon.act=2;Dungeon.migrate(pre)
 check(pre.state.dungeon.instance=="magma_depths" and pre.state.dungeon.instance_choices.is_empty(),"Saves from before instances keep their depth's theme")

 # Running out of lives ends the run and banks its score.
 var f=Campaign.new();f.new_run("Snuffed",96,777,"Champion");Dungeon.start(f);squad(f)
 check(f.state.dungeon.lives==2,"Champion difficulty has two lives")
 var guard=0
 while not f.state.get("run_over",false) and guard<10:
  settle(f)
  if f.state.dungeon.map.is_empty():continue
  var opts=Dungeon.reachable(f);var pick=opts[0]
  for o in opts:
   if f.state.dungeon.map[int(f.state.dungeon.row)+1][o].type in ["battle","elite","boss"]:pick=o;break
  var kind=Dungeon.enter(f,pick)
  if kind in ["battle","elite","boss"]:check(fight(f,false),"Losing fight resolves")
  guard+=1
 check(f.state.get("run_over",false) and f.state.dungeon.lives==0,"The run ends when the last life is lost")
 check(f.state.dungeon.has("final_score") and Dungeon.scores().size()==2,"A fallen run banks its score")
 # Tradeoffs: rerolls cost escalating gold, the altar trades a relic up, the ferryman takes a champion.
 var t=Campaign.new();t.new_run("Tradeoffs",95,4242,"Standard");Dungeon.start(t);squad(t)
 var td=t.state.dungeon;t.state.gold=200
 Dungeon.offer_loot(t,"relic");var first=td.loot.duplicate()
 check(Dungeon.reroll_cost(t)==20 and Dungeon.reroll_loot(t) and t.state.gold==180,"A reroll costs 20 gold")
 check(Dungeon.reroll_cost(t)==40 and td.loot.size()==3 and td.loot_kind=="relic","Rerolls climb by 20 and keep the reward kind")
 Dungeon.take_loot(t,0)
 t.state.gold=10;Dungeon.offer_loot(t,"item");check(not Dungeon.reroll_loot(t),"No reroll without the gold");Dungeon.skip_loot(t)
 Dungeon.offer_draft(t,"checkpoint",0);t.state.gold=100;var names=td.draft.offers.map(func(h):return h.sp)
 check(Dungeon.reroll_draft(t) and td.draft.offers.size()==5,"A draft can be rerolled")
 Dungeon.skip_draft(t)
 var altar=Dungeon.EVENTS.filter(func(e):return e.id=="altar")[0].duplicate(true)
 td.event=altar;var relics_before=td.relics.size();var gone=str(td.relics[-1])
 check(Dungeon.choose_event(t,0)!="" and td.relics.size()==relics_before-1 and gone not in td.relics and td.loot_kind=="relic","The Ember Altar destroys a relic for a better pick")
 check(td.loot.all(func(r):return Relics.info(str(r)).rarity in ["Rare","Boss"]),"The altar offers a higher rarity")
 Dungeon.take_loot(t,0)
 var ferry=Dungeon.EVENTS.filter(func(e):return e.id=="ferryman")[0].duplicate(true)
 var who=Dungeon.ferry_candidate(t);var size_before=t.state.roster.size();var gold_before=int(t.state.gold)
 td.event=ferry
 check(not who.is_empty() and str(who.id)!=str(t.state.headliner),"The ferryman never takes the headliner")
 check(Dungeon.choose_event(t,0)!="" and t.state.roster.size()==size_before-1 and int(t.state.gold)==gold_before+120 and td.loot_kind=="relic","The ferryman trades a champion for a Boss relic and gold")
 check(td.loot.all(func(r):return Relics.info(str(r)).rarity=="Boss"),"The ferryman's relics are Boss relics")
 Dungeon.take_loot(t,0)
 # Threat reads: every fight room ahead gets a label, Wardens read harder than the first skirmish.
 var th=Campaign.new();th.new_run("Threat",95,5151,"Standard");Dungeon.start(th);squad(th);Dungeon.choose_instance(th,th.state.dungeon.instance_choices[0])
 var first_room=Dungeon.threat(th,0,0);var boss_room=Dungeon.threat(th,Dungeon.ROWS-1,0)
 check(first_room>0.0 and not Dungeon.threat_label(first_room).is_empty(),"Fight rooms carry a threat read (%.2f)"%first_room)
 check(boss_room>0.0,"The Warden carries a threat read (%.2f)"%boss_room)
 for h in th.state.roster:h.level=int(h.level)+5
 check(Dungeon.threat(th,Dungeon.ROWS-1,0)<boss_room,"A stronger guild reads the same Warden as less dangerous")
 # Ascension: modifiers stack and clears unlock the next rank.
 var asc_run=Campaign.new();asc_run.new_run("Ascended",95,6161,"Standard");Dungeon.start(asc_run,8)
 check(asc_run.state.dungeon.lives==2 and DungeonAscension.rank(asc_run)==8,"Ascension 4+ starts with one fewer life")
 check(Dungeon.draft_size(asc_run)==4,"Ascension 5+ drafts offer four")
 check(is_equal_approx(Dungeon.multiplier(asc_run),1.0+0.15*8),"Ascension adds 15% score per rank")
 if FileAccess.file_exists(DungeonAscension.PROGRESS_PATH):DirAccess.remove_absolute(DungeonAscension.PROGRESS_PATH)
 check(DungeonAscension.unlocked()==0,"A fresh profile has no Ascension")
 var a0=Campaign.new();a0.new_run("Climber",95,7171,"Standard");Dungeon.start(a0,0)
 check(DungeonAscension.record_clear(a0)==1 and DungeonAscension.unlocked()==1,"Clearing rank 0 unlocks Ascension 1")
 check(DungeonAscension.record_clear(a0)==-1,"Clearing a rank twice unlocks nothing new")
 if kept_progress!="":
  var pf=FileAccess.open(DungeonAscension.PROGRESS_PATH,FileAccess.WRITE);pf.store_string(kept_progress);pf.close()
 elif FileAccess.file_exists(DungeonAscension.PROGRESS_PATH):DirAccess.remove_absolute(DungeonAscension.PROGRESS_PATH)
 for slot in [95,96,97]:
  for suffix in ["",".backup",".tmp"]:
   if FileAccess.file_exists(Campaign.save_path(slot)+suffix):DirAccess.remove_absolute(Campaign.save_path(slot)+suffix)
 if FileAccess.file_exists(Dungeon.SCORES_PATH):DirAccess.remove_absolute(Dungeon.SCORES_PATH)
 print("Dungeon smoke: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
