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
 for i in range(500):
  var id="economy%d"%i
  for difficulty in ["Keeper","Standard","Champion"]:
   var prior=1
   for cup in range(1,6):
    var copies=TourBalance.rival_copies(cup,difficulty,id)
    check(copies in [1,3,6] and copies>=prior,"Legal, monotone rival stars")
    check(cup>1 or copies==1,"No first-cup enemy star wall")
    check(copies<6 or cup>=3,"Three-star rivals need late-game income")
    prior=copies
 var h=HeroData.make_hero("golem","merge","Merge",1);h.rolls={"hp":30,"attack":10,"armor":20,"haste":15,"speed":5,"potency":31}
 var changed=ChampionStars.merge(h,{"hp":1,"attack":25,"armor":20,"haste":18,"speed":31,"potency":3})
 check(h.rolls=={"hp":30,"attack":25,"armor":20,"haste":18,"speed":31,"potency":31},"Copies replace only weaker rolls")
 check(changed==["attack","haste","speed"],"Improvement feedback lists actual changed stats")
 var first=ChampionStars.offer(h,"shop-seed")
 check(first==ChampionStars.offer(h,"shop-seed"),"Displayed offer remains stable until purchase or reroll")
 h.copies=2
 check(first!=ChampionStars.offer(h,"shop-seed"),"A purchase generates a new offer")
 print("Shop economy/roll balance: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
