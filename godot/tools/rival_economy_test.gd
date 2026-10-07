extends SceneTree
var checks=0
var failures=0
func check(ok: bool,msg: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(msg)
func _initialize() -> void:
 HeroData.load_data()
 for case in range(9):
  var difficulty=["Keeper","Standard","Champion"][case%3]
  var c=Campaign.new();c.new_run("Rival wallets",94,831+int(case/3),difficulty)
  c.state.roster=[HeroData.make_hero(League.tiers().Legendary[0],"mine","Mine",1)];c.draft_rivals()
  var opening={}
  for cl in c.state.clubs:
   RivalEconomy.ensure(cl);opening[cl.name]=cl.development_gold
  for cup in range(1,6):
   c.state.tour.level=cup;WorldTour.outfit_clubs(c)
   for cl in c.state.clubs:
    for bout in range(4):RivalEconomy.earn(c,cl,bout<2)
    RivalEconomy.prize(c,cl,4)
    check(cl.development_gold>=0,"Rivals cannot spend into debt")
    check(opening[cl.name]+cl.development_earned==cl.development_gold+cl.development_spent,"All rival purchases are funded")
    var before=cl.duplicate(true);RivalEconomy.prize(c,cl,4)
    check(cl==before,"Cup prizes cannot be claimed twice")
    RivalEconomy.develop(c,cl)
    check(cl==before,"Viewing the squad grants no free rolls, items or stars")
    for h in cl.roster:
     check(h.equipment.size()<=HeroData.item_slots(h),"Legal rival equipment slots")
     check(ChampionStars.copies(h)<=6,"Rival six-copy cap")
     var unique={}
     for id in h.equipment.values():check(Forge.valid(id),"Valid rival equipment");unique[id]=true
     check(unique.size()==h.equipment.size(),"No duplicate equipped items")
  check(c.save(),"Rival wallet saves with the campaign")
  var loaded=JSON.parse_string(FileAccess.get_file_as_string(Campaign.save_path(94)))
  check(loaded.clubs[0].development_gold==c.state.clubs[0].development_gold,"Saved wallet preserves balance")
 print("Rival gold/development: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
