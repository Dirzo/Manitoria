class_name FantasyUI
extends RefCounted
static func menu(game: Node) -> void:
 var title=Title3D.new();game.ui.add_child(title);title.position=Vector2(100,110);title.size=Vector2(1400,190)
 var sub=game.label(game.ui,"THE LIVING ARENA",22,Color("fff5d2"),false);sub.position=Vector2(400,280);sub.size=Vector2(800,38);sub.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;sub.add_theme_color_override("font_outline_color",Color("201a32"));sub.add_theme_constant_override("outline_size",5)
 var latest=0;var modified=0
 for slot in range(1,4):
  if FileAccess.file_exists(Campaign.save_path(slot)) and FileAccess.get_modified_time(Campaign.save_path(slot))>modified:latest=slot;modified=FileAccess.get_modified_time(Campaign.save_path(slot))
 var entries=[["Continue","victory",Color("69dba8"),func():game.load_campaign(latest)],["New club","summons",Color("cdb0ff"),func():game.sound.announce("found_guild",true);game.new_mode="guild";game.phase="new";game.render()],["Dungeon","flamewave",Color("ff9a5c"),func():game.sound.announce("found_guild",true);game.new_mode="dungeon";game.phase="new";game.render()],["Exhibition","gore",Color("ffbd77"),game.start_exhibition]]
 for i in range(entries.size()):
  var entry=entries[i];var frame=FantasyFrame.new();game.ui.add_child(frame);frame.position=Vector2(207+i*302,405);frame.size=Vector2(280,332);frame.accent=entry[2]
  frame.add_theme_stylebox_override("panel",game.style(Color(.055,.10,.12,.9),entry[2],12,16,0))
  var box=VBoxContainer.new();frame.add_child(box);AbilityArt.icon(box,entry[1],196)
  var button=game.button(box,entry[0],entry[3],true,i==0 and latest==0);button.custom_minimum_size.y=62;button.add_theme_font_size_override("font_size",23)
  if entry[0]=="Dungeon":frame.tooltip_text="A branching descent in the spirit of The Last Flame and Guildrun: choose rooms, collect relics, build run-trait synergies, defeat three Wardens, then chase a high score in the endless depths.";button.name="DungeonMenuButton"
  frame.mouse_entered.connect(func():frame.modulate=Color(1.13,1.13,1.13));frame.mouse_exited.connect(func():frame.modulate=Color.WHITE)
 var lab=game.button(game.ui,"Speedrun stat check",game.start_speedrun,true);lab.position=Vector2(1040,767);lab.size=Vector2(380,46);lab.name="SpeedrunMenuButton"
 var saves=game.button(game.ui,"Saved campaigns",func():save_picker(game));saves.position=Vector2(620,767);saves.size=Vector2(360,46)
 var hs=game.button(game.ui,"Dungeon high scores",func():DungeonUI.high_scores(game));hs.position=Vector2(180,767);hs.size=Vector2(380,46);hs.name="DungeonScoresButton"
 if FileAccess.file_exists("user://speedrun_draft.json"):
  var resume=game.button(game.ui,"Resume speedrun draft",game.resume_speedrun);resume.position=Vector2(1040,823);resume.size=Vector2(380,40)
 var version=game.label(game.ui,"Windows edition 0.73 · Speedrun Stat Check",14,Color("eee3cf"),false);version.position=Vector2(30,861)

static func save_picker(game: Node) -> void:
 var dialog=GearUI.modal(game,"Your campaigns")
 for slot in range(1,4):
  var saved=Campaign.new()
  if saved.load_slot(slot):game.button(dialog.box,"%d · %s · %s%s"%[slot,saved.state.name,"Dungeon depth %d"%int(saved.state.dungeon.act) if Dungeon.active(saved) else "Cup %d"%int(saved.state.get("tour",{}).get("level",1))," · Fallen" if saved.state.get("run_over",false) else ""],func():game.load_campaign(slot),true)
  else:game.label(dialog.box,"Slot %d · Empty"%slot,19,game.MUTED)

static func header(game: Node) -> void:
 if game.phase in ["menu","new"]:
  var row=HBoxContainer.new();game.ui.add_child(row);row.position=Vector2(1452,28)
  row.position=Vector2(1390,28)
  game.button(row,"♪",game.toggle_music).tooltip_text="Music on/off"
  game.button(row,"⚙",func():FlowUI.settings(game)).tooltip_text="Settings: music, effects and announcer volume"
  game.button(row,"Exit",game.close_game)
  return
 location_banner(game)

## Immersive top banner: club on the left, the arena you're standing in at centre,
## the World Tour road on the right.
static func location_banner(game: Node) -> void:
 var c=game.campaign;var touring=game.phase!="new" and not game.exhibition and c.state.has("tour")
 var r=WorldTour.display_region(c) if touring else {}
 var accent=Color(r.get("color","e8c27a"))
 var band=ColorRect.new();game.ui.add_child(band);band.position=Vector2.ZERO;band.size=Vector2(1600,124);band.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var sh=Shader.new();sh.code="""shader_type canvas_item;
uniform vec4 accent:source_color;
void fragment(){
 float fade=1.-smoothstep(.55,1.,UV.y);
 float line=exp(-pow((UV.y-.86)*90.,2.))*(1.-smoothstep(.15,.5,abs(UV.x-.5)));
 vec3 c=mix(vec3(.02,.025,.035),accent.rgb*.25,.25*(1.-smoothstep(0.,.35,abs(UV.x-.5))));
 COLOR=vec4(mix(c,accent.rgb,line),max(fade*.86,line*.9));
}"""
 var m=ShaderMaterial.new();m.shader=sh;m.set_shader_parameter("accent",accent);band.material=m
 # Left: club identity
 var left=HBoxContainer.new();game.ui.add_child(left);left.position=Vector2(26,18)
 var club_name=c.state.get("name","Manitoria") if game.phase!="new" else "Manitoria"
 var crest=Crest.make(left,Crest.of_campaign(c),club_name,Vector2(58,66));crest.mouse_filter=Control.MOUSE_FILTER_PASS;crest.tooltip_text=club_name+("\n“%s”"%c.state.motto if str(c.state.get("motto",""))!="" else "")
 var face=c.headliner() if game.phase!="new" else {}
 if not face.is_empty():
  var portrait=SplashArt.make(left,face.sp,Vector2(62,70));portrait.mouse_filter=Control.MOUSE_FILTER_PASS;portrait.tooltip_text="Headliner · "+face.name
 var id=VBoxContainer.new();id.add_theme_constant_override("separation",0);left.add_child(id)
 var nm=game.label(id,club_name,26,game.WHITE,false);nm.add_theme_color_override("font_outline_color",Color(0,0,0,.8));nm.add_theme_constant_override("outline_size",5)
 FlowUI.fit_label(nm,300 if face.is_empty() else 290,26,13)
 if game.phase!="new":FlowUI.run_bar(game,id)
 # Centre: where we are
 var mid=VBoxContainer.new();game.ui.add_child(mid);mid.position=Vector2(470,10);mid.size=Vector2(660,100);mid.add_theme_constant_override("separation",-2)
 var kicker;var place;var stage
 if game.phase=="new":kicker="THE FOUNDING CHARTER";place="Manitoria";stage="Name your club and claim a headliner"
 elif game.phase=="starter":kicker="";place="Draft your headliner champion";stage="Your headliner leads the guild. Next you draft the rest of your squad."
 elif game.exhibition:kicker="EXHIBITION";place="The Living Arena";stage="Champion showcase"
 elif touring and Dungeon.active(c):
  kicker="THE DUNGEON  ·  "+str(Dungeon.depth(c).depth_label).to_upper()
  place=str(Dungeon.depth(c).name)
  stage=Dungeon.stage_label(c)
 elif touring:
  var t=c.state.tour
  kicker="%s  ·  CUP %d OF %d"%[str(r.name).to_upper(),WorldTour.shown_level(c),WorldTour.cup_limit(c)]
  place=str(r.place)
  stage=_stage_text(c)
 else:kicker="";place="Manitoria";stage=game.stage_label()
 var k=game.label(mid,kicker,14,accent.lightened(.25),false);k.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 k.add_theme_color_override("font_outline_color",Color(0,0,0,.8));k.add_theme_constant_override("outline_size",4)
 var title=game.label(mid,place.to_upper(),34,Color("ffe9b8"),false);title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 if game.phase=="starter":FlowUI.fit_label(title,660,34,20)
 title.add_theme_font_override("font",load(game.TITLE_FONT))
 title.add_theme_color_override("font_outline_color",Color("1a0f14"));title.add_theme_constant_override("outline_size",8)
 title.add_theme_color_override("font_shadow_color",Color(accent,.55));title.add_theme_constant_override("shadow_offset_y",3)
 var st=game.label(mid,stage,16,game.WHITE,false);st.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 if int(c.state.get("challenge_rank",0))>0:st.text+=" · ASCENSION %d"%int(c.state.challenge_rank)
 st.add_theme_color_override("font_outline_color",Color(0,0,0,.85));st.add_theme_constant_override("outline_size",4)
 # Right: the road and controls
 if touring and game.phase!="starter" and not Dungeon.active(c):
  var road=TourPath.new();road.level=WorldTour.shown_level(c);game.ui.add_child(road);road.position=Vector2(1112,40);road.size=Vector2(312,62)
  var cap=game.label(game.ui,"WORLD TOUR",11,Color(1,1,1,.6),false);cap.position=Vector2(1112,12);cap.size=Vector2(290,18);cap.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 var tools=VBoxContainer.new();game.ui.add_child(tools);tools.position=Vector2(1446,14);tools.add_theme_constant_override("separation",6)
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",6);tools.add_child(row)
 var mb=game.button(row,"♪",game.toggle_music);mb.tooltip_text="Music: "+("on" if game.sound.music_enabled else "off");mb.custom_minimum_size=Vector2(56,40)
 var fb=game.button(row,"FX",game.toggle_effects);fb.tooltip_text="Sound effects: "+("on" if game.sound.effects_enabled else "off");fb.custom_minimum_size=Vector2(56,40)
 var row2=HBoxContainer.new();row2.add_theme_constant_override("separation",6);tools.add_child(row2)
 var sb=game.button(row2,"⚙",func():FlowUI.settings(game));sb.tooltip_text="Settings: music, effects and announcer volume";sb.custom_minimum_size=Vector2(44,40)
 var menu_button=game.button(row2,"Menu",game.quit_to_menu if game.phase!="new" else func():game.phase="menu";game.render());menu_button.custom_minimum_size=Vector2(68,40)

static func _stage_text(c: Campaign) -> String:
 var t=c.state.tour
 if c.state.roster.is_empty():return "Draft your headliner"
 if t.get("complete",false):return "World Tour complete"
 var b=t.get("bracket",{})
 if b.is_empty():return "Opening round"
 if b.get("finished",false):
  return "Cup decided"
 return WorldTour.stage_label(c)
