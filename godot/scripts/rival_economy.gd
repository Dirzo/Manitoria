class_name RivalEconomy
extends RefCounted
## Saved wallets. Buying development consumes the same component prices as the player.
static func item_cost(id: String) -> int:
 if Forge.is_item(id):
  var total=0
  for component in Forge.ITEMS[id].recipe:total+=int(Forge.info(component).price)
  return total
 return int(Forge.info(id).get("price",0))
static func ensure(club: Dictionary) -> void:
 if club.has("development_gold"):return
 var draft=0
 for h in club.roster:draft+=League.cost(h.sp)
 club.development_gold=maxi(0,League.START_GOLD-draft)
 club.development_earned=0;club.development_spent=0;club.development_purchases=0
 # Existing saves keep previously granted equipment; no retroactive debt.
static func earn(c: Campaign,club: Dictionary,won: bool) -> void:
 ensure(club)
 var amount=TourBalance.match_gold(int(c.state.tour.level),str(c.state.difficulty),won)
 club.development_gold+=amount;club.development_earned+=amount
 develop(c,club)
static func pay(club: Dictionary,amount: int) -> bool:
 if int(club.development_gold)<amount:return false
 club.development_gold-=amount;club.development_spent+=amount;club.development_purchases+=1
 return true
static func develop(c: Campaign,club: Dictionary) -> void:
 ensure(club)
 var heroes=club.roster.filter(func(h):return h.slot>=0)
 var desired={}
 for h in heroes:desired[h.id]=Forge.rival_loadout(h,WorldTour.stage(c),str(c.state.difficulty))
 # Spread equipment across the team instead of filling one hero while leaving others naked.
 for slot in range(4):
  var key=str(slot)
  for h in heroes:
   h.equipment=h.get("equipment",{})
   if not desired[h.id].has(key):continue
   var id=str(desired[h.id][key]);var old=str(h.equipment.get(key,""))
   if id==old or id in h.equipment.values():continue
   var credit=0
   if not old.is_empty():
    credit=item_cost(old)
    if not Forge.is_item(id) or old not in Forge.ITEMS[id].recipe:credit/=2
   var cost=maxi(0,item_cost(id)-credit)
   if pay(club,cost):h.equipment[key]=id
static func prize(c: Campaign,club: Dictionary,place: int) -> void:
 ensure(club)
 var cup=int(c.state.tour.level)
 if int(club.get("development_prize_cup",0))>=cup:return
 club.development_prize_cup=cup
 var amount=int({1:150+WorldTour.stage(c)*15,2:90,3:60,4:40}.get(place,20))
 club.development_gold+=amount;club.development_earned+=amount
 develop(c,club)
