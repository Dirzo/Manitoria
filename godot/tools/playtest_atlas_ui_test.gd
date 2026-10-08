extends SceneTree
var failures=0
var checks=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func close_modal(game: Node) -> void:
 for node in game.ui.get_children():
  if node is ColorRect and node.size.x>1000:node.queue_free()
func labels(game: Node) -> Array:return game.ui.find_children("*","Label",true,false)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var game=load("res://scripts/main.gd").new();root.add_child(game)
 await create_timer(1.0).timeout;game.qa=""
 AtlasUI.open(game);await create_timer(.3).timeout
 check(game.ui.find_children("*","Button",true,false).any(func(b):return b.text=="Naga"),"Default Atlas is populated before any personal match")
 check(labels(game).any(func(l):return l.text.contains("8,192 audited")),"Full audit provenance displayed")
 await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("user://playtest-tier.png")
 close_modal(game);await process_frame
 PlaytestAtlas.open(game,{"dataset":"post","cup":3},"champion","naga")
 await create_timer(.2).timeout
 check(labels(game).any(func(l):return l.text.begins_with("Naga ·")),"Filtered champion detail renders")
 check(labels(game).any(func(l):return l.text.contains("162 appearances")),"Champion drill-down retains real filtered data")
 check(labels(game).any(func(l):return l.text=="COMPLETE ABILITY CATALOG"),"Champion kit catalog")
 check(labels(game).any(func(l):return l.text.begins_with("OPPONENT MATCHUPS")),"Champion matchup table")
 await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("user://playtest-champion.png")
 close_modal(game);await process_frame
 PlaytestAtlas.open(game,{"dataset":"pre"},"items");await create_timer(.2).timeout
 check(game.ui.find_children("*","Button",true,false).any(func(b):return b.text=="Saint's Rosary"),"Full item screen includes named items")
 await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("user://playtest-items.png")
 close_modal(game);await process_frame
 PlaytestAtlas.open(game,{"dataset":"post"},"item","rosary");await create_timer(.2).timeout
 check(labels(game).any(func(l):return l.text.contains("48 independent mirrored setups")),"Controlled item sample and interval detail")
 close_modal(game);await process_frame
 PlaytestAtlas.open(game,{"dataset":"post","search":"Naga"},"skills");await create_timer(.2).timeout
 check(game.ui.find_children("*","Button",true,false).any(func(b):return b.text.contains("Tidal Ward")),"Global skill browser")
 close_modal(game);await process_frame
 PlaytestAtlas.open(game,{},"balance");await create_timer(.2).timeout
 check(labels(game).any(func(l):return l.text.begins_with("Naga ·") and l.text.contains("→")),"Before/after balance results")
 var export_path=PlaytestDatabase.export_database()
 check(not export_path.is_empty() and FileAccess.file_exists(export_path+"/raw-audit.zip"),"Database exports from game resources")
 close_modal(game);await process_frame
 AtlasUI.open(game,{"side":"player"});await create_timer(.2).timeout
 check(labels(game).any(func(l):return l.text.begins_with("RUN ATLAS")),"Personal data remains separate and reachable")
 game.queue_free();await process_frame
 print("PLAYTEST ATLAS UI: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
