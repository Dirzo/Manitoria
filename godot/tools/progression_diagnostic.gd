extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 HeroData.load_data()
 var game = load("res://scripts/main.gd").new(); root.add_child(game)
 game.set_process(false)
 var path = "C:/Users/cmayb/AppData/Roaming/Godot/app_userdata/Manitoria — The Living Arena/campaign_1.json"
 game.campaign.state = JSON.parse_string(FileAccess.get_file_as_string(path))
 var c = game.campaign
 print("busy=",Dungeon.busy(c)," reachable=",Dungeon.reachable(c)," int membership=",0 in Dungeon.reachable(c)," float membership=",0.0 in Dungeon.reachable(c))
 game.phase="hub";game.tab="overview";game.render()
 await process_frame
 print("room buttons=",game.ui.find_children("DungeonRoom_*","",true,false).map(func(n):return [n.name,n.disabled]))
 quit()
