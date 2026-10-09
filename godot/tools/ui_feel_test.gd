extends SceneTree
## UI feel: buttons react to hover and press, and tooltips appear as floating text boxes.
## Run rendered: --script res://tools/ui_feel_test.gd -- --qa=menu
var failures=0
func check(ok: bool,msg: String) -> void:
 if not ok:failures+=1;push_error(msg)
func _initialize() -> void:call_deferred("run")
func hover(game: Node, c: Control) -> void:
 var p=game.get_viewport().get_final_transform()*c.get_global_rect().get_center()
 var mm=InputEventMouseMotion.new();mm.position=p;mm.global_position=p
 game.get_viewport().push_input(mm)
func run() -> void:
 var game=load("res://scripts/main.gd").new();root.add_child(game)
 await create_timer(1.2).timeout;game.qa=""
 var feel: UIFeel=game.get_node("UIFeel")
 check(feel!=null,"UI feel is attached")
 check(game.ui.find_child("DungeonMenuButton",true,false)!=null,"Title screen features the dungeon")
 var cta: Control=game.ui.find_child("MusicMedallion",true,false)
 hover(game,cta);await process_frame;await process_frame
 await create_timer(0.7).timeout
 check(cta.scale.x>1.005,"Hovered button lifts (scale %.3f)"%cta.scale.x)
 check(feel.tip.visible and feel.tip.modulate.a>0.5,"Hovering shows a floating text box")
 check(feel.tip_text.text.contains("[b]"),"Tooltip has a gold title line")
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("user://ui_feel_tooltip.png")
 var away=InputEventMouseMotion.new();away.position=Vector2(40,880);away.global_position=away.position;game.get_viewport().push_input(away)
 await create_timer(0.4).timeout
 check(not feel.tip.visible,"Tooltip hides when the cursor leaves")
 check(cta.scale.x<1.01,"Button settles back")
 check(UIFeel.format("Stun Strike\nDeals 150% damage and stuns for 1.5s.").contains("ffd98a"),"Numbers are highlighted")
 print("UI FEEL: 8 checks, ",failures," failures")
 quit(1 if failures else 0)
