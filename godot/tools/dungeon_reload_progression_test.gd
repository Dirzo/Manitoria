extends SceneTree
var checks = 0
var failures = 0
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok: failures += 1; push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
 HeroData.load_data()
 var c = Campaign.new(); c.new_run("Reload regression",96,731)
 Dungeon.start(c,0)
 c.state.dungeon.instance_choices=[]
 c.state.dungeon.map=[[{"type":"battle","done":true,"links":[0,1]}],[{"type":"checkpoint","done":false,"links":[]},{"type":"checkpoint","done":false,"links":[]}]]
 c.state.dungeon.row=0; c.state.dungeon.col=0
 c.state.dungeon.fight=false;c.state.tour.shop=false;c.state.tour.intermission=false
 for roundtrip in [false,true]:
  if roundtrip: c.state=JSON.parse_string(JSON.stringify(c.state));Dungeon.migrate(c)
  var next = Dungeon.reachable(c)
  check(0 in next and 1 in next,"Next rooms must use integer indices before and after JSON reload")
  check(not Dungeon.busy(c),"An unsettled gate must not be invented by reload")
  var state_before=c.state.duplicate(true)
  check(Dungeon.enter(c,9)=="","Invalid links must remain rejected")
  check(c.state==state_before,"Rejected room must not change state")
  check(Dungeon.enter(c,0)=="checkpoint","A valid linked checkpoint must be enterable after reload")
  c.state=state_before
 c.state.dungeon.loot=["tusk"]
 check(Dungeon.reachable(c).is_empty(),"Outstanding loot must continue to block path selection")
 print("Dungeon JSON reload progression: ",checks," checks; ",failures," failures")
 quit(1 if failures else 0)
