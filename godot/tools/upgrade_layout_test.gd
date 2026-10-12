extends SceneTree
var checks=0
var failures=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var game=load("res://scripts/main.gd").new();root.add_child(game)
 game.qa="";game.set_process(false)
 await create_timer(.4).timeout
 var h=HeroData.make_hero("cyclops","qa","Cyclops",6)
 h.learned={"1":2,"10":1,"6":1}
 var rng=RandomNumberGenerator.new();rng.seed=48
 var offers=HeroData.choices(h,true,rng)
 offers[0]=HeroData.legendary_card(h.sp)
 for c in offers:c.description+=" Detailed inspection text to exercise overflowing content.".repeat(12)
 h.pending=[offers];h.rewards=[{"level":6,"won":true,"seed":48}]
 game.campaign.state.roster=[h];game.phase="upgrade"
 for resolution in [Vector2i(1280,720),Vector2i(1440,810),Vector2i(1920,1080),Vector2i(1680,720)]:
  root.size=resolution;game.render()
  await create_timer(1.0).timeout
  print("Requested resolution: ",resolution,"; actual window: ",root.size,"; logical viewport: ",root.get_visible_rect())
  var visible_rect=root.get_visible_rect()
  for i in range(offers.size()):
   var b=game.ui.find_child("ChooseSkill%d"%i,true,false) as Button
   check(b!=null and b.is_visible_in_tree() and not b.disabled,"Every choice is available at %s"%resolution)
   if b:
    check(visible_rect.encloses(b.get_global_rect()),"Choice stays inside logical viewport at %s: %s"%[resolution,b.get_global_rect()])
    check(b.get_global_rect().size.y>=44,"Choice retains a usable hit target")
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../../tools/upgrade-%dx%d.png"%[resolution.x,resolution.y]))
  var preview=AbilityPreview.new();preview.game=game;preview.hero=h.duplicate(true);preview.card=offers[0].duplicate(true);game.ui.add_child(preview);preview.build()
  await create_timer(.5).timeout
  var close_button=preview.find_children("*","Button",true,false)[0] as Button
  check(visible_rect.encloses(close_button.get_global_rect()),"Preview close action stays visible")
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../../tools/preview-%dx%d.png"%[resolution.x,resolution.y]))
  while preview.demo.elapsed<2.3:await process_frame
  check(preview.demo.totals().damage>0,"Offensive legendary preview resolves damage after its telegraph")
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../../tools/legendary-impact-%dx%d.png"%[resolution.x,resolution.y]))
  preview.close();await process_frame
 root.size=Vector2i(1280,720)
 var tank=HeroData.make_hero("zaratan","tank","Zaratan",6)
 var defensive=AbilityPreview.new();defensive.game=game;defensive.hero=tank;defensive.card=HeroData.legendary_card(tank.sp);game.ui.add_child(defensive);defensive.build()
 while defensive.demo.elapsed<2.3:await process_frame
 check(defensive.demo.totals().shield>0,"Defensive legendary preview visibly applies area protection")
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../../tools/legendary-tank.png"))
 defensive.close();await process_frame
 game.phase="upgrade";game.render();await create_timer(.5).timeout
 var before=h.pending.size()
 (game.ui.find_child("ChooseSkill0",true,false) as Button).pressed.emit()
 await create_timer(.2).timeout
 check(h.pending.size()==before-1 and h.learned.has("100"),"Choosing visible legendary clears the pending gate and learns the fresh skill")
 game.phase="menu";game.render();await create_timer(.3).timeout
 game.sound.stop_all();game.queue_free();await process_frame
 print("Upgrade layout: ",checks," checks; ",failures," failures")
 quit(1 if failures else 0)
