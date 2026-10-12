extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var game=load("res://scripts/main.gd").new();root.add_child(game)
 game.qa="";game.set_process(false)
 await create_timer(.4).timeout
 # Read only: the original profile is never selected as APPDATA and no choose/save call runs.
 var path="C:/Users/cmayb/AppData/Roaming/Godot/app_userdata/Manitoria — The Living Arena/campaign_1.json"
 var state=JSON.parse_string(FileAccess.get_file_as_string(path))
 if not state is Dictionary:push_error("Saved campaign unavailable");quit(1);return
 game.campaign.state=state.duplicate(true)
 for h in game.campaign.state.roster:HeroData.migrate_progression(h)
 game.phase="upgrade";game.render()
 await create_timer(1.0).timeout
 var pending=game.campaign.pending_heroes()
 if pending.is_empty():push_error("No saved pending choices");quit(1);return
 var h=pending[0]
 var choices=game.ui.find_children("ChooseSkill*","Button",true,false)
 var visible=choices.size()==h.pending[0].size() and choices.all(func(b):return not b.disabled and root.get_visible_rect().encloses(b.get_global_rect()))
 print("Saved upgrade: species=",h.sp,"; offers=",h.pending[0].map(func(c):return [c.type,c.key,c.rarity]),"; all choices reachable=",visible)
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../../tools/saved-upgrade.png"))
 game.sound.stop_all();game.queue_free();await process_frame
 quit(0 if visible else 1)
