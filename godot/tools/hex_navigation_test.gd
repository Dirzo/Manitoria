extends SceneTree
var failures=0
var checks=0
func check(ok: bool, message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(message)

func _init() -> void:
 HeroData.load_data()
 for seed_value in range(1,7):
  var teams=[[],[]]
  for side in range(2):
   for i in range(5):
    var sp=["golem","minotaur","cyclops","harpy","unicorn"][i]
    var hero=HeroData.make_hero(sp,"%d-%d"%[side,i],sp,5)
    hero.slot=Campaign.FORMATION[i];hero.learned={"0":1,"1":1}
    teams[side].append(hero)
  var sim=BattleSim.new();sim.setup(teams[0],teams[1],seed_value)
  var valid={"cells":true,"steps":true,"standing":true,"attack":true,"attacks":0,"moves":0}
  sim.action.connect(func(event):
   if event.type!="attack":return
   var unit=sim.find_unit(event.uid);var target=sim.find_unit(unit.pending_target)
   valid.attacks+=1
   if unit.has("next_cell") or not unit.pos.is_equal_approx(ArenaGrid.point(unit.cell)) or ArenaGrid.distance(unit.cell,target.cell)>unit.attack_hexes:valid.attack=false)
  while not sim.finished:
   sim.step(1.0/30.0)
   var occupied={}
   for unit in sim.units:
    if not unit.alive:continue
    if occupied.has(unit.cell):valid.cells=false
    occupied[unit.cell]=true
    if unit.has("next_cell"):
     valid.moves+=1
     if occupied.has(unit.next_cell):valid.cells=false
     occupied[unit.next_cell]=true
     if ArenaGrid.distance(unit.cell,unit.next_cell)!=1:valid.steps=false
     if Geometry2D.get_closest_point_to_segment(unit.pos,ArenaGrid.point(unit.cell),ArenaGrid.point(unit.next_cell)).distance_to(unit.pos)>0.001:valid.steps=false
    elif not unit.pos.is_equal_approx(ArenaGrid.point(unit.cell)):valid.standing=false
  check(valid.cells,"No two living units share or reserve the same hex")
  check(valid.steps and valid.moves>0,"All normal movement follows adjacent hex edges")
  check(valid.standing,"Standing units stay centered on their hex")
  check(valid.attack and valid.attacks>0,"Basic attacks begin on a hex and inside fixed hex range")
  check(sim.time<CombatPacing.TIME_LIMIT,"Mixed teams resolve without a navigation timeout")
 var sim=BattleSim.new()
 var a=sim.add_unit(HeroData.make_hero("golem","a","A",3),0,Vector2.ZERO)
 var b=sim.add_unit(HeroData.make_hero("cyclops","b","B",3),1,Vector2.ZERO)
 check(a.cell!=b.cell,"Overlapping spawn requests find distinct free cells")
 sim.leap(a,b)
 check(a.cell!=b.cell and a.pos.is_equal_approx(ArenaGrid.point(a.cell)),"Leaps land on an unoccupied hex")
 var old_a=a.cell;var old_b=b.cell
 sim.swap_hexes(a,b)
 check(a.cell==old_b and b.cell==old_a,"Wild position swaps preserve hex occupancy")
 print("Hex navigation: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
