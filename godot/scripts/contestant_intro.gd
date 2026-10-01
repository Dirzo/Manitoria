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
 var subtitle=game.label(self,"MEET THE CONTESTANTS",17,game.WHITE,false);subtitle.position=Vector2(560,178);subtitle.size.x=480;subtitle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 timeline=create_tween();timeline.set_parallel(true)
 for side in range(2):
  var heroes=home if side==0 else away;var leader=HeadlinerUI.strongest(heroes);var face=c.headliner() if side==0 else leader
  if face.is_empty():continue
  var frame=FantasyFrame.new();add_child(frame);frame.position=Vector2(36 if side==0 else 852,226);frame.size=Vector2(712,532);frame.accent=Color("72dbff") if side==0 else Color("ff9989")
  frame.add_theme_stylebox_override("panel",game.style(Color(.045,.06,.16,.96),frame.accent,6,18,3))
  var column=VBoxContainer.new();column.add_theme_constant_override("separation",8);frame.add_child(column)
  game.label(column,c.state.name if side==0 else rival.name,24,frame.accent)
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
   var p=game.label(tile,"%d PWR"%HeroData.power(h),13,game.MUTED,false);p.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
   tile.modulate.a=0;timeline.tween_property(tile,"modulate:a",1.0,.22).set_delay(.5+i*.32+side*.12)
   if side==0:timeline.tween_callback(func():game.sound.play_sample("contest_reveal",-12,2,-.4 if i%2==0 else .4,1.0+i*.055);revealed+=1).set_delay(.5+i*.32)
  var target=frame.position;frame.position.x+=-200 if side==0 else 200;frame.modulate.a=0
  timeline.tween_property(frame,"position",target,.48).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(side*.15)
  timeline.tween_property(frame,"modulate:a",1.0,.35).set_delay(side*.15)
  timeline.tween_callback(func():model.play("cast");game.sound.play_sample("hero_"+face.sp,-15,2,-.55 if side==0 else .55)).set_delay(2.3+side*.65)
 var versus=game.label(self,"VS",66,game.GOLD,false);versus.position=Vector2(747,405);versus.size.x=106;versus.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;versus.modulate.a=0;versus.pivot_offset=Vector2(53,45);versus.scale=Vector2(2,2)
 timeline.tween_property(versus,"modulate:a",1.0,.18).set_delay(2.15);timeline.tween_property(versus,"scale",Vector2.ONE,.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(2.15)
 timeline.tween_callback(func():game.sound.cue("contest_versus")).set_delay(2.15)
 var delta=HeadlinerUI.power(home)-HeadlinerUI.power(away)
 var odds=game.label(self,"EVENLY MATCHED" if delta==0 else ("YOUR TEAM" if delta>0 else "RIVALS")+" LEAD BY %d POWER"%abs(delta),18,game.GOLD,false);odds.position=Vector2(350,770);odds.size.x=900;odds.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 var back=game.button(self,"← Formation",func():game.phase="prep";game.render());back.position=Vector2(36,824);back.size=Vector2(240,54)
 var fight=game.button(self,"Fight! →",launch,true);fight.position=Vector2(1164,816);fight.size=Vector2(400,64)
 fight.tooltip_text="Start when ready, or skip the introduction immediately."

func launch() -> void:
 if committed or game.phase!="intro":return
 committed=true
 if timeline:timeline.kill()
 game.begin_battle()

func _exit_tree() -> void:
 if timeline:timeline.kill()
