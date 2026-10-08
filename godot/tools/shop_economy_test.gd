extends SceneTree
var checks=0
var failures=0
func check(ok: bool,msg: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(msg)
func _initialize() -> void:
 HeroData.load_data()
 for difficulty in ["Keeper","Standard","Champion"]:
  var previous=0
  for cup in range(1,6):
   var win=TourBalance.match_gold(cup,difficulty,true);var loss=TourBalance.match_gold(cup,difficulty,false)
   check(win>110 and loss>75 and win-loss==35,"More gold and bounded win advantage")
   check(win>=previous and (cup==1 or win-previous==10),"Smooth income ramp")
   check(loss>=135 and loss>=Forge.info("fang").price,"Loss income supports meaningful purchases")
   check(TourBalance.match_gold(cup,"Keeper",true)>=TourBalance.match_gold(cup,"Standard",true) and TourBalance.match_gold(cup,"Standard",true)>=TourBalance.match_gold(cup,"Champion",true),"Difficulty economy ordering")
   previous=win
 for difficulty in ["Keeper","Standard","Champion"]:
  for cup in range(6,11):
   check(TourBalance.level(cup,difficulty)<=20,"Extended rival levels cap at 20")
   check(TourBalance.quality(cup,0,difficulty)>TourBalance.quality(cup-1,0,difficulty),"Extended quality ramps smoothly")
   check(TourBalance.match_gold(cup,difficulty,true)-TourBalance.match_gold(cup-1,difficulty,true)==10,"Extended income grows ten per cup")
 print("Shop economy/roll balance: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
