class_name PlaytestAtlas
extends RefCounted
const PATCHES=["0.70 · champion validation + expanded items","0.69 · full champion/item screen","0.69 · expanded item follow-up"]
const DATASETS=["post","pre","expanded"]

static func text(game: Node,parent: Node,value: String,size: int=16,color: Color=Color("fff5df")) -> Label:
 return game.label(parent,value,size,color,not (parent is HBoxContainer))

static func rate(s: Dictionary) -> String:
 return "%.1f%% · %.1f–%.1f%%"%[float(s.wins)*100,float(s.interval[0])*100,float(s.interval[1])*100] if int(s.n)>0 else "No data"

static func open(game: Node,f: Dictionary={},view: String="champions",id: String="") -> void:
 var d=PlaytestDatabase.dataset(str(f.get("dataset","post")))
 var dlg=GearUI.modal(game,"MANITORIA ATLAS · Playtest database",Vector2(1480,800))
 var nav=HBoxContainer.new();dlg.box.add_child(nav)
 for v in ["champions","items","skills","balance","method"]:
  var b=game.button(nav,v.capitalize(),func():dlg.root.queue_free();open(game,f,v),view==v);b.add_theme_font_size_override("font_size",16)
 game.button(nav,"My runs",func():dlg.root.queue_free();AtlasUI.open(game,{"side":"player"})).add_theme_font_size_override("font_size",16)
 game.button(nav,"Export database",func():
  var path=PlaytestDatabase.export_database();var notice=GearUI.modal(game,"Playtest database export",Vector2(1000,300))
  text(game,notice.box,"Could not export the database." if path.is_empty() else "Raw audit and query datasets saved to:\n"+path,19)
  if not path.is_empty():game.button(notice.box,"Copy folder path",func():DisplayServer.clipboard_set(path))).add_theme_font_size_override("font_size",16)
 var row=HBoxContainer.new();dlg.box.add_child(row)
 var key=str(f.get("dataset","post"));var current=PATCHES[maxi(0,DATASETS.find(key))]
 AtlasUI.selector(row,PATCHES,current,func(v):var next=f.duplicate();next.dataset=DATASETS[PATCHES.find(v)];dlg.root.queue_free();open(game,next,view,id))
 AtlasUI.selector(row,["all","Keeper","Standard","Champion"],str(f.get("difficulty","all")),func(v):change(game,dlg,f,"difficulty",v,view,id))
 AtlasUI.selector(row,["All cups","Cup 1","Cup 2","Cup 3","Cup 4","Cup 5"],"All cups" if int(f.get("cup",0))==0 else "Cup %d"%int(f.cup),func(v):change(game,dlg,f,"cup",0 if v=="All cups" else int(v.right(1)),view,id))
 AtlasUI.selector(row,["All stars","1 star","2 stars","3 stars"],"All stars" if int(f.get("stars",0))==0 else "%d %s"%[int(f.stars),"star" if int(f.stars)==1 else "stars"],func(v):change(game,dlg,f,"stars",0 if v=="All stars" else int(v.left(1)),view,id))
 var second=HBoxContainer.new();dlg.box.add_child(second)
 AtlasUI.selector(second,["all","Balanced","Attack tempo","Spell power","Tank carry"],str(f.get("strategy","all")),func(v):change(game,dlg,f,"strategy",v,view,id))
 var roles=["All roles"]
 for sp in d.species:
  if d.species[sp].role not in roles:roles.append(d.species[sp].role)
 if view in ["champions","skills"]:AtlasUI.selector(second,roles,str(f.get("role","All roles")),func(v):change(game,dlg,f,"role",v,view,id))
 var search=LineEdit.new();search.custom_minimum_size.x=210;search.placeholder_text="Search · Enter to filter";search.text=str(f.get("search",""));second.add_child(search)
 search.text_submitted.connect(func(v):change(game,dlg,f,"search",v,view,id))
 game.label(second,"Min tests" if view=="items" else "Min appearances",13,game.WHITE,false)
 var minimum=SpinBox.new();minimum.max_value=20000;minimum.value=int(f.get("minimum",0));minimum.custom_minimum_size.x=100;second.add_child(minimum)
 minimum.value_changed.connect(func(v):change(game,dlg,f,"minimum",int(v),view,id))
 game.button(second,"Reset",func():dlg.root.queue_free();open(game,{"dataset":key},view,id)).add_theme_font_size_override("font_size",14)
 var sort_names=["Default sort","Sample count","Team win rate","Damage output","Name"]
 var sort_keys=["default","n","wins","dps","name"]
 AtlasUI.selector(second,sort_names,sort_names[maxi(0,sort_keys.find(str(f.get("sort","default"))))],func(v):change(game,dlg,f,"sort",sort_keys[sort_names.find(v)],view,id))
 var us=PlaytestDatabase.units(f);var pairs={}
 for u in us:pairs[str(u.pair)+"|"+str(u.side)]=true
 text(game,dlg.box,"8,192 audited matches bundled · Selected cohort: %s · %d total battles / %d champion battles · %d filtered champion appearances"%[d.version,int(d.battle_count),int(d.champion_battles),us.size()],14,game.GOLD)
 text(game,dlg.box,"Simulated playtests, separate from personal runs. Mirrored sides are correlated. Team win rates, builds and matchups show associations; item experiments compare added gear with an empty-slot control.",13,game.MUTED)
 var scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;dlg.box.add_child(scroll)
 var body=VBoxContainer.new();body.add_theme_constant_override("separation",8);body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(body)
 if view=="champion":champion(game,body,f,id,us,dlg)
 elif view=="items":items(game,body,f,dlg)
 elif view=="item":item(game,body,f,id,us,dlg)
 elif view=="skills":skills(game,body,f,us,dlg)
 elif view=="balance":balance(game,body)
 elif view=="method":method(game,body)
 else:champions(game,body,f,dlg)

static func change(game: Node,dlg: Dictionary,f: Dictionary,key: String,value: Variant,view: String,id: String) -> void:
 var next=f.duplicate();next[key]=value;dlg.root.queue_free();open(game,next,view,id)

static func line(parent: Node) -> HBoxContainer:
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",8);parent.add_child(row);return row

static func cell(game: Node,parent: Node,value: String,width: float=160,color: Color=Color("fff5df")) -> void:
 var l=game.label(parent,value,15,color,false);l.custom_minimum_size.x=width;l.clip_text=true;l.mouse_filter=Control.MOUSE_FILTER_STOP;l.tooltip_text=value

static func picture(parent: Node,texture: Texture2D) -> void:
 var icon=TextureRect.new();icon.texture=texture;icon.custom_minimum_size=Vector2(42,42);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;parent.add_child(icon)

static func eligible(d: Dictionary,f: Dictionary,sp: String,s: Dictionary) -> bool:
 if int(s.n)<int(f.get("minimum",0)):return false
 if f.get("role","All roles")!="All roles" and d.species[sp].role!=f.role:return false
 var search=str(f.get("search","")).to_lower()
 return search.is_empty() or str(d.species[sp].n).to_lower().contains(search)

static func champions(game: Node,body: Node,f: Dictionary,dlg: Dictionary) -> void:
 var d=PlaytestDatabase.dataset(str(f.get("dataset","post")));var data=PlaytestDatabase.champions(f);var keys=d.species.keys()
 var headers=line(body)
 for entry in [["Champion", "name",280],["Tier","score",55],["Team win / 95% interval","wins",205],["Appearances","n",110],["Draft pairs","pairs",100],["DPS","dps",75],["HPS","hps",75],["Survival","survival",85]]:
  var b=game.button(headers,entry[0],func():var next=f.duplicate();next.sort=entry[1];next.ascending=not bool(f.get("ascending",false)) if f.get("sort","wins")==entry[1] else entry[1]=="name";dlg.root.queue_free();open(game,next));b.custom_minimum_size.x=entry[2];b.add_theme_font_size_override("font_size",13)
 var sort=str(f.get("sort","wins"));var asc=bool(f.get("ascending",false))
 if sort=="default":sort="wins"
 keys.sort_custom(func(a,b):var x=d.species[a].n if sort=="name" else data.get(a,{}).get(sort,0);var y=d.species[b].n if sort=="name" else data.get(b,{}).get(sort,0);return x<y if asc else x>y)
 for sp in keys:
  var s=data.get(sp,PlaytestDatabase.stats([]))
  if not eligible(d,f,sp,s):continue
  var row=line(body);picture(row,load("res://assets/portraits/%s.png"%sp))
  var b=game.button(row,d.species[sp].n,func():dlg.root.queue_free();open(game,f,"champion",sp));b.custom_minimum_size.x=230;b.add_theme_font_size_override("font_size",18)
  cell(game,row,s.tier,55,game.GOLD);cell(game,row,rate(s),205);cell(game,row,str(s.n),110);cell(game,row,str(s.pairs),100);cell(game,row,"%.1f"%s.dps,75);cell(game,row,"%.1f"%s.hps,75);cell(game,row,"%.1f%%"%(s.survival*100),85)
 if data.is_empty():text(game,body,"This cohort contains item experiments only. Open Items or choose a champion cohort.",20,game.GOLD)

static func champion(game: Node,body: Node,f: Dictionary,sp: String,us: Array,dlg: Dictionary) -> void:
 var d=PlaytestDatabase.dataset(str(f.get("dataset","post")))
 if not d.species.has(sp):return
 var rows=us.filter(func(u):return u.sp==sp);var s=PlaytestDatabase.stats(rows)
 var hero=line(body);picture(hero,load("res://assets/portraits/%s.png"%sp));text(game,hero,d.species[sp].n+" · "+d.species[sp].role,28,game.GOLD)
 text(game,body,"%s team wins · %d appearances / %d draft pairs · %.1f DPS / %.1f HPS · %.1f%% survival"%[rate(s),s.n,s.pairs,s.dps,s.hps,s.survival*100],18)
 var profile=d.skills[sp].signature;text(game,body,profile.name+" · "+profile.description,17,game.MUTED)
 var groups={}
 for u in rows:
  var ids=u.items.duplicate();ids.sort();var key="|".join(ids)
  if key.is_empty():continue
  var list=groups.get(key,[]);list.append(u);groups[key]=list
 var cores=[]
 for key in groups:cores.append({"key":key,"stats":PlaytestDatabase.stats(groups[key])})
 cores.sort_custom(func(a,b):return a.stats.n>b.stats.n)
 if not cores.is_empty():core(game,body,"MOST SAMPLED CORE",cores[0],d)
 var supported=cores.filter(func(c):return c.stats.pairs>=20);supported.sort_custom(func(a,b):return a.stats.interval[0]>b.stats.interval[0])
 if not supported.is_empty():core(game,body,"STRONGEST SUPPORTED CORE · ≥20 draft pairs",supported[0],d)
 else:text(game,body,"No core meets the 20-draft-pair support threshold under these filters.",14,game.MUTED)
 for field in ["cup","strategy","stars","evolution"]:
  text(game,body,{"cup":"PERFORMANCE THROUGH CUPS","strategy":"BUILD POLICIES","stars":"STAR GRADES","evolution":"EVOLUTION PATHS"}[field],20,game.GOLD)
  for value in PlaytestDatabase.grouped(rows,field):
   var a=PlaytestDatabase.stats(PlaytestDatabase.grouped(rows,field)[value]);var row=line(body)
   cell(game,row,"Not evolved" if value.is_empty() else value,220);cell(game,row,rate(a),240);cell(game,row,"%d appearances · %d pairs"%[a.n,a.pairs],240)
 var item_groups={}
 for u in rows:
  for key in u.items:
   var list=item_groups.get(key,[]);list.append(u);item_groups[key]=list
 text(game,body,"OBSERVED ITEM CHOICES",20,game.GOLD)
 for key in item_groups:
  var a=PlaytestDatabase.stats(item_groups[key]);var row=line(body)
  var b=game.button(row,d.items[key].name,func():dlg.root.queue_free();open(game,f,"item",key));b.custom_minimum_size.x=300
  cell(game,row,rate(a),240);cell(game,row,"%d appearances · %d pairs"%[a.n,a.pairs],240)
 text(game,body,"MEASURED SKILL CONTRIBUTIONS",20,game.GOLD);skills(game,body,f,rows,dlg)
 var opponents={}
 for u in rows:
  for enemy in u.opponents:
   var list=opponents.get(enemy,[]);list.append(u);opponents[enemy]=list
 var counters=[]
 for enemy in opponents:counters.append({"sp":enemy,"stats":PlaytestDatabase.stats(opponents[enemy])})
 counters.sort_custom(func(a,b):return a.stats.wins<b.stats.wins)
 text(game,body,"OPPONENT MATCHUPS · enemy-team co-occurrence, not duels",20,game.GOLD)
 for counter in counters:
  var row=line(body);var b=game.button(row,d.species[counter.sp].n,func():dlg.root.queue_free();open(game,f,"champion",counter.sp));b.custom_minimum_size.x=300
  cell(game,row,rate(counter.stats),240);cell(game,row,"%d appearances · %d pairs"%[counter.stats.n,counter.stats.pairs],240)
 text(game,body,"COMPLETE ABILITY CATALOG",20,game.GOLD)
 for key in d.skills[sp]:
  var a=d.skills[sp][key];text(game,body,"%s · %s · %.1fs cooldown"%[a.name,scaling(a.get("scaling",{})),float(a.get("cooldown",0))],17)
  text(game,body,str(a.get("description","")),14,game.MUTED)

static func core(game: Node,body: Node,title: String,c: Dictionary,d: Dictionary) -> void:
 text(game,body,title,20,game.GOLD)
 var names=[]
 for id in c.key.split("|"):names.append(d.items[id].name)
 text(game,body," + ".join(names),18)
 text(game,body,"%s team wins · %d appearances / %d pairs · observed combination"%[rate(c.stats),c.stats.n,c.stats.pairs],14,game.MUTED)

static func scaling(values: Dictionary) -> String:
 var parts=[]
 for key in values:parts.append("%d%% %s"%[roundi(float(values[key])*100),key.to_upper()])
 return " + ".join(parts)

static func skills(game: Node,body: Node,f: Dictionary,us: Array,dlg: Dictionary) -> void:
 var d=PlaytestDatabase.dataset(str(f.get("dataset","post")));var all=PlaytestDatabase.skills(us)
 var sort=str(f.get("sort","default"))
 all.sort_custom(func(a,b):return a.stats.n>b.stats.n if sort=="n" else a.stats.wins>b.stats.wins if sort=="wins" else str(a.sp)+str(a.key)<str(b.sp)+str(b.key) if sort=="name" else a.damage/maxf(1,a.casts)>b.damage/maxf(1,b.casts))
 for s in all:
  if not eligible(d,f,s.sp,s.stats):continue
  var key=str(s.key).trim_prefix("ability:");var info=d.skills[s.sp].get(key,{"name":"Basic attack","scaling":{"ad":1}})
  var row=line(body);picture(row,AbilityArt.texture(AbilityArt.metric_info(s.sp,s.key).art))
  var b=game.button(row,d.species[s.sp].n+" · "+info.name,func():dlg.root.queue_free();open(game,f,"champion",s.sp));b.custom_minimum_size.x=320;b.add_theme_font_size_override("font_size",15)
  cell(game,row,scaling(info.get("scaling",{})),170);cell(game,row,"%d casts"%int(s.casts),100)
  cell(game,row,"%.1f dmg/cast"%(s.damage/maxf(1,s.casts)),150);cell(game,row,"%.1f heal/cast"%(s.healing/maxf(1,s.casts)),150);cell(game,row,"%d appearances"%s.stats.n,130)
  cell(game,row,rate(s.stats),205)
 if all.is_empty():text(game,body,"No measured skills in this filtered cohort.",18,game.MUTED)

static func items(game: Node,body: Node,f: Dictionary,dlg: Dictionary) -> void:
 var d=PlaytestDatabase.dataset(str(f.get("dataset","post")));var all=[]
 for id in d.items:
  var s=PlaytestDatabase.item_stats(id,f)
  if s.n<int(f.get("minimum",0)):continue
  var search=str(f.get("search","")).to_lower()
  if not search.is_empty() and not str(d.items[id].name).to_lower().contains(search):continue
  all.append(s)
 var sort=str(f.get("sort","default"))
 all.sort_custom(func(a,b):return a.n>b.n if sort=="n" else a.wins>b.wins if sort=="wins" else a.dps>b.dps if sort=="dps" else d.items[a.id].name<d.items[b.id].name if sort=="name" else a.margin>b.margin)
 text(game,body,"ITEM SCREEN · Outcome shift is summed surviving health fractions · 95% t interval over mirrored setup means",16,game.GOLD)
 for s in all:
  var row=line(body);var token=GearUI.token(game,row,Forge.info(s.id),42);token.tooltip_text=str(d.items[s.id].get("description",""))
  var b=game.button(row,d.items[s.id].name,func():dlg.root.queue_free();open(game,f,"item",s.id));b.custom_minimum_size.x=280;b.add_theme_font_size_override("font_size",16)
  cell(game,row,"%+.2f [%+.2f, %+.2f]"%[s.margin,s.interval[0],s.interval[1]] if s.interval_available else "%+.2f · too few setups"%s.margin if s.n>0 else "Not tested in this cohort",245)
  cell(game,row,"%d setups"%s.pairs,100);cell(game,row,"%.1f%% / %.1f%% wins"%[s.wins*100,s.control*100] if s.n>0 else "—",185)
  cell(game,row,"%+.1f DPS / %+.1f HPS"%[s.dps,s.hps] if s.n>0 else "—",190)

static func item(game: Node,body: Node,f: Dictionary,id: String,us: Array,dlg: Dictionary) -> void:
 var d=PlaytestDatabase.dataset(str(f.get("dataset","post")))
 if not d.items.has(id):return
 var info=d.items[id];var s=PlaytestDatabase.item_stats(id,f)
 var row=line(body);var token=GearUI.token(game,row,Forge.info(id),70);token.tooltip_text=str(info.get("description",""));text(game,row,info.name+" · "+info.kind,28,game.GOLD)
 text(game,body,str(info.get("description",info.get("text",""))),18)
 text(game,body,"Acquisition cost: %dg · This experiment adds one free item to an existing build, compared with no added item."%int(info.get("cost",0)),15,game.MUTED)
 if s.n>0:
  text(game,body,"Outcome shift %+.3f · %s · %d independent mirrored setups"%[s.margin,"95%% interval [%+.3f, %+.3f]"%[s.interval[0],s.interval[1]] if s.interval_available else "Too few setups for an interval",s.pairs],20,game.GOLD)
  text(game,body,"Test/control wins: %.1f%% / %.1f%% · %+.1f DPS · %+.1f HPS · %.1f logged activations/fight"%[s.wins*100,s.control*100,s.dps,s.hps,s.procs],18)
  text(game,body,"Test carriers: "+" · ".join(s.carriers),15)
 else:text(game,body,"No controlled experiment for this item under the selected cohort and filters. Choose 0.69 full screen for all 136 items.",18,game.GOLD)
 text(game,body,"CHAMPIONS USING THIS ITEM · observed team win associations",20,game.GOLD)
 var groups=PlaytestDatabase.grouped(us.filter(func(u):return id in u.items),"sp")
 for sp in groups:
  var a=PlaytestDatabase.stats(groups[sp]);var r=line(body);var b=game.button(r,d.species[sp].n,func():dlg.root.queue_free();open(game,f,"champion",sp));b.custom_minimum_size.x=280
  cell(game,r,rate(a),240);cell(game,r,"%d appearances / %d pairs"%[a.n,a.pairs],260)

static func balance(game: Node,body: Node) -> void:
 var d=RunDatabase.read_json(PlaytestDatabase.ROOT+"balance.json")
 text(game,body,"BALANCE PASS · fixed before/after cohorts; global filters do not alter this comparison",20,game.GOLD)
 for row in d.changes:
  text(game,body,str(row[0])+" · "+str(row[1]),18);text(game,body,str(row[2]),14,game.MUTED)
 for c in d.champions:text(game,body,"%s · %.1f%% → %.1f%% team wins · %d appearances per patch"%[HeroData.species[c.sp].n,c.before*100,c.after*100,c.n],18)
 for i in d.items:text(game,body,"%s · HP shift %+.3f → %+.3f · 48 matched setups per patch"%[i.name,i.before_margin,i.after_margin],18)

static func method(game: Node,body: Node) -> void:
 text(game,body,"COMPLETE PLAYTEST DATABASE · 8,192 actual simulated matches",26,game.GOLD)
 for paragraph in ["0.69 full screen: 1,536 champion battles plus 4,352 item/control battles. 0.70 validation: 1,536 same-draft champion battles plus 384 expanded item/control battles. Separate 0.69 expanded item follow-up: 384 battles. Cohorts never mix patches.","Champion drafts use legal budgets, difficulty level floors and four buying policies. Each matchup plays both sides with the same seed. This measures composition performance, not human pick popularity, player-vs-AI difficulty odds or full tournament completion rates.","Champion confidence intervals use unique draft pairs as the effective sample size. Appearances and teammates remain correlated. U tier means fewer than 30 pairs; S requires score ≥55% and a lower interval above 50%; A ≥52.5%, B ≥47.5%, C ≥42.5%, otherwise D. Draws count as non-wins for displayed win rates and half credit for tiers.","The full item screen tests eight mirrored setups per item. Expanded cohorts test 48 setups for each changed item. Item intervals use a t interval over independent setup means after averaging mirrored sides. Filters can leave too few setups to form an interval. An added free item versus an empty slot is not an equal-gold alternative; economic item value is not measured by single-battle wins.","Core builds and enemy matchups are observed associations. Strongest-core cards require at least 20 draft pairs. Skill outputs pool ranks and rarities. Shields, buffs, control, displacement and summons cannot be judged from damage/healing alone.","Raw batch hashes, exact cohort membership and dataset checksums are bundled in data/playtests/manifest.json. The original raw audit archive and runner remain in the repository. Personal run data stays separate and continues to grow locally."]:
  text(game,body,paragraph,17,game.MUTED)
