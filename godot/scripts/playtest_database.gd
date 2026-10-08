class_name PlaytestDatabase
extends RefCounted
const ROOT="res://data/playtests/"
static var datasets: Dictionary={}
static var results: Dictionary={}

static func dataset(key: String="post") -> Dictionary:
 if key not in ["pre","post","expanded"]:key="post"
 if not datasets.has(key):datasets[key]=RunDatabase.read_json(ROOT+key+".json")
 return datasets[key]

static func matches(r: Dictionary,f: Dictionary) -> bool:
 if f.get("difficulty","all")!="all" and r.get("difficulty")!=f.difficulty:return false
 if int(f.get("cup",0))>0 and int(r.get("cup",0))!=int(f.cup):return false
 if int(f.get("stars",0))>0 and int(r.get("stars",0))!=int(f.stars):return false
 if f.get("strategy","all")!="all" and r.get("strategy")!=f.strategy:return false
 return true

static func units(f: Dictionary={}) -> Array:
 return dataset(str(f.get("dataset","post"))).get("units",[]).filter(func(u):return matches(u,f))

static func stats(rows: Array) -> Dictionary:
 var s={"n":rows.size(),"wins":0.0,"score":0.0,"damage":0.0,"healing":0.0,"dps":0.0,"hps":0.0,"survival":0.0,"cc":0.0,"pairs":0}
 var pairs={}
 for u in rows:
  s.wins+=float(u.get("won",false));s.score+=0.5 if u.get("draw",false) else float(u.get("won",false))
  s.damage+=float(u.get("damage",0));s.healing+=float(u.get("healing",0))
  s.dps+=float(u.get("damage",0))/maxf(1,float(u.get("seconds",0)));s.hps+=float(u.get("healing",0))/maxf(1,float(u.get("seconds",0)))
  s.survival+=float(u.get("alive",false));s.cc+=float(u.get("cc",0));pairs[u.get("pair",-1)]=true
 s.pairs=pairs.size()
 for k in ["wins","score","dps","hps","survival","cc"]:s[k]/=maxi(1,rows.size())
 s.interval=wilson(float(s.wins),int(s.pairs));s.tier=tier(s)
 return s

static func wilson(p: float,n: int) -> Array:
 if n==0:return [0.0,1.0]
 var z=1.96;var denominator=1.0+z*z/n
 var middle=(p+z*z/(2*n))/denominator
 var radius=z*sqrt(p*(1.0-p)/n+z*z/(4*n*n))/denominator
 return [maxf(0,middle-radius),minf(1,middle+radius)]

static func tier(s: Dictionary) -> String:
 if int(s.pairs)<30:return "U"
 if float(s.score)>=.55 and float(s.interval[0])>.5:return "S"
 if float(s.score)>=.525:return "A"
 if float(s.score)>=.475:return "B"
 if float(s.score)>=.425:return "C"
 return "D"

static func grouped(rows: Array,key: String) -> Dictionary:
 var out={}
 for u in rows:
  var value=str(u.get(key,""));var list=out.get(value,[]);list.append(u);out[value]=list
 return out

static func champions(f: Dictionary={}) -> Dictionary:
 var key=JSON.stringify(f)
 if results.has(key):return results[key]
 var out={}
 var groups=grouped(units(f),"sp")
 for sp in groups:out[sp]=stats(groups[sp])
 results[key]=out
 return out

static func skills(rows: Array) -> Array:
 var groups={}
 for u in rows:
  for key in u.get("skills",{}):
   if key=="incoming" or key.begins_with("item:"):continue
   var id=u.sp+"|"+key
   var d=groups.get(id,{"sp":u.sp,"key":key,"rows":[],"casts":0.0,"damage":0.0,"healing":0.0})
   d.rows.append(u)
   for metric in ["casts","damage","healing"]:d[metric]+=float(u.skills[key].get(metric,0))
   groups[id]=d
 var out=[]
 for id in groups:
  var d=groups[id];d.stats=stats(d.rows);d.erase("rows");out.append(d)
 return out

static func item_stats(id: String,f: Dictionary={}) -> Dictionary:
 var rows=dataset(str(f.get("dataset","post"))).effects.filter(func(e):return e.id==id and matches(e,f))
 var groups={};var win=0.0;var control=0.0;var dps=0.0;var hps=0.0;var procs=0.0;var carriers={}
 for r in rows:
  var key=str(r.pair);var g=groups.get(key,[]);g.append(float(r.margin));groups[key]=g
  win+=float(r.won);control+=float(r.baseline_won);dps+=float(r.dps);hps+=float(r.hps);procs+=float(r.procs);carriers[r.carrier]=true
 var means=[]
 for key in groups:means.append(mean(groups[key]))
 var margin=mean(means);var variance=0.0
 for v in means:variance+=pow(v-margin,2)
 var n=means.size();var error=0.0
 if n>1:
  var critical=12.706 if n==2 else 4.303 if n==3 else 3.182 if n==4 else 2.776 if n==5 else 2.571 if n==6 else 2.447 if n==7 else 2.365 if n==8 else 2.262 if n<=11 else 2.131 if n<=16 else 2.086 if n<=21 else 2.060 if n<=26 else 2.045 if n<=31 else 2.021 if n<=41 else 2.012 if n<=49 else 1.96
  error=critical*sqrt(variance/(n-1)/n)
 return {"id":id,"n":rows.size(),"pairs":n,"margin":margin,"interval":[margin-error,margin+error],"interval_available":n>1,"wins":win/maxi(1,rows.size()),"control":control/maxi(1,rows.size()),"dps":dps/maxi(1,rows.size()),"hps":hps/maxi(1,rows.size()),"procs":procs/maxi(1,rows.size()),"carriers":carriers.keys()}

static func mean(values: Array) -> float:
 var total=0.0
 for v in values:total+=float(v)
 return total/maxi(1,values.size())

static func export_database() -> String:
 var target="user://playtest_export_0.72"
 if DirAccess.make_dir_recursive_absolute(target)!=OK:return ""
 for file in ["pre.json","post.json","expanded.json","balance.json","manifest.json","raw-audit.zip"]:
  if DirAccess.copy_absolute(ROOT+file,target+"/"+file)!=OK:return ""
 return ProjectSettings.globalize_path(target)
