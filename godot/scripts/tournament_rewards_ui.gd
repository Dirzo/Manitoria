class_name TournamentRewardsUI
extends Control
var game: Node
var mode="bracket"
var reveal: Dictionary={}
var animate:=false            # play the matches that just resolved
var on_continue:=Callable()   # when set, a big continue button replaces Close
var continue_text:="Continue  ▶"
var tiles:={}
var rows:={}
var canvas_ref:Control
var body: VBoxContainer
func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter=Control.MOUSE_FILTER_STOP
 var immersive=mode=="bracket" and game.campaign.state.has("tour")
 if immersive:
  # The current stop's own scenery, dimmed, behind the board.
  var r=WorldTour.region(game.campaign)
  var bg=TextureRect.new();bg.texture=load("res://assets/ui/regions/%s.jpg"%str(r.theme).to_lower());bg.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;bg.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
  bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);bg.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(bg)
  var dim=ColorRect.new();dim.color=Color(Color(r.color).darkened(0.85),0.62);dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);dim.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(dim)
 else:
  var shade=ColorRect.new();shade.color=Color(0.015,0.025,0.07,0.97);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shade)
 var frame=FantasyFrame.new();frame.position=Vector2(50,105) if not immersive else Vector2(40,40);frame.size=Vector2(1500,755) if not immersive else Vector2(1520,820);add_child(frame)
 frame.add_theme_stylebox_override("panel",game.style(Color("12282e"),game.GOLD,14,24,2) if not immersive else StyleBoxEmpty.new())
 var layout=VBoxContainer.new();layout.add_theme_constant_override("separation",16);frame.add_child(layout)
 var header=HBoxContainer.new();layout.add_child(header)
 var head=game.label(header,"" if immersive else {"bracket":"THE TOURNAMENT BOARD","progress":"WORLD TOUR PROGRESS"}.get(mode,"CHAMPION'S VAULT"),30,game.GOLD);head.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 if immersive:
  head.text=str(WorldTour.region(game.campaign).name).to_upper();head.add_theme_font_override("font",load(game.TITLE_FONT));head.add_theme_color_override("font_color",Color(WorldTour.region(game.campaign).color).lightened(0.3))
 if on_continue.is_valid():
  var go=FlowUI.cta(game,header,continue_text,func():on_continue.call(),false,300)
 else:game.button(header,"Close",func():game.render())
 var scroll=ScrollContainer.new();scroll.custom_minimum_size=Vector2(1435,650);scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;layout.add_child(scroll)
 body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",18);scroll.add_child(body)
 refresh()
func refresh() -> void:
 for child in body.get_children():body.remove_child(child);child.queue_free()
 if mode=="bracket":bracket()
 elif mode=="progress":progress()
 else:vault()
func tile(parent: Node) -> VBoxContainer:
 var panel=FantasyFrame.new();parent.add_child(panel);panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 panel.add_theme_stylebox_override("panel",game.style(Color("213a40"),Color("57738c"),8,14,1))
 var box=VBoxContainer.new();box.add_theme_constant_override("separation",7);panel.add_child(box);return box
const POS := {
 0: Vector2(0, 40), 1: Vector2(0, 118), 2: Vector2(0, 196), 3: Vector2(0, 274),
 4: Vector2(285, 79), 5: Vector2(285, 235), 6: Vector2(570, 157),
 7: Vector2(0, 420), 8: Vector2(0, 498), 9: Vector2(285, 420), 10: Vector2(285, 498),
 11: Vector2(570, 459), 12: Vector2(855, 380),
 13: Vector2(1140, 268), 14: Vector2(1140, 358)}
const FEEDS := {4: [0, 1], 5: [2, 3], 6: [4, 5], 9: [7], 10: [8], 11: [9, 10], 12: [11, 6], 13: [6, 12], 14: [13]}
const TILE := Vector2(255, 66)

func bracket() -> void:
 var c=game.campaign;WorldTour.ensure_bracket(c);var b=c.state.tour.bracket
 var canvas=Control.new();canvas.custom_minimum_size=Vector2(1410,600);body.add_child(canvas);canvas_ref=canvas;tiles={};rows={}
 for cap in [["GRAND FINAL",Vector2(1140,234),game.GOLD]]:
  var l=game.label(canvas,cap[0],18,cap[2],false);l.position=cap[1]
  l.add_theme_font_override("font",load(game.TITLE_FONT));l.add_theme_color_override("font_outline_color",Color(0,0,0,.8));l.add_theme_constant_override("outline_size",5)
 # connectors
 for target in FEEDS:
  for src in FEEDS[target]:
   var from:Vector2=POS[src]+Vector2(TILE.x,TILE.y*0.5);var to:Vector2=POS[target]+Vector2(0,TILE.y*0.5)
   var mid=(from.x+to.x)*0.5
   var pts=PackedVector2Array([from,Vector2(mid,from.y),Vector2(mid,to.y),to])
   # Brass rails pinned to the board, with a carved shadow beneath.
   var accent=Color(WorldTour.region(c).color) if c.state.has("tour") else Color("dfe8ec")
   var line=Line2D.new();line.width=3;line.default_color=Color(accent.lightened(0.3),0.55) if not (src==6 and target==12) else Color("ff8a7a",0.45);line.points=pts;canvas.add_child(line)
 var next=WorldTour.current_match(c) if not b.finished else {}
 for i in range(b.matches.size()):
  var m=b.matches[i]
  if i==14 and m.skipped:continue
  var panel=PanelContainer.new();canvas.add_child(panel);panel.position=POS[i];panel.size=TILE;tiles[i]=panel;rows[i]={}
  var is_next=not next.is_empty() and next==m
  # Each match is a card floating over the region scenery.
  # Dark glass cards floating over the scenery; the next match glows warmer.
  var plaque=StyleBoxFlat.new();plaque.bg_color=Color(0.03,0.05,0.07,0.82) if not is_next else Color(0.22,0.17,0.05,0.9);plaque.set_corner_radius_all(10)
  plaque.shadow_color=Color(0,0,0,0.45);plaque.shadow_size=10;plaque.shadow_offset=Vector2(0,4)
  for side_m in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]:plaque.set_content_margin(side_m,8)
  panel.add_theme_stylebox_override("panel",plaque)
  if is_next:
   var lamp=create_tween().set_loops();lamp.tween_property(panel,"modulate",Color(1.25,1.15,0.9),0.8);lamp.tween_property(panel,"modulate",Color.WHITE,0.8)
  var box=VBoxContainer.new();box.add_theme_constant_override("separation",2);panel.add_child(box)
  for side in ["a","b"]:
   var team=int(m["team_"+side]);var row=HBoxContainer.new();row.add_theme_constant_override("separation",6);box.add_child(row);rows[i][side]=row
   if team<0:
    game.label(row,"—",13,Color(1,1,1,0.25),false);continue
   var roster=WorldTour.team_roster(c,team)
   var face=c.headliner() if team==0 else HeadlinerUI.rival_face(c,{"club":team,"roster":roster})
   if not face.is_empty():HeadlinerUI.portrait(row,face,22)
   var won=int(m.winner)==team;var lost=int(m.loser)==team
   var name=game.label(row,WorldTour.team_name(c,team),14,game.GOLD if won else Color("86dbf2") if team==0 else (game.MUTED if lost else game.WHITE),false)
   name.size_flags_horizontal=Control.SIZE_EXPAND_FILL;name.clip_text=true
   var pw=int(b.get("ovr_%d"%team,0))
   game.label(row,"✓" if won else str(pw),14,game.GOLD if won else TraitUI.power_color(pw),false).tooltip_text="Team power"
  panel.tooltip_text=m.label
 var foot=HBoxContainer.new();foot.add_theme_constant_override("separation",30);body.add_child(foot)
 if b.finished:
  game.label(foot,"CHAMPION · "+WorldTour.team_name(c,int(b.champion)),25,game.GOLD,false)
  var place=WorldTour.placement(c,0)
  game.label(foot,"Your finish: %s"%_place_text(place),20,Color("86dbf2"),false)
 else:
  game.label(foot,"NEXT  ·  %s"%str(next.get("label","")).to_upper(),18,game.GOLD,false)

# ---------------------------------------------------------------- cup progress
## After a cup ends: where you finished, how far along the World Tour you are, and how the team grew.
func progress() -> void:
 var c=game.campaign;var t=c.state.tour
 if t.history.is_empty():game.label(body,"No cups finished yet.",20);return
 var last=t.history[-1];var place=int(last.get("place",0));var won=place==1
 var head=game.label(body,"CUP WON!" if won else "FINISHED %s"%_place_text(place).to_upper(),70,game.GOLD if won else Color("dfe8ec"))
 head.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;head.add_theme_font_override("font",load(game.TITLE_FONT))
 head.add_theme_color_override("font_outline_color",Color("1a0f14"));head.add_theme_constant_override("outline_size",10)
 head.pivot_offset=Vector2(700,40);head.scale=Vector2(0.6,0.6);var pop=create_tween();pop.tween_property(head,"scale",Vector2.ONE,0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
 var sub=game.label(body,"%s  ·  Cup %d of %d  ·  %d wins"%[last.location,int(last.level),WorldTour.MAX_LEVEL,int(last.wins)],20,game.WHITE);sub.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 # The road: the finished cup lights up, the next stop pulses.
 var holder=CenterContainer.new();holder.custom_minimum_size=Vector2(1400,200);body.add_child(holder)
 var box=Control.new();box.custom_minimum_size=Vector2(312*2.6,62*2.6);holder.add_child(box)
 var road=TourPath.new();road.level=int(t.level);road.size=Vector2(312,62);road.scale=Vector2(2.6,2.6);box.add_child(road)
 var chips=HBoxContainer.new();chips.alignment=BoxContainer.ALIGNMENT_CENTER;chips.add_theme_constant_override("separation",40);body.add_child(chips)
 FlowUI.chip(game,chips,"trophy","%d cups won"%int(c.state.get("trophies",0)),"Total cups won this run",game.GOLD)
 FlowUI.chip(game,chips,"coin","%d gold"%int(c.state.gold),"Gold in the bank",Color("ffdf7e"))
 var done=0
 for hh in t.history:done+=1
 FlowUI.chip(game,chips,"swords","%d / %d cups played"%[done,WorldTour.MAX_LEVEL],"World Tour progress")
 if not t.complete and not c.state.get("run_over",false):
  var nxt=WorldTour.region(c)
  var nl=game.label(body,"NEXT STOP  ·  %s  ·  %s"%[str(nxt.name).to_upper(),nxt.place],22,Color(nxt.get("color","e8c27a")));nl.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 # Team growth this cup.
 var grow=HBoxContainer.new();grow.alignment=BoxContainer.ALIGNMENT_CENTER;grow.add_theme_constant_override("separation",18);body.add_child(grow)
 var start=last.get("start_levels",{})
 for h in c.lineup():
  var col=VBoxContainer.new();grow.add_child(col)
  SplashArt.make(col,h.sp,Vector2(120,130))
  var gained=int(h.level)-int(start.get(h.id,h.level))
  var l=game.label(col,"%s  Lv %d%s"%[h.name,int(h.level),("  ▲%d"%gained) if gained>0 else ""],15,Color("6fe08a") if gained>0 else game.WHITE,false);l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  var pw=HeroData.power(h);var p=game.label(col,"%d power"%pw,14,TraitUI.power_color(pw),false);p.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 if won:FlowUI.banner(game,"CHAMPIONS!",game.GOLD,"%s conquers %s"%[c.state.name,last.location])

# ---------------------------------------------------------------- drama
## Replays the matches that just resolved: winners fly gold to their next tile, losers tumble
## down into the losers bracket (or off the board entirely).
func play_results() -> void:
 var c=game.campaign;var anim=c.state.tour.get("last_anim",{})
 var b=c.state.tour.get("bracket",{})
 if anim.is_empty() or b.is_empty() or int(anim.get("level",-1))!=int(b.get("level",-2)):return
 c.state.tour.erase("last_anim")
 var seq:Array=anim.matches
 # Hide arrivals so they can land.
 var hidden=[]
 for idx in seq:
  for j in tiles:
   for side in ["a","b"]:
    var src=b.matches[j][side]
    if (int(src.get("w",-1))==idx or int(src.get("l",-1))==idx) and rows[j].has(side):rows[j][side].modulate.a=0.0;hidden.append([j,side,idx])
 var t=create_tween();var delay=0.5
 for k in range(seq.size()):
  var idx=int(seq[k]);var mine=idx==int(anim.player);var dur=0.9 if mine else 0.38
  var m=b.matches[idx]
  t.tween_callback(func():_resolve_one(b,idx,mine,hidden,dur)).set_delay(delay if k==0 else (1.6 if k==1 else 0.45))
  if mine:t.tween_interval(0.2)
 t.tween_callback(func():
  for h in hidden:
   if rows[h[0]].has(h[1]):rows[h[0]][h[1]].modulate.a=1.0)

func _resolve_one(b: Dictionary,idx: int,mine: bool,hidden: Array,dur: float) -> void:
 if not tiles.has(idx):return
 var m=b.matches[idx];var panel:Control=tiles[idx]
 var flash=create_tween();flash.tween_property(panel,"modulate",Color(1.8,1.6,1.1),0.12);flash.tween_property(panel,"modulate",Color.WHITE,0.3)
 var c=game.campaign
 for outcome in ["w","l"]:
  var team=int(m.winner if outcome=="w" else m.loser);if team<0:continue
  var dest=-1;var dest_side=""
  for j in tiles:
   for side in ["a","b"]:
    if int(b.matches[j][side].get(outcome,-1))==idx:dest=j;dest_side=side
  var ghost=PanelContainer.new();canvas_ref.add_child(ghost);ghost.z_index=20
  var col=game.GOLD if outcome=="w" else Color("ff6b5e")
  ghost.add_theme_stylebox_override("panel",game.style(Color(.1,.08,.04,.95) if outcome=="w" else Color(.14,.03,.03,.95),col,6,6,3 if mine else 2))
  game.label(ghost,WorldTour.team_name(c,team),16 if mine else 13,col,false)
  var side_row=rows[idx].get("a" if int(m.team_a)==team else "b")
  ghost.position=panel.position+(side_row.position if side_row else Vector2.ZERO);ghost.pivot_offset=Vector2(60,12)
  var tw=create_tween()
  if outcome=="w":
   var to=tiles[dest].position+Vector2(6,6 if dest_side=="a" else 36) if dest>=0 else panel.position+Vector2(TILE.x+40,0)
   tw.tween_property(ghost,"scale",Vector2(1.25,1.25),dur*0.25).set_trans(Tween.TRANS_BACK)
   tw.tween_property(ghost,"position",to,dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
   tw.parallel().tween_property(ghost,"scale",Vector2.ONE,dur)
  else:
   if dest>=0:
    var to=tiles[dest].position+Vector2(6,6 if dest_side=="a" else 36)
    tw.tween_property(ghost,"rotation",0.25,dur*0.2)
    tw.tween_property(ghost,"position",to,dur*1.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
    tw.parallel().tween_property(ghost,"rotation",0.0,dur*1.2)
   else:
    # Eliminated: the name falls off the board.
    tw.tween_property(ghost,"position",ghost.position+Vector2(30,520),dur*1.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    tw.parallel().tween_property(ghost,"rotation",1.4,dur*1.6)
    tw.parallel().tween_property(ghost,"modulate:a",0.0,dur*1.6)
  tw.tween_callback(func():
   for h in hidden:
    if h[0]==dest and h[1]==dest_side and h[2]==idx and rows[dest].has(dest_side):
     rows[dest][dest_side].modulate.a=1.0
     var pop=create_tween();pop.tween_property(tiles[dest],"scale",Vector2(1.06,1.06),0.08);pop.tween_property(tiles[dest],"scale",Vector2.ONE,0.15)
   if outcome=="w" or dest>=0:ghost.queue_free())
 if mine:
  var won=int(m.winner)==0;var out=not won and WorldTour.losses(c,0)>=2
  game.sound.cue("victory" if won else "honor",true)
  if not won:
   var shake=create_tween()
   for k in range(6):shake.tween_property(canvas_ref,"position:x",(8.0 if k%2==0 else -8.0)*(1.0-k/6.0),0.05)
   shake.tween_property(canvas_ref,"position:x",0.0,0.05)
  var b2=c.state.tour.bracket
  var text="ADVANCES!" if won else ("ELIMINATED" if out else "DROPPED TO LOSERS")
  if b2.finished and int(b2.champion)==0:text="CHAMPIONS!"
  FlowUI.banner(game,text,game.GOLD if won else Color("ff6b5e"),WorldTour.team_name(c,int(m.winner))+" beat "+WorldTour.team_name(c,int(m.loser)))

## A carved wooden tournament board: warm grain, darker edges, a lantern glow in the middle.
func board_backing(canvas: Control) -> void:
 var wood=ColorRect.new();wood.mouse_filter=Control.MOUSE_FILTER_IGNORE;canvas.add_child(wood);wood.position=Vector2(-16,-8);wood.size=Vector2(1442,616)
 var sh=Shader.new();sh.code="""shader_type canvas_item;
float h(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float n(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.-2.*f);return mix(mix(h(i),h(i+vec2(1,0)),f.x),mix(h(i+vec2(0,1)),h(i+vec2(1,1)),f.x),f.y);}
void fragment(){
 vec2 uv=UV*vec2(1442.,616.);
 float plank=floor(uv.y/77.);
 float g=n(vec2(uv.x*0.012+plank*13.,uv.y*0.35))*0.6+n(vec2(uv.x*0.05,uv.y*0.9+plank*7.))*0.4;
 float rings=0.5+0.5*sin(uv.x*0.02+g*9.+plank*3.);
 vec3 c=mix(vec3(0.16,0.09,0.05),vec3(0.32,0.19,0.10),g*0.7+rings*0.3);
 float seam=smoothstep(0.0,2.5,abs(mod(uv.y,77.)-0.5));c*=mix(0.45,1.,seam);
 vec2 d=UV-vec2(.5,.48);c*=1.15-dot(d,d)*1.6;
 c+=vec3(0.35,0.22,0.08)*exp(-dot(d,d)*6.)*0.35;
 COLOR=vec4(c,1.);
}"""
 var m=ShaderMaterial.new();m.shader=sh;wood.material=m
 # Iron frame around the board.
 if game.campaign.state.has("tour"):wood.modulate=Color(1,1,1).lerp(Color(WorldTour.region(game.campaign).color),0.25)

func _source_text(src: Dictionary) -> String:
 if src.has("w"):return "Winner of %s"%_short(int(src.w))
 if src.has("l"):return "Loser of %s"%_short(int(src.l))
 return "Seed %d"%(int(src.get("seed",0))+1)

func _short(i: int) -> String:
 return ["W1-A","W1-B","W1-C","W1-D","W Semi A","W Semi B","Winners Final","L1-A","L1-B","L2-A","L2-B","Losers Semi","Losers Final","Grand Final","Reset"][i]

static func _place_text(place: int) -> String:
 return {1:"Champion",2:"2nd",3:"3rd",4:"4th",5:"5th–6th",7:"7th–8th"}.get(place,"—")

func vault() -> void:
 var c=game.campaign;TrophyVault.sync(c);var data=TrophyVault.data
 game.label(body,"LEGACY  ·  +%d%% health  /  +%d%% attack  ·  %d / 32 evolutions"%[data.vitality,data.might,data.unlocks.size()],20,game.GOLD)
 game.label(body,"Finish 1st, 2nd or 3rd to earn a Gold, Silver or Bronze chest of Forge items. Gold chests also unlock evolutions and permanent legacy boosts.",16,game.MUTED)
 if not reveal.is_empty():
  var row=HBoxContainer.new();body.add_child(row)
  for reward in reveal.rewards:
   var box=tile(row)
   if reward.has("species"):HeadlinerUI.portrait(box,{"sp":reward.species},100)
   if reward.get("kind","")=="item":GearUI.token(game,box,Forge.info(reward.item),84)
   game.label(box,reward.title,24,game.GOLD);game.label(box,reward.detail,17)
 game.label(body,"Awakening replaces your current path: a fifth action, with −10% attack.",16,game.GOLD)
 var chests=TrophyVault.unopened(c)
 if not chests.is_empty():
  var row=HBoxContainer.new();body.add_child(row)
  for chest in chests:
   var medal=str(chest.get("medal","Gold"));var mc=Color({"Gold":"ffd36e","Silver":"d8e4ee","Bronze":"d9935a"}[medal])
   var box=tile(row);box.get_parent().add_theme_stylebox_override("panel",game.style(Color(.06,.08,.1,.96),mc,6,14,3))
   game.label(box,"◆  %s CHEST"%medal.to_upper(),22,mc);game.label(box,chest.location,16)
   game.label(box,{"Gold":"Finished item, WILD item, 2 components, 150 gold, evolution","Silver":"Finished item, 2 components, 100 gold","Bronze":"2 components, 60 gold"}[medal],14,game.MUTED)
   game.button(box,"Open chest",func():
    reveal=TrophyVault.open(c,chest.id)
    if reveal.is_empty():game.toast(TrophyVault.error if not TrophyVault.error.is_empty() else "Could not save the chest reward. Please try again.")
    else:ChestOpening.play(game,reveal,refresh)
    refresh(),true)
 else:game.label(body,"No unopened chests · Your next crown awaits",17,game.MUTED)
 var grid=GridContainer.new();grid.columns=4;grid.add_theme_constant_override("h_separation",12);grid.add_theme_constant_override("v_separation",12);body.add_child(grid)
 for sp in HeroData.species:
  var box=tile(grid);box.get_parent().custom_minimum_size.x=340
  var unlocked=sp in data.unlocks;var row=HBoxContainer.new();box.add_child(row)
  var art=HeadlinerUI.portrait(row,{"sp":sp},76);art.modulate=Color.WHITE if unlocked else Color(0.45,0.45,0.5)
  var words=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(words)
  game.label(words,ChampionEvolution.NAMES[sp],18,ChampionEvolution.color(sp) if unlocked else game.MUTED)
  game.label(words,"UNLOCKED" if unlocked else "WIN A CHEST",12,game.GOLD if unlocked else game.MUTED)
  box.tooltip_text=ChampionEvolution.info({"sp":sp}).description
  game.button(box,"Preview evolution action",func():
   var demo=AbilityPreview.new();demo.game=game;demo.hero=HeroData.make_hero(sp,"evolution_preview",HeroData.species[sp].n,10)
   demo.hero.evolution="ascended"
   var ability=ChampionEvolution.action(sp)
   demo.card={"type":"ability","key":"12","name":ability.name,"description":ability.description,"rarity":"Legendary","bonus":1.0}
   game.ui.add_child(demo);demo.build())
  for h in c.state.roster:
   if h.sp!=sp:continue
   var ready=unlocked and h.level>=10 and h.pending.is_empty() and h.evolution!="ascended"
   game.button(box,"Awaken "+h.name if ready else "Awakened" if h.evolution=="ascended" else h.name+" · Reach Lv 10" if h.level<10 else "Finish level-up choices" if not h.pending.is_empty() else "Evolution locked",func():
    if TrophyVault.awaken(c,h.id):game.sound.cue("upgrade",true);refresh()
    else:game.toast(c.last_error),ready,not ready)
func _unhandled_key_input(event: InputEvent) -> void:
 if event.is_action_pressed("ui_cancel"):get_viewport().set_input_as_handled();game.render()
static func open_screen(game_node: Node,screen: String,then:=Callable(),then_text:="Continue  ▶",play:=false) -> TournamentRewardsUI:
 var view=TournamentRewardsUI.new();view.game=game_node;view.mode=screen;view.on_continue=then;view.continue_text=then_text;view.animate=play;game_node.ui.add_child(view)
 if play and screen=="bracket":view.play_results()
 return view
