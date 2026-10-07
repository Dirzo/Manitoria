extends SceneTree
var failures=0
func check(ok: bool,msg: String) -> void:
 if not ok:failures+=1;push_error(msg)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var game=load("res://scripts/main.gd").new();get_root().add_child(game)
 await create_timer(.8).timeout;game.qa=""
 var hero=game.campaign.state.roster[0];hero.sp="arachne";hero.level=5;hero.learned={};hero.rewards=[]
 var a=HeroData.learned_ability("arachne",2)
 var offer={"type":"ability","key":"2","name":a.name,"description":a.description,"summary":a.summary,"rarity":"Rare","bonus":1.1}
 hero.pending=[[offer]];game.phase="upgrade";game.render();await process_frame
 var buttons=game.ui.find_children("*","Button",true,false).filter(func(b):return b.text=="Learn ability")
 check(buttons.size()==1,"New skill has a Learn ability action")
 if buttons.size()==1:buttons[0].pressed.emit()
 await create_timer(2.1).timeout
 var previews=game.ui.get_children().filter(func(n):return n is AbilityPreview)
 check(previews.size()==1,"Learning opens a skill celebration replay")
 check(hero.learned.get("2",0)==1,"Actual learned skill remains rank one")
 if not previews.is_empty():
  var preview=previews[0]
  check(preview.unlocked and preview.demo.hero.learned.get("2",0)==1,"Replay is marked unlocked and applies the skill once")
  check(preview.demo.cast_started and preview.arena.vfx.count()>0,"Celebration casts the real skill and shows its VFX")
  await RenderingServer.frame_post_draw
  get_root().get_texture().get_image().save_png("res://../../skill-unlock-preview.png")
  preview.close();await process_frame
  check(hero.learned.get("2",0)==1,"Closing replay does not alter campaign progress")
 print("Skill unlock UI: 6 checks, ",failures," failures")
 game.sound.stop_all();game.queue_free();await process_frame;quit(1 if failures else 0)
