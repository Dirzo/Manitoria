class_name DecisionMatrix
extends RefCounted
const CONDITIONS=["Always","Cup 3+","Enemy healers","Enemy ranged majority","After a defeat"]
const GOALS=["Adaptive","Attack damage","Ability power","Attack speed","Armor","Cooldowns"]

static func default_rules(h: Dictionary) -> Array:
 var role=HeroData.species[h.sp].role
 var preset="Support" if role=="Support" else "Artillery" if role in ["Artillery","Ranged"] else "Assassin" if role in ["Assassin","Diver"] else "Vanguard" if role in ["Tank","Warden"] else "Natural"
 return [{"condition":"Enemy healers","preset":"Hunter","goal":"Adaptive"},{"condition":"Always","preset":preset,"goal":"Adaptive"}]

static func matches(condition: String,c: Campaign,enemies: Array) -> bool:
 match condition:
  "Always":return true
  "Cup 3+":return int(c.state.get("tour",{}).get("level",1))>=3
  "After a defeat":return int(c.state.get("report",{}).get("winner",-1))==1
  "Enemy healers":return enemies.any(func(h):return HeroData.species[h.sp].role=="Support")
  "Enemy ranged majority":return enemies.filter(func(h):return ArenaGrid.attack_hexes(HeroData.stats(h).range)>=3).size()>enemies.size()/2
 return false

static func preview(c: Campaign,enemies: Array) -> Array:
 var out=[]
 for h in c.lineup():
  var rules=c.state.get("decision_matrix",{}).get(h.id,default_rules(h))
  for r in rules:
   if str(r.get("preset","")) not in BattleTactics.PRESETS or str(r.get("goal","")) not in GOALS:continue
   if matches(str(r.get("condition","")),c,enemies):
    out.append({"id":h.id,"name":h.name,"condition":r.condition,"preset":r.preset,"goal":r.goal});break
 return out

static func apply(c: Campaign,enemies: Array) -> bool:
 var before=c.state.duplicate(true)
 for p in preview(c,enemies):
  var h=c.hero_by_id(p.id);h.tactics=BattleTactics.normalized(BattleTactics.PRESETS[p.preset]);h.build_goal=p.goal
 if c.save():return true
 c.state=before;return false
