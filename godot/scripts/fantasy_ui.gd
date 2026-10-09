class_name FantasyUI
extends RefCounted
## The landing: the title, three buttons and your saves. Dungeon is the big one.
static func menu(game: Node) -> void:
 var title=Title3D.new();game.ui.add_child(title);title.position=Vector2(100,70);title.size=Vector2(1400,190)
 var saves={"dungeon":[],"guild":[]}
 for slot in range(1,4):
  var saved=Campaign.new()
  if not saved.load_slot(slot):continue
  saves["dungeon" if Dungeon.active(saved) else "guild"].append({"slot":slot,"c":saved,"time":FileAccess.get_modified_time(Campaign.save_path(slot))})
 for k in saves:saves[k].sort_custom(func(a,b):return a.time>b.time)
 # A soft shadow behind the menu column so the words read over the bright painting.
 var veil=ColorRect.new();game.ui.add_child(veil);veil.position=Vector2(250,290);veil.size=Vector2(1100,300);veil.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var vsh=Shader.new();vsh.code="shader_type canvas_item; void fragment(){ vec2 d=(UV-0.5)*vec2(1.0,1.6); COLOR=vec4(0.012,0.01,0.02,(1.0-smoothstep(0.1,0.5,length(d)))*0.62); }"
 var vm=ShaderMaterial.new();vm.shader=vsh;veil.material=vm
 var col=VBoxContainer.new();game.ui.add_child(col);col.position=Vector2(300,330);col.size=Vector2(1000,0);col.add_theme_constant_override("separation",6)
 var start_dungeon=func():game.sound.announce("found_guild",true);game.new_mode="dungeon";game.phase="new";game.render()
 var start_guild=func():game.sound.announce("found_guild",true);game.new_mode="guild";game.phase="new";game.render()
 mode_row(game,col,"Dungeon",start_dungeon,saves.dungeon,"DungeonMenuButton",true)
 mode_row(game,col,"Tournament draft",start_guild,saves.guild,"GuildMenuButton",false)
 mode_row(game,col,"Statistics & achievements",func():stats_menu(game),[],"StatsMenuButton",false)
 col.modulate.a=0.0;col.create_tween().tween_property(col,"modulate:a",1.0,0.45)
 var version=game.label(game.ui,"0.75.4",13,Color(1,1,1,0.45),false);version.position=Vector2(24,866)

## One landing button, centred, with its saved runs as small chips just after it.
static func mode_row(game: Node, col: Control, text: String, action: Callable, saves: Array, node_name: String, hero: bool) -> void:
 var row=HBoxContainer.new();row.alignment=BoxContainer.ALIGNMENT_CENTER;row.add_theme_constant_override("separation",12);col.add_child(row)
 var b: Button
 if hero:
  b=HudKit.menu_item(row,game,text,action,64,true,true);b.custom_minimum_size=Vector2(520,104)
 else:
  b=HudKit.menu_item(row,game,text,action,27,false,false);b.custom_minimum_size=Vector2(420,56)
 b.name=node_name
 for s in saves.slice(0,3):
  var c: Campaign=s.c;var slot=int(s.slot)
  var short=("Depth %d"%int(c.state.dungeon.act)) if Dungeon.active(c) else ("Cup %d"%int(c.state.get("tour",{}).get("level",1)))
  if c.state.get("run_over",false) or c.state.get("tour",{}).get("complete",false):short="Ended"
  var chip=HudKit.menu_item(row,game,short,func():game.load_campaign(slot),17);chip.custom_minimum_size=Vector2(104,40)
  chip.name="Save%d"%slot;chip.tooltip_text="Continue  ·  %s\nSave slot %d"%[str(c.state.name),slot]
  chip.size_flags_vertical=Control.SIZE_SHRINK_CENTER
 if not saves.is_empty():
  # Keep the main button centred: a matching spacer on the left.
  var pad=Control.new();pad.custom_minimum_size.x=mini(saves.size(),3)*116;row.add_child(pad);row.move_child(pad,0)

## Statistics & achievements: Atlas, high scores, achievements, and the labs.
static func stats_menu(game: Node) -> void:
 var dlg=GearUI.modal(game,"Statistics & achievements",Vector2(760,520))
 var grid=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",16);grid.add_theme_constant_override("v_separation",16);dlg.box.add_child(grid)
 for e in [["Atlas",func():AtlasUI.open(game)],["High scores",func():DungeonUI.high_scores(game)],["Achievements",func():achievements(game)],["Speedrun lab",game.start_speedrun],["Exhibition",game.start_exhibition],["Saved runs",func():save_picker(game)]]:
  var b=game.button(grid,e[0],e[1]);b.custom_minimum_size=Vector2(340,64);b.add_theme_font_size_override("font_size",20)
  b.name=e[0].replace(" ","")+"Button"
 if FileAccess.file_exists("user://speedrun_draft.json"):
  var r=game.button(dlg.box,"Resume speedrun draft",game.resume_speedrun);r.custom_minimum_size=Vector2(696,48)

## Achievements, read from your high scores, the Ascension ladder and the trophy vault.
static func achievement_list() -> Array:
 var scores=Dungeon.scores();var best=0;var wardens=0;var deepest=0;var endless=false;var runs=scores.size()
 for r in scores:
  best=maxi(best,int(r.score));wardens=maxi(wardens,int(r.wardens));deepest=maxi(deepest,int(r.depth));endless=endless or bool(r.get("endless",false))
 var asc=DungeonAscension.unlocked()
 TrophyVault.read_profile();var trophies=TrophyVault.data.get("claims",{}).size()
 return [
  ["First descent","Bank a dungeon run.",runs>=1],
  ["Warden slayer","Defeat a Warden.",wardens>=1],
  ["Dungeon conquered","Defeat all three Wardens in one run.",wardens>=3],
  ["Into the endless","Reach depth 4.",deepest>=4 or endless],
  ["Abyss walker","Reach depth 6.",deepest>=6],
  ["Ascendant","Unlock Ascension 1.",asc>=1],
  ["Hungry for more","Unlock Ascension 4.",asc>=4],
  ["The Last Light","Unlock Ascension 8.",asc>=8],
  ["High scorer","Bank a run worth 5,000 points.",best>=5000],
  ["Trophy hunter","Claim a tournament medal chest.",trophies>=1],
 ]

static func achievements(game: Node) -> void:
 var list=achievement_list();var got=list.filter(func(a):return a[2]).size()
 var dlg=GearUI.modal(game,"Achievements  ·  %d / %d"%[got,list.size()],Vector2(760,640))
 var scroll=ScrollContainer.new();scroll.custom_minimum_size=Vector2(700,540);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;dlg.box.add_child(scroll)
 var box=VBoxContainer.new();box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;box.add_theme_constant_override("separation",8);scroll.add_child(box)
 for a in list:
  var row=HBoxContainer.new();box.add_child(row);row.add_theme_constant_override("separation",14)
  var mark=game.label(row,"◆" if a[2] else "◇",24,Color("e3c589") if a[2] else Color(1,1,1,0.3),false);mark.custom_minimum_size.x=30
  var words=VBoxContainer.new();words.add_theme_constant_override("separation",0);row.add_child(words)
  game.label(words,a[0],19,Color("f1e6cc") if a[2] else Color(1,1,1,0.5),false)
  game.label(words,a[1],14,Color("a99f8e"),false)

static func save_picker(game: Node) -> void:
 var dialog=GearUI.modal(game,"Your campaigns")
 for slot in range(1,4):
  var saved=Campaign.new()
  if saved.load_slot(slot):game.button(dialog.box,"%d · %s · %s%s"%[slot,saved.state.name,"Dungeon depth %d"%int(saved.state.dungeon.act) if Dungeon.active(saved) else "Cup %d"%int(saved.state.get("tour",{}).get("level",1))," · Fallen" if saved.state.get("run_over",false) else ""],func():game.load_campaign(slot),true)
  else:game.label(dialog.box,"Slot %d · Empty"%slot,19,game.MUTED)

static func header(game: Node) -> void:
 if game.phase in ["menu","new"]:
  var row=HBoxContainer.new();game.ui.add_child(row);row.add_theme_constant_override("separation",8)
  var mm=HudKit.medallion(row,game,"music","","Music on/off",game.toggle_music,false,48);mm.muted=not game.sound.music_enabled;mm.name="MusicMedallion"
  HudKit.medallion(row,game,"gear","","Settings: music, effects and announcer volume",func():FlowUI.settings(game),false,48)
  HudKit.medallion(row,game,"close","","Exit the game",game.close_game,false,48)
  row.position=Vector2(1600-row.get_child_count()*56-14,24)
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
 # Controls: four small medallions, no boxes.
 var row=HBoxContainer.new();game.ui.add_child(row);row.add_theme_constant_override("separation",6)
 HudKit.medallion(row,game,"music","","Music: "+("on" if game.sound.music_enabled else "off"),game.toggle_music,false,46).muted=not game.sound.music_enabled
 HudKit.medallion(row,game,"sound","","Sound effects: "+("on" if game.sound.effects_enabled else "off"),game.toggle_effects,false,46).muted=not game.sound.effects_enabled
 HudKit.medallion(row,game,"gear","","Settings: music, effects and announcer volume",func():FlowUI.settings(game),false,46)
 HudKit.medallion(row,game,"menu","","Main menu",game.quit_to_menu if game.phase!="new" else func():game.phase="menu";game.render(),false,46)
 row.position=Vector2(1600-row.get_child_count()*52-12,18)
 if game.phase!="battle":
  # Reference tools sit on a quieter second row, under the controls.
  var tools=HBoxContainer.new();game.ui.add_child(tools);tools.add_theme_constant_override("separation",6)
  AtlasUI.medallions(game,tools,38)
  tools.position=Vector2(1600-tools.get_child_count()*44-16,72)

static func _stage_text(c: Campaign) -> String:
 var t=c.state.tour
 if c.state.roster.is_empty():return "Draft your headliner"
 if t.get("complete",false):return "World Tour complete"
 var b=t.get("bracket",{})
 if b.is_empty():return "Opening round"
 if b.get("finished",false):
  return "Cup decided"
 return WorldTour.stage_label(c)
