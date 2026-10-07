extends SceneTree
var checks=0
var failures=0
func check(ok: bool,msg: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(msg)
func _initialize() -> void:
 HeroData.load_data()
 var sim=BattleSim.new();sim.silent=true
 var a=sim.add_unit(HeroData.make_hero("unicorn","a","A",8),0,Vector2.ZERO)
 var tank=sim.add_unit(HeroData.make_hero("golem","tank","Tank",8),0,Vector2.ONE)
 tank.hp=tank.max_hp*.1;var hp=tank.hp;sim.heal(a,tank,100)
 check(is_equal_approx(tank.hp-hp,100),"Single-support healing retains full power")
 var b=sim.add_unit(HeroData.make_hero("treant","b","B",8),0,Vector2.ONE*2)
 hp=tank.hp;sim.heal(a,tank,100)
 check(is_equal_approx(tank.hp-hp,70),"Two supports have a defined stacking tradeoff")
 b.alive=false;hp=tank.hp;sim.heal(a,tank,100)
 check(is_equal_approx(tank.hp-hp,100),"Losing a support restores the survivor's full healing")
 a.forge=["grievous"];tank.scorch_source=a.uid;sim.status(tank,"scorch",3.0)
 hp=tank.hp;sim.heal(a,tank,100)
 check(is_equal_approx(tank.hp-hp,50),"Grievous Thorns offers a meaningful 50% healing counter")
 a.forge=[];hp=tank.hp;sim.heal(a,tank,100)
 check(is_equal_approx(tank.hp-hp,65),"Other scorch effects keep their existing reduction")
 check(CombatPacing.sustain_factor(59)==1.0,"Normal-duration battles keep full sustain")
 check(is_equal_approx(CombatPacing.sustain_factor(85),.5),"Overtime fades sustain gradually")
 check(is_equal_approx(CombatPacing.sustain_factor(120),.05),"Late fights cannot retain a high sustain floor")
 check(CombatPacing.support_heal_factor(4)==.4,"Stacking does not reduce healing to zero")
 print("Healing/stacking/overtime: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
