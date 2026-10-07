extends SceneTree
var failures=0
func check(ok: bool,msg: String) -> void:
 if not ok:failures+=1;push_error(msg)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var game=load("res://scripts/main.gd").new();get_root().add_child(game)
 await create_timer(1).timeout;game.qa=""
 var c=game.campaign;c.state.tour.shop=false;c.state.tour.intermission=true;c.state.gold=6000
 game.phase="hub";game.tab="market";game.render()
 await create_timer(.5).timeout
 var buttons=game.ui.find_children("*","Button",true,false).filter(func(b):return b.text.begins_with("Buy copy"))
 check(buttons.size()==c.state.roster.size(),"Market shows a copy offer per owned champion")
 var h=c.state.roster[0];var gold=int(c.state.gold)
 buttons[0].pressed.emit()
 await create_timer(.3).timeout
 check(ChampionStars.copies(h)==2 and c.state.gold==gold-League.cost(h.sp),"Real market button buys the selected champion's copy")
 buttons=game.ui.find_children("*","Button",true,false).filter(func(b):return b.text.begins_with("Buy copy"))
 buttons[0].pressed.emit()
 await create_timer(.3).timeout
 check(ChampionStars.tier(h)==2,"Second purchase promotes original to two stars")
 await RenderingServer.frame_post_draw
 get_root().get_texture().get_image().save_png("user://champion-stars-market.png")
 game.tab="roster";game.render();await create_timer(.4).timeout
 var labels=game.ui.find_children("*","Label",true,false)
 check(labels.any(func(l):return l.text==ChampionStars.label(h)),"Roster displays persisted star progress")
 await RenderingServer.frame_post_draw
 get_root().get_texture().get_image().save_png("user://champion-stars-roster.png")
 c.state.tour.intermission=false;c.state.tour.shop=true;c.state.gold=6000;h.copies=2
 for key in HeroData.ROLL_KEYS:h.rolls[key]=HeroData.roll_floor(h.sp)
 game.selected_id=h.id;game.phase="shop";game.render();await create_timer(.3).timeout
 var copy=game.ui.find_child("ShopChampionCopy",true,false)
 check(copy!=null and not copy.disabled,"Shop exposes selected champion copy offer")
 check(not c.recruit(c.state.market[0].id),"Shop copies do not unlock new recruitment")
 copy.pressed.emit();await create_timer(.2).timeout
 var hex=game.ui.find_child("ShopChampionStatHex",true,false)
 check(ChampionStars.tier(h)==2 and hex!=null and hex.reveal>0 and hex.reveal<1,"Shop purchase animates the stat hex through star promotion")
 check(hex.improvement.hp>0 and hex.prior_values.hp<=hex.values.hp,"Hex includes previous outline and real improvement")
 await create_timer(.8).timeout;await RenderingServer.frame_post_draw
 get_root().get_texture().get_image().save_png("user://champion-copy-shop.png")
 var offered=c.copy_offer(h)
 check(c.reroll_shop() and offered!=c.copy_offer(h),"Shop reroll refreshes champion stats as well as items")
 game.queue_free();await process_frame
 print("Champion stars UI: 9 checks, ",failures," failures")
 quit(1 if failures else 0)
