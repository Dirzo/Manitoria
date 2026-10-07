class_name ChampionWardrobe
extends RefCounted
static func build(desk: ManagementDesk) -> void:
 var game=desk.game;var c=game.campaign;var hero=GearUI.selected(game)
 var top=HBoxContainer.new();top.add_theme_constant_override("separation",10);desk.body.add_child(top)
 var title=game.label(top,"YOUR CHAMPIONS",30);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var jump=game.button(top,"Formation & XP  ▼",func():pass)
 game.button(top,"Auto lineup",func():c.suggest_lineup();game.render(),false,c.state.roster.is_empty())
 if c.recruitment_open():game.button(top,"Recruit",func():desk.navigate("market"))
 if hero.is_empty():game.label(desk.body,"Recruit your first champion to begin.",25);return
 next_steps(desk)
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",12);desk.body.add_child(row)
 for h in c.lineup():champion(desk,row,h)
 for i in range(5-c.lineup().size()):
  var empty=FantasyFrame.new();empty.custom_minimum_size=Vector2(280,338);row.add_child(empty)
  var box=VBoxContainer.new();empty.add_child(box);game.label(box,"+",62,game.GOLD).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  if c.recruitment_open():game.button(box,"Recruit",func():desk.navigate("market"))
  else:game.label(box,"Roster locked until cup ends",14,game.MUTED)
 var lower=HBoxContainer.new();lower.add_theme_constant_override("separation",14);desk.body.add_child(lower)
 jump.pressed.connect(func():
  var sc=desk.body.get_parent()
  if not sc is ScrollContainer:return
  var tw=sc.create_tween();tw.tween_property(sc,"scroll_vertical",int(lower.position.y)-10,0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT))
 formation(desk,lower)
 presets(desk,lower)
 xp_guide(desk,lower)
 var bench=TraitUI.sorted(c.state.roster.filter(func(h):return h.slot<0),game.desk_state.get("sort","Board"))
 if not bench.is_empty():
  var reserve=HBoxContainer.new();desk.body.add_child(reserve);game.label(reserve,"RESERVES",15,game.GOLD)
  TraitUI.sort_bar(game,reserve)
  for h in bench:
   var button=GearUI.hero_button(game,reserve,h,60,false)
   button.tooltip_text="Click to field or replace a starter. Drop gear here to equip.\nXP priority: "+str(h.get("xp_priority","normal")).capitalize()+(" (trains on the bench)" if h.get("xp_priority","normal")=="focus" else "")
   button.pressed.connect(func():desk.field_hero(h))
   priority_toggle(desk,reserve,h,true)
 var bag=FantasyFrame.new();desk.body.add_child(bag);var bag_box=VBoxContainer.new();bag.add_child(bag_box);bag_box.add_theme_constant_override("separation",6)
 GearUI.bag(game,bag_box,hero)
 var tools=HBoxContainer.new();desk.body.add_child(tools)
 game.label(tools,"Selected: "+hero.name,16,game.GOLD).size_flags_horizontal=Control.SIZE_EXPAND_FILL
 game.button(tools,"Hero details",func():desk.profile(hero,true))
 game.button(tools,"Compare / stats",func():performance(desk))

## The loop at a glance: what a battle earns and where it goes.
static func next_steps(desk: ManagementDesk) -> void:
 var game=desk.game;var c=game.campaign;var fresh=c.state.get("roster_intro",false)
 var strip=PanelContainer.new();desk.body.add_child(strip)
 strip.add_theme_stylebox_override("panel",game.style(Color(0.16,0.11,0.05,0.92) if fresh else Color(0.05,0.07,0.1,0.8),Color("ffd36e") if fresh else Color(0,0,0,0),10,10,2 if fresh else 0))
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",26);row.alignment=BoxContainer.ALIGNMENT_CENTER;strip.add_child(row)
 if fresh:game.label(row,"YOUR SQUAD IS SET",18,game.GOLD,false)
 for step in [["swords","Win battles","gold + XP for everyone who fights"],["coin","Outfitter after every match","buy components, forge items"],["star","Level up","new skills · Rare & Legendary rolls · Lv %d evolution" % EVOLVE_LEVEL]]:
  var cell=HBoxContainer.new();cell.add_theme_constant_override("separation",8);row.add_child(cell)
  FlowUI.glyph(cell,step[0],26)
  var v=VBoxContainer.new();v.add_theme_constant_override("separation",0);cell.add_child(v)
  game.label(v,step[1],16,Color.WHITE,false);game.label(v,step[2],12,Color("c9d6dc"),false)

const EVOLVE_LEVEL := HeroData.EVOLVE_LEVEL
const LEGEND_LEVEL := 5

## XP bar + the next milestone this champion is working toward.
static func xp_block(game: Node,parent: Node,h: Dictionary) -> void:
 var lv=int(h.level);var need=HeroData.xp_needed(lv)
 var head=HBoxContainer.new();parent.add_child(head)
 var l=game.label(head,"Lv %d  ·  %d/%d XP"%[lv,int(h.xp),need],12,Color("c9d6dc"),false);l.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var goal=""
 if lv<LEGEND_LEVEL:goal="Legendary rolls in %d Lv"%(LEGEND_LEVEL-lv)
 elif str(h.get("evolution","")).is_empty() and lv<EVOLVE_LEVEL:goal="Evolves in %d Lv"%(EVOLVE_LEVEL-lv)
 elif str(h.get("evolution","")).is_empty():goal="Evolution ready!"
 else:goal=HeroData.evolution_info(h).get("name","Evolved")
 game.label(head,goal,12,Color("ffb3ec") if goal.begins_with("Evol") else Color("ffd36e"),false)
 var bar=ProgressBar.new();bar.max_value=need;bar.value=int(h.xp);bar.show_percentage=false;bar.custom_minimum_size=Vector2(0,7);parent.add_child(bar)
 bar.add_theme_stylebox_override("background",game.style(Color("1d2a31"),Color.TRANSPARENT,4,0,0))
 bar.add_theme_stylebox_override("fill",game.style(Color("8fd4ff") if h.get("xp_priority","normal")!="focus" else Color("ffd36e"),Color.TRANSPARENT,4,0,0))

## Rest · Normal · Focus selector for a champion's share of battle XP.
static func priority_toggle(desk: ManagementDesk,parent: Node,h: Dictionary,small:=false) -> void:
 var game=desk.game;var c=game.campaign
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",3);row.alignment=BoxContainer.ALIGNMENT_CENTER;parent.add_child(row)
 if not small:game.label(row,"XP",12,Color("9fb0b8"),false)
 var cur=str(h.get("xp_priority","normal"))
 for opt in [["rest","Rest","Earns less XP (45% share) so others level faster."],["normal","Normal","An even share of battle XP."],["focus","★ Focus","Earns a much bigger share (160%%) and trains even from the bench. Up to %d champions."%Campaign.MAX_FOCUS]]:
  var on=cur==opt[0]
  var b=Button.new();b.text=opt[1];b.tooltip_text=opt[2];b.focus_mode=Control.FOCUS_NONE;row.add_child(b)
  b.add_theme_font_size_override("font_size",11 if small else 12)
  var col=Color("ffd36e") if opt[0]=="focus" else (Color("8fd4ff") if opt[0]=="normal" else Color("9fb0b8"))
  b.add_theme_stylebox_override("normal",game.style(col.darkened(0.55) if on else Color(0.08,0.09,0.12,0.9),col if on else Color(0,0,0,0),6,5,2 if on else 0))
  b.add_theme_stylebox_override("hover",game.style(col.darkened(0.4),col,6,5,2))
  b.add_theme_color_override("font_color",col.lightened(0.3) if on else Color("9fb0b8"))
  var key=opt[0]
  b.pressed.connect(func():
   if c.set_xp_priority(h.id,key):game.sound.cue("contest_reveal");game.render()
   else:game.toast(c.last_error))

## Inline formation board: click a square to move the selected champion, or drag between squares.
static func formation(desk: ManagementDesk,parent: Node) -> void:
 var game=desk.game;var c=game.campaign
 var frame=PanelContainer.new();parent.add_child(frame);frame.add_theme_stylebox_override("panel",game.style(Color(0.05,0.07,0.1,0.85),Color(0,0,0,0),10,12,0))
 var box=VBoxContainer.new();box.add_theme_constant_override("separation",6);frame.add_child(box)
 var sel=c.hero_by_id(game.selected_id)
 var fh=HBoxContainer.new();box.add_child(fh)
 game.label(fh,"FORMATION",18,game.GOLD,false).size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var std=game.button(fh,"Standard",func():
  if c.standard_formation():game.sound.cue("contest_lock");game.render());std.add_theme_font_size_override("font_size",13)
 std.tooltip_text="Front-liners to the front, flankers to the middle, ranged to the back."
 game.label(box,("Click a square to move "+str(sel.get("name",""))) if not sel.is_empty() else "Select a champion, then click a square",12,Color("c9d6dc"),false)
 var heads=HBoxContainer.new();box.add_child(heads)
 for t in ["BACK","MIDDLE","FRONT →"]:
  var l=game.label(heads,t,11,Color("9fb0b8"),false);l.custom_minimum_size.x=104;l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 var grid=GridContainer.new();grid.columns=3;grid.add_theme_constant_override("h_separation",4);grid.add_theme_constant_override("v_separation",4);box.add_child(grid)
 for slot in range(15):
  var cell=FormationCell.new();cell.destination=slot;cell.custom_minimum_size=Vector2(100,30);cell.focus_mode=Control.FOCUS_NONE
  cell.add_theme_font_size_override("font_size",12);cell.clip_text=true
  var here=c.lineup().filter(func(h):return h.slot==slot)
  cell.hero_id=here[0].id if not here.is_empty() else ""
  cell.text=here[0].name if not here.is_empty() else ""
  var col=SkillCombat.tint(here[0].sp) if not here.is_empty() else Color(1,1,1,0.08)
  var picked=not here.is_empty() and here[0].id==game.selected_id
  cell.add_theme_stylebox_override("normal",game.style(Color(col,0.35) if not here.is_empty() else Color(1,1,1,0.05),game.GOLD if picked else Color(0,0,0,0),6,3,2 if picked else 0))
  cell.add_theme_stylebox_override("hover",game.style(Color(1,1,1,0.16),game.GOLD,6,3,1))
  cell.placed.connect(game.place_hero)
  cell.pressed.connect(func():
   if cell.hero_id!="" and cell.hero_id!=game.selected_id:game.selected_id=cell.hero_id;game.render()
   elif game.selected_id!="":game.place_hero(game.selected_id,slot))
  grid.add_child(cell)

## Three saved formations: store who starts and where, and swap between them in one click.
static func presets(desk: ManagementDesk,parent: Node) -> void:
 var game=desk.game;var c=game.campaign
 var frame=PanelContainer.new();parent.add_child(frame);frame.add_theme_stylebox_override("panel",game.style(Color(0.05,0.07,0.1,0.85),Color(0,0,0,0),10,12,0))
 var box=VBoxContainer.new();box.add_theme_constant_override("separation",8);frame.add_child(box)
 game.label(box,"SAVED FORMATIONS",18,game.GOLD,false)
 var list=c.state.get("formations",[])
 for i in range(Campaign.FORMATION_SLOTS):
  var saved=i<list.size() and not list[i].is_empty()
  var r=HBoxContainer.new();r.add_theme_constant_override("separation",6);box.add_child(r)
  var names="—"
  if saved:
   var ids=list[i].slots.keys();var nm=[]
   for id in ids:
    var h=c.hero_by_id(id)
    if not h.is_empty():nm.append(h.name)
   names=", ".join(nm)
  var l=game.label(r,"%d · %s"%[i+1,names],12,Color.WHITE if saved else Color("6f7d85"),false);l.custom_minimum_size.x=210;l.clip_text=true;l.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
  var idx=i
  game.button(r,"Load",func():
   if c.load_formation(idx):game.sound.cue("contest_lock");game.render()
   else:game.toast(c.last_error),false,not saved).add_theme_font_size_override("font_size",13)
  game.button(r,"Save",func():
   if c.save_formation(idx):game.toast("Saved as formation %d"%(idx+1));game.render(),false,not c.lineup_ready()).add_theme_font_size_override("font_size",13)
 game.label(box,"Tactics: use each card's Tactics button",12,Color("9fb0b8"),false)

## How XP priority works, and who is focused right now.
static func xp_guide(desk: ManagementDesk,parent: Node) -> void:
 var game=desk.game;var c=game.campaign
 var frame=PanelContainer.new();frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(frame);frame.add_theme_stylebox_override("panel",game.style(Color(0.05,0.07,0.1,0.85),Color(0,0,0,0),10,12,0))
 var box=VBoxContainer.new();box.add_theme_constant_override("separation",6);frame.add_child(box)
 game.label(box,"XP PRIORITY",18,game.GOLD,false)
 game.label(box,"Battle XP is shared by priority. Focus up to %d champions to rush them to Legendary skill rolls (Lv %d) and evolution (Lv %d). Focused reserves train from the bench."%[Campaign.MAX_FOCUS,LEGEND_LEVEL,EVOLVE_LEVEL],12,Color("c9d6dc"),true)
 var grid=GridContainer.new();grid.columns=4;grid.add_theme_constant_override("h_separation",18);grid.add_theme_constant_override("v_separation",4);box.add_child(grid)
 for h in c.state.roster:
  var pr=str(h.get("xp_priority","normal"))
  var col=Color("ffd36e") if pr=="focus" else (Color("8fd4ff") if pr=="normal" else Color("9fb0b8"))
  game.label(grid,h.name+(" (bench)" if h.slot<0 else ""),13,Color.WHITE,false)
  game.label(grid,"Lv %d"%int(h.level),13,Color("c9d6dc"),false)
  game.label(grid,("★ " if pr=="focus" else "")+pr.capitalize(),13,col,false)
  var lv=int(h.level);var goal=("Legendary rolls in %d Lv"%(LEGEND_LEVEL-lv)) if lv<LEGEND_LEVEL else (("Evolves in %d Lv"%(EVOLVE_LEVEL-lv)) if lv<EVOLVE_LEVEL and str(h.get("evolution","")).is_empty() else ("Evolution ready!" if str(h.get("evolution","")).is_empty() else HeroData.evolution_info(h).get("name","Evolved")))
  game.label(grid,goal,13,Color("ffb3ec") if goal.begins_with("Evol") else Color("ffd36e"),false)

static func champion(desk: ManagementDesk,parent: Node,h: Dictionary) -> void:
 var game=desk.game;var selected=h.id==game.selected_id
 var frame=FantasyFrame.new();frame.accent=game.GOLD if selected else SkillCombat.tint(h.sp);frame.custom_minimum_size=Vector2(280,360);parent.add_child(frame)
 frame.add_theme_stylebox_override("panel",game.style(Color(.09,.055,.16,.93),frame.accent,4,12,2))
 var box=VBoxContainer.new();box.add_theme_constant_override("separation",6);frame.add_child(box)
 var name_label=game.label(box,h.name+" · "+str(h.level),24,game.GOLD if selected else game.WHITE);name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 game.label(box,ChampionStars.label(h),13,game.GOLD,false).tooltip_text=ChampionStars.description(h)
 var evo=game.label(box,ChampionStars.evolution_label(h),12,HeroData.evolution_color(h) if not str(h.get("evolution","")).is_empty() else game.MUTED);evo.tooltip_text=HeroData.evolution_info(h).get("description","Choose a species evolution at level eight; it unlocks a fourth item slot.")
 var preview_holder=GearToken.new();preview_holder.game=game;preview_holder.target_hero=h.id;preview_holder.custom_minimum_size=Vector2(252,120);box.add_child(preview_holder);preview_holder.name="Champion_"+h.id
 preview_holder.add_theme_stylebox_override("normal",StyleBoxEmpty.new());preview_holder.pressed.connect(func():game.selected_id=h.id;game.render())
 var preview=SplashArt.new();preview.sp=h.sp;preview_holder.add_child(preview);preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);preview.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var role=game.label(box,HeroData.species[h.sp].n+"  ·  "+("★ " if Traits.is_ideal(h) else "")+Traits.trait_of(h),15,TraitUI.IDEAL if Traits.is_ideal(h) else game.MUTED);role.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;role.tooltip_text=Traits.describe(h)+"\n"+Traits.scaling_text(h.sp)+" · "+Traits.info(h.sp).calling
 TraitUI.rolls(game,box,h,true)
 var slots=HBoxContainer.new();slots.alignment=BoxContainer.ALIGNMENT_CENTER;slots.add_theme_constant_override("separation",12);box.add_child(slots)
 for key in GearUI.slot_keys(h):GearUI.slot(game,slots,h,key,62)
 xp_block(game,box,h)
 priority_toggle(desk,box,h)
 var actions=HBoxContainer.new();actions.alignment=BoxContainer.ALIGNMENT_CENTER;box.add_child(actions)
 var tb=game.button(actions,"Tactics",func():game.show_tactics(h.id));tb.add_theme_font_size_override("font_size",14);tb.tooltip_text="Current orders: "+BattleTactics.summary(h)
 game.button(actions,"Details",func():desk.profile(h,true)).add_theme_font_size_override("font_size",14)
 var bench=game.button(actions,"↓",func():game.campaign.bench(h.id);game.render());bench.tooltip_text="Move to reserves"

static func game_sort(desk: ManagementDesk) -> String:
 return desk.game.desk_state.get("sort","Board")

static func performance(desk: ManagementDesk) -> void:
 var dialog=desk.overlay("Champion statistics")
 var table=GridContainer.new();table.columns=6;table.add_theme_constant_override("h_separation",40);dialog.body.add_child(table)
 for title in ["HERO","LEVEL","POWER","KILLS","IMPACT / MATCH","COMPARE"]:desk.text(table,title,14,desk.GOLD)
 for h in TraitUI.sorted(desk.state.roster,game_sort(desk)):
  desk.action(table,h.name,func():dialog.root.queue_free();desk.profile(h,true))
  desk.text(table,str(h.level));desk.text(table,str(HeroData.power(h)));desk.text(table,str(h.kills));desk.text(table,"%.1f"%(h.impact/maxf(1,h.bouts)))

  desk.action(table,"Selected" if h.id in desk.prefs.compare else "Select",func():
   if h.id in desk.prefs.compare:desk.prefs.compare.erase(h.id)
   else:
    if desk.prefs.compare.size()>=2:desk.prefs.compare.pop_front()
    desk.prefs.compare.append(h.id)
   dialog.root.queue_free();performance(desk))
 desk.action(dialog.body,"Compare selected",func():dialog.root.queue_free();desk.compare_heroes(),true,desk.prefs.compare.size()!=2)
