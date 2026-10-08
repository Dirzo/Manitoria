class_name RunDatabase
extends RefCounted
const DIR = "user://atlas_runs"
const PATCH = "0.71"
static var cache: Dictionary={}
static var run_cache: Array=[]
static var run_cache_ready=false

static func ensure_id(c: Campaign) -> String:
 if not c.state.has("atlas_run_id"):
  c.state.atlas_run_id="%d_%d_%d" % [int(Time.get_unix_time_from_system()),int(c.state.get("seed",0)),int(c.state.get("slot",0))]
 return str(c.state.atlas_run_id)

static func capture(c: Campaign, sim: BattleSim, source: String, key: String) -> void:
 if not sim.finished:return
 var rows=[]
 var reports=sim.report_rows()
 for u in sim.units:
  if u.summon:continue
  var h=u.hero;var found=reports.filter(func(r):return str(r.id)==str(h.id) and int(r.team)==int(u.team))
  if found.is_empty():continue
  var r=found[0]
  rows.append({"sp":h.sp,"team":u.team,"won":sim.winner==u.team,"draw":sim.winner<0,"stars":ChampionStars.tier(h),"level":h.level,"evolution":h.get("evolution",""),"items":Forge.carried(h).duplicate(),"learned":h.get("learned",{}).duplicate(true),"tactics":BattleTactics.for_hero(h),"damage":r.get("damage",0),"healing":r.get("healing",0),"blocked":r.get("blocked",0),"skills":r.get("ability_stats",{}).duplicate(true),"alive":r.get("alive",false)})
 var id=ensure_id(c)+"|"+key
 var entry={"id":id,"patch":PATCH,"source":source,"cup":int(c.state.get("tour",{}).get("level",1)),"difficulty":c.state.get("difficulty","Standard"),"challenge":int(c.state.get("challenge_rank",0)),"seconds":sim.time,"winner":sim.winner,"rows":rows}
 var pending=c.state.get("atlas_pending",[])
 if not pending.any(func(e):return e.id==id):pending.append(entry)
 c.state.atlas_pending=pending

static func read_json(path: String) -> Dictionary:
 if not FileAccess.file_exists(path):return {}
 var parsed=JSON.parse_string(FileAccess.get_file_as_string(path))
 return parsed if parsed is Dictionary else {}

static func flush(c: Campaign) -> bool:
 if c.state.get("atlas_pending",[]).is_empty():return true
 if DirAccess.make_dir_recursive_absolute(DIR)!=OK:return false
 var path=DIR+"/"+ensure_id(c)+".json"
 var data=read_json(path)
 if data.is_empty() and FileAccess.file_exists(path):return false # preserve corrupt evidence for recovery
 data.name=c.state.get("name","Guild");data.run_id=c.state.atlas_run_id
 data.complete=c.state.get("tour",{}).get("complete",false);data.fallen=c.state.get("run_over",false)
 data.challenge=int(c.state.get("challenge_rank",0));data.matches=data.get("matches",[])
 data.plan=c.state.get("decision_matrix",{}).duplicate(true)
 var known={}
 for e in data.matches:known[e.id]=true
 for e in c.state.atlas_pending:
  if not known.has(e.id):data.matches.append(e);known[e.id]=true
 var f=FileAccess.open(path+".tmp",FileAccess.WRITE)
 if f==null:return false
 f.store_string(JSON.stringify(data));f.close()
 if FileAccess.file_exists(path) and DirAccess.copy_absolute(path,path+".backup")!=OK:return false
 if DirAccess.rename_absolute(path+".tmp",path)!=OK:return false
 c.state.atlas_pending=[]
 cache.clear()
 run_cache_ready=false
 return true

static func runs() -> Array:
 if run_cache_ready:return run_cache
 var out=[];var dir=DirAccess.open(DIR)
 if dir==null:return out
 for file in dir.get_files():
  if file.ends_with(".json"):
   var d=read_json(DIR+"/"+file)
   if d.get("matches") is Array:out.append(d)
 run_cache=out;run_cache_ready=true
 return out

static func aggregate(filters: Dictionary={}) -> Dictionary:
 var cache_key=JSON.stringify(filters)
 if cache.has(cache_key):return cache[cache_key]
 var result={"champions":{},"matches":0,"runs":0}
 for run in runs():
  var used=false
  for e in run.matches:
   if filters.get("side","all")=="player" and e.source!="player":continue
   if str(filters.get("source","all"))!="all" and e.source!=filters.source:continue
   if str(filters.get("difficulty","all"))!="all" and e.difficulty!=filters.difficulty:continue
   if int(filters.get("cup",0))>0 and int(e.cup)!=int(filters.cup):continue
   if str(filters.get("patch","all"))!="all" and e.patch!=filters.patch:continue
   if int(filters.get("challenge",-1))>=0 and int(e.get("challenge",0))!=int(filters.challenge):continue
   result.matches+=1;used=true
   for r in e.rows:
    if filters.get("side","all")=="player" and (e.source!="player" or int(r.team)!=0):continue
    if filters.get("side","all")=="cpu" and e.source=="player" and int(r.team)==0:continue
    if int(filters.get("stars",0))>0 and int(r.stars)!=int(filters.stars):continue
    add_row(result.champions,r,float(e.seconds))
  result.runs+=int(used)
 cache[cache_key]=result
 return result

static func add_row(target: Dictionary,r: Dictionary,seconds: float) -> void:
 var d=target.get(r.sp,{"n":0,"wins":0.0,"damage":0.0,"healing":0.0,"seconds":0.0,"items":{},"skills":{}})
 d.n+=1;d.wins+=0.5 if r.get("draw",false) else float(r.get("won",false));d.damage+=r.get("damage",0);d.healing+=r.get("healing",0);d.seconds+=seconds
 for item in r.get("items",[]):
  var v=d.items.get(item,{"n":0,"wins":0.0});v.n+=1;v.wins+=0.5 if r.get("draw",false) else float(r.get("won",false));d.items[item]=v
 for key in r.get("skills",{}):
  if key=="incoming":continue
  var s=d.skills.get(key,{"casts":0.0,"damage":0.0,"healing":0.0});var raw=r.skills[key]
  for metric in s:s[metric]+=float(raw.get(metric,0))
  d.skills[key]=s
 target[r.sp]=d

static func unlocked_rank() -> int:
 var rank=1
 for run in runs():
  if run.get("complete",false) and int(run.get("challenge",0))>0:rank=maxi(rank,int(run.challenge)+1)
 return mini(10,rank)
