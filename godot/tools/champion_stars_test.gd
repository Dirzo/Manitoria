extends SceneTree
var checks=0
var failures=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func _initialize() -> void:
 HeroData.load_data()
 for sp in HeroData.species:
  var hero=HeroData.make_hero(sp,"retired-"+sp,sp,9)
  hero.slot=5;hero.evolution=Evolutions.options(sp)[0];hero.equipment={"0":"stormorb"}
  var base=HeroData.stats(hero);var power=HeroData.power(hero)
  for copies in [1,2,3,6]:
   hero.copies=copies
   check(HeroData.stats(hero)==base,"Legacy copies cannot alter combat: "+sp)
   check(HeroData.power(hero)==power,"Legacy copies cannot alter power: "+sp)
   check(not ChampionStars.label(hero).contains("star") and not ChampionStars.label(hero).contains("copies"),"Progression label shows level")
  var c=Campaign.new();c.new_run("Retirement QA",95,73002,"Standard");c.state.speedrun_memory=true;c.state.roster=[hero];c.state.gold=10000
  for shop in [true,false]:
   c.state.tour.shop=shop
   check(not c.copy_purchases_open() and not c.buy_champion_copy(hero.id),"Copy purchases disabled in every phase")
   check(int(c.state.gold)==10000,"Copy requests never spend gold")
  c.ensure_management();check(not hero.has("copies") and not hero.has("copy_feedback"),"Legacy counters stripped on load")
 print("Copy retirement: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
