class_name TrophyVault
extends RefCounted
# A separate local profile survives starting a fresh team or loading another slot.
const PATH="user://trophy_vault.json"
static var data: Dictionary={}
static var error=""

static func read_profile() -> void:
 if not data.is_empty():return
 data={"claims":{},"unlocks":[],"vitality":0,"might":0}
 if FileAccess.file_exists(PATH):
  var parsed=JSON.parse_string(FileAccess.get_file_as_string(PATH))
  if not valid(parsed) and FileAccess.file_exists(PATH+".backup"):parsed=JSON.parse_string(FileAccess.get_file_as_string(PATH+".backup"))
  if valid(parsed):data=parsed
  else:error="The trophy profile could not be read. Its files have been preserved."

static func valid(value: Variant) -> bool:
 return value is Dictionary and value.get("claims") is Dictionary and value.get("unlocks") is Array and value.get("vitality",-1)>=0 and value.get("vitality",99)<=5 and value.get("might",-1)>=0 and value.get("might",99)<=5

static func persist() -> bool:
 if not error.is_empty():return false
 var file=FileAccess.open(PATH+".tmp",FileAccess.WRITE)
 if file==null:return false
 file.store_string(JSON.stringify(data));file.close()
 if FileAccess.file_exists(PATH) and DirAccess.copy_absolute(PATH,PATH+".backup")!=OK:return false
 return DirAccess.rename_absolute(PATH+".tmp",PATH)==OK

static func sync(c: Campaign) -> void:
 read_profile()
 for h in c.state.get("roster",[]):
  h.legacy_hp=int(data.vitality)*0.01;h.legacy_attack=int(data.might)*0.01
  h.ascension_unlocked=h.sp in data.unlocks

static func award(c: Campaign, medal: String = "Gold") -> void:
 if not c.state.has("run_id"):c.state.run_id=Crypto.new().generate_random_bytes(16).hex_encode()
 if not c.state.has("chests"):c.state.chests=[]
 var id=c.state.run_id+":"+str(int(c.state.tour.level))
 if c.state.chests.any(func(chest):return chest.id==id):return
 var face=c.headliner()
 c.state.chests.append({"id":id,"level":c.state.tour.level,"species":face.get("sp","minotaur"),"location":WorldTour.region(c).name,"medal":medal})

static func unopened(c: Campaign) -> Array:
 read_profile()
 return c.state.get("chests",[]).filter(func(chest):return not data.claims.has(chest.id))

static func open(c: Campaign,id: String) -> Dictionary:
 read_profile()
 if not error.is_empty() or data.claims.has(id):return {}
 var eligible=unopened(c).filter(func(chest):return chest.id==id)
 if eligible.is_empty():return {}
 var chest=eligible[0];var before=data.duplicate(true);var rewards=[]
 var medal=str(chest.get("medal","Gold"))
 var state_before=c.state.duplicate(true)
 # Forge loot: Gold > Silver > Bronze.
 var rng=RandomNumberGenerator.new();rng.seed=hash(id)
 var tame=Forge.ITEMS.keys().filter(func(k):return not Forge.ITEMS[k].get("wild",false))
 var wild=Forge.ITEMS.keys().filter(func(k):return Forge.ITEMS[k].get("wild",false))
 var loot=[]
 var parts={"Gold":2,"Silver":2,"Bronze":2}[medal]
 for i in range(parts):loot.append(Forge.COMPONENT_ORDER[rng.randi_range(0,Forge.COMPONENT_ORDER.size()-1)])
 if medal in ["Gold","Silver"]:loot.append(tame[rng.randi_range(0,tame.size()-1)])
 if medal=="Gold":loot.append(wild[rng.randi_range(0,wild.size()-1)])
 var coins={"Gold":150,"Silver":100,"Bronze":60}[medal]
 for item_id in loot:
  c.state.inventory.append(item_id);var info=Forge.info(item_id)
  rewards.append({"kind":"item","item":item_id,"title":info.name,"detail":info.description})
 c.state.gold+=coins;c.state.earned_gold=int(c.state.get("earned_gold",0))+coins
 rewards.append({"kind":"gold","title":"%d gold"%coins,"detail":"Prize purse for a %s finish."%medal.to_lower()})
 if medal!="Gold":
  var result_small={"rewards":rewards,"location":chest.location,"medal":medal}
  data.claims[id]=result_small
  if not persist() or not c.save():data=before;c.state=state_before;return {}
  return result_small
 var keys=HeroData.species.keys();var target=str(chest.species)
 if target in data.unlocks:
  target=""
  for h in c.state.roster:
   if h.sp not in data.unlocks:target=h.sp;break
  if target.is_empty():
   for key in keys:
    if key not in data.unlocks:target=key;break
 if not target.is_empty():
  data.unlocks.append(target)
  rewards.append({"kind":"evolution","species":target,"title":ChampionEvolution.NAMES[target],"detail":"Evolution unlocked · Awaken this champion at level 10."})
 var stat="vitality" if int(data.vitality)<=int(data.might) else "might"
 if int(data[stat])<5:
  data[stat]=int(data[stat])+1
  rewards.append({"kind":"boost","title":"Legacy "+stat.capitalize(),"detail":"+1% "+("maximum health" if stat=="vitality" else "attack")+" for your champions, in every run. Maximum +5%."})
 if rewards.size()<=loot.size()+1:rewards.append({"kind":"honor","title":"Champion's honor","detail":"All 32 evolutions and permanent boosts collected. Trophy added to your collection."})
 var result={"rewards":rewards,"location":chest.location,"medal":medal}
 data.claims[id]=result
 if not persist() or not c.save():data=before;c.state=state_before;return {}
 sync(c)
 return result

static func awaken(c: Campaign,id: String) -> bool:
 sync(c)
 var h=c.hero_by_id(id)
 if h.is_empty() or h not in c.state.roster or h.level<10 or not h.get("ascension_unlocked",false) or h.get("evolution","")=="ascended" or not h.pending.is_empty():return false
 var before=h.duplicate(true)
 h.evolution="ascended";h.history.append(ChampionEvolution.NAMES[h.sp])
 if c.save():return true
 h.clear();h.merge(before,true);return false
