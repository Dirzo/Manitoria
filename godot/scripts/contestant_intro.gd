class_name ContestantIntro
extends Control
var game: Node
var timeline: Tween
var elapsed=0.0
var committed=false
var revealed=0

func build() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_IGNORE
 var c=game.campaign;var home=c.lineup();var rival=c.opponent();var away=rival.roster
 var title=game.label(self,WorldTour.region(c).name.to_upper() if c.state.has("tour") else "THE ARENA",36,game.GOLD,false);title.position=Vector2(140,125);title.size.x=1320;title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 var subtitle=game.label(self,stakes(c),19,game.WHITE,false);subtitle.position=Vector2(140,176);subtitle.size.x=1320;subtitle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 subtitle.add_theme_color_override("font_outline_color",Color(0,0,0,.85));subtitle.add_theme_constant_override("outline_size",5)
 timeline=create_tween();timeline.set_parallel(true)
 for side in range(2):
  var heroes=home if side==0 else away;var leader=HeadlinerUI.strongest(heroes);var face=c.headliner() if side==0 else leader
  if face.is_empty():continue
  var frame=FantasyFrame.new();add_child(frame);frame.position=Vector2(36 if side==0 else 852,226);frame.size=Vector2(712,532);frame.accent=Color("72dbff") if side==0 else Color("ff9989")
  frame.add_theme_stylebox_override("panel",game.style(Color(frame.accent.darkened(0.88),.9),frame.accent,14,18,0))
  var column=VBoxContainer.new();column.add_theme_constant_override("separation",8);frame.add_child(column)
  FlowUI.fit_label(game.label(column,c.state.name if side==0 else rival.name,24,frame.accent,false),650,24,12)
  var banner=HBoxContainer.new();column.add_child(banner)
  var model=HeroPreview.new();model.species_id=face.sp;model.custom_minimum_size=Vector2(280,236);banner.add_child(model)
  var words=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;banner.add_child(words)
  game.label(words,"HEADLINER" if side==0 else "RIVAL POWER LEADER",13,frame.accent)
  game.label(words,face.name.to_upper(),40,game.GOLD);game.label(words,HeroData.species[face.sp].n,23)
  game.label(words,"%d TEAM POWER"%HeadlinerUI.power(heroes),20,game.GOLD)
  game.label(words,"Strongest active: %s · %d"%[leader.name,HeroData.power(leader)],16,game.MUTED)
  if side==0 and face.slot<0:game.label(words,"Headliner on the bench",13,game.MUTED)
  var strip=HBoxContainer.new();strip.add_theme_constant_override("separation",8);column.add_child(strip)
  for i in range(heroes.size()):
   var h=heroes[i];var tile=VBoxContainer.new();tile.custom_minimum_size.x=124;strip.add_child(tile)
   HeadlinerUI.portrait(tile,h,106);var n=game.label(tile,h.name,16,game.GOLD if h.id==leader.id else game.WHITE,false);n.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
   var pw=HeroData.power(h);var p=game.label(tile,"%d"%pw,22,TraitUI.power_color(h),false);p.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;p.tooltip_text="Power";p.mouse_filter=Control.MOUSE_FILTER_STOP
   tile.modulate.a=0;timeline.tween_property(tile,"modulate:a",1.0,.22).set_delay(.5+i*.32+side*.12)
   if side==0:timeline.tween_callback(func():game.sound.play_sample("contest_reveal",-12,2,-.4 if i%2==0 else .4,1.0+i*.055);revealed+=1).set_delay(.5+i*.32)
  scout_row(column,heroes,side)
  var target=frame.position;frame.position.x+=-200 if side==0 else 200;frame.modulate.a=0
  timeline.tween_property(frame,"position",target,.48).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(side*.15)
  timeline.tween_property(frame,"modulate:a",1.0,.35).set_delay(side*.15)
  timeline.tween_callback(func():model.play("cast");game.sound.play_sample("hero_"+face.sp,-15,2,-.55 if side==0 else .55)).set_delay(2.3+side*.65)
 var versus=game.label(self,"VS",66,game.GOLD,false);versus.position=Vector2(747,405);versus.size.x=106;versus.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;versus.modulate.a=0;versus.pivot_offset=Vector2(53,45);versus.scale=Vector2(2,2)
 timeline.tween_property(versus,"modulate:a",1.0,.18).set_delay(2.15);timeline.tween_property(versus,"scale",Vector2.ONE,.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(2.15)
 timeline.tween_callback(func():game.sound.cue("contest_versus")).set_delay(2.15)
 var delta=HeadlinerUI.power(home)-HeadlinerUI.power(away)
 var odds=game.label(self,"EVENLY MATCHED" if delta==0 else ("YOUR TEAM" if delta>0 else "RIVALS")+" LEAD BY %d POWER"%abs(delta),18,game.GOLD,false);odds.position=Vector2(350,770);odds.size.x=900;odds.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 var back=game.button(self,"Formation",func():game.phase="prep";game.render());back.position=Vector2(36,816);back.size=Vector2(200,60)
 if c.state.has("tour"):
  var br=game.button(self,"Bracket",func():TournamentRewardsUI.open_screen(game,"bracket"));br.position=Vector2(250,816);br.size=Vector2(180,60)
 var holder=HBoxContainer.new();add_child(holder);holder.position=Vector2(1164,812);holder.size=Vector2(400,64)
 var fight=FlowUI.cta(game,holder,"FIGHT  ▶",launch,false,400)
 fight.tooltip_text="Start when ready, or skip the introduction immediately."

## "Winners Semifinal · win → Winners Final · lose → Losers Round 2"
func stakes(c: Campaign) -> String:
 if not c.state.has("tour"):return "MEET THE CONTESTANTS"
 var b=c.state.tour.get("bracket",{});var m=WorldTour.current_match(c)
 if b.is_empty():return str(m.get("label","")).to_upper()
 var idx=b.matches.find(m);var win="";var lose=""
 for j in range(b.matches.size()):
  var n=b.matches[j]
  for side in ["a","b"]:
   if int(n[side].get("w",-1))==idx:win=n.label
   if int(n[side].get("l",-1))==idx:lose=n.label
 if idx==13:
  win="Champion"
  if lose!="":lose="Grand Final reset"
 if idx==14:win="Champion"
 var out_next=WorldTour.losses(c,0)>=1 or lose==""
 return "%s   ·   WIN → %s   ·   LOSE → %s"%[str(m.label).to_upper(),win if win!="" else "Champion",("ELIMINATED" if out_next else lose)]

## Basic scouting, always visible: shape of the team, healers, ranged, gear and the biggest threat.
func scout_row(column: Node,heroes: Array,side: int) -> void:
 var counts={"Front":0,"Flank":0,"Back":0};var healers=0;var ranged=0;var items=0;var wild=0
 for h in heroes:
  counts[HeroData.line(h.sp)]+=1
  if HeroData.species[h.sp].role in ["Support"] or h.sp in ["unicorn","treant","naga","hydra"]:healers+=1
  if HeroData.species[h.sp].range>90:ranged+=1
  for v in h.get("equipment",{}).values():
   items+=1
   if Forge.ITEMS.has(str(v)) and Forge.ITEMS[str(v)].get("wild",false):wild+=1
 var row=HFlowContainer.new();row.add_theme_constant_override("h_separation",8);row.add_theme_constant_override("v_separation",4);column.add_child(row)
 var chip=func(text: String,col: Color,tip: String):
  var p=PanelContainer.new();row.add_child(p);p.add_theme_stylebox_override("panel",game.style(col.darkened(.75),col,8,5,0));p.tooltip_text=tip
  game.label(p,text,14,col,false)
 chip.call("%d front · %d flank · %d back"%[counts.Front,counts.Flank,counts.Back],Color("dfe8ec"),"Formation lines")
 chip.call("%d healer%s"%[healers,"" if healers==1 else "s"],Color("8cff9a") if healers>0 else Color("9fb0b8"),"Champions that heal or sustain")
 chip.call("%d ranged"%ranged,Color("9fd8ff"),"Champions that attack from range")
 chip.call("%d items%s"%[items,(" · %d WILD"%wild) if wild>0 else ""],Color("ff9be0") if wild>0 else Color("ffd36e"),"Equipped items")
 var top=HeadlinerUI.strongest(heroes)
 if side==1 and not top.is_empty():chip.call("Threat: %s (%s)"%[top.name,HeroData.species[top.sp].n],Color("ff8a7a"),"Highest power on their team: focus or peel it")

func launch() -> void:
 if committed or game.phase!="intro":return
 committed=true
 if timeline:timeline.kill()
 game.begin_battle()

func _exit_tree() -> void:
 if timeline:timeline.kill()
