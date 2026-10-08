class_name SpeedrunUI
extends RefCounted

static func refresh(game: Node,lab: SpeedrunLab) -> void:
 game.campaign.state.speedrun_plan=lab.plan.duplicate(true);game.campaign.save();game.render()

static func build(game: Node,lab: SpeedrunLab) -> void:
 if not is_instance_valid(lab):game.phase="hub";game.render();return
 if lab.plan.is_empty():lab.reset_plan()
 var top=game.panel(Rect2(26,136,1548,102));var bar=HBoxContainer.new();top.add_child(bar)
 game.label(bar,"SPEEDRUN STAT CHECK",28,game.GOLD,false).size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var cups=OptionButton.new();cups.add_item("5 cups");cups.add_item("10 cups");cups.selected=0 if int(lab.plan.cups)==5 else 1;cups.disabled=lab.running;bar.add_child(cups)
 cups.item_selected.connect(func(i):lab.plan.cups=5 if i==0 else 10;refresh(game,lab))
 var diff=OptionButton.new()
 for name in ["Keeper","Standard","Champion"]:diff.add_item(name)
 diff.selected=["Keeper","Standard","Champion"].find(lab.plan.difficulty);diff.disabled=lab.running;bar.add_child(diff)
 diff.item_selected.connect(func(i):lab.plan.difficulty=["Keeper","Standard","Champion"][i];refresh(game,lab))
 var seed_label=game.label(bar,"Seed %d"%int(game.campaign.state.seed),15,game.MUTED,false)
 seed_label.tooltip_text="Same draft, plan and seed produce the same combat outcomes."
 if lab.running:
  var cancel=game.button(bar,"Cancel",func():lab.cancelled=true);cancel.name="SpeedrunCancel"
 else:
  game.button(bar,"History",func():history(game,lab))
  game.button(bar,"Draft / roster",func():game.phase="hub";game.tab="roster";game.render())
  var start=game.button(bar,"SIMULATE ▶",lab.start,true);start.name="SpeedrunSimulate";start.tooltip_text="Simulate your current draft and priorities. Viewing history does not replace your draft."
 var state=game.label(top,lab.status,16,Color("94e0af"));state.name="SpeedrunStatus"
 if lab.running:
  game.label(top,"Running real hex combat, player rewards and all CPU bracket matches. Cancel preserves partial results.",13,game.MUTED)
  var box=game.scroll_panel(Rect2(26,254,1548,610));game.label(box,"Your plan is locked while the run is simulating.",24)
  for h in game.campaign.lineup():game.label(box,h.name+" · "+HeroData.species[h.sp].n+" · "+str(lab.plan.goals.get(h.id,"Adaptive")),20)
  return
 if not lab.result.is_empty():
  results(game,lab);return
 formation(game,lab)
 priorities(game,lab)
 evolutions(game,lab)

static func formation(game: Node,lab: SpeedrunLab) -> void:
 var c: Campaign=game.campaign;var box=game.scroll_panel(Rect2(26,254,368,610))
 game.label(box,"1 · FORMATION",22,game.GOLD)
 game.label(box,"Select a champion, then a hex. Occupied hexes swap champions.",14,game.MUTED)
 if not c.lineup().any(func(h):return h.id==game.selected_id):game.selected_id=c.lineup()[0].id
 for h in c.lineup():
  var row=HBoxContainer.new();box.add_child(row);SplashArt.make(row,h.sp,Vector2(38,38))
  var select=game.button(row,("● " if game.selected_id==h.id else "")+h.name,func():game.selected_id=h.id;game.render());select.size_flags_horizontal=Control.SIZE_EXPAND_FILL;select.add_theme_font_size_override("font_size",16)
 game.label(box,"BACK        MID        FRONT →",13,game.GOLD)
 var grid=Control.new();grid.custom_minimum_size=Vector2(310,300);box.add_child(grid)
 for slot in range(15):
  var cell=FormationCell.new();cell.destination=slot;cell.position=Vector2((slot%3)*94,(slot/3)*52+(26 if slot%3==1 else 0));cell.size=Vector2(94,52)
  var occupants=c.lineup().filter(func(h):return int(h.slot)==slot)
  cell.hero_id=occupants[0].id if not occupants.is_empty() else "";cell.caption=occupants[0].name if not occupants.is_empty() else "+";cell.selected=cell.hero_id==game.selected_id
  cell.placed.connect(func(id,destination):c.place_hero(id,destination);refresh(game,lab))
  cell.pressed.connect(func():c.place_hero(game.selected_id,slot);refresh(game,lab));grid.add_child(cell)
 game.button(box,"Standard formation",func():c.standard_formation();refresh(game,lab))
 game.label(box,"Starting gold: %d · Same squad stays through every cup."%int(c.state.gold),14,game.MUTED)

static func priorities(game: Node,lab: SpeedrunLab) -> void:
 var box=game.scroll_panel(Rect2(408,254,660,610))
 game.label(box,"2 · ITEM PRIORITIES · %d / 20"%lab.plan.items.size(),22,game.GOLD)
 game.label(box,"Each row buys one item at its two-component cost. Choose a target or let build fit decide. No free gear; no random shop offers. Full slots wait for evolution.",14,game.MUTED)
 var row=HBoxContainer.new();box.add_child(row)
 var search=LineEdit.new();search.placeholder_text="Search items…";search.text=lab.item_filter;search.custom_minimum_size.x=170;row.add_child(search)
 var select=OptionButton.new();select.custom_minimum_size.x=300;select.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(select)
 var ids=Forge.ITEMS.keys();ids.sort_custom(func(a,b):return str(Forge.info(a).name)<str(Forge.info(b).name))
 var populate=func(value):
  lab.item_filter=value;select.clear()
  for id in ids:
   var info=Forge.info(id)
   if not value.is_empty() and not str(info.name).to_lower().contains(str(value).to_lower()):continue
   select.add_item(str(info.name)+" · %dg"%RivalEconomy.item_cost(id));select.set_item_metadata(select.item_count-1,id)
  if select.item_count>0:
   for i in range(select.item_count):
    if select.get_item_metadata(i)==lab.selected_item:select.selected=i
   lab.selected_item=str(select.get_item_metadata(select.selected))
  else:lab.selected_item=""
 populate.call(lab.item_filter);search.text_changed.connect(populate)
 select.item_selected.connect(func(i):lab.selected_item=str(select.get_item_metadata(i)))
 var target=OptionButton.new();target.add_item("Best build fit");target.set_item_metadata(0,"");box.add_child(target)
 for h in game.campaign.lineup():target.add_item(h.name+" · "+HeroData.species[h.sp].n);target.set_item_metadata(target.item_count-1,h.id)
 for i in range(target.item_count):
  if target.get_item_metadata(i)==lab.selected_target:target.selected=i
 target.item_selected.connect(func(i):lab.selected_target=str(target.get_item_metadata(i)))
 var buttons=HBoxContainer.new();box.add_child(buttons)
 var add=game.button(buttons,"+ Add priority",func():
  if lab.plan.items.size()>=20 or not Forge.is_item(lab.selected_item):return
  lab.plan.items.append({"id":lab.selected_item,"target":lab.selected_target});refresh(game,lab),true,lab.plan.items.size()>=20);add.name="SpeedrunAddPriority"
 game.button(buttons,"Suggested team build",func():
  lab.plan.items=[]
  for h in game.campaign.lineup():
   var preview=h.duplicate(true);preview.build_goal=lab.plan.goals.get(h.id,"Adaptive");preview.evolution=lab.plan.evolutions.get(h.id,"")
   for id in Forge.recommended(h.sp,preview):lab.plan.items.append({"id":id,"target":h.id})
  refresh(game,lab))
 for i in range(lab.plan.items.size()):
  var item=lab.plan.items[i];var item_row=HBoxContainer.new();box.add_child(item_row)
  var info=Forge.info(item.id);GearUI.token(game,item_row,info,38)
  var recipient=game.campaign.hero_by_id(str(item.get("target","")))
  var text=game.label(item_row,"%02d · %s\n%s · %dg"%[i+1,info.name,recipient.get("name","Best build fit"),RivalEconomy.item_cost(item.id)],15);text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  game.button(item_row,"↑",func():lab.plan.items[i]=lab.plan.items[i-1];lab.plan.items[i-1]=item;refresh(game,lab),false,i==0)
  game.button(item_row,"↓",func():lab.plan.items[i]=lab.plan.items[i+1];lab.plan.items[i+1]=item;refresh(game,lab),false,i==lab.plan.items.size()-1)
  game.button(item_row,"×",func():lab.plan.items.remove_at(i);refresh(game,lab))
 if lab.plan.items.is_empty():game.label(box,"No priorities yet. An empty list tests your squad without purchased items.",16,game.MUTED)

static func evolutions(game: Node,lab: SpeedrunLab) -> void:
 var box=game.scroll_panel(Rect2(1082,254,492,610))
 game.label(box,"3 · BUILD & EVOLUTION",22,game.GOLD)
 game.label(box,"Choose each champion's preferred evolution and Apex. Earned skill offers follow the build path; evolutions unlock at their normal XP thresholds.",14,game.MUTED)
 for h in game.campaign.lineup():
  var row=HBoxContainer.new();box.add_child(row);var face=SplashArt.make(row,h.sp,Vector2(45,45));face.size_flags_vertical=Control.SIZE_SHRINK_CENTER
  var identity=game.label(row,h.name+" · "+HeroData.species[h.sp].n,19);identity.custom_minimum_size.x=350;identity.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  var goal=OptionButton.new();box.add_child(goal)
  for name in DecisionMatrix.GOALS:goal.add_item(name)
  goal.selected=DecisionMatrix.GOALS.find(lab.plan.goals.get(h.id,"Adaptive"))
  goal.item_selected.connect(func(i):lab.plan.goals[h.id]=DecisionMatrix.GOALS[i];refresh(game,lab))
  var options=Evolutions.options(h.sp);var evo=OptionButton.new();box.add_child(evo)
  for key in options:
   var preview=h.duplicate(true);preview.evolution=key;var info=Evolutions.of(preview);evo.add_item(str(info.name));evo.set_item_tooltip(evo.item_count-1,str(info.get("text","")))
  if not options.is_empty():
   if not lab.plan.evolutions.has(h.id):lab.plan.evolutions[h.id]=options[0]
   evo.selected=maxi(0,options.find(lab.plan.evolutions[h.id]))
   evo.item_selected.connect(func(i):lab.plan.evolutions[h.id]=options[i];refresh(game,lab))
   var preview=h.duplicate(true);preview.evolution=lab.plan.evolutions[h.id];game.label(box,Evolutions.of(preview).get("text",""),13,game.MUTED)
  var apex=OptionButton.new();box.add_child(apex);var keys=HeroData.APEX.keys()
  for key in keys:apex.add_item("Apex · "+str(HeroData.APEX[key].name))
  apex.selected=maxi(0,keys.find(lab.plan.apex.get(h.id,"apex_skill")))
  apex.item_selected.connect(func(i):lab.plan.apex[h.id]=keys[i];refresh(game,lab))
  game.button(box,"Tactics",func():game.show_tactics(h.id))

static func results(game: Node,lab: SpeedrunLab) -> void:
 var r=lab.result;var box=game.scroll_panel(Rect2(26,254,1548,610))
 var row=HBoxContainer.new();box.add_child(row)
 game.label(row,"RESULTS · %s"%("Complete" if r.complete else "Partial"),26,game.GOLD).size_flags_horizontal=Control.SIZE_EXPAND_FILL
 game.label(box,"Result seed %d · %d-cup plan · Current draft is available above."%[int(r.seed),int(r.requested_cups)],14,game.MUTED)
 game.button(row,"Edit priorities",func():lab.result={};game.render())
 game.button(row,"Export JSON",func():var path=lab.export_result();game.toast("Exported: "+path if not path.is_empty() else "Could not export results."))
 var outcome="Survived every cup's normal cutoff." if int(r.first_survival_failure)==0 and r.complete else "A regular run would end in cup %d. Benchmark continued to measure later cups."%int(r.first_survival_failure) if int(r.first_survival_failure)>0 else "No survival failure in the completed cups."
 game.label(box,outcome,20,Color("94e0af") if int(r.first_survival_failure)==0 else Color("ffbb83"))
 game.label(box,"%d player matches · %d priority items bought · %d gold left · %.1fs wall time · %s"%[r.matches.size(),r.purchases.size(),r.gold_left,r.elapsed_seconds,r.difficulty],17)
 game.label(box,"Benchmark: continues after elimination with normal gold and training. Cups 6–10 extend rival levels (+2/cup, capped at 20) and quality (+2.5%/cup). No campaign rewards or Ascension unlocks.",14,game.MUTED)
 var table=GridContainer.new();table.columns=7;table.add_theme_constant_override("h_separation",18);table.add_theme_constant_override("v_separation",8);box.add_child(table)
 for heading in ["Cup","Arena","Place","W / L","Gold","Normal cutoff","Details"]:game.label(table,heading,18,game.GOLD,false)
 for cup in r.cups:
  var bouts=r.matches.filter(func(m):return int(m.cup)==int(cup.level));var won=bouts.filter(func(m):return int(m.winner)==0).size()
  game.label(table,str(int(cup.level)),19);game.label(table,cup.location,19);game.label(table,str(int(cup.place)),19)
  game.label(table,"%d / %d"%[won,bouts.size()-won],19);game.label(table,str(int(cup.gold)),19)
  game.label(table,"Survived" if cup.survived else "Fallen",19,Color("94e0af") if cup.survived else Color("ffbb83"))
  game.button(table,"Matches & CPU bracket",func():cup_detail(game,cup,bouts))
 var widths=[50,320,60,100,100,180,320]
 for i in range(table.get_child_count()):
  var cell=table.get_child(i);cell.custom_minimum_size.x=widths[i%7];cell.size_flags_vertical=Control.SIZE_SHRINK_CENTER
  if cell is Label:cell.autowrap_mode=TextServer.AUTOWRAP_OFF
  if cell is Button:cell.add_theme_font_size_override("font_size",16);cell.custom_minimum_size.y=42
 game.label(box,"FINAL SQUAD",22,game.GOLD)
 var team=HBoxContainer.new();box.add_child(team)
 for h in r.final_roster:
  var card=VBoxContainer.new();card.custom_minimum_size.x=280;team.add_child(card)
  SplashArt.make(card,h.sp,Vector2(80,80));game.label(card,h.name,20);game.label(card,"Lv %d · Power %d"%[int(h.level),HeroData.power(h)],17)
  game.label(card,ChampionStars.evolution_label(h),14,game.GOLD);StatHex.make(card,h,Vector2(270,165))
  for id in h.get("equipment",{}).values():game.label(card,Forge.info(id).name,14)
 game.button(box,"Purchase & skill decisions",func():
  var dialog=GearUI.modal(game,"Decisions · purchases and earned skill choices",Vector2(1240,760));var scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;dialog.box.add_child(scroll);var body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(body)
  for purchase in r.purchases:game.label(body,"Cup %d · #%d · %s → %s · %dg · %dg left"%[purchase.cup,purchase.priority,Forge.info(purchase.item).name,purchase.hero,purchase.cost,purchase.gold_left],17)
  for decision in r.decisions:game.label(body,"Cup %d · %s · %s · %s"%[decision.cup,decision.hero,decision.type,decision.name],17))
 game.label(box,"%d item priorities remain unfilled. Export JSON includes purchasing reasons and all player/CPU combat rows."%r.get("unfulfilled",[]).size(),14,game.MUTED)

static func history(game: Node,lab: SpeedrunLab) -> void:
 var dialog=GearUI.modal(game,"Speedrun database · previous benchmarks",Vector2(1160,700))
 var scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;dialog.box.add_child(scroll);var box=VBoxContainer.new();box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(box)
 var records=JSON.parse_string(FileAccess.get_file_as_string(SpeedrunLab.RESULTS_PATH)) if FileAccess.file_exists(SpeedrunLab.RESULTS_PATH) else []
 if not records is Array:records=[]
 if records.is_empty():game.label(box,"Simulate a run to begin collecting benchmark results.",20)
 for r in records:
  game.button(box,"Seed %d · %s · %d/%d cups · %d matches · %s"%[int(r.seed),r.difficulty,r.cups.size(),int(r.requested_cups),r.matches.size(),"Complete" if r.complete else "Partial"],func():lab.result=r;lab.status="Viewing saved benchmark · current draft stays unchanged";dialog.root.queue_free();game.render())

static func cup_detail(game: Node,cup: Dictionary,bouts: Array) -> void:
 var dialog=GearUI.modal(game,"Cup %d · %s"%[int(cup.level),cup.location],Vector2(1240,760))
 var scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;dialog.box.add_child(scroll);var box=VBoxContainer.new();box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(box)
 for m in bouts:
  game.label(box,"%s · %s vs %s · %.1fs · %dg"%[m.stage,"Won" if m.winner==0 else "Lost" if m.winner==1 else "Draw",m.opponent,m.duration,m.gold],20,game.GOLD)
  var grid=GridContainer.new();grid.columns=6;grid.add_theme_constant_override("h_separation",24);box.add_child(grid)
  for heading in ["Champion","Team","Damage","Healing","Blocked","Kills"]:game.label(grid,heading,15,game.GOLD,false)
  for stat in m.rows:
   game.label(grid,str(stat.name),15,game.WHITE,false);game.label(grid,"You" if stat.team==0 else "Rival",15,game.MUTED,false)
   for metric in ["damage","healing","blocked","kills"]:game.label(grid,str(roundi(float(stat.get(metric,0)))),15,game.WHITE,false)
 game.label(box,"CPU & PLAYER BRACKET · real simulated outcomes",22,game.GOLD)
 for m in cup.bracket.matches:
  if int(m.winner)<0:continue
  game.label(box,"%s · %s beat %s"%[m.label,cup.team_names[int(m.winner)],cup.team_names[int(m.loser)]],17)
 for cl in cup.get("cpu_economy",[]):game.label(box,"%s · %d gold earned · %d spent on items · %d gold left"%[cl.name,int(cl.earned),int(cl.spent),int(cl.gold)],15,game.MUTED)
