extends SceneTree
var checks=0
var failures=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func _initialize() -> void:
 HeroData.load_data()
 var pre=PlaytestDatabase.dataset("pre");var post=PlaytestDatabase.dataset("post");var expanded=PlaytestDatabase.dataset("expanded")
 check(pre.battle_count==5888 and post.battle_count==1920 and expanded.battle_count==384,"Exact nonoverlapping 8192-match cohorts")
 check(pre.units.size()==14322 and post.units.size()==14322,"Complete champion records, not aggregates")
 check(pre.effects.size()==2176 and post.effects.size()==192 and expanded.effects.size()==192,"Every controlled item comparison bundled")
 check(pre.items.size()==136 and pre.species.size()==32,"Full item and champion catalogs")
 var seen={}
 for d in [pre,post,expanded]:
  for entry in d.manifest:
   check(not seen.has(entry.file),"Raw batch is not double-counted");seen[entry.file]=true
 check(seen.size()==12,"Twelve unique raw audit batches")
 var naga=PlaytestDatabase.champions({"dataset":"post"}).naga
 check(naga.n==794 and naga.pairs==342,"Naga counts match HTML site")
 check(absf(naga.wins-.466)<.001,"Naga rate matches 46.6 percent")
 check(naga.interval[0]>.413 and naga.interval[1]<.520,"Pair-based confidence interval matches HTML")
 var filtered=PlaytestDatabase.units({"dataset":"post","difficulty":"Champion","cup":3,"strategy":"Spell power"})
 check(not filtered.is_empty() and filtered.all(func(u):return u.difficulty=="Champion" and u.cup==3 and u.strategy=="Spell power"),"Filters query raw records")
 check(PlaytestDatabase.units({"dataset":"post","stars":2}).all(func(u):return u.stars==2),"Stars filter")
 var rosary=PlaytestDatabase.item_stats("rosary",{"dataset":"post"})
 check(rosary.pairs==48 and rosary.n==96,"Expanded rosary has 48 independent mirrored setups")
 check(absf(rosary.margin-.322)<.002,"Rosary paired effect matches validated report")
 check(rosary.interval[0]<0 and rosary.interval[1]>0,"Rosary uncertainty retains zero")
 check(PlaytestDatabase.item_stats("fang",{"dataset":"pre"}).pairs==8,"Initial item screen preserves 8-setup design")
 check(PlaytestDatabase.item_stats("fang",{"dataset":"post"}).n==0,"Untested post-patch items remain unmeasured")
 check(PlaytestDatabase.item_stats("rosary",{"dataset":"expanded"}).pairs==48,"Pre-patch expanded comparison is queryable")
 var skills=PlaytestDatabase.skills(PlaytestDatabase.units({"dataset":"post"}).filter(func(u):return u.sp=="naga"))
 check(skills.any(func(s):return s.key=="signature" and s.casts>3000),"Ability measurements come from observed casts")
 check(RunDatabase.runs().is_empty(),"Bundled playtests never fabricate personal runs")
 var manifest=RunDatabase.read_json(PlaytestDatabase.ROOT+"manifest.json")
 for file in manifest.files:check(FileAccess.get_sha256(PlaytestDatabase.ROOT+file)==manifest.files[file],"Bundled dataset checksum: "+file)
 check(FileAccess.get_sha256(PlaytestDatabase.ROOT+"raw-audit.zip")==manifest.raw_archive.sha256,"Raw archive integrity")
 var archive=ZIPReader.new();check(archive.open(PlaytestDatabase.ROOT+"raw-audit.zip")==OK,"Raw playtest archive opens")
 var raw_count=0
 for file in archive.get_files():
  if file.ends_with(".jsonl"):raw_count+=archive.read_file(file).get_string_from_utf8().split("\n",false).size()
 check(raw_count==8192,"Every raw match is included in the exported game")
 archive.close()
 print("PLAYTEST DATABASE: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
