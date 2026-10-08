extends SceneTree
## 0.73 retired champion copies. The market and the shop must no longer offer them.
## Run rendered with an isolated user-data folder: -- --qa=tour_shop
var failures=0
func check(ok: bool,msg: String) -> void:
 if not ok:failures+=1;push_error(msg)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var game=load("res://scripts/main.gd").new();get_root().add_child(game)
 await create_timer(1).timeout;game.qa=""
 var c=game.campaign
 check(c!=null and not c.state.is_empty() and c.state.has("tour"),"QA tour campaign loads (run with --qa=tour_shop)")
 if failures:print("Copy retirement UI: 4 checks, ",failures," failures");quit(1);return
 c.state.tour.shop=false;c.state.tour.intermission=true;c.state.gold=6000
 game.phase="hub";game.tab="market";game.render()
 await create_timer(.5).timeout
 var copies=game.ui.find_children("*","Button",true,false).filter(func(b):return b.text.begins_with("Buy copy"))
 check(copies.is_empty(),"Market shows no copy offers")
 c.state.tour.intermission=false;c.state.tour.shop=true
 game.selected_id=c.state.roster[0].id;game.phase="shop";game.render();await create_timer(.3).timeout
 check(game.ui.find_child("ShopChampionCopy",true,false)==null,"Shop shows no copy offer")
 var gold=int(c.state.gold)
 check(not c.buy_champion_copy(c.state.roster[0].id) and int(c.state.gold)==gold,"Copy purchase refused without charging gold")
 print("Copy retirement UI: 4 checks, ",failures," failures")
 quit(1 if failures else 0)
