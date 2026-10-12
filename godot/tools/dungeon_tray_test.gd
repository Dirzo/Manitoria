extends SceneTree
var checks=0
var failures=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func _initialize() -> void:call_deferred("run")
func drawer(game: Node) -> DungeonTeamTray:return game.ui.find_child("DungeonTeamTray",true,false) as DungeonTeamTray
func click(game: Node,id: String) -> void:
 var b=game.ui.find_child(id,true,false) as Button
 check(b!=null,"Action exists: "+id)
 if b:
  var press=InputEventMouseButton.new();press.button_index=MOUSE_BUTTON_LEFT;press.pressed=true;press.position=b.get_global_rect().get_center();press.global_position=press.position;root.push_input(press,true)
  var release=press.duplicate();release.pressed=false;root.push_input(release,true)
 await process_frame
func run() -> void:
 var game=load("res://scripts/main.gd").new();root.add_child(game);game.qa="";game.set_process(false)
 await create_timer(.5).timeout
 var c=game.campaign;c.new_run("Tray QA",96,733)
 c.state.roster=[]
 for i in range(5):
  var h=HeroData.make_hero(["cyclops","zaratan","minotaur","unicorn","harpy"][i],"tray%d"%i,"Champion %d"%(i+1),6);h.slot=Campaign.FORMATION[i];c.state.roster.append(h)
 c.state.headliner="tray0";Dungeon.start(c,0);Dungeon.choose_instance(c,c.state.dungeon.instance_choices[0])
 c.state.inventory=[Forge.COMPONENT_ORDER[0],Forge.COMPONENT_ORDER[1],Forge.COMPONENT_ORDER[2]]
 game.selected_id="tray0";game.phase="hub";game.tab="overview";game.render()
 await create_timer(.4).timeout
 check(drawer(game)!=null,"Dungeon map has a champion drawer")
 var tray=drawer(game);tray.set_process(false);tray.set_open(false)
 await create_timer(.3).timeout
 check(tray.frame.position.y==856,"Collapsed drawer leaves the bottom handle visible")
 var event=InputEventMouseMotion.new();event.position=Vector2(800,875);event.global_position=event.position;root.push_input(event,true)
 await process_frame
 print("Hover pointer=",tray.pointer_position,"; drawer=",tray.frame.get_global_rect())
 tray._process(.1);await create_timer(.3).timeout
 check(tray.opened,"Hovering the bottom opens the drawer")
 var out=InputEventMouseMotion.new();out.position=Vector2(800,200);out.global_position=out.position;root.push_input(out,true)
 tray._process(.6);await create_timer(.3).timeout
 check(not tray.opened,"Leaving the drawer closes it after the grace period")
 root.push_input(event,true);tray._process(.1);await create_timer(.3).timeout
 check(tray.opened,"Returning to the bottom reopens the drawer")
 await click(game,"TeamTrayPin")
 root.push_input(out,true);tray._process(1.0)
 check(tray.pinned and tray.opened,"Pin keeps the drawer open after the pointer leaves")
 game.render();await create_timer(.2).timeout
 for resolution in [Vector2i(1280,720),Vector2i(1440,810),Vector2i(1920,1080),Vector2i(1680,720)]:
  root.size=resolution;await create_timer(.3).timeout
  tray=drawer(game)
  check(root.get_visible_rect().encloses(tray.frame.get_global_rect()),"Expanded drawer stays inside canvas at "+str(resolution))
  for id in ["TrayDetails","TrayTactics","TrayFormation0","TrayForgeReady"]:
   var b=game.ui.find_child(id,true,false) as Button
   check(b!=null and tray.frame.get_global_rect().encloses(b.get_global_rect()),"Usable drawer action: "+id)
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../../tools/dungeon-tray-%dx%d.png"%[resolution.x,resolution.y]))
 await click(game,"TrayHero_tray1")
 check(game.selected_id=="tray1" and drawer(game).opened,"Champion selection persists with drawer open")
 var component=str(c.state.inventory[2])
 await click(game,"Bag_"+component)
 check(c.hero_by_id("tray1").equipment.values().has(component),"Clicking inventory equips the selected champion")
 var equipment=c.hero_by_id("tray1").equipment.duplicate(true)
 var payload={"kind":"equipped","owner":"tray1","slot":equipment.keys()[0],"id":component}
 check(GearUI.apply_drop(game,payload,"tray0"),"Existing drag/drop transfer works from drawer")
 await process_frame
 check(c.hero_by_id("tray0").equipment.values().has(component),"Transfer changes the actual owner")
 var before=c.state.inventory.size();await click(game,"TrayForgeReady")
 check(c.state.inventory.size()==before-1 and c.state.inventory.any(func(id):return Forge.is_item(id)),"Drawer forge consumes two components and creates a finished item")
 var other=c.hero_by_id("tray0");var old_slot=other.slot
 await click(game,"TrayFormation%d"%old_slot)
 check(c.hero_by_id("tray1").slot==old_slot,"Formation action swaps selected champion through campaign rules")
 check(drawer(game).opened,"Equipment, forge and formation refreshes keep pinned drawer open")
 tray=drawer(game);tray.set_process(false)
 var hover=InputEventMouseMotion.new();hover.position=Vector2(1500,875);hover.global_position=hover.position;root.push_input(hover,true)
 await click(game,"TeamTrayToggle")
 tray._process(.1);await create_timer(.3).timeout
 check(not tray.opened and not tray.pinned,"Explicit close unpins and cannot immediately hover-reopen")
 game.render();await create_timer(.3).timeout
 check(not drawer(game).opened,"Explicit close survives refresh")
 root.push_input(out,true);drawer(game)._process(.1);root.push_input(event,true);drawer(game)._process(.1);await create_timer(.3).timeout
 check(drawer(game).opened,"Hover opens again after leaving and returning")
 game.desk_state.dungeon_tray_pinned=true;game.render();await create_timer(.3).timeout
 var ui_count=game.ui.get_child_count()
 await click(game,"TrayDetails")
 check(game.ui.get_child_count()>ui_count,"Champion details open above the drawer")
 game.render();await create_timer(.2).timeout
 await click(game,"TrayTactics")
 var editor=game.ui.find_children("*","TacticsMenu",true,false)
 check(editor.size()==1,"Tactics can be edited from the map drawer")
 var approach=game.ui.find_child("Tactic_posture",true,false) as OptionButton
 if approach:approach.item_selected.emit(1)
 check(BattleTactics.for_hero(c.hero_by_id(game.selected_id)).posture=="aggressive","Map tactics editor saves actual champion orders")
 game.render();await create_timer(.2).timeout
 await click(game,"TrayBench")
 check(c.hero_by_id(game.selected_id).slot<0,"Selected champion can be benched from the map")
 await click(game,"TrayFormation0")
 check(c.hero_by_id(game.selected_id).slot==0,"A benched champion can return to the formation")
 for i in range(5,14):
  var h=HeroData.make_hero("golem","reserve%d"%i,"Long Reserve Champion %d"%i,6);h.slot=-1;c.state.roster.append(h)
 game.render();await create_timer(.3).timeout
 var outer=game.ui.find_child("TrayRosterScroll",true,false) as ScrollContainer
 check(outer.get_v_scroll_bar().max_value>outer.size.y,"Large rosters stay accessible through bounded portrait scrolling")
 var last_position=game.ui.find_child("TrayFormation14",true,false) as Button
 check(drawer(game).frame.get_global_rect().encloses(last_position.get_global_rect()),"Large rosters keep formation actions visible beside inventory")
 check(root.get_visible_rect().encloses(drawer(game).frame.get_global_rect()),"Large roster cannot push drawer beyond the viewport")
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../../tools/dungeon-tray-large-roster.png"))
 var original=c.state.duplicate(true)
 c.state.dungeon.row=0;c.state.dungeon.col=0;c.state.dungeon.fight=true;game.render();await create_timer(.3).timeout
 drawer(game).toggle_open();await create_timer(.3).timeout
 for b in game.ui.find_children("*","Button",true,false):
  if b.text in ["Scout","Formation"] or b.text.begins_with("Fight"):
   check(not drawer(game).frame.get_global_rect().intersects(b.get_global_rect()),"Collapsed handle must not obscure map action: "+b.text)
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../../tools/dungeon-tray-collapsed.png"))
 c.state=original
 c.state.dungeon.loot=[Forge.COMPONENT_ORDER[0]];game.render();await process_frame
 check(drawer(game)==null,"Required loot modal has priority over the hover drawer")
 c.state=original;game.tab="roster";game.render();await process_frame
 check(drawer(game)==null,"Drawer appears only on the dungeon map")
 game.sound.stop_all();game.queue_free();await process_frame
 print("Dungeon drawer: ",checks," checks; ",failures," failures")
 quit(1 if failures else 0)
