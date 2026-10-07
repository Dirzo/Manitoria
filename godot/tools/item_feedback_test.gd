extends SceneTree
var checks=0
var failures=0
func check(ok: bool,msg: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(msg)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 HeroData.load_data()
 var vfx=VFX.new();get_root().add_child(vfx)
 var sound=SoundDesign.new();get_root().add_child(sound)
 var families={}
 for id in ItemFeedback.ids():
  var hero=HeroData.make_hero("minotaur","item","Item",7);hero.equipment={"0":id}
  var foe=HeroData.make_hero("golem","foe","Foe",7)
  var sim=BattleSim.new();sim.setup([hero],[foe],991)
  var carrier=sim.units[0];var enemy=sim.units[1];var events=[]
  sim.action.connect(func(e):
   if e.type=="item_feedback":events.append(e.duplicate(true)))
  ItemFeedback.opening(sim,carrier)
  check(events.size()==1 and events[0].item_id==id,"Equipped item has an identity cue: "+id)
  var p=ItemFeedback.profile(id);families[p.family]=true
  check(p.color.a>0 and not p.name.is_empty(),"Resolved themed profile: "+id)
  ItemFeedback.play(vfx,events[0],Vector3.ZERO,Vector3.ZERO)
  check(vfx.count()>0,"Visible equipped item: "+id);vfx.clear()
  ItemFeedback.signal_effect(sim,carrier,id,enemy,"proc",15)
  var proc_event=events[-1]
  ItemFeedback.play(vfx,proc_event,Vector3.ZERO,Vector3(3,0,0))
  check(vfx.count()>0 and vfx.count()<=VFX.MAX_LIVE,"Visible bounded activation: "+id)
  var cue=SoundDesign.event_sound(proc_event,carrier)
  check(not cue.key.is_empty() and sound.cache.has(cue.key),"Loaded activation sound: "+id)
  var before=events.size();ItemFeedback.signal_effect(sim,carrier,id,enemy,"proc",15)
  check(events.size()==before,"Repeated activations are presentation-throttled: "+id)
  var age=vfx.live[0].age;vfx.advance(0)
  check(vfx.live[0].age==age,"Item VFX pause with battle: "+id)
  vfx.advance(3);check(vfx.count()==0,"Item VFX expire: "+id)
  # Compare real combat with presentation enabled/disabled. Same damage, outcomes and RNG.
  var snapshots=[]
  for show in [true,false]:
   ItemFeedback.enabled=show
   var battle=BattleSim.new();battle.silent=true;battle.setup([hero.duplicate(true)],[foe.duplicate(true)],921)
   for tick in range(600):
    if battle.finished:break
    battle.step(1.0/30.0)
   snapshots.append([battle.winner,battle.time,battle.rng.state,battle.units.map(func(u):return [u.hp,u.damage,u.healing,u.shield,u.attack,u.interval])])
  check(snapshots[0]==snapshots[1],"Presentation does not alter combat or RNG: "+id)
  ItemFeedback.enabled=true
  await process_frame
 # Verify meaningful passive augmentation is emitted by the real action hooks.
 var h=HeroData.make_hero("minotaur","attacker","Attacker",7);h.equipment={"0":"fang","1":"plate","2":"ember"}
 var sim=BattleSim.new();sim.setup([h],[HeroData.make_hero("golem","enemy","Enemy",7)],7)
 var events=[];sim.action.connect(func(e):
  if e.type=="item_feedback":events.append(e.duplicate(true)))
 var u=sim.units[0];var target=sim.units[1]
 sim.hurt(u,target,25,false,"basic")
 check(events.any(func(e):return e.item_id=="fang" and e.stage=="augment"),"Actual basic damage shows attack-stat augmentation")
 sim.hurt(target,u,25,false,"basic")
 check(events.any(func(e):return e.item_id=="plate" and e.stage=="augment"),"Actual incoming damage shows armor augmentation")
 sim.cast_visual(u,"gore","Gore",target.pos)
 check(events.any(func(e):return e.item_id=="ember" and e.stage=="augment"),"Actual cast shows spell-stat augmentation")
 check(families.size()>=9,"Distinct item feedback families")
 sound.stop_all();sound.queue_free();vfx.queue_free();await process_frame
 print("Item feedback/audio: ",checks," checks, ",failures," failures; ",ItemFeedback.ids().size()," items; ",families.size()," families")
 quit(1 if failures else 0)
