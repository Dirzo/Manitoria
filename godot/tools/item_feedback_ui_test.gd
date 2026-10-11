extends SceneTree
var failures=0
func check(ok: bool,msg: String) -> void:
 if not ok:failures+=1;push_error(msg)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var game=load("res://scripts/main.gd").new();get_root().add_child(game)
 await create_timer(1).timeout;game.qa=""
 check(game.sim!=null and game.arena!=null,"Arena feedback integration starts")
 var u=game.sim.units[0];var target=game.sim.units[5]
 var played=game.sound.played_cues
 ItemFeedback.signal_effect(game.sim,u,"thundercleaver",target,"proc")
 check(game.sound.played_cues==played,"Activation keeps audio silent while retaining visual feedback")
 check(game.arena.vfx.count()>0,"Activation reaches the real arena VFX")
 await create_timer(.18).timeout
 game.paused=true
 var count_before=game.arena.vfx.count();var age=game.arena.vfx.live[-1].age
 await create_timer(.3).timeout
 check(game.arena.vfx.count()==count_before and game.arena.vfx.live[-1].age==age,"Item effect freezes with paused combat")
 if DisplayServer.get_name() != "headless":
  await RenderingServer.frame_post_draw
  get_root().get_texture().get_image().save_png("res://../../item-feedback-arena.png")
 game.sound.set_combat_paused(true);played=game.sound.played_cues
 game.sound.battle_event({"type":"item_feedback","item_id":"bastion","stage":"proc","uid":u.uid},u)
 check(game.sound.played_cues==played,"Paused combat suppresses item audio")
 game.sound.stop_all();game.queue_free();await process_frame
 print("Item arena/audio UI: 5 checks, ",failures," failures")
 quit(1 if failures else 0)
