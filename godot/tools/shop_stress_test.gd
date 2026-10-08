extends SceneTree
var checks=0
var failures=0
func check(ok: bool,msg: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(msg)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var game=load("res://scripts/main.gd").new();get_root().add_child(game)
 await create_timer(.8).timeout;game.qa=""
 var carousel=game.ui.find_child("ChampionCarousel",true,false);var instance=carousel.get_instance_id()
 var models=carousel.entries.map(func(e):return e.root.get_instance_id())
 for i in range(30):
  var poses=carousel.entries.map(func(e):return e.root.position)
  carousel.rotate(1 if i%3 else -1)
  carousel=game.ui.find_child("ChampionCarousel",true,false)
  check(carousel.get_instance_id()==instance,"Rotation retains one 3D stage")
  for j in range(poses.size()):check(carousel.entries[j].root.position.is_equal_approx(poses[j]),"Interrupted rotation starts from its current pose")
  check(carousel.entries.map(func(e):return e.root.get_instance_id())==models,"Rotation retains all champion models")
  await create_timer(.04).timeout
 await create_timer(.5).timeout
 var chosen=carousel.entries.filter(func(e):return e.offset==0)[0]
 check(chosen.root.position.is_equal_approx(ChampionCarousel.pose(0).position),"Rapid rotations settle in the center")
 check(chosen.target.target_hero==game.selected_id,"Visible selection matches the item recipient")
 game.campaign.state.gold=10000
 var hero=GearUI.selected(game);hero.level=10;hero.evolution=Evolutions.options(hero.sp)[0]
 hero.equipment={"0":"stormorb","1":"archmage"};game.render();await process_frame
 check(game.ui.find_child("ChampionCarousel",true,false).get_instance_id()==instance,"Item changes preserve the stage")
 var labels=game.ui.find_children("*","Label",true,false)
 check(game.ui.find_child("ShopChampionCopy",true,false)==null,"Champion-copy market removed")
 check(labels.any(func(l):return l.text==ChampionStars.evolution_label(hero)),"Named evolution remains visible")
 check(HeroData.item_slots(hero)==4,"Evolution unlocks the correct equipment slot")
 await create_timer(1).timeout;await RenderingServer.frame_post_draw
 get_root().get_texture().get_image().save_png("user://shop-stress-evolved-073.png")
 game.sound.stop_all();game.queue_free();await process_frame
 print("Shop rotation/purchase stress: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
