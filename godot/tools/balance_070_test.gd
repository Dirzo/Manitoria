extends SceneTree
var checks=0
var failures=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func _initialize() -> void:
 HeroData.load_data();ItemFeedback.enabled=false
 var sim=BattleSim.new();sim.silent=true
 var naga=sim.add_unit(HeroData.make_hero("naga","n","Naga",8),0,ArenaGrid.center(0,0))
 var covered=sim.add_unit(HeroData.make_hero("golem","c","Covered",8),0,ArenaGrid.center(1,1))
 var far=sim.add_unit(HeroData.make_hero("golem","f","Far",8),0,ArenaGrid.center(0,2))
 var foe=sim.add_unit(HeroData.make_hero("golem","e","Enemy",8),1,ArenaGrid.center(-1,0))
 naga.casting_resolution=true
 check(sim.cast_signature(naga,foe),"Naga casts Tidal Ward")
 check(covered.shield>0,"Ward covers an ally on the diagonal second hex")
 check(far.shield==0,"Ward preserves a meaningful formation boundary")
 var dive=BattleSim.new();dive.silent=true
 var gargoyle=dive.add_unit(HeroData.make_hero("gargoyle","g","Gargoyle",8),0,ArenaGrid.center(0,0))
 var enemy=dive.add_unit(HeroData.make_hero("golem","e1","Primary",8),1,ArenaGrid.center(1,0))
 var neighbor=dive.add_unit(HeroData.make_hero("golem","e2","Nearby",8),1,ArenaGrid.center(1,1))
 var distant=dive.add_unit(HeroData.make_hero("golem","e3","Distant",8),1,ArenaGrid.center(4,0))
 gargoyle.casting_resolution=true
 check(dive.cast_signature(gargoyle,enemy),"Stone Dive casts")
 check(enemy.hp<enemy.max_hp and neighbor.hp<neighbor.max_hp,"Stone Dive damages primary and nearby enemies")
 check(distant.hp==distant.max_hp,"Stone Dive does not splash distant enemies")
 check(gargoyle.shield>0,"Stone Dive retains its protective stone shield")
 var h=HeroData.make_hero("direwolf","s","Sugar",8);h.equipment={"0":"sugarrush"}
 var sugar=dive.add_unit(h,0,ArenaGrid.center(-2,0))
 Forge.tick(dive,sugar,10.0)
 check(is_equal_approx(sugar.hp/sugar.max_hp,.94),"Sugar Rush trades 6% health for ten seconds of tempo")
 Forge.tick(dive,sugar,1000.0)
 check(is_equal_approx(sugar.hp/sugar.max_hp,.15),"Sugar Rush cannot drain below its 15% floor")
 for sp in HeroData.species:
  var rec=Forge.recommended(sp)
  check(rec.size()==3 and rec.all(func(id):return Forge.is_item(id)),"Legal suggested items for "+sp)
 print("0.70 targeted mechanics: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
