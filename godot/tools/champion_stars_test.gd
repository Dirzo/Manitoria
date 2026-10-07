extends SceneTree
var checks=0
var failures=0
func check(ok: bool,msg: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(msg)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var c=Campaign.new();c.new_run("Stars QA",95,982,"Champion")
 var h=HeroData.make_hero("thunderbird","stars","Kaboom",9)
 h.slot=5;h.learned={"6":2,"7":3,"9":1};h.evolution="thunderbird:2";h.equipment={"0":"stormorb"};h.price=450
 c.state.roster=[h];c.state.headliner=h.id;c.state.gold=10000
 check(not c.buy_champion_copy(h.id) and c.state.gold==10000,"Protect founding squad budget before four starters")
 c.state.tour.intermission=true
 var original=h.duplicate(true);var base=HeroData.stats(h);var price=League.cost(h.sp)
 check(ChampionStars.tier(h)==1,"Legacy saves default to one star")
 for copy in range(2,7):
  var gold=int(c.state.gold)
  check(c.buy_champion_copy(h.id),"Purchase and save copy %d"%copy)
  check(ChampionStars.copies(h)==copy,"Original included in copy counter")
  check(c.state.gold==gold-price,"One tier-price payment per copy")
  check(c.state.roster.size()==1,"Copies don't occupy roster or formation slots")
  check(h.id==original.id and h.name==original.name and h.learned==original.learned and h.equipment==original.equipment and h.evolution==original.evolution and h.level==original.level and h.xp==original.xp,"Preserve champion identity and build")
  check(ChampionStars.tier(h)==(3 if copy==6 else 2 if copy>=3 else 1),"Three / six thresholds")
  for key in HeroData.ROLL_KEYS:check(int(h.rolls[key])>=int(original.rolls[key]),"Copies never lower a roll")
  var reference=h.duplicate(true);reference.copies=1;base=HeroData.stats(reference)
  var stats=HeroData.stats(h)
  check(is_equal_approx(stats.hp/base.hp,ChampionStars.health(h)),"Star health multiplier")
  for key in ["attack","ability_power","skill_base"]:check(is_equal_approx(stats[key]/base[key],ChampionStars.damage(h)),"Independent damage multiplier: "+key)
  check(is_equal_approx(stats.hp/stats.base_hp,base.hp/base.base_hp),"Health scaling isn't counted twice")
  check(stats.interval==base.interval and stats.range==base.range and stats.armor==base.armor,"Stars preserve speed, range and armor tradeoffs")
 var gold=int(c.state.gold)
 check(not c.buy_champion_copy(h.id) and c.state.gold==gold,"Three-star cap cannot spend gold")
 var loaded=JSON.parse_string(FileAccess.get_file_as_string(Campaign.save_path(95)))
 check(loaded.roster[0].copies==6 and loaded.roster[0].copy_gold==5*price,"Copies and cost survive save/load")
 check(c.sell_price(h)==roundi((450+5*price)*.5),"Sell refund includes paid copies")
 h.copies=1;c.state.tour.cup_started=true;c.state.tour.intermission=false
 check(not c.buy_champion_copy(h.id) and c.state.gold==gold,"Cup roster lock covers copies")
 check(not c.refresh_market() and c.state.gold==gold,"Cup roster lock covers refresh")
 c.state.tour.shop=true
 check(c.buy_champion_copy(h.id),"Shop permits owned champion improvement inside a cup")
 c.state.tour.shop=false;h.copies=1
 c.state.tour.intermission=true;c.state.gold=price-1
 check(not c.buy_champion_copy(h.id) and h.copies==1,"Insufficient funds cannot grant a copy")
 c.state.gold=price
 for i in range(11):c.state.roster.append(HeroData.make_hero("golem","bench%d"%i,"Bench %d"%i,1))
 check(c.buy_champion_copy(h.id) and c.state.roster.size()==12,"Copies work at the roster cap")
 check(not c.buy_champion_copy("not-owned"),"Cannot buy copies for another club")
 # Exercise the rollback path using an unwritable destination directory as the save filename.
 c.state.gold=price;c.state.slot=999
 var blocked=Campaign.save_path(999)+".tmp";DirAccess.make_dir_recursive_absolute(blocked)
 var previous=c.state.duplicate(true)
 check(not c.buy_champion_copy(h.id),"Failed save rejects purchase")
 check(c.state.gold==previous.gold and c.state.roster[0].copies==previous.roster[0].copies and c.state.news==previous.news,"Failed save restores gold, copies and news")
 DirAccess.remove_absolute(blocked)
 var one=original.duplicate(true);var two=original.duplicate(true);two.copies=3;two.id="two"
 var sim=BattleSim.new();sim.silent=true;sim.setup([one],[two],982,1.0)
 var first=sim.units[0];var upgraded=sim.units[1]
 check(is_equal_approx(upgraded.max_hp/first.max_hp,1.18),"Stars reach actual combat health")
 check(is_equal_approx(upgraded.attack/first.attack,1.12) and is_equal_approx(upgraded.ability_power/first.ability_power,1.12),"Stars reach actual combat AD and AP")
 for effect in ["stormcall","maul","ward","regrowth"]:
  check(is_equal_approx(SkillScaling.power(upgraded,effect)/SkillScaling.power(first,effect),1.12),"Damage, armor and healing channels scale once: "+effect)
 print("Champion stars: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
