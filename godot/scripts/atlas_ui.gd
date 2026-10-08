class_name AtlasUI
extends RefCounted

static func launchers(game: Node) -> void:
 var row=HBoxContainer.new();game.ui.add_child(row);row.position=Vector2(1190,102) if game.phase in ["menu","new"] else Vector2(96,764)
 var b=game.button(row,"Atlas",func():open(game));b.custom_minimum_size=Vector2(110,32);b.add_theme_font_size_override("font_size",14)
 if not game.campaign.state.get("roster",[]).is_empty():
  var lab=game.campaign.state.get("speedrun_lab",false)
  var p=game.button(row,"Speedrun plan" if lab else "Run plan",game.prepare_match if lab else func():matrix(game));p.custom_minimum_size=Vector2(110,32);p.add_theme_font_size_override("font_size",14)

static func selector(parent: Node,values: Array,current: String,callback: Callable) -> OptionButton:
 var pick=OptionButton.new();pick.custom_minimum_size=Vector2(130,40);pick.size_flags_vertical=Control.SIZE_SHRINK_CENTER;parent.add_child(pick)
 for v in values:pick.add_item(str(v))
 pick.selected=maxi(0,values.find(current));pick.item_selected.connect(func(i):callback.call(values[i]))
 return pick

static func open(game: Node,filters: Dictionary={},sp: String="") -> void:
 if filters.is_empty() or filters.get("side","")=="research":
  PlaytestAtlas.open(game,{},"champions" if sp.is_empty() else "champion",sp);return
 var dlg=GearUI.modal(game,"RUN ATLAS · Your collected evidence",Vector2(1380,740))
 var row=HBoxContainer.new();dlg.box.add_child(row)
 var source=str(filters.get("side","player"))
 selector(row,["player","cpu","all","research"],source,func(v):dlg.root.queue_free();var f=filters.duplicate();f.side=v;open(game,f))
 selector(row,["all","Keeper","Standard","Champion"],str(filters.get("difficulty","all")),func(v):dlg.root.queue_free();var f=filters.duplicate();f.difficulty=v;open(game,f))
 selector(row,["All cups","Cup 1","Cup 2","Cup 3","Cup 4","Cup 5"],"All cups" if int(filters.get("cup",0))==0 else "Cup %d"%int(filters.cup),func(v):dlg.root.queue_free();var f=filters.duplicate();f.cup=0 if v=="All cups" else int(v.right(1));open(game,f))
 selector(row,["All stars","1 star","2 stars","3 stars"],"All stars" if int(filters.get("stars",0))==0 else "%d %s"%[int(filters.stars),"star" if int(filters.stars)==1 else "stars"],func(v):dlg.root.queue_free();var f=filters.duplicate();f.stars=0 if v=="All stars" else int(v.left(1));open(game,f))
 var query=LineEdit.new();query.placeholder_text="Search champion";query.text=str(filters.get("search",""));row.add_child(query)
 query.text_submitted.connect(func(v):dlg.root.queue_free();var f=filters.duplicate();f.search=v;open(game,f))
 var extra=HBoxContainer.new();dlg.box.add_child(extra)
 game.button(extra,"Items",func():items(game,filters))
 game.button(extra,"Run history",func():history(game))
 game.label(extra,"Rules version",13,game.WHITE,false)
 selector(extra,["all","0.71","0.72"],str(filters.get("patch","all")),func(v):dlg.root.queue_free();var f=filters.duplicate();f.patch=v;open(game,f))
 var ranks=["All challenges","Normal rules"]
 for rank in range(1,11):ranks.append("Ascension %d"%rank)
 selector(extra,ranks,"All challenges" if int(filters.get("challenge",-1))<0 else "Normal rules" if int(filters.challenge)==0 else "Ascension %d"%int(filters.challenge),func(v):dlg.root.queue_free();var f=filters.duplicate();f.challenge=-1 if v=="All challenges" else 0 if v=="Normal rules" else int(v.split(" ")[-1]);open(game,f))
 var data=RunDatabase.read_json("res://data/atlas_research.json") if source=="research" else RunDatabase.aggregate(filters.merged({"side":source},true))
 game.label(dlg.box,"%d matches · %d runs · %s"%[int(data.get("matches",0)),int(data.get("runs",0)),"Bundled 0.70 mirrored research; filters apply only to your recorded runs." if source=="research" else "Saved locally across campaigns · includes completed matches only"],14,game.GOLD)
 game.label(dlg.box,"Team results are associations: teammates, cup, rolls and spending affect outcomes. CPU and player samples are separate. Research never counts as your own runs.",13,game.MUTED)
 var scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;dlg.box.add_child(scroll)
 var body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",8);scroll.add_child(body)
 if not sp.is_empty():
  game.button(body,"← Champion table",func():dlg.root.queue_free();open(game,filters))
  detail(game,body,sp,data.get("champions",{}).get(sp,{}));return
 var keys=HeroData.species.keys();var champions=data.get("champions",{})
 keys.sort_custom(func(a,b):return float(champions.get(a,{}).get("wins",0))/maxf(1,float(champions.get(a,{}).get("n",0)))>float(champions.get(b,{}).get("wins",0))/maxf(1,float(champions.get(b,{}).get("n",0))))
 for key in keys:
  var search=str(filters.get("search","")).to_lower()
  if not search.is_empty() and not str(HeroData.species[key].n).to_lower().contains(search):continue
  var stats=champions.get(key,{})
  var line=HBoxContainer.new();body.add_child(line)
  var icon=TextureRect.new();icon.texture=load("res://assets/portraits/%s.png"%key);icon.custom_minimum_size=Vector2(44,44);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;line.add_child(icon)
  var title=game.button(line,HeroData.species[key].n,func():dlg.root.queue_free();open(game,filters,key));title.custom_minimum_size.x=270
  var n=int(stats.get("n",0));var rate=100.0*float(stats.get("wins",0))/maxi(1,n)
  game.label(line,"%s · %d appearances · %.1f DPS · %.1f HPS"%["No data" if n==0 else "%.1f%% team wins"%rate,n,float(stats.get("damage",0))/maxf(1,float(stats.get("seconds",0))),float(stats.get("healing",0))/maxf(1,float(stats.get("seconds",0)))],16,game.WHITE,false)
  if n>0 and n<30:game.label(line,"Small sample",13,game.GOLD,false)
  var bar=ProgressBar.new();bar.custom_minimum_size=Vector2(100,12);bar.size_flags_vertical=Control.SIZE_SHRINK_CENTER;bar.show_percentage=false;bar.value=rate;line.add_child(bar)

static func detail(game: Node,body: Node,sp: String,d: Dictionary) -> void:
 game.label(body,HeroData.species[sp].n+" · "+HeroData.species[sp].role,30,game.GOLD)
 game.label(body,"%d appearances · Recorded item associations (not controlled purchase comparisons)"%int(d.get("n",0)),16)
 var items=d.get("items",{}).keys();items.sort_custom(func(a,b):return int(d.items[a].n)>int(d.items[b].n))
 for key in items:
  var v=d.items[key];game.label(body,"%s · %d samples · %.1f%% team wins"%[Forge.info(key).name,int(v.n),100.0*float(v.wins)/maxf(1,float(v.n))],17)
 game.label(body,"MEASURED ABILITIES",20,game.GOLD)
 for key in d.get("skills",{}):
  var v=d.skills[key];var info=AbilityArt.metric_info(sp,key)
  game.label(body,"%s · %d casts · %.1f damage/cast · %.1f healing/cast"%[info.name,int(v.casts),float(v.damage)/maxf(1,float(v.casts)),float(v.healing)/maxf(1,float(v.casts))],16)
 if d.is_empty():game.label(body,"Play completed matches with this champion to collect evidence. Use Research to consult the bundled audit.",18,game.MUTED)

static func matrix(game: Node) -> void:
 var c: Campaign=game.campaign
 var dlg=GearUI.modal(game,"RUN PLAN · Decision matrix",Vector2(1360,730))
 game.label(dlg.box,"First matching rule per champion wins. Apply sets tactics and a build priority; it never spends gold or replaces your skills. Re-apply after scouting each opponent.",15,game.MUTED)
 var draft=c.state.get("decision_matrix",{}).duplicate(true)
 var scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;dlg.box.add_child(scroll)
 var body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(body)
 for h in c.lineup():
  var rules=draft.get(h.id,DecisionMatrix.default_rules(h)).duplicate(true);draft[h.id]=rules
  game.label(body,h.name+" · "+HeroData.species[h.sp].n,21,game.GOLD)
  for r in rules:
   var row=HBoxContainer.new();body.add_child(row)
   game.label(row,"IF",14,game.WHITE,false)
   selector(row,DecisionMatrix.CONDITIONS,r.condition,func(v):r.condition=v)
   game.label(row,"THEN",14,game.WHITE,false)
   selector(row,BattleTactics.PRESETS.keys(),r.preset,func(v):r.preset=v)
   selector(row,DecisionMatrix.GOALS,r.goal,func(v):r.goal=v)
 var actions=HBoxContainer.new();dlg.box.add_child(actions)
 game.button(actions,"Save rules",func():
  var before=c.state.get("decision_matrix",{}).duplicate(true);c.state.decision_matrix=draft.duplicate(true)
  if c.save():game.toast("Run plan saved");dlg.root.queue_free()
  else:c.state.decision_matrix=before;game.toast(c.last_error),true)
 game.button(actions,"Preview saved plan",func():
  var enemies=WorldTour.next_opponent(c).get("roster",[]) if c.state.has("tour") else c.opponent().roster
  var p=GearUI.modal(game,"Matched rules · next opponent",Vector2(1050,600))
  for match_row in DecisionMatrix.preview(c,enemies):game.label(p.box,"%s · %s → %s / %s"%[match_row.name,match_row.condition,match_row.preset,match_row.goal],18)
  game.button(p.box,"Apply saved plan",func():
   if DecisionMatrix.apply(c,enemies):game.toast("Plan applied · review tactics and gear before fighting");p.root.queue_free();dlg.root.queue_free()
   else:game.toast(c.last_error),true))

static func items(game: Node,filters: Dictionary) -> void:
 if filters.get("side","")=="research":PlaytestAtlas.open(game,{},"items");return
 var source=str(filters.get("side","player"))
 var data=RunDatabase.read_json("res://data/atlas_research.json") if source=="research" else RunDatabase.aggregate(filters.merged({"side":source},true))
 var totals={}
 for sp in data.get("champions",{}):
  for key in data.champions[sp].get("items",{}):
   var v=data.champions[sp].items[key];var row=totals.get(key,{"n":0,"wins":0.0});row.n+=int(v.n);row.wins+=float(v.wins);totals[key]=row
 var dlg=GearUI.modal(game,"ITEM ATLAS · "+source.capitalize(),Vector2(1180,700))
 game.label(dlg.box,"Equipped champion appearances, using your selected filters. Team win association includes the rest of the build; it does not measure an item's isolated effect.",15,game.MUTED)
 var scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;dlg.box.add_child(scroll)
 var box=VBoxContainer.new();box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(box)
 var keys=totals.keys();keys.sort_custom(func(a,b):return int(totals[a].n)>int(totals[b].n))
 for key in keys:
  var v=totals[key];var row=HBoxContainer.new();box.add_child(row)
  GearUI.token(game,row,Forge.info(key),44)
  game.label(row,"%s · %d appearances · %.1f%% team wins"%[Forge.info(key).name,int(v.n),100.0*float(v.wins)/maxf(1,float(v.n))],17,game.WHITE,false)
 if keys.is_empty():game.label(box,"No equipped-item evidence for this selection yet.",18,game.MUTED)

static func history(game: Node) -> void:
 var dlg=GearUI.modal(game,"YOUR RUN DATABASE",Vector2(1100,660))
 game.label(dlg.box,"Records stay on this computer. New games and overwritten campaign slots retain collected evidence. Recording begins with 0.71; older reports lack complete build snapshots.",15,game.MUTED)
 var scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;dlg.box.add_child(scroll)
 var box=VBoxContainer.new();box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(box)
 var runs=RunDatabase.runs()
 for run in runs:
  var player=run.matches.filter(func(e):return e.source=="player").size()
  game.label(box,"%s · %s · %d player / %d CPU matches · Ascension %d"%[run.get("name","Guild"),"Complete" if run.get("complete",false) else "Fallen" if run.get("fallen",false) else "In progress",player,run.matches.size()-player,int(run.get("challenge",0))],18)
 if runs.is_empty():game.label(box,"Complete your first match to start your personal database.",20,game.GOLD)
