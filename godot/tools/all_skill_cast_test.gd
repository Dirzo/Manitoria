extends SceneTree
func _init() -> void:
 HeroData.load_data()
 var casts=0;var failures=0
 for sp in HeroData.species:
  for i in range(16):
   var a=HeroData.learned_ability(sp,i)
   if a.is_empty():continue
   var sim=BattleSim.new();sim.silent=true;sim.rng.seed=42
   var source=sim.add_unit(HeroData.make_hero(sp,"s","Source",5),0,Vector2.ZERO)
   var target=sim.add_unit(HeroData.make_hero("golem","t","Target",5),1,ArenaGrid.center(1,0))
   source.hp=source.max_hp*0.4;source.casting_resolution=true
   target.hp=target.max_hp*20.0
   if not sim.cast_learned(source,target,a,1):
    failures+=1;push_error("Failed to resolve %s:%d — %s"%[sp,i,a.name])
   casts+=1
   # Resolve missiles and damage-over-time in the actual simulation.
   for frame in range(90):sim.step(1.0/30.0)
 print("All skill mechanics: %d actual casts, %d failures"%[casts,failures])
 quit(1 if failures else 0)
