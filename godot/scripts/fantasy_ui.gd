class_name FantasyUI
extends RefCounted
static func menu(game: Node) -> void:
 var title=Title3D.new();game.ui.add_child(title);title.position=Vector2(100,64);title.size=Vector2(1400,190)
 var sub=game.label(game.ui,"THE LIVING ARENA",20,Color("fff5d2"),false);sub.position=Vector2(400,232);sub.size=Vector2(800,34);sub.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;sub.add_theme_color_override("font_outline_color",Color("201a32"));sub.add_theme_constant_override("outline_size",5)
 # Saves: the newest overall, and the newest unfinished dungeon run.
 var latest=0;var modified=0;var dungeon_slot=0;var dungeon_time=0;var dungeon_save: Campaign=null
 for slot in range(1,4):
  if not FileAccess.file_exists(Campaign.save_path(slot)):continue
  var t=FileAccess.get_modified_time(Campaign.save_path(slot))
  if t>modified:latest=slot;modified=t
  var saved=Campaign.new()
  if t>dungeon_time and saved.load_slot(slot) and Dungeon.active(saved) and not saved.state.get("run_over",false) and not saved.state.get("tour",{}).get("complete",false):
   dungeon_slot=slot;dungeon_time=t;dungeon_save=saved
 featured(game,dungeon_slot,dungeon_save)
 # Everything else: a clean row of text links under the feature, no boxes.
 # A dark band so the links read over any painting.
 var band=ColorRect.new();game.ui.add_child(band);band.position=Vector2(0,706);band.size=Vector2(1600,84);band.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var bsh=Shader.new();bsh.code="shader_type canvas_item; void fragment(){ float y=1.0-abs(UV.y-0.5)*2.0; float x=1.0-smoothstep(0.25,0.5,abs(UV.x-0.5)); COLOR=vec4(0.02,0.015,0.03,smoothstep(0.0,0.6,y)*x*0.82); }"
 var bm=ShaderMaterial.new();bm.shader=bsh;band.material=bm
 var links=HBoxContainer.new();game.ui.add_child(links);links.position=Vector2(250,724);links.size=Vector2(1100,48);links.add_theme_constant_override("separation",6)
 var entries=[]
 if latest>0 and latest!=dungeon_slot:entries.append(["Continue guild",func():game.load_campaign(latest),"ContinueMenuButton","Resume your most recent save"])
 entries.append(["Guild tour",func():game.sound.announce("found_guild",true);game.new_mode="guild";game.phase="new";game.render(),"GuildMenuButton","Found a guild and compete across five World Tour cups"])
 entries.append(["Exhibition",game.start_exhibition,"ExhibitionMenuButton","A showcase battle with any champions"])
 entries.append(["Speedrun stat check",game.start_speedrun,"SpeedrunMenuButton","Plan a draft, formation and items, then simulate five or ten cups"])
 entries.append(["Saved runs",func():save_picker(game),"SavesMenuButton","Load one of three saved runs"])
 entries.append(["High scores",func():DungeonUI.high_scores(game),"DungeonScoresButton","Your best banked dungeon runs"])
 for i in range(entries.size()):
  if i>0:
   var dot=game.label(links,"·",22,Color(0.89,0.77,0.54,0.45),false);dot.size_flags_vertical=Control.SIZE_SHRINK_CENTER
  var e=entries[i];var tab=HudKit.nav_tab(links,game,e[0],e[1]);tab.name=e[2];tab.tooltip_text=e[3];tab.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 if FileAccess.file_exists("user://speedrun_draft.json"):
  var resume=HudKit.nav_tab(game.ui,game,"Resume speedrun draft",game.resume_speedrun);resume.position=Vector2(650,776);resume.size=Vector2(300,40)
 var version=game.label(game.ui,"Windows edition 0.75 · Dungeon",14,Color("eee3cf"),false);version.position=Vector2(30,861)

## The headline feature: the dungeon, as a painted banner with one gilded call to action.
static func featured(game: Node, slot: int, saved: Campaign) -> void:
 var rect=Rect2(300,288,1000,404)
 var zone="magma_depths" if saved==null else Dungeon.instance_id(saved)
 var info=DungeonInstances.info(zone);var accent=Color(info.accent)
 var card=DungeonUI.plate(game.ui,rect,Color("e3c589"),Color(0.03,0.025,0.04,0.97));card.clip_contents=true;card.name="DungeonFeature"
 DungeonUI.painted(card,zone,Rect2(3,3,rect.size.x-6,rect.size.y-6),0.62)
 var shade=ColorRect.new();card.add_child(shade);shade.position=Vector2(3,3);shade.size=rect.size-Vector2(6,6);shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var sh=Shader.new();sh.code="shader_type canvas_item; void fragment(){ float l=smoothstep(0.95,0.25,UV.x); float b=smoothstep(0.35,1.0,UV.y); COLOR=vec4(0.015,0.012,0.02,clamp(l*0.9+b*0.55,0.0,0.95)); }"
 var m=ShaderMaterial.new();m.shader=sh;shade.material=m
 DungeonUI.vignette(card,Rect2(3,3,rect.size.x-6,rect.size.y-6),Color(info.fog).darkened(0.7),0.6)
 var x=44.0
 DungeonUI.caption(game,card,"Featured  ·  Dungeon mode" if saved==null else "Your descent continues",Vector2(x,34),Color("ffcf8a"))
 var hd=DungeonUI.heading(game,card,"Into the Dungeon" if saved==null else str(saved.state.name),Vector2(x,58),46,Color("fff0d0"),620);FlowUI.fit_label(hd,620,46,24)
 var line="Ten cursed zones, each with its own monsters and a Warden. Draft champions as you go, collect relics, awaken run-trait synergies, and chase a high score in the endless depths."
 if saved!=null:
  var d=saved.state.dungeon
  line="%s  ·  %s  ·  %d of %d lives  ·  %d points so far"%[str(Dungeon.depth(saved).name),Dungeon.stage_label(saved),int(d.lives),int(d.max_lives),int(d.score)]
 var body=DungeonUI.text(game,card,line,Vector2(x,126),18,Color("e9dcc2"),560);body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 # Small facts, as chips.
 var chips=HBoxContainer.new();card.add_child(chips);chips.position=Vector2(x,226);chips.add_theme_constant_override("separation",8);chips.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var best=Dungeon.scores()
 var facts=["10 zones","10 Wardens","26 relics","Endless depths"]
 if not best.is_empty():facts.append("Best  %d"%int(best[0].score))
 for f in facts:
  var chip=PanelContainer.new();chips.add_child(chip);chip.mouse_filter=Control.MOUSE_FILTER_IGNORE
  var sb=DungeonUI.skin(Color(accent,0.7),Color(0.05,0.04,0.06,0.85),12,false,1);sb.content_margin_left=12;sb.content_margin_right=12;sb.content_margin_top=3;sb.content_margin_bottom=4;chip.add_theme_stylebox_override("panel",sb)
  var l=game.label(chip,f,14,Color("f1e6cc"),false);l.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var row=HBoxContainer.new();card.add_child(row);row.position=Vector2(x,292);row.add_theme_constant_override("separation",16)
 if saved!=null:
  var go=FlowUI.cta(game,row,"Continue descent  ▶",func():game.load_campaign(slot),false,360);go.name="DungeonMenuButton"
  var fresh=game.button(row,"New descent",func():game.sound.announce("found_guild",true);game.new_mode="dungeon";game.phase="new";game.render());fresh.custom_minimum_size=Vector2(200,58);fresh.name="NewDungeonButton"
 else:
  var go=FlowUI.cta(game,row,"Enter the dungeon  ▶",func():game.sound.announce("found_guild",true);game.new_mode="dungeon";game.phase="new";game.render(),false,380);go.name="DungeonMenuButton"
  go.tooltip_text="A branching descent in the spirit of The Last Flame and Guildrun\nChoose rooms, collect relics, build run-trait synergies, defeat three Wardens, then chase a high score in the endless depths."
 # Warden portrait on the right, glowing.
 var boss=Bestiary.BOSSES.get(str(info.boss),{})
 if not boss.is_empty():
  var face=DungeonUI.portrait(card,str(boss.sp),Rect2(rect.size.x-250,60,190,190),Color(boss.glow),Color(boss.tint).lerp(Color.WHITE,0.45))
  face.tooltip_text="%s\n%s"%[boss.name,boss.text]
  var cap=DungeonUI.caption(game,card,str(boss.name),Vector2(rect.size.x-300,262),Color("ffb3a8"),290,HORIZONTAL_ALIGNMENT_CENTER)
 # The card breathes gently, so the eye lands on it first.
 card.pivot_offset=rect.size*0.5;card.modulate.a=0.0;card.position.y+=12
 var tw=card.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
 tw.tween_property(card,"modulate:a",1.0,0.5);tw.tween_property(card,"position:y",rect.position.y,0.6)

static func save_picker(game: Node) -> void:
 var dialog=GearUI.modal(game,"Your campaigns")
 for slot in range(1,4):
  var saved=Campaign.new()
  if saved.load_slot(slot):game.button(dialog.box,"%d · %s · %s%s"%[slot,saved.state.name,"Dungeon depth %d"%int(saved.state.dungeon.act) if Dungeon.active(saved) else "Cup %d"%int(saved.state.get("tour",{}).get("level",1))," · Fallen" if saved.state.get("run_over",false) else ""],func():game.load_campaign(slot),true)
  else:game.label(dialog.box,"Slot %d · Empty"%slot,19,game.MUTED)

static func header(game: Node) -> void:
 if game.phase in ["menu","new"]:
  var row=HBoxContainer.new();game.ui.add_child(row);row.add_theme_constant_override("separation",8)
  AtlasUI.medallions(game,row,48)
  HudKit.medallion(row,game,"music","","Music on/off",game.toggle_music,false,48).muted=not game.sound.music_enabled
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
