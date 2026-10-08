extends SceneTree
var failures=0
func check(ok: bool,message: String) -> void:
 if not ok:failures+=1;push_error(message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var game=load("res://scripts/main.gd").new();root.add_child(game)
 await create_timer(1.0).timeout
 game.qa="";game.phase="shop";game.render();await process_frame
 var buttons=game.ui.find_children("*","Button",true,false)
 check(buttons.any(func(b):return b.text=="Atlas"),"Atlas is reachable in shop")
 AtlasUI.open(game,{"side":"research"});await create_timer(.4).timeout
 buttons=game.ui.find_children("*","Button",true,false)
 check(buttons.any(func(b):return b.text=="Naga"),"Research champion table renders")
 AtlasUI.items(game,{"side":"research"});await process_frame
 check(game.ui.find_children("*","Label",true,false).any(func(l):return l.text.contains("appearances") and l.text.contains("team wins")),"Item Atlas renders measured associations")
 # Remove the item overlay, leaving the underlying champion table.
 var shades=game.ui.get_children().filter(func(n):return n is ColorRect and n.size.x>1000)
 if shades.size()>1:shades[-1].queue_free()
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("user://atlas-table.png")
 var naga=buttons.filter(func(b):return b.text=="Naga")
 if not naga.is_empty():naga[0].pressed.emit()
 await create_timer(.2).timeout
 check(game.ui.find_children("*","Label",true,false).any(func(l):return l.text.begins_with("Naga ·")),"Champion detail navigation renders")
 # Close modal(s), then open the editable matrix.
 for node in game.ui.get_children():
  if node is ColorRect and node.size.x>1000:node.queue_free()
 await process_frame
 AtlasUI.matrix(game);await create_timer(.3).timeout
 buttons=game.ui.find_children("*","Button",true,false)
 var save_rule=buttons.filter(func(b):return b.text=="Save rules")
 check(save_rule.size()==1,"Post-draft plan editor renders")
 if not save_rule.is_empty():save_rule[0].pressed.emit()
 await process_frame
 check(game.campaign.state.get("decision_matrix",{}).size()==game.campaign.lineup().size(),"Plan save stores rules for the drafted team")
 AtlasUI.matrix(game);await create_timer(.3).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("user://decision-matrix.png")
 buttons=game.ui.find_children("*","Button",true,false)
 var preview=buttons.filter(func(b):return b.text=="Preview saved plan")
 if not preview.is_empty():preview[0].pressed.emit()
 await process_frame
 check(game.ui.find_children("*","Button",true,false).any(func(b):return b.text=="Apply saved plan"),"Opponent-based preview has explicit apply")
 game.queue_free();await process_frame
 print("RUN ATLAS UI: 7 checks, %d failures"%failures);quit(1 if failures else 0)
