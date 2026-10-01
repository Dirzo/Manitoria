class_name TournamentRewardsUI
extends Control
var game: Node
var mode="bracket"
var reveal: Dictionary={}
var body: VBoxContainer
func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter=Control.MOUSE_FILTER_STOP
 var shade=ColorRect.new();shade.color=Color(0.015,0.025,0.07,0.97);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shade)
 var frame=FantasyFrame.new();frame.position=Vector2(50,105);frame.size=Vector2(1500,755);add_child(frame)
 frame.add_theme_stylebox_override("panel",game.style(Color("12282e"),game.GOLD,14,24,2))
 var layout=VBoxContainer.new();layout.add_theme_constant_override("separation",16);frame.add_child(layout)
 var header=HBoxContainer.new();layout.add_child(header)
 game.label(header,"THE TOURNAMENT" if mode=="bracket" else "CHAMPION'S VAULT",30,game.GOLD).size_flags_horizontal=Control.SIZE_EXPAND_FILL
 game.button(header,"Close",func():game.render())
 var scroll=ScrollContainer.new();scroll.custom_minimum_size=Vector2(1435,650);scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;layout.add_child(scroll)
 body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",18);scroll.add_child(body)
 refresh()
func refresh() -> void:
 for child in body.get_children():body.remove_child(child);child.queue_free()
 if mode=="bracket":bracket()
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
 game.label(body,"%s · Level %d · Double elimination — lose twice and you're out. The losers' champion must win the grand final twice."%[WorldTour.REGIONS[(int(b.level)-1)%6].name,b.level],17,game.GOLD)
 var canvas=Control.new();canvas.custom_minimum_size=Vector2(1410,600);body.add_child(canvas)
 for cap in [["WINNERS BRACKET",Vector2(0,6),Color("8fd7ff")],["LOSERS BRACKET",Vector2(0,386),Color("ffa98f")],["GRAND FINAL",Vector2(1140,234),game.GOLD]]:
  var l=game.label(canvas,cap[0],18,cap[2],false);l.position=cap[1]
 # connectors
 for target in FEEDS:
  for src in FEEDS[target]:
   var from:Vector2=POS[src]+Vector2(TILE.x,TILE.y*0.5);var to:Vector2=POS[target]+Vector2(0,TILE.y*0.5)
   var mid=(from.x+to.x)*0.5
   var line=Line2D.new();line.width=2;line.default_color=Color("5d7a8f") if not (src==6 and target==12) else Color("8a5d5d")
   line.points=PackedVector2Array([from,Vector2(mid,from.y),Vector2(mid,to.y),to]);canvas.add_child(line)
 var next=WorldTour.current_match(c) if not b.finished else {}
 for i in range(b.matches.size()):
  var m=b.matches[i]
  if i==14 and m.skipped:continue
  var panel=PanelContainer.new();canvas.add_child(panel);panel.position=POS[i];panel.size=TILE
  var is_next=not next.is_empty() and next==m
  panel.add_theme_stylebox_override("panel",game.style(Color("1d3238") if not is_next else Color("3a3220"),game.GOLD if is_next else Color("57738c"),6,8,2 if is_next else 1))
  var box=VBoxContainer.new();box.add_theme_constant_override("separation",2);panel.add_child(box)
  for side in ["a","b"]:
   var team=int(m["team_"+side]);var row=HBoxContainer.new();row.add_theme_constant_override("separation",6);box.add_child(row)
   if team<0:
    game.label(row,_source_text(m[side]),13,game.MUTED,false);continue
   var seed=b.seeds.find(team)+1
   game.label(row,str(seed),12,game.MUTED,false).custom_minimum_size.x=14
   var roster=WorldTour.team_roster(c,team)
   var face=c.headliner() if team==0 else HeadlinerUI.rival_face(c,{"club":team,"roster":roster})
   if not face.is_empty():HeadlinerUI.portrait(row,face,22)
   var won=int(m.winner)==team;var lost=int(m.loser)==team
   var name=game.label(row,WorldTour.team_name(c,team),14,game.GOLD if won else Color("86dbf2") if team==0 else (game.MUTED if lost else game.WHITE),false)
   name.size_flags_horizontal=Control.SIZE_EXPAND_FILL;name.clip_text=true
   game.label(row,"✓" if won else str(b.get("ovr_%d"%team,"")),13,game.GOLD if won else game.MUTED,false)
  panel.tooltip_text=m.label
 var foot=HBoxContainer.new();foot.add_theme_constant_override("separation",30);body.add_child(foot)
 if b.finished:
  game.label(foot,"CHAMPION · "+WorldTour.team_name(c,int(b.champion)),25,game.GOLD,false)
  var place=WorldTour.placement(c,0)
  game.label(foot,"Your finish: %s"%_place_text(place),20,Color("86dbf2"),false)
 else:
  game.label(foot,"Next: %s  ·  Your record %d–%d  ·  Outfitter between every match  ·  Podium finishes earn Gold, Silver or Bronze chests; every club moves on to the next cup"%[next.get("label",""),int(c.state.tour.wins),WorldTour.losses(c,0)],16,game.MUTED,false)

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
    else:game.sound.cue("upgrade",true)
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
static func open_screen(game_node: Node,screen: String) -> void:
 var view=TournamentRewardsUI.new();view.game=game_node;view.mode=screen;game_node.ui.add_child(view)
