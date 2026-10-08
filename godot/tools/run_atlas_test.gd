extends SceneTree
var checks=0
var failures=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func _initialize() -> void:
 HeroData.load_data();ItemFeedback.enabled=false
 var c=Campaign.new();c.new_run("Atlas test",1,710071,"Champion")
 for i in range(5):
  var h=c.draft_prospect(["golem","naga","arachne","direwolf","thunderbird"][i]);h.slot=Campaign.FORMATION[i];c.state.roster.append(h)
 RunDatabase.ensure_id(c)
 var enemy=[]
 for i in range(5):
  var h=HeroData.make_hero(["golem","naga","arachne","direwolf","thunderbird"][i],"e%d"%i,"Enemy",1);h.slot=Campaign.FORMATION[i];enemy.append(h)
 var sim=BattleSim.new();sim.silent=true;sim.setup(c.lineup(),enemy,710);sim.run_to_end()
 RunDatabase.capture(c,sim,"player","one")
 check(c.state.atlas_pending.size()==1,"Record completed player match")
 check(c.state.atlas_pending[0].rows.size()==10,"Capture both teams with complete snapshots")
 RunDatabase.capture(c,sim,"player","one")
 check(c.state.atlas_pending.size()==1,"Pending records deduplicate")
 check(c.save(),"Save campaign and independent Atlas")
 check(c.state.atlas_pending.is_empty(),"Successful flush clears memory queue")
 var all=RunDatabase.aggregate({"side":"all"});check(all.matches==1 and all.champions.golem.n==2,"Both teams aggregate once")
 var player=RunDatabase.aggregate({"side":"player"});check(player.champions.golem.n==1,"Player filter excludes opponent")
 RunDatabase.capture(c,sim,"player","one");check(RunDatabase.flush(c),"Retry after restart is safe")
 check(RunDatabase.aggregate().matches==1,"Disk dedup prevents double counting")
 RunDatabase.capture(c,sim,"cpu","two");check(c.save(),"CPU bracket match persists")
 check(RunDatabase.aggregate({"side":"cpu"}).champions.golem.n==3,"CPU filter includes opposition and bracket")
 check(RunDatabase.aggregate({"side":"player"}).matches==1,"Player match count excludes CPU-only matches")
 check(RunDatabase.aggregate({"cup":5}).matches==0,"Cup filter")
 check(RunDatabase.aggregate({"difficulty":"Keeper"}).matches==0,"Difficulty filter")
 check(RunDatabase.aggregate({"patch":"0.70"}).matches==0,"Patch filter")
 var plan=DecisionMatrix.preview(c,enemy);check(plan.size()==5,"Every drafted champion receives a matching rule")
 check(plan.all(func(p):return p.condition=="Enemy healers"),"First matching rule takes precedence")
 c.state.decision_matrix={c.lineup()[0].id:[{"condition":"Always","preset":"Vanguard","goal":"Armor"}]}
 check(DecisionMatrix.apply(c,enemy),"Apply persists legal tactics")
 check(c.lineup()[0].build_goal=="Armor" and c.lineup()[0].tactics.posture=="guard","Matrix affects tactics and build goal")
 var base=SkillScaling.build_weights(c.lineup()[0]);c.lineup()[0].build_goal="Adaptive"
 check(base.armor>SkillScaling.build_weights(c.lineup()[0]).armor,"Build goal affects suggested item scoring")
 var q=c.quality();c.state.challenge_rank=10;check(is_equal_approx(c.quality(),q*1.2),"Challenge strength is fixed and monotonic")
 check(RunDatabase.unlocked_rank()==1,"Only first challenge initially available")
 c.state.challenge_rank=1;c.state.tour.complete=true
 RunDatabase.capture(c,sim,"player","three");check(c.save(),"Completed challenge persists")
 check(RunDatabase.unlocked_rank()==2,"Completed challenge unlocks next rank")
 var fresh=Campaign.new();fresh.new_run("Other campaign",2,12,"Keeper")
 check(RunDatabase.aggregate().matches==3,"New campaigns retain prior research")
 var restored=Campaign.new();check(restored.load_slot(1),"Old save loads with Atlas and matrix fields")
 RunDatabase.flush(restored);check(RunDatabase.aggregate().matches==3,"Save replay remains idempotent")
 print("RUN ATLAS: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
