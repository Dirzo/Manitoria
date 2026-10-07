extends SceneTree
var failures=0
var checks=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 HeroData.load_data()
 var book=JSON.parse_string(FileAccess.get_file_as_string("res://data/skill-audit.json"))
 var balance=JSON.parse_string(FileAccess.get_file_as_string("res://data/build-path-audit.json"))
 check(balance.counts.ad==174 and balance.counts.ap==174,"Equal AD/AP damage pools")
 var channels={"ad":0,"ap":0};var ids={}
 var vfx=VFX.new();get_root().add_child(vfx)
 for sp in book:
  var primary=book[sp].signature.build_path;channels[primary]+=1
  for key in book[sp]:
   var entry=book[sp][key];var credit="signature" if key=="signature" else "ability:"+key
   check(entry.scaling.get("ap" if primary=="ad" else "ad",0.0)==0.0,"Single primary channel: "+sp+":"+key)
   var c=AbilityFX.ctx(sp,Color.TRANSPARENT,"Rare",credit,entry.effect)
   check(c.skill_id==sp+":"+key and not ids.has(c.skill_id),"Unique VFX identity: "+sp+":"+key);ids[c.skill_id]=true
   AbilityFX.play(vfx,entry.effect,c,Vector3(-3,0,0),Vector3(2,0,0),[Vector3(2,0,0),Vector3(3,0,1)])
   check(vfx.count()>0 and vfx.count()<=VFX.MAX_LIVE,"Visible, bounded cast: "+c.skill_id)
   var age=vfx.live[0].age;vfx.advance(0)
   check(vfx.live[0].age==age,"Pause-safe: "+c.skill_id)
   vfx.advance(12)
   check(vfx.count()==0,"Effect expires: "+c.skill_id)
   if entry.effect in ["barrage","wisps"]:
    var projectile=AbilityFX.projectile(vfx,c,entry.effect)
    check(projectile.has_meta("skill_id"),"Named projectile silhouette: "+c.skill_id);projectile.free()
   await process_frame
 check(channels.ad==16 and channels.ap==16,"16 champions per primary path")
 # A disposable replay applies the learned skill once and leaves the real hero untouched.
 var hero=HeroData.make_hero("arachne","unlock","Unlock",5)
 var offer={"type":"ability","key":"3","name":"Spider Swarm","rarity":"Rare","bonus":1.1}
 var snapshot=hero.duplicate(true);var demo=AbilityDemo.new();demo.setup(hero,offer)
 check(hero==snapshot and demo.hero.learned["3"]==1,"Unlock replay cannot mutate or double-upgrade a campaign skill")
 for evo in Evolutions.options("hydra"):
  check(Evolutions.entry(evo).get("mods",{}).get("potency",1.0)<=1.0,"AD Hydra evolutions avoid AP bonuses")
 var trained=HeroData.make_hero("minotaur","trained","Trained",20)
 trained.signature_rank=3;trained.learned={"0":3,"1":3,"2":3}
 trained.evolution=Evolutions.options("minotaur")[0];trained.apex="apex_stats"
 var growth=HeroData.choices(trained,true,RandomNumberGenerator.new())
 check(growth.any(func(c):return c.type=="agility") and not growth.any(func(c):return c.type=="focus"),"Max-rank AD growth avoids a useless AP reward")
 var interval=HeroData.stats(trained).interval
 HeroData.apply_choice(trained,{"type":"agility","name":"Relentless Tempo"})
 check(is_equal_approx(HeroData.stats(trained).interval,interval/1.08),"Tempo growth raises attack speed by eight percent")
 print("Build paths/VFX: ",checks," checks, ",failures," failures; ",ids.size()," actions")
 vfx.queue_free();await process_frame;quit(1 if failures else 0)
