extends SceneTree
var checks=0
var failures=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func _initialize() -> void:
 HeroData.load_data()
 var expected: Array[Vector2i]=[]
 for q in range(-4,5):
  for row in range(-3,4):
   var point=ArenaGrid.center(q,row)
   if absf(point.x)<=ArenaGrid.BOUNDS.x and absf(point.y)<=ArenaGrid.BOUNDS.y:expected.append(Vector2i(q,row))
 check(ArenaGrid.cells()==expected,"Cached grid retains original cell order")
 for cell in expected:
  var adjacent: Array[Vector2i]=[]
  for other in expected:
   if ArenaGrid.distance(cell,other)==1:adjacent.append(other)
  check(ArenaGrid.neighbors(cell)==adjacent and ArenaGrid.neighbors(cell)==adjacent,"Cached neighbor order preserves BFS tie breaks")
  check(ArenaGrid.neighbors(cell).is_read_only(),"Cached geometry cannot be mutated")
 var h=HeroData.make_hero("thunderbird","perf","Bird",12);h.equipment={"0":"stormorb","1":"galetalons","2":"stormmantle"};h.learned={"0":2,"1":2}
 var foe=HeroData.make_hero("golem","foe","Golem",12);foe.equipment={"0":"ironbark","1":"mirror","2":"colossus"}
 var snapshots=[]
 for silent in [false,true]:
  var sim=BattleSim.new();sim.silent=silent;sim.setup([h],[foe],7392)
  while not sim.finished:sim.step(1.0/30.0)
  snapshots.append([sim.winner,sim.time,sim.rng.state,sim.report_rows()])
 check(snapshots[0]==snapshots[1],"Skipping presentation leaves combat, metrics and RNG identical")
 print("Speedrun performance: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
